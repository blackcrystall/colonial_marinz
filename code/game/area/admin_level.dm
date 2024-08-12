// Bunker01
// Areas

/area/adminlevel
	base_lighting_alpha = 255

/area/adminlevel/bunker01
	icon_state = "thunder"
	requires_power = FALSE
	statistic_exempt = TRUE
	flags_area = AREA_NOTUNNEL

/area/adminlevel/bunker01/mainroom
	name = "\improper Bunker Main Room"
	icon_state = "bunker01_main"

/area/adminlevel/bunker01/medbay
	name = "\improper Bunker Medbay"
	icon_state = "bunker01_medbay"

/area/adminlevel/bunker01/security
	name = "\improper Bunker Security"
	icon_state = "bunker01_security"

/area/adminlevel/bunker01/engineering
	name = "\improper Bunker Engineering"
	icon_state = "bunker01_engineering"

/area/adminlevel/bunker01/storage
	name = "\improper Bunker Storage"
	icon_state = "bunker01_storage"

/area/adminlevel/bunker01/bedroom
	name = "\improper Bunker Bedroom"
	icon_state = "bunker01_bedroom"

/area/adminlevel/bunker01/command
	name = "\improper Bunker Command Room"
	icon_state = "bunker01_command"

/area/adminlevel/bunker01/bathroom
	name = "\improper Bunker Bathroom"
	icon_state = "bunker01_bathroom"

/area/adminlevel/bunker01/kitchen
	name = "\improper Bunker Kitchen"
	icon_state = "bunker01_kitchen"

/area/adminlevel/bunker01/hydroponics
	name = "\improper Bunker Hydroponics"
	icon_state = "bunker01_hydroponics"

/area/adminlevel/bunker01/breakroom
	name = "\improper Bunker Breakroom"
	icon_state = "bunker01_break"

/area/adminlevel/bunker01/gear
	name = "\improper Bunker Gear"
	icon_state = "bunker01_gear"

/area/adminlevel/bunker01/caves
	name = "\improper Bunker Caves"
	icon_state = "bunker01_caves"
	always_unpowered = TRUE
	requires_power = TRUE

/area/adminlevel/bunker01/caves/outpost
	name = "\improper Bunker Outpost"
	icon_state = "bunker01_caves_outpost"
	requires_power = TRUE
	always_unpowered = FALSE

/area/adminlevel/bunker01/caves/xeno
	name = "\improper Bunker Xeno Hive"
	icon_state = "bunker01_caves_outpost"
	flags_area = AREA_NOTUNNEL|AREA_ALLOW_XENO_JOIN

	var/datum/faction/faction

/area/adminlevel/bunker01/caves/xeno/Initialize()
	. = ..()
	faction = GLOB.faction_datums[FACTION_XENOMORPH_ALPHA]

/area/adminlevel/bunker01/caves/xeno/Entered(atom/movable/arrived, old_loc)
	. = ..()
	if(isxeno(arrived))
		var/mob/living/carbon/xenomorph/xenomorph = arrived

		xenomorph.away_timer = XENO_LEAVE_TIMER
		xenomorph.set_hive_and_update(faction)

// ERT Station
/area/adminlevel/ert_station
	name = "ERT Station"
	icon_state = "green"
	requires_power = FALSE
	flags_area = AREA_NOTUNNEL

/area/adminlevel/ert_station/weyland_station
	name = "PMC Command"
	icon_state = "red"

/area/adminlevel/ert_station/uscm_station
	name = "USCM Command"
	icon_state = "green"

/area/adminlevel/ert_station/clf_station
	name = "CLF Station"
	icon_state = "white"

/area/adminlevel/ert_station/upp_station
	name = "UPP Command"
	icon_state = "green"

/area/adminlevel/ert_station/freelancer_station
	name = "Freelancer Station"
	icon_state = "yellow"

/area/adminlevel/ert_station/royal_marines_station
	name = "HMS Patna Hangerbay"
	icon_state = "yellow"

/area/adminlevel/ert_station/xenomorph_station
	name = "RSC-M Research Facility"
	icon_state = "red"

/area/adminlevel/ert_station/shuttle_dispatch
	name = "Shuttle Dispatch Station"
	soundscape_playlist = SCAPE_PL_ELEVATOR_MUSIC
	icon_state = "yellow"

//Simulation area
/area/adminlevel/simulation
	name = "Simulated Reality"
	icon_state = "green"
	flags_area = AREA_NOTUNNEL
	requires_power = FALSE

	static_lighting = FALSE
	area_has_base_lighting = TRUE
	luminosity = 1
	base_lighting_alpha = 255


/area/misc/testroom
	requires_power = FALSE
	name = "Test Room"
