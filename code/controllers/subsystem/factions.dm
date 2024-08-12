
#define CORPSES_TO_SPAWN 200

SUBSYSTEM_DEF(factions)
	name = "Factions"
	init_order = SS_INIT_FACTIONS
	runlevels = RUNLEVEL_GAME
	wait = 10 SECONDS

	var/list/datum/faction/active_factions = list()
	var/list/obj/structure/prop/sector_center/sectors = list()
	var/list/datum/faction_task/active_tasks = list()
	var/list/datum/faction_task/total_tasks = list()
	var/processing_tasks = 0

	var/list/datum/objectives_datum/active_objectives_controllers = list()
	var/total_objectives = 0
	var/total_active_objectives = 0
	var/next_sitrep = SITREP_INTERVAL
	var/list/statistics = list(
		"documents_completed" = 0,
		"documents_total_instances" = 0,
		"documents_total_points_earned" = 0,
		"chemicals_completed" = 0,
		"chemicals_total_instances" = 0,
		"chemicals_total_points_earned" = 0,
		"data_retrieval_completed" = 0,
		"data_retrieval_total_instances" = 0,
		"data_retrieval_total_points_earned" = 0,
		"item_retrieval_completed" = 0,
		"item_retrieval_total_instances" = 0,
		"item_retrieval_total_points_earned" = 0,
		"miscellaneous_completed" = 0,
		"miscellaneous_total_instances" = 0,
		"miscellaneous_total_points_earned" = 0,
		"survivors_rescued" = 0,
		"survivors_rescued_total_points_earned" = 0,
		"corpses_recovered" = 0,
		"corpses_total_points_earned" = 0
	)

	var/list/datum/faction/current_active_run = list()
	var/list/datum/cm_objective/current_active_run_objectives = list()
	var/list/datum/faction_task/current_active_run_tasks = list()

/datum/controller/subsystem/factions/Initialize(start_timeofday)
	. = ..()

	RegisterSignal(SSdcs, COMSIG_GLOB_MODE_POSTSETUP, PROC_REF(post_round_start))

	return SS_INIT_SUCCESS

/datum/controller/subsystem/factions/stat_entry(msg)
	msg = "F:[length(GLOB.faction_datums)]|AF:[length(active_factions)]|OC:[length(GLOB.objective_controller)]|AOC:[length(active_objectives_controllers)]|O:[total_objectives]|AO:[total_active_objectives]|S:[length(sectors)]|T:[length(total_tasks)]|P:[length(processing_tasks)]"
	return ..()

/datum/controller/subsystem/factions/fire()
	if(length(current_active_run))
		active_factions = list()
		processing_tasks = 0

		for(var/faction_to_get in FACTION_LIST_ALL)
			var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
			if(!length(faction.totalMobs))
				continue
			active_factions += faction

		current_active_run = active_factions.Copy()

		active_objectives_controllers = list()
		total_objectives = 0
		total_active_objectives = 0
		for(var/faction_to_get in GLOB.objective_controller)
			var/datum/objectives_datum/objectives_controller = GLOB.objective_controller[faction_to_get]
			total_objectives += length(objectives_controller.objectives)
			if(!objectives_controller.check_status())
				total_objectives += length(objectives_controller.processing_objectives)
			else
				total_active_objectives += length(objectives_controller.processing_objectives)
				active_objectives_controllers += objectives_controller

		if(world.time > next_sitrep)
			next_sitrep = world.time + SITREP_INTERVAL
			announce_stats()

		if(MC_TICK_CHECK)
			return

	while(length(current_active_run))
		var/datum/faction/faction = current_active_run[length(current_active_run)]
		if(!length(current_active_run_tasks) && !length(current_active_run_objectives))
			for(var/datum/faction_task/task in SSfactions.active_tasks)
				if(task.faction_owner != faction)
					continue
				current_active_run_tasks += task
			current_active_run_objectives = faction.objectives_controller.objectives.Copy()

		while(length(current_active_run_tasks))
			if(MC_TICK_CHECK)
				return

			var/datum/faction_task/task = current_active_run_tasks[length(current_active_run_tasks)]
			current_active_run_tasks.len--
			task.process()
			task.check_completion()
			if(task.state & OBJECTIVE_COMPLETE|OBJECTIVE_FAILED)
				stop_processing_task(task)

		while(length(current_active_run_objectives))
			if(MC_TICK_CHECK)
				return

			var/datum/cm_objective/objective = current_active_run_objectives[length(current_active_run_objectives)]
			current_active_run_objectives.len--
			objective.process()
			objective.check_completion()
			if(objective.objective_state & OBJECTIVE_COMPLETE|OBJECTIVE_FAILED)
				GLOB.faction_datums[objective.controller].objectives_controller.stop_processing_objective(objective)

		current_active_run.len--

	try_to_set_task()

/datum/controller/subsystem/factions/proc/try_to_set_task()
	set waitfor = FALSE

	if(length(processing_tasks) < length(SSticker.mode.factions_pool) || prob(1))
		for(var/faction_name in SSticker.mode.factions_pool)
			var/datum/faction/faction = GLOB.faction_datums[SSticker.mode.factions_pool[faction_name]]
			if(make_potential_tasks(faction))
				break

/datum/controller/subsystem/factions/proc/make_potential_tasks(datum/faction/faction, use_game_enders = FALSE)
	var/datum/faction_task/faction_task
	var/picked_gen = pick(use_game_enders ? GLOB.task_gen_list_game_enders : GLOB.task_gen_list)
	switch(picked_gen)
		if("sector_control")
			for(var/obj/structure/prop/sector_center/sector in sectors)
				if(sector.faction != faction)
					continue

				for(var/obj/structure/prop/sector_center/border_sector in sector.bordered_sectors)
					if(border_sector.faction == faction || !(border_sector.home_sector && faction.homes_sector_occupation))
						continue
					var/list/potential_task_list = GLOB.task_gen_list[picked_gen]
					var/list/datum/faction_task/tasks_list = border_sector.get_faction_tasks(faction)
					for(var/datum/faction_task/task in tasks_list)
						potential_task_list -= task.type
					if(length(potential_task_list))
						var/type_to_gen = pick(potential_task_list)
						faction_task = new type_to_gen(faction, border_sector)
						break

				if(faction_task)
					break

		if("game_enders")
			var/list/potential_task_list = GLOB.task_gen_list_game_enders[picked_gen]
			var/game_ender_type_to_gen = pick(potential_task_list)
			faction_task = new game_ender_type_to_gen(faction)

	if(faction_task)
		active_tasks += faction_task
		return TRUE
	return FALSE

/datum/controller/subsystem/factions/proc/build_sectors()
	var/list/sectors_by_id = list()
	for(var/obj/structure/prop/sector_center/sector in sectors)
		sectors_by_id[sector.sector_id] = sector

	for(var/obj/structure/prop/sector_center/sector in sectors)
		for(var/bordered_sector_id in sector.sector_connections)
			sector.bordered_sectors += sectors_by_id[bordered_sector_id]

/datum/controller/subsystem/factions/proc/add_task(datum/faction_task/task)
	total_tasks += task

/datum/controller/subsystem/factions/proc/remove_task(datum/faction_task/task)
	total_tasks -= task

/datum/controller/subsystem/factions/proc/start_processing_task(datum/faction_task/task)
	active_tasks += task

/datum/controller/subsystem/factions/proc/stop_processing_task(datum/faction_task/task)
	active_tasks -= task

/// Allows to perform objective initialization later on in case of map changes
/datum/controller/subsystem/factions/proc/initialize_objectives()
	var/datum/map_config/ground_map = SSmapping.configs[GROUND_MAP]
	var/total_percent = length(GLOB.clients) / 100
	for(var/faction_to_get in GLOB.objective_controller)
		var/datum/objectives_datum/objectives_controller = GLOB.objective_controller[faction_to_get]
		objectives_controller.generate_objectives()
		connect_objectives(objectives_controller)
		var/faction_mobs = length(GLOB.faction_datums[objectives_controller.associated_faction].totalMobs)
		if(faction_mobs)
			objectives_controller.corpsewar.generate_corpses(round(ground_map.map_corpses * faction_mobs / total_percent))

/datum/controller/subsystem/factions/proc/post_round_start()
	set waitfor = FALSE

	initialize_objectives()
	for(var/faction_to_get in GLOB.objective_controller)
		var/datum/objectives_datum/objectives_controller = GLOB.objective_controller[faction_to_get]
		for(var/datum/cm_objective/objective in objectives_controller.objectives)
			objective.post_round_start()

/datum/controller/subsystem/factions/proc/connect_objectives(datum/objectives_datum/objectives_controller)
	// Sets up the objective interdependance faction
	// Every objective (which isn't a dead end) gets one guaranteed objective it unlocks.
	// Every objective gets x random objectives that unlock it based on variable 'number_of_clues_to_generate'

	var/list/low_value = list()
	var/list/medium_value = list()
	var/list/high_value = list()
	var/list/extreme_value = list()
	var/list/absolute_value = list()
	// Sort objectives into categories
	for(var/datum/cm_objective/objective in objectives_controller.objectives)
		if(objective.objective_flags & OBJECTIVE_DO_NOT_TREE)
			continue // exempt from the tree
		switch(objective.value)
			if(OBJECTIVE_LOW_VALUE)
				low_value += objective
			if(OBJECTIVE_MEDIUM_VALUE)
				medium_value += objective
			if(OBJECTIVE_HIGH_VALUE)
				high_value += objective
			if(OBJECTIVE_EXTREME_VALUE)
				extreme_value += objective
			if(OBJECTIVE_ABSOLUTE_VALUE)
				absolute_value += objective

	// Set up preqrequisites:
	// Low
	for(var/datum/cm_objective/objective in low_value)
		// Add at least one guaranteed clue for this objective to unlock.
		if(!(objective.objective_flags & OBJECTIVE_DEAD_END) && length(medium_value))
			var/datum/cm_objective/enables = pick(medium_value)
			link_objectives(objective, enables)

	// Medium
	for(var/datum/cm_objective/objective in medium_value)
		var/list/low_value_list = low_value.Copy()
		while(length(objective.required_objectives) < objective.number_of_clues_to_generate && length(low_value_list))
			var/datum/cm_objective/req = pick(low_value_list)
			low_value_list -= req
			if(req in objective.required_objectives || (req.objective_flags & OBJECTIVE_DEAD_END))
				continue //don't want to pick the same thing twice OR use a dead-end objective.
			link_objectives(req, objective)

		// Add at least one guaranteed clue for this objective to unlock.
		if(!(objective.objective_flags & OBJECTIVE_DEAD_END) && length(high_value))
			var/datum/cm_objective/enables = pick(high_value)
			link_objectives(objective, enables)

	// High
	for(var/datum/cm_objective/objective in high_value)
		var/list/medium_value_list = medium_value.Copy()
		while(length(objective.required_objectives) < objective.number_of_clues_to_generate && length(medium_value_list))
			var/datum/cm_objective/req = pick(medium_value_list)
			medium_value_list -= req
			if(req in objective.required_objectives || (req.objective_flags & OBJECTIVE_DEAD_END))
				continue //don't want to pick the same thing twice OR use a dead-end objective.
			link_objectives(req, objective)

		// Add at least one guaranteed clue for this objective to unlock.
		if(!(objective.objective_flags & OBJECTIVE_DEAD_END) && length(extreme_value))
			var/datum/cm_objective/enables = pick(extreme_value)
			link_objectives(objective, enables)

	// Extreme
	for(var/datum/cm_objective/objective in extreme_value)
		var/list/high_value_list = high_value.Copy()
		while(length(objective.required_objectives) < objective.number_of_clues_to_generate && length(high_value_list))
			var/datum/cm_objective/req = pick(high_value_list)
			high_value_list -= req
			if(req in objective.required_objectives || (req.objective_flags & OBJECTIVE_DEAD_END))
				continue //don't want to pick the same thing twice OR use a dead-end objective.
			link_objectives(req, objective)

		// Add at least one guaranteed clue for this objective to unlock.
		if(!(objective.objective_flags & OBJECTIVE_DEAD_END) && length(absolute_value))
			var/datum/cm_objective/enables = pick(absolute_value)
			link_objectives(objective, enables)

	// Absolute
	for(var/datum/cm_objective/objective in absolute_value)
		var/list/extreme_value_list = extreme_value.Copy()
		while(length(objective.required_objectives) < objective.number_of_clues_to_generate && length(extreme_value_list))
			var/datum/cm_objective/req = pick(extreme_value_list)
			extreme_value_list -= req
			if(req in objective.required_objectives || (req.objective_flags & OBJECTIVE_DEAD_END))
				continue //don't want to pick the same thing twice OR use a dead-end objective.
			link_objectives(req, objective)

// For linking 2 objectives together in the objective tree
/datum/controller/subsystem/factions/proc/link_objectives(datum/cm_objective/required_objective, datum/cm_objective/enabled_objective)
	enabled_objective.required_objectives += required_objective
	required_objective.enables_objectives += enabled_objective

/datum/controller/subsystem/factions/proc/get_objectives_progress(faction)
	var/point_total = 0
	var/complete = 0

	var/list/categories = list()
	var/list/notable_objectives = list()

	for(var/datum/cm_objective/C as anything in GLOB.faction_datums[faction].objectives_controller.objectives)
		if(!C.observable_by_faction(faction))
			continue
		if(C.display_category)
			if(!(C.display_category in categories))
				categories += C.display_category
				categories[C.display_category] = list("count" = 0, "total" = 0, "complete" = 0)
			categories[C.display_category]["count"]++
			categories[C.display_category]["total"] += C.total_point_value(faction)
			categories[C.display_category]["complete"] += C.get_point_value(faction)

		if(C.objective_flags & OBJECTIVE_DISPLAY_AT_END)
			notable_objectives += C

		point_total += C.total_point_value(faction)
		complete += C.get_point_value(faction)

	var/dat = ""
	if(length(GLOB.faction_datums[faction].objectives_controller.objectives)) // protect against divide by zero
		dat = "<b>Total Objectives:</b> [complete]pts achieved<br>"
		if(length(categories))
			var/total = 1 //To avoid divide by zero errors, just in case...
			var/compl
			for(var/cat in categories)
				total = categories[cat]["total"]
				compl = categories[cat]["complete"]
				if(total == 0)
					total = 1 //To avoid divide by zero errors, just in case...
				dat += "<b>[cat]: </b> [compl]pts achieved<br>"

		for(var/datum/cm_objective/objective as anything in notable_objectives)
			if(!objective.observable_by_faction(faction))
				continue
			dat += objective.get_readable_progress(faction)

	return dat

/datum/controller/subsystem/factions/proc/get_scored_points(faction)
	var/scored_points = 0

	for(var/datum/cm_objective/L as anything in GLOB.faction_datums[faction].objectives_controller.objectives)
		if(!L.observable_by_faction(faction))
			continue
		scored_points += L.get_point_value(faction)

	return scored_points

/datum/controller/subsystem/factions/proc/get_total_points(faction)
	var/total_points = 0

	for(var/datum/cm_objective/L as anything in GLOB.faction_datums[faction].objectives_controller.objectives)
		if(!L.observable_by_faction(faction))
			continue
		total_points += L.total_point_value(faction)

	return total_points

/datum/controller/subsystem/factions/proc/announce_stats()
	to_chat(GLOB.observer_list, "<h2 class='alert'>Отчет по задачам</h2>")
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(!faction.objectives_active)
			continue

		faction.objectives_controller.check_defcon_level()
		var/message = "Статус цели: [faction.objectives_controller.last_objectives_scored_points] / [faction.objectives_controller.player_points_defcon] ([faction.objectives_controller.last_objectives_completion_percentage]%)."
		if(faction.faction_name == FACTION_MARINE)
			ai_silent_announcement(message, ":i", TRUE)
			ai_silent_announcement(message, ":t", TRUE)
		else if(istype(faction, /datum/faction/xenomorph))
			xeno_announcement(SPAN_XENOANNOUNCE(message), faction, XENO_GENERAL_ANNOUNCE)
		else
			faction_announcement(message, "Цели", 'sound/AI/commandreport.ogg', faction)
		message_admins("[faction.name] [message]")
		to_chat(GLOB.observer_list, SPAN_WARNING("[faction.name] [message]"))
