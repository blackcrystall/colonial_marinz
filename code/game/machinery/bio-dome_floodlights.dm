/obj/structure/machinery/hydro_floodlight_switch
	name = "Biodome Floodlight Switch"
	icon = 'icons/obj/structures/machinery/power.dmi'
	icon_state = "panelnopower"
	desc = "This switch controls the floodlights surrounding the archaeology complex. It only functions when there is power."
	density = FALSE
	anchored = TRUE
	var/ispowered = FALSE
	light_on = 0
	use_power = USE_POWER_IDLE
	unslashable = TRUE
	unacidable = TRUE
	var/list/floodlist = list() // This will save our list of floodlights on the map

/obj/structure/machinery/hydro_floodlight_switch/Initialize(mapload, ...)
	. = ..()
	for(var/obj/structure/machinery/hydro_floodlight/F in GLOB.machines)
		floodlist += F
		F.fswitch = src
	start_processing()

/obj/structure/machinery/hydro_floodlight_switch/Destroy()
	for(var/obj/structure/machinery/hydro_floodlight/floodlight as anything in floodlist)
		floodlight.fswitch = null
	floodlist = null
	return ..()


/obj/structure/machinery/hydro_floodlight_switch/process()
	var/lightpower = 0
	for(var/obj/structure/machinery/hydro_floodlight/H in floodlist)
		if(!H.light_on)
			continue
		lightpower += H.power_tick
	use_power(lightpower)

/obj/structure/machinery/hydro_floodlight_switch/update_icon()
	if(!ispowered)
		icon_state = "panelnopower"
	else if(light_on)
		icon_state = "panelon"
	else
		icon_state = "paneloff"

/obj/structure/machinery/hydro_floodlight_switch/power_change()
	..()
	if((stat & NOPOWER))
		if(ispowered && light_on)
			toggle_lights()
		ispowered = FALSE
		update_icon()
	else
		ispowered = TRUE
		update_icon()

/obj/structure/machinery/hydro_floodlight_switch/proc/toggle_lights()
	for(var/obj/structure/machinery/hydro_floodlight/F in floodlist)
		if(!istype(F) || QDELETED(F) || F.damaged) continue //Missing or damaged, skip it

		spawn(rand(0,50))
			F.set_light_on(!F.light_on)
			F.update_light()
			F.update_icon()
	return 0

/obj/structure/machinery/hydro_floodlight_switch/attack_hand(mob/user as mob)
	if(!ishuman(user))
		to_chat(user, "Nice try.")
		return 0
	if(!ispowered)
		to_chat(user, "Nothing happens.")
		return 0
	playsound(src,'sound/machines/click.ogg', 15, 1)
	use_power(5)
	toggle_lights()
	update_icon()
	return 1

/obj/structure/machinery/hydro_floodlight
	name = "Biodome Floodlight"
	icon = 'icons/obj/structures/machinery/big_floodlight.dmi'
	icon_state = "flood_s_off"
	density = TRUE
	anchored = TRUE
	layer = WINDOW_LAYER
	var/damaged = 0 //Can be smashed by xenos
	unslashable = TRUE
	unacidable = TRUE
	var/power_tick = 800 // power each floodlight takes up per process
	use_power = USE_POWER_NONE //It's the switch that uses the actual power, not the lights
	var/obj/structure/machinery/hydro_floodlight_switch/fswitch = null //Reverse lookup for power grabbing in area

	light_system = STATIC_LIGHT
	light_range = 7
	light_power = 1
	light_on = FALSE

/obj/structure/machinery/hydro_floodlight/Destroy()
	if(fswitch?.floodlist)
		fswitch.floodlist -= src
	fswitch = null
	return ..()

/obj/structure/machinery/hydro_floodlight/update_icon()
	if(damaged)
		icon_state = "flood_s_dmg"
	else if(light_on)
		icon_state = "flood_s_on"
	else
		icon_state = "flood_s_off"

/obj/structure/machinery/hydro_floodlight/attackby(obj/item/W as obj, mob/user as mob)
	var/obj/item/tool/weldingtool/WT = W
	if(istype(WT))
		if(!damaged) return
		if(!HAS_TRAIT(WT, TRAIT_TOOL_BLOWTORCH))
			to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
			return
		if(WT.remove_fuel(0, user))
			playsound(src.loc, 'sound/items/weldingtool_weld.ogg', 25)
			user.visible_message(SPAN_NOTICE("[user] starts welding [src]'s damage."), \
				SPAN_NOTICE("You start welding [src]'s damage."))
			if(do_after(user, 200 * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				playsound(get_turf(src), 'sound/items/Welder2.ogg', 25, 1)
				if(!src || !WT.isOn()) return
				damaged = 0
				user.visible_message(SPAN_NOTICE("[user] finishes welding [src]'s damage."), \
					SPAN_NOTICE("You finish welding [src]'s damage."))
				if(!light_on)
					set_light_on(TRUE)
					update_light()
				update_icon()
				return 1
		else
			to_chat(user, SPAN_WARNING("You need more welding fuel to complete this task."))
			return 0
	..()
	return 0

/obj/structure/machinery/hydro_floodlight/attack_hand(mob/user as mob)
	if(ishuman(user))
		to_chat(user, SPAN_WARNING("Nothing happens. Looks like it's powered elsewhere."))
		return 0
	else if(!light_on)
		to_chat(user, SPAN_WARNING("Why bother? It's just some weird metal thing."))
		return 0
	else
		if(damaged)
			to_chat(user, SPAN_WARNING("It's already damaged."))
			return 0
		else
			if(islarva(user))
				return //Larvae can't do shit
			if(user.get_active_hand())
				to_chat(user, SPAN_WARNING("You need your claws empty for this!"))
				return FALSE
			user.visible_message(SPAN_DANGER("[user] starts to slash and claw away at [src]!"),
			SPAN_DANGER("You start slashing and clawing at [src]!"))
			if(do_after(user, 50, INTERRUPT_ALL, BUSY_ICON_HOSTILE) && !damaged) //Not when it's already damaged.
				if(!src) return 0
				damaged = 1
				set_light_on(FALSE)
				update_light()
				user.visible_message(SPAN_DANGER("[user] slashes up [src]!"),
				SPAN_DANGER("You slash up [src]!"))
				playsound(src, 'sound/weapons/blade1.ogg', 25, 1)
				update_icon()
				return 0
	..()
