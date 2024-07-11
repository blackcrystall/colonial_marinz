/datum/world_topic
	/// query key
	var/key

	/// can be used with anonymous authentication
	var/anonymous = FALSE

	var/list/required_params = list()
	var/statuscode
	var/response
	var/data

/datum/world_topic/proc/CheckParams(list/params)
	var/list/missing_params = list()
	var/errorcount = 0

	for(var/param in required_params)
		if(!params[param])
			errorcount++
			missing_params += param

	if(errorcount)
		statuscode = 400
		response = "Bad Request - Missing parameters"
		data = missing_params
		return errorcount

/datum/world_topic/proc/Run(list/input)
	// Always returns true; actual details in statuscode, response and data variables
	return TRUE

// API INFO TOPICS

/datum/world_topic/api_get_authed_functions
	key = "api_get_authed_functions"
	anonymous = TRUE

/datum/world_topic/api_get_authed_functions/Run(list/input)
	. = ..()
	var/list/functions = GLOB.topic_tokens[input["auth"]]
	if(functions)
		statuscode = 200
		response = "Authorized functions retrieved"
		data = functions
	else
		statuscode = 401
		response = "Unauthorized - No functions found"
		data = null

// TOPICS

/datum/world_topic/ping
	key = "ping"
	anonymous = TRUE

/datum/world_topic/ping/Run(list/input)
	. = ..()
	statuscode = 200
	response = "Pong!"
	data = length(GLOB.clients)


/datum/world_topic/playing
	key = "playing"
	anonymous = TRUE

/datum/world_topic/playing/Run(list/input)
	. = ..()
	statuscode = 200
	response = "Player count retrieved"
	data = length(GLOB.player_list)


/datum/world_topic/adminwho
	key = "adminwho"

/datum/world_topic/adminwho/Run(list/input)
	. = ..()
	var/list/admins = list()
	for(var/client/admin in GLOB.admins)
		admins += list(
			"ckey" = admin.ckey,
			"key" = admin.key,
			"rank" = admin.admin_holder.rank,
			"stealth" = admin.admin_holder.fakekey ? TRUE : FALSE,
			"afk" = admin.is_afk(),
		)
	statuscode = 200
	response = "Admin list fetched"
	data = admins


/datum/world_topic/playerlist
	key = "playerlist"
	anonymous = TRUE

/datum/world_topic/playerlist/Run(list/input)
	. = ..()
	data = list()
	for(var/client/C as() in GLOB.clients)
		data += C.ckey
	statuscode = 200
	response = "Player list fetched"


/datum/world_topic/status
	key = "status"
	anonymous = TRUE

/datum/world_topic/status/Run(list/input)
	. = ..()
	data = list()
	data["round_name"] = "Loading..."

	data["round_id"] = "Loading..."
	if(SSperf_logging.round?.id)
		data["round_id"] = SSperf_logging.round.id

	data["map_name"] = "Loading..."
	if(SSmapping.configs?[GROUND_MAP])
		data["map_name"] = SSmapping.configs[GROUND_MAP].map_name
	if(SSmapping.next_map_configs?[GROUND_MAP])
		data["next_map_name"] = SSmapping.next_map_configs[GROUND_MAP].map_name

	data["ship_map_name"] = "Loading..."
	if(SSmapping.configs?[SHIP_MAP])
		data["ship_map_name"] = SSmapping.configs[SHIP_MAP].map_name
	if(SSmapping.next_map_configs?[SHIP_MAP])
		data["next_ship_map_name"] = SSmapping.next_map_configs[SHIP_MAP].map_name

	data["players"] = length(GLOB.clients)
	data["players_avg"] = round(SSstats_collector.get_avg_players(), 0.01)

	data["mode"] = "Loading..."
	if(SSticker.mode)
		if(SSticker.mode.round_statistics?.round_name)
			data["round_name"] = SSticker.mode.round_statistics.round_name
		if(SSticker.mode.round_finished)
			data["round_end_state"] = SSticker.mode.end_round_message()
		data["mode"] = SSticker.mode.name

	data["revision"] = GLOB.revdata.commit
	data["revision_date"] = GLOB.revdata.date

	var/list/adm = get_admin_counts()
	var/list/presentmins = adm["present"]
	var/list/afkmins = adm["afk"]
	data["admins"] = length(presentmins) + length(afkmins) //equivalent to the info gotten from adminwho
	data["gamestate"] = SSticker.current_state

	data["round_duration"] = ROUND_TIME
	data["zone_time"] = SSsunlighting.game_time_offseted() - GLOB.timezoneOffset
	// Amount of world's ticks in seconds, useful for calculating round duration

	//Time dilation stats.
	data["time_dilation_current"] = SStime_track.time_dilation_current
	data["time_dilation_avg"] = SStime_track.time_dilation_avg
	data["time_dilation_avg_slow"] = SStime_track.time_dilation_avg_slow
	data["time_dilation_avg_fast"] = SStime_track.time_dilation_avg_fast

	data["mcpu"] = world.map_cpu
	data["cpu"] = world.cpu

	statuscode = 200
	response = "Status retrieved"

/datum/world_topic/lookup_discord_id
	key = "lookup_discord_id"
	required_params = list("discord_id")

/datum/world_topic/lookup_discord_id/Run(list/input)
	data = list()

	var/datum/view_record/discord_link/link = locate() in DB_VIEW(/datum/view_record/discord_link, DB_COMP("discord_id", DB_EQUALS, input["discord_id"]))

	if(!link || !link.player_id)
		statuscode = 500
		response = "Database lookup failed."
		return

	var/datum/view_record/players/player = locate() in DB_VIEW(/datum/view_record/players, DB_COMP("id", DB_EQUALS, link.player_id))

	data["notes"] = get_all_notes(player.ckey)
	data["total_minutes"] = get_total_living_playtime(player.id)
	data["ckey"] = player.ckey
	var/datum/view_record/player_whitelist_view/whitelist = locate() in DB_VIEW(/datum/view_record/player_whitelist_view, DB_COMP("player_id", DB_EQUALS, player.id))
	data["roles"] = get_whitelisted_roles(whitelist?.whitelist_flags)
	statuscode = 200
	response = "Lookup successful."


/datum/world_topic/lookup_ckey
	key = "lookup_ckey"
	required_params = list("ckey")

/datum/world_topic/lookup_ckey/Run(list/input)
	data = list()

	var/datum/view_record/players/player = locate() in DB_VIEW(/datum/view_record/players, DB_COMP("ckey", DB_EQUALS, input["ckey"]))
	if(!player)
		statuscode = 501
		response = "Database lookup failed."
		return

	var/datum/view_record/discord_link/link = locate() in DB_VIEW(/datum/view_record/discord_link, DB_COMP("player_id", DB_EQUALS, player.id))

	if(link && link.discord_id)
		data["discord_id"] = link.discord_id

	data["notes"] = get_all_notes(player.ckey)
	data["total_minutes"] = get_total_living_playtime(player.id)
	var/datum/view_record/player_whitelist_view/whitelist = locate() in DB_VIEW(/datum/view_record/player_whitelist_view, DB_COMP("player_id", DB_EQUALS, player.id))
	data["roles"] = get_whitelisted_roles(whitelist?.whitelist_flags)
	statuscode = 200
	response = "Lookup successful."
