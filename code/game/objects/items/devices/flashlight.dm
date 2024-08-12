/obj/item/device/flashlight
	name = "flashlight"
	desc = "A hand-held emergency light."
	icon = 'icons/obj/items/lighting.dmi'
	icon_state = "flashlight"
	item_state = "flashlight"
	w_class = SIZE_SMALL
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_WAIST

	matter = list("metal" = 50,"glass" = 20)

	var/activation_sound = 'sound/handling/flashlight.ogg'
	actions_types = list(/datum/action/item_action)

	light_system = MOVABLE_LIGHT
	light_range = 5
	light_power = 0.5
	light_color = COLOR_WHITE
	light_on = FALSE

	var/raillight_compatible = TRUE //Can this be turned into a rail light ?
	var/toggleable = TRUE

	var/can_be_broken = TRUE //can xenos swipe at this to break it/turn it off?
	var/breaking_sound = 'sound/handling/click_2.ogg' //sound used when this happens

/obj/item/device/flashlight/Initialize()
	. = ..()
	if(light_on)
		turn_light(null, light_on)
		update_icon()

/obj/item/device/flashlight/turn_light(mob/user, toggle_on, cooldown = 1 SECONDS, sparks = FALSE, forced = FALSE, light_again = FALSE)
	. = ..()
	if(. != CHECKS_PASSED)
		return
	if(!user && ismob(loc))
		user = loc
	set_light_on(toggle_on)
	update_icon()
	for(var/datum/action/action in actions)
		action.update_button_icon()

/obj/item/device/flashlight/pickup(mob/living/M)
	RegisterSignal(M, COMSIG_ATOM_OFF_LIGHT, TYPE_PROC_REF(/atom, turn_light), FALSE, override = TRUE)
	..()

/obj/item/device/flashlight/dropped(mob/living/M)
	UnregisterSignal(M, COMSIG_ATOM_OFF_LIGHT)
	..()

/obj/item/device/flashlight/update_icon()
	. = ..()
	if(light_on)
		icon_state = "[initial(icon_state)]-on"
	else
		icon_state = initial(icon_state)

/obj/item/device/flashlight/attack_self(mob/user)
	..()

	if(!toggleable)
		to_chat(user, SPAN_WARNING("You cannot toggle \the [src.name] on or off."))
		return FALSE

	if(!isturf(user.loc))
		to_chat(user, SPAN_WARNING("You cannot turn the light [light_on ? "off" : "on"] while in [user.loc].")) //To prevent some lighting anomalies.
		return FALSE

	if(activation_sound && turn_light(user, !light_on))
		playsound(get_turf(src), activation_sound, 15, 1)

	return TRUE

/obj/item/device/flashlight/attackby(obj/item/I as obj, mob/user as mob)
	if(HAS_TRAIT(I, TRAIT_TOOL_SCREWDRIVER))
		if(!raillight_compatible) //No fancy messages, just no
			return
		if(light_on)
			to_chat(user, SPAN_WARNING("Turn off [src] first."))
			return
		if(isstorage(loc))
			var/obj/item/storage/S = loc
			S.remove_from_storage(src)
		if(loc == user)
			user.drop_inv_item_on_ground(src) //This part is important to make sure our light sources update, as it calls dropped()
		var/obj/item/attachable/flashlight/F = new(src.loc)
		user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
		to_chat(user, SPAN_NOTICE("You modify [src]. It can now be mounted on a weapon."))
		to_chat(user, SPAN_NOTICE("Use a screwdriver on [F] to change it back."))
		qdel(src) //Delete da old flashlight
		return
	else
		..()

/obj/item/device/flashlight/attack(mob/living/M as mob, mob/living/user as mob)
	add_fingerprint(user)
	if(light_on && user.zone_selected == "eyes")

		if((user.getBrainLoss() >= 60) && prob(50)) //too dumb to use flashlight properly
			return ..() //just hit them in the head

		if((!ishuman(user) || SSticker) && SSticker.mode.name != "monkey") //don't have dexterity
			to_chat(user, SPAN_NOTICE("You don't have the dexterity to do this!"))
			return

		var/mob/living/carbon/human/H = M //mob has protective eyewear
		if(ishuman(H) && ((H.head && H.head.flags_inventory & COVEREYES) || (H.wear_mask && H.wear_mask.flags_inventory & COVEREYES) || (H.glasses && H.glasses.flags_inventory & COVEREYES)))
			to_chat(user, SPAN_NOTICE("You're going to need to remove that [(H.head && H.head.flags_inventory & COVEREYES) ? "helmet" : (H.wear_mask && H.wear_mask.flags_inventory & COVEREYES) ? "mask": "glasses"] first."))
			return

		if(M == user) //they're using it on themselves
			M.flash_eyes()
			M.visible_message(SPAN_NOTICE("[M] directs [src] to \his eyes."), \
							SPAN_NOTICE("You wave the light in front of your eyes! Trippy!"))
			return

		user.visible_message(SPAN_NOTICE("[user] directs [src] to [M]'s eyes."), \
							SPAN_NOTICE("You direct [src] to [M]'s eyes."))

		if(istype(M, /mob/living/carbon/human)) //robots and aliens are unaffected
			if(M.stat == DEAD || M.sdisabilities & DISABILITY_BLIND) //mob is dead or fully blind
				to_chat(user, SPAN_NOTICE("[M] pupils does not react to the light!"))
			else //they're okay!
				M.flash_eyes()
				to_chat(user, SPAN_NOTICE("[M]'s pupils narrow."))
	else
		return ..()

/obj/item/device/flashlight/attack_alien(mob/living/carbon/xenomorph/M)
	. = ..()

	if(light_on && can_be_broken)
		if(breaking_sound)
			playsound(src.loc, breaking_sound, 25, 1)
		turn_light(null, FALSE, 1 SECONDS, FALSE, TRUE)

/obj/item/device/flashlight/on
	light_on = TRUE

/obj/item/device/flashlight/pen
	name = "penlight"
	desc = "A pen-sized light, used by medical staff."
	icon_state = "penlight"
	item_state = ""
	flags_atom = FPRINT|CONDUCT
	light_range = 2
	w_class = SIZE_TINY
	raillight_compatible = 0

/obj/item/device/flashlight/drone
	name = "low-power flashlight"
	desc = "A miniature lamp, that might be used by small robots."
	icon_state = "penlight"
	item_state = ""
	light_range = 2
	w_class = SIZE_TINY
	raillight_compatible = 0

//The desk lamps are a bit special
/obj/item/device/flashlight/lamp
	name = "desk lamp"
	desc = "A desk lamp with an adjustable mount."
	icon_state = "lamp"
	item_state = "lamp"
	light_range = 5
	light_on = TRUE
	w_class = SIZE_LARGE
	raillight_compatible = 0
	breaking_sound = 'sound/effects/Glasshit.ogg'

//Menorah!
/obj/item/device/flashlight/lamp/menorah
	name = "Menorah"
	desc = "For celebrating Chanukah."
	icon_state = "menorah"
	item_state = "menorah"
	light_range = 2
	w_class = SIZE_LARGE
	light_on = TRUE
	breaking_sound = null

//Generic Candelabra
/obj/item/device/flashlight/lamp/candelabra
	name = "candelabra"
	desc = "A fire hazard that can be used to thwack things with impunity."
	icon_state = "candelabra"
	force = 15
	light_on = TRUE

	breaking_sound = null

//Green-shaded desk lamp
/obj/item/device/flashlight/lamp/green
	desc = "A classic green-shaded desk lamp."
	icon_state = "lampgreen"
	item_state = "lampgreen"
	light_range = 5

/obj/item/device/flashlight/lamp/tripod
	name = "tripod lamp"
	desc = "An emergency light tube mounted onto a tripod. It seemingly lasts forever."
	icon_state = "tripod_lamp"
	light_range = 6//pretty good
	w_class = SIZE_LARGE
	light_on = TRUE

/obj/item/device/flashlight/lamp/tripod/grey
	icon_state = "tripod_lamp_grey"

/obj/item/device/flashlight/lamp/verb/toggle_light()
	set name = "Toggle light"
	set category = "Object"
	set src in oview(1)

	if(istype(usr, /mob/living/carbon/xenomorph)) //Sneaky xenos turning off the lights
		attack_alien(usr)
		return

	if(!usr.stat)
		attack_self(usr)

// FLARES

/obj/item/device/flashlight/flare
	name = "flare"
	desc = "A red USCM issued flare. There are instructions on the side, it reads 'pull cord, make light'."
	w_class = SIZE_SMALL
	light_power = 2
	light_range = 7
	light_color = COLOR_RED_LIGHT
	icon_state = "flare"
	item_state = "flare"
	actions = list() //just pull it manually, neckbeard.
	raillight_compatible = 0
	can_be_broken = FALSE
	var/burnt_out = FALSE
	var/fuel = 0
	var/fuel_rate = AMOUNT_PER_TIME(1 SECONDS, 1 SECONDS)
	var/on_damage = 7
	var/ammo_datum = /datum/ammo/flare

	/// Whether to use flame overlays for this flare type
	var/show_flame = TRUE
	/// Tint for the greyscale flare flame
	var/flame_tint = "#ffcccc"
	/// Color correction, added to the whole flame overlay
	var/flame_base_tint = "#ff0000"
	// "But, why are there two colors?"
	// The flame_tint is applied multiplicatively to the greyscale animation
	// However it represents levels within the flame, not the color of the flame as a whole.
	// To get around this, we additively apply flame_base_tint for coloring.

/obj/item/device/flashlight/flare/Initialize()
	. = ..()
	fuel = rand(9.5 MINUTES, 12.5 MINUTES)
	ammo_datum = GLOB.ammo_list[ammo_datum]
	if(light_on)
		turn_light(null, TRUE)

/obj/item/device/flashlight/flare/update_icon()
	overlays?.Cut()
	. = ..()
	if(light_on)
		icon_state = "[initial(icon_state)]-on"
		if(show_flame)
			var/image/flame = image('icons/obj/items/lighting.dmi', src, "flare_flame")
			flame.color = flame_tint
			flame.appearance_flags = KEEP_APART|RESET_COLOR|RESET_TRANSFORM
			var/image/flame_base = image('icons/obj/items/lighting.dmi', src, "flare_flame")
			flame_base.color = flame_base_tint
			flame_base.appearance_flags = KEEP_APART|RESET_COLOR
			flame_base.blend_mode = BLEND_ADD
			flame.overlays += flame_base
			overlays += flame
	else if(burnt_out)
		icon_state = "[initial(icon_state)]-empty"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/device/flashlight/flare/pickup(mob/living/M)
	if(transform)
		apply_transform(matrix()) // reset rotation
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(M, COMSIG_ATOM_OFF_LIGHT, PROC_REF(burn_out))
	return ..()

/obj/item/device/flashlight/flare/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_ATOM_OFF_LIGHT)
	if(iscarbon(user) && light_on)
		var/mob/living/carbon/flare_user = user
		flare_user.toggle_throw_mode(THROW_MODE_OFF)

/obj/item/device/flashlight/flare/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

// Causes flares to stop with a rotation offset for visual purposes
/obj/item/device/flashlight/flare/animation_spin(speed = 5, loop_amount = -1, clockwise = TRUE, sections = 3, angular_offset = 0, pixel_fuzz = 0)
	clockwise = pick(TRUE, FALSE)
	angular_offset = rand(360)
	pixel_fuzz = 16
	return ..()

/obj/item/device/flashlight/flare/proc/burn_out()
	turn_light(null, FALSE, 0, FALSE, TRUE)
	fuel = 0
	burnt_out = TRUE

/obj/item/device/flashlight/flare/turn_light(mob/user, toggle_on, cooldown = 0, sparks = FALSE, forced = FALSE, light_again = FALSE)
	. = ..()
	if(. != CHECKS_PASSED)
		return
	if(toggle_on)
		light_on = TRUE
		force = on_damage
		damtype = "fire"
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)
		fuel = 0
		burnt_out = TRUE
		force = initial(force)
		damtype = initial(damtype)
		update_icon()

/obj/item/device/flashlight/flare/process(delta_time)
	fuel -= fuel_rate * delta_time
	if(fuel <= 0 || !light_on)
		burn_out()

/obj/item/device/flashlight/flare/attack_self(mob/living/user)

	// Usual checks
	if(!fuel)
		to_chat(user, SPAN_NOTICE("It's out of fuel."))
		return FALSE
	if(light_on)
		if(!do_after(user, 2.5 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE, src, INTERRUPT_MOVED, BUSY_ICON_HOSTILE))
			return
		if(!light_on)
			return
		var/hand = user.hand ? "l_hand" : "r_hand"
		user.visible_message(SPAN_WARNING("[user] snuffs out [src]."),\
		SPAN_WARNING("You snuff out [src], singing your hand."))
		user.apply_damage(7, BURN, hand)
		burn_out()
		//TODO: add snuff out sound so guerilla CLF snuffing flares get noticed
		return

	. = ..()
	// All good, turn it on.
	if(.)
		user.visible_message(SPAN_NOTICE("[user] activates the flare."), SPAN_NOTICE("You pull the cord on the flare, activating it!"))
		playsound(src,'sound/handling/flare_activate_2.ogg', 50, 1) //cool guy sound
		turn_light(null, TRUE)
		var/mob/living/carbon/U = user
		if(istype(U) && !U.throw_mode)
			U.toggle_throw_mode(THROW_MODE_NORMAL)

/obj/item/device/flashlight/flare/proc/activate_signal(mob/living/carbon/human/user)
	return

/obj/item/device/flashlight/flare/on
	light_on = TRUE

/// Flares deployed by a flare gun
/obj/item/device/flashlight/flare/on/gun
	light_on = TRUE

//Special flare subtype for the illumination flare shell
//Acts like a flare, just even stronger, and set length
/obj/item/device/flashlight/flare/on/illumination
	name = "illumination flare"
	desc = "It's really bright, and unreachable."
	icon_state = "" //No sprite
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_power = 1 //Way brighter than most lights
	show_flame = FALSE

/obj/item/device/flashlight/flare/on/illumination/Initialize()
	. = ..()
	fuel = rand(4.5 MINUTES, 5.5 MINUTES) // Half the duration of a flare, but justified since it's invincible

/obj/item/device/flashlight/flare/on/illumination/update_icon()
	return

/obj/item/device/flashlight/flare/on/illumination/burn_out()
	..()
	qdel(src)

/obj/item/device/flashlight/flare/on/illumination/ex_act(severity)
	return //Nope

/obj/item/device/flashlight/flare/on/starshell_ash
	name = "burning star shell ash"
	desc = "Bright burning ash from a Star Shell 40mm. Don't touch, or it'll burn ya'."
	icon_state = "starshell_ash"
	light_power = 0.7
	anchored = TRUE
	ammo_datum = /datum/ammo/flare/starshell
	show_flame = FALSE

/obj/item/device/flashlight/flare/on/starshell_ash/Initialize(mapload, ...)
	if(mapload)
		return INITIALIZE_HINT_QDEL
	. = ..()
	fuel = rand(30 SECONDS,	60 SECONDS)

/obj/item/device/flashlight/flare/on/illumination/chemical
	name = "chemical light"
	light_power = 0
	light_range = 0
	light_color = COLOR_VERY_SOFT_YELLOW

/obj/item/device/flashlight/flare/on/illumination/chemical/Initialize(mapload, amount)
	. = ..()
	light_power = round(amount * 0.01)
	light_range = round(amount * 0.04)
	if(!light_power)
		return INITIALIZE_HINT_QDEL
	fuel = amount * 5 SECONDS

/obj/item/device/flashlight/slime
	gender = PLURAL
	name = "glowing slime"
	desc = "A glowing ball of what appears to be amber."
	icon = 'icons/obj/items/lighting.dmi'
	// not a slime extract sprite but... something close enough!
	icon_state = "floor1"
	item_state = "slime"
	w_class = SIZE_TINY
	light_power = 0.2
	light_range = 6
	// Bio-luminesence has one setting, on.
	light_on = TRUE
	raillight_compatible = FALSE
	// Bio-luminescence does not toggle.
	toggleable = FALSE

/obj/item/device/flashlight/slime/update_icon()
	. = ..()
	icon_state = initial(icon_state)

//******************************Lantern*******************************/

/obj/item/device/flashlight/lantern
	name = "lantern"
	icon_state = "lantern"
	desc = "A mining lantern."
	light_power = 0.3

//Signal Flare
/obj/item/device/flashlight/flare/signal
	name = "signal flare"
	desc = "A green USCM issued signal flare. The telemetry computer works on chemical reaction that releases smoke and light and thus works only while the flare is burning."
	icon_state = "cas_flare"
	item_state = "cas_flare"
	layer = ABOVE_FLY_LAYER
	light_color = COLOR_VIBRANT_LIME
	ammo_datum = /datum/ammo/flare/signal
	var/datum/cas_signal/signal
	var/activate_message = TRUE
	flame_base_tint = "#00aa00"
	flame_tint = "#aaccaa"

/obj/item/device/flashlight/flare/signal/Initialize()
	. = ..()
	fuel = rand(160 SECONDS, 200 SECONDS)

/obj/item/device/flashlight/flare/signal/attack_self(mob/living/carbon/human/user)
	if(!istype(user))
		return

	. = ..()

	if(.)
		faction = user.faction
		addtimer(CALLBACK(src, PROC_REF(activate_signal), user), 5 SECONDS)

/obj/item/device/flashlight/flare/signal/activate_signal(mob/living/carbon/human/user)
	..()
	if(faction && cas_groups[faction.faction_name])
		signal = new(src)
		signal.target_id = ++cas_tracking_id_increment
		name = "[user.assigned_squad ? user.assigned_squad.name : "X"]-[signal.target_id] flare"
		signal.name = name
		signal.linked_cam = new(loc, name)
		cas_groups[user.faction.faction_name].add_signal(signal)
		anchored = TRUE
		if(activate_message)
			visible_message(SPAN_DANGER("[src]'s flame reaches full strength. It's fully active now."), null, 5)
		var/turf/target_turf = get_turf(src)
		msg_admin_niche("Flare target [src] has been activated by [key_name(user, 1)] at ([target_turf.x], [target_turf.y], [target_turf.z]). (<A HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];adminplayerobservecoodjump=1;X=[target_turf.x];Y=[target_turf.y];Z=[target_turf.z]'>JMP LOC</a>)")
		log_game("Flare target [src] has been activated by [key_name(user, 1)] at ([target_turf.x], [target_turf.y], [target_turf.z]).")
		return TRUE

/obj/item/device/flashlight/flare/signal/attack_hand(mob/user)
	if(!user) return

	if(anchored)
		to_chat(user, "[src] is too hot. You will burn your hand if you pick it up.")
		return
	..()

/obj/item/device/flashlight/flare/signal/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(signal)
		cas_groups[faction.faction_name].remove_signal(signal)
		QDEL_NULL(signal)
	return ..()

/obj/item/device/flashlight/flare/signal/burn_out()
	anchored = FALSE
	if(signal)
		cas_groups[faction.faction_name].remove_signal(signal)
		qdel(signal)
	..()

/// Signal flares deployed by a flare gun
/obj/item/device/flashlight/flare/signal/gun
	activate_message = FALSE

/obj/item/device/flashlight/flare/signal/gun/activate_signal(mob/living/carbon/human/user)
	turn_light(null, TRUE)
	faction = user.faction
	return ..()

/obj/item/device/flashlight/flare/signal/debug
	name = "debug signal flare"
	desc = "A signal flare used to test CAS runs. If you're seeing this, someone messed up."

/obj/item/device/flashlight/flare/signal/debug/Initialize()
	. = ..()
	fuel = INFINITY
	return INITIALIZE_HINT_ROUNDSTART

/obj/item/device/flashlight/flare/signal/debug/LateInitialize()
	activate_signal()

/obj/item/device/flashlight/flare/signal/debug/activate_signal()
	turn_light(null, TRUE)
	faction = GLOB.faction_datums[FACTION_MARINE]
	signal = new(src)
	signal.target_id = ++cas_tracking_id_increment
	name += " [rand(100, 999)]"
	signal.name = name
	signal.linked_cam = new(loc, name)
	cas_groups[FACTION_MARINE].add_signal(signal)
	anchored = TRUE
