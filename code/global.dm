//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31
#define MAIN_SHIP_NAME SSmapping.get_main_ship_name()
#define MAIN_SHIP_DEFAULT_NAME "USS Almayer"
//=================================================
//Please don't edit these values without speaking to Errorage first ~Carn
//Admin Permissions
#define R_BUILDMODE (1<<0)
#define R_ADMIN (1<<1)
#define R_BAN (1<<2)
#define R_SERVER (1<<3)
#define R_DEBUG (1<<4)
#define R_POSSESS (1<<5)
#define R_PERMISSIONS (1<<6)
#define R_STEALTH (1<<7)
#define R_COLOR (1<<8)
#define R_VAREDIT (1<<9)
#define R_SOUNDS (1<<10)
#define R_SPAWN (1<<11)
#define R_MOD (1<<12)
#define R_MENTOR (1<<13)
#define R_HOST (1<<14)
#define R_PROFILER (1<<15)
#define R_NOLOCK (1<<16)
#define R_EVENT (1<<17)

/// The sum of all other rank permissions, other than host or profiler.
#define RL_EVERYTHING (R_BUILDMODE|R_ADMIN|R_BAN|R_SERVER|R_DEBUG|R_PERMISSIONS|R_POSSESS|R_STEALTH|R_COLOR|R_VAREDIT|R_EVENT|R_SOUNDS|R_NOLOCK|R_SPAWN|R_MOD|R_MENTOR)
/// Truely everything
#define RL_HOST (RL_EVERYTHING|R_HOST|R_PROFILER)
// 512.1430 increases maximum bit flags from 16 to 24, so the following flags should be available for future changes:
//=================================================

#define CLIENT_HAS_RIGHTS(cli, flags) ((cli?.admin_holder?.rights & flags) == flags)
#define CLIENT_IS_STAFF(cli) (cli?.admin_holder?.rights & (R_MOD|R_ADMIN))
#define CLIENT_IS_MENTOR(cli) CLIENT_HAS_RIGHTS(cli, R_MENTOR)

#define AHOLD_IS_MOD(ahold) (ahold && (ahold.rights & R_MOD))
#define AHOLD_IS_ADMIN(ahold) (ahold && (ahold.rights & R_ADMIN))

		//items that ask to be called every cycle

//////////////
var/list/paper_tag_whitelist = list("center","p","div","span","h1","h2","h3","h4","h5","h6","hr","pre", \
	"big","small","font","i","u","b","s","sub","sup","tt","br","hr","ol","ul","li","caption","col", \
	"table","td","th","tr")

///////////////

var/command_name = "Central Command"
var/station_name = "[MAIN_SHIP_NAME]"
var/game_version = "Colonial Marines"

var/going = 1.0
var/secret_force_mode = "secret" // if this is anything but "secret", the secret rotation will forceably choose this mode

var/host = null
var/abandon_allowed = 1
var/locked_conect = 0
var/shuttle_frozen = 0
var/shuttle_left = 0
var/midi_playing = 0
var/heard_midi = 0
var/total_silenced = 0

var/list/combatlog = list()
var/list/IClog = list()
var/list/OOClog = list()
var/list/adminlog = list()

var/Debug = 0 // global debug switch

var/datum/moduletypes/mods = new()

var/list/BorgWireColorToFlag = RandomBorgWires()
var/list/BorgIndexToFlag
var/list/BorgIndexToWireColor
var/list/BorgWireColorToIndex
var/list/AAlarmWireColorToFlag = RandomAAlarmWires()
var/list/AAlarmIndexToFlag
var/list/AAlarmIndexToWireColor
var/list/AAlarmWireColorToIndex

//Don't set this very much higher then 1024 unless you like inviting people in to dos your server with message spam
#define MAX_MESSAGE_LEN 1024
#define MAX_EMOTE_LEN 256
#define MAX_PAPER_MESSAGE_LEN 3072
#define MAX_BOOK_MESSAGE_LEN 9216
#define MAX_NAME_LEN 26

/// 3 minutes in the station.
#define shuttle_time_in_station 3 MINUTES
/// 10 minutes to arrive.
#define shuttle_time_to_arrive 10 MINUTES

// Reference list for disposal sort junctions. Filled up by sorting junction's New()
/var/list/tagger_locations = list()

//added for Xenoarchaeology, might be useful for other stuff
var/list/alphabet_uppercase = list("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
var/list/alphabet_lowercase = list("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")

var/list/greek_letters = list("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omnicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
var/list/nato_phonetic_alphabet = list("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-Ray", "Yankee", "Zulu")

//Used for autocall procs on ERT
var/distress_cancel = 0
var/destroy_cancel = 0

//Coordinate obsfucator
//Used by the rangefinders and linked systems to prevent coords collection/prefiring

/// A number between -2000 and 2000.
var/global/obfs_x = 0
/// A number between -2000 and 2000.
var/global/obfs_y = 0

// Which lobby art is on display
// This is updated by the lobby art turf when it initializes
var/displayed_lobby_art = -1

// Last global ID that was assigned to a mob (for round recording purposes)
var/last_mob_gid = 0
