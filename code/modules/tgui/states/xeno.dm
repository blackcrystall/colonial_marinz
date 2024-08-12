/**
 * tgui state: hive_state
 *
 * Checks that the user is part of a hive.
 *
 */

GLOBAL_LIST_INIT(hive_state, setup_hive_states())

/proc/setup_hive_states()
	. = list()

	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		.[faction.faction_name] = new/datum/ui_state/hive_state(faction)

/datum/ui_state/hive_state
	var/datum/faction/faction

/datum/ui_state/hive_state/New(datum/faction/faction_to_set)
	. = ..()

	faction = faction_to_set

/datum/ui_state/hive_state/can_use_topic(src_object, mob/user)
	if(faction == user.faction)
		return UI_INTERACTIVE
	return UI_CLOSE

/**
 * tgui state: hive_state_queen
 *
 * Checks that the user is part of a hive and is the leading queen of that hive.
 *
 */

GLOBAL_LIST_INIT(hive_state_queen, setup_hive_queen_states())

/proc/setup_hive_queen_states()
	. = list()

	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		.[faction.faction_name] = new/datum/ui_state/hive_state/queen(faction)

/datum/ui_state/hive_state/queen/can_use_topic(src_object, mob/user)
	. = ..()
	if(. == UI_CLOSE)
		return

	if(faction.living_xeno_queen == user)
		return UI_INTERACTIVE
	return UI_UPDATE
