//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/*
 * GAMEMODES (by Rastaf0)
 *
 * In the new mode system all special roles are fully supported.
 * You can have proper wizards/traitors/changelings/cultists during any mode.
 * Only two things really depends on gamemode:
 * 1. Starting roles, equipment and preparations
 * 2. Conditions of finishing the round.
 *
 */

var/global/cas_tracking_id_increment = 0 //this var used to assign unique tracking_ids to tacbinos and signal flares

/datum/game_mode
	var/name = "invalid"
	var/config_tag = null
	var/votable = TRUE
	var/vote_cycle = null
	var/probability = 0
	var/end_game_announce = "Так заканчивается история бравых мужчин и женщин экипажа ###SHIPNAME### и их борьба на"
	var/list/round_end_states = list()
	var/list/faction_round_end_state = list()
	var/list/faction_result_end_state = list()
	var/list/datum/mind/modePlayer = new
	var/required_players = 0
	var/required_players_secret = 0 //Minimum number of players for that game mode to be chose in Secret
	var/ert_disabled = 0
	var/force_end_at = 0
	var/xeno_evo_speed = 0 // if not 0 - gives xeno an evo boost/nerf
	var/is_in_endgame = FALSE //Set it to TRUE when we trigger DELTA alert or dropship crashes
	/// When set and this gamemode is selected, the taskbar icon will change to the png selected here
	var/taskbar_icon = 'icons/taskbar/gml_distress.png'
	var/static_comms_amount = 0
	var/obj/structure/machinery/computer/shuttle/dropship/flight/active_lz = null

	var/datum/faction/faction_won = null

	var/datum/entity/statistic_round/round_statistics = null

	var/list/active_roles_mappings_pool = list()
	var/list/active_roles_pool = list()
	var/list/factions_pool = list()

	var/population_min = null
	var/population_max = null

	var/planet_nuked = NUKE_NONE

/datum/game_mode/New()
	..()
	if(taskbar_icon)
		GLOB.available_taskbar_icons |= taskbar_icon

	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(length(faction.roles_list[name]))
			factions_pool[faction.name] = faction.faction_name
			active_roles_mappings_pool += faction.role_mappings[name]
			for(var/i in faction.roles_list[name])
				active_roles_pool += i

/datum/game_mode/proc/announce() //to be calles when round starts
	to_world("<B>Notice</B>: [src] did not define announce()")

///can_start()
///Checks to see if the game can be setup and ran with the current number of players or whatnot.
/datum/game_mode/proc/can_start(bypass_checks = FALSE)
	if(bypass_checks)
		return TRUE
	var/playerC = 0
	for(var/mob/new_player/player in GLOB.new_player_list)
		if(player.client && player.ready)
			playerC++

	if(GLOB.master_mode == "secret")
		if(playerC >= required_players_secret)
			return TRUE
	else
		if(playerC >= required_players)
			return TRUE
	return FALSE


///pre_setup()
///Attempts to select players for special roles the mode might have.
/datum/game_mode/proc/pre_setup()
	SHOULD_CALL_PARENT(TRUE)
	setup_structures()
	if(static_comms_amount)
		spawn_static_comms()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MODE_PRESETUP)
	return TRUE

///Triggered partway through the first drop, based on DROPSHIP_DROP_MSG_DELAY. Marines are underway but haven't yet landed.
/datum/game_mode/proc/ds_first_drop(obj/docking_port/mobile/marine_dropship)
	return

///Triggered when the dropship first lands.
/datum/game_mode/proc/ds_first_landed(obj/docking_port/stationary/marine_dropship)
	SHOULD_CALL_PARENT(TRUE)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_DS_FIRST_LANDED)
	return

/// Spawn structures relevant to the game mode setup, done before actual game setup. By default try to setup everything.
/datum/game_mode/proc/setup_structures()
	for(var/obj/effect/landmark/structure_spawner/setup/SS in GLOB.structure_spawners)
		SS.apply()

///post_setup()
///Everyone should now be on the station and have their normal gear.  This is the place to give the special roles extra things
/datum/game_mode/proc/post_setup()
	SHOULD_CALL_PARENT(TRUE)
	for(var/obj/effect/landmark/structure_spawner/SS in GLOB.structure_spawners)
		SS.post_setup()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MODE_POSTSETUP)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(display_roundstart_logout_report)), ROUNDSTART_LOGOUT_REPORT_TIME)

	for(var/mob/new_player/np in GLOB.new_player_list)
		np.new_player_panel_proc()
	round_time_lobby = world.time
	log_game("Round started at [time2text(world.realtime)]")
	if(SSticker.mode)
		log_game("Game mode set to [SSticker.mode]")
	log_game("Server IP: [world.internet_address]:[world.port]")
	return TRUE


///process()
///Called by the gameticker
/datum/game_mode/process()
	return FALSE


/datum/game_mode/proc/check_finished() //to be called by ticker
	if(SSevacuation.dest_status == NUKE_EXPLOSION_FINISHED || SSevacuation.dest_status == NUKE_EXPLOSION_GROUND_FINISHED)
		return TRUE

/datum/game_mode/proc/cleanup() //This is called when the round has ended but not the game, if any cleanup would be necessary in that case.
	return

/datum/game_mode/proc/announce_ending()
	to_chat_spaced(world, margin_top = 2, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDHEADER("|Раунд Закончен|"))
	var/rendered_announce_text = replacetext(end_game_announce, "###SHIPNAME###", MAIN_SHIP_NAME)
	to_chat_spaced(world, type = MESSAGE_TYPE_SYSTEM, html = SPAN_ROUNDBODY("[rendered_announce_text] [SSmapping.configs[GROUND_MAP].map_name].\nИгровой режим был: [GLOB.master_mode]!\n[CONFIG_GET(string/endofroundblurb)]"))

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relevant information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/declare_completion()
	var/clients = 0
	var/surviving_humans = 0
	var/surviving_total = 0
	var/ghosts = 0

	for(var/mob/M in GLOB.player_list)
		if(M.client)
			clients++
			if(ishuman(M))
				if(!M.stat)
					surviving_humans++

			if(!M.stat)
				surviving_total++

			if(isobserver(M))
				ghosts++

	if(clients > 0)
		log_game("Конец раунда - клиенты: [clients]")

	if(ghosts > 0)
		log_game("Конец раунда - наблюдатели: [ghosts]")

	if(surviving_humans > 0)
		log_game("Конец раунда - люди: [surviving_humans]")

	if(surviving_total > 0)
		log_game("Конец раунда - всего: [surviving_total]")

	announce_ending()

	var/list/winners_info = get_winners_states()

	log_game("Результат раунда - [round_finished]")
	if(round_statistics)
		round_statistics.game_mode = name
		round_statistics.round_length = world.time
		round_statistics.round_result = round_finished
		if(!length(round_statistics.current_map.victories))
			round_statistics.current_map.victories = list()
		round_statistics.current_map.victories[round_finished]++
		round_statistics.end_round_player_population = length(GLOB.clients)

		round_statistics.log_round_statistics()
		round_statistics.track_round_end()

	calculate_end_statistics()
	show_end_statistics(winners_info[1], winners_info[2], winners_info[3])
	return TRUE

/datum/game_mode/proc/get_winners_states()
	var/list/icon_states = list()
	var/list/musical_tracks = list()
	var/list/standart_payload = list()
	standart_payload += "draw"
	var/sound/sound = sound(pick('sound/music/round_end/sad_loss1.ogg', 'sound/music/round_end/sad_loss2.ogg', 'sound/music/round_end/neutral_melancholy1.ogg', 'sound/music/round_end/neutral_melancholy2.ogg'), channel = SOUND_CHANNEL_LOBBY)
	sound.status = SOUND_STREAM
	standart_payload += sound
	sound = sound(pick('sound/music/round_end/end.ogg'), channel = SOUND_CHANNEL_LOBBY)
	sound.status = SOUND_STREAM
	standart_payload += sound
	for(var/faction_name in factions_pool)
		if(faction_result_end_state[faction_name])
			icon_states[faction_name] = faction_result_end_state[faction_name][round_finished][1]
			sound = sound(pick(faction_result_end_state[faction_name][round_finished][2]), channel = SOUND_CHANNEL_LOBBY)
			sound.status = SOUND_STREAM
			musical_tracks[faction_name] = list(sound)
			sound = sound(pick(faction_result_end_state[faction_name][round_finished][3]), channel = SOUND_CHANNEL_LOBBY)
			sound.status = SOUND_STREAM
			musical_tracks[faction_name] += sound
		else
			icon_states[faction_name] = standart_payload[1]
			musical_tracks[faction_name] = list(standart_payload[2], standart_payload[3])


	return list(icon_states, musical_tracks, standart_payload)

/datum/game_mode/proc/calculate_end_statistics()
	for(var/i in GLOB.alive_mob_list)
		var/mob/M = i
		M.life_time_total = world.time - M.life_time_start
		M.track_death_calculations()
		M.statistic_exempt = TRUE

		if(M.client && M.client.player_data)
			if(M.stat == DEAD)
				record_playtime(M.client.player_data, JOB_OBSERVER, type)
			else
				record_playtime(M.client.player_data, M.job, type)

/datum/game_mode/proc/show_end_statistics(icon_states, musical_tracks, standart_payload)
	var/list/mobs = list()
	for(var/faction_name in factions_pool)
		var/faction_to_get = factions_pool[faction_name]
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		for(var/mob/mob in faction.totalMobs)
			if(mob.client)
				mobs += mob
				give_action(mob, /datum/action/show_round_statistics, null, icon_states[faction_to_get])
				sound_to(mob, musical_tracks[faction.name][1])
				if(length(musical_tracks[faction_to_get]) > 1)
					spawn(20 SECONDS)
						sound_to(mob, musical_tracks[faction_to_get][2])

	for(var/mob/mob in GLOB.player_list - mobs)
		if(mob.client)
			give_action(mob, /datum/action/show_round_statistics, null, standart_payload[1])
			sound_to(mob, standart_payload[2])
			if(length(standart_payload) > 2)
				spawn(20 SECONDS)
					sound_to(mob, standart_payload[3])

/datum/game_mode/proc/check_win() //universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
	return FALSE

/datum/game_mode/proc/get_players_for_role(role, override_jobbans = 0)
	var/list/players = list()
	var/list/candidates = list()

	var/ban_check = role
	switch(role)
		if(JOB_XENOMORPH)
			ban_check = JOB_XENOMORPH
		if(JOB_XENOMORPH_QUEEN)
			ban_check = JOB_XENOMORPH_QUEEN

	//Assemble a list of active players without jobbans.
	for(var/mob/new_player/player in GLOB.player_list)
		if(player.client && player.ready)
			if(!jobban_isbanned(player, ban_check))
				players += player

	//Shuffle the players list so that it becomes ping-independent.
	players = shuffle(players)

	//Get a list of all the people who want to be the antagonist for this round
	for(var/mob/new_player/player in players)
		if(player.client.prefs.get_job_priority(role) > 0)
			log_debug("[player.key] had [role] enabled, so we are drafting them.")
			candidates += player.mind
			players -= player

	return candidates //Returns: The number of people who had the antagonist role set to yes


///////////////////////////////////
//Keeps track of all living heads//
///////////////////////////////////
/datum/game_mode/proc/get_living_heads()
	var/list/heads = list()
	for(var/i in GLOB.alive_human_list)
		var/mob/living/carbon/human/player = i
		if(player.stat!=2 && player.mind && (player.job in ROLES_COMMAND))
			heads += player.mind
	return heads


////////////////////////////
//Keeps track of all heads//
////////////////////////////
/datum/game_mode/proc/get_all_heads()
	var/list/heads = list()
	for(var/mob/player in GLOB.mob_list)
		if(player.mind && (player.job in ROLES_COMMAND))
			heads += player.mind
	return heads

/datum/game_mode/proc/spawn_static_comms()
	for(var/i = 1 to static_comms_amount)
		var/obj/effect/landmark/static_comms/SCO = pick_n_take(GLOB.comm_tower_landmarks_net_one)
		var/obj/effect/landmark/static_comms/SCT = pick_n_take(GLOB.comm_tower_landmarks_net_two)
		if(SCO)
			SCO.spawn_tower()
		if(SCT)
			SCT.spawn_tower()
	QDEL_NULL_LIST(GLOB.comm_tower_landmarks_net_one)
	QDEL_NULL_LIST(GLOB.comm_tower_landmarks_net_two)


//////////////////////////
//Reports player logouts//
//////////////////////////
/proc/display_roundstart_logout_report()
	var/msg = FONT_SIZE_LARGE("<b>Отчет о покидание игры\n\n")
	for(var/i in GLOB.living_mob_list)
		var/mob/living/L = i

		if(L.ckey)
			var/found = 0
			for(var/client/C in GLOB.clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[key_name(L)]</b>, the [L.job] (<font color='#ffcc00'><b>Отключен</b></font>)\n"


		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME * 0.5)) //Connected, but inactive (alt+tabbed or something)
				msg += "<b>[key_name(L)]</b>, the [L.job] (<font color='#ffcc00'><b>Подключен, Неактивный</b></font>)\n"
				continue //AFK client
			if(L.stat)
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[key_name(L)]</b>, на [L.job] (Умирает)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[key_name(L)]</b>, на [L.job] (Умер)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/dead/observer/D in GLOB.observer_list)
			if(D.mind && (D.mind.original == L || D.mind.current == L))
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), на [L.job] (Умер)\n"
					continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), на [L.job] (<font color='red'><b>Невозможно определить.</b></font>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), на [L.job] (<font color='red'><b>Покинул тело</b></font>)\n"
						continue //Ghosted while alive

	for(var/mob/M in GLOB.player_list)
		if(M.client.admin_holder && (M.client.admin_holder.rights & R_MOD))
			to_chat_spaced(M, html = msg)

//Announces objectives/generic antag text.
/proc/show_generic_antag_text(datum/mind/player)
	if(player.current)
		player.current << \
		"You are an antagonist! <font color=blue>Within the rules,</font> \
		try to act as an opposing force to the crew. Further RP and try to make sure \
		other players have <i>fun</i>! If you are confused or at a loss, always adminhelp, \
		and before taking extreme actions, please try to also contact the administration! \
		Think through your actions and make the roleplay immersive! <b>Please remember all \
		rules aside from those without explicit exceptions apply to antagonists.</b>"


/////////////////
//Defcon events//
/////////////////
/datum/game_mode/proc/defcon_event(datum/faction/faction, defcon)
	return FALSE

/datum/game_mode/proc/on_nuclear_diffuse(obj/structure/machinery/nuclearbomb/bomb, mob/living/carbon/xenomorph/xenomorph)
	return FALSE

/datum/game_mode/proc/on_nuclear_explosion(datum/source, list/z_levels = SSmapping.levels_by_trait(ZTRAIT_GROUND))
	planet_nuked = NUKE_INPROGRESS
	faction_announcement("DANGER. DANGER. Planetary Nuke Activated. DANGER. DANGER. Activation in progress. DANGER. DANGER.", "Priority Alert", sound('sound/effects/explosionfar.ogg', 'sound/music/round_end/nuclear_detonation1.ogg', 'sound/music/round_end/nuclear_detonation2.ogg'), "Everyone (-Yautja)")
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/game_mode, play_cinematic), z_levels, list("intro_planet", "intro_planet", "planet_nuke", "planet_end"), create_cause_data("взрыва ядерной боеголовки", source))
	addtimer(VARSET_CALLBACK(src, planet_nuked, NUKE_COMPLETED), 5 SECONDS)

/datum/game_mode/proc/play_cinematic(list/z_levels = SSmapping.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP), cinematic_icons = list("intro_ship", "intro_nuke", "ship_spared", "summary_spared"), datum/cause_data/cause_data, explosion_sound = list('sound/effects/explosionfar.ogg'))
	var/L1[] = new //Everyone who will be destroyed on the zlevel(s).
	var/L2[] = new //Everyone who only needs to see the cinematic.
	var/mob/mob
	var/turf/T
	var/atom/movable/screen/cinematic/explosion/cinematic = new
	cinematic.icon_state = cinematic_icons[1]
	world << sound('sound/effects/explosionfar.ogg')
	for(mob in GLOB.player_list) //This only does something cool for the people about to die, but should prove pretty interesting.
		if(!mob || !mob.loc || !mob.client)
			continue //In case something changes when we sleep().
		if(mob.stat == DEAD)
			L2 |= mob
			mob << sound(pick(explosion_sound))
			mob.client.screen |= cinematic
		else if(mob.z in z_levels)
			L1 |= mob
			mob << sound(pick(explosion_sound))
			mob.client.screen |= cinematic
			shake_camera(mob, 110, 2)

	sleep(15) //Extra 1.5 seconds to look at the ship.
	flick(cinematic_icons[2], cinematic)
	sleep(35)
	for(mob in L1)
		if(mob && mob.loc) //Who knows, maybe they escaped, or don't exist anymore.
			T = get_turf(mob)
			if(T.z in z_levels)
				mob.death(cause_data)
			else
				mob.client.screen -= cinematic //those who managed to escape the z level at last second shouldn't have their view obstructed.

	flick(cinematic_icons[3], cinematic)
	cinematic.icon_state = cinematic_icons[4]

	sleep(2 SECONDS)
	for(mob in L1 + L2)
		if(mob && mob.client)
			mob.client.screen -= cinematic //They may have disconnected in the mean time.
	qdel(cinematic)
