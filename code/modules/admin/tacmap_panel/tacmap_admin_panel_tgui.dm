GLOBAL_DATUM_INIT(tacmap_admin_panel, /datum/tacmap_admin_panel, new)

#define LATEST_SELECTION -1

/datum/tacmap_admin_panel
	var/name = "Tacmap Panel"
	/// Map zlevel
	var/selected_zlevel = 1
	/// The index picked last for USCM (zero indexed), -1 will try to select latest if it exists
	var/faction_selection = LATEST_SELECTION
	/// Faction followed
	var/faction_selected = FACTION_MARINE
	/// The last time the map selection was changed - used as a key to trick react into updating the map
	var/last_update_time = 0

/datum/tacmap_admin_panel/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)

		// Ensure we actually have the latest map images sent (recache can handle older/different faction maps)
		resend_current_map_png(user, GLOB.faction_datums[faction_selected], selected_zlevel)

		ui = new(user, src, "TacmapAdminPanel", "Tacmap Panel")
		ui.open()

/datum/tacmap_admin_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/tacmap_admin_panel/ui_data(mob/user)
	. = list()
	var/list/faction_ckeys = list()
	var/list/faction_names = list()
	var/list/faction_times = list()

	// Assumption: Length of flat_tacmap_data is the same as svg_tacmap_data
	var/svg_length = length(GLOB.faction_datums[faction_selected].tcmp_faction_datum.svg_drawns["[selected_zlevel]"])
	if(faction_selection < 0 || faction_selection >= svg_length)
		faction_selection = svg_length - 1
	for(var/i = 1, i <= svg_length, i++)
		var/datum/svg_overlay/current_svg = GLOB.faction_datums[faction_selected].tcmp_faction_datum.svg_drawns["[selected_zlevel]"][i]
		faction_ckeys += current_svg.ckey
		faction_names += current_svg.name
		faction_times += current_svg.time
	.["faction_ckeys"] = faction_ckeys
	.["faction_names"] = faction_names
	.["faction_times"] = faction_times

	if(faction_selection == LATEST_SELECTION)
		.["faction_map"] = null
		.["faction_svg"] = null
	else
		var/datum/flattened_tacmap/selected_flat = GLOB.unannounced_maps["[selected_zlevel]"][faction_selection + 1]
		var/datum/svg_overlay/selected_svg = GLOB.faction_datums[faction_selected].tcmp_faction_datum.svg_drawns["[selected_zlevel]"][faction_selection + 1]
		.["faction_map"] = selected_flat.flat_tacmap
		.["faction_svg"] = selected_svg.svg_data


	.["faction_selection"] = faction_selection
	.["faction_name"] = GLOB.faction_datums[faction_selected].name
	.["last_update_time"] = last_update_time
	.["factions"] = list()
	for(var/faction_to_get in FACTION_LIST_ALL)
		var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
		var/icon = "medal"
		if(istype(faction, /datum/faction/xenomorph))
			icon = "star"
		.["factions"] += list(
			"name" = faction.name,
			"icon" = icon,
			"color" = faction.color
		)

	.["max_zlevel"] = world.maxz

/datum/tacmap_admin_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	var/client/client_user = user.client
	if(!client_user)
		return // Is this even possible?

	switch(action)
		if("recache")
			var/datum/flattened_tacmap/selected_flat = GLOB.unannounced_maps["[selected_zlevel]"][faction_selection + 1]
			SSassets.transport.send_assets(client_user, selected_flat.asset_key)
			last_update_time = world.time
			return TRUE

		if("change_selection")
			faction_selection = params["index"]
			last_update_time = world.time
			return TRUE

		if("delete")
			var/datum/svg_overlay/selected_svg =  GLOB.faction_datums[faction_selected].tcmp_faction_datum.svg_drawns["[selected_zlevel]"][faction_selection + 1]
			selected_svg.svg_data = null
			last_update_time = world.time
			message_admins("[key_name_admin(usr)] deleted the <a href='?tacmaps_panel=1'>tactical map drawing</a> by [selected_svg.ckey].")
			return TRUE

/datum/tacmap_admin_panel/ui_close(mob/user)
	. = ..()
	faction_selection = LATEST_SELECTION

#undef LATEST_SELECTION
