#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_plague_special>
#include <xs>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

/* ~ [ Zombie Class Setting's ] ~ */
new const ZM_CLASS_NAME[] = "Stamper"
new const ZM_CLASS_INFO[] = "Habilidade [G]"
new const ZM_CLASS_MODEL[] = "x_stamper"
new const ZM_CLASS_CLAW[] = "v_knife_stamper.mdl"
new const ZM_CLASS_BOMB[] = "models/x/grenades/v_zbomb_stamper.mdl"
const ZM_CLASS_HEALTH = 5100;
const ZM_CLASS_SPEED = 235;
const Float: ZM_CLASS_GRAVITY = 0.88;
const Float: ZM_CLASS_KNOCKBACK = 0.64;
const Float: ZM_CLASS_WAIT_COFFIN = 20.0;

/* ~ [ Entity ] ~ */
new const ENTITY_COFFIN_CLASSNAME[] = "ent_coffinx";
new const ENTITY_COFFIN_MODEL[] = "models/ndk/caixao_stamper_ndk.mdl";
new const ENTITY_COFFIN_SOUNDS[][] =
{
	"x/stamper/zombi_stamper_iron_maiden_stamping.wav",
	"x/stamper/zombi_stamper_iron_maiden_explosion.wav",
	"debris/wood1.wav"
};
new const ENTITY_COFFIN_RESOURCES[][] =
{
	"sprites/x/zombiebomb_exp.spr",
	"models/woodgibs.mdl",
	"sprites/shockwave.spr"
};
new const ENTITY_SLOW_SPRITE[] = "sprites/x/zbt_slow.spr";

const Float: ENTITY_COFFIN_RADIUS = 200.0;
const Float: ENTITY_COFFIN_KNOCKBACK = 600.0;
const Float: ENTITY_COFFIN_ALIVE = 20.0;
const Float: ENTITY_COFFIN_HEALTH = 450.0;

/* ~ [ Macroses ] ~ */
#define PDATA_SAFE 2
#define BREAK_WOOD 8
#define ACT_RANGE_ATTACK1 28 
#define TASKID_WAIT_HUD 9800

#define pev_owner_ex pev_iuser1

#define get_bit(%1,%2) ((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2) %1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2) %1 &= ~(1 << (%2 & 31))

/* ~ [ Offset's ] ~ */
// Linux extra offsets
#define linux_diff_animating 4
#define linux_diff_weapon 4
#define linux_diff_player 5

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40

// CBasePlayerItem
#define m_pPlayer 41

// CBaseMonster
#define m_Activity 73
#define m_IdealActivity 74
#define m_flNextAttack 83

// CBasePlayer
#define m_flLastAttackTime 220

/* ~ [ Params ] ~ */
new gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Coffin,
	gl_iszAllocString_Slow;
new gl_iszModelIndex_Resources[sizeof ENTITY_COFFIN_RESOURCES];
new Float: gl_flCoffinWait[33];
new gl_iBitUserHasCoffin,
	gl_iMaxPlayers,
	gl_iZClassID;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Class: Stamper", "2020 | 1.0", "xUnicorn (t3rkecorejz)");

	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");
	register_menu("Menu Stamper", KEYSMENU, "menu_stamper_cases");

	new const GRENADES_ENTITY[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" };
	for(new i = 0; i < sizeof GRENADES_ENTITY; i++)
		RegisterHam(Ham_Item_Deploy, GRENADES_ENTITY[i], "CGrenade__Deploy_Post", true);

	RegisterHam(Ham_TakeDamage, "info_target", "CEntity__TakeDamage_Post", true);
	RegisterHam(Ham_Killed, "info_target", "CEntity__Killed_Post", true);
	RegisterHam(Ham_Think, "info_target", "CEntity__Think_Pre", false);

	register_clcmd("drop", "Command__UseAbility");

	gl_iMaxPlayers = get_maxplayers();
}

public plugin_precache()
{
	new i;

	// Models
	engfunc(EngFunc_PrecacheModel, ZM_CLASS_BOMB);
	engfunc(EngFunc_PrecacheModel, ENTITY_COFFIN_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_SLOW_SPRITE);

	/// Sounds
	for(i = 0; i < sizeof ENTITY_COFFIN_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, ENTITY_COFFIN_SOUNDS[i])

	//UTIL_PrecacheSoundsFromModel(ZM_CLASS_BOMB);

	// Model Index
	for(i = 0; i < sizeof ENTITY_COFFIN_RESOURCES; i++)
		gl_iszModelIndex_Resources[i] = engfunc(EngFunc_PrecacheModel, ENTITY_COFFIN_RESOURCES[i]);

	// Alloc String
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Coffin = engfunc(EngFunc_AllocString, ENTITY_COFFIN_CLASSNAME);
	gl_iszAllocString_Slow = engfunc(EngFunc_AllocString, "ent_slowx");

	// Other
	gl_iZClassID = zp_register_zombie_class(ZM_CLASS_NAME, ZM_CLASS_INFO, ZM_CLASS_MODEL, ZM_CLASS_CLAW, ZM_CLASS_HEALTH, ZM_CLASS_SPEED, ZM_CLASS_GRAVITY, ZM_CLASS_KNOCKBACK)
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != gl_iZClassID) return PLUGIN_CONTINUE

	@SHOW_MENUSTAMPER(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUSTAMPER(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \ySTAMPER \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONEST");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOST");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDAST");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDST");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYST");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNST");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1ST");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Stamper");

	return PLUGIN_CONTINUE
}

public menu_stamper_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

Reset_Value(iPlayer)
{
	reset_bit(gl_iBitUserHasCoffin, iPlayer);

	gl_flCoffinWait[iPlayer] = 0.0;

	if(task_exists(iPlayer + TASKID_WAIT_HUD))
		remove_task(iPlayer + TASKID_WAIT_HUD);

	new iEntity = fm_find_ent_by_owner_ex(ENTITY_COFFIN_CLASSNAME, iPlayer);
	if(pev_valid(iEntity) == PDATA_SAFE)
		set_pev(iEntity, pev_ltime, get_gametime());
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(iPlayer) Reset_Value(iPlayer);
#else
public client_disconnected(iPlayer) Reset_Value(iPlayer);
#endif
public client_putinserver(iPlayer) Reset_Value(iPlayer);

public Command__UseAbility(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return PLUGIN_CONTINUE;
	if(zp_get_user_zombie_class(iPlayer) != gl_iZClassID) return PLUGIN_CONTINUE;
	if(get_user_weapon(iPlayer) != CSW_KNIFE) return PLUGIN_CONTINUE;
	if(get_pdata_float(iPlayer, m_flNextAttack, linux_diff_player) > 0.0) return PLUGIN_CONTINUE;
	if(get_bit(gl_iBitUserHasCoffin, iPlayer)) return PLUGIN_CONTINUE;

	new Float: flGameTime = get_gametime();
	if(gl_flCoffinWait[iPlayer] <= flGameTime)
	{
		UTIL_SendWeaponAnim(iPlayer, 2);
		UTIL_PlayerAnimation(iPlayer, "skill");
		set_pdata_float(iPlayer, m_flNextAttack, 1.0, linux_diff_player);

		set_task(5/15.0, "CTask__SetCoffin", iPlayer);
	}

	return PLUGIN_CONTINUE;
}

/* ~ [ Events ] ~ */
public EV_RoundStart()
{
	new iEntity = FM_NULLENT;
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", ENTITY_COFFIN_CLASSNAME)))
	{
		if(pev_valid(iEntity))
			set_pev(iEntity, pev_flags, FL_KILLME);
	}

	for(new iPlayer = 1; iPlayer <= gl_iMaxPlayers; iPlayer++) 
	{
		if(!is_user_connected(iPlayer)) continue;

		Reset_Value(iPlayer);
	}
}

/* ~ [ Zombie Plague ] ~ */
public zp_user_infected_post(iPlayer, iInfector)
{
	Reset_Value(iPlayer);
	
	if(zp_get_user_zombie_class(iPlayer) == gl_iZClassID)
		UTIL_ColorChat(iPlayer, "!g[ZP] !ySua habilidade !g[G]");
}
public zp_user_humanized_pre(iPlayer) Reset_Value(iPlayer);

/* ~ [ HamSandwich ] ~ */
public CGrenade__Deploy_Post(iItem)
{
	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return;

	if(zp_get_user_zombie_class(iPlayer) == gl_iZClassID)
		set_pev(iPlayer, pev_viewmodel2, ZM_CLASS_BOMB);
}

public CEntity__TakeDamage_Post(iEntity, iAttacker, Float: flDamage)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Coffin)
	{
		// TraceAttack: get_tr2(pTrace, TR_vecEndPos, vecEndPos);
		new Float: vecEndPos[3]; global_get(glb_trace_endpos, vecEndPos);

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPARKS);
		engfunc(EngFunc_WriteCoord, vecEndPos[0]);
		engfunc(EngFunc_WriteCoord, vecEndPos[1]);
		engfunc(EngFunc_WriteCoord, vecEndPos[2]);
		message_end();

		emit_sound(iEntity, CHAN_VOICE, ENTITY_COFFIN_SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	return HAM_IGNORED;
}

public CEntity__Killed_Post(iEntity, iAttacker)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Coffin)
	{
		new iOwner = pev(iEntity, pev_owner_ex);
		CEntity__DestroyCoffin(iEntity, iOwner);
	}
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	new Float: flGameTime = get_gametime();
	static Float: flEntityLifetime, iOwner;

	if(pev(iEntity, pev_classname) == gl_iszAllocString_Coffin)
	{
		pev(iEntity, pev_ltime, flEntityLifetime);
		iOwner = pev(iEntity, pev_owner_ex);

		if(flEntityLifetime <= flGameTime)
		{
			CEntity__DestroyCoffin(iEntity, iOwner);

			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		set_pev(iEntity, pev_nextthink, flGameTime + 0.1);
	}
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Slow)
	{
		pev(iEntity, pev_ltime, flEntityLifetime);
		iOwner = pev(iEntity, pev_owner);

		if(flEntityLifetime <= flGameTime || zp_get_user_zombie(iOwner) || !is_user_connected(iOwner))
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		static Float: vecVelocity[3]; pev(iOwner, pev_velocity, vecVelocity);
		vecVelocity[0] *= 0.5;
		vecVelocity[1] *= 0.5;
		set_pev(iOwner, pev_velocity, vecVelocity);

		set_pev(iEntity, pev_nextthink, flGameTime + 0.1);
	}

	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
public CEntity__DestroyCoffin(iEntity, iPlayer)
{
	// Entity
	new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

	emit_sound(iEntity, CHAN_ITEM, ENTITY_COFFIN_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 20.0);
	write_short(gl_iszModelIndex_Resources[0]);
	write_byte(20); // Scale
	write_byte(24); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 20.0);
	engfunc(EngFunc_WriteCoord, 16);
	engfunc(EngFunc_WriteCoord, 16);
	engfunc(EngFunc_WriteCoord, 16);
	engfunc(EngFunc_WriteCoord, random_num(-50, 50));
	engfunc(EngFunc_WriteCoord, random_num(-50, 50));
	engfunc(EngFunc_WriteCoord, 25);
	write_byte(10);
	write_short(gl_iszModelIndex_Resources[1]);
	write_byte(10);
	write_byte(25);
	write_byte(BREAK_WOOD);
	message_end();

	new iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_COFFIN_RADIUS)) > 0)
	{
		if(!is_user_alive(iVictim)) continue;

		new Float: flLen, Float: vecVelocity[3], Float: vecVOrigin[3];
		pev(iVictim, pev_origin, vecVOrigin);

		xs_vec_sub(vecVOrigin, vecOrigin, vecVelocity);
		flLen = xs_vec_len(vecVelocity);
		xs_vec_mul_scalar(vecVelocity, ENTITY_COFFIN_KNOCKBACK / flLen, vecVelocity);

		set_pev(iVictim, pev_velocity, vecVelocity);
	}

	// Player
	new Float: flGameTime = get_gametime();

	reset_bit(gl_iBitUserHasCoffin, iPlayer);
	gl_flCoffinWait[iPlayer] = flGameTime + ZM_CLASS_WAIT_COFFIN;
}

public CPlayer__CreateCoffin(iPlayer, iDuck)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_angles, vecAngles);
	new Float: vecAnglesEntity[3]; vecAnglesEntity[1] = vecAngles[1];
	new Float: vecForward[3]; angle_vector(vecAnglesEntity, ANGLEVECTOR_FORWARD, vecForward);

	new Float: vecEndPos[3];
	xs_vec_mul_scalar(vecForward, 75.0, vecForward);
	xs_vec_add(vecOrigin, vecForward, vecEndPos);

	{
		new pTrace = create_tr2();

		engfunc(EngFunc_TraceLine, vecOrigin, vecEndPos, DONT_IGNORE_MONSTERS, iPlayer, pTrace);
		get_tr2(pTrace, TR_vecEndPos, vecEndPos);

		free_tr2(pTrace);
	}

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Coffin);
	set_pev(iEntity, pev_movetype, MOVETYPE_PUSHSTEP);
	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_owner_ex, iPlayer);
	set_pev(iEntity, pev_takedamage, DAMAGE_YES);
	set_pev(iEntity, pev_health, ENTITY_COFFIN_HEALTH);
	set_pev(iEntity, pev_nextthink, flGameTime + 0.1);
	set_pev(iEntity, pev_ltime, flGameTime + ENTITY_COFFIN_ALIVE);
	set_pev(iEntity, pev_angles, vecAnglesEntity);
	set_pev(iEntity, pev_body, iDuck);
	set_pev(iEntity, pev_skin, 1);

	set_entity_anim(iEntity, iDuck);

	new Float: flMins[3], Float: flMaxs[3];
	flMins[0] = flMins[1] = -8.0; flMins[2] = 0.0;
	flMaxs[0] = flMaxs[1] = flMins[0] / -1.0; flMaxs[2] = iDuck ? 48.0 : 64.0;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_COFFIN_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecEndPos);
	engfunc(EngFunc_SetSize, iEntity, flMins, flMaxs);

	emit_sound(iEntity, CHAN_ITEM, ENTITY_COFFIN_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	if(is_entity_stuck(iEntity, iDuck))
	{
		CEntity__DestroyCoffin(iEntity, iPlayer);
		set_pev(iEntity, pev_flags, FL_KILLME);

		return FM_NULLENT;
	}

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_BEAMDISK);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2] + (iDuck ? -10.0 : -26.0));
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2] + 250.0);
	write_short(gl_iszModelIndex_Resources[2]);
	write_byte(0);
	write_byte(0);
	write_byte(5);
	write_byte(1);
	write_byte(0);
	write_byte(128);
	write_byte(128);
	write_byte(128);
	write_byte(255);
	write_byte(0);
	message_end();

	new iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecEndPos, ENTITY_COFFIN_RADIUS)) > 0)
	{
		if(!is_user_alive(iVictim) || zp_get_user_zombie(iVictim)) continue;

		CPlayer__SetSlow(iVictim);
	}

	return iEntity;
}

public CPlayer__SetSlow(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Slow);
	set_pev(iEntity, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_aiment, iPlayer);
	set_pev(iEntity, pev_ltime, get_gametime() + 5.0);
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 200.0);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_SLOW_SPRITE);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

/* ~ [ Tasks ] ~ */
public CTask__SetCoffin(iPlayer)
{
	set_bit(gl_iBitUserHasCoffin, iPlayer);
	CPlayer__CreateCoffin(iPlayer, pev(iPlayer, pev_flags) & FL_DUCKING ? 1 : 0);

	if(task_exists(iPlayer + TASKID_WAIT_HUD))
		remove_task(iPlayer + TASKID_WAIT_HUD);

	set_task(1.0, "CTask__CreateWaitHud", iPlayer + TASKID_WAIT_HUD, _, _, .flags = "b");

	remove_task(iPlayer);
}

public CTask__CreateWaitHud(iTask)
{
	new iPlayer = iTask - TASKID_WAIT_HUD;

	if(is_user_alive(iPlayer))
	{
		if(!zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer))
		{
			remove_task(iTask);
			return;
		}

		new szText[256];
		new Float: flGameTime = get_gametime();

		if(get_bit(gl_iBitUserHasCoffin, iPlayer))
		{
			new iEntity = fm_find_ent_by_owner_ex(ENTITY_COFFIN_CLASSNAME, iPlayer);
			if(pev_valid(iEntity) == PDATA_SAFE)
			{
				static Float: flCoffinHealth; pev(iEntity, pev_health, flCoffinHealth);
				formatex(szText, charsmax(szText), "O caixão vai desaparecer através %i seg. [+%i]", floatround(pev(iEntity, pev_ltime) - flGameTime), floatround(flCoffinHealth));
			}
		}
		else
		{
			if(gl_flCoffinWait[iPlayer] > flGameTime)
				formatex(szText, charsmax(szText), "(G) Caixão: [%02d]", floatround(gl_flCoffinWait[iPlayer] - flGameTime));
			else
			{
				remove_task(iTask);
				return;
			}
		}

		set_hudmessage(250, 180, 30, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1);
		show_hudmessage(iPlayer, "%s", szText);
	}
	else remove_task(iTask);
}

// [ Stocks ]
stock is_entity_stuck(iEntity, iDuck)
{
	static Float: vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, iDuck ? HULL_HEAD : HULL_HUMAN, iEntity, 0);
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock set_entity_anim(iEntity, iSequence)
{
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_sequence, iSequence);
}

stock fm_find_ent_by_owner_ex(const szClassName[], iOwner, jghgtype = 0)
{
	new szStrType[11] = "classname", iEntity = FM_NULLENT;
	switch(jghgtype)
	{
		case 1: szStrType = "target";
		case 2: szStrType = "targetname";
	}

	while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, szStrType, szClassName)) && pev(iEntity, pev_owner_ex) != iOwner) {}

	return iEntity;
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_ColorChat(iPlayer, const szInput[], any:...)
{
    new iCount = 1, iPlayers[32];
    static szMessage[188];
    vformat(szMessage, charsmax(szMessage), szInput, 3);
    
    replace_all(szMessage, charsmax(szMessage), "!g", "^4");
    replace_all(szMessage, charsmax(szMessage), "!y", "^1");
    replace_all(szMessage, charsmax(szMessage), "!t", "^3");
    
    if(iPlayer) iPlayers[0] = iPlayer; else get_players(iPlayers, iCount, "ch");
    {
        for(new i = 0; i < iCount; i++)
        {
            if(is_user_connected(iPlayers[i]))
            {
                message_begin(MSG_ONE, get_user_msgid("SayText"), _, iPlayers[i]);
                write_byte(iPlayers[i]);
                write_string(szMessage);
                message_end();
            }
        }
    }
    
    return true;
}

stock UTIL_PlayerAnimation(iPlayer, const szAnimation[])
{
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(iPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;

	set_entity_anim(iPlayer, iAnimDesired);
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, get_gametime(), linux_diff_animating);
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);   
	set_pdata_float(iPlayer, m_flLastAttackTime, get_gametime(), linux_diff_player);
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
