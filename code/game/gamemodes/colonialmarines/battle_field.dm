#define BF_MAX_EVENT_TIER	8
#define BF_MAX_EVENT_ID		50

//Global proc for checking if the game is whiskey outpost so I dont need to type if(gamemode == whiskey outpost) 50000 times
/proc/Check_BF()
	if(SSticker.mode == MODE_NAME_BATTLE_FIELD || GLOB.master_mode == MODE_NAME_BATTLE_FIELD)
		return TRUE
	return FALSE

/datum/game_mode/battle_field
	name = MODE_NAME_BATTLE_FIELD
	config_tag = MODE_NAME_BATTLE_FIELD
	required_players 		= 0
	xeno_bypass_timer 		= 1
	flags_round_type = MODE_NEW_SPAWN

	roles_setting_tp = /datum/mode_roles_settings/wo

	latejoin_larva_drop = 0 //You never know

	//var/mob/living/carbon/human/Commander //If there is no Commander, marines wont get any supplies
	//No longer relevant to the game mode, since supply drops are getting changed.
	var/checkwin_counter = 0
	var/finished = 0
	var/has_started_timer = 10 //This is a simple timer so we don't accidently check win conditions right in post-game
	var/randomovertime = 1 MINUTES //This is a simple timer so we can add some random time to the game mode.
	var/spawn_next_event = 8 MINUTES //Spawn first batch at ~12 minutes

	var/list/turf/enemy_spawn = list()
	var/list/turf/event_spawn = list()

	var/list/players = list()

	//Who to spawn and how often which caste spawns
		//The more entires with same path, the more chances there are to pick it
			//This will get populated with spawn_xenos() proc
	var/list/spawnenemy = list()

	var/current_event_tier = 1

	var/ending = 0 //type of end

	var/special_game_mode = "Нормально"
	var/mini_sectors_accepted = 2
	var/crafting_probability = 1.0
	var/additional_changes
	var/list/enemy_pool = list()
	var/list/event_dropp_pool = list()
	var/list/event_objectives_pool = list()

	var/event_ticks_passed

	var/ticks_passed = 0
	var/lobby_time = 0 //Lobby time does not count for marine 1h win condition


	var/spawn_next_bf_event = FALSE
	var/xeno_debuff_percent = 50 //% debuff xeno

	var/list/bf_events = list()
	var/bf_event_tier = 0

	special_core = TRUE
	votable = FALSE // not fun

/datum/game_mode/battle_field/announce()
	return TRUE

/datum/game_mode/battle_field/pre_setup()
	for(var/obj/effect/landmark/battle_field/enemy_spawn/ES)
		var/i = ES.additional_info
		enemy_spawn += ES
		enemy_spawn[i] = list()
	for(var/obj/effect/landmark/battle_field/event_spawn/EVS)
		var/i = EVS.additional_info
		event_spawn += EVS
		event_spawn[i] = list()


	//  BF random
	var/list/paths = typesof(/datum/battle_field_events)
	for(var/i in 1 to BF_MAX_EVENT_ID)
		bf_events += i
		bf_events[i] = list()
	for(var/T in paths)
		var/datum/battle_field_events/BFE = new T
		if(BFE.event_tier == 0)
			bf_events[BFE.event_id] += BFE

	return ..()

/datum/game_mode/battle_field/post_setup()
	set waitfor = FALSE
	update_controllers()
	initialize_post_marine_gear_list()
	lobby_time = world.time

	for(var/turf/floor/trench/fake/T in world)//Make all the fake trenches into real ones.
		T.ChangeTurf(/turf/floor/trench)

	CONFIG_SET(flag/remove_gun_restrictions, TRUE)
	sleep(10)
	to_world(SPAN_ROUNDHEADER("В данный момент игровой режим - [name]!"))

	to_world(SPAN_ROUNDBODY("Сложность [special_game_mode], Количество подсекторов [mini_sectors_accepted], Сложность рецептов [crafting_probability]."))
	if(additional_changes)
		to_world(SPAN_ROUNDBODY("Дополнительные настройки: [additional_changes]."))

	to_world(SPAN_ROUNDBODY("Это 2184 год, планета LV-21, стратегическая экономическая и военная точка, за этот мир давно уже идут сражения"))
	to_world(SPAN_ROUNDBODY("Данная планета имеет огромные залежы ресурсов, а также уже хорошо развитую инфраструктуру и промышленность"))
	to_world(SPAN_ROUNDBODY("В секторе DELTA на планете [SSmapping.configs[GROUND_MAP].map_name], была основана стратегическая база 3 года назад"))
	to_world(SPAN_ROUNDBODY("К сожалению вы отрезаны от USCM и зажаты, они стремятся помочь как могу, но к сожалению все четно, огромные планетарные баттареи сбивают все корабли на подлете"))
	to_world(SPAN_ROUNDBODY("До ближайшего союзного укрепленного поселения более 2000 километров, без воздушного транспорта это почти невыполнимо, если бы мы успели даже до того как враги уничтожат его"))
	to_world(SPAN_ROUNDBODY("Враг делает успех последние 2 месяца, мы должны стоять до конца и захватить одну из планетарных баттарей, нам срочно надо взять этот сектор под свой контроль"))
	to_world(SPAN_ROUNDBODY("Нам надо надеятся только на себя."))

	world << sound('sound/effects/siren.ogg')

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(show_blurb_uscm), 0, "Специальный Отряд. 'Железный Кулак'", "Аванпост 'Бесконечность'"))

	addtimer(CALLBACK(src, PROC_REF(story_announce), 0, 20), 10 MINUTES)
	return ..()

/datum/game_mode/battle_field/proc/story_announce(time, dop_timer)
	switch(time)
		if(0)
			faction_announcement("К сожалению враги вас окружили, у нас нет точной информации, но вас эвакуировать не удастся, планетарные баттареии были захвачены врагом, более 100 укреплений и баз были окружены, глобальная энергетическая система планеты повреждена *bzzzzzzzzzzz* $@(зь по)*@ н*@ б*мб(!... *shhhhhhhh*", "Глава Безопасности Жарго, Планетарная Администрация, Колония 'Авка'")
		if(1)
			faction_announcement("Мы начинаем эвакуацию, 4 и 6 планетарная баттарея выведена из строя, к сожалению высшее командывание считает что битва проиграна, нам приказывают эвакуировать всех солдат... К сожалению враг захватывает все больше инфраструктуры, городов, укреплений. Нам некуда отступать, к сожалению мы не можем вас спасти, наши силы на исходе. Вам придеться самим вырываться оттуда, или надеяться на то что скоро прибудет тяжелая артилерия и мы сможем вернуть контроль хотябы кое-где себе. К сожалению командывание не решается бомбить планету. Скорее всего это последние мое вам сообщение.", "Глава Безопасности Жарго, Планетарная Администрация, Колония 'Авка'")
		if(2)
			faction_announcement("Все кто слышит это оповещение, мы уже идем. Командывание дало зеленый свет на атаку. Ситуация накаляется, началась открытая война. Если вы меня слышите, посторайтесь вывести из строя как можно больше вражеской защиты, мы надеемся понести как можно меньше потерь и не использовать оружие массового поражения,  новые ракеты 'Dead Touch'. Пока что мы ведем активное сражение с вражиским флотом, но мы спешим как можем!", "Командир  Кардац, Флагман 'USS Cvarth', Флотилия 'USS Dead Hand'")

	if(time == 3 && ending == 0) //??? ending
		faction_announcement("Пора ликовать! Враг отступает!", "Оператор ALPHA-3, Командный Центр, Главное Командывание")

	if(time == 3 && ending == 1) //good ending
		faction_announcement("Эвакуация начнется прямо сейчас, готовтесь!", "Командир  Кардац, Флагман 'USS Cvarth', Флотилия 'USS Dead Hand'")

	if(time == 3 && ending == 2) //neutral ending
		faction_announcement("К сожалению мы отступаем и не сможем вам помочь, мы терпим огромные потери.", "Заместитель Командира(Кардац) Кристиан, Тяжелый Корабль 'USS Garpun', Флотилия 'USS Dead Hand'")

	if(time == 3 && ending == 3) //bad ending
		faction_announcement("Мы запускаем новые ракеты массового уничтожения... В связи с ситуацией... у нас нет выбора! Простите братья.", "Командир  Кардац, Флагман 'USS Cvarth', Флотилия 'USS Dead Hand'")

	if(time <= 2)
		addtimer(CALLBACK(src, PROC_REF(story_announce), time+1, dop_timer+15), dop_timer MINUTES)

/datum/game_mode/battle_field/proc/update_controllers()
	//Update controllers while we're on this mode
	if(SSitem_cleanup)
		//Cleaning stuff more aggresively
		SSitem_cleanup.start_processing_time = 0
		SSitem_cleanup.percentage_of_garbage_to_delete = 0.25
		SSitem_cleanup.wait = 1 MINUTES
		SSitem_cleanup.next_fire = 1 MINUTES
		spawn(0)
			//Deleting Almayer, for performance!
			SSitem_cleanup.delete_almayer()


//PROCCESS
/datum/game_mode/battle_field/process(delta_time)
	. = ..()
	checkwin_counter++
	ticks_passed++
	event_ticks_passed++

	if(event_ticks_passed >= (spawn_next_event/(delta_time SECONDS)))
		event_ticks_passed = 0
		spawn_next_bf_event = TRUE

	if(spawn_next_bf_event)
		spawn_next_bf_event()

	if(has_started_timer > 0)
		has_started_timer--

	if(checkwin_counter >= 10) //Only check win conditions every 10 ticks.
		if(!finished && round_should_check_for_win && ending)
			check_win()
		checkwin_counter = 0
	return 0


//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relevant information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/battle_field/declare_completion()
	if(round_statistics)
		round_statistics.track_round_end()
	if(finished == 1)
		log_game("Round end result - second side won")
		to_world(SPAN_ROUNDHEADER("Последние укрепления маринов на LV21 пали."))
		to_world(SPAN_ROUNDBODY("Этот бой оказался непосилен маринам, к сожалению это конец истории маринов на планете LV21!"))
		world << sound('sound/misc/Game_Over_Man.ogg')
		if(round_statistics)
			round_statistics.round_result = MODE_INFESTATION_X_MAJOR
			if(round_statistics.current_map)
				round_statistics.current_map.total_xeno_victories++
				round_statistics.current_map.total_xeno_majors++

	else if(finished == 2)
		log_game("Round end result - marines won")
		to_world(SPAN_ROUNDHEADER("Glory to mens and womens of Battle Fields LV21."))
		addtimer(CALLBACK(src, PROC_REF(story_announce), 3))
		switch(ending)
			if(0)
				to_world(SPAN_ROUNDBODY("Планета была отбита"))
			if(1)
				to_world(SPAN_ROUNDBODY("Все марины были спасены"))
			if(2)
				to_world(SPAN_ROUNDBODY("Бравые марины остались одни на планете"))
				world << sound('sound/effects/siren.ogg')
			if(3)
				to_world(SPAN_ROUNDBODY("На фоне лишь только взрывы и ничего более..."))
				world << sound('sound/effects/siren.ogg')

		if(round_statistics)
			round_statistics.round_result = MODE_INFESTATION_M_MAJOR
			if(round_statistics.current_map)
				round_statistics.current_map.total_marine_victories++
				round_statistics.current_map.total_marine_majors++

		addtimer(CALLBACK(src, PROC_REF(end_game_music)), 0.1 MINUTES)

	else
		log_game("Round end result - no winners")
		to_world(SPAN_ROUNDHEADER("NOBODY WON!"))
		to_world(SPAN_ROUNDBODY("How? Don't ask me..."))
		world << 'sound/misc/sadtrombone.ogg'
		if(round_statistics)
			round_statistics.round_result = MODE_INFESTATION_DRAW_DEATH

	if(round_statistics)
		round_statistics.game_mode = name
		round_statistics.round_length = world.time
		round_statistics.end_round_player_population = GLOB.clients.len

		round_statistics.log_round_statistics()

		round_finished = 1

	calculate_end_statistics()

	return 1

/datum/game_mode/battle_field/proc/end_game_music()
	world << sound('sound/misc/hell_march.ogg')

//Randomizes and chooses a call datum.
/datum/game_mode/battle_field/proc/spawn_random_bf_event()
	var/add_prob = 0
	var/datum/battle_field_events/chosen_event
	var/total_probablity = 0
	var/list/currnet_event_list = list()

	for(var/datum/battle_field_events/E in bf_events)
		if(E.event_tier == current_event_tier)
			currnet_event_list += E

	//Ensure that if someone messed up the math we still get the good probability
	for(var/datum/battle_field_events/E in currnet_event_list)
		total_probablity += E.event_chance
	var/chance = rand(1, total_probablity)

	for(var/datum/battle_field_events/E in currnet_event_list) //Loop through all potential candidates
		if(chance >= E.event_chance + add_prob) //Tally up probabilities till we find which one we landed on
			add_prob += E.event_chance
			continue
		chosen_event = new E.type() //Our random chance found one.
		break

	if(!istype(chosen_event))
		error("get_random_event !istype(chosen_event)")
		return null
	else
		return chosen_event

/datum/game_mode/battle_field/proc/spawn_next_bf_event()
	var/datum/battle_field_events/event = spawn_random_bf_event()

	spawn_next_bf_event = FALSE
	spawn_bf_event(event)
	announce_new_event(event)
	if(current_event_tier == 4 && event.spawn_additional_marines)
		//Wave when Marines get reinforcements!
		get_specific_call("Marine Reinforcements (Squad)", TRUE, FALSE)
	if(prob(10))
		current_event_tier = min(current_event_tier + 1, BF_MAX_EVENT_TIER)


/datum/game_mode/battle_field/proc/announce_new_event(datum/battle_field_events/event_data)
	if(!istype(event_data))
		return
	if(event_data.command_announcement.len > 0)
		faction_announcement(event_data.command_announcement[1], event_data.command_announcement[2])
	if(event_data.sound_effect.len > 0)
		playsound_z(SSmapping.levels_by_trait(ZTRAIT_GROUND), pick(event_data.sound_effect))

//CHECK WIN
/datum/game_mode/battle_field/check_win()
	var/C = count_humans_and_xenos(SSmapping.levels_by_trait(ZTRAIT_GROUND))

	if(C[1] == 0)
		finished = 1 //Alien win
	else if(ending)
		finished = 2 //Marine win

/datum/game_mode/battle_field/proc/disablejoining()
	for(var/i in SSticker.role_authority.roles_by_name)
		var/datum/job/J = GET_MAPPED_ROLE(i)

		// If the job has unlimited job slots, We set the amount of slots to the amount it has at the moment this is called
		if(J.spawn_positions < 0)
			J.spawn_positions = J.current_positions
			J.total_positions = J.current_positions
		J.current_positions = J.get_total_positions(TRUE)
	to_world("<B>New players may no longer join the game.</B>")
	message_admins("Event one has begun. Disabled new player game joining except for replacement of cryoed marines.")
	world.update_status()












#define BF_SPAWN_MULTIPLIER 0.9
#define BF_SCALED_EVENT 1
#define BF_STATIC_EVENT 2

//SPAWN XENOS
/datum/game_mode/battle_field/proc/spawn_bf_event(datum/battle_field_events/event_data)
	if(!istype(event_data))
		return

	if(event_data.xenos)
		var/datum/faction_status/xeno/hive = GLOB.faction_datums[event_data.xenos]
		if(hive.slashing_allowed != XENO_SLASH_ALLOWED)
			hive.slashing_allowed = XENO_SLASH_ALLOWED //Allows harm intent for aliens

	var/enemy_to_spawn
	var/event_objectives_to_spawn
	var/event_dropp_to_spawn
	if(event_data.event_type == BF_SCALED_EVENT)
		enemy_to_spawn = max(count_marines(SSmapping.levels_by_trait(ZTRAIT_GROUND)),5) * event_data.scaling_factor * BF_SPAWN_MULTIPLIER
		event_objectives_to_spawn = max(count_marines(SSmapping.levels_by_trait(ZTRAIT_GROUND)),5) * event_data.scaling_factor * BF_SPAWN_MULTIPLIER
		event_dropp_pool = max(count_marines(SSmapping.levels_by_trait(ZTRAIT_GROUND)),5) * event_data.scaling_factor * BF_SPAWN_MULTIPLIER
	else
		enemy_to_spawn = event_data.number_of_enemy * BF_SPAWN_MULTIPLIER
		event_objectives_to_spawn = event_data.number_of_objectives * BF_SPAWN_MULTIPLIER
		event_dropp_pool = event_data.number_of_dropp * BF_SPAWN_MULTIPLIER

	spawn_next_event = event_data.event_delay

	if(event_data.event_tier == 1)
		call(/datum/game_mode/battle_field/proc/disablejoining)()

	while(enemy_to_spawn-- > 0)
		enemy_pool += pick(event_data.event_enemy) // Adds the event enemy to the current pool
	while(event_objectives_to_spawn-- > 0)
		event_objectives_pool += pick(event_data.event_objectives) // Adds the event enemy to the current pool
	while(event_dropp_to_spawn-- > 0)
		event_dropp_pool += pick(event_data.event_dropp) // Adds the event enemy to the current pool

	if(event_objectives_pool)
		spawn_event_objectives(event_data)
	if(event_dropp_pool)
		spawn_event_dropp(event_data)

/datum/game_mode/battle_field/proc/spawn_event_objectives(datum/battle_field_events/event_data)
/datum/game_mode/battle_field/proc/spawn_event_dropp(datum/battle_field_events/event_data)

/datum/game_mode/battle_field/attempt_to_join_as_second_side(mob/enemy_candidate, instant_join = 0)
	var/list/available_enemy = list()

	var/list/enemy_by_role = list() // the list the mobs are assigned to first, for sorting purposes
	for(var/mob/living/L as anything in enemy_pool)
		var/role_name = L.get_role_name()
		if(!role_name)
			role_name = "No Role"
		if(istype(L) && !L.client)
			if(L.away_timer >= LEAVE_TIMER)
				LAZYINITLIST(enemy_by_role[role_name])
				enemy_by_role[role_name] += L

	for(var/role in enemy_by_role)
		for(var/enemy in enemy_by_role[role])
			available_enemy["[enemy] ([role])"] = enemy

	if(!available_enemy.len)
		to_chat(enemy_candidate, SPAN_WARNING("There aren't any available mobs."))
		return FALSE

	var/choice = tgui_input_list(usr, "Available Second Side Characters:", "Join as Second Side", available_enemy)
	if(!choice)
		return
	if(!enemy_candidate)
		return FALSE

	var/mob/living/L = available_enemy[choice]
	if(!L || !(L in enemy_pool))
		return

	if(!istype(L))
		return

	if(QDELETED(L) || L.client)
		enemy_pool -= L
		to_chat(src, SPAN_WARNING("Something went wrong."))
		return

	if(isnewplayer(enemy_candidate))
		var/mob/new_player/N = enemy_candidate
		N.close_spawn_windows()
	enemy_pool -= L
	enemy_candidate.mind.transfer_to(L, TRUE)

/datum/battle_field_events
	var/event_id = 1
	var/event_tier = 1
	var/list/event_enemy = list()
	var/list/event_objectives = list()
	var/list/event_dropp = list()
	var/xenos = XENO_HIVE_MUTATED
	var/event_chance = 1.00 //100% >> 1%^ (1.00 >> 0.01)
	var/event_type = BF_SCALED_EVENT
	var/scaling_factor = 1.0
	var/number_of_enemy = 0 // not used for scaled waves
	var/number_of_objectives = 0
	var/number_of_dropp = 0
	var/event_delay = 200 SECONDS
	var/xeno_debuff_percent = 0.75 //100% >> 1%^ (1.00 >> 0.01)
	var/spawn_additional_marines = FALSE
	var/list/sound_effect = list('sound/effects/siren.ogg')
	var/list/command_announcement = list("Enemy coming here, WATCHOUT, this is last our outpost... We don't can lose control on biggest factory and extraction world!", "USCM General Covved, Primary Commanding Officer")
