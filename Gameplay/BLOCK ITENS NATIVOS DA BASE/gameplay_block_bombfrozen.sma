#include <amxmodx>
#include <fakemeta>
#include <zombie_plague_special>

new pl_current[55]
new cvar_limit;

new gMaxPlayer
public plugin_init()
{
	register_plugin("[ZP] Block Bomb Frozen", "1.0", "Teixeira | Hard");
	register_logevent("round_End", 2, "1=Round_End")
	cvar_limit = register_cvar("limit", "5");
	
	gMaxPlayer = get_maxplayers()
}

public client_putinserver(id)
{
	pl_current[id] = 0;
}

public zp_extra_item_selected_pre(player, itemid) 
{
	new iIndex = zp_get_extra_item_id("Frost Grenade");
	if(itemid != iIndex) return PLUGIN_CONTINUE;

	zp_extra_item_textadd(fmt("\y[LMT:%d/%d]", pl_current[player], get_pcvar_num(cvar_limit)));

	if(pl_current[player] >= get_pcvar_num(cvar_limit))
		return ZP_PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE;
}

public zp_extra_item_selected(player, itemid)
{
	new iIndex = zp_get_extra_item_id("Frost Grenade");
	if (itemid != iIndex) 
		return;

	pl_current[player]++
}

public round_End() 
{
	for (new id = 1; id <= gMaxPlayer; id++) 
		pl_current[id] = 0;
}
