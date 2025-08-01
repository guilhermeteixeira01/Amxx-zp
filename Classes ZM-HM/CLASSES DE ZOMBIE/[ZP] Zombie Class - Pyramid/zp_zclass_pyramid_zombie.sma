/*
/--------------[ZP] Zclass Pyramid Zombie----------------
/-This zombie class can not be hit in the head
/-More damage with knife (acording to cvar)
/-----------------------Have Fun!------------------------
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich> 
#include <zombieplague>

// Zombie Attributes
new const zclass_name[] =  "Pyramid Zombie"  // name
new const zclass_info[] =  "+damage -HP"  // description
new const zclass_model[] =  "pyramid"  // model
new const zclass_clawmodel[] = { "v_knife_.mdl" }  // claw model
const zclass_health = 1250 // health
const zclass_speed = 250 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback = 0.6 // knockback

// New variables
new g_zclassid1, zm_knife_damage, g_iMaxPlayers

// Registering cvars and fuctions
public plugin_init() {
	register_forward(FM_TraceLine, "fw_traceline", 1)
	g_iMaxPlayers = get_maxplayers()
	zm_knife_damage = register_cvar("zm_exta_knife_damage", "4")	
}

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	register_plugin("[ZP] Zombie Class: Pyramid Zombie", "1.0", "Zombiezzz") 
	
	// Register the new class and store ID for reference
	g_zclassid1 = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback) 
}

// No Headshot to the zombie
public fw_traceline(Float:start[3], Float:end[3], id, trace)
{
    if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_zombie_class(id) != g_zclassid1)
        return FMRES_IGNORED
    
    static iVictim
    iVictim = get_tr2(trace, TR_pHit)
    
    if(!(1 <= iVictim <= g_iMaxPlayers) || !is_user_alive(iVictim))
        return FMRES_IGNORED
    
    if(get_tr2(trace, TR_iHitgroup) != HIT_HEAD && (pev(id, pev_button) & IN_ATTACK))
    {
        set_tr2(trace, TR_flFraction, 1.0)
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

// Knife Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{ 
	if ( get_user_weapon(attacker) == CSW_KNIFE ) { 
  	SetHamParamFloat(4, damage * get_pcvar_float( zm_knife_damage ) ) 
 	}
}  

// This take effect when hte user is infected
public zp_user_infected_post ( id)
{
              if (zp_get_user_zombie_class(id) == g_zclassid1)
             {
                  client_print(id, print_chat, "[ZP] You have chossen Pyramid Zombie, Good Luck!")
             }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
