#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombie_plague_special>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206
/*================================================================================
 [Customizations]
=================================================================================*/

// Zombie Attributes
new const zclass_name[] = "Swarm" // name
new const zclass_info[] = "Mata e nao infecta" // description
new const zclass_model[] = "NDK_zp_zombie_swarm" // model
new const zclass_clawmodel[] = "v_ndk_swarm_knife.mdl" // claw model

const zclass_health = 5000 // health
const zclass_speed = 230 // speed

const Float:zclass_gravity = 0.85 // gravity
const Float:zclass_knockback = 0.0 // knockback

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

// Variables
new g_iSwarmZID, g_iMaxPlayers

// Cvar pointers
new cvar_dmgmult, cvar_surv_dmgmult, cvar_blockinfbomb_infect

// Cached cvars
new bool:g_bCvar_Infbomb_Infect, Float:g_flCvar_DmgMult, Float:g_flCvar_SurvDmgMult

// Bools
new bool:g_bIsConnected[33], bool:g_bRoundEnding

// Offsets
const m_pPlayer = 41

// A const
const NADE_TYPE_INFECTION = 1111 // from main ZP plugin

// Plug info.
#define PLUG_VERSION "0.7"
#define PLUG_AUTH "meTaLiCroSS"

// Macros
#define zp_get_grenade_type(%1)        (entity_get_int(%1, EV_INT_flTimeStepSound))
#define is_user_valid_connected(%1)    (1 <= %1 <= g_iMaxPlayers && g_bIsConnected[%1])

/*================================================================================
 [Init, CFG and Precache]
=================================================================================*/

public plugin_init()
{
    // Plugin Register
    register_plugin("[ZP] Zombie Class: Swarm Zombie", PLUG_VERSION, PLUG_AUTH)
        
    // Main events
    register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
    register_menu("Menu Swarm", KEYSMENU, "menu_swarm_cases");
    
    // Hamsandwich Forwards
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_KnifeAttack")
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_KnifeAttack")
    
    // Cvars
    cvar_dmgmult = register_cvar("zp_swarm_damage_mult", "2.0")
    cvar_surv_dmgmult = register_cvar("zp_swarm_surv_damage_mult", "3.0")
    cvar_blockinfbomb_infect = register_cvar("zp_swarm_infbomb_infect", "1")
    
    static szCvar[30]
    formatex(szCvar, charsmax(szCvar), "v%s by %s", PLUG_VERSION, PLUG_AUTH)
    register_cvar("zp_zclass_swarm", szCvar, FCVAR_SERVER|FCVAR_SPONLY) 
    
    // Vars
    g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
    // Do some cvars cache
    cache_cvars()
}

public plugin_precache()
{
    // Hamsandwich Forwards
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    
    // Register the new class and store ID for reference
    g_iSwarmZID = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)    
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_iSwarmZID) return PLUGIN_CONTINUE

	@SHOW_MENUSWARM(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUSWARM(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \ySWARM \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONESW");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOSW");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDASW");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDSW");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYSW");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNSW");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1SW");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Swarm");

	return PLUGIN_CONTINUE
}

public menu_swarm_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

/*================================================================================
 [Main Events]
=================================================================================*/

public event_RoundStart()
{
    // Do some cvars cache
    cache_cvars()
    
    // Update bool
    g_bRoundEnding = false
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public client_putinserver(id)
{
    // Updating bool
    g_bIsConnected[id] = true
}

public client_disconnected(id)
{
    // Updating bool
    g_bIsConnected[id] = false
}

public fw_KnifeAttack(knife)
{
    // We need to block the Knife attack, because
    // when has throwed an Infection bomb it can Kill/Infect
    // with Knife, and will be a bug
    // ----
    // Get knife owner (player)
    static iPlayer 
    iPlayer = get_pdata_cbase(knife, m_pPlayer, 4)
    
    // Non-player entity
    if(!is_user_valid_connected(iPlayer))
        return HAM_IGNORED
    
    // Swarm zombie class, not a nemesis and has throwed a infection nade
    if(zp_get_user_zombie_class(iPlayer) == g_iSwarmZID && !zp_get_user_nemesis(iPlayer) && zp_get_user_infection_nade(iPlayer) > 0)
        return HAM_SUPERCEDE
    
    return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagetype, gamemode)
{
    // In the Main ZP plugin, the TakeDamage forward is Superceded, so
    // we need to register this in Precache to get it working again
    // ----
    // Non-player attacker, self attack, attacked by world, or isn't make damage by himself


    if(!is_user_valid_connected(attacker) || victim == attacker || !attacker || attacker != inflictor)
        return HAM_IGNORED
        
    // Swarm zombie class
    if(zp_get_user_zombie(attacker) && zp_get_user_zombie_class(attacker) == g_iSwarmZID && !zp_get_user_nemesis(attacker) && !g_bRoundEnding)
    {
        // Get damage result (with survivor and human damage multiplier)
        static Float:flDamageResult 
        flDamageResult = damage * (zp_get_user_survivor(victim) ? g_flCvar_SurvDmgMult : g_flCvar_DmgMult)
        
        // Do damage again
        ExecuteHam(Ham_TakeDamage, victim, inflictor, attacker, flDamageResult, damagetype)
        
        // Stop here
        return HAM_SUPERCEDE;
    }
        
    return HAM_IGNORED
}

/*================================================================================
 [Zombie Plague Forwards]
=================================================================================*/

public zp_user_infect_attempt(victim, infector, nemesis)
{
    // Non-player infection or turned into a nemesis
    if(!infector || nemesis)    
        return PLUGIN_CONTINUE
        
    // Check Swarm Zombie class and block infection.
    // I'm detecting if is Zombie and isn't Nemesis because
    // can be an infection by zp_infect_user native
    if(zp_get_user_zombie_class(infector) == g_iSwarmZID && zp_get_user_zombie(infector) && !zp_get_user_nemesis(infector))
    {
        // With infection grenade then must kill or infect, defined by cvar.
        if(zp_get_user_infection_nade(infector) > 0)
        {
            switch(g_bCvar_Infbomb_Infect)
            {
                case true:    return PLUGIN_CONTINUE // Infect
                case false:    ExecuteHamB(Ham_Killed, victim, infector, 0) // Kill
            }
        }
        
        return ZP_PLUGIN_HANDLED
    }
        
    return PLUGIN_CONTINUE
}

public zp_user_infected_post(id, infector, nemesis)
{
    // It's the selected zombie class
    if(zp_get_user_zombie_class(id) == g_iSwarmZID && !nemesis)
    {
        // My rofl message :D
        client_print_color(id, print_team_default, "^4[ZP]^1 Voce ta usando Zombie ^4Swarm", zclass_name, PLUG_AUTH)
    }
}

public zp_round_ended(winteam)
{
    // Update bool
    g_bRoundEnding = true
}

/*================================================================================
 [Internal Functions]
=================================================================================*/

cache_cvars()
{
    // Caching cvars
    g_flCvar_DmgMult = get_pcvar_float(cvar_dmgmult)
    g_flCvar_SurvDmgMult = get_pcvar_float(cvar_surv_dmgmult)
    g_bCvar_Infbomb_Infect = bool:get_pcvar_num(cvar_blockinfbomb_infect)
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock zp_get_user_infection_nade(id)
{
    static iNade
    iNade = get_grenade(id)
    
    if(iNade > 0 && is_valid_ent(iNade) 
    && zp_get_grenade_type(iNade) == NADE_TYPE_INFECTION)    
        return iNade
    
    return 0;
}