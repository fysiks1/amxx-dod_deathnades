/*********************************************************************************************
*
*	DOD DeathNades - Written for Day of Defeat 1.3
*
*	Rewritten by Vet(3TT3V) - www.rip2001.com - partymix@gmail.com
*	Rewritten by Wilson [29th ID] - www.dodplugins.net
*	Original Plugin by Firestorm - www.dodplugins.net
*
*	About this Plugin:
*	This plugin is another rewrite of Firestorm's dod_dropgrenades plugin. That plugin
*	was also rewritten by Wilson [29th ID] who added some sweet features. This rewrite is
*	kind of a combination of those 2 plugins. I've added many new features, and omitted a
*	few others.	Feature changes are listed below. Both Firestorm's original plugin and
*	Wilson's rewrite can be obtained at wwww.dodpugins.net
*
*	Description:
*	This plugin will allow players who die, to drop the grenades they're carrying, and allows
*	other players to pick them up and use them. The number of grenades dropped is dependent
*	upon the plugin's control setting. The plugin's behavior is controllable by admins with
*	level 'h' status via the 'amx_dod_deathnades' console command.
*
*	New Features:
*	- Ability to control, via Admin Command, how many grenades are dropped
*	- Grenades will not be dropped if player commits suicide or is TKed
*	- Optionally reports to the killer, via chat, that the victim dropped grenades
*	- Optionally disallows victims killed by grenades or rockets to spawn grenades
*	- Nades will fall at random locations and at random angles
*	- Players may carry 2 nades of each type (4 grenades max)
*	- Will also drop enemy grenades you've picked up
*	- Bots won't pickup nades when 'use' key is not enforced
*
*	Features Kept:
*	- Option to force players to press their 'use' key to pick up nades
*	- Grenade's lifespan time can be changed via cvar
*	- Spawns actual enemy's grenades
*
*	Features Dropped:
*	- Visual effects for dropped nades
*	- Compatability with Zor's Smoke Grenades plugin
*	- Option to drop ammobox model instead of grenade
*	- Ability to drop grenades while alive
*
*	Command:
*		dod_deathnades # (0 - 4)
*			0 = Disables the plugin
*			1 = Drop 1 nade of YOUR TEAM'S type
*			2 = Drops up to 2 nades of ANY type (default)
*			3 = Drops up to 3 nades of ANY type
*			4 = Drops ALL nades of ANY type
*			(Note: Of course, nades are only dropped if you have them)
*
*	CVARS:
*		dod_deathnades_ctrl <#> - Sets the mode of operation (see above, Default 2)
*		dod_deathnades_life <##> - Life (in seconds) of nade after its dropped (Default 20)
*		dod_deathnades_say <0|1> - Announce to killer, in chat, that victim dropped nades (Default 1)
*		dod_deathnades_wpn <0|1> - Don't drop a grenade if killed by a grenade or rocket (Default 1)
*		dod_deathnades_use <0|1> - Force players to press the 'use' key to pick up nades (Default 0)
*
*	CREDIT and THANKS to:
*		Firestorm - www.dodplugins.net
*			- Original plugin idea and code
*
*		Wilson [29th ID] - www.dodplugins.net
*			- The main conversion of Firestorm's plugin to fakemeta
*			- Implemention of the 'use' key to pickup nades
*			- Giving nades a variable lifespan
*			- Use of #defines instead of fakemeta_util (sweet idea)
*
*		teame06 - www.alliedmods.net
*			- Providing a work-around for 'dod_get_user_ammo' on LINUX machines
*
**********************************************************************************************/
// 2.0 changes
// Changed team defines
// Added "e" to Ammox event and have function check if plugin enabled
// Split up some conditions for more logical flow and efficiency
// Streamlined nade_cleanup routine
// Added routine to cleanup nades if ctrl changed to 0 during a round
// Changed nade set_origin method
// Return Think & Touch with SUPERCEDE
// Changed from client_death to DeathMsg event
// Fixed switching to picked-up nade if using a knife or spade
// Correct weapons error in DeathMsg

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <dodx>

#define PLUGIN "DOD_Deathnades"
#define VERSION "2.0"
#define AUTHOR "Vet(3TT3V)"
#define SVALUE "v2.0 by Vet(3TT3V)"

#define MAX_NADES_TYPE 2	// DON'T FUCK WITH THIS SETTING
#define BRITISH 0
#define ALLY_PTR 0
#define AXIS_PTR 1
#define HAND_OFFSET 289
#define STICK_OFFSET 291
#define MAX_PLAYERS 32

// Correct errors in DeathMsg weapons
#define DODDMW_MILLS_BOMB 39
#define DODDMW_MORTAR 32

// From VEN's FM_Utilities
#define fm_set_model(%1,%2) engfunc(EngFunc_SetModel, %1, %2)
#define fm_set_origin(%1,%2) engfunc(EngFunc_SetOrigin, %1, %2)
#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1)
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

// Entity globals
new g_ent_myclass[3][] = {"vetnadeally", "vetnadeally", "vetnadeaxis"}
new g_ent_mdl[3][] = {"models/w_mills.mdl", "models/w_grenade.mdl", "models/w_stick.mdl"}
new g_give_nade[3][] = {"weapon_handgrenade", "weapon_handgrenade", "weapon_stickgrenade"}

// Pcvar globals
new g_control
new g_nade_life
new g_wpn_restrict
new g_nade_say
new g_use_key

// Client_Death info array
enum CDinfo {
	MyTeam,
	OppTeam,
	MyNades,
	OppNades,
	Dropped
}

// Nade count global
new g_pnades[MAX_PLAYERS + 1][2]

public plugin_precache()
{
	precache_model(g_ent_mdl[BRITISH])
	precache_model(g_ent_mdl[ALLIES])
	precache_model(g_ent_mdl[AXIS])
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("DeathMsg", "event_death", "a")
	register_forward(FM_Touch, "nade_touch")
	register_forward(FM_Think, "nade_think", 1)
	register_concmd("dod_deathnades", "deathnades_ctrl", ADMIN_CFG, "<#|?>")
	register_event("AmmoX", "ammo_update", "be")
	register_event("RoundState", "cleanup_nades", "a", "1=3", "1=4")

	g_control = register_cvar("dod_deathnades_ctrl", "2")
	g_nade_life = register_cvar("dod_deathnades_life", "20")
	g_wpn_restrict = register_cvar("dod_deathnades_wpn", "1")
	g_nade_say = register_cvar("dod_deathnades_say", "1")
	g_use_key = register_cvar("dod_deathnades_use", "0")

	register_cvar(PLUGIN, SVALUE, FCVAR_SERVER|FCVAR_SPONLY)
	return PLUGIN_CONTINUE
}

public ammo_update(id)
{
	if (get_pcvar_num(g_control)) {
		g_pnades[id][ALLY_PTR] = get_pdata_int(id, HAND_OFFSET)
		g_pnades[id][AXIS_PTR] = get_pdata_int(id, STICK_OFFSET)
	}
	return PLUGIN_CONTINUE
}

public event_death()
{
	static killer, victim, wpnindex
	static ctrl
	static CD[CDinfo]

	killer = read_data(1)
	victim = read_data(2)
	wpnindex = read_data(3)

	ctrl = get_pcvar_num(g_control)
	if (!ctrl || killer == victim || !killer)
		return PLUGIN_CONTINUE		// Plugin disabled, Suicide or Worldspawn death, so exit
	if (get_user_team(killer) == get_user_team(victim))
		return PLUGIN_CONTINUE		// TK, so exit

	if (get_pcvar_num(g_wpn_restrict)) {
		switch(wpnindex) {
			case DODW_HANDGRENADE, DODW_STICKGRENADE, DODW_HANDGRENADE_EX, DODW_STICKGRENADE_EX, DODDMW_MILLS_BOMB: {
				return PLUGIN_CONTINUE
			}
			case DODW_BAZOOKA, DODW_PANZERSCHRECK, DODW_PIAT, DODDMW_MORTAR: {
				return PLUGIN_CONTINUE
			}
		}
	}
	CD[MyTeam] = get_user_team(victim)
	if (CD[MyTeam] == ALLIES) {
		CD[OppTeam] = AXIS
		CD[MyTeam] = dod_get_map_info(MI_ALLIES_TEAM) ? BRITISH : ALLIES
	}
	else
		CD[OppTeam] = dod_get_map_info(MI_ALLIES_TEAM) ? BRITISH : ALLIES

	CD[MyNades] = (CD[MyTeam] == AXIS) ? g_pnades[victim][AXIS_PTR] : g_pnades[victim][ALLY_PTR]
	CD[OppNades] = (CD[MyTeam] == AXIS) ? g_pnades[victim][ALLY_PTR] : g_pnades[victim][AXIS_PTR]
	if (!CD[MyNades] && !CD[OppNades])
		return PLUGIN_CONTINUE		// No nades, so exit

	CD[Dropped] = 0
	switch(ctrl) {
		case 1: {
			if (CD[MyNades]) {
				spawn_nade(victim, CD[MyTeam])
				++CD[Dropped]
			}
		}
		case 2, 3, 4: {
			while (CD[MyNades] > 0) {
				spawn_nade(victim, CD[MyTeam])
				--CD[MyNades]
				++CD[Dropped]
			}
			while (CD[Dropped] < ctrl && CD[OppNades] > 0) {
				spawn_nade(victim, CD[OppTeam])
				--CD[OppNades]
				++CD[Dropped]
			}
		}
	}
	if (get_pcvar_num(g_nade_say) && CD[Dropped]) {
		new vname[32]
		get_user_name(victim, vname, 31)
		client_print(killer, print_chat, "%s dropped %s", vname, (CD[Dropped] > 1) ? "some grenades" : "a grenade")
	}
	return PLUGIN_CONTINUE
}

public spawn_nade(id, type)
{
	static Float:n_info[3], ent
	n_info = Float:{0.0, 0.0, 0.0}
	ent = fm_create_entity("info_target")

	set_pev(ent, pev_classname, g_ent_myclass[type])
	n_info[1] = get_gametime() + float(get_pcvar_num(g_nade_life))
	set_pev(ent, pev_nextthink, n_info[1])
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	n_info[1] = float(random(360))
	set_pev(ent, pev_angles, n_info)
	pev(id, pev_origin, n_info)
	n_info[0] += (random(31) - 15)
	n_info[1] += (random(31) - 15)
	fm_set_origin(ent, n_info)
	fm_set_model(ent, g_ent_mdl[type])
}

public nade_touch(ent, player)
{
	static touch_class[32], weapon

	if (!pev_valid(ent))
		return FMRES_IGNORED
	pev(ent, pev_classname, touch_class, 31)
	if (!equal(touch_class, g_ent_myclass[BRITISH], 8))
		return FMRES_IGNORED
	if (!is_user_alive(player) || is_user_bot(player) || !get_pcvar_num(g_control))
		return FMRES_IGNORED
	if (get_pcvar_num(g_use_key)) {
		if (!(pev(player, pev_button) & IN_USE && pev(player, pev_oldbuttons) & ~IN_USE))
			return FMRES_IGNORED
	}

	weapon = dod_get_user_weapon(player, _, _)
	if (equal(touch_class, g_ent_myclass[ALLIES]) && get_pdata_int(player, HAND_OFFSET) < MAX_NADES_TYPE)
		fm_give_item(player, g_give_nade[ALLIES])
	else {
		if (equal(touch_class, g_ent_myclass[AXIS]) && get_pdata_int(player, STICK_OFFSET) < MAX_NADES_TYPE)
			fm_give_item(player, g_give_nade[AXIS])
		else
			return FMRES_IGNORED
	}

	switch(weapon) {
		case 1, 37: {
			client_cmd(player, "weapon_amerknife")
		}
		case 2: {
			client_cmd(player, "weapon_gerknife")
		}
		case 19: {
			client_cmd(player, "weapon_spade")
		}
	}
	fm_remove_entity(ent)
	return FMRES_SUPERCEDE
}

public nade_think(ent)
{
	static think_class[32]
	if (get_pcvar_num(g_control) && pev_valid(ent)) {
		pev(ent, pev_classname, think_class, 31)
		if (equal(think_class, g_ent_myclass[BRITISH], 8)) {
			fm_remove_entity(ent)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public cleanup_nades()
{
	new ent = -1
	while ((ent = fm_find_ent_by_class(ent, g_ent_myclass[ALLIES]))) {
		fm_remove_entity(ent)
	}
	ent = -1
	while ((ent = fm_find_ent_by_class(ent, g_ent_myclass[AXIS]))) {
		fm_remove_entity(ent)
	}
	return PLUGIN_CONTINUE
}

public deathnades_ctrl(id, lvl, cid)
{
	if (!cmd_access(id, lvl, cid, 2))
		return PLUGIN_HANDLED
		
	new tmpstr[32]
	read_argv(1, tmpstr, 31)
	trim(tmpstr)
	if (equal(tmpstr, "?")) {
		console_print(id, "^nDeathnades Control: dod_deathnades #")
		console_print(id, "  0 - Disables Deathnades plugin")
		console_print(id, "  1 - Drop 1 nade of YOUR type")
		console_print(id, "  2 - Drop up to 2 nades of ANY type")
		console_print(id, "  3 - Drop up to 3 nades of ANY type")
		console_print(id, "  4 - Drop ALL nades of ANY type")
		console_print(id, "DOD_Deathnades Is Currently Set To: %d^n", get_pcvar_num(g_control))
		return PLUGIN_HANDLED
	}

	new tmpctrl = str_to_num(tmpstr)
	if (tmpctrl < 0 || tmpctrl > 4) {
		console_print(id, "Deathnades control parameter out of range (0 - 4)")
		return PLUGIN_HANDLED
	}

	if (tmpctrl == 0)
		cleanup_nades()
	set_cvar_string("dod_deathnades_ctrl", tmpstr)
	get_user_name(id, tmpstr, 31)
	console_print(id, "Deathnades control changed to %d", tmpctrl)
	log_message("[AMXX] Deathnades - Admin %s changed Deathnades control to %d", tmpstr, tmpctrl)

	return PLUGIN_HANDLED
}

// From VEN's FM_Utilities (slightly modified)
stock fm_give_item(index, const item[]) {
	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)
	return -1
}