#include < amxmodx >
#include < engine >
#include < zombie_plague_special >

new const zclass_name[ ] = "Illusion Zombie"
new const zclass_info[ ] = "faz ilusão [G]"
new const zclass_model[ ] = "NDK_ZM_ILUSION"
new const zclass_clawmodel[ ] = "v_knife_NDK_ZM_ILUSION.mdl"
const zclass_health = 1337
const zclass_speed = 200
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 0.5

// Models
new const dummy_model[ ] = "models/player/NDK_ZM_ILUSION/NDK_ZM_ILUSION.mdl"

new g_zclass_dummy, gCvarDummyShouldDie, gCvarDummyHealth, gCvarDummyAnimation, gCvarDummyLimit, gCvarPlayerOrigin

new gCounter[ 33 ]

public plugin_init( ) 
{
	register_plugin( "[ZP] Zombie Class: Dummy Zombie", "1.1", "007 & Twilight Suzuka & 01101101" )
	
	register_think( "npc_dummy","npc_think" )
	
	register_event( "HLTV", "event_new_round", "a", "1=0", "2=0" )
	register_clcmd("drop", "create_dummy")
	
	gCvarDummyShouldDie = register_cvar( "zp_dummy_should_die", "1" ) // ( 0 : Dummy will not die | 1: Dummy will die ) Default: 1
	gCvarDummyHealth = register_cvar( "zp_dummy_health", "1000" ) // Dummy's health Default: 100
	gCvarDummyAnimation = register_cvar( "zp_dummy_animation", "1" ) // ( 0 : Dummy floating animation | 1: Dummy standing animation ) Default: 1
	gCvarDummyLimit = register_cvar( "zp_dummy_spawn_limit", "3" ) // Amount of dummy he can spawn when he gets infected
	gCvarPlayerOrigin = register_cvar( "zp_dummy_player_origin", "1" ) // ( 0: X Axis | 1: Y Axis | 2: Z Axis )
}

public plugin_precache( )
{
	g_zclass_dummy = zp_register_zombie_class( zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback )
	precache_model(dummy_model)
}

public event_new_round( )
{
	new ent = -1
	while( ( ent = find_ent_by_class( ent, "npc_dummy" ) ) )
	{
		remove_entity( ent )
	}
}

public zp_user_infected_post( id, infector )
{
	if( zp_get_user_zombie_class( id ) == g_zclass_dummy && !zp_get_user_nemesis( id ) )
	{
		gCounter[ id ] = 0
		client_print_color(id, print_team_default, "^4[ZP]^1 Pressione^4 ^"G^"^1 botão para construir um clone!" )
	}
}

public create_dummy( id )
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_zombie_special_class(id)) return PLUGIN_CONTINUE

	if(!is_user_alive( id ) || zp_get_user_zombie_class( id ) != g_zclass_dummy)
		return PLUGIN_HANDLED

	if( gCounter[ id ] >= get_pcvar_num( gCvarDummyLimit ) )
	{
		client_print_color(id, print_team_default, "^4[ZP]^1 Você atingiu o limite!" )
		return PLUGIN_HANDLED
	}
	
	new Float:origin[ 3 ]
	
	entity_get_vector( id, EV_VEC_origin,origin )
	
	new ent = create_entity( "info_target" )
	
	entity_set_origin( ent, origin )
	origin[ get_pcvar_num( gCvarPlayerOrigin ) ] += 50.0
	entity_set_origin( id,origin )
	
	entity_set_float( ent, EV_FL_takedamage, get_pcvar_float( gCvarDummyShouldDie ) )
	entity_set_float( ent, EV_FL_health, get_pcvar_float( gCvarDummyHealth ) )
	
	entity_set_string( ent, EV_SZ_classname, "npc_dummy" )
	entity_set_model( ent, dummy_model )
	entity_set_int( ent, EV_INT_solid, 2 )
	
	entity_set_byte( ent, EV_BYTE_controller1, 125 )
	entity_set_byte( ent, EV_BYTE_controller2, 125 )
	entity_set_byte( ent, EV_BYTE_controller3, 125 )
	entity_set_byte( ent, EV_BYTE_controller4, 125 )
	
	new Float:maxs[ 3 ] = { 16.0, 16.0, 36.0 }
	new Float:mins[ 3 ] = { -16.0, -16.0, -36.0 }
	
	entity_set_size( ent, mins, maxs )
	
	entity_set_float( ent, EV_FL_animtime, 2.0 )
	entity_set_float( ent, EV_FL_framerate, 1.0 )
	entity_set_int( ent, EV_INT_sequence, get_pcvar_num( gCvarDummyAnimation ) )
	
	entity_set_float( ent,EV_FL_nextthink, halflife_time( ) + 0.01 )
	
	drop_to_floor( ent )
	
	gCounter[ id ] ++
	client_print_color(id, print_team_default, "^4[ZP]^1 Você usou^4 %d / %d^1 Clones.", gCounter[ id ], get_pcvar_num( gCvarDummyLimit ) )
	return 1
}

public npc_think( id )
{
	entity_set_float( id, EV_FL_nextthink, halflife_time( ) + 0.01 )
}