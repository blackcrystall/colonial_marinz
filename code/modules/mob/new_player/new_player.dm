/mob/new_player
	var/ready = FALSE
	var/spawning = FALSE//Referenced when you want to delete the new_player later on in the code.

	invisibility = 101

	density = FALSE
	canmove = FALSE
	anchored = TRUE
	universal_speak = TRUE
	stat = DEAD

	var/datum/queued_player/que_data

/mob/new_player/Initialize()
	. = ..()
	GLOB.new_player_list += src
	GLOB.dead_mob_list -= src

/mob/new_player/Destroy()
	if(ready)
		readied_players--
	GLOB.new_player_list -= src
	return ..()

/mob/new_player/verb/new_player_panel()
	set src = usr
	if(client)
		new_player_panel_proc()

/mob/new_player/proc/new_player_panel_proc(refresh = FALSE)
	if(!client)
		return

	var/tempnumber = rand(1, 999)
	var/postfix_text = (client.prefs && client.prefs.xeno_postfix) ? ("-"+client.prefs.xeno_postfix) : ""
	var/prefix_text = (client.prefs && client.prefs.xeno_prefix) ? client.prefs.xeno_prefix : "XX"
	var/xeno_text = "[prefix_text]-[tempnumber][postfix_text]"
	var/round_start = !SSticker || !SSticker.mode || SSticker.current_state <= GAME_STATE_PREGAME

	var/output = "<div align='center'>[client.auto_lang(LANGUAGE_WELCOME)],"
	output +="<br><b>[client.key]</b>"
	output +="<br><b>[(client.prefs && client.prefs.real_name) ? client.prefs.real_name : client.key]</b>"
	output +="<br><b>[xeno_text]</b>"
	output += "<p><a href='byond://?src=\ref[src];lobby_choice=show_preferences'>[client.auto_lang(LANGUAGE_LOBBY_PREFS)]</A></p>"

	output += "<p><a href='byond://?src=\ref[src];lobby_choice=show_playtimes'>[client.auto_lang(LANGUAGE_LOBBY_PLAYTIME)]</A></p>"

	output += "<p><a href='byond://?src=\ref[src];lobby_choice=show_statistics'>[client.auto_lang(LANGUAGE_LOBBY_STATISTIC)]</A></p>"

	if(round_start)
		output += "<p>\[ [ready? "<b>[client.auto_lang(LANGUAGE_LOBBY_READY)]</b>":"<a href='byond://?src=\ref[src];lobby_choice=ready'>[client.auto_lang(LANGUAGE_LOBBY_READY)]</a>"] | [ready? "<a href='byond://?src=\ref[src];lobby_choice=unready'>[client.auto_lang(LANGUAGE_LOBBY_NOT_READY)]</a>":"<b>[client.auto_lang(LANGUAGE_LOBBY_NOT_READY)]</b>"] \]</p>"
		output += "<b>[client.auto_lang(LANGUAGE_PREF_SET_XENO)]:</b> [(client.prefs && (client.prefs.get_job_priority(JOB_XENOMORPH))) ? client.auto_lang(LANGUAGE_YES) : client.auto_lang(LANGUAGE_NO)]"

	else
		output += "<a href='byond://?src=\ref[src];lobby_choice=manifest'>[client.auto_lang(LANGUAGE_MANIFEST)]</A><br><br>"
		output += "<a href='byond://?src=\ref[src];lobby_choice=hiveleaders'>[client.auto_lang(LANGUAGE_LOBBY_HIVE_LEADERS)]</A><br><br>"
		output += "<p><a href='byond://?src=\ref[src];lobby_choice=late_join'>[client.auto_lang(LANGUAGE_LOBBY_JOIN)]</A></p>"

	output += "<p><a href='byond://?src=\ref[src];lobby_choice=observe'>[client.auto_lang(LANGUAGE_LOBBY_SPECTATE)]</A></p>"

	output += "</div>"
	if(refresh)
		close_browser(src, "lobby")
	show_browser(src, output, client.auto_lang(LANGUAGE_LOBBY), "lobby", "size=240x500;can_close=0;can_minimize=0")
	return

/mob/new_player/Topic(href, href_list[])
	. = ..()
	if(.)
		return
	if(!client)
		return

	switch(href_list["lobby_choice"])
		if("show_preferences")
			// Otherwise the preview dummy will runtime
			// because atoms aren't initialized yet
			if(SSticker.current_state < GAME_STATE_PREGAME)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT)))
				return
			if(!SSentity_manager.initialized)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT_DB)))
				return
			client.prefs.ShowChoices(src)
			return 1

		if("show_playtimes")
			if(SSticker.current_state < GAME_STATE_PREGAME)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT)))
				return
			if(!SSentity_manager.initialized)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT_DB)))
				return
			if(client.player_data)
				client.player_data.tgui_interact(src)
			return 1

		if("show_statistics")
			if(SSticker.current_state < GAME_STATE_PREGAME)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT)))
				return
			if(!SSentity_manager.initialized)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT_DB)))
				return
			if(client?.player_data?.player_entity)
				client.player_data.player_entity.tgui_interact(src)
			return 1

		if("ready")
			if( (SSticker.current_state <= GAME_STATE_PREGAME) && !ready) // Make sure we don't ready up after the round has started
				ready = TRUE
				readied_players++

			new_player_panel_proc()

		if("unready")
			if((SSticker.current_state <= GAME_STATE_PREGAME) && ready) // Make sure we don't ready up after the round has started
				ready = FALSE
				readied_players--

			new_player_panel_proc()

		if("refresh")
			new_player_panel_proc(TRUE)

		if("observe")
			if(!SSticker || SSticker.current_state == GAME_STATE_STARTUP)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_WAIT)))
				return
			if(alert(src, client.auto_lang(LANGUAGE_LOBBY_GO_SPECTATE), client.auto_lang(LANGUAGE_LOBBY_PREFS), client.auto_lang(LANGUAGE_YES), client.auto_lang(LANGUAGE_NO)) == client.auto_lang(LANGUAGE_YES))
				if(!client)
					return TRUE
				if(!client.prefs?.preview_dummy)
					client.prefs.update_preview_icon()

				var/mob/dead/observer/observer = new /mob/dead/observer(null, client.prefs.preview_dummy)
				observer.set_lighting_alpha_from_pref(client)
				spawning = TRUE
				observer.started_as_observer = TRUE

				close_spawn_windows()

				var/obj/effect/landmark/observer_start/O = SAFEPICK(GLOB.observer_starts)
				if(istype(O))
					to_chat(src, SPAN_NOTICE(client.auto_lang(LANGUAGE_LOBBY_TELEPORTING)))
					observer.forceMove(O.loc)
				else
					to_chat(src, SPAN_DANGER(client.auto_lang(LANGUAGE_LOBBY_TELEPORTING_UNABLE)))
				observer.icon = 'icons/mob/humans/species/r_human.dmi'
				observer.icon_state = "anglo_example"
				observer.alpha = 127

				if(client.prefs.be_random_name)
					client.prefs.real_name = random_name(client.prefs.gender)
				observer.real_name = client.prefs.real_name
				observer.name = observer.real_name

				mind.transfer_to(observer, TRUE)

				if(observer.client)
					observer.client.change_view(world_view_size)

				observer.set_huds_from_prefs()

				qdel(src)
				return 1

		if("late_join")
			if(SSticker.current_state != GAME_STATE_PLAYING || !SSticker.mode)
				to_chat(src, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_ROUND_NO_JOIN)))
				return

			if(MODE_HAS_FLAG(MODE_NO_LATEJOIN))
				to_chat(src, SPAN_WARNING(replacetext(client.auto_lang(LANGUAGE_LOBBY_NO_LATEJOIN), "###MODE_NAME###", "[SSticker.mode.name]")))
				return

			if(client.prefs.species != "Human")
				if(!is_alien_whitelisted(src, client.prefs.species) && CONFIG_GET(flag/usealienwhitelist))
					to_chat(src, "You are currently not whitelisted to play [client.prefs.species].")
					return

				var/datum/species/S = GLOB.all_species[client.prefs.species]
				if(!(S.species_flags & IS_WHITELISTED))
					to_chat(src, alert("Your current species, [client.prefs.species], is not available for play on the station."))
					return

			LateChoices()

		if("manifest")
			ViewManifest()

		if("hiveleaders")
			ViewHiveLeaders()

		if("SelectedJob")
			if(!enter_allowed)
				to_chat(usr, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_JOIN_LOCK)))
				return

			if(client.prefs.species != "Human")
				if(!is_alien_whitelisted(src, client.prefs.species) && CONFIG_GET(flag/usealienwhitelist))
					to_chat(src, alert("You are currently not whitelisted to play [client.prefs.species]."))
					return 0

				var/datum/species/S = GLOB.all_species[client.prefs.species]
				if(!(S.species_flags & IS_WHITELISTED))
					to_chat(src, alert("Your current species,[client.prefs.species], is not available for play on the station."))
					return 0

			AttemptLateSpawn(href_list["job_selected"])
			return

		else
			new_player_panel()

/mob/new_player/proc/AttemptLateSpawn(rank)
	var/datum/job/player_rank = SSticker.role_authority.roles_for_mode[rank]
	if(src != usr)
		return
	if(SSticker.current_state != GAME_STATE_PLAYING)
		to_chat(usr, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_ROUND_NO_JOIN)))
		return
	if(!enter_allowed)
		to_chat(usr, SPAN_WARNING(client.auto_lang(LANGUAGE_LOBBY_JOIN_LOCK)))
		return
	if(!SSticker.role_authority.assign_role(src, GET_MAPPED_ROLE(player_rank), 1))
		to_chat(src, alert("[rank] [client.auto_lang(LANGUAGE_LOBBY_RANK_LOCKED)]"))
		return

	spawning = TRUE
	close_spawn_windows()

	var/mob/living/carbon/human/character = create_character(TRUE) //creates the human and transfers vars and mind
	SSticker.role_authority.equip_role(character, GET_MAPPED_ROLE(player_rank), late_join = TRUE)
	EquipCustomItems(character)

	if((security_level > SEC_LEVEL_BLUE || SSevacuation.evac_status) && player_rank.gets_emergency_kit)
		to_chat(character, SPAN_HIGHDANGER("[character.client.auto_lang(LANGUAGE_LOBBY_RED_ALERT)]: '[SSevacuation.evac_status ? character.client.auto_lang(LANGUAGE_LOBBY_RED_ALERT_MSG_E) : character.client.auto_lang(LANGUAGE_LOBBY_RED_ALERT_MSG_D)]'."))
		character.put_in_hands(new /obj/item/storage/box/kit/cryo_self_defense(character.loc))

	GLOB.data_core.manifest_inject(character)
	SSticker.minds += character.mind
	SSticker.mode.latejoin_tally += character.faction.get_role_coeff(player_rank)

	if(SSticker.mode.latejoin_larva_drop && SSticker.mode.latejoin_tally >= SSticker.mode.latejoin_larva_drop)
		SSticker.mode.latejoin_tally -= SSticker.mode.latejoin_larva_drop
		var/datum/faction/faction = GLOB.faction_datums[FACTION_XENOMORPH_NORMAL]
		faction.stored_larva++
		faction.faction_ui.update_burrowed_larva()

	if(character.mind && character.client.player_data)
		var/list/xeno_playtimes = LAZYACCESS(character.client.player_data.playtime_data, "stored_xeno_playtime")
		var/list/marine_playtimes = LAZYACCESS(character.client.player_data.playtime_data, "stored_human_playtime")
		if(!xeno_playtimes && !marine_playtimes)
			msg_admin_niche("NEW JOIN: <b>[key_name(character, 1, 1, 0)]</b>. IP: [character.lastKnownIP], CID: [character.computer_id]")
		if(character.client)
			var/client/C = character.client
			if(C.player_data && C.player_data.playtime_loaded && length(C.player_data.playtimes) == 0)
				msg_admin_niche("NEW PLAYER: <b>[key_name(character, 1, 1, 0)]</b>. IP: [character.lastKnownIP], CID: [character.computer_id]")
			if(C.player_data && C.player_data.playtime_loaded && ((round(C.get_total_human_playtime() DECISECONDS_TO_HOURS, 0.1)) <= 5))
				msg_sea("NEW PLAYER: <b>[key_name(character, 0, 1, 0)]</b> only has [(round(C.get_total_human_playtime() DECISECONDS_TO_HOURS, 0.1))] hours as a human. Current role: [character.job] - Current location: [get_area(character)]")

	character.client.init_verbs()
	qdel(src)


/mob/new_player/proc/LateChoices()
	var/list/faction_to_get_list = list()
	for(var/faction_to_get in SSticker.mode.factions_pool)
		var/datum/faction/faction = GLOB.faction_datums[SSticker.mode.factions_pool[faction_to_get]]
		if(!faction.spawning_enabled || (!faction.force_spawning && !faction.weight_act[SSticker.mode.name]))
			continue
		faction_to_get_list += faction_to_get

	var/choice = tgui_input_list(src, "Choose faction to join:", "Factions", faction_to_get_list)
	if(!choice)
		return

	GLOB.faction_datums[SSticker.mode.factions_pool[choice]].get_join_status(src)


/mob/new_player/proc/create_character(is_late_join = FALSE)
	spawning = TRUE
	close_spawn_windows()

	var/mob/living/carbon/human/new_character

	var/datum/species/chosen_species
	if(client.prefs.species)
		chosen_species = GLOB.all_species[client.prefs.species]
	if(chosen_species)
		// Have to recheck admin due to no usr at roundstart. Latejoins are fine though.
		if(is_species_whitelisted(chosen_species) || has_admin_rights())
			new_character = new(loc, client.prefs.species)

	if(!new_character)
		new_character = new(loc)

	new_character.lastarea = get_area(loc)

	client.prefs.copy_all_to(new_character, job, is_late_join)

	if(client.prefs.be_random_body)
		var/datum/preferences/TP = new()
		TP.randomize_appearance(new_character)

	if(mind)
		mind_initialize()
		mind.active = 0 //we wish to transfer the key manually
		mind.original = new_character
		mind.transfer_to(new_character) //won't transfer key since the mind is not active

	new_character.job = job
	new_character.name = real_name
	new_character.voice = real_name

	// Update the character icons
	// This is done in set_species when the mob is created as well, but
	INVOKE_ASYNC(new_character, TYPE_PROC_REF(/mob/living/carbon/human, regenerate_icons))
	INVOKE_ASYNC(new_character, TYPE_PROC_REF(/mob/living/carbon/human, update_body), 1, 0)
	INVOKE_ASYNC(new_character, TYPE_PROC_REF(/mob/living/carbon/human, update_hair))

	new_character.key = key //Manually transfer the key to log them in
	new_character.client?.change_view(world_view_size)

	return new_character

/mob/new_player/proc/ViewManifest()
	var/list/datum/faction/factions = list()
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction_to_set = GLOB.faction_datums[faction_to_get]
		if(!length(faction_to_set.totalMobs))
			continue
		LAZYSET(factions, faction_to_set.name, faction_to_set)

	var/choice = tgui_input_list(src, client.auto_lang(LANGUAGE_MANIFEST_CHOOSE), client.auto_lang(LANGUAGE_MANIFEST_CONFIRM), factions)
	if(!choice)
		return FALSE

	return factions[choice].tgui_interact(src)

/mob/new_player/proc/ViewHiveLeaders()
	if(!GLOB.hive_leaders_tgui)
		GLOB.hive_leaders_tgui = new /datum/hive_leaders()
	GLOB.hive_leaders_tgui.tgui_interact(src)

/datum/hive_leaders/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/datum/hive_leaders/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HiveLeaders", "Hive Leaders")
		ui.open()
		ui.set_autoupdate(FALSE)

// Player panel
/datum/hive_leaders/ui_data(mob/user)
	var/list/data = list()

	var/datum/faction/main_hive = GLOB.faction_datums[FACTION_XENOMORPH_NORMAL]
	var/list/queens = list()
	if(main_hive.living_xeno_queen)
		queens += list(list("designation" = main_hive.living_xeno_queen.full_designation, "caste_type" = main_hive.living_xeno_queen.name))
	data["queens"] = queens
	var/list/leaders = list()
	for(var/mob/living/carbon/xenomorph/xeno_leader in main_hive.xeno_leader_list)
		leaders += list(list("designation" = xeno_leader.full_designation, "caste_type" = xeno_leader.caste_type))
	data["leaders"] = leaders
	return data


/datum/hive_leaders/ui_state(mob/user)
	return GLOB.always_state

/mob/new_player/Move()
	return 0

/mob/proc/close_spawn_windows() // Somehow spawn menu stays open for non-newplayers
	close_browser(src, "latechoices") //closes late choices window
	close_browser(src, "lobby") //closes the player setup window
	close_browser(src, "que") //closes the player setup window
	src << sound(null, repeat = 0, wait = 0, volume = 85, channel = SOUND_CHANNEL_LOBBY) // Stops lobby music.
	if(src.open_uis)
		for(var/datum/nanoui/ui in src.open_uis)
			if(ui.allowed_user_stat == -1)
				ui.close()
				continue

/mob/new_player/proc/has_admin_rights()
	return client.admin_holder.rights & R_ADMIN

/mob/new_player/proc/is_species_whitelisted(datum/species/S)
	if(!S) return 1
	return is_alien_whitelisted(src, S.name) || !CONFIG_GET(flag/usealienwhitelist) || !(S.species_flags & IS_WHITELISTED)

/mob/new_player/get_species()
	var/datum/species/chosen_species
	if(client.prefs.species)
		chosen_species = GLOB.all_species[client.prefs.species]

	if(!chosen_species)
		return "Human"

	if(is_species_whitelisted(chosen_species) || has_admin_rights())
		return chosen_species.name

	return "Human"

/mob/new_player/get_gender()
	if(!client || !client.prefs) ..()
	return client.prefs.gender

/mob/new_player/is_ready()
	return ready && ..()

/mob/new_player/hear_say(message, verb = "says", datum/language/language = null, alt_name = "", italics = 0, mob/speaker = null)
	return

/mob/new_player/hear_radio(message, verb, datum/language/language, part_a, part_b, mob/speaker, hard_to_hear, vname, command, no_paygrade = FALSE)
	return

/mob/new_player/get_status_tab_items()
	. = ..()

	. += ""

	. += "[client.auto_lang(LANGUAGE_STATUS_GAMEMODE)]: [GLOB.master_mode]"

	if(!SSticker.HasRoundStarted())
		var/time_remaining = SSticker.GetTimeLeft()
		if(time_remaining > 0)
			. += "[client.auto_lang(LANGUAGE_STATUS_TIME)]: [round(time_remaining)]s"
		else if(time_remaining == -10)
			. += "[client.auto_lang(LANGUAGE_STATUS_TIME)]: [client.auto_lang(LANGUAGE_STATUS_TIME_DELAYED)]"
		else
			. += "[client.auto_lang(LANGUAGE_STATUS_TIME)]: [client.auto_lang(LANGUAGE_STATUS_TIME_RIGHT_NOW)]"

	var/players = length(GLOB.clients)
	. += "[client.auto_lang(LANGUAGE_WHO_PLAYERS)]: [players]"
	if(!SSticker.HasRoundStarted())
		if(client.admin_holder)
			. += "[client.auto_lang(LANGUAGE_STATUS_READIED)]: [SSticker.totalPlayersReady]"
