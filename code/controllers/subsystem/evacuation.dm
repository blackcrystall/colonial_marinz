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
	msg = "E:[evac_time ? "I (T:[duration2text_hour_min_sec(EVACUATION_ESTIMATE_DEPARTURE)])":"S"]|D:[dest_started_at ? "I":"S"] R:[dest_index]/[length(dest_rods)]|SE:[ship_evac_time ? "I (T:[duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE)])":"S"]"
	return ..()

/datum/controller/subsystem/evacuation/fire()
	if(ship_evacuating)
		if(SHIP_ESCAPE_ESTIMATE_DEPARTURE >= 0)
			SSticker.mode.round_finished = "Marine Minor Victory"
			SSticker.mode.faction_won = GLOB.faction_datum[FACTION_MARINE]
			ship_operation_stage_status = OPERATION_DEBRIEFING
			ship_evac_time = null
			ship_evacuating = FALSE
			for(var/shuttle_id in shuttles_to_check)
				var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
				var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
				console.disabled = FALSE

		var/shuttles_report = shuttels_onboard()
		if(shuttles_report)
			shuttles_report += " был отправлен в обход протокола на зону операции, ожидание ответа оператора..."
			cancel_ship_evacuation(shuttles_report)

	if(dest_master && dest_master.loc && dest_master.active_state == SELF_DESTRUCT_MACHINE_ARMED && dest_status == NUKE_EXPLOSION_ACTIVE && dest_index <= dest_rods.len)
		var/obj/structure/machinery/self_destruct/rod/rod = dest_rods[dest_index]
		if(dest_master.activated_by_evac && (world.time >= dest_cooldown/4 + rod.activate_time))
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
	dest_master = locate()
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
	else if(!critical_marine_loses() && !all_faction_mobs_onboard(GLOB.faction_datum[FACTION_MARINE]))
		return "Not all forces onboard"
	else if(!shuttels_onboard())
		return "All shuttles should be loaded on ship"
	return FALSE

/datum/controller/subsystem/evacuation/proc/initiate_ship_evacuation(force = FALSE) //Begins the evacuation procedure.
	if((force || !ship_evac_blocked()) && !ship_evacuating)
		ship_evacuating = TRUE
		ship_evac_time = world.time
		ship_operation_stage_status = OPERATION_LEAVING_OPERATION_PLACE
		enter_allowed = FALSE
		ai_announcement("Внимание. Чрезвычайная ситуация. Всему персоналу и морпехам немедленно вернуться на корабль, в связи с критической ситуацией начинается немедленный процесс отбытия с зоны операции, посадочные шатлы станут недоступны через [duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE, "hh:mm:ss")]!", 'sound/AI/evacuate.ogg', logging = ARES_LOG_SECURITY)
		xeno_message_all("Волна адреналина прокатилась по улью. Существа из плоти пытаются улететь, надо сейчас же попасть на их железный улей! У вас есть всего [duration2text_hour_min_sec(SHIP_ESCAPE_ESTIMATE_DEPARTURE, "hh:mm:ss")] до того как они покинут зону досягаемости.")

		for(var/obj/structure/machinery/status_display/status_display in machines)
			if(is_mainship_level(status_display.z))
				status_display.set_picture("depart")
		for(var/shuttle_id in shuttles_to_check)
			var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
			var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
			console.escape_locked = FALSE
		return TRUE

/datum/controller/subsystem/evacuation/proc/critical_marine_loses()
	if(length(GLOB.faction_datum[FACTION_MARINE].totalMobs) < length(GLOB.faction_datum[FACTION_MARINE].totalDeadMobs) * 1.25)
		return TRUE
	return FALSE

/datum/controller/subsystem/evacuation/proc/cancel_ship_evacuation(reason) //Cancels the evac procedure. Useful if admins do not want the marines leaving.
	if(ship_operation_stage_status == OPERATION_LEAVING_OPERATION_PLACE)
		ship_evacuating = FALSE
		enter_allowed = TRUE
		ship_evac_time = null
		ship_operation_stage_status = OPERATION_ENDING
		ai_announcement(reason, 'sound/AI/evacuate_cancelled.ogg', logging = ARES_LOG_SECURITY)

		for(var/shuttle_id in shuttles_to_check)
			var/obj/docking_port/mobile/marine_dropship/shuttle = SSshuttle.getShuttle(shuttle_id)
			var/obj/structure/machinery/computer/shuttle/dropship/flight/console = shuttle.getControlConsole()
			console.escape_locked = FALSE

		for(var/obj/structure/machinery/status_display/status_display in machines)
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
		for(var/obj/structure/machinery/status_display/status_display in machines)
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
			for(var/obj/structure/machinery/status_display/status_display in machines)
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
				if(lifeboat && lifeboat.available)
					lifeboat_dock.open_dock()

			enable_self_destruct(FALSE, TRUE)

			for(var/obj/docking_port/stationary/escape_pod/escape_pod in GLOB.escape_almayer_docks)
				var/obj/docking_port/mobile/crashable/escape_shuttle/escape_shuttle = escape_pod.get_docked()
				var/obj/structure/machinery/computer/shuttle/escape_pod_panel/evacuation_program = escape_shuttle.getControlConsole()
				if(escape_shuttle && evacuation_program.pod_state != ESCAPE_STATE_BROKEN)
					escape_shuttle.evac_launch() //May or may not launch, will do everything on its own.
					sleep(5 SECONDS) //Sleeps 5 seconds each launch.

			var/obj/docking_port/mobile/crashable/lifeboat/L1 = SSshuttle.getShuttle(MOBILE_SHUTTLE_LIFEBOAT_PORT)
			var/obj/docking_port/mobile/crashable/lifeboat/L2 = SSshuttle.getShuttle(MOBILE_SHUTTLE_LIFEBOAT_STARBOARD)
			while(L1.available || L2.available)
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
		if(evac)
			dest_master.activated_by_evac = TRUE
		dest_status = NUKE_EXPLOSION_ACTIVE
		dest_master.lock_or_unlock()
		dest_started_at = world.time
		set_security_level(SEC_LEVEL_DELTA) //also activate Delta alert, to open the status_display shutters.
		spawn(0)
			for(var/obj/structure/machinery/door/poddoor/almayer/D in machines)
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
		dest_master.in_progress = !dest_master.in_progress
		for(rod in SSevacuation.dest_rods)
			rod.in_progress = 1
		ai_announcement("ОПАСНОСТЬ. ОПАСНОСТЬ. Система самоуничтожения активирована. ОПАСНОСТЬ. ОПАСНОСТЬ. Самоуничтожение выполняется. ОПАСНОСТЬ. ОПАСНОСТЬ.", logging = ARES_LOG_SECURITY)
		trigger_self_destruct(,,override)
		return TRUE

/datum/controller/subsystem/evacuation/proc/trigger_self_destruct(list/z_levels = SSmapping.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP), origin = dest_master, override = FALSE, end_type = NUKE_EXPLOSION_FINISHED, play_anim = TRUE, end_round = TRUE)
	set waitfor = FALSE
	if(dest_status < NUKE_EXPLOSION_IN_PROGRESS) //One more check for good measure, in case it's triggered through a bomb instead of the destruct mechanism/admin panel.
		dest_status = NUKE_EXPLOSION_IN_PROGRESS
		playsound(origin, 'sound/machines/Alarm.ogg', 75, 0, 30)
		world << pick('sound/music/round_end/nuclear_detonation1.ogg','sound/music/round_end/nuclear_detonation2.ogg')

		var/ship_status = 1
		for(var/i in z_levels)
			if(is_mainship_level(i))
				ship_status = 0 //Destroyed.
			break

		var/L1[] = new //Everyone who will be destroyed on the zlevel(s).
		var/L2[] = new //Everyone who only needs to see the cinematic.
		var/mob/M
		var/turf/T
		for(M in GLOB.player_list) //This only does something cool for the people about to die, but should prove pretty interesting.
			if(!M || !M.loc) continue //In case something changes when we sleep().
			if(M.stat == DEAD)
				L2 |= M
			else if(M.z in z_levels)
				L1 |= M
				shake_camera(M, 110, 4)


		sleep(100)
		/*Hardcoded for now, since this was never really used for anything else.
		Would ideally use a better system for showing cutscenes.*/
		var/atom/movable/screen/cinematic/explosion/C = new

		if(play_anim)
			for(M in L1 + L2)
				if(M && M.loc && M.client)
					M.client.screen |= C //They may have disconnected in the mean time.

			sleep(15) //Extra 1.5 seconds to look at the ship.
			flick(override ? "intro_override" : "intro_nuke", C)
		sleep(35)
		for(M in L1)
			if(M && M.loc) //Who knows, maybe they escaped, or don't exist anymore.
				T = get_turf(M)
				if(T.z in z_levels)
					M.death(create_cause_data("самоуничтожения корабля"))
				else
					if(play_anim)
						M.client.screen -= C //those who managed to escape the z level at last second shouldn't have their view obstructed.
		if(play_anim)
			flick(ship_status ? "ship_spared" : "ship_destroyed", C)
			C.icon_state = ship_status ? "summary_spared" : "summary_destroyed"
		world << sound('sound/effects/explosionfar.ogg')

		if(end_round)
			dest_status = end_type

			sleep(5)
			if(SSticker.mode)
				SSticker.mode.check_win()

			if(!SSticker.mode) //Just a safety, just in case a mode isn't running, somehow.
				to_world(SPAN_ROUNDBODY("Рестарт через 30 секунд!"))
				sleep(300)
				log_game("Рестарт из-за самоуничтожения корабля.")
				world.Reboot(HrefToken(TRUE), SSticker.graceful)
			return TRUE

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
	var/activated_by_evac = FALSE

/obj/structure/machinery/self_destruct/Initialize(mapload, ...)
	. = ..()
	icon_state += "_1"
	return INITIALIZE_HINT_LATELOAD

/obj/structure/machinery/self_destruct/LateInitialize()
	. = ..()
	SSevacuation.prepare()

/obj/structure/machinery/self_destruct/ex_act()
	return

/obj/structure/machinery/self_destruct/proc/lock_or_unlock(lock)
	playsound(src, 'sound/machines/hydraulics_1.ogg', 25, 1)

//TODO: Add sounds.
/obj/structure/machinery/self_destruct/attack_hand(mob/user)
	if(inoperable())
		return

	tgui_interact(user)

/obj/structure/machinery/self_destruct/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SelfDestructConsole", name)
		ui.open()

/obj/structure/machinery/sleep_console/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(inoperable())
		return UI_CLOSE


/obj/structure/machinery/self_destruct/ui_data(mob/user)
	var/list/data = list()

	data["dest_status"] = active_state

	return data

/obj/structure/machinery/self_destruct/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
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
	..()
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
