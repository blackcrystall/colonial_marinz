/proc/Check_HVH()
	if(SSticker.mode == MODE_NAME_HUMAN_WARS || GLOB.master_mode == MODE_NAME_HUMAN_WARS)
		return TRUE
	return FALSE

/datum/game_mode/humanvs
	name = MODE_NAME_HUMAN_WARS
	config_tag = MODE_NAME_HUMAN_WARS
	required_players = 2
	end_game_announce = "Битва закончена, осталось лишь только убирать последствия и трупы... на"

	round_end_states = list(MODE_HVH_UPP_WIN, MODE_HVH_MARINE_WIN, MODE_HVH_WY_WIN, MODE_HVH_CLF_WIN, MODE_HVH_PEACE_CONFERENCE, MODE_HVH_NUCLEAR_DESTRUCTION)
	faction_round_end_state = list(FACTION_UPP = MODE_HVH_UPP_WIN, FACTION_MARINE = MODE_HVH_MARINE_WIN, FACTION_WY = MODE_HVH_WY_WIN, FACTION_CLF = MODE_HVH_CLF_WIN)

	faction_result_end_state = list(
		list("marine_major", list('sound/music/round_end/winning_triumph1.ogg', 'sound/music/round_end/winning_triumph2.ogg'), list('sound/music/round_end/bluespace.ogg')),
		list("marine_minor", list('sound/music/round_end/sad_loss1.ogg', 'sound/music/round_end/sad_loss2.ogg'), list('sound/music/round_end/end.ogg')),
		list("draw", list('sound/music/round_end/nuclear_detonation1.ogg', 'sound/music/round_end/nuclear_detonation2.ogg'), list('sound/music/round_end/issomebodysinging.ogg')),
	)

	flags_round_type = MODE_NEW_SPAWN|MODE_NO_SHIP_MAP
	static_comms_amount = 2

	vote_cycle = 5
	population_min = 20

	var/req_victory_points = 100000
	var/list/datum/faction_task/faction_mode_tasks

////////////////////////////////////////////////////////////////////////////////////////
/* Pre-pre-startup */
/datum/game_mode/humanvs/can_start()
	initialize_special_clamps()
	return TRUE

/datum/game_mode/humanvs/announce()
	to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDHEADER("В данный момент карта - [SSmapping.configs[GROUND_MAP].map_name]!"))

////////////////////////////////////////////////////////////////////////////////////////
/* Pre-setup */
/datum/game_mode/humanvs/pre_setup()
	if(prob(20))
		for(var/faction_name in factions_pool)
			var/datum/faction/faction = GLOB.faction_datums[factions_pool[faction_name]]
			faction.objectives_active = TRUE
			if(SSfactions.make_potential_tasks(faction, TRUE))
				break

	SSfactions.build_sectors()
	return ..()

////////////////////////////////////////////////////////////////////////////////////////
/* Post-setup */
//This happens after create_character, so our mob SHOULD be valid and built by now, but without job data.
//We move it later with transform_survivor but they might flicker at any start_loc spawn landmark effects then disappear.
//Xenos and survivors should not spawn anywhere until we transform them.
/datum/game_mode/humanvs/post_setup()
	initialize_post_marine_gear_list()

	if(SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_BASIC_RT])
		flags_round_type |= MODE_BASIC_RT

	round_time_lobby = world.time

	addtimer(CALLBACK(src, PROC_REF(map_announcement)), 20 SECONDS)

	return ..()

/datum/game_mode/humanvs/proc/map_announcement()
	if(SSmapping.configs[GROUND_MAP].announce_text)
		faction_announcement(SSmapping.configs[GROUND_MAP].announce_text, "[MAIN_SHIP_NAME]")

////////////////////////////////////////////////////////////////////////////////////////
//This is processed each tick, but check_win is only checked 5 ticks, so we don't go crazy with scanning for mobs.
/datum/game_mode/humanvs/process()
	. = ..()
	if(round_started > 0)
		round_started--
		return FALSE

	if(!round_finished)
		if(SSevacuation.ship_operation_stage_status == OPERATION_DECRYO && world.time > decryo_stage_timer)
			SSevacuation.ship_operation_stage_status = OPERATION_BRIEFING

		if(!active_lz && world.time > lz_selection_timer)
			for(var/obj/structure/machinery/computer/shuttle/dropship/flight/default_console in GLOB.machines)
				if(is_ground_level(default_console.z))
					select_lz(default_console)
					break

		if(++round_checkwin >= 5) //Only check win conditions every 5 ticks.
			if(round_should_check_for_win)
				check_win()
			round_checkwin = 0

///////////////////////////
//Checks to see who won///
//////////////////////////
/datum/game_mode/humanvs/check_win()
	if(SSticker.current_state != GAME_STATE_PLAYING)
		return

	var/list/alive_factions = list()
	for(var/faction_name in SSticker.mode.factions_pool)
		var/datum/faction/faction = GLOB.faction_datums[SSticker.mode.factions_pool[faction_name]]
		if(!length(faction.totalMobs))
			continue
		alive_factions += faction
		if(faction.faction_victory_points > req_victory_points)
			round_finished = faction_round_end_state[faction.faction_name]
			SSticker.mode.faction_won = faction

	if(length(alive_factions) > 1)
		return
	else if(length(alive_factions))
		var/datum/faction/faction = pick(alive_factions)
		if(faction)
			round_finished = faction_round_end_state[faction.faction_name]
			SSticker.mode.faction_won = faction
	else
		round_finished = MODE_HVH_PEACE_CONFERENCE

	return

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/humanvs/check_finished()
	if(round_finished)
		return TRUE

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relevant information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/humanvs/declare_completion()
	. = ..()

	declare_completion_announce_fallen_soldiers()
	declare_completion_announce_medal_awards()
	declare_fun_facts()


/datum/game_mode/humanvs/get_winners_states()
	var/list/icon_states = list()
	var/list/musical_tracks = list()
	var/sound/sound
	for(var/faction_name in factions_pool)
		var/pick = 1
		if(!faction_won)
			pick = 3
		else if(faction_won.faction_name != faction_name)
			pick = 2

		icon_states[faction_name] = faction_result_end_state[pick][1]
		sound = sound(pick(faction_result_end_state[pick][2]), channel = SOUND_CHANNEL_LOBBY)
		sound.status = SOUND_STREAM
		musical_tracks[faction_name] = sound
		sound = sound(pick(faction_result_end_state[pick][3]), channel = SOUND_CHANNEL_LOBBY)
		sound.status = SOUND_STREAM
		musical_tracks[faction_name] += sound

	return list(icon_states, musical_tracks)

/datum/game_mode/humanvs/defcon_event(datum/faction/faction, defcon)
	if(defcon == 5)
		on_nuclear_explosion()
		addtimer(VARSET_CALLBACK(src, round_finished, MODE_HVH_NUCLEAR_DESTRUCTION), 1 SECONDS)
