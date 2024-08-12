// --------------------------------------------
// *** Get communications up ***
// --------------------------------------------
/datum/cm_objective/communications
	name = "Restore Colony Communications"
	objective_flags = OBJECTIVE_DO_NOT_TREE
	value = OBJECTIVE_EXTREME_VALUE
	controller = FACTION_MARINE

/datum/cm_objective/communications/complete()
	faction_announcement("SYSTEMS REPORT: Colony communications link online.", MAIN_AI_SYSTEM, null, GLOB.faction_datums[controller])
	objective_state = OBJECTIVE_COMPLETE
