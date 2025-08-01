#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <Gold>
#include <zombie_plague_special>

#define PLUGIN  "[ZP] Drop Fix palhaco"
#define VERSION "1.0"
#define AUTHOR  "Teixeira"

#define JOKER_CLASSNAME "palhacindocrime"
#define JOKER_SOUNDPICK "zombie_plague/palhaco.wav"
#define JOKER_MODEL "models/palhaco.mdl"

new xMsgIdScreenFade, xCvarRemoveNewRound, cvar_giveammo, cvar_givegold, allow_dropex;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary("palhaco.txt")

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_touch(JOKER_CLASSNAME, "player", "fw_JokerTouch")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", true)

	xMsgIdScreenFade = get_user_msgid("ScreenFade")

	cvar_giveammo = register_cvar("zp_palhaco_ap", "2")
	cvar_givegold = register_cvar("zp_palhaco_gl", "2")
	xCvarRemoveNewRound = register_cvar("joker_remove_new_round", "1")
}

public plugin_precache()
{
	precache_model(JOKER_MODEL)
	precache_sound(JOKER_SOUNDPICK)
}

public Event_NewRound()
{
	if(get_pcvar_num(xCvarRemoveNewRound))
		remove_entity_name(JOKER_CLASSNAME)
}


public fw_PlayerKilled_Post(Victim, Attacker)
{
	if(zp_get_user_zombie(Victim) || zp_get_zombie_special_class(Victim) || !zp_get_user_zombie(Victim))
	{
		static Float:Origin[3]
		pev(Victim, pev_origin, Origin)

		xCreateJoker(Origin)
	}
}

public zp_round_started(gamemode){
	if(gamemode == MODE_INFECTION || gamemode == MODE_MULTI)
		allow_dropex = true
	else 
		allow_dropex = false
}


public fw_JokerTouch(Ent, id)
{
	if(!pev_valid(Ent))
		return PLUGIN_HANDLED;

	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
		
	message_begin(MSG_ONE_UNRELIABLE, xMsgIdScreenFade, _, id)
	write_short((1<<12) * 1) // duration
	write_short(0) // hold time
	write_short(0x0000) // fade type
	write_byte(127) // red
	write_byte(255) // green
	write_byte(127) // blue
	write_byte(50) // alpha
	message_end()
	
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + get_pcvar_num(cvar_giveammo))
	zp_set_user_gold(id, zp_get_user_gold(id) + get_pcvar_num(cvar_givegold))
	client_print_color(id, print_team_default, "%L", id, "PEGOU")
	emit_sound(Ent, CHAN_ITEM, JOKER_SOUNDPICK, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)			
	
	if(allow_dropex)
	{
		new i = random_num(0, 200);
		switch(i) {
			case 0..10: {
			
			} case 11..18: {
				
			} case 19..25: {
				
			} case 26..28: {
				
			} case 29..30:{
				
			} case 31..40: {
				
			} case 41..45: {
				
			} case 46..48: {
				
			} case 49..50: {
				if(!zp_get_zombie_special_class(id) || !zp_get_human_special_class(id))
				{
					if(zp_get_user_zombie(id))
					{
						zp_set_user_madness(id, 1, -1.0)
						client_print_color(id, print_team_default, "%L", id, "MADNESS")
					}
				}
			} case 51..52: {
				
			} case 53..60: {
				
			} case 61..62: {
				
			} case 63..70: {
				
			} case 71..75: {
				
			} case 76..78: {
				
			} case 79..94: {
				
			} case 95..96: {
				
			} case 97..98: {
				
			} case 99..100: {
			
			} case 101..110: {
				if(!zp_get_zombie_special_class(id) || !zp_get_human_special_class(id))
				{
					if(zp_get_user_zombie(id))
					{
						zp_set_user_madness(id, 1, -1.0)
						client_print_color(id, print_team_default, "%L", id, "MADNESS")
					}
				}
			} case 111..118: {
				
			} case 119..125: {
				
			} case 126..128: {
				
			} case 129..130:{
				
			} case 131..140: {
				
			} case 141..145: {
				
			} case 146..148: {
				
			} case 149..150: {
			
			} case 151..152: {
				
			} case 153..160: {
				
			} case 161..162: {
				
			} case 163..170: {
				
			} case 171..175: {
				
			} case 176..178: {
		
			} case 179..194: {
				
			} case 195..196: {
				if(!zp_get_zombie_special_class(id) || !zp_get_human_special_class(id))
				{
					if(zp_get_user_zombie(id)) 
					{
						zp_disinfect_user(id, 0, 0)
						client_print_color(id, print_team_default, "%L", id, "DISINFECT")
					}
				}
			} case 197..198: {
				
			} case 199..200: {
			
			}
		}
	}
	set_pev(Ent, pev_flags, FL_KILLME)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
	return PLUGIN_HANDLED;
}

public xCreateJoker(Float:Origin[3])
{
	static Ent
	Ent = create_entity("info_target")
		
	set_pev(Ent, pev_classname, JOKER_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, JOKER_MODEL)

	engfunc(EngFunc_SetSize, Ent, Float:{-16.0,-16.0,0.0}, Float:{16.0,16.0,16.0})
	
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_movetype, MOVETYPE_TOSS)

	static Float:Ori[3]; Ori = Origin; Ori[2] += 8.0
	engfunc(EngFunc_SetOrigin, Ent, Ori)
	
	fm_set_rendering(Ent, kRenderFxGlowShell, random_num(0, 255), random_num(0, 255), random_num(0, 255), kRenderNormal, 0)
	set_pev(Ent, pev_light_level, 255)
	
	set_pev(Ent, pev_animtime, get_gametime())
	set_pev(Ent, pev_framerate, 1.0)
	set_pev(Ent, pev_sequence, 0)
	return Ent
}