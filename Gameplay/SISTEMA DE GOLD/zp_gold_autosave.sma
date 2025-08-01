#include <amxmodx> 
#include <fvault> 
#include <Gold> 
#include <tx_config>

#pragma compress 1

new bool:user_logged[33]; new userLogin[32];

#define PLUGIN "[ZP] Gold AutoSave" 
#define VERSION "1.0" 
#define AUTHOR "ShaDoW | Teixeira"

new const g_vault_name[] = "GoldBank"
new g_maxplayers

#define user_logged_real(%1) (!is_user_hltv(%1) && !is_user_bot(%1) && is_user_connected(%1))

public plugin_init() 
{ 
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_maxplayers = get_maxplayers()
}

public client_disconnected(id) 
{   
	if(user_logged[id])
	{ 
		SaveGold(id);
		user_logged[id] = false;
		zp_set_user_gold(id, 0);
	} 
}

public zp_round_ended()
{
	for(new id = 1; id <= g_maxplayers; id++) 
	{ 
		if(user_logged[id]) SaveGold(id);
	} 
}

public plugin_end() 
{ 
	for(new id = 1; id <= g_maxplayers; id++) 
	{ 
		if(user_logged[id]) SaveGold(id);
	} 
} 

public sr_user_logout_post(id) 
{
	if(user_logged[id])
	{ 
		SaveGold(id);
		user_logged[id] = false;
		zp_set_user_gold(id, 0);
	}
}

public sr_user_logged_post(id)
{
	user_logged[id] = true;

	sr_get_user_account(id, userLogin, charsmax(userLogin));
	
	new gdata[256]; 
	if(fvault_get_data(g_vault_name, userLogin, gdata, charsmax(gdata)))
	zp_set_user_gold(id, str_to_num(gdata)) // loaded Gold

	else 
	zp_set_user_gold(id, 0) // default start.
}

stock SaveGold(id) 
{ 
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		if(user_logged[id])
		{
			sr_get_user_account(id, userLogin, charsmax(userLogin));
			
			new gdata[256];
			
			num_to_str(zp_get_user_gold(id), gdata, charsmax(gdata));
			fvault_set_data(g_vault_name, userLogin, gdata);
		}
	}
}
