/*===============================================================================
---> Includes
=================================================================================*/
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <Gold>
#include <zombie_plague_special>

/*===============================================================================
---> Variable/Defines/Enums/Consts
=================================================================================*/
#define MAX_TEXT_BUFFER_SIZE 65

#define CHAT_PREFIX "^4[GOLD]^1"
#define MENU_TAG "\r[\yGOLD\r]\w"

#pragma compress 1

enum _:items {
	i_name[MAX_TEXT_BUFFER_SIZE], 
	i_description[MAX_TEXT_BUFFER_SIZE], 
	i_cost, 
	i_team
}
enum {
	ITEMS_SELECTED_PRE, 
	ITEMS_SELECTED_POST, 
	MAX_FORWARDS_NUM
}

new g_forward_return, g_forwards[MAX_FORWARDS_NUM], g_team[33], g_AdditionalMenuText[32], Gold[33]
new extra_items[items], Array:items_database, g_registered_items_count, g_itemid


/*===============================================================================
---> Registro do Plugin
=================================================================================*/
public plugin_init() {
	register_plugin("[ZP] Addon: Gold System", "1.2", "Teixeira")

	register_clcmd("say gm", "gold_menu")
	register_clcmd("say /gm", "gold_menu")
	register_clcmd("say .gm", "gold_menu")
	register_clcmd("say_team sm", "gold_menu")
	register_clcmd("say_team /gm", "gold_menu")
	register_clcmd("say_team .gm", "gold_menu")

	g_forwards[ITEMS_SELECTED_PRE] = CreateMultiForward("zp_golden_item_selected_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_forwards[ITEMS_SELECTED_POST] = CreateMultiForward("zp_golden_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
	//teixeira_is_valid_server_ip();
}

/*===============================================================================
---> Natives
=================================================================================*/
public plugin_natives() {
	register_native("zp_get_user_gold", "native_get_user_gold", 1)
	register_native("zp_set_user_gold", "native_set_user_gold", 1)
	register_native("zp_reset_user_gold", "native_reset_user_gold", 1)
	register_native("zp_set_user_ultimate_gold", "native_set_user_ultimate_gold", 1)
	register_native("zp_register_golden_item", "native_register_golden_item")
	register_native("zp_golden_item_textadd", "native_extra_item_textadd")
}

public native_register_golden_item(plugin_id, param_nums) {
	if(!items_database) 
		items_database = ArrayCreate(items);

	get_string(1, extra_items[i_name], MAX_TEXT_BUFFER_SIZE-1);
	get_string(2, extra_items[i_description], MAX_TEXT_BUFFER_SIZE-1);
	extra_items[i_cost] = get_param(3);
	extra_items[i_team] = get_param(4);
	ArrayPushArray(items_database, extra_items)
	g_registered_items_count++
	return (g_registered_items_count-1)
}

public native_extra_item_textadd(plugin_id, num_params) {
	static text[32]; get_string(1, text, charsmax(text))
	strcat(g_AdditionalMenuText, text, charsmax(g_AdditionalMenuText))
}

public native_get_user_gold(id)
{
	return Gold[id]
}

public native_set_user_gold(id, amount)
{
	Gold[id] = amount
}

public native_reset_user_gold(id)
{
	Gold[id] = 0
}

public native_set_user_ultimate_gold(id)
{
	Gold[id] = 999999999
}

public zp_golden_item_selected(id, itemid) if(itemid == g_itemid) gold_menu(id);

public plugin_end() if(items_database) ArrayDestroy(items_database);

/*===============================================================================
---> Gold Menu
=================================================================================*/
public gold_menu(id) {
	if(!is_user_alive(id)){
		return;
	}
	
	if(!g_registered_items_count || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
		client_print_color(id, print_team_default, "%s Menu de ^4Itens Extras Desativado^1 para sua classe!", CHAT_PREFIX)
		return;
	}
		
	new holder[400], menu, i, team_check, golds, check
	formatex(holder, charsmax(holder), "%s GOLD Menu:^nTeam: %s", MENU_TAG, zp_get_user_zombie(id) ? "\r[Zombie]" : "\y[Humano]")
	
	menu = menu_create(holder, "gold_menu_handler")
	golds = zp_get_user_gold(id)
	
	team_check |= zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN

	g_team[id] = team_check
	for(i=0; i < g_registered_items_count; i++) {
		g_AdditionalMenuText[0] = 0
		ArrayGetArray(items_database, i, extra_items)
		if(extra_items[i_team] != 0 && !(g_team[id] & extra_items[i_team]))
			continue;
	
		ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, i)
		if (g_forward_return >= ZP_PLUGIN_SUPERCEDE)
			continue;

		if(g_forward_return >= ZP_PLUGIN_HANDLED || !is_user_alive(id) || golds < extra_items[i_cost]) { 
			formatex(holder, charsmax(holder), "\d%s [%s] [%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
			menu_additem(menu, holder, fmt("%d", i), (1<<30))
		}
		else  {
			formatex(holder, charsmax(holder), "\w%s \r[%s] \y[%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
			menu_additem(menu, holder, fmt("%d", i), 0)
		}
		check++
		
	}
	if(check == 0) {
		client_print_color(id, print_team_default, "%s Menu de ^4Itens Extras Desativado^1 para sua classe", CHAT_PREFIX)
		return;
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_NEXTNAME, "Proximo")
	menu_setprop(menu, MPROP_BACKNAME, "Voltar")
	menu_setprop(menu, MPROP_EXITNAME, "Sair")
	menu_display(id, menu, 0)
}
 
public gold_menu_handler(id, menu, item) {
	if(item == MENU_EXIT || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64], item_id, golds, aaccess, callback, team_check
	menu_item_getinfo(menu, item, aaccess, data, charsmax(data), iName, charsmax(iName), callback)
	
	team_check |= zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN
	if(g_team[id] != team_check) {
		menu_destroy(menu)
		gold_menu(id)
		return PLUGIN_HANDLED;
	}
	
	item_id = str_to_num(data)
	ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, item_id)
	if (g_forward_return >= ZP_PLUGIN_HANDLED) 
		return PLUGIN_HANDLED;
	
	golds = zp_get_user_gold(id)
	ArrayGetArray(items_database, item_id, extra_items)
	if(golds >= extra_items[i_cost]) {
		ExecuteForward(g_forwards[ITEMS_SELECTED_POST], g_forward_return, id, item_id)
		if(g_forward_return < ZP_PLUGIN_HANDLED) zp_set_user_gold(id, golds - extra_items[i_cost]);
	}
	else client_print_color(id, print_team_default, "%s Voce Nao tem ^4Golds suficiente", CHAT_PREFIX)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}