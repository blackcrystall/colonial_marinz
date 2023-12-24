// -- Docks
/obj/docking_port/stationary/sselevator
	name = "Sky Scraper Elevator Floor"
	id = MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR
	width = 7
	height = 7

/obj/docking_port/stationary/sselevator/register()
	id = "[MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR]_[src.z]"
	. = ..()
	GLOB.ss_elevator_floors["[id]"] = src

// -- Shuttles

/obj/docking_port/mobile/sselevator
	name = "sky scraper elevator"
	id = MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR
	width = 7
	height = 7

	landing_sound = null
	ignition_sound = 'sound/machines/asrs_raising.ogg'
	ambience_flight = 'sound/ambience/elevator_music.ogg'
	ambience_idle = 'sound/ambience/elevator_music.ogg'
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)

	custom_ceiling = /turf/open/floor/roof/ship_hull/lab

	var/disabled_elevator = TRUE // Fix of auto mode, when shuttle got in troubles or loading
	var/target_floor = 100
	var/floor_offset = 0
	var/offseted_z = 0
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/door
	var/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button
	var/list/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/doors = list()
	var/list/obj/structure/machinery/gear/gears = list()
	var/list/buttons[100]
	var/list/disabled_floors[100]
	var/list/called_floors[100]
	var/next_moving = 0
	var/moving = FALSE
	var/cooldown = FALSE
	var/move_delay = 3 SECONDS

/obj/docking_port/mobile/sselevator/Initialize()
	. = ..()
	for(var/i=1;i<100;i++)
		disabled_floors[i] = TRUE
	disabled_floors[100] = FALSE
	for(var/i=1;i<100;i++)
		called_floors[i] = FALSE

/obj/docking_port/mobile/sselevator/register()
	. = ..()
	SSshuttle.sky_scraper_elevator = src

/obj/docking_port/mobile/sselevator/request(obj/docking_port/stationary/S) //No transit, no ignition, just a simple up/down platform
	initiate_docking(S, force = TRUE)

/obj/docking_port/mobile/sselevator/afterShuttleMove()
	if(disabled_elevator)
		return
	offseted_z = z - floor_offset
	if(offseted_z == target_floor)
		cooldown = TRUE
		sleep(2 SECONDS)
		on_stop_actions()
		moving = FALSE
		target_floor = 0
		sleep(13 SECONDS)
		cooldown = FALSE
		if(next_moving)
			calc_elevator_order(next_moving)
			next_moving = 0

	else if(called_floors[offseted_z])
		sleep(2 SECONDS)
		on_stop_actions()
		sleep(13 SECONDS)
		on_move_actions()
		move_elevator()
	else
		move_elevator(FALSE)

/obj/docking_port/mobile/sselevator/proc/on_move_actions()
	button.update_icon("_animated")
	INVOKE_ASYNC(doors["[z]"], TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, close_and_lock))
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, close_and_lock))
	for(var/obj/structure/machinery/gear/gear as anything in gears)
		gear.start_moving()

/obj/docking_port/mobile/sselevator/proc/on_stop_actions()
	var/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button = buttons[offseted_z]
	if(button)
		button.update_icon()
	button.update_icon()
	called_floors[offseted_z] = FALSE
	INVOKE_ASYNC(doors["[z]"], TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))
	for(var/obj/structure/machinery/gear/gear as anything in gears)
		gear.stop_moving()

/obj/docking_port/mobile/sselevator/proc/move_elevator(message = TRUE)
	var/floor_to_move = offseted_z > target_floor ? offseted_z - 1 : offseted_z + 1
	if(message)
		button.visible_message(SPAN_NOTICE("Лифт отправляется и прибудет на этаж [floor_to_move]. Пожалуйста стойте в стороне от дверей."))
	playsound(return_center_turf(), ignition_sound, 60, 0, falloff = 4)
	sleep(4 SECONDS)
	calculate_move_delay(floor_to_move)
	SSshuttle.moveShuttleToDock(id, GLOB.ss_elevator_floors["[MOBILE_SHUTTLE_SKY_SCRAPER_ELEVATOR]_[floor_to_move + floor_offset]"], move_delay, FALSE)

/obj/docking_port/mobile/sselevator/proc/calculate_move_delay(floor_calc)
	if(offseted_z > target_floor ? offseted_z - floor_calc > 4 : floor_calc - offseted_z > 4)
		move_delay--
	else
		move_delay += 0.2 SECONDS
	move_delay = Clamp(move_delay, 4 SECONDS, 0.5 SECONDS)

/obj/docking_port/mobile/sselevator/proc/calc_elevator_order(floor_calc)
	if(!moving && !cooldown)
		var/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button = buttons[floor_calc]
		if(button)
			button.update_icon("_animated")
		called_floors[floor_calc] = TRUE
		target_floor = floor_calc
		moving = offseted_z > target_floor ? "DOWN" : "UP"
		on_move_actions()
		move_elevator()
	else
		var/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button = buttons[floor_calc]
		if(button)
			button.update_icon("_animated")
		called_floors[floor_calc] = TRUE
		switch(moving)
			if("DOWN")
				if(floor_calc > next_moving)
					next_moving = floor_calc
				else if(floor_calc < target_floor)
					target_floor = floor_calc
			if("UP")
				if(floor_calc > target_floor)
					target_floor = floor_calc
				else if(floor_calc < next_moving)
					next_moving = floor_calc
			else
				if((floor_calc > next_moving > offseted_z) || (floor_calc < next_moving < offseted_z))
					next_moving = floor_calc
				if((floor_calc > target_floor > offseted_z) || (floor_calc < target_floor < offseted_z))
					target_floor = floor_calc

/obj/docking_port/stationary/sselevator/floor_roof
	roundstart_template = /datum/map_template/shuttle/sky_scraper_elevator

/obj/docking_port/stationary/sselevator/floor_roof/load_roundstart()
	. = ..()
	SSshuttle.sky_scraper_elevator.disabled_elevator = FALSE
	SSshuttle.sky_scraper_elevator.floor_offset = z - 100
	SSshuttle.sky_scraper_elevator.target_floor = z - SSshuttle.sky_scraper_elevator.floor_offset
	var/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator/B = SSshuttle.sky_scraper_elevator.doors["[z]"]
	INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door/airlock/multi_tile/almayer/dropshiprear/blastdoor/elevator, unlock_and_open))

//Console

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator
	name = "'S95 v2' elevator console"
	desc = "Controls for the 'S95 v2' elevator."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "elevator_screen"
	var/floor
	var/obj/docking_port/mobile/sselevator/elevator

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/Initialize(mapload, ...)
	. = ..()
	connect_elevator()

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/proc/connect_elevator()
	set waitfor = FALSE
	UNTIL(SSshuttle.sky_scraper_elevator)
	elevator = SSshuttle.sky_scraper_elevator
	if(floor != "control")
		floor = z - elevator.floor_offset
		elevator.buttons[floor] = src

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/Destroy()
	if(floor != "control")
		elevator.buttons[floor] -= src
	. = ..()

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/update_icon(icon_update = "")
	icon_state = initial(icon_state) + icon_update

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Доступ Запрещен!"))
		return
	if(!isRemoteControlling(user))
		user.set_interaction(src)
	tgui_interact(user)

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/tgui_interact(mob/user, datum/tgui/ui)
	// Update UI
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		// Open UI
		ui = new(user, src, "Elevator", name, 600, 600)
		ui.open()

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/ui_data()
	var/list/data = list()
	data["buttons"] = list()
	for(var/i=1;i<100;i++)
		data["buttons"] += list(list(
			id = i, title = "Floor [i]", disabled = elevator.disabled_floors[i], called = elevator.called_floors[i],
		))
	return data

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	if(action == "click")
		var/target_floor = params["id"]
		if(elevator.offseted_z == target_floor || elevator.called_floors[target_floor])
			return
		playsound(src, 'sound/machines/click.ogg', 15, 1)
		elevator.calc_elevator_order(target_floor)
		return
	return

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock, idnum, override)
	. = ..()
	if(istype(port, /obj/docking_port/mobile/sselevator))
		var/obj/docking_port/mobile/sselevator/L = port
		L.button = src

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button
	desc = "The remote controls for the 'S95 v2' elevator."

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Доступ Запрещен!"))
		return
	if(elevator.offseted_z == floor)
		return
	if(elevator.disabled_floors[floor])
		visible_message(SPAN_WARNING("Лифт не может отправится на этот этаж, обратитесь на ближайший пост службы безопасности!"))
		return
	if(elevator.called_floors[floor])
		visible_message(SPAN_NOTICE("Лифт уже едет на этот этаж, ожидайте."))
		return
	call_elevator(user)

/obj/structure/machinery/computer/shuttle/shuttle_control/sselevator/button/proc/call_elevator()
	playsound(src, 'sound/machines/click.ogg', 15, 1)
	visible_message(SPAN_NOTICE("Лифт вызван, ожидайте."))
	elevator.calc_elevator_order(floor)


/obj/structure/machinery/computer/security_blocker
	name = "Security Controller"
	desc = "Used to control floors of sky scraper."
	icon_state = "terminal1"

	density = TRUE
	unacidable = TRUE
	anchored = TRUE
	indestructible = TRUE

	var/generate_time = 1 MINUTES
	var/segment_time = 30 SECONDS

	var/total_segments = 5 // total number of times the hack is required
	var/completed_segments = 0 // what segment we are on, (once this hits total)
	var/current_timer

	var/working = FALSE
	var/security_protocol = TRUE

	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/stairs_doors = list()
	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/elevator_doors = list()
	var/list/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/move_lock_doors = list()
	var/list/obj/structure/machinery/siren/sirens = list()
	var/list/obj/structure/machinery/light/double/almenia/lights = list()
	var/obj/docking_port/mobile/sselevator/elevator
	var/list/locked = list("stairs" = FALSE, "elevator" = FALSE)

	var/list/technobabble = list(
		"Запускаем терминал",
		"Критическая ошибка, поиск причины",
		"ОШИБКА, недостаточный доступ для проведения операции",
		"Подключаемся к главному серверу W-Y, скачиваем протоколы обхода защиты",
		"Протоколы скачаны, запустите их для снятия блокировки, хорошего дня (C) W-Y General Security Systems"
	)

/obj/structure/machinery/computer/security_blocker/Initialize()
	. = ..()
	GLOB.skyscrapers_sec_comps["[z]"] += src
	connect_elevator()

/obj/structure/machinery/computer/security_blocker/proc/connect_elevator()
	set waitfor = FALSE
	UNTIL(SSshuttle.sky_scraper_elevator)
	elevator = SSshuttle.sky_scraper_elevator
	for(var/obj/structure/machinery/siren/S as anything in sirens)
		S.siren_warning_start("ТРЕВОГА, КРИТИЧЕСКАЯ СИТУАЦИЯ, ЗАПУЩЕН ПРОТОКОЛ МАКСИМАЛЬНОЙ БЕЗОПАСНОСТИ, ЭТАЖ [z - elevator.floor_offset]")
	for(var/obj/structure/machinery/light/double/almenia/L as anything in lights)
		L.change_almenia_state(1)

/obj/structure/machinery/computer/security_blocker/ex_act(severity)
	return

/obj/structure/machinery/computer/security_blocker/process()
	. = ..()
	if((. && current_timer > 0) || current_timer == 0)
		updateUsrDialog()
		return

	deltimer(current_timer)
	current_timer = null
	working = FALSE
	visible_message("<b>[src]</b> выключается из-за отсутствия питания.")
	updateUsrDialog()
	return PROCESS_KILL

/obj/structure/machinery/computer/security_blocker/attackby(mob/user as mob)
	interact(user)

/obj/structure/machinery/computer/security_blocker/attack_hand(mob/user as mob)
	. = ..()
	interact(user)

/obj/structure/machinery/computer/security_blocker/attack_remote(mob/user as mob)
	interact(user)

/obj/structure/machinery/computer/security_blocker/interact(mob/user)
	. = ..()
	user.set_interaction(src)
	var/dat = ""
	dat += "<div align='center'>Терминал безопасности [z - elevator.floor_offset] этажа</a></div>"
	dat += "<br/><span><b>Протокол безопасности</b>: [security_protocol ? "включен" : "отключен"]</span>"
	if(!security_protocol)
		if(istype(user,/mob/living/carbon/xenomorph/queen) && !current_timer)
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=unlock'>Разблокировать этаж</a></div>"
		else if(current_timer)
			dat += "<br/><span><b>Терминал заблокирован</b></span>"
			dat += "<br/><span><b>Оставшееся время</b>: [current_timer ? round(timeleft(current_timer) * 0.1, 2) : 0.0]</span>"
		else
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=stairs'>Разблокировать/Заблокировать лестницу</a></div>"
			dat += "<div align='center'><a href='?src=[REF(src)];blastdoors=elevator'>Разблокировать/Заблокировать лифт</a></div>"

	else
		dat += "<div align='center'><a href='?src=[REF(src)];generate=1'>Запустить программу</a></div>"
		dat += "<br/>"
		dat += "<hr/>"
		dat += "<div align='center'><h2>Статус</h2></div>"

		var/message = "Ошибка"
		if(completed_segments >= total_segments)
			message = "Коды сгенерированны. Запустите программу для разблокировки."
		else if(current_timer || working)
			message = "Программа запущена"
		else if(completed_segments == 0)
			message = "Ожидание"
		else if(completed_segments < total_segments)
			message = "Требуется перезапуск. Пожалуйста перезапустите программу"
		else
			message = "Неизвестно"

		var/progress = round((completed_segments / total_segments) * 100)

		dat += "<br/><span><b>Прогресс</b>: [progress]%</span>"
		dat += "<br/><span><b>Оставшееся время</b>: [current_timer ? round(timeleft(current_timer) * 0.1, 2) : 0.0]</span>"
		dat += "<br/><span><b>Сообщение</b>: [message]</span>"

		var/flair = ""
		for(var/i = 1 to completed_segments)
			flair += "[technobabble[i]]<br/>"

		dat += "<br/><br/><span style='font-family: monospace, monospace;'>[flair]</span>"

	dat += "<div align='center'><h1>(C) W-Y General Security Systems</h1></div>"

	show_browser(user, dat, "Security Floor Controller", "security_blocker", "size=600x700")
	onclose(user, "security_blocker")

/obj/structure/machinery/computer/security_blocker/Topic(href, href_list)
	if(..())
		return

	add_fingerprint(usr)

	if(href_list["blastdoors"])
		var/stairs = locked["stairs"]
		var/elevator = locked["elevator"]
		switch(href_list["blastdoors"])
			if("stairs")
				if(!elevator)
					for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B as anything  in stairs_doors)
						if(stairs)
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
						else
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, close))

					locked["stairs"] = !locked["stairs"]
					to_chat(usr, SPAN_WARNING("Лестница [locked["elevator"] ? "раз" : "за"]блокирована."))
				else
					to_chat(usr, SPAN_WARNING("Блокировка лифта не допускает блокировку лестницы!"))
					return
			if("elevator")
				if(!stairs)
					for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B as anything in elevator_doors)
						if(elevator)
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
						else
							INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, close))

					locked["elevator"] = !locked["elevator"]
					to_chat(usr, SPAN_WARNING("Лифт [locked["elevator"] ? "раз" : "за"]блокирован."))
				else
					to_chat(usr, SPAN_WARNING("Блокировка лестницы не допускает блокировку лифта!"))
					return
			if("unlock")
				for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B as anything in stairs_doors + elevator_doors + move_lock_doors)
					if(B.density)
						INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
					locked["stairs"] = FALSE
					locked["elevator"] = FALSE

		current_timer = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, process)), segment_time)

	else if(href_list["generate"])
		if(working || current_timer)
			to_chat(usr, SPAN_WARNING("Программа восстановления уже запущена."))
			return

		if(security_protocol && completed_segments == total_segments)
			working = FALSE
			usr.visible_message("[usr] запустил программу для разблокировки консоли.", "Вы запустили программу для разблокировки консоли.")
			if(!do_after(usr, round(generate_time/5), INTERRUPT_ALL, BUSY_ICON_HOSTILE))
				working = TRUE
				return

			unlock_floor()
			return

		working = TRUE
		addtimer(VARSET_CALLBACK(src, working, FALSE), segment_time)

		usr.visible_message("[usr] запустил программу для восстановления консоли.", "Вы запустили программу для восстановления консоли.")
		if(!do_after(usr, segment_time, INTERRUPT_ALL, BUSY_ICON_HOSTILE, CALLBACK(src, TYPE_PROC_REF(/datum, process))))
			working = FALSE
			return

		current_timer = addtimer(CALLBACK(src, PROC_REF(complete_segment)), generate_time, TIMER_STOPPABLE)

	updateUsrDialog()

/obj/structure/machinery/computer/security_blocker/proc/complete_segment()
	playsound(src, 'sound/machines/ping.ogg', 25, 1)
	deltimer(current_timer)
	current_timer = null
	completed_segments = min(completed_segments + 1, total_segments)

	if(completed_segments == total_segments)
		visible_message(SPAN_NOTICE("[src] beeps as it ready to generate code."))
		return
	visible_message(SPAN_NOTICE("[src] beeps as it program requires attention."))

/obj/structure/machinery/computer/security_blocker/proc/unlock_floor()
	elevator.disabled_floors[z - elevator.floor_offset] = FALSE
	security_protocol = FALSE
	for(var/obj/structure/machinery/siren/S as anything in sirens)
		S.siren_warning_stop()
	for(var/obj/structure/machinery/light/double/almenia/L as anything in lights)
		L.change_almenia_state(0)
	for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B as anything in move_lock_doors)
		if(B.density)
			INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
	var/obj/structure/machinery/computer/security_blocker/parrent_blocker
	if((z - SSshuttle.sky_scraper_elevator.floor_offset) % 2 == 1)
		parrent_blocker = GLOB.skyscrapers_sec_comps["[z-1]"]
	else
		parrent_blocker = GLOB.skyscrapers_sec_comps["[z+1]"]
	for(var/obj/structure/machinery/door/poddoor/shutters/almayer/containment/skyscraper/B as anything in parrent_blocker.move_lock_doors)
		if(B.density)
			INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/structure/machinery/door, open))
	visible_message(SPAN_NOTICE("[src] beeps as it finishes generating code."))

/turf/closed/wall/vents
	name = "Vents"
	desc = "Wall with big vents"
	icon = 'icons/turf/vent.dmi'
	icon_state = "vent"
// 0 open, 1 closed, 2 welded, 3 broken
	var/state = 0
	var/welding_stage = 0
	var/pressure = 0
	var/max_pressure = 10000

/turf/closed/wall/vents/update_icon()
	return FALSE

/turf/closed/wall/vents/can_be_dissolved()
	return FALSE

/turf/closed/wall/vents/thermitemelt()
	return FALSE

/turf/closed/wall/vents/dismantle_wall()
	state = 3
	icon_state = "vent_broken"

/turf/closed/wall/vents/attackby(obj/item/attacking_item, mob/user)
	if(!ishuman(user) && !isrobot(user))
		to_chat(user, SPAN_WARNING("You don't have the dexterity to do this!"))
		return

	if(state > 1)
		return
	else if(HAS_TRAIT(attacking_item, TRAIT_TOOL_CROWBAR))
		to_chat(user, SPAN_WARNING("You start [state ? "opening" : "closing"] vents with your [attacking_item]."))
		if(!do_after(user, 10 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD, numticks = 3) || state > 1)
			to_chat(user, SPAN_WARNING("You stop [state ? "opening" : "closing"] vents with your [attacking_item]."))
			return FALSE
		to_chat(user, SPAN_WARNING("You [state ? "opened" : "closed"] vents."))
		state = !state
	else if(istype(attacking_item, /obj/item/stack/sheet/metal) && welding_stage == 0)
		if(!skillcheck(user, SKILL_ENGINEER, SKILL_ENGINEER_ENGI))
			to_chat(user, SPAN_WARNING("You do not understand how to do it [src]."))
			return FALSE
		var/obj/item/stack/sheet/metal/metal = attacking_item
		to_chat(user, SPAN_NOTICE("You start to reinforce \the [src]."))
		if(!do_after(user, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD, numticks = 3))
			to_chat(user, SPAN_WARNING("You stop reinforcing \the [src]."))
			return FALSE
		if(!metal || !metal.use(40))
			to_chat(user, SPAN_WARNING("You need a 40 sheets of metal to reinforce."))
			return FALSE
		to_chat(user, SPAN_NOTICE("You reinforced \the [src]."))
		welding_stage++
		return TRUE
	else if(istype(attacking_item, /obj/item/stack/sheet/plasteel) && welding_stage == 1)
		if(!skillcheck(user, SKILL_ENGINEER, SKILL_ENGINEER_ENGI))
			to_chat(user, SPAN_WARNING("You do not understand how to do it [src]."))
			return FALSE
		var/obj/item/stack/sheet/plasteel/plasteel = attacking_item
		to_chat(user, SPAN_NOTICE("You start to reinforce \the [src]."))
		if(!do_after(user, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD, numticks = 3))
			to_chat(user, SPAN_WARNING("You stop reinforcing \the [src]."))
			return FALSE
		if(!plasteel || !plasteel.use(10))
			to_chat(user, SPAN_WARNING("You need a 10 sheets of plasteel to reinforce."))
			return FALSE
		to_chat(user, SPAN_NOTICE("You reinforced \the [src]."))
		welding_stage++
		return TRUE
	else if(iswelder(attacking_item) && welding_stage == 2)
		if(!HAS_TRAIT(attacking_item, TRAIT_TOOL_BLOWTORCH))
			to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
			return
		var/obj/item/tool/weldingtool/weldingtool = attacking_item
		if(!weldingtool.isOn())
			to_chat(user, SPAN_WARNING("\The [weldingtool] needs to be on!"))
			return
		playsound(src, 'sound/items/Welder.ogg', 25, 1)
		if(!do_after(user, 10 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD, numticks = 3) || state > 1)
			to_chat(user, SPAN_WARNING("You stop welding \the [src]."))
			return FALSE
		if(!weldingtool || !weldingtool.isOn())
			return
		to_chat(user, SPAN_NOTICE("You welded vent."))
		welding_stage++
		state = 2

/turf/closed/wall/vents/proc/spread_smoke(transfer_pressure, datum/cause_data/cause_data)
	var/turf/closed/wall/vents/above = SSmapping.get_turf_above(src)
	if(state == 1)
		if(istype(above) && max_pressure - pressure + above.max_pressure - above.pressure > transfer_pressure)
			pressure += transfer_pressure
			if(pressure > max_pressure)
				above.spread_smoke(pressure - max_pressure, cause_data)
				pressure = max_pressure
			return
		pressure += transfer_pressure
		playsound(src, 'sound/items/Welder.ogg', 25, 1)
		state = 0
		icon_state = "vent"

	var/obj/effect/particle_effect/smoke/chlor/foundsmoke = locate() in get_turf(src)
	if(!foundsmoke)
		foundsmoke = new(src, transfer_pressure, cause_data)
		foundsmoke.setDir(pick(GLOB.cardinals))
		foundsmoke.spread_smoke()
	else
		foundsmoke.amount = foundsmoke.amount + transfer_pressure
		foundsmoke.spread_smoke()
		pressure = foundsmoke.amount
		if(pressure > max_pressure)
			if(istype(above))
				above.spread_smoke(pressure*0.5, cause_data)
				foundsmoke.smoke_action_in(above)

/////////////////////////////////////////
// CHLOR SMOKE
/////////////////////////////////////////

/obj/effect/particle_effect/smoke/chlor
	color = "#c6d89e"
	opacity = FALSE
	spread_speed = 5
	smokeranking = SMOKE_RANK_CHLOR

/obj/effect/particle_effect/smoke/chlor/process()
	amount--
	if(amount <= 0)
		qdel(src)
		return

	apply_smoke_effect(get_turf(src))

/obj/effect/particle_effect/smoke/chlor/spread_smoke(direction)
	set waitfor = FALSE
	sleep(spread_speed)
	if(QDELETED(src))
		return
	var/turf/own_turf = get_turf(src)
	if(!own_turf)
		return
	for(var/next_direction in GLOB.cardinals)
		if(direction && next_direction != direction)
			continue
		if(amount < 20)
			return
		var/turf/acting_turf = get_step(own_turf, next_direction)
		if(check_airblock(own_turf, acting_turf)) //smoke can't spread that way
			continue
		smoke_action_in(acting_turf)

/obj/effect/particle_effect/smoke/chlor/proc/smoke_action_in(turf/acting_turf)
	var/obj/effect/particle_effect/smoke/foundsmoke = locate() in acting_turf
	if(foundsmoke)
		if(foundsmoke.smokeranking <= smokeranking)
			qdel(foundsmoke)
		else if(foundsmoke.smokeranking == smokeranking && foundsmoke.amount + 10 < amount)
			foundsmoke.amount += 10
			amount -= 10
			if(foundsmoke.amount > 0)
				foundsmoke.spread_smoke()
			return

	var/obj/effect/particle_effect/smoke/S = new type(acting_turf, 10, cause_data)
	amount -= 10
	S.setDir(pick(GLOB.cardinals))
	if(S.amount > 0)
		S.spread_smoke()

/obj/effect/particle_effect/smoke/chlor/Crossed(mob/living/carbon/target as mob)
	return

/obj/effect/particle_effect/smoke/chlor/affect(mob/living/carbon/target)
	..()

	if(target.stat == DEAD)
		return

	if(istype(target.wear_mask, /obj/item/clothing/mask/gas))
		if(prob(20))
			to_chat(target, SPAN_DANGER("You're having trouble breathing, but you're breathing in fresh air"))
		return

	target.last_damage_data = cause_data
	target.apply_damage(5, OXY) //Basic oxyloss from "can't breathe"
	if(target.coughedtime != 1 && !target.stat && ishuman(target)) //Coughing/gasping
		target.coughedtime = 1
		if(prob(50))
			target.emote("cough")
		else
			target.emote("gasp")
		addtimer(VARSET_CALLBACK(target, coughedtime, 0), 1.5 SECONDS)

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_armoured_damage(amount*rand(5, 10), ARMOR_BIO, BURN) //Burn damage, randomizes between various parts //Amount corresponds to upgrade level, 1 to 2.5
	else
		target.burn_skin(5) //Failsafe for non-humans

	target.updatehealth()
