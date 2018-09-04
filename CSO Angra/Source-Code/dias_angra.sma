#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>

#define PLUGIN "[Dias's Boss] ANGRA"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define ANGRA_MODEL "models/cso_angra/zbs_bossl_big06.mdl"
#define ANGRA_CLASSNAME "cso_angra"

#define READY_MUSIC "cso_angra/bg/Scenario_Ready.mp3"
#define FIGHT_MUSIC "cso_angra/bg/Scenario_Normal.mp3"

#define TASK_ANIM_LOOP 28000+2
#define TASK_TURNING 28000+3
#define TASK_WALKING 28000+4

#define ANGRA_HEALTH 2000.0

enum
{
	ANGRA_ANIM_DUMMY = 0,
	ANGRA_ANIM_APPEAR1,
	ANGRA_ANIM_APPEAR2,
	ANGRA_ANIM_APPEAR3,
	ANGRA_ANIM_IDLE,
	ANGRA_ANIM_WALK,
	ANGRA_ANIM_RUN,
	ANGRA_ANIM_ATTACK_QUAKE,
	ANGRA_ANIM_ATTACK_BITE,
	ANGRA_ANIM_ATTACK_WIND,
	ANGRA_ANIM_ATTACK_SWING,
	ANGRA_ANIM_ATTACK_TENTACLE1,
	ANGRA_ANIM_ATTACK_TENTACLE2,
	ANGRA_ANIM_ATTACK_POISON1,
	ANGRA_ANIM_ATTACK_POISON2,
	ANGRA_ANIM_ATTACK_FLY1_POISON1,
	ANGRA_ANIM_ATTACK_FLY1_POISON2,
	ANGRA_ANIM_ATTACK_FLY2_POISON1,
	ANGRA_ANIM_FLY1,
	ANGRA_ANIM_FLY2,
	ANGRA_ANIM_LAND1,
	ANGRA_ANIM_LAND2,
	ANGRA_ANIM_LAND3,
	ANGRA_ANIM_FLY2_2,
	ANGRA_ANIM_FLY_CHANGE1,
	ANGRA_ANIM_FLY_CHANGE2,
	ANGRA_ANIM_DEATH,
	ANGRA_ANIM_STUN1,
	ANGRA_ANIM_STUN2,
	ANGRA_ANIM_STUN3
}

enum
{
	ANGRA_STATE_IDLE = 0,
	ANGRA_STATE_WALK,
	ANGRA_STATE_ATTACK_QUAKE,
	ANGRA_STATE_ATTACK_BITE,
	ANGRA_STATE_ATTACK_SWING,
	ANGRA_STATE_ATTACK_TENTACLE1,
	ANGRA_STATE_ATTACK_TENTACLE2,
	ANGRA_STATE_FLYING_UP,
	ANGRA_STATE_IDLE_FLYING,
	ANGRA_STATE_LANDING_DOWN,
	ANGRA_STATE_ATTACK_LAND_POISON1,
	ANGRA_STATE_ATTACK_LAND_POISON2,
	ANGRA_STATE_ATTACK_FLY_POISON1,
	ANGRA_STATE_ATTACK_FLY_POISON2
}

// Start Scene
#define START_ORIGIN_X 1477.333251
#define START_ORIGIN_Y 374.952941
#define START_ORIGIN_Z 732.03125

#define START_ANGLES_X -2.933349 
#define START_ANGLES_Y -179.121093 
#define START_ANGLES_Z 0.000000

#define APPEAR1_TIME 8.0
#define APPEAR2_ANIM_LOOP_TIME 0.5

#define SOUND_APPEAR1 "cso_angra/angra_appear1.wav"
#define SOUND_APPEAR3 "cso_angra/angra_appear3.wav"

#define TASK_APPEAR 28000+10
// End Of "Start Scene"

// Quake Scene
#define TASK_DO_QUAKE 28000+50
#define SOUND_ATTACK_QUAKE "cso_angra/angra_zbs_attack_quake.wav"

#define QUAKE_DAMAGE random_float(2.0, 7.0)
#define QUAKE_DAMAGE_RADIUS 500.0

// Bite Scene
#define TASK_DO_BITE 28000+60
#define SOUND_ATTACK_BITE "cso_angra/angra_zbs_attack_bite.wav"

#define BITE_DAMAGE random_float(7.0, 17.0)

// Swing Scene
#define TASK_DO_SWING 28000+70
#define SOUND_ATTACK_SWING "cso_angra/zbs_attack_swing.wav"

#define SWING_DAMAGE random_float(10.0, 20.0)

// Tentacle Scene
#define TASK_DO_TENTACLE 28000+80
#define TASK_DO_TENTACLE_SOUND 28000+90
#define TASK_DO_CREATING_TENTACLE 28000+100
#define TASK_TENTACLE_GROW 28000+110

#define MAP_CENTER_X 0.0
#define MAP_CENTER_Y 0.0
#define MAP_CENTER_Z 100.0

#define SOUND_ATTACK_TENTACLE1 "cso_angra/angra_zbs_attack_tentacle1.wav"
#define SOUND_ATTACK_TENTACLE2 "cso_angra/angra_zbs_attack_tentacle2.wav"

#define TENTACEL_DAMAGE random_float(20.0, 40.0)

#define TENTACLE_MODEL "models/cso_angra/tentacle3.mdl"
#define EARTHHOLE_MODEL_BEGIN "models/cso_angra/ef_tentacle_sign.mdl"
#define EARTHHOLE_MODEL_END "models/cso_angra/ef_tentacle.mdl"

#define TENTACLE_CLASSNAME "tentacle"
#define EARTHHOLE_CLASSNAME "earthhole"
#define TENTACLE_MAX1 30
#define TENTACLE_MAX2 60

new g_Tentacle_Count

// Flying Up Scene
#define TASK_DO_FLYING_UP 28000+120

#define SOUND_FLYING_UP "cso_angra/angra_zbs_fly1.wav"
#define SOUND_FLYING "cso_angra/angra_zbs_fly2.wav"

// Landing Down Scene
#define TASK_DO_LANDING_DOWN 28000+130

#define SOUND_LANDED "cso_angra/angra_zbs_land3.wav"

// Poison Scene
#define TASK_DO_POISON 28000+140
#define TASK_DO_THROWING_POISON 28000+150
#define SOUND_DO_POISON "cso_angra/angra_zbs_poison1.wav"

#define POISON_SPR "sprites/cso_angra/ef_smoke_poison.spr"
#define POISON_CLASSNAME "poison"
#define POISON_DAMAGE random_float(1.0, 5.0)

new Float:g_Current_Angles2

// Other
#define UTIL_FixedUnsigned16(%1,%2)   (clamp(floatround(%1*%2), 0, 0xFFFF))

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new g_Angra_Ent, Angra_Modelindex, Float:Angra_Time_Idle
new g_Msg_ScreenShake, g_MaxPlayers

const pev_playable = pev_iuser1
const pev_state = pev_iuser2

new Test_ExpSprId

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	
	register_think(ANGRA_CLASSNAME, "fw_Angra_Think")
	register_think(POISON_CLASSNAME, "fw_Poison_Think")
	register_touch(POISON_CLASSNAME, "*", "fw_Poison_Touch")	
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()

	register_clcmd("say /get", "get_origin")
	register_clcmd("say /set", "set_origin")
	register_clcmd("say /start", "Start_Boss")
	
	register_clcmd("quake", "Angra_Do_Quake")
	register_clcmd("bite", "Angra_Do_Bite")
	register_clcmd("swing", "Angra_Do_Swing")
	register_clcmd("tentacle", "Angra_Do_Tentacle")
	register_clcmd("flying", "Angra_Do_FlyingUp")
	register_clcmd("land", "Angra_Do_LandingDown")
	register_clcmd("poison", "Angra_Do_Poison")
	register_clcmd("flypoison", "Angra_Do_FlyPoison")
	
	register_clcmd("set_health", "CMD_Health")
}

public CMD_Health(id)
{
	set_pev(id, pev_health, 150.0)
}

public plugin_precache()
{
	Angra_Modelindex = engfunc(EngFunc_PrecacheModel, ANGRA_MODEL)
	
	static TempString[128]
	engfunc(EngFunc_PrecacheSound, SOUND_APPEAR1)
	engfunc(EngFunc_PrecacheSound, SOUND_APPEAR3)
	
	formatex(TempString, sizeof(TempString), "sound/%s", READY_MUSIC)
	engfunc(EngFunc_PrecacheGeneric, TempString)
	formatex(TempString, sizeof(TempString), "sound/%s", FIGHT_MUSIC)
	engfunc(EngFunc_PrecacheGeneric, TempString)
	
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_QUAKE)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_BITE)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_SWING)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_TENTACLE1)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_TENTACLE2)
	
	engfunc(EngFunc_PrecacheModel, TENTACLE_MODEL)
	engfunc(EngFunc_PrecacheModel, EARTHHOLE_MODEL_BEGIN)
	engfunc(EngFunc_PrecacheModel, EARTHHOLE_MODEL_END)
	
	engfunc(EngFunc_PrecacheSound, SOUND_FLYING_UP)
	engfunc(EngFunc_PrecacheSound, SOUND_FLYING)
	engfunc(EngFunc_PrecacheSound, SOUND_LANDED)
	
	engfunc(EngFunc_PrecacheSound, SOUND_DO_POISON)
	engfunc(EngFunc_PrecacheModel, POISON_SPR)
	
	Test_ExpSprId = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
}

static Float:MyOrigin[3], Float:MyAngles[3]
public get_origin(id)
{
	static Float:Vector[3]
	
	pev(id, pev_origin, Vector)
	MyOrigin = Vector
	client_print(id, print_console, "Origin: %f %f %f", Vector[0], Vector[1], Vector[2])
	
	pev(id, pev_v_angle, Vector)
	MyAngles = Vector
	client_print(id, print_console, "Angles: %f %f %f", Vector[0], Vector[1], Vector[2])
}

public set_origin(id)
{
	if(!pev_valid(g_Angra_Ent))
		return
	
	set_pev(g_Angra_Ent, pev_origin, MyOrigin)
	set_pev(g_Angra_Ent, pev_angles, MyAngles)
}

public Event_NewRound()
{
	PlaySound(0, READY_MUSIC)
	client_print(0, print_chat, "Game is Starting...")
}

public Event_RoundStart()
{
	PlaySound(0, FIGHT_MUSIC)
	client_print(0, print_chat, "[CSO] ATTENTION. ANGRA IS COMING !!!")
	
	set_task(2.5, "Start_Boss")
}

public Start_Boss()
{
	if(pev_valid(g_Angra_Ent))
		engfunc(EngFunc_RemoveEntity, g_Angra_Ent)
	
	static Angra; Angra = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Angra)) return
	
	g_Angra_Ent = Angra
	
	static Float:Vector[3]
	
	// Set Origin & Angles
	Vector[0] = START_ORIGIN_X; Vector[1] = START_ORIGIN_Y; Vector[2] = START_ORIGIN_Z
	set_pev(Angra, pev_origin, Vector)
	Vector[0] = START_ANGLES_X; Vector[1] = START_ANGLES_Y; Vector[2] = START_ANGLES_Z
	set_pev(Angra, pev_angles, Vector)	
	
	// Set Config
	set_pev(Angra, pev_gamestate, 1)
	set_pev(Angra, pev_classname, ANGRA_CLASSNAME)
	engfunc(EngFunc_SetModel, Angra, ANGRA_MODEL)
	set_pev(Angra, pev_solid, SOLID_BBOX)
	set_pev(Angra, pev_movetype, MOVETYPE_NONE)
	
	// Set Size
	new Float:maxs[3] = {162.0, 122.0, 194.0}
	new Float:mins[3] = {-162.0, -122.0, 20.0}
	entity_set_size(Angra, mins, maxs)
	
	// Set Config 2
	set_pev(Angra, pev_modelindex, Angra_Modelindex)
	set_entity_anim(Angra, ANGRA_ANIM_APPEAR1, 1)
	
	set_pev(Angra, pev_playable, 0)

	// Set Task Appear 2
	set_task(APPEAR1_TIME - 0.5, "Set_State_Appear2", Angra+TASK_APPEAR)
	set_task(0.5, "Set_Sound_Appear1")
	
	engfunc(EngFunc_DropToFloor, Angra)
}

// ================= APPEAR SCENE ===================
public Set_Sound_Appear1() PlaySound(0, SOUND_APPEAR1)

public Set_State_Appear2(Angra)
{
	Angra -= TASK_APPEAR
	if(!pev_valid(Angra)) return
	
	set_pev(Angra, pev_movetype, MOVETYPE_PUSHSTEP)
	set_task(APPEAR2_ANIM_LOOP_TIME, "Anim_Loop_Appear2", Angra+TASK_ANIM_LOOP, _, _, "b")
	set_pev(Angra, pev_gravity, 0.6)
	set_entity_anim(Angra, ANGRA_ANIM_APPEAR2, 1)
	
	static Float:TargetOrigin[3]

	TargetOrigin[0] = 496.0; TargetOrigin[1] = 209.0; TargetOrigin[2] = 985.0
	hook_ent2(Angra, TargetOrigin, 500.0)
	
	set_task(1.9, "Set_State_Appear3", Angra+TASK_APPEAR)
}

public Set_State_Appear3(Angra)
{
	Angra -= TASK_APPEAR
	if(!pev_valid(Angra)) return
	
	remove_task(Angra+TASK_ANIM_LOOP)

	set_pev(Angra, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(Angra, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.05, "Appear3_Anim", Angra+TASK_APPEAR)
}

public Appear3_Anim(Angra) 
{
	Angra -= TASK_APPEAR
	if(!pev_valid(Angra)) return	
	
	engfunc(EngFunc_DropToFloor, Angra)
	set_entity_anim(Angra, ANGRA_ANIM_APPEAR3, 1)
	PlaySound(0, SOUND_APPEAR3)
	
	Make_PlayerShake(0)
	set_task(3.0, "Boss_Really_Start", Angra+TASK_APPEAR)
}

public Boss_Really_Start(Angra)
{
	Angra -= TASK_APPEAR
	if(!pev_valid(Angra)) return
	
	set_pev(Angra, pev_playable, 1)
	set_pev(Angra, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Angra, pev_state, ANGRA_STATE_IDLE)
	
	set_pev(Angra, pev_health, ANGRA_HEALTH + 10000.0)
	set_pev(Angra, pev_takedamage, DAMAGE_YES)
	
	set_pev(Angra, pev_nextthink, get_gametime() + 0.05)
}

public Anim_Loop_Appear2(Angra)
{
	Angra -= TASK_ANIM_LOOP
	if(!pev_valid(Angra)) return
	
	set_entity_anim(Angra, ANGRA_ANIM_APPEAR2, 0)
}

public Make_PlayerShake(id)
{
	if(!id) 
	{
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake, _, id)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	}
}

// ================= IDLE SCENE ===================
public fw_Angra_Think(Angra)
{
	if(!pev_valid(Angra)) return
	if(!pev(Angra, pev_playable)) return
	if(pev(Angra, pev_health) - 10000.0 <= 0.0)
	{
		Angra_Die(Angra)
		return
	}
	
	set_pev(Angra, pev_nextthink, get_gametime() + 0.1)
	
	switch(pev(Angra, pev_state))
	{
		case ANGRA_STATE_IDLE:
		{
			if(get_gametime() - 1.6 < Angra_Time_Idle) 
				return
			
			set_entity_anim(Angra, ANGRA_ANIM_IDLE, 0)
			Angra_Time_Idle = get_gametime()
		}
		case ANGRA_STATE_IDLE_FLYING:
		{
			if(get_gametime() - 0.8 < Angra_Time_Idle) 
				return
				
			set_entity_anim(Angra, ANGRA_ANIM_FLY2, 0)
			PlaySound(0, SOUND_FLYING)
				
			Angra_Time_Idle = get_gametime()	
		}
	}
}

public Set_Appear_Idle(Angra)
{
	Angra -= TASK_APPEAR
	if(!pev_valid(Angra)) return
	
	set_entity_anim(Angra, ANGRA_ANIM_IDLE, 0)
}

// ================= QUAKE SCENE ===================
public Angra_Do_Quake()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_QUAKE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "Do_Quake_Now", g_Angra_Ent+TASK_DO_QUAKE)
}

public Do_Quake_Now(Angra)
{
	Angra -= TASK_DO_QUAKE
	if(!pev_valid(Angra)) return
	
	set_entity_anim(Angra, ANGRA_ANIM_ATTACK_QUAKE, 1)
	PlaySound(0, SOUND_ATTACK_QUAKE)
	
	set_task(1.3, "Check_Target_Quake", Angra+TASK_DO_QUAKE)
	set_task(4.5, "Angra_Done_Quake", Angra+TASK_DO_QUAKE)
}

public Check_Target_Quake(Angra)
{
	Angra -= TASK_DO_QUAKE
	if(!pev_valid(Angra)) return
	
	Make_PlayerShake(0)
	Drop_PlayerWeapon(0)
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	pev(Angra, pev_origin, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > QUAKE_DAMAGE_RADIUS)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, i, QUAKE_DAMAGE, DMG_BLAST)
	}	
}

public Drop_PlayerWeapon(id)
{
	static wpn, wpnname[32]
	
	if(!id)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i)) continue
			
			wpn = get_user_weapon(i)
			if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
				engclient_cmd(i, "drop", wpnname)
		}
	} else {
		if(!is_user_alive(id)) return
		
		wpn = get_user_weapon(id)
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(id, "drop", wpnname)
	}
}

public Angra_Done_Quake(Angra)
{
	Angra -= TASK_DO_QUAKE
	if(!pev_valid(Angra)) return
	
	remove_task(Angra+TASK_DO_QUAKE)
	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
}

// ================= BITE SCENE ===================
public Angra_Do_Bite()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_BITE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "Do_Bite_Now", g_Angra_Ent+TASK_DO_BITE)
}

public Do_Bite_Now(Angra)
{
	Angra -= TASK_DO_BITE
	if(!pev_valid(Angra)) return
	
	set_entity_anim(Angra, ANGRA_ANIM_ATTACK_BITE, 1)
	PlaySound(0, SOUND_ATTACK_BITE)
	
	set_task(0.4, "Check_Target_BiteLeft", Angra+TASK_DO_BITE)
	set_task(0.9, "Check_Target_BiteRight", Angra+TASK_DO_BITE)
	
	set_task(2.6, "Angra_Done_Bite", Angra+TASK_DO_BITE)
}

public Check_Target_BiteLeft(Angra)
{
	Angra -= TASK_DO_BITE
	if(!pev_valid(Angra)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(Angra, 325.0, -40.0, 0.0, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, i, BITE_DAMAGE, DMG_BLAST)
		Knockback_Player(i, TargetOrigin, 500.0, 0)
		Make_PlayerShake(i)
	}
}

public Check_Target_BiteRight(Angra)
{
	Angra -= TASK_DO_BITE
	if(!pev_valid(Angra)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(Angra, 400.0, 40.0, 0.0, TargetOrigin)	
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, i, BITE_DAMAGE, DMG_BLAST)
		Knockback_Player(i, TargetOrigin, 500.0, 0)
		Make_PlayerShake(i)
	}	
}

public Angra_Done_Bite(Angra)
{
	Angra -= TASK_DO_BITE
	if(!pev_valid(Angra)) return
	
	remove_task(Angra+TASK_DO_BITE)
	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
}

// ================= SWING SCENE ===================
public Angra_Do_Swing()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_SWING)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "Do_Swing_Now", g_Angra_Ent+TASK_DO_SWING)
}

public Do_Swing_Now(Angra)
{
	Angra -= TASK_DO_SWING
	if(!pev_valid(Angra)) return
	
	set_entity_anim(Angra, ANGRA_ANIM_ATTACK_SWING, 1)
	
	set_task(0.75, "Set_Swing_Sound", Angra+TASK_DO_SWING)
	set_task(1.0, "Check_Target_Swing", Angra+TASK_DO_SWING)
	set_task(2.3, "Angra_Done_Swing", Angra+TASK_DO_SWING)
}

public Set_Swing_Sound(Angra)
{
	Angra -= TASK_DO_SWING
	if(!pev_valid(Angra)) return
	
	PlaySound(0, SOUND_ATTACK_SWING)
}

public Check_Target_Swing(Angra)
{
	Angra -= TASK_DO_SWING
	if(!pev_valid(Angra)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(Angra, 400.0, 0.0, 0.0, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 300.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, i, SWING_DAMAGE, DMG_BLAST)
		Knockback_Player(i, TargetOrigin, 1000.0, 0)
		Make_PlayerShake(i)
	}
}

public Angra_Done_Swing(Angra)
{
	Angra -= TASK_DO_SWING
	if(!pev_valid(Angra)) return
	
	remove_task(Angra+TASK_DO_SWING)
	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
}

// ================= TENTACLE SCENE ===================
public Angra_Do_Tentacle()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)	
	set_task(0.1, "Do_Tentacle_Now", g_Angra_Ent+TASK_DO_TENTACLE)
}

public Do_Tentacle_Now(Angra)
{
	Angra -= TASK_DO_TENTACLE
	if(!pev_valid(Angra)) return
	
	g_Tentacle_Count = 0
	
	if(random_num(0,1) == 1) // Tentacle 1
	{
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_TENTACLE1)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_TENTACLE1, 1)
		
		set_task(1.0, "Do_Tentacle_Sound", g_Angra_Ent+TASK_DO_TENTACLE_SOUND)
		set_task(2.0, "Create_Tentacle1", g_Angra_Ent+TASK_DO_TENTACLE)
	} else { // Tentacle 2
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_TENTACLE2)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_TENTACLE2, 1)
		
		set_task(1.0, "Do_Tentacle_Sound", g_Angra_Ent+TASK_DO_TENTACLE_SOUND)
		set_task(2.0, "Create_Tentacle2", g_Angra_Ent+TASK_DO_TENTACLE)
	}
}

public Do_Tentacle_Sound(Angra)
{
	Angra -= TASK_DO_TENTACLE_SOUND
	if(!pev_valid(Angra)) return	
	
	PlaySound(0, pev(Angra, pev_state) == ANGRA_STATE_ATTACK_TENTACLE1 ? SOUND_ATTACK_TENTACLE1 : SOUND_ATTACK_TENTACLE2)
}

public Create_Tentacle1(Angra)
{
	Angra -= TASK_DO_TENTACLE
	if(!pev_valid(Angra)) return
	
	static Float:Origin[3]
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		
		pev(i, pev_origin, Origin)
		Create_Tentacle_Entity(Origin)
	}
	
	set_task(0.1, "Create_Tentacle_Now1", Angra+TASK_DO_CREATING_TENTACLE)
	set_task(5.0, "Angra_Done_Tentacle", Angra+TASK_DO_TENTACLE)
}

public Create_Tentacle2(Angra)
{
	Angra -= TASK_DO_TENTACLE
	if(!pev_valid(Angra)) return
	
	static Float:Origin[3]
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		
		pev(i, pev_origin, Origin)
		Create_Tentacle_Entity(Origin)
	}
	
	set_task(0.1, "Create_Tentacle_Now2", Angra+TASK_DO_CREATING_TENTACLE)
	set_task(8.0, "Angra_Done_Tentacle", Angra+TASK_DO_TENTACLE)
}

public Create_Tentacle_Now1(Angra)
{
	Angra -= TASK_DO_CREATING_TENTACLE
	if(!pev_valid(Angra)) return	
	
	if(g_Tentacle_Count >= TENTACLE_MAX1)
		return
	
	static Float:RanOrigin[3], Classname[64], Float:EntOrigin[3], Continue
	
	RanOrigin[0] = MAP_CENTER_X + random_float(-500.0, 500.0)
	RanOrigin[1] = MAP_CENTER_Y + random_float(-500.0, 500.0)
	RanOrigin[2] = MAP_CENTER_Z
	
	Continue = 1
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
		
		pev(i, pev_classname, Classname, sizeof(Classname))
		if(!equal(Classname, TENTACLE_CLASSNAME))
			continue
		
		pev(i, pev_origin, EntOrigin)
		if(get_distance_f(RanOrigin, EntOrigin) < 75.0)
		{
			Continue = 0
			return
		}
	}
	
	if(Continue) 
	{
		g_Tentacle_Count++
		Create_Tentacle_Entity(RanOrigin)
		set_task(0.1, "Create_Tentacle_Now1", Angra+TASK_DO_CREATING_TENTACLE)
	} else {
		Create_Tentacle_Now1(Angra+TASK_DO_CREATING_TENTACLE)
	}
}

public Create_Tentacle_Now2(Angra)
{
	Angra -= TASK_DO_CREATING_TENTACLE
	if(!pev_valid(Angra)) return	
	
	if(g_Tentacle_Count >= TENTACLE_MAX2)
		return
	
	static Float:RanOrigin[3], Classname[64], Float:EntOrigin[3], Continue

	RanOrigin[0] = MAP_CENTER_X + random_float(-700.0, 700.0)
	RanOrigin[1] = MAP_CENTER_Y + random_float(-700.0, 700.0)
	RanOrigin[2] = MAP_CENTER_Z
	
	Continue = 1
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
		
		pev(i, pev_classname, Classname, sizeof(Classname))
		if(!equal(Classname, TENTACLE_CLASSNAME))
			continue
		
		pev(i, pev_origin, EntOrigin)
		if(get_distance_f(RanOrigin, EntOrigin) < 75.0)
		{
			Continue = 0
			return
		}
	}
	
	if(Continue) 
	{
		g_Tentacle_Count++
		Create_Tentacle_Entity(RanOrigin)
		set_task(0.1, "Create_Tentacle_Now2", Angra+TASK_DO_CREATING_TENTACLE)
	} else {
		Create_Tentacle_Now2(Angra+TASK_DO_CREATING_TENTACLE)
	}
}

public Create_Tentacle_Entity(Float:Origin[3])
{
	static EarthHole; EarthHole = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(EarthHole)) return
		
	engfunc(EngFunc_SetOrigin, EarthHole, Origin)
		
	// Set Config
	set_pev(EarthHole, pev_gamestate, 1)
	set_pev(EarthHole, pev_classname, EARTHHOLE_CLASSNAME)
	engfunc(EngFunc_SetModel, EarthHole, EARTHHOLE_MODEL_BEGIN)
	set_pev(EarthHole, pev_solid, SOLID_NOT)
	set_pev(EarthHole, pev_movetype, MOVETYPE_NONE)
	
	// Set Size
	new Float:maxs[3] = {0.0, 0.0, 0.0}
	new Float:mins[3] = {0.0, 0.0, 0.0}
	entity_set_size(EarthHole, mins, maxs)

	fm_set_rendering(EarthHole, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 150)
	
	set_entity_anim(EarthHole, 0, 1)
	//engfunc(EngFunc_DropToFloor, EarthHole)

	set_task(random_float(1.0, 2.0), "Set_Tentacle_Now", EarthHole+TASK_TENTACLE_GROW)
}

public Set_Tentacle_Now(EarthHole)
{
	EarthHole -= TASK_TENTACLE_GROW
	if(!pev_valid(EarthHole)) return
	
	engfunc(EngFunc_SetModel, EarthHole, EARTHHOLE_MODEL_END)
	static Float:Origin[3]
	pev(EarthHole, pev_origin, Origin)
	
	Make_True_Tentacle(Origin)
	set_task(random_float(2.0, 5.0), "Remove_This_Ent", EarthHole+(TASK_TENTACLE_GROW-1))
}

public Remove_This_Ent(Ent)
{
	Ent -= (TASK_TENTACLE_GROW-1)
	if(!pev_valid(Ent)) return
	
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Make_True_Tentacle(Float:Origin[3])
{
	static Tentacle; Tentacle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Tentacle)) return
		
	engfunc(EngFunc_SetOrigin, Tentacle, Origin)
		
	// Set Config
	set_pev(Tentacle, pev_gamestate, 1)
	set_pev(Tentacle, pev_classname, TENTACLE_CLASSNAME)
	engfunc(EngFunc_SetModel, Tentacle, TENTACLE_MODEL)
	set_pev(Tentacle, pev_solid, SOLID_NOT)
	set_pev(Tentacle, pev_movetype, MOVETYPE_NONE)
	
	// Set Size
	new Float:maxs[3] = {0.0, 0.0, 0.0}
	new Float:mins[3] = {0.0, 0.0, 0.0}
	entity_set_size(Tentacle, mins, maxs)
	set_entity_anim(Tentacle, 0, 1)	
	
	static Float:POrigin[3]
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		
		pev(i, pev_origin, POrigin)
		
		if(get_distance_f(POrigin, Origin) < 250.0)
			Make_PlayerShake(i)
		
		if(get_distance_f(POrigin, Origin) < 60.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, TENTACEL_DAMAGE, DMG_BLAST)
			static Float:Velocity[3]
			Velocity[0] = random_float(0.0, 250.0)
			Velocity[1] = random_float(0.0, 250.0)
			Velocity[2] = random_float(0.0, 900.0)
			set_pev(i, pev_velocity, Velocity)
		}
	}
	
	set_task(1.5, "Remove_This_Ent", Tentacle+(TASK_TENTACLE_GROW-1))
}

public Angra_Done_Tentacle(Angra)
{
	Angra -= TASK_DO_TENTACLE
	if(!pev_valid(Angra)) return
	
	g_Tentacle_Count = 0
	
	remove_task(Angra+TASK_DO_TENTACLE)
	remove_task(Angra+TASK_DO_CREATING_TENTACLE)
	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
}

// ================= FLYING UP SCENE ===================
public Angra_Do_FlyingUp()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_PUSHSTEP)	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_FLYING_UP)
	
	set_task(0.1, "Start_FlyingUp", g_Angra_Ent+TASK_DO_FLYING_UP)
}

public Start_FlyingUp(ent)
{
	ent -= TASK_DO_FLYING_UP
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_FLY1, 1)
	PlaySound(0, SOUND_FLYING_UP)
	
	set_task(1.7, "Set_FlyUp", ent+(TASK_DO_FLYING_UP+1))
	set_task(3.0, "Set_FlyState", ent+TASK_DO_FLYING_UP)
}

public Set_FlyUp(ent)
{
	ent -= (TASK_DO_FLYING_UP+1)
	if(!pev_valid(ent)) return
	
	static Float:Vec[3]
	Vec[2] = 700.0
	set_pev(ent, pev_velocity, Vec)
}

public Set_FlyState(ent)
{
	ent -= TASK_DO_FLYING_UP
	if(!pev_valid(ent)) return
	
	remove_task(ent+(TASK_DO_FLYING_UP+1))
	
	set_pev(ent, pev_state, ANGRA_STATE_IDLE_FLYING)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	new Float:maxs[3] = {162.0, 122.0, 324.0}
	new Float:mins[3] = {-162.0, -122.0, 150.0}
	entity_set_size(ent, mins, maxs)
}

// ================= LANDING DOWN SCENE ===================
public Angra_Do_LandingDown()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE_FLYING)
		return
		
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_PUSHSTEP)	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_LANDING_DOWN)
	
	set_task(0.1, "Start_LandingDown", g_Angra_Ent+TASK_DO_LANDING_DOWN)	
}

public Start_LandingDown(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_LAND1, 1)
	set_task(0.7, "Set_Landing_Down", ent+TASK_DO_LANDING_DOWN)
}

public Set_Landing_Down(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_LAND2, 1)
	
	// Set Size
	new Float:maxs[3] = {162.0, 122.0, 194.0}
	new Float:mins[3] = {-162.0, -122.0, 20.0}
	entity_set_size(ent, mins, maxs)		
	
	static Float:Velocity[3]
	Velocity[2] = -500.0
	set_pev(ent, pev_velocity, Velocity)
	
	set_task(0.25, "Set_PreLanded_Down", ent+TASK_DO_LANDING_DOWN)
}

public Set_PreLanded_Down(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	static Float:Velocity[3]
	set_pev(ent, pev_velocity, Velocity)		
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	engfunc(EngFunc_DropToFloor, ent)
	
	set_task(0.1, "Set_Landed_Down", ent+TASK_DO_LANDING_DOWN)
}

public Set_Landed_Down(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	g_Tentacle_Count = 0
	
	set_entity_anim(ent, ANGRA_ANIM_LAND3, 1)	
	PlaySound(0, SOUND_LANDED)
	
	Make_PlayerShake(0)
	Drop_PlayerWeapon(0)
	Make_Landed_Tentacle(ent+TASK_DO_CREATING_TENTACLE)
	
	set_task(5.4, "Angra_Done_Land", ent+TASK_DO_LANDING_DOWN)
}

public Make_Landed_Tentacle(Angra)
{	
	Angra -= TASK_DO_CREATING_TENTACLE
	if(!pev_valid(Angra)) return	
	
	if(g_Tentacle_Count >= TENTACLE_MAX2)
		return
	
	static Float:RanOrigin[3], Classname[64], Float:EntOrigin[3], Continue

	RanOrigin[0] = MAP_CENTER_X + random_float(-700.0, 700.0)
	RanOrigin[1] = MAP_CENTER_Y + random_float(-700.0, 700.0)
	RanOrigin[2] = MAP_CENTER_Z
	
	Continue = 1
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
		
		pev(i, pev_classname, Classname, sizeof(Classname))
		if(!equal(Classname, TENTACLE_CLASSNAME))
			continue
		
		pev(i, pev_origin, EntOrigin)
		if(get_distance_f(RanOrigin, EntOrigin) < 75.0)
		{
			Continue = 0
			return
		}
	}
	
	if(Continue) 
	{
		g_Tentacle_Count++
		Create_Tentacle_Entity(RanOrigin)
		set_task(0.1, "Make_Landed_Tentacle", Angra+TASK_DO_CREATING_TENTACLE)
	} else {
		Make_Landed_Tentacle(Angra+TASK_DO_CREATING_TENTACLE)
	}	
}

public Angra_Done_Land(Angra)
{
	Angra -= TASK_DO_LANDING_DOWN
	if(!pev_valid(Angra)) return
	
	remove_task(Angra+TASK_DO_LANDING_DOWN)
	
	set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)
}

// ================= POISON SCENE ===================
public Angra_Do_Poison()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE)
		return
		
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)	
	set_task(0.05, "Checking_Poison", g_Angra_Ent+TASK_DO_POISON)
}

public Checking_Poison(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	if(random_num(0,1) == 1) // Poison 1
	{
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_LAND_POISON1)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_POISON1, 1)
		
		set_task(0.1, "Set_Poison_Sound", ent+(TASK_DO_POISON+2))
		
		set_task(2.7, "Angra_Create_Poison1", ent+TASK_DO_POISON)
		set_task(4.25, "Angra_Stop_Poison", ent+(TASK_DO_POISON+3))
		set_task(4.9, "Angra_Done_Poison", ent+(TASK_DO_POISON+1))
	} else { // Poison 2
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_LAND_POISON2)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_POISON1, 1)
		
		set_task(0.1, "Set_Poison_Sound", ent+(TASK_DO_POISON+2))
		
		set_task(3.0, "Angra_Create_Poison2", ent+TASK_DO_POISON)
		set_task(4.25, "Angra_Stop_Poison", ent+(TASK_DO_POISON+3))
		set_task(4.7, "Angra_Done_Poison", ent+(TASK_DO_POISON+1))
	}	
}

public Set_Poison_Sound(ent)
{
	ent -= (TASK_DO_POISON+2)
	
	if(!pev_valid(ent)) return
	PlaySound(0, SOUND_DO_POISON)
}

public Angra_Create_Poison1(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison1", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public Angra_Stop_Poison(ent)
{
	ent -= (TASK_DO_POISON+3)
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_THROWING_POISON)
}

public Create_Poison1(ent)
{
	ent -= TASK_DO_THROWING_POISON
	if(!pev_valid(ent)) return
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(ent, 350.0, -230.0, 120.0, Origin)
	pev(ent, pev_angles, Angles)

	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)	
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 250.0)
	set_pev(ent, pev_scale, 0.5)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(ent, pev_classname, POISON_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, POISON_SPR)
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -10.0})
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 10.0})
	set_pev(ent, pev_fuser1, get_gametime() + 1.5)

	set_pev(ent, pev_gravity, 0.1)
	VelocityByAim(ent, 700, Velocity)
	Velocity[0] *= -1
	set_pev(ent, pev_velocity, Velocity)

	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	
	set_pev(ent, pev_solid, SOLID_TRIGGER)	
}

public Angra_Create_Poison2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison1", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public fw_Poison_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new Float:fFrame, Float:fNextThink, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.01
		fFrame += 0.5
		
		if (fFrame > 39.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	// effect normal
	else
	{
		fNextThink = 0.05
		
		fFrame += 0.5
		fScale += 0.25
		
		fFrame = floatmin(39.0, fFrame)
		fScale = floatmin(4.0, fScale)
		
		if (fFrame > 39.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue

		if(entity_range(i, iEnt) < 100.0)
			ExecuteHamB(Ham_TakeDamage, i, 0, i, POISON_DAMAGE, DMG_POISON)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	// time remove
	new Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}	
}

public fw_Angra_Touch(ent, id)
{	
	if(!pev_valid(ent))
		return
		
	if(pev_valid(id))
	{
		static Classname[32]
		pev(id, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, POISON_CLASSNAME))
			return
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}

public Angra_Done_Poison(ent)
{
	ent -= (TASK_DO_POISON+1)
	if(!pev_valid(ent)) return

	remove_task(ent+TASK_DO_POISON)
	remove_task(ent+TASK_DO_THROWING_POISON)
	
	set_pev(ent, pev_state, ANGRA_STATE_IDLE)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
}

// ================= FLYPOISON SCENE ===================
public Angra_Do_FlyPoison()
{
	if(!pev_valid(g_Angra_Ent)) return
	if(pev(g_Angra_Ent, pev_state) != ANGRA_STATE_IDLE_FLYING)
		return
		
	set_pev(g_Angra_Ent, pev_movetype, MOVETYPE_NONE)	
	set_task(0.05, "Checking_Poison2", g_Angra_Ent+TASK_DO_POISON)	
}

public Checking_Poison2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	g_Current_Angles2 = random_float(-700.0, -1400.0)
	
	if(random_num(0,1) == 1) // Poison 1
	{	
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_FLY_POISON1)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_FLY1_POISON1, 1)
		
		set_task(1.0, "Angra_Create_Poison1_2", ent+TASK_DO_POISON)
		set_task(2.3, "Angra_Stop_Poison_2", ent+(TASK_DO_POISON+3))
		set_task(2.3, "Angra_Done_Poison2", ent+(TASK_DO_POISON+1))
	} else { // Poison 2
		set_pev(g_Angra_Ent, pev_state, ANGRA_STATE_ATTACK_FLY_POISON1)
		set_entity_anim(g_Angra_Ent, ANGRA_ANIM_ATTACK_FLY1_POISON1, 1)
		
		set_task(1.25, "Angra_Create_Poison2_2", ent+TASK_DO_POISON)
		set_task(2.5, "Angra_Stop_Poison_2", ent+(TASK_DO_POISON+3))
		set_task(2.5, "Angra_Done_Poison2", ent+(TASK_DO_POISON+1))
	}	
}

public Angra_Create_Poison1_2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison1_2", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public Angra_Stop_Poison_2(ent)
{
	ent -= (TASK_DO_POISON+3)
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_THROWING_POISON)
}

public Create_Poison1_2(ent)
{
	ent -= TASK_DO_THROWING_POISON
	if(!pev_valid(ent)) return
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(ent, 450.0, -230.0, 900.0, Origin)
	pev(ent, pev_angles, Angles)

	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)	
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 250.0)
	set_pev(ent, pev_scale, 1.0)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(ent, pev_classname, POISON_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, POISON_SPR)
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -10.0})
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 10.0})
	set_pev(ent, pev_fuser1, get_gametime() + 1.5)

	set_pev(ent, pev_gravity, 1.0)
	VelocityByAim(ent, 1400, Velocity)
	g_Current_Angles2 -= 75.0
	Velocity[0] *= -1
	Velocity[2] = g_Current_Angles2
	set_pev(ent, pev_velocity, Velocity)

	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	
	set_pev(ent, pev_solid, SOLID_TRIGGER)	
}

public Angra_Create_Poison2_2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison1_2", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public Angra_Done_Poison2(ent)
{
	ent -= (TASK_DO_POISON+1)
	if(!pev_valid(ent)) return

	remove_task(ent+TASK_DO_POISON)
	remove_task(ent+TASK_DO_THROWING_POISON)
	
	set_pev(ent, pev_state, ANGRA_STATE_IDLE_FLYING)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
}

// ================= FLYPOISON SCENE ===================
public Angra_Die(ent)
{

}

// ================= STOCK ===================
public npc_turntotarget(ent, Float:Vic_Origin[3]) 
{
	if(!pev_valid(ent)) return
	
	static Float:newAngle[3], Float:EntOrigin[3]
	static Float:x, Float:z, Float:radians
	static Float:EntAngles[3]
	
	pev(ent, pev_angles, newAngle)
	pev(ent, pev_angles, EntAngles)
	pev(ent, pev_origin, EntOrigin)
	
	x = Vic_Origin[0] - EntOrigin[0]
	z = Vic_Origin[1] - EntOrigin[1]

	radians = floatatan(z/x, radian)
	newAngle[1] = radians * (180 / 3.14)
	
	if(Vic_Origin[0] < EntOrigin[0]) newAngle[1] -= 180.0
	
	static Float:TempAngle1, Float:TempAngle2
	if(newAngle[1] >= 0.1 && newAngle[1] < 179.0) // 0 -> 180
	{
		TempAngle1 = 180 - newAngle[1]
		
		TempAngle2 = TempAngle1 / 10.0
		EntAngles[1] -= TempAngle2
	} else if(newAngle[1] <= 0.1 && newAngle[1] > -179.0) {// 0 -> -180
		TempAngle1 = 180 - (newAngle[1]*-1)
		
		TempAngle2 = TempAngle1 / 10.0
		EntAngles[1] += TempAngle2
	}

	set_pev(ent, pev_v_angle, EntAngles)
	set_pev(ent, pev_angles, EntAngles)
}

stock set_entity_anim(ent, anim, reset_frame)
{
	if(!pev_valid(ent)) return
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 1.0)
	if(reset_frame) set_pev(ent, pev_frame, 0.0)
	
	set_pev(ent, pev_sequence, anim)	
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	if(get_distance_f(VicOrigin, EntOrigin) > 65.0)
	{
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = fl_Velocity[1] = fl_Velocity[2] = 0.0
	}
	
	set_pev(ent, pev_velocity, fl_Velocity)
}

stock Knockback_Player(id, Float:CenterOrigin[3], Float:Power, Increase_High)
{
	if(!is_user_alive(id)) return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(id, pev_origin, EntOrigin)
	distance_f = get_distance_f(EntOrigin, CenterOrigin)
	fl_Time = distance_f / Power
		
	fl_Velocity[0] = (EntOrigin[0]- CenterOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[0]- CenterOrigin[1]) / fl_Time
	if(Increase_High)
		fl_Velocity[2] = (((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(10.0, 50.0) * 1.5)
	else
		fl_Velocity[2] = ((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(1.5, 3.5)
	
	set_pev(id, pev_velocity, fl_Velocity)
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent)) return
	
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	//pev(ent, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
