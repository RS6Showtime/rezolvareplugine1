#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <dhudmessage> 

#define PLUGIN "IDEAL VIP by Ba/lePa"
#define VERSION "2.9"
#define AUTHOR "Ba/lePa"

#define VIP_TAG (1<<2)				// vip ? ???????
#define vip_flag ADMIN_LEVEL_H		// ???? ???????

#define music // ???? ???? ??? ????? ?????? ?? ?????, ?? ????????? // ????? #define


#define MAX_TEXT_LENGTH                200
#define MAX_NAME_LENGTH                40
new bool:gl_not_map

new g_Round, g_Weapon[33], g_vip 
new PlayerBomb[33] = false
new cvar_connect, cvar_red, cvar_green, cvar_blue, cvar_x, cvar_y;
new cvar_prefix
new cvar_round, cvar_open, cvar_show, cvar_chat, cvar_pistols, cvar_funk, cvar_tab
new cvar_health, cvar_health_head, cvar_health_max
new cvar_money, cvar_money_head
new cvar_music
new cvar_damage, cvar_hudsek

new vip_opened[33]
new maxplayers = 0
new SayText
new pistols[6] = {CSW_USP, CSW_GLOCK18, CSW_ELITE, CSW_FIVESEVEN, CSW_P228, CSW_DEAGLE}
new bool: g_chosen[33] = false;

new string[32]

new hud;
public plugin_precache()
{
	if(check_map())
	{
		gl_not_map = true
		return;
	}
	
	#if defined(music)
		precache_sound("IDEAL_VIP/ideal_sound.wav")
	#endif
}

public plugin_init()
{		
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	if(gl_not_map)
		return;
	
	register_dictionary("ideal_vip.txt")
	
	maxplayers = get_maxplayers();
	
	register_message( get_user_msgid( "ScoreAttrib" ), "msgScoreAttrib" )
	
	register_event("HLTV", "round_start", "a", "1=0", "2=0")
	register_event("TextMsg", "round_restart", "a", "2=#Game_will_restart_in","2=#Game_Commencing");
	
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "ham_damage")

	register_clcmd("say /vipmenu", "main_menu")
	register_clcmd("say_team /vipmenu", "main_menu")
	
	register_clcmd("say /vip_menu", "main_menu")
	register_clcmd("say_team /vip_menu", "main_menu")
	
	register_clcmd("vipmenu", "main_menu")
	
	register_clcmd("say /vips", "vip_online")
	register_clcmd("say_team /vips", "vip_online")
	
	register_clcmd("say /adminka", "admin_motd")
	register_clcmd("say_team /adminka", "admin_motd")
	
	register_clcmd("say /vipka", "vip_motd")
	register_clcmd("say_team /vipka", "vip_motd")
	
	
	cvar_round 			= 	register_cvar("amx_vipround", "2")
	cvar_open 			= 	register_cvar("amx_vipzaround", "0")
	cvar_show 			= 	register_cvar("amx_vipshow","1")
	cvar_chat 			= 	register_cvar("amx_chatshow", "1")
	cvar_pistols 		= 	register_cvar("amx_vipautopistols", "0")
	cvar_funk 			= 	register_cvar("amx_vipautoset", "1")
	cvar_health 		= 	register_cvar("amx_viphealth", "30")
	cvar_health_head 	= 	register_cvar("amx_viphealth_head", "60")
	cvar_health_max 	= 	register_cvar("amx_viphealth_max", "100")
	cvar_money 			= 	register_cvar("amx_vipmoney", "500")
	cvar_money_head 	= 	register_cvar("amx_vipmoney_head", "1000")
	cvar_tab			=	register_cvar("amx_viptab", "1")
	cvar_connect 		=	register_cvar("amx_showconnect", "2")
	cvar_red			=	register_cvar("amx_vipRED", "100")
	cvar_green			=	register_cvar("amx_vipGREEN", "100")
	cvar_blue			=	register_cvar("amx_vipBLUE", "100")
	cvar_x				=	register_cvar("amx_vipXcoord", "-1.0")
	cvar_y				=	register_cvar("amx_vipYcoord", "0.6")
	cvar_prefix			=	register_cvar("amx_vip_prefix", "!y[!gIDEAL VIP!y]");
	#if defined(music)
		cvar_music			=	register_cvar("amx_vipMusic", "1");
	#endif
	cvar_damage			=	register_cvar("amx_vipdamager", "1");
	cvar_hudsek			=	register_cvar("amx_viphudsek", "5.0");
	
	get_pcvar_string(cvar_prefix, string, charsmax(string))
	
	SayText = get_user_msgid("SayText")
	hud = CreateHudSyncObj();
}

public plugin_cfg()
{
	new configsdir[128]
	
	get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
	
	return server_cmd("exec %s/ideal_vip.cfg", configsdir);
}

public admin_motd(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_CONTINUE;
		
	show_motd(id, "adminka.txt", "??? ?????? ???????")
	
	return PLUGIN_CONTINUE;
}

public vip_motd(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_CONTINUE;
		
	show_motd(id, "vipka.txt", "??? ?????? ?????")
	
	return PLUGIN_CONTINUE; 
}

public client_putinserver(id)
{
	client_cmd(id, "bind ^"F5^" ^"vipmenu^"")
	g_Weapon[id] = 0;
	
	if(is_user_cool(id))
		set_task(0.5, "vip_connect", id + 132)
}

public vip_connect(TASKID)
{
	new id = TASKID - 132;
	
	#if defined(music)
		if(get_pcvar_num(cvar_music))
			client_cmd(0, "spk IDEAL_VIP/ideal_sound.wav");
	#endif
	
	new name[32];
	get_user_name(id, name, charsmax(name));
	
	switch(get_pcvar_num(cvar_connect))
	{
		case 1:
		{
			chat_color(0, "%L", id, "VIP_CONNECT", string, name)	
		}
		case 2:
		{
			set_hudmessage(get_pcvar_num(cvar_red), get_pcvar_num(cvar_green), get_pcvar_num(cvar_blue), get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, 0.0, 5.0, 0.0, 0.0, -1) 
			show_hudmessage(0, "%L", id, "VIP_CONNECT1", name)
		}
		case 3:
		{
			set_dhudmessage(get_pcvar_num(cvar_red), get_pcvar_num(cvar_green), get_pcvar_num(cvar_blue), get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, 0.0, 5.0, 0.0, 0.0, false) 
			show_dhudmessage(0, "%L", id, "VIP_CONNECT1", name)
		}
		case 4:
		{
			chat_color(0, "%L", id, "VIP_CONNECT", string,  name)
			
			set_hudmessage(get_pcvar_num(cvar_red), get_pcvar_num(cvar_green), get_pcvar_num(cvar_blue), get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, 0.0, 5.0, 0.0, 0.0, -1) 
			show_hudmessage(0, "%L", id, "VIP_CONNECT1", name)
		}
		case 5:
		{
			chat_color(0, "%L", id, "VIP_CONNECT", string,  name)
			
			set_dhudmessage(get_pcvar_num(cvar_red), get_pcvar_num(cvar_green), get_pcvar_num(cvar_blue), get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, 0.0, 5.0, 0.0, 0.0, false) 
			show_dhudmessage(0, "%L", id, "VIP_CONNECT1", name)				
		}
	}
}
	
public client_disconnect(id)
{
	g_Weapon[id] = 0;
	g_chosen[id] = false;
}
	
public round_start()	
	g_Round++	

public round_restart()
	g_Round = 0
	
public player_spawn(Player)
{
PlayerBomb[Player] = false
vip_opened[Player] = 0;
if(g_Round == 0)
first_menu(Player)
			
if(is_user_alive(Player))
{
if(get_pcvar_num(cvar_funk) == 1)
task_funk(Player);
if(get_pcvar_num(cvar_show) == 1 && g_Round >= get_pcvar_num(cvar_round))
main_menu(Player);
}
}


public task_funk(id)
{
	give_item(id, "weapon_knife")
	give_item(id, "item_thighpack") 
	give_item(id, "weapon_hegrenade")
	give_item(id, "weapon_flashbang")
	give_item(id, "weapon_flashbang")
	give_item(id, "weapon_smokegrenade")
	give_item(id, "item_assaultsuit")
	if(PlayerBomb[id])
	{
		fm_give_item(id, "weapon_c4");
		cs_set_user_plant(id);
		PlayerBomb[id] = false;
	}
	
	if(get_pcvar_num(cvar_pistols))
	{
		for(new i = 0; i < 6; i++)
			fm_strip_user_gun(id, pistols[i])
			
		switch(g_Weapon[id])
		{
			case 0:
			{
				first_menu(id);
			}
			case 1:
			{
				give_item(id, "weapon_deagle");
				cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			}
			case 2:
			{
				give_item(id, "weapon_usp");
				cs_set_user_bpammo(id, CSW_USP, 100)
			}
			case 3:
			{
				give_item(id, "weapon_glock18");
				cs_set_user_bpammo(id, CSW_GLOCK18, 120)
			}
		}
	}
}

public main_menu(id)
{
		if(is_user_alive(id))
		{
			if(vip_opened[id] < get_pcvar_num(cvar_open) || get_pcvar_num(cvar_open) == 0)
			{
				if(g_Round >= get_pcvar_num(cvar_round))
				{
					new s_Title[64], s_Name[32], s_Pistol[32], szMenuMulti[64]
					
					get_user_name(id, s_Name, charsmax(s_Name))
					
					switch(g_Weapon[id])
					{
						case 0: s_Pistol = "NONE";
						case 1: s_Pistol = "Deagle";
						case 2: s_Pistol = "Usp";
						case 3: s_Pistol = "Glock";
					}
					
					formatex(s_Title, charsmax(s_Title), "%L", id, "VIP_MENU", s_Name)		
					new i_Menu = menu_create(s_Title, "main_handler", 1); 
			
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU1", s_Pistol)
					menu_additem(i_Menu, szMenuMulti, "1", 0)
					
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU2", s_Pistol)
					menu_additem(i_Menu, szMenuMulti, "2", 0)
					
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU3", s_Pistol)
					menu_additem(i_Menu, szMenuMulti, "3", 0)
					
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU4", s_Pistol)
					menu_additem(i_Menu, szMenuMulti, "4", 0)
					
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU5", s_Pistol)
					menu_additem(i_Menu, szMenuMulti, "5", 0)
			
					menu_addblank(i_Menu, 0);
					
					formatex(szMenuMulti, charsmax(szMenuMulti), "%L", id, "ITEM_MENU6")
					menu_additem(i_Menu, szMenuMulti, "6", 0)
					
					menu_addblank(i_Menu, 1);

					menu_setprop(i_Menu, MPROP_EXITNAME, "?????")
					menu_display(id, i_Menu, 0)	
				}
				else
				{					
					if(get_pcvar_num(cvar_round) == 2)		
					{
						chat_color(id, "%L", id, "VIP_WARNING5", string, get_pcvar_num(cvar_round))
						return PLUGIN_HANDLED;
					}
					else
					{
						chat_color(id, "%L", id, "VIP_WARNING1", string, get_pcvar_num(cvar_round))
						return PLUGIN_HANDLED;
					}
				}
			}
			else
				chat_color(id, "%L", id, "VIP_WARNING2", string)
		}
		else
			chat_color(id, "%L", id, "VIP_WARNING3", string)
		
                return PLUGIN_HANDLED;
}

public main_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		
		return PLUGIN_HANDLED;
	}
	
	new s_Data[6], s_Name[60], i_Access, i_Callback
	
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback)
	
	new i_Key = str_to_num(s_Data)
	new name[32] 
	get_user_name(id, name, charsmax(name))
	
	
	switch(i_Key)
	{
		case 1:
		{
			vip_opened[id]++
			if(user_has_weapon(id, CSW_C4))
				PlayerBomb[id] = true
				
			strip_user_weapons(id)
			task_funk(id)
			switch(g_Weapon[id])
			{
				case 0:
				{
					first_menu(id);
				}				
				case 1:
				{
					give_item(id, "weapon_deagle")
					cs_set_user_bpammo(id, CSW_DEAGLE, 35)
				}
				case 2:
				{	
					give_item(id, "weapon_usp")
					cs_set_user_bpammo(id, CSW_USP, 100)
				}
				case 3:
				{
					give_item(id, "weapon_glock18")
					cs_set_user_bpammo(id, CSW_GLOCK18, 120)
				}
			}
			
			give_item(id, "weapon_m4a1")
			cs_set_user_bpammo(id, CSW_M4A1, 90)
			
			if(get_pcvar_num(cvar_chat) == 1)
				chat_color(0, "%L", id, "VIP_M4A1", string, name)			
		}
		case 2:
		{
			vip_opened[id]++
			if(user_has_weapon(id, CSW_C4))
				PlayerBomb[id] = true
			strip_user_weapons(id)
			task_funk(id)
			
			switch(g_Weapon[id])
			{
				case 0:
				{
					first_menu(id);
				}				
				case 1:
				{
					give_item(id, "weapon_deagle")
					cs_set_user_bpammo(id, CSW_DEAGLE, 35)
				}
				case 2:
				{	
					give_item(id, "weapon_usp")
					cs_set_user_bpammo(id, CSW_USP, 100)
				}
				case 3:
				{
					give_item(id, "weapon_glock18")
					cs_set_user_bpammo(id, CSW_GLOCK18, 120)
				}
			}
			
			give_item(id, "weapon_ak47")
			cs_set_user_bpammo(id, CSW_AK47, 90)
			
			if(get_pcvar_num(cvar_chat) == 1)
				chat_color(0, "%L", id, "VIP_AK47", string, name)
			
		}
		case 3:
		{
			vip_opened[id]++
			if(user_has_weapon(id, CSW_C4))
				PlayerBomb[id] = true
			strip_user_weapons(id)
			task_funk(id)
			
			switch(g_Weapon[id])
			{
				case 0:
				{
					first_menu(id);
				}				
				case 1:
				{
					give_item(id, "weapon_deagle")
					cs_set_user_bpammo(id, CSW_DEAGLE, 35)
				}
				case 2:
				{	
					give_item(id, "weapon_usp")
					cs_set_user_bpammo(id, CSW_USP, 100)
				}
				case 3:
				{
					give_item(id, "weapon_glock18")
					cs_set_user_bpammo(id, CSW_GLOCK18, 120)
				}
			}
			
			give_item(id, "weapon_awp")
			cs_set_user_bpammo(id, CSW_AWP, 30)
			
			if(get_pcvar_num(cvar_chat) == 1)
				chat_color(0, "%L", id, "VIP_AWP", string, name)
			
			
		}
		case 4:
		{
			vip_opened[id]++
			if(user_has_weapon(id, CSW_C4))
				PlayerBomb[id] = true
			strip_user_weapons(id)
			task_funk(id)
			
			switch(g_Weapon[id])
			{
				case 0:
				{
					first_menu(id);
				}				
				case 1:
				{
					give_item(id, "weapon_deagle")
					cs_set_user_bpammo(id, CSW_DEAGLE, 35)
				}
				case 2:
				{	
					give_item(id, "weapon_usp")
					cs_set_user_bpammo(id, CSW_USP, 100)
				}
				case 3:
				{
					give_item(id, "weapon_glock18")
					cs_set_user_bpammo(id, CSW_GLOCK18, 120)
				}
			}
			
			give_item(id, "weapon_famas")
			cs_set_user_bpammo(id, CSW_FAMAS, 90)
			
			if(get_pcvar_num(cvar_chat) == 1)
				chat_color(0, "%L", id, "VIP_FAMAS", string, name)		
		}
		case 5:
		{
			vip_opened[id]++
			if(user_has_weapon(id, CSW_C4))
				PlayerBomb[id] = true
			strip_user_weapons(id)
			task_funk(id)
			
			switch(g_Weapon[id])
			{
				case 0:
				{
					first_menu(id);
				}				
				case 1:
				{
					give_item(id, "weapon_deagle")
					cs_set_user_bpammo(id, CSW_DEAGLE, 35)
				}
				case 2:
				{	
					give_item(id, "weapon_usp")
					cs_set_user_bpammo(id, CSW_USP, 100)
				}
				case 3:
				{
					give_item(id, "weapon_glock18")
					cs_set_user_bpammo(id, CSW_GLOCK18, 120)
				}
			}
			
			give_item(id, "weapon_scout")
			cs_set_user_bpammo(id, CSW_SCOUT, 90)
			
			if(get_pcvar_num(cvar_chat) == 1)
				chat_color(0, "%L", id, "VIP_SCOUT", string, name)			
		}		
		case 6:
		{
			first_menu(id);
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public first_menu(id)
{
	if(!is_user_connected(id))
		return;
		
	new i_Menu = menu_create("\r??? ?? ??????????????", "first_menu_handler")

	menu_additem(i_Menu, "\yDeagle", "1", 0)
	menu_additem(i_Menu, "\yGlock", "2", 0)
	menu_additem(i_Menu, "\rUsp", "3", 0)
	
	
	menu_setprop(i_Menu, MPROP_EXITNAME, "?????")
	menu_display(id, i_Menu, 0)
}

public first_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)		
		return PLUGIN_HANDLED
	}
	
	new s_Data[6], s_Name[60], i_Access, i_Callback
	
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback)
	
	new i_Key = str_to_num(s_Data)
	
	for(new i = 0; i < 6; i++)
		fm_strip_user_gun(id, pistols[i])
	
	switch(i_Key)
	{
		case 1:
		{
			g_chosen[id] = true;
			g_Weapon[id] = 1;
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
		}
		case 2: 
		{
			g_chosen[id] = true;
			g_Weapon[id] = 3;
			give_item(id, "weapon_glock18")
			cs_set_user_bpammo(id, CSW_GLOCK18, 120)
		}
		case 3:
		{
			g_chosen[id] = true;
			g_Weapon[id] = 2;
			give_item(id, "weapon_usp")
			cs_set_user_bpammo(id, CSW_USP, 100)
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public msgScoreAttrib(const MsgId, const MsgType, const MsgDest) 
{
	if(get_pcvar_num(cvar_tab))
	{
		if(is_user_cool(get_msg_arg_int(1)) && !get_msg_arg_int(2))
			set_msg_arg_int(2, ARG_BYTE, VIP_TAG)
	}
}

public vip_online(id)
{
	g_vip = 0;
	
	new Len, message[512], name[32]
	new Player

	for(Player = 1; Player <= maxplayers; Player++)
	{
		if(is_user_cool(Player))
		{
			g_vip++
			get_user_name(Player, name, charsmax(name))
			if(g_vip == 1)
				Len += format(message[Len], 511 - Len, "%s", name)
			else
				Len += format(message[Len], 511 - Len, " , %s", name)
		}
	}
	if(g_vip < 1)
		chat_color(id, "%L", id, "VIP_ONLINE", string)
	else
		chat_color(id, "%s: !t%s", string, message)
}

public player_killed(victim, killer, corpse)
{
	static const m_LastHitGroup = 75
	
	if(is_user_cool(victim))
		if(!g_chosen[victim])
			set_task(1.0, "first_menu", victim)
			
	if(is_user_cool(killer))
	{
		if(is_user_alive(killer))
		{
			if( get_pdata_int( victim, m_LastHitGroup ) == HIT_HEAD)
			{
				set_user_health(killer, get_user_health(killer) + get_pcvar_num(cvar_health_head))
				if(get_user_health(killer) > get_pcvar_num(cvar_health_max))
					set_user_health(killer, get_pcvar_num(cvar_health_max))
				cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(cvar_money_head))
			}
			else
			{
				set_user_health(killer, get_user_health(killer) + get_pcvar_num(cvar_health))
				if(get_user_health(killer) > get_pcvar_num(cvar_health_max))
					set_user_health(killer, get_pcvar_num(cvar_health_max))
				cs_set_user_money(killer, cs_get_user_money(killer) + get_pcvar_num(cvar_money))
			}
		}
	}
}

public ham_damage(victim, weapon, killer, Float:fDamage, damagebits)
{
	if(get_pcvar_num(cvar_damage) == 0)
		return;
	
	if(victim == killer)
		return;
	
	if(!is_user_cool(killer) && !is_user_cool(victim))
		return;
		
	if(get_user_team(killer) == get_user_team(victim))
		return;
	
	new iDamage;
	iDamage = floatround(fDamage, floatround_floor)
	
	if(iDamage <= 0)
		return;
	
	if(is_user_cool(victim))
	{
		set_hudmessage(255, 0, 0, 0.6, 0.5, 0, 0.0, get_pcvar_float(cvar_hudsek), 0.0, 0.0, 1) 
		ShowSyncHudMsg(victim, hud, "%d", iDamage);
	}
	if(is_user_cool(killer))
	{
		set_hudmessage(0, 100, 255, 0.4, 0.5, 0, 0.0, get_pcvar_float(cvar_hudsek), 0.0, 0.0, 2) 
		ShowSyncHudMsg(killer, hud, "%d", iDamage);
	}
}

stock chat_color(const id, const input[], any:...)
{
	new count = 1, players[32]; 
	static msg[191]; 
	vformat(msg, 190, input, 3); 
	replace_all(msg, 190, "!g", "^4"); // Green Color 
	replace_all(msg, 190, "!y", "^1"); // Default Color 
	replace_all(msg, 190, "!t", "^3"); // Team Color 
	if (id) players[0] = id; else get_players(players, count, "ch"); 
	{
		for ( new i = 0; i < count; i++ ) 
		{ 
			if ( is_user_connected(players[i]) ) 
			{
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i]); 
				write_byte(players[i]); 
				write_string(msg); 
				message_end(); 
			} 
		} 
	} 
}

stock bool: is_user_cool(const id)
{
	if(!is_user_connected(id))
		return false;
	
	if((get_user_flags(id) & vip_flag))
		return true;
		
	return false;
}

check_map()
{
	new got_line, line_num, len
	new cfgdir[MAX_TEXT_LENGTH]
	new cfgpath[MAX_TEXT_LENGTH]
	new mapname[MAX_NAME_LENGTH]
	new txt[MAX_TEXT_LENGTH]

	get_localinfo("amxx_configsdir", cfgdir, charsmax(cfgdir))
	get_mapname(mapname, MAX_NAME_LENGTH-1)

	format(cfgpath, MAX_TEXT_LENGTH, "%s/ideal_block_maps.ini", cfgdir)

	if (file_exists(cfgpath))
	{
		got_line = read_file(cfgpath, line_num, txt, MAX_TEXT_LENGTH-1, len)
		while (got_line>0)
		{
			if (equali(txt, mapname)) return 1
			line_num++
			got_line = read_file(cfgpath, line_num, txt, MAX_TEXT_LENGTH-1, len)
		}
	}
	return 0
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
