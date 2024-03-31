
// Called when the item is in the active hand, and clicked; alternately, there is an 'activate held object' verb or you can hit pagedown.
/obj/item/proc/attack_self(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF, user)

	if(flags_item & CAN_DIG_SHRAPNEL && ishuman(user))
		dig_out_shrapnel(user)

// No comment
/atom/proc/attackby(obj/item/W, mob/living/user,list/mods)
	if(SEND_SIGNAL(src, COMSIG_PARENT_ATTACKBY, W, user, mods) & COMPONENT_NO_AFTERATTACK)
		return TRUE
	return FALSE

/atom/movable/attackby(obj/item/W, mob/living/user)
	if(W)
		if(!(W.flags_item & NOBLUDGEON))
			visible_message(SPAN_DANGER("[src] has been hit by [user] with [W]."), null, null, 5, CHAT_TYPE_MELEE_HIT)
			user.animation_attack_on(src)
			user.flick_attack_overlay(src, "punch")

/mob/living/attackby(obj/item/I, mob/user)
	/* Commented surgery code, proof of concept. Would need to tweak human attackby to prevent duplication; mob/living don't have separate limb objects.
	if((user.mob_flags & SURGERY_MODE_ON) && user.a_intent & (INTENT_HELP|INTENT_DISARM))
		safety = TRUE
		var/datum/surgery/current_surgery = active_surgeries[user.zone_selected]
		if(current_surgery)
			if(current_surgery.attempt_next_step(user, I))
				return TRUE
		else if(initiate_surgery_moment(I, src, null, user))
			return TRUE
	*/
	if(istype(I) && ismob(user))
		return I.attack(src, user)


// Proximity_flag is 1 if this afterattack was called on something adjacent, in your square, or on your person.
// Click parameters is the params string from byond Click() code, see that documentation.
/obj/item/proc/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	return FALSE


/obj/item/proc/attack(mob/living/mob, mob/living/user)
	if((flags_item & NOBLUDGEON) || (MODE_HAS_TOGGLEABLE_FLAG(MODE_NO_ATTACK_DEAD) && mob.stat == DEAD && !user.ally(mob.faction)))
		return FALSE

	if(SEND_SIGNAL(mob, COMSIG_ITEM_ATTEMPT_ATTACK, user, src) & COMPONENT_CANCEL_ATTACK) //Sent by target mob.
		return FALSE

	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK, user, mob) & COMPONENT_CANCEL_ATTACK) //Sent by source item.
		return FALSE

	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		if(!human.melee_allowed)
			to_chat(human, SPAN_DANGER("You are currently unable to attack."))
			return FALSE

	var/showname = "."
	if(user)
		if(mob == user)
			showname = " by themselves."
		else
			showname = " by [user]."
	if(!(user in viewers(mob, null)))
		showname = "."

	if (user.a_intent == INTENT_HELP && ((user.client?.prefs && user.client?.prefs?.toggle_prefs & TOGGLE_HELP_INTENT_SAFETY) || (user.mob_flags & SURGERY_MODE_ON)))
		playsound(loc, 'sound/effects/pop.ogg', 25, 1)
		user.visible_message(SPAN_NOTICE("[mob] has been poked with [src][showname]"),\
			SPAN_NOTICE("You poke [mob == user ? "yourself":mob] with [src]."), null, 4)

		return FALSE

	/////////////////////////
	user.attack_log += "\[[time_stamp()]\]<font color='red'> Attacked [key_name(mob)] with [name] (INTENT: [uppertext(intent_text(user.a_intent))]) (DAMTYE: [uppertext(damtype)])</font>"
	mob.attack_log += "\[[time_stamp()]\]<font color='orange'> Attacked by  [key_name(user)] with [name] (INTENT: [uppertext(intent_text(user.a_intent))]) (DAMTYE: [uppertext(damtype)])</font>"
	msg_admin_attack("[key_name(user)] attacked [key_name(mob)] with [name] (INTENT: [uppertext(intent_text(user.a_intent))]) (DAMTYE: [uppertext(damtype)]) in [get_area(src)] ([src.loc.x],[src.loc.y],[src.loc.z]).", src.loc.x, src.loc.y, src.loc.z)

	/////////////////////////

	add_fingerprint(user)

	var/power = force
	if(user.skills)
		power = round(power * (1 + 0.25 * user.skills.get_skill_level(SKILL_MELEE_WEAPONS))) //25% bonus per melee level
	if(!ishuman(mob))
		var/used_verb = "attacked"
		if(attack_verb && attack_verb.len)
			used_verb = pick(attack_verb)
		user.visible_message(SPAN_DANGER("[mob] has been [used_verb] with [src][showname]."), \
			SPAN_DANGER("You [used_verb] [mob == user ? "yourself":mob] with [src]."), null, 5, CHAT_TYPE_MELEE_HIT)

		user.animation_attack_on(mob)
		user.flick_attack_overlay(mob, "punch")
		if(isxeno(mob))
			var/mob/living/carbon/xenomorph/xenomorph = mob
			power = armor_damage_reduction(GLOB.xeno_melee, power, xenomorph.armor_deflection + xenomorph.armor_deflection_buff - xenomorph.armor_deflection_debuff, 20, 0, 0, xenomorph.armor_integrity)
			var/armor_punch = armor_break_calculation(GLOB.xeno_melee, power, xenomorph.armor_deflection + xenomorph.armor_deflection_buff - xenomorph.armor_deflection_debuff, 20, 0, 0, xenomorph.armor_integrity)
			xenomorph.apply_armorbreak(armor_punch)
		if(hitsound)
			playsound(loc, hitsound, 25, 1)
		switch(damtype)
			if("brute")
				mob.apply_damage(power, BRUTE)
			if("fire")
				mob.apply_damage(power, BURN)
				to_chat(mob, SPAN_WARNING("It burns!"))
		user.track_damage(initial(name), mob, power)
		if(user.faction == mob.faction)
			user.track_friendly_damage(initial(name), mob, power)
		if(power > 5)
			mob.last_damage_data = create_cause_data(initial(name), user, src)
			user.track_hit(initial(name))
			if(user.faction == mob.faction)
				user.track_friendly_fire(initial(name))
		mob.updatehealth()
	else
		var/mob/living/carbon/human/human = mob
		var/hit = human.attacked_by(src, user)
		if(hit && hitsound)
			playsound(loc, hitsound, 25, 1)
		return hit
	return TRUE
