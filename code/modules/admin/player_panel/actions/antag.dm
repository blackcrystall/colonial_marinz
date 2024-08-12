// MUTINEER
/datum/player_action/make_mutineer
	action_tag = "make_mutineer"
	name = "Make Mutineer"

/datum/player_action/make_mutineer/act(client/user, mob/target, list/params)
	if(!ishuman(target))
		to_chat(user, SPAN_WARNING("This can only be done to instances of type /mob/living/carbon/human"))
		return

	var/mob/living/carbon/human/H = target

	if(H.faction != GLOB.faction_datums[FACTION_MARINE])
		to_chat(user, SPAN_WARNING("This player's faction must equal '[FACTION_MARINE]' to make them a mutineer."))
		return

	var/datum/equipment_preset/preset = GLOB.gear_path_presets_list[/datum/equipment_preset/other/mutineer]
	if(params["leader"])
		preset = GLOB.gear_path_presets_list[/datum/equipment_preset/other/mutineer/leader]


	preset.load_status(H)

	var/title = params["leader"]? "mutineer leader" : "mutineer"
	message_admins("[key_name_admin(user)] has made [key_name_admin(H)] into a [title].")

// XENO
/datum/player_action/change_faction
	action_tag = "xeno_change_faction"
	name = "Change faction"
	permissions_required = R_SPAWN

/datum/player_action/change_faction/act(client/user, mob/target, list/params)
	if(!params["faction"])
		return

	if(!isxeno(target))
		return

	var/mob/living/carbon/xenomorph/xeno = target
	xeno.set_hive_and_update(params["faction"])
	message_admins("[key_name_admin(user)] changed faction of [target] to [params["faction"]].")
	return TRUE

/datum/player_action/make_cultist
	action_tag = "make_cultist"
	name = "Make Cultist"
	permissions_required = R_ADMIN

/datum/player_action/make_cultist/act(client/user, mob/target, list/params)
	if(!params["faction"])
		return

	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	var/datum/equipment_preset/preset = GLOB.gear_path_presets_list[/datum/equipment_preset/other/xeno_cultist]

	if(params["leader"])
		preset = GLOB.gear_path_presets_list[/datum/equipment_preset/other/xeno_cultist/leader]


	preset.load_race(H, params["faction"])
	preset.load_status(H)

	var/title = params["leader"]? "xeno cultist leader" : "cultist"

	message_admins("[key_name_admin(user)] has made [target] into a [title], enslaved to faction [params["faction"]].")
	return TRUE
