#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

// Zombie Attributes
new const zclass_name[] = "Crawl" // name
new const zclass_info[] = "Ducka sem parar" // description
new const zclass_model[] = "NDK_zm_Crawl" // model
new const zclass_clawmodel[] = "v_knife_ndk_Crawl.mdl" // claw model
const zclass_health = 5700 // health
const zclass_speed = 300 // speed
const Float:zclass_gravity = 0.50 // gravity
const Float:zclass_knockback = 1.14 // knockback

// Class IDs
new g_zcrawl

// Player is ducked
new g_ducked[33]

// Get server's max players and speed | Create a custom chat print
new g_maxplayers, g_maxspeed

public plugin_init()
{
	register_menu("Menu Crawler", KEYSMENU, "menu_crawler_cases");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	g_maxplayers = get_maxplayers()
	g_maxspeed = get_cvar_pointer("sv_maxspeed")
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_zcrawl) return PLUGIN_CONTINUE

	@SHOW_MENUCRAWLER(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUCRAWLER(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yCARNICEIRO \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONECR");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOCR");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDACR");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDCR");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYCR");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNCR");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1CR");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Crawler");

	return PLUGIN_CONTINUE
}

public menu_crawler_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	register_plugin("[ZP] Zombie Class: Crawler", "1.4", "93()|29!/< | Henrique")
	
	// Register the new class and store ID for reference
	g_zcrawl = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

// User Infected forward
public zp_user_infected_post(id, infector, nemesis)
{
	// Check if the player has been turned into nemesis
	if (nemesis)
	{
		// Get up
		unduck_player(id)
		
		g_ducked[id] = false
		
		return;
	}
	
	if (zp_get_user_zombie_class(id) != g_zcrawl)
	{
		g_ducked[id] = false
		
		return;
	}
	
	client_cmd(id, "cl_forwardspeed %d; cl_backspeed %d; cl_sidespeed %d", Float:zclass_speed, Float:zclass_speed, Float:zclass_speed)
	
	//zp_colored_print(id, "^x04[ZP]^x03 Atencao!^x01 Os seguintes valores cvar do cliente foram definidos de acordo")
	
	g_ducked[id] = true
}

// User Humanized forward
public zp_user_humanized_post(id, survivor)
{
	// Stand up
	unduck_player(id)
	
	g_ducked[id] = false
}

// Player has just connected/reconnected
public client_connect(id)
{
	g_ducked[id] = false
}
	

// Client is disconnecting
public client_disconnected(id)
{
	unduck_player(id)
}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Checks...
	if (zp_get_user_nemesis(id) || zp_get_user_assassin(id) || !zp_get_user_zombie(id) || is_user_bot(id)
	|| zp_get_user_zombie_class(id) != g_zcrawl || !is_user_alive(id))
		return;
	
	
	// Make the player crouch
	set_pev(id, pev_bInDuck, 1)
	client_cmd(id, "+duck")
	
	g_ducked[id] = true
}

// Ham Player Killed Forward
public fw_PlayerKilled(id)
{
	// Make the player stand up
	unduck_player(id)
	
	g_ducked[id] = false
}

// Log Event Round End
public logevent_round_end()
{
	static id
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Some extra checks on round end aren't bad...i think
		if (zp_get_user_nemesis(id) || zp_get_user_assassin(id) || zp_get_user_assassin(id) || zp_get_user_predator(id) || zp_get_user_bombardier(id) || zp_get_user_dragon(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zcrawl || !is_user_alive(id))
			g_ducked[id] = false
		else
			g_ducked[id] = true
	}
}

// Event Round Start
public event_round_start()
{
	// Make sure the server isn't blocking our zombie's speed
	if (get_pcvar_float(g_maxspeed) < Float:zclass_speed)
		server_cmd("sv_maxspeed 1000") // Better than setting it to the zombie speed value
	set_task(0.0, "xLEVANTAR")
}

public xLEVANTAR(id)
{
	for (id = 1; id <= g_maxplayers; id++)
		{
			// Get the hell up
		unduck_player(id)

		g_ducked[id] = false
	}
}

// Make the player stand up
public unduck_player(id)
{
	// Isn't ducked | Is a bot
	if (!g_ducked[id] || is_user_bot(id))
		return;
	
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
	client_cmd(id, "-duck") // Prevent death spectator camera bug
}
