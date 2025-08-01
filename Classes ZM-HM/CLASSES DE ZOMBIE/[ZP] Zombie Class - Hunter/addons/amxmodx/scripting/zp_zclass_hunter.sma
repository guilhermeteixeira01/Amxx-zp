#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>
#include <zombie_plague_special>

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
const OFFSET_CSMENUCODE = 206

new const zclass_name[] = "Hunter";
new const zclass_info[] = "Super pulo (E)";
new const zclass_model[] = "zombie_source";
new const zclass_clawmodel[] = "v_knife_zombie.mdl";

const zclass_health = 6800;
const zclass_speed = 220;

const LONG_JUMP_FORCE = 980;
const Float:NEXT_TIME_USE = 30.0;

const Float:zclass_gravity = 1.14;
const Float:zclass_knockback = 2.50;

new const LEAP_SOUNDS[][] =
{
	"left_4_dead2/hunter_jump.wav",
	"left_4_dead2/hunter_jump1.wav",
	"left_4_dead2/hunter_jump2.wav",
	"left_4_dead2/hunter_jump3.wav",
};

new g_iClassHunter;
new Float:LongJump_CountDown[MAX_PLAYERS + 1];

public plugin_precache()
{
	g_iClassHunter = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback);

	for(new IND = 0; IND < sizeof(LEAP_SOUNDS); IND++) {
		precache_sound(LEAP_SOUNDS[IND]);
	}
}

new xCountSync, Float:LongJump_LastTime[MAX_PLAYERS + 1];

public plugin_init() 
{
	register_plugin("[ZP] Class: Hunter", "1,0", "BRUN0");

	xCountSync = CreateHudSyncObj();
	register_menu("Menu Hunter", KEYSMENU, "menu_hunter_cases");
	RegisterHookChain(RG_CBasePlayer_PreThink, "@CBasePlayer_PreThink");
}

public zp_zombie_class_choosed_post(id, classid)
{
	if(classid != g_iClassHunter) return PLUGIN_CONTINUE

	@SHOW_MENUHUNTER(id)
	return PLUGIN_HANDLED
}

@SHOW_MENUHUNTER(id)
{
	static menu[999], len; len = 0

	len += formatex(menu[len], charsmax(menu) - len, "\r>> Classe \yHUNTER \r<<^n^n");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SELECIONEH");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "DESCRICAOH");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "VIDAH");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "SPEEDH");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, "GRAVITYH");
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "KNH");

	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "DC1H");

	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "SAIR");

	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Menu Hunter");

	return PLUGIN_CONTINUE
}

public menu_hunter_cases(id, key)
{
	switch(key)
	{
		case 0:
		{

		}
	}
	return PLUGIN_HANDLED
}

@CBasePlayer_PreThink(const id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_iClassHunter)
		return;

	static Float:xTIME; xTIME = get_gametime();

	if(LongJump_CountDown[id] && LongJump_CountDown[id] < xTIME)
	{
		if(LongJump_LastTime[id] > 0.0)
		{
			if(LongJump_LastTime[id] >= 0.0) ClearSyncHud(id, xCountSync);
	
			set_hudmessage(180, 180, 0, -1.0, 0.33, 0, 0.06, 0.06, 0.05, 0.05, -1);
			ShowSyncHudMsg(id, xCountSync, "» Skill Countdown %.1f «", LongJump_LastTime[id]);
			LongJump_LastTime[id] -= 0.1;

			LongJump_CountDown[id] = xTIME + 0.1;
		}
	}

	if(!(get_entvar(id, var_button) & IN_USE) || LongJump_LastTime[id] && LongJump_LastTime[id] >= 0.0)
		return;

	static Float:velocity[3];
	velocity_by_aim(id, LONG_JUMP_FORCE, velocity);
	set_entvar(id, var_velocity, velocity);

	//ClearSyncHud(id, xCountSync); // Nesseçario?

	rh_emit_sound2(id, 0, CHAN_VOICE, LEAP_SOUNDS[random_num(0, sizeof(LEAP_SOUNDS) - 1)], 1.0, ATTN_NORM);

	LongJump_CountDown[id] = 0.01;
	LongJump_LastTime[id] = NEXT_TIME_USE;
}

