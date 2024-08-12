GLOBAL_LIST_EMPTY(unannounced_maps)

/datum/flattened_tacmap
	var/flat_tacmap
	var/asset_key
	var/time

/datum/flattened_tacmap/New(flat_tacmap, asset_key)
	src.flat_tacmap = flat_tacmap
	src.asset_key = asset_key
	src.time = time_stamp()

/datum/svg_overlay
	var/svg_data
	var/ckey
	var/name
	var/time

/datum/svg_overlay/New(svg_data, mob/user)
	src.svg_data = svg_data
	src.ckey = user?.persistent_ckey
	src.name = user?.real_name
	src.time = time_stamp()

/**
 * Re-sends relevant flattened tacmaps to a single client.
 *
 * Arguments:
 * * user: The mob that is either an observer, marine, or xeno
 */
/proc/resend_current_map_png(mob/user, datum/faction/faction, zlevel)
	if(!user.client)
		return
	var/datum/flattened_tacmap/latest
	if(faction.tcmp_faction_datum.drawnings["[zlevel]"])
		latest = faction.tcmp_faction_datum.drawnings["[zlevel]"][length(faction.tcmp_faction_datum.drawnings["[zlevel]"])]
	if(latest)
		SSassets.transport.send_assets(user.client, latest.asset_key)
	var/datum/flattened_tacmap/unannounced = GLOB.unannounced_maps["[zlevel]"]
	if(unannounced &&(!latest || latest.asset_key != unannounced.asset_key))
		SSassets.transport.send_assets(user.client, unannounced.asset_key)

///////////////////////
//TACMAP INITIAL INFO//
///////////////////////

//MINIMAP EFFECT TO MOVABLE
/obj/effect/tacmap_detector
	invisibility = 101
	anchored = 1
	var/atom/movable/atom_ref
	var/datum/shape/rectangle/range_bounds

/obj/effect/tacmap_detector/New(atom/movable/follow_ref)
	atom_ref = follow_ref
	range_bounds = new

/obj/effect/tacmap_detector/proc/get_range_bounds()
	var/turf/cur_turf = get_turf(src)
	if(!istype(cur_turf))
		return

	if(!range_bounds)
		range_bounds = new/datum/shape/rectangle
	range_bounds.center_x = cur_turf.x
	range_bounds.center_y = cur_turf.y
	range_bounds.width = atom_ref.sensor_radius * 2
	range_bounds.height = atom_ref.sensor_radius * 2
	return range_bounds

///////////////////////

///////////////////////
/////FACTION DATUM/////
///////////////////////
/datum/tacmap/faction_datums
	var/datum/faction/faction
	var/list/datum/tacmap/atom_datum/faction_mobs_to_draw = list()
	var/list/datum/tacmap/atom_datum/mobs_to_draw = list()

	var/list/datum/flattened_tacmap/drawnings = list()
	var/list/datum/flattened_tacmap/svg_drawns = list()

	var/list/enemy_draw = list()
	var/list/passive_scan = list()

/datum/tacmap/faction_datums/New(datum/faction/faction_to_set)
	faction = faction_to_set
	SSmapview.faction_tcmp[faction.faction_name] = src

/datum/tacmap/faction_datums/proc/overlays_to_draw(zlevel)
	if(!enemy_draw[zlevel])
		enemy_draw[zlevel] = TRUE
		spawn(12 SECONDS)
			enemy_draw(zlevel)
			enemy_draw[zlevel] = FALSE
	if(!passive_scan[zlevel])
		passive_scan[zlevel] = TRUE
		spawn(8 SECONDS)
			passive_scan(zlevel)
			passive_scan[zlevel] = FALSE

	var/list/image/images_to_gen = list()
	for(var/datum/tacmap/atom_datum/mob_datum as anything in mobs_to_draw)
		if(mob_datum.atom_ref.z == text2num(zlevel))
			images_to_gen += mob_datum.image_assoc[faction.faction_name]
	for(var/datum/tacmap/atom_datum/mob_datum as anything in faction_mobs_to_draw)
		if(mob_datum.atom_ref.z == text2num(zlevel) &&(mob_datum.atom_ref.tacmap_visibly || mob_datum.flags_tacmap & TCMP_INVISIBLY_OV))
			images_to_gen += mob_datum.image_assoc[faction.faction_name]
	return images_to_gen

/datum/tacmap/faction_datums/proc/passive_scan(zlevel)
	for(var/atom/movable/M as anything in SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(zlevel)]"].assoc_atom_datums)
		var/datum/tacmap/atom_datum/tcov = SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(zlevel)]"].assoc_atom_datums[M]
		if(LAZYISIN(mobs_to_draw, tcov))
			continue
		if(tcov.atom_ref_faction != faction)
			var/turf/turf = get_turf(tcov.atom_ref.loc)
			var/turf/roof = turf.get_real_roof()
			if(!roof.air_strike(25, turf, TRUE))
				continue
			mobs_to_draw += tcov
			spawn(4 SECONDS)
				mobs_to_draw -= tcov

/datum/tacmap/faction_datums/proc/enemy_draw()
	for(var/datum/tacmap/atom_datum/tcov as anything in faction_mobs_to_draw)
		var/list/view_candidates = SSquadtree.players_in_range(tcov.tcmp_effect.get_range_bounds(), tcov.atom_ref.z, QTREE_EXCLUDE_OBSERVER | QTREE_SCAN_MOBS)

		for(var/mob/living/M as anything in view_candidates)
			if(M.faction == faction)
				continue
			var/datum/tacmap/atom_datum/tcov_second = SSmapview.assoc_atom_datums[M]
			if(LAZYISIN(mobs_to_draw, tcov_second))
				continue
			if(faction.faction_is_ally(tcov_second.atom_ref_faction))
				if(tcov_second.atom_ref_faction != faction)
					mobs_to_draw += tcov_second
					spawn(11 SECONDS)
						mobs_to_draw -= tcov_second
			else
				mobs_to_draw += tcov_second
				spawn(11 SECONDS)
					mobs_to_draw -= tcov_second
///////////////////////

///////////////////////
//////////UI///////////
///////////////////////
/datum/ui_minimap
	var/minimap_name = "Tactical Map"

	var/datum/tacmap/faction_datums/faction_tcmp_ref
	var/datum/tacmap/atom_datum/active_marker
	var/datum/tacmap/minimap/minimap_ref

	/// current flattend map
	var/datum/flattened_tacmap/new_current_map
	/// previous flattened map
	var/datum/flattened_tacmap/old_map
	/// current svg
	var/datum/svg_overlay/current_svg

	var/atom/owner_ref
	var/acting_setting = FALSE
	var/selected_zlevel

	var/coldown_duration = 5 MINUTES
	var/canvas_cooldown = 0
	var/toolbar_color_selection = "black"
	var/toolbar_updated_selection = "black"
	var/updated_canvas = FALSE
	var/last_update_time = 0

/datum/ui_minimap/New(datum/tacmap/faction_datums/_faction_tcmp_ref, datum/tacmap/minimap/_minimap_ref, atom/_owner_ref, _acting_setting, _minimap_name)
	faction_tcmp_ref = _faction_tcmp_ref
	minimap_ref = _minimap_ref
	owner_ref = _owner_ref
	acting_setting = _acting_setting
	minimap_name = _minimap_name
	if(!minimap_ref)
		error("UI minimap tried to load without map")
		qdel(src)

/datum/ui_minimap/Destroy()
	faction_tcmp_ref = null
	active_marker = null
	minimap_ref = null
	new_current_map = null
	old_map = null
	current_svg = null
	owner_ref = null
	return ..()

/datum/ui_minimap/proc/distribute_current_map_png(minimap_zlevel)
	// Send to only relevant clients
	var/list/clients = list()
	for(var/mob/client_mob as anything in faction_tcmp_ref.faction.totalMobs)
		if(!client_mob.client)
			continue
		clients += client_mob.client

	// This may be unnecessary to do this way if the asset url is always the same as the lookup key
	var/flat_tacmap_key = icon2html(SSmapview.flat_maps_by_zlevel["[minimap_zlevel]"], clients, keyonly = TRUE)
	if(!flat_tacmap_key)
		to_chat(usr, SPAN_WARNING("A critical error has occurred! Contact a coder."))
		return FALSE
	var/flat_tacmap_png = SSassets.transport.get_asset_url(flat_tacmap_key)
	var/datum/flattened_tacmap/new_flat = new(flat_tacmap_png, flat_tacmap_key)
	qdel(GLOB.unannounced_maps["[minimap_zlevel]"])
	GLOB.unannounced_maps["[minimap_zlevel]"] = new_flat
	return TRUE

/datum/ui_minimap/tgui_interact(mob/user, datum/tgui/ui)
	if(!selected_zlevel)
		selected_zlevel = pick(minimap_ref.map_zlevels)

	new_current_map = GLOB.unannounced_maps["[selected_zlevel]"]
	if(faction_tcmp_ref)
		if(faction_tcmp_ref.drawnings["[selected_zlevel]"])
			old_map = faction_tcmp_ref.drawnings["[selected_zlevel]"][length(faction_tcmp_ref.drawnings["[selected_zlevel]"])]
		if(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])
			current_svg = faction_tcmp_ref.svg_drawns["[selected_zlevel]"][length(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])]

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		// Ensure we actually have the map image sent
		resend_current_map_png(user, user.faction, selected_zlevel)

		user.client.register_map_obj(SSmapview.hud_by_zlevel["[selected_zlevel]"])
		if(acting_setting)
			if(faction_tcmp_ref)
				distribute_current_map_png(selected_zlevel)
			last_update_time = world.time

		ui = new(user, src, "TacticalMap", minimap_name)
		ui.open()
		ui.set_autoupdate(10)

/datum/ui_minimap/ui_data()
	. = list()

	.["newCanvasFlatImage"] = new_current_map?.flat_tacmap
	.["oldCanvasFlatImage"] = old_map?.flat_tacmap
	.["svgData"] = current_svg?.svg_data

	.["toolbarColorSelection"] = toolbar_color_selection
	.["toolbarUpdatedSelection"] = toolbar_updated_selection

	.["minimap_zlevels"] = minimap_ref.map_zlevels
	.["canvasCooldown"] = max(canvas_cooldown - world.time, 0)
	.["updatedCanvas"] = updated_canvas
	.["lastUpdateTime"] = last_update_time

	var/list/markers = get_markers()
	if(active_marker)
		.["activeMarker"] = list(
			name = markers[active_marker],
		)
	.["markers"] = list()
	for(var/i in markers)
		var/datum/tacmap/atom_datum/M = markers[i]
		var/marker_color = M.get_color(faction_tcmp_ref?.faction)
		.["markers"] += list(list(
			name = i,
			icon_file = M.icon_file,
			icon_state = M.icon_state,
			x = MINIMAP_PIXEL_FROM_WORLD(M.atom_ref.x),
			y = MINIMAP_PIXEL_FROM_WORLD(M.atom_ref.y),
			z = M.atom_ref.z,
			dir = M.atom_ref.dir,
			recoloring = M.recoloring,
			color = marker_color,
			rotating = M.rotating
		))

/datum/ui_minimap/ui_static_data(mob/user)
	. = list()
	.["mapRef"] = "[selected_zlevel]_mapview"
	.["canvasCooldownDuration"] = coldown_duration
	.["canDraw"] = acting_setting
	.["selectedTheme"] = istype(user, /mob/living/carbon/xenomorph) // TODO: Do it right way, don't leave shitcode from original

/datum/ui_minimap/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	switch(action)
		if("switchMarker")
			var/c_tag = params["name"]
			var/list/markers = get_markers()
			var/datum/tacmap/atom_datum/M = markers[c_tag]
			active_marker = M

		if("menuSelect")
			if(params["selection"] != "Canvas")
				if(updated_canvas)
					updated_canvas = FALSE
					toolbar_updated_selection = toolbar_color_selection  // doing this if it == canvas can cause a latency issue with the stroke.
			else
				if(!acting_setting)
					msg_admin_niche("[key_name(user)] made an unauthorized attempt to 'menuSelect' the 'new canvas' panel of the tacmap!")
					return FALSE
				distribute_current_map_png(selected_zlevel)
				last_update_time = world.time
				// An attempt to get the image to load on first try in the interface, but doesn't seem always reliable

			if(!faction_tcmp_ref)
				return

			new_current_map = GLOB.unannounced_maps["[selected_zlevel]"]
			if(faction_tcmp_ref.drawnings["[selected_zlevel]"])
				old_map = faction_tcmp_ref.drawnings["[selected_zlevel]"][length(faction_tcmp_ref.drawnings["[selected_zlevel]"])]
			if(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])
				current_svg = faction_tcmp_ref.svg_drawns["[selected_zlevel]"][length(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])]

		if("updateCanvas")
			if(!faction_tcmp_ref)
				return

			toolbar_updated_selection = "export"
			updated_canvas = TRUE

		if("clearCanvas")
			if(!faction_tcmp_ref)
				return

			toolbar_updated_selection = "clear"
			updated_canvas = FALSE

		if("undoChange")
			if(!faction_tcmp_ref)
				return

			toolbar_updated_selection = "undo"
			updated_canvas = FALSE

		if("selectColor")
			if(!faction_tcmp_ref)
				return

			var/newColor = params["color"]
			if(newColor)
				toolbar_color_selection = newColor
				toolbar_updated_selection = newColor

		if("onDraw")
			if(!faction_tcmp_ref)
				return

			updated_canvas = FALSE

		if("selectAnnouncement")
			if(!faction_tcmp_ref)
				return

			if(!acting_setting)
				msg_admin_niche("[key_name(user)] made an unauthorized attempt to 'selectAnnouncement' the tacmap!")
				return FALSE

			if(!istype(params["image"], /list)) // potentially very serious?
				return FALSE

			if(max(canvas_cooldown - world.time, 0))
				msg_admin_niche("[key_name(user)] attempted to 'selectAnnouncement' the tacmap while it is still on cooldown!")
				return FALSE

			canvas_cooldown = world.time + coldown_duration
			faction_tcmp_ref.drawnings["[selected_zlevel]"] += new_current_map
			faction_tcmp_ref.svg_drawns["[selected_zlevel]"] += new /datum/svg_overlay(params["image"], user)
			if(faction_tcmp_ref.drawnings["[selected_zlevel]"])
				old_map = faction_tcmp_ref.drawnings["[selected_zlevel]"][length(faction_tcmp_ref.drawnings["[selected_zlevel]"])]
			if(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])
				current_svg = faction_tcmp_ref.svg_drawns["[selected_zlevel]"][length(faction_tcmp_ref.svg_drawns["[selected_zlevel]"])]

			toolbar_updated_selection = toolbar_color_selection
			message_admins("[key_name(user)] has updated the <a href='?tacmaps_panel=1'>tactical map</a> for [faction_tcmp_ref.faction].")
			updated_canvas = FALSE

	. = TRUE

/datum/ui_minimap/proc/get_markers()
	. = list()
	for(var/datum/faction/faction in faction_tcmp_ref ? list(faction_tcmp_ref.faction) : GLOB.faction_datums)
		var/datum/tacmap/faction_datums/faction_tcmp = faction.tcmp_faction_datum
		for(var/datum/tacmap/atom_datum/M as anything in faction_tcmp.faction_mobs_to_draw)
			if(M.atom_ref.z in minimap_ref.map_zlevels)
				.["[M.generated_tag_ally]"] = M
		for(var/datum/tacmap/atom_datum/M as anything in faction_tcmp.mobs_to_draw)
			if(M.atom_ref.z in minimap_ref.map_zlevels)
				.["[M.generated_tag]"] = M

/datum/ui_minimap/ui_close(mob/user)
	. = ..()
	updated_canvas = FALSE
	toolbar_color_selection = "black"
	toolbar_updated_selection = "black"

/datum/ui_minimap/ui_status(mob/user)
	if(!isatom(owner_ref))
		return UI_INTERACTIVE

	var/dist = get_dist(owner_ref, user)
	if(dist <= 1)
		return UI_INTERACTIVE
	else if(dist <= 2)
		return UI_UPDATE
	else
		return UI_CLOSE
///////////////////////
