/datum/action/human_action/update_button_icon()
	if(action_cooldown_check())
		button.color = rgb(120,120,120,200)
	else
		button.color = rgb(255,255,255,255)

/datum/action/human_action/proc/action_cooldown_check()
	return FALSE


/datum/action/human_action/issue_order
	name = "Issue Order"
	action_icon_state = "order"
	var/order_type = "help"

/datum/action/human_action/issue_order/give_to(mob/living/L)
	..()
	if(!ishuman(L))
		return
	cooldown = COMMAND_ORDER_COOLDOWN

/datum/action/human_action/issue_order/action_activate()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.issue_order(order_type)

/datum/action/human_action/issue_order/action_cooldown_check()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	return !H.command_aura_available

/datum/action/human_action/issue_order/move
	name = "Issue Order - Move"
	action_icon_state = "order_move"
	order_type = COMMAND_ORDER_MOVE

/datum/action/human_action/issue_order/hold
	name = "Issue Order - Hold"
	action_icon_state = "order_hold"
	order_type = COMMAND_ORDER_HOLD

/datum/action/human_action/issue_order/focus
	name = "Issue Order - Focus"
	action_icon_state = "order_focus"
	order_type = COMMAND_ORDER_FOCUS


/datum/action/human_action/smartpack/action_cooldown_check()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(istype(H.back, /obj/item/storage/backpack/marine/smartpack))
		var/obj/item/storage/backpack/marine/smartpack/S = H.back
		return cooldown_check(S)
	else
		return FALSE

/datum/action/human_action/smartpack/action_activate()
	if(!istype(owner, /mob/living/carbon/human))
		return
	var/mob/living/carbon/human/H = owner
	if(istype(H.back, /obj/item/storage/backpack/marine/smartpack))
		var/obj/item/storage/backpack/marine/smartpack/S = H.back
		form_call(S, H)

/datum/action/human_action/smartpack/give_to(mob/living/L)
	..()
	if(!ishuman(L))
		return
	var/mob/living/carbon/human/H = L
	if(istype(H.back, /obj/item/storage/backpack/marine/smartpack))
		var/obj/item/storage/backpack/marine/smartpack/S = H.back
		cooldown = set_cooldown(S)
	else
		return

/datum/action/human_action/smartpack/proc/form_call(obj/item/storage/backpack/marine/smartpack/S, mob/living/carbon/human/H)
	return

/datum/action/human_action/smartpack/proc/set_cooldown(obj/item/storage/backpack/marine/smartpack/S)
	return

/datum/action/human_action/smartpack/proc/cooldown_check(obj/item/storage/backpack/marine/smartpack/S)
	return S.activated_form


/datum/action/human_action/smartpack/protective_form
	name = "Protective Form"
	action_icon_state = "smartpack_protect"

/datum/action/human_action/smartpack/protective_form/set_cooldown(obj/item/storage/backpack/marine/smartpack/S)
	return S.protective_form_cooldown

/datum/action/human_action/smartpack/protective_form/form_call(obj/item/storage/backpack/marine/smartpack/S, mob/living/carbon/human/H)
	S.protective_form(H)

/datum/action/human_action/smartpack/immobile_form
	name = "Immobile Form"
	action_icon_state = "smartpack_immobile"

/datum/action/human_action/smartpack/immobile_form/form_call(obj/item/storage/backpack/marine/smartpack/S, mob/living/carbon/human/H)
	S.immobile_form(H)

/datum/action/human_action/smartpack/repair_form
	name = "Repair Form"
	action_icon_state = "smartpack_repair"

/datum/action/human_action/smartpack/repair_form/set_cooldown(obj/item/storage/backpack/marine/smartpack/S)
	return S.repair_form_cooldown

/datum/action/human_action/smartpack/repair_form/form_call(obj/item/storage/backpack/marine/smartpack/S, mob/living/carbon/human/H)
	S.repair_form(H)

/datum/action/human_action/smartpack/repair_form/cooldown_check(obj/item/storage/backpack/marine/smartpack/S)
	return S.repairing

/*
CULT
*/
/datum/action/human_action/activable
	var/ability_used_time = 0

/datum/action/human_action/activable/can_use_action()
	var/mob/living/carbon/human/H = owner
	if(istype(H) && !H.is_mob_incapacitated() && !H.dazed)
		return TRUE

// Called when the action is clicked on.
/datum/action/human_action/activable/action_activate()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(H.selected_ability == src)
		to_chat(H, "You will no longer use [name] with \
			[H.client && H.client.prefs && H.client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK ? "middle-click" : "shift-click"].")
		button.icon_state = "template"
		H.selected_ability = null
	else
		to_chat(H, "You will now use [name] with \
			[H.client && H.client.prefs && H.client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK ? "middle-click" : "shift-click"].")
		if(H.selected_ability)
			H.selected_ability.button.icon_state = "template"
			H.selected_ability = null
		button.icon_state = "template_on"
		H.selected_ability = src

/datum/action/human_action/activable/remove_from(mob/living/carbon/human/H)
	..()
	if(H.selected_ability == src)
		H.selected_ability = null

/datum/action/human_action/activable/proc/use_ability(mob/M)
	return

/datum/action/human_action/activable/update_button_icon()
	if(!button)
		return
	if(!action_cooldown_check())
		button.color = rgb(240,180,0,200)
	else
		button.color = rgb(255,255,255,255)

/datum/action/human_action/activable/action_cooldown_check()
	return ability_used_time <= world.time

/datum/action/human_action/activable/proc/enter_cooldown(amount = cooldown)
	ability_used_time = world.time + amount

	update_button_icon()

	addtimer(CALLBACK(src, PROC_REF(update_button_icon)), amount)

/datum/action/human_action/activable/cult
	name = "Activable Cult Ability"

/datum/action/human_action/activable/cult/speak_hivemind
	name = "Speak in Hivemind"
	action_icon_state = "cultist_channel_hivemind"

/datum/action/human_action/activable/cult/speak_hivemind/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner


	var/message = input(H, "Say in Hivemind", "Hivemind Chat") as null|text
	if(!message)
		return

	message = trim(strip_html(message))

	message = capitalize(trim(message))
	message = process_chat_markup(message, list("~", "_"))

	if(!(copytext(message, -1) in ENDING_PUNCT))
		message += "."

	if(istype(H.faction))
		return

	H.hivemind_broadcast(message, H.faction)

/datum/action/human_action/activable/cult/obtain_equipment
	name = "Obtain Equipment"
	action_icon_state = "cultist_channel_equipment"
	var/list/items_to_spawn = list(/obj/item/clothing/suit/cultist_hoodie/, /obj/item/clothing/head/cultist_hood/)

/datum/action/human_action/activable/cult/obtain_equipment/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner

	if(tgui_alert(H, "Once obtained, you'll be unable to take it off. Confirm selection.", "Obtain Equipment", H.client.auto_lang(LANGUAGE_YES), H.client.auto_lang(LANGUAGE_NO)) != H.client.auto_lang(LANGUAGE_YES))
		to_chat(H, SPAN_WARNING("You have decided not to obtain your equipment."))
		return

	H.visible_message(SPAN_DANGER("[H] gets onto their knees and begins praying."), \
	SPAN_WARNING("You get onto your knees to pray."))

	if(!do_after(H, 3 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		to_chat(H, SPAN_WARNING("You decide not to retrieve your equipment."))
		return

	H.drop_inv_item_on_ground(H.get_item_by_slot(WEAR_JACKET), FALSE, TRUE)
	H.drop_inv_item_on_ground(H.get_item_by_slot(WEAR_HEAD), FALSE, TRUE)

	var/obj/item/clothing/C = new /obj/item/clothing/suit/cultist_hoodie()
	H.equip_to_slot_or_del(C, WEAR_JACKET)
	C.flags_item |= NODROP|DELONDROP

	C = new /obj/item/clothing/head/cultist_hood()
	H.equip_to_slot_or_del(C, WEAR_HEAD)
	C.flags_item |= NODROP|DELONDROP

	H.put_in_any_hand_if_possible(new /obj/item/device/flashlight, FALSE, TRUE)

	playsound(H.loc, 'sound/voice/scream_horror1.ogg', 25)

	H.visible_message(SPAN_HIGHDANGER("[H] puts on their robes."), SPAN_WARNING("You put on your robes."))
	for(var/datum/action/human_action/activable/cult/obtain_equipment/O in H.actions)
		O.remove_from(H)

/datum/action/human_action/activable/cult_leader
	name = "Activable Leader Ability"

/datum/action/human_action/activable/cult_leader/proc/can_target(mob/living/carbon/human/H)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/Hu = owner

	if(H.skills && (skillcheck(H, SKILL_LEADERSHIP, SKILL_LEAD_EXPERT) || skillcheck(H, SKILL_POLICE, SKILL_POLICE_SKILLED)))
		to_chat(Hu, SPAN_WARNING("This mind is too strong to target with your abilities."))
		return

	if(get_dist_sqrd(get_turf(H), get_turf(owner)) > 2)
		to_chat(Hu, SPAN_WARNING("This target is too far away!"))
		return

	return H.stat != DEAD && istype(H) && ishuman_strict(H) && H.faction != Hu.faction && !isnull(get_hive())

/datum/action/human_action/activable/cult_leader/proc/get_hive()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner

	if(!H.faction.living_xeno_queen && !H.faction.allow_no_queen_actions)
		return
	return H.faction

/datum/action/human_action/activable/cult_leader/convert
	name = "Convert"
	action_icon_state = "cultist_channel_convert"

/datum/action/human_action/activable/cult_leader/convert/use_ability(mob/M)
	var/datum/faction/faction = get_hive()

	if(!istype(faction))
		to_chat(owner, SPAN_DANGER("There is no Queen. You are alone."))
		return

	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner

	var/mob/living/carbon/human/choice = M

	if(!can_target(choice))
		return

	if(choice.stat != CONSCIOUS)
		to_chat(H, SPAN_XENOMINORWARNING("[choice] must be conscious for the conversion to work!"))
		return

	if(!do_after(H, 10 SECONDS, INTERRUPT_ALL, BUSY_ICON_HOSTILE, choice, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		to_chat(H, SPAN_XENOMINORWARNING("You decide not to convert [choice]."))
		return

	var/datum/equipment_preset/preset = GLOB.gear_path_presets_list[/datum/equipment_preset/other/xeno_cultist]
	preset.load_race(choice, H.faction)
	preset.load_status(choice)

	to_chat(choice, SPAN_ROLE_HEADER("You are now a Xeno Cultist!"))
	to_chat(choice, SPAN_ROLE_BODY("Worship the Xenomorphs and listen to the Cult Leader for orders. The Cult Leader is typically the person who transformed you. Do not kill anyone unless you are wearing your black robes, you may defend yourself."))

	xeno_message("[choice] has been converted into a cultist!", 2, faction)

	choice.apply_effect(5, PARALYZE)
	choice.make_jittery(105)

	if(choice.client)
		playsound_client(choice.client, 'sound/effects/xeno_newlarva.ogg', null, 25)

/datum/action/human_action/activable/cult_leader/stun
	name = "Psychic Stun"
	action_icon_state = "cultist_channel_stun"

	cooldown = 1 MINUTES

/datum/action/human_action/activable/cult_leader/stun/use_ability(mob/M)
	if(!action_cooldown_check())
		return

	var/datum/faction/faction = get_hive()

	if(!istype(faction))
		to_chat(owner, SPAN_DANGER("There is no Queen. You are alone."))
		return

	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner

	var/mob/living/carbon/human/choice = M

	if(!can_target(choice))
		return

	to_chat(choice, SPAN_HIGHDANGER("You feel a dangerous presence in the back of your head. You find yourself unable to move!"))

	choice.frozen = TRUE
	choice.update_canmove()

	choice.update_xeno_hostile_hud()

	if(!do_after(H, 2 SECONDS, INTERRUPT_ALL | BEHAVIOR_IMMOBILE, BUSY_ICON_HOSTILE, choice, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		to_chat(H, SPAN_XENOMINORWARNING("You decide not to stun [choice]."))
		unroot_human(choice)

		enter_cooldown(5 SECONDS)
		return

	enter_cooldown()

	unroot_human(choice)

	choice.apply_effect(10, PARALYZE)
	choice.make_jittery(105)

	to_chat(choice, SPAN_HIGHDANGER("An immense psychic wave passes through you, causing you to pass out!"))

	playsound(get_turf(choice), 'sound/scp/scare1.ogg', 25)

/datum/action/human_action/activable/mutineer
	name = "Mutiny abilities"

/datum/action/human_action/activable/mutineer/mutineer_convert
	name = "Convert"
	action_icon_state = "mutineer_convert"

	var/list/converted = list()

/datum/action/human_action/activable/mutineer/mutineer_convert/use_ability(mob/M)
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner
	var/mob/living/carbon/human/choice = M

	if(!istype(choice))
		return

	if(choice.faction != GLOB.faction_datums[FACTION_MARINE] || (choice.skills && skillcheck(choice, SKILL_POLICE, 2)) || (choice in converted))
		to_chat(H, SPAN_WARNING("You can't convert [choice]!"))
		return

	to_chat(H, SPAN_NOTICE("Mutiny join request sent to [choice]!"))

	if(tgui_alert(choice, "Do you want to be a mutineer?", "Become Mutineer", list(choice.client.auto_lang(LANGUAGE_YES), choice.client.auto_lang(LANGUAGE_NO))) != choice.client.auto_lang(LANGUAGE_YES))
		return

	converted += choice
	to_chat(choice, SPAN_WARNING("You'll become a mutineer when the mutiny begins. Prepare yourself and do not cause any harm until you've been made into a mutineer."))

	message_admins("[key_name_admin(choice)] has been converted into a mutineer by [key_name_admin(H)].")

/datum/action/human_action/activable/mutineer/mutineer_begin
	name = "Begin Mutiny"
	action_icon_state = "mutineer_begin"

/datum/action/human_action/activable/mutineer/mutineer_begin/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner

	if(tgui_alert(H, "Are you sure you want to begin the mutiny?", "Begin Mutiny?", list(owner.client.auto_lang(LANGUAGE_YES), owner.client.auto_lang(LANGUAGE_NO))) != owner.client.auto_lang(LANGUAGE_YES))
		return

	shipwide_ai_announcement("DANGER: Communications received; a mutiny is in progress. Code: Detain, Arrest, Defend.")
	var/datum/equipment_preset/other/mutineer/XC = new()

	XC.load_status(H)
	for(var/datum/action/human_action/activable/mutineer/mutineer_convert/converted in H.actions)
		for(var/mob/living/carbon/human/choice in converted.converted)
			XC.load_status(choice)
		converted.remove_from(H)

	message_admins("[key_name_admin(H)] has begun the mutiny.")
	remove_from(H)


/datum/action/human_action/cancel_view // cancel-camera-view, but a button
	name = "Cancel View"
	action_icon_state = "cancel_view"

/datum/action/human_action/cancel_view/give_to(user)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_RESET_VIEW, PROC_REF(remove_from)) // will delete the button even if you reset view by resisting or the verb

/datum/action/human_action/cancel_view/remove_from(mob/L)
	. = ..()
	UnregisterSignal(L, COMSIG_MOB_RESET_VIEW)

/datum/action/human_action/cancel_view/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner

	H.cancel_camera()
	H.reset_view()
	H.client.change_view(world_view_size, target)
	H.client.pixel_x = 0
	H.client.pixel_y = 0

//Similar to a cancel-camera-view button, but for mobs that were buckled to special vehicle seats.
//Unbuckles them, which handles the view and offsets resets and other stuff.
/datum/action/human_action/vehicle_unbuckle
	name = "Vehicle Unbuckle"
	action_icon_state = "unbuckle"

/datum/action/human_action/vehicle_unbuckle/give_to(user)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_RESET_VIEW, PROC_REF(remove_from))//since unbuckling from special vehicle seats also resets the view, gonna use same signal

/datum/action/human_action/vehicle_unbuckle/remove_from(mob/L)
	. = ..()
	UnregisterSignal(L, COMSIG_MOB_RESET_VIEW)

/datum/action/human_action/vehicle_unbuckle/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/H = owner
	if(H.buckled)
		if(istype(H.buckled, /obj/structure/bed/chair/comfy/vehicle))
			H.buckled.unbuckle()
		else if(!isvehiclemultitile(H.interactee))
			remove_from(H)
	else if(!isvehiclemultitile(H.interactee))
		remove_from(H)

	H.unset_interaction()
	H.client.change_view(world_view_size, target)
	H.client.pixel_x = 0
	H.client.pixel_y = 0
	H.reset_view()
	remove_from(H)


/datum/action/human_action/mg_exit
	name = "Exit MG"
	action_icon_state = "cancel_view"

/datum/action/human_action/mg_exit/action_activate()
	if(!can_use_action())
		return

	var/mob/living/carbon/human/human_user = owner
	SEND_SIGNAL(human_user, COMSIG_MOB_MG_EXIT)
