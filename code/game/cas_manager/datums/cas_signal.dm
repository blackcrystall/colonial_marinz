/datum/cas_signal
	var/signal_loc
	var/name = "Unknown Electronic Signal"
	var/target_id = 0
	var/obj/structure/machinery/camera/cas/linked_cam
	var/z_initial

/datum/cas_signal/New(location)
	z_initial = z_descend(location)
	signal_loc = location

/datum/cas_signal/Destroy()
	QDEL_NULL(linked_cam)
	signal_loc = null
	. = ..()

/datum/cas_signal/proc/get_name()
	var/area/laser_area = get_area(signal_loc)
	var/obstructed = obstructed_signal() ? "OBSTRUCTED" : ""
	if(laser_area)
		return "[name] ([laser_area.name]) [obstructed]"
	return "[name] [obstructed]"

//prevents signal from being triggered from pockets. It has to be on turf
/datum/cas_signal/proc/valid_signal()
	var/obj/object = signal_loc
	var/new_z = z_descend(signal_loc)
	return istype(object) && istype(object.loc, /turf/) && obstructed_signal() && new_z == z_initial

/datum/cas_signal/proc/obstructed_signal()
	var/turf/laser_turf = get_turf(signal_loc)
	var/turf/roof = laser_turf.get_real_roof()
	return roof.air_strike(10, laser_turf, TRUE)

/proc/z_descend(loc)
	var/sloc = loc
	while(sloc && !sloc:z)
		sloc = sloc:loc
	if(!sloc)
		return null
	return sloc:z
