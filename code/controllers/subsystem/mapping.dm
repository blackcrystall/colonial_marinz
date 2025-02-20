SUBSYSTEM_DEF(mapping)
	name = "Mapping"
	init_order = SS_INIT_MAPPING
	flags = SS_NO_FIRE

	var/list/datum/map_config/configs
	var/list/datum/map_config/next_map_configs

	///Name of all maps
	var/list/map_templates = list()
	///Name of all shuttles
	var/list/shuttle_templates = list()
	var/list/all_shuttle_templates = list()
	///map_id of all tents
	var/list/tent_type_templates = list()

	var/list/areas_in_z = list()

	var/list/turf/unused_turfs = list() //Not actually unused turfs they're unused but reserved for use for whatever requests them. "[zlevel_of_turf]" = list(turfs)
	var/list/datum/turf_reservations //list of turf reservations
	var/list/used_turfs = list() //list of turf = datum/turf_reservation

	var/list/reservation_ready = list()
	var/clearing_reserved_turfs = FALSE

	/// True when in the process of adding a new Z-level, global locking
	var/adding_new_zlevel = FALSE

	//Z-manager stuff
	var/ground_start // should only be used for maploading-related tasks
	var/list/z_list
	///list of all z level indices that form multiz connections and whether theyre linked up or down.
	///list of lists, inner lists are of the form: list("up or down link direction" = TRUE)
	var/datum/space_level/transit
	var/num_of_res_levels = 1

	/// list of traits and their associated z leves
	var/list/z_trait_levels = list()

//dlete dis once #39770 is resolved
/datum/controller/subsystem/mapping/proc/HACK_LoadMapConfig()
	configs = load_map_configs(ALL_MAPTYPES, error_if_missing = FALSE)
	world.name = "[CONFIG_GET(string/title)] - [SSmapping.configs[SHIP_MAP].map_name]"

/datum/controller/subsystem/mapping/Initialize(timeofday)
	if(!configs)
		HACK_LoadMapConfig()
	if(initialized)
		return SS_INIT_SUCCESS

	for(var/i in ALL_MAPTYPES)
		var/datum/map_config/MC = configs[i]
		if(MC.defaulted)
			var/old_config = configs[i]
			configs[i] = global.config.defaultmaps[i]
			if(!configs || configs[i].defaulted)
				to_chat(world, SPAN_BOLDANNOUNCE("Unable to load next or default map config, defaulting."))
				configs[i] = old_config

	loadWorld()
	repopulate_sorted_areas()
	preloadTemplates()
	// Add the transit level
	transit = add_new_zlevel("Transit/Reserved", list(ZTRAIT_RESERVED = TRUE))
	initialize_reserved_level(transit.z_value)
	repopulate_sorted_areas()
	for(var/maptype as anything in configs)
		var/datum/map_config/MC = configs[maptype]
		if(MC.perf_mode)
			GLOB.perf_flags |= MC.perf_mode
	return SS_INIT_SUCCESS

/// Takes a z level datum, and tells the mapping subsystem to manage it
/// Also handles things like plane offset generation, and other things that happen on a z level to z level basis
/datum/controller/subsystem/mapping/proc/manage_z_level(datum/space_level/new_z)
	// First, add the z
	z_list += new_z

/datum/controller/subsystem/mapping/proc/wipe_reservations(wipe_safety_delay = 100)
	if(clearing_reserved_turfs || !initialized) //in either case this is just not needed.
		return
	clearing_reserved_turfs = TRUE
	message_admins("Clearing dynamic reservation space.")
	do_wipe_turf_reservations()
	clearing_reserved_turfs = FALSE

/datum/controller/subsystem/mapping/Recover()
	flags |= SS_NO_INIT
	initialized = SSmapping.initialized
	map_templates = SSmapping.map_templates
	unused_turfs = SSmapping.unused_turfs
	turf_reservations = SSmapping.turf_reservations
	used_turfs = SSmapping.used_turfs

	configs = SSmapping.configs
	next_map_configs = SSmapping.next_map_configs

	clearing_reserved_turfs = SSmapping.clearing_reserved_turfs

	z_list = SSmapping.z_list

/datum/controller/subsystem/mapping/proc/LoadGroup(list/errorList, name, path, files, list/traits, list/default_traits, silent = FALSE, override_map_path = "maps/")
	. = list()
	var/start_time = REALTIMEOFDAY

	if(!islist(files))  // handle single-level maps
		files = list(files)

	// check that the total z count of all maps matches the list of traits
	var/total_z = 0
	var/list/parsed_maps = list()
	for (var/file in files)
		var/full_path = "[override_map_path]/[path]/[file]"
		var/datum/parsed_map/pm = new(file(full_path))
		var/bounds = pm?.bounds
		if(!bounds)
			errorList |= full_path
			continue
		parsed_maps[pm] = total_z  // save the start Z of this file
		total_z += bounds[MAP_MAXZ] - bounds[MAP_MINZ] + 1

	if(!length(traits))  // null or empty - default
		for(var/i in 1 to total_z)
			traits += list(default_traits)
	else if(total_z != traits.len)  // mismatch
		INIT_ANNOUNCE("WARNING: [traits.len] trait sets specified for [total_z] z-levels in [path]!")
		if(total_z < traits.len)  // ignore extra traits
			traits.Cut(total_z + 1)
		if(total_z > traits.len)
			traits = list()
			while(total_z > traits.len)  // fall back to defaults on extra levels
				traits += list(default_traits)

	// preload the relevant space_level datums
	var/start_z = world.maxz + 1
	var/i = 0
	for(var/level in traits)
		add_new_zlevel("[name][i ? " [i + 1]" : ""]", level)
		++i

	// load the maps
	for (var/datum/parsed_map/pm as anything in parsed_maps)
		var/cur_z = start_z + parsed_maps[pm]
		if(!pm.load(1, 1, cur_z, no_changeturf = TRUE))
			errorList |= pm.original_path
		if(istype(z_list[cur_z], /datum/space_level))
			var/datum/space_level/cur_level = z_list[cur_z]
			cur_level.x_bounds = pm.bounds[MAP_MAXX]
			cur_level.y_bounds = pm.bounds[MAP_MAXY]
	if(!silent)
		INIT_ANNOUNCE("Загружено [name] за [(REALTIMEOFDAY - start_time)/10] секунд!")
	return parsed_maps

/datum/controller/subsystem/mapping/proc/Loadship(list/errorList, name, path, files, list/traits, list/default_traits, silent = FALSE, override_map_path = "maps/")
	LoadGroup(errorList, name, path, files, traits, default_traits, silent, override_map_path = override_map_path)

/datum/controller/subsystem/mapping/proc/Loadground(list/errorList, name, path, files, list/traits, list/default_traits, silent = FALSE, override_map_path = "maps/")
	LoadGroup(errorList, name, path, files, traits, default_traits, silent, override_map_path = override_map_path)

/datum/controller/subsystem/mapping/proc/loadWorld()
	//if any of these fail, something has gone horribly, HORRIBLY, wrong
	var/list/FailedZs = list()

	// ensure we have space_level datums for compiled-in maps
	InitializeDefaultZLevels()

	// load the ground level
	ground_start = world.maxz + 1

	var/datum/map_config/ground_map = configs[GROUND_MAP]
	INIT_ANNOUNCE("Загружается [ground_map.map_name]...")
	var/ground_base_path = "maps/"
	if(ground_map.override_map)
		ground_base_path = "data/"
	Loadground(FailedZs, ground_map.map_name, ground_map.map_path, ground_map.map_file, ground_map.traits, ZTRAITS_GROUND, override_map_path = ground_base_path)

	if(!ground_map.disable_ship_map && !MODE_HAS_FLAG(MODE_NO_SHIP_MAP))
		var/datum/map_config/ship_map = configs[SHIP_MAP]
		var/ship_base_path = "maps/"
		if(ship_map.override_map)
			ship_base_path = "data/"
		INIT_ANNOUNCE("Загружается [ship_map.map_name]...")
		Loadship(FailedZs, ship_map.map_name, ship_map.map_path, ship_map.map_file, ship_map.traits, ZTRAITS_MAIN_SHIP, override_map_path = ship_base_path)

	if(length(FailedZs)) //but seriously, unless the server's filesystem is messed up this will never happen
		var/msg = "RED ALERT! The following map files failed to load: [FailedZs[1]]"
		if(FailedZs.len > 1)
			for(var/I in 2 to FailedZs.len)
				msg += ", [FailedZs[I]]"
		msg += ". Yell at your server host!"
		INIT_ANNOUNCE(msg)

/datum/controller/subsystem/mapping/proc/changemap(datum/map_config/VM, maptype = GROUND_MAP)
	LAZYINITLIST(next_map_configs)
	if(maptype == GROUND_MAP)
		if(!VM.MakeNextMap(maptype))
			next_map_configs[GROUND_MAP] = load_map_configs(list(maptype), default = TRUE)
			message_admins("Failed to set new map with next_map.json for [VM.map_name]! Using default as backup!")
			return

		next_map_configs[GROUND_MAP] = VM
		return TRUE

	else if(maptype == SHIP_MAP)
		if(!VM.MakeNextMap(maptype))
			next_map_configs[SHIP_MAP] = load_map_configs(list(maptype), default = TRUE)
			message_admins("Failed to set new map with next_map.json for [VM.map_name]! Using default as backup!")
			return

		next_map_configs[SHIP_MAP] = VM
		return TRUE

/datum/controller/subsystem/mapping/proc/preloadTemplates(path = "maps/templates/") //see master controller setup
	var/list/filelist = flist(path)
	for(var/map in filelist)
		var/datum/map_template/T = new(path = "[path][map]", rename = "[map]")
		map_templates[T.name] = T

	preloadShuttleTemplates()

/proc/generateMapList(filename)
	. = list()
	var/list/Lines = file2list(filename)

	if(!Lines.len)
		return
	for (var/t in Lines)
		if(!t)
			continue

		t = trim(t)
		if(length(t) == 0)
			continue
		else if(t[1] == "#")
			continue

		var/pos = findtext(t, " ")
		var/name = null

		if(pos)
			name = lowertext(copytext(t, 1, pos))

		else
			name = lowertext(t)

		if(!name)
			continue

		. += t

/datum/controller/subsystem/mapping/proc/preloadShuttleTemplates()
	for(var/item in subtypesof(/datum/map_template/shuttle))
		var/datum/map_template/shuttle/shuttle_type = item

		var/datum/map_template/shuttle/S = new shuttle_type()

		shuttle_templates[S.shuttle_id] = S
		all_shuttle_templates[item] = S
		map_templates[S.shuttle_id] = S

/datum/controller/subsystem/mapping/proc/preload_tent_templates()
	for(var/template in subtypesof(/datum/map_template/tent))
		var/datum/map_template/tent/new_tent = new template()
		tent_type_templates[new_tent.map_id] = new_tent

/datum/controller/subsystem/mapping/proc/RequestBlockReservation(width, height, z, type = /datum/turf_reservation, turf_type_override)
	UNTIL(initialized && !clearing_reserved_turfs)
	var/datum/turf_reservation/reserve = new type
	if(turf_type_override)
		reserve.turf_type = turf_type_override
	if(!z)
		for(var/i in levels_by_trait(ZTRAIT_RESERVED))
			if(reserve.Reserve(width, height, i))
				return reserve
		//If we didn't return at this point, theres a good chance we ran out of room on the exisiting reserved z levels, so lets try a new one
		log_debug("Ran out of space in existing transit levels, adding a new one")
		num_of_res_levels++
		var/datum/space_level/newReserved = add_new_zlevel("Transit/Reserved [num_of_res_levels]", list(ZTRAIT_RESERVED = TRUE))
		initialize_reserved_level(newReserved.z_value)
		for(var/i in levels_by_trait(ZTRAIT_RESERVED))
			if(reserve.Reserve(width, height, i))
				return reserve
		CRASH("Despite adding a fresh reserved zlevel still failed to get a reservation")
	else
		if(!level_trait(z, ZTRAIT_RESERVED))
			log_debug("Cannot block reserve on a non-ZTRAIT_RESERVED level")
			qdel(reserve)
			return
		else
			if(reserve.Reserve(width, height, z))
				return reserve
	log_debug("unknown reservation failure")
	QDEL_NULL(reserve)

//This is not for wiping reserved levels, use wipe_reservations() for that.
/datum/controller/subsystem/mapping/proc/initialize_reserved_level(z)
	UNTIL(!clearing_reserved_turfs) //regardless, lets add a check just in case.
	clearing_reserved_turfs = TRUE //This operation will likely clear any existing reservations, so lets make sure nothing tries to make one while we're doing it.
	if(!level_trait(z, ZTRAIT_RESERVED))
		clearing_reserved_turfs = FALSE
		CRASH("Invalid z level prepared for reservations.")
	var/turf/A = get_turf(locate(8,8,z))
	var/turf/B = get_turf(locate(world.maxx - 8,world.maxy - 8,z))
	var/block = block(A, B)
	for(var/t in block)
		// No need to empty() these, because it's world init and they're
		// already /turf/open/space/basic.
		var/turf/T = t
		T.turf_flags |= TURF_UNUSED_RESERVATION
	unused_turfs["[z]"] = block
	reservation_ready["[z]"] = TRUE
	clearing_reserved_turfs = FALSE

/datum/controller/subsystem/mapping/proc/reserve_turfs(list/turfs)
	for(var/i in turfs)
		var/turf/T = i
		T.empty(RESERVED_TURF_TYPE, RESERVED_TURF_TYPE, null, TRUE)
		LAZYINITLIST(unused_turfs["[T.z]"])
		unused_turfs["[T.z]"] |= T
		T.turf_flags |= TURF_UNUSED_RESERVATION
		GLOB.areas_by_type[world.area].contents += T
		CHECK_TICK

//DO NOT CALL THIS PROC DIRECTLY, CALL wipe_reservations().
/datum/controller/subsystem/mapping/proc/do_wipe_turf_reservations()
	UNTIL(initialized) //This proc is for AFTER init, before init turf reservations won't even exist and using this will likely break things.
	for(var/i in turf_reservations)
		var/datum/turf_reservation/TR = i
		if(!QDELETED(TR))
			qdel(TR, TRUE)
	UNSETEMPTY(turf_reservations)
	var/list/clearing = list()
	for(var/l in unused_turfs) //unused_turfs is a assoc list by z = list(turfs)
		if(islist(unused_turfs[l]))
			clearing |= unused_turfs[l]
	clearing |= used_turfs //used turfs is an associative list, BUT, reserve_turfs() can still handle it. If the code above works properly, this won't even be needed as the turfs would be freed already.
	unused_turfs.Cut()
	used_turfs.Cut()
	reserve_turfs(clearing)

/datum/controller/subsystem/mapping/proc/reg_in_areas_in_z(list/areas)
	for(var/B in areas)
		var/area/A = B
		A.reg_in_areas_in_z()

/// Gets a name for the marine ship as per the enabled ship map configuration
/datum/controller/subsystem/mapping/proc/get_main_ship_name()
	if(!configs)
		return MAIN_SHIP_DEFAULT_NAME
	var/datum/map_config/MC = configs[SHIP_MAP]
	if(!MC)
		return MAIN_SHIP_DEFAULT_NAME
	return MC.map_name
