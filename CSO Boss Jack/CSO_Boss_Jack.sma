#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define PLUGIN "[CSO] Jack"
#define VERSION "1.0"
#define AUTHOR "Joseph Rias de Dias"

#define JACK_HEALTH 50000.0
#define JACK_ATTACK_RANGE 160.0
#define JACK_MOVESPEED 290.0

#define JACK_MODEL "models/jack/zombiejack.mdl"
#define JACK_SWING "models/jack/ef_jack_swing.mdl"
#define JACK_THORNY "models/jack/ef_thorn.mdl"
#define JACK_SW "models/jack/ef_shockwave.mdl"
#define JACK_ROCKET "models/jack/jack_rocket.mdl"

new const JackSounds[19][] = 
{
	"jack/zbs_appear.wav",
	"jack/zbs_attack_m134_start.wav",
	"jack/zbs_attack_rocket_shoot.wav",
	"jack/zbs_attack_rocket1.wav",
	"jack/zbs_attack_rocket2.wav",
	"jack/zbs_attack_shockwave.wav",
	"jack/zbs_attack_thorny.wav",
	"jack/zbs_attack_thorny1.wav",
	"jack/zbs_attack1.wav",
	"jack/zbs_attack2.wav",
	"jack/zbs_attack3.wav",
	"jack/zbs_death.wav",
	"jack/zbs_idle.wav",
	"jack/zbs_jump_end.wav",
	"jack/zbs_jump_start.wav",
	"jack/zbs_walk1.wav",
	"jack/zbs_walk2.wav",
	"jack/zbs_warpattack_ready.wav",
	"jack/m134ex_shoot.wav"
}

enum
{
	ANIM_DUMMY = 0,
	ANIM_APPEAR,
	ANIM_IDLE,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_JUMP_START,
	ANIM_JUMP_LOOP,
	ANIM_JUMP_END,
	ANIM_ATTACK1,
	ANIM_ATTACK2,
	ANIM_ATTACK3,
	ANIM_WARPATK_READY,
	ANIM_WARPATK_LOOP,
	ANIM_WARPATK1,
	ANIM_WARPATK2,
	ANIM_WARPATK3,
	ANIM_THORNY,
	ANIM_SHOCKWAVE,
	ANIM_M134_START,
	ANIM_M134_LOOP,
	ANIM_M134_END,
	ANIM_ROCKET,
	ANIM_DEATH,
	ANIM_DEATH2,
	ANIM_SCENE1
}

enum
{
	STATE_APPEAR = 0,
	STATE_IDLE,
	STATE_SEARCHING_ENEMY,
	STATE_MOVE,
	STATE_ATTACK,
	STATE_TELEPORTA,
	STATE_TELEPORTB,
	STATE_TELEPORTC,
	STATE_THORNY,
	STATE_SHOCKWAVE,
	STATE_LANDING1,
	STATE_LANDING2,
	STATE_LANDING3,
	STATE_DEATH
}

#define TASK_APPEARJUMP 2221
#define TASK_ATTACK 2222
#define TASK_SCENE 2223
#define TASK_TELEPORT 2224

#define HEALTH_OFFSET 10000.0
#define JACK_CLASSNAME "jack"

new Door, g_RegHam
new Jack, g_BossState
new Float:Time1, Float:Time2, Float:Time3, Float:Time4
new g_MsgScreenShake, g_MaxPlayers, m_iBlood[2], g_StopTeleport, g_iSpriteIndex

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	Find_MainDoor()
	
	register_think(JACK_CLASSNAME, "fw_Jack_Think")
	register_touch(JACK_CLASSNAME, "player", "fw_JackPlayer")
	register_think("attack_effect", "fw_Effect1_Think")
	register_touch("thorny", "*", "fw_Thorny_Touch")
	register_touch("rk", "*", "fw_Thorny_Touch")
	register_think("sw", "fw_SW_Think")
	register_think("sw2", "fw_SW2_Think")
	register_touch("sw", "*", "fw_SW_Touch")
	
	register_concmd("jack_start", "Precache_Boss")
	register_concmd("jack_end", "End_Boss")
	
	g_MsgScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(JACK_MODEL)
	precache_model(JACK_SWING)
	precache_model(JACK_THORNY)
	precache_model(JACK_SW)
	precache_model(JACK_ROCKET)
	
	for(new i = 0; i < sizeof(JackSounds); i++)
		precache_sound(JackSounds[i])
		
	g_iSpriteIndex = precache_model("sprites/zerogxplode.spr")
		
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
}

native CSO_Scenario_Boss(Win)

public Find_MainDoor()
{
	static Classname[32]
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
			
		pev(i, pev_classname, Classname, sizeof(Classname))
		if(!equal(Classname, "func_breakable"))
			continue
		pev(i, pev_targetname, Classname, sizeof(Classname))
		if(!equal(Classname, "door_brk"))
			continue
	
		Door = i
		server_print("[CSO] Jack: Found Door (%i)", Door)
	}
}

public Precache_Boss() Make()
public End_Boss()
{
	remove_task(Jack+TASK_TELEPORT)
	remove_task(Jack+TASK_ATTACK)
	remove_task(Jack+TASK_SCENE)
	remove_task(Jack+TASK_APPEARJUMP)
	
	set_pev(Jack, pev_rendermode, kRenderTransAlpha)
	set_pev(Jack, pev_renderfx, kRenderFxNone)
	set_pev(Jack, pev_renderamt, 255.0)	
	
	if(pev_valid(Jack)) engfunc(EngFunc_RemoveEntity, Jack)
}

public Make()
{
	if(pev_valid(Jack)) engfunc(EngFunc_RemoveEntity, Jack)
	
	static Jack1; Jack1 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Jack1)) return
	
	Jack = Jack1
	
	// Set Origin & Angles
	set_pev(Jack, pev_origin, {1450.249755, 401.756225, 732.03125})
	
	static Float:Angles[3]
	Angles[1] = 180.0
	set_pev(Jack, pev_angles, Angles)
	
	// Set Config
	set_pev(Jack, pev_classname, JACK_CLASSNAME)
	engfunc(EngFunc_SetModel, Jack, JACK_MODEL)
	set_pev(Jack, pev_modelindex, engfunc(EngFunc_ModelIndex, JACK_MODEL))
		
	set_pev(Jack, pev_gamestate, 1)
	set_pev(Jack, pev_solid, SOLID_SLIDEBOX)
	set_pev(Jack, pev_movetype, MOVETYPE_PUSHSTEP)
	
	// Set Size
	new Float:maxs[3] = {70.0, 70.0, 160.0}
	new Float:mins[3] = {-70.0, -70.0, 26.0}
	engfunc(EngFunc_SetSize, Jack, mins, maxs)
	
	// Set Life
	set_pev(Jack, pev_takedamage, DAMAGE_YES)
	set_pev(Jack, pev_health, HEALTH_OFFSET + JACK_HEALTH)
	
	// Set Config 2
	Set_EntAnim(Jack, ANIM_SCENE1, 1.0, 1)
	g_BossState = STATE_APPEAR
	
	set_task(30.0, "Set_AppearEnd1", Jack+TASK_APPEARJUMP)
	set_task(35.0, "Set_AppearEnd2", Jack+TASK_APPEARJUMP)
	set_pev(Jack, pev_nextthink, get_gametime() + 1.0)
	
	engfunc(EngFunc_DropToFloor, Jack)
	
	if(!g_RegHam)
	{
		g_RegHam = 1
		RegisterHamFromEntity(Ham_TraceAttack, Jack, "fw_Jack_TraceAttack")
	}
	
	engfunc(EngFunc_DropToFloor, Jack)
}

public Set_AppearEnd1(Ent)
{
	Ent -= TASK_APPEARJUMP
	
	if(!pev_valid(Ent))
		return
	if(!pev_valid(Door))
		return
		
	// Set Origin & Angles
	set_pev(Jack, pev_origin, {900.0, 0.0, 130.0})
	Set_EntAnim(Jack, ANIM_DUMMY, 1.0, 1)
	
	engfunc(EngFunc_DropToFloor, Jack)
}

public Set_AppearEnd2(Ent)
{
	Ent -= TASK_APPEARJUMP
	
	if(!pev_valid(Ent))
		return
	if(!pev_valid(Door))
		return
		
	set_pev(Door, pev_takedamage, DAMAGE_YES)
	set_pev(Door, pev_health, 100.0)
		
	ExecuteHam(Ham_TakeDamage, Door, 0, 0, 1000.0, DMG_BULLET)
	
	// Jack
	Set_EntAnim(Jack, ANIM_IDLE, 1.0, 1)
	g_BossState = STATE_IDLE
}

public fw_Jack_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(g_BossState == STATE_DEATH)
		return
	if((pev(ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		Jack_Death(ent)
		return
	}
	
	// Set Next Think
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	
	if(get_gametime() - Time4 > Time3)
	{
		static RandomNum; RandomNum = random_num(0, 3)
	
		static Victim3
		Victim3 = FindClosetEnemy(ent, 1)
		if(is_user_alive(Victim3)) set_pev(ent, pev_enemy, Victim3)
		else set_pev(ent, pev_enemy, 0)

		switch(RandomNum)
		{
			case 0: Jack_Teleport(ent)
			case 1: Jack_Shockwave(ent)
			case 2: Jack_Thorny(ent)
			case 3: Jack_IncheonLanding(ent)
			default: Jack_IncheonLanding(ent)
		}

		Time4 = random_float(1.0, 3.0)
		Time3 = get_gametime()
	}
	
	switch(g_BossState)
	{
		case STATE_APPEAR:
		{
			
		}
		case STATE_IDLE:
		{
			if(get_gametime() - 5.0 > Time1)
			{
				Set_EntAnim(ent, ANIM_IDLE, 2.0, 1)
				Time1 = get_gametime()
			}
			if(get_gametime() - 1.0 > Time2)
			{
				g_BossState = STATE_SEARCHING_ENEMY
				Time2 = get_gametime()
			}
		}
		case STATE_SEARCHING_ENEMY:
		{
			static Victim; Victim = FindClosetEnemy(ent, 1)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				g_BossState = STATE_MOVE
			} else {
				set_pev(ent, pev_enemy, 0)
				g_BossState = STATE_IDLE
			}
		}
		case STATE_MOVE:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(JACK_ATTACK_RANGE))
				{
					g_BossState = STATE_ATTACK
					
					Aim_To(ent, EnemyOrigin, 2.0, 1) 
					switch(random_num(0, 2))
					{
						case 0: Jack_StartAttack11(ent+TASK_ATTACK)
						case 1: Jack_StartAttack12(ent+TASK_ATTACK)
						case 2: Jack_StartAttack13(ent+TASK_ATTACK)
					}
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						Aim_To(ent, EnemyOrigin, 1.0, 1) 
						hook_ent2(ent, OriginAhead, JACK_MOVESPEED)
						
						Set_EntAnim(ent, ANIM_RUN, 1.0, 0)
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				g_BossState = STATE_SEARCHING_ENEMY
			}
		}
		/*
		case STATE_TELEPORTA:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				Aim_To(ent, EnemyOrigin, 2.0, 0) 
			}
		}*/
		case STATE_TELEPORTB:
		{
			static Victim; Victim = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Victim, pev_origin, EnemyOrigin)
	
			if(is_user_alive(Victim))
			{
				if(entity_range(ent, Victim) < 175.0)
				{
					TeleportAttack(ent, Victim)
				} else {
					Set_EntAnim(ent, ANIM_WARPATK_LOOP, 1.0, 0)
					
					Aim_To(ent, EnemyOrigin, 2.0, 0) 
					
					static Float:Origin[3]; pev(Victim, pev_origin, Origin)
					hook_ent2(ent, Origin, 1000.0)
				}
			} else {
				Victim = FindClosetEnemy(ent, 1)
				if(is_user_alive(Victim))
				{
					Set_EntAnim(ent, ANIM_WARPATK_LOOP, 1.0, 0)
					
					set_pev(ent, pev_enemy, Victim)
				} else {
					set_pev(ent, pev_enemy, 0)
					Jack_StopTeleport(ent+TASK_TELEPORT)
				}
			}
		}
		case STATE_LANDING1:
		{
			static Float:Target[3], Float:Origin[3]
			
			pev(ent, pev_origin, Origin)
			Target[0] = 1.122291
			Target[1] = 685.318298
			Target[2] = 485.29754
			
			if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
			{
				if(get_distance_f(Target, Origin) > 48.0)
				{
					Aim_To(ent, Target, 1.0, 1) 
					hook_ent2(ent, Target, JACK_MOVESPEED * 4.0)
					
					Set_EntAnim(ent, ANIM_JUMP_LOOP, 1.0, 0)
				} else {
					set_pev(ent, pev_velocity, 0.0)
					set_pev(ent, pev_origin, Target)
					set_pev(ent, pev_movetype, MOVETYPE_NONE)
					
					Set_EntAnim(ent, ANIM_JUMP_END, 1.0, 0)
					g_BossState = STATE_LANDING2
					
					set_task(1.0, "Jack_LandingSkill", ent+TASK_TELEPORT)
				}
			} else {
				set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
			}
		}
		case STATE_LANDING2:
		{
			static Victim; Victim = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Victim, pev_origin, EnemyOrigin)
	
			if(is_user_alive(Victim))
			{
				Aim_To(ent, EnemyOrigin, 2.0, 0) 
			} else {
				Victim = FindClosetEnemy(ent, 1)
				if(is_user_alive(Victim))
				{
					Aim_To(ent, EnemyOrigin, 2.0, 0) 
					set_pev(ent, pev_enemy, Victim)
				} else {
					set_pev(ent, pev_enemy, 0)
					Jack_LandingDown(ent+TASK_TELEPORT)
				}
			}
		}
		case STATE_LANDING3:
		{
			static Float:Target[3], Float:Origin[3]
			
			pev(ent, pev_origin, Origin)
			Target[0] = -24.624618
			Target[1] = -22.096893
			Target[2] = 100.03125
			
			if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
			{
				if(get_distance_f(Target, Origin) > 48.0)
				{
					Aim_To(ent, Target, 1.0, 1) 
					hook_ent2(ent, Target, JACK_MOVESPEED * 4.0)
					
					Set_EntAnim(ent, ANIM_JUMP_LOOP, 1.0, 0)
				} else {
					set_pev(ent, pev_movetype, MOVETYPE_NONE)
					
					set_pev(ent, pev_velocity, 0.0)
					set_pev(ent, pev_origin, Target)
					
					Set_EntAnim(ent, ANIM_JUMP_END, 1.0, 0)
					g_BossState = STATE_SEARCHING_ENEMY
					
					set_pev(ent, pev_nextthink, get_gametime() + 2.0)
				}
			} else {
				set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
			}
		}
	}	
}

public fw_JackPlayer(Ent, ID)
{
	if(!pev_valid(Ent))
		return
		
	if(is_user_alive(ID)) user_kill(ID)
}

public KickBack()
{
	static Float:Origin[3]
	Origin[0] = 0.0
	Origin[1] = 0.0
	Origin[2] = 200.0

	Check_Knockback(Origin, 0)
}

public Check_Knockback(Float:Origin[3], Damage)
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		fuck_ent(i, Origin, 5000.0)
	}
}

public Jack_StartAttack11(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	Set_EntAnim(ent, ANIM_IDLE, 1.0, 1)

	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "Jack_StartAttack112", ent+TASK_ATTACK)
}

public Jack_Death(Ent)
{
	if(!pev_valid(Ent))
		return
	
	CSO_Scenario_Boss(1)
	
	set_pev(Ent, pev_body, 0)
	
	remove_task(Ent+TASK_ATTACK)
	remove_task(Ent+TASK_TELEPORT)
	
	g_BossState = STATE_DEATH

	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "Jack_Death2", Ent)
}

public Jack_Death2(Ent)
{
	Set_EntAnim(Ent, ANIM_DEATH, 1.0, 1)
	set_task(3.5, "Set_Death", Ent+TASK_SCENE)
}

public Set_Death(Ent)
{
	Ent -= TASK_SCENE
	if(!pev_valid(Ent))
		return
	
	Set_EntAnim(Ent, ANIM_DEATH2, 1.0, 1)
}

public Jack_StartAttack12(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	Set_EntAnim(ent, ANIM_IDLE, 1.0, 1)
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "Jack_StartAttack122", ent+TASK_ATTACK)	
}

public Jack_StartAttack13(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	Set_EntAnim(ent, ANIM_IDLE, 1.0, 1)
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "Jack_StartAttack132", ent+TASK_ATTACK)	
}

public Jack_StartAttack112(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	
	Set_EntAnim(ent, ANIM_ATTACK1, 1.0, 1)
	
	set_task(0.75, "Check_AttackDamge", ent+TASK_ATTACK)
	set_task(3.0, "Done_Attack", ent+TASK_ATTACK)	
}

public Jack_StartAttack122(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	Set_EntAnim(ent, ANIM_ATTACK2, 1.0, 1)
	
	set_task(1.0, "Check_AttackDamge", ent+TASK_ATTACK)
	set_task(3.0, "Done_Attack", ent+TASK_ATTACK)	
}

public Jack_StartAttack132(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	Set_EntAnim(ent, ANIM_ATTACK2, 1.0, 1)
	
	set_task(1.0, "Check_AttackDamge", ent+TASK_ATTACK)
	set_task(3.0, "Done_Attack", ent+TASK_ATTACK)	
}

public Check_AttackDamge(Ent)
{
	Ent -= TASK_ATTACK
	if(!pev_valid(Ent))
		return
	
	static Float:Origin[3]; get_position(Ent, 250.0, 0.0, 0.0, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 250.0)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, i, random_float(30.0, 50.0), DMG_BLAST)
		Make_PlayerShake(i)
	}
}

public Check_AttackDamge2(Ent)
{
	if(!pev_valid(Ent))
		return
	
	static Float:Origin[3]; get_position(Ent, 0.0, 0.0, 0.0, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 250.0)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, i, random_float(20.0, 40.0), DMG_BLAST)
		Make_PlayerShake(i)
	}
}

public Done_Attack(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)		
	g_BossState = STATE_MOVE
}

// ====================== Teleport
public Jack_Teleport(Ent)
{
	if(!pev_valid(Ent)) return

	if(g_BossState == STATE_IDLE || g_BossState == STATE_MOVE)
	{
		g_BossState = STATE_TELEPORTA
		//set_pev(Ent, pev_movetype, MOVETYPE_NONE)

		set_task(0.1, "Jack_TeleportStart", Ent+TASK_TELEPORT)	
	}
}

public Jack_TeleportStart(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	g_StopTeleport = 0
		
	Set_EntAnim(ent, ANIM_WARPATK_READY, 1.0, 1)
	
	//set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_task(0.75, "Jack_STeleport", ent+TASK_TELEPORT)
	set_task(5.0, "Jack_StopTeleportF", ent+TASK_TELEPORT)
}

public Jack_STeleport(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	Set_EntAnim(ent, ANIM_WARPATK_LOOP, 1.0, 1)
	
	set_pev(ent, pev_rendermode, kRenderTransAlpha)
	set_pev(ent, pev_renderamt, 100.0)		
	
	g_BossState = STATE_TELEPORTB
}

public TeleportAttack(Ent, Victim)
{
	g_BossState = STATE_TELEPORTA
	
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.5, "TeleportAttackDMG", Ent+TASK_TELEPORT)
	set_task(0.1, "TeleportAttack2", Ent+TASK_TELEPORT)
}

public TeleportAttackDMG(Ent)
{
	Ent -= TASK_TELEPORT
	if(!pev_valid(Ent))
		return	
		
	Check_AttackDamge(Ent+TASK_ATTACK)
}

public TeleportAttack2(Ent)
{
	Ent -= TASK_TELEPORT
	if(!pev_valid(Ent))
		return	
		
	set_pev(Ent, pev_rendermode, kRenderTransAlpha)
	set_pev(Ent, pev_renderfx, kRenderFxNone)
	set_pev(Ent, pev_renderamt, 255.0)		
		
	switch(random_num(0, 2))
	{
		case 0: 
		{
			Set_EntAnim(Ent, ANIM_WARPATK1, 1.0, 1)
			TeleportAttack_Effect(Ent, 0)
		}
		case 1: Set_EntAnim(Ent, ANIM_WARPATK2, 1.0, 1)
		case 2: 
		{
			Set_EntAnim(Ent, ANIM_WARPATK3, 1.0, 1)
			TeleportAttack_Effect(Ent, 2)
		}
	}
	
	if(g_StopTeleport) set_task(1.0, "Jack_StopTeleport", Ent+TASK_TELEPORT)
	else set_task(0.85, "ContinueTeleport", Ent+TASK_TELEPORT)
}

public TeleportAttack_Effect(ent, anim)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
		
	static Float:Vector[3]
	
	pev(ent, pev_origin, Vector); set_pev(Ent, pev_origin, Vector)
	pev(ent, pev_angles, Vector); set_pev(Ent, pev_angles, Vector)
	
	// Set Config
	set_pev(Ent, pev_classname, "attack_effect")
	engfunc(EngFunc_SetModel, Ent, JACK_SWING)
		
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(Ent, pev_aiment, ent)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)
	
	Set_EntAnim(Ent, anim, 1.0, 1)
	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
}

public ContinueTeleport(Ent)
{
	Ent -= TASK_TELEPORT
	if(!pev_valid(Ent))
		return	
		
	g_BossState = STATE_TELEPORTB
		
	Set_EntAnim(Ent, ANIM_WARPATK_LOOP, 1.0, 1)
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	set_pev(Ent, pev_rendermode, kRenderTransAlpha)
	set_pev(Ent, pev_renderfx, kRenderFxNone)
	set_pev(Ent, pev_renderamt, 100.0)
}

public Jack_StopTeleportF(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	g_StopTeleport = 1
}

public Jack_StopTeleport(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	g_BossState = STATE_TELEPORTC
	
	remove_task(ent+TASK_TELEPORT)
	
	set_pev(ent, pev_rendermode, kRenderTransAlpha)
	set_pev(ent, pev_renderfx, kRenderFxNone)
	set_pev(ent, pev_renderamt, 255.0)	
	
	set_task(0.75, "Jack_EndTeleport", ent+TASK_TELEPORT)
}

public Jack_EndTeleport(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
			
	set_pev(ent, pev_movetype, MOVETYPE_NONE)		
	g_BossState = STATE_SEARCHING_ENEMY
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_Effect1_Think(Ent)
{
	if(!pev_valid(Ent))
		return
	
	set_pev(Ent, pev_flags, FL_KILLME)
}

public Jack_Thorny(Ent)
{
	if(!pev_valid(Ent)) return

	if(g_BossState == STATE_IDLE || g_BossState == STATE_MOVE)
	{
		g_BossState = STATE_THORNY
		set_pev(Ent, pev_movetype, MOVETYPE_NONE)

		set_task(0.1, "Jack_ThornyStart", Ent+TASK_TELEPORT)	
	}
}

public Jack_ThornyStart(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	Set_EntAnim(ent, ANIM_THORNY, 1.0, 1)
	
	//set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	set_task(3.0, "Jack_CreateThorny", ent+TASK_TELEPORT)
	set_task(3.5, "Jack_StopThorny", ent+TASK_TELEPORT)
}

public Jack_CreateThorny(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	static Float:Target[6][3], Float:Start[3]
	
	pev(ent, pev_origin, Start)
	
	get_position(ent, 100.0, 0.0, 10.0, Target[0])
	get_position(ent, 80.0, 20.0, 10.0, Target[1])
	get_position(ent, 60.0, 40.0, 10.0, Target[2])
	get_position(ent, 40.0, 60.0, 10.0, Target[3])
	get_position(ent, 20.0, 80.0, 10.0, Target[4])
	get_position(ent, 0.0, 100.0, 10.0, Target[5])
		
	for(new i = 0; i < 6; i++)
		Create_Thorny(Start, Target[i])
}

public Create_Thorny(Float:Start[3], Float:End[3])
{
	static Thorny; Thorny = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Thorny)) return
		
	engfunc(EngFunc_SetOrigin, Thorny, Start)
		
	// Set Config
	set_pev(Thorny, pev_classname, "thorny")
	engfunc(EngFunc_SetModel, Thorny, JACK_THORNY)
	set_pev(Thorny, pev_solid, SOLID_TRIGGER)
	set_pev(Thorny, pev_movetype, MOVETYPE_PUSHSTEP)
	
	// Set Size
	new Float:maxs[3] = {3.0, 3.0, 3.0}
	new Float:mins[3] = {-3.0, -3.0, -3.0}
	entity_set_size(Thorny, mins, maxs)
	
	Set_EntAnim(Thorny, 0, 1.0, 1)
	hook_ent2(Thorny, End, random_float(1500.0, 3000.0))
}

public fw_Thorny_Touch(Ent, Touched)
{
	if(!pev_valid(Ent))
		return
	if(Touched == Jack)
		return
	
	static Classname[32]; pev(Touched, pev_classname, Classname, 31)
	if(equal(Classname, "thorny")) return
		
	static Float:Origin[3];
	pev(Ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_iSpriteIndex)
	write_byte(50)
	write_byte(30)
	write_byte(0)  
	message_end()
	
	Check_AttackDamge2(Ent)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(Ent, pev_flags, FL_KILLME)
}

public Jack_StopThorny(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	g_BossState = STATE_TELEPORTC
	
	remove_task(ent+TASK_TELEPORT)
	
	set_pev(ent, pev_rendermode, kRenderTransAlpha)
	set_pev(ent, pev_renderfx, kRenderFxNone)
	set_pev(ent, pev_renderamt, 255.0)	
	
	set_task(0.75, "Jack_EndTeleport", ent+TASK_TELEPORT)
}

public Jack_Shockwave(Ent)
{
	if(!pev_valid(Ent)) return

	if(g_BossState == STATE_IDLE || g_BossState == STATE_MOVE)
	{
		g_BossState = STATE_SHOCKWAVE
		set_pev(Ent, pev_movetype, MOVETYPE_NONE)

		set_task(0.1, "Jack_SWStart", Ent+TASK_TELEPORT)	
	}
}

public Jack_SWStart(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	Set_EntAnim(ent, ANIM_SHOCKWAVE, 1.0, 1)
	
	//set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	set_task(1.5, "Jack_CreateSW", ent+TASK_TELEPORT)
	set_task(2.75, "Jack_StopSW", ent+TASK_TELEPORT)
}

public Jack_CreateSW(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	static SW; SW = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(SW)) return
		
	static Float:Start[3], Float:End[3], Float:Angles[3]
	get_position(ent, 60.0, 30.0, 50.0, Start)
	get_position(ent, 1000.0, 30.0, 50.0, End)
	pev(ent, pev_angles, Angles)
		
	engfunc(EngFunc_SetOrigin, SW, Start)
	set_pev(SW, pev_angles, Angles)
		
	// Set Config
	set_pev(SW, pev_classname, "sw")
	engfunc(EngFunc_SetModel, SW, JACK_SW)
	set_pev(SW, pev_solid, SOLID_TRIGGER)
	set_pev(SW, pev_movetype, MOVETYPE_FLY)
	set_pev(SW, pev_gravity, 0.01)
	
	set_pev(SW, pev_rendermode, kRenderTransAlpha)
	set_pev(SW, pev_renderfx, kRenderFxNone)
	set_pev(SW, pev_renderamt, 0.0)
	
	// Set Size
	new Float:maxs[3] = {10.0, 10.0, 10.0}
	new Float:mins[3] = {-10.0, -10.0, -10.0}
	entity_set_size(SW, mins, maxs)
	
	Set_EntAnim(SW, 0, 1.0, 1)
	hook_ent2(SW, End, 1000.0)
	
	set_pev(SW, pev_nextthink, get_gametime() + 0.1)
}

public fw_SW_Think(ent)
{
	if(!pev_valid(ent))
		return	
		
	static SW; SW = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(SW)) return
		
	static Float:Start[3], Float:Angles[3]
	pev(ent, pev_origin, Start)
	pev(ent, pev_angles, Angles)
		
	engfunc(EngFunc_SetOrigin, SW, Start)
	set_pev(SW, pev_angles, Angles)
		
	// Set Config
	set_pev(SW, pev_classname, "sw2")
	engfunc(EngFunc_SetModel, SW, JACK_SW)
	set_pev(SW, pev_solid, SOLID_NOT)
	set_pev(SW, pev_movetype, MOVETYPE_NONE)
	set_pev(SW, pev_gravity, 0.01)
	
	// Set Size
	new Float:maxs[3] = {10.0, 10.0, 10.0}
	new Float:mins[3] = {-10.0, -10.0, -10.0}
	entity_set_size(SW, mins, maxs)
	
	Set_EntAnim(SW, 0, 1.0, 1)
	
	set_pev(SW, pev_nextthink, get_gametime() + 0.25)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_SW2_Think(ent)
{
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(ent, pev_flags, FL_KILLME)
}

public fw_SW_Touch(Ent, Touched)
{
	if(!pev_valid(Ent))
		return
	if(Touched == Jack)
		return
		
		
	static Float:Origin[3];
	pev(Ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_iSpriteIndex)
	write_byte(70)
	write_byte(30)
	write_byte(0)  
	message_end()
	
	Check_AttackDamge2(Ent)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(Ent, pev_flags, FL_KILLME)
}
		
public Jack_StopSW(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	g_BossState = STATE_TELEPORTC
	
	remove_task(ent+TASK_TELEPORT)
	
	set_pev(ent, pev_rendermode, kRenderTransAlpha)
	set_pev(ent, pev_renderfx, kRenderFxNone)
	set_pev(ent, pev_renderamt, 255.0)	
	
	set_task(0.75, "Jack_EndTeleport", ent+TASK_TELEPORT)
}

public Jack_IncheonLanding(Ent)
{
	if(!pev_valid(Ent)) return

	if(g_BossState == STATE_IDLE || g_BossState == STATE_MOVE)
	{
		g_BossState = STATE_LANDING1
		set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)

		set_pev(Ent, pev_nextthink, get_gametime() + 0.75)
		
		set_task(0.1, "Jack_LandingStart", Ent+TASK_TELEPORT)	
	}
}

public Jack_LandingStart(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	Set_EntAnim(ent, ANIM_JUMP_START, 1.0, 1)
	
	static Float:Origin[3]; pev(ent, pev_origin, Origin)
	Origin[2] += 100.0
	
	hook_ent2(ent, Origin, 750.0)
}

public Jack_LandingSkill(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
	
	if(random_num(0, 1) == 1)
	{ // M134
		Set_EntAnim(ent, ANIM_M134_START, 1.0, 1)
		
		set_task(1.0, "Jack_ShootingM134", ent+TASK_TELEPORT)
		set_task(10.0, "Jack_StopM134", ent+TASK_TELEPORT)
		
		set_pev(ent, pev_body, 2)
	} else { // Rocket
		g_StopTeleport = 0
		Set_EntAnim(ent, ANIM_ROCKET, 1.0, 1)
		
		set_task(3.6, "Jack_ShootingRocket", ent+TASK_TELEPORT)
		set_task(10.0, "Jack_StopRocket", ent+TASK_TELEPORT)
		
		set_pev(ent, pev_body, 1)
	}
}

public Jack_ReloadRocket(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	if(!g_StopTeleport)
	{
		Set_EntAnim(ent, ANIM_ROCKET, 1.0, 1)
		set_task(3.6, "Jack_ShootingRocket", ent+TASK_TELEPORT)
		
		set_pev(ent, pev_body, 1)
	} else {		
		remove_task(ent+TASK_TELEPORT)
		Jack_LandingDown(ent+TASK_TELEPORT)
	}
}

public Jack_StopRocket(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return
		
	g_StopTeleport = 1
}

public Jack_StopM134(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_TELEPORT)
	Set_EntAnim(ent, ANIM_M134_END, 1.0, 1)
	
	set_task(3.0, "Jack_LandingDown", ent+TASK_TELEPORT)
}

public Jack_LandingDown(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_TELEPORT)

	set_pev(ent, pev_body, 0)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
		
	static Float:Origin[3]; pev(ent, pev_origin, Origin)
	Origin[2] += 100.0
	
	Set_EntAnim(ent, ANIM_JUMP_START, 1.0, 1)
	hook_ent2(ent, Origin, 500.0)
	
	KickBack()
	
	g_BossState = STATE_LANDING3
	set_pev(ent, pev_nextthink, get_gametime() + 0.5)
}

public Jack_ShootingM134(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	static Victim; Victim = pev(ent, pev_enemy)
	static Float:EnemyOrigin[3]
	pev(Victim, pev_origin, EnemyOrigin)
	
	if(is_user_alive(Victim))
	{
		Set_EntAnim(ent, ANIM_M134_LOOP, 1.0, 0)
		
		static Float:Start[3]; pev(ent, pev_origin, Start); Start[2] += 26.0
		static Float:Target[3]; Target = EnemyOrigin
		
		emit_sound(ent, CHAN_WEAPON, JackSounds[18], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TRACER)
		engfunc(EngFunc_WriteCoord, Start[0])
		engfunc(EngFunc_WriteCoord, Start[1])
		engfunc(EngFunc_WriteCoord, Start[2])
		engfunc(EngFunc_WriteCoord, Target[0])
		engfunc(EngFunc_WriteCoord, Target[1])
		engfunc(EngFunc_WriteCoord, Target[2])
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TRACER)
		engfunc(EngFunc_WriteCoord, Start[0])
		engfunc(EngFunc_WriteCoord, Start[1])
		engfunc(EngFunc_WriteCoord, Start[2])
		engfunc(EngFunc_WriteCoord, Target[0] + random_float(0.0, 100.0))
		engfunc(EngFunc_WriteCoord, Target[1])
		engfunc(EngFunc_WriteCoord, Target[2])
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TRACER)
		engfunc(EngFunc_WriteCoord, Start[0])
		engfunc(EngFunc_WriteCoord, Start[1])
		engfunc(EngFunc_WriteCoord, Start[2])
		engfunc(EngFunc_WriteCoord, Target[0] - random_float(0.0, 100.0))
		engfunc(EngFunc_WriteCoord, Target[1])
		engfunc(EngFunc_WriteCoord, Target[2])
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_TRACER)
		engfunc(EngFunc_WriteCoord, Start[0])
		engfunc(EngFunc_WriteCoord, Start[1])
		engfunc(EngFunc_WriteCoord, Start[2])
		engfunc(EngFunc_WriteCoord, Target[0])
		engfunc(EngFunc_WriteCoord, Target[1] + random_float(0.0, 100.0))
		engfunc(EngFunc_WriteCoord, Target[2] + random_float(0.0, 100.0))
		message_end()
		
		if(random_num(0, 3) == 2) ExecuteHamB(Ham_TakeDamage, Victim, 0, Victim, random_float(0.0, 20.0), DMG_BULLET)
	}
	
	set_task(0.1, "Jack_ShootingM134", ent+TASK_TELEPORT)
}

public Jack_ShootingRocket(ent)
{
	ent -= TASK_TELEPORT
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_body, 0)
		
	static Victim; Victim = pev(ent, pev_enemy)
	static Float:EnemyOrigin[3]
	pev(Victim, pev_origin, EnemyOrigin)
	
	static SW; SW = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(SW)) return
		
	static Float:Start[3], Float:Angles[3]
	get_position(ent, 60.0, 30.0, 60.0, Start)
	pev(ent, pev_angles, Angles)
		
	engfunc(EngFunc_SetOrigin, SW, Start)
	set_pev(SW, pev_angles, Angles)
	
	Aim_To2(SW, EnemyOrigin)
		
	// Set Config
	set_pev(SW, pev_classname, "rk")
	engfunc(EngFunc_SetModel, SW, JACK_ROCKET)
	set_pev(SW, pev_solid, SOLID_TRIGGER)
	set_pev(SW, pev_movetype, MOVETYPE_FLY)
	set_pev(SW, pev_gravity, 0.01)
	
	// Set Size
	new Float:maxs[3] = {10.0, 10.0, 10.0}
	new Float:mins[3] = {-10.0, -10.0, -10.0}
	entity_set_size(SW, mins, maxs)
	
	hook_ent2(SW, EnemyOrigin, 1500.0)
	set_pev(SW, pev_nextthink, get_gametime() + 0.1)
	
	set_task(1.0, "Jack_ReloadRocket", ent+TASK_TELEPORT)
}

// =========== 
public fw_Jack_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return HAM_IGNORED
	if(g_BossState == STATE_APPEAR)
		return HAM_SUPERCEDE
     
	static Classname[32]
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
	     
	if(!equal(Classname, JACK_CLASSNAME)) 
		return HAM_IGNORED
		 
	static Float:EndPos[3] 
	get_tr2(ptr, TR_vecEndPos, EndPos)

	create_blood(EndPos)
	if(is_user_alive(Attacker)) client_print(Attacker, print_center, "Health: %i", floatround(pev(Ent, pev_health) - HEALTH_OFFSET))

	return HAM_IGNORED
}

public FindClosetEnemy(ent, can_see)
{
	new Float:maxdistance = 4980.0
	new indexid = 0	
	new Float:current_dis = maxdistance

	for(new i = 1 ;i <= g_MaxPlayers; i++)
	{
		if(can_see)
		{
			if(is_user_alive(i) && can_see_fm(ent, i) && entity_range(ent, i) < current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}
		} else {
			if(is_user_alive(i) && entity_range(ent, i) < current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}			
		}
	}	
	
	return indexid
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}

public Aim_To(iEnt, Float:vTargetOrigin[3], Float:flSpeed, Style)
{
	if(!pev_valid(iEnt))	
		return
		
	if(!Style)
	{
		static Float:Vec[3], Float:Angles[3]
		pev(iEnt, pev_origin, Vec)
		
		Vec[0] = vTargetOrigin[0] - Vec[0]
		Vec[1] = vTargetOrigin[1] - Vec[1]
		Vec[2] = vTargetOrigin[2] - Vec[2]
		engfunc(EngFunc_VecToAngles, Vec, Angles)
		Angles[0] = Angles[2] = 0.0 
		
		set_pev(iEnt, pev_v_angle, Angles)
		set_pev(iEnt, pev_angles, Angles)
	} else {
		new Float:f1, Float:f2, Float:fAngles, Float:vOrigin[3], Float:vAim[3], Float:vAngles[3];
		pev(iEnt, pev_origin, vOrigin);
		xs_vec_sub(vTargetOrigin, vOrigin, vOrigin);
		xs_vec_normalize(vOrigin, vAim);
		vector_to_angle(vAim, vAim);
		
		if (vAim[1] > 180.0) vAim[1] -= 360.0;
		if (vAim[1] < -180.0) vAim[1] += 360.0;
		
		fAngles = vAim[1];
		pev(iEnt, pev_angles, vAngles);
		
		if (vAngles[1] > fAngles)
		{
			f1 = vAngles[1] - fAngles;
			f2 = 360.0 - vAngles[1] + fAngles;
			if (f1 < f2)
			{
				vAngles[1] -= flSpeed;
				vAngles[1] = floatmax(vAngles[1], fAngles);
			}
			else
			{
				vAngles[1] += flSpeed;
				if (vAngles[1] > 180.0) vAngles[1] -= 360.0;
			}
		}
		else
		{
			f1 = fAngles - vAngles[1];
			f2 = 360.0 - fAngles + vAngles[1];
			if (f1 < f2)
			{
				vAngles[1] += flSpeed;
				vAngles[1] = floatmin(vAngles[1], fAngles);
			}
			else
			{
				vAngles[1] -= flSpeed;
				if (vAngles[1] < -180.0) vAngles[1] += 360.0;
			}		
		}
	
		set_pev(iEnt, pev_v_angle, vAngles)
		set_pev(iEnt, pev_angles, vAngles)
	}
}

public Aim_To2(iEnt, Float:vTargetOrigin[3])
{
	if(!pev_valid(iEnt))	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(iEnt, pev_origin, Vec)
	
	Vec[0] = vTargetOrigin[0] - Vec[0]
	Vec[1] = vTargetOrigin[1] - Vec[1]
	Vec[2] = vTargetOrigin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	//Angles[0] = Angles[2] = 0.0 
	
	set_pev(iEnt, pev_v_angle, Angles)
	set_pev(iEnt, pev_angles, Angles)
}

public Make_PlayerShake(id)
{
	if(!id) 
	{
		message_begin(MSG_BROADCAST, g_MsgScreenShake)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, g_MsgScreenShake, _, id)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	}
}

stock fuck_ent(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (EntOrigin[0]- VicOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[1]- VicOrigin[1]) / fl_Time
	fl_Velocity[2] = (EntOrigin[2]- VicOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

stock Set_EntAnim(ent, anim, Float:framerate, resetframe)
{
	if(!pev_valid(ent))
		return
	
	if(!resetframe)
	{
		if(pev(ent, pev_sequence) != anim)
		{
			set_pev(ent, pev_animtime, get_gametime())
			set_pev(ent, pev_framerate, framerate)
			set_pev(ent, pev_sequence, anim)
		}
	} else {
		set_pev(ent, pev_animtime, get_gametime())
		set_pev(ent, pev_framerate, framerate)
		set_pev(ent, pev_sequence, anim)
	}
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent))
		return
		
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
