#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define FT_MODEL "models/fallentitan/fallentitan.mdl"
#define FT_CLASSNAME "fallentitan"

#define CANNON_MODEL "models/shell_svdex.mdl"

#define FT_HEALTH 20000.0
#define FT_SPEED 200.0

#define HEALTH_OFFSET 10000.0

#define FT_ATTACK_RANGE 200.0
#define ATTACK1_RADIUS 200.0
#define ATTACK2_RADIUS 200.0
#define ATTACK_DAMAGE random_float(10.0, 15.0)
#define FT_ATTACK_CANNON_DAMAGE random_float(30.0, 50.0)

new const FT_Sounds[18][] = 
{
	"fallentitan/death.wav",
	"fallentitan/footstep1.wav",
	"fallentitan/footstep2.wav",
	"fallentitan/landmine_drop1.wav",
	"fallentitan/landmine_drop2.wav",
	"fallentitan/landmine_drop3.wav",
	"fallentitan/landmine_drop4.wav",
	"fallentitan/landmine_exp.wav",
	"fallentitan/landmine_jut.wav",
	"fallentitan/scene_appear1.wav",
	"fallentitan/scene_appear3.wav",
	"fallentitan/scene_howling.wav",
	"fallentitan/zbs_attack1.wav",
	"fallentitan/zbs_attack2.wav",
	"fallentitan/zbs_cannon_ready.wav",
	"fallentitan/zbs_cannon1.wav",
	"fallentitan/zbs_idle1.wav",
	"fallentitan/zbs_landmine1.wav"
}

#define READY_MUSIC "fallentitan/background/Scenario_Ready.mp3"
#define FIGHT_MUSIC "fallentitan/background/Scenario_Normal.mp3"

enum
{
	FT_ANIM_DUMMY = 0,
	FT_ANIM_SCENE_APPEAR1,
	FT_ANIM_SCENE_APPEAR2,
	FT_ANIM_SCENE_APPEAR3,
	FT_ANIM_HOWLING,
	FT_ANIM_IDLE,
	FT_ANIM_WALK,
	FT_ANIM_RUN,
	FT_ANIM_DASH_BEGIN,
	FT_ANIM_DASH_ING,
	FT_ANIM_DASH_END,
	FT_ANIM_ATTACK1,
	FT_ANIM_ATTACK2,
	FT_ANIM_CANNON_BEGIN,
	FT_ANIM_CANNON_ING,
	FT_ANIM_CANNON_END,
	FT_ANIM_CANNON_SPECIAL,
	FT_ANIM_LANDMINE1,
	FT_ANIM_LANDMINE2,
	FT_ANIM_DEATH
}

enum
{
	FT_STATE_IDLE = 0,
	FT_STATE_APPEARING1,
	FT_STATE_APPEARING2,
	FT_STATE_APPEARING3,
	FT_STATE_APPEARING4,
	FT_STATE_SEARCHING_ENEMY,
	FT_STATE_CHASE_ENEMY,
	FT_STATE_ATTACK_NORMAL,
	FT_STATE_ATTACK_DASH,
	FT_STATE_ATTACK_CANNON,
	FT_STATE_DEATH
}

// Start Origin
#define STARTORIGIN_X 900.575744
#define STARTORIGIN_Y 0.229084
#define STARTORIGIN_Z 300.031250

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016

const pev_state = pev_iuser1
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, g_Reg_Ham
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep, m_iBlood[2], spr_trail, g_expspr_id, g_SmokeSprId

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(FT_CLASSNAME, "fw_FT_Think")
	register_touch("grenade2", "*", "fw_Grenade_Touch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()

	//register_cmd("dash", "FT_Do_Dash")
	//register_clcmd("cannon", "FT_Do_Cannon")
}

public FT_Do_Dash()
{
	FT_Attack_Dash(g_CurrentBoss_Ent)
}

public FT_Do_Cannon()
{
	FT_Attack_Cannon(g_CurrentBoss_Ent)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, FT_MODEL)
	
	for(new i = 0; i < sizeof(FT_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, FT_Sounds[i])
		
	engfunc(EngFunc_PrecacheSound, READY_MUSIC)
	engfunc(EngFunc_PrecacheSound, FIGHT_MUSIC)
	
	engfunc(EngFunc_PrecacheModel, CANNON_MODEL)
	
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_expspr_id = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
	g_SmokeSprId = engfunc(EngFunc_PrecacheModel, "sprites/steam1.spr")	
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")		
}

public plugin_cfg()
{
	server_cmd("mp_roundtime 10.0")
	server_cmd("mp_freezetime 20.0")
}

public Event_NewRound()
{
	remove_task(TASK_GAME_START)
	
	PlaySound(0, READY_MUSIC)
}

public Event_RoundStart()
{
	PlaySound(0, FIGHT_MUSIC)

	set_hudmessage(0, 200, 0, -1.0, 0.22, 1, 3.0, 3.0)
	show_hudmessage(0, "Fallen Titan Is Coming !!!")
	
	set_task(2.0, "Game_Start", TASK_GAME_START)
}

public Game_Start()
{
	Break_Main_Door()
	Create_Boss()
}

public Break_Main_Door()
{
	static String[64]
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(!pev_valid(i))
			continue
		pev(i, pev_classname, String, sizeof(String))
		if(!equal(String, "func_breakable"))
			continue
		pev(i, pev_targetname, String, sizeof(String))
		if(!equal(String, "door_brk"))
			continue

		ExecuteHam(Ham_TakeDamage, i, 0, i, 100.0, DMG_BLAST)
	}
}

public Create_Boss()
{
	if(pev_valid(g_CurrentBoss_Ent))
		engfunc(EngFunc_RemoveEntity, g_CurrentBoss_Ent)
	
	static FT; FT = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(FT)) return
	
	g_CurrentBoss_Ent = FT

	static Float:StartOrigin[3]

	// Set Origin & Angles
	StartOrigin[0] = STARTORIGIN_X; StartOrigin[1] = STARTORIGIN_Y; StartOrigin[2] = STARTORIGIN_Z
	set_pev(FT, pev_origin, StartOrigin)
	
	static Float:Angles[3]
	Angles[1] = 179.0
	
	set_pev(FT, pev_angles, Angles)
	set_pev(FT, pev_v_angle, Angles)
	
	// Set Config
	set_pev(FT, pev_classname, FT_CLASSNAME)
	engfunc(EngFunc_SetModel, FT, FT_MODEL)
		
	set_pev(FT, pev_gamestate, 1)
	set_pev(FT, pev_solid, SOLID_BBOX)
	set_pev(FT, pev_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {57.0, 67.0, 184.0}
	new Float:mins[3] = {-57.0, -67.0, 20.0}
	engfunc(EngFunc_SetSize, FT, mins, maxs)
	
	// Set Life
	set_pev(FT, pev_takedamage, DAMAGE_YES)
	set_pev(FT, pev_health, HEALTH_OFFSET + FT_HEALTH)
	
	// Set Config 2
	set_entity_anim(FT, FT_ANIM_IDLE, 1.0)
	set_pev(FT, pev_state, FT_STATE_APPEARING1)

	set_pev(FT, pev_nextthink, get_gametime() + 1.0)
	engfunc(EngFunc_DropToFloor, FT)
	
	set_pev(FT, pev_time2, get_gametime() + 1.0)
	
	if(!g_Reg_Ham)
	{
		g_Reg_Ham = 1
		RegisterHamFromEntity(Ham_TraceAttack, FT, "fw_FT_TraceAttack")
	}	
}

public fw_FT_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == FT_STATE_DEATH)
		return
	if((pev(ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		FT_Death(ent)
		return
	}

	switch(pev(ent, pev_state))
	{
		case FT_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, FT_ANIM_IDLE, 1.0)
				PlaySound(0, FT_Sounds[16])
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_APPEARING1:
		{
			static Float:Ahead[3]
			get_position(ent, 1000.0, 0.0, 0.0, Ahead)

			MM_Aim_To(ent, Ahead)
			hook_ent2(ent, Ahead, FT_SPEED - 50.0)
			
			if(get_gametime() - 4.76 > pev(ent, pev_time))
			{
				set_entity_anim(ent, FT_ANIM_WALK, 1.0)
				set_pev(ent, pev_time, get_gametime())
			}	
			if(get_gametime() - 1.0 > pev(ent, pev_time3))
			{
				if(g_FootStep != 1) g_FootStep = 1
				else g_FootStep = 2
				PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
				
				set_pev(ent, pev_time3, get_gametime())
			}
			if(get_gametime() - 5.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, FT_STATE_APPEARING2)
				set_pev(ent, pev_time, get_gametime())
			}
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				if(entity_range(ent, i) > 90)
					continue
					
				user_kill(i)
			}

			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_APPEARING2:
		{
			set_entity_anim(ent, FT_ANIM_IDLE, 1.0)

			set_pev(ent, pev_state, FT_STATE_APPEARING3)
			set_pev(ent, pev_nextthink, get_gametime() + 0.5)
		}
		case FT_STATE_APPEARING3:
		{
			set_pev(ent, pev_movetype, MOVETYPE_NONE)
			set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
			
			set_pev(ent, pev_state, FT_STATE_APPEARING4)
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		}
		case FT_STATE_APPEARING4:
		{
			set_entity_anim(ent, FT_ANIM_HOWLING, 1.0)
			PlaySound(0, FT_Sounds[11])
			set_task(0.75, "Make_PlayerShake", 0)
			
			set_pev(ent, pev_state, FT_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 4.6)
		}
		case FT_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 1)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, FT_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(FT_ATTACK_RANGE))
				{
					set_pev(ent, pev_state, FT_STATE_ATTACK_NORMAL)
					
					MM_Aim_To(ent, EnemyOrigin) 
					
					if(random_num(0, 1) == 1)
						set_task(0.1, "FT_StartAttack1", ent+TASK_ATTACK)
					else 
						set_task(0.1, "FT_StartAttack2", ent+TASK_ATTACK)
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, FT_SPEED + 30.0)
						
						set_entity_anim2(ent, FT_ANIM_RUN, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 10.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 6)
							if(rand == 1)
								FT_Attack_Dash(ent)
							else if(rand == 2) FT_Attack_Cannon(ent)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}	
		case (FT_STATE_ATTACK_DASH + 1000):
		{
			static Float:Ahead[3], Float:CheckOrigin[3]
			get_position(ent, 1000.0, 0.0, 0.0, Ahead)

			MM_Aim_To(ent, Ahead)
			hook_ent2(ent, Ahead, FT_SPEED * 10.0)	
			
			get_position(ent, 150.0, 0.0, 0.0, CheckOrigin)
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				
				pev(i, pev_origin, Ahead)
					
				if(get_distance_f(Ahead, CheckOrigin) > 100.0)
					continue
					
				ExecuteHam(Ham_TakeDamage, i, 0, i, ATTACK_DAMAGE * 100.0, DMG_BLAST)
				
				static Float:Velocity[3]
				Velocity[0] = random_float(1000.0, 5000.0)
				Velocity[1] = random_float(1000.0, 5000.0)
				Velocity[2] = random_float(1000.0, 5000.0)
			}
			
			if(get_gametime() - 1.0 > pev(ent, pev_time3))
			{
				if(g_FootStep != 1) g_FootStep = 1
				else g_FootStep = 2
			
				PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
				
				set_pev(ent, pev_time3, get_gametime())
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}

public fw_FT_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return
     
	static Classname[32]
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
	     
	if(!equal(Classname, FT_CLASSNAME)) 
		return
		 
	static Float:EndPos[3] 
	get_tr2(ptr, TR_vecEndPos, EndPos)

	create_blood(EndPos)
	if(is_user_alive(Attacker)) client_print(Attacker, print_center, "Fallen Titan's Health: %i", floatround(pev(Ent, pev_health) - HEALTH_OFFSET))
}

public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(1, 99)
	
	if(RandomNum >= 0 && RandomNum <= 60)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 61 && RandomNum <= 80)
		FT_Attack_Dash(ent)
	else if(RandomNum >= 81 && RandomNum <= 100)
		FT_Attack_Cannon(ent)
	else
		Random_AttackMethod(ent)
}

public FT_StartAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "FT_StartAttack1_2", ent+TASK_ATTACK)
}

public FT_StartAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "FT_StartAttack2_2", ent+TASK_ATTACK)	
}

public FT_StartAttack1_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, FT_ANIM_ATTACK1, 1.0)
	PlaySound(0, FT_Sounds[12])
	
	set_task(1.5, "FT_CheckAttack1", ent+TASK_ATTACK)
	set_task(3.6, "FT_DoneAttack", ent+TASK_ATTACK)	
}

public FT_StartAttack2_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, FT_ANIM_ATTACK2, 1.0)
	PlaySound(0, FT_Sounds[13])
	
	set_task(1.0, "FT_CheckAttack2", ent+TASK_ATTACK)
	set_task(3.7, "FT_DoneAttack", ent+TASK_ATTACK)	
}

public FT_CheckAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 200.0, 80.0, 0.0, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK1_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, i, ATTACK_DAMAGE, DMG_BLAST)
		
		static Float:Velocity[3]
		Velocity[0] = random_float(100.0, 200.0)
		Velocity[1] = random_float(100.0, 200.0)
		Velocity[2] = random_float(100.0, 400.0)
		set_pev(i, pev_velocity, Velocity)
		
		Make_PlayerShake(i)
	}
}

public FT_CheckAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	static Float:CheckPosition[3], Float:VicOrigin[3]
	pev(ent, pev_origin, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK2_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, i, ATTACK_DAMAGE * 1.5, DMG_BLAST)
	
		static Float:Velocity[3]
		Velocity[0] = random_float(10.0, 50.0)
		Velocity[1] = random_float(10.0, 50.0)
		Velocity[2] = random_float(100.0, 600.0)
		set_pev(i, pev_velocity, Velocity)
		
		Make_PlayerShake(i)
	}	
}

public FT_DoneAttack(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)		
	set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public FT_Attack_Dash(ent)
{
	if(pev(ent, pev_state) == FT_STATE_CHASE_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		set_pev(ent, pev_state, FT_STATE_ATTACK_DASH)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "FT_Start_Attack_Dash", ent+TASK_ATTACK)	
	}
}

public FT_Start_Attack_Dash(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_entity_anim(ent, FT_ANIM_DASH_BEGIN, 1.0)
	set_task(1.3, "FT_Start_Dashing", ent+TASK_ATTACK)
}

public Reset_MoveType(ent)
{
	if(!pev_valid(ent))
		return		
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
}

public FT_Start_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_DASH_ING, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_DASH + 1000)
	
	set_task(0.1, "Reset_MoveType", ent)
	set_task(2.0, "FT_Stop_Dashing", ent+TASK_ATTACK)
	set_pev(ent, pev_nextthink, get_gametime() + 0.2)
}

public FT_Stop_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_DASH_END, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_DASH)
	
	set_task(1.7, "FT_End_Dashing", ent+TASK_ATTACK)
}

public FT_End_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)		
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public FT_Attack_Cannon(ent)
{
	if(pev(ent, pev_state) == FT_STATE_CHASE_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "FT_Start_Attack_Cannon", ent+TASK_ATTACK)	
	}
}

public FT_Start_Attack_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
		
	set_entity_anim(ent, FT_ANIM_CANNON_BEGIN, 1.0)
	set_task(0.6, "Cannon_StartSound")
	set_task(1.43, "FT_Attacking_Cannon", ent+TASK_ATTACK)
}

public Cannon_StartSound() PlaySound(0, FT_Sounds[14])

public FT_Attacking_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_CANNON_ING, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.25, "FT_Shoot_Cannon", ent+TASK_ATTACK, _, _, "b")
	set_task(3.0, "FT_Stop_Cannon", ent+TASK_ATTACK)
}

public FT_Shoot_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_CANNON_ING, 1.0)
	
	static Float:StartOrigin[3], Float:TargetOrigin[3][3], Float:Angles[3]
	pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
	
	get_position(ent, 50.0, -50.0, 80.0, StartOrigin)
	
	get_position(ent, 1000.0, random_float(-200.0, 200.0), random_float(-30.0, 60.0), TargetOrigin[0])
	get_position(ent, 1000.0, random_float(-200.0, 200.0), random_float(-30.0, 60.0), TargetOrigin[1])
	get_position(ent, 1000.0, random_float(-200.0, 200.0), random_float(-30.0, 60.0), TargetOrigin[2])
	
	pev(ent, pev_angles, Angles)
	
	for(new i = 0; i < 3; i++)
		Shoot_Cannon(StartOrigin, Angles, TargetOrigin[i])
}

public Shoot_Cannon(Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3])
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	
	set_pev(Ent, pev_classname, "grenade2")
	engfunc(EngFunc_SetModel, Ent, CANNON_MODEL)
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_v_angle, Angles)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)	
	
	// Create Velocity
	static Float:Velocity[3]
	get_speed_vector(StartOrigin, TargetOrigin, 5000.0, Velocity)
	//VelocityByAim(Ent, random_num(500, 2500), Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(spr_trail) // sprite
	write_byte(10)  // life
	write_byte(4)  // width
	write_byte(200) // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();	
}

public fw_Grenade_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	new Classname[32]
	if(pev_valid(id)) pev(id, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "grenade2") || equal(Classname, FT_CLASSNAME))
		return
		
	Make_Explosion(ent)
	remove_entity(ent)
}

public Make_Explosion(ent)
{
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expspr_id)	// sprite index
	write_byte(30)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(0)	// flags
	message_end()
	
	// Put decal on "world" (a wall)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(random_num(46, 48))
	message_end()	
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_SmokeSprId)	// sprite index 
	write_byte(30)	// scale in 0.1's 
	write_byte(10)	// framerate 
	message_end()
	
	static Float:Origin2[3]
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, Origin2)
		if(get_distance_f(Origin, Origin2) > 200.0)
			continue

		ExecuteHamB(Ham_TakeDamage, i, 0, i, FT_ATTACK_CANNON_DAMAGE, DMG_BULLET)
	}
}


public FT_Stop_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
	
	remove_task(ent+TASK_ATTACK)
	
	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON)
	set_entity_anim(ent, FT_ANIM_CANNON_END, 1.0)
	
	set_task(1.43, "FT_End_Cannon", ent+TASK_ATTACK)
}

public FT_End_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)		
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public FT_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	
	set_pev(ent, pev_state, FT_STATE_DEATH)

	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "FT_Death2", ent)	
}

public FT_Death2(ent)
{
	set_task(0.3, "FT_Death_Sound", ent)
	set_entity_anim(ent, FT_ANIM_DEATH, 1.0)
}

public FT_Death_Sound(ent) PlaySound(0, FT_Sounds[0])

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

public MM_Aim_To(ent, Float:Origin[3]) 
{
	if(!pev_valid(ent))	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(ent, pev_origin, Vec)
	
	Vec[0] = Origin[0] - Vec[0]
	Vec[1] = Origin[1] - Vec[1]
	Vec[2] = Origin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	Angles[0] = Angles[2] = 0.0 
	
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
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

stock set_entity_anim(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock set_entity_anim2(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return

	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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


stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
