/atom/movable/screen/plane_master
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	plane = LOWEST_EVER_PLANE
	var/show_alpha = 255
	var/hide_alpha = 0

	//--rendering relay vars--
	///integer: what plane we will relay this planes render to
	var/render_relay_plane = RENDER_PLANE_GAME
	///bool: Whether this plane should get a render target automatically generated
	var/generate_render_target = TRUE
	///integer: blend mode to apply to the render relay in case you dont want to use the plane_masters blend_mode
	var/blend_mode_override
	///reference: current relay this plane is utilizing to render
	var/atom/movable/render_plane_relay/relay

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob)
	SHOULD_CALL_PARENT(TRUE)
	if(!isnull(render_relay_plane))
		relay_render_to_plane(mymob, render_relay_plane)

///Things rendered on "openspace"; holes in multi-z
/atom/movable/screen/plane_master/openspace_backdrop
	name = "open space backdrop plane master"
	plane = OPENSPACE_BACKDROP_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
	alpha = 255

//MOJAVE SUN EDIT - Depth Blur & Fixes//
/atom/movable/screen/plane_master/openspace
	name = "open space plane master"
	plane = OPENSPACE_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	alpha = 255

/atom/movable/screen/plane_master/openspace/Initialize(mapload) //Increase this if making map larger than 7 Zs
	. = ..()
	add_filter("z_level_blur", 1, list(type = "blur", size = 0.75))
	add_filter("first_stage_openspace", 2, drop_shadow_filter(color = "#04080FAA", size = -10))
	add_filter("second_stage_openspace", 3, drop_shadow_filter(color = "#04080FAA", size = -15))
	add_filter("third_stage_openspace", 4, drop_shadow_filter(color = "#04080FAA", size = -20))
	add_filter("fourth_stage_openspace", 5, drop_shadow_filter(color = "#04080FAA", size = -25))
	add_filter("fifth_stage_openspace", 6, drop_shadow_filter(color = "#04080FAA", size = -30))
	add_filter("sixth_stage_openspace", 7, drop_shadow_filter(color = "#04080FAA", size = -35))
	add_filter("seventh_stage_openspace", 8, drop_shadow_filter(color = "#04080FAA", size = -40))
	add_filter("eighth_stage_openspace", 9, drop_shadow_filter(color = "#04080FAA", size = -45))
	add_filter("ninth_stage_openspace", 10, drop_shadow_filter(color = "#04080FAA", size = -50))
	add_filter("tenth_stage_openspace", 11, drop_shadow_filter(color = "#04080FAA", size = -55))
	add_filter("eleven_stage_openspace", 12, drop_shadow_filter(color = "#04080FAA", size = -60))
	add_filter("twelfth_stage_openspace", 13, drop_shadow_filter(color = "#04080FAA", size = -65))
	add_filter("thirteenth_stage_openspace", 14, drop_shadow_filter(color = "#04080FAA", size = -70))

///For any transparent multi-z tiles we want to render
/atom/movable/screen/plane_master/transparent
	name = "transparent plane master"
	plane = TRANSPARENT_FLOOR_PLANE
	appearance_flags = PLANE_MASTER

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/over_tile
	name = "over tile world plane master"
	plane = OVER_TILE_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/wall
	name = "wall plane master"
	plane = WALL_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/wall/backdrop(mob/mymob)
	. = ..()
	remove_filter("AO")
	if(istype(mymob) && mymob?.client?.prefs?.toggle_prefs & TOGGLE_AMBIENT_OCCLUSION)
		add_filter("AO", 1, drop_shadow_filter(x = 0, y = -2, size = 4, color = "#04080FAA"))

///Contains most things in the game world
/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world/backdrop(mob/mymob)
	. = ..()
	remove_filter("AO")
	if(istype(mymob) && mymob?.client?.prefs?.toggle_prefs & TOGGLE_AMBIENT_OCCLUSION)
		add_filter("AO", 1, drop_shadow_filter(x = 0, y = -2, size = 4, color = "#04080FAA"))

/atom/movable/screen/plane_master/game_world_fov_hidden
	name = "game world fov hidden plane master"
	plane = GAME_PLANE_FOV_HIDDEN
	render_relay_plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world_fov_hidden/Initialize()
	. = ..()
	add_filter("vision_cone", 1, alpha_mask_filter(render_source = FIELD_OF_VISION_BLOCKER_RENDER_TARGET, flags = MASK_INVERSE))

/atom/movable/screen/plane_master/game_world_upper
	name = "upper game world plane master"
	plane = GAME_PLANE_UPPER
	render_relay_plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world_upper_fov_hidden
	name = "upper game world fov hidden plane master"
	plane = GAME_PLANE_UPPER_FOV_HIDDEN
	render_relay_plane = GAME_PLANE_FOV_HIDDEN
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world_above
	name = "above game world plane master"
	plane = ABOVE_GAME_PLANE
	render_relay_plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/frill_under
	name = "frill under plane master"
	plane = UNDER_FRILL_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/frill
	name = "frill plane master"
	plane = FRILL_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/frill_over
	name = "frill under plane master"
	plane = OVER_FRILL_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/ghost
	name = "ghost plane master"
	plane = GHOST_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_NON_GAME

/// Plane master handling display of building roofs. They're meant to become invisible when inside a building.
/atom/movable/screen/plane_master/roof
	name = "roof plane master"
	plane = ROOF_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/**
 * Plane master handling byond internal blackness
 * vars are set as to replicate behavior when rendering to other planes
 * do not touch this unless you know what you are doing
 */
/atom/movable/screen/plane_master/blackness
	name = "darkness plane master"
	plane = BLACKNESS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR | PIXEL_SCALE
	blend_mode = BLEND_MULTIPLY
	//byond internal end

/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */

///Contains all lighting objects
/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	blend_mode_override = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	. = ..()
	mymob.overlay_fullscreen("lighting_backdrop", /atom/movable/screen/fullscreen/lighting_backdrop/backplane)
	mymob.overlay_fullscreen("lighting_backdrop_lit_secondary", /atom/movable/screen/fullscreen/lighting_backdrop/lit_secondary)

/atom/movable/screen/plane_master/lighting/Initialize()
	. = ..()
	add_filter("emissives", 1, alpha_mask_filter(render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("object_lighting", 2, alpha_mask_filter(render_source = O_LIGHTING_VISUAL_RENDER_TARGET, flags = MASK_INVERSE))
	if(SSsunlighting.initialized)
		vis_contents += SSsunlighting.sun_color

//Contains all sun light objects
/atom/movable/screen/plane_master/s_light_visual
	name = "sun light visual plane master"
	plane = S_LIGHTING_VISUAL_PLANE
	render_target = S_LIGHTING_VISUAL_RENDER_TARGET
	render_relay_plane = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY

//Contains all weather overlays
/atom/movable/screen/plane_master/weather_overlay
	name = "weather overlay master"
	plane = WEATHER_OVERLAY_PLANE
	render_target = WEATHER_RENDER_TARGET
	render_relay_plane = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/parallax_white
	name = "parallax whitifier plane master"
	plane = PLANE_SPACE

/atom/movable/screen/plane_master/displacement_maps
	name = "displacement maps plane"
	plane = DISPLACEMENT_MAP_PLANE
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = null

/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	render_target = GRAVITY_PULSE_RENDER_TARGET
	blend_mode = BLEND_ADD
	blend_mode_override = BLEND_ADD
	render_relay_plane = null

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "emissive plane master"
	plane = EMISSIVE_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = EMISSIVE_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/emissive/Initialize()
	. = ..()
	add_filter("em_block_masking", 1, color_matrix_filter(GLOB.em_mask_matrix))

/atom/movable/screen/plane_master/above_lighting
	name = "above lighting plane master"
	plane = ABOVE_LIGHTING_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME
//TODO: Fix that shit, wrong render effects

/atom/movable/screen/plane_master/runechat
	name = "runechat plane master"
	plane = RUNECHAT_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/o_light_visual
	name = "overlight light visual plane master"
	plane = O_LIGHTING_VISUAL_PLANE
	render_target = O_LIGHTING_VISUAL_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	blend_mode_override = BLEND_MULTIPLY

/atom/movable/screen/plane_master/runechat/backdrop(mob/mymob)
	. = ..()
	remove_filter("AO")
	add_filter("AO", 1, drop_shadow_filter(x = 0, y = -2, size = 4, color = "#04080FAA"))

/atom/movable/screen/plane_master/fullscreen
	name = "fullscreen alert plane"
	plane = FULLSCREEN_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/field_of_vision_blocker
	name = "field of vision blocker plane master"
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	render_target = FIELD_OF_VISION_BLOCKER_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = null

/atom/movable/screen/plane_master/hud
	name = "HUD plane"
	plane = HUD_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/above_hud
	name = "above HUD plane"
	plane = ABOVE_HUD_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/cinematic
	name = "cinematic plane"
	plane = CINEMATIC_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/escape_menu
	name = "Escape Menu"
	plane = ESCAPE_MENU_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_MASTER
