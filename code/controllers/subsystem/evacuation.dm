GLOBAL_LIST_EMPTY(dest_rods)

SUBSYSTEM_DEF(evacuation)
	name		= "Evacuation"
	wait		= 5 SECONDS
	priority	= SS_PRIORITY_EVAC
	flags		= SS_KEEP_TIMING|SS_NO_INIT
	runlevels	= RUNLEVELS_DEFAULT|RUNLEVEL_LOBBY

	var/evac_time	//Time the evacuation was initiated.
	var/evac_status = EVACUATION_STATUS_STANDING_BY //What it's doing now? It can be standing by, getting ready to launch, or finished.

	var/obj/structure/machinery/self_destruct/dest_master //The main console that does the brunt of the work.
	var/dest_rods[] //Slave devices to make the explosion work.
	var/dest_cooldown //How long it takes between rods, determined by the amount of total rods present.
	var/dest_index = 1	//What rod the thing is currently on.
	var/dest_status = NUKE_EXPLOSION_INACTIVE
	var/dest_started_at = 0

	var/ship_evac_time
	var/ship_operation_stage_status = OPERATION_DECRYO
	var/shuttles_to_check = list(DROPSHIP_ALAMO, DROPSHIP_NORMANDY)
	var/ship_evacuating = FALSE
	var/ship_evacuating_forced = FALSE

	var/lifesigns = 0

	var/flags_scuttle = NO_FLAGS

/datum/controller/subsystem/evacuation/stat_entry(msg)
	msg = "E:[evac_time ? "I (T:[duration2text_hour_min_sec(EVACUATION_ESTIMATE_DEPARTURE)])":"S"]|D:[dest_started_at ? "I":"S"] R:[dest_index]/[length(dest_rods)]|SE:[ship_evacuating ? "I (T:[duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE)])":"S"]"
	return ..()

/datum/controller/subsystem/evacuation/fire()
	if(ship_evacuating)
		if(SHIP_ESCAPE_ESTIMATE_DEPARTURE <= 0 && ship_operation_stage_status == OPERATION_LEAVING_OPERATION_PLACE)
			SSticker.mode.round_finished = "Marine Minor Victory"
			SSticker.mode.faction_won = GLOB.faction_datums[FACTION_MARINE]
			ship_operation_stage_status = OPERATION_DEBRIEFING
			ship_evacuating = FALSE

		var/shuttles_report = shuttels_onboard()
		if(shuttles_report)
			shuttles_report += " был отправлен в обход протокола на зону операции, ожидание ответа оператора..."
			cancel_ship_evacuation(shuttles_report)

	if(dest_master && dest_master.loc && dest_master.active_state == SELF_DESTRUCT_MACHINE_ARMED && dest_status == NUKE_EXPLOSION_ACTIVE && dest_index <= dest_rods.len)
		var/obj/structure/machinery/self_destruct/rod/rod = dest_rods[dest_index]
		if(world.time >= dest_cooldown/4 + rod.activate_time)
			rod.lock_or_unlock() //Unlock it.
			if(++dest_index <= dest_rods.len)
				rod = dest_rods[dest_index]//Start the next sequence.
				rod.activate_time = world.time
		else if(world.time >= dest_cooldown + rod.activate_time)
			rod.lock_or_unlock() //Unlock it.
			if(++dest_index <= dest_rods.len)
				rod = dest_rods[dest_index]//Start the next sequence.
				rod.activate_time = world.time

/datum/controller/subsystem/evacuation/proc/prepare()
	if(!dest_master)
		log_debug("ERROR CODE SD1: could not find master self-destruct console")
		to_world(SPAN_DEBUG("ERROR CODE SD1: could not find master self-destruct console"))
		return FALSE
	if(!dest_rods)
		dest_rods = new
		for(var/obj/structure/machinery/self_destruct/rod/rod in GLOB.dest_rods)
			dest_rods += rod
	if(!dest_rods.len)
		log_debug("ERROR CODE SD2: could not find any self destruct rods")
		to_world(SPAN_DEBUG("ERROR CODE SD2: could not find any self destruct rods"))
		return FALSE
	dest_cooldown = SELF_DESTRUCT_ROD_STARTUP_TIME / dest_rods.len
	dest_master.desc = "Главная панель управления системой самоуничтожения. Она требует очень малого участия пользователя, но окончательный механизм безопасности разблокируется вручную.\nПосле начальной последовательности запуска, [dest_rods.len] управляющие стержни должны быть поставлены в режим готовности, после чего вручную переключается выключатель детонации."

/datum/controller/subsystem/evacuation/proc/get_affected_zlevels() //This proc returns the ship's z level list (or whatever specified), when an evac/self destruct happens.
	if(dest_status < NUKE_EXPLOSION_IN_PROGRESS && evac_status == EVACUATION_STATUS_COMPLETE) //Nuke is not in progress and evacuation finished, end the round on ship and low orbit (dropships in transit) only.
		. = SSmapping.levels_by_any_trait(list(ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP))
	else
		if(SSticker.mode && SSticker.mode.is_in_endgame)
			. = SSmapping.levels_by_any_trait(list(ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP))

/datum/controller/subsystem/evacuation/proc/ship_evac_blocked()
	if(get_security_level() != "red")
		return "Required RED alert"
	else if(!critical_marine_loses() && !all_faction_mobs_onboard(GLOB.faction_datums[FACTION_MARINE]))
		return "Not all forces onboard"
	else if(!shuttels_onboard())
		return "All shuttles should be loaded on ship"
	return FALSE

/datum/controller/subsystem/evacuation/proc/initiate_ship_evacuation(force = FALSE) //Begins the evacuation procedure.
	if((force || !ship_evac_blocked()) && !ship_evacuating)
		ship_evac_time = world.time
		ship_evacuating = TRUE
		ship_operation_stage_status = OPERATION_LEAVING_OPERATION_PLACE
		enter_allowed = FALSE
		ai_announcement("Внимание. Чрезвычайная ситуация. Всему персоналу и морпехам немедленно вернуться на корабль, в связи с критической ситуацией начинается немедленный процесс отбытия с зоны операции, посадочные шатлы станут недоступны через [duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE, "hh:mm:ss")]!", 'sound/AI/evacuate.ogg', logging = ARES_LOG_SECURITY)
		xeno_message_all("Волна адреналина прокатилась по улью. Существа из плоти пытаются улететь, надо сейчас же попасть на их железный улей! У вас есть всего [duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE, "hh:mm:ss")] до того как они покинут зону досягаемости.")

		for(var/obj/structure/machinery/status_display/status_display in GLOB.machines)
			if(is_mainship_level(status_display.z))
				status_display.set_picture("depart")
		for(var/shuttle_id in shuttles_to_check)
			var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
			var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
			console.escape_locked = TRUE
		return TRUE

/datum/controller/subsystem/evacuation/proc/critical_marine_loses()
	if(length(GLOB.faction_datums[FACTION_MARINE].totalMobs) < length(GLOB.faction_datums[FACTION_MARINE].totalDeadMobs) * 1.25)
		return TRUE
	return FALSE

/datum/controller/subsystem/evacuation/proc/cancel_ship_evacuation(reason) //Cancels the evac procedure. Useful if admins do not want the marines leaving.
	if(ship_operation_stage_status == OPERATION_LEAVING_OPERATION_PLACE)
		ship_operation_stage_status = OPERATION_ENDING
		ship_evacuating = FALSE
		enter_allowed = TRUE
		ai_announcement(reason, 'sound/AI/evacuate_cancelled.ogg', logging = ARES_LOG_SECURITY)

		for(var/shuttle_id in shuttles_to_check)
			var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
			var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
			console.escape_locked = FALSE

		for(var/obj/structure/machinery/status_display/status_display in GLOB.machines)
			if(is_mainship_level(status_display.z))
				status_display.set_picture("redalert")
		return TRUE

/datum/controller/subsystem/evacuation/proc/all_faction_mobs_onboard(datum/faction/faction)
	for(var/mob/living/carbon/human/M in faction.totalMobs)
		if(!is_mainship_level(M.z) && !M.check_tod())
			return FALSE
	return TRUE

/datum/controller/subsystem/evacuation/proc/shuttels_onboard()
	for(var/shuttle_id in shuttles_to_check)
		var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
		if(!shuttle)
			CRASH("Warning, something went wrong at evacuation shuttles check, please review shuttles spelling")
		else if(!is_mainship_level(shuttle.z))
			return shuttle_id
	return FALSE

/datum/controller/subsystem/evacuation/proc/get_ship_operation_stage_status_panel_eta()
	switch(ship_operation_stage_status)
		if(OPERATION_DECRYO) . = "пробуждение"
		if(OPERATION_BRIEFING) . = "брифинг"
		if(OPERATION_FIRST_LANDING) . = "высадка"
		if(OPERATION_IN_PROGRESS) . = "выполнение целей операции"
		if(OPERATION_ENDING) . = "операция завершена"
		if(OPERATION_LEAVING_OPERATION_PLACE)
			var/eta = SHIP_ESCAPE_ESTIMATE_DEPARTURE
			. = "время до покидание зоны операции - ETA [time2text(eta, "hh:mm.ss")]"
		if(OPERATION_DEBRIEFING) . = "подведение итогов"
		if(OPERATION_CRYO) . = "перемещение экипажа в крио"

/datum/controller/subsystem/evacuation/proc/initiate_evacuation(force = FALSE) //Begins the evacuation procedure.
	if(force || ((evac_status == EVACUATION_STATUS_STANDING_BY && !(flags_scuttle & FLAGS_EVACUATION_DENY)) && ship_operation_stage_status < OPERATION_ENDING))
		enter_allowed = FALSE
		evac_time = world.time
		evac_status = EVACUATION_STATUS_INITIATING
		ai_announcement("Внимание. Чрезвычайная ситуация. Всему персоналу немедленно покинуть корабль. У вас есть всего [duration2text_hour_min_sec(EVACUATION_ESTIMATE_DEPARTURE, "hh:mm:ss")] до отлета капсул, после чего все вторичные системы выключатся.", 'sound/AI/evacuate.ogg', logging = ARES_LOG_SECURITY)
		xeno_message_all("Волна адреналина прокатилась по улью. Существа из плоти пытаются сбежать!")
		for(var/obj/structure/machinery/status_display/status_display in GLOB.machines)
			if(is_mainship_level(status_display.z))
				status_display.set_picture("evac")
		activate_escape()
		activate_lifeboats()
		process_evacuation()
		return TRUE

/datum/controller/subsystem/evacuation/proc/cancel_evacuation() //Cancels the evac procedure. Useful if admins do not want the marines leaving.
	if(evac_status == EVACUATION_STATUS_INITIATING)
		enter_allowed = TRUE
		evac_time = null
		evac_status = EVACUATION_STATUS_STANDING_BY
		ai_announcement("Эвакуация отменена.", 'sound/AI/evacuate_cancelled.ogg', logging = ARES_LOG_SECURITY)
		if(get_security_level() == "red")
			for(var/obj/structure/machinery/status_display/status_display in GLOB.machines)
				if(is_mainship_level(status_display.z))
					status_display.set_picture("redalert")
		deactivate_escape()
		deactivate_lifeboats()
		return TRUE

/datum/controller/subsystem/evacuation/proc/begin_launch() //Launches the pods.
	if(evac_status == EVACUATION_STATUS_INITIATING)
		evac_status = EVACUATION_STATUS_IN_PROGRESS //Cannot cancel at this point. All shuttles are off.
		spawn() //One of the few times spawn() is appropriate. No need for a new proc.
			ai_announcement("ВНИМАНИЕ: Приказ о эвакуации приведен в действие. Запуск спасательных капсул.", 'sound/AI/evacuation_confirmed.ogg', logging = ARES_LOG_SECURITY)

			for(var/obj/docking_port/stationary/lifeboat_dock/lifeboat_dock in GLOB.lifeboat_almayer_docks) //evacuation confirmed, time to open lifeboats
				var/obj/docking_port/mobile/crashable/lifeboat/lifeboat = lifeboat_dock.get_docked()
				if(lifeboat && !lifeboat.launched)
					lifeboat_dock.open_dock()

			enable_self_destruct(FALSE, TRUE)

			for(var/obj/docking_port/stationary/escape_pod/escape_pod in GLOB.escape_almayer_docks)
				var/obj/docking_port/mobile/crashable/escape_shuttle/escape_shuttle = escape_pod.get_docked()
				if(!escape_shuttle)
					continue
				var/obj/structure/machinery/computer/shuttle/escape_pod_panel/evacuation_program = escape_shuttle.getControlConsole()
				if(escape_shuttle && evacuation_program.pod_state != ESCAPE_STATE_BROKEN)
					escape_shuttle.evac_launch() //May or may not launch, will do everything on its own.
					sleep(5 SECONDS) //Sleeps 5 seconds each launch.

			var/obj/docking_port/mobile/crashable/lifeboat/L1 = SSshuttle.getShuttle(MOBILE_SHUTTLE_LIFEBOAT_PORT)
			var/obj/docking_port/mobile/crashable/lifeboat/L2 = SSshuttle.getShuttle(MOBILE_SHUTTLE_LIFEBOAT_STARBOARD)
			while(!L1.launched || !L2.launched)
				sleep(5 SECONDS) //Sleep 5 more seconds to make sure everyone had a chance to leave. And wait for lifeboats

			lifesigns += L1.survivors + L2.survivors

			ai_announcement("ВНИМАНИЕ: Эвакуация спасательных капсул закончена. Исходящие жизненые сигналы: [lifesigns ? lifesigns  : "отсутсвуют"].", 'sound/AI/evacuation_complete.ogg', logging = ARES_LOG_SECURITY)

			evac_status = EVACUATION_STATUS_COMPLETE

			if(L1.status != LIFEBOAT_LOCKED && L2.status != LIFEBOAT_LOCKED)
				trigger_self_destruct()
			else
				ai_announcement("ВНИМАНИЕ: Не все спасательные шлюпки улетели, автоматическое самоуничтожение отменено, требуется ручное введение управляющих стержней.", 'sound/AI/evacuation_complete.ogg', logging = ARES_LOG_SECURITY)

		return TRUE

/datum/controller/subsystem/evacuation/proc/process_evacuation() //Process the timer.
	set waitfor = FALSE
	set background = TRUE

	spawn while(evac_status == EVACUATION_STATUS_INITIATING) //If it's not departing, no need to process.
		if(world.time >= evac_time + EVACUATION_AUTOMATIC_DEPARTURE)
			begin_launch()
		sleep(10) //One second

/datum/controller/subsystem/evacuation/proc/get_evac_status_panel_eta()
	switch(evac_status)
		if(EVACUATION_STATUS_STANDING_BY) . = "ожидание"
		if(EVACUATION_STATUS_INITIATING) . = "ОВДЗ: [duration2text_hour_min_sec(EVACUATION_ESTIMATE_DEPARTURE, "hh:mm:ss")]"
		if(EVACUATION_STATUS_IN_PROGRESS) . = "запуск спасательных капсул"
		if(EVACUATION_STATUS_COMPLETE) . = "эвакуация завершена"

// ESCAPE_POODS
/datum/controller/subsystem/evacuation/proc/activate_escape()
	for(var/obj/docking_port/stationary/escape_pod/escape_pod in GLOB.escape_almayer_docks)
		var/obj/docking_port/mobile/crashable/escape_shuttle/escape_shuttle = escape_pod.get_docked()
		var/obj/structure/machinery/computer/shuttle/escape_pod_panel/evacuation_program = escape_shuttle.getControlConsole()
		if(escape_shuttle && evacuation_program.pod_state != ESCAPE_STATE_BROKEN)
			escape_shuttle.prepare_evac()

/datum/controller/subsystem/evacuation/proc/deactivate_escape()
	for(var/obj/docking_port/stationary/escape_pod/escape_pod in GLOB.escape_almayer_docks)
		var/obj/docking_port/mobile/crashable/escape_shuttle/escape_shuttle = escape_pod.get_docked()
		var/obj/structure/machinery/computer/shuttle/escape_pod_panel/evacuation_program = escape_shuttle.getControlConsole()
		if(escape_shuttle && evacuation_program.pod_state != ESCAPE_STATE_BROKEN)
			escape_shuttle.prepare_evac()


// LIFEBOATS CORNER
/datum/controller/subsystem/evacuation/proc/activate_lifeboats()
	for(var/obj/docking_port/stationary/lifeboat_dock/LD in GLOB.lifeboat_almayer_docks)
		var/obj/docking_port/mobile/crashable/lifeboat/L = LD.get_docked()
		if(L && L.status != LIFEBOAT_LOCKED)
			L.status = LIFEBOAT_ACTIVE
			L.set_mode(SHUTTLE_RECHARGING)
			L.setTimer(12.5 MINUTES)

/datum/controller/subsystem/evacuation/proc/deactivate_lifeboats()
	for(var/obj/docking_port/stationary/lifeboat_dock/LD in GLOB.lifeboat_almayer_docks)
		var/obj/docking_port/mobile/crashable/lifeboat/L = LD.get_docked()
		if(L && L.status != LIFEBOAT_LOCKED)
			L.status = LIFEBOAT_INACTIVE
			L.set_mode(SHUTTLE_IDLE)
			L.setTimer(0)

//=========================================================================================
//===================================SELF DESTRUCT=========================================
//=========================================================================================

/datum/controller/subsystem/evacuation/proc/enable_self_destruct(force = FALSE, evac = FALSE)
	if(force || ((dest_status == NUKE_EXPLOSION_INACTIVE && !(flags_scuttle & FLAGS_SELF_DESTRUCT_DENY)) && ship_operation_stage_status < OPERATION_ENDING))
		dest_status = NUKE_EXPLOSION_ACTIVE
		dest_master.lock_or_unlock()
		dest_started_at = world.time
		set_security_level(SEC_LEVEL_DELTA) //also activate Delta alert, to open the status_display shutters.
		spawn(0)
			for(var/obj/structure/machinery/door/poddoor/almayer/D in GLOB.machines)
				if(D.id == "sd_lockdown")
					D.open()
		return TRUE

//Override is for admins bypassing normal player restrictions.
/datum/controller/subsystem/evacuation/proc/cancel_self_destruct(override)
	if(dest_status == NUKE_EXPLOSION_ACTIVE)
		var/obj/structure/machinery/self_destruct/rod/rod
		for(rod in SSevacuation.dest_rods)
			if(rod.active_state == SELF_DESTRUCT_MACHINE_ARMED && !override)
				dest_master.state(SPAN_WARNING("ПРЕДУПРЕЖДЕНИЕ: Невозможно отменить детонацию. Пожалуйста деактивируйте все управляющие стержни."))
				return FALSE

		dest_status = NUKE_EXPLOSION_INACTIVE
		dest_master.in_progress = 1
		dest_started_at = 0
		for(rod in dest_rods)
			if(rod.active_state == SELF_DESTRUCT_MACHINE_ACTIVE || (rod.active_state == SELF_DESTRUCT_MACHINE_ARMED && override))
				rod.lock_or_unlock(1)
		dest_master.lock_or_unlock(1)
		dest_index = 1
		ai_announcement("Система аварийного самоуничтожения была деактивирована.", 'sound/AI/selfdestruct_deactivated.ogg', logging = ARES_LOG_SECURITY)
		if(evac_status == EVACUATION_STATUS_STANDING_BY) //the evac has also been cancelled or was never started.
			set_security_level(SEC_LEVEL_RED, TRUE) //both status_display and evac are inactive, lowering the security level.
		return TRUE

/datum/controller/subsystem/evacuation/proc/initiate_self_destruct(override)
	if(dest_status < NUKE_EXPLOSION_IN_PROGRESS)
		var/obj/structure/machinery/self_destruct/rod/rod
		for(rod in dest_rods)
			if(rod.active_state != SELF_DESTRUCT_MACHINE_ARMED && !override)
				dest_master.state(SPAN_WARNING("ПРЕДУПРЕЖДЕНИЕ: Невозможно запустить детонацию. Пожалуйста, активируйте все управляющие стержни."))
				return FALSE
		dest_master.in_progress = 0
		for(rod in SSevacuation.dest_rods)
			rod.in_progress = 1
		trigger_self_destruct(override)
		return TRUE

/datum/controller/subsystem/evacuation/proc/trigger_self_destruct(override)
	ai_announcement("ОПАСНОСТЬ. ОПАСНОСТЬ. Система самоуничтожения активирована. ОПАСНОСТЬ. ОПАСНОСТЬ. Самоуничтожение выполняется. ОПАСНОСТЬ. ОПАСНОСТЬ.", logging = ARES_LOG_SECURITY)
	playsound(dest_master, 'sound/machines/Alarm.ogg', 75, 0, 30)
	enter_allowed = FALSE
	SSticker.mode.play_cinematic(cinematic_icons = override ? list("intro_ship", "intro_override", "ship_spared", "summary_spared") : list("intro_ship", "intro_nuke", "ship_destroyed", "summary_destroyed"),cause_data = create_cause_data("самоуничтожения корабля", src), explosion_sound = list('sound/music/round_end/nuclear_detonation1.ogg', 'sound/music/round_end/nuclear_detonation2.ogg'))
	for(var/shuttle_id in list(DROPSHIP_ALAMO, DROPSHIP_NORMANDY))
		var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
		var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
		console.disable()
	to_chat_spaced(world, html = SPAN_ANNOUNCEMENT_HEADER_BLUE("Вы видите как на орбите рядом взрывается USS Almayer, его осколки охватывают всю орбиту"))

//Generic parent base for the self_destruct items.
/obj/structure/machinery/self_destruct
	icon = 'icons/obj/structures/machinery/self_destruct.dmi'
	icon_state = "console"
	use_power = USE_POWER_NONE //Runs unpowered, may need to change later.
	density = FALSE
	anchored = TRUE //So it doesn't go anywhere.
	unslashable = TRUE
	unacidable = TRUE //Cannot C4 it either.
	mouse_opacity = FALSE //No need to click or interact with this initially.
	var/in_progress = 0 //Cannot interact with while it's doing something, like an animation.
	var/active_state = SELF_DESTRUCT_MACHINE_INACTIVE //What step of the process it's on.

/obj/structure/machinery/self_destruct/Initialize(mapload)
	. = ..()
	icon_state += "_1"

/obj/structure/machinery/self_destruct/ex_act()
	return

/obj/structure/machinery/self_destruct/attack_hand()
	if(..() || in_progress)
		return FALSE //This check is backward, ugh.
	return TRUE

/obj/structure/machinery/self_destruct/proc/lock_or_unlock(lock)
	set waitfor = FALSE
	in_progress = 1
	flick(initial(icon_state) + (lock? "_5" : "_2"), src)
	sleep(9)
	mouse_opacity = !mouse_opacity
	icon_state = initial(icon_state) + (lock? "_1" : "_3")
	in_progress = 0
	active_state = active_state > SELF_DESTRUCT_MACHINE_INACTIVE ? SELF_DESTRUCT_MACHINE_INACTIVE : SELF_DESTRUCT_MACHINE_ACTIVE

/obj/structure/machinery/self_destruct/console
	name = "self destruct control panel"
	icon_state = "console"

/obj/structure/machinery/self_destruct/console/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/machinery/self_destruct/console/LateInitialize()
	. = ..()
	SSevacuation.dest_master = src
	SSevacuation.prepare()

/obj/structure/machinery/self_destruct/console/Destroy()
	. = ..()
	SSevacuation.dest_master = null
	SSevacuation.dest_rods = null

/obj/structure/machinery/self_destruct/console/attack_hand(mob/user)
	. = ..()
	if(.)
		tgui_interact(user)

/obj/structure/machinery/self_destruct/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SelfDestructConsole", "OMICRON6 PAYLOAD")
		ui.open()

/obj/structure/machinery/self_destruct/console/ui_data(mob/user)
	var/list/data = list()

	data["dest_status"] = active_state

	return data

/obj/structure/machinery/self_destruct/console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("dest_start")
			to_chat(usr, SPAN_NOTICE("You press a few keys on the panel."))
			to_chat(usr, SPAN_NOTICE("The system must be booting up the self-destruct sequence now."))
			playsound(src.loc, 'sound/items/rped.ogg', 25, TRUE)
			sleep(2 SECONDS)
			ai_announcement("Danger. The emergency destruct system is now activated. The ship will detonate in T-minus 20 minutes. Automatic detonation is unavailable. Manual detonation is required.", 'sound/AI/selfdestruct.ogg', ARES_LOG_SECURITY)
			active_state = SELF_DESTRUCT_MACHINE_ARMED //Arm it here so the process can execute it later.
			var/obj/structure/machinery/self_destruct/rod/rod = SSevacuation.dest_rods[SSevacuation.dest_index]
			rod.activate_time = world.time
			. = TRUE

		if("dest_trigger")
			SSevacuation.initiate_self_destruct()
			. = TRUE

		if("dest_cancel")
			if(!allowed(usr))
				to_chat(usr, SPAN_WARNING("You don't have the necessary clearance to cancel the emergency destruct system!"))
				return
			SSevacuation.cancel_self_destruct()
			. = TRUE

/obj/structure/machinery/sleep_console/console/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(inoperable())
		return UI_CLOSE

/obj/structure/machinery/self_destruct/rod
	name = "self-destruct control rod"
	desc = "It is part of a complicated self-destruct sequence, but relatively simple to operate. Twist to arm or disarm."
	icon_state = "rod"
	layer = BELOW_OBJ_LAYER
	var/activate_time

/obj/structure/machinery/self_destruct/rod/Initialize(mapload, ...)
	. = ..()
	GLOB.dest_rods += src

/obj/structure/machinery/self_destruct/rod/Destroy()
	. = ..()
	GLOB.dest_rods -= src

/obj/structure/machinery/self_destruct/rod/lock_or_unlock(lock)
	playsound(src, 'sound/machines/hydraulics_2.ogg', 25, 1)
	. = ..()
	if(lock)
		activate_time = null
		density = FALSE
		layer = initial(layer)
	else
		density = TRUE
		layer = ABOVE_OBJ_LAYER

/obj/structure/machinery/self_destruct/rod/attack_hand(mob/user)
	if(..())
		switch(active_state)
			if(SELF_DESTRUCT_MACHINE_ACTIVE)
				to_chat(user, SPAN_NOTICE("You twist and release the control rod, arming it."))
				playsound(src, 'sound/machines/switch.ogg', 25, 1)
				icon_state = "rod_4"
				active_state = SELF_DESTRUCT_MACHINE_ARMED
			if(SELF_DESTRUCT_MACHINE_ARMED)
				to_chat(user, SPAN_NOTICE("You twist and release the control rod, disarming it."))
				playsound(src, 'sound/machines/switch.ogg', 25, 1)
				icon_state = "rod_3"
				active_state = SELF_DESTRUCT_MACHINE_ACTIVE
			else to_chat(user, SPAN_WARNING("The control rod is not ready."))
