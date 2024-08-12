/datum/tacmap/atom_datum
	var/icon_state = null
	var/icon_file = 'icons/map_effects.dmi'
	var/recoloring = TRUE
	var/rotating = FALSE
	var/datum/faction/atom_ref_faction
	var/color
	var/flags_tacmap = NO_FLAGS
	var/generated_tag_ally
	var/generated_tag
	var/list/image/image_assoc = list()
	var/atom/movable/atom_ref
	var/obj/effect/tacmap_detector/tcmp_effect

/datum/tacmap/atom_datum/New(atom/movable/atom_source, iconstate, recoloring_new, rotating_new, custom_color, new_flags)
	tcmp_effect = new(atom_source)
	tcmp_effect.forceMove(atom_source)
	tcmp_effect.range_bounds.width = atom_source.sensor_radius * 2
	tcmp_effect.range_bounds.height = atom_source.sensor_radius * 2
	flags_tacmap = new_flags
	atom_ref = atom_source
	atom_ref_faction = atom_source.faction
	icon_state = iconstate
	recoloring = recoloring_new
	rotating = rotating_new
	if(custom_color)
		color = custom_color
		flags_tacmap |= TCMP_CUSTOM_COLOR

	atom_ref_faction.tcmp_faction_datum.faction_mobs_to_draw += src
/*
	for(var/faction_to_get in FACTION_LIST_ALL)
		image_assoc[faction_to_get] = generate_icon(faction_to_get)
*/
	generated_tag_ally = "[atom_ref.name] [atom_ref_faction.name]"
	generated_tag = "unknow entity [SSmapview.assoc_atom_datums.len + 1]"

	RegisterSignal(atom_source, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_z_change))
//	RegisterSignal(atom_source, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
/*
/datum/tacmap/atom_datum/proc/generate_icon(faction_to_get)
	var/datum/faction/faction = GLOB.faction_datums[faction_to_get]
	var/image/image = image(icon_file, icon_state, pixel_x = MINIMAP_PIXEL_FROM_WORLD(atom_ref.x), pixel_y = MINIMAP_PIXEL_FROM_WORLD(atom_ref.y), dir = atom_ref.dir)
	if(recoloring)
		image.color = get_color(faction)
	if(rotating)
		image.dir = turn(atom_ref.dir, 0)
	return image
*/
/datum/tacmap/atom_datum/proc/get_color(datum/faction/faction)
	if(flags_tacmap & TCMP_CUSTOM_COLOR)
		return color
	else if(!faction || (atom_ref_faction.faction_is_ally(faction) && atom_ref_faction != faction))
		return faction.color
	else if(faction == atom_ref_faction)
		return COLOR_GREEN
	else
		return COLOR_SOFT_RED

/datum/tacmap/atom_datum/proc/on_z_change(oldz, newz)
	SIGNAL_HANDLER
	if(!SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(oldz)]"]?.assoc_atom_datums[atom_ref])
		return
	//see previous byond bug comments http://www.byond.com/forum/post/2661309
	var/ref_old = SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(oldz)]"].assoc_atom_datums[atom_ref]
	SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(newz)]"].assoc_atom_datums[atom_ref] = ref_old
	var/anotherref = SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(oldz)]"].assoc_atom_datums
	anotherref -= atom_ref
	var/rawold = SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(oldz)]"].assoc_atom_datums[atom_ref]
	var/rawnew = SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(newz)]"].assoc_atom_datums
	rawold -= ref_old
	rawnew += ref_old
/*
/datum/tacmap/atom_datum/proc/on_move()
	SIGNAL_HANDLER
	if(!atom_ref.z)
		return //this can happen legitimately when you go into pipes, it shouldnt but thats how it is
	for(var/f in FACTION_LIST_ALL)
		var/image/i = image_assoc[f]
		if(SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(atom_ref.z)]"])
			i.pixel_x = MINIMAP_PIXEL_FROM_WORLD(atom_ref.x) + SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(atom_ref.z)]"].x_offset
			i.pixel_y = MINIMAP_PIXEL_FROM_WORLD(atom_ref.y) + SSmapview.minimaps_by_trait["[SSmapping.level_minimap_trait(atom_ref.z)]"].y_offset
		if(rotating)
			i.dir = atom_ref.dir
	var/turf/cur_turf = get_turf(atom_ref)
	if(!istype(cur_turf))
		return
	tcmp_effect.range_bounds.center_x = cur_turf.x
	tcmp_effect.range_bounds.center_y = cur_turf.y
*/
