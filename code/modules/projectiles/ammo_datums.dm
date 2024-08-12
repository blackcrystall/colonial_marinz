/datum/ammo
	var/name			= "generic bullet"
	var/headshot_state	= null		//Icon state when a human is permanently killed with it by execution/suicide.
	var/hud_state		= "unknown" //Bullet type on the Ammo HUD
	var/hud_state_empty	= "unknown" //Empty bullet type on the Ammo HUD
	var/icon			= 'icons/obj/items/weapons/projectiles.dmi'
	var/icon_state		= "bullet"
	var/ping			= "ping_b"	//The icon that is displayed when the bullet bounces off something.
	var/sound_hit			//When it deals damage.
	var/sound_armor			//When it's blocked by human armor.
	var/sound_miss			//When it misses someone.
	var/sound_bounce		//When it bounces off something.
	var/sound_shield_hit	//When the bullet is absorbed by a xeno_shield

	var/accurate_range_min			= 0			// Snipers use this to simulate poor accuracy at close ranges
	var/scatter						= 0			// How much the ammo scatters when burst fired, added to gun scatter, along with other mods
	var/stamina_damage				= 0
	var/damage						= 0			// This is the base damage of the bullet as it is fired
	var/damage_type					= BRUTE		// BRUTE, BURN, TOX, OXY, CLONE are the only things that should be in here
	var/penetration					= 0			// How much armor it ignores before calculations take place
	var/shrapnel_chance				= 0			// The % chance it will imbed in a human
	var/shrapnel_type				= 0			// The shrapnel type the ammo will embed, if the chance rolls
	var/bonus_projectiles_type					// Type path of the extra projectiles
	var/bonus_projectiles_amount	= 0			// How many extra projectiles it shoots out. Works kind of like firing on burst, but all of the projectiles travel together
	var/debilitate[]				= null		// Stun,knockdown,knockout,irradiate,stutter,eyeblur,drowsy,agony
	var/pen_armor_punch				= 0.25		// how much armor breaking will be done per point of penetration. This is for weapons that penetrate with their shape (like needle bullets)
	var/damage_armor_punch			= 0.25		// how much armor breaking is done by sheer weapon force. This is for big blunt weapons
	var/sound_override				= null		// if we should play a special sound when firing.
	var/flags_ammo_behavior			= NO_FLAGS

	var/accuracy					= HIT_ACCURACY_TIER_1			// This is added to the bullet's base accuracy.
	var/accuracy_var_low			= PROJECTILE_VARIANCE_TIER_9	// How much the accuracy varies when fired. // This REDUCES the lower bound of accuracy variance by 2%, to 96%.
	var/accuracy_var_high			= PROJECTILE_VARIANCE_TIER_9	// This INCREASES the upper bound of accuracy variance by 2%, to 107%.
	var/accurate_range				= 6								// For most guns, this is where the bullet dramatically looses accuracy. Not for snipers though.
	var/max_range					= 22							// This will de-increment a counter on the bullet.
	var/ammo_range_fallof			= BULLET_FALLOF_MULT_TIER_1
	var/damage_var_low				= PROJECTILE_VARIANCE_TIER_9	// Same as with accuracy variance.
	var/damage_var_high				= PROJECTILE_VARIANCE_TIER_9	// This INCREASES the upper bound of damage variance by 2%, to 107%.
	var/damage_falloff				= DAMAGE_FALLOFF_TIER_10		// How much damage the bullet loses per turf traveled after the effective range
	var/damage_buildup				= DAMAGE_BUILDUP_TIER_1			// How much damage the bullet loses per turf away before the effective range
	var/effective_range_min			= EFFECTIVE_RANGE_OFF			//What minimum range the ammo deals full damage, builds up the closer you get. 0 for no minimum. Added onto gun range as a modifier.
	var/effective_range_max			= EFFECTIVE_RANGE_OFF			//What maximum range the ammo deals full damage, tapers off using damage_falloff after hitting this value. 0 for no maximum. Added onto gun range as a modifier.
	var/shell_speed					= AMMO_SPEED_TIER_1				// How fast the projectile moves.

	var/bullet_color				= COLOR_WHITE	//Determines what color our bullet will be when it flies

	var/handful_type				= /obj/item/ammo_magazine/handful
	var/handful_color
	var/handful_state				= "bullet"		//custom handful sprite, for shotgun shells or etc.
	var/multiple_handful_name						//so handfuls say 'buckshot shells' not 'shell'

	var/apply_delegate				= TRUE			// Does this apply xenomorph behaviour delegate?

	var/list/list/traits_to_give					// that will be given to a projectile with the current ammo datum An assoc list in the format list(/datum/element/bullet_trait_to_give = list(...args))

	var/flamer_reagent_type			= /datum/reagent/napalm/ut
	var/flame_range					= 0

	var/hit_effect_color			= "#FF0000"	// The flicker that plays when a bullet hits a target. Usually red. Can be nulled so it doesn't show up at all.

/datum/ammo/New()
	set_bullet_traits()

/datum/ammo/proc/on_bullet_generation(obj/item/projectile/generated_projectile, mob/bullet_generator) //NOT used on New(), applied to the projectiles.
	return

/// Populate traits_to_give in this proc
/datum/ammo/proc/set_bullet_traits()
	return

/datum/ammo/can_vv_modify()
	return FALSE

/datum/ammo/proc/do_at_half_range(obj/item/projectile/proj)
	SHOULD_NOT_SLEEP(TRUE)
	return

/datum/ammo/proc/on_embed(mob/embedded_mob, obj/limb/target_organ)
	return

/datum/ammo/proc/do_at_max_range(turf/T, obj/item/projectile/proj)
	SHOULD_NOT_SLEEP(TRUE)
	return

/datum/ammo/proc/on_shield_block(mob/hit, obj/item/projectile/proj) //Does it do something special when shield blocked? Ie. a flare or grenade that still blows up.
	return

/datum/ammo/proc/on_hit_turf(turf/T, obj/item/projectile/proj) //Special effects when hitting dense turfs.
	SHOULD_NOT_SLEEP(TRUE)
	return

/datum/ammo/proc/on_hit_mob(mob/hit, obj/item/projectile/proj, mob/user) //Special effects when hitting mobs.
	SHOULD_NOT_SLEEP(TRUE)
	return

///Special effects when pointblanking mobs. Ultimately called from /living/attackby(). Return TRUE to end the PB attempt.
/datum/ammo/proc/on_pointblank(mob/living/living, obj/item/projectile/proj, mob/living/user, obj/item/weapon/gun/fired_from)
	return

/datum/ammo/proc/on_hit_obj(obj/O, obj/item/projectile/proj) //Special effects when hitting objects.
	SHOULD_NOT_SLEEP(TRUE)
	return

///Special effects for leaving a turf. Only called if the projectile has AMMO_LEAVE_TURF enabled
/datum/ammo/proc/on_leave_turf(turf/T, atom/firer, obj/item/projectile/proj)
	return

/datum/ammo/proc/on_near_target(turf/T, obj/item/projectile/proj) //Special effects when passing near something. Range of things that triggers it is controlled by other ammo flags.
	return 0 //return 0 means it flies even after being near something. Return 1 means it stops

/datum/ammo/proc/knockback(mob/living/living_mob, obj/item/projectile/fired_projectile, max_range = 2)
	if(!living_mob || living_mob == fired_projectile.firer)
		return
	if(fired_projectile.distance_travelled > max_range || living_mob.lying)
		return //Two tiles away or more, basically.

	if(living_mob.mob_size >= MOB_SIZE_BIG)
		return //Big xenos are not affected.

	shake_camera(living_mob, 3, 4)
	knockback_effects(living_mob, fired_projectile)
	slam_back(living_mob, fired_projectile)

/datum/ammo/proc/slam_back(mob/living/living_mob, obj/item/projectile/fired_projectile)
	//Either knockback or slam them into an obstacle.
	var/direction = Get_Compass_Dir(fired_projectile.z ? fired_projectile : fired_projectile.firer, living_mob) //More precise than get_dir.
	if(!direction) //Same tile.
		return
	if(!step(living_mob, direction))
		living_mob.animation_attack_on(get_step(living_mob, direction))
		playsound(living_mob.loc, "punch", 25, 1)
		living_mob.visible_message(SPAN_DANGER("[living_mob] slams into an obstacle!"),
			isxeno(living_mob) ? SPAN_XENODANGER("You slam into an obstacle!") : SPAN_HIGHDANGER("You slam into an obstacle!"), null, 4, CHAT_TYPE_TAKING_HIT)
		living_mob.apply_damage(MELEE_FORCE_TIER_2)

///The applied effects for knockback(), overwrite to change slow/stun amounts for different ammo datums
/datum/ammo/proc/knockback_effects(mob/living/living_mob, obj/item/projectile/fired_projectile)
	if(iscarbonsizexeno(living_mob))
		var/mob/living/carbon/xenomorph/target = living_mob
		target.apply_effect(0.7, WEAKEN) // 0.9 seconds of stun, per agreement from Balance Team when switched from MC stuns to exact stuns
		target.apply_effect(1, SUPERSLOW)
		target.apply_effect(2, SLOW)
		to_chat(target, SPAN_XENODANGER("You are shaken by the sudden impact!"))
	else
		living_mob.apply_stamina_damage(fired_projectile.ammo.damage, fired_projectile.def_zone, ARMOR_BULLET)

/datum/ammo/proc/pushback(mob/target_mob, obj/item/projectile/fired_projectile, max_range = 2)
	if(!target_mob || target_mob == fired_projectile.firer || fired_projectile.distance_travelled > max_range || target_mob.lying)
		return

	if(target_mob.mob_size >= MOB_SIZE_BIG)
		return //too big to push

	to_chat(target_mob, isxeno(target_mob) ? SPAN_XENODANGER("You are pushed back by the sudden impact!") : SPAN_HIGHDANGER("You are pushed back by the sudden impact!"), null, 4, CHAT_TYPE_TAKING_HIT)
	slam_back(target_mob, fired_projectile, max_range)

/datum/ammo/proc/burst(atom/target, obj/item/projectile/proj, damage_type = BRUTE, range = 1, damage_div = 2, show_message = SHOW_MESSAGE_VISIBLE) //damage_div says how much we divide damage
	if(!target || !proj)
		return
	for(var/mob/living/carbon/hit in orange(range,target))
		if(proj.firer == hit)
			continue
		if(show_message)
			var/msg = "You are hit by backlash from \a </b>[proj.name]</b>!"
			hit.visible_message(SPAN_DANGER("[hit] is hit by backlash from \a [proj.name]!"), isxeno(hit) ? SPAN_XENODANGER("[msg]"):SPAN_HIGHDANGER("[msg]"))
		var/damage = proj.damage/damage_div

		var/mob/living/carbon/xenomorph/XNO = null

		if(isxeno(hit))
			XNO = hit
			var/total_explosive_resistance = XNO.caste.xeno_explosion_resistance + XNO.armor_explosive_buff
			damage = armor_damage_reduction(GLOB.xeno_explosive, damage, total_explosive_resistance , 60, 0, 0.5, XNO.armor_integrity)
			var/armor_punch = armor_break_calculation(GLOB.xeno_explosive, damage, total_explosive_resistance, 60, 0, 0.5, XNO.armor_integrity)
			XNO.apply_armorbreak(armor_punch)

		hit.apply_damage(damage,damage_type)

		if(XNO && XNO.xeno_shields.len)
			proj.play_shielded_hit_effect(hit)
		else
			proj.play_hit_effect(hit)

/datum/ammo/proc/fire_bonus_projectiles(obj/item/projectile/orig_proj)
	set waitfor = FALSE

	var/turf/curloc = get_turf(orig_proj.shot_from)
	var/initial_angle = Get_Angle(curloc, orig_proj.original_target_turf)

	for(var/i in 1 to bonus_projectiles_amount) //Want to run this for the number of bonus projectiles.
		var/final_angle = initial_angle

		var/obj/item/projectile/proj = new /obj/item/projectile(curloc, orig_proj.weapon_cause_data)
		proj.generate_bullet(GLOB.ammo_list[bonus_projectiles_type]) //No bonus damage or anything.
		proj.accuracy = round(proj.accuracy * orig_proj.accuracy/initial(orig_proj.accuracy)) //if the gun changes the accuracy of the main proj, it also affects the bonus ones.
		orig_proj.give_bullet_traits(proj)

		var/total_scatter_angle = proj.scatter
		final_angle += rand(-total_scatter_angle, total_scatter_angle)
		var/turf/new_target = get_angle_target_turf(curloc, final_angle, 30)

		proj.fire_at(new_target, orig_proj.firer, orig_proj.shot_from, proj.ammo.max_range, proj.ammo.shell_speed, final_angle) //Fire!

/datum/ammo/proc/drop_flame(turf/T, datum/cause_data/cause_data)
	if(!istype(T))
		return
	if(locate(/obj/flamer_fire) in T)
		return

	var/datum/reagent/R = new flamer_reagent_type()
	new /obj/flamer_fire(T, cause_data, R, flame_range)

/datum/ammo/proc/ammo_process(obj/item/projectile/proj)
	return


/*
//======
					Default Ammo
//======
*/
//Only when things screw up do we use this as a placeholder.
/datum/ammo/bullet
	name = "default bullet"
	icon_state = "bullet"
	headshot_state = HEADSHOT_OVERLAY_LIGHT
	flags_ammo_behavior = AMMO_BALLISTIC
	sound_hit  = "ballistic_hit"
	sound_armor  = "ballistic_armor"
	sound_miss  = "ballistic_miss"
	sound_bounce = "ballistic_bounce"
	sound_shield_hit = "ballistic_shield_hit"

	bullet_color = COLOR_VERY_SOFT_YELLOW

	accurate_range_min = 0
	damage = 10
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_1
	shrapnel_type = /obj/item/shard/shrapnel
	shell_speed = AMMO_SPEED_TIER_4

/datum/ammo/bullet/proc/handle_battlefield_execution(datum/ammo/firing_ammo, mob/living/hit, obj/item/projectile/firing_projectile, mob/living/user, obj/item/weapon/gun/fired_from)
	SIGNAL_HANDLER

	if(!user || hit == user || user.zone_selected != "head" || user.a_intent != INTENT_HARM || !ishuman_strict(hit))
		return

	if(!skillcheck(user, SKILL_EXECUTION, SKILL_EXECUTION_TRAINED))
		to_chat(user, SPAN_DANGER("You don't know how to execute someone correctly."))
		return

	var/mob/living/carbon/human/execution_target = hit

	if(execution_target.status_flags & PERMANENTLY_DEAD)
		to_chat(user, SPAN_DANGER("[execution_target] has already been executed!"))
		return

	INVOKE_ASYNC(src, PROC_REF(attempt_battlefield_execution), src, execution_target, firing_projectile, user, fired_from)

	return COMPONENT_CANCEL_AMMO_POINT_BLANK

/datum/ammo/bullet/proc/attempt_battlefield_execution(datum/ammo/firing_ammo, mob/living/carbon/human/execution_target, obj/item/projectile/firing_projectile, mob/living/user, obj/item/weapon/gun/fired_from)
	user.affected_message(execution_target,
		SPAN_HIGHDANGER("You aim \the [fired_from] at [execution_target]'s head!"),
		SPAN_HIGHDANGER("[user] aims \the [fired_from] directly at your head!"),
		SPAN_DANGER("[user] aims \the [fired_from] at [execution_target]'s head!"))

	user.next_move += 1.1 SECONDS //PB has no click delay; readding it here to prevent people accidentally queuing up multiple executions.

	if(!do_after(user, 1 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE) || !user.Adjacent(execution_target))
		fired_from.delete_bullet(firing_projectile, TRUE)
		return

	if(!(fired_from.flags_gun_features & GUN_SILENCED))
		playsound(user, fired_from.fire_sound, fired_from.firesound_volume, FALSE)
	else
		playsound(user, fired_from.fire_sound, 25, FALSE)

	shake_camera(user, 1, 2)

	execution_target.apply_damage(damage * 3, BRUTE, "head", no_limb_loss = TRUE, permanent_kill = TRUE) //Apply gobs of damage and make sure they can't be revived later...
	execution_target.apply_damage(200, OXY) //...fill out the rest of their health bar with oxyloss...
	execution_target.death(create_cause_data("execution", user)) //...make certain they're properly dead...
	shake_camera(execution_target, 3, 4)
	execution_target.update_headshot_overlay(headshot_state) //...and add a gory headshot overlay.

	execution_target.visible_message(SPAN_HIGHDANGER(uppertext("[execution_target] WAS EXECUTED!")), \
		SPAN_HIGHDANGER("You WERE EXECUTED!"))

	user.count_statistic_stat(STATISTICS_EXECUTION)

	var/area/execution_area = get_area(execution_target)

	msg_admin_attack(FONT_SIZE_HUGE("[key_name(usr)] has battlefield executed [key_name(execution_target)] in [get_area(usr)] ([usr.loc.x],[usr.loc.y],[usr.loc.z])."), usr.loc.x, usr.loc.y, usr.loc.z)
	log_attack("[key_name(usr)] battlefield executed [key_name(execution_target)] at [execution_area.name].")

	if(flags_ammo_behavior & AMMO_EXPLOSIVE)
		execution_target.gib()


/*
//======
					Custom Ammo
//======
*/
/* SPECIAL FLAGS
CUSTOM_AMMO_EXPLOSION
CUSTOM_AMMO_CHEMICAL
CUSTOM_AMMO_SMOKE
CUSTOM_AMMO_EFFECT
CUSTOM_AMMO_ON_HIT
CUSTOM_AMMO_ON_SHOT
CUSTOM_AMMO_CONTROL
CUSTOM_AMMO_AUTO_TARGET
CUSTOM_AMMO_PENETRATION
*/
/datum/ammo/bullet/custom
	name = "custom bullet"
	icon_state = "bullet"
	flags_ammo_behavior = AMMO_BALLISTIC
	sound_hit 	 = "ballistic_hit"
	sound_armor  = "ballistic_armor"
	sound_miss	 = "ballistic_miss"
	sound_bounce = "ballistic_bounce"
	sound_shield_hit = "ballistic_shield_hit"

//new vars
	var/caliber
	var/flags_custom_ammo


/datum/ammo/bullet/custom/do_at_half_range(obj/item/projectile/proj)
	. = ..()

/datum/ammo/bullet/custom/on_embed(mob/embedded_mob, obj/limb/target_organ)
	. = ..()

/datum/ammo/bullet/custom/do_at_max_range(turf/T, obj/item/projectile/proj)
	. = ..()

/datum/ammo/bullet/custom/on_shield_block(mob/hit, obj/item/projectile/proj) //Does it do something special when shield blocked? Ie. a flare or grenade that still blows up.
	. = ..()
	if(flags_custom_ammo & CUSTOM_AMMO_PENETRATION)
		drop_flame(get_turf(proj), proj.weapon_cause_data, proj)
		if(shrapnel_type)
			create_shrapnel(get_turf(proj), 4, , , shrapnel_type, proj.weapon_cause_data)
		burst(get_turf(proj), proj, damage_type, 2 , 3)

/datum/ammo/bullet/custom/on_hit_turf(turf/T, obj/item/projectile/proj) //Special effects when hitting dense turfs.
	. = ..()

/datum/ammo/bullet/custom/on_hit_mob(mob/hit, obj/item/projectile/proj, mob/user) //Special effects when hitting mobs.
	. = ..()

///Special effects when pointblanking mobs. Ultimately called from /living/attackby(). Return TRUE to end the PB attempt.
/datum/ammo/bullet/custom/on_pointblank(mob/living/living, obj/item/projectile/proj, mob/living/user, obj/item/weapon/gun/fired_from)
	. = ..()

/datum/ammo/bullet/custom/on_hit_obj(obj/O, obj/item/projectile/proj) //Special effects when hitting objects.
	. = ..()

/datum/ammo/bullet/custom/on_near_target(turf/T, obj/item/projectile/proj) //Special effects when passing near something. Range of things that triggers it is controlled by other ammo flags.
	if(flags_custom_ammo & CUSTOM_AMMO_PROXIMITY)
		drop_flame(T, proj.weapon_cause_data, proj)
		if(shrapnel_type)
			create_shrapnel(T, 4, , ,shrapnel_type, proj.weapon_cause_data)
		return FALSE
	else if(flags_custom_ammo & CUSTOM_AMMO_FLAK)
		burst(T,proj,damage_type, 2 , 3)
		return FALSE

/datum/ammo/bullet/custom/drop_flame(turf/T, datum/cause_data/cause_data, obj/item/projectile/proj)
	if(proj.container && proj.container.inernal_charge && proj.container.inernal_detonator)
		proj.forceMove(proj.loc)
		proj.container.inernal_charge.prime()


//headshot_state | bullet_color
/datum/ammo/bullet/custom/proc/calculate_new_ammo_stats(new_stats = list(), new_flags, new_caliber)
	caliber = new_caliber
	flags_custom_ammo = new_flags
	for(var/i in new_stats)
		switch(i)
			if("damage")
				damage = new_stats[i]
			if("scatter")
				scatter = new_stats[i]
			if("accuracy")
				accuracy = new_stats[i]
			if("damage_falloff")
				damage_falloff = new_stats[i]
			if("damage_buildup")
				damage_buildup = new_stats[i]
			if("penetration")
				penetration = new_stats[i]
			if("shrapnel_chance")
				shrapnel_chance = new_stats[i]
			if("shrapnel_type")
				shrapnel_type = new_stats[i]
			if("debilitate")
				debilitate = new_stats[i]
			if("accurate_range")
				accurate_range = new_stats[i]
			if("max_range")
				max_range = new_stats[i]
			if("shell_speed")
				shell_speed = new_stats[i]
/*
//======
					Pistol Ammo
//======
*/

// Used by M4A3, M4A3 Custom and B92FS
/datum/ammo/bullet/pistol
	name = "pistol bullet"
	hud_state = "pistol"
	hud_state_empty = "pistol_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM
	accuracy = HIT_ACCURACY_TIER_0
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	damage = 40
	penetration= ARMOR_PENETRATION_TIER_2
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

/datum/ammo/bullet/pistol/tiny
	name = "light pistol bullet"
	hud_state = "pistol_light"

/datum/ammo/bullet/pistol/tranq
	name = "tranquilizer bullet"
	hud_state = "pistol_tranq"
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_RESIST
	stamina_damage = 30
	damage = 15

//2020 rebalance: is supposed to counter runners and lurkers, dealing high damage to the only castes with no armor.
//Limited by its lack of versatility and lower supply, so marines finally have an answer for flanker castes that isn't just buckshot.

/datum/ammo/bullet/pistol/hollow
	name = "hollowpoint pistol bullet"
	hud_state = "pistol_hollow"

	damage = 55 //hollowpoint is strong
	penetration = 0 //hollowpoint can't pierce armor!
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_3 //hollowpoint causes shrapnel

// Used by M4A3 AP and mod88
/datum/ammo/bullet/pistol/ap
	name = "armor-piercing pistol bullet"
	hud_state = "pistol_ap"

	damage = 25
	accuracy = HIT_ACCURACY_TIER_2
	penetration = ARMOR_PENETRATION_TIER_8
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

	pen_armor_punch = 0.5

/datum/ammo/bullet/pistol/ap/penetrating
	name = "wall-penetrating pistol bullet"
	hud_state = "pistol_wp"
	shrapnel_chance = 0

	damage = 30
	penetration = ARMOR_PENETRATION_TIER_10

	damage_armor_punch = 0.5

/datum/ammo/bullet/pistol/ap/penetrating/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/pistol/ap/cluster
	name = "cluster pistol bullet"
	hud_state = "pistol_cluster"
	shrapnel_chance = 0
	var/cluster_addon = 1.5

/datum/ammo/bullet/pistol/ap/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/pistol/ap/toxin
	name = "toxic pistol bullet"
	hud_state = "pistol_tox"
	var/acid_per_hit = 10
	var/organic_damage_mult = 3

/datum/ammo/bullet/pistol/ap/toxin/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/toxic_buildup, acid_per_hit)

/datum/ammo/bullet/pistol/ap/toxin/on_hit_turf(turf/T, obj/item/projectile/proj)
	. = ..()
	if(T.turf_flags & TURF_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/pistol/ap/toxin/on_hit_obj(obj/O, obj/item/projectile/proj)
	. = ..()
	if(O.flags_obj & OBJ_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/pistol/le
	name = "armor-shredding pistol bullet"
	hud_state = "pistol_le"
	damage = 15
	penetration = ARMOR_PENETRATION_TIER_4
	pen_armor_punch = 3

/datum/ammo/bullet/pistol/rubber
	name = "rubber pistol bullet"
	sound_override = 'sound/weapons/gun_c99.ogg'
	hud_state = "pistol_light"

	damage = 0
	stamina_damage = 25
	shrapnel_chance = 0

// Reskinned rubber bullet used for the ES-4 CL pistol.
/datum/ammo/bullet/pistol/rubber/stun
	name = "stun pistol bullet"
	sound_override = null

// Used by M1911, Deagle and KT-42
/datum/ammo/bullet/pistol/heavy
	name = "heavy pistol bullet"
	hud_state = "pistol_eagle"
	hud_state_empty = "pistol_eagle_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM
	accuracy = HIT_ACCURACY_TIER_0
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	damage = 55
	penetration = ARMOR_PENETRATION_TIER_3
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

/datum/ammo/bullet/pistol/heavy/cluster
	name = "heavy cluster pistol bullet"
	hud_state = "pistol_cluster"
	var/cluster_addon = 1.5

/datum/ammo/bullet/pistol/heavy/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/pistol/heavy/super //Commander's variant
	name = ".50 heavy pistol bullet"
	damage = 60
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/pistol/heavy/super/highimpact
	name = ".50 high-impact pistol bullet"
	hud_state = "pistol_eagle_highimpact"
	penetration = ARMOR_PENETRATION_TIER_1
	debilitate = list(0,1.5,0,0,0,1,0,0)
	flags_ammo_behavior = AMMO_BALLISTIC

/datum/ammo/bullet/pistol/heavy/super/highimpact/ap
	name = ".50 high-impact armor piercing pistol bullet"
	penetration = ARMOR_PENETRATION_TIER_10
	damage = 45

	damage_armor_punch = 1

/datum/ammo/bullet/pistol/heavy/super/highimpact/upp
	name = "high-impact pistol bullet"
	sound_override = 'sound/weapons/gun_DE50.ogg'
	penetration = ARMOR_PENETRATION_TIER_6
	debilitate = list(0,1.5,0,0,0,1,0,0)
	flags_ammo_behavior = AMMO_BALLISTIC

/datum/ammo/bullet/pistol/heavy/super/highimpact/New()
	..()
	RegisterSignal(src, COMSIG_AMMO_POINT_BLANK, PROC_REF(handle_battlefield_execution))

/datum/ammo/bullet/pistol/heavy/super/highimpact/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 4)

/datum/ammo/bullet/pistol/deagle
	name = ".50 heavy pistol bullet"
	damage = 45
	headshot_state = HEADSHOT_OVERLAY_HEAVY
	accuracy = HIT_ACCURACY_TIER_0
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_6
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_5

/datum/ammo/bullet/pistol/incendiary
	name = "incendiary pistol bullet"
	hud_state = "pistol_fire"
	damage_type = BURN
	shrapnel_chance = 0
	flags_ammo_behavior = AMMO_BALLISTIC

	bullet_color = COLOR_TAN_ORANGE

	accuracy = HIT_ACCURACY_TIER_3
	damage = 20

/datum/ammo/bullet/pistol/incendiary/set_bullet_traits()
	..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

// Used by the hipower
// I know that the 'high power' in the name is supposed to mean its 'impressive' magazine capacity
// but this is CM, half our guns have baffling misconceptions and mistakes (how do you grab the type-71?) so it's on-brand.
// maybe in the far flung future of 2280 someone screwed up the design.

/datum/ammo/bullet/pistol/highpower
	name = "high-powered pistol bullet"
	headshot_state = HEADSHOT_OVERLAY_MEDIUM

	accuracy = HIT_ACCURACY_TIER_3
	damage = 36
	penetration = ARMOR_PENETRATION_TIER_5
	damage_falloff = DAMAGE_FALLOFF_TIER_7

// Used by VP78 and Auto 9
/datum/ammo/bullet/pistol/squash
	name = "squash-head pistol bullet"
	hud_state = "pistol_sq"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM
	debilitate = list(0,0,0,0,0,0,0,2)

	accuracy = HIT_ACCURACY_TIER_4
	damage = 45
	penetration= ARMOR_PENETRATION_TIER_6
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2
	damage_falloff = DAMAGE_FALLOFF_TIER_6 //"VP78 - the only pistol viable as a primary."-Vampmare, probably.

/datum/ammo/bullet/pistol/squash/toxin
	name = "toxic squash-head pistol bullet"
	hud_state = "pistol_tox"
	var/acid_per_hit = 10
	var/organic_damage_mult = 3

/datum/ammo/bullet/pistol/squash/toxin/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/toxic_buildup, acid_per_hit)

/datum/ammo/bullet/pistol/squash/toxin/on_hit_turf(turf/T, obj/item/projectile/proj)
	. = ..()
	if(T.turf_flags & TURF_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/pistol/squash/toxin/on_hit_obj(obj/O, obj/item/projectile/proj)
	. = ..()
	if(O.flags_obj & OBJ_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/pistol/squash/penetrating
	name = "wall-penetrating squash-head pistol bullet"
	hud_state = "pistol_wp"
	shrapnel_chance = 0
	penetration = ARMOR_PENETRATION_TIER_10

/datum/ammo/bullet/pistol/squash/penetrating/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/pistol/squash/cluster
	name = "cluster squash-head pistol bullet"
	hud_state = "pistol_wp"
	shrapnel_chance = 0
	var/cluster_addon = 2

/datum/ammo/bullet/pistol/squash/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/pistol/squash/incendiary
	name = "incendiary squash-head pistol bullet"
	hud_state = "pistol_fire"
	damage_type = BURN
	bullet_color = COLOR_TAN_ORANGE
	shrapnel_chance = 0
	flags_ammo_behavior = AMMO_BALLISTIC
	accuracy = HIT_ACCURACY_TIER_3
	damage = 35

/datum/ammo/bullet/pistol/squash/incendiary/set_bullet_traits()
	..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))


/datum/ammo/bullet/pistol/mankey
	name = "live monkey"
	icon_state = "monkey1"
	hud_state = "monkey"
	hud_state_empty = "monkey_empty"
	ping = null //no bounce off.
	bullet_color = COLOR_TAN_ORANGE
	damage_type = BURN
	debilitate = list(4,4,0,0,0,0,0,0)
	flags_ammo_behavior = AMMO_IGNORE_ARMOR

	damage = 15
	damage_var_high = PROJECTILE_VARIANCE_TIER_5
	shell_speed = AMMO_SPEED_TIER_2

/datum/ammo/bullet/pistol/mankey/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/pistol/mankey/on_hit_mob(mob/hit,obj/item/projectile/proj)
	if(proj && proj.loc && !hit.stat && !istype(hit,/mob/living/carbon/human/monkey))
		proj.visible_message(SPAN_DANGER("The [src] chimpers furiously!"))
		new /mob/living/carbon/human/monkey(proj.loc)

/datum/ammo/bullet/pistol/smart
	name = "smartpistol bullet"
	flags_ammo_behavior = AMMO_BALLISTIC

	accuracy = HIT_ACCURACY_TIER_8
	damage = 30
	penetration = 20
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

/*
//======
					Revolver Ammo
//======
*/

/datum/ammo/bullet/revolver
	name = "revolver bullet"
	hud_state = "revolver"
	hud_state_empty = "revolver_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM

	damage = 55
	penetration = ARMOR_PENETRATION_TIER_1
	accuracy = HIT_ACCURACY_TIER_1

/datum/ammo/bullet/revolver/marksman
	name = "marksman revolver bullet"
	hud_state = "revolver_ap"
	shrapnel_chance = 0
	damage_falloff = 0
	accurate_range = 12
	penetration = ARMOR_PENETRATION_TIER_7

/datum/ammo/bullet/revolver/heavy
	name = "heavy revolver bullet"
	hud_state = "revolver_heavy"
	damage = 35
	penetration = ARMOR_PENETRATION_TIER_4
	accuracy = HIT_ACCURACY_TIER_3

/datum/ammo/bullet/revolver/heavy/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 4)

/datum/ammo/bullet/revolver/incendiary
	name = "incendiary revolver bullet"
	hud_state = "revolver_fire"
	damage = 40
	bullet_color = COLOR_TAN_ORANGE

/datum/ammo/bullet/revolver/incendiary/set_bullet_traits()
	..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/revolver/marksman/toxin
	name = "toxic revolver bullet"
	hud_state = "revolver_toxin"
	var/acid_per_hit = 10
	var/organic_damage_mult = 3

/datum/ammo/bullet/revolver/marksman/toxin/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/toxic_buildup, acid_per_hit)

/datum/ammo/bullet/revolver/marksman/toxin/on_hit_turf(turf/T, obj/item/projectile/proj)
	. = ..()
	if(T.turf_flags & TURF_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/revolver/marksman/toxin/on_hit_obj(obj/O, obj/item/projectile/proj)
	. = ..()
	if(O.flags_obj & OBJ_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/revolver/penetrating
	name = "wall-penetrating revolver bullet"
	hud_state = "revolver_wp"
	shrapnel_chance = 0

	penetration = ARMOR_PENETRATION_TIER_10

/datum/ammo/bullet/revolver/penetrating/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/revolver/cluster
	name = "cluster revolver bullet"
	hud_state = "revolver_cluster"
	shrapnel_chance = 0
	var/cluster_addon = 4
	penetration = ARMOR_PENETRATION_TIER_10

/datum/ammo/bullet/revolver/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/revolver/nagant
	name = "nagant revolver bullet"
	hud_state = "revolver_cluster"
	headshot_state	= HEADSHOT_OVERLAY_LIGHT //Smaller bullet.
	damage = 40


/datum/ammo/bullet/revolver/upp/shrapnel
	name = "shrapnel shot"
	hud_state = "revolver_shrapnel"
	headshot_state	= HEADSHOT_OVERLAY_HEAVY //Gol-dang shotgun blow your fething head off.
	debilitate = list(0,0,0,0,0,0,0,0)
	icon_state = "shrapnelshot"
	handful_state = "shrapnel"
	bonus_projectiles_type = /datum/ammo/bullet/revolver/upp/shrapnel_bits

	max_range = 6
	damage = 40 // + TIER_4 * 3
	damage_falloff = DAMAGE_FALLOFF_TIER_7
	penetration = ARMOR_PENETRATION_TIER_8
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_3
	shrapnel_chance = 100
	shrapnel_type = /obj/item/shard/shrapnel/upp
	//roughly 90 or so damage with the additional shrapnel, around 130 in total with primary round

/datum/ammo/bullet/revolver/nagant/shrapnel/on_hit_mob(mob/hit, obj/item/projectile/proj)
	pushback(hit, proj, 1)

/datum/ammo/bullet/revolver/upp/shrapnel_bits
	name = "small shrapnel"
	icon_state = "shrapnelshot_bit"
	hud_state = "revolver_shrapnel"

	max_range = 6
	damage = 30
	penetration = ARMOR_PENETRATION_TIER_4
	scatter = SCATTER_AMOUNT_TIER_1
	bonus_projectiles_amount = 0
	shrapnel_type = /obj/item/shard/shrapnel/upp/bits

/datum/ammo/bullet/revolver/small
	name = "small revolver bullet"
	hud_state = "revolver"
	headshot_state	= HEADSHOT_OVERLAY_LIGHT

	damage = 45

	penetration = ARMOR_PENETRATION_TIER_3

/datum/ammo/bullet/revolver/small/hollowpoint
	name = "small hollowpoint revolver bullet"
	headshot_state = HEADSHOT_OVERLAY_MEDIUM

	damage = 75 // way too strong because it's hard to make a good balance between HP and normal with this system, but the damage falloff is really strong
	penetration = 0
	damage_falloff = DAMAGE_FALLOFF_TIER_6

/datum/ammo/bullet/revolver/mateba
	name = ".454 heavy revolver bullet"
	hud_state = "revolver_heavy"

	damage = 60
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/revolver/mateba/highimpact
	name = ".454 heavy high-impact revolver bullet"
	hud_state = "revolver_highimpact"
	debilitate = list(0,2,0,0,0,1,0,0)
	penetration = ARMOR_PENETRATION_TIER_1
	flags_ammo_behavior = AMMO_BALLISTIC

/datum/ammo/bullet/revolver/mateba/highimpact/ap
	name = ".454 heavy high-impact armor piercing revolver bullet"
	penetration = ARMOR_PENETRATION_TIER_10
	damage = 45

	damage_armor_punch = 1.5

/datum/ammo/bullet/revolver/mateba/highimpact/New()
	..()
	RegisterSignal(src, COMSIG_AMMO_POINT_BLANK, PROC_REF(handle_battlefield_execution))

/datum/ammo/bullet/revolver/mateba/highimpact/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 4)

/datum/ammo/bullet/revolver/mateba/highimpact/explosive //if you ever put this in normal gameplay, i am going to scream
	name = ".454 heavy explosive revolver bullet"
	hud_state = "revolver_explosive"
	damage = 100
	damage_var_low = PROJECTILE_VARIANCE_TIER_10
	damage_var_high = PROJECTILE_VARIANCE_TIER_1
	penetration = ARMOR_PENETRATION_TIER_10
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_BALLISTIC

/datum/ammo/bullet/revolver/mateba/highimpact/explosive/on_hit_mob(mob/hit, obj/item/projectile/proj)
	..()
	cell_explosion(get_turf(hit), 120, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/revolver/mateba/highimpact/explosive/on_hit_obj(obj/O, obj/item/projectile/proj)
	..()
	cell_explosion(get_turf(O), 120, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/revolver/mateba/highimpact/explosive/on_hit_turf(turf/T, obj/item/projectile/proj)
	..()
	cell_explosion(T, 120, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/revolver/webley //Mateba round without the knockdown.
	name = ".455 Webley bullet"
	damage = 60
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_2

/*
//======
					SMG Ammo
//======
*/
//2020 SMG/ammo rebalance. default ammo actually has penetration so it can be useful, by 4khan: should be meh against t3s, better under 15 armor. Perfectly does this right now (oct 2020)
//has reduced falloff compared to the m39. this means it is best for kiting castes (mostly t2s and below admittedly)
//while the m39 ap is better for shredding them at close range, but has reduced velocity, so it's better for just running in and erasing armor-centric castes (defender, crusher)
// which i think is really interesting and good balance, giving both ammo types a reason to exist even against ravagers.
//i feel it is necessary to reflavor the default bullet, because otherwise, people won't be able to notice it has less falloff and faster bullet speed. even with a changelog,
//way too many people don't read the changelog, and after one or two months the changelog entry is all but archive, so there needs to be an ingame description of what the ammo does
//in comparison to armor-piercing rounds.

/datum/ammo/bullet/smg
	name = "submachinegun bullet"
	hud_state = "smg"
	hud_state_empty = "smg_empty"
	damage = 40
	accurate_range = 4
	effective_range_max = 4
	penetration = ARMOR_PENETRATION_TIER_1
	shell_speed = AMMO_SPEED_TIER_6
	damage_falloff = DAMAGE_FALLOFF_TIER_3
	scatter = SCATTER_AMOUNT_TIER_6
	accuracy = HIT_ACCURACY_TIER_3

/datum/ammo/bullet/smg/m39
	name = "high-velocity submachinegun bullet" //i don't want all smgs to inherit 'high velocity'
	hud_state = "smg_hv"

/datum/ammo/bullet/smg/ap
	name = "armor-piercing submachinegun bullet"
	hud_state = "smg_ap"

	damage = 24
	penetration = ARMOR_PENETRATION_TIER_6
	shell_speed = AMMO_SPEED_TIER_4

	pen_armor_punch = 0.75

/datum/ammo/bullet/smg/heap
	name = "high-explosive armor-piercing submachinegun bullet"

	damage = 45
	headshot_state = HEADSHOT_OVERLAY_MEDIUM
	penetration = ARMOR_PENETRATION_TIER_6
	shell_speed = AMMO_SPEED_TIER_4

/datum/ammo/bullet/smg/ap/toxin
	name = "toxic submachinegun bullet"
	hud_state = "smg_tox"
	var/acid_per_hit = 5
	var/organic_damage_mult = 3

/datum/ammo/bullet/smg/ap/toxin/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/toxic_buildup, acid_per_hit)

/datum/ammo/bullet/smg/ap/toxin/on_hit_turf(turf/T, obj/item/projectile/proj)
	. = ..()
	if(T.turf_flags & TURF_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/smg/ap/toxin/on_hit_obj(obj/O, obj/item/projectile/proj)
	. = ..()
	if(O.flags_obj & OBJ_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/smg/nail
	name = "7x45mm plasteel nail"
	icon_state = "nail-projectile"
	hud_state = "nail"

	damage = 25
	penetration = ARMOR_PENETRATION_TIER_5
	damage_falloff = DAMAGE_FALLOFF_TIER_6
	accurate_range = 5
	shell_speed = AMMO_SPEED_TIER_4


/datum/ammo/bullet/smg/nail/on_pointblank(mob/living/living, obj/item/projectile/proj, mob/living/user, obj/item/weapon/gun/fired_from)
	if(!living || living == proj.firer || living.lying)
		return

	if(iscarbonsizexeno(living))
		var/mob/living/carbon/xenomorph/X = living
		if(X.tier != 1) // 0 is queen!
			return
	else if(HAS_TRAIT(living, TRAIT_SUPER_STRONG))
		return

	if(living.frozen)
		to_chat(user, SPAN_DANGER("[living] struggles and avoids being nailed further!"))
		return

	//Check for presence of solid surface behind
	var/atom/movable/thick_surface = LinkBlocked(living, get_turf(living), get_step(living, get_dir(user, living)))
	if(!thick_surface || ismob(thick_surface) && !thick_surface.anchored)
		return

	living.frozen = TRUE
	user.visible_message(SPAN_DANGER("[user] punches [living] with the nailgun and nails their limb to [thick_surface]!"),
		SPAN_DANGER("You punch [living] with the nailgun and nail their limb to [thick_surface]!"))
	living.update_canmove()
	addtimer(CALLBACK(living, TYPE_PROC_REF(/mob, unfreeze)), 3 SECONDS)

/datum/ammo/bullet/smg/nail/on_hit_mob(mob/living/living, obj/item/projectile/proj)
	if(!living || living == proj.firer || living.lying)
		return

	living.adjust_effect(1, SLOW) //Slow on hit.
	living.recalculate_move_delay = TRUE
	var/super_slowdown_duration = 3
	//If there's an obstacle on the far side, superslow and do extra damage.
	if(iscarbonsizexeno(living)) //Unless they're a strong xeno, in which case the slowdown is drastically reduced
		var/mob/living/carbon/xenomorph/X = living
		if(X.tier != 1) // 0 is queen!
			super_slowdown_duration = 0.5
	else if(HAS_TRAIT(living, TRAIT_SUPER_STRONG))
		super_slowdown_duration = 0.5

	var/atom/movable/thick_surface = LinkBlocked(living, get_turf(living), get_step(living, get_dir(proj.loc ? proj : proj.firer, living)))
	if(!thick_surface || ismob(thick_surface) && !thick_surface.anchored)
		return

	living.apply_armoured_damage(damage*0.5, ARMOR_BULLET, BRUTE, null, penetration)
	living.adjust_effect(super_slowdown_duration, SUPERSLOW)

/datum/ammo/bullet/smg/incendiary
	name = "incendiary submachinegun bullet"
	hud_state = "smg_fire"
	damage_type = BURN
	shrapnel_chance = 0
	flags_ammo_behavior = AMMO_BALLISTIC

	bullet_color = COLOR_TAN_ORANGE

	damage = 25
	accuracy = HIT_ACCURACY_TIER_0

/datum/ammo/bullet/smg/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/smg/ap/penetrating
	name = "wall-penetrating submachinegun bullet"
	hud_state = "smg_wp"
	shrapnel_chance = 0

	damage = 30
	penetration = ARMOR_PENETRATION_TIER_10

	damage_armor_punch = 0.75

/datum/ammo/bullet/smg/ap/penetrating/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/smg/ap/cluster
	name = "cluster submachinegun bullet"
	hud_state = "smg_cluster_ap"
	shrapnel_chance = 0
	damage = 30
	penetration = ARMOR_PENETRATION_TIER_10
	var/cluster_addon = 0.8

/datum/ammo/bullet/smg/ap/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/smg/le
	name = "armor-shredding submachinegun bullet"
	hud_state = "smg_le"

	scatter = SCATTER_AMOUNT_TIER_10
	damage = 20
	penetration = ARMOR_PENETRATION_TIER_4
	shell_speed = AMMO_SPEED_TIER_3
	damage_falloff = DAMAGE_FALLOFF_TIER_10
	pen_armor_punch = 4

/datum/ammo/bullet/smg/rubber
	name = "rubber submachinegun bullet"
	sound_override = 'sound/weapons/gun_c99.ogg'
	hud_state = "smg_light"

	damage = 0
	stamina_damage = 10
	shrapnel_chance = 0

/datum/ammo/bullet/smg/mp27
	name = "simple submachinegun bullet"
	damage = 40
	accurate_range = 5
	effective_range_max = 7
	penetration = 0
	shell_speed = AMMO_SPEED_TIER_6
	damage_falloff = DAMAGE_FALLOFF_TIER_6
	scatter = SCATTER_AMOUNT_TIER_6
	accuracy = HIT_ACCURACY_TIER_2

// less damage than the m39, but better falloff, range, and AP

/datum/ammo/bullet/smg/ppsh
	name = "crude submachinegun bullet"
	damage = 26
	accurate_range = 7
	effective_range_max = 7
	penetration = ARMOR_PENETRATION_TIER_2
	damage_falloff = DAMAGE_FALLOFF_TIER_7
	scatter = SCATTER_AMOUNT_TIER_5

/datum/ammo/bullet/smg/pps43
	name = "simple submachinegun bullet"
	damage = 35
	accurate_range = 7
	effective_range_max = 10
	penetration = ARMOR_PENETRATION_TIER_4
	damage_falloff = DAMAGE_FALLOFF_TIER_6
	scatter = SCATTER_AMOUNT_TIER_6

/*
//======
					Rifle Ammo
//======
*/

/datum/ammo/bullet/rifle
	name = "rifle bullet"
	hud_state = "rifle"
	hud_state_empty = "rifle_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM

	damage = 40
	penetration = ARMOR_PENETRATION_TIER_1
	accurate_range = 16
	accuracy = HIT_ACCURACY_TIER_4
	scatter = SCATTER_AMOUNT_TIER_10
	shell_speed = AMMO_SPEED_TIER_6
	effective_range_max = 7
	damage_falloff = DAMAGE_FALLOFF_TIER_7
	max_range = 24 //So S8 users don't have their bullets magically disappaer at 22 tiles (S8 can see 24 tiles)

	pen_armor_punch = 0.5
	damage_armor_punch = 0.5

/datum/ammo/bullet/rifle/holo_target
	name = "holo-targeting rifle bullet"
	damage = 30
	var/holo_stacks = 10

/datum/ammo/bullet/rifle/holo_target/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/bonus_damage_stack, holo_stacks, world.time)

/datum/ammo/bullet/rifle/holo_target/hunting
	name = "holo-targeting hunting bullet"
	damage = 25
	holo_stacks = 15

/datum/ammo/bullet/rifle/explosive
	name = "explosive rifle bullet"
	hud_state = "rifle_ex"

	damage = 25
	accurate_range = 22
	accuracy = HIT_ACCURACY_TIER_1
	shell_speed = AMMO_SPEED_TIER_4
	damage_falloff = DAMAGE_FALLOFF_TIER_9

/datum/ammo/bullet/rifle/explosive/on_hit_mob(mob/hit, obj/item/projectile/proj)
	cell_explosion(get_turf(hit), 80, 40, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/rifle/explosive/on_hit_obj(obj/O, obj/item/projectile/proj)
	cell_explosion(get_turf(O), 80, 40, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/rifle/explosive/on_hit_turf(turf/T, obj/item/projectile/proj)
	if(T.density)
		cell_explosion(T, 80, 40, EXPLOSION_FALLOFF_SHAPE_LINEAR, proj.dir, proj.weapon_cause_data)

/datum/ammo/bullet/rifle/ap
	name = "armor-piercing rifle bullet"
	hud_state = "rifle_ap"

	damage = 30
	penetration = ARMOR_PENETRATION_TIER_8

	pen_armor_punch = 1
	damage_armor_punch = 0.75

// Basically AP but better. Focused at taking out armour temporarily
/datum/ammo/bullet/rifle/ap/toxin
	name = "toxic rifle bullet"
	hud_state = "rifle_tox"
	var/acid_per_hit = 7
	var/organic_damage_mult = 3

/datum/ammo/bullet/rifle/ap/toxin/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/toxic_buildup, acid_per_hit)

/datum/ammo/bullet/rifle/ap/toxin/on_hit_turf(turf/T, obj/item/projectile/proj)
	. = ..()
	if(T.turf_flags & TURF_ORGANIC)
		proj.damage *= organic_damage_mult

/datum/ammo/bullet/rifle/ap/toxin/on_hit_obj(obj/O, obj/item/projectile/proj)
	. = ..()
	if(O.flags_obj & OBJ_ORGANIC)
		proj.damage *= organic_damage_mult


/datum/ammo/bullet/rifle/ap/penetrating
	name = "wall-penetrating rifle bullet"
	hud_state = "rifle_wp"
	shrapnel_chance = 0

	damage = 35
	penetration = ARMOR_PENETRATION_TIER_10

	pen_armor_punch = 1.25
	damage_armor_punch = 1

/datum/ammo/bullet/rifle/ap/penetrating/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/rifle/ap/cluster
	name = "cluster rifle bullet"
	hud_state = "rifle_cluster"
	shrapnel_chance = 0

	damage = 35
	penetration = ARMOR_PENETRATION_TIER_10
	var/cluster_addon = 1

/datum/ammo/bullet/rifle/ap/cluster/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/cluster_stack, cluster_addon, damage, world.time)

/datum/ammo/bullet/rifle/le
	name = "armor-shredding rifle bullet"
	hud_state = "rifle_le"

	damage = 20
	penetration = ARMOR_PENETRATION_TIER_4
	pen_armor_punch = 5

/datum/ammo/bullet/rifle/heap
	name = "high-explosive armor-piercing rifle bullet"

	headshot_state = HEADSHOT_OVERLAY_HEAVY
	damage = 55//big damage, doesn't actually blow up because thats stupid.
	penetration = ARMOR_PENETRATION_TIER_8

/datum/ammo/bullet/rifle/rubber
	name = "rubber rifle bullet"
	sound_override = 'sound/weapons/gun_c99.ogg'
	hud_state = "rifle_light"

	damage = 0
	stamina_damage = 15
	shrapnel_chance = 0

/datum/ammo/bullet/rifle/incendiary
	name = "incendiary rifle bullet"
	hud_state = "rifle_fire"
	damage_type = BURN
	shrapnel_chance = 0
	flags_ammo_behavior = AMMO_BALLISTIC

	bullet_color = COLOR_TAN_ORANGE

	damage = 30
	shell_speed = AMMO_SPEED_TIER_4
	accuracy = HIT_ACCURACY_TIER_1
	damage_falloff = DAMAGE_FALLOFF_TIER_10

/datum/ammo/bullet/rifle/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/rifle/m4ra
	name = "A19 high velocity bullet"
	hud_state = "hivelo"
	hud_state_empty = "hivelo_empty"
	shrapnel_chance = 0
	damage_falloff = 0
	flags_ammo_behavior = AMMO_BALLISTIC
	accurate_range_min = 4

	damage = 55
	scatter = -SCATTER_AMOUNT_TIER_8
	penetration= ARMOR_PENETRATION_TIER_7
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/rifle/m4ra/incendiary
	name = "A19 high velocity incendiary bullet"
	hud_state = "hivelo_fire"
	flags_ammo_behavior = AMMO_BALLISTIC

	bullet_color = COLOR_TAN_ORANGE

	damage = 40
	accuracy = HIT_ACCURACY_TIER_4
	scatter = -SCATTER_AMOUNT_TIER_8
	penetration= ARMOR_PENETRATION_TIER_5
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/rifle/m4ra/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/rifle/m4ra/impact
	name = "A19 high velocity impact bullet"
	hud_state = "hivelo_impact"
	flags_ammo_behavior = AMMO_BALLISTIC

	damage = 40
	accuracy = HIT_ACCURACY_TIER_1
	scatter = -SCATTER_AMOUNT_TIER_8
	penetration = ARMOR_PENETRATION_TIER_10
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/rifle/m4ra/impact/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 32) // Can knockback basically at max range

/datum/ammo/bullet/rifle/m4ra/impact/knockback_effects(mob/living/living_mob, obj/item/projectile/fired_projectile)
	if(iscarbonsizexeno(living_mob))
		var/mob/living/carbon/xenomorph/target = living_mob
		to_chat(target, SPAN_XENODANGER("You are shaken and slowed by the sudden impact!"))
		target.apply_effect(0.5, WEAKEN)
		target.apply_effect(2, SUPERSLOW)
		target.apply_effect(5, SLOW)
	else
		if(!isyautja(living_mob)) //Not predators.
			living_mob.apply_effect(1, SUPERSLOW)
			living_mob.apply_effect(2, SLOW)
			to_chat(living_mob, SPAN_HIGHDANGER("The impact knocks you off-balance!"))
		living_mob.apply_stamina_damage(fired_projectile.ammo.damage, fired_projectile.def_zone, ARMOR_BULLET)

/datum/ammo/bullet/rifle/mar40
	name = "heavy rifle bullet"
	hud_state = "rifle_heavy"

	damage = 55

/datum/ammo/bullet/rifle/type71
	name = "heavy rifle bullet"
	hud_state = "rifle_heavy"

	damage = 55
	penetration = ARMOR_PENETRATION_TIER_3

/datum/ammo/bullet/rifle/type71/ap
	name = "heavy armor-piercing rifle bullet"
	hud_state = "rifle_heavy_ap"

	damage = 40
	penetration = ARMOR_PENETRATION_TIER_10

	pen_armor_punch = 1
	damage_armor_punch = 0.75

/datum/ammo/bullet/rifle/type71/heap
	name = "heavy high-explosive armor-piercing rifle bullet"

	headshot_state = HEADSHOT_OVERLAY_HEAVY
	damage = 65
	penetration = ARMOR_PENETRATION_TIER_10

/*
//======
					Shotgun Ammo
//======
*/

/datum/ammo/bullet/shotgun
	headshot_state	= HEADSHOT_OVERLAY_HEAVY
	hud_state_empty = "shotgun_empty"

/datum/ammo/bullet/shotgun/slug
	name = "shotgun slug"
	handful_state = "slug_shell"
	hud_state = "shotgun_buckshot"

	accurate_range = 6
	max_range = 8
	damage = 70
	penetration = ARMOR_PENETRATION_TIER_4
	damage_armor_punch = 2
	handful_state = "slug_shell"

/datum/ammo/bullet/shotgun/slug/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 6)

/datum/ammo/bullet/shotgun/slug/knockback_effects(mob/living/living_mob, obj/item/projectile/fired_projectile)
	if(iscarbonsizexeno(living_mob))
		var/mob/living/carbon/xenomorph/target = living_mob
		to_chat(target, SPAN_XENODANGER("You are shaken and slowed by the sudden impact!"))
		target.apply_effect(0.5, WEAKEN)
		target.apply_effect(1, SUPERSLOW)
		target.apply_effect(3, SLOW)
	else
		if(!isyautja(living_mob)) //Not predators.
			living_mob.apply_effect(1, SUPERSLOW)
			living_mob.apply_effect(2, SLOW)
			to_chat(living_mob, SPAN_HIGHDANGER("The impact knocks you off-balance!"))
		living_mob.apply_stamina_damage(fired_projectile.ammo.damage, fired_projectile.def_zone, ARMOR_BULLET)

/datum/ammo/bullet/shotgun/beanbag
	name = "beanbag slug"
	headshot_state = HEADSHOT_OVERLAY_LIGHT //It's not meant to kill people... but if you put it in your mouth, it will.
	handful_state = "beanbag_slug"
	hud_state = "shotgun_beanbag"
	icon_state = "beanbag"
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_RESIST
	sound_override = 'sound/weapons/gun_shotgun_riot.ogg'

	max_range = 12
	shrapnel_chance = 0
	damage = 0
	stamina_damage = 45
	accuracy = HIT_ACCURACY_TIER_3
	shell_speed = AMMO_SPEED_TIER_3
	handful_state = "beanbag_slug"

/datum/ammo/bullet/shotgun/beanbag/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(!hit || hit == proj.firer) return
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		shake_camera(H, 2, 1)


/datum/ammo/bullet/shotgun/incendiary
	name = "incendiary slug"
	handful_state = "incendiary_slug"
	hud_state = "shotgun_fire_slug"
	damage_type = BURN
	flags_ammo_behavior = AMMO_BALLISTIC

	bullet_color = COLOR_TAN_ORANGE

	accuracy = HIT_ACCURACY_TIER_1
	max_range = 12
	damage = 55
	penetration= ARMOR_PENETRATION_TIER_1
	handful_state = "incendiary_slug"

/datum/ammo/bullet/shotgun/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/shotgun/incendiary/on_hit_mob(mob/hit,obj/item/projectile/proj)
	burst(get_turf(hit),proj,damage_type)
	knockback(hit, proj)

/datum/ammo/bullet/shotgun/incendiary/on_hit_obj(obj/O,obj/item/projectile/proj)
	burst(get_turf(proj),proj,damage_type)

/datum/ammo/bullet/shotgun/incendiary/on_hit_turf(turf/T,obj/item/projectile/proj)
	burst(T,proj,damage_type)


/datum/ammo/bullet/shotgun/flechette
	name = "flechette shell"
	icon_state = "flechette"
	handful_state = "flechette_shell"
	hud_state = "shotgun_flechette"
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/flechette_spread

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	max_range = 12
	damage = 30
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_7
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_3
	handful_state = "flechette_shell"
	multiple_handful_name = TRUE

/datum/ammo/bullet/shotgun/flechette_spread
	name = "additional flechette"
	icon_state = "flechette"

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	max_range = 12
	damage = 30
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_7
	scatter = SCATTER_AMOUNT_TIER_5

/datum/ammo/bullet/shotgun/buckshot
	name = "buckshot shell"
	icon_state = "buckshot"
	handful_state = "buckshot_shell"
	hud_state = "shotgun_buckshot"
	multiple_handful_name = TRUE
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/spread

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_5
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_5
	accurate_range = 4
	max_range = 4
	damage = 65
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_1
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_3
	shell_speed = AMMO_SPEED_TIER_2
	damage_armor_punch = 0
	pen_armor_punch = 0
	handful_state = "buckshot_shell"
	multiple_handful_name = TRUE

/datum/ammo/bullet/shotgun/buckshot/incendiary
	name = "incendiary buckshot shell"
	handful_state = "incen_buckshot"
	hud_state = "shotgun_fire_buck"
	handful_type = /obj/item/ammo_magazine/handful/shotgun/buckshot/incendiary
	bullet_color = COLOR_TAN_ORANGE

/datum/ammo/bullet/shotgun/buckshot/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/shotgun/buckshot/on_hit_mob(mob/hit,obj/item/projectile/proj)
	knockback(hit, proj)

//buckshot variant only used by the masterkey shotgun attachment.
/datum/ammo/bullet/shotgun/buckshot/masterkey
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/spread/masterkey

	damage = 55

/datum/ammo/bullet/shotgun/spread
	name = "additional buckshot"
	icon_state = "buckshot"

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 4
	max_range = 6
	damage = 65
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_1
	shell_speed = AMMO_SPEED_TIER_2
	scatter = SCATTER_AMOUNT_TIER_1
	damage_armor_punch = 0
	pen_armor_punch = 0

/datum/ammo/bullet/shotgun/spread/masterkey
	damage = 20

/*
					8 GAUGE SHOTGUN AMMO
*/

/datum/ammo/bullet/shotgun/heavy/buckshot
	name = "heavy buckshot shell"
	icon_state = "buckshot"
	handful_state = "heavy_buckshot"
	hud_state = "shotgun_buckshot"
	multiple_handful_name = TRUE
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/heavy/buckshot/spread
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_3
	accurate_range = 3
	max_range = 3
	damage = 75
	penetration = 0
	shell_speed = AMMO_SPEED_TIER_2
	damage_armor_punch = 0
	pen_armor_punch = 0

/datum/ammo/bullet/shotgun/heavy/buckshot/on_hit_mob(mob/hit,obj/item/projectile/proj)
	knockback(hit, proj)

/datum/ammo/bullet/shotgun/heavy/buckshot/spread
	name = "additional heavy buckshot"
	max_range = 4
	scatter = SCATTER_AMOUNT_TIER_1
	bonus_projectiles_amount = 0

//basically the same
/datum/ammo/bullet/shotgun/heavy/buckshot/dragonsbreath
	name = "dragon's breath shell"
	handful_state = "heavy_dragonsbreath"
	hud_state = "shotgun_fire_buck"
	multiple_handful_name = TRUE
	bullet_color = COLOR_TAN_ORANGE
	damage_type = BURN
	damage = 60
	accurate_range = 3
	max_range = 4
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/heavy/buckshot/dragonsbreath/spread

/datum/ammo/bullet/shotgun/heavy/buckshot/dragonsbreath/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/shotgun/heavy/buckshot/dragonsbreath/spread
	name = "additional dragon's breath"
	bonus_projectiles_amount = 0
	accurate_range = 4
	max_range = 5 //make use of the ablaze property
	shell_speed = AMMO_SPEED_TIER_4 // so they hit before the main shell stuns


/datum/ammo/bullet/shotgun/heavy/slug
	name = "heavy shotgun slug"
	handful_state = "heavy_slug"
	hud_state = "shotgun_slug"

	accurate_range = 7
	max_range = 8
	damage = 90 //ouch.
	penetration = ARMOR_PENETRATION_TIER_6
	damage_armor_punch = 2

/datum/ammo/bullet/shotgun/heavy/slug/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 7)

/datum/ammo/bullet/shotgun/heavy/slug/knockback_effects(mob/living/living_mob, obj/item/projectile/fired_projectile)
	if(iscarbonsizexeno(living_mob))
		var/mob/living/carbon/xenomorph/target = living_mob
		to_chat(target, SPAN_XENODANGER("You are shaken and slowed by the sudden impact!"))
		target.apply_effect(0.5, WEAKEN)
		target.apply_effect(2, SUPERSLOW)
		target.apply_effect(5, SLOW)
	else
		if(!isyautja(living_mob)) //Not predators.
			living_mob.apply_effect(1, SUPERSLOW)
			living_mob.apply_effect(2, SLOW)
			to_chat(living_mob, SPAN_HIGHDANGER("The impact knocks you off-balance!"))
		living_mob.apply_stamina_damage(fired_projectile.ammo.damage, fired_projectile.def_zone, ARMOR_BULLET)

/datum/ammo/bullet/shotgun/heavy/beanbag
	name = "heavy beanbag slug"
	icon_state = "beanbag"
	headshot_state = HEADSHOT_OVERLAY_MEDIUM
	handful_state = "heavy_beanbag"
	hud_state = "shotgun_beanbag"
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_RESIST
	sound_override = 'sound/weapons/gun_shotgun_riot.ogg'

	max_range = 7
	shrapnel_chance = 0
	damage = 0
	stamina_damage = 100
	accuracy = HIT_ACCURACY_TIER_2
	shell_speed = AMMO_SPEED_TIER_2

/datum/ammo/bullet/shotgun/heavy/beanbag/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(!hit || hit == proj.firer)
		return
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		shake_camera(H, 2, 1)

/datum/ammo/bullet/shotgun/heavy/flechette
	name = "heavy flechette shell"
	icon_state = "flechette"
	handful_state = "heavy_flechette"
	hud_state = "shotgun_flechette"
	multiple_handful_name = TRUE
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/heavy/flechette_spread

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_3
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_3
	max_range = 12
	damage = 45
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_10
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_2

/datum/ammo/bullet/shotgun/heavy/flechette_spread
	name = "additional heavy flechette"
	icon_state = "flechette"
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	max_range = 12
	damage = 45
	damage_var_low = PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_10
	scatter = SCATTER_AMOUNT_TIER_4

//Enormous shell for Van Bandolier's superheavy double-barreled hunting gun.
/datum/ammo/bullet/shotgun/twobore
	name = "two bore bullet"
	icon_state = "autocannon"
	handful_state = "twobore"

	accurate_range = 8 //Big low-velocity projectile; this is for blasting dangerous game at close range.
	max_range = 14 //At this range, it's lost all its damage anyway.
	damage = 300 //Hits like a buckshot PB.
	penetration = ARMOR_PENETRATION_TIER_3
	damage_falloff = DAMAGE_FALLOFF_TIER_1 * 3 //It has a lot of energy, but the 26mm bullet drops off fast.
	effective_range_max = EFFECTIVE_RANGE_MAX_TIER_2 //Full damage up to this distance, then falloff for each tile beyond.
	var/hit_messages = list()

/datum/ammo/bullet/shotgun/twobore/on_hit_mob(mob/living/hit, obj/item/projectile/proj)
	var/mob/shooter = proj.firer
	if(shooter && ismob(shooter) && HAS_TRAIT(shooter, TRAIT_TWOBORE_TRAINING) && hit.stat != DEAD && prob(40)) //Death is handled by periodic life() checks so this should have a chance to fire on a killshot.
		if(!length(hit_messages)) //Pick and remove lines, refill on exhaustion.
			hit_messages = list("Got you!", "Aha!", "Bullseye!", "It's curtains for you, Sonny Jim!", "Your head will look fantastic on my wall!", "I have you now!", "You miserable coward! Come and fight me like a man!", "Tally ho!")
		var/message = pick_n_take(hit_messages)
		shooter.say(message)

	if(proj.distance_travelled > 8)
		knockback(hit, proj, 12)

	else if(!hit || hit == proj.firer || hit.lying) //These checks are included in knockback and would be redundant above.
		return

	shake_camera(hit, 3, 4)
	hit.apply_effect(2, WEAKEN)
	hit.apply_effect(4, SLOW)
	if(iscarbonsizexeno(hit))
		to_chat(hit, SPAN_XENODANGER("The impact knocks you off your feet!"))
	else //This will hammer a Yautja as hard as a human.
		to_chat(hit, SPAN_HIGHDANGER("The impact knocks you off your feet!"))

	step(hit, get_dir(proj.firer, hit))

/datum/ammo/bullet/shotgun/twobore/knockback_effects(mob/living/living_mob, obj/item/projectile/fired_projectile)
	if(iscarbonsizexeno(living_mob))
		var/mob/living/carbon/xenomorph/target = living_mob
		to_chat(target, SPAN_XENODANGER("You are shaken and slowed by the sudden impact!"))
		target.apply_effect(0.5, WEAKEN)
		target.apply_effect(2, SUPERSLOW)
		target.apply_effect(5, SLOW)
	else
		if(!isyautja(living_mob)) //Not predators.
			living_mob.apply_effect(1, SUPERSLOW)
			living_mob.apply_effect(2, SLOW)
			to_chat(living_mob, SPAN_HIGHDANGER("The impact knocks you off-balance!"))
		living_mob.apply_stamina_damage(fired_projectile.ammo.damage, fired_projectile.def_zone, ARMOR_BULLET)

/datum/ammo/bullet/lever_action
	name = "lever-action bullet"

	damage = 80
	penetration = 0
	accuracy = HIT_ACCURACY_TIER_1
	shell_speed = AMMO_SPEED_TIER_6
	accurate_range = 14
	handful_state = "lever_action_bullet"
	hud_state = "sniper"
	hud_state_empty = "sniper_empty"

//unused and not working. need to refactor MD code. Unobtainable.
//intended mechanic is to have xenos hit with it show up very frequently on any MDs around
/datum/ammo/bullet/lever_action/tracker
	name = "tracking lever-action bullet"
	icon_state = "redbullet"

	damage = 70
	penetration = ARMOR_PENETRATION_TIER_3
	accuracy = HIT_ACCURACY_TIER_1
	handful_state = "tracking_lever_action_bullet"

/datum/ammo/bullet/lever_action/tracker/on_hit_mob(mob/hit, obj/item/projectile/proj, mob/user)
	//SEND_SIGNAL(user, COMSIG_BULLET_TRACKING, user, hit)
	hit.visible_message(SPAN_DANGER("You hear a faint beep under [hit]'s [hit.mob_size > MOB_SIZE_HUMAN ? "chitin" : "skin"]."))

/datum/ammo/bullet/lever_action/training
	name = "lever-action blank"
	icon_state = "blank"

	damage = 70  //blanks CAN hurt you if shot very close
	penetration = 0
	accuracy = HIT_ACCURACY_TIER_1
	damage_falloff = DAMAGE_FALLOFF_BLANK //not much, though (comparatively)
	shell_speed = AMMO_SPEED_TIER_5
	handful_state = "training_lever_action_bullet"

//unused, and unobtainable... for now
/datum/ammo/bullet/lever_action/marksman
	name = "marksman lever-action bullet"

	shrapnel_chance = 0
	damage_falloff = 0
	accurate_range = 12
	damage = 70
	penetration = ARMOR_PENETRATION_TIER_6
	shell_speed = AMMO_SPEED_TIER_6
	handful_state = "marksman_lever_action_bullet"

/datum/ammo/bullet/lever_action/xm88
	name = ".458 SOCOM round"

	damage = 80
	penetration = ARMOR_PENETRATION_TIER_2
	accuracy = HIT_ACCURACY_TIER_1
	shell_speed = AMMO_SPEED_TIER_6
	accurate_range = 14
	handful_state = "boomslang_bullet"

/datum/ammo/bullet/lever_action/xm88/pen20
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/lever_action/xm88/pen30
	penetration = ARMOR_PENETRATION_TIER_6

/datum/ammo/bullet/lever_action/xm88/pen40
	penetration = ARMOR_PENETRATION_TIER_8

/datum/ammo/bullet/lever_action/xm88/pen50
	penetration = ARMOR_PENETRATION_TIER_10

/*
//======
					Sniper Ammo
//======
*/

/datum/ammo/bullet/sniper
	name = "sniper bullet"
	hud_state = "sniper"
	hud_state_empty = "sniper_empty"
	headshot_state	= HEADSHOT_OVERLAY_HEAVY
	damage_falloff = 0
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_COVER
	accurate_range_min = 4

	accuracy = HIT_ACCURACY_TIER_8
	accurate_range = 32
	max_range = 32
	ammo_range_fallof = BULLET_FALLOF_MULT_TIER_10
	scatter = 0
	damage = 70
	penetration= ARMOR_PENETRATION_TIER_10
	shell_speed = AMMO_SPEED_TIER_6
	damage_falloff = 0

	pen_armor_punch = 1.5
	damage_armor_punch = 1.5

/datum/ammo/bullet/sniper/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/living = hit
		living.apply_armoured_damage(damage*2, ARMOR_BULLET, BRUTE, null, penetration)
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/datum/ammo/bullet/sniper/incendiary
	name = "incendiary sniper bullet"
	hud_state = "sniper_fire"
	shrapnel_chance = 0
	damage_type = BURN
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_COVER

	bullet_color = COLOR_TAN_ORANGE

	ammo_range_fallof = BULLET_FALLOF_MULT_TIER_10
	damage = 60
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/sniper/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/sniper/incendiary/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/living = hit
		var/blind_duration = 5
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_BIG)
				blind_duration = 2
		living.AdjustEyeBlur(blind_duration)
		living.adjust_fire_stacks(10)
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/datum/ammo/bullet/sniper/flak
	name = "flak sniper bullet"
	hud_state = "sniper_flak"
	damage_type = BRUTE
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_COVER

	accuracy = HIT_ACCURACY_TIER_8
	ammo_range_fallof = BULLET_FALLOF_MULT_TIER_10
	scatter = SCATTER_AMOUNT_TIER_8
	damage = 55
	damage_var_high = PROJECTILE_VARIANCE_TIER_8 //Documenting old code: This converts to a variance of 96-109% damage. -Kaga
	penetration = 0

/datum/ammo/bullet/sniper/flak/on_hit_mob(mob/hit,obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/slow_duration = 7
		var/mob/living/living = hit
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_BIG)
				slow_duration = 4
		hit.adjust_effect(slow_duration, SUPERSLOW)
		living.apply_armoured_damage(damage, ARMOR_BULLET, BRUTE, null, penetration)
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))
	else
		burst(get_turf(hit),proj,damage_type, 2 , 2)
		burst(get_turf(hit),proj,damage_type, 1 , 2 , 0)

/datum/ammo/bullet/sniper/flak/on_near_target(turf/T, obj/item/projectile/proj)
	burst(T,proj,damage_type, 2 , 2)
	burst(T,proj,damage_type, 1 , 2, 0)
	return 1

/datum/ammo/bullet/sniper/crude
	name = "crude sniper bullet"
	damage = 42
	penetration = ARMOR_PENETRATION_TIER_6

/datum/ammo/bullet/sniper/crude/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	pushback(hit, proj, 3)

/datum/ammo/bullet/sniper/upp
	name = "armor-piercing sniper bullet"
	damage = 80
	penetration = ARMOR_PENETRATION_TIER_10

/datum/ammo/bullet/sniper/anti_materiel
	name = "anti-materiel sniper bullet"

	shrapnel_chance = 0 // This isn't leaving any shrapnel.
	accuracy = HIT_ACCURACY_TIER_8
	damage = 125
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/sniper/anti_materiel/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/L = hit
		var/size_damage_mod = 0.8
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_XENO)
				size_damage_mod += 0.6
			if(target.mob_size >= MOB_SIZE_BIG)
				size_damage_mod += 0.6
		L.apply_armoured_damage(damage*size_damage_mod, ARMOR_BULLET, BRUTE, null, penetration)
		// 180% damage to all targets (225), 240% (300) against non-Runner xenos, and 300% against Big xenos (375). -Kaga
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/datum/ammo/bullet/sniper/anti_materiel/vulture
	damage = 400 // Fully intended to vaporize anything smaller than a mini cooper
	accurate_range_min = 10
	handful_state = "vulture_bullet"
	sound_hit = 'sound/bullets/bullet_vulture_impact.ogg'
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_COVER|AMMO_ANTISTRUCT

	ammo_range_fallof = BULLET_FALLOF_MULT_TIER_10

/datum/ammo/bullet/sniper/anti_materiel/vulture/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	knockback(hit, proj, 30)
	hit.apply_effect(3, SLOW)

/datum/ammo/bullet/sniper/anti_materiel/vulture/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating/heavy)
	))

/datum/ammo/bullet/sniper/elite
	name = "supersonic sniper bullet"

	shrapnel_chance = 0 // This isn't leaving any shrapnel.
	accuracy = HIT_ACCURACY_TIER_8
	damage = 150
	shell_speed = AMMO_SPEED_TIER_6 + AMMO_SPEED_TIER_2

/datum/ammo/bullet/sniper/elite/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/sniper/elite/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/L = hit
		var/size_damage_mod = 0.5
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_XENO)
				size_damage_mod += 0.5
			if(target.mob_size >= MOB_SIZE_BIG)
				size_damage_mod += 1
			L.apply_armoured_damage(damage*size_damage_mod, ARMOR_BULLET, BRUTE, null, penetration)
		else
			L.apply_armoured_damage(damage, ARMOR_BULLET, BRUTE, null, penetration)
		// 150% damage to runners (225), 300% against Big xenos (450), and 200% against all others (300). -Kaga
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/datum/ammo/bullet/tank/crowbar
	name = "105mm \"crowbar\""
	handful_state = "vulture_bullet"
	sound_hit = 'sound/bullets/bullet_vulture_impact.ogg'
	flags_ammo_behavior = AMMO_IGNORE_COVER|AMMO_ANTISTRUCT|AMMO_BALLISTIC|AMMO_NO_DEFLECT

	accuracy = HIT_ACCURACY_TIER_10
	accurate_range = 32
	max_range = 32
	damage = 400
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/tank/crowbar/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating/heavy)
	))

/datum/ammo/bullet/tank/crowbar/on_hit_mob(mob/hit, obj/item/projectile/proj)
	knockback(hit, proj, 30)
	hit.apply_effect(3, SLOW)
	cell_explosion(get_turf(hit), 100, 50, direction = proj.dir, explosion_cause_data = proj.weapon_cause_data, shrapnel = FALSE)
	create_shrapnel(get_turf(hit), rand(5, 40), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/metal, proj.weapon_cause_data, TRUE)
	if(istype(hit, /mob/living/carbon/xenomorph))
		create_shrapnel(get_turf(hit), rand(5, 40), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/light/xeno, proj.weapon_cause_data, TRUE)
	else
		create_shrapnel(get_turf(hit), rand(1, 10), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/light/human, proj.weapon_cause_data, TRUE)
		create_shrapnel(get_turf(hit), rand(2, 15), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/light/human/var1, proj.weapon_cause_data, TRUE)
		create_shrapnel(get_turf(hit), rand(2, 15), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/light/human/var2, proj.weapon_cause_data, TRUE)

/datum/ammo/bullet/tank/crowbar/on_hit_obj(obj/O, obj/item/projectile/proj)
	cell_explosion(get_turf(O), 100, 50, direction = proj.dir, explosion_cause_data = proj.weapon_cause_data, shrapnel = FALSE)
	create_shrapnel(get_turf(O), rand(10, 80), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/metal, proj.weapon_cause_data)

/datum/ammo/bullet/tank/crowbar/on_hit_turf(turf/T, obj/item/projectile/proj)
	cell_explosion(T, 100, 50, direction = proj.dir, explosion_cause_data = proj.weapon_cause_data, shrapnel = FALSE)
	create_shrapnel(T, rand(10, 80), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/metal, proj.weapon_cause_data)

/datum/ammo/bullet/tank/crowbar/do_at_max_range(turf/T, obj/item/projectile/proj)
	cell_explosion(T, 100, 50, direction = proj.dir, explosion_cause_data = proj.weapon_cause_data, shrapnel = FALSE)
	create_shrapnel(T, rand(10, 80), proj.dir_angle, 90, /datum/ammo/bullet/shrapnel/metal, proj.weapon_cause_data)

/datum/ammo/bullet/tank/flak
	name = "flak autocannon bullet"
	icon_state = "autocannon"
	damage_falloff = 0
	flags_ammo_behavior = AMMO_BALLISTIC
	accurate_range_min = 4

	accuracy = HIT_ACCURACY_TIER_8
	scatter = 0
	damage = 60
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_6
	accurate_range = 32
	max_range = 32
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/tank/flak/on_hit_mob(mob/hit,obj/item/projectile/proj)
	burst(get_turf(hit),proj,damage_type, 2 , 3)
	burst(get_turf(hit),proj,damage_type, 1 , 3 , 0)

/datum/ammo/bullet/tank/flak/on_near_target(turf/T, obj/item/projectile/proj)
	burst(T,proj,damage_type, 2 , 3)
	burst(T,proj,damage_type, 1 , 3, 0)
	return 1

/datum/ammo/bullet/tank/flak/on_hit_obj(obj/O,obj/item/projectile/proj)
	burst(get_turf(proj),proj,damage_type, 2 , 3)
	burst(get_turf(proj),proj,damage_type, 1 , 3 , 0)

/datum/ammo/bullet/tank/flak/on_hit_turf(turf/T,obj/item/projectile/proj)
	burst(T,proj,damage_type, 2 , 3)
	burst(T,proj,damage_type, 1 , 3 , 0)

/datum/ammo/bullet/tank/dualcannon
	name = "dualcannon bullet"
	icon_state = "autocannon"
	damage_falloff = 0
	flags_ammo_behavior = AMMO_BALLISTIC

	accuracy = HIT_ACCURACY_TIER_8
	scatter = 0
	damage = 50
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_3
	accurate_range = 10
	max_range = 12
	shell_speed = AMMO_SPEED_TIER_5

/datum/ammo/bullet/tank/dualcannon/on_hit_mob(mob/hit,obj/item/projectile/proj)
	for(var/mob/living/carbon/living in get_turf(hit))
		if(living.stat == CONSCIOUS && living.mob_size <= MOB_SIZE_XENO)
			shake_camera(living, 1, 1)

/datum/ammo/bullet/tank/dualcannon/on_near_target(turf/T, obj/item/projectile/proj)
	for(var/mob/living/carbon/living in T)
		if(living.stat == CONSCIOUS && living.mob_size <= MOB_SIZE_XENO)
			shake_camera(living, 1, 1)
	return 1

/datum/ammo/bullet/tank/dualcannon/on_hit_obj(obj/O,obj/item/projectile/proj)
	for(var/mob/living/carbon/living in get_turf(O))
		if(living.stat == CONSCIOUS && living.mob_size <= MOB_SIZE_XENO)
			shake_camera(living, 1, 1)

/datum/ammo/bullet/tank/dualcannon/on_hit_turf(turf/T,obj/item/projectile/proj)
	for(var/mob/living/carbon/living in T)
		if(living.stat == CONSCIOUS && living.mob_size <= MOB_SIZE_XENO)
			shake_camera(living, 1, 1)

/datum/ammo/bullet/sniper/svd
	name = "crude sniper bullet"
	hud_state = "sniper_heavy"

/datum/ammo/bullet/sniper/anti_materiel
	name = "anti-materiel sniper bullet"

	shrapnel_chance = 0 // This isn't leaving any shrapnel.
	accuracy = HIT_ACCURACY_TIER_8
	damage = 125
	shell_speed = AMMO_SPEED_TIER_6

/datum/ammo/bullet/sniper/anti_materiel/on_hit_mob(mob/hit,obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/living = hit
		var/size_damage_mod = 0.8
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_XENO)
				size_damage_mod += 0.6
			if(target.mob_size >= MOB_SIZE_BIG)
				size_damage_mod += 0.6
		living.apply_armoured_damage(damage*size_damage_mod, ARMOR_BULLET, BRUTE, null, penetration)
		// 180% damage to all targets (225), 240% (300) against non-Runner xenos, and 300% against Big xenos (375). -Kaga
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/datum/ammo/bullet/sniper/elite
	name = "supersonic sniper bullet"
	hud_state = "sniper_supersonic"

	shrapnel_chance = 0 // This isn't leaving any shrapnel.
	accuracy = HIT_ACCURACY_TIER_8
	damage = 150
	shell_speed = AMMO_SPEED_TIER_6 + AMMO_SPEED_TIER_2

/datum/ammo/bullet/sniper/elite/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_penetrating)
	))

/datum/ammo/bullet/sniper/elite/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if((proj.projectile_flags & PROJECTILE_BULLSEYE) && hit == proj.original_target)
		var/mob/living/living = hit
		var/size_damage_mod = 0.5
		if(isxeno(hit))
			var/mob/living/carbon/xenomorph/target = hit
			if(target.mob_size >= MOB_SIZE_XENO)
				size_damage_mod += 0.5
			if(target.mob_size >= MOB_SIZE_BIG)
				size_damage_mod += 1
			living.apply_armoured_damage(damage*size_damage_mod, ARMOR_BULLET, BRUTE, null, penetration)
		else
			living.apply_armoured_damage(damage, ARMOR_BULLET, BRUTE, null, penetration)
		// 150% damage to runners (225), 300% against Big xenos (450), and 200% against all others (300). -Kaga
		to_chat(proj.firer, SPAN_WARNING("Bullseye!"))

/*
//======
					Special Ammo
//======
*/

/datum/ammo/bullet/smartgun
	name = "smartgun bullet"
	icon_state = "redbullet"
	hud_state = "smartgun"
	hud_state_empty = "smartgun_empty"
	flags_ammo_behavior = AMMO_BALLISTIC

	max_range = 18
	accuracy = HIT_ACCURACY_TIER_4
	damage = 30
	penetration = 0

/datum/ammo/bullet/smartgun/armor_piercing
	name = "armor-piercing smartgun bullet"
	icon_state = "bullet"
	hud_state = "smartgun_ap"

	accurate_range = 18
	accuracy = HIT_ACCURACY_TIER_2
	damage = 20
	penetration = ARMOR_PENETRATION_TIER_8
	damage_armor_punch = 1

/datum/ammo/bullet/smartgun/dirty
	name = "irradiated smartgun bullet"
	hud_state = "smartgun_radioactive"
	debilitate = list(0,0,0,3,0,0,0,1)

	shrapnel_chance = SHRAPNEL_CHANCE_TIER_7
	accurate_range = 32
	accuracy = HIT_ACCURACY_TIER_3
	damage = 40
	penetration = 0

/datum/ammo/bullet/smartgun/dirty/armor_piercing
	name = "irradiated armor-piercing smartgun bullet"
	hud_state = "smartgun_radioactive_ap"
	debilitate = list(0,0,0,3,0,0,0,1)

	accurate_range = 22
	accuracy = HIT_ACCURACY_TIER_3
	damage = 30
	penetration = ARMOR_PENETRATION_TIER_7
	damage_armor_punch = 3

/datum/ammo/bullet/smartgun/holo_target //Royal marines smartgun bullet has only diff between regular ammo is this one does holostacks
	name = "holo-targeting smartgun bullet"
	damage = 30
///Stuff for the HRP holotargetting stacks
	var/holo_stacks = 15

/datum/ammo/bullet/smartgun/holo_target/on_hit_mob(mob/M, obj/item/projectile/proj)
	. = ..()
	M.AddComponent(/datum/component/bonus_damage_stack, holo_stacks, world.time)

/datum/ammo/bullet/smartgun/holo_target/ap
	name = "armor-piercing smartgun bullet"
	icon_state = "bullet"

	accurate_range = 12
	accuracy = HIT_ACCURACY_TIER_2
	damage = 20
	penetration = ARMOR_PENETRATION_TIER_8

	pen_armor_punch = 1
	damage_armor_punch = 1

/datum/ammo/bullet/smartgun/m56_fpw
	name = "\improper M56 FPW bullet"
	icon_state = "redbullet"
	flags_ammo_behavior = AMMO_BALLISTIC

	max_range = 9
	accuracy = HIT_ACCURACY_TIER_7
	damage = 35
	penetration = ARMOR_PENETRATION_TIER_1

/datum/ammo/bullet/turret
	name = "autocannon bullet"
	icon_state = "redbullet" //Red bullets to indicate friendly fire restriction
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_IGNORE_COVER

	accurate_range = 22
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_8
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_8
	max_range = 22
	damage = 30
	penetration = ARMOR_PENETRATION_TIER_7
	damage_armor_punch = 0
	pen_armor_punch = 0
	shell_speed = 2*AMMO_SPEED_TIER_6
	accuracy = HIT_ACCURACY_TIER_5

/datum/ammo/bullet/turret/dumb
	icon_state = "bullet"
	flags_ammo_behavior = AMMO_BALLISTIC

/datum/ammo/bullet/machinegun //Adding this for the MG Nests (~Art)
	name = "machinegun bullet"
	icon_state 	= "bullet" // Keeping it bog standard with the turret but allows it to be changed. Had to remove IFF so you have to watch out.
	hud_state = "minigun"
	hud_state_empty = "minigun_empty"

	accurate_range = 12
	damage = 35
	penetration= ARMOR_PENETRATION_TIER_10 //Bumped the penetration to serve a different role from sentries, MGs are a bit more offensive
	accuracy = HIT_ACCURACY_TIER_3

/datum/ammo/bullet/machinegun/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff)
	))

/datum/ammo/bullet/machinegun/auto // for M2C, automatic variant for M56D, stats for bullet should always be moderately overtuned to fulfill its ultra-offense + flank-push purpose
	name = "heavy machinegun bullet"

	accurate_range = 10
	damage =  50
	penetration = ARMOR_PENETRATION_TIER_6
	accuracy = HIT_ACCURACY_TIER_10
	shell_speed = AMMO_SPEED_TIER_2
	max_range = 15
	effective_range_max = 7
	damage_falloff = DAMAGE_FALLOFF_TIER_8

/datum/ammo/bullet/machinegun/auto/set_bullet_traits()
	return

/datum/ammo/bullet/minigun
	name = "minigun bullet"
	hud_state = "minigun"
	hud_state_empty = "minigun_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM

	accuracy = HIT_ACCURACY_TIER_0
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 12
	damage = 35
	penetration = ARMOR_PENETRATION_TIER_6

/datum/ammo/bullet/minigun/New()
	..()
	if(SSticker.mode && MODE_HAS_FLAG(MODE_HVH_BALANCE))
		damage = 15
	else if(SSticker.current_state < GAME_STATE_PLAYING)
		RegisterSignal(SSdcs, COMSIG_GLOB_MODE_PRESETUP, PROC_REF(setup_hvh_damage))

/datum/ammo/bullet/minigun/proc/setup_hvh_damage()
	if(MODE_HAS_FLAG(MODE_HVH_BALANCE))
		damage = 15

/datum/ammo/bullet/minigun/tank
	accuracy = HIT_ACCURACY_TIER_1
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_8
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_8
	accurate_range = 12

/datum/ammo/bullet/m60
	name = "M60 bullet"
	hud_state = "rifle_heavy"
	hud_state_empty = "rifle_empty"
	headshot_state	= HEADSHOT_OVERLAY_MEDIUM

	accuracy = HIT_ACCURACY_TIER_2
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_8
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 12
	damage = 45 //7.62x51 is scary
	penetration= ARMOR_PENETRATION_TIER_6
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

/datum/ammo/bullet/pkp
	name = "machinegun bullet"
	headshot_state = HEADSHOT_OVERLAY_MEDIUM

	accuracy = HIT_ACCURACY_TIER_1
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_8
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 14
	damage = 35
	penetration= ARMOR_PENETRATION_TIER_6
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2

/*
//======
					Rocket Ammo
//======
*/

/datum/ammo/rocket
	name = "high explosive rocket"
	icon_state = "missile"
	hud_state = "rocket_he"
	ping = null //no bounce off.
	sound_bounce = "rocket_bounce"
	damage_falloff = 0
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_ROCKET|AMMO_STRIKES_SURFACE
	var/datum/effect_system/smoke_spread/smoke

	bullet_color = LIGHT_COLOR_FIRE

	accuracy = HIT_ACCURACY_TIER_2
	accurate_range = 7
	max_range = 14
	damage = 15
	shell_speed = AMMO_SPEED_TIER_2

/datum/ammo/rocket/New()
	..()
	smoke = new()

/datum/ammo/rocket/Destroy()
	qdel(smoke)
	smoke = null
	. = ..()

/datum/ammo/rocket/on_hit_mob(mob/hit, obj/item/projectile/proj)
	cell_explosion(get_turf(hit), 150, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, get_turf(hit))
	if(ishuman_strict(hit)) // No yautya or synths. Makes humans gib on direct hit.
		hit.ex_act(350, proj.dir, proj.weapon_cause_data, 100)
	smoke.start()

/datum/ammo/rocket/on_hit_obj(obj/O, obj/item/projectile/proj)
	cell_explosion(get_turf(O), 150, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, get_turf(O))
	smoke.start()

/datum/ammo/rocket/on_hit_turf(turf/T, obj/item/projectile/proj)
	cell_explosion(T, 150, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, T)
	smoke.start()

/datum/ammo/rocket/do_at_max_range(turf/T, obj/item/projectile/proj)
	cell_explosion(get_turf(proj), 150, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, get_turf(proj))
	smoke.start()

/datum/ammo/rocket/ap
	name = "anti-armor rocket"
	hud_state = "rocket_ap"
	damage_falloff = 0
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_ROCKET

	accuracy = HIT_ACCURACY_TIER_8
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_9
	accurate_range = 6
	max_range = 12
	damage = 10
	penetration= ARMOR_PENETRATION_TIER_10

/datum/ammo/rocket/ap/on_hit_mob(mob/hit, obj/item/projectile/proj)
	var/turf/T = get_turf(hit)
	hit.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
	hit.apply_effect(2, WEAKEN)
	hit.apply_effect(2, PARALYZE)
	if(ishuman_strict(hit)) // No yautya or synths. Makes humans gib on direct hit.
		hit.ex_act(300, proj.dir, proj.weapon_cause_data, 100)
	cell_explosion(T, 100, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, T)
	smoke.start()

/datum/ammo/rocket/ap/on_hit_obj(obj/O, obj/item/projectile/proj)
	var/turf/T = get_turf(O)
	O.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
	cell_explosion(T, 100, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, T)
	smoke.start()

/datum/ammo/rocket/ap/on_hit_turf(turf/T, obj/item/projectile/proj)
	var/hit_something = 0
	for(var/mob/hit in T)
		hit.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
		hit.apply_effect(4, WEAKEN)
		hit.apply_effect(4, PARALYZE)
		hit_something = 1
		continue
	if(!hit_something)
		for(var/obj/O in T)
			if(O.density)
				O.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
				hit_something = 1
				continue
	if(!hit_something)
		T.ex_act(150, proj.dir, proj.weapon_cause_data, 200)

	cell_explosion(T, 100, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, T)
	smoke.start()

/datum/ammo/rocket/ap/do_at_max_range(turf/T, obj/item/projectile/proj)
	var/hit_something = 0
	for(var/mob/hit in T)
		hit.ex_act(250, proj.dir, proj.weapon_cause_data, 100)
		hit.apply_effect(2, WEAKEN)
		hit.apply_effect(2, PARALYZE)
		hit_something = 1
		continue
	if(!hit_something)
		for(var/obj/O in T)
			if(O.density)
				O.ex_act(250, proj.dir, proj.weapon_cause_data, 100)
				hit_something = 1
				continue
	if(!hit_something)
		T.ex_act(250, proj.dir, proj.weapon_cause_data)
	cell_explosion(T, 100, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	smoke.set_up(1, T)
	smoke.start()

/datum/ammo/rocket/ap/anti_tank
	name = "anti-tank rocket"
	damage = 100
	var/vehicle_slowdown_time = 5 SECONDS
	shrapnel_chance = 5
	shrapnel_type = /obj/item/large_shrapnel/at_rocket_dud

/datum/ammo/rocket/ap/anti_tank/on_hit_obj(obj/O, obj/item/projectile/proj)
	if(istype(O, /obj/vehicle/multitile))
		var/obj/vehicle/multitile/hit = O
		hit.next_move = world.time + vehicle_slowdown_time
		playsound(hit, 'sound/effects/meteorimpact.ogg', 35)
		hit.at_munition_interior_explosion_effect(cause_data = create_cause_data("Anti-Tank Rocket"))
		hit.interior_crash_effect()
		var/turf/T = get_turf(hit.loc)
		hit.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
		smoke.set_up(1, T)
		smoke.start()
		return
	return ..()


/datum/ammo/rocket/ltb
	name = "cannon round"
	icon_state = "ltb"
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_ROCKET|AMMO_STRIKES_SURFACE

	accuracy = HIT_ACCURACY_TIER_3
	accurate_range = 32
	max_range = 32
	damage = 25
	shell_speed = AMMO_SPEED_TIER_3

/datum/ammo/rocket/ltb/on_hit_mob(mob/hit, obj/item/projectile/proj)
	cell_explosion(get_turf(hit), 220, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	cell_explosion(get_turf(hit), 200, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/ltb/on_hit_obj(obj/O, obj/item/projectile/proj)
	cell_explosion(get_turf(O), 220, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	cell_explosion(get_turf(O), 200, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/ltb/on_hit_turf(turf/T, obj/item/projectile/proj)
	cell_explosion(T, 220, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	cell_explosion(T, 200, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/ltb/do_at_max_range(turf/T, obj/item/projectile/proj)
	cell_explosion(get_turf(proj), 220, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	cell_explosion(get_turf(proj), 200, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/wp
	name = "white phosphorous rocket"
	hud_state = "rocket_fire"
	flags_ammo_behavior = AMMO_ROCKET|AMMO_EXPLOSIVE|AMMO_STRIKES_SURFACE
	damage_type = BURN

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 8
	damage = 90
	max_range = 16

/datum/ammo/rocket/wp/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/rocket/wp/drop_flame(turf/T, datum/cause_data/cause_data)
	playsound(T, 'sound/weapons/gun_flamethrower3.ogg', 75, 1, 7)
	if(!istype(T)) return
	smoke.set_up(1, T)
	smoke.start()
	var/datum/reagent/napalm/blue/R = new()
	new /obj/flamer_fire(T, cause_data, R, 3)

	var/datum/effect_system/smoke_spread/phosphorus/landingSmoke = new /datum/effect_system/smoke_spread/phosphorus
	landingSmoke.set_up(3, 0, T, null, 6, cause_data)
	landingSmoke.start()
	landingSmoke = null

/datum/ammo/rocket/wp/on_hit_mob(mob/hit, obj/item/projectile/proj)
	drop_flame(get_turf(hit), proj.weapon_cause_data)

/datum/ammo/rocket/wp/on_hit_obj(obj/O, obj/item/projectile/proj)
	drop_flame(get_turf(O), proj.weapon_cause_data)

/datum/ammo/rocket/wp/on_hit_turf(turf/T, obj/item/projectile/proj)
	drop_flame(T, proj.weapon_cause_data)

/datum/ammo/rocket/wp/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_flame(get_turf(proj), proj.weapon_cause_data)

/datum/ammo/rocket/wp/upp
	name = "extreme-intensity incendiary rocket"
	flags_ammo_behavior = AMMO_ROCKET|AMMO_EXPLOSIVE|AMMO_STRIKES_SURFACE
	damage_type = BURN

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 8
	damage = 150
	max_range = 10

/datum/ammo/rocket/wp/upp/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/rocket/wp/upp/drop_flame(turf/T, datum/cause_data/cause_data)
	playsound(T, 'sound/weapons/gun_flamethrower3.ogg', 75, 1, 7)
	if(!istype(T)) return
	smoke.set_up(1, T)
	smoke.start()
	var/datum/reagent/napalm/upp/R = new()
	new /obj/flamer_fire(T, cause_data, R, 3)

/datum/ammo/rocket/wp/upp/on_hit_mob(mob/M, obj/item/projectile/proj)
	drop_flame(get_turf(M), proj.weapon_cause_data)

/datum/ammo/rocket/wp/upp/on_hit_obj(obj/O, obj/item/projectile/proj)
	drop_flame(get_turf(O), proj.weapon_cause_data)

/datum/ammo/rocket/wp/upp/on_hit_turf(turf/T, obj/item/projectile/proj)
	drop_flame(T, proj.weapon_cause_data)

/datum/ammo/rocket/wp/upp/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_flame(get_turf(proj), proj.weapon_cause_data)

/datum/ammo/rocket/wp/quad
	name = "thermobaric rocket"
	hud_state = "rocket_thermobaric"
	flags_ammo_behavior = AMMO_ROCKET|AMMO_STRIKES_SURFACE

	damage = 100
	max_range = 32
	shell_speed = AMMO_SPEED_TIER_3

/datum/ammo/rocket/wp/quad/on_hit_mob(mob/hit, obj/item/projectile/proj)
	drop_flame(get_turf(hit), proj.weapon_cause_data)
	cell_explosion(get_turf(hit), 500, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/wp/quad/on_hit_obj(obj/O, obj/item/projectile/proj)
	drop_flame(get_turf(O), proj.weapon_cause_data)
	cell_explosion(get_turf(O), 500, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/wp/quad/on_hit_turf(turf/T, obj/item/projectile/proj)
	drop_flame(T, proj.weapon_cause_data)
	cell_explosion(T, 500, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/wp/quad/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_flame(get_turf(proj), proj.weapon_cause_data)
	cell_explosion(get_turf(proj), 500, 100, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/rocket/custom
	name = "custom rocket"

/datum/ammo/rocket/custom/proc/prime(atom/A, obj/item/projectile/proj)
	var/obj/item/weapon/gun/launcher/rocket/launcher = proj.shot_from
	var/obj/item/ammo_magazine/rocket/custom/rocket = launcher.current_mag
	if(rocket.locked && rocket.warhead && rocket.warhead.detonator)
		if(rocket.fuel && rocket.fuel.reagents.get_reagent_amount(rocket.fuel_type) >= rocket.fuel_requirement)
			rocket.forceMove(get_turf(proj))
		rocket.warhead.cause_data = proj.weapon_cause_data
		rocket.warhead.prime()
		qdel(rocket)
	smoke.set_up(1, get_turf(A))
	smoke.start()

/datum/ammo/rocket/custom/on_hit_mob(mob/hit, obj/item/projectile/proj)
	prime(hit, proj)

/datum/ammo/rocket/custom/on_hit_obj(obj/O, obj/item/projectile/proj)
	prime(O, proj)

/datum/ammo/rocket/custom/on_hit_turf(turf/T, obj/item/projectile/proj)
	prime(T, proj)

/datum/ammo/rocket/custom/do_at_max_range(turf/T, obj/item/projectile/proj)
	prime(null, proj)

/*
//======
					Energy Ammo
//======
*/

/datum/ammo/energy
	ping = null //no bounce off. We can have one later.
	sound_hit = "energy_hit"
	sound_miss = "energy_miss"
	sound_bounce = "energy_bounce"
	hud_state = "taser"
	hud_state_empty = "battery_empty"

	damage_type = BURN
	flags_ammo_behavior = AMMO_ENERGY

	accuracy = HIT_ACCURACY_TIER_4

/datum/ammo/energy/emitter //Damage is determined in emitter.dm
	name = "emitter bolt"
	icon_state = "emitter"
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_ARMOR

	accurate_range = 6
	max_range = 6

/datum/ammo/energy/taser
	name = "taser bolt"
	icon_state = "stun"
	damage_type = OXY
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_RESIST|AMMO_ALWAYS_FF //Not that ignoring will do much right now.

	bullet_color = COLOR_VIVID_YELLOW

	stamina_damage = 45
	accuracy = HIT_ACCURACY_TIER_8
	shell_speed = AMMO_SPEED_TIER_1 // Slightly faster
	hit_effect_color = "#FFFF00"

/datum/ammo/energy/taser/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		H.disable_special_items() // Disables scout cloak

/datum/ammo/energy/taser/precise
	name = "precise taser bolt"
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_RESIST|AMMO_MP

/datum/ammo/energy/rxfm_eva
	name = "laser blast"
	icon_state = "laser_new"
	flags_ammo_behavior = AMMO_LASER
	accurate_range = 14
	max_range = 22
	damage = 45
	stamina_damage = 25 //why not
	shell_speed = AMMO_SPEED_TIER_3

/datum/ammo/energy/rxfm_eva/on_hit_mob(mob/living/hit, obj/item/projectile/proj)
	..()
	if(prob(10)) //small chance for one to ignite on hit
		hit.fire_act()

/datum/ammo/energy/laz_uzi
	name = "laser bolt"
	icon_state = "laser_new"
	flags_ammo_behavior = AMMO_ENERGY
	damage = 40
	accurate_range = 5
	effective_range_max = 7
	max_range = 10
	shell_speed = AMMO_SPEED_TIER_4
	scatter = SCATTER_AMOUNT_TIER_6
	accuracy = HIT_ACCURACY_TIER_3
	damage_falloff = DAMAGE_FALLOFF_TIER_8

/datum/ammo/energy/yautja
	headshot_state = HEADSHOT_OVERLAY_MEDIUM
	accurate_range = 12
	shell_speed = AMMO_SPEED_TIER_3
	damage_type = BURN
	flags_ammo_behavior = AMMO_IGNORE_RESIST

/datum/ammo/energy/yautja/pistol
	name = "plasma pistol bolt"
	icon_state = "ion"

	bullet_color = COLOR_VIBRANT_LIME

	damage = 40
	shell_speed = AMMO_SPEED_TIER_2

/datum/ammo/energy/yautja/pistol/incendiary
	damage = 10

/datum/ammo/energy/yautja/pistol/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/shrapnel/plasma
	name = "plasma wave"
	shrapnel_chance = 0
	penetration = ARMOR_PENETRATION_TIER_10
	accuracy = HIT_ACCURACY_TIER_MAX
	damage = 15
	icon_state = "shrapnel_plasma"
	damage_type = BURN

/datum/ammo/bullet/shrapnel/plasma/on_hit_mob(mob/hit, obj/item/projectile/hit_projectile)
	hit.apply_effect(2, WEAKEN)

/datum/ammo/energy/yautja/caster
	name = "root caster bolt"
	icon_state = "ion"

/datum/ammo/energy/yautja/caster/stun
	name = "low power stun bolt"
	debilitate = list(2,2,0,0,0,1,0,0)

	damage = 0
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_RESIST

/datum/ammo/energy/yautja/caster/bolt
	name = "plasma bolt"
	icon_state = "pulse1"
	flags_ammo_behavior = AMMO_IGNORE_RESIST
	shell_speed = AMMO_SPEED_TIER_6
	damage = 35

/datum/ammo/energy/yautja/caster/bolt/stun
	name = "high power stun bolt"
	var/stun_time = 2

	damage = 0
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_RESIST

/datum/ammo/energy/yautja/caster/bolt/stun/on_hit_mob(mob/hit, obj/item/projectile/proj)
	var/mob/living/carbon/C = hit
	var/stun_time = src.stun_time
	if(istype(C))
		if(isyautja(C) || ispredalien(C))
			return
		to_chat(C, SPAN_DANGER("An electric shock ripples through your body, freezing you in place!"))
		log_attack("[key_name(C)] was stunned by a high power stun bolt from [key_name(proj.firer)] at [get_area(proj)]")

		if(ishuman(C))
			var/mob/living/carbon/human/H = C
			stun_time++
			H.apply_effect(stun_time, WEAKEN)
		else
			hit.apply_effect(stun_time, WEAKEN)

		C.apply_effect(stun_time, STUN)
	..()

/datum/ammo/energy/yautja/caster/sphere
	name = "plasma eradicator"
	icon_state = "bluespace"
	flags_ammo_behavior = AMMO_EXPLOSIVE|AMMO_HITS_TARGET_TURF
	shell_speed = AMMO_SPEED_TIER_4
	accuracy = HIT_ACCURACY_TIER_8

	damage = 55

	accurate_range = 8
	max_range = 8

	var/vehicle_slowdown_time = 5 SECONDS

/datum/ammo/energy/yautja/caster/sphere/on_hit_mob(mob/hit, obj/item/projectile/proj)
	cell_explosion(proj, 170, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/energy/yautja/caster/sphere/on_hit_turf(turf/T, obj/item/projectile/proj)
	cell_explosion(proj, 170, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/energy/yautja/caster/sphere/on_hit_obj(obj/O, obj/item/projectile/proj)
	if(istype(O, /obj/vehicle/multitile))
		var/obj/vehicle/multitile/multitile_vehicle = O
		multitile_vehicle.next_move = world.time + vehicle_slowdown_time
		playsound(multitile_vehicle, 'sound/effects/meteorimpact.ogg', 35)
		multitile_vehicle.at_munition_interior_explosion_effect(cause_data = create_cause_data("Plasma Eradicator", proj.firer))
		multitile_vehicle.interior_crash_effect()
		multitile_vehicle.ex_act(150, proj.dir, proj.weapon_cause_data, 100)
	cell_explosion(get_turf(proj), 170, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)

/datum/ammo/energy/yautja/caster/sphere/do_at_max_range(turf/T, obj/item/projectile/proj)
	cell_explosion(get_turf(proj), 170, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)


/datum/ammo/energy/yautja/caster/sphere/stun
	name = "plasma immobilizer"
	damage = 0
	flags_ammo_behavior = AMMO_ENERGY|AMMO_IGNORE_RESIST
	accurate_range = 20
	max_range = 20

	var/stun_range = 4 // Big
	var/stun_time = 6

/datum/ammo/energy/yautja/caster/sphere/stun/on_hit_mob(mob/hit, obj/item/projectile/proj)
	do_area_stun(proj)

/datum/ammo/energy/yautja/caster/sphere/stun/on_hit_turf(turf/T,obj/item/projectile/proj)
	do_area_stun(proj)

/datum/ammo/energy/yautja/caster/sphere/stun/on_hit_obj(obj/O,obj/item/projectile/proj)
	do_area_stun(proj)

/datum/ammo/energy/yautja/caster/sphere/stun/do_at_max_range(turf/T, obj/item/projectile/proj)
	do_area_stun(proj)

/datum/ammo/energy/yautja/caster/sphere/stun/proc/do_area_stun(obj/item/projectile/proj)
	playsound(proj, 'sound/weapons/wave.ogg', 75, 1, 25)
	for (var/mob/living/carbon/hit in view(src.stun_range, get_turf(proj)))
		var/stun_time = src.stun_time
		log_attack("[key_name(hit)] was stunned by a plasma immobilizer from [key_name(proj.firer)] at [get_area(proj)]")
		if(isyautja(hit))
			stun_time -= 2
		if(ispredalien(hit))
			continue
		to_chat(hit, SPAN_DANGER("A powerful electric shock ripples through your body, freezing you in place!"))
		hit.apply_effect(stun_time, STUN)

		if(ishuman(hit))
			var/mob/living/carbon/human/H = hit
			H.apply_effect(stun_time, WEAKEN)
		else
			hit.apply_effect(stun_time, WEAKEN)




/datum/ammo/energy/yautja/rifle/bolt
	name = "plasma rifle bolt"
	icon_state = "ion"
	damage_type = BURN
	debilitate = list(0,2,0,0,0,0,0,0)
	flags_ammo_behavior = AMMO_IGNORE_RESIST

	damage = 55
	penetration = ARMOR_PENETRATION_TIER_10

/datum/ammo/energy/yautja/rifle/blast
	name = "plasma shatterer"
	icon_state = "bluespace"
	damage_type = BURN

	shell_speed = AMMO_SPEED_TIER_4
	damage = 40

/datum/ammo/energy/yautja/rifle/blast/on_hit_mob(mob/hit, obj/item/projectile/proj)
	var/living = get_turf(hit)
	cell_explosion(living, 90, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	..()

/datum/ammo/energy/yautja/rifle/blast/on_hit_turf(turf/T, obj/item/projectile/proj)
	cell_explosion(T, 90, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	..()

/datum/ammo/energy/yautja/rifle/blast/on_hit_obj(obj/O, obj/item/projectile/proj)
	cell_explosion(get_turf(O), 100, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	..()

/datum/ammo/energy/yautja/rifle/blast/do_at_max_range(turf/T, obj/item/projectile/proj)
	cell_explosion(get_turf(proj), 100, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, proj.weapon_cause_data)
	..()


/*
//======
					Xeno Spits
//======
*/
/datum/ammo/xeno
	icon_state = "neurotoxin"
	ping = "ping_x"
	damage_type = TOX
	flags_ammo_behavior = AMMO_XENO

	///used to make cooldown of the different spits vary.
	var/added_spit_delay = 0
	var/spit_cost

	bullet_color = COLOR_LIME

	/// Should there be a windup for this spit?
	var/spit_windup = FALSE

	/// Should there be an additional warning while winding up? (do not put to true if there is not a windup)
	var/pre_spit_warn = FALSE

	accuracy = HIT_ACCURACY_TIER_MAX
	max_range = 12

/datum/ammo/xeno/toxin
	name = "neurotoxic spit"
	damage_falloff = 0
	flags_ammo_behavior = AMMO_XENO|AMMO_IGNORE_RESIST
	spit_cost = 25
	var/effect_power = XENO_NEURO_TIER_4
	var/datum/callback/neuro_callback

	shell_speed = AMMO_SPEED_TIER_3
	max_range = 7

/datum/ammo/xeno/toxin/New()
	..()

	neuro_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(apply_neuro))

/proc/apply_neuro(mob/hit, power, insta_neuro)
	if(skillcheck(hit, SKILL_ENDURANCE, SKILL_ENDURANCE_MAX) && !insta_neuro)
		hit.visible_message(SPAN_DANGER("[hit] withstands the neurotoxin!"))
		return //endurance 5 makes you immune to weak neurotoxin
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		if(H.chem_effect_flags & CHEM_EFFECT_RESIST_NEURO || H.species.species_flags & NO_NEURO)
			H.visible_message(SPAN_DANGER("[hit] shrugs off the neurotoxin!"))
			return //species like zombies or synths are immune to neurotoxin

	if(!isxeno(hit))
		if(insta_neuro)
			if(hit.knocked_down < 3)
				hit.adjust_effect(1 * power, WEAKEN)
			return

		if(ishuman(hit))
			hit.apply_effect(2.5, SUPERSLOW)
			hit.visible_message(SPAN_DANGER("[hit]'s movements are slowed."))

		var/no_clothes_neuro = FALSE

		if(ishuman(hit))
			var/mob/living/carbon/human/H = hit
			if(!H.wear_suit || H.wear_suit.slowdown == 0)
				no_clothes_neuro = TRUE

		if(no_clothes_neuro)
			if(hit.knocked_down < 5)
				hit.adjust_effect(1 * power, WEAKEN) // KD them a bit more
				hit.visible_message(SPAN_DANGER("[hit] falls prone."))

/proc/apply_scatter_neuro(mob/hit)
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		if(skillcheck(hit, SKILL_ENDURANCE, SKILL_ENDURANCE_MAX))
			hit.visible_message(SPAN_DANGER("[hit] withstands the neurotoxin!"))
			return //endurance 5 makes you immune to weak neuro
		if(H.chem_effect_flags & CHEM_EFFECT_RESIST_NEURO || H.species.species_flags & NO_NEURO)
			H.visible_message(SPAN_DANGER("[hit] shrugs off the neurotoxin!"))
			return

		if(hit.knocked_down < 0.7) // apply knockdown only if current knockdown is less than 0.7 second
			hit.apply_effect(0.7, WEAKEN)
			hit.visible_message(SPAN_DANGER("[hit] falls prone."))

/datum/ammo/xeno/toxin/on_hit_mob(mob/hit,obj/item/projectile/proj)
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		if(H.status_flags & XENO_HOST)
			neuro_callback.Invoke(H, effect_power, TRUE)
			return

	neuro_callback.Invoke(hit, effect_power, FALSE)

/datum/ammo/xeno/toxin/medium //Spitter
	name = "neurotoxic spatter"
	spit_cost = 50
	effect_power = 1

	shell_speed = AMMO_SPEED_TIER_5

/datum/ammo/xeno/toxin/queen
	name = "neurotoxic spit"
	spit_cost = 50
	effect_power = 2

	accuracy = HIT_ACCURACY_TIER_MAX
	max_range = 6 - 1

/datum/ammo/xeno/toxin/queen/on_hit_mob(mob/hit,obj/item/projectile/proj)
	neuro_callback.Invoke(hit, effect_power, TRUE)

/datum/ammo/xeno/toxin/shotgun
	name = "neurotoxic droplet"
	flags_ammo_behavior = AMMO_XENO|AMMO_IGNORE_RESIST
	bonus_projectiles_type = /datum/ammo/xeno/toxin/shotgun/additional

	accuracy_var_low = PROJECTILE_VARIANCE_TIER_6
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_6
	accurate_range = 5
	max_range = 5
	scatter = SCATTER_AMOUNT_NEURO
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_4

/datum/ammo/xeno/toxin/shotgun/New()
	..()

	neuro_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(apply_scatter_neuro))

/datum/ammo/xeno/toxin/shotgun/additional
	name = "additional neurotoxic droplets"

	bonus_projectiles_amount = 0

/*proc/neuro_flak(turf/T, obj/item/projectile/proj, datum/callback/CB, power, insta_neuro, radius)
	if(!T) return FALSE
	var/firer = proj.firer
	var/hit_someone = FALSE
	for(var/mob/living/carbon/hit in orange(radius,T))
		if(isxeno(hit) && isxeno(firer) && hit:faction == firer:faction)
			continue

		if(HAS_TRAIT(hit, TRAIT_NESTED))
			continue

		hit_someone = TRUE
		CB.Invoke(hit, power, insta_neuro)

		proj.play_hit_effect(hit)

	return hit_someone

/datum/ammo/xeno/toxin/burst //sentinel burst
	name = "neurotoxic air splash"
	effect_power = XENO_NEURO_TIER_1
	spit_cost = 50
	flags_ammo_behavior = AMMO_XENO|AMMO_IGNORE_RESIST

/datum/ammo/xeno/toxin/burst/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(isxeno(hit) && isxeno(proj.firer) && hit:faction == proj.firer:faction)
		neuro_callback.Invoke(hit, effect_power*1.5, TRUE)

	neuro_flak(get_turf(hit), proj, neuro_callback, effect_power, FALSE, 1)

/datum/ammo/xeno/toxin/burst/on_near_target(turf/T, obj/item/projectile/proj)
	return neuro_flak(T, proj, neuro_callback, effect_power, FALSE, 1)

/datum/ammo/xeno/sticky
	name = "sticky resin spit"
	icon_state = "sticky"
	ping = null
	flags_ammo_behavior = AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE
	added_spit_delay = 5
	spit_cost = 40

	shell_speed = AMMO_SPEED_TIER_3
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_4
	max_range = 32

/datum/ammo/xeno/sticky/on_hit_mob(mob/hit,obj/item/projectile/proj)
	drop_resin(get_turf(proj))

/datum/ammo/xeno/sticky/on_hit_obj(obj/O,obj/item/projectile/proj)
	drop_resin(get_turf(proj))

/datum/ammo/xeno/sticky/on_hit_turf(turf/T,obj/item/projectile/proj)
	drop_resin(T)

/datum/ammo/xeno/sticky/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_resin(get_turf(proj))

/datum/ammo/xeno/sticky/proc/drop_resin(turf/T)
	if(T.density)
		return

	for(var/obj/O in T.contents)
		if(istype(O, /obj/item/clothing/mask/facehugger))
			return
		if(istype(O, /obj/effect/alien/egg))
			return
		if(istype(O, /obj/structure/mineral_door) || istype(O, /obj/effect/alien/resin) || istype(O, /obj/structure/bed))
			return
		if(O.density && !(O.flags_atom & ON_BORDER))
			return

	new /obj/effect/alien/resin/sticky/thin(T, null, faction) */

/datum/ammo/xeno/acid
	name = "acid spit"
	icon_state = "xeno_acid"
	sound_hit  = "acid_hit"
	sound_bounce = "acid_bounce"
	damage_type = BURN
	spit_cost = 25
	flags_ammo_behavior = AMMO_ACIDIC|AMMO_XENO
	accuracy = HIT_ACCURACY_TIER_MAX
	damage = 20
	max_range = 8 // 7 will disappear on diagonals. i love shitcode
	penetration = ARMOR_PENETRATION_TIER_2
	shell_speed = AMMO_SPEED_TIER_3

/datum/ammo/xeno/acid/on_shield_block(mob/hit, obj/item/projectile/proj)
	burst(hit,proj,damage_type)

/datum/ammo/xeno/acid/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(iscarbon(hit))
		var/mob/living/carbon/C = hit
		if(C.status_flags & XENO_HOST && HAS_TRAIT(C, TRAIT_NESTED) || C.stat == DEAD)
			return FALSE
	..()

/datum/ammo/xeno/acid/spatter
	name = "acid spatter"

	damage = 30
	max_range = 6

/datum/ammo/xeno/acid/spatter/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	if(. == FALSE)
		return

	new /datum/effects/acid(hit, proj.firer)

/datum/ammo/xeno/acid/praetorian
	name = "acid splash"

	accuracy = HIT_ACCURACY_TIER_MAX
	max_range = 8
	damage = 30
	shell_speed = AMMO_SPEED_TIER_2
	added_spit_delay = 0

/datum/ammo/xeno/acid/dot
	name = "acid spit"

/datum/ammo/xeno/acid/prae_nade // Used by base prae's acid nade
	name = "acid scatter"

	flags_ammo_behavior = AMMO_STOPPED_BY_COVER
	accuracy = HIT_ACCURACY_TIER_7
	accurate_range = 32
	max_range = 4
	damage = 25
	shell_speed = AMMO_SPEED_TIER_1
	scatter = SCATTER_AMOUNT_TIER_6

	apply_delegate = FALSE

/datum/ammo/xeno/acid/prae_nade/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(!ishuman(hit))
		return

	var/mob/living/carbon/human/H = hit

	var/datum/effects/prae_acid_stacks/PAS = null
	for (var/datum/effects/prae_acid_stacks/prae_acid_stacks in H.effects_list)
		PAS = prae_acid_stacks
		break

	if(PAS == null)
		PAS = new /datum/effects/prae_acid_stacks(H)
		PAS.cause_data = proj.weapon_cause_data
	else
		PAS.increment_stack_count()

/*datum/ammo/xeno/prae_skillshot
	name = "blob of acid"
	icon_state = "boiler_gas2"
	ping = "ping_x"
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE|AMMO_IGNORE_RESIST

	accuracy = HIT_ACCURACY_TIER_8
	accurate_range = 32
	max_range = 8
	damage = 20
	damage_falloff = DAMAGE_FALLOFF_TIER_10
	shell_speed = AMMO_SPEED_TIER_1
	scatter = SCATTER_AMOUNT_TIER_10

/datum/ammo/xeno/prae_skillshot/on_hit_mob(mob/hit, obj/item/projectile/proj)
	acid_stacks_aoe(get_turf(proj))

/datum/ammo/xeno/prae_skillshot/on_hit_obj(obj/O, obj/item/projectile/proj)
	acid_stacks_aoe(get_turf(proj))

/datum/ammo/xeno/prae_skillshot/on_hit_turf(turf/T, obj/item/projectile/proj)
	acid_stacks_aoe(get_turf(proj))

/datum/ammo/xeno/prae_skillshot/do_at_max_range(turf/T, obj/item/projectile/proj)
	acid_stacks_aoe(get_turf(proj))

/datum/ammo/xeno/prae_skillshot/proc/acid_stacks_aoe(turf/T)

	if(!istype(T))
		return

	for (var/mob/living/carbon/human/H in orange(1, T))
		to_chat(H, SPAN_XENODANGER("You are spattered with acid!"))
		animation_flash_color(H)
		var/datum/effects/prae_acid_stacks/PAS = null
		for (var/datum/effects/prae_acid_stacks/prae_acid_stacks in H.effects_list)
			PAS = prae_acid_stacks
			break

		if(PAS == null)
			PAS = new /datum/effects/prae_acid_stacks(H)
			PAS.increment_stack_count()
		else
			PAS.increment_stack_count()
			PAS.increment_stack_count() */

/*
//======
					Xeno Boiler Gas
//======
*/
/datum/ammo/xeno/toxin/shatter // Used by boiler shatter glob strain
	name = "neurotoxin spatter"
	accuracy = HIT_ACCURACY_TIER_7
	accurate_range = 32
	max_range = 4
	damage = 10
	shell_speed = AMMO_SPEED_TIER_1
	scatter = SCATTER_AMOUNT_TIER_5

/datum/ammo/xeno/acid/shatter // Used by boiler shatter glob strain
	name = "acid spatter"
	accuracy = HIT_ACCURACY_TIER_7
	accurate_range = 32
	max_range = 4
	damage = 20
	shell_speed = AMMO_SPEED_TIER_1
	scatter = SCATTER_AMOUNT_TIER_5

/datum/ammo/xeno/boiler_gas
	name = "glob of neuro gas"
	icon_state = "neuro_glob"
	ping = "ping_x"
	debilitate = list(2,2,0,1,11,12,1,10) // Stun,knockdown,knockout,irradiate,stutter,eyeblur,drowsy,agony
	flags_ammo_behavior = AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE|AMMO_IGNORE_RESIST|AMMO_HITS_TARGET_TURF|AMMO_ACIDIC
	var/datum/effect_system/smoke_spread/smoke_system

	bullet_color = COLOR_VERY_PALE_LIME_GREEN

	spit_cost = 200
	pre_spit_warn = TRUE
	spit_windup = 5 SECONDS
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_4
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_4
	accuracy = HIT_ACCURACY_TIER_8
	scatter = SCATTER_AMOUNT_TIER_4
	shell_speed = 0.75
	max_range = 16
	/// range on the smoke in tiles from center
	var/smokerange = 4
	var/lifetime_mult = 1.0

/datum/ammo/xeno/boiler_gas/New()
	..()
	set_xeno_smoke()

/datum/ammo/xeno/boiler_gas/Destroy()
	qdel(smoke_system)
	smoke_system = null
	. = ..()

/datum/ammo/xeno/boiler_gas/on_hit_mob(mob/moob, obj/item/projectile/proj)
	if(iscarbon(moob))
		var/mob/living/carbon/carbon = moob
		if(carbon.status_flags & XENO_HOST && HAS_TRAIT(carbon, TRAIT_NESTED) || carbon.stat == DEAD)
			return
	var/datum/effects/neurotoxin/neuro_effect = locate() in moob.effects_list
	if(!neuro_effect)
		neuro_effect = new /datum/effects/neurotoxin(moob, proj.firer)
	neuro_effect.duration += 5
	moob.apply_effect(3, DAZE)
	to_chat(moob, SPAN_HIGHDANGER("Neurotoxic liquid spreads all over you and immediately soaks into your pores and orifices! Oh fuck!")) // Fucked up but have a chance to escape rather than being game-ended
	drop_nade(get_turf(proj), proj,TRUE)

/datum/ammo/xeno/boiler_gas/on_hit_obj(obj/outbacksteakhouse, obj/item/projectile/proj)
	drop_nade(get_turf(proj), proj)

/datum/ammo/xeno/boiler_gas/on_hit_turf(turf/Turf, obj/item/projectile/proj)
	if(Turf.density && isturf(proj.loc))
		drop_nade(proj.loc, proj) //we don't want the gas globs to land on dense turfs, they block smoke expansion.
	else
		drop_nade(Turf, proj)

/datum/ammo/xeno/boiler_gas/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_nade(get_turf(proj), proj)

/datum/ammo/xeno/boiler_gas/proc/set_xeno_smoke(obj/item/projectile/proj)
	smoke_system = new /datum/effect_system/smoke_spread/xeno_weaken()

/datum/ammo/xeno/boiler_gas/proc/drop_nade(turf/turf, obj/item/projectile/proj)
	var/lifetime_mult = 1.0
	var/datum/cause_data
	if(isboiler(proj.firer))
		cause_data = proj.weapon_cause_data
	smoke_system.set_up(smokerange, 0, turf, new_cause_data = cause_data)
	smoke_system.lifetime = 12 * lifetime_mult
	smoke_system.start()
	turf.visible_message(SPAN_DANGER("A glob of acid lands with a splat and explodes into noxious fumes!"))

/datum/ammo/xeno/boiler_gas/corrosive
	name = "glob of acid"
	icon_state = "boiler_gas"
	sound_hit = "acid_hit"
	sound_bounce = "acid_bounce"
	debilitate = list(1,1,0,0,1,1,0,0)
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE|AMMO_IGNORE_ARMOR
	damage = 50
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	damage_type = BURN

/datum/ammo/xeno/boiler_gas/corrosive/on_shield_block(mob/hit, obj/item/projectile/proj)
	burst(hit,proj,damage_type)

/datum/ammo/xeno/boiler_gas/corrosive/set_xeno_smoke(obj/item/projectile/proj)
	smoke_system = new /datum/effect_system/smoke_spread/xeno_acid()

/datum/ammo/xeno/boiler_gas/corrosive/drop_nade(turf/T, obj/item/projectile/proj)
	var/amount = 3
	var/lifetime_mult = 1.0
	if(isboiler(proj.firer))
		var/mob/living/carbon/xenomorph/boiler/B = proj.firer
		amount += B.gas_level
		lifetime_mult = B.gas_life_multiplier
	smoke_system.set_up(amount, 0, T)
	smoke_system.lifetime = 6 * lifetime_mult
	smoke_system.start()
	T.visible_message(SPAN_DANGER("A glob of acid lands with a splat and explodes into corrosive bile!"))

/datum/ammo/xeno/boiler_gas/acid
	name = "glob of acid gas"
	icon_state = "acid_glob"
	ping = "ping_x"
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_4
	smokerange = 3


/datum/ammo/xeno/boiler_gas/acid/set_xeno_smoke(obj/item/projectile/proj)
	smoke_system = new /datum/effect_system/smoke_spread/xeno_acid()

/datum/ammo/xeno/boiler_gas/acid/on_hit_mob(mob/moob, obj/item/projectile/proj)
	if(iscarbon(moob))
		var/mob/living/carbon/carbon = moob
		if(carbon.status_flags & XENO_HOST && HAS_TRAIT(carbon, TRAIT_NESTED) || carbon.stat == DEAD)
			return
	to_chat(moob,SPAN_HIGHDANGER("Acid covers your body! Oh fuck!"))
	playsound(moob,"acid_strike",75,1)
	INVOKE_ASYNC(moob, TYPE_PROC_REF(/mob, emote), "pain") // why do I need this bullshit
	new /datum/effects/acid(moob, proj.firer)
	drop_nade(get_turf(proj), proj,TRUE)

/datum/ammo/xeno/boiler_gas/shatter
	name = "glob of neurotoxin"
	icon_state = "boiler_shatter2"
	ping = "ping_x"
	sound_hit = "acid_hit"
	sound_bounce = "acid_bounce"
	debilitate = list(19,21,0,0,11,12,0,0)
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE|AMMO_IGNORE_RESIST
	shrapnel_type = /datum/ammo/xeno/toxin/shatter
	var/shrapnel_amount = 32

/datum/ammo/xeno/boiler_gas/shatter/drop_nade(turf/T, obj/item/projectile/proj)
	create_shrapnel(T, shrapnel_amount, , ,shrapnel_type)
	T.visible_message(SPAN_DANGER("A huge ball of neurotoxin splashes down, sending drops and splashes in every direction!"))
	playsound(T, 'sound/effects/squelch1.ogg', 25, 1)

/datum/ammo/xeno/boiler_gas/shatter/acid
	name = "glob of acid"
	icon_state = "boiler_shatter"
	ping = "ping_x"
	sound_hit = "acid_hit"
	sound_bounce = "acid_bounce"
	debilitate = list(1,1,0,0,1,1,0,0)
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_EXPLOSIVE|AMMO_IGNORE_RESIST
	shrapnel_type = /datum/ammo/xeno/acid/shatter
	shrapnel_amount = 32

/datum/ammo/xeno/boiler_gas/shatter/acid/drop_nade(turf/T, obj/item/projectile/proj)
	create_shrapnel(T, shrapnel_amount, , ,shrapnel_type)
	T.visible_message(SPAN_DANGER("A huge ball of acid splashes down, sending drops and splashes in every direction!"))
	playsound(T, 'sound/effects/squelch1.ogg', 25, 1)

/datum/ammo/xeno/railgun_glob
	name = "railgun glob of acid"
	icon_state = "boiler_railgun"
	ping = "ping_x_railgun"
	sound_hit = "acid_hit"
	sound_bounce = "acid_bounce"
	debilitate = list(1,1,0,0,1,1,0,0)
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_IGNORE_ARMOR|AMMO_ANTISTRUCT|AMMO_STOPPED_BY_COVER
	damage_type = BURN
	accuracy = HIT_ACCURACY_TIER_MAX
	accurate_range = 32
	max_range = 32
	damage = 50
	damage_var_high = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_6
	shell_speed = AMMO_SPEED_TIER_3
	scatter = SCATTER_AMOUNT_TIER_10

/datum/ammo/xeno/railgun_glob/on_hit_obj(obj/O, obj/item/projectile/proj)
	if(istype(O, /obj/structure/barricade))
		var/obj/structure/barricade/B = O
		B.health -= damage + rand(5)
		B.update_health(1)

/*
//======
					Xeno Bone Chips
//======
*/
/datum/ammo/xeno/bone_chips
	name = "bone chips"
	icon_state = "shrapnel_light"
	ping = null
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_STOPPED_BY_COVER|AMMO_IGNORE_ARMOR
	damage_type = BRUTE
	bonus_projectiles_type = /datum/ammo/xeno/bone_chips/spread

	damage = 5
	max_range = 5
	accuracy = HIT_ACCURACY_TIER_MAX
	accuracy_var_low = PROJECTILE_VARIANCE_TIER_7
	accuracy_var_high = PROJECTILE_VARIANCE_TIER_7
	bonus_projectiles_amount = EXTRA_PROJECTILES_TIER_7
	shrapnel_type = /obj/item/shard/shrapnel/bone_chips
	shrapnel_chance = 60

/datum/ammo/xeno/bone_chips/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(iscarbon(hit))
		var/mob/living/carbon/C = hit
		if((HAS_FLAG(C.status_flags, XENO_HOST) && HAS_TRAIT(C, TRAIT_NESTED)) || C.stat == DEAD)
			return
	if(ishuman_strict(hit) || isxeno(hit))
		playsound(hit, 'sound/effects/spike_hit.ogg', 25, 1, 1)
		if(hit.slowed < 8)
			hit.apply_effect(8, SLOW)

/datum/ammo/xeno/bone_chips/spread
	name = "small bone chips"

	scatter = 30 // We want a wild scatter angle
	max_range = 5
	bonus_projectiles_amount = 0

/datum/ammo/xeno/bone_chips/spread/short_range
	name = "small bone chips"

	max_range = 3 // Very short range

/datum/ammo/xeno/bone_chips/spread/runner_skillshot
	name = "bone chips"

	scatter = 0
	max_range = 5
	damage = 10
	shrapnel_chance = 0

/datum/ammo/xeno/bone_chips/spread/runner/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(iscarbon(hit))
		var/mob/living/carbon/C = hit
		if((HAS_FLAG(C.status_flags, XENO_HOST) && HAS_TRAIT(C, TRAIT_NESTED)) || C.stat == DEAD)
			return
	if(ishuman_strict(hit) || isxeno(hit))
		playsound(hit, 'sound/effects/spike_hit.ogg', 25, 1, 1)
		if(hit.slowed < 6)
			hit.apply_effect(6, SLOW)

/datum/ammo/xeno/oppressor_tail
	name = "tail hook"
	icon_state = "none"
	ping = null
	flags_ammo_behavior = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_STOPPED_BY_COVER|AMMO_IGNORE_ARMOR
	damage_type = BRUTE

	damage = XENO_DAMAGE_TIER_5
	max_range = 4
	accuracy = HIT_ACCURACY_TIER_MAX

/datum/ammo/xeno/oppressor_tail/on_bullet_generation(obj/item/projectile/generated_projectile, mob/bullet_generator)
	//The projectile has no icon, so the overlay shows up in FRONT of the proj, and the beam connects to it in the middle.
	var/image/hook_overlay = new(icon = 'icons/effects/beam.dmi', icon_state = "oppressor_tail_hook", layer = BELOW_MOB_LAYER)
	generated_projectile.overlays += hook_overlay

/datum/ammo/xeno/oppressor_tail/on_hit_mob(mob/target, obj/item/projectile/fired_proj)
	var/mob/living/carbon/xenomorph/xeno_firer = fired_proj.firer
	if(xeno_firer.can_not_harm(target))
		return

	shake_camera(target, 5, 0.1 SECONDS)
	var/obj/effect/beam/tail_beam = fired_proj.firer.beam(target, "oppressor_tail", 'icons/effects/beam.dmi', 0.5 SECONDS, 5)
	var/image/tail_image = image('icons/effects/status_effects.dmi', "hooked")
	target.overlays += tail_image

	new /datum/effects/xeno_slow(target, fired_proj.firer, ttl = 0.5 SECONDS)
	target.apply_effect(0.5, STUN)
	INVOKE_ASYNC(target, TYPE_PROC_REF(/atom/movable, throw_atom), fired_proj.firer, get_dist(fired_proj.firer, target)-1, SPEED_VERY_FAST)

	qdel(tail_beam)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/ammo/xeno/oppressor_tail, remove_tail_overlay), target, tail_image), 0.5 SECONDS) //needed so it can actually be seen as it gets deleted too quickly otherwise.

/datum/ammo/xeno/oppressor_tail/proc/remove_tail_overlay(mob/overlayed_mob, image/tail_image)
	overlayed_mob.overlays -= tail_image

/*
//======
					Shrapnel
//======
*/
/datum/ammo/bullet/shrapnel
	name = "shrapnel"
	icon_state = "buckshot"
	accurate_range_min = 5
	flags_ammo_behavior = AMMO_BALLISTIC|AMMO_STOPPED_BY_COVER

	accuracy = HIT_ACCURACY_TIER_3
	accurate_range = 32
	max_range = 8
	damage = 25
	damage_var_low = -PROJECTILE_VARIANCE_TIER_6
	damage_var_high = PROJECTILE_VARIANCE_TIER_6
	penetration = ARMOR_PENETRATION_TIER_4
	shell_speed = AMMO_SPEED_TIER_2
	shrapnel_chance = 5

/datum/ammo/bullet/shrapnel/on_hit_obj(obj/O, obj/item/projectile/proj)
	if(istype(O, /obj/structure/barricade))
		var/obj/structure/barricade/B = O
		B.health -= rand(2, 5)
		B.update_health(1)

/datum/ammo/bullet/shrapnel/rubber
	name = "rubber pellets"
	icon_state = "rubber_pellets"
	flags_ammo_behavior = AMMO_STOPPED_BY_COVER

	damage = 0
	stamina_damage = 25
	shrapnel_chance = 0


/datum/ammo/bullet/shrapnel/hornet_rounds
	name = ".22 hornet round"
	icon_state = "hornet_round"
	flags_ammo_behavior = AMMO_BALLISTIC
	damage = 20
	shrapnel_chance = 0
	shell_speed = AMMO_SPEED_TIER_3//she fast af boi
	penetration = ARMOR_PENETRATION_TIER_5

/datum/ammo/bullet/shrapnel/hornet_rounds/on_hit_mob(mob/hit, obj/item/projectile/proj)
	. = ..()
	hit.AddComponent(/datum/component/bonus_damage_stack, 10, world.time)

/datum/ammo/bullet/shrapnel/medium
	name = "big shrapnel"
	icon_state = "buckshot"
	accurate_range_min = 5
	accuracy = HIT_ACCURACY_TIER_3
	accurate_range = 32
	max_range = 12
	damage = 60
	damage_var_low = -PROJECTILE_VARIANCE_TIER_8
	damage_var_high = PROJECTILE_VARIANCE_TIER_8
	penetration = ARMOR_PENETRATION_TIER_8
	shell_speed = AMMO_SPEED_TIER_1

	shrapnel_chance = 50
	shrapnel_type = /obj/item/shard/shrapnel/big

/datum/ammo/bullet/shrapnel/incendiary
	name = "flaming shrapnel"
	icon_state = "beanbag" // looks suprisingly a lot like flaming shrapnel chunks
	flags_ammo_behavior = AMMO_STOPPED_BY_COVER

	shell_speed = AMMO_SPEED_TIER_1
	damage = 20
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/shrapnel/incendiary/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/bullet/shrapnel/metal
	name = "metal shrapnel"
	icon_state = "shrapnelshot_bit"
	flags_ammo_behavior = AMMO_STOPPED_BY_COVER|AMMO_BALLISTIC
	shell_speed = AMMO_SPEED_TIER_1
	damage = 30
	shrapnel_chance = 15
	accuracy = HIT_ACCURACY_TIER_8
	penetration = ARMOR_PENETRATION_TIER_4

/datum/ammo/bullet/shrapnel/light // weak shrapnel
	name = "light shrapnel"
	icon_state = "shrapnel_light"

	damage = 10
	penetration = ARMOR_PENETRATION_TIER_1
	shell_speed = AMMO_SPEED_TIER_1
	shrapnel_chance = 0

/datum/ammo/bullet/shrapnel/light/human
	name = "human bone fragments"
	icon_state = "shrapnel_human"

	shrapnel_chance = 50
	shrapnel_type = /obj/item/shard/shrapnel/bone_chips/human

/datum/ammo/bullet/shrapnel/light/human/var1 // sprite variants
	icon_state = "shrapnel_human1"

/datum/ammo/bullet/shrapnel/light/human/var2 // sprite variants
	icon_state = "shrapnel_human2"

/datum/ammo/bullet/shrapnel/light/xeno
	name = "alien bone fragments"
	icon_state = "shrapnel_xeno"

	shrapnel_chance = 50
	shrapnel_type = /obj/item/shard/shrapnel/bone_chips/xeno

/datum/ammo/bullet/shrapnel/spall // weak shrapnel
	name = "spall"
	icon_state = "shrapnel_light"

	damage = 10
	penetration = ARMOR_PENETRATION_TIER_1
	shell_speed = AMMO_SPEED_TIER_1
	shrapnel_chance = 0

/datum/ammo/bullet/shrapnel/light/glass
	name = "glass shrapnel"
	icon_state = "shrapnel_glass"

/datum/ammo/bullet/shrapnel/light/effect/ // no damage, but looks bright and neat
	name = "sparks"

	damage = 1 // Tickle tickle

/datum/ammo/bullet/shrapnel/light/effect/ver1
	icon_state = "shrapnel_bright1"

/datum/ammo/bullet/shrapnel/light/effect/ver2
	icon_state = "shrapnel_bright2"

/datum/ammo/bullet/shrapnel/jagged
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_2
	accuracy = HIT_ACCURACY_TIER_MAX

/datum/ammo/bullet/shrapnel/jagged/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(isxeno(hit))
		hit.apply_effect(0.4, SLOW)

/*
//========
					CAS 30mm impacters
//========
*/
/datum/ammo/bullet/shrapnel/gau  //for the GAU to have a impact bullet instead of firecrackers
	name = "30mm Multi-Purpose shell"

	damage = 1 // ALL DAMAGE IS IN dropship_ammo SO WE CAN DEAL DAMAGE TO RESTING MOBS, these will still remain however so that we can get cause_data and status effects.
	damage_type = BRUTE
	penetration = ARMOR_PENETRATION_TIER_2
	accuracy = HIT_ACCURACY_TIER_MAX
	max_range = 0
	shrapnel_chance = 100 //the least of your problems

/datum/ammo/bullet/shrapnel/gau/at
	name = "30mm Anti-Tank shell"

	damage = 1 // ALL DAMAGE IS IN dropship_ammo SO WE CAN DEAL DAMAGE TO RESTING MOBS, these will still remain however so that we can get cause_data and status effects.
	penetration = ARMOR_PENETRATION_TIER_8
	accuracy = HIT_ACCURACY_TIER_MAX
/*
//======
					Misc Ammo
//======
*/

/datum/ammo/alloy_spike
	name = "alloy spike"
	headshot_state = HEADSHOT_OVERLAY_MEDIUM
	ping = "ping_s"
	icon_state = "MSpearFlight"
	sound_hit = "alloy_hit"
	sound_armor = "alloy_armor"
	sound_bounce = "alloy_bounce"

	accuracy = HIT_ACCURACY_TIER_8
	accurate_range = 12
	max_range = 12
	damage = 30
	penetration= ARMOR_PENETRATION_TIER_10
	shrapnel_chance = SHRAPNEL_CHANCE_TIER_7
	shrapnel_type = /obj/item/shard/shrapnel

/datum/ammo/flamethrower
	name = "flame"
	icon_state = "pulse0"
	damage_type = BURN
	flags_ammo_behavior = AMMO_IGNORE_ARMOR|AMMO_HITS_TARGET_TURF

	bullet_color = LIGHT_COLOR_FIRE

	max_range = 6
	damage = 35

/datum/ammo/flamethrower/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/flamethrower/on_hit_mob(mob/hit, obj/item/projectile/proj)
	drop_flame(get_turf(hit), proj.weapon_cause_data)

/datum/ammo/flamethrower/on_hit_obj(obj/O, obj/item/projectile/proj)
	drop_flame(get_turf(O), proj.weapon_cause_data)

/datum/ammo/flamethrower/on_hit_turf(turf/T, obj/item/projectile/proj)
	drop_flame(T, proj.weapon_cause_data)

/datum/ammo/flamethrower/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_flame(get_turf(proj), proj.weapon_cause_data)

/datum/ammo/flamethrower/tank_flamer
	flamer_reagent_type = /datum/reagent/napalm/blue
	flame_range = 2

/datum/ammo/flamethrower/sentry_flamer
	flags_ammo_behavior = AMMO_IGNORE_ARMOR|AMMO_IGNORE_COVER|AMMO_FLAME
	flamer_reagent_type = /datum/reagent/napalm/blue

	accuracy = HIT_ACCURACY_TIER_8
	accurate_range = 6
	max_range = 12
	shell_speed = AMMO_SPEED_TIER_3

/datum/ammo/flamethrower/sentry_flamer/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/flamethrower/sentry_flamer/glob
	max_range = 14
	accurate_range = 10
	var/datum/effect_system/smoke_spread/phosphorus/smoke

/datum/ammo/flamethrower/sentry_flamer/glob/New()
	. = ..()
	smoke = new()

/datum/ammo/flamethrower/sentry_flamer/glob/drop_flame(turf/T, datum/cause_data/cause_data)
	if(!istype(T))
		return
	var/flame_radius = 1
	if(!(T.turf_flags & TURF_WEATHER))
		flame_radius += 8
	smoke.set_up(flame_radius, 0, T, new_cause_data = cause_data)
	smoke.start()

/datum/ammo/flamethrower/sentry_flamer/glob/Destroy()
	qdel(smoke)
	return ..()

/datum/ammo/flamethrower/sentry_flamer/mini
	name = "normal fire"

/datum/ammo/flamethrower/sentry_flamer/mini/drop_flame(turf/T, datum/cause_data/cause_data)
	if(!istype(T))
		return
	var/datum/reagent/napalm/ut/R = new()
	R.durationfire = BURN_TIME_INSTANT
	new /obj/flamer_fire(T, cause_data, R, 0)

/datum/ammo/flare
	name = "flare"
	ping = null //no bounce off.
	damage_type = BURN
	flags_ammo_behavior = AMMO_HITS_TARGET_TURF
	icon_state = "flare"

	damage = 15
	accuracy = HIT_ACCURACY_TIER_3
	max_range = 14
	shell_speed = AMMO_SPEED_TIER_3

	var/flare_type = /obj/item/device/flashlight/flare/on/gun
	handful_type = /obj/item/device/flashlight/flare

/datum/ammo/flare/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_incendiary)
	))

/datum/ammo/flare/on_hit_mob(mob/hit,obj/item/projectile/proj)
	drop_flare(get_turf(hit), proj, proj.firer)

/datum/ammo/flare/on_hit_obj(obj/O,obj/item/projectile/proj)
	drop_flare(get_turf(proj), proj, proj.firer)

/datum/ammo/flare/on_hit_turf(turf/T, obj/item/projectile/proj)
	if(T.density && isturf(proj.loc))
		drop_flare(proj.loc, proj, proj.firer)
	else
		drop_flare(T, proj, proj.firer)

/datum/ammo/flare/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_flare(get_turf(proj), proj, proj.firer)

/datum/ammo/flare/proc/drop_flare(turf/T, obj/item/projectile/fired_projectile, mob/firer)
	var/obj/item/device/flashlight/flare/G = new flare_type(T)
	var/matrix/rotation = matrix()
	rotation.Turn(fired_projectile.dir_angle - 90)
	G.apply_transform(rotation)
	G.visible_message(SPAN_WARNING("\A [G] bursts into brilliant light nearby!"))
	return G

/datum/ammo/flare/signal
	name = "signal flare"
	icon_state = "flare_signal"
	flare_type = /obj/item/device/flashlight/flare/signal/gun
	handful_type = /obj/item/device/flashlight/flare/signal

/datum/ammo/flare/signal/drop_flare(turf/T, obj/item/projectile/fired_projectile, mob/firer)
	var/obj/item/device/flashlight/flare/signal/gun/signal_flare = ..()
	signal_flare.activate_signal(firer)
	if(istype(fired_projectile.shot_from, /obj/item/weapon/gun/flare))
		var/obj/item/weapon/gun/flare/flare_gun_fired_from = fired_projectile.shot_from
		flare_gun_fired_from.last_signal_flare_name = signal_flare.name

/datum/ammo/flare/starshell
	name = "starshell ash"
	icon_state = "starshell_bullet"
	max_range = 5
	flare_type = /obj/item/device/flashlight/flare/on/starshell_ash

/datum/ammo/flare/starshell/set_bullet_traits()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff, /datum/element/bullet_trait_incendiary)
	))

/datum/ammo/souto
	name = "Souto Can"
	ping = null //no bounce off.
	damage_type = BRUTE
	shrapnel_type = /obj/item/reagent_container/food/drinks/cans/souto/classic
	flags_ammo_behavior = AMMO_SKIPS_ALIENS|AMMO_IGNORE_ARMOR|AMMO_IGNORE_RESIST|AMMO_BALLISTIC|AMMO_STOPPED_BY_COVER|AMMO_SPECIAL_EMBED
	var/obj/item/reagent_container/food/drinks/cans/souto/can_type
	icon_state = "souto_classic"

	max_range = 12
	shrapnel_chance = 10
	accuracy = HIT_ACCURACY_TIER_10
	accurate_range = 12
	shell_speed = AMMO_SPEED_TIER_1

/datum/ammo/souto/on_embed(mob/embedded_mob, obj/limb/target_organ)
	if(ishuman(embedded_mob) && !isyautja(embedded_mob))
		if(istype(target_organ))
			target_organ.embed(new can_type)

/datum/ammo/souto/on_hit_mob(mob/hit, obj/item/projectile/proj)
	if(!hit || hit == proj.firer) return
	if(hit.throw_mode && !hit.get_active_hand()) //empty active hand and we're in throw mode. If so we catch the can.
		if(!hit.is_mob_incapacitated()) // People who are not able to catch cannot catch.
			if(proj.contents.len == 1)
				for(var/obj/item/reagent_container/food/drinks/cans/souto/S in proj.contents)
					hit.put_in_active_hand(S)
					for(var/mob/O in viewers(world_view_size, proj)) //find all people in view.
						O.show_message(SPAN_DANGER("[hit] catches the [S]!"), SHOW_MESSAGE_VISIBLE) //Tell them the can was caught.
					return //Can was caught.
	if(ishuman(hit))
		var/mob/living/carbon/human/H = hit
		if(H.species.name == "Human") //no effect on synths or preds.
			H.apply_effect(6, STUN)
			H.apply_effect(8, WEAKEN)
			H.apply_effect(15, DAZE)
			H.apply_effect(15, SLOW)
		shake_camera(H, 2, 1)
		if(proj.contents.len)
			drop_can(proj.loc, proj) //We make a can at the location.

/datum/ammo/souto/on_hit_obj(obj/O,obj/item/projectile/proj)
	drop_can(proj.loc, proj) //We make a can at the location.

/datum/ammo/souto/on_hit_turf(turf/T, obj/item/projectile/proj)
	drop_can(proj.loc, proj) //We make a can at the location.

/datum/ammo/souto/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_can(proj.loc, proj) //We make a can at the location.

/datum/ammo/souto/on_shield_block(mob/hit, obj/item/projectile/proj)
	drop_can(proj.loc, proj) //We make a can at the location.

/datum/ammo/souto/proc/drop_can(loc, obj/item/projectile/proj)
	if(proj.contents.len)
		for(var/obj/item/I in proj.contents)
			I.forceMove(loc)
	randomize_projectile(proj)

/datum/ammo/souto/proc/randomize_projectile(obj/item/projectile/proj)
	shrapnel_type = pick(typesof(/obj/item/reagent_container/food/drinks/cans/souto)-/obj/item/reagent_container/food/drinks/cans/souto)

/datum/ammo/grenade_container
	name = "grenade shell"
	ping = null
	damage_type = BRUTE
	var/nade_type = /obj/item/explosive/grenade/high_explosive
	icon_state = "grenade"
	flags_ammo_behavior = AMMO_IGNORE_COVER|AMMO_SKIPS_ALIENS

	damage = 15
	accuracy = HIT_ACCURACY_TIER_3
	max_range = 8

/datum/ammo/grenade_container/on_hit_mob(mob/hit,obj/item/projectile/proj)
	drop_nade(proj)

/datum/ammo/grenade_container/on_hit_obj(obj/O,obj/item/projectile/proj)
	drop_nade(proj)

/datum/ammo/grenade_container/on_hit_turf(turf/T,obj/item/projectile/proj)
	drop_nade(proj)

/datum/ammo/grenade_container/do_at_max_range(turf/T, obj/item/projectile/proj)
	drop_nade(proj)

/datum/ammo/grenade_container/proc/drop_nade(obj/item/projectile/proj)
	var/turf/T = get_turf(proj)
	var/obj/item/explosive/grenade/G = new nade_type(T)
	G.visible_message(SPAN_WARNING("\A [G] lands on [T]!"))
	G.det_time = 10
	G.cause_data = proj.weapon_cause_data
	G.activate()

/datum/ammo/grenade_container/rifle
	flags_ammo_behavior = NO_FLAGS

/datum/ammo/grenade_container/smoke
	name = "smoke grenade shell"
	nade_type = /obj/item/explosive/grenade/smokebomb
	icon_state = "smoke_shell"

/datum/ammo/hugger_container
	name = "hugger shell"
	ping = null
	damage_type = BRUTE
	var/hugger_hive = FACTION_XENOMORPH_NORMAL
	icon_state = "smoke_shell"

	bullet_color = ""

	damage = 15
	accuracy = HIT_ACCURACY_TIER_3
	max_range = 6

/datum/ammo/hugger_container/on_hit_mob(mob/hit,obj/item/projectile/proj)
	spawn_hugger(get_turf(proj))

/datum/ammo/hugger_container/on_hit_obj(obj/O,obj/item/projectile/proj)
	spawn_hugger(get_turf(proj))

/datum/ammo/hugger_container/on_hit_turf(turf/T,obj/item/projectile/proj)
	spawn_hugger(get_turf(proj))

/datum/ammo/hugger_container/do_at_max_range(turf/T, obj/item/projectile/proj)
	spawn_hugger(get_turf(proj))

/datum/ammo/hugger_container/proc/spawn_hugger(turf/T)
	var/obj/item/clothing/mask/facehugger/child = new(T)
	child.faction = GLOB.faction_datums[hugger_hive]
	INVOKE_ASYNC(child, TYPE_PROC_REF(/obj/item/clothing/mask/facehugger, leap_at_nearest_target))
