//Custom
/datum/emergency_call/custom
	mob_min = 0

	probability = 0
	hostility = FALSE

	var/list/players_to_offer = list()
	var/client/owner

	shuttle_id = null

	ert_message = "Several characters have been offered up to be played by the admins"

/datum/emergency_call/custom/create_member(datum/mind/M, turf/override_spawn_loc)
	set waitfor = FALSE
	var/turf/spawn_loc = override_spawn_loc ? override_spawn_loc : get_spawn_point()

	if(!istype(spawn_loc))
		return //Didn't find a useable spawn point.

	if(!players_to_offer.len)
		return // No more players

	var/mob/living/carbon/human/H = pick(players_to_offer)

	if(!H) // Something went wrong
		return

	M.transfer_to(H, TRUE)
	GLOB.ert_mobs += H

	players_to_offer -= H

	return

/datum/emergency_call/custom/spawn_candidates(announce, override_spawn_loc)
	. = ..()
	if(owner)
		for(var/mob/living/carbon/human/H in players_to_offer)
			owner.free_for_ghosts(H)
