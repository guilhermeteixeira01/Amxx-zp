#include <amxmodx>

#define PLUGIN  "[ZP] Auto Desbug"
#define VERSION "1.2"
#define AUTHOR  "Teixeira"

new xCvarTimeDebug

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	xCvarTimeDebug = register_cvar( "csr_ad_time_desbug", "60")
	set_task(float(get_pcvar_num(xCvarTimeDebug)), "xAutoDesbug", _, _, _, "b")
}

public xAutoDesbug()
{
	if(get_playersnum(1) < 2)
		return
	
	server_cmd("sv_timeout 1;wait;wait;wait;wait;wait;wait;wait;wait;wait;sv_timeout 60")
	server_exec()
}

