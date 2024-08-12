#define BOOST_POWER_MAX 20
#define BOOST_POWER_MIN 1
#define EVOLUTION_INCREMENT_TIME (30 MINUTES) // Evolution increases by 1 every 30 minutes.

SUBSYSTEM_DEF(xevolution)
	name		= "Evolution"
	wait		= 1 MINUTES
	priority	= SS_PRIORITY_INACTIVITY

	var/human_xeno_ratio_modifier = 0.4
	var/time_ratio_modifier = 0.4

	var/list/boost_power = list()
	var/force_boost_power = FALSE // Debugging only

/datum/controller/subsystem/xevolution/Initialize(start_timeofday)
	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		boost_power[faction] = 1
	return SS_INIT_SUCCESS

/datum/controller/subsystem/xevolution/fire(resumed = FALSE)
	for(var/faction_to_get in FACTION_LIST_XENOMORPH)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		if(!faction)
			continue

		if(!faction.dynamic_evolution)
			boost_power[faction] = faction.evolution_rate + faction.evolution_bonus
			faction.faction_ui.update_burrowed_larva()
			continue

		var/boost_power_new
		// Minimum of 5 evo until 10 minutes have passed.
		if((world.time - SSticker.round_start_time) < XENO_ROUNDSTART_PROGRESS_TIME_2)
			boost_power_new = max(boost_power_new, XENO_ROUNDSTART_PROGRESS_AMOUNT)
		else
			boost_power_new = round(10 * (world.time - XENO_ROUNDSTART_PROGRESS_TIME_2 - SSticker.round_start_time) / EVOLUTION_INCREMENT_TIME) / 10

			//Add on any bonuses from evopods after applying upgrade progress
			boost_power_new += (0.5 * faction.has_special_structure(XENO_STRUCTURE_EVOPOD))

		boost_power_new = Clamp(boost_power_new, BOOST_POWER_MIN, BOOST_POWER_MAX)

		boost_power_new += faction.evolution_bonus
		if(!force_boost_power)
			boost_power[faction] = boost_power_new

		//Update displayed Evilution, which is under larva apparently
		faction.faction_ui.update_burrowed_larva()

/datum/controller/subsystem/xevolution/proc/get_evolution_boost_power(datum/faction/faction)
	return boost_power[faction]

#undef EVOLUTION_INCREMENT_TIME
#undef BOOST_POWER_MIN
#undef BOOST_POWER_MAX
