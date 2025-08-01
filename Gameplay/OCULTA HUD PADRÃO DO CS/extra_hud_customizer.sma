#pragma semicolon 1
#include <amxmodx>
#include <reapi>
#pragma compress 1

public plugin_init()
{
	register_plugin("[REAPI] Hud customizer", "1.0", "Teixeira");
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
}

@CBasePlayer_Spawn_Post(const id)
{
	if(task_exists(id)) remove_task(id);
	set_task(0.5, "@set_all", id);
}

@set_all(const id)
{
	if (!is_user_connected(id))
		return;

	set_member(id, m_iHideHUD,
	get_member(id, m_iHideHUD) | HIDEHUD_HEALTH | HIDEHUD_MONEY);
}