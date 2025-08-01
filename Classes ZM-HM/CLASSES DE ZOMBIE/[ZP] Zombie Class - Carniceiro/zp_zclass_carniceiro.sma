#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

// Plugin Version
new const PLUGIN_VERSION[] = "1.2"

// Carniceiro Zombie
new const zclass_name[] = { "Zombie Carniceiro" }
new const zclass_info[] = { "ataques Rapidos" }
new const zclass_model[] = { "zombie_carniceiro" }
new const zclass_clawmodel[] = { "v_zombie_carniceiro_claws.mdl" }
const zclass_health = 2000
const zclass_speed = 230
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 1.0

// weapon const
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new g_bCarniceiro[33]

// Game vars
new g_iCarniceiroIndex
new g_iMaxPlayers

// Cvar Pointer
new cvar_Primary, cvar_PrimarySpeed, cvar_Secondary, cvar_SecondarySpeed

public plugin_precache()
{
	register_plugin("[ZP] Class : Zombie Carniceiro", PLUGIN_VERSION, "schmurgel1983/Henrique")
	
	g_iCarniceiroIndex = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public plugin_init()
{
	register_menu("Menu Carniceiro", KEYSMENU, "menu_carniceiro_cases");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "event_player_death", "a")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fwd_Knife_PriAtk_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fwd_Knife_SecAtk_Post", 1)
	
	cvar_Primary = register_cvar("zp_zm_ex_pri", "1")
	cvar_PrimarySpeed = register_cvar("zp_zm_ex_pri_speed", "0.70")
	cvar_Secondary = register_cvar("zp_zm_ex_sec", "1")
	cvar_SecondarySpeed = register_cvar("zp_zm_ex_sec_speed", "0.60")
	
	register_cvar("Carniceiro_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Carniceiro_version", PLUGIN_VERSION)
	
	g_iMaxPlayers = get_maxplayers()
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_iCarniceiroIndex) return PLUGIN_CONTINUE

	@SHOW_MENUCARNICEIRO(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUCARNICEIRO(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yCARNICEIRO \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONEC");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOC");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDAC");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDC");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYC");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNC");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1C");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Carniceiro");

	return PLUGIN_CONTINUE
}

public menu_carniceiro_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

public client_putinserver(id) g_bCarniceiro[id] = false;

public client_disconnected(id) g_bCarniceiro[id] = false;

/*================================================================================
 [Main Forwards]
=================================================================================*/

public event_round_start()
{
	for (new id = 1; id <= g_iMaxPlayers; id++)
		g_bCarniceiro[id] = false
}

public event_player_death() g_bCarniceiro[read_data(2)] = false

public fwd_Knife_PriAtk_Post(ent)
{
	if (!get_pcvar_num(cvar_Primary))
		return HAM_IGNORED;
	
	static owner
	owner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!g_bCarniceiro[owner])
		return HAM_IGNORED
	
	static Float:Speed, Float:Primary, Float:Secondary
	Speed = get_pcvar_float(cvar_PrimarySpeed)
	Primary = get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS) * Speed
	Secondary = get_pdata_float(ent, m_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS) * Speed
	
	if (Primary > 0.0 && Secondary > 0.0)
	{
		set_pdata_float(ent, m_flNextPrimaryAttack, Primary, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, m_flNextSecondaryAttack, Secondary, OFFSET_LINUX_WEAPONS)
	}
	
	return HAM_IGNORED;
}

public fwd_Knife_SecAtk_Post(ent)
{
	if (!get_pcvar_num(cvar_Secondary))
		return HAM_IGNORED;
	
	static owner
	owner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!g_bCarniceiro[owner])
		return HAM_IGNORED
	
	static Float:Speed, Float:Primary, Float:Secondary
	Speed = get_pcvar_float(cvar_SecondarySpeed)
	Primary = get_pdata_float(ent, m_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS) * Speed
	Secondary = get_pdata_float(ent, m_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS) * Speed
	
	if (Primary > 0.0 && Secondary > 0.0)
	{
		set_pdata_float(ent, m_flNextPrimaryAttack, Primary, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, m_flNextSecondaryAttack, Secondary, OFFSET_LINUX_WEAPONS)
	}
	
	return HAM_IGNORED;
}

public zp_user_infected_post(id, infector)
{
	if(is_user_alive(id) && !zp_get_user_assassin(id) && !zp_get_user_nemesis(id) && 
	!zp_get_user_predator(id) && !zp_get_user_dragon(id) && !zp_get_user_bombardier(id))
	
	if (zp_get_user_zombie_class(id) == g_iCarniceiroIndex)
		g_bCarniceiro[id] = true
		
}

public zp_user_humanized_post(id) g_bCarniceiro[id] = false


/*================================================================================
 [Stocks]
=================================================================================*/

stock ham_cs_get_weapon_ent_owner(entity)
{
	return get_pdata_cbase(entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
