// --------------------------------------------
// *** The core objective interface to allow generic handling of objectives ***
// --------------------------------------------
/datum/cm_objective
	var/name = "An objective to complete"
	var/objective_state = OBJECTIVE_INACTIVE // Whether the objective is inactive, active or complete.
	var/value = OBJECTIVE_NO_VALUE // The point value of this objective.
	var/list/required_objectives = list() //List of objectives that are required to complete this objectives.
	var/list/enables_objectives = list() //List of objectives that require this objective to complete.
	var/objective_flags = NO_FLAGS // functionality related flags.
	var/number_of_clues_to_generate = 1 // miminum number of clues we generate for the objective(aka how many things will point to this objective).
	var/controller = FACTION_NEUTRAL
	var/display_category // group objectives for round end display

/datum/cm_objective/New(faction_to_get)
	if(!faction_to_get)
		qdel(src)
		return
	controller = faction_to_get
	connect_objective()

// Hotfix for testing, until rework in proper way pregenerated objectives (TODO: REMOVE WHEN PREGENERATED SPAWNS OF OBJECTIVES REMOVED)
/datum/cm_objective/proc/connect_objective()
	set waitfor = FALSE
	UNTIL(length(GLOB.faction_datums))
	GLOB.faction_datums[controller].objectives_controller.add_objective(src)

/datum/cm_objective/Destroy()
	if(controller)
		GLOB.faction_datums[controller].objectives_controller.stop_processing_objective(src)
		GLOB.faction_datums[controller].objectives_controller.remove_objective(src)
	for(var/datum/cm_objective/R as anything in required_objectives)
		R.enables_objectives -= src
	for(var/datum/cm_objective/E as anything in enables_objectives)
		E.required_objectives -= src
	required_objectives = null
	enables_objectives = null
	return ..()

// initial setup after the map has loaded
/datum/cm_objective/proc/Initialize()

// called by game mode on a short delay after round starts
/datum/cm_objective/proc/post_round_start()

// Get the objective data to display on the TGUI interface.
/datum/cm_objective/proc/get_tgui_data()

/datum/cm_objective/proc/get_clue()

//For returning labels of related items (folders, discs, etc.)
/datum/cm_objective/proc/get_related_label()

// Set this objective to complete.
/datum/cm_objective/proc/complete()

// Check if the objective's aim are met.
/datum/cm_objective/proc/check_completion()

// Make this objective call process() and check_completion() every SS tick.
/datum/cm_objective/proc/activate()
	GLOB.faction_datums[controller].objectives_controller.start_processing_objective(src)

// Stops the Objective from processing
/datum/cm_objective/proc/deactivate()
	GLOB.faction_datums[controller].objectives_controller.start_processing_objective(src)

/datum/cm_objective/proc/get_completion_status()
	if(objective_state & OBJECTIVE_COMPLETE)
		return "<span class='objectivesuccess'>Succeeded!</span>"
	return "<span class='objectivebig'>In Progress!</span>"

/datum/cm_objective/proc/get_readable_progress()
	var/dat = "<b>[name]:</b> "
	return dat + get_completion_status() + "<br>"

/datum/cm_objective/proc/get_point_value()
	if(objective_state & OBJECTIVE_COMPLETE)
		return value
	return FALSE

/datum/cm_objective/proc/total_point_value()
	return value

/datum/cm_objective/proc/observable_by_faction(faction)
	if(controller == faction || objective_flags & OBJECTIVE_NO_FACTION_LINK)
		return TRUE
	return FALSE
