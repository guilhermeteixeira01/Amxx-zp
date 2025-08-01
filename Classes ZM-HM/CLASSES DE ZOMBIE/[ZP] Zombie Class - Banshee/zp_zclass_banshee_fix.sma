#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>
#include <xs>

#define PLUGIN "[ZP] Zombie Class Banshee"
#define VERSION "2.0"
#define AUTHOR "Csoldjb & Teixeira"

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

new const zclass_name[] = "Bruxa"
new const zclass_info[] = "(G) Para soltar os Morcegos"
new const zclass_model[] = "x_zm_banshee"
new const zclass_clawmodel[] = "v_knife_banshee.mdl"
const zclass_health = 1800
const zclass_speed = 190
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 1.0

new const SOUND_FIRE[] = "class_zombie/zm_banshe/zombi_banshee_pulling_fire.wav"
new const SOUND_BAT_HIT[] = "class_zombie/zm_banshe/zombi_banshee_laugh.wav"
new const SOUND_BAT_MISS[] = "class_zombie/zm_banshe/zombi_banshee_pulling_fail.wav"
new const MODEL_BAT[] = "models/bat_banshee.mdl"
new const BAT_CLASSNAME[] = "banchee_bat"
new spr_skull

const Float:banchee_skull_bat_speed = 600.0
const Float:banchee_skull_bat_flytime = 3.0
const Float:banchee_skull_bat_catch_time = 3.0
const Float:banchee_skull_bat_catch_speed = 100.0
const Float:bat_timewait = 20.0

new g_stop[33]
new g_bat_time[33]
new g_bat_stat[33]
new g_bat_enemy[33]
//new Float:g_temp_speed[33]

new idclass_banchee
new g_maxplayers
new g_roundend

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2367,
	TASK_REMOVE_STAT
}

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_TASK_REMOVE_STAT (taskid - TASK_REMOVE_STAT)

public plugin_precache()
{
	precache_sound(SOUND_FIRE)
	precache_sound(SOUND_BAT_HIT)
	precache_sound(SOUND_BAT_MISS)
	
	precache_model(MODEL_BAT)
	
	spr_skull = precache_model("sprites/banshee/ef_bat.spr")
	
	idclass_banchee = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeath", "a")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_clcmd("drop", "cmd_bat")

	register_menu("Menu Banshe", KEYSMENU, "menu_banshe_cases");
	
	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	
	RegisterHam(Ham_Touch,"info_target","EntityTouchPost",1)
	RegisterHam(Ham_Think,"info_target","EntityThink")
	
	g_maxplayers = get_maxplayers()
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != idclass_banchee) return PLUGIN_CONTINUE

	@SHOW_MENUBANSHE(id)
	return PLUGIN_HANDLED
}


@SHOW_MENUBANSHE(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yBruxa \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONEB");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOB");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDAB");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDB");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYB");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNB");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DCB1");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Banshe");

	return PLUGIN_CONTINUE
}

public menu_banshe_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	reset_value_player(id)
}

public client_disconnected(id)
{
	reset_value_player(id)
}

public EventHLTV()
{
	g_roundend = 0
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public EventDeath()
{
	new id = read_data(2)
	
	reset_value_player(id)
}

public zp_user_infected_post(id)
{
	reset_value_player(id)
	
	if(zp_get_zombie_special_class(id)) return;
	
	if(zp_get_user_zombie_class(id) == idclass_banchee)
	{
		if(is_user_bot(id))
		{
			set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
			return
		}
		client_print_color(id, print_team_default, "%L", id, "BAT_TIME", bat_timewait)
	}
}

public zp_user_humanized_post(id)
{
	reset_value_player(id)
}

public cmd_bat(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_zombie_special_class(id)) return PLUGIN_CONTINUE

	
	if(zp_get_user_zombie_class(id) == idclass_banchee && !g_bat_time[id])
	{
		g_bat_time[id] = 1
		
		set_task(bat_timewait,"clear_stat",id+TASK_REMOVE_STAT)
		
		new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
		
		if(!pev_valid(ent)) return PLUGIN_HANDLED
		
		new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
		fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
		pev(id,pev_angles,vecAngle)
		
		engfunc(EngFunc_MakeVectors,vecAngle)
		global_get(glb_v_forward,vecForward)
		
		velocity_by_aim(id,floatround(banchee_skull_bat_speed),vecVelocity)

		set_pev(ent,pev_origin,vecOrigin)
		set_pev(ent,pev_angles,vecAngle)
		set_pev(ent,pev_classname,BAT_CLASSNAME)
		set_pev(ent,pev_movetype,MOVETYPE_FLY)
		set_pev(ent,pev_solid,SOLID_BBOX)
		engfunc(EngFunc_SetSize,ent,{-20.0,-15.0,-8.0},{20.0,15.0,8.0})
		
		engfunc(EngFunc_SetModel,ent,MODEL_BAT)
		set_pev(ent,pev_animtime,get_gametime())
		set_pev(ent,pev_framerate,1.0)
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_velocity,vecVelocity)
		set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_flytime)
		emit_sound(ent, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		g_stop[id] = ent
		PlayWeaponAnimation(id, 2)
		//set_pev(id, pev_maxspeed, 0.1)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	
	if(g_bat_stat[id])
	{
		new owner = g_bat_enemy[id], Float:ownerorigin[3]
		pev(owner,pev_origin,ownerorigin)
		static Float:vec[3]
		aim_at_origin(id,ownerorigin,vec)
		engfunc(EngFunc_MakeVectors, vec)
		global_get(glb_v_forward, vec)
		vec[0] *= banchee_skull_bat_catch_speed
		vec[1] *= banchee_skull_bat_catch_speed
		vec[2] = 0.0
		set_pev(id, pev_velocity, vec)
	}
	
	return FMRES_IGNORED
}

public EntityThink(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		static Float:origin[3];
		pev(ent,pev_origin,origin);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION); // TE_EXPLOSION
		write_coord(floatround(origin[0])); // origin x
		write_coord(floatround(origin[1])); // origin y
		write_coord(floatround(origin[2])); // origin z
		write_short(spr_skull); // sprites
		write_byte(40); // scale in 0.1's
		write_byte(30); // framerate
		write_byte(14); // flags 
		message_end(); // message end
		
		emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		new owner = pev(ent, pev_owner)
		g_stop[owner] = 0
		//set_pev(owner,pev_maxspeed, g_temp_speed[owner])
		
		engfunc(EngFunc_RemoveEntity,ent)
	}
	
	return HAM_IGNORED
}

public EntityTouchPost(ent,ptd)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		if(!pev_valid(ptd))
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
			write_byte(TE_EXPLOSION); // TE_EXPLOSION
			write_coord(floatround(origin[0])); // origin x
			write_coord(floatround(origin[1])); // origin y
			write_coord(floatround(origin[2])); // origin z
			write_short(spr_skull); // sprites
			write_byte(40); // scale in 0.1's
			write_byte(30); // framerate
			write_byte(14); // flags 
			message_end(); // message end
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new owner = pev(ent, pev_owner)
			g_stop[owner] = 0
			//set_pev(owner, pev_maxspeed, g_temp_speed[owner])
			
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
		
		new owner = pev(ent,pev_owner)
		
		if(zp_get_user_zombie(ptd) || zp_get_zombie_special_class(ptd)) return PLUGIN_HANDLED;  // <- Verificação para bloquear de puchar os zombie ou special class

		if(0 < ptd && ptd <= g_maxplayers && is_user_alive(ptd) && ptd != owner)
		{
			g_bat_enemy[ptd] = owner
			
			set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_catch_time)
			set_task(banchee_skull_bat_catch_time,"clear_stat2",ptd+TASK_REMOVE_STAT)
			set_pev(ent,pev_movetype,MOVETYPE_FOLLOW)
			set_pev(ent,pev_aiment,ptd)
			
			emit_sound(owner, CHAN_VOICE, SOUND_BAT_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			g_bat_stat[ptd] = 1
		}
	}
	
	return HAM_IGNORED
}

public clear_stat(taskid)
{
	new id = ID_TASK_REMOVE_STAT
	
	g_bat_stat[id] = 0
	g_bat_time[id] = 0
	
	client_print_color(id, print_team_default, "%L", id, "BAT_STAT");
}

public clear_stat2(idx)
{
	new id = idx-TASK_REMOVE_STAT
	
	g_bat_enemy[id] = 0
	g_bat_stat[id] = 0
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;
	
	cmd_bat(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}

reset_value_player(id)
{
	g_stop[id] = 0
	g_bat_time[id] = 0
	g_bat_stat[id] = 0
	g_bat_enemy[id] = 0
	
	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id+TASK_REMOVE_STAT)
}
