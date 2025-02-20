

/*
AIR ALARM ITEM
Handheld air alarm frame, for placing on walls
Code shamelessly copied from apc_frame
*/
/obj/item/frame/air_alarm
	name = "air alarm frame"
	desc = "Used for building Air Alarms"
	icon = 'icons/obj/structures/machinery/monitors.dmi'
	icon_state = "alarm_bitem"
	flags_atom = FPRINT|CONDUCT

/obj/item/frame/air_alarm/attackby(obj/item/W as obj, mob/user as mob)
	if(HAS_TRAIT(W, TRAIT_TOOL_WRENCH))
		new /obj/item/stack/sheet/metal( get_turf(src.loc), 2 )
		qdel(src)
		return
	..()

/obj/item/frame/air_alarm/proc/try_build(turf/on_wall)
	if(get_dist(on_wall,usr)>1)
		return

	var/ndir = get_dir(on_wall,usr)
	if(!(ndir in  GLOB.cardinals))
		return

	var/turf/loc = get_turf(usr)
	var/area/A = loc.loc
	if(!istype(loc, /turf/open/floor))
		to_chat(usr, SPAN_DANGER("Air Alarm cannot be placed on this spot."))
		return
	if(A.requires_power == 0 || A.name == "Space")
		to_chat(usr, SPAN_DANGER("Air Alarm cannot be placed in this area."))
		return

	if(gotwallitem(loc, ndir))
		to_chat(usr, SPAN_DANGER("There's already an item on this wall!"))
		return

	new /obj/structure/machinery/alarm(loc, ndir, 1)
	qdel(src)

/*
FIRE ALARM ITEM
Handheld fire alarm frame, for placing on walls
Code shamelessly copied from apc_frame
*/
/obj/item/frame/fire_alarm
	name = "fire alarm frame"
	desc = "Used for building Fire Alarms"
	icon = 'icons/obj/structures/machinery/monitors.dmi'
	icon_state = "fire_bitem"
	flags_atom = FPRINT|CONDUCT

/obj/item/frame/fire_alarm/attackby(obj/item/W as obj, mob/user as mob)
	if(HAS_TRAIT(W, TRAIT_TOOL_WRENCH))
		new /obj/item/stack/sheet/metal( get_turf(src.loc), 2 )
		qdel(src)
		return
	..()

/obj/item/frame/fire_alarm/proc/try_build(turf/on_wall)
	if(get_dist(on_wall,usr)>1)
		return

	var/ndir = get_dir(on_wall,usr)
	if(!(ndir in  GLOB.cardinals))
		return

	var/turf/loc = get_turf(usr)
	var/area/A = loc.loc
	if(!istype(loc, /turf/open/floor))
		to_chat(usr, SPAN_DANGER("Fire Alarm cannot be placed on this spot."))
		return
	if(A.requires_power == 0 || A.name == "Space")
		to_chat(usr, SPAN_DANGER("Fire Alarm cannot be placed in this area."))
		return

	if(gotwallitem(loc, ndir))
		to_chat(usr, SPAN_DANGER("There's already an item on this wall!"))
		return

	new /obj/structure/machinery/firealarm(loc, ndir, 1)

	qdel(src)
