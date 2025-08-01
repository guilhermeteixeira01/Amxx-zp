/* 
*
* 		The Plugin is Made by N.O.V.A 
* 	
*		Credit:- +Arukari , Th3-822 , Perfect Scrash
*			 
*		Contacts:-
*
* 		Fb:- facebook.com/nova.gaming.cs
* 		Insta :-  instagram.com/_n_o_v_a_g_a_m_i_n_g
* 		Discord :- N.O.V.A#1790
* 		Youtube :- NOVA GAMING
*		
*		To Do:-
*			- Add Ability to Kill Hound
*			- Add Max Hounds System
*			- (Done) Fix the Player Animation ( i will try FW_ADDTOFULLPACK )
*
*		Change Logs:-
*				v 1.0 B :- Released The Beta Plugin
*				v 1.0 Stable - Fixed Player Animation
*
*/


/*----------------------------------*/
/*           INCLUDES               */
/*----------------------------------*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
//#include <amxmisc>
//#include <fakemeta_util>
//#include <fun>
//#include <cstrike>

/*----------------------------------*/
/*         ANTI-DECOMPILE           */
/*----------------------------------*/

#pragma compress 1
//#pragma semicolon 1

/*----------------------------------*/
/*            DEFINES               */
/*----------------------------------*/

#define PLUGIN "[NV] ZP CSO LIKE CLASS TYRANT"
#define VERSION "1.0 | 03-12-2020"
#define AUTHOR "N.O.V.A"

#define TASK_DASH_LOOP 562987
#define TASK_DASH_START 5327985
#define TASK_DASH_RELOAD 568726
#define TASK_DASH_FINISHED 6987206
#define TASK_HUD_MESSAGE 9823675

#define is_entity_on_ground(%1) ( entity_get_int ( %1, EV_INT_flags ) & FL_ONGROUND )

/*----------------------------------*/
/*         	NEWS 	            */
/*----------------------------------*/

// I Take this from Dias Class

new const zclass_name[] = "Tyrant"
new const zclass_info[] = "| G -> Dash | R -> Shoot Hound |"
new const zclass_model[] = "zombi_meatwall_fix"
new const zclass_clawmodel[] = "v_knife_zombimeatwall.mdl"
const zclass_health = 5000;
const zclass_speed = 230;
const Float:zclass_gravity = 1.0;
const Float:zclass_knockback = 1.0;


// Ent Classnames

new const g_ClassName_Wave[] = "nv_tyrant_wave_class";
new const g_ClassName_Egg[] = "nv_tyrant_egg_class";
new const g_ClassName_Hound[] = "nv_tyrant_hound_class";

// Models & Sprites

new const HoundMdl[] = "models/zombie_plague/meatwall/zombiedog.mdl";
new const WaveMdl[] = "models/zombie_plague/meatwall/ef_meatwall_wave.mdl";
new const RockMdl[] = "models/rockgibs.mdl";
new const BallMdl[] = "models/zombie_plague/meatwall/meatwall_egg.mdl";
new const EggSpr[] =  "sprites/ef_meatwall_egg.spr";
new const WaveSpr[] = "sprites/shockwave.spr";

// Sounds

new const Szsound[][] = 
{
	"zombie/meatwall/meatwallzombie_egg_crash.wav",
	"zombie/meatwall/meatwallzombie_ref_shoot_egg.wav",
	"zombie/meatwall/meatwallzombie_skill_dash_finish.wav",
	"zombie/meatwall/meatwallzombie_skill_dash_hold.wav",
	"zombie/meatwall/zombiedog_death1.wav",
	"zombie/meatwall/zombiedog_attack1.wav",
	"zombie/meatwall/zombiedog_howls.wav",
	"zombie/meatwall/zombiedog_skill1.wav"
	
};

// enums , Thanks +Arukari , Magic Numbers xD

enum 
{
	S_EGG_CRASH = 0,
	S_SHOOT_EGG,
	S_DASH_FINISH,
	S_DASH_START,
	S_HOUND_DEATH,
	S_HOUND_RUN,
	S_HOUND_SPAWN,
	S_HOUND_ATTACK
	
};

enum Cvars
{
	C_DASH_TIME = 0,
	C_TOUCH_KNOCKBACK,
	C_SHOCKWAVE_KNOCKBACK,
	C_KNOCKBACK_RADIUS,
	C_KNOCKBACK_MTL,
	C_ABILITY_RELOAD,
	C_HOUND_TYPE,
	C_KILL_HOUND,
	C_HUD_X,
	C_HUD_Y,
	C_HOUND_RANGE,
	C_FLAG_ON,
	C_FLAGS
};

// News

new bool:g_AbilityOn[33],bool:g_dashing[33],g_iPlayerAnimation[33],g_spr_ef,g_hudsync,g_zclass_tyrant,g_iCvar[Cvars],g_spr_wave,g_gibs_rock,g_max_players;

/*----------------------------------*/
/*          PLUGIN START            */
/*----------------------------------*/

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	Register_Cvars();
	register_dictionary("nv_zp_tr_class.txt");
	
	register_forward(FM_CmdStart,"fw_CmdStart");
	register_forward(FM_AddToFullPack, "forward_AddToFullPack", 1); 
	
	register_think(g_ClassName_Hound,"Think_Hound");
	
	register_clcmd("drop","Clcmd_Dash_Start");
	
	RegisterHam(Ham_Touch, "player", "CBP_Touch" );
	
	g_max_players = get_maxplayers();
	g_hudsync = CreateHudSyncObj();

}

public plugin_cfg()
{
	new configsdir[128];
	get_localinfo("amxx_configsdir", configsdir, 127);
	server_cmd("exec %s/bynova/nv_tyrant_class_zp.cfg", configsdir);
	
}

public Register_Cvars()
{
	register_cvar("nv_zp_cso_tyrant", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	g_iCvar[C_DASH_TIME] = register_cvar("nv_tyrant_dash_time","5.0");
	g_iCvar[C_KNOCKBACK_RADIUS] = register_cvar("nv_tr_knockback_radius","300.0");
	g_iCvar[C_KNOCKBACK_MTL] = register_cvar("nv_tr_knockback_multiplier","15.0");
	g_iCvar[C_ABILITY_RELOAD] = register_cvar("nv_tr_ability_reload","10.0");
	g_iCvar[C_HOUND_TYPE] = register_cvar("nv_tr_hd_dmg_type","1");
	g_iCvar[C_KILL_HOUND] = register_cvar("nv_tr_hd_kill_time","20.0");
	g_iCvar[C_HUD_X] = register_cvar("nv_tr_hud_x","0.80");
	g_iCvar[C_HUD_Y] = register_cvar("nv_tr_hud_y","0.40");
	g_iCvar[C_HOUND_RANGE] = register_cvar("nv_tr_hd_range","500.0");
	g_iCvar[C_FLAG_ON] = register_cvar("nv_tr_only_flag","1");
	g_iCvar[C_FLAGS] = register_cvar("nv_tr_flags","t");
	

}

public plugin_natives()
{
	register_native("nv_tr_is_dashing","is_user_dashing",1);
	register_native("nv_tr_is_user_tyrant","is_user_capable",1);
	register_native("nv_tr_get_hound_target","Get_Hound_Target",1);
	register_native("nv_tr_set_hound_target","Set_Hound_Target",1);
	register_native("nv_tr_get_hound_Owner","Get_Hound_Owner",1);
	register_native("nv_tr_set_hound_Owner","Set_Hound_Owner",1);
	
}

public plugin_precache()
{
	precache_model(HoundMdl);
	precache_model(BallMdl);
	precache_model(WaveMdl);
	
	g_gibs_rock = precache_model(RockMdl);
	g_spr_ef = precache_model(EggSpr);
	g_spr_wave = precache_model(WaveSpr);
	
	
	g_zclass_tyrant = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback);
	
	for(new i=0;i<sizeof(Szsound);i++)
	{
		precache_sound(Szsound[i]);
	}
}

public client_connect(id) Remove_Values(id);

#if AMXX_VERSION_NUM >= 183

public client_disconnected(id) Remove_Values(id);

#else

public client_disconnect(id) Remove_Values(id);

#endif

/*----------------------------------*/
/*          HOUND-SETTINGS          */
/*----------------------------------*/

public Set_Hound_Target(ent,target)
{
	new Data = set_pev(ent,pev_iuser3,target);
	return Data;
}

public Set_Hound_Owner(ent,owner)
{
	new Data = set_pev(ent,pev_iuser2,owner);
	return Data;
}

public Get_Hound_Target(ent)
{
	new Data = pev(ent,pev_iuser3);
	return Data;
}

public Get_Hound_Owner(ent)
{
	new Data = pev(ent,pev_iuser2);
	return Data;
}

/*----------------------------------*/
/*           ZP-SETTINGS            */
/*----------------------------------*/

public zp_user_infected_pre(id)
{
	if(get_pcvar_num(g_iCvar[C_FLAG_ON]) == 1)
	{
		if(!(get_user_flags(id) & read_pcvar_flags(g_iCvar[C_FLAGS])))
		{
			ChatColor(id,"%L",id,"NV_TR_NO_FLAG");
		}
	}
}

public zp_user_infected_post(id, infector)
{
	// First Remove Old Values....
	
	Remove_Values(id); 
	
	if (zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_tyrant)
	{
		g_AbilityOn[id] = true;
		g_dashing[id] = false;
		Reset_Player_Animation(id);
		set_task(1.0,"Show_Information",id+TASK_HUD_MESSAGE,_,_,"b");
	}
	
}

public zp_user_humanized_post(id) Remove_Values(id); 

public zp_round_ended() 
{
	remove_entity_name(g_ClassName_Egg);
	remove_entity_name(g_ClassName_Hound);
	remove_entity_name(g_ClassName_Wave);
	
	for(new i = 0; i <= g_max_players; i++)
	{
		if(is_user_connected(i))
		{
			Remove_Values(i);
		}
	}
	
}

/*----------------------------------*/
/*           DASH-SETTINGS          */
/*----------------------------------*/


public Clcmd_Dash_Start(id)
{
	if(is_user_capable(id) && is_user_alive(id))
	{
		if(g_AbilityOn[id])
		{
			g_AbilityOn[id] = false;
			set_task(1.0,"Dash_Ability_Start",id+TASK_DASH_START);
			set_task(get_pcvar_float(g_iCvar[C_DASH_TIME]) + 2.0,"Dash_Ability_Finished",id+TASK_DASH_FINISHED);
			set_task(get_pcvar_float(g_iCvar[C_ABILITY_RELOAD]),"Ability_Reload",id+TASK_DASH_RELOAD);
			ChatColor(id,"%L",id,"NV_TR_ABILITY_TIME",floatround(get_pcvar_float(g_iCvar[C_ABILITY_RELOAD])));
			set_weapon_anim(id,9);
			emit_sound(id, CHAN_WEAPON, Szsound[S_DASH_START], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

public fw_CmdStart(id,uc_handle,seed)
{
	if(is_user_alive(id) && is_user_capable(id) && get_user_weapon(id) == CSW_KNIFE && g_AbilityOn[id])
	{
	
		new buttons = get_uc(uc_handle,UC_Buttons);
		new oldbuttons = pev(id, pev_oldbuttons); 
	
		if(buttons & IN_RELOAD && !(oldbuttons & IN_RELOAD))
		{
			CBP_Egg(id);
			set_weapon_anim(id,14);
			g_AbilityOn[id] = false;
			set_task(get_pcvar_float(g_iCvar[C_ABILITY_RELOAD]),"Ability_Reload",id+TASK_DASH_RELOAD);
			ChatColor(id,"%L",id,"NV_TR_ABILITY_TIME",get_pcvar_num(g_iCvar[C_ABILITY_RELOAD]));
			emit_sound(id, CHAN_WEAPON, Szsound[S_SHOOT_EGG], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
	}
	return FMRES_IGNORED;
}

// Thanks To Perfect Scrash

public forward_AddToFullPack(es_handle, e, id, host, hostflags, player, pSet)
{
	if(!is_user_connected(host))
		return FMRES_IGNORED;

	if(is_user_alive(id) && player)
	{
		if(is_user_capable(id) && g_iPlayerAnimation[id] != -1)
		{
			// Set players sequence
			if(get_es(es_handle, ES_Sequence) != g_iPlayerAnimation[id]) 
			{
				set_es(es_handle, ES_Sequence, g_iPlayerAnimation[id]);
				
			}
		}
	}
	return FMRES_HANDLED;
}

public Show_Information(taskid)
{
	new id = taskid - TASK_HUD_MESSAGE;
	static TempMsg[500];
	
	if(is_user_capable(id))
	{
		if(g_AbilityOn[id])
		{
			formatex(TempMsg,charsmax(TempMsg),"%L",id,"NV_TR_HUD_ACTIVATED");
		}
		else
		{
			formatex(TempMsg,charsmax(TempMsg),"%L",id,"NV_TR_HUD_LOADING");
		}
	
		set_hudmessage(255, 0, 0, get_pcvar_float(g_iCvar[C_HUD_X]), get_pcvar_float(g_iCvar[C_HUD_Y]), 0, 1.0, 1.1, 0.0, 0.0, -1);
		ShowSyncHudMsg(id, g_hudsync, TempMsg);
	}
	else
		remove_task(taskid);
	
}

public Remove_Values(id)
{
	g_AbilityOn[id] = false;
	g_dashing[id] = false;
	
	remove_task(id);
	remove_task(id+TASK_DASH_FINISHED);
	remove_task(id+TASK_DASH_LOOP);
	remove_task(id+TASK_DASH_RELOAD);
	remove_task(id+TASK_DASH_START);
	remove_task(id+TASK_HUD_MESSAGE);
	
	CBP_KillAllHound(id);
	Reset_Player_Animation(id);
	
}

public Dash_Ability_Start(taskid)
{	
	new id = taskid - TASK_DASH_START;
	
	set_task(0.1,"Dash_Ability_Loop",id+TASK_DASH_LOOP,_,_,"a",get_pcvar_num(g_iCvar[C_DASH_TIME])*10);
	set_weapon_anim(id,10);
	Fade_Red(id,150);
	Util_ScreenShake(id);
	g_iPlayerAnimation[id] = 107;
	g_dashing[id] = true;
	
}

public Dash_Ability_Loop(taskid)
{
	new id = taskid - TASK_DASH_LOOP;
	static Float:Velocity[3];
	
	if(pev(id,pev_weaponanim) != 10) set_weapon_anim(id,10);
	
	velocity_by_aim(id, 550, Velocity);
	Velocity[2] = 0.0;	// We Don't Wanted Our Zm To Fly !!!!
	set_user_velocity(id,Velocity);
	
	
	// This Don't work Mostly.. i tried Everything But Animation is Same.It works if Tyrant is Flying xD
	//set_pev(id,pev_sequence,107); 
		
}


public Dash_Ability_Finished(taskid)
{
	new id = taskid - TASK_DASH_FINISHED;
	set_weapon_anim(id,12);
	Dash_Create_Wave(id);
	
	g_dashing[id] = false;
	
	/*new Float:jOrigin[3];
	pev(id,pev_origin,jOrigin);
	jOrigin[2] += 50.0;
	set_pev(id,pev_origin,jOrigin);
	set_pev(id,pev_sequence,109);*/
	
	g_iPlayerAnimation[id] = 109;
	
	emit_sound(id, CHAN_WEAPON, Szsound[S_DASH_FINISH], 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public Ability_Reload(taskid)
{
	new id = taskid - TASK_DASH_RELOAD;
	
	g_AbilityOn[id] = true;
	
}

public CBP_Touch(iPlayer,id)
{
	if(is_user_capable(iPlayer) && is_user_alive(id) && is_user_alive(iPlayer) && iPlayer != id)
	{
		if(!zp_get_user_zombie(id) && g_dashing[iPlayer])
		{
			KnockBack(iPlayer,id,get_pcvar_num(g_iCvar[C_KNOCKBACK_MTL]));
		}	
	}
	
}

// We hit something!!!
public pfn_touch(ptr, ptd)
{
	// If ent is valid
	if (pev_valid(ptr))
	{	
		// Get classnames
		static classname[32];
		pev(ptr, pev_classname, classname, 31);
		
		// Our ent
		if(equal(classname, g_ClassName_Egg))
		{
			new owner = pev(ptr,pev_iuser2);
			new Float:Origin[3];
			pev(ptr,pev_origin,Origin);
			CBP_Hound(owner,Origin);
			
			new Origins[3];
			FVecIVec(Origin, Origins);
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_SPRITE);
			write_coord(Origins[0]);
			write_coord(Origins[1]);
			write_coord(Origins[2] + 20);
			write_short(g_spr_ef);
			write_byte(6); // Scale
			write_byte(200);// Brighness
			message_end();

			remove_entity(ptr);
			
			emit_sound(ptr, CHAN_WEAPON, Szsound[S_EGG_CRASH], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
	}
}

public CBP_Egg(id)
{
	new Float:origin[3],Float:velocity[3],Float:angles[3];
	engfunc(EngFunc_GetAttachment, id, 0, origin,angles);
	pev(id,pev_angles,angles);
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"));
	set_pev(ent, pev_classname, g_ClassName_Egg);
	set_pev(ent, pev_solid, SOLID_BBOX);
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(ent, pev_mins, { -0.1, -0.1, -0.1 });
	set_pev(ent, pev_maxs, { 0.1, 0.1, 0.1 });
	entity_set_model(ent, BallMdl);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_angles, angles);
	set_pev(ent, pev_iuser2, id);
	velocity_by_aim(id, 1500, velocity);
	set_pev(ent, pev_velocity, velocity);
	
	
}

public CBP_Hound(id,Float:origin[3])
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"));
	engfunc(EngFunc_SetModel, ent, HoundMdl);
	
	set_pev(ent, pev_classname, g_ClassName_Hound);
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	engfunc(EngFunc_SetSize, ent, Float:{ -0.1, -0.1, -0.1 }, Float:{ 0.1, 0.1, 0.1 });	
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_takedamage,DAMAGE_NO);
	
	Set_Hound_Owner(ent,id);
	Set_Hound_Target(ent,0);
	
	set_anim(ent,1);
	set_task(get_pcvar_float(g_iCvar[C_KILL_HOUND]),"CBP_KillHound",ent);
	ChatColor(id,"%L",id,"NV_TR_HD_TIME",floatround(get_pcvar_float(g_iCvar[C_KILL_HOUND])));
	emit_sound(ent, CHAN_WEAPON, Szsound[S_HOUND_SPAWN], 1.0, ATTN_NORM, 0, PITCH_NORM);
	set_pev(ent,pev_nextthink,get_gametime() + 2.0);
	
}

public CBP_KillAllHound(id)
{
	new ent = -1;
	while((ent = find_ent_by_class(ent,g_ClassName_Hound)))
	{
		if(pev_valid(ent))
		{
			if(Get_Hound_Owner(ent) == id)
			{
				CBP_KillHound(ent);
			}
		}
	}
}

public CBP_KillHound(ent)
{
	if(pev_valid(ent))
	{
		set_pev(ent,pev_nextthink,0.0);
		set_anim(ent,15);
		set_task(3.0,"remove_valid_entity",ent);
		ChatColor(Get_Hound_Owner(ent),"%L",Get_Hound_Owner(ent),"NV_TR_HD_DIED");
		emit_sound(ent, CHAN_WEAPON, Szsound[S_HOUND_DEATH], 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}

// This is Baddest Code i Have done  :-D

public Think_Hound(ent)
{
	if(pev_valid(ent))
	{
		new Target = FindClosesEnemy(ent,get_pcvar_float(g_iCvar[C_HOUND_RANGE]));
		new MainTarget = Get_Hound_Target(ent);
		new Owner = Get_Hound_Owner(ent);
		
		new Float:EntOrigin[3],Float:TargetOrigin[3],Float:Distance;
		
		if(Target && Get_Hound_Target(ent) == 0)
		{
			Set_Hound_Target(ent,Target);
		}
		
		if(is_user_connected(MainTarget))
		{
			if(zp_get_user_zombie(MainTarget))
			{
				if(pev(ent,pev_sequence) != 1)
				{
						set_anim(ent,1);
						Set_Hound_Target(ent,0);
				}
			}
		}
		
		if(!is_user_connected(Target) || !is_user_alive(Target)) 
		{
			if(pev(ent,pev_sequence) != 1)
			{
					set_anim(ent,1);
					Set_Hound_Target(ent,0);
			}
		}
		
		pev(ent,pev_origin,EntOrigin);
		pev(Target,pev_origin,TargetOrigin);
		Distance = get_distance_f(TargetOrigin,EntOrigin);
		
		if(is_user_alive(Target))
		{	
			if(!zp_get_user_zombie(Target))
			{
				if(can_see_fm(ent,Target))
				{
					if(Distance <= 65.0)
					{
						Ham_Do_Damage(get_pcvar_num(g_iCvar[C_HOUND_TYPE]) ? Owner:0,ent,Target,50);
						reset_velocity(ent);
						
						// We Don't Want Sound to be bla bla bla ....
						
						if(random_num(0,99) < 10) 
						{
							emit_sound(ent, CHAN_WEAPON, Szsound[S_HOUND_ATTACK], 1.0, ATTN_NORM, 0, PITCH_NORM);
						}
						
						if(pev(ent,pev_sequence) != 8) set_anim(ent,8);
					}
					else
					{
						hook_ent(ent,Target,150.0);
						set_pev(ent,pev_movetype,MOVETYPE_PUSHSTEP);
						Hound_Turn_To_Taget(ent,Target);
						
						if(random_num(0,99) < 10) 
						{
							emit_sound(ent, CHAN_WEAPON, Szsound[S_HOUND_RUN], 1.0, ATTN_NORM, 0, PITCH_NORM);
						}
						
						if(pev(ent,pev_sequence) != 3) set_anim(ent,3);
						
					}
				
				}
				else
				{
					Set_Hound_Target(ent,0);
					if(pev(ent,pev_sequence) != 1) set_anim(ent,1);
					
				}
			
			}
			else
			{
				Set_Hound_Target(ent,0);
				if(pev(ent,pev_sequence) != 1) set_anim(ent,1);
			}
		}
		else
		{
			Set_Hound_Target(ent,0);
			if(pev(ent,pev_sequence) != 1) set_anim(ent,1);
		
		}
		set_pev(ent,pev_nextthink,get_gametime() + 0.1);
	}
	
}

public Dash_Create_Wave(id)
{
	new iOrigin[3] , Float:Origin[3];
	pev(id,pev_origin,Origin);
	FVecIVec(Origin,iOrigin);
	
	Origin[2] -= 18.0;
	
	new i_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	entity_set_model(i_Ent,WaveMdl);
	set_pev(i_Ent, pev_classname, g_ClassName_Wave);
	set_pev(i_Ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(i_Ent, pev_origin,Origin);
	set_anim(i_Ent,0);
	
	set_task(1.0,"remove_valid_entity",i_Ent);
	set_task(1.5,"Reset_Player_Animation",id);
	
	message_begin(MSG_ALL,SVC_TEMPENTITY,iOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]-18);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]+300);
	write_short(g_spr_wave); //Sprite
	write_byte(0); // Startframe
	write_byte(1); // framerate
	write_byte(10); // life
	write_byte(70); // width
	write_byte(15); //amplitude
	write_byte(255); //red
	write_byte(0); //green
	write_byte(0); // blue
	write_byte(255); // brightness
	write_byte(5); // speed
	message_end();
	
	 // Glass shatter
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0 );
	write_byte( TE_BREAKMODEL );
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_coord(60); // size x
	write_coord(60); // size y
	write_coord(60); // size z
	write_coord(random_num(-7,10)); // velocity x
	write_coord(random_num(-7,10)); // velocity y
	write_coord(20); // velocity z
	write_byte(10); // random velocity
	write_short(g_gibs_rock);
	write_byte(50); // count
	write_byte(30); // life
	write_byte(6); // flags
	message_end();
	
	for(new i=1;i<= g_max_players;i++)
	{
		if(is_user_alive(i) && !is_user_capable(i) && is_user_in_sphere(id,i,get_pcvar_float(g_iCvar[C_KNOCKBACK_RADIUS])))
		{
			Util_ScreenShake(i);
			KnockBack(id,i,get_pcvar_num(g_iCvar[C_KNOCKBACK_MTL]));
			
		}
	}
	
}

public Reset_Player_Animation(id)
{
	g_iPlayerAnimation[id] = -1
}
/*----------------------------------*/
/*            OTHER FX 	            */
/*----------------------------------*/

public Ham_Do_Damage(attacker,inf,target,damage)
{
	ExecuteHamB(Ham_TakeDamage, target, inf , attacker, float(damage) , DMG_ALWAYSGIB);
}


public KnockBack(zm,id,value)
{
	static Float:pos_ptr[3], Float:pos_ptd[3];
	pev(zm, pev_origin, pos_ptr);
	pev(id, pev_origin, pos_ptd);
	
	for(new i = 0; i < 3; i++)
	{
		pos_ptd[i] -= pos_ptr[i];
		pos_ptd[i] *= value;
	}
	
	set_pev(id, pev_velocity, pos_ptd);
	set_pev(id, pev_impulse, pos_ptd);
	
}

public remove_valid_entity(ent)
{
	if(is_valid_ent(ent))
	{
		remove_entity(ent);
	}
}

public is_user_capable(id)
{
	if(is_user_connected(id))
	{
		if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_tyrant && !zp_get_user_nemesis(id))
			return true;
	}
	return false;
}

public is_user_in_sphere(id,enemy,Float:radius)
{
	new Float:Distance;
	Distance = entity_range(id, enemy);
	
	if(Distance <= radius)
		return true;
	
	return false;
	
}

public is_user_dashing(id)
{
	if(g_dashing[id])
		return true;
		
	return false;	
}

public reset_velocity(ent)
{
	static Float:fl_Velocity[3];
	fl_Velocity[0] = 0.0;
	fl_Velocity[1] = 0.0;
	fl_Velocity[2] = 0.0;
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity);
}

/*----------------------------------*/
/*          	STOCKS              */
/*----------------------------------*/

stock Hound_Turn_To_Taget(ent,target) 
{
	new Float:Vic_Origin[3], Float:Ent_Origin[3];
	pev(ent,pev_origin,Ent_Origin);
	pev(target,pev_origin,Vic_Origin);
	
	if(target) 
	{
		new Float:newAngle[3];
		entity_get_vector(ent, EV_VEC_angles, newAngle);
		new Float:x = Vic_Origin[0] - Ent_Origin[0];
		new Float:z = Vic_Origin[1] - Ent_Origin[1];

		new Float:radians = floatatan(z/x, radian);
		newAngle[1] = radians * (180 / 3.14);
		
		if (Vic_Origin[0] < Ent_Origin[0])
			newAngle[1] -= 180.0;
		
		entity_set_vector(ent, EV_VEC_angles, newAngle);
	}
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return;
	
	set_pev(id, pev_weaponanim, anim);
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock Util_ScreenShake(id)
{
	static ScreenShake = 0;
	if( !ScreenShake )
	{
		ScreenShake = get_user_msgid("ScreenShake");
	}
	if(is_user_connected(id))
	{
		message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, ScreenShake, _, id);
		write_short(255<<14); //ammount 
		write_short(10 << 14); //lasts this long 
		write_short(255<< 14); //frequency 
		message_end();
	}
}


stock Fade_Red(id, amount)
{    
	if(amount > 255)
	amount = 255;
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid( "ScreenFade" ), {0,0,0}, id);
	write_short(amount * 100);    //Durration
	write_short(0);       //Hold
	write_short(0);        //Type
	write_byte(255);    //R
	write_byte(0);    //G
	write_byte(0);    //B
	write_byte(amount);    //B
	message_end();
    
}  

/// Thanks to Dias.
stock FindClosesEnemy(entid,Float:maxdistance)
{
	new Float:Dist,Float:EntOrigin[3],Float:TargetOrigin[3];
	new indexid=0;
	for(new i=1;i<=g_max_players;i++)
	{
		if(is_user_alive(i) && can_see_fm(entid, i))
		{
			if(!zp_get_user_zombie(i))
			{
				pev(entid,pev_origin,EntOrigin);
				pev(i,pev_origin,TargetOrigin);
				Dist = get_distance_f(TargetOrigin,EntOrigin);
				if(Dist <= maxdistance)
				{
					maxdistance=Dist;
					indexid=i;
				
					return indexid;
				}
			}	
		}
	}	
	return 0;
}

stock bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false;

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags);
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false;
		}

		new Float:lookerOrig[3];
		new Float:targetBaseOrig[3];
		new Float:targetOrig[3];
		new Float:temp[3];

		pev(entindex1, pev_origin, lookerOrig);
		pev(entindex1, pev_view_ofs, temp);
		lookerOrig[0] += temp[0];
		lookerOrig[1] += temp[1];
		lookerOrig[2] += temp[2];

		pev(entindex2, pev_origin, targetBaseOrig);
		pev(entindex2, pev_view_ofs, temp);
		targetOrig[0] = targetBaseOrig [0] + temp[0];
		targetOrig[1] = targetBaseOrig [1] + temp[1];
		targetOrig[2] = targetBaseOrig [2] + temp[2];

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false;
		} 
		else 
		{
			new Float:flFraction;
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true;
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0];
				targetOrig[1] = targetBaseOrig [1];
				targetOrig[2] = targetBaseOrig [2];
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true;
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0];
					targetOrig[1] = targetBaseOrig [1];
					targetOrig[2] = targetBaseOrig [2] - 17.0;
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction);
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}

stock hook_ent(entity, target, Float:speed)
{
	
	if (!is_valid_ent(entity) || !is_valid_ent(target)) return 0;
	
	new Float:entity_origin[3], Float:target_origin[3];
	entity_get_vector(entity, EV_VEC_origin, entity_origin);
	entity_get_vector(target, EV_VEC_origin, target_origin);
 
	new Float:diff[3];
	diff[0] = target_origin[0] - entity_origin[0];
	diff[1] = target_origin[1] - entity_origin[1];
	diff[2] = target_origin[2] - entity_origin[2];

	new Float:length = floatsqroot(floatpower(diff[0], 2.0) + floatpower(diff[1], 2.0) + floatpower(diff[2], 2.0));

	new Float:Velocity[3];
	Velocity[0] = diff[0] * (speed / length);
	Velocity[1] = diff[1] * (speed / length);
	Velocity[2] = diff[2] * (speed / length);
	
	entity_set_vector(entity, EV_VEC_velocity, Velocity);
	
	return 1;
}
 
stock set_anim(ent, sequence) 
{
	if(is_valid_ent(ent))
	{
		set_pev(ent, pev_sequence, sequence);
		set_pev(ent, pev_animtime, halflife_time());
		set_pev(ent, pev_framerate, 1.0);
	}
}

/// Thanks to Unknown Author

stock read_pcvar_flags(const pcvar)
{
	new flags[27];
	get_pcvar_string(pcvar, flags, charsmax(flags));
	return read_flags(flags);
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
       
	replace_all(msg, 190, "!g", "^4"); // Green Color
	replace_all(msg, 190, "!y", "^1"); // Default Color
	replace_all(msg, 190, "!team", "^3"); // Team Color
	replace_all(msg, 190, "!team2", "^0"); // Team2 Color
       
        if (id) players[0] = id; else get_players(players, count, "ch");
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
                                write_byte(players[i]);
                                write_string(msg);
                                message_end();
                        }
                }
        }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
