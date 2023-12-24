/obj/structure/machinery/defenses/sentry
	name = "UA 571-C sentry gun"
	icon = 'icons/obj/structures/machinery/defenses/sentry.dmi'
	desc = "A deployable, semi-automated turret with AI targeting capabilities. Armed with an M30 Autocannon and a 500-round drum magazine."
	req_one_access = list(ACCESS_MARINE_ENGINEERING, ACCESS_MARINE_ENGPREP, ACCESS_MARINE_LEADER)
	var/list/targets = list() // Lists of current potential targets
	var/list/other_targets = list() //List of special target types to shoot at, if needed.
	var/atom/movable/target = null
	var/datum/shape/rectangle/range_bounds
	var/datum/effect_system/spark_spread/spark_system //The spark system, used for generating... sparks?
	var/last_fired = 0
	var/fire_delay = 4
	var/immobile = FALSE //Used for prebuilt ones.
	var/obj/item/ammo_magazine/ammo = new /obj/item/ammo_magazine/sentry
	var/sentry_type = "sentry" //Used for the icon
	var/sentry_icon = 'icons/obj/structures/machinery/defenses/sentry.dmi'
	var/sentry_icon_resize = 0
	display_additional_stats = TRUE
	/// Check if they have been upgraded or not, used for sentry post
	var/upgraded = FALSE
	var/omni_directional = FALSE
	var/fire_angle = 135
	var/sentry_range = 5
	var/muzzlelum = 3
	var/engaged_timeout = 60 SECONDS
	var/low_ammo_timeout = 20 SECONDS
	var/low_ammo_alert_percentage = 0.25
	var/list/list/traits_to_give
	has_camera = TRUE
	var/damage_mult = 1
	var/accuracy_mult = 1
	var/burst = 1
	var/inherent_rounds = 0
	var/max_inherent_rounds = 0
	handheld_type = /obj/item/defenses/handheld/sentry

	/// timer triggered when sentry gun shoots at a target to not spam the laptop
	var/engaged_timer = null
	/// timer triggered when sentry gun is low on ammo to not spam the laptop
	var/low_ammo_timer = null
	/// timer triggered when sentry gun is out of ammo to not spam the laptop
	var/sent_empty_ammo = FALSE

	/// action list is configurable for all subtypes, this is just an example
	choice_categories = list(
		// SENTRY_CATEGORY_ROF = list(ROF_SINGLE, ROF_BURST, ROF_FULL_AUTO),
		SENTRY_CATEGORY_IFF = list(SENTRY_IFF_OFF, SENTRY_IFF_HALF, SENTRY_IFF_FULL),
	)

	selected_categories = list(
		// SENTRY_CATEGORY_ROF = ROF_SINGLE,
		SENTRY_CATEGORY_IFF = SENTRY_IFF_HALF,
	)

	light_range = 5

/obj/structure/machinery/defenses/sentry/Initialize()
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff)
	))
	. = ..()

/obj/structure/machinery/defenses/sentry/Destroy() //Clear these for safety's sake.
	targets = null
	other_targets = null
	target = null
	QDEL_NULL(range_bounds)
	QDEL_NULL(spark_system)
	QDEL_NULL(ammo)
	stop_processing()
	. = ..()

/obj/structure/machinery/defenses/sentry/process()
	if(!light_on)
		stop_processing()
		return

	if(!range_bounds)
		set_range()
	targets = SSquadtree.players_in_range(range_bounds, z, QTREE_SCAN_MOBS | QTREE_EXCLUDE_OBSERVER)
	for(var/atom/atom in GLOB.special_turrets_targets)
		if(atom in range(sentry_range, src))
			other_targets += atom

	if(!targets && !other_targets)
		return FALSE

	if(!target && targets.len)
		target = pick(targets)

	get_target(target)
	return TRUE

/obj/structure/machinery/defenses/sentry/proc/set_range()
	if(omni_directional)
		range_bounds = RECT(x, y, sentry_range, sentry_range)
		return
	var/size_bound = sentry_range * 2
	switch(dir)
		if(EAST)
			range_bounds = RECT(x + sentry_range, y, size_bound, size_bound)
		if(WEST)
			range_bounds = RECT(x - sentry_range, y, size_bound, size_bound)
		if(NORTH)
			range_bounds = RECT(x, y + sentry_range, size_bound, size_bound)
		if(SOUTH)
			range_bounds = RECT(x, y - sentry_range, size_bound, size_bound)

/obj/structure/machinery/defenses/sentry/proc/unset_range()
	SIGNAL_HANDLER
	if(range_bounds)
		QDEL_NULL(range_bounds)

/obj/structure/machinery/defenses/sentry/update_icon()
	..()

	overlays.Cut()
	if(stat == DEFENSE_DAMAGED)
		overlays += image(icon = sentry_icon, icon_state = "[defense_type] [sentry_type]_destroyed", pixel_x = sentry_icon_resize, pixel_y = sentry_icon_resize)
		return

	if(!ammo || ammo && !ammo.ammo_position)
		overlays += image(icon = sentry_icon, icon_state = "[defense_type] [sentry_type]_noammo", pixel_x = sentry_icon_resize, pixel_y = sentry_icon_resize)
		return

	if(light_on)
		overlays += image(icon = sentry_icon, icon_state = "[defense_type] [sentry_type]_on", pixel_x = sentry_icon_resize, pixel_y = sentry_icon_resize)
	else
		overlays += image(icon = sentry_icon, icon_state = "[defense_type] [sentry_type]", pixel_x = sentry_icon_resize, pixel_y = sentry_icon_resize)


/obj/structure/machinery/defenses/sentry/attack_hand_checks(mob/user)
	if(immobile)
		to_chat(user, SPAN_WARNING("[src]'s panel is completely locked, you can't do anything."))
		return FALSE

	// Reloads the sentry using inherent rounds
	if(!light_on && inherent_rounds && (ammo.ammo_position < ammo.max_rounds))
		use_inherent_rounds(user)
		return FALSE

	return TRUE

/obj/structure/machinery/defenses/sentry/proc/use_inherent_rounds(mob/user)
	if(user)
		if(!do_after(user, 2 SECONDS * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
			to_chat(user, SPAN_WARNING("You were interrupted! Try to stay still while you reload the sentry..."))
			return

		to_chat(user, SPAN_WARNING("[src]'s internal magazine with [ammo.ammo_position] rounds, [inherent_rounds] rounds left in storage"))
		playsound(loc, 'sound/weapons/handling/m40sd_reload.ogg', 25, 1)
		update_icon()

	playsound(loc, pick('sound/weapons/handling/mag_refill_1.ogg', 'sound/weapons/handling/mag_refill_2.ogg', 'sound/weapons/handling/mag_refill_3.ogg'), 150, 1)
	var/ammo_to_fill = min(ammo.max_rounds - ammo.ammo_position, inherent_rounds)
	for(var/i = 1 to ammo_to_fill)
		ammo.ammo_position++
		ammo.current_rounds[ammo.ammo_position] = new ammo.default_projectile(src, null, ammo.default_ammo[i % ammo.default_ammo.len + 1], ammo.caliber)
	inherent_rounds -= ammo_to_fill

/obj/structure/machinery/defenses/sentry/update_choice(mob/user, category, selection)
	. = ..()
	if(.)
		return
	if(category in selected_categories)
		selected_categories[category] = selection
		switch(category)
			if(SENTRY_CATEGORY_ROF)
				handle_rof(selection)
				return TRUE
	return FALSE

/**
 * Update the rate of fire in the sentry gun.
 * @param level: level of rate of fire, typically single, burst or full auto.
 */
/obj/structure/machinery/defenses/sentry/proc/handle_rof(level)
	switch(level)
		if(ROF_SINGLE)
			burst = 1
			accuracy_mult = 1
			fire_delay = 4
		if(ROF_BURST)
			burst = 3
			accuracy_mult = 0.6
			fire_delay = 12
		if(ROF_FULL_AUTO)
			burst = 1
			accuracy_mult = 0.5
			fire_delay = 0.5

/obj/structure/machinery/defenses/sentry/get_examine_text(mob/user)
	. = ..()
	if(ammo)
		. += SPAN_NOTICE("[src] has [ammo.ammo_position]/[ammo.max_rounds] rounds loaded.")
	if(inherent_rounds)
		. += SPAN_NOTICE("\The [src] has [inherent_rounds] round\s left in storage.")
	if(upgraded)
		. += SPAN_NOTICE("\The [src] has been reinforced with metal sheets.")
	else
		. += SPAN_NOTICE("\The [src] is empty and needs to be refilled with ammo.")
		if(inherent_rounds)
			. += SPAN_HELPFUL("Click \The [src] while it's turned off to reload.")

/obj/structure/machinery/defenses/sentry/power_on_action()
	target = null

	set_light_on(TRUE)

	visible_message("[icon2html(src, viewers(src))] [SPAN_NOTICE("The [name] hums to life and emits several beeps.")]")
	visible_message("[icon2html(src, viewers(src))] [SPAN_NOTICE("The [name] buzzes in a monotone voice: 'Default systems initiated'")]")
	start_processing()
	set_range()

/obj/structure/machinery/defenses/sentry/power_off_action()
	set_light_on(FALSE)
	visible_message("[icon2html(src, viewers(src))] [SPAN_NOTICE("The [name] powers down and goes silent.")]")
	stop_processing()
	unset_range()

/obj/structure/machinery/defenses/sentry/attackby(obj/item/O, mob/user)
	if(QDELETED(O) || QDELETED(user))
		return

	//Securing/Unsecuring
	if(HAS_TRAIT(O, TRAIT_TOOL_WRENCH))
		if(immobile)
			to_chat(user, SPAN_WARNING("[src] is completely welded in place. You can't move it without damaging it."))
			return

	if(!..())
		return

	// Rotation
	if(HAS_TRAIT(O, TRAIT_TOOL_SCREWDRIVER))
		if(immobile)
			to_chat(user, SPAN_WARNING("[src] is completely welded in place. You can't move it without damaging it."))
			return

		if(light_on)
			to_chat(user, SPAN_WARNING("[src] is currently active. The motors will prevent you from rotating it safely."))
			return

		playsound(loc, 'sound/items/Screwdriver.ogg', 25, 1)
		user.visible_message(SPAN_NOTICE("[user] rotates [src]."), SPAN_NOTICE("You rotate [src]."))
		setDir(turn(dir, -90))
		return

	if(istype(O, ammo))
		var/obj/item/ammo_magazine/M = O
		if(!skillcheck(user, SKILL_ENGINEER, SKILL_ENGINEER_ENGI) || user.action_busy)
			return

		if(ammo.ammo_position)
			to_chat(user, SPAN_WARNING("You only know how to swap [M.name] when it's empty."))
			return

		user.visible_message(SPAN_NOTICE("[user] begins swapping a new [O.name] into [src]."),
		SPAN_NOTICE("You begin swapping a new [O.name] into [src]."))
		if(!do_after(user, 70 * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_ALL, BUSY_ICON_FRIENDLY, src))
			return

		playsound(loc, 'sound/weapons/unload.ogg', 25, 1)
		user.visible_message(SPAN_NOTICE("[user] swaps a new [O.name] into [src]."),
		SPAN_NOTICE("You swap a new [O.name] into [src]."))

		ammo = O
		user.drop_held_item(O)
		O.forceMove(src)
		sent_empty_ammo = FALSE
		update_icon()
		return

	if(O.force)
		update_health(O.force/2)
	return ..()

/obj/structure/machinery/defenses/sentry/destroyed_action()
	visible_message("[icon2html(src, viewers(src))] [SPAN_WARNING("The [name] starts spitting out sparks and smoke!")]")
	playsound(loc, 'sound/mecha/critdestrsyndi.ogg', 25, 1)
	for(var/i = 1 to 6)
		setDir(pick(NORTH, EAST, SOUTH, WEST))
		sleep(2)

	cell_explosion(loc, 10, 10, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("взрыва турели", owner_mob))
	if(!QDELETED(src))
		qdel(src)

/obj/structure/machinery/defenses/sentry/damaged_action(damage)
	if(prob(10))
		spark_system.start()
	..()


/obj/structure/machinery/defenses/sentry/proc/fire(atom/A)
	if(!(world.time-last_fired >= fire_delay) || !light_on || !ammo || QDELETED(target))
		return

	if(world.time-last_fired >= 30 SECONDS) //if we haven't fired for a while, beep first
		playsound(loc, 'sound/machines/twobeep.ogg', 50, 1)
		sleep(3)

	if(ammo && ammo.ammo_position <= 0)
		to_chat(usr, SPAN_WARNING("[name] does not have any ammo."))
		return

	last_fired = world.time

	if(QDELETED(owner_mob))
		owner_mob = src

	if(omni_directional)
		setDir(get_dir(src, A))
	for(var/i in 1 to burst)
		if(actual_fire(A))
			break

	if(targets.len)
		addtimer(CALLBACK(src, PROC_REF(get_target)), fire_delay)

	if(!engaged_timer)
		SEND_SIGNAL(src, COMSIG_SENTRY_ENGAGED_ALERT, src)
		engaged_timer = addtimer(CALLBACK(src, PROC_REF(reset_engaged_timer)), engaged_timeout)

	if(!low_ammo_timer && ammo?.ammo_position && (ammo?.ammo_position < (ammo?.max_rounds * low_ammo_alert_percentage)))
		SEND_SIGNAL(src, COMSIG_SENTRY_LOW_AMMO_ALERT, src)
		low_ammo_timer = addtimer(CALLBACK(src, PROC_REF(reset_low_ammo_timer)), low_ammo_timeout)

/obj/structure/machinery/defenses/sentry/proc/reset_engaged_timer()
	engaged_timer = null

/obj/structure/machinery/defenses/sentry/proc/reset_low_ammo_timer()
	low_ammo_timer = null

/obj/structure/machinery/defenses/sentry/proc/actual_fire(atom/A)
	var/obj/item/projectile/proj = ammo.transfer_bullet_out()
	proj.forceMove(src)
	apply_traits(proj)
	proj.bullet_ready_to_fire(initial(name), null, owner_mob)
	var/datum/cause_data/cause_data = create_cause_data(initial(name), owner_mob, src)
	proj.weapon_cause_data = cause_data
	proj.firer = cause_data?.resolve_mob()
	proj.damage *= damage_mult
	proj.accuracy *= accuracy_mult
	GIVE_BULLET_TRAIT(proj, /datum/element/bullet_trait_iff, faction)
	proj.fire_at(A, src, owner_mob, proj.ammo.max_range, proj.ammo.shell_speed, null)
	muzzle_flash(Get_Angle(get_turf(src), A))
	track_shot()
	if(!ammo.ammo_position)
		handle_empty()
		return TRUE
	return FALSE

/obj/structure/machinery/defenses/sentry/proc/apply_traits(obj/item/projectile/proj)
	// Apply bullet traits from gun
	for(var/entry in traits_to_give)
		var/list/L
		// Check if this is an ID'd bullet trait
		if(istext(entry))
			L = traits_to_give[entry].Copy()
		else
			// Prepend the bullet trait to the list
			L = list(entry) + traits_to_give[entry]
		proj.apply_bullet_trait(L)

/obj/structure/machinery/defenses/sentry/proc/handle_empty()
	visible_message("[icon2html(src, viewers(src))] [SPAN_WARNING("The [name] beeps steadily and its ammo light blinks red.")]")
	playsound(loc, 'sound/weapons/smg_empty_alarm.ogg', 25, 1)
	update_icon()
	sent_empty_ammo = TRUE
	SEND_SIGNAL(src, COMSIG_SENTRY_EMPTY_AMMO_ALERT, src)

//Mostly taken from gun code.
/obj/structure/machinery/defenses/sentry/proc/muzzle_flash(angle)
	if(isnull(angle))
		return

	light_range += muzzlelum
	update_light()
//	play_fov_effect(src, 6, "gunfire", dir = NORTH, angle = angle)
	spawn(5)
		light_range -= muzzlelum
		update_light()

	var/image_layer = layer + 0.1
	var/offset = 13

	var/image/flash = image('icons/obj/items/weapons/projectiles.dmi',src,"muzzle_flash",image_layer)
	var/matrix/rotate = matrix() //Change the flash angle.
	rotate.Translate(0, offset)
	rotate.Turn(angle)
	flash.transform = rotate
	flash.flick_overlay(src, 3)

/obj/structure/machinery/defenses/sentry/proc/get_target(atom/movable/new_target)
	if(!islist(targets))
		return
	if(!targets.Find(new_target))
		targets.Add(new_target)

	if(!targets.len)
		return

	var/list/conscious_targets = list()
	var/list/unconscious_targets = list()

	for(var/atom/movable/A in targets) // orange allows sentry to fire through gas and darkness
		if(isliving(A))
			var/mob/living/M = A
			if(M.stat & DEAD)
				if(A == target)
					target = null
				targets.Remove(A)
				continue

			if(M.ally(faction) || M.invisibility || HAS_TRAIT(M, TRAIT_ABILITY_BURROWED))
				if(M == target)
					target = null
				targets.Remove(M)
				continue

		else
			if(!(A in other_targets))
				if(A == target)
					target = null
				targets.Remove(A)
				continue
			else
				if(A.ally(faction) || A.invisibility)
					if(A == target)
						target = null
					targets.Remove(A)
					continue

		if(!omni_directional)
			var/opp
			var/adj
			switch(dir)
				if(NORTH)
					opp = x-A.x
					adj = A.y-y
				if(SOUTH)
					opp = x-A.x
					adj = y-A.y
				if(EAST)
					opp = y-A.y
					adj = A.x-x
				if(WEST)
					opp = y-A.y
					adj = x-A.x

			var/r = 9999
			if(adj != 0)
				r = abs(opp/adj)
			var/angledegree = arcsin(r/sqrt(1+(r*r)))
			if(adj < 0 || (angledegree*2) > fire_angle)
				if(A == target)
					target = null
				targets.Remove(A)
				continue

		var/list/turf/path = getline2(src, A, include_from_atom = FALSE)
		if(!path.len || get_dist(src, A) > sentry_range)
			if(A == target)
				target = null
			targets.Remove(A)
			continue

		var/blocked = FALSE
		for(var/turf/T in path)
			if(T.density || T.opacity)
				blocked = TRUE
				break

			for(var/obj/structure/S in T)
				if(S.opacity)
					blocked = TRUE
					break

			for(var/obj/vehicle/multitile/V in T)
				blocked = TRUE
				break

			for(var/obj/effect/particle_effect/smoke/S in T)
				blocked = TRUE
				break

		if(!omni_directional)
			var/turf/F = get_step(src, src.dir)
			if(F.density || F.opacity)
				blocked = TRUE

			for(var/obj/structure/S in F)
				if(F.opacity)
					blocked = TRUE
					break

			for(var/obj/vehicle/multitile/V in F)
				blocked = TRUE
				break

		if(blocked)
			if(A == target)
				target = null
			targets.Remove(A)
			continue

		if(isliving(A))
			var/mob/living/M = A
			if(M.stat & UNCONSCIOUS)
				unconscious_targets += M
			else
				conscious_targets += M
		else
			target = A

	if(conscious_targets.len)
		target = pick(conscious_targets)
	else if(unconscious_targets.len)
		target = pick(unconscious_targets)

	if(!target) //No targets, don't bother firing
		return

	fire(target)

/obj/structure/machinery/defenses/sentry/premade
	name = "UA-577 Gauss Turret"
	immobile = TRUE
	light_on = TRUE
	icon_state = "premade" //for the map editor only
	faction_to_get = FACTION_MARINE
	static = TRUE

/obj/structure/machinery/defenses/sentry/premade/Initialize()
	. = ..()
	if(selected_categories[SENTRY_CATEGORY_IFF])
		selected_categories[SENTRY_CATEGORY_IFF] = SENTRY_IFF_HALF

/obj/structure/machinery/defenses/sentry/premade/get_examine_text(mob/user)
	. = ..()
	. += SPAN_NOTICE("It seems this one's bolts have been securely welded into the floor, and the access panel locked. You can't interact with it.")

/obj/structure/machinery/defenses/sentry/premade/attackby(obj/item/O, mob/user)
	return

/obj/structure/machinery/defenses/sentry/premade/power_on()
	return

/obj/structure/machinery/defenses/sentry/premade/power_off()
	return

/obj/structure/machinery/defenses/sentry/premade/damaged_action()
	return

/obj/structure/machinery/defenses/sentry/premade/dumb
	name = "Modified UA-577 Gauss Turret"
	desc = "A deployable, semi-automated turret with AI targeting capabilities. Armed with an M30 Autocannon and a high-capacity drum magazine. This one's IFF system has been disabled, and it will open fire on any targets within range."
	faction_to_get = null
	ammo = new /obj/item/ammo_magazine/sentry/premade/dumb

//the turret inside a static sentry deployment system
/obj/structure/machinery/defenses/sentry/premade/deployable
	name = "UA-633 Static Gauss Turret"
	desc = "A fully-automated defence turret with mid-range targeting capabilities. Armed with a modified M32-S Autocannon and an internal belt feed."
	density = TRUE
	faction_to_get = FACTION_MARINE
	fire_delay = 1
	ammo = new /obj/item/ammo_magazine/sentry/premade
	var/obj/structure/machinery/sentry_holder/deployment_system

/obj/structure/machinery/defenses/sentry/premade/deployable/Destroy()
	if(deployment_system)
		deployment_system.deployed_turret = null
		deployment_system = null
	. = ..()

/obj/structure/machinery/defenses/sentry/premade/deployable/colony
	faction_to_get = FACTION_COLONIST

//the turret inside the shuttle sentry deployment system
/obj/structure/machinery/defenses/sentry/premade/dropship
	density = TRUE
	faction_to_get = FACTION_MARINE
	omni_directional = TRUE
	choice_categories = list()
	selected_categories = list()
	var/obj/structure/dropship_equipment/sentry_holder/deployment_system
	var/obj/structure/machinery/camera/cas/linked_cam

/obj/structure/machinery/defenses/sentry/premade/dropship/Destroy()
	if(deployment_system)
		deployment_system.deployed_turret = null
		deployment_system = null
	QDEL_NULL(linked_cam)
	. = ..()

#define SENTRY_SNIPER_RANGE 10
/obj/structure/machinery/defenses/sentry/dmr
	name = "UA 725-D Sniper Sentry"
	desc = "A fully-automated defence turret with long-range targeting capabilities. Armed with a modified M32-S Autocannon and an internal belt feed."
	defense_type = "DMR"
	health = 150
	health_max = 150
	fire_delay = 1.25 SECONDS
	ammo = new /obj/item/ammo_magazine/sentry
	sentry_range = SENTRY_SNIPER_RANGE
	accuracy_mult = 4
	damage_mult = 2
	handheld_type = /obj/item/defenses/handheld/sentry/dmr

/obj/structure/machinery/defenses/sentry/dmr/handle_rof(level)
	return

/obj/structure/machinery/defenses/sentry/dmr/set_range()
	switch(dir)
		if(EAST)
			range_bounds = RECT(x + (SENTRY_SNIPER_RANGE/2), y, SENTRY_SNIPER_RANGE, SENTRY_SNIPER_RANGE)
		if(WEST)
			range_bounds = RECT(x - (SENTRY_SNIPER_RANGE/2), y, SENTRY_SNIPER_RANGE, SENTRY_SNIPER_RANGE)
		if(NORTH)
			range_bounds = RECT(x, y + (SENTRY_SNIPER_RANGE/2), SENTRY_SNIPER_RANGE, SENTRY_SNIPER_RANGE)
		if(SOUTH)
			range_bounds = RECT(x, y - (SENTRY_SNIPER_RANGE/2), SENTRY_SNIPER_RANGE, SENTRY_SNIPER_RANGE)

#undef SENTRY_SNIPER_RANGE
/obj/structure/machinery/defenses/sentry/shotgun
	name = "UA 12-G Shotgun Sentry"
	defense_type = "Shotgun"
	health = 250
	health_max = 250
	fire_delay = 2 SECONDS
	sentry_range = 3
	ammo = new /obj/item/ammo_magazine/sentry/shotgun

	accuracy_mult = 2 // Misses a lot since shotgun ammo has low accuracy, this should ensure a lot of shots actually hit.
	handheld_type = /obj/item/defenses/handheld/sentry/shotgun
	disassemble_time = 1.5 SECONDS

/obj/structure/machinery/defenses/sentry/shotgun/attack_alien(mob/living/carbon/xenomorph/M)
	. = ..()
	if(. == XENO_ATTACK_ACTION && light_on)
		M.visible_message(SPAN_DANGER("The sentry's steel tusks cut into [M]!"),
		SPAN_DANGER("The sentry's steel tusks cut into you!"), null, 5, CHAT_TYPE_XENO_COMBAT)
		M.apply_damage(20)

/obj/structure/machinery/defenses/sentry/shotgun/hitby(atom/movable/AM)
	if(AM.throwing && light_on)
		if(ismob(AM))
			var/mob/living/L = AM
			L.apply_damage(20)
			playsound(L, "bonk", 75, FALSE)
			L.visible_message(SPAN_DANGER("The sentry's steel tusks impale [L]!"),
			SPAN_DANGER("The sentry's steel tusks impale you!"))
			if(L.mob_size <= MOB_SIZE_XENO_SMALL)
				L.apply_effect(1, WEAKEN)

/obj/structure/machinery/defenses/sentry/mini
	name = "UA 512-M mini sentry"
	defense_type = "Mini"
	fire_delay = 0.15 SECONDS
	health = 150
	health_max = 150
	damage_mult = 0.4
	density = FALSE
	disassemble_time = 0.75 SECONDS
	handheld_type = /obj/item/defenses/handheld/sentry/mini
	composite_icon = FALSE

/obj/structure/machinery/defenses/sentry/launchable
	name = "UA 571-O sentry post"
	desc = "A deployable, omni-directional automated turret with AI targeting capabilities. Armed with an M30 Autocannon and a 100-round drum magazine with 500 rounds stored internally.  Due to the deployment method it is incapable of being moved."
	ammo = new /obj/item/ammo_magazine/sentry/dropped
	faction_to_get = FACTION_MARINE
	light_range = 5
	omni_directional = TRUE
	inherent_rounds = 500
	max_inherent_rounds = 500
	immobile = TRUE
	static = TRUE
	/// Cost to give sentry extra health
	var/upgrade_cost = 5
	/// Amount of bonus health they get from upgrade
	var/health_upgrade = 50
	var/obj/structure/machinery/camera/cas/linked_cam
	var/static/sentry_count = 1
	var/sentry_number
	light_range = 9

/obj/structure/machinery/defenses/sentry/launchable/Initialize()
	. = ..()
	sentry_number = sentry_count
	sentry_count++

/obj/structure/machinery/defenses/sentry/launchable/Destroy()
	QDEL_NULL(linked_cam)
	. = ..()

/obj/structure/machinery/defenses/sentry/launchable/power_on_action()
	. = ..()
	linked_cam = new(loc, "[name] [sentry_number] at [get_area(src)] ([obfuscate_x(x)], [obfuscate_y(y)])")

/obj/structure/machinery/defenses/sentry/launchable/power_off_action()
	. = ..()
	QDEL_NULL(linked_cam)


/obj/structure/machinery/defenses/sentry/launchable/attackby(obj/item/stack/sheets, mob/user)
	. = ..()

	if(!istype(sheets, /obj/item/stack/sheet/metal))
		to_chat(user, SPAN_WARNING("Use [upgrade_cost] metal sheets to give the sentry some plating."))
		return

	if(upgraded)
		to_chat(user, SPAN_WARNING("\The [src] has already been upgraded."))
		return

	if(sheets.amount >= upgrade_cost)
		if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION) , INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
			to_chat(user, SPAN_WARNING("You were interrupted! Try to stay still while you bolster the sentry with metal sheets..."))
			return

		if(sheets.use(upgrade_cost))
			src.health_max += health_upgrade
			src.update_health(-health_upgrade)
			upgraded = TRUE
			to_chat(user, SPAN_WARNING("You added some metal plating to the sentry, increasing its durability!"))
		else
			to_chat(user, SPAN_WARNING("You need at least [upgrade_cost] sheets of metal to upgrade this."))
	else
		to_chat(user, SPAN_WARNING("You need at least [upgrade_cost] sheets of metal to upgrade this."))

/obj/structure/machinery/defenses/sentry/launchable/handle_empty()
	// Checks if its completely dry or just needs reload, deconstruct if completely empty
	if(max_inherent_rounds > 0)
		visible_message(SPAN_WARNING("\The [name] beeps steadily and its ammo light blinks red. It still has rounds, requires manual reload!"))
		playsound(loc, 'sound/weapons/smg_empty_alarm.ogg', 25, 1)
		update_icon()
	else
		visible_message(SPAN_WARNING("\The [name] beeps steadily and its ammo light blinks red. It rapidly deconstructs itself!"))
		playsound(loc, 'sound/weapons/smg_empty_alarm.ogg', 25, 1)
		deconstruct()

/obj/structure/machinery/defenses/sentry/launchable/deconstruct(disassembled = TRUE)
	if(disassembled)
		new /obj/item/stack/sheet/metal/medium_stack(loc)
		new /obj/item/stack/sheet/plasteel/medium_stack(loc)
	return ..()

/obj/structure/machinery/defenses/sentry/anti_tank
	name = "UAC AT DE-58 sentry gun"
	desc = "A deployable, semi-automated turret with AI targeting capabilities. Armed with an 105mm cannon, with 20 rounds drum."
	defense_type = "at" // TODO: DO FUCKING ICON
	fire_delay = 5 SECONDS
	ammo = new /obj/item/ammo_magazine/sentry/anti_tank
	sentry_icon = 'icons/obj/structures/machinery/defenses/big_sentry.dmi'
	omni_directional = TRUE
	sentry_icon_resize = -16
	inherent_rounds = 18
	max_inherent_rounds = 18
