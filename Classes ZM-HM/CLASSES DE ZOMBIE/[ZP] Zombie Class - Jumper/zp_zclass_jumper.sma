#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombie_plague_special>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

new g_multijumps[33] = 0;
new jumpnum[33] = 0;
new bool:dojump[33] = false;

new const zclass_name[ ] = "Zombie Jumper"
new const zclass_info[ ] = "+ 2 jump"
new const zclass_model[ ] = "zm_jumper"
new const zclass_clawmodel[ ] = "v_knife_zm_jumper.mdl"
const zclass_health = 4500
const zclass_speed = 280
const Float:zclass_gravity = 0.47
const Float:zclass_knockback = 1.00

new g_jumper

public plugin_init()
{
	register_plugin("[ZP] Zombie Jumper", "1.0", "Dexter")
	register_menu("Menu Jumper", KEYSMENU, "menu_jumper_cases");
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink");
	register_forward(FM_PlayerPostThink, "FW_PlayerPostThink");
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_jumper) return PLUGIN_CONTINUE

	@SHOW_MENUJUMPER(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUJUMPER(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yJUMPER \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONEJ");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOJ");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDAJ");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDJ");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYJ");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNJ");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1J");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Jumper");

	return PLUGIN_CONTINUE
}

public menu_jumper_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

public plugin_precache()
{
	g_jumper = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public client_putinserver(player)
{
	g_multijumps[player]++
}

public client_disconnected(id)
{
	g_multijumps[id] = g_multijumps[id] = 0
}

public FW_PlayerPreThink(id)
{
	if(zp_get_user_zombie_class(id) != g_jumper) return PLUGIN_CONTINUE
	if(is_user_alive(id) || !zp_get_user_zombie(id) || !zp_get_user_survivor(id) || !zp_get_user_nemesis(id) 
	|| !zp_get_user_sniper(id) || !zp_get_user_assassin(id))
	{
	new nbut = pev(id,pev_button);
	new obut = pev(id,pev_oldbuttons);
	if((nbut & IN_JUMP) && !(pev(id,pev_flags) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[id] < g_multijumps[id])
		{
			dojump[id] = true;
			jumpnum[id]++;
			return PLUGIN_CONTINUE
		}
	}
	if((nbut & IN_JUMP) && (pev(id,pev_flags) & FL_ONGROUND))
	{
		jumpnum[id] = 0;
		return PLUGIN_CONTINUE
	}
}
	return PLUGIN_CONTINUE
}

public FW_PlayerPostThink(id)
{
	if(zp_get_user_zombie_class(id) != g_jumper) return PLUGIN_CONTINUE
	if(is_user_alive(id) || !zp_get_user_zombie(id) || !zp_get_user_survivor(id) || !zp_get_user_nemesis(id) 
	|| !zp_get_user_sniper(id) || !zp_get_user_assassin(id))
	{
		if(dojump[id] == true)
		{
			new Float:velocity[3];
			pev(id,pev_velocity,velocity);
			velocity[2] = random_float(265.0,285.0);
			set_pev(id,pev_velocity,velocity)
			dojump[id] = false
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}
