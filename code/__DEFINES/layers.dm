
//Defines for atom layers and planes

//the hardcoded ones are AREA_LAYER = 1, TURF_LAYER = 2, OBJ_LAYER = 3, MOB_LAYER = 4, FLY_LAYER = 5

/*=============================*\
| |
|   LAYER DEFINES |
| |
\*=============================*/

//#define AREA_LAYER 1
// PLANE_SPACE layer(s)
#define SPACE_LAYER 1.8

#define UNDER_TURF_LAYER 1.99

#define TURF_LAYER 2

#define ABOVE_TURF_LAYER 2.01
#define WALL_LAYER 2.02

#define LATTICE_LAYER 2.15

#define DISPOSAL_PIPE_LAYER 2.3

#define BELOW_ATMOS_PIPE_LAYER 2.37
#define ATMOS_PIPE_SCRUBBER_LAYER 2.38
#define ATMOS_PIPE_SUPPLY_LAYER 2.39
#define ATMOS_PIPE_LAYER 2.4

#define WIRE_LAYER 2.44
#define WIRE_TERMINAL_LAYER 2.45

/// bluespace beacon, navigation beacon, etc
#define UNDERFLOOR_OBJ_LAYER 2.46
/// catwalk overlay of /turf/open/floor/plating/plating_catwalk
#define CATWALK_LAYER 2.47

/// stairs overlay on turf
#define STAIRS_LAYER 2.5

/// Alien weeds and node layer
#define WEED_LAYER 2.51
/// Over weeds, such as blood
#define ABOVE_WEED_LAYER 2.518

#define ABOVE_BLOOD_LAYER 2.519

/// vents, connector ports, atmos devices that should be above pipe layer.
#define ATMOS_DEVICE_LAYER 2.52

#define ANIMAL_HIDING_LAYER 2.53

/// Right under poddoors
#define FIREDOOR_OPEN_LAYER 2.549
/// Under doors and virtually everything that's "above the floor"
#define PODDOOR_OPEN_LAYER 2.55
/// conveyor belt
#define CONVEYOR_LAYER 2.56

#define RESIN_STRUCTURE_LAYER 2.6

#define LADDER_LAYER 2.7

#define WINDOW_FRAME_LAYER 2.72

#define XENO_HIDING_LAYER 2.75

#define BELOW_TABLE_LAYER 2.79
#define TABLE_LAYER 2.8
#define ABOVE_TABLE_LAYER 2.81

/// Under all objects if opened. 2.85 due to tables being at 2.8
#define DOOR_OPEN_LAYER 2.85

///For hatches on the floor.
#define HATCH_LAYER 2.9

#define BELOW_VAN_LAYER 2.98

/// just below all items
#define BELOW_OBJ_LAYER 2.98

/// for items that should be at the bottom of the pile of items
#define LOWER_ITEM_LAYER 2.99

#define OBJ_LAYER 3

#define ABOVE_SPECIAL_RESIN_STRUCTURE_LAYER 3.01

/// A layer above objects (like structures) but below items
#define BETWEEN_OBJECT_ITEM_LAYER 3.01

/// The layer on which items lay
#define ITEM_LAYER 3.02
/// for items that should be at the top of the pile of items
#define UPPER_ITEM_LAYER 3.03
/// just above all items
#define ABOVE_OBJ_LAYER 3.04

#define BUSH_LAYER 3.05

/// Above most items if closed
#define DOOR_CLOSED_LAYER 3.1
/// Right under poddoors
#define FIREDOOR_CLOSED_LAYER 3.189
/// Above doors which are at 3.1
#define PODDOOR_CLOSED_LAYER 3.19
/// above closed doors
#define WINDOW_LAYER 3.2
/// posters on walls
#define WALL_OBJ_LAYER 3.5
/// above windows and wall mounts so the top of the loader doesn't clip.
#define POWERLOADER_LAYER 3.6

#define BELOW_MOB_LAYER 3.75
#define LYING_DEAD_MOB_LAYER 3.76
#define LYING_BETWEEN_MOB_LAYER 3.79
#define LYING_LIVING_MOB_LAYER 3.8

/// drone (not the xeno)
#define ABOVE_LYING_MOB_LAYER 3.9

//#define MOB_LAYER 4

#define ABOVE_MOB_LAYER 4.1

/// above ABOVE_MOB_LAYER because it's used for shallow river overlays
#define BIG_XENO_LAYER 4.11
/// for xenos to hide behind bushes and tall grass
#define ABOVE_XENO_LAYER 4.12
/// for facehuggers
#define FACEHUGGER_LAYER 4.13
/// for vehicle
#define VEHICLE_LAYER 4.14
#define INTERIOR_DOOR_INSIDE_LAYER 4.19
#define RIPPLE_LAYER 4.2
#define INTERIOR_WALL_SOUTH_LAYER 4.21
#define INTERIOR_DOOR_LAYER 4.22
#define INTERIOR_WALLMOUNT_LAYER 4.3
#define INTERIOR_ROOF_LAYER 4.5

//#define FLY_LAYER 5

#define ABOVE_FLY_LAYER 6


/// Vulture sniper/spotter scope
#define FULLSCREEN_VULTURE_SCOPE_LAYER 17.21
/// blip from motion detector
#define BELOW_FULLSCREEN_LAYER 17.9
#define FULLSCREEN_LAYER 18
/// Weather
#define FULLSCREEN_WEATHER_LAYER 18.01
/// visual impairment from wearing welding helmet, etc.
#define FULLSCREEN_IMPAIRED_LAYER 18.02
#define FULLSCREEN_DRUGGY_LAYER 18.03
#define FULLSCREEN_BLURRY_LAYER 18.04
/// flashed
#define FULLSCREEN_FLASH_LAYER 18.05
/// red circles when hurt
#define FULLSCREEN_DAMAGE_LAYER 18.1
/// unconscious
#define FULLSCREEN_BLIND_LAYER 18.15
/// pain flashes
#define FULLSCREEN_PAIN_LAYER	18.16
/// in critical
#define FULLSCREEN_CRIT_LAYER 18.25

#define HUD_LAYER 19
#define ABOVE_HUD_LAYER 20

#define CINEMATIC_LAYER 21

/// for areas, so they appear above everything else on map file.
#define AREAS_LAYER 999

/// The layer you should use if you _really_ don't want an emissive overlay to be blocked.
#define EMISSIVE_LAYER_UNBLOCKABLE 9999
#define FOV_EFFECTS_LAYER 10000 //Blindness effects are not layer 4, they lie to you

#define LIGHTING_BACKPLANE_LAYER 14.5

#define LIGHTING_RENDER_TARGET "LIGHT_PLANE"

#define SHADOW_RENDER_TARGET "SHADOW_RENDER_TARGET"

/// Plane for balloon text (text that fades up)
#define BALLOON_CHAT_PLANE 110
/// Bubble for typing indicators
#define TYPING_LAYER 500

#define LIGHTING_PRIMARY_LAYER 15	//The layer for the main lights of the station
#define LIGHTING_PRIMARY_DIMMER_LAYER 15.1	//The layer that dims the main lights of the station
#define LIGHTING_SECONDARY_LAYER 16	//The colourful, usually small lights that go on top

#define LIGHTING_SHADOW_LAYER 17	//Where the shadows happen

#define ABOVE_LIGHTING_LAYER 18

/*=============================*\
| |
|   PLANE DEFINES |
| |
\*=============================*/

/// NEVER HAVE ANYTHING BELOW THIS PLANE ADJUST IF YOU NEED MORE SPACE
#define LOWEST_EVER_PLANE -200

#define FIELD_OF_VISION_BLOCKER_PLANE -199
#define FIELD_OF_VISION_BLOCKER_RENDER_TARGET "*FIELD_OF_VISION_BLOCKER_RENDER_TARGET"

#define CLICKCATCHER_PLANE -99

#define PLANE_SPACE -95
#define PLANE_SPACE_PARALLAX -90

#define WEATHER_OVERLAY_PLANE -80
#define WEATHER_RENDER_TARGET "*WEATHER_OVERLAY_PLANE"

#define GRAVITY_PULSE_PLANE -70
#define GRAVITY_PULSE_RENDER_TARGET "*GRAVPULSE_RENDER_TARGET"

#define DISPLACEMENT_MAP_PLANE -69

#define OPENSPACE_LAYER 600 //Openspace layer over all
#define TRANSPARENT_FLOOR_PLANE -62 //Transparent plane that shows openspace underneath the floor
#define OPENSPACE_PLANE -61 //Openspace plane below all turfs
#define OPENSPACE_BACKDROP_PLANE -60 //Black square just over openspace plane to guaranteed cover all in openspace turf

#define FLOOR_PLANE -45

#define OVER_TILE_PLANE -44

#define WALL_PLANE -43

#define GAME_PLANE -41

#define ROOF_PLANE -31

#define WEATHER_EFFECT_PLANE -30

#define GAME_PLANE_FOV_HIDDEN -29
#define GAME_PLANE_UPPER -28
#define GAME_PLANE_UPPER_FOV_HIDDEN -27
#define PARTICLES_PLANE -26

#define ABOVE_GAME_PLANE -20

#define UNDER_FRILL_PLANE -12 //MOJAVE SUN EDIT - Wallening Testmerge
#define UNDER_FRILL_RENDER_TARGET "*UNDER_RENDER_TARGET" //MOJAVE SUN EDIT - Wallening Testmerge
#define FRILL_PLANE -11 //MOJAVE SUN EDIT - Wallening Testmerge
#define OVER_FRILL_PLANE -10 //MOJAVE SUN EDIT - Wallening Testmerge

/// To keep from conflicts with SEE_BLACKNESS internals
#define BLACKNESS_PLANE 0

#define GHOST_PLANE 80

#define FRILL_MASK_PLANE 95
#define FRILL_MASK_RENDER_TARGET "*FRILL_MASK_RENDER_TARGET"

//------------------- LIGHTING -------------------
//Normal 1 per turf dynamic lighting underlays
#define LIGHTING_PLANE 100

#define S_LIGHTING_VISUAL_PLANE 120
#define S_LIGHTING_VISUAL_RENDER_TARGET "S_LIGHT_VISUAL_PLANE"

#define O_LIGHTING_VISUAL_PLANE 130
#define O_LIGHTING_VISUAL_RENDER_TARGET "O_LIGHT_VISUAL_PLANE"

//Things that should render ignoring lighting
#define ABOVE_LIGHTING_PLANE 150

//------------------- EMISSIVES -------------------
//Layering order of these is not particularly meaningful.
//Important part is the seperation of the planes for control via plane_master

/// This plane masks out lighting to create an "emissive" effect, ie for glowing lights in otherwise dark areas.
#define EMISSIVE_PLANE 150
/// The render target used by the emissive layer.
#define EMISSIVE_RENDER_TARGET "*EMISSIVE_PLANE"

//------------------- FULLSCREEN RUNECHAT BUBBLES -
//Popup Chat Messages
#define RUNECHAT_PLANE 501

//------------------- Rendering -------------------
#define RENDER_PLANE_GAME 990
#define RENDER_PLANE_NON_GAME 995

#define ESCAPE_MENU_PLANE 997

#define RENDER_PLANE_MASTER 999

// NOTE! You can only ever have planes greater then -10000, if you add too many with large offsets you will brick multiz
// Same can be said for large multiz maps. Tread carefully mappers
#define HIGHEST_EVER_PLANE RENDER_PLANE_MASTER
/// The range unique planes can be in
#define PLANE_RANGE (HIGHEST_EVER_PLANE - LOWEST_EVER_PLANE)

//------------------- HUD -------------------------
#define FULLSCREEN_PLANE 500

/// HUD layer defines
#define HUD_PLANE 1000
#define ABOVE_HUD_PLANE 1100

#define CINEMATIC_PLANE 1200


/// Plane master controller keys
#define PLANE_MASTERS_GAME "plane_masters_game"
#define PLANE_MASTERS_NON_MASTER "plane_masters_non_master"
