#define PYLON_REPAIR_TIME (4 SECONDS)
#define PYLON_WEEDS_REGROWTH_TIME (15 SECONDS)

//Hive Pylon - Remote building location for other structures, generates strong weeds

/obj/effect/alien/resin/special/pylon
	name = XENO_STRUCTURE_PYLON
	desc = "A towering spike of resin. Its base pulsates with large tendrils."
	icon_state = "pylon"

	health = 1800
	block_range = 0

	var/cover_range = WEED_RANGE_PYLON
	var/node_type = /obj/effect/alien/weeds/node/pylon
	var/obj/effect/alien/weeds/node/node
	var/linked_turfs = list()

	var/damaged = FALSE
	var/plasma_stored = 0
	var/plasma_required_to_repair = 1000

	var/protection_level = 10

	/// How many lesser drone spawns this pylon is able to spawn currently
	var/lesser_drone_spawns = 0
	/// The maximum amount of lesser drone spawns this pylon can hold
	var/lesser_drone_spawn_limit = 5

	light_on = TRUE
	light_range = 3
	light_power = 0.2
	light_system = STATIC_LIGHT
	light_color = COLOR_VIBRANT_LIME

/obj/effect/alien/resin/special/pylon/Initialize(mapload, hive_ref)
	. = ..()

	node = place_node()
	for(var/turf/turf in range(round(cover_range * COVERAGE_MULT), loc))
		LAZYADD(turf.linked_pylons, src)
		linked_turfs += turf

	if(light_range)
		set_light(light_range)

/obj/effect/alien/resin/special/pylon/Destroy()
	for(var/turf/turf as anything in linked_turfs)
		LAZYREMOVE(turf.linked_pylons, src)

	if(node)
		QDEL_NULL(node)
	. = ..()

/obj/effect/alien/resin/special/pylon/process(delta_time)
	if(lesser_drone_spawns < lesser_drone_spawn_limit)
		// One every 10 seconds while on ovi, one every 120-ish seconds while off ovi
		lesser_drone_spawns = min(lesser_drone_spawns + ((faction.living_xeno_queen?.ovipositor ? 0.1 : 0.008) * delta_time), lesser_drone_spawn_limit)

/obj/effect/alien/resin/special/pylon/attack_alien(mob/living/carbon/xenomorph/xeno)
	if(isxeno_builder(xeno) && xeno.a_intent == INTENT_HELP && xeno.faction == faction)
		do_repair(xeno) //This handles the delay itself.
		return XENO_NO_DELAY_ACTION
	else
		return ..()

/obj/effect/alien/resin/special/pylon/get_examine_text(mob/user)
	. = ..()

	var/lesser_count = 0
	for(var/mob/living/carbon/xenomorph/lesser_drone/lesser in faction.totalMobs)
		lesser_count++

	. += "Currently holding [SPAN_NOTICE("[round(lesser_drone_spawns)]")]/[SPAN_NOTICE("[lesser_drone_spawn_limit]")] lesser drones."
	. += "There are currently [SPAN_NOTICE("[lesser_count]")] lesser drones in the hive. The hive can support [SPAN_NOTICE("[faction.lesser_drone_limit]")] lesser drones."

/obj/effect/alien/resin/special/pylon/attack_ghost(mob/dead/observer/user)
	. = ..()
	spawn_lesser_drone(user)

/obj/effect/alien/resin/special/pylon/proc/do_repair(mob/living/carbon/xenomorph/xeno)
	if(!istype(xeno))
		return
	if(!xeno.plasma_max)
		return
	var/can_repair = damaged || health < maxhealth
	if(!can_repair)
		to_chat(xeno, SPAN_XENONOTICE("\The [name] is in good condition, you don't need to repair it."))
		return

	to_chat(xeno, SPAN_XENONOTICE("You begin adding the plasma to \the [name] to repair it."))
	xeno_attack_delay(xeno)
	if(!do_after(xeno, PYLON_REPAIR_TIME, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD, src) || !can_repair)
		return

	var/amount_to_use = min(xeno.plasma_stored, (plasma_required_to_repair - plasma_stored))
	plasma_stored += amount_to_use
	xeno.plasma_stored -= amount_to_use

	if(plasma_stored < plasma_required_to_repair)
		to_chat(xeno, SPAN_WARNING("\The [name] requires [plasma_required_to_repair - plasma_stored] more plasma to repair it."))
		return

	damaged = FALSE
	plasma_stored = 0
	health = initial(health)

	var/obj/effect/alien/weeds/node/pylon/pylon = locate() in loc
	if(!pylon)
		return
	for(var/obj/effect/alien/weeds/weeds in pylon.children)
		if(get_dist(pylon, weeds) >= pylon.node_range)
			continue
		if(istype(weeds, /obj/effect/alien/weeds/weedwall))
			continue
		addtimer(CALLBACK(weeds, TYPE_PROC_REF(/obj/effect/alien/weeds, weed_expand), pylon), PYLON_WEEDS_REGROWTH_TIME, TIMER_UNIQUE)

	to_chat(xeno, SPAN_XENONOTICE("You have successfully repaired \the [name]."))
	playsound(loc, "alien_resin_build", 25)

/obj/effect/alien/resin/special/pylon/proc/place_node()
	var/obj/effect/alien/weeds/node/pylon/pylon_node = new node_type(loc, null, null, faction)
	pylon_node.resin_parent = src
	return pylon_node

/obj/effect/alien/resin/special/pylon/proc/spawn_lesser_drone(mob/xeno_candidate)
	if(!faction.can_spawn_as_lesser_drone(xeno_candidate, src))
		return FALSE

	if(tgui_alert(xeno_candidate, "Are you sure you want to become a lesser drone?", "Confirmation", list("Yes", "No")) != "Yes")
		return FALSE

	if(!faction.can_spawn_as_lesser_drone(xeno_candidate, src))
		return FALSE

	var/mob/living/carbon/xenomorph/lesser_drone/new_drone = new(loc, null, faction)
	xeno_candidate.mind.transfer_to(new_drone, TRUE)
	lesser_drone_spawns -= 1
	new_drone.visible_message(SPAN_XENODANGER("A lesser drone emerges out of [src]!"), SPAN_XENODANGER("You emerge out of [src] and awaken from your slumber. For the Hive!"))
	playsound(new_drone, 'sound/effects/xeno_newlarva.ogg', 25, TRUE)
	new_drone.generate_name()

	return TRUE

/obj/effect/alien/resin/special/pylon/endgame
	cover_range = WEED_RANGE_CORE
	var/activated = FALSE

/obj/effect/alien/resin/special/pylon/endgame/Destroy()
	if(activated)
		activated = FALSE

		if(hijack_delete)
			return ..()

		faction_announcement("ALERT.\n\nEnergy build up around communication relay at [get_area(src)] halted.", "[MAIN_AI_SYSTEM] Biological Scanner")

		for(var/faction_to_get in FACTION_LIST_XENOMORPH)
			var/datum/faction/selected_faction = GLOB.faction_datums[faction_to_get]
			if(!length(selected_faction.totalMobs))
				continue

			if(selected_faction == faction)
				xeno_announcement(SPAN_XENOANNOUNCE("We have lost our control of the tall's communication relay at [get_area(src)]."), selected_faction, XENO_GENERAL_ANNOUNCE)
			else
				xeno_announcement(SPAN_XENOANNOUNCE("Another hive has lost control of the tall's communication relay at [get_area(src)]."), selected_faction, XENO_GENERAL_ANNOUNCE)

	return ..()

/// Checks if all comms towers are connected and then starts end game content on all pylons if they are
/obj/effect/alien/resin/special/pylon/endgame/proc/comms_relay_connection()
	faction_announcement("ALERT.\n\nIrregular build up of energy around communication relays at [get_area(src)].", "[MAIN_AI_SYSTEM] Biological Scanner")

	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/selected_faction = GLOB.faction_datums[faction_to_get]
		if(!length(selected_faction.totalMobs))
			continue

		if(selected_faction == faction)
			xeno_announcement(SPAN_XENOANNOUNCE("We have harnessed the tall's communication relay at [get_area(src)]. Hold it!"), selected_faction, XENO_GENERAL_ANNOUNCE)
		else
			xeno_announcement(SPAN_XENOANNOUNCE("Another hive has harnessed the tall's communication relay at [get_area(src)].[faction.faction_is_ally(selected_faction) ? "" : " Stop them!"]"), selected_faction, XENO_GENERAL_ANNOUNCE)

	activated = TRUE
	addtimer(CALLBACK(src, PROC_REF(give_larva)), XENO_PYLON_ACTIVATION_COOLDOWN, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_LOOP|TIMER_DELETE_ME)

#define ENDGAME_LARVA_CAP_MULTIPLIER 0.4
#define LARVA_ADDITION_MULTIPLIER 0.10

/// Looped proc via timer to give larva after time
/obj/effect/alien/resin/special/pylon/endgame/proc/give_larva()
	if(!activated)
		return

	if(!faction.faction_location || !faction.living_xeno_queen)
		return

	var/list/hive_xenos = faction.totalMobs

	for(var/mob/living/carbon/xenomorph/xeno in hive_xenos)
		if(!xeno.counts_for_slots)
			hive_xenos -= xeno

	if(length(hive_xenos) > (length(GLOB.alive_human_list) * ENDGAME_LARVA_CAP_MULTIPLIER))
		return

	faction.partial_larva += length(hive_xenos) * LARVA_ADDITION_MULTIPLIER
	faction.convert_partial_larva_to_full_larva()
	faction.faction_ui.update_burrowed_larva()

#undef ENDGAME_LARVA_CAP_MULTIPLIER
#undef LARVA_ADDITION_MULTIPLIER

/obj/effect/alien/resin/special/pylon/cluster
	name = XENO_STRUCTURE_CLUSTER
	desc = "A large clump of gooey mass. It rhythmically pulses, as if its pumping something into the weeds below..."
	icon = 'icons/mob/xenos/structures48x48.dmi'
	icon_state = "hive_cluster_idle"

	pixel_x = -8
	pixel_y = -8

	health = 1200
	block_range = 0

	node_type = /obj/effect/alien/weeds/node/pylon/cluster

	damaged = FALSE
	plasma_stored = 0
	plasma_required_to_repair = 300

	protection_level = 5

//Hive Core - Generates strong weeds, supports other buildings
/obj/effect/alien/resin/special/pylon/core
	name = XENO_STRUCTURE_CORE
	desc = "A giant pulsating mound of mass. It looks very much alive."
	icon_state = "core"
	health = 2000
	cover_range = WEED_RANGE_CORE
	node_type = /obj/effect/alien/weeds/node/pylon/core
	var/hardcore = FALSE
	var/next_attacked_message = 5 SECONDS
	var/last_attacked_message = 0
	var/warn = TRUE // should we warn of hivecore destruction?
	var/heal_amount = 100
	var/heal_interval = 10 SECONDS
	var/last_healed = 0
	var/last_attempt = 0 // logs time of last attempt to prevent spam. if you want to destroy it, you must commit.
	var/last_larva_time = 0
	var/last_larva_queue_time = 0
	var/last_surge_time = 0
	var/spawn_cooldown = 30 SECONDS
	var/surge_cooldown = 90 SECONDS
	var/surge_incremental_reduction = 3 SECONDS
	var/crash_mode = FALSE

	protection_level = 20

	light_on = TRUE
	light_range = 4
	light_power = 0.3
	light_system = STATIC_LIGHT
	light_color = COLOR_PURPLE_GRAY

	lesser_drone_spawn_limit = 10

/obj/effect/alien/resin/special/pylon/core/Initialize(mapload, datum/faction/faction_to_set)
	. = ..()

	faction.set_faction_location(src)
	faction.faction_location = src

	SSmapview.add_marker(src, "hive_core")

/obj/effect/alien/resin/special/pylon/core/process()
	. = ..()

	// Handle spawning larva if core is connected to a hive
	if(faction)
		for(var/mob/living/carbon/xenomorph/larva/larva in range(2, src))
			if((!larva.ckey || larva.stat == DEAD) && larva.burrowable && (larva.faction == faction) && !QDELETED(larva))
				visible_message(SPAN_XENODANGER("[larva] quickly burrows into \the [src]."))
				if(!larva.banished)
					// Goob job bringing her back home, but no doubling please
					faction.stored_larva++
					faction.faction_ui.update_burrowed_larva()
				qdel(larva)

		var/spawning_larva = can_spawn_larva() && (last_larva_time + spawn_cooldown) < world.time
		if(spawning_larva)
			last_larva_time = world.time
		if(spawning_larva || (last_larva_queue_time + spawn_cooldown * 4) < world.time)
			last_larva_queue_time = world.time
			var/list/players_with_xeno_pref = get_alien_candidates(faction)
			if(players_with_xeno_pref && players_with_xeno_pref.len)
				if(spawning_larva && spawn_burrowed_larva(players_with_xeno_pref[1]))
					// We were in spawning_larva mode and successfully spawned someone
					message_alien_candidates(players_with_xeno_pref, dequeued = 1)
				else
					// Just time to update everyone their queue status (or the spawn failed)
					message_alien_candidates(players_with_xeno_pref, dequeued = 0)

		if((faction.hijack_burrowed_surge || crash_mode) && (last_surge_time + surge_cooldown) < world.time)
			last_surge_time = world.time
			faction.stored_larva++
			faction.faction_ui.update_burrowed_larva()
			faction.hijack_burrowed_left--
			notify_ghosts(header = "Claim Xeno", message = "The Hive has gained another burrowed larva! Click to take it.", source = src, action = NOTIFY_JOIN_XENO, enter_link = "join_xeno")
			if(surge_cooldown > 30 SECONDS) //mostly for sanity purposes
				surge_cooldown = surge_cooldown - surge_incremental_reduction //ramps up over time
			if(faction.hijack_burrowed_left < 1)
				faction.hijack_burrowed_surge = FALSE
				xeno_message(SPAN_XENOANNOUNCE("The hive's power wanes. You will no longer gain pooled larva over time."), 3, faction)

	// Hive core can repair itself over time
	if(health < maxhealth && last_healed <= world.time)
		health += min(heal_amount, maxhealth-health)
		last_healed = world.time + heal_interval

/obj/effect/alien/resin/special/pylon/core/proc/can_spawn_larva()
	if(faction.hardcore)
		return FALSE

	return faction.stored_larva

/obj/effect/alien/resin/special/pylon/core/proc/spawn_burrowed_larva(mob/xeno_candidate)
	if(can_spawn_larva() && xeno_candidate)
		var/mob/living/carbon/xenomorph/larva/new_xeno = spawn_faction_larva(loc, faction)
		if(isnull(new_xeno))
			return FALSE

		new_xeno.visible_message(SPAN_XENODANGER("A larva suddenly emerges from [src]!"),
		SPAN_XENODANGER("You emerge from [src] and awaken from your slumber. For the Hive!"))
		msg_admin_niche("[key_name(new_xeno)] emerged from \a [src]. [ADMIN_JMP(src)]")
		playsound(new_xeno, 'sound/effects/xeno_newlarva.ogg', 50, 1)
		if(!SSticker.mode.transfer_xenomorph(xeno_candidate, new_xeno))
			qdel(new_xeno)
			return FALSE
		to_chat(new_xeno, SPAN_XENOANNOUNCE("You are a xenomorph larva awakened from slumber!"))
		playsound(new_xeno, 'sound/effects/xeno_newlarva.ogg', 50, 1)
		if(new_xeno.client)
			if(new_xeno.client?.prefs.toggles_flashing & FLASH_POOLSPAWN)
				window_flash(new_xeno.client)

		faction.stored_larva--
		faction.faction_ui.update_burrowed_larva()

		return TRUE
	return FALSE

/obj/effect/alien/resin/special/pylon/core/attackby(obj/item/attack_item, mob/user)
	if(!istype(attack_item, /obj/item/grab) || !isxeno(user))
		return ..(attack_item, user)

	var/larva_amount = 0 // The amount of larva they get

	var/obj/item/grab/grab = attack_item
	if(!isxeno(grab.grabbed_thing))
		return
	var/mob/living/carbon/carbon_mob = grab.grabbed_thing
	if(carbon_mob.buckled)
		to_chat(user, SPAN_XENOWARNING("Unbuckle first!"))
		return
	if(!faction || carbon_mob.stat != DEAD)
		return

	if(SSticker.mode && !(SSticker.mode.flags_round_type & MODE_XVX))
		return // For now, disabled on gamemodes that don't support it (primarily distress signal)

	// Will probably allow for hives to slowly gain larva by killing hostile xenos and taking them to the hive core
	// A self sustaining cycle until one hive kills more of the other hive to tip the balance

	// Makes attacking hives very profitable if they can successfully wipe them out without suffering any significant losses
	var/mob/living/carbon/xenomorph/xeno = carbon_mob
	if(xeno.faction != faction)
		if(isqueen(xeno))
			larva_amount = 5
		else
			larva_amount += max(xeno.tier, 1) // Now you always gain larva.
	else
		return

	if(!do_after(user, 10, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_GENERIC))
		return

	visible_message(SPAN_DANGER("[src] engulfs [xeno] in resin!"))
	playsound(src, "alien_resin_build", 25, 1)
	qdel(xeno)

	faction.stored_larva += larva_amount
	faction.faction_ui.update_burrowed_larva()

/obj/effect/alien/resin/special/pylon/core/attack_alien(mob/living/carbon/xenomorph/xeno)
	if(xeno.a_intent != INTENT_HELP && xeno.can_destroy_special() && xeno.faction == faction)
		if(!hardcore && last_attempt + 6 SECONDS > world.time)
			to_chat(xeno,SPAN_WARNING("You have attempted to destroy \the [src] too recently! Wait a bit!")) // no spammy
		else
			if((alert(xeno, xeno.client.auto_lang(LANGUAGE_HIVE_CORE_COLDOWN), xeno.client.auto_lang(LANGUAGE_CONFIRM), xeno.client.auto_lang(LANGUAGE_YES), xeno.client.auto_lang(LANGUAGE_NO)) != xeno.client.auto_lang(LANGUAGE_YES)))
				INVOKE_ASYNC(src, PROC_REF(startDestroying), xeno)
		return XENO_NO_DELAY_ACTION

	if(faction)
		var/current_health = health
		if(hardcore && (xeno.faction == faction || xeno.faction.faction_is_ally(faction)))
			return XENO_NO_DELAY_ACTION
		. = ..()
		if(hardcore && last_attacked_message < world.time && current_health > health)
			xeno_message(SPAN_XENOANNOUNCE(xeno.client.auto_lang(LANGUAGE_HIVE_CORE_UNDER_ATTACK)), 2, faction)
			last_attacked_message = world.time + next_attacked_message
	else
		. = ..()

/obj/effect/alien/resin/special/pylon/core/Destroy()
	if(faction)
		visible_message(SPAN_XENOHIGHDANGER("The resin roof withers away as \the [src] dies!"), max_distance = WEED_RANGE_CORE)
		faction.faction_location = null
		if(world.time < XENOMORPH_PRE_SETUP_CUTOFF && !hardcore)
			. = ..()
			return
		faction.hivecore_cooldown = TRUE
		INVOKE_ASYNC(src, PROC_REF(cooldownFinish), faction) // start cooldown
		if(hardcore)
			xeno_message(SPAN_XENOANNOUNCE("You can no longer gain new sisters or another Queen. Additionally, you are unable to heal if your Queen is dead"), 2, faction)
			faction.hardcore = TRUE
			faction.allow_queen_evolve = FALSE
			faction.faction_structures_limit[XENO_STRUCTURE_CORE] = 0
			faction.faction_structures_limit[XENO_STRUCTURE_POOL] = 0
			xeno_announcement("\The [faction.name] has lost their hive core!", "everything", HIGHER_FORCE_ANNOUNCE)

		if(faction.hijack_burrowed_surge)
			visible_message(SPAN_XENODANGER("You hear something resembling a scream from [src] as it's destroyed!"))
			xeno_message(SPAN_XENOANNOUNCE("Psychic pain storms throughout the hive as [src] is destroyed! You will no longer gain burrowed larva over time."), 3, faction)
			faction.hijack_burrowed_surge = FALSE

	. = ..()

/obj/effect/alien/resin/special/pylon/core/proc/startDestroying(mob/living/carbon/xenomorph/xeno)
	xeno_message(SPAN_XENOANNOUNCE("[xeno] is destroying \the [src]!"), 3, faction)
	visible_message(SPAN_DANGER("[xeno] starts destroying \the [src]!"))
	last_attempt = world.time //spamcheck
	if(!do_after(xeno, 5 SECONDS , INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_HOSTILE))
		to_chat(xeno,SPAN_WARNING("You stop destroying \the [src]."))
		visible_message(SPAN_WARNING("[xeno] stops destroying \the [src]."))
		last_attempt = world.time // update the spam check
		return XENO_NO_DELAY_ACTION
	qdel(src)

/obj/effect/alien/resin/special/pylon/core/proc/cooldownFinish(datum/faction/faction)
	sleep(HIVECORE_COOLDOWN)
	if(faction.hivecore_cooldown) // check if its true so we don't double set it.
		faction.hivecore_cooldown = FALSE
		xeno_message(SPAN_XENOANNOUNCE("The weeds have recovered! A new hive core can be built!"), 3, faction)
	else
		log_admin("Hivecore cooldown reset proc aborted due to hivecore cooldown var being set to false before the cooldown has finished!")
		// Tell admins that this condition is reached so they know what has happened if it fails somehow
		return

#undef PYLON_REPAIR_TIME
#undef PYLON_WEEDS_REGROWTH_TIME
