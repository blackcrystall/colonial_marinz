/*
How this works:
jobs.dm contains the job defines that work on that level only. Things like equipping a character, creating IDs, and so forth, are handled there.
Role Authority handles the creation and assignment of roles. Roles can be things like regular marines, PMC response teams, aliens, and so forth.
Role Authority creates two master lists on New(), one for every role defined in the game, by path, and one only for roles that should appear
at round start, by name. The title of a role is important and is a unique identifier. Two roles can share the same title, but it's really
the same role, just with different equipment, spawn conditions, or something along those lines. The title is there to tell the job ban system
which roles to ban, and it does so through the roles_by_name master list.

When a round starts, the roles are assigned based on the round, from another list. This is done to make sure that both the master list of roles
by name can be kept for things like job bans, while the round may add or remove roles as needed.If you need to equip a mob for a job, always
use roles_by_path as it is an accurate account of every specific role path (with specific equipment).
*/

#define GET_RANDOM_JOB 0
#define BE_MARINE 1
#define RETURN_TO_LOBBY 2
#define BE_XENOMORPH 3

#define NEVER_PRIORITY 0
#define HIGH_PRIORITY 1
#define MED_PRIORITY 2
#define LOW_PRIORITY 3

#define SHIPSIDE_ROLE_WEIGHT 0.25

var/global/players_preassigned = 0


/proc/guest_jobbans(job)
	return (job in ROLES_COMMAND)

/datum/authority/branch/role
	var/name = "Role Authority"

	var/list/roles_by_path //Master list generated when role aithority is created, listing every role by path, including variable roles. Great for manually equipping with.
	var/list/roles_by_name //Master list generated when role authority is created, listing every default role by name, including those that may not be regularly selected.
	var/list/roles_by_faction
	var/list/roles_for_mode //Derived list of roles only for the game mode, generated when the round starts.
	var/list/castes_by_path //Master list generated when role aithority is created, listing every caste by path.
	var/list/castes_by_name //Master list generated when role authority is created, listing every default caste by name.

	/// List of mapped roles that should be used in place of usual ones
	var/list/role_mappings
	var/list/default_roles
	var/max_weigth = 0

	var/list/unassigned_players
	var/list/squads
	var/list/squads_by_type

//Whenever the controller is created, we want to set up the basic role lists.
/datum/authority/branch/role/New()
	var/roles_all[] = typesof(/datum/job) - list( //We want to prune all the parent types that are only variable holders.
											/datum/job,
											/datum/job/command,
											/datum/job/civilian,
											/datum/job/logistics,
											/datum/job/uscm/squad,
											/datum/job/antag,
											/datum/job/special,
											/datum/job/special/provost,
											/datum/job/special/uaac,
											/datum/job/special/uaac/tis,
											/datum/job/special/uscm,
											/datum/job/upp,
											/datum/job/upp/command,
											/datum/job/upp/squad,
											/datum/job/special/cmb,
											)
	var/squads_all[] = typesof(/datum/squad) - /datum/squad
	var/castes_all[] = subtypesof(/datum/caste_datum)

	if(!length(roles_all))
		to_world(SPAN_DEBUG("Error setting up jobs, no job datums found."))
		log_debug("Error setting up jobs, no job datums found.")
		return //No real reason this should be length zero, so we'll just return instead.

	if(!length(squads_all))
		to_world(SPAN_DEBUG("Error setting up squads, no squad datums found."))
		log_debug("Error setting up squads, no squad datums found.")
		return

	if(!length(castes_all))
		to_world(SPAN_DEBUG("Error setting up castes, no caste datums found."))
		log_debug("Error setting up castes, no caste datums found.")
		return

	castes_by_path = list()
	castes_by_name = list()
	for(var/caste in castes_all) //Setting up our castes.
		var/datum/caste_datum/C = new caste()

		if(!C.caste_type) //In case you forget to subtract one of those variable holder jobs.
			to_world(SPAN_DEBUG("Error setting up castes, blank caste name: [C.type].</span>"))
			log_debug("Error setting up castes, blank caste name: [C.type].")
			continue

		castes_by_path[C.type] = C
		castes_by_name[C.caste_type] = C

	roles_by_path = list()
	roles_by_name = list()
	roles_by_faction = list()
	for(var/role in roles_all) //Setting up our roles.
		var/datum/job/job = new role()

		if(!job.title) //In case you forget to subtract one of those variable holder jobs.
			to_world(SPAN_DEBUG("Error setting up jobs, blank title job: [job.type]."))
			log_debug("Error setting up jobs, blank title job: [job.type].")
			continue

		roles_by_path[job.type] = job
		roles_by_name[job.title] = job

	set_up_roles()

	squads = list()
	squads_by_type = list()
	for(var/squad in squads_all) //Setting up our squads.
		var/datum/squad/new_squad = new squad()
		squads += new_squad
		squads_by_type[new_squad.type] = new_squad

/*
Consolidated into a better collection of procs. It was also calling too many loops, and I tried to fix that as well.
I hope it's easier to tell what the heck this proc is even doing, unlike previously.
 */

/datum/authority/branch/role/proc/setup_candidates_and_roles()
	//===============================================================\\
	//PART I: Get roles relevant to the mode

	// Getting role list
	set_up_roles()

	// Also register game mode specific mappings to standard roles
	role_mappings = list()
	default_roles = list()
	if(SSticker.mode.active_roles_mappings_pool)
		for(var/role_path in SSticker.mode.active_roles_mappings_pool)
			var/mapped_title = SSticker.mode.active_roles_mappings_pool[role_path]
			var/datum/job/job = roles_by_path[role_path]
			if(!job || !roles_by_name[mapped_title])
				debug_log("Missing job for prefs: [role_path]")
				continue
			role_mappings[mapped_title] = job
			default_roles[job.title] = mapped_title

	/*===============================================================*/

	//===============================================================\\
	//PART II: Setting up our player variables and lists, to see if we have anyone to destribute.

	unassigned_players = list()
	for(var/mob/new_player/M in GLOB.player_list) //Get all players who are ready.
		if(!M.ready || M.job)
			continue

		unassigned_players += M

	if(!length(unassigned_players)) //If we don't have any players, the round can't start.
		unassigned_players = null
		return

	unassigned_players = shuffle(unassigned_players, 1) //Shuffle the players.

	// How many positions do we open based on total pop
	for(var/i in roles_by_name)
		var/datum/job/job = roles_by_name[i]
		if(job.scaled)
			job.set_spawn_positions(length(unassigned_players))

	/*===============================================================*/

	//===============================================================\\
	//PART III: Here we're doing the main body of the loop and assigning everyone.

	players_preassigned = assign_roles(roles_for_mode, unassigned_players, TRUE)

	// Set up limits for other roles based on our balancing weight number.
	// Set the xeno starting amount based on marines assigned
	for(var/role_name in roles_for_mode)
		var/datum/job/job = roles_for_mode[role_name]
		job.current_positions = 0
		job.set_spawn_positions(players_preassigned)

	// Assign the roles, this time for real, respecting limits we have established.
	var/list/roles_left = assign_roles(roles_for_mode, unassigned_players)

	var/alternate_option_assigned = 0
	for(var/mob/new_player/M in unassigned_players)
		switch(M.client.prefs.alternate_option)
			if(GET_RANDOM_JOB)
				roles_left = assign_random_role(M, roles_left) //We want to keep the list between assignments.
				alternate_option_assigned++
			if(BE_MARINE)
				for(var/base_role in JOB_SQUAD_NORMAL_LIST)
					var/datum/job/job = GET_MAPPED_ROLE(base_role)
					if(assign_role(M, job))
						alternate_option_assigned++
						break

			if(BE_XENOMORPH)
				var/datum/job/xenomorph_job = GET_MAPPED_ROLE(JOB_XENOMORPH)
				assign_role(M, xenomorph_job)
			if(RETURN_TO_LOBBY)
				M.ready = 0
		unassigned_players -= M

	if(length(unassigned_players))
		to_world(SPAN_DEBUG("Error setting up jobs, unassigned_players still has players left. Length of: [length(unassigned_players)]."))
		log_debug("Error setting up jobs, unassigned_players still has players left. Length of: [length(unassigned_players)].")

	unassigned_players = null

	// Now we take spare unfilled xeno slots and make them larva NEW
	var/datum/faction/faction = GLOB.faction_datums[FACTION_XENOMORPH_NORMAL]
	var/datum/job/antag/xenos/xenomorph = GET_MAPPED_ROLE(JOB_XENOMORPH)
	if(istype(faction) && istype(xenomorph))
		faction.stored_larva += max(0, (xenomorph.total_positions - xenomorph.current_positions) \
		+ (xenomorph.calculate_extra_spawn_positions(alternate_option_assigned)))
		faction.faction_ui.update_burrowed_larva()

	/*===============================================================*/

/datum/authority/branch/role/proc/set_up_roles()
	roles_for_mode = list()
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(length(faction.roles_list[SSticker.mode.name]))
			for(var/role_name in faction.roles_list[SSticker.mode.name])
				var/datum/job/job = roles_by_name[role_name]
				if(!job)
					debug_log("Missing job for prefs: [role_name]")
					continue
				roles_for_mode[role_name] = job
				roles_by_faction[role_name] = faction.faction_name

/**
* Assign roles to the players. Return roles that are still avialable.
* If count is true, return role balancing weight instead.
*/
/datum/authority/branch/role/proc/assign_roles(list/roles_to_iterate, list/unassigned_players, count = FALSE)
	var/list/roles_left = list()
	var/assigned = 0
	for(var/priority in HIGH_PRIORITY to LOW_PRIORITY)
		if(count)
			assigned += assign_initial_roles(priority, roles_to_iterate, unassigned_players)
		else
			roles_left = assign_initial_roles(priority, roles_to_iterate, unassigned_players, FALSE)
	if(count)
		return assigned
	return roles_left

/datum/authority/branch/role/proc/assign_initial_roles(priority, list/roles_to_iterate, list/unassigned_players, count = TRUE)
	var/assigned = 0
	if(!length(roles_to_iterate) || !length(unassigned_players))
		return

	for(var/role_name in roles_to_iterate)
		var/datum/job/job = roles_to_iterate[role_name]
		if(!istype(job)) //Shouldn't happen, but who knows.
			to_world(SPAN_DEBUG("Error setting up jobs, no job datum set for: [role_name]."))
			log_debug("Error setting up jobs, no job datum set for: [role_name].")
			continue

		for(var/M in unassigned_players)
			var/mob/new_player/NP = M
			if(!(NP.client.prefs.get_job_priority(job.title) == priority))
				continue //If they don't want the job. //TODO Change the name of the prefs proc?

			if(assign_role(NP, job))
				assigned++
				unassigned_players -= NP
				// -1 check is not strictly needed here, since standard marines are
				// supposed to have an actual spawn_positions number at this point
				if(job.spawn_positions != -1 && job.current_positions >= job.spawn_positions)
					roles_to_iterate -= role_name //Remove the position, since we no longer need it.
					break //Maximum position is reached?

		if(!length(unassigned_players))
			break //No players left to assign? Break.

	if(count)
		return assigned
	return roles_to_iterate

/datum/authority/branch/role/proc/assign_random_role(mob/new_player/M, list/roles_to_iterate) //In case we want to pass on a list.
	. = roles_to_iterate
	if(length(roles_to_iterate))
		var/datum/job/job
		var/i = 0
		var/role_name
		while(++i < 3) //Get two passes.
			if(!length(roles_to_iterate) || prob(65))
				break //Base chance to become a marine when being assigned randomly, or there are no roles available.
			role_name = pick(roles_to_iterate)
			job = roles_to_iterate[role_name]

			if(!istype(job))
				to_world(SPAN_DEBUG("Error setting up jobs, no job datum set for: [role_name]."))
				log_debug("Error setting up jobs, no job datum set for: [role_name].")
				continue

			if(assign_role(M, job)) //Check to see if they can actually get it.
				if(job.current_positions >= job.spawn_positions) roles_to_iterate -= role_name
				return roles_to_iterate

	//If they fail the two passes, or no regular roles are available, they become a marine regardless.
	for(var/base_role in JOB_SQUAD_NORMAL_LIST)
		var/datum/job/job = GET_MAPPED_ROLE(base_role)
		if(assign_role(M, job))
			break

/datum/authority/branch/role/proc/assign_role(mob/new_player/M, datum/job/job, latejoin = FALSE)
	if(ismob(M) && istype(job))
		var/datum/faction/faction = GLOB.faction_datums[roles_by_faction[job.title]]
		var/check_result = check_role_entry(M, job, faction, latejoin)
		if(!check_result)
			M.job = job.title
			job.current_positions++
			return TRUE
		else if(latejoin)
			to_chat(M, "[job.title]: [check_result]")

/datum/authority/branch/role/proc/check_role_entry(mob/new_player/M, datum/job/job, datum/faction/faction, latejoin = FALSE)
	if(jobban_isbanned(M, job.title) || (job.role_ban_alternative && jobban_isbanned(M, job.role_ban_alternative)))
		return  M.client.auto_lang(LANGUAGE_JS_JOBBANED)
	if(!job.can_play_role(M.client))
		return  M.client.auto_lang(LANGUAGE_JS_CANT_PLAY)
	if(job.flags_startup_parameters & ROLE_WHITELISTED && !(M.client.player_data?.whitelist?.whitelist_flags & job.flags_whitelist))
		return  M.client.auto_lang(LANGUAGE_JS_WHITELIST)
	if(job.total_positions != -1 && job.get_total_positions(latejoin) <= job.current_positions)
		return  M.client.auto_lang(LANGUAGE_JS_NO_SLOTS_OPEN)
	if(latejoin && !job.late_joinable)
		return  M.client.auto_lang(LANGUAGE_JS_CLOSED)
	if(!SSautobalancer.can_join(faction))
		return M.client.auto_lang(LANGUAGE_JS_BALANCE_ISSUE)
	return FALSE

/datum/authority/branch/role/proc/free_role(datum/job/job, latejoin = 1) //Want to make sure it's a job, and nothing like a MODE or special role.
	if(istype(job) && job.total_positions != -1 && job.get_total_positions(latejoin) >= job.current_positions)
		job.current_positions--
		return TRUE

/datum/authority/branch/role/proc/free_role_admin(datum/job/job, latejoin = 1, user) //Specific proc that used for admin "Free Job Slots" verb (round tab)
	if(!istype(job) || job.total_positions == -1)
		return

	if(job.current_positions < 1) //this should be filtered earlier, but we still check just in case
		to_chat(user, "There are no [job] job slots occupied.")
		return

//here is the main reason this proc exists - to remove freed squad jobs from squad,
//so latejoining person ends in the squad which's job was freed and not random one
	var/datum/squad/squad = null
	var/real_job = GET_DEFAULT_ROLE(job)
	if(real_job in JOB_SQUAD_ROLES_LIST)
		var/list/squad_list = list()
		for(squad as anything in SSticker.role_authority.squads)
			if(squad.roundstart && squad.usable && squad.faction == job.faction && squad.name != "Root")
				squad_list += squad
		squad = null
		squad = input(user, "Select squad you want to free [job.title] slot from.", "Squad Selection")  as null|anything in squad_list
		if(!squad)
			return
		var/slot_check
		if(real_job in JOB_SQUAD_LEADER_LIST)
			slot_check = "leaders"
		else if(real_job in JOB_SQUAD_SPEC_LIST)
			slot_check = "specialists"
		else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
			slot_check = "main_supports"
		else if(real_job in JOB_SQUAD_SUP_LIST)
			slot_check = "supports"
		else if(real_job in JOB_SQUAD_MEDIC_LIST)
			slot_check = "medics"
		else if(real_job in JOB_SQUAD_ENGI_LIST)
			slot_check = "engineers"

		if(squad.vars["num_[slot_check]"] > 0)
			squad.vars["num_[slot_check]"]--
		else
			to_chat(user, "There are no [job.title] slots occupied in [squad.name] Squad.")
			return
	job.current_positions--
	message_admins("[key_name(user)] freed the [job.title] job slot[squad ? " in [squad.name] Squad" : ""].")
	return 1

/datum/authority/branch/role/proc/modify_role(datum/job/job, amount)
	if(!istype(job))
		return 0
	if(amount < job.current_positions) //we should be able to slot everyone
		return 0
	job.total_positions = amount
	job.total_positions_so_far = amount
	return 1

//I'm not entirely sure why this proc exists. //TODO Figure this out.
/datum/authority/branch/role/proc/reset_roles()
	for(var/mob/new_player/M in GLOB.new_player_list)
		M.job = null


/datum/authority/branch/role/proc/equip_role(mob/living/M, datum/job/job, turf/late_join)
	if(!istype(M) || !istype(job))
		return

	. = TRUE

	if(!ishuman(M))
		return

	var/mob/living/carbon/human/human = M

	var/job_whitelist = job.title
	var/whitelist_status = job.get_whitelist_status(human.client.player_data?.whitelist?.whitelist_flags, human.client)
	if(job.job_options && human?.client?.prefs?.pref_special_job_options[job.title])
		job.handle_job_options(human.client.prefs.pref_special_job_options[job.title])

	if(whitelist_status)
		job_whitelist = "[job.title][whitelist_status]"

	human.job = job.title //TODO Why is this a mob variable at all?

	if(job.gear_preset_whitelist[job_whitelist])
		arm_equipment(human, job.gear_preset_whitelist[job_whitelist], FALSE, TRUE)
		var/generated_account = job.generate_money_account(human)
		job.announce_entry_message(human, generated_account, whitelist_status) //Tell them their spawn info.
		job.generate_entry_conditions(human, whitelist_status) //Do any other thing that relates to their spawn.
	else
		arm_equipment(human, job.gear_preset, FALSE, TRUE) //After we move them, we want to equip anything else they should have.
		var/generated_account = job.generate_money_account(human)
		job.announce_entry_message(human, generated_account) //Tell them their spawn info.
		job.generate_entry_conditions(human) //Do any other thing that relates to their spawn.

	if(job.flags_startup_parameters & ROLE_ADD_TO_SQUAD) //Are we a muhreen? Randomize our squad. This should go AFTER IDs. //TODO Robust this later.
		randomize_squad(human)

	if(Check_WO() && JOB_SQUAD_ROLES_LIST & GET_DEFAULT_ROLE(human.job)) //activates self setting proc for marine headsets for WO
		var/datum/game_mode/whiskey_outpost/wo = SSticker.mode
		wo.self_set_headset(human)

	var/assigned_squad
	if(human.assigned_squad)
		assigned_squad = human.assigned_squad.name

	if(isturf(late_join))
		human.forceMove(late_join)
	else if(late_join)
		human.forceMove(job.get_latejoin_turf(human))
	else
		var/turf/join_turf
		if(!late_join)
			if(assigned_squad && GLOB.spawns_by_squad_and_job[assigned_squad] && GLOB.spawns_by_squad_and_job[assigned_squad][job.type])
				join_turf = get_turf(pick(GLOB.spawns_by_squad_and_job[assigned_squad][job.type]))
			else if(GLOB.spawns_by_job[job.type])
				join_turf = get_turf(pick(GLOB.spawns_by_job[job.type]))

		if(!join_turf)
			join_turf = job.get_latejoin_turf(human)

		human.forceMove(join_turf)

	for(var/cardinal in GLOB.cardinals)
		var/obj/structure/machinery/cryopod/pod = locate() in get_step(human, cardinal)
		if(pod)
			pod.go_in_cryopod(human, silent = TRUE)
			break

	human.sec_hud_set_ID()
	human.hud_set_squad()

	SSround_recording.recorder.track_player(human)

//Find which squad has the least population. If all 4 squads are equal it should just use a random one
/datum/authority/branch/role/proc/randomize_squad(mob/living/carbon/human/human, skip_limit = FALSE)
	if(!human)
		return

	if(!length(squads))
		to_chat(human, "Something went wrong with your squad randomizer! Tell a coder!")
		return //Shit, where's our squad data

	if(human.assigned_squad) //Wait, we already have a squad. Get outta here!
		return

	//Deal with IOs first
	if(human.job == JOB_INTEL)
		var/datum/squad/intel_squad = get_squad_by_name(SQUAD_MARINE_7)
		if(!intel_squad || !istype(intel_squad)) //Something went horribly wrong!
			to_chat(human, "Something went wrong with randomize_squad()! Tell a coder!")
			return
		intel_squad.put_marine_in_squad(human) //Found one, finish up
		return

	var/slot_check
	var/real_job = GET_DEFAULT_ROLE(human.job)
	if(real_job in JOB_SQUAD_LEADER_LIST)
		slot_check = "leaders"
	else if(real_job in JOB_SQUAD_SPEC_LIST)
		slot_check = "specialists"
	else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
		slot_check = "main_supports"
	else if(real_job in JOB_SQUAD_SUP_LIST)
		slot_check = "supports"
	else if(real_job in JOB_SQUAD_MEDIC_LIST)
		slot_check = "medics"
	else if(real_job in JOB_SQUAD_ENGI_LIST)
		slot_check = "engineers"

	//we make a list of squad that is randomized so alpha isn't always lowest squad.
	var/list/mixed_squads = list()
	for(var/datum/squad/squad in squads)
		if(squad.roundstart && squad.usable && squad.faction == human.faction.faction_name && squad.name != "Root")
			mixed_squads += squad

	var/preferred_squad
	if(human && human.client && human.client.prefs.preferred_squad)
		if(human.client.prefs.preferred_squad in SQUAD_SELECTOR)
			preferred_squad = SQUAD_BY_FACTION[human.faction.faction_name][SQUAD_SELECTOR[human.client.prefs.preferred_squad]]
		else
			preferred_squad = human.client.prefs.preferred_squad

	var/datum/squad/lowest
	for(var/datum/squad/squad in mixed_squads)
		if(slot_check && !skip_limit)
			if(squad.vars["num_[slot_check]"] >= squad.vars["max_[slot_check]"])
				continue

		if(preferred_squad == "None" && squad.put_marine_in_squad(human))
			return squad

		if(squad == preferred_squad && squad.put_marine_in_squad(human)) //fav squad has a spot for us, no more searching needed.
			return squad

		if(!lowest)
			lowest = squad

		else if(slot_check)
			if(squad.vars["num_[slot_check]"] < lowest.vars["num_[slot_check]"])
				lowest = squad

	if(!lowest || !lowest.put_marine_in_squad(human))
		to_world("Warning! Bug in get_random_squad()!")
		return
	return lowest

/datum/authority/branch/role/proc/get_caste_by_text(name)
	var/mob/living/carbon/xenomorph/M
	switch(name) //ADD NEW CASTES HERE!
		if(XENO_CASTE_LARVA)
			M = /mob/living/carbon/xenomorph/larva
		if(XENO_CASTE_PREDALIEN_LARVA)
			M = /mob/living/carbon/xenomorph/larva/predalien
		if(XENO_CASTE_FACEHUGGER)
			M = /mob/living/carbon/xenomorph/facehugger
		if(XENO_CASTE_LESSER_DRONE)
			M = /mob/living/carbon/xenomorph/lesser_drone
		if(XENO_CASTE_RUNNER)
			M = /mob/living/carbon/xenomorph/runner
		if(XENO_CASTE_DRONE)
			M = /mob/living/carbon/xenomorph/drone
		if(XENO_CASTE_CARRIER)
			M = /mob/living/carbon/xenomorph/carrier
		if(XENO_CASTE_HIVELORD)
			M = /mob/living/carbon/xenomorph/hivelord
		if(XENO_CASTE_BURROWER)
			M = /mob/living/carbon/xenomorph/burrower
		if(XENO_CASTE_PRAETORIAN)
			M = /mob/living/carbon/xenomorph/praetorian
		if(XENO_CASTE_RAVAGER)
			M = /mob/living/carbon/xenomorph/ravager
		if(XENO_CASTE_SENTINEL)
			M = /mob/living/carbon/xenomorph/sentinel
		if(XENO_CASTE_SPITTER)
			M = /mob/living/carbon/xenomorph/spitter
		if(XENO_CASTE_LURKER)
			M = /mob/living/carbon/xenomorph/lurker
		if(XENO_CASTE_WARRIOR)
			M = /mob/living/carbon/xenomorph/warrior
		if(XENO_CASTE_DEFENDER)
			M = /mob/living/carbon/xenomorph/defender
		if(XENO_CASTE_QUEEN)
			M = /mob/living/carbon/xenomorph/queen
		if(XENO_CASTE_CRUSHER)
			M = /mob/living/carbon/xenomorph/crusher
		if(XENO_CASTE_BOILER)
			M = /mob/living/carbon/xenomorph/boiler
		if(XENO_CASTE_PREDALIEN)
			M = /mob/living/carbon/xenomorph/predalien
		if(XENO_CASTE_HELLHOUND)
			M = /mob/living/carbon/xenomorph/hellhound
	return M


/proc/get_desired_status(desired_status, status_limit)
	var/found_desired = FALSE
	var/found_limit = FALSE

	for(var/status in WHITELIST_HIERARCHY)
		if(status == desired_status)
			found_desired = TRUE
			break
		if(status == status_limit)
			found_limit = TRUE
			break

	if(found_desired)
		return desired_status
	else if(found_limit)
		return status_limit

	return desired_status

/proc/transfer_marine_to_squad(mob/living/carbon/human/transfer_marine, datum/squad/new_squad, datum/squad/old_squad, obj/item/card/id/ID)
	if(old_squad)
		if(transfer_marine.assigned_fireteam)
			if(old_squad.fireteam_leaders["FT[transfer_marine.assigned_fireteam]"] == transfer_marine)
				old_squad.unassign_ft_leader(transfer_marine.assigned_fireteam, TRUE, FALSE)
			old_squad.unassign_fireteam(transfer_marine, TRUE) //reset fireteam assignment
		old_squad.remove_marine_from_squad(transfer_marine, ID)
		old_squad.update_free_mar()
	. = new_squad.put_marine_in_squad(transfer_marine, ID)
	if(.)
		new_squad.update_free_mar()

		var/marine_ref = WEAKREF(transfer_marine)
		for(var/datum/data/record/t in GLOB.data_core.general) //we update the crew manifest
			if(t.fields["ref"] == marine_ref)
				t.fields["squad"] = new_squad.name
				break

		transfer_marine.hud_set_squad()

// returns TRUE if transfer_marine's role is at max capacity in the new squad
/datum/authority/branch/role/proc/check_squad_capacity(mob/living/carbon/human/transfer_marine, datum/squad/new_squad)
	var/slot_check
	var/real_job = GET_DEFAULT_ROLE(transfer_marine.job)
	if(real_job in JOB_SQUAD_LEADER_LIST)
		slot_check = "leaders"
	else if(real_job in JOB_SQUAD_SPEC_LIST)
		slot_check = "specialists"
	else if(real_job in JOB_SQUAD_MAIN_SUP_LIST)
		slot_check = "main_supports"
	else if(real_job in JOB_SQUAD_SUP_LIST)
		slot_check = "supports"
	else if(real_job in JOB_SQUAD_MEDIC_LIST)
		slot_check = "medics"
	else if(real_job in JOB_SQUAD_ENGI_LIST)
		slot_check = "engineers"
	if(new_squad.vars["num_[slot_check]"] >= new_squad.vars["max_[slot_check]"])
		return TRUE
	return FALSE
