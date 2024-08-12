/proc/Check_DS()
	if(SSticker.mode == MODE_NAME_DISTRESS_SIGNAL || GLOB.master_mode == MODE_NAME_DISTRESS_SIGNAL)
		return TRUE
	return FALSE

#define HIJACK_EXPLOSION_COUNT 5
#define MARINE_MAJOR_ROUND_END_DELAY 3 MINUTES

/datum/game_mode/colonialmarines
	name = MODE_NAME_DISTRESS_SIGNAL
	config_tag = MODE_NAME_DISTRESS_SIGNAL
	required_players = 2
	xeno_required_num = 1
	monkey_amount = 5
	flags_round_type = MODE_INFESTATION|MODE_FOG_ACTIVATED|MODE_NEW_SPAWN
	static_comms_amount = 1
	var/round_status_flags
	round_end_states = list(MODE_INFESTATION_X_MAJOR, MODE_INFESTATION_M_MAJOR, MODE_INFESTATION_X_MINOR, MODE_INFESTATION_M_MINOR, MODE_INFESTATION_DRAW_DEATH)

	faction_result_end_state = list(
		FACTION_MARINE = list(
			MODE_INFESTATION_M_MAJOR = list("marine_major", list('sound/music/round_end/winning_triumph1.ogg', 'sound/music/round_end/winning_triumph2.ogg'), list('sound/music/round_end/issomebodysinging.ogg')),
			MODE_INFESTATION_M_MINOR = list("marine_major", list('sound/music/round_end/neutral_hopeful1.ogg', 'sound/music/round_end/neutral_hopeful2.ogg'), list()),
			MODE_INFESTATION_X_MINOR = list("marine_minor", list('sound/music/round_end/neutral_melancholy1.ogg', 'sound/music/round_end/neutral_melancholy2.ogg'), list('sound/music/round_end/bluespace.ogg')),
			MODE_INFESTATION_X_MAJOR = list("marine_minor", list('sound/music/round_end/sad_loss1.ogg', 'sound/music/round_end/sad_loss2.ogg'), list('sound/music/round_end/end.ogg')),
			MODE_GENERIC_DRAW_NUKE =  list("draw", list('sound/music/round_end/nuclear_detonation1.ogg', 'sound/music/round_end/nuclear_detonation2.ogg'), list()),
		),
		FACTION_XENOMORPH_NORMAL = list(
			MODE_INFESTATION_X_MAJOR = list("xeno_major", list('sound/music/round_end/winning_triumph1.ogg', 'sound/music/round_end/winning_triumph2.ogg'), list()),
			MODE_INFESTATION_X_MINOR = list("xeno_major", list('sound/music/round_end/neutral_hopeful1.ogg', 'sound/music/round_end/neutral_hopeful2.ogg'), list()),
			MODE_INFESTATION_M_MINOR = list("xeno_minor", list('sound/music/round_end/neutral_melancholy1.ogg', 'sound/music/round_end/neutral_melancholy2.ogg'), list('sound/music/round_end/bluespace.ogg')),
			MODE_INFESTATION_M_MAJOR = list("xeno_minor", list('sound/music/round_end/sad_loss1.ogg', 'sound/music/round_end/sad_loss2.ogg'), list('sound/music/round_end/end.ogg')),
			MODE_GENERIC_DRAW_NUKE =  list("draw", list('sound/music/round_end/nuclear_detonation1.ogg', 'sound/music/round_end/nuclear_detonation2.ogg'), list()),
		)
	)

	population_min = 10

	var/research_allocation_interval = 10 MINUTES
	var/next_research_allocation = 0
	var/next_stat_check = 0
	var/list/running_round_stats = list()

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

/* Pre-pre-startup */
/datum/game_mode/colonialmarines/can_start(bypass_checks = FALSE)
	if(!bypass_checks)
		var/list/datum/mind/possible_xenomorphs = get_players_for_role(JOB_XENOMORPH)
		var/list/datum/mind/possible_queens = get_players_for_role(JOB_XENOMORPH_QUEEN)
		if(possible_xenomorphs.len + possible_queens.len < xeno_required_num) //We don't have enough aliens, we don't consider people rolling for only Queen.
			to_world("Not enough players have chosen to be a xenomorph in their character setup. <b>Aborting</b>.")
			return FALSE

		var/players = 0
		for(var/mob/new_player/player in GLOB.new_player_list)
			if(player.client && player.ready)
				players++

		if(players < required_players)
			return FALSE

	initialize_special_clamps()
	return TRUE

/datum/game_mode/colonialmarines/announce()
	to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDHEADER("В данный момент карта - [SSmapping.configs[GROUND_MAP].map_name]!"))

////////////////////////////////////////////////////////////////////////////////////////
//Temporary, until we sort this out properly.
/obj/effect/landmark/lv624
	icon = 'icons/landmarks.dmi'

/obj/effect/landmark/lv624/fog_blocker
	name = "fog blocker"
	icon_state = "fog"

	var/time_to_dispel = 25 MINUTES

/obj/effect/landmark/lv624/fog_blocker/short
	time_to_dispel = 15 MINUTES

/obj/effect/landmark/lv624/fog_blocker/Initialize(mapload, ...)
	. = ..()

	return INITIALIZE_HINT_ROUNDSTART

/obj/effect/landmark/lv624/fog_blocker/LateInitialize()
	if(!(SSticker.mode.flags_round_type & MODE_FOG_ACTIVATED) || !SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_FOG])
		return

	new /obj/structure/blocker/fog(loc, time_to_dispel)
	qdel(src)

/obj/effect/landmark/lv624/xeno_tunnel
	name = "xeno tunnel"
	icon_state = "xeno_tunnel"

/obj/effect/landmark/lv624/xeno_tunnel/Initialize(mapload, ...)
	. = ..()
	GLOB.xeno_tunnels += src

/obj/effect/landmark/lv624/xeno_tunnel/Destroy()
	GLOB.xeno_tunnels -= src
	return ..()

////////////////////////////////////////////////////////////////////////////////////////

/* Pre-setup */
/datum/game_mode/colonialmarines/pre_setup()
	QDEL_LIST(GLOB.hunter_primaries)
	QDEL_LIST(GLOB.hunter_secondaries)
	QDEL_LIST(GLOB.crap_items)
	QDEL_LIST(GLOB.good_items)
	//desert river test
	if(!length(round_toxic_river))
		round_toxic_river = null //No tiles?
	else
		round_time_river = rand(-100,100)
		flags_round_type |= MODE_FOG_ACTIVATED

	..()

	var/obj/structure/tunnel/T
	var/i = 0
	var/turf/t
	while(length(GLOB.xeno_tunnels) && i++ < 3)
		t = get_turf(pick_n_take(GLOB.xeno_tunnels))
		T = new(t)
		T.id = "hole[i]"
	return TRUE

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

/* Post-setup */
//This happens after create_character, so our mob SHOULD be valid and built by now, but without job data.
//We move it later with transform_survivor but they might flicker at any start_loc spawn landmark effects then disappear.
//Xenos and survivors should not spawn anywhere until we transform them.
/datum/game_mode/colonialmarines/post_setup()
	initialize_post_marine_gear_list()
	spawn_smallhosts()

	if(SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_BASIC_RT])
		flags_round_type |= MODE_BASIC_RT

	addtimer(CALLBACK(src, PROC_REF(ares_online)), 5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(map_announcement)), 20 SECONDS)

	return ..()

#define MONKEYS_TO_TOTAL_RATIO 1/32

/datum/game_mode/colonialmarines/proc/spawn_smallhosts()
	if(!players_preassigned)
		return

	monkey_types = SSmapping.configs[GROUND_MAP].monkey_types

	if(!length(monkey_types))
		return

	var/amount_to_spawn = round(players_preassigned * MONKEYS_TO_TOTAL_RATIO)

	for(var/i in 0 to min(amount_to_spawn, length(GLOB.monkey_spawns)))
		var/turf/T = get_turf(pick_n_take(GLOB.monkey_spawns))
		var/monkey_to_spawn = pick(monkey_types)
		new monkey_to_spawn(T)

/datum/game_mode/colonialmarines/proc/map_announcement()
	if(SSmapping.configs[GROUND_MAP].announce_text)
		var/rendered_announce_text = replacetext(SSmapping.configs[GROUND_MAP].announce_text, "###SHIPNAME###", MAIN_SHIP_NAME)
		faction_announcement(rendered_announce_text, "[MAIN_SHIP_NAME]")

/datum/game_mode/colonialmarines/proc/ares_conclude()
	ai_silent_announcement("Bioscan complete. No unknown lifeform signature detected.", ".V")
	ai_silent_announcement("Saving operational report to archive.", ".V")
	ai_silent_announcement("Commencing final systems scan in 3 minutes.", ".V")

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

#define PODLOCKS_OPEN_WAIT (45 MINUTES) // CORSAT pod doors drop at 12:45

//This is processed each tick, but check_win is only checked 5 ticks, so we don't go crazy with scanning for mobs.
/datum/game_mode/colonialmarines/process()
	. = ..()
	if(round_started > 0)
		round_started--
		return FALSE

	if(is_in_endgame)
		check_hijack_explosions()
		check_ground_humans()

	if(next_research_allocation < world.time)
		chemical_data.update_credits(chemical_data.research_allocation_amount)
		next_research_allocation = world.time + research_allocation_interval

	if(!round_finished)
		for(var/faction_to_get in FACTION_LIST_ALL)
			var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
			if(!faction.xeno_queen_timer)
				continue

			if(!faction.living_xeno_queen && faction.xeno_queen_timer < world.time)
				xeno_message("Улей готов для эволюции новой королевы.", 3, faction)

		if(SSevacuation.ship_operation_stage_status == OPERATION_DECRYO && world.time > decryo_stage_timer)
			SSevacuation.ship_operation_stage_status = OPERATION_BRIEFING

		if(!active_lz && world.time > lz_selection_timer)
			select_lz(locate(/obj/structure/machinery/computer/shuttle/dropship/flight/lz1))

		// Automated bioscan / Queen Mother message
		if(world.time > bioscan_current_interval) //If world time is greater than required bioscan time.
			announce_bioscans() //Announce the results of the bioscan to both sides.
			bioscan_current_interval += bioscan_ongoing_interval //Add to the interval based on our set interval time.

		if(++round_checkwin >= 5) //Only check win conditions every 5 ticks.
			if(!(round_status_flags & ROUNDSTATUS_PODDOORS_OPEN))
				if(SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_LOCKDOWN])
					if(world.time >= (PODLOCKS_OPEN_WAIT + round_time_lobby))
						round_status_flags |= ROUNDSTATUS_PODDOORS_OPEN
						var/input = "Защитная блокировка будет снята через 30 секунд согласно автоматическому протоколу."
						var/name = "Automated Security Authority Announcement"
						faction_announcement(input, name, 'sound/AI/commandreport.ogg')
						for(var/i in GLOB.living_xeno_list)
							var/mob/M = i
							sound_to(M, sound(get_sfx("queen"), wait = 0, volume = 50))
							to_chat(M, SPAN_XENOANNOUNCE("The Queen Mother reaches into your mind from worlds away."))
							to_chat(M, SPAN_XENOANNOUNCE("Для моих детей и их Королевы. Я чувствую что большие двери ловушки откроются через 30 секунд."))
						addtimer(CALLBACK(src, PROC_REF(open_podlocks), "map_lockdown"), 300)
			if(round_should_check_for_win && SSticker.current_state == GAME_STATE_PLAYING)
				check_win()
			round_checkwin = 0

		if(!evolution_ovipositor_threshold && world.time >= SSticker.round_start_time + round_time_evolution_ovipositor)
			for(var/faction_to_get in FACTION_LIST_ALL)
				var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
				faction.evolution_without_ovipositor = FALSE
				if(faction.living_xeno_queen && !faction.living_xeno_queen.ovipositor)
					to_chat(faction.living_xeno_queen, SPAN_XENODANGER("Время сесть на яйцеклад и дать эволюцию детям."))
			evolution_ovipositor_threshold = TRUE
			msg_admin_niche("Ксеноморфам требуется Королева на яйцекладе.")

		if(!GLOB.resin_lz_allowed && world.time >= SSticker.round_start_time + round_time_resin)
			set_lz_resin_allowed(TRUE)

		if(next_stat_check <= world.time)
			add_current_round_status_to_end_results((next_stat_check ? "" : "Round Start"))
			next_stat_check = world.time + 30 MINUTES

/**
 * Primes and fires off the explodey-pipes during hijack.
 */
/datum/game_mode/colonialmarines/proc/check_hijack_explosions()
	if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_HIJACK_BARRAGE))
		return

	var/list/shortly_exploding_pipes = list()
	for(var/i = 1 to HIJACK_EXPLOSION_COUNT)
		shortly_exploding_pipes += pick(GLOB.mainship_pipes)

	for(var/obj/structure/pipes/exploding_pipe as anything in shortly_exploding_pipes)
		exploding_pipe.warning_explode(5 SECONDS)

	addtimer(CALLBACK(src, PROC_REF(shake_ship)), 5 SECONDS)
	TIMER_COOLDOWN_START(src, COOLDOWN_HIJACK_BARRAGE, 15 SECONDS)

#define GROUNDSIDE_XENO_MULTIPLIER 1.0

///Checks for humans groundside after hijack, spawns forsaken if requirements met
/datum/game_mode/colonialmarines/proc/check_ground_humans()
	if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_HIJACK_GROUND_CHECK))
		return

	var/groundside_humans = 0
	var/groundside_xenos = 0

	for(var/mob/current_mob in GLOB.player_list)
		if(!is_ground_level(current_mob.z) || !current_mob.client || current_mob.stat == DEAD)
			continue

		if(ishuman_strict(current_mob))
			groundside_humans++
			continue

		if(isxeno(current_mob))
			groundside_xenos++
			continue

	if(groundside_humans > (groundside_xenos * GROUNDSIDE_XENO_MULTIPLIER))
		SSticker.mode.get_specific_call("Xenomorphs Groundside (Forsaken)", TRUE, FALSE, FALSE, announce_dispatch_message = FALSE)

	TIMER_COOLDOWN_START(src, COOLDOWN_HIJACK_GROUND_CHECK, 1 MINUTES)

#undef GROUNDSIDE_XENO_MULTIPLIER

/**
 * Makes the mainship shake, along with playing a klaxon sound effect.
 */
/datum/game_mode/colonialmarines/proc/shake_ship()
	for(var/mob/current_mob in GLOB.living_mob_list)
		if(!is_mainship_level(current_mob.z))
			continue
		shake_camera(current_mob, 3, 1)

	playsound_z(SSmapping.levels_by_any_trait(list(ZTRAIT_MARINE_MAIN_SHIP)), 'sound/effects/double_klaxon.ogg', volume = 10)

#undef PODLOCKS_OPEN_WAIT

/datum/game_mode/colonialmarines/ds_first_drop(obj/docking_port/mobile/marine_dropship)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(show_blurb_uscm)), DROPSHIP_DROP_MSG_DELAY)
	add_current_round_status_to_end_results("First Drop")

/datum/game_mode/colonialmarines/ds_first_landed(obj/docking_port/mobile/marine_dropship)
	SSevacuation.ship_operation_stage_status = OPERATION_IN_PROGRESS
	if(world.time - GLOB.xenomorph_attack_delay > 15 MINUTES)
		GLOB.xenomorph_attack_delay = GLOB.xenomorph_attack_delay - (world.time - GLOB.xenomorph_attack_delay - 15 MINUTES)
	var/name = "[MAIN_AI_SYSTEM] Стадия Операции"
	var/input = "Операция [uppertext(round_statistics.round_name)]\n\n[game_time_timestamp("hhmm hrs")] (время в зоне операции [planet_game_time_timestamp("hh:mm:ss")]), [uppertext(time2text(REALTIMEOFDAY, "DD-MMM-[game_year]"))]\n\n\
				[SSmapping.configs[GROUND_MAP].map_name]\n\n\
				НАЧАТА\n\n\n\n\
				Примерное время [duration2text_hour_min_sec(GLOB.ship_hc_delay, "hh:mm:ss")] до получение трансляции Командыванием USCM"
	faction_announcement(input, name)
	. = ..()

///////////////////////////
//Checks to see who won///
//////////////////////////
/datum/game_mode/colonialmarines/check_win()
	var/living_player_list[] = count_humans_and_xenos(SSevacuation.get_affected_zlevels())
	var/num_humans = living_player_list[1]
	var/num_xenos = living_player_list[2]

	if(force_end_at && world.time > force_end_at)
		round_finished = MODE_INFESTATION_X_MINOR
		return

	if(!num_humans && !num_xenos)
		if(SSevacuation.dest_status == NUKE_EXPLOSION_FINISHED || SSevacuation.dest_status == NUKE_EXPLOSION_GROUND_FINISHED)
			round_finished = MODE_GENERIC_DRAW_NUKE
			return
		round_finished = MODE_INFESTATION_DRAW_DEATH

	else if(!num_humans)
		if(SSevacuation.dest_status == NUKE_EXPLOSION_FINISHED || SSevacuation.dest_status == NUKE_EXPLOSION_GROUND_FINISHED)
			round_finished = MODE_INFESTATION_X_MINOR
		if(SSticker.mode && SSticker.mode.is_in_endgame)
			round_finished = MODE_INFESTATION_X_MAJOR
		else
			round_finished = MODE_INFESTATION_X_MAJOR

	else if(!num_xenos)
		if(SSevacuation.dest_status == NUKE_EXPLOSION_FINISHED || SSevacuation.dest_status == NUKE_EXPLOSION_GROUND_FINISHED)
			round_finished = MODE_INFESTATION_M_MINOR
		if(SSticker.mode && SSticker.mode.is_in_endgame)
			round_finished = MODE_INFESTATION_M_MINOR
		else
			round_finished = MODE_INFESTATION_M_MAJOR

/datum/game_mode/colonialmarines/check_queen_status(datum/faction/faction)
	set waitfor = FALSE
	if(!(flags_round_type & MODE_INFESTATION))
		return
	xeno_queen_deaths++
	var/num_last_deaths = xeno_queen_deaths
	sleep(QUEEN_DEATH_COUNTDOWN)
	//We want to make sure that another queen didn't die in the interim.

	if(xeno_queen_deaths == num_last_deaths && !round_finished)
		if(!faction)
			for(var/faction_to_get in FACTION_LIST_ALL)
				faction = GLOB.faction_datums[faction_to_get]
				if(faction.living_xeno_queen && !is_admin_level(faction.living_xeno_queen.loc.z))
					//Some Queen is alive, we shouldn't end the game yet
					return
		else
			if(faction.living_xeno_queen && !is_admin_level(faction.living_xeno_queen.loc.z))
				//Some Queen is alive, we shouldn't end the game yet
				return
		round_finished = MODE_INFESTATION_M_MINOR

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/colonialmarines/check_finished()
	if(round_finished)
		return TRUE

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relevant information stated//
//////////////////////////////////////////////////////////////////////
#define MAJORITY 0.5 // What percent do we consider a 'majority?'

/datum/game_mode/colonialmarines/declare_completion()
	. = ..()

	declare_completion_announce_fallen_soldiers()
	declare_completion_announce_xenomorphs()
	declare_completion_announce_predators()
	declare_completion_announce_medal_awards()
	declare_fun_facts()


	add_current_round_status_to_end_results("Round End")
	handle_round_results_statistics_output()

	return TRUE

// for the toolbox
/datum/game_mode/colonialmarines/end_round_message()
	switch(round_finished)
		if(MODE_INFESTATION_X_MAJOR)
			return "Round has ended. Xeno Major Victory."
		if(MODE_INFESTATION_M_MAJOR)
			return "Round has ended. Marine Major Victory."
		if(MODE_INFESTATION_X_MINOR)
			return "Round has ended. Xeno Minor Victory."
		if(MODE_INFESTATION_M_MINOR)
			return "Round has ended. Marine Minor Victory."
		if(MODE_INFESTATION_DRAW_DEATH)
			return "Round has ended. Draw."
	return "Round has ended in a strange way."

/datum/game_mode/colonialmarines/proc/add_current_round_status_to_end_results(special_round_status as text)
	var/list/counted_mobs = list()
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(!length(faction.totalMobs) && !length(faction.totalDeadMobs))
			continue
		var/list/faction_payload = list("alive mobs" = list(), "dead mobs" = list())
		for(var/mob/mob in faction.totalMobs)
			if(istype(mob, /mob/living/carbon/xenomorph))
				var/mob/living/carbon/xenomorph/xeno = mob
				faction_payload["alive mobs"] += list("[xeno.name] as [xeno.mutation_type]")
			else
				if(istype(mob, /mob/living/carbon/human))
					var/mob/living/carbon/human/human = mob
					if(human.spawned_corpse)
						continue
				faction_payload["alive mobs"] += list("[mob.name] as [mob.job]")
		for(var/mob/mob in faction.totalDeadMobs)
			if(istype(mob, /mob/living/carbon/xenomorph))
				var/mob/living/carbon/xenomorph/xeno = mob
				faction_payload["dead mobs"] += list("[xeno.name] as [xeno.mutation_type]")
			else
				if(istype(mob, /mob/living/carbon/human))
					var/mob/living/carbon/human/human = mob
					if(human.spawned_corpse)
						continue
				faction_payload["dead mobs"] += list("[mob.name] as [mob.job]")
		counted_mobs[faction.name] = faction_payload

	var/list/total_data = list("special round status" = special_round_status, "round time" = duration2text(), "counted faction mobs" = counted_mobs)
	running_round_stats = running_round_stats + list(total_data)

/datum/game_mode/colonialmarines/proc/handle_round_results_statistics_output()
	var/list/data = list()
	for(var/list/round_status_report in running_round_stats)
		var/special_status = round_status_report["special round status"]
		var/round_time = round_status_report["round time"]

		var/field_name = "[special_status ? "[round_time] - [special_status]" : "[round_time]"]"

		var/job_final_text = ""
		var/list/job_report = round_status_report["counted faction mobs"]
		for(var/faction in job_report)
			var/list/alive_mob_report = job_report[faction]["alive mobs"]
			if(!length(alive_mob_report))
				continue
			var/list/dead_mob_report = job_report[faction]["dead mobs"]
			job_final_text += "\n\n**[faction]**\n"
			job_final_text += "\ntotal alive mobs ([length(alive_mob_report)]):\n"
			for(var/mob_info in alive_mob_report)
				job_final_text += "[mob_info]\n"
			job_final_text += "\ntotal dead mobs ([length(dead_mob_report)]):\n"
			for(var/mob_info in dead_mob_report)
				job_final_text += "[mob_info]\n"

		data += list(list("title" = "[field_name]", "desc" = "[job_final_text]"))

	REDIS_PUBLISH("byond.round", "type" = "statistic", "state" = "statistic", "statistic" = data)

#undef HIJACK_EXPLOSION_COUNT
#undef MARINE_MAJOR_ROUND_END_DELAY
#undef MAJORITY
