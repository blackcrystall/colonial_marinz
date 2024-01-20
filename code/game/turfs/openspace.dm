GLOBAL_DATUM_INIT(openspace_backdrop_one_for_all, /atom/movable/openspace_backdrop, new)

/atom/movable/openspace_backdrop
	name = "openspace_backdrop"
	anchored = TRUE
	icon = 'icons/turf/open_space.dmi'
	icon_state = "grey"
	plane = OPENSPACE_BACKDROP_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	alpha = 50

/turf/open/space/openspace
	icon = 'icons/turf/open_space.dmi'
	icon_state = "invisible"
	turf_flags = TURF_MULTIZ|TURF_WEATHER_PROOF
	baseturfs = /turf/open/openspace
	antipierce = 0

/turf/open/space/openspace/Initialize(mapload) // handle plane and layer here so that they don't cover other obs/turfs in Dream Maker
	. = ..()
	overlays += GLOB.openspace_backdrop_one_for_all //Special grey square for projecting backdrop darkness filter on it.
	icon_state = "invisible"
	return INITIALIZE_HINT_LATELOAD

/turf/open/space/openspace/LateInitialize()
	. = ..()
	AddElement(/datum/element/turf_z_transparency, is_openspace = TRUE)

/turf/open/space/openspace/ex_act(severity, explosion_direction)
	return

/turf/open/space/openspace/zPassIn(atom/movable/A, direction, turf/source)
	if(direction == DOWN)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_IN_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_IN_UP)
				return FALSE
		return TRUE
	return FALSE

/turf/open/space/openspace/zPassOut(atom/movable/A, direction, turf/destination, allow_anchored_movement)
	if(A.anchored && !allow_anchored_movement)
		return FALSE
	if(direction == DOWN)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_OUT_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_OUT_UP)
				return FALSE
		return TRUE
	return FALSE


/turf/open/openspace
	icon = 'icons/turf/open_space.dmi'
	name = "open space"
	desc = "Watch your step!"
	icon_state = "invisible"
	turf_flags = TURF_MULTIZ|TURF_WEATHER_PROOF
	weedable = NOT_WEEDABLE
	baseturfs = /turf/open/openspace
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	antipierce = 0

/turf/open/openspace/Initialize(mapload) // handle plane and layer here so that they don't cover other obs/turfs in Dream Maker
	. = ..()
	overlays += GLOB.openspace_backdrop_one_for_all //Special grey square for projecting backdrop darkness filter on it.
	return INITIALIZE_HINT_LATELOAD

/turf/open/openspace/LateInitialize()
	. = ..()
	AddElement(/datum/element/turf_z_transparency, is_openspace = TRUE)

/**
 * Prepares a moving movable to be precipitated if Move() is successful.
 * This is done in Enter() and not Entered() because there's no easy way to tell
 * if the latter was called by Move() or forceMove() while the former is only called by Move().
 */
/turf/open/openspace/Enter(atom/movable/movable, atom/oldloc)
	. = ..()
	if(.)
		//higher priority than CURRENTLY_Z_FALLING so the movable doesn't fall on Entered()
		movable.set_currently_z_moving(CURRENTLY_Z_FALLING_FROM_MOVE)
		return .

///Makes movables fall when forceMove()'d to this turf.
/turf/open/openspace/Entered(atom/movable/movable)
	. = ..()
	if(.)
		if(movable.set_currently_z_moving(CURRENTLY_Z_FALLING))
			zFall(movable, falling_from_move = TRUE)
		return .
/**
 * Drops movables spawned on this turf only after they are successfully initialized.
 * so flying mobs, qdeleted movables and things that were moved somewhere else during
 * Initialize() won't fall by accident.
 */
/turf/open/openspace/on_atom_created(atom/created_atom)
	if(ismovable(created_atom))
		//Drop it only when it's finished initializing, not before.
		addtimer(CALLBACK(src, PROC_REF(zfall_if_on_turf), created_atom), 0 SECONDS)

/turf/open/openspace/proc/zfall_if_on_turf(atom/movable/movable)
	if(QDELETED(movable) || movable.loc != src)
		return
	zFall(movable)

/turf/open/openspace/zPassIn(atom/movable/A, direction, turf/source)
	if(direction == DOWN)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_IN_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_IN_UP)
				return FALSE
		return TRUE
	return FALSE

/turf/open/openspace/zPassOut(atom/movable/A, direction, turf/destination, allow_anchored_movement)
	if(A.anchored && !allow_anchored_movement)
		return FALSE
	if(direction == DOWN)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_OUT_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/contained_object in contents)
			if(contained_object.flags_obj & OBJ_BLOCK_Z_OUT_UP)
				return FALSE
		return TRUE
	return FALSE
