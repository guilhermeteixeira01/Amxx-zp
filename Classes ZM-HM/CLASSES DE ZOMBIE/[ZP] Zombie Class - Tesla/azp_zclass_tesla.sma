#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < xs >
#include < fun >
#include < cstrike > 
#include < engine >
#include < zombieplague >

#define is_valid_player(%1) (1 <= %1 <= maxplayers)

new const sound_hit[ ] = "player/bhit_helmet-1.wav"

const OFFSET_LINUX = 5
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod


enum (+= 100)
{
	TASK_COOLDOWN,
	TASK_ABILITY
}

new bool:g_has_pain_shock_free[33]

#define ICON_HIDE 0
#define ICON_SHOW 1
#define SUPPORT_BOT_TO_USE
//#define FIRST_ZOMBIE_CANT_USE
#define HAVE_DYNAMIC_LIGHT_EFFECT
//#define WHEN_HITED_DROP_WEAPON
#define WHEN_HITED_CANT_SHOOT
#define WHEN_HITED_CANT_MOVE
#define WHEN_DAMAGE_OVER_HEALTH_INFECT
#define WHEN_DAMAGE_MAKE_FAIL
#define HITED_ZOMBIE_KNOCKBACK

#if defined WHEN_DAMAGE_MAKE_FAIL
#define SUPPORT_CZBOT
#define Damage_Check_Time_Range 2.0
#define Get_Amount_Of_Damage 300.0
#endif

#define Hit_Attack2_Key_Time 0.1
#define Make_EnergyBall_Time 0.1
#define EnergyBall_Deduct_Speed 0
#define Short_Dist_Cant_Shoot 10
const Float:Damage_Survivor_Multiplier = 1.0

#define Task_ID_1 param[0]+5333

#if defined WHEN_HITED_DROP_WEAPON

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|
	(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
#endif

const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48

const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

new const zclass_name[] = { "Tesla" }
new const zclass_info[] = { "Energy ball" }
new const zclass_model[] = { "BZ_tesla" }
new const zclass_clawmodel[] = {"v_knife_tesla.mdl" }
const zclass_health = 5000
const zclass_speed = 240
const Float:zclass_gravity = 0.80
const Float:zclass_knockback = 0.80

new gCvarDamageMultiplier, gCvarShouldPlaySound


new const EnergyBall_P_Model[] = { "models/BZ_models/p_snowball.mdl" }
new const EnergyBall_W_Model[] = { "models/BZ_models/w_snowball.mdl" }
new const EnergyBall_Make_Sound[] = { "weapons/electro4.wav" }
new const EnergyBall_Shoot_Sound[] = { "weapons/gauss2.wav" }
new const EnergyBall_Touch_Sound[][] = { "weapons/ric_conc-1.wav", "weapons/ric_conc-2.wav" } 
new const EnergyBall_Hit_Pain_Sound[] = { "player/pl_pain6.wav" } 

new g_zclass_energyball

new i_cooldown_time[33]

new g_shoot_times, g_speed, g_damage, g_cooldown, g_explosion_range, g_effect_time, g_surv_effect_time
new maxplayers, bool:round_end, Float:current_time
new g_msgScreenShake, g_msgScreenFade, g_msgDamage
new g_msgDeathMsg, g_msgScoreAttrib, g_msgScoreInfo
new g_trailSpr, g_shokewaveSpr
new gMsgID

new energyball_num[33]
new check_step[33], bool:step_started[33], Float:step_check_time[33]
new bool:make_energyball[33], bool:have_energyball[33]
new bool:cooldown_started[33], Float:cooldown_over_time[33]
new bool:be_hited[33], Float:be_hit_check_time[33]
new bool:effect_started[33], Float:effect_over_time[33]
new Float:next_play_sound_time[33]
new bool:touched_energyball[33], Float:touch_energyball_time[33]
new g_ent_weaponmodel[33]
new Float:g_abilonecooldown = 15.0 // cooldown time
new g_witch_dmg_multi,g_MsgSync

#if defined WHEN_DAMAGE_MAKE_FAIL
new Float:get_attack_damage[33], Float:damage_check_time[33]
#endif

#if defined WHEN_DAMAGE_OVER_HEALTH_INFECT
new bool:is_infect_round
#endif

#if defined SUPPORT_BOT_TO_USE
new aim_target[33], Float:aim_check_over_time[33]
#endif

#if defined SUPPORT_CZBOT

new cvar_botquota
new bool:BotHasDebug = false
#endif

public plugin_init()
{
	g_shoot_times = register_cvar("zp_zclass_eb_shoottimes", "6")
	g_speed = register_cvar("zp_zclass_eb_speed", "1000")
	g_damage = register_cvar("zp_zclass_eb_damage", "100")
	g_cooldown = register_cvar("zp_zclass_eb_cooldown", "15.0")
	g_explosion_range = register_cvar("zp_zclass_eb_exploderange", "5.0")
	g_effect_time = register_cvar("zp_zclass_eb_effecttime", "5.0")
	g_surv_effect_time = register_cvar("zp_zclass_eb_surveffecttime", "0.1") 
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	
	register_cvar("zp_give_hp_tesla", "100")
	register_cvar("zp_give_hp_tesla_freq", "3.0")
	
	g_witch_dmg_multi = register_cvar( "zp_witch_dmg_multi", "2.0" )
	
	register_dictionary( "zp_zclass_energy_ball.txt" )
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_StartFrame, "fw_StartFrame")
	RegisterHam( Ham_TakeDamage, "player", "fwww_TakeDamage" )
	RegisterHam( Ham_TakeDamage, "player", "fww_TakeDamage" )
	
	register_event("ResetHUD","NewRound","be")
	register_event("DeathMsg", "Death", "a")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_logevent("roundStart", 2, "1=Round_Start")
	RegisterHam(Ham_Spawn, "player", "player_spawn")

	gCvarDamageMultiplier = register_cvar( "zp_iron_dmg_multiplier", "0.60" )	// ( 1.0: Default Damage | 0.5: Half Damage ) Default: 0.75
	gCvarShouldPlaySound = register_cvar( "zp_iron_play_sound", "0" ) // ( 1: Play sound | 0: Don't play sound ) Default: 1
	
	#if defined WHEN_DAMAGE_MAKE_FAIL
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	#endif
	
	maxplayers = get_maxplayers()
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgDamage = get_user_msgid("Damage")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_MsgSync = CreateHudSyncObj()
	
	gMsgID = get_user_msgid("StatusIcon")
	
	#if defined SUPPORT_CZBOT
	// CZBot support
	cvar_botquota = get_cvar_pointer("bot_quota")
	#endif
  }

public plugin_precache()
{
	precache_model(EnergyBall_P_Model)
	precache_model(EnergyBall_W_Model)
	precache_sound(EnergyBall_Make_Sound)
	precache_sound(EnergyBall_Shoot_Sound)

	for (new i = 0; i < sizeof EnergyBall_Touch_Sound; i++)
		precache_sound(EnergyBall_Touch_Sound[i])
	
	precache_sound(EnergyBall_Hit_Pain_Sound)
	
	g_trailSpr = precache_model("sprites/zbeam4.spr")
	g_shokewaveSpr = precache_model( "sprites/shockwave.spr")

	precache_sound( sound_hit )
	
	g_zclass_energyball = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}
public fwww_TakeDamage( victim, inflictor, attacker, Float:damage )
{
	if( !is_valid_player( attacker ) || victim == attacker || !zp_get_user_zombie( victim ) || zp_get_user_zombie_class( victim ) != g_zclass_energyball || zp_get_user_nemesis( victim ) )
		return
		
	SetHamParamFloat( 4, damage * get_pcvar_float( gCvarDamageMultiplier ) )
	
	if( get_pcvar_num( gCvarShouldPlaySound ) == 1 )
	{
		emit_sound( victim, CHAN_STREAM, sound_hit, 1.0, ATTN_NORM, 0, PITCH_HIGH )
	}
}
public zp_user_infected_post(id, infector)
{
	
	
	if (infector&&zp_get_user_zombie_class(infector) == g_zclass_energyball)
	{
		if ((energyball_num[infector]) <= get_pcvar_num(g_shoot_times))
		{
			ammo_hud(infector, 0)
			energyball_num[infector] += 1
			ammo_hud(infector, 1)
		}
	}
	if (zp_get_user_zombie_class(id) == g_zclass_energyball && !zp_get_user_nemesis(id))
	{
		ammo_hud(id,1)
		ChatColor(id, "!g[ZP] !yСпособность !g[Энергетический шар] !y| Ожидание !g15 !yсек | Кнопка!g 'ATTACK2'")
		i_cooldown_time[id] = floatround(g_abilonecooldown)
		reset_cvars(id)
		g_has_pain_shock_free[id] = true
	}

	set_task(1.0, "Ability", id+TASK_ABILITY, _, _, "b")
	set_pev(id, pev_body, random_num(0, 1))
}
public fw_TakeDamage_Post(id)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id))
		return HAM_IGNORED
		
	if (zp_get_user_zombie_class(id) != g_zclass_energyball)
		return HAM_IGNORED
		
	g_has_pain_shock_free[id] = true
		
	set_pdata_float(id, OFFSET_PAINSHOCK, 1.0, OFFSET_LINUX)
	
	return HAM_IGNORED
}
public roundStart()
{
	for (new i = 1; i <= maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_abilonecooldown)
		remove_task(i)
	    remove_task(i+TASK_ABILITY)
	    remove_task(i+TASK_COOLDOWN)
	}
}

/*public AddHP44(id)
{
	if (!is_user_connected(id))
  		return PLUGIN_CONTINUE;

	if (zp_get_user_zombie(id) && !zp_is_survivor_round(  ) ) {
		if (zp_get_user_zombie_class(id) == g_zclass_energyball) {
			new cur_hp2 = get_user_health(id)
			new am_hp2 = get_cvar_num("zp_give_hp_tesla")
			new max_hp2 = zp_get_zombie_maxhealth(id)
	
			if (cur_hp2 < max_hp2) {
			set_user_health(id, cur_hp2 + am_hp2)
			} else {
				return PLUGIN_HANDLED
			}
		} else {
			remove_task(id)
		}
	} else {
		remove_task(id)
	}

	return PLUGIN_CONTINUE
}*/
public fww_TakeDamage( victim, inflictor, attacker, Float:damage, damagebits )
{
	if( is_user_connected( attacker )&&victim!=attacker && zp_get_user_zombie( attacker ) && zp_get_user_zombie_class( attacker ) == g_zclass_energyball && !zp_get_user_nemesis( attacker ) )
	{
		SetHamParamFloat( 4, damage * get_pcvar_float( g_witch_dmg_multi ) )
	}
}
public player_spawn(id)
{
	ammo_hud(id,0)
	reset_cvars(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_energyball)
		return FMRES_IGNORED;
	
	if (zp_get_user_nemesis(id))
		return FMRES_IGNORED;
		
	if (zp_is_survivor_round())
		return FMRES_IGNORED;
	
	#if defined FIRST_ZOMBIE_CANT_USE
	if (zp_get_user_first_zombie(id))
		return FMRES_IGNORED;
	#endif
	
	static weap_id
	weap_id = get_user_weapon(id)
	
	if (weap_id != CSW_KNIFE)
	{
		if (make_energyball[id] || have_energyball[id])
		{
			check_step[id] = 1
			step_started[id] = false
			make_energyball[id] = false
			have_energyball[id] = false
			set_user_weapon_attack_time(id, 0.0)
		}
		
		return FMRES_IGNORED;
	}
	
	if (get_pcvar_num(g_shoot_times) != 0 && energyball_num[id] <= 0)
		return FMRES_IGNORED;
	
	if (cooldown_started[id])
		return FMRES_IGNORED;
	
	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		static target, body
		get_user_aiming(id, target, body)
		if (check_target_valid(target))
		{
			aim_target[id] = target
			
			aim_check_over_time[id] = current_time + 20.0
		}
		else
		{
			aim_target[id] = 0
			
			if (current_time >= aim_check_over_time[id])
			{
				check_step[id] = 1
				step_started[id] = false
				
				if (make_energyball[id] || have_energyball[id])
				{
					make_energyball[id] = false
					have_energyball[id] = false
					set_user_weapon_attack_time(id, 0.0)
				}
			}
		}
		
		switch (check_step[id])
		{
			case 1:
			{
				if (!step_started[id])
				{

					if (aim_target[id])
					{
						step_started[id] = true
						step_check_time[id] = current_time + Hit_Attack2_Key_Time
					}
				}
				else
				{
					if (current_time >= step_check_time[id])
					{
						check_step[id] = 2
						step_started[id] = false
						make_energyball[id] = true
						set_user_weapon_attack_time(id, 0.5)
						SendWeaponAnim(id, 0)
					}
				}
			}
			case 2:
			{
				if (!step_started[id])
				{
					step_started[id] = true
					step_check_time[id] = current_time + Make_EnergyBall_Time
				}
				else
				{
					if (current_time >= step_check_time[id])
					{
						check_step[id] = 3
						step_started[id] = false
						make_energyball[id] = false
						have_energyball[id] = true
						set_user_weapon_attack_time(id, 0.5)
						SendWeaponAnim(id, 0)
					}
				}
			}
			case 3:
			{
				if (aim_target[id])
				{
					if (have_energyball[id])
					{
						check_step[id] = 1
						have_energyball[id] = false
						shoot_energyball(id)
						set_user_weapon_attack_time(id, 0.0)
					}
				}
			}
		}
		
		return FMRES_IGNORED;
	}
	#endif
	
	switch (check_step[id])
	{
		case 1:
		{
			if (button & IN_ATTACK)
			{
				check_step[id] = 1
				step_started[id] = false
			}
			else if (button & IN_ATTACK2)
			{
				if (!step_started[id])
				{
					if (!(oldbutton & IN_ATTACK2))
					{
						step_started[id] = true
						step_check_time[id] = current_time + Hit_Attack2_Key_Time
					}
				}
				else
				{
					if (current_time >= step_check_time[id])
					{
						if (get_pcvar_num(g_shoot_times) != 0)
							//client_print(id, print_chat, "[SERVER] x3 1%d ", energyball_num[id])
						
						check_step[id] = 2
						step_started[id] = false
						make_energyball[id] = true
						set_user_weapon_attack_time(id, 1.0)
						SendWeaponAnim(id, 0)
					}
				}
			}
			else
			{
				step_started[id] = false
			}
		}
		case 2:
		{
			if (button & IN_ATTACK)
			{
				check_step[id] = 1
				step_started[id] = false
				
				if (make_energyball[id])
				{
					client_print(id, print_center, "")
					make_energyball[id] = false
					set_user_weapon_attack_time(id, 0.0)
				}
			}
			else if (button & IN_ATTACK2)
			{
				client_print(id, print_center, "")
				
				if (!step_started[id])
				{
					step_started[id] = true
					step_check_time[id] = current_time + Make_EnergyBall_Time
				}
				else
				{
					if (current_time >= step_check_time[id])
					{
						check_step[id] = 3
						step_started[id] = false
						make_energyball[id] = false
						have_energyball[id] = true
						set_user_weapon_attack_time(id, 1.0)
						SendWeaponAnim(id, 0)
					}
				}
			}
			else
			{
				check_step[id] = 1
				step_started[id] = false
				
				if (make_energyball[id])
				{
					client_print(id, print_center, "")
					make_energyball[id] = false
					set_user_weapon_attack_time(id, 0.0)
				}
			}
		}
		case 3:
		{
			if (button & IN_ATTACK)
			{
				check_step[id] = 1
				
				if (have_energyball[id])
				{
					client_print(id, print_center, "")
					have_energyball[id] = false
					set_user_weapon_attack_time(id, 0.0)
				}
			}
			else if (button & IN_ATTACK2)
			{
				static dist
				dist = get_forward_view_dist(id)
				if (dist < Short_Dist_Cant_Shoot)
					client_print(id, print_chat, "")
				else
					client_print(id, print_chat, "")
			}
			else
			{
				if (have_energyball[id])
				{
					client_print(id, print_center, "")
					check_step[id] = 1
					have_energyball[id] = false
					shoot_energyball(id)
					set_user_weapon_attack_time(id, 0.0)
				}
			}
		}
	}
	
	return FMRES_HANDLED;
}

#if defined SUPPORT_BOT_TO_USE
check_target_valid(target)
{
	if (!(1 <= target <= maxplayers) || !is_user_alive(target) || zp_get_user_zombie(target))
		return 0;
	
	return 1;
}
#endif

set_user_weapon_attack_time(id, Float:next_attack_time)
{
	static weap_id
	weap_id = get_user_weapon(id)
	
	static weap_name[32]
	get_weaponname(weap_id, weap_name, charsmax(weap_name))
	
	static weap_ent
	weap_ent = fm_find_ent_by_owner(-1, weap_name, id)
	
	set_weapon_next_pri_attack(weap_ent, next_attack_time)
	set_weapon_next_sec_attack(weap_ent, next_attack_time)
	
	if (weap_id == CSW_XM1014 || weap_id == CSW_M3)
		set_weapon_idle_time(weap_ent, next_attack_time)
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (zp_get_user_zombie(id))
	{
		if (zp_get_user_zombie_class(id) != g_zclass_energyball)
			return FMRES_IGNORED;
		
		if (zp_get_user_nemesis(id))
			return FMRES_IGNORED;
		
		#if defined FIRST_ZOMBIE_CANT_USE
		if (zp_get_user_first_zombie(id))
			return FMRES_IGNORED;
		#endif
		
		if (get_pcvar_num(g_shoot_times) != 0 && energyball_num[id] <= 0)
			return FMRES_IGNORED;
		
		if (make_energyball[id] || have_energyball[id])
		{
			freeze_user_attack(id)
		}
		
		if (cooldown_started[id])
		{
			if (current_time >= cooldown_over_time[id])
			{
				cooldown_started[id] = false
				ChatColor(id, "!g[ZP] !yЭнергетический Шар готов!")
			}
		}
	}
	else
	{
		if (be_hited[id])
		{
			if (current_time >= be_hit_check_time[id])
			{
				be_hited[id] = false
				effect_started[id] = true
				
				if (zp_get_user_survivor(id))
					effect_over_time[id] = current_time + get_pcvar_float(g_surv_effect_time)
				else
					effect_over_time[id] = current_time + get_pcvar_float(g_effect_time)
			}
		}
		
		if (effect_started[id])
		{
			#if defined WHEN_HITED_CANT_SHOOT
			freeze_user_attack(id)
			#endif
			
			#if defined WHEN_HITED_CANT_MOVE
			if (is_user_on_ground(id))
			{
				set_pev(id, pev_velocity, Float:{0.0,0.0,0.0}) // stop motion
				set_pev(id, pev_maxspeed, 1.0) // prevent from moving
				set_pev(id, pev_gravity, 999999.9) // set really high

			}
			#endif
			fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 255, kRenderNormal, 16)
			
			if (current_time >= effect_over_time[id])
			{
				#if defined WHEN_HITED_CANT_MOVE
				set_pev(id, pev_gravity, get_cvar_float("zp_human_gravity"))

				#endif
				fm_set_rendering(id, 0, 0, 0, 0, kRenderNormal, 25) 
				
				effect_started[id] = false
			}
		}
		
		if (touched_energyball[id])
		{
			if (current_time - touch_energyball_time[id] >= 0.2)
			{
				touched_energyball[id] = false
			}
		}
	}
	
	return FMRES_IGNORED;
}

freeze_user_attack(id)
{
	static weap_id
	weap_id = get_user_weapon(id)
	
	static weap_name[32]
	get_weaponname(weap_id, weap_name, charsmax(weap_name))
	
	static weap_ent
	weap_ent = fm_find_ent_by_owner(-1, weap_name, id)
	
	if (get_weapon_next_pri_attack(weap_ent) <= 0.1)
		set_weapon_next_pri_attack(weap_ent, 1.0)
	
	if (get_weapon_next_sec_attack(weap_ent) <= 0.1)
		set_weapon_next_sec_attack(weap_ent, 1.0)
	
	if (weap_id == CSW_XM1014 || weap_id == CSW_M3)
	{
		if (get_weapon_idle_time(weap_ent) <= 0.1)
			set_weapon_idle_time(weap_ent, 1.0)
	}
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr))
		return FMRES_IGNORED;
	
	static classname[32]
	pev(ptr, pev_classname, classname, 31)
	
	if (!equal(classname, "EnergyBall_Ent"))
		return FMRES_IGNORED;
	
	static owner
	owner = pev(ptr, pev_iuser1)
	
	static Float:ent_origin[3]
	pev(ptr, pev_origin, ent_origin)
	
	static sound_index 
	sound_index = random_num(0, sizeof EnergyBall_Touch_Sound -1)
	engfunc(EngFunc_EmitSound, ptr, CHAN_VOICE, EnergyBall_Touch_Sound[sound_index], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static ent_speed
	ent_speed = pev(ptr, pev_iuser4) - EnergyBall_Deduct_Speed
	set_pev(ptr, pev_iuser4, ent_speed)
	
	pev(ptd, pev_classname, classname, 31)
	
	if (equal(classname, "EnergyBall_Ent"))
	{
		set_pev(ptr, pev_iuser2, 1)
	}
	else if ((1 <= ptd <= 32) && is_user_alive(ptd) && !touched_energyball[ptd])
	{
		#if !(defined HITED_ZOMBIE_KNOCKBACK)
		if (zp_get_user_zombie(ptd))
			return FMRES_IGNORED;
		#endif
		
		if (round_end)
			return FMRES_IGNORED;
		
		touched_energyball[ptd] = true
		touch_energyball_time[ptd] = current_time
		
		static Float:origin[3], Float:velocity1[3], Float:velocity2[3]
		pev(ptd, pev_origin, origin)
		pev(ptd, pev_velocity, velocity1)
		
		particle_burst_effect(origin)
		
		velocity2[0] = origin[0] - ent_origin[0]
		velocity2[1] = origin[1] - ent_origin[1]
		velocity2[2] = origin[2] - ent_origin[2]
		
		static Float:speed
		speed = vector_length(velocity2)
		
		speed = floatmax(float(ent_speed) - 800.0, 0.0) / (speed > 0.0 ? speed : 1.0)
		
		xs_vec_mul_scalar(velocity2, speed, velocity2)
		xs_vec_sub(velocity2, velocity1, velocity2)
		
		speed = vector_length(velocity2)
		if (speed > 800.0)
			xs_vec_mul_scalar(velocity2, (800.0 / speed), velocity2) 
		
		floatclamp(velocity2[2], -200.0, 800.0)
		
		set_pev(ptd, pev_velocity, velocity2)
		
		if (!zp_get_user_zombie(ptd))
		{
			if (fm_get_user_godmode(ptd) || get_user_godmode(ptd))
				return FMRES_IGNORED;
			
			PlaySound(ptd, EnergyBall_Hit_Pain_Sound)
			screen_shake(ptd, 6, 1, 5)
			screen_fade(ptd, 0.2, 220, 0, 0, 150)
			
			#if defined WHEN_HITED_DROP_WEAPON
			if (!zp_get_user_survivor(ptd))
			{
				static EnergyBall_fly_time
				EnergyBall_fly_time = pev(ptr, pev_iuser3)
				
				if (EnergyBall_fly_time <= 10)
					drop_current_weapon(ptd)
			}
			#endif
			
			static damage
			damage = get_pcvar_num(g_damage)
			
			if (zp_get_user_survivor(ptd))
				damage = floatround(float(damage) * Damage_Survivor_Multiplier)
			
			damage_human_user(owner, ptd, damage, (4.0 /5.0), DMG_BLAST, "EnergyBall")
		}
	}
	
	return FMRES_IGNORED;
}

damage_human_user(attacker, victim, damage, Float:damage_armor_rate, damage_type, weapon[])
{
	new health = get_user_health(victim)
	new armor = get_user_armor(victim)
	
	new damage_armor = floatround(float(damage) * damage_armor_rate)
	
	if (damage_armor > 0 && armor > 0)
	{
		if (armor > damage_armor)
		{
			damage -= damage_armor
			fm_set_user_armor(victim, armor - damage_armor)
		}
		else
		{
			damage -= armor
			fm_set_user_armor(victim, 0)
		}
	}
	
	if (damage > 0)
	{
		if (health > damage)
		{
			set_user_takedamage(victim, damage, damage_type)
			effect_started[victim] = false
			be_hited[victim] = true
			be_hit_check_time[victim] = current_time + 1.0 
		}
		else
		{
			new frags = get_user_frags(attacker)
			
			#if defined WHEN_DAMAGE_OVER_HEALTH_INFECT
			if (is_infect_round && !(zp_get_user_last_human(victim) || zp_get_user_survivor(victim)))
			{
				if (zp_infect_user(victim, 0))
				{
					new weapon_string[64]
					format(weapon_string, charsmax(weapon_string), "%s (Infect)", weapon)
					SendDeathMsg(attacker, victim, 1, weapon_string)
					cs_set_user_deaths(victim, get_user_deaths(victim) + 1)
				}
				else
				{
					set_msg_block(g_msgDeathMsg, BLOCK_SET)
					ExecuteHamB(Ham_Killed, victim, attacker, 0)
					set_msg_block(g_msgDeathMsg, BLOCK_NOT)
					SendDeathMsg(attacker, victim, 0, weapon)
				}
			}
			else
			{
			#endif
			
			set_msg_block(g_msgDeathMsg, BLOCK_SET)
			ExecuteHamB(Ham_Killed, victim, attacker, 0)
			set_msg_block(g_msgDeathMsg, BLOCK_NOT)
			SendDeathMsg(attacker, victim, 0, weapon)
			
			#if defined WHEN_DAMAGE_OVER_HEALTH_INFECT
			}
			#endif
			
			fm_set_user_frags(attacker, frags + 1)
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 1)
			
			FixDeadAttrib(victim, (is_user_alive(victim) ? 0 : 1))
			Update_ScoreInfo(victim, get_user_frags(victim), get_user_deaths(victim))
			FixDeadAttrib(attacker, (is_user_alive(attacker) ? 0 : 1))
			Update_ScoreInfo(attacker, get_user_frags(attacker), get_user_deaths(attacker))
			
/*
			new k_name[32], v_name[32], k_authid[32], v_authid[32], k_team[10], v_team[10]
			get_user_name(attacker, k_name, charsmax(k_name))
			get_user_team(attacker, k_team, charsmax(k_team))
			get_user_authid(attacker, k_authid, charsmax(k_authid))
			get_user_name(victim, v_name, charsmax(v_name))
			get_user_team(victim, v_team, charsmax(v_team))
			get_user_authid(victim, v_authid, charsmax(v_authid))
			log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
			k_name, get_user_userid(attacker), k_authid, k_team, 
	 		v_name, get_user_userid(victim), v_authid, v_team, weapon)
*/
		}
	}
}

public fw_StartFrame()
{
	current_time = get_gametime()
	
	static Float:next_check_time, id
	if (current_time < next_check_time)
		return FMRES_IGNORED;
	else
		next_check_time = current_time + 0.1
	
	#if defined HAVE_DYNAMIC_LIGHT_EFFECT
	static Float:origin[3]
	#endif
	
	for (id = 1; id <= maxplayers; id++)
	{
		if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_energyball)
			continue;
		
		if (make_energyball[id])
		{
			#if defined HAVE_DYNAMIC_LIGHT_EFFECT
			pev(id, pev_origin, origin)
			
			create_dynamic_light(origin, 15, 127, 255, 212, 2)
			#endif
			
			if (current_time > next_play_sound_time[id])
			{
				engfunc(EngFunc_EmitSound, id, CHAN_VOICE, EnergyBall_Make_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				next_play_sound_time[id] = current_time + 1.0
			}
		}
		else if (have_energyball[id])
		{
			#if defined HAVE_DYNAMIC_LIGHT_EFFECT
			pev(id, pev_origin, origin)
			
			create_dynamic_light(origin, 15, 244, 102, 255, 2)
			#endif
			
			fm_set_weaponmodel_ent(id, EnergyBall_P_Model)
			
			if (pev_valid(g_ent_weaponmodel[id]))
			{
				fm_set_rendering(g_ent_weaponmodel[id], kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 255)
			}
		}
		
		if (!have_energyball[id])
		{
			fm_remove_weaponmodel_ent(id)
		}
	}
	
	return FMRES_IGNORED;
}

#if defined WHEN_DAMAGE_MAKE_FAIL
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker))
		return HAM_IGNORED;
	
	if (zp_get_user_zombie_class(victim) != g_zclass_energyball || zp_get_user_nemesis(victim))
		return HAM_IGNORED;
	
	
	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	if (!make_energyball[victim] && !have_energyball[victim])
	{
		get_attack_damage[victim] = 0.0
		return HAM_IGNORED;
	}
	
	if (current_time > damage_check_time[victim])
	{
		get_attack_damage[victim] = 0.0
		damage_check_time[victim] = current_time + Damage_Check_Time_Range
	}
	
	get_attack_damage[victim] += damage
	
	if (get_attack_damage[victim] >= Get_Amount_Of_Damage)
	{
		get_attack_damage[victim] = 0.0
		damage_check_time[victim] = current_time + Damage_Check_Time_Range
		
		check_step[victim] = 1
		step_started[victim] = false
		make_energyball[victim] = false
		have_energyball[victim] = false
		//set_user_weapon_attack_time(id, 0.0)
	}
	
	return HAM_IGNORED;
}
#endif

public shoot_energyball(id)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_energyball)
		return;
	
	new dist = get_forward_view_dist(id)
	if (dist < Short_Dist_Cant_Shoot)	
		return;
	
	SendWeaponAnim(id, 7)
	
	fm_remove_weaponmodel_ent(id)
	
	new Float:origin[3], Float:vector[3]
	pev(id, pev_origin, origin)
	velocity_by_aim(id, 45, vector)
	xs_vec_add(origin, vector, origin)
	
	new Float:angles[3]
	pev(id, pev_angles, angles)
	
	new ent = create_entity_object2("EnergyBall_Ent", SOLID_BBOX, MOVETYPE_BOUNCEMISSILE, 1, EnergyBall_W_Model, Float:{ 20.0, 20.0, 20.0 }, angles, origin)
	if (ent == -1)	return;
	
	new Float:speed = vector_length(vector)
	speed = get_pcvar_float(g_speed) / (speed > 0.0 ? speed : 1.0)
	xs_vec_mul_scalar(vector, speed, vector)
	speed = vector_length(vector)
	set_pev(ent, pev_iuser4, floatround(speed))
	set_pev(ent, pev_iuser3, 0)
	set_pev(ent, pev_iuser2, 0) 
	set_pev(ent, pev_iuser1, id) 
	
	set_pev(ent, pev_velocity, vector)
	fm_set_rendering(ent, kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 255)
	engfunc(EngFunc_EmitSound, id, CHAN_VOICE, EnergyBall_Shoot_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	create_beam_follow(ent, 224, 102, 255, 200)
	
	new param[4]
	param[0] = ent
	param[1] = 100
	param[2] = 3
	param[3] = 0
	set_task(1.0, "energyball_fly", Task_ID_1, param, 4)
	
	if (get_pcvar_num(g_shoot_times) != 0)
	{
		ammo_hud(id,0)
		energyball_num[id]--
		ammo_hud(id,1)
		//~ new icon[9], temp
		//~ temp = get_msg_arg_string(2, icon, 8)
		//~ client_print(id, print_chat, "%d", temp)
		//~ if (szIcon == energyball_num[id] + 1) {
		//~ new tmp[9]
		//~ formatex(tmp, 8, "%s%d", icon, energyball_num[id])
		//~ client_print(id, print_chat, "%s", tmp)
		//~ set_msg_arg_string(2, tmp)
		//~ }
		//~ msg_energyball_num(id, 1, energyball_num[id])
		
		if (energyball_num[id] > 0)
			ChatColor(id,  "", energyball_num[id])
		else
			ChatColor(id, "!g[ZP] !yВы !gиспользовали!y всю Энергию.")
	}
	
	cooldown_started[id] = true
	cooldown_over_time[id] = current_time + get_pcvar_float(g_cooldown)
	i_cooldown_time[id] = 15
	set_task(1.0, "RemoveCooldown", id+TASK_COOLDOWN, _, _, "a",i_cooldown_time[id])	
}

public Ability(taskid)
{
	new id = taskid - TASK_ABILITY
	
	if(is_user_alive(id))
	{
		if (i_cooldown_time[id] == 0)
		{
           set_hudmessage(200, 100, 0, -1.0, 0.12, 0, 1.0, 1.1, 0.0, 0.0, -1)
		   ShowSyncHudMsg(id, g_MsgSync, "Энергетический шар - [ATTACK2]^nСпособность готова!")
		}
	}
	else remove_task(id+TASK_ABILITY)
}

public RemoveCooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	
	if(is_user_alive(id))
	{
		i_cooldown_time[id]--
		if (i_cooldown_time[id] == 0)
		{
		    set_task(2.5, "Ability", id+TASK_ABILITY)
			remove_task(id+TASK_COOLDOWN)
		}
		set_hudmessage(200, 100, 0, -1.0, 0.12, 0, 1.0, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_MsgSync, "Энергетический шар - [ATTACK2]^nПерезарядка: %d",i_cooldown_time[id])
	}
	else remove_task(id+TASK_COOLDOWN)
}

public energyball_fly(param[4])
{
	new ent = param[0]
	
	if (!pev_valid(ent))
		return;
	
	if (round_end)
	{
		if (pev_valid(ent))
		{
			//kill_beam(ent)
			engfunc(EngFunc_RemoveEntity, ent)
		}
		
		return;
	}
	
	kill_beam(ent)
	create_beam_follow(ent, 224, 102, 255, 200)
	
	new Float:velocity[3]
	pev(ent, pev_velocity, velocity)
	new Float:speed = vector_length(velocity)
	
	new Float:origin[3]
	pev(ent, pev_origin, origin)
	
	new EnergyBall_fly_time = pev(ent, pev_iuser3)
	set_pev(ent, pev_iuser3, EnergyBall_fly_time + 1)
	
	new touch_EnergyBall = pev(ent, pev_iuser2)
	
	if (is_ent_stuck(ent))
		param[3]++
	else
		param[3] = 0
	
	if (param[1] <= 0 || touch_EnergyBall || param[3] >= 5 || speed <= 20.0)
	{
		set_pev(ent, pev_velocity, { 0.0, 0.0, 0.0 })
		create_explo2(origin)
		create_blast_effect(origin, 224, 102, 255, 200, get_pcvar_float(g_explosion_range))
		
		if (!round_end)
			search_in_range_target(origin)
		
		if (pev_valid(ent))
			engfunc(EngFunc_RemoveEntity, ent)
		
		return;
	}
	
	if (param[2] <= 0)
	{
		new set_speed = pev(ent, pev_iuser4)
		speed = float(set_speed) / (speed > 0.0 ? speed : 1.0)
		xs_vec_mul_scalar(velocity, speed, velocity)
		set_pev(ent, pev_velocity, velocity)
		param[2] = 3
	}
	
	param[2]--
	param[1]--
	
	set_task(0.1, "energyball_fly", Task_ID_1, param, 4)
}

public search_in_range_target(Float:origin[3])
{
	new i, Float:target_origin[3], Float:dist
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_alive(i) || zp_get_user_zombie(i))
			continue;
		
		if (fm_get_user_godmode(i) || get_user_godmode(i))
			continue;
		
		pev(i, pev_origin, target_origin)
		dist = get_distance_f(origin, target_origin)
		if (dist > get_pcvar_float(g_explosion_range))
			continue;
		
		screen_fade(i, 0.2, 224, 102, 255, 150)
		screen_fade(i, 0.2, 122, 55, 139, 150)
		
		be_hited[i] = true
		be_hit_check_time[i] = current_time
	}
}

public zp_user_humanized_post(id)
{
	fm_remove_weaponmodel_ent(id)
	remove_task(id)
	reset_cvars(id)
	ammo_hud(id, 0)
	remove_task(id+TASK_ABILITY)
	remove_task(id+TASK_COOLDOWN)
}

#if defined WHEN_DAMAGE_OVER_HEALTH_INFECT
public zp_round_started(gamemode, id)
{
	is_infect_round = (gamemode == MODE_INFECTION || gamemode == MODE_MULTI)
}
#endif

public logevent_round_end()
{
	round_end = true
}

public client_connect(id)
{
	reset_cvars(id)
	ammo_hud(id,0)
}

public client_disconnect(id)
{
	fm_remove_weaponmodel_ent(id)
	reset_cvars(id)
	ammo_hud(id,0)
}

public NewRound(id)
{
	fm_remove_weaponmodel_ent(id)
	reset_cvars(id)
}

public Death()
{
	new id = read_data(2)
	if (!(1 <= id <= maxplayers))
		return;
	
	fm_remove_weaponmodel_ent(id)
	reset_cvars(id)
}

public event_round_start()
{

	for(new i;i<=32;i++)
	{
	    remove_task(i+TASK_ABILITY)
	    remove_task(i+TASK_COOLDOWN)
	}

	round_end = false
	
	remove_energyball()
	
	#if defined WHEN_DAMAGE_OVER_HEALTH_INFECT
	is_infect_round = false
	#endif

	
}

public reset_cvars(id)
{
	energyball_num[id] = get_pcvar_num(g_shoot_times)
	check_step[id] = 1
	step_started[id] = false
	step_check_time[id] = 0.0
	make_energyball[id] = false
	have_energyball[id] = false
	cooldown_started[id] = false
	cooldown_over_time[id] = 0.0
	be_hited[id] = false
	be_hit_check_time[id] = 0.0
	effect_started[id] = false
	effect_over_time[id] = 0.0
	touched_energyball[id] = false
	touch_energyball_time[id] = 0.0
	g_ent_weaponmodel[id] = 0
}

public remove_energyball()
{
	new ent = fm_find_ent_by_class(-1, "EnergyBall_Ent")
	while(ent)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		ent = fm_find_ent_by_class(ent, "EnergyBall_Ent")
	}
}

stock create_entity_object2(const classname[], solid, movetype, sequence, const model[], Float:size[3], Float:angles[3], Float:origin[3])
{
	// Create entity
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!pev_valid(ent)) return -1;
	
	// Set entity status
	set_pev(ent, pev_classname, classname)
	set_pev(ent, pev_solid, solid)
	set_pev(ent, pev_movetype, movetype)
	set_pev(ent, pev_sequence, sequence)
	
	// Set entity size
	new Float:half_size[3], Float:mins[3], Float:maxs[3]
	half_size[0] = size[0] / 2.0
	half_size[1] = size[1] / 2.0
	half_size[2] = size[2] / 2.0
	mins[0] = 0.0 - half_size[0]
	mins[1] = 0.0 - half_size[1]
	mins[2] = 0.0 - half_size[2]
	maxs[0] = half_size[0]
	maxs[1] = half_size[1]
	maxs[2] = half_size[2]
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set entity angles
	set_pev(ent, pev_angles, angles)
	
	// Set entity model
	if (strlen(model) > 0)
		engfunc(EngFunc_SetModel, ent, model)
	
	// Set entity origin
	set_pev(ent, pev_origin, origin)
	
	return ent;
}

stock get_forward_view_dist(id)
{
	new iOrigin1[3], iOrigin2[3]
	get_user_origin(id, iOrigin1, 0)
	get_user_origin(id, iOrigin2, 3)
	new dist = get_distance(iOrigin1, iOrigin2)
	
	return dist;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_set_user_armor(index, armor)
{
	set_pev(index, pev_armorvalue, float(armor));
	
	return 1;
}

stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	
	return 1;
}

stock set_user_takedamage(index, damage, damage_type)
{
	new Float:origin[3], iOrigin[3]
	pev(index, pev_origin, origin)
	FVecIVec(origin, iOrigin)
	
	message_begin(MSG_ONE, g_msgDamage, _, index)
	write_byte(21) // damage save
	write_byte(20) // damage take
	write_long(damage_type) // damage type
	write_coord(iOrigin[0]) // position.x
	write_coord(iOrigin[1]) // position.y
	write_coord(iOrigin[2]) // position.z
	message_end()
	
	fm_set_user_health(index, max(get_user_health(index) - damage, 0))
}

stock fm_set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags));
	
	return 1;
}

stock is_user_on_ground(index)
{
	if (pev(index, pev_flags) & FL_ONGROUND)
		return true;
	
	return false;
}

stock is_ent_stuck(ent)
{
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, HULL_HEAD, ent, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

#if defined WHEN_HITED_DROP_WEAPON
stock drop_current_weapon(id)
{
	static weapon_id, clip, ammo
	weapon_id = get_user_weapon(id, clip, ammo)
	
	if (((1<<weapon_id) & PRIMARY_WEAPONS_BIT_SUM) || ((1<<weapon_id) & SECONDARY_WEAPONS_BIT_SUM))
	{
		static weapon_name[32]
		get_weaponname(weapon_id, weapon_name, sizeof weapon_name - 1)
		engclient_cmd(id, "drop", weapon_name)
	}
}
#endif

stock PlaySound(index, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(index, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(index, "spk ^"%s^"", sound)
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock SendDeathMsg(attacker, victim, headshot, const weapon[]) // Send Death Message
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) 
	write_byte(victim) 
	write_byte(headshot) 
	write_string(weapon) 
	message_end()
}

stock FixDeadAttrib(id, dead_flag = 0) // Fix Dead Attrib on scoreboard
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) 
	write_byte(dead_flag) 
	message_end()
}

stock Update_ScoreInfo(id, frags, deaths)
{
	// Update scoreboard with attacker's info
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id) 
	write_short(frags) 
	write_short(deaths) 
	write_short(0)
	write_short(get_user_team(id)) 
	message_end()
}

stock screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude)
	write_short((1<<12)*duration) 
	write_short((1<<12)*frequency) 
	message_end()
}

stock screen_fade(id, Float:time, red, green, blue, alpha)
{
	// Add a blue tint to their screen
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short((1<<12)*1) 
	write_short(floatround((1<<12)*time)) 
	write_short(0x0000)
	write_byte(red) 
	write_byte(green) 
	write_byte(blue) 
	write_byte(alpha) 
	message_end()
}

stock particle_burst_effect(const Float:originF[3])
{
	// Particle burst
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) 
	engfunc(EngFunc_WriteCoord, originF[1]) 
	engfunc(EngFunc_WriteCoord, originF[2])
	write_short(50)
	write_byte(70)
	write_byte(3)
	message_end()
}

#if defined HAVE_DYNAMIC_LIGHT_EFFECT
stock create_dynamic_light(const Float:originF[3], radius, red, green, blue, life)
{
	// Dynamic light, effect world, minor entity effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT) // TE id: 27
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1]) 
	engfunc(EngFunc_WriteCoord, originF[2]) 
	write_byte(radius) 
	write_byte(red) 
	write_byte(green)
	write_byte(blue)
	write_byte(life)
	write_byte(0)
	message_end()
}
#endif

stock create_beam_follow(entity, red, green, blue, brightness)
{
	//Entity add colored trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) 
	write_short(entity) 
	write_short(g_trailSpr) 
	write_byte(1) 
	write_byte(10) 
	write_byte(red) 
	write_byte(green)
	write_byte(blue)
	write_byte(brightness)
	message_end()
}

stock create_explo2(const Float:originF[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION2) 
	engfunc(EngFunc_WriteCoord, originF[0]) 
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2]) 
	write_byte(1) // starting color
	write_byte(10) // num colors
	message_end()
}

stock create_blast_effect(const Float:originF[3], red, green, blue, brightness, Float:radius)
{
	// Light ring effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) 
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1]) 
	engfunc(EngFunc_WriteCoord, originF[2]) 
	engfunc(EngFunc_WriteCoord, originF[0]) 
	engfunc(EngFunc_WriteCoord, originF[1]) 
	engfunc(EngFunc_WriteCoord, originF[2] + radius) 
	write_short(g_shokewaveSpr) 
	write_byte(0)
	write_byte(0) 
	write_byte(4) 
	write_byte(60) 
	write_byte(0) 
	write_byte(red) 
	write_byte(green) 
	write_byte(blue)
	write_byte(brightness) 
	write_byte(0)
	message_end()
}

stock kill_beam(entity)
{
	// Kill all beams attached to entity
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM) // TE id: 99
	write_short(entity)
	message_end()
}

stock fm_get_user_godmode(index)
{
	new Float:val;
	pev(index, pev_takedamage, val);
	
	return (val == DAMAGE_NO);
}

// Set Weapon Model on Entity
stock fm_set_weaponmodel_ent(id, const weapon_model[])
{
	// Set model on entity or make a new one if unexistant
	if (!pev_valid(g_ent_weaponmodel[id]))
	{
		g_ent_weaponmodel[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if (!pev_valid(g_ent_weaponmodel[id])) return;
		
		set_pev(g_ent_weaponmodel[id], pev_classname, "weapon_model")
		set_pev(g_ent_weaponmodel[id], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_ent_weaponmodel[id], pev_aiment, id)
		set_pev(g_ent_weaponmodel[id], pev_owner, id)
	}
	
	static model[100]
	
	if (equal(weapon_model, ""))
	{
		static weap_id, weap_name[32]
		weap_id = get_user_weapon(id)
		get_weaponname(weap_id, weap_name, sizeof weap_name - 1)
		formatex(model, sizeof model - 1, "models/p_%s.mdl", weap_name[7])
	}
	else
	{
		copy(model, sizeof model - 1, weapon_model)
	}
	
	engfunc(EngFunc_SetModel, g_ent_weaponmodel[id], model)
}

stock fm_remove_weaponmodel_ent(id)
{
	// Remove "weaponmodel" ent if present
	if (pev_valid(g_ent_weaponmodel[id]))
	{
		engfunc(EngFunc_RemoveEntity, g_ent_weaponmodel[id])
		g_ent_weaponmodel[id] = 0
	}
}

#if defined SUPPORT_CZBOT
public client_putinserver(id)
{
	if (!cvar_botquota || !is_user_bot(id) || BotHasDebug)
		return;
	
	new classname[32]
	pev(id, pev_classname, classname, 31)
	
	if (!equal(classname, "player"))
		set_task(0.1, "_Debug", id)
}
public _Debug(id)
{
	if (!get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	BotHasDebug = true
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
#endif

ammo_hud(id, sw)
{

	if(is_user_bot(id)||!is_user_alive(id)||!is_user_connected(id)) 
        	return
        if ( zp_is_survivor_round ( ) ) return ;
	new s_sprite[33]
	format(s_sprite,32,"number_%d",energyball_num[id])
	if(sw)
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( ICON_SHOW ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 255 ) // red
		write_byte( 186 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
	else
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( ICON_HIDE ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 255 ) // red
		write_byte( 186 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
}

stock set_player_rendering(id, renderfx, red, green, blue, rendermode, renderamt, alive) {
	if (is_user_connected(id) && ((is_user_alive(id) && alive) || !alive)) {
		new Float:rendercolor[3]
		set_pev(id, pev_renderfx, renderfx)
		rendercolor[0] = float(red)
		rendercolor[1] = float(green)
		rendercolor[2] = float(blue)
		set_pev(id, pev_rendercolor, rendercolor)
		set_pev(id, pev_rendermode, rendermode)
		set_pev(id, pev_renderamt, float(renderamt))
	}
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color
	replace_all(msg, 190, "!team2", "^0") // Team2 Color
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
	for (new i = 0; i < count; i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
}
}
