SUBSYSTEM_DEF(autobalancer)
	name = "Autobalancer"
	wait = 1 MINUTES
	priority = SS_PRIORITY_BALANCER
	flags = SS_NO_INIT|SS_POST_FIRE_TIMING
	runlevels = RUNLEVEL_LOBBY|RUNLEVEL_SETUP|RUNLEVEL_GAME|RUNLEVEL_POSTGAME

	var/list/faction_balance = list()
	var/list/balance_rows = list()
	var/list/potential_calculated_chance = list()

/datum/controller/subsystem/autobalancer/stat_entry(msg)
	if(length(potential_calculated_chance))
		msg = "WP:[potential_calculated_chance[2]] \[[potential_calculated_chance[3]]%\]"
	else
		msg = "LOADING"
	return ..()

/datum/controller/subsystem/autobalancer/Recover()
	faction_balance = SSautobalancer.faction_balance
	potential_calculated_chance = SSautobalancer.potential_calculated_chance

/datum/controller/subsystem/autobalancer/fire(resumed)
	var/list/faction_win_info = list()
	var/total_potential_power = 0
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		var/datum/autobalance_row_faction_info/autobalance_row = faction_balance[faction.faction_name]
		if(!autobalance_row || !faction.weight_act[SSticker.mode.name])
			continue

		var/potential_power = autobalance_row.esteminate_faction_info()
		total_potential_power += potential_power
		faction_win_info += list(list(faction, potential_power))

	if(!total_potential_power)
		return

	total_potential_power /= 100

	var/highest = 0
	var/datum/faction/last_faction
	for(var/list/potential_winner_list in faction_win_info)
		var/datum/faction/potential_winner = potential_winner_list[1]
		var/esteminated_chance = potential_winner_list[2] / total_potential_power
		if(esteminated_chance < highest)
			continue

		last_faction = potential_winner
		highest = esteminated_chance

	potential_calculated_chance = list(last_faction.faction_name, last_faction.name, highest)

/datum/controller/subsystem/autobalancer/proc/can_join(datum/faction/faction)
	var/datum/autobalance_row_faction_info/our_autobalance_row = faction_balance[faction.faction_name]
	if(!our_autobalance_row)
		our_autobalance_row = new /datum/autobalance_row_faction_info(faction)
		faction_balance[faction.faction_name] = our_autobalance_row

	for(var/faction_to_get in FACTION_LIST_ALL - faction.faction_name)
		var/datum/faction/next_faction = GLOB.faction_datums[faction_to_get]
		var/datum/autobalance_row_faction_info/autobalance_row = faction_balance[next_faction.faction_name]
		if(autobalance_row && next_faction.spawning_enabled && length(next_faction.roles_list[SSticker.mode.name]) && next_faction.weight_act[SSticker.mode.name] && (autobalance_row.weight + round(length(GLOB.clients) / 4, 1)) * 1.5 < our_autobalance_row.weight)
			return FALSE
	return TRUE

/datum/controller/subsystem/autobalancer/proc/balance_action(mob/player_mob, action)
	if(!player_mob?.client?.player_data?.player_entity || !player_mob.faction)
		return

	switch(action)
		if("add")
			var/datum/autobalance_row_info/information = balance_rows[player_mob.ckey]
			if(!information)
				information = new /datum/autobalance_row_info(player_mob.client.player_data.player_entity)
				balance_rows[player_mob.ckey] = information
			information.status_change(action)
		if("remove")
			QDEL_NULL(balance_rows[player_mob.ckey])
		else
			if(!player_mob.client)
				return

			var/datum/autobalance_row_info/information = balance_rows[player_mob.ckey]
			if(!information)
				information = new /datum/autobalance_row_info(player_mob.client.player_data.player_entity)
				balance_rows[player_mob.ckey] = information
			information.status_change(action)

/datum/controller/subsystem/autobalancer/proc/round_start()
	for(var/faction_to_get in faction_balance)
		var/datum/autobalance_row_faction_info/autobalance_row = faction_balance[faction_to_get]
		autobalance_row.round_start()
