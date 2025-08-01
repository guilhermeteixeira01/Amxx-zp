#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fun>

//native zp_override_user_model(id, const newmodel[], modelindex = 0)

// ZP NATIVE
#include <zombie_plague_special>

#define PLUGIN	"[ZP] Metatronic Zombie"
#define VERSION	"1.0"
#define AUTHOR	"Asep Khairul Anam"

/*
***************************************
The Plugins Is Made By Asep KhairulAnam
***************************************
************ ZOMBIE-MOD.RU ************
***************************************
NOTE: Please To Don't Enabled Admin Knife
Zombie Or Admin Knife Player Models To Work
The Plugins ...
*/

// Player Model In The "cstrike/models/player/metatronic_zombie/metatronic_zombie.mdl"
#define PLAYER_MODEL		"metatronic_zombie"

// Zombie Configuration (String)
#define ZOMBIE_NAME			"Metatronic Zombie"
#define ZOMBIE_INFO			"Can Revival, Create Fake Health"
#define ZOMBIE_MODEL			"metatronic_zombie"
#define ZOMBIE_CLAW_MDL			"v_knife_metatronic.mdl"
#define ZM_CLAWBOMB				"v_bomb_metatronic_merah.mdl"

// Buff Sprites
#define BUFFSPR_MODEL		"sprites/zb_skill_hpbuff.spr"
#define BUFFSPR_CLASSNAME	"buffspr_skill"
#define BUFFSPR_SCALE		1.0
#define BUFFSPR_ORIGIN_X	0.0
#define BUFFSPR_ORIGIN_Y	0.0
#define BUFFSPR_ORIGIN_Z	50.0

// Heal Sprites
#define SPR_MODEL		"sprites/zb_skill_hp.spr"
#define SPR_CLASSNAME		"buffspr_skill"
#define SPR_SCALE		1.0
#define SPR_ORIGIN_X		0.0
#define SPR_ORIGIN_Y		0.0
#define SPR_ORIGIN_Z		50.0

// Zombie Configuration
#define ZOMBIE_HEALTH		6000
#define ZOMBIE_SPEED		250
#define ZOMBIE_GRAVITY		0.9
#define ZOMBIE_KNOCKBACK	0.8

// Zombie Configuration (Skill)
#define ZOMBIE_SKILL_1_TIME		5	// Time GodMode + Regeneration
#define ZOMBIE_SKILL_1_COUNT		5	// Count Regen
#define ZOMBIE_SKILL_1_REGEN		100	// Health Regen
#define ZOMBIE_SKILL_2_FAKE_HEALTH	2000	// Fake Health Count
#define DELAY_SKILL_1			50	// Delay To Use The Skill Again
#define DELAY_SKILL_2			30	// Delay To Use The Skill Again

// Task
#define TASK_SKILL	10221
#define	TASK_DELAY	10222

enum _:METATRONIC_SKILL
{
	SKILL_READY = 0,
	SKILL_USE,
	SKILL_DELAY,
	SKILL_DO
}

enum _:METATRONIC_ANIMATION
{
	V_ANIM_SKILL_1	= 2,
	P_ANIM_SKILL_1	= 150
}

enum _:METATRONIC_SOUND
{
	SKILL_1 = 0,
	SKILL_2,
	PAIN_HURT,
	PAIN_DEATH_1,
	PAIN_DEATH_2,
	PAIN_HEAL
}

enum _:METATRONIC_ENT
{
	ENT_HEAD_SPR_HP_BUFF = 0,
	ENT_HEAD_SPR_HP
}

new const MetatronicSound[][] = 
{
	"asep/metatronic_skill.wav",
	"asep/metatronic_revival.wav",
	"asep/metatronic_pain_hurt.wav",
	"asep/metatronic_pain_death1.wav",
	"asep/metatronic_pain_death2.wav",
	"asep/metatronic_heal.wav"
}

new g_head_spr_ent[33][2]
new class_metatronic[33]
new g_skill1[33]
new g_skill1_regen_count[33]
new g_skill2[33]
new g_skill2_fake_health[33]
new Float:g_speed_hud[33]
new sync_hud
new g_godmode_temp[33]
new g_HamBot
new index_metatronic
new g_metatronic

public plugin_init()
{
	// Register Plugins .....
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Forward Event
	register_event("DeathMsg", "Event_Death", "a")
	register_event("CurWeapon","Event_CurWeapon","be","1=1")
	register_event("HLTV", "Event_RoundStart", "a", "1=0", "2=0")
	
	// Forward Log Event
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	
	// Forward Fakemeta
	register_forward(FM_CmdStart , "Forward_CmdStart")
	
	// Forward Ham
	RegisterHam(Ham_TakeDamage, "player", "Forward_TakeDamage")
	
	// Forward Think Entity
	register_think(BUFFSPR_CLASSNAME, "Forward_Buffspr_Think")
	register_think(SPR_MODEL, "Forward_Spr_Think")
	
	// Create Sync Hud
	sync_hud = CreateHudSyncObj()
	g_metatronic = zp_register_zombie_class(ZOMBIE_NAME, ZOMBIE_INFO, ZOMBIE_MODEL, ZOMBIE_CLAW_MDL, ZOMBIE_HEALTH, ZOMBIE_SPEED, ZOMBIE_GRAVITY, ZOMBIE_KNOCKBACK)
}

public plugin_precache()
{	
	for(new i = 0; i < sizeof(MetatronicSound); i++)
		precache_sound(MetatronicSound[i])
	
	new CLAW_MDL[101]
	formatex(CLAW_MDL, charsmax(CLAW_MDL), "models/ZMR/%s", ZOMBIE_CLAW_MDL)
	precache_model(CLAW_MDL)
	
	precache_model(BUFFSPR_MODEL)
	precache_model(SPR_MODEL)
	
	new player_models[101]
	formatex(player_models, charsmax(player_models), "models/player/%s/%s.mdl", PLAYER_MODEL, PLAYER_MODEL)
	index_metatronic = precache_model(player_models)
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
	metatronic_reset_value( id );
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "Forward_TakeDamage")
}

public zp_user_humanized_post(id) metatronic_reset_value(id)
public Event_RoundEnd(id) metatronic_reset_value(id)
public Event_RoundStart(id) metatronic_reset_value(id)
public Event_Death()
{
	new id = read_data(2)
	if(zp_get_user_zombie(id) && class_metatronic[id])
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, MetatronicSound[random_num(PAIN_DEATH_1, PAIN_DEATH_2)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		metatronic_reset_value(id)
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	
	if(g_skill1[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
	else if(g_skill2[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
}

public Forward_TakeDamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker))
		return HAM_IGNORED
	if(!class_metatronic[victim])
		return HAM_IGNORED
	
	engfunc(EngFunc_EmitSound, victim, CHAN_BODY, MetatronicSound[PAIN_HURT], 1.0, ATTN_NORM, 0, PITCH_NORM)

	if(g_skill1[victim] == SKILL_USE)
		return HAM_SUPERCEDE
		
	if(g_skill1[victim] == SKILL_USE && damage >= get_user_health(victim) && !g_godmode_temp[victim])
	{
		g_skill1[victim] = SKILL_DO
		g_godmode_temp[victim] = 2
		return HAM_SUPERCEDE
	}
	
	if(g_skill1[victim] == SKILL_DO && damage >= get_user_health(victim) && g_godmode_temp[victim] > 0)
	{
		g_godmode_temp[victim]--
		return HAM_SUPERCEDE
	}
	
	if(g_skill2[victim] == SKILL_USE)
	{
		if(g_skill2_fake_health[victim] > 0)
		{
			g_skill2_fake_health[victim] -= floatround(damage)
			g_speed_hud[victim] = 0.05
			ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, 0.0, dmgtype)
		}
		else if(g_skill2_fake_health[victim] <= 0)
		{
			g_skill2[victim] = SKILL_DELAY
			g_skill2_fake_health[victim] = 0
			g_speed_hud[victim] = 1.0
			metatronic_remove_headspr(victim, ENT_HEAD_SPR_HP_BUFF)
			set_task(float(DELAY_SKILL_2), "action_skill2_delay", victim+TASK_DELAY)
		}
		
		return HAM_SUPERCEDE
	}
		
	return HAM_HANDLED
}

public show_metatronic_hud(id)
{
	static Temp_Skill_1[128], Temp_Skill_2[256]
	static Red[2], Blue[2], Green[2]
	if(g_skill1[id] == SKILL_READY)
	{
		Red[0] = 200
		Green[0] = 200
		Blue[0] = 200
		
		formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] - Регенерация || Невозможно")
	}
	else if(g_skill1[id] == SKILL_USE)
	{
		Red[0] = 200
		Green[0] = 200
		Blue[0] = 0
		
		formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] - Регенерация || Используется..")
	}
	else if(g_skill1[id] == SKILL_DELAY)
	{
		Red[0] = 255
		Green[0] = 0
		Blue[0] = 0
		
		formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] - Регенерация || Перезарядка..")
	}
	else if(g_skill1[id] == SKILL_DO)
	{
		Red[0] = 0
		Green[0] = 255
		Blue[0] = 0
		
		formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] - Регенерация || Готово")
	}
	
	if(g_skill2[id] == SKILL_READY)
	{
		Red[1] = 0
		Green[1] = 255
		Blue[1] = 0
		
		formatex(Temp_Skill_2, sizeof(Temp_Skill_2), "%s^n[ R ] - Выдержка || Готово", Temp_Skill_1)
	}
	else if(g_skill2[id] == SKILL_USE)
	{
		Red[1] = 0
		Green[1] = 180
		Blue[1] = 200
		
		formatex(Temp_Skill_2, sizeof(Temp_Skill_2), "%s^n---- ВЫДЕРЖКА: %i ----", Temp_Skill_1, g_skill2_fake_health[id])
	}
	else if(g_skill2[id] == SKILL_DELAY)
	{
		Red[1] = 255
		Green[1] = 0
		Blue[1] = 0
		
		formatex(Temp_Skill_2, sizeof(Temp_Skill_2), "%s^n[ R ] - Выдержка || Перезарядка...", Temp_Skill_1)
	}
	
	set_hudmessage(Red[0], Green[0], Blue[0], -1.0, -0.79, 0, 2.0, 10.0)
	ShowSyncHudMsg(id, sync_hud, Temp_Skill_2)
}

public Forward_CmdStart(id, UC_Handle, seed)
{
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	
	static Float:CurrentTime, Float:g_hud_delay[33]
	CurrentTime = get_gametime()
	
	if(CurrentTime - g_speed_hud[id] > g_hud_delay[id])
	{
		show_metatronic_hud(id)
		
		if(pev(id, pev_solid) == SOLID_NOT)
			set_pev(id, pev_solid, SOLID_BBOX)
			
		if(g_skill1[id] == SKILL_USE && g_skill1_regen_count[id] > 0)
		{
			set_user_health(id, get_user_health(id) + ZOMBIE_SKILL_1_REGEN)
			engfunc(EngFunc_EmitSound, id, CHAN_ITEM, MetatronicSound[SKILL_2], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			g_skill1_regen_count[id]--
		}
		
		if(g_speed_hud[id] < 1.0)
			g_speed_hud[id] = 1.0
			
		g_hud_delay[id] = CurrentTime
	}
	
	if(g_skill1[id] == SKILL_READY && get_user_health(id) <= 100)
		g_skill1[id] = SKILL_DO
	
	static PressedButton
	PressedButton = get_uc(UC_Handle, UC_Buttons)
	
	if(PressedButton & IN_USE)
	{
		if(g_skill1[id] != SKILL_DO)
			return
			
		set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
		set_task(0.001, "action_skill_1", id+TASK_SKILL)
	}
	else if(PressedButton & IN_RELOAD)
	{
		if(g_skill2[id] != SKILL_READY)
			return
		
		set_task(0.001, "action_skill_2", id+TASK_SKILL)
	}
	
}

public zp_zombie_class_choosed_pre(id, classid) 
{
	if(g_metatronic != classid)
		return PLUGIN_CONTINUE;

	zp_menu_textadd("\d[SEM ACESSO]"); // Adiciona um textin igual no 5.0
	if(!(get_user_flags(id) & ADMIN_LEVEL_G) && !(get_user_flags(id) & ADMIN_LEVEL_F) && !(get_user_flags(id) & ADMIN_LEVEL_E) && !(get_user_flags(id) & ADMIN_LEVEL_D) && !(get_user_flags(id) & ADMIN_LEVEL_C) && !(get_user_flags(id) & ADMIN_LEVEL_B) && !(get_user_flags(id) & ADMIN_LEVEL_A) && !(get_user_flags(id) & ADMIN_RCON))
		return ZP_PLUGIN_HANDLED;

	else 
	zp_menu_textadd("\y[ACESSO ACEITO]")
	return PLUGIN_CONTINUE;
}

public zp_user_infected_post(id)
{
	if(zp_get_user_zombie_class(id) == g_metatronic && !zp_get_user_nemesis(id))
	{
		class_metatronic[id] = true
	
		show_metatronic_hud(id)
		metatronic_reset_var_skill(id)
		
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		
		//zp_override_user_model(id, PLAYER_MODEL)
		set_pdata_int(id, 491, index_metatronic, 5)
		
		set_user_maxspeed(id, float(ZOMBIE_SPEED))
		set_user_gravity(id, ZOMBIE_GRAVITY)
		
		remove_task(id)
		remove_task(id+TASK_SKILL)
		remove_task(id+TASK_DELAY)
	}
}

public action_skill_1(id)
{
	id -= TASK_SKILL
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill1[id] != SKILL_DO)
		return
	
	g_skill1[id] = SKILL_USE
	g_skill1_regen_count[id] = ZOMBIE_SKILL_1_COUNT
	
	set_pdata_float(id, 83, 1.03, 5)
	
	set_weapon_anim(id, V_ANIM_SKILL_1)
	set_pev(id, pev_sequence, P_ANIM_SKILL_1)
	set_pev(id, pev_framerate, 0.5)
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, MetatronicSound[SKILL_1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(30) // radius
	write_byte(150)    // r
	write_byte(150)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(40)  // decay rate in 10's
	message_end()
	
	// Create Head SPR (By Dias)
	Create_Head_Sprites(id, ENT_HEAD_SPR_HP, SPR_CLASSNAME, SPR_MODEL, 0.75, 20.0, 5.0, 255.0, SPR_ORIGIN_X, SPR_ORIGIN_Y, SPR_ORIGIN_Z, 1, 0, 180, 220)
	
	set_task(1.0, "action_reset_ability", id+TASK_SKILL)
	set_task(float(ZOMBIE_SKILL_1_TIME), "reset_action_skill_1", id+TASK_SKILL)
}

public action_reset_ability(id)
{
	id -= TASK_SKILL
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill1[id] != SKILL_USE)
		return
	
	set_pev(id, pev_framerate, 1.0)
}

public reset_action_skill_1(id)
{
	id -= TASK_SKILL
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill1[id] != SKILL_USE)
		return
	
	g_skill1[id] = SKILL_DELAY
	metatronic_remove_headspr(id, ENT_HEAD_SPR_HP)
	
	set_task(float(DELAY_SKILL_1), "action_skill1_delay", id+TASK_DELAY)
}

public action_skill1_delay(id)
{
	id -= TASK_DELAY
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill1[id] != SKILL_DELAY)
	{
		remove_task(id+TASK_DELAY)
		return
	}
	
	g_skill1[id] = SKILL_READY
}

public action_skill_2(id)
{
	id -= TASK_SKILL
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill2[id] != SKILL_READY)
		return
	
	g_skill2[id] = SKILL_USE
	g_skill2_fake_health[id] = ZOMBIE_SKILL_2_FAKE_HEALTH
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, MetatronicSound[PAIN_HEAL], 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, MetatronicSound[SKILL_2], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	Create_Head_Sprites(id, ENT_HEAD_SPR_HP_BUFF,  BUFFSPR_CLASSNAME, BUFFSPR_MODEL, 0.5, 0.0, 0.0, 255.0, BUFFSPR_ORIGIN_X, BUFFSPR_ORIGIN_Y, BUFFSPR_ORIGIN_Z, 1, 0, 180, 220)
}

public action_skill2_delay(id)
{
	id -= TASK_DELAY
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_metatronic[id])
		return
	if(g_skill2[id] != SKILL_DELAY)
	{
		remove_task(id+TASK_DELAY)
		return
	}
	
	g_skill2[id] = SKILL_READY
	g_skill2_fake_health[id] = 0
}

public Create_Head_Sprites(id, num, const Classname[], const Sprite[], Float:Scale, Float:Frame, Float:Time, Float:Transparent, Float:Forward, Float:Right, Float:Up, ColorActivate, Red, Green, Blue)
{
	// Thanks To Dias ... 
	
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent))
		return
		
	g_head_spr_ent[id][num] = Ent
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	Origin[0] += Forward
	Origin[2] += Up
	
	set_pev(Ent, pev_origin, Origin)
		
	set_pev(Ent, pev_takedamage, DAMAGE_NO)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	
	set_pev(Ent, pev_classname, Classname)
	engfunc(EngFunc_SetModel, Ent, Sprite)
	
	set_pev(Ent, pev_renderfx, kRenderFxNone)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, Transparent)
	
	new Color[3]
	Color[0] = Red
	Color[1] = Green
	Color[2] = Blue
	
	if(ColorActivate)
		set_pev(Ent, pev_rendercolor, Color)
	
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_scale, Scale)
	
	if(Time > 0.0)
		set_pev(Ent, pev_fuser1, get_gametime() + Time)
	
	set_pev(Ent, pev_fuser2, Forward)
	set_pev(Ent, pev_fuser3, Right)
	set_pev(Ent, pev_fuser4, Up)
	
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_iuser1, floatround(Frame))
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
}

public Forward_Buffspr_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3], owner
	owner = pev(ent, pev_owner)
	pev(owner, pev_origin, Origin)
	
	Origin[0] += pev(ent, pev_fuser2)
	Origin[1] += pev(ent, pev_fuser3)
	Origin[2] += pev(ent, pev_fuser4)
	
	engfunc(EngFunc_SetOrigin, ent, Origin)
	set_pev(ent, pev_nextthink, get_gametime() + 0.000001)
}

public Forward_Spr_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3], owner
	static Float:fFrame
	
	owner = pev(ent, pev_owner)
	pev(owner, pev_origin, Origin)
	pev(ent, pev_frame, fFrame)
	
	fFrame += 1.0
	if(fFrame > 20.0) fFrame = 0.0
	
	Origin[0] += pev(ent, pev_fuser2)
	Origin[1] += pev(ent, pev_fuser3)
	Origin[2] += pev(ent, pev_fuser4)
	
	set_pev(ent, pev_frame, fFrame)
	engfunc(EngFunc_SetOrigin, ent, Origin)
	set_pev(ent, pev_nextthink, get_gametime() + 0.001)
	
	static Float:fTimeRemove
	pev(ent, pev_fuser1, fTimeRemove)
	if(get_gametime() >= pev(ent, pev_fuser1) || g_skill1[owner] != SKILL_USE)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}
}

public metatronic_reset_value(id)
{
	class_metatronic[id] = false
	metatronic_reset_var_skill(id)
}

public metatronic_reset_var_skill(id)
{
	g_skill1[id] = 0
	g_skill2[id] = 0
	g_skill1_regen_count[id] = 0
	g_skill2_fake_health[id] = 0
	g_speed_hud[id] = 1.0
	
	if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP]))
	{
		remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP])
		g_head_spr_ent[id][ENT_HEAD_SPR_HP] = 0
	}
	if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF]))
	{
		remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF])
		g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF] = 0
	}
}

public metatronic_remove_headspr(id, num)
{
	if(num == ENT_HEAD_SPR_HP)
	{
		if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP]))
		{
			remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP])
			g_head_spr_ent[id][ENT_HEAD_SPR_HP] = 0
		}
	}
	else if(num == ENT_HEAD_SPR_HP_BUFF)
	{
		if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF]))
		{
			remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF])
			g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF] = 0
		}
	}
	else if(num == 2)
	{
		if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP]))
		{
			remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP])
			g_head_spr_ent[id][ENT_HEAD_SPR_HP] = 0
		}
		if(pev_valid(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF]))
		{
			remove_entity(g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF])
			g_head_spr_ent[id][ENT_HEAD_SPR_HP_BUFF] = 0
		}
	}
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock precache_viewmodel_sound(const model[]) // I Get This From BTE
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], NumSeq, SeqID, Event, NumEvents, EventID
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqID, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqID + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventID, BLOCK_INT)
			fseek(file, EventID + 176 * i, SEEK_SET)
			
			// The Output Is All Sound To Precache In ViewModels (GREAT :V)
			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventID + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}