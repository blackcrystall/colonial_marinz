
//Feral Xenomorphs, hostile to TRULY everyone.
/datum/emergency_call/feral_xenos
	name = "Xenomorphs (Feral)"
	mob_min = 1
	mob_max = 8
	max_medics = 2 //Support T2 castes
	max_engineers = 3 //Combat T2 castes
	probability = 5
	auto_shuttle_launch = TRUE //because xenos can't use the shuttle console.
	hostility = TRUE

/datum/emergency_call/feral_xenos/New()
	..()
	arrival_message = "[MAIN_SHIP_NAME], this is USS Vriess respond-- #&...*#&^#.. signal... oh god, they're in the vent---... Priority Warning: Signal lost."
	objectives = "Destroy everything!"

/datum/emergency_call/feral_xenos/spawn_items()
	var/turf/drop_spawn = get_spawn_point(TRUE)
	if(istype(drop_spawn))
		//drop some weeds for xeno plasma regen.
		new /obj/effect/alien/weeds/node/feral(drop_spawn, null, null, GLOB.faction_datums[FACTION_XENOMORPH_FERAL])

/datum/emergency_call/feral_xenos/create_member(datum/mind/mind, turf/override_spawn_loc)
	var/turf/spawn_loc = override_spawn_loc ? override_spawn_loc : get_spawn_point()
	var/datum/faction/faction_to_set = GLOB.faction_datums[FACTION_XENOMORPH_FERAL]

	if(!istype(spawn_loc))
		return //Didn't find a useable spawn point.

	var/mob/current_mob = mind.current
	var/hive_leader = FALSE

	var/mob/living/carbon/xenomorph/xenomorph
	if(!leader)
		var/picked = pick(/mob/living/carbon/xenomorph/ravager, /mob/living/carbon/xenomorph/praetorian, /mob/living/carbon/xenomorph/crusher)
		xenomorph = new picked(spawn_loc, null, faction_to_set)
		leader = xenomorph
		hive_leader = TRUE

	else if(medics < max_medics)
		medics++
		var/picked = pick(/mob/living/carbon/xenomorph/drone, /mob/living/carbon/xenomorph/hivelord, /mob/living/carbon/xenomorph/burrower)
		xenomorph = new picked(spawn_loc, null, faction_to_set)

	else if(engineers < max_engineers)
		engineers++
		var/picked = pick(/mob/living/carbon/xenomorph/warrior, /mob/living/carbon/xenomorph/lurker, /mob/living/carbon/xenomorph/spitter)
		xenomorph = new picked(spawn_loc, null, faction_to_set)

	else
		var/picked = pick(/mob/living/carbon/xenomorph/drone, /mob/living/carbon/xenomorph/runner, /mob/living/carbon/xenomorph/defender)
		xenomorph = new picked(spawn_loc, null, faction_to_set)

	mind.transfer_to(xenomorph, TRUE)
	GLOB.ert_mobs += xenomorph
	if(hive_leader)
		faction_to_set.add_hive_leader(xenomorph)

	QDEL_NULL(current_mob)


/datum/emergency_call/feral_xenos/platoon
	name = "Xenomorphs (Feral Platoon)"
	mob_min = 1
	mob_max = 30
	probability = 1
