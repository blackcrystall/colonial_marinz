#define is_hive_living(faction) (!faction.hardcore || faction.living_xeno_queen)

/datum/game_mode/xenovs
	name = MODE_NAME_HIVE_WARS
	config_tag = MODE_NAME_HIVE_WARS
	required_players = 4 //Need at least 4 players
	xeno_required_num = 4 //Need at least four xenos.
	monkey_amount = 0.2 // Amount of monkeys per player
	end_game_announce = "Thus ends the story of the battling hives on"
	flags_round_type = MODE_NO_SPAWN|MODE_NO_LATEJOIN|MODE_XVX|MODE_RANDOM_HIVE

	faction_result_end_state = list(
		list("xeno_major", list('sound/music/round_end/winning_triumph1.ogg', 'sound/music/round_end/winning_triumph2.ogg'), list('sound/music/round_end/bluespace.ogg')),
		list("xeno_minor", list('sound/music/round_end/sad_loss1.ogg', 'sound/music/round_end/sad_loss2.ogg'), list('sound/music/round_end/end.ogg')),
	)

	var/list/structures_to_delete = list(/obj/effect/alien/weeds, /turf/closed/wall/resin, /obj/structure/mineral_door/resin, /obj/structure/bed/nest, /obj/item, /obj/structure/tunnel, /obj/structure/machinery/computer/shuttle_control, /obj/structure/machinery/defenses/sentry/premade)
	var/list/hives = list()
	var/list/hive_cores = list()

	var/sudden_death = FALSE
	var/time_until_sd = 90 MINUTES

	var/list/current_hives = list()

	var/hive_larva_interval_gain = 5 MINUTES

	var/round_time_larva_interval = 0
	var/round_time_sd = 0
	votable = FALSE // broken

/* Pre-pre-startup */
/datum/game_mode/xenovs/can_start(bypass_checks = FALSE)
	for(var/hivename in SSmapping.configs[GROUND_MAP].xvx_hives)
		if(readied_players > SSmapping.configs[GROUND_MAP].xvx_hives[hivename])
			hives += hivename
	xeno_starting_num = readied_players
	if(!initialize_starting_xenomorph_list(hives, TRUE) && !bypass_checks)
		hives.Cut()
		return FALSE
	return TRUE

/datum/game_mode/xenovs/announce()
	to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDHEADER("В данный момент карта - [SSmapping.configs[GROUND_MAP].map_name]!"))

/* Pre-setup */
/datum/game_mode/xenovs/pre_setup()
	monkey_types = SSmapping.configs[GROUND_MAP].monkey_types
	if(monkey_amount)
		if(monkey_types.len)
			for(var/i = min(round(monkey_amount*GLOB.clients.len), GLOB.monkey_spawns.len), i > 0, i--)

				var/turf/T = get_turf(pick_n_take(GLOB.monkey_spawns))
				var/monkey_to_spawn = pick(monkey_types)
				new monkey_to_spawn(T)


	for(var/atom/A in world)
		for(var/type in structures_to_delete)
			if(istype(A, type))
				if(istype(A, /turf))
					var/turf/T = A
					T.ScrapeAway()
				else
					qdel(A)

	round_time_sd = (time_until_sd + world.time)

	update_controllers()

	..()
	return TRUE

/datum/game_mode/xenovs/proc/update_controllers()
	//Update controllers while we're on this mode
	if(SSitem_cleanup)
		//Cleaning stuff more aggressively
		SSitem_cleanup.start_processing_time = 0
		SSitem_cleanup.percentage_of_garbage_to_delete = 1
		SSitem_cleanup.wait = 1 MINUTES
		SSitem_cleanup.next_fire = 1 MINUTES
		spawn(0)
			//Deleting Almayer, for performance!
			SSitem_cleanup.delete_almayer()

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

/* Post-setup */
//This happens after create_character, so our mob SHOULD be valid and built by now, but without job data.
//We move it later with transform_survivor but they might flicker at any start_loc spawn landmark effects then disappear.
//Xenos and survivors should not spawn anywhere until we transform them.
/datum/game_mode/xenovs/post_setup()
	initialize_post_xenomorph_list(GLOB.xeno_hive_spawns)

	round_time_lobby = world.time
	for(var/area/A in GLOB.all_areas)
		if(!(A.is_resin_allowed))
			A.is_resin_allowed = TRUE

	open_podlocks("map_lockdown")

	..()

/datum/game_mode/xenovs/proc/initialize_post_xenomorph_list(list/hive_spawns = GLOB.xeno_spawns)
	var/list/hive_spots = list()
	for(var/faction in hives)
		var/turf/spot = get_turf(pick(hive_spawns))
		hive_spots[GLOB.faction_datums[faction]] = spot
		hive_spawns -= spot

		current_hives += GLOB.faction_datums[faction].name

	for(var/datum/faction/faction in xenomorphs) //Build and move the xenos.
		for(var/datum/mind/ghost_mind in xenomorphs[faction])
			transform_xeno(ghost_mind, hive_spots[faction], faction, FALSE)
			ghost_mind.current.close_spawn_windows()

	// Have to spawn the queen last or the mind will be added to xenomorphs and double spawned
	for(var/datum/faction/faction in picked_queens)
		transform_queen(picked_queens[faction], hive_spots[faction], faction)
		var/datum/mind/M = picked_queens[faction]
		M.current.close_spawn_windows()

	for(var/datum/faction/faction in hive_spots)
		var/obj/effect/alien/resin/special/pylon/core/core = new(hive_spots[faction], faction)
		core.hardcore = TRUE // This'll make losing the hive core more detrimental than losing a Queen
		hive_cores += core

/datum/game_mode/xenovs/proc/transform_xeno(datum/mind/ghost_mind, turf/xeno_turf, datum/faction/faction = GLOB.faction_datums[FACTION_XENOMORPH_NORMAL], should_spawn_nest = TRUE)
	if(should_spawn_nest)
		var/mob/living/carbon/human/original = ghost_mind.current

		original.first_xeno = TRUE
		original.set_stat(UNCONSCIOUS)
		transform_survivor(ghost_mind, xeno_turf = xeno_turf) //Create a new host
		original.apply_damage(50, BRUTE)
		original.spawned_corpse = TRUE

		for(var/obj/item/device/radio/radio in original.contents_recursive())
			radio.listening = FALSE

		var/obj/structure/bed/nest/start_nest = new /obj/structure/bed/nest(original.loc) //Create a new nest for the host
		original.statistic_exempt = TRUE
		original.buckled = start_nest
		original.setDir(start_nest.dir)
		original.update_canmove()
		start_nest.buckled_mob = original
		start_nest.afterbuckle(original)

		var/obj/item/alien_embryo/embryo = new /obj/item/alien_embryo(original) //Put the initial larva in a host
		embryo.stage = 5 //Give the embryo a head-start (make the larva burst instantly)
		embryo.faction = faction
		if(original && !original.first_xeno)
			qdel(original)
	else
		var/mob/living/carbon/xenomorph/larva/xeno = new(xeno_turf, null, faction)
		ghost_mind.transfer_to(xeno)

/datum/game_mode/xenovs/pick_queen_spawn(datum/mind/ghost_mind, datum/faction/faction = GLOB.faction_datums[FACTION_XENOMORPH_NORMAL])
	. = ..()
	if(!.) return
	// Spawn additional hive structures
	var/turf/T  = .
	var/area/AR = get_area(T)
	if(!AR) return
	for(var/obj/effect/landmark/structure_spawner/xvx_hive/SS in AR)
		SS.apply()
		qdel(SS)

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

//This is processed each tick, but check_win is only checked 5 ticks, so we don't go crazy with scanning for mobs.
/datum/game_mode/xenovs/process()
	. = ..()
	if(round_started > 0)
		round_started--
		return FALSE

	if(!round_finished)
		if(++round_checkwin >= 5) //Only check win conditions every 5 ticks.
			if(world.time > round_time_larva_interval)
				for(var/faction in hives)
					var/datum/faction/hive = GLOB.faction_datums[faction]
					hive.stored_larva++
					hive.faction_ui.update_burrowed_larva()

				round_time_larva_interval = world.time + hive_larva_interval_gain

			if(!sudden_death && world.time > round_time_sd)
				sudden_death = TRUE
				xeno_announcement("The hives have entered sudden death mode. No more respawns, no more Queens", "everything", HIGHER_FORCE_ANNOUNCE)
				for(var/obj/effect/alien/resin/special/pylon/core/C in hive_cores)
					qdel(C)
				hive_cores = list()

			if(round_should_check_for_win)
				check_win()
			round_checkwin = 0


/datum/game_mode/xenovs/proc/get_xenos_hive(list/z_levels = SSmapping.levels_by_any_trait(list(ZTRAIT_GROUND, ZTRAIT_RESERVED, ZTRAIT_MARINE_MAIN_SHIP)))
	var/list/factions = list()
	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(!is_hive_living(faction))
			continue
		factions += list(faction.name = list())
		for(var/mob/living/carbon/xenomorph/xenomorph in faction.totalMobs)
			if(xenomorph.z && (xenomorph.z in z_levels) && !istype(xenomorph.loc, /turf/open/space))
				factions[faction.name] += xenomorph

	return factions

///////////////////////////
//Checks to see who won///
//////////////////////////
/datum/game_mode/xenovs/check_win()
	if(SSticker.current_state != GAME_STATE_PLAYING)
		return

	var/list/living_player_list = get_xenos_hive()

	var/datum/faction/last_living_hive
	var/living_hives = 0

	for(var/datum/faction/hive in living_player_list)
		if(length(living_player_list[hive]) > 0)
			living_hives++
			last_living_hive = hive
		else if(hive in current_hives)
			xeno_announcement("\The [hive] has been eliminated from the world", "everything", HIGHER_FORCE_ANNOUNCE)
			current_hives -= hive

	if(!living_hives)
		round_finished = "No one has won."
	else if(living_hives == 1)
		round_finished = "The [last_living_hive] has won."
		SSticker.mode.faction_won = last_living_hive

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/xenovs/check_finished()
	if(round_finished)
		return TRUE
	return FALSE

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relevant information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/xenovs/declare_completion()
	. = ..()

	declare_completion_announce_xenomorphs()
	calculate_end_statistics()
	declare_fun_facts()

/datum/game_mode/xenovs/announce_ending()
	log_game("Round end result: [round_finished]")
	to_chat_spaced(world, margin_top = 2, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDHEADER("|Раунд Закончен|"))
	to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDBODY("[end_game_announce] [SSmapping.configs[GROUND_MAP].map_name]. [round_finished]\nThe game-mode was: [GLOB.master_mode]!\n[CONFIG_GET(string/endofroundblurb)]"))

/datum/game_mode/xenovs/get_winners_states()
	var/list/icon_states = list()
	var/list/musical_tracks = list()
	var/sound/sound
	for(var/faction_name in factions_pool)
		var/pick = 2
		if(faction_won.faction_name == faction_name)
			pick = 1

		icon_states[faction_name] = faction_result_end_state[pick][1]
		sound = sound(pick(faction_result_end_state[pick][2]), channel = SOUND_CHANNEL_LOBBY)
		sound.status = SOUND_STREAM
		musical_tracks[faction_name] = sound
		sound = sound(pick(faction_result_end_state[pick][3]), channel = SOUND_CHANNEL_LOBBY)
		sound.status = SOUND_STREAM
		musical_tracks[faction_name] += sound

	return list(icon_states, musical_tracks)
