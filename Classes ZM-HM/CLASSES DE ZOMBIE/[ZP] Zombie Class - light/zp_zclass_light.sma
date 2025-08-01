#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <zombie_plague_special>
#include <fun>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

#define PLUGIN "[ZP] Zombie Class: Light Zombie"
#define VERSION "1.0"
#define AUTHOR "Dias"
// Editado Tradu��o By Henrique W.

#define TASK_INVISIBLE 124798
#define TASK_COOLDOWN 574825

new g_zclass_light
new bool:can_invisible[33]
new bool:is_invisible[33]

new const zclass_name[] = "Light"
new const zclass_info[] = "[G] -> Invisivel" 
new const zclass_model[] = "NDK_zm_light"
new const zclass_clawmodel[] = "v_ndk_knife_zlight.mdl"
new const invisible_sound[] = "zombie_plague/zombi_pressure_female.wav"
const zclass_health = 5700
const zclass_speed = 250
const Float:zclass_gravity = 0.75
const Float:zclass_knockback = 1.0

new cvar_inv_time
new cvar_cooldown
new cvar_invisible_amount

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop", "use_skill")
	register_menu("Menu Light", KEYSMENU, "menu_light_cases");
	cvar_inv_time = register_cvar("zp_zm_light_invisible_temp", "15.0")
	cvar_cooldown = register_cvar("zp_zm_light_cooldown", "30.0")
	cvar_invisible_amount = register_cvar("zp_zm_light_Invisivel_qualidade", "0")
}

public plugin_precache()
{
	g_zclass_light = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)	
	precache_sound(invisible_sound)
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_zclass_light) return PLUGIN_CONTINUE

	@SHOW_MENULIGHT(id)
	return PLUGIN_HANDLED
}

@SHOW_MENULIGHT(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yLIGHT \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONELI");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOLI");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDALI");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDLI");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYLI");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNLI");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1LI");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Light");

	return PLUGIN_CONTINUE
}

public menu_light_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

public zp_user_infected_post(id)
{
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_light)
	{
		can_invisible[id] = true
		is_invisible[id] = false
		remove_task(id+TASK_INVISIBLE)
		remove_task(id+TASK_COOLDOWN)
		
		client_print_color(id, print_team_default, "%L", id, "PRECIONE")
	}
}

public zp_user_humanized_post(id)
{
	can_invisible[id] = false
	is_invisible[id] = false
	
	remove_task(id-TASK_INVISIBLE)
	remove_task(id-TASK_COOLDOWN)
}

public use_skill(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_light && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		if(can_invisible[id] && !is_invisible[id])
		{
			do_skill(id)		
		} else {
			client_print_color(id, print_team_default, "%L", id, "ESPERE")
		}
	}
}

public do_skill(id)
{
	is_invisible[id] = true
	can_invisible[id] = false

	set_user_maxspeed(id, get_user_maxspeed(id) + 50)
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, get_pcvar_num(cvar_invisible_amount))

	emit_sound(id, CHAN_VOICE, invisible_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(get_pcvar_float(cvar_inv_time), "visible", id+TASK_INVISIBLE)
	
	client_print_color(id, print_team_default, "^4[ZP] ^1Voce esta Invisivel^4.")
}

public visible(taskid)
{
	new id = taskid - TASK_INVISIBLE
	
	is_invisible[id] = false
	
	set_user_maxspeed(id, get_user_maxspeed(id) - 50)
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	
	client_print_color(id, print_team_default, "^4[ZP] ^1Voce voltou ao normal^4.")
	
	set_task(get_pcvar_float(cvar_cooldown), "reset_cooldown", id+TASK_COOLDOWN)
}

public reset_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) && g_zclass_light)
	{		
		can_invisible[id] = true
		client_print_color(id, print_team_default, "^4[ZP] ^1Pressione ^4[G] ^1para ficar Invisivel^4.")
	}
}
