#define DELETE_TIME 1800

/mob/living/carbon/xenomorph/death(cause, gibbed)
	var/msg = "lets out a waning guttural screech, green blood bubbling from its maw."
	tacmap_visibly = FALSE
	. = ..(cause, gibbed, msg)
	if(!.)
		return //If they're already dead, it will return.

	GLOB.living_xeno_list -= src

	if(is_zoomed)
		zoom_out()

	if(MODE_HAS_FLAG(MODE_HARDCORE))
		ghostize()

	set_light_on(FALSE)

	if(pulledby)
		pulledby.stop_pulling()

	if(!gibbed)
		if(hud_used && hud_used.healths)
			hud_used.healths.icon_state = "health_dead"
		if(hud_used && hud_used.alien_plasma_display)
			hud_used.alien_plasma_display.icon_state = "power_display_empty"
		update_icons()

	if(!is_admin_level(z)) //so xeno players don't get death messages from admin tests
		if(isqueen(src))
			var/mob/living/carbon/xenomorph/queen/queen = src
			playsound(loc, 'sound/voice/alien_queen_died.ogg', 75, 0)
			if(queen.observed_xeno)
				queen.overwatch(queen.observed_xeno, TRUE)
			if(queen.ovipositor)
				queen.dismount_ovipositor(TRUE)

			if(faction.stored_larva)
				faction.stored_larva = round(faction.stored_larva * 0.5) //Lose half on dead queen
				var/list/players_with_xeno_pref = get_alien_candidates(faction)
				if(players_with_xeno_pref && istype(faction.faction_location, /obj/effect/alien/resin/special/pylon/core))
					var/turf/larva_spawn = get_turf(faction.faction_location)
					var/count = 0
					while(faction.stored_larva > 0 && count < length(players_with_xeno_pref)) // still some left
						var/mob/xeno_candidate = players_with_xeno_pref[++count]
						var/mob/living/carbon/xenomorph/larva/new_xeno = new /mob/living/carbon/xenomorph/larva(larva_spawn)
						new_xeno.set_hive_and_update(faction)

						new_xeno.generate_name()
						if(!SSticker.mode.transfer_xenomorph(xeno_candidate, new_xeno))
							qdel(new_xeno)
							break

						new_xeno.visible_message(SPAN_XENODANGER("A larva suddenly burrows out of the ground!"),
						SPAN_XENODANGER("You burrow out of the ground after feeling an immense tremor through the hive, which quickly fades into complete silence..."))

						faction.stored_larva--
						faction.faction_ui.update_burrowed_larva()
					if(count)
						message_alien_candidates(players_with_xeno_pref, dequeued = count)

			if(faction && faction.living_xeno_queen == src)
				notify_ghosts(header = "Queen Death", message = "The Queen has been slain!", source = src, action = NOTIFY_ORBIT)
				xeno_message(SPAN_XENOANNOUNCE("A sudden tremor ripples through the hive... the Queen has been slain! Vengeance!"), 3, faction)
				faction.slashing_allowed = XENO_SLASH_ALLOWED
				faction.set_living_xeno_queen(null)
				//on the off chance there was somehow two queen alive
				for(var/mob/living/carbon/xenomorph/queen/selected_queen in GLOB.living_xeno_list)
					if(!QDELETED(selected_queen) && selected_queen != src && selected_queen.faction == faction)
						faction.set_living_xeno_queen(selected_queen)
						break
				faction.on_leader_death()
				faction.handle_xeno_leader_pheromones()
				if(SSticker.mode)
					INVOKE_ASYNC(SSticker.mode, TYPE_PROC_REF(/datum/game_mode, check_queen_status), faction)
					LAZYADD(SSticker.mode.dead_queens, "<br>[!isnull(full_designation) ? full_designation : "?"] was [src] [SPAN_BOLDNOTICE("(DIED)")]")

		else if(ispredalien(src))
			playsound(loc,'sound/voice/predalien_death.ogg', 25, TRUE)
		else if(isfacehugger(src))
			playsound(loc, 'sound/voice/alien_facehugger_dies.ogg', 25, TRUE)
		else
			playsound(loc, prob(50) == 1 ? 'sound/voice/alien_death.ogg' : 'sound/voice/alien_death2.ogg', 25, 1)
		var/area/area = get_area(src)
		if(faction && faction.living_xeno_queen)
			xeno_message("Hive: [src] has <b>died</b>[area? " at [sanitize_area(area.name)]":""]! [banished ? "They were banished from the hive." : ""]", death_fontsize, faction)

	if(faction && IS_XENO_LEADER(src))	//Strip them from the Xeno leader list, if they are indexed in here
		faction.remove_hive_leader(src)
		if(faction.living_xeno_queen)
			to_chat(faction.living_xeno_queen, SPAN_XENONOTICE("A leader has fallen!")) //alert queens so they can choose another leader

	hud_update() //updates the overwatch hud to remove the upgrade chevrons, gold star, etc

	if(behavior_delegate)
		behavior_delegate.handle_death(src)

	for(var/atom/movable/atom in stomach_contents)
		stomach_contents.Remove(atom)
		atom.acid_damage = 0 //Reset the acid damage
		atom.forceMove(loc)

	// Banished xeno provide a burrowed larva on death to compensate
	if(banished && refunds_larva_if_banished)
		faction.stored_larva++
		SSautobalancer.balance_action(src, "remove")
		faction.faction_ui.update_burrowed_larva()

	if(faction)
		if(SSticker.mode && SSticker.current_state != GAME_STATE_FINISHED)
			if((last_ares_callout + 2 MINUTES) > world.time)
				return

		if(faction == GLOB.faction_datums[FACTION_XENOMORPH_NORMAL] && (length(faction.totalMobs) == 1))
			var/mob/living/carbon/xenomorph/xeno = LAZYACCESS(faction.totalMobs, 1)
			last_ares_callout = world.time
			// Tell the marines where the last one is.
			var/name = "[MAIN_AI_SYSTEM] Bioscan Status"
			var/input = "Bioscan complete.\n\nСенсоры обнаружили одну оставшуюся неизвестную сигнатуру жизненной формы в [get_area(xeno)]."
			faction_announcement(input, name, 'sound/AI/bioscan.ogg')
			// Tell the xeno she is the last one.
			if(xeno.client)
				to_chat(xeno, SPAN_XENOANNOUNCE("Your carapace rattles with dread. You are all that remains of the hive!"))
			notify_ghosts(header = "Last Xenomorph", message = "There is only one Xenomorph left: [xeno.name].", source = xeno, action = NOTIFY_ORBIT)

	if(MODE_HAS_FLAG(MODE_HARDCORE))
		QDEL_IN(src, 3 SECONDS)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_XENO_DEATH, src, gibbed)

/mob/living/carbon/xenomorph/gib(datum/cause_data/cause = create_cause_data("gibbing", src))
	var/obj/effect/decal/remains/xeno/remains = new(get_turf(src))
	remains.icon = icon
	remains.pixel_x = pixel_x //For 2x2.

	if(!caste)
		CRASH("CASTE ERROR: gib() was called without a caste. (name: [name], disposed: [QDELETED(src)], health: [health])")

	switch(caste.caste_type) //This will need to be changed later, when we have proper xeno pathing. Might do it on caste or something.
		if(XENO_CASTE_BOILER)
			var/mob/living/carbon/xenomorph/boiler/src_boiler = src
			visible_message(SPAN_DANGER("[src] begins to bulge grotesquely, and explodes in a cloud of corrosive gas!"))
			src_boiler.smoke.set_up(2, 0, get_turf(src), new_cause_data = src_boiler.smoke.cause_data)
			src_boiler.smoke.start()
			remains.icon_state = "gibbed-a-corpse"
		if(XENO_CASTE_RUNNER)
			remains.icon_state = "gibbed-a-corpse-runner"
		if(XENO_CASTE_LARVA, XENO_CASTE_PREDALIEN_LARVA)
			remains.icon_state = "larva_gib_corpse"
		else
			remains.icon_state = "gibbed-a-corpse"

	check_blood_splash(35, BURN, 65, 2) //Some testing numbers. 35 burn, 65 chance.

	..(cause)

/mob/living/carbon/xenomorph/gib_animation()
	var/to_flick = "gibbed-a"
	var/icon_path
	if(mob_size >= MOB_SIZE_BIG)
		icon_path = 'icons/mob/xenos/xenomorph_64x64.dmi'
	else
		icon_path = 'icons/mob/xenos/xenomorph_48x48.dmi'
	switch(caste.caste_type)
		if(XENO_CASTE_RUNNER)
			to_flick = "gibbed-a-runner"
		if(XENO_CASTE_LARVA, XENO_CASTE_PREDALIEN_LARVA)
			to_flick = "larva_gib"
	new /obj/effect/overlay/temp/gib_animation/xeno(loc, src, to_flick, icon_path)

/mob/living/carbon/xenomorph/spawn_gibs()
	xgibs(get_turf(src))

/mob/living/carbon/xenomorph/dust_animation()
	new /obj/effect/overlay/temp/dust_animation(loc, src, "dust-a")

/mob/living/carbon/xenomorph/revive()
	SEND_SIGNAL(src, COMSIG_XENO_REVIVED)
	..()
