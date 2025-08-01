#include <amxmodx>

#define NAME "[ANTI WEARING]"
#define VERSION "BETA"
#define AUTHOR "Teixeira"

new aviso_p[33];

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)
	register_dictionary("antiwearing.txt")
	register_clcmd("say", "CmdSayX");
	register_clcmd("say_team", "CmdSayX");
}

new const xingamentos[][] = {
	"macaco", "filho da puta", "filha da puta", "seu macaco", "seu filho da puta", "sua filha da puta", "sua mãe aquela vagabunda",
	"monkey", "son of a bitch", "motherfucker", "your monkey", "you son of a bitch", "you daughter of a bitch", "your mother is that slut",
	"mono", "Hijo de puta", "hijo de puta", "tu mono", "tu hijo de puta", "tu hija de puta", "tu madre es esa puta"
};

public CmdSayX(id) 
{  
	new szMessage[200]; read_args(szMessage, charsmax(szMessage)); remove_quotes(szMessage);
	new szName[50]; get_user_name(id, szName, charsmax(szName));

	new i;
	for(i = 0; i < sizeof xingamentos; i++) 
	if(equali(szMessage, xingamentos[i]))
	{
		aviso_p[id]++;
		client_print_color(id, print_team_default, "%L", id, "WEARING", aviso_p[id])
	}
	if(aviso_p[id] == 3)
	{
		server_cmd("amx_addban #%i ^"-1^" ^"Mais respeito^"", get_user_userid(id));
		aviso_p[id] = 0;

		client_print(id, print_console, "[X]--------------[Anti Swearing By: Teixeira]-----------------------------------[X]")
		client_print(id, print_console, "[X]---> Nick: %s", szName)
		client_print(id, print_console, "[X]---> Motivo: Desrespeito com outros membros ou racismo")
		client_print(id, print_console, "[X]---> Tempo Restante: Permanente")
		client_print(id, print_console, "[X]---> Nick do Adm: NIGHT DARKNESS")
		client_print(id, print_console, "[X]---> Cargo do Adm: O BRABO")
		client_print(id, print_console, "[X] Caso o ban tenha sido abuso denuncie no discord: https://discord.gg/rWcyPfXpEc")
		client_print(id, print_console, "[X]---------------------------------------------------------------------------------------[X]")


		client_print(0, print_console, "[X]--------------[Anti Swearing By: Teixeira]-----------------------------------[X]")
		client_print(0, print_console, "[X]---> Nick: %s", szName)
		client_print(0, print_console, "[X]---> Motivo: Desrespeito com outros membros ou racismo")
		client_print(0, print_console, "[X]---> Tempo Restante: Permanente")
		client_print(0, print_console, "[X]---> Nick do Adm: NIGHT DARKNESS")
		client_print(0, print_console, "[X]---> Cargo do Adm: O BRABO")
		client_print(0, print_console, "[X]---------------------------------------------------------------------------------------[X]")

		server_cmd("kick #%i ^"Voce esta Banido deste servidor, Verifique seu console!^"", get_user_userid(id));
	}
}