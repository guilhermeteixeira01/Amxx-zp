#include <amxmodx>
#include <fakemeta>
#include <zombie_plague_special>


#define CLASS_ACESS ADMIN_RCON

new const hclass1_name[] = { "Dono" }
new const hclass1_info[] = { "\rKit \yFundador" }
const hclass1_health = 350 // 0 - For use default health (Cvar: zp_human_health)
const hclass1_armor = 200
const hclass1_speed = 220 // 0 - For use default speed (Cvar: zp_human_speed)
const Float:hclass1_gravity = 0.0 // 0 - For default gravity (Cvar: zp_human_gravity)

new g_classedonoID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human Dono", "1.0", "TEIXEIRA")
	g_classedonoID = zp_register_human_class(hclass1_name, hclass1_info, hclass1_health, hclass1_armor, hclass1_speed, hclass1_gravity)
}

public client_putinserver(id)
{
	if(get_user_flags(id) & CLASS_ACESS)
		zp_set_user_human_class(id, g_classedonoID)
}

public client_connect(id)
{
	if(get_user_flags(id) & CLASS_ACESS)
		g_classedonoID = true;
}
// no lugar do ZP_CLASS_AVAILABLE usa o PLUGIN_CONTINUE
// no lugar do ZP_CLASS_NOT_AVAILABLE usa o ZP_PLUGIN_HANDLED
// no lugar do ZP_CLASS_DONT_SHOW usa o ZP_PLUGIN_SUPERCEDE
public zp_human_class_choosed_pre(id, classid) {
	if(g_classedonoID != classid)
		return PLUGIN_CONTINUE;

	//zp_menu_textadd("\r[Fundador]"); // Adiciona um textin igual no 5.0
	if(!(get_user_flags(id) & CLASS_ACESS))
		return ZP_PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

// Essa função executa apos o cara pegar as armas selecionadas no M1
public zp_weapon_selected_post(id, wpn_type)
{
	if(wpn_type != WPN_SECONDARY || !is_user_alive(id))
		return;

	if(zp_get_next_human_class(id) != g_classedonoID || zp_get_user_zombie(id) || zp_get_human_special_class(id))
		return;

	zp_give_item(id, "weapon_g3sg1", 1)
	zp_give_item(id, "weapon_hegrenade")
	zp_give_item(id, "weapon_flashbang")
	zp_give_item(id, "weapon_flashbang")
	zp_give_item(id, "weapon_smokegrenade")
}