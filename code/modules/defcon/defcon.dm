#define DEFCON_ASSET_VEND			(1<<0)
#define DEFCON_ASSET_DELIVERY		(1<<1)
#define DEFCON_ASSET_DELIVERY_CARGO	(1<<2)

/datum/objectives_datum
	var/name = "DEFCON Level Accounting"
	var/associated_faction
	var/current_level = 5
	var/real_current_level = 1

	var/list/datum/cm_objective/objectives = list()
	var/list/datum/cm_objective/processing_objectives = list()

	var/list/objective_spawns = list()

	var/list/purchased_rewards = list()
	var/remaining_reward_points = REWARD_POINT_GAIN_PER_LEVEL

	var/additional_points = 0
	var/player_points_defcon = 0
	var/last_objectives_scored_points = 0
	var/last_objectives_total_points = 0
	var/last_objectives_completion_percentage = 0

	var/level_triggers_additional_points = 0
	var/level_triggers_modificator = 28

	var/first_drop_complete = FALSE
	var/datum/cm_objective/communications/comms
	var/datum/cm_objective/power/establish_power/power
	var/datum/cm_objective/recover_corpses/corpsewar

/datum/objectives_datum/New(faction_to_get)
	associated_faction = faction_to_get
	comms = new(associated_faction)
	power = new(associated_faction)
	corpsewar = new(associated_faction)
	RegisterSignal(SSdcs, COMSIG_GLOB_DS_FIRST_LANDED, PROC_REF(on_landing))

/datum/objectives_datum/proc/check_status()
	if(length(GLOB.faction_datums[associated_faction].totalMobs))
		return TRUE
	return FALSE

/datum/objectives_datum/proc/add_objective_spawn(objective_spawn_name, objective_spawn_weight, objective_spawn_location)
	var/found = FALSE
	for(var/datum/objective_spawn_handler/objectives_handler in objective_spawns[objective_spawn_name])
		if(objectives_handler.weight != objective_spawn_weight)
			continue
		objectives_handler.linked_spawns += objective_spawn_location
		found = TRUE
		break

	if(!found)
		if(!objective_spawns[objective_spawn_name])
			objective_spawns[objective_spawn_name] = list()
		objective_spawns[objective_spawn_name] += new /datum/objective_spawn_handler(objective_spawn_name, objective_spawn_weight, objective_spawn_location)

/datum/objectives_datum/proc/generate_objectives()
	var/datum/faction/faction = GLOB.faction_datums[associated_faction]
	if(!faction.objectives_active && length(faction.objectives))
		return

	var/faction_pop_scale = length(faction.totalMobs) * 0.05
	//TODO: Combine objectives and faction tasks, plus make more "specialized" objectives and change system in per faction special faction objectives handler.
	for(var/subtyope in faction.objectives)
		var/ammount = faction.objectives[subtyope] * faction_pop_scale
		var/objective_type
		if(!length(objective_spawns[subtyope]))
			continue
		for(var/i = 1 to ammount)
			var/list/potential_spawns = list()
			objective_type = pick(GLOB.objectives_links[subtyope])
			for(var/datum/objective_spawn_handler/objectives_handler in objective_spawns[subtyope])
				var/atom/new_potential_spawn = SAFEPICK(objectives_handler.linked_spawns)
				if(!new_potential_spawn)
					continue
				//TODO: Make multi use spawning objection points (something like GLOB.machines)
				objectives_handler.linked_spawns -= new_potential_spawn
				potential_spawns += new_potential_spawn

			if(!length(potential_spawns))
				return

			var/atom/chosen_spawn = pick(potential_spawns)
			var/generated = FALSE
			if(!istype(chosen_spawn, /turf))
				var/obj/item/new_item = new objective_type(chosen_spawn, associated_faction)
				chosen_spawn.contents += new_item
				generated = TRUE
				break

			if(!generated)
				new objective_type(get_turf(chosen_spawn), associated_faction)

//TODO: Through this is datum make spawns and custom objectives, not only items (like terminals, safes and etc)
/datum/objective_spawn_handler
	var/name = "normal"
	var/weight = 20
	var/list/atom/linked_spawns = list()

/datum/objective_spawn_handler/New(objective_spawn_name, objective_spawn_weight, objective_linked_spawns)
	name = objective_spawn_name
	weight = objective_spawn_weight
	linked_spawns += objective_linked_spawns

/datum/objectives_datum/proc/add_objective(datum/cm_objective/objective)
	objectives += objective

/datum/objectives_datum/proc/remove_objective(datum/cm_objective/objective)
	objectives -= objective

/datum/objectives_datum/proc/start_processing_objective(datum/cm_objective/objective)
	processing_objectives += objective

/datum/objectives_datum/proc/stop_processing_objective(datum/cm_objective/objective)
	processing_objectives -= objective

/datum/objectives_datum/proc/on_landing(faction)
	SIGNAL_HANDLER
	if(faction == associated_faction)
		first_drop_complete = TRUE
		UnregisterSignal(SSdcs, COMSIG_GLOB_DS_FIRST_LANDED)

/datum/objectives_datum/proc/check_objectives_percentage()
	if(current_level == 1)
		return "MAXIMUM"
	else
		if(!level_triggers_modificator)
			return "ERROR"
		var/percentage = last_objectives_scored_points / player_points_defcon
		return percentage * 100

/datum/objectives_datum/proc/check_defcon_level()
	last_objectives_scored_points = SSfactions.get_scored_points(associated_faction) + additional_points
	last_objectives_total_points = SSfactions.get_total_points(associated_faction)
	player_points_defcon = (level_triggers_modificator * max(length(GLOB.faction_datums[associated_faction].totalMobs), 1) + level_triggers_additional_points) * real_current_level * 0.65
	last_objectives_completion_percentage = check_objectives_percentage()
	if(current_level > 1)
		if(last_objectives_scored_points > player_points_defcon)
			decrease_level()

/datum/objectives_datum/proc/decrease_level()
	if(current_level > 1)
		current_level--
		real_current_level++
		remaining_reward_points +=  REWARD_POINT_GAIN_PER_LEVEL * real_current_level + REWARD_POINT_GAIN_PER_LEVEL
		level_triggers_additional_points += rand(level_triggers_modificator, length(GLOB.faction_datums[associated_faction].totalMobs) * 4)
		chemical_data.update_credits(real_current_level * 4)
		announce_level()
		SSticker.mode.defcon_event(GLOB.faction_datums[associated_faction], real_current_level)

/datum/objectives_datum/proc/add_reward_points(amount)
	remaining_reward_points += amount

/datum/objectives_datum/proc/add_defcon_points(amount)
	additional_points += amount

/datum/objectives_datum/proc/announce_level()
	var/name = "[r_uppertext(GLOB.faction_datums[associated_faction])] DEFCON LEVEL LOWERED"
	var/input = "THREAT ASSESSMENT LEVEL INCREASED TO [last_objectives_completion_percentage]%.\n\nDEFCON level lowered to [current_level]. Additional assets have been authorised to handle the situation."
	faction_announcement(input, name, 'sound/AI/commandreport.ogg', GLOB.faction_datums[associated_faction])
	if(associated_faction == FACTION_MARINE)
		SSticker.mode.round_statistics.defcon_level = current_level

/datum/objectives_datum/proc/list_and_purchase_rewards()
	var/list/datum/objectives_reward/rewards_for_purchase = available_rewards()
	if(!length(rewards_for_purchase))
		to_chat(usr, usr.client.auto_lang(LANGUAGE_DEFCON_NO_MORE))
	var/pick = tgui_input_list(usr, usr.client.auto_lang(LANGUAGE_DEFCON_CHOICE), usr.client.auto_lang(LANGUAGE_MUTATION_CONFIRM), rewards_for_purchase)
	if(!pick)
		return FALSE
	var/datum/objectives_reward/reward = rewards_for_purchase[pick]
	if(reward.apply_reward(src))
		to_chat(usr, usr.client.auto_lang(LANGUAGE_DEFCON_GRANTED))
		reward.announce_reward()
		return TRUE
	else
		to_chat(usr, usr.client.auto_lang(LANGUAGE_DEFCON_GRANTED_FAILED))
		return FALSE

//Lists rewards available for purchase
/datum/objectives_datum/proc/available_rewards()
	var/list/can_purchase = list()
	var/list/rewards = GLOB.objectives_reward_list[associated_faction]
	if(!remaining_reward_points || !length(rewards)) //No points - can't buy anything
		return FALSE

	for(var/datum/objectives_reward/reward in rewards)
		if(can_purchase_reward(reward))
			LAZYSET(can_purchase, "[usr.client.auto_lang(reward.name)] ([reward.cost] [usr.client.auto_lang(LANGUAGE_POINTS)])", reward)

	return can_purchase

/datum/objectives_datum/proc/can_purchase_reward(datum/objectives_reward/reward)
	if(current_level > reward.minimum_level)
		return FALSE
	if(remaining_reward_points < reward.cost)
		return FALSE
	if(reward.unique)
		if(reward.name in purchased_rewards)
			return FALSE
	if(reward.accessing_type & DEFCON_ASSET_DELIVERY_CARGO && MODE_HAS_FLAG(MODE_NO_SHIP_MAP) && !(reward.accessing_type & DEFCON_ASSET_DELIVERY) && !(reward.accessing_type & DEFCON_ASSET_VEND))
		return FALSE
	return TRUE

//A class for rewarding the next DEFCON level being reached
/datum/objectives_reward
	var/name = "Reward"
	var/cost = null //Cost to get this reward
	var/minimum_level = 0 //DEFCON needs to be at this level or LOWER
	var/unique = FALSE //Whether the reward is unique or not
	var/announcement_message = "YOU SHOULD NOT BE SEEING THIS MESSAGE. TELL A DEV." //Message to be shared after a reward is purchased
	var/associated_faction

	var/accessing_type
	var/reward_name

/datum/objectives_reward/proc/announce_reward(name = "SPECIAL ASSETS AUTHORISED")
	faction_announcement(announcement_message, name, 'sound/misc/notice2.ogg', GLOB.faction_datums[associated_faction])

/datum/objectives_reward/proc/apply_reward(datum/objectives_datum/d)
	if(d.remaining_reward_points < cost)
		return FALSE

	if(reward_name)
		if(accessing_type & DEFCON_ASSET_VEND)
			GLOB.gears_defcon[reward_name].on_unlock()

		else if(accessing_type & DEFCON_ASSET_DELIVERY && (MODE_HAS_FLAG(MODE_NO_SHIP_MAP) || associated_faction != FACTION_MARINE))
			var/obj/structure/droppod/supply/pod = new()
			var/atom/container = pod
			var/datum/supply_packs/package = supply_controller.supply_packs[reward_name]
			if(package.containertype)
				container = new package.containertype(container)
				if(package.containername)
					container.name = package.containername

			var/list/content_types = package.contains
			if(package.randomised_num_contained)
				content_types = list()
				for(var/i in 1 to package.randomised_num_contained)
					content_types += pick(package.contains)

			for(var/typepath in content_types)
				new typepath(container)

			pod.launch(get_turf(pick(GLOB.defcon_drop_point[associated_faction])))

		else if(accessing_type & DEFCON_ASSET_DELIVERY_CARGO)
			var/datum/supply_order/O = new /datum/supply_order()
			O.ordernum = supply_controller.ordernum
			supply_controller.ordernum++
			O.object = supply_controller.supply_packs[reward_name]
			O.orderedby = GLOB.faction_datums[associated_faction]
			supply_controller.shoppinglist += O

	d.remaining_reward_points -= cost
	d.purchased_rewards += name
	return TRUE



//******************************************************************************************//
/datum/objectives_reward/upp
	associated_faction = FACTION_UPP



//5 DEFCON//
/datum/objectives_reward/upp/support_kits
	name = LANGUAGE_DEFCON_KITS
	cost = REWARD_COST_PRICEY
	minimum_level = 5
	unique = TRUE
	announcement_message = "Специальные наборы для медиков и инженеров в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "UPP Support Kits"



//4 DEFCON//
/datum/objectives_reward/upp/squad
	name = LANGUAGE_DEFCON_UNITS
	cost = REWARD_COST_MODERATE
	minimum_level = 4
	announcement_message = "Дополнительные морпехи подняты из крио."

/datum/objectives_reward/upp/cryo_squad/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return

	SSticker.mode.get_specific_call("Marine Cryo Reinforcements (Full Equipment) (Squad)", FALSE, FALSE)


/datum/objectives_reward/upp/implants
	name = LANGUAGE_DEFCON_IMPLANTS
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 4
	unique = TRUE
	announcement_message = "Импланты в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "UPP Implants"


/datum/objectives_reward/upp/ammo
	name = LANGUAGE_DEFCON_AMMO
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 4
	unique = TRUE
	announcement_message = "Особые патроны в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "UPP Special Ammo"



//3 DEFCON//
/datum/objectives_reward/upp/exp_kits
	name = LANGUAGE_DEFCON_GUNS
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 3
	unique = TRUE
	announcement_message = "Наборы эксперементального вооружения в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "UPP Experemental Guns Kits"


/datum/objectives_reward/upp/spec_kits
	name = LANGUAGE_DEFCON_SPEC
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 3
	unique = TRUE
	announcement_message = "Наборы специалистов были загружены в карго лифт."

	accessing_type = DEFCON_ASSET_DELIVERY|DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "UPP Weapons Specialist Kits"



//2 DEFCON//
/datum/objectives_reward/upp/tank_points
	name = LANGUAGE_DEFCON_LTB
	cost = REWARD_COST_LUDICROUS
	minimum_level = 2
	unique = TRUE
	announcement_message = "Были доставлены дополнительные ресурсы на танк с тяжелым оружием."

	accessing_type = DEFCON_ASSET_DELIVERY|DEFCON_ASSET_DELIVERY_CARGO
	// I have to write this abomination because of ASRS
	var/datum/supply_packs/VK = /datum/supply_packs/vc_kit
	var/datum/supply_packs/ALC =  /datum/supply_packs/ammo_ltb_cannon
	var/datum/supply_packs/AGL = /datum/supply_packs/ammo_glauncher

/datum/objectives_reward/upp/tank_points/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return

	var/to_order = list(
		initial(VK.name),
		initial(ALC.name),
		initial(AGL.name)
	)
	if(accessing_type & DEFCON_ASSET_DELIVERY && (MODE_HAS_FLAG(MODE_NO_SHIP_MAP) || associated_faction != FACTION_MARINE))
		var/obj/structure/droppod/supply/tank_pod = new()
		new /obj/vehicle/multitile/tank/fixed_ltb(tank_pod, associated_faction)
		tank_pod.launch(get_turf(pick(GLOB.defcon_drop_point[associated_faction])))
		for(var/order in to_order)
			var/obj/structure/droppod/supply/pod = new()
			var/atom/container = pod
			var/datum/supply_packs/package = supply_controller.supply_packs[reward_name]
			if(package.containertype)
				container = new package.containertype(container)
				if(package.containername)
					container.name = package.containername

			var/list/content_types = package.contains
			if(package.randomised_num_contained)
				content_types = list()
				for(var/i in 1 to package.randomised_num_contained)
					content_types += pick(package.contains)

			for(var/typepath in content_types)
				new typepath(container)

			pod.launch(get_turf(pick(GLOB.defcon_drop_point[associated_faction])))

	else if(accessing_type & DEFCON_ASSET_DELIVERY_CARGO)
		var/obj/structure/machinery/computer/supplycomp/vehicle/comp = VehicleElevatorConsole
		if(!comp)
			return

		comp.spent = FALSE
		QDEL_NULL_LIST(comp.vehicles)
		comp.vehicles = list(
			new/datum/vehicle_order/tank/ltb/upp()
		)
		comp.allowed_roles = null
		comp.req_access = list()
		comp.req_one_access = list()

		for(var/order in to_order)
			var/datum/supply_order/O = new /datum/supply_order()
			O.ordernum = supply_controller.ordernum
			supply_controller.ordernum++
			O.object = supply_controller.supply_packs[order]
			O.orderedby = MAIN_AI_SYSTEM

			supply_controller.shoppinglist += O

/obj/vehicle/multitile/tank/fixed_ltb/load_hardpoints(obj/vehicle/multitile/R)
	..()

	add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	add_hardpoint(new /obj/item/hardpoint/armor/ballistic)
	add_hardpoint(new /obj/item/hardpoint/locomotion/treads)

	var/obj/item/hardpoint/holder/tank_turret/T = locate() in hardpoints
	if(!T)
		return

	T.add_hardpoint(new /obj/item/hardpoint/primary/cannon)
	T.add_hardpoint(new /obj/item/hardpoint/secondary/grenade_launcher)


/datum/vehicle_order/tank/ltb/upp
	faction_to_get = FACTION_UPP



//******************************************************************************************//
/datum/objectives_reward/marine
	associated_faction = FACTION_MARINE



//5 DEFCON//
/datum/objectives_reward/marine/supply_points
	name = LANGUAGE_DEFCON_SUPPLY_BUDGET
	cost = REWARD_COST_MODERATE
	minimum_level = 5
	announcement_message = "Дополнительный бюджет выделен для карго."

/datum/objectives_reward/marine/supply_points/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return
	supply_controller.points += 2000


/datum/objectives_reward/marine/dropship_part_fabricator_points
	name = LANGUAGE_DEFCON_DS_FAB
	cost = REWARD_COST_MODERATE
	minimum_level = 5
	announcement_message = "Дополнительный бюджет выделен для фабрикатору для шатлов."

/datum/objectives_reward/marine/dropship_part_fabricator_points/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return
	supply_controller.dropship_points += 2800 //Enough for both fuel enhancers, or about 3.5 fatties


/datum/objectives_reward/marine/ob_he
	name = LANGUAGE_DEFCON_OB_HE
	cost = REWARD_COST_CHEAP
	minimum_level = 5
	announcement_message = "Дополнительные боеприпасы орбитального орудия (HE, количество: 2) были загружены в карго лифт."

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "OB HE Crate"


/datum/objectives_reward/marine/ob_cluster
	name = LANGUAGE_DEFCON_OB_C
	cost = REWARD_COST_CHEAP
	minimum_level = 5
	announcement_message = "Дополнительные боеприпасы орбитального орудия (Cluster, количество: 2) были загружены в карго лифт."

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "OB Cluster Crate"


/datum/objectives_reward/marine/ob_incendiary
	name = LANGUAGE_DEFCON_OB_INC
	cost = REWARD_COST_CHEAP
	minimum_level = 5
	announcement_message = "Дополнительные боеприпасы орбитального орудия (Incendiary, количество: 2) были загружены в карго лифт."

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "OB Incendiary Crate"


/datum/objectives_reward/marine/support_kits
	name = LANGUAGE_DEFCON_KITS
	cost = REWARD_COST_PRICEY
	minimum_level = 5
	unique = TRUE
	announcement_message = "Специальные наборы для медиков и инженеров в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "Support Kits"



//4 DEFCON//
/datum/objectives_reward/marine/cryo_squad
	name = LANGUAGE_DEFCON_WAKE_UNITS
	cost = REWARD_COST_MODERATE
	minimum_level = 4
	announcement_message = "Дополнительные морпехи подняты из крио."

/datum/objectives_reward/marine/cryo_squad/apply_reward(datum/objectives_datum/d)
	if(!SSticker.mode)
		return

	. = ..()
	if(. == FALSE)
		return

	SSticker.mode.get_specific_call("Marine Cryo Reinforcements (Full Equipment) (Squad)", FALSE, FALSE)


/datum/objectives_reward/marine/implants
	name = LANGUAGE_DEFCON_IMPLANTS
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 4
	unique = TRUE
	announcement_message = "Импланты в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "Implants"


/datum/objectives_reward/marine/ammo
	name = LANGUAGE_DEFCON_AMMO
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 4
	unique = TRUE
	announcement_message = "Особые патроны в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "Special Ammo"



//3 DEFCON//
/datum/objectives_reward/marine/chemical_points
	name = LANGUAGE_DEFCON_RESEARCH
	cost = REWARD_COST_PRICEY
	minimum_level = 3
	announcement_message = "Дополнительный бюджет выделен научному отделу."

/datum/objectives_reward/marine/chemical_points/apply_reward(datum/objectives_datum/d)
	if(!SSticker.mode)
		return

	. = ..()
	if(. == FALSE)
		return

	chemical_data.update_credits((6 - d.current_level)*6)


/datum/objectives_reward/marine/exp_kits
	name = LANGUAGE_DEFCON_GUNS
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 3
	unique = TRUE
	announcement_message = "Наборы эксперементального вооружения в наличии в SOGV."

	accessing_type = DEFCON_ASSET_VEND
	reward_name = "Experemental Guns Kits"


/datum/objectives_reward/marine/spec_kits
	name = LANGUAGE_DEFCON_SPEC
	cost = REWARD_COST_EXPENSIVE
	minimum_level = 3
	announcement_message = "Наборы специалистов были загружены в карго лифт."

	accessing_type = DEFCON_ASSET_DELIVERY|DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "Weapons Specialist Kits"



//2 DEFCON//
/datum/objectives_reward/marine/rocket_launcher
	name = LANGUAGE_DEFCON_ROCKETS
	cost = REWARD_COST_LUDICROUS
	minimum_level = 2
	unique = TRUE
	announcement_message = "Ракетные батареи разблокированы."
	var/obj/structure/machinery/computer/rocket_launcher/rocket_launcher_type = /obj/structure/machinery/computer/rocket_launcher

/datum/objectives_reward/marine/rocket_launcher/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return
	for(var/a in GLOB.rocket_launcher_computer_turf_position)
		var/datum/rocket_launcher_computer_location/RLCL = a
		var/turf/T = RLCL.coords.get_turf_from_coord()
		if(!T)
			continue

		var/obj/structure/machinery/computer/rocket_launcher/RLG = new rocket_launcher_type(T)
		RLG.dir = RLCL.direction

/datum/objectives_reward/marine/tank_points
	name = LANGUAGE_DEFCON_LTB
	cost = REWARD_COST_LUDICROUS
	minimum_level = 2
	unique = TRUE
	announcement_message = "Были доставлены дополнительные ресурсы на танк с тяжелым оружием."

	accessing_type = DEFCON_ASSET_DELIVERY|DEFCON_ASSET_DELIVERY_CARGO

	var/datum/supply_packs/VK = /datum/supply_packs/vc_kit
	var/datum/supply_packs/ALC =  /datum/supply_packs/ammo_ltb_cannon
	var/datum/supply_packs/AGL = /datum/supply_packs/ammo_glauncher

/datum/objectives_reward/marine/tank_points/apply_reward(datum/objectives_datum/d)
	. = ..()
	if(. == FALSE)
		return

	var/to_order = list(
		initial(VK.name),
		initial(ALC.name),
		initial(AGL.name)
	)
	if(accessing_type & DEFCON_ASSET_DELIVERY && (MODE_HAS_FLAG(MODE_NO_SHIP_MAP) || associated_faction != FACTION_MARINE))
		var/obj/structure/droppod/supply/tank_pod = new()
		new /obj/vehicle/multitile/tank/fixed_ltb(tank_pod, associated_faction)
		tank_pod.launch(get_turf(pick(GLOB.defcon_drop_point[associated_faction])))
		for(var/order in to_order)
			var/obj/structure/droppod/supply/pod = new()
			var/atom/container = pod
			var/datum/supply_packs/package = supply_controller.supply_packs[reward_name]
			if(package.containertype)
				container = new package.containertype(container)
				if(package.containername)
					container.name = package.containername

			var/list/content_types = package.contains
			if(package.randomised_num_contained)
				content_types = list()
				for(var/i in 1 to package.randomised_num_contained)
					content_types += pick(package.contains)

			for(var/typepath in content_types)
				new typepath(container)

			pod.launch(get_turf(pick(GLOB.defcon_drop_point[associated_faction])))

	else if(accessing_type & DEFCON_ASSET_DELIVERY_CARGO)
		var/obj/structure/machinery/computer/supplycomp/vehicle/comp = VehicleElevatorConsole
		if(!comp)
			return

		comp.spent = FALSE
		QDEL_NULL_LIST(comp.vehicles)
		comp.vehicles = list(
			new/datum/vehicle_order/tank/ltb()
		)
		comp.allowed_roles = null
		comp.req_access = list()
		comp.req_one_access = list()

		for(var/order in to_order)
			var/datum/supply_order/O = new /datum/supply_order()
			O.ordernum = supply_controller.ordernum
			supply_controller.ordernum++
			O.object = supply_controller.supply_packs[order]
			O.orderedby = MAIN_AI_SYSTEM

			supply_controller.shoppinglist += O


/datum/supply_packs/vc_kit
	name = "Vehicle Crewman Kits"
	contains = list(
		/obj/item/pamphlet/skill/vc,
		/obj/item/pamphlet/skill/vc
	)
	cost = 0
	containertype = /obj/structure/closet/crate/supply
	containername = "vehicle crewman kits crate"
	buyable = 0
	group = "Operations"
	iteration_needed = null

/obj/item/pamphlet/skill/vc
	name = "vehicle training manual"
	desc = "A manual used to quickly impart vital knowledge on driving vehicles."
	icon_state = "pamphlet_vehicle"
	trait = /datum/character_trait/skills/vc
	bypass_pamphlet_limit = TRUE

/obj/vehicle/multitile/tank/fixed_ltb/load_hardpoints(obj/vehicle/multitile/R)
	..()

	add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	add_hardpoint(new /obj/item/hardpoint/armor/ballistic)
	add_hardpoint(new /obj/item/hardpoint/locomotion/treads)

	var/obj/item/hardpoint/holder/tank_turret/T = locate() in hardpoints
	if(!T)
		return

	T.add_hardpoint(new /obj/item/hardpoint/primary/cannon)
	T.add_hardpoint(new /obj/item/hardpoint/secondary/grenade_launcher)

/datum/vehicle_order/tank/ltb
	name = "M34A2 Longstreet Light Tank"
	ordered_vehicle = /obj/vehicle/multitile/tank/fixed_ltb

/datum/vehicle_order/tank/ltb/has_vehicle_lock()
	return FALSE

/datum/vehicle_order/tank/ltb/on_created(obj/vehicle/multitile/tank/fixed_ltb/tank)
	tank.req_one_access = list()


/datum/objectives_reward/marine/turrets
	name = LANGUAGE_DEFCON_SPECIAL_ASSETS
	cost = REWARD_COST_LUDICROUS
	minimum_level = 2
	unique = TRUE
	announcement_message = "Специальные наборы для укрепления позиций доставлены в карго, внимание, требуется использовать с повышенной осторожностью, не забудьте выполнить протокол перед использованием и все расходы USCM теперь на вашей ответсвенности"

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "Operational Special Assets"//TODO: Add here more funny assets

/datum/objectives_reward/marine/nuke/announce_reward(name = "СТРАТЕГИЧЕСКОЕ ЭКСПЕРЕМЕНТАЛЬНОЕ ОРУЖИЕ АВТОРИЗОВАННО")
	faction_announcement(announcement_message, name, 'sound/misc/notice1.ogg')


/datum/objectives_reward/marine/nuke
	name = LANGUAGE_DEFCON_PLANETARY_NUKE
	cost = REWARD_COST_MAX
	minimum_level = 2
	unique = TRUE
	announcement_message = "Ядерная боеголовка была загружена в карго лифт, не забудьте выполнить протокол перед использованием и все расходы USCM теперь на вашей ответсвенности, также требуется соблюсти 10 пунктов из операционных правил USCM по применению оружия."

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "Encrypted Operational Nuke"

/datum/objectives_reward/marine/nuke/announce_reward(name = "СТРАТЕГИЧЕСКОЕ ЯДЕРНОЕ ОРУЖИЕ АВТОРИЗОВАННО")
	faction_announcement(announcement_message, name, 'sound/misc/notice1.ogg')



//1 DEFCON//
/datum/objectives_reward/marine/obnuke
	name = LANGUAGE_DEFCON_OB_NUKE
	cost = REWARD_COST_MAX
	minimum_level = 1
	unique = TRUE
	announcement_message = "Орбитальная ядерная боеголовка была загружена в карго лифт, не забудьте выполнить протокол перед использованием и все расходы USCM теперь на вашей ответсвенности, а также требуется соблюсти 93 пункта использования космического ядерного оружия вблизи планет и 10 пунктов из операционных правил USCM по применению оружия."

	accessing_type = DEFCON_ASSET_DELIVERY_CARGO
	reward_name = "Operational OB Nuke"

/datum/objectives_reward/marine/obnuke/announce_reward(name = "СТРАТЕГИЧЕСКОЕ КОСМИЧЕСКОЕ ЯДЕРНОЕ ОРУЖИЕ АВТОРИЗОВАННО")
	faction_announcement(announcement_message, name, 'sound/misc/notice1.ogg')
