//Some debug variables. Toggle them to 1 in order to see the related debug messages. Helpful when testing out formulas.
#define DEBUG_HIT_CHANCE 0
#define DEBUG_HUMAN_DEFENSE 0
#define DEBUG_XENO_DEFENSE 0

//The actual bullet objects.
/obj/item/projectile
	name = "bullet"
	desc = "This is bullet."
	var/fire_ready = FALSE
	plane = GAME_PLANE
	matter = list("metal" = 50)
	flags_atom = FPRINT|CONDUCT

	throwforce = 2
	w_class = SIZE_SMALL
	throw_speed = SPEED_SLOW
	throw_range = 6
	var/caliber = null // This is used for matching handfuls to each other or whatever the mag is. Examples are" "12g" ".44" ".357" etc.

	var/cause_data = "взрыв боеприпасов"
	var/shrapnel_type = /datum/ammo/bullet/shrapnel
	var/explosing

	attack_speed = 3 // should make reloading less painful

	var/can_be_scraped = TRUE
	var/scrapping_probability = 0.01
	var/scrap_ammo_perc = 0 //If 0, all good, if 100 your ass gonna die

	//light
	light_system = MOVABLE_LIGHT
	light_range = 2
	light_power = 0.2
	light_color = COLOR_VERY_SOFT_YELLOW

	var/datum/ammo/ammo //The ammo data which holds most of the actual info.

	var/def_zone = "chest" //So we're not getting empty strings.
	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/apx //Pixel location in absolute coordinates. This is (((x - 1) * 32) + 16 + pixel_x)
	var/apy //These values are floats, not integers. They need to be converted through CEILING or such when translated to relative pixel coordinates.

	var/current = null
	var/atom/shot_from = null // the object which shot us
	var/turf/starting_turf = null // the projectile's starting turf
	var/atom/original_target = null // the original target clicked
	var/turf/original_target_turf = null // the original target's starting turf
	var/atom/firer = null // Who shot it

	var/permutated[] = null // we've passed through these atoms, don't try to hit them again
	var/list/atom/movable/uncross_scheduled = list() // List of border movable atoms to check for when exiting a turf.

	var/damage = 0
	var/accuracy = 70 //Base projectile accuracy. Can maybe be later taken from the mob if desired.
	var/max_range = 0

	var/damage_falloff = 0 //how much effectiveness in damage the projectile loses per tiles travelled beyond the effective range
	var/damage_buildup = 0 //how much effectiveness in damage the projectile loses before the effective range

	var/effective_range_min = 0 //What minimum range the projectile deals full damage, builds up the closer you get. 0 for no minimum. Set by the weapon.
	var/effective_range_max = 0 //What maximum range the projectile deals full damage, tapers off using damage_falloff after hitting this value. 0 for no maximum. Set by the weapon.

	var/scatter = 0
	var/distance_travelled = 0
	var/range_fallof = 0

	var/projectile_speed = 1 //Tiles travelled per full tick.

	var/projectile_override_flags = NO_FLAGS
	var/projectile_flags = NO_FLAGS
	var/projectile_status_flags = NO_FLAGS

	var/datum/cause_data/weapon_cause_data
	var/list/bullet_traits

	/// The beam linked to the projectile. Can be utilized for things like grappling hooks, harpoon guns, tripwire guns, etc..
	var/obj/effect/bound_beam

	/// The flicker that plays when a bullet hits a target. Usually red. Can be nulled so it doesn't show up at all.
	var/hit_effect_color = "#FF0000"
	/// How much to make the bullet fall off by accuracy-wise when closer than the ideal range
	var/accuracy_range_falloff = 10

	///The icon of the laser beam that will be created
	var/effect_icon = null

	//Fired processing vars
	var/last_projectile_move = 0
	var/stored_moves = 0
	var/dir_angle //0 is north, 90 is east, 180 is south, 270 is west. BYOND angles and all.
	var/x_offset //Float, not integer.
	var/y_offset

//custom bullets, used only in custom projectiles, but can in normal if you wanna make hard custom proj
	var/obj/item/ammo_parts/part/container/container = null

/obj/item/projectile/Initialize(mapload, datum/cause_data/_weapon_cause_data, datum/ammo/_ammo, _caliber, _effect_icon)
	. = ..(mapload)
	permutated = list()
	if(can_be_scraped && prob(scrapping_probability))
		scrap_ammo_perc = rand(1, 100)

	if(_weapon_cause_data)
		weapon_cause_data = _weapon_cause_data

	if(_ammo)
		ammo = _ammo
		name = _ammo.name

	if(_caliber)
		caliber = _caliber

	if(_effect_icon)
		effect_icon = _effect_icon

	projectile_flags |= PROJECTILE_HITSCAN

	pixel_x = rand(-8.0, 8) //Want to move them just a tad.
	pixel_y = rand(-8.0, 8)

/obj/item/projectile/update_icon() //Handles the icon itself as well as some bonus things.
	if(!ammo)
		return
	if(!fire_ready)
		icon = 'icons/obj/items/weapons/guns/handful.dmi'
		icon_state = ammo.handful_state + "_1"
	else
		icon = 'icons/obj/items/weapons/projectiles.dmi'
		icon_state = ammo.icon_state

/obj/item/projectile/pickup(mob/user)
	var/olddir = dir
	. = ..()
	dir = olddir

/obj/item/projectile/equipped(mob/user, slot)
	var/thisDir = src.dir
	..(user,slot)
	setDir(thisDir)
	return

/obj/item/projectile/Destroy()
	invisibility = 100
	SSprojectiles.stop_projectile(src)
	QDEL_NULL(bound_beam)
	. = ..()
	ammo = null
	shot_from = null
	original_target = null
	permutated = null
	uncross_scheduled = null
	original_target_turf = null
	starting_turf = null
	weapon_cause_data = null
	firer = null

/obj/item/projectile/Crossed(atom/movable/AM) //A mob moving on a tile with a projectile is hit by it.
	. = ..()
	if(AM && !QDELETED(src) && !(AM in permutated) && fire_ready)
		permutated |= AM
		if(scan_a_turf(get_turf(AM)))
			SSprojectiles.stop_projectile(src)
			qdel(src)

/obj/item/projectile/Collided(atom/movable/AM)
	if(AM && !QDELETED(src) && !(AM in permutated) && fire_ready)
		permutated |= AM
		if(scan_a_turf(get_turf(AM)))
			SSprojectiles.stop_projectile(src)
			qdel(src)

/obj/item/projectile/proc/apply_bullet_trait(list/entry)
	bullet_traits += list(entry.Copy())
	// Need to use the proc instead of the wrapper because each entry is a list
	_AddElement(entry)

/obj/item/projectile/proc/give_bullet_traits(obj/item/projectile/proj)
	for(var/list/entry in bullet_traits)
		proj.apply_bullet_trait(entry.Copy())

/obj/item/projectile/proc/bullet_ready_to_fire(atom/bullet_source = null, weapon_source_mob = null)
	unacidable = TRUE
	anchored = TRUE
	flags_atom = NOINTERACT
	layer = FLY_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	generate_bullet(null, weapon_source_mob, 0, NO_FLAGS)

	if(isliving(loc) && !weapon_source_mob)
		var/mob/M = loc
		weapon_source_mob = M
	if(!weapon_cause_data)
		weapon_cause_data = create_cause_data(initial(bullet_source.name), weapon_source_mob, bullet_source)
	firer = weapon_cause_data?.resolve_mob()

/obj/item/projectile/ex_act()
	if(fire_ready)
		return FALSE
	. = ..()

/obj/item/projectile/throw_atom()
	if(fire_ready)
		return FALSE
	. = ..()

/obj/item/projectile/proc/generate_bullet(ammo_datum = null, bullet_generator, bonus_damage = 0, special_flags = NO_FLAGS)
	if(ammo_datum)
		ammo = ammo_datum
	name = ammo.name
	icon = ammo.icon
	icon_state = ammo.icon_state
	damage = (ammo.damage + bonus_damage) * (rand(PROJ_VARIANCE_LOW-ammo.damage_var_low, PROJ_VARIANCE_HIGH+ammo.damage_var_high) * PROJ_BASE_DAMAGE_MULT)
	scatter = ammo.scatter
	accuracy = (accuracy + ammo.accuracy) * (rand(PROJ_VARIANCE_LOW-ammo.accuracy_var_low, PROJ_VARIANCE_HIGH+ammo.accuracy_var_high) * PROJ_BASE_ACCURACY_MULT)
	max_range = max_range + ammo.max_range
	damage_falloff = ammo.damage_falloff
	damage_buildup = ammo.damage_buildup
	hit_effect_color = ammo.hit_effect_color
	projectile_override_flags = special_flags
	fire_ready = TRUE

	ammo.on_bullet_generation(src, bullet_generator)

	// Apply bullet traits from ammo
	for(var/entry in ammo.traits_to_give)
		var/list/L
		// Check if this is an ID'd bullet trait
		if(istext(entry))
			L = ammo.traits_to_give[entry].Copy()
		else
			// Prepend the bullet trait to the list
			L = list(entry) + ammo.traits_to_give[entry]
		// Need to use the proc instead of the wrapper because each entry is a list
		apply_bullet_trait(L)
	update_icon()

/obj/item/projectile/attackby(obj/item/I, mob/user)
	if(fire_ready)
		return
	if(istype(I, /obj/item/projectile)) // We have a handful. They don't need to hold it.
		bullet_make_handful(user, I)

/obj/item/projectile/proc/bullet_make_handful(mob/user, obj/item/projectile/proj)
	if(proj)
		var/obj/item/ammo_magazine/handful/new_handful = new ammo.handful_type(src, TRUE, TRUE)
		new_handful.generate_handful(ammo, caliber, 5)
		new_handful.generate_ammo(TRUE)
		if(user)
			user.temp_drop_inv_item(src)
			user.temp_drop_inv_item(proj)
			proj.forceMove(new_handful)
			if(!user.put_in_hands(new_handful))
				new_handful.forceMove(user.loc)
		forceMove(new_handful)
		new_handful.ammo_position++
		new_handful.current_rounds[new_handful.ammo_position] = proj
		new_handful.ammo_position++
		new_handful.current_rounds[new_handful.ammo_position] = src
		new_handful.update_icon()
		return new_handful
	else
		var/obj/item/ammo_magazine/handful/new_handful = new ammo.handful_type(src, TRUE, TRUE)
		new_handful.generate_handful(ammo, caliber, 5)
		new_handful.generate_ammo(TRUE)
		if(user)
			user.temp_drop_inv_item(src)
		forceMove(new_handful)
		new_handful.ammo_position++
		new_handful.current_rounds[new_handful.ammo_position] = src
		new_handful.update_icon()
		return new_handful

/obj/item/projectile/proc/calculate_damage()
	if(effective_range_min && distance_travelled < effective_range_min)
		return max(0, damage - round((effective_range_min - distance_travelled) * damage_buildup))
	else if(distance_travelled > effective_range_max)
		return max(0, damage - round((distance_travelled - effective_range_max) * damage_falloff))
	return damage

/*
CEILING() is used on some contexts:
1) For absolute pixel locations to tile conversions, as the coordinates are read from left-to-right (from low to high numbers) and each tile occupies 32 pixels.
So if we are on the 32th absolute pixel coordinate we are on tile 1, but if we are on the 33th (to 64th) we are then on the second tile.
2) For number of pixel moves, as it is counting number of full (pixel) moves required.
*/
#define PROJ_ABS_PIXEL_TO_TURF(abspx, abspy, zlevel) (locate(CEILING((abspx / 32), 1), CEILING((abspy / 32), 1), zlevel))
#define PROJ_ANIMATION_SPEED ((end_of_movement/projectile_speed) || (required_moves/projectile_speed)) //Movements made times deciseconds per movement.

// Target, firer, shot from (i.e. the gun), projectile range, projectile speed, original target (who was aimed at, not where projectile is going towards)
/obj/item/projectile/proc/fire_at(atom/target, atom/shooter, atom/source, range, speed, atom/original_override, angle)
	if(!isnull(speed))
		projectile_speed = speed

	if(!original_target)
		original_target = istype(original_override) ? original_override : target

	//Safety checks.
	if(QDELETED(target) && !isnum(angle)) //We can work with either a target or an angle, or both, but not without any.
		stack_trace("fire_at called on a QDELETED target ([target]) with no original_target_turf and a null angle.")
		qdel(src)
		return

	if(projectile_speed <= 0) //Shouldn't happen without a coder oofing, but if they do, it risks breaking a lot, so better safe than sorry.
		stack_trace("[src] achieved [projectile_speed] velocity somehow at fire_at. Type: [type]. From: [target]. Shot by: [shooter].")
		qdel(src)
		return

	if(!isnull(range))
		max_range = range

	if(shooter && !firer)
		firer = shooter

	if(source)
		shot_from = source

	if(!istype(loc, /turf))
		if(!(projectile_flags & PROJECTILE_SHRAPNEL) && shooter)
			forceMove(get_turf(shooter))
		else if(source)
			forceMove(get_turf(source))
		else
			forceMove(get_turf(src))

	starting_turf = loc

	if(target)
		original_target = target
		original_target_turf = get_turf(target)
		if(original_target_turf == loc) //Shooting from and towards the same tile. Why not?
			distance_travelled++
			scan_a_turf(loc)
			qdel(src)
			return

	apx = ABS_COOR(x) //Set the absolute coordinates. Center of a tile is assumed to be (16,16)
	apy = ABS_COOR(y)

	if(isnum(angle))
		dir_angle = angle
	else
		if(isliving(target)) //If we clicked on a living mob, use the clicked atom tile's center for maximum accuracy. Else aim for the clicked pixel.
			dir_angle = round(Get_Pixel_Angle((ABS_COOR(target.x) - apx), (ABS_COOR(target.y) - apy))) //Using absolute pixel coordinates.
		else
			dir_angle = round(Get_Pixel_Angle((ABS_COOR_OFFSET(target.x, p_x) - apx), (ABS_COOR_OFFSET(target.y, p_y) - apy)))

	x_offset = round(sin(dir_angle), 0.01)
	y_offset = round(cos(dir_angle), 0.01)


	var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags
	if(SSticker.mode.round_statistics && ammo_flags & AMMO_BALLISTIC)
		SSticker.mode.round_statistics.total_projectiles_fired++
		if(ammo.bonus_projectiles_amount)
			SSticker.mode.round_statistics.total_projectiles_fired += ammo.bonus_projectiles_amount

	if(firer && ismob(firer) && weapon_cause_data)
		var/mob/M = firer
		M.track_shot(weapon_cause_data.cause_name)

	//If we have the right kind of ammo, we can fire several projectiles at once.
	if(ammo.bonus_projectiles_amount && ammo.bonus_projectiles_type)
		ammo.fire_bonus_projectiles(src)

	if(shooter && !(projectile_flags & PROJECTILE_SHRAPNEL))
		firer = shooter
		permutated |= firer //Don't hit the shooter

	if(projectile_flags & PROJECTILE_HITSCAN)
		if(shooter.Adjacent(target) && ismob(target))
			var/mob/mob_to_hit = target
			ammo.on_hit_mob(mob_to_hit, src)
			mob_to_hit.bullet_act(src)
			qdel(src)
			return

		if(projectile_batch_move_hitscan() == PROJECTILE_FROZEN || (projectile_status_flags & PROJECTILE_FROZEN))
			var/atom/movable/hitscan_projectile_effect/laser_effect = new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.01, effect_icon, ammo.bullet_color)
			RegisterSignal(loc, COMSIG_TURF_RESUME_PROJECTILE_MOVE, PROC_REF(resume_move))
			laser_effect.RegisterSignal(loc, COMSIG_TURF_RESUME_PROJECTILE_MOVE, TYPE_PROC_REF(/atom/movable/hitscan_projectile_effect, remove_effect))
			laser_effect.RegisterSignal(src, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/atom/movable/hitscan_projectile_effect, remove_effect))
			return

		qdel(src)
		return

	var/proj_dir
	switch(dir_angle) //The projectile starts at the edge of the firer's tile (still inside it).
		if(0, 360)
			proj_dir = NORTH
			pixel_x = 0
			pixel_y = 16
		if(1 to 44)
			proj_dir = NORTHEAST
			pixel_x = round(16 * ((dir_angle) / 45))
			pixel_y = 16
		if(45)
			proj_dir = NORTHEAST
			pixel_x = 16
			pixel_y = 16
		if(46 to 89)
			proj_dir = NORTHEAST
			pixel_x = 16
			pixel_y = round(16 * ((90 - dir_angle) / 45))
		if(90)
			proj_dir = EAST
			pixel_x = 16
			pixel_y = 0
		if(91 to 134)
			proj_dir = SOUTHEAST
			pixel_x = 16
			pixel_y = round(-15 * ((dir_angle - 90) / 45))
		if(135)
			proj_dir = SOUTHEAST
			pixel_x = 16
			pixel_y = -15
		if(136 to 179)
			proj_dir = SOUTHEAST
			pixel_x = round(16 * ((180 - dir_angle) / 45))
			pixel_y = -15
		if(180)
			proj_dir = SOUTH
			pixel_x = 0
			pixel_y = -15
		if(181 to 224)
			proj_dir = SOUTHWEST
			pixel_x = round(-15 * ((dir_angle - 180) / 45))
			pixel_y = -15
		if(225)
			proj_dir = SOUTHWEST
			pixel_x = -15
			pixel_y = -15
		if(226 to 269)
			proj_dir = SOUTHWEST
			pixel_x = -15
			pixel_y = round(-15 * ((270 - dir_angle) / 45))
		if(270)
			proj_dir = WEST
			pixel_x = -15
			pixel_y = 0
		if(271 to 314)
			proj_dir = NORTHWEST
			pixel_x = -15
			pixel_y = round(16 * ((dir_angle - 270) / 45))
		if(315)
			proj_dir = NORTHWEST
			pixel_x = -15
			pixel_y = 16
		if(316 to 359)
			proj_dir = NORTHWEST
			pixel_x = round(-15 * ((360 - dir_angle) / 45))
			pixel_y = 16

	setDir(proj_dir)

	apx += pixel_x //Update the absolute pixels with the offset.
	apy += pixel_y

	var/matrix/rotate = matrix() //Change the bullet angle.
	rotate.Turn(dir_angle)
	transform = rotate

	var/first_move = min(1, 1)
	var/first_moves = projectile_speed
	switch(projectile_batch_move(first_move))
		if(PROJECTILE_HIT) //Hit on first movement.
			if(!(projectile_status_flags & PROJECTILE_FROZEN))
				qdel(src)
			return
		if(PROJECTILE_ERROR)
			qdel(src)
			return
		if(PROJECTILE_FROZEN)
			return

	first_moves -= first_move
	switch(first_moves && projectile_batch_move(first_moves))
		if(PROJECTILE_HIT) //First movement batch happens on the same tick.
			if(!(projectile_status_flags & PROJECTILE_FROZEN))
				qdel(src)
			return
		if(PROJECTILE_ERROR)
			qdel(src)
			return
		if(PROJECTILE_FROZEN)
			return

	if(QDELETED(src))
		return

	set_light_on(TRUE)
	SSprojectiles.queue_projectile(src)

/obj/item/projectile/process()
	if(QDELETED(src))
		return PROCESS_KILL

	var/required_moves = required_moves_calc()
	if(!required_moves)
		return //Slowpoke. Maybe next tick.

	switch(projectile_batch_move(required_moves))
		if(PROJECTILE_HIT) //Hit on first movement.
			if(!(projectile_status_flags & PROJECTILE_FROZEN))
				qdel(src)
			return PROCESS_KILL
		if(PROJECTILE_ERROR)
			qdel(src)
			return PROCESS_KILL
		if(PROJECTILE_FROZEN)
			return PROCESS_KILL

	if(QDELETED(src))
		return PROCESS_KILL

	if(ammo.flags_ammo_behavior & AMMO_SPECIAL_PROCESS)
		ammo.ammo_process(src)


/obj/item/projectile/proc/required_moves_calc()
	var/elapsed_time_deciseconds = world.time - last_projectile_move
	if(!elapsed_time_deciseconds)
		return 0 //No moves needed if not a tick has passed.
	var/required_moves = (elapsed_time_deciseconds * projectile_speed) + stored_moves
	stored_moves = 0
	var/modulus_excess = MODULUS(required_moves, 1) //Fractions of a move.
	if(modulus_excess)
		required_moves -= modulus_excess
		stored_moves += modulus_excess

	if(required_moves > SSprojectiles.global_max_tick_moves)
		stored_moves += required_moves - SSprojectiles.global_max_tick_moves
		required_moves = SSprojectiles.global_max_tick_moves

	return required_moves

/obj/item/projectile/proc/projectile_batch_move(required_moves)
	var/end_of_movement = 0 //In batch moves this loop, only if the projectile stopped.
	var/turf/last_processed_turf = loc
	var/x_pixel_dist_travelled = 0
	var/y_pixel_dist_travelled = 0
	for(var/i in 1 to required_moves)
		distance_travelled++
		//Here we take the projectile's absolute pixel coordinate + the travelled distance and use PROJ_ABS_PIXEL_TO_TURF to first convert it into tile coordinates, and then use those to locate the turf.
		var/turf/next_turf = PROJ_ABS_PIXEL_TO_TURF((apx + x_pixel_dist_travelled + (32 * x_offset)), (apy + y_pixel_dist_travelled + (32 * y_offset)), z)
		if(!next_turf) //Map limit.
			end_of_movement = (i-- || 1)
			break
		if(next_turf == last_processed_turf)
			x_pixel_dist_travelled += 32 * x_offset
			y_pixel_dist_travelled += 32 * y_offset
			continue //Pixel movement only, didn't manage to change turf.

		var/movement_dir = get_dir(last_processed_turf, next_turf)
		if(dir != movement_dir)
			setDir(movement_dir)

		if(ISDIAGONALDIR(movement_dir)) //Diagonal case. We need to check the turf to cross to get there.
			if(!x_offset || !y_offset) //Unless a coder screws up this won't happen. Buf if they do it will cause an infinite processing loop due to division by zero, so better safe than sorry.
				stack_trace("projectile_batch_move called with diagonal movement_dir and offset-lacking. x_offset: [x_offset], y_offset: [y_offset].")
				return PROJECTILE_ERROR
			var/turf/turf_crossed_by
			var/pixel_moves_until_crossing_x_border
			var/pixel_moves_until_crossing_y_border
			var/border_escaped_through
			switch(movement_dir)
				if(NORTHEAST)
					pixel_moves_until_crossing_x_border = CEILING(((33 - ABS_PIXEL_TO_REL(apx + x_pixel_dist_travelled)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((33 - ABS_PIXEL_TO_REL(apy + y_pixel_dist_travelled)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border) //Escapes vertically.
						border_escaped_through = NORTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border) //Escapes horizontally.
						border_escaped_through = EAST
					else //Escapes both borders at the same time, perfectly diagonal.
						border_escaped_through = pick(NORTH, EAST) //So choose at random to preserve behavior of no purely diagonal movements allowed.
				if(SOUTHEAST)
					pixel_moves_until_crossing_x_border = CEILING(((33 - ABS_PIXEL_TO_REL(apx + x_pixel_dist_travelled)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((0 - ABS_PIXEL_TO_REL(apy + y_pixel_dist_travelled)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = SOUTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = EAST
					else
						border_escaped_through = pick(SOUTH, EAST)
				if(SOUTHWEST)
					pixel_moves_until_crossing_x_border = CEILING(((0 - ABS_PIXEL_TO_REL(apx + x_pixel_dist_travelled)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((0 - ABS_PIXEL_TO_REL(apy + y_pixel_dist_travelled)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = SOUTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = WEST
					else
						border_escaped_through = pick(SOUTH, WEST)
				if(NORTHWEST)
					pixel_moves_until_crossing_x_border = CEILING(((0 - ABS_PIXEL_TO_REL(apx + x_pixel_dist_travelled)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((33 - ABS_PIXEL_TO_REL(apy + y_pixel_dist_travelled)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = NORTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = WEST
					else
						border_escaped_through = pick(NORTH, WEST)
			turf_crossed_by = get_step(last_processed_turf, border_escaped_through)
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled)
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = i
			uncross_scheduled.len = 0
			if(end_of_movement)
				if(border_escaped_through & (NORTH|SOUTH))
					x_pixel_dist_travelled += --pixel_moves_until_crossing_x_border * x_offset
					y_pixel_dist_travelled += --pixel_moves_until_crossing_x_border * y_offset
				else
					x_pixel_dist_travelled += pixel_moves_until_crossing_y_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_y_border * y_offset
				break
			if(scan_a_turf(turf_crossed_by, border_escaped_through))
				last_processed_turf = turf_crossed_by
				if(border_escaped_through & (NORTH|SOUTH)) //Escapes through X.
					x_pixel_dist_travelled += pixel_moves_until_crossing_x_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_x_border * y_offset
				else //Escapes through Y.
					x_pixel_dist_travelled += pixel_moves_until_crossing_y_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_y_border * y_offset
				end_of_movement = i
				break
			if(HAS_TRAIT(turf_crossed_by, TRAIT_TURF_BULLET_MANIPULATION))
				SEND_SIGNAL(turf_crossed_by, COMSIG_TURF_PROJECTILE_MANIPULATED, src)
//				if(HAS_TRAIT_FROM(turf_crossed_by, TRAIT_TURF_BULLET_MANIPULATION, PORTAL_TRAIT))
//					return
				RegisterSignal(turf_crossed_by, COMSIG_TURF_RESUME_PROJECTILE_MOVE, PROC_REF(resume_move))
				return PROJECTILE_FROZEN
			if(turf_crossed_by == original_target_turf && ammo.flags_ammo_behavior & AMMO_EXPLOSIVE)
				last_processed_turf = turf_crossed_by
				ammo.do_at_max_range(turf_crossed_by, src)
				if(border_escaped_through & (NORTH|SOUTH))
					x_pixel_dist_travelled += pixel_moves_until_crossing_x_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_x_border * y_offset
				else
					x_pixel_dist_travelled += pixel_moves_until_crossing_y_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_y_border * y_offset
				end_of_movement = i
				break
			movement_dir -= border_escaped_through //Next scan should come from the other component cardinal direction.
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled) //We are leaving turf_crossed_by now.
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = i
				break
			uncross_scheduled.len = 0
			if(scan_a_turf(next_turf, movement_dir))
				end_of_movement = i
			if(end_of_movement)	//This is a bit overkill to deliver the right animation, but oh well.
				if(border_escaped_through & (NORTH|SOUTH)) //Inverse logic than before. We now want to run the longer distance now.
					x_pixel_dist_travelled += pixel_moves_until_crossing_y_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_y_border * y_offset
				else
					x_pixel_dist_travelled += pixel_moves_until_crossing_x_border * x_offset
					y_pixel_dist_travelled += pixel_moves_until_crossing_x_border * y_offset
				break
			if(ammo.flags_ammo_behavior & AMMO_LEAVE_TURF)
				ammo.on_leave_turf(turf_crossed_by, firer, src)
		if(length_char(uncross_scheduled)) //Time to exit the last turf entered, if the diagonal movement didn't handle it already.
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled)
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = i
				break
			uncross_scheduled.len = 0
			if(end_of_movement)
				break
		if(scan_a_turf(next_turf, movement_dir))
			end_of_movement = i
			break
		if(ammo.flags_ammo_behavior & AMMO_LEAVE_TURF)
			ammo.on_leave_turf(last_processed_turf, firer, src)
		x_pixel_dist_travelled += 32 * x_offset
		y_pixel_dist_travelled += 32 * y_offset
		last_processed_turf = next_turf
		if(HAS_TRAIT(next_turf, TRAIT_TURF_BULLET_MANIPULATION))
			SEND_SIGNAL(next_turf, COMSIG_TURF_PROJECTILE_MANIPULATED, src)
//			if(HAS_TRAIT_FROM(next_turf, TRAIT_TURF_BULLET_MANIPULATION, PORTAL_TRAIT))
//				return
			RegisterSignal(next_turf, COMSIG_TURF_RESUME_PROJECTILE_MOVE, PROC_REF(resume_move))
			return PROJECTILE_FROZEN
		if(next_turf == original_target_turf && ammo.flags_ammo_behavior & AMMO_EXPLOSIVE)
			ammo.on_hit_turf(next_turf, src)
			end_of_movement = i
			break
		if(distance_travelled >= max_range)
			ammo.do_at_max_range(next_turf, src)
			end_of_movement = i
			break

	if(end_of_movement && last_processed_turf == loc)
		last_projectile_move = world.time
		return PROJECTILE_HIT

	apx += x_pixel_dist_travelled
	apy += y_pixel_dist_travelled

	var/new_pixel_x = ABS_PIXEL_TO_REL(apx) //The final pixel offset after this movement. Float value.
	var/new_pixel_y = ABS_PIXEL_TO_REL(apy)

	if(projectile_speed > 5) //At this speed the animation barely shows. Changing the vars through animation alone takes almost 5 times the CPU than setting them directly. No need for that if there's nothing to show for it.
		pixel_x = round(new_pixel_x, 1) - 16
		pixel_y = round(new_pixel_y, 1) - 16
		forceMove(last_processed_turf)
	else //Pixel shifts during the animation, which happens after the fact has happened. Light travels slowly here...
		var/old_pixel_x = new_pixel_x - x_pixel_dist_travelled //The pixel offset relative to the new position of where we came from. Float value.
		var/old_pixel_y = new_pixel_y - y_pixel_dist_travelled
		pixel_x = round(old_pixel_x, 1) - 16 //Projectile's sprite is displaced back to where it came from through relative pixel offset. Integer value.
		pixel_y = round(old_pixel_y, 1) - 16 //We substract 16 because this value should range from 1 to 32, but pixel offset usually ranges within the same tile from -15 to 16 (depending on the sprite).
		if(last_processed_turf != loc)
			forceMove(last_processed_turf)
		animate(src, pixel_x = (round(new_pixel_x, 1) - 16), pixel_y = (round(new_pixel_y, 1) - 16), time = PROJ_ANIMATION_SPEED, flags = ANIMATION_END_NOW) //Then we represent the movement through the animation, which updates the position to the new and correct one.

	last_projectile_move = world.time
	if(end_of_movement) //We hit something ...probably!
		return PROJECTILE_HIT
	return FALSE //No hits ...yet!

// HITSCAN
/obj/item/projectile/proc/projectile_batch_move_hitscan(first_projectile = TRUE)
	var/end_of_movement = FALSE //In batch moves this loop, only if the projectile stopped.
	var/turf/last_processed_turf = loc
	var/list/atom/movable/hitscan_projectile_effect/laser_effects = list()
	while(!end_of_movement)
		distance_travelled++
		//Here we take the projectile's absolute pixel coordinate + the travelled distance and use PROJ_ABS_PIXEL_TO_TURF to first convert it into tile coordinates, and then use those to locate the turf.
		var/turf/next_turf = PROJ_ABS_PIXEL_TO_TURF((apx + (32 * x_offset)), (apy + (32 * y_offset)), z)
		if(!next_turf) //Map limit.
			end_of_movement = TRUE
			break
		apx += 32 * x_offset
		apy += 32 * y_offset

		if(apx % 32 == 0) // This is god damn right awfull, but PROJ_ABS_PIXEL_TO_TURF panic when this happens
			apx += 0.1
		if(apy % 32 == 0)
			apy += 0.1

		if(next_turf == last_processed_turf)
			laser_effects += new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.1, effect_icon, ammo.bullet_color)
			continue //Pixel movement only, didn't manage to change turf.
		var/movement_dir = get_dir(last_processed_turf, next_turf)

		if(ISDIAGONALDIR(movement_dir)) //Diagonal case. We need to check the turf to cross to get there.
			if(!x_offset || !y_offset) //Unless a coder screws up this won't happen. Buf if they do it will cause an infinite processing loop due to division by zero, so better safe than sorry.
				stack_trace("projectile_batch_move called with diagonal movement_dir and offset-lacking. x_offset: [x_offset], y_offset: [y_offset].")
				return PROJECTILE_ERROR
			var/turf/turf_crossed_by
			var/pixel_moves_until_crossing_x_border
			var/pixel_moves_until_crossing_y_border
			var/border_escaped_through
			switch(movement_dir)
				if(NORTHEAST)
					pixel_moves_until_crossing_x_border = CEILING(((33 - ABS_PIXEL_TO_REL(apx)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((33 - ABS_PIXEL_TO_REL(apy)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border) //Escapes vertically.
						border_escaped_through = NORTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border) //Escapes horizontally.
						border_escaped_through = EAST
					else //Escapes both borders at the same time, perfectly diagonal.
						border_escaped_through = pick(NORTH, EAST) //So choose at random to preserve behavior of no purely diagonal movements allowed.
				if(SOUTHEAST)
					pixel_moves_until_crossing_x_border = CEILING(((33 - ABS_PIXEL_TO_REL(apx)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((0 - ABS_PIXEL_TO_REL(apy)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = SOUTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = EAST
					else
						border_escaped_through = pick(SOUTH, EAST)
				if(SOUTHWEST)
					pixel_moves_until_crossing_x_border = CEILING(((0 - ABS_PIXEL_TO_REL(apx)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((0 - ABS_PIXEL_TO_REL(apy)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = SOUTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = WEST
					else
						border_escaped_through = pick(SOUTH, WEST)
				if(NORTHWEST)
					pixel_moves_until_crossing_x_border = CEILING(((0 - ABS_PIXEL_TO_REL(apx)) / x_offset), 1)
					pixel_moves_until_crossing_y_border = CEILING(((33 - ABS_PIXEL_TO_REL(apy)) / y_offset), 1)
					if(pixel_moves_until_crossing_y_border < pixel_moves_until_crossing_x_border)
						border_escaped_through = NORTH
					else if(pixel_moves_until_crossing_x_border < pixel_moves_until_crossing_y_border)
						border_escaped_through = WEST
					else
						border_escaped_through = pick(NORTH, WEST)
			turf_crossed_by = get_step(last_processed_turf, border_escaped_through)
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled)
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = TRUE
				break
			uncross_scheduled.Cut()
			if(end_of_movement)
				break
			if(scan_a_turf(turf_crossed_by, border_escaped_through))
				break
			if(turf_crossed_by == original_target_turf && ammo.flags_ammo_behavior & AMMO_EXPLOSIVE)
				last_processed_turf = turf_crossed_by
				ammo.do_at_max_range(turf_crossed_by, src)
				end_of_movement = TRUE
				break
			if(HAS_TRAIT(turf_crossed_by, TRAIT_TURF_BULLET_MANIPULATION))
				SEND_SIGNAL(turf_crossed_by, COMSIG_TURF_PROJECTILE_MANIPULATED, src)
				QDEL_LIST_IN(laser_effects, 2)
//				if(HAS_TRAIT_FROM(turf_crossed_by, TRAIT_TURF_BULLET_MANIPULATION, PORTAL_TRAIT))
//					return
				forceMove(turf_crossed_by)
				return PROJECTILE_FROZEN
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled) //We are leaving turf_crossed_by now.
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = TRUE
				break
			uncross_scheduled.Cut()
			if(end_of_movement)
				break
			if(ammo.flags_ammo_behavior & AMMO_LEAVE_TURF)
				ammo.on_leave_turf(turf_crossed_by, firer, src)
		if(length(uncross_scheduled)) //Time to exit the last turf entered, if the diagonal movement didn't handle it already.
			for(var/atom/movable/thing_to_uncross as anything in uncross_scheduled)
				if(QDELETED(thing_to_uncross))
					continue
				thing_to_uncross.do_projectile_hit(src)
				end_of_movement = TRUE
				break
			uncross_scheduled.len = 0
			if(end_of_movement)
				break
		if(ammo.flags_ammo_behavior & AMMO_LEAVE_TURF)
			ammo.on_leave_turf(last_processed_turf, firer, src)
		last_processed_turf = next_turf
		if(scan_a_turf(next_turf, movement_dir))
			end_of_movement = TRUE
			break
		if(next_turf == original_target_turf && ammo.flags_ammo_behavior & AMMO_EXPLOSIVE)
			ammo.do_at_max_range(next_turf, src)
			end_of_movement = TRUE
			break
		if(distance_travelled >= max_range)
			ammo.do_at_max_range(next_turf, src)
			end_of_movement = TRUE
			break
		if(HAS_TRAIT(next_turf, TRAIT_TURF_BULLET_MANIPULATION))
			SEND_SIGNAL(next_turf, COMSIG_TURF_PROJECTILE_MANIPULATED, src)
			QDEL_LIST_IN(laser_effects, 2)
//			if(HAS_TRAIT_FROM(turf_crossed_by, TRAIT_TURF_BULLET_MANIPULATION, PORTAL_TRAIT))
//				return
			forceMove(next_turf)
			return PROJECTILE_FROZEN
		if(first_projectile)
			laser_effects += new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.01, "muzzle_"+effect_icon, ammo.bullet_color)
			first_projectile = FALSE
		else
			laser_effects += new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.01, effect_icon, ammo.bullet_color)
	apx -= 8 * x_offset
	apy -= 8 * y_offset

	if(apx % 32 == 0)
		apx += 0.1
	if(apy % 32 == 0)
		apy += 0.1
	if(first_projectile)
		laser_effects += new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.01, "muzzle_"+effect_icon, ammo.bullet_color)
	laser_effects += new /atom/movable/hitscan_projectile_effect(PROJ_ABS_PIXEL_TO_TURF(apx, apy, z), dir_angle, apx % 32 - 16, apy % 32 - 16, 1.01, "impact_"+effect_icon, ammo.bullet_color)
	QDEL_LIST_IN(laser_effects, 2)
//

#undef PROJ_ABS_PIXEL_TO_TURF
#undef PROJ_ANIMATION_SPEED

///Tells the projectile to move again
/obj/item/projectile/proc/resume_move(datum/source)
	SIGNAL_HANDLER
	if(projectile_flags & PROJECTILE_HITSCAN)
		UnregisterSignal(source, COMSIG_TURF_RESUME_PROJECTILE_MOVE)
		projectile_batch_move(FALSE)
		qdel(src)
	else
		if(source)
			UnregisterSignal(source, COMSIG_TURF_RESUME_PROJECTILE_MOVE)
		SSprojectiles.queue_projectile(src)

/obj/item/projectile/proc/scan_a_turf(turf/turf_to_scan, proj_dir)
	if(turf_to_scan && turf_to_scan.density) //Handle wall hit.
		var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

		if(SEND_SIGNAL(src, COMSIG_BULLET_PRE_HANDLE_TURF, turf_to_scan) & COMPONENT_BULLET_PASS_THROUGH)
			return FALSE

		// If the ammo should hit the surface of the target and the next turf is dense
		// The current turf is the "surface" of the target
		if(ammo_flags & AMMO_STRIKES_SURFACE)
			// We "hit" the current turf but strike the actual blockage
			ammo.on_hit_turf(get_turf(src),src)
		else
			ammo.on_hit_turf(turf_to_scan,src)

		if(SEND_SIGNAL(src, COMSIG_BULLET_POST_HANDLE_TURF, turf_to_scan) & COMPONENT_BULLET_PASS_THROUGH)
			return FALSE

		ammo.on_hit_turf(turf_to_scan, src)
		turf_to_scan.bullet_act(src)
		return TRUE

	if(shot_from)
		switch(SEND_SIGNAL(shot_from, COMSIG_PROJ_SCANTURF, turf_to_scan))
			if(COMPONENT_PROJ_SCANTURF_TURFCLEAR)
				return FALSE
			if(COMPONENT_PROJ_SCANTURF_TARGETFOUND)
				original_target.do_projectile_hit(src)
				return TRUE

	// Firer's turf, keep moving
	if(firer && turf_to_scan == firer.loc && !(projectile_flags & PROJECTILE_SHRAPNEL))
		return FALSE
	var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

	var/hit_turf = FALSE
	// Explosive ammo always explodes on the turf of the clicked target
	// So does ammo that's flagged to always hit the target
	if(((ammo_flags & AMMO_EXPLOSIVE) || (ammo_flags & AMMO_HITS_TARGET_TURF)) && turf_to_scan == original_target_turf)
		hit_turf = TRUE

	if(ammo_flags & AMMO_SCANS_NEARBY && proj_dir)
		//this thing scans depending on dir
		var/cardinal_dir = get_perpen_dir(proj_dir)
		if(!cardinal_dir)
			var/d1 = proj_dir&(proj_dir-1)	// eg west	(1+8)&(8) = 8
			var/d2 = proj_dir - d1			// eg north	(1+8) - 8 = 1
			cardinal_dir = list(d1,d2)

		var/remote_detonation = 0
		var/kill_proj = 0

		for(var/ddir in cardinal_dir)
			var/dloc = get_step(turf_to_scan, ddir)
			var/turf/dturf = get_turf(dloc)
			for(var/atom/movable/dA in dturf)
				if(!isliving(dA))
					continue

				var/mob/living/dL = dA
				if(dL.is_dead())
					continue

				if(SEND_SIGNAL(src, COMSIG_BULLET_CHECK_MOB_SKIPPING, dL) & COMPONENT_SKIP_MOB\
					|| runtime_iff_group && dL.ally(runtime_iff_group)\
				)
					continue

				if(ammo_flags & AMMO_SKIPS_ALIENS && isxeno(dL))
					var/mob/living/carbon/xenomorph/X = dL
					var/mob/living/carbon/xenomorph/F = firer

					if(!istype(F))
						continue

					if(F.can_not_harm(X))
						continue

				remote_detonation = 1
				kill_proj = ammo.on_near_target(turf_to_scan, src)
				break

			if(remote_detonation)
				break

		if(kill_proj)
			return TRUE

	// Empty turf, keep moving
	if(!turf_to_scan || (!turf_to_scan.contents.len && !hit_turf))
		return FALSE

	for(var/obj/O in turf_to_scan) //check objects before checking mobs, so that barricades protect
		if(handle_object(O))
			return TRUE

	for(var/mob/living/L in turf_to_scan)
		if(handle_mob(L))
			return TRUE

	if(hit_turf)
		ammo.on_hit_turf(turf_to_scan, src)
		if(turf_to_scan && turf_to_scan.loc)
			turf_to_scan.bullet_act(src)
		return TRUE
	return FALSE

/obj/item/projectile/proc/handle_object(obj/O)
	// If we've already handled this atom, don't do it again
	if(O in permutated)
		return FALSE
	permutated |= O

	var/hit_chance = O.get_projectile_hit_boolean(src)
	if(hit_chance) // Calculated from combination of both ammo accuracy and gun accuracy
		SEND_SIGNAL(src, COMSIG_BULLET_PRE_HANDLE_OBJ, O)
		var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

		// If we are a xeno shooting something
		if(istype(ammo, /datum/ammo/xeno) && isxeno(firer) && ammo.apply_delegate)
			var/mob/living/carbon/xenomorph/X = firer
			if(X.behavior_delegate)
				var/datum/behavior_delegate/MD = X.behavior_delegate
				MD.ranged_attack_additional_effects_target(O)
				MD.ranged_attack_additional_effects_self(O)

		// If the ammo should hit the surface of the target and there is an object blocking
		// The current turf is the "surface" of the target
		if(ammo_flags & AMMO_STRIKES_SURFACE)
			var/turf/T = get_turf(O)

			// We "hit" the current turf but strike the actual blockage
			ammo.on_hit_turf(get_turf(src),src)
			T.bullet_act(src)
		else
			ammo.on_hit_obj(O,src)
			if(O && O.loc)
				O.bullet_act(src)
		. = TRUE

	if(SEND_SIGNAL(src, COMSIG_BULLET_POST_HANDLE_OBJ, O, .) & COMPONENT_BULLET_PASS_THROUGH)
		return FALSE

/obj/item/projectile/proc/handle_mob(mob/living/L)
	// If we've already handled this atom, don't do it again

	if(SEND_SIGNAL(src, COMSIG_BULLET_PRE_HANDLE_MOB, L, .) & COMPONENT_BULLET_PASS_THROUGH)
		return FALSE

	if((MODE_HAS_TOGGLEABLE_FLAG(MODE_NO_ATTACK_DEAD) && L.stat == DEAD) || (L in permutated))
		return FALSE
	permutated |= L
	if((ammo.flags_ammo_behavior & AMMO_XENO) && (isfacehugger(L) || L.stat == DEAD)) //xeno ammo is NEVER meant to hit or damage dead people. If you want to add a xeno ammo that DOES then make a new flag that makes it ignore this check.
		return FALSE

	var/hit_chance = max(L.get_projectile_hit_chance(src), 0)

	if(hit_chance) // Calculated from combination of both ammo accuracy and gun accuracy

		var/hit_roll = rand(1, 100)

		if(original_target != L || hit_roll > hit_chance-base_miss_chance[def_zone])	// If hit roll is high or the firer wasn't aiming at this mob, we still hit but now we might hit the wrong body part
			def_zone = rand_zone()
		else
			SEND_SIGNAL(firer, COMSIG_BULLET_DIRECT_HIT, L)
		hit_chance -= base_miss_chance[def_zone] // Reduce accuracy based on spot.

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([L]) Hit chance: [hit_chance] | Roll: [hit_roll]"))
		#endif

		if(hit_chance > hit_roll)
			#if DEBUG_HIT_CHANCE
			to_world(SPAN_DEBUG("([L]) Hit."))
			#endif
			var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

			// If the ammo should hit the surface of the target and there is a mob blocking
			// The current turf is the "surface" of the target
			if(ammo_flags & AMMO_STRIKES_SURFACE)
				var/turf/T = get_turf(L)

				// We "hit" the current turf but strike the actual blockage
				ammo.on_hit_turf(get_turf(src),src)
				T.bullet_act(src)
			else if(L && L.loc && (L.bullet_act(src) != -1))
				ammo.on_hit_mob(L, src, firer)

				// If we are a xeno shooting something
				if(istype(ammo, /datum/ammo/xeno) && isxeno(firer) && L.stat != DEAD && ammo.apply_delegate)
					var/mob/living/carbon/xenomorph/X = firer
					if(X.behavior_delegate)
						var/datum/behavior_delegate/MD = X.behavior_delegate
						MD.ranged_attack_additional_effects_target(L)
						MD.ranged_attack_additional_effects_self(L)

				// If the thing we're hitting is a Xeno
				if(istype(L, /mob/living/carbon/xenomorph))
					var/mob/living/carbon/xenomorph/X = L
					if(X.behavior_delegate)
						X.behavior_delegate.on_hitby_projectile(ammo)

			. = TRUE
		else if(!L.lying)
			animatation_displace_reset(L)
			if(ammo.sound_miss)
				playsound_client(L.client, ammo.sound_miss, get_turf(L), 75, TRUE)
			L.visible_message(SPAN_AVOIDHARM("[src] misses [L]!"),
				SPAN_AVOIDHARM("[src] narrowly misses you!"), null, 4, CHAT_TYPE_TAKING_HIT)
			var/log_message = "[src] narrowly missed [key_name(L)]"

			var/mob/living/carbon/shotby = firer
			if(istype(shotby))
				L.attack_log += "\[[time_stamp()]\] [src], fired by [key_name(firer)], narrowly missed [key_name(L)]"
				shotby.attack_log += "\[[time_stamp()]\] [src], fired by [key_name(shotby)], narrowly missed [key_name(L)]"
				log_message = "[src], fired by [key_name(firer)], narrowly missed [key_name(L)]"
			log_attack(log_message)

			#if DEBUG_HIT_CHANCE
			to_world(SPAN_DEBUG("([L]) Missed."))
			#endif

	if(SEND_SIGNAL(src, COMSIG_BULLET_POST_HANDLE_MOB, L, .) & COMPONENT_BULLET_PASS_THROUGH)
		return FALSE

//----------------------------------------------------------
				// \\
				//  HITTING THE TARGET  \\
				// \\
				// \\
//----------------------------------------------------------

/atom/proc/do_projectile_hit(obj/item/projectile/proj)
	return

/obj/item/projectile/proc/get_effective_accuracy()
	#if DEBUG_HIT_CHANCE
	to_world(SPAN_DEBUG("Base accuracy is <b>[accuracy]</b>; scatter: <b>[scatter]</b>; distance: <b>[distance_travelled]</b>"))
	#endif

	var/effective_accuracy = accuracy //We want a temporary variable so accuracy doesn't change every time the bullet misses.
	if(distance_travelled <= ammo.accurate_range)
		if(distance_travelled <= ammo.accurate_range_min) // If bullet stays within max accurate range + random variance
			effective_accuracy -= (ammo.accurate_range_min - distance_travelled) * accuracy_range_falloff // Snipers have accuracy falloff at closer range before point blank
	else
		effective_accuracy -= (distance_travelled - ammo.accurate_range) * (ammo.ammo_range_fallof + range_fallof)

	effective_accuracy = max(5, effective_accuracy) //default hit chance is at least 5%.

	if(ishuman(firer))
		var/mob/living/carbon/human/shooter_human = firer
		if(shooter_human.marksman_aura)
			effective_accuracy += shooter_human.marksman_aura * 1.5 //Flat buff of 3 % accuracy per aura level
			effective_accuracy += distance_travelled * 0.35 * shooter_human.marksman_aura //Flat buff to accuracy per tile travelled

	#if DEBUG_HIT_CHANCE
	to_world(SPAN_DEBUG("Final accuracy is <b>[effective_accuracy]</b>"))
	#endif

	return effective_accuracy

//objects use get_projectile_hit_boolean unlike mobs, which use get_projectile_hit_chance
/obj/proc/get_projectile_hit_boolean(obj/item/projectile/projectile)
	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	return TRUE

//Used by machines and structures to calculate shooting past cover
/obj/proc/calculate_cover_hit_boolean(obj/item/projectile/proj, distance = 0, cade_direction_correct = FALSE)
	if(istype(proj.shot_from, /obj/item/hardpoint)) //anything shot from a tank gets a bonus to bypassing cover
		distance -= 3

	if(distance < 1 || (distance > 3 && cade_direction_correct))
		return FALSE

	//an object's "projectile_coverage" var indicates the maximum probability of blocking a projectile
	var/effective_accuracy = proj.get_effective_accuracy()
	var/distance_limit = 6 //number of tiles needed to max out block probability
	var/accuracy_factor = 50 //degree to which accuracy affects probability   (if accuracy is 100, probability is unaffected. Lower accuracies will increase block chance)

	var/hitchance = min(projectile_coverage, (projectile_coverage * distance/distance_limit) + accuracy_factor * (effective_accuracy/100))

	#if DEBUG_HIT_CHANCE
	to_world(SPAN_DEBUG("([name] as cover) Distance travelled: [proj.distance_travelled]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]"))
	#endif

	return prob(hitchance)

/obj/structure/machinery/get_projectile_hit_boolean(obj/item/projectile/proj)
	if(src == proj.original_target && layer > ATMOS_DEVICE_LAYER) //clicking on the object itself hits the object
		var/hitchance = proj.get_effective_accuracy()

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([name]) Distance travelled: [proj.distance_travelled]  |  Effective accuracy: [hitchance]  |  Hit chance: [hitchance]"))
		#endif

		if(prob(hitchance))
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	if(!throwpass)
		return TRUE
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	if(ammo_flags & AMMO_IGNORE_COVER)
		return FALSE

	var/distance = proj.distance_travelled

	if(flags_atom & ON_BORDER) //windoors
		if(proj.dir & reverse_direction(dir))
			distance-- //no bias towards "inner" side
			if(ammo_flags & AMMO_STOPPED_BY_COVER)
				return TRUE
		else if( !(proj.dir & dir) )
			return FALSE //no effect if bullet direction is perpendicular to barricade
	else
		distance--

	return calculate_cover_hit_boolean(proj, distance)


/obj/structure/get_projectile_hit_boolean(obj/item/projectile/proj)
	if(src == proj.original_target && layer > ATMOS_DEVICE_LAYER) //clicking on the object itself hits the object
		var/hitchance = proj.get_effective_accuracy()

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([name]) Distance travelled: [proj.distance_travelled]  |  Effective accuracy: [hitchance]  |  Hit chance: [hitchance]"))
		#endif

		if(prob(hitchance))
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	if(!throwpass)
		return TRUE

	//At this point, all that's left is window frames, tables, and barricades
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	if(ammo_flags & AMMO_IGNORE_COVER && src != proj.original_target)
		return FALSE

	var/distance = proj.distance_travelled

	var/cade_direction_correct = TRUE
	if(flags_atom & ON_BORDER) //barricades, flipped tables
		if(proj.dir & reverse_direction(dir))
			if(ammo_flags & AMMO_STOPPED_BY_COVER)
				return TRUE
			distance-- //no bias towards "inner" side
			cade_direction_correct = FALSE
		else if(!(proj.dir & dir))
			return FALSE //no effect if bullet direction is perpendicular to barricade

	else
		distance--
		if(climbable)
			for(var/obj/structure/S in get_turf(proj))
				if(S && S.climbable && !(S.flags_atom & ON_BORDER)) //if a proj is coming from a window frame or table, it's guaranteed to pass the next window frame/table
					return FALSE
	return calculate_cover_hit_boolean(proj, distance, cade_direction_correct)

/obj/item/do_projectile_hit(obj/item/projectile/proj)
	proj.ammo.on_hit_obj(src, proj)
	if(QDELETED(src)) //on_hit_obj could delete the object
		return
	bullet_act(proj)

/obj/item/get_projectile_hit_boolean(obj/item/projectile/proj)
	if(proj && src == proj.original_target) //clicking on the object itself. Code copied from mob get_projectile_hit_chance
		var/hitchance = proj.get_effective_accuracy()
		switch(w_class) //smaller items are harder to hit
			if(SIZE_TINY)
				hitchance -= 50
			if(SIZE_SMALL)
				hitchance -= 30
			if(SIZE_MEDIUM)
				hitchance -= 20
			if(SIZE_LARGE)
				hitchance -= 10

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([name]) Distance travelled: [proj.distance_travelled]  |  Effective accuracy: [hitchance]  |  Hit chance: [hitchance]"))
		#endif

		if(prob(hitchance))
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	return TRUE


/obj/vehicle/get_projectile_hit_boolean(obj/item/projectile/proj)
	if(src == proj.original_target) //clicking on the object itself hits the object
		var/hitchance = proj.get_effective_accuracy()

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([proj.name]) Distance travelled: [proj.distance_travelled]  |  Effective accuracy: [hitchance]  |  Hit chance: [hitchance]"))
		#endif

		if(prob(hitchance))
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection.
		return FALSE

	return TRUE


/obj/structure/window/get_projectile_hit_boolean(obj/item/projectile/proj)
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	if(ammo_flags & AMMO_ENERGY)
		return FALSE
	else if(!(flags_atom & ON_BORDER) || (proj.dir & dir) || (proj.dir & reverse_direction(dir)))
		return TRUE

/obj/structure/machinery/door/poddoor/railing/get_projectile_hit_boolean(obj/item/projectile/proj)
	return src == proj.original_target

/obj/effect/alien/egg/get_projectile_hit_boolean(obj/item/projectile/proj)
	return src == proj.original_target

/obj/effect/alien/resin/trap/get_projectile_hit_boolean(obj/item/projectile/proj)
	return src == proj.original_target

/obj/item/clothing/mask/facehugger/get_projectile_hit_boolean(obj/item/projectile/proj)
	return src == proj.original_target



//mobs use get_projectile_hit_chance instead of get_projectile_hit_boolean


/mob/living/do_projectile_hit(obj/item/projectile/proj)
	proj.ammo.on_hit_mob(src, proj)
	bullet_act(proj)

/mob/living/carbon/do_projectile_hit(obj/item/projectile/proj)
	. = ..()


/mob/living/proc/get_projectile_hit_chance(obj/item/projectile/proj)
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	if(ammo_flags & AMMO_XENO)
		if((status_flags & XENO_HOST) && HAS_TRAIT(src, TRAIT_NESTED))
			return FALSE

	. = proj.get_effective_accuracy()

	if(src == proj.original_target)
		if(lying)
			if(stat)
				. += 5
			else
				. += 10
		else
			. += 15
	else
		if(lying)
			if(stat)
				. -= 70
			else
				. -= 90
		else
			. -= 50


	if(istype(get_turf(src), /turf/open/trench))
		if(src == proj.original_target)
			. -= 25
		else
			. -= 50

	if(isliving(proj.firer))
		var/mob/living/shooter_living = proj.firer
		if(!can_see(shooter_living, src))
			. -= 25 //Can't see the target (Opaque thing between shooter and target)

/mob/living/carbon/human/get_projectile_hit_chance(obj/item/projectile/proj)
	. = ..()
	if(.)
		var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
		if(SEND_SIGNAL(proj, COMSIG_BULLET_CHECK_MOB_SKIPPING, src) & COMPONENT_SKIP_MOB\
			|| proj.runtime_iff_group && ally(proj.runtime_iff_group)\
		)
			return FALSE
		if(mobility_aura)
			. -= mobility_aura * 5
		var/mob/living/carbon/human/shooter_human = proj.firer
		if(istype(shooter_human))
			if(shooter_human.faction == faction && !(ammo_flags & AMMO_ALWAYS_FF))
				. -= FF_hit_evade

			if(ammo_flags & AMMO_MP)
				if(criminal)
					. += FF_hit_evade
				else
					return FALSE

/mob/living/carbon/xenomorph/get_projectile_hit_chance(obj/item/projectile/proj)
	. = ..()
	if(.)
		var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
		if(SEND_SIGNAL(proj, COMSIG_BULLET_CHECK_MOB_SKIPPING, src) & COMPONENT_SKIP_MOB\
			|| proj.runtime_iff_group && ally(proj.runtime_iff_group))
			return FALSE

		if(ammo_flags & AMMO_SKIPS_ALIENS)
			var/mob/living/carbon/xenomorph/X = proj.firer
			if(!istype(X))
				return FALSE
			if(X.faction == faction)
				return FALSE

		if(mob_size >= MOB_SIZE_BIG)
			. += 10
		if(evasion > 0)
			. -= evasion

/mob/living/silicon/robot/drone/get_projectile_hit_chance(obj/item/projectile/proj)
	return FALSE // just stop them getting hit by projectiles completely


/obj/item/projectile/proc/play_hit_effect(mob/hit_mob)
	if(ammo.sound_hit)
		playsound(hit_mob, ammo.sound_hit, 50, 1)
	if(hit_mob.stat != DEAD && !isnull(hit_effect_color))
		animation_flash_color(hit_mob, hit_effect_color)

/obj/item/projectile/proc/play_shielded_hit_effect(mob/hit_mob)
	if(ammo.sound_shield_hit)
		playsound(hit_mob, ammo.sound_shield_hit, 50, 1)
	if(hit_mob.stat != DEAD && !isnull(hit_effect_color))
		animation_flash_color(hit_mob, hit_effect_color)

//----------------------------------------------------------
				// \\
				// OTHER PROCS \\
				// \\
				// \\
//----------------------------------------------------------

/atom/proc/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	return FALSE

/mob/dead/bullet_act(/obj/item/projectile/proj)
	return FALSE

/mob/living/bullet_act(obj/item/projectile/proj)
	if(!proj)
		return

	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	var/damage = proj.calculate_damage()
	if(proj.ammo.debilitate && stat != DEAD && (damage || (ammo_flags & AMMO_IGNORE_RESIST)))
		apply_effects(arglist(proj.ammo.debilitate))

	. = TRUE
	if(damage)
		bullet_message(proj)
		apply_damage(damage, proj.ammo.damage_type, proj.def_zone, 0, 0, proj)
		proj.play_hit_effect(src)

	SEND_SIGNAL(proj, COMSIG_BULLET_ACT_LIVING, src, damage, damage)


/mob/living/carbon/human/bullet_act(obj/item/projectile/proj)
	if(!proj)
		return

	if(isxeno(proj.firer))
		var/mob/living/carbon/xenomorph/X = proj.firer
		if(X.can_not_harm(src))
			bullet_ping(proj)
			return -1

	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	var/mob/shoot_mob
	if(proj.weapon_cause_data)
		shoot_mob = proj.weapon_cause_data.resolve_mob()

	if(shoot_mob)
		shoot_mob.track_shot_hit(proj.weapon_cause_data.cause_name, src)

	var/damage = proj.calculate_damage()
	var/damage_result = damage

	if(SEND_SIGNAL(src, COMSIG_HUMAN_PRE_BULLET_ACT, proj) & COMPONENT_CANCEL_BULLET_ACT)
		return

	flash_weak_pain()
	if(proj.ammo.stamina_damage)
		apply_stamina_damage(proj.ammo.stamina_damage, proj.def_zone, ARMOR_ENERGY) // Stamina damage is energy

	//Shields
	if(!(ammo_flags & AMMO_ROCKET)) //No, you can't block rockets.
		if(prob(75) && check_shields(damage * 0.65, "[proj]") ) // Lower chance to block bullets
			proj.ammo.on_shield_block(src)
			bullet_ping(proj)
			return

	var/obj/limb/organ = get_limb(check_zone(proj.def_zone)) //Let's finally get what organ we actually hit.
	if(!organ)
		return//Nope. Gotta shoot something!

	//Run armor check. We won't bother if there is no damage being done.
	if(damage > 0 && !(ammo_flags & AMMO_IGNORE_ARMOR))
		var/armor //Damage types don't correspond to armor types. We are thus merging them.
		switch(proj.ammo.damage_type)
			if(BRUTE)
				if(ammo_flags & AMMO_ROCKET)
					armor = getarmor_organ(organ, ARMOR_BOMB)
				else
					armor = getarmor_organ(organ, ARMOR_BULLET)
			if(BURN)
				if(ammo_flags & AMMO_ENERGY)
					armor = getarmor_organ(organ, ARMOR_ENERGY)
				else if(ammo_flags & AMMO_LASER)
					armor = getarmor_organ(organ, ARMOR_LASER)
				else
					armor = getarmor_organ(organ, ARMOR_BIO)
			if(TOX, OXY, CLONE)
				armor = getarmor_organ(organ, ARMOR_BIO)
			else
				armor = getarmor_organ(organ, ARMOR_ENERGY) //Won't be used, but just in case.

		damage_result = armor_damage_reduction(GLOB.marine_ranged, damage, armor, proj.ammo.penetration)
		if(damage_result <= 5)
			to_chat(src,SPAN_XENONOTICE("Your armor absorbs the force of [proj]!"))
		if(damage_result <= 3)
			damage_result = 0
			bullet_ping(proj)
			visible_message(SPAN_AVOIDHARM("[src]'s armor deflects [proj]!"))
			if(proj.ammo.sound_armor)
				playsound(src, proj.ammo.sound_armor, 50, 1)

	if(proj.ammo.debilitate && stat != DEAD && ( damage || ( ammo_flags & AMMO_IGNORE_RESIST) ) )  //They can't be dead and damage must be inflicted (or it's a xeno toxin).
		//Predators and synths are immune to these effects to cut down on the stun spam. This should later be moved to their apply_effects proc, but right now they're just humans.
		if(!isspeciesyautja(src) && !isspeciessynth(src))
			apply_effects(arglist(proj.ammo.debilitate))

	bullet_message(proj) //We still want this, regardless of whether or not the bullet did damage. For griefers and such.

	if(SEND_SIGNAL(src, COMSIG_HUMAN_BULLET_ACT, damage_result, ammo_flags, proj) & COMPONENT_CANCEL_BULLET_ACT)
		return

	proj.play_hit_effect(src)
	if(damage || (ammo_flags & AMMO_SPECIAL_EMBED))
		var/splatter_dir = get_dir(proj.starting_turf, loc)
		handle_blood_splatter(splatter_dir)
		. = TRUE
		apply_damage(damage_result, proj.ammo.damage_type, proj.def_zone, firer = proj.firer)

		if(proj.ammo.shrapnel_chance > 0 && prob(proj.ammo.shrapnel_chance + round(damage / 10)))
			if(ammo_flags & AMMO_SPECIAL_EMBED)
				proj.ammo.on_embed(src, organ)

			var/obj/item/shard/shrapnel/new_embed = new proj.ammo.shrapnel_type
			var/obj/item/large_shrapnel/large_embed = new proj.ammo.shrapnel_type
			if(istype(large_embed))
				large_embed.on_embed(src, organ)
			if(istype(new_embed))
				var/found_one = FALSE
				for(var/obj/item/shard/shrapnel/S in embedded_items)
					if(S.name == new_embed.name)
						S.count++
						qdel(new_embed)
						found_one = TRUE
						break

				if(!found_one)
					new_embed.on_embed(src, organ)

				if(!stat && pain.feels_pain)
					emote("scream")
					to_chat(src, SPAN_HIGHDANGER("You scream in pain as the impact sends <B>shrapnel</b> into the wound!"))

	if(shoot_mob)
		shoot_mob.track_damage(proj.weapon_cause_data.cause_name, src, damage)
		if(shoot_mob.faction == faction)
			shoot_mob.track_friendly_damage(proj.weapon_cause_data.cause_name, src, damage)

	SEND_SIGNAL(proj, COMSIG_POST_BULLET_ACT_HUMAN, src, damage, damage_result)

//Deal with xeno bullets.
/mob/living/carbon/xenomorph/bullet_act(obj/item/projectile/proj)
	if(!proj || !istype(proj))
		return

	var/damage = proj.calculate_damage()
	var/damage_result = damage
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	var/mob/shoot_mob
	if(proj.weapon_cause_data)
		shoot_mob = proj.weapon_cause_data.resolve_mob()

	if((ammo_flags & AMMO_FLAME) && (src.caste.fire_immunity & FIRE_IMMUNITY_NO_IGNITE|FIRE_IMMUNITY_NO_DAMAGE))
		to_chat(src, SPAN_AVOIDHARM("You shrug off the glob of flame."))
		return

	if(isxeno(proj.firer))
		var/mob/living/carbon/xenomorph/X = proj.firer
		if(X.can_not_harm(src))
			bullet_ping(proj)
			return -1
		else
			damage *= XVX_PROJECTILE_DAMAGEMULT
			damage_result = damage

	if(shoot_mob)
		shoot_mob.track_shot_hit(proj.weapon_cause_data.cause_name, src)

	flash_weak_pain()

	if(damage > 0 && !(ammo_flags & AMMO_IGNORE_ARMOR))
		var/armor = armor_deflection + armor_deflection_buff - armor_deflection_debuff

		var/list/damagedata = list(
			"damage" = damage,
			"armor" = armor,
			"penetration" = proj.ammo.penetration,
			"armour_break_pr_pen" = proj.ammo.pen_armor_punch,
			"armour_break_flat" = proj.ammo.damage_armor_punch,
			"armor_integrity" = armor_integrity,
			"direction" = proj.dir,
		)
		SEND_SIGNAL(src, COMSIG_XENO_PRE_CALCULATE_ARMOURED_DAMAGE_PROJECTILE, damagedata)
		damage_result = armor_damage_reduction(GLOB.xeno_ranged, damagedata["damage"],
			damagedata["armor"], damagedata["penetration"], damagedata["armour_break_pr_pen"],
			damagedata["armour_break_flat"], damagedata["armor_integrity"])

		var/armor_punch = armor_break_calculation(GLOB.xeno_ranged, damagedata["damage"],
			damagedata["armor"], damagedata["penetration"], damagedata["armour_break_pr_pen"],
			damagedata["armour_break_flat"], damagedata["armor_integrity"])

		apply_armorbreak(armor_punch)

		if(damage <= 3)
			damage = 0
			bullet_ping(proj)

	bullet_message(proj) //Message us about the bullet, since damage was inflicted.



	if(SEND_SIGNAL(src, COMSIG_XENO_BULLET_ACT, damage_result, ammo_flags, proj) & COMPONENT_CANCEL_BULLET_ACT)
		return

	if(damage)
		//only apply the blood splatter if we do damage
		if(shoot_mob)
			shoot_mob.track_damage(proj.weapon_cause_data.cause_name, src, damage)
			if(shoot_mob.faction == faction)
				shoot_mob.track_friendly_damage(proj.weapon_cause_data.cause_name, src, damage)
		handle_blood_splatter(get_dir(proj.starting_turf, loc))

		apply_damage(damage_result, proj.ammo.damage_type, proj.def_zone)	//Deal the damage.
		if(xeno_shields.len)
			proj.play_shielded_hit_effect(src)
		else
			proj.play_hit_effect(src)
		if(!stat && prob(5 + round(damage_result / 4)))
			var/pain_emote = prob(70) ? "hiss" : "roar"
			emote(pain_emote)
		updatehealth()

	SEND_SIGNAL(proj, COMSIG_BULLET_ACT_XENO, src, damage, damage_result)

	return TRUE

/turf/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_TURF_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return

	if(!proj || !density)
		return //It's just an empty turf

	bullet_ping(proj)

	var/list/mobs_list = list() //Let's built a list of mobs on the bullet turf and grab one.
	for(var/mob/living/L in src)
		if(L in proj.permutated)
			continue
		var/chance_hit = max(L.get_projectile_hit_chance(proj), 0)
		if(prob(chance_hit))
			mobs_list += L

	if(length(mobs_list))
		var/mob/living/picked_mob = pick(mobs_list) //Hit a mob, if there is one.
		if(istype(picked_mob))
			picked_mob.bullet_act(proj)
			return
	return

// walls can get shot and damaged, but bullets (vs energy guns) do much less.
/turf/closed/wall/bullet_act(obj/item/projectile/proj)
	. = ..()
	var/damage = proj.damage
	if(damage < 1)
		return
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags

	switch(proj.ammo.damage_type)
		if(BRUTE) //Rockets do extra damage to walls.
			if(ammo_flags & AMMO_ROCKET)
				damage = round(damage * 10)
		if(BURN)
			if(ammo_flags & AMMO_ENERGY)
				damage = round(damage * 7)
			else if(ammo_flags & AMMO_ANTISTRUCT) // Railgun does extra damage to turfs
				damage = round(damage * ANTISTRUCT_DMG_MULT_WALL)
	if(ammo_flags & AMMO_BALLISTIC)
		current_bulletholes++
	take_damage(damage, proj.firer)

/turf/closed/wall/almayer/research/containment/bullet_act(obj/item/projectile/proj)
	if(proj)
		var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
		if(ammo_flags & AMMO_ACIDIC)
			return //immune to acid spit
	. = ..()




//Hitting an object. These are too numerous so they're staying in their files.
//Why are there special cases listed here? Oh well, whatever. ~N
/obj/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	if(proj.ammo.damage_type == HALLOSS || proj.ammo.damage_type == TOX || proj.ammo.damage_type == CLONE || proj.damage == 0)
		return FALSE
	bullet_ping(proj)
	if(proj.ammo.damage)
		update_health(round(proj.ammo.damage / 2))
	return TRUE


// ITEMS BULLET ACTS //
/obj/item/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	if(proj.ammo.damage_type == BRUTE)
		explosion_throw(proj.damage/2, proj.dir, 4)
	return TRUE


// STRUCTURES BULLET ACTS //
/obj/structure/surface/table/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	health -= round(proj.damage/2)
	if(health < 0)
		visible_message(SPAN_WARNING("[src] breaks down!"))
		deconstruct()
	return TRUE

/obj/structure/machinery/disposal/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	return FALSE

/obj/structure/machinery/cm_vending/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	return FALSE

/obj/structure/machinery/door/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	if(proj.damage)
		if(proj.ammo.flags_ammo_behavior & AMMO_ROCKET)
			take_damage(proj.damage * 4, proj.firer) // rockets wreck airlocks
			return TRUE
		else
			take_damage(proj.damage, proj.firer)
			return TRUE
	return FALSE

/obj/structure/machinery/door/window/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	if(proj.ammo.damage)
		take_damage(round(proj.ammo.damage / 2))
		if(proj.ammo.damage_type == BRUTE)
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 25, 1)
	return TRUE

/obj/structure/machinery/telecomms/relay/preset/tower/bullet_act(obj/item/projectile/proj)
	..()
	if(istype(proj.ammo, /datum/ammo/xeno/boiler_gas))
		update_health(50)

	else if(proj.ammo.flags_ammo_behavior & AMMO_ANTISTRUCT)
		update_health(proj.damage*ANTISTRUCT_DMG_MULT_BARRICADES)

	update_health(round(proj.damage/2))
	return TRUE

/obj/structure/fence/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	//Tasers and the like should not damage windows.
	var/ammo_flags = proj.ammo.flags_ammo_behavior | proj.projectile_override_flags
	if(proj.ammo.damage_type == HALLOSS || proj.damage <= 0 || ammo_flags == AMMO_ENERGY)
		return FALSE

	health -= proj.damage * 0.3
	..()
	healthcheck()
	return TRUE

/obj/structure/window_frame/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	bullet_ping(proj)
	take_damage(proj.damage)
	return TRUE

/obj/structure/machinery/door/poddoor/railing/bullet_act(obj/item/projectile/proj)
	if(SEND_SIGNAL(proj, COMSIG_ATOM_BULLET_ACT, src) & COMPONENT_BULLET_ACT_OVERRIDE)
		return FALSE
	return FALSE


//----------------------------------------------------------
					// \\
					// OTHER PROCS \\
					// \\
					// \\
//----------------------------------------------------------


//This is where the bullet bounces off.
/atom/proc/bullet_ping(obj/item/projectile/proj, pixel_x_offset = 0, pixel_y_offset = 0)
	SEND_SIGNAL(proj, COMSIG_BULLET_PING_ACT, src)
	if(!proj || !proj.ammo.ping)
		return

	if(proj.ammo.sound_bounce)
		playsound(src, proj.ammo.sound_bounce, 50, 1)
	var/image/I = image('icons/obj/items/weapons/projectiles.dmi', src, proj.ammo.ping, 10, pixel_x = pixel_x_offset, pixel_y = pixel_y_offset)
	var/angle = (proj.firer && prob(60)) ? round(Get_Angle(proj.firer, src)) : proj.dir_angle
	I.pixel_x += rand(-6,6)
	I.pixel_y += rand(-6,6)

	var/matrix/rotate = matrix()
	rotate.Turn(angle)
	I.transform = rotate
	// Need to do this in order to prevent the ping from being deleted
	addtimer(CALLBACK(I, TYPE_PROC_REF(/image, flick_overlay), src, 3), 1)

/mob/proc/bullet_message(obj/item/projectile/proj)
	if(!proj)
		return
	visible_message(SPAN_DANGER("[src] is hit by the [proj.name] in the [parse_zone(proj.def_zone)]!"), \
		SPAN_HIGHDANGER("You are hit by the [proj.name] in the [parse_zone(proj.def_zone)]!"), null, 4, CHAT_TYPE_TAKING_HIT)

	last_damage_data = proj.weapon_cause_data
	if(proj.firer && ismob(proj.firer))
		var/mob/firingMob = proj.firer
		var/area/A = get_area(src)
		if(ishuman(firingMob) && ishuman(src) && faction == firingMob.faction && !A?.statistic_exempt) //One human shot another, be worried about it but do everything basically the same //special_role should be null or an empty string if done correctly
			if(!istype(proj.ammo, /datum/ammo/energy/taser))
				var/ff_msg = "[key_name(firingMob)] shot [key_name(src)] with \a [proj.name] in [get_area(firingMob)]"
				var/ffl = "[ADMIN_JMP(firingMob)] [ADMIN_PM(firingMob)]"
				var/ff_living = TRUE
				if(src.stat == DEAD)
					ff_living = FALSE
				msg_admin_ff("[ff_msg] [ffl]", ff_msg, ff_living)
				if(ishuman(firingMob) && proj.weapon_cause_data)
					var/mob/living/carbon/human/H = firingMob
					H.track_friendly_fire(proj.weapon_cause_data.cause_name)
			else
				msg_admin_attack("[key_name(firingMob)] tased [key_name(src)] in [get_area(firingMob)] ([firingMob.x],[firingMob.y],[firingMob.z]).", firingMob.x, firingMob.y, firingMob.z)
		else
			msg_admin_attack("[key_name(firingMob)] shot [key_name(src)] with \a [proj.name] in [get_area(firingMob)] ([firingMob.x],[firingMob.y],[firingMob.z]).", firingMob.x, firingMob.y, firingMob.z)
		attack_log += "\[[time_stamp()]\] <b>[key_name(firingMob)]</b> shot <b>[key_name(src)]</b> with \a <b>[proj]</b> in [get_area(firingMob)]."
		firingMob.attack_log += "\[[time_stamp()]\] <b>[key_name(firingMob)]</b> shot <b>[key_name(src)]</b> with \a <b>[proj]</b> in [get_area(firingMob)]."
		return

	attack_log += "\[[time_stamp()]\] <b>SOMETHING??</b> shot <b>[key_name(src)]</b> with a <b>[proj]</b>"
	msg_admin_attack("SOMETHING?? shot [key_name(src)] with a [proj] in [get_area(src)] ([loc.x],[loc.y],[loc.z]).", loc.x, loc.y, loc.z)

//Abby -- Just check if they're 1 tile horizontal or vertical, no diagonals
/proc/get_adj_simple(atom/Loc1,atom/Loc2)
	var/dx = Loc1.x - Loc2.x
	var/dy = Loc1.y - Loc2.y

	if(dx == 0) //left or down of you
		if(dy == -1 || dy == 1)
			return TRUE
	if(dy == 0) //above or below you
		if(dx == -1 || dx == 1)
			return TRUE

/obj/item/projectile/vulture
	accuracy_range_falloff = 10
	/// The odds of hitting a xeno in less than your gun's range. Doesn't apply to humans.
	var/xeno_shortrange_chance = 10

/obj/item/projectile/vulture/Initialize(mapload, datum/cause_data/cause_data)
	. = ..()
	RegisterSignal(src, COMSIG_GUN_VULTURE_FIRED_ONEHAND, PROC_REF(on_onehand))

/obj/item/projectile/vulture/handle_mob(mob/living/hit_mob)
	if((ammo.accurate_range_min > distance_travelled) && isxeno(hit_mob))
		if(prob(xeno_shortrange_chance))
			return ..()

		permutated |= hit_mob
		return

	return ..()

/// Handler for when the user one-hands the firing gun
/obj/item/projectile/vulture/proc/on_onehand(datum/source)
	SIGNAL_HANDLER

	accuracy = HIT_ACCURACY_TIER_2 // flat 10% chance if you're desperate and try to fire this thing without a bipod

#undef DEBUG_HIT_CHANCE
#undef DEBUG_HUMAN_DEFENSE
#undef DEBUG_XENO_DEFENSE
