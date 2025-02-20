/mob/living/silicon/ai/var/max_locations = 10
/mob/living/silicon/ai/var/stored_locations[0]

/mob/living/silicon/ai/proc/InvalidTurf(turf/T as turf)
	if(!T)
		return 1
	if(is_admin_level(T.z))
		return 1
	if(T.z > 6)
		return TRUE
	return FALSE

/mob/living/silicon/ai/proc/get_camera_list()

	if(src.stat == 2)
		return

	var/list/L = list()
	for (var/obj/structure/machinery/camera/C in cameranet.cameras)
		L.Add(C)

	camera_sort(L)

	var/list/T = list()
	T["Cancel"] = "Cancel"
	for (var/obj/structure/machinery/camera/C in L)
		T[text("[][]", C.c_tag, (C.can_use() ? null : " (Deactivated)"))] = C

	track = new()
	track.cameras = T
	return T


/mob/living/silicon/ai/proc/ai_camera_list(camera in get_camera_list())
	set category = "AI Commands"
	set name = "Show Camera List"

	if(src.stat == 2)
		to_chat(src, "You can't list the cameras because you are dead!")
		return

	if(!camera || camera == "Cancel")
		return 0

	var/obj/structure/machinery/camera/C = track.cameras[camera]
	src.eyeobj.setLoc(C)

	return

/mob/living/silicon/ai/proc/ai_store_location(newloc as text)
	set category = "AI Commands"
	set name = "Store Camera Location"
	set desc = "Stores your current camera location by the given name"

	newloc = copytext(sanitize(loc), 1, MAX_MESSAGE_LEN)
	if(!newloc)
		to_chat(src, SPAN_DANGER("Must supply a location name"))
		return

	if(stored_locations.len >= max_locations)
		to_chat(src, SPAN_DANGER("Cannot store additional locations. Remove one first"))
		return

	if(newloc in stored_locations)
		to_chat(src, SPAN_DANGER("There is already a stored location by this name"))
		return

	var/L = src.eyeobj.getLoc()
	if(InvalidTurf(get_turf(L)))
		to_chat(src, SPAN_DANGER("Unable to store this location"))
		return

	stored_locations[newloc] = L
	to_chat(src, "Location '[newloc]' stored")

/mob/living/silicon/ai/proc/sorted_stored_locations()
	return sortList(stored_locations)

/mob/living/silicon/ai/proc/ai_goto_location(loc in sorted_stored_locations())
	set category = "AI Commands"
	set name = "Goto Camera Location"
	set desc = "Returns to the selected camera location"

	if(!(loc in stored_locations))
		to_chat(src, SPAN_DANGER("Location [loc] not found"))
		return

	var/L = stored_locations[loc]
	src.eyeobj.setLoc(L)

/mob/living/silicon/ai/proc/ai_remove_location(loc in sorted_stored_locations())
	set category = "AI Commands"
	set name = "Delete Camera Location"
	set desc = "Deletes the selected camera location"

	if(!(loc in stored_locations))
		to_chat(src, SPAN_DANGER("Location [loc] not found"))
		return

	stored_locations.Remove(loc)
	to_chat(src, "Location [loc] removed")

// Used to allow the AI is write in mob names/camera name from the CMD line.
/datum/trackable
	var/list/names = list()
	var/list/namecounts = list()
	var/list/humans = list()
	var/list/others = list()
	var/list/cameras = list()

/mob/living/silicon/ai/proc/trackable_mobs()

	if(usr.stat == 2)
		return list()

	var/datum/trackable/TB = new()
	for(var/i in GLOB.living_mob_list)
		var/mob/living/M = i
		// Easy checks first.
		// Don't detect mobs on Centcom. Since the wizard den is on Centcomm, we only need this.
		if(InvalidTurf(get_turf(M)))
			continue
		if(M == usr)
			continue
		if(M.invisibility)//cloaked
			continue

		// Human check
		var/human = 0
		if(istype(M, /mob/living/carbon/human))
			human = 1
			var/mob/living/carbon/human/H = M
			//Cameras can't track people wearing an agent card or a ninja hood.
			if(H.wear_id && istype(H.wear_id.GetID(), /obj/item/card/id/syndicate))
				continue

		// Now, are they viewable by a camera? (This is last because it's the most intensive check)
		if(!near_camera(M))
			continue

		var/name = M.name
		if(name in TB.names)
			TB.namecounts[name]++
			name = text("[] ([])", name, TB.namecounts[name])
		else
			TB.names.Add(name)
			TB.namecounts[name] = 1
		if(human)
			TB.humans[name] = M
		else
			TB.others[name] = M

	var/list/targets = sortList(TB.humans) + sortList(TB.others)
	src.track = TB
	return targets

/mob/living/silicon/ai/proc/ai_camera_track(target_name in trackable_mobs())
	set category = "AI Commands"
	set name = "Track With Camera"
	set desc = "Select who you would like to track."

	if(src.stat == 2)
		to_chat(src, "You can't track with camera because you are dead!")
		return
	if(!target_name)
		src.cameraFollow = null

	var/mob/target = (isnull(track.humans[target_name]) ? track.others[target_name] : track.humans[target_name])
	src.track = null
	ai_actual_track(target)

/mob/living/silicon/ai/proc/ai_cancel_tracking(forced = 0)
	if(!cameraFollow)
		return

	to_chat(src, "Follow camera mode [forced ? "terminated" : "ended"].")
	cameraFollow = null

/mob/living/silicon/ai/proc/ai_actual_track(mob/living/target as mob)
	if(!istype(target)) return
	var/mob/living/silicon/ai/U = usr

	U.cameraFollow = target
	//U << text("Now tracking [] on camera.", target.name)
	//if(U.interactee == null)
	//	U.set_interaction(U)
	to_chat(U, "Now tracking [target.name] on camera.")

	spawn (0)
		while (U.cameraFollow == target)
			if(U.cameraFollow == null)
				return
			if(istype(target, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = target
				if(H.wear_id && istype(H.wear_id.GetID(), /obj/item/card/id/syndicate))
					U.ai_cancel_tracking(1)
					return

			if(!near_camera(target))
				to_chat(U, "Target is not near any active cameras.")
				sleep(100)
				continue

			if(U.eyeobj)
				U.eyeobj.setLoc(get_turf(target), 0)
			else
				view_core()
				return
			sleep(10)

/proc/near_camera(mob/living/M)
	if(!isturf(M.loc))
		return 0
	if(isrobot(M))
		var/mob/living/silicon/robot/R = M
		if(!(R.camera && R.camera.can_use()) && !cameranet.checkCameraVis(M))
			return 0
	else if(!cameranet.checkCameraVis(M))
		return 0
	return 1

/obj/structure/machinery/camera/attack_remote(mob/living/silicon/ai/user as mob)
	if(!istype(user))
		return
	if(!src.can_use())
		return
	user.eyeobj.setLoc(get_turf(src))


/mob/living/silicon/ai/attack_remote(mob/user as mob)
	ai_camera_list()

/proc/camera_sort(list/L) // TODO: replace this bubblesort with a mergesort - spookydonut
	var/obj/structure/machinery/camera/a
	var/obj/structure/machinery/camera/b

	for (var/i = L.len, i > 0, i--)
		for (var/j = 1 to i - 1)
			a = L[j]
			b = L[j + 1]
			if(a.c_tag_order != b.c_tag_order)
				if(a.c_tag_order > b.c_tag_order)
					L.Swap(j, j + 1)
			else
				if(sorttext(a.c_tag, b.c_tag) < 0)
					L.Swap(j, j + 1)
	return L
