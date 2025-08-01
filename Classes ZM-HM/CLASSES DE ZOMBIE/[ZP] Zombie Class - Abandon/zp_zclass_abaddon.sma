/* ~ Change Log ~
 * 1.0 - Первый релиз
 */

new const PLUGIN_VERSION[] = "1.0"
new const PLUGIN_PREFIX[] = "^1[^4t3^1]"

#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <ColorChat>
#include <zombieplague>

new const Class_Name[] = { "Abaddon Zombie" }
new const Class_Info[] = { "Borrowed Time \r[G]" }
new const Class_Model[] = { "abaddon_zombie" }
new const Class_Hand_Model[] = { "v_knife_abaddon.mdl" }

const Class_HP = 2300
const Class_Speed = 225
const Float:Class_Gravity = 0.8
const Float:Class_Knockback = 1.75

new const ABILITY_SOUND[][] = { "abaddon/borrowed_time.wav" }

new g_class_abaddon;
new bool:g_Ability[33];                          
new cvar_skill_time, cvar_skill_countdown;

public plugin_init() 
{
    register_plugin("[ZP] Class: Abaddon Zombie", PLUGIN_VERSION, "t3rkecorejz");
    
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    
    register_clcmd("drop", "ability");
    
    cvar_skill_time = register_cvar("zp_abaddon_skill_time", "5.0");
    cvar_skill_countdown = register_cvar("zp_abaddon_skill_cd", "30.0");
}

public plugin_precache()
{
    g_class_abaddon = zp_register_zombie_class(Class_Name, Class_Info, Class_Model, Class_Hand_Model, Class_HP, Class_Speed, Class_Gravity, Class_Knockback); 

    for(new i=0;i<sizeof(ABILITY_SOUND);i++) engfunc(EngFunc_PrecacheSound, ABILITY_SOUND[i])
}

public zp_user_infected_post(id, infector)
{    
    if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_class_abaddon && !zp_get_user_nemesis(id))
    {
        ColorChat(id, TEAM_COLOR, "%s Ваша способность ^3[Borrowed Time]^1. Активация ^4[G]", PLUGIN_PREFIX);
    }
}

public ability(id)
{
    static Float:fLastUse[33];
    
    if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_class_abaddon && is_user_alive(id) && !zp_get_user_nemesis(id)  && fLastUse[id] + get_pcvar_float(cvar_skill_countdown) < get_gametime())
    {
        g_Ability[id] = true;
        
        set_task(get_pcvar_float(cvar_skill_time), "EndSkill", id+227);
        set_task(get_pcvar_float(cvar_skill_countdown), "CDSkill", id+228);
        
        emit_sound(id, CHAN_VOICE, ABILITY_SOUND[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
        
        ColorChat(id, TEAM_COLOR, "%s Пока вам наносят урон - вы лечитесь!", PLUGIN_PREFIX);
        
        fLastUse[id] = get_gametime();
        
        fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 1);
        
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
        write_short(1<<14);
        write_short(1<<14);
        write_short(0x0000);
        write_byte(255);
        write_byte(0);
        write_byte(0);
        write_byte(60);
        message_end();
        
        play_weapon_anim(id, 8);
        
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if(!is_user_alive(victim) || !is_user_connected(victim))
        return 1;

    if(zp_get_user_zombie(victim) && zp_get_user_zombie_class(victim) == g_class_abaddon)
    {
        if(g_Ability[victim] == true)
        {
            set_user_health(victim, get_user_health(victim) + (floatround(damage) * 2))
        }
    }
    return HAM_IGNORED;
}

public EndSkill(id)
{
    id-=227
    fm_set_rendering(id, kRenderFxNone, 113, 227, 234, kRenderNormal, 1);
    
    g_Ability[id] = false;
    
    message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id);
    write_short(0);
    write_short(0);
    write_short(0);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    write_byte(255);
    message_end();
}

public CDSkill(id)
{
    id-=228
    ColorChat(id, TEAM_COLOR, "%s Ваша способность ^3[Borrowed Time]^1 готова! Активация ^4[G]", PLUGIN_PREFIX);
}

play_weapon_anim(player, anim)
{
    set_pev(player, pev_weaponanim, anim)
    message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
    write_byte(anim)
    write_byte(0)
    message_end()
}
