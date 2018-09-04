#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN "[Dias's NPC] Goliath"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define GOLIATH_HEALTH 500.0
#define GOLIATH_CLASSNAME "goliath"
#define ROCKET_DAMAGE 30.0
#define FIRE_DAMAGE 25.0
#define SHOOT_DAMAGE 40.0

new const goliath_model[] = "models/goliath/goliath.mdl"

// MainCode
new goliath_model_id, g_reg, g_ent, g_doing_skill, g_doing_special, g_special_count, g_special_shoot
new Float:MyOrigin[3], Float:MyAngles[3], Float:MyVAngle[3], Float:g_last_check
#define TASK_IDLE 56765

// Shoot Code
new g_shoot_vir_ent1, g_shoot_vir_ent2, g_shoot_vir_ent3, g_shoot_vir_ent4
#define TASK_SHOOT 4123125
#define TASK_S_ROTATE 412312
#define TASK_S_ROTATE_M1 412313
#define TASK_S_ROTATE_M2 412314
#define TASK_S_ROTATE_M3 42316
new g_shoot_rotate_mode, g_shoot_count
new g_blood, g_bloodspray

// Missile
new const missile_model[] = "models/goliath/dron_missile.mdl"
new const missile_sound[1][] = {
	"goliath/dron_missle_exp.wav"
}
#define TASK_DO_MISSILE 322543
#define MISSILE_TIME 3
#define MISSILE_CLASSNAME "missile_goliath"
new g_missile_count, g_missile_vir_ent1, g_missile_vir_ent2
new g_exp_spr_id, g_smoke_spr_id

// FireCode
new const fire_spr_name[] = "sprites/fire_salamander.spr"
#define FIRE_CLASSNAME "fire_goliath"
new g_virtual_ent1, g_fire_rotate_mode, g_fire_count
#define TASK_FIRE 3123125
#define TASK_ROTATE 312312
#define TASK_ROTATE_M1 312313
#define TASK_ROTATE_M2 312314
#define TASK_ROTATE_M3 312316

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	
	// Fire Salamander
	register_forward(FM_Touch, "fw_touch")
	register_think(FIRE_CLASSNAME, "fw_fire_think")	
	register_think(MISSILE_CLASSNAME, "fw_missile_think")	
	
	register_clcmd("say /get_origin", "get_origin")
	register_clcmd("say /make", "create_goliath")
	
	register_clcmd("say /did", "did_skill")
}

public plugin_precache()
{
	// Fire Code
	precache_model(fire_spr_name)
	
	// Missile Code
	precache_model(missile_model)
	g_exp_spr_id = precache_model("sprites/zerogxplode.spr")
	g_smoke_spr_id = precache_model("sprites/steam1.spr")
	for(new i = 0; i < sizeof(missile_sound); i++)
		precache_sound(missile_sound[i])
	
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")	
	goliath_model_id = engfunc(EngFunc_PrecacheModel, goliath_model)
}

public get_origin(id)
{
	pev(id, pev_origin, MyOrigin)
	pev(id, pev_angles, MyAngles)
	pev(id, pev_v_angle, MyVAngle)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, MyOrigin[0])
	engfunc(EngFunc_WriteCoord, MyOrigin[0])
	engfunc(EngFunc_WriteCoord, MyOrigin[0])
	write_short(g_exp_spr_id)	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()	
}

public create_goliath(id)
{
	new ent = create_entity("info_target")
	g_ent = ent
	
	entity_set_origin(ent, MyOrigin)

	MyVAngle[0] = 0.0
	set_pev(ent, pev_angles, MyVAngle)
	set_pev(ent, pev_v_angle, MyVAngle)
	
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_health, GOLIATH_HEALTH + 1000.0)
	
	entity_set_string(ent,EV_SZ_classname, GOLIATH_CLASSNAME)
	entity_set_model(ent, goliath_model)
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_STEP)
	
	new Float:maxs[3] = {200.0, 200.0, 300.0}
	new Float:mins[3] = {-200.0, -200.0, -0.0}
	entity_set_size(ent, mins, maxs)
	entity_set_int(ent, EV_INT_modelindex, goliath_model_id)
	
	set_pev(ent, pev_controller, 125)
	set_pev(ent, pev_controller_0, 125)
	set_pev(ent, pev_controller_1, 125)
	set_pev(ent, pev_controller_2, 125)
	set_pev(ent, pev_controller_3, 125)
	
	set_entity_anim(ent, 1)
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 3.0)
	set_task(3.0, "start_goliath", ent)
	
	if(!g_reg)
	{
		RegisterHamFromEntity(Ham_TakeDamage, ent, "fw_takedmg", 1)
		RegisterHamFromEntity(Ham_Think, ent, "fw_think")
		g_reg = 1
	}	
	
	g_doing_skill = 0
	g_doing_special = 0
	
	drop_to_floor(ent)
}

public start_goliath(ent)
{
	set_entity_anim(ent, 2)
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1)
}

public did_skill(id)
{	
	//starting_flame(g_ent)
	//starting_missile(g_ent)
	//starting_shoot(g_ent)
}

public set_idle(ent)
{
	ent -= TASK_IDLE
	
	set_entity_anim(ent, 2)
	g_doing_skill = 0
	g_doing_special = 0
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)		
}

public goliath_death(ent)
{
	set_entity_anim(ent, 4)
	set_task(15.0, "move_entity", ent)
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)
	entity_set_float(ent, EV_FL_takedamage, 0.0)
}

public move_entity(ent)
{
	remove_entity(ent)
}

public stop_all_skill(ent)
{
	// Stop Fire
	remove_entity(g_virtual_ent1)
	
	remove_task(ent+TASK_FIRE)
	remove_task(ent+TASK_ROTATE)
	remove_task(ent+TASK_ROTATE_M1)
	remove_task(ent+TASK_ROTATE_M2)
	remove_task(ent+TASK_ROTATE_M3)	
	
	// Stop Missile
	remove_task(ent+TASK_DO_MISSILE)
	
	remove_entity(g_missile_vir_ent1)
	remove_entity(g_missile_vir_ent2)
	
	// Stop Shoot
	remove_entity(g_shoot_vir_ent1)
	remove_entity(g_shoot_vir_ent2)
	remove_entity(g_shoot_vir_ent3)
	remove_entity(g_shoot_vir_ent4)	
	
	remove_task(ent+TASK_SHOOT)
	remove_task(ent+TASK_S_ROTATE)
	remove_task(ent+TASK_S_ROTATE_M1)
	remove_task(ent+TASK_S_ROTATE_M2)
	remove_task(ent+TASK_S_ROTATE_M3)	
	
	// Reset Main
	set_pev(ent, pev_controller_0, 125)
	set_entity_anim(ent, 2)
	g_doing_skill = 0	
	g_special_shoot = 0
	g_doing_special = 0
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)
}

public event_newround()
{
	stop_all_skill(g_ent)
	
	g_doing_skill = 0
	g_doing_special = 0
	g_special_shoot = 0
	
	remove_entity_name(GOLIATH_CLASSNAME)
}

// Shoot Code
public starting_shoot(ent, special)
{
	if(g_doing_skill || g_doing_special)
		return PLUGIN_HANDLED
	
	g_shoot_vir_ent1 = create_entity("info_target")
	g_shoot_vir_ent2 = create_entity("info_target")
	g_shoot_vir_ent3 = create_entity("info_target")
	g_shoot_vir_ent4 = create_entity("info_target")	

	set_pev(ent, pev_controller_0, 140)
	
	if(special)
	{
		g_doing_skill = 0
		g_special_shoot = 1
		set_entity_anim(ent, 14)
	}
	else 
	{
		g_doing_skill = 1
		g_special_shoot = 0
		set_entity_anim(ent, 8)
	}
	
	static Float:Origin1[3], Float:Origin2[3], Float:Angles[3]

	get_position(ent, 225.0, 170.0, 250.0, Origin1)
	get_position(ent, 225.0, -170.0, 250.0, Origin2)
	
	pev(ent, pev_angles, Angles)

	set_pev(g_shoot_vir_ent1, pev_origin, Origin1)
	set_pev(g_shoot_vir_ent2, pev_origin, Origin2)	
	
	Angles[0] -= 15.0
	
	set_pev(g_shoot_vir_ent1, pev_angles, Angles)
	set_pev(g_shoot_vir_ent2, pev_angles, Angles)
	
	Angles[0] -= Angles[0] * 2
	set_pev(g_shoot_vir_ent1, pev_v_angle, Angles)
	set_pev(g_shoot_vir_ent2, pev_v_angle, Angles)	
	
	reset_vector(ent)
	
	set_task(1.0, "do_shoot", ent+TASK_SHOOT)	
	
	if(!special)
		set_task(3.0, "do_shoot_rotate_m1", ent+TASK_S_ROTATE)
	else
		set_task(11.0, "stop_shoot", ent)
	
	return PLUGIN_HANDLED	
}

public stop_shoot(ent)
{
	if(!pev_valid(ent))
		return PLUGIN_HANDLED
	
	remove_entity(g_shoot_vir_ent1)
	remove_entity(g_shoot_vir_ent2)
	remove_entity(g_shoot_vir_ent3)
	remove_entity(g_shoot_vir_ent4)	
	
	set_pev(ent, pev_controller_0, 125)
	
	remove_task(ent+TASK_SHOOT)
	remove_task(ent+TASK_S_ROTATE)
	remove_task(ent+TASK_S_ROTATE_M1)
	remove_task(ent+TASK_S_ROTATE_M2)
	remove_task(ent+TASK_S_ROTATE_M3)	
	
	if(g_special_shoot)
	{
		g_special_shoot = 0
		g_doing_special = 0
		
		set_entity_anim(ent, 16)
		set_task(0.1, "set_idle", ent+TASK_IDLE)
	} else {
		g_special_shoot = 0
		g_doing_special = 0
		
		set_entity_anim(ent, 7)
		set_task(1.0, "set_idle", ent+TASK_IDLE)
	}
	
	return PLUGIN_HANDLED
}

public do_shoot_rotate_m1(ent)
{
	ent -= TASK_S_ROTATE

	g_shoot_rotate_mode = 1
	g_shoot_count = 50
	
	set_entity_anim(ent, 9)
	set_task(0.1, "shoot_rotate_m1", ent+TASK_S_ROTATE_M1)
}

public shoot_rotate_m1(ent)
{
	ent -= TASK_S_ROTATE_M1
	
	if(g_shoot_rotate_mode != 1)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_shoot_count > 0)
	{
		Angles[1] -= 1.0
		g_shoot_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.075, "shoot_rotate_m1", ent+TASK_S_ROTATE_M1)
	} else {
		g_shoot_rotate_mode = 2
		g_shoot_count = 100
		
		set_task(0.1, "shoot_rotate_m2", ent+TASK_S_ROTATE_M2)
	}
	
	return PLUGIN_HANDLED
}

public shoot_rotate_m2(ent)
{
	ent -= TASK_S_ROTATE_M2
	
	if(g_shoot_rotate_mode != 2)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_shoot_count > 0)
	{
		Angles[1] += 1.0
		g_shoot_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.075, "shoot_rotate_m2", ent+TASK_S_ROTATE_M2)
	} else {
		g_shoot_rotate_mode = 3
		g_shoot_count = 50
		
		set_task(0.1, "shoot_rotate_m3", ent+TASK_S_ROTATE_M3)
	}
	
	return PLUGIN_HANDLED
}

public shoot_rotate_m3(ent)
{
	ent -= TASK_S_ROTATE_M3
	
	if(g_shoot_rotate_mode != 3)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_shoot_count > 0)
	{
		Angles[1] -= 1.0
		g_shoot_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.075, "shoot_rotate_m3", ent+TASK_S_ROTATE_M3)
	} else {
		g_shoot_rotate_mode = 0
		g_shoot_count = 0
		
		stop_shoot(ent)
	}
	
	return PLUGIN_HANDLED
}

public do_shoot(ent)
{
	ent -= TASK_SHOOT

	static Float:Origin1[5][3], Float:Origin2[5][3], Float:AimOrigin1[5][3], Float:AimOrigin2[5][3]
	
	reset_vector(ent)
	
	if(g_special_shoot)
	{
		if(pev(ent, pev_sequence) != 15)
			set_entity_anim(ent, 15)
	} else {
		if(pev(ent, pev_sequence) != 9)
			set_entity_anim(ent, 9)		
	}

	// 1st
	get_position(g_shoot_vir_ent1, 0.0, 30.0, 0.0, Origin1[0])
	get_position(g_shoot_vir_ent3, 0.0, 30.0, 0.0, AimOrigin1[0])
	
	get_position(g_shoot_vir_ent1, 0.0, -30.0, 0.0, Origin1[1])
	get_position(g_shoot_vir_ent3, 0.0, -30.0, 0.0, AimOrigin1[1])
	
	get_position(g_shoot_vir_ent1, 0.0, 0.0, 0.0, Origin1[2])
	get_position(g_shoot_vir_ent3, 0.0, 0.0, 0.0, AimOrigin1[2])
	
	get_position(g_shoot_vir_ent1, 0.0, 0.0, -30.0, Origin1[3])
	get_position(g_shoot_vir_ent3, 0.0, 0.0, -30.0, AimOrigin1[3])
	
	get_position(g_shoot_vir_ent1, 0.0, 0.0, 30.0, Origin1[4])
	get_position(g_shoot_vir_ent3, 0.0, 0.0, 30.0, AimOrigin1[4])
	
	// 2nd
	get_position(g_shoot_vir_ent2, 0.0, 30.0, 0.0, Origin2[0])
	get_position(g_shoot_vir_ent4, 0.0, 30.0, 0.0, AimOrigin2[0])
	
	get_position(g_shoot_vir_ent2, 0.0, -30.0, 0.0, Origin2[1])
	get_position(g_shoot_vir_ent4, 0.0, -30.0, 0.0, AimOrigin2[1])
	
	get_position(g_shoot_vir_ent2, 0.0, 0.0, 0.0, Origin2[2])
	get_position(g_shoot_vir_ent4, 0.0, 0.0, 0.0, AimOrigin2[2])
	
	get_position(g_shoot_vir_ent2, 0.0, 0.0, -30.0, Origin2[3])
	get_position(g_shoot_vir_ent4, 0.0, 0.0, -30.0, AimOrigin2[3])
	
	get_position(g_shoot_vir_ent2, 0.0, 0.0, 30.0, Origin2[4])
	get_position(g_shoot_vir_ent4, 0.0, 0.0, 30.0, AimOrigin2[4])

	for(new i = 0; i < sizeof(Origin1); i++)
		create_tracer(g_shoot_vir_ent1, Origin1[i], AimOrigin1[i])
	for(new i = 0; i < sizeof(Origin1); i++)
		create_tracer(g_shoot_vir_ent2, Origin2[i], AimOrigin2[i])
	
	set_task(0.1, "do_shoot", ent+TASK_SHOOT)
}

public reset_vector(ent)
{
	static Float:Origin1[3], Float:Origin2[3], Float:Angles[3], Float:Angles2[3]

	get_position(ent, 225.0, 170.0, 250.0, Origin1)
	get_position(ent, 225.0, -170.0, 250.0, Origin2)
	
	pev(ent, pev_angles, Angles)

	set_pev(g_shoot_vir_ent1, pev_origin, Origin1)
	set_pev(g_shoot_vir_ent2, pev_origin, Origin2)	
	
	Angles[0] -= 15.0
	
	set_pev(g_shoot_vir_ent1, pev_angles, Angles)
	set_pev(g_shoot_vir_ent2, pev_angles, Angles)
	
	Angles[0] -= Angles[0] * 2
	set_pev(g_shoot_vir_ent1, pev_v_angle, Angles)
	set_pev(g_shoot_vir_ent2, pev_v_angle, Angles)	
	
	static Float:AimOrigin1[3], Float:AimOrigin2[3]
	
	fm_get_aim_origin(g_shoot_vir_ent1, AimOrigin1)
	fm_get_aim_origin(g_shoot_vir_ent2, AimOrigin2)
	
	pev(g_shoot_vir_ent1, pev_angles, Angles)
	pev(g_shoot_vir_ent2, pev_angles, Angles2)
	
	set_pev(g_shoot_vir_ent3, pev_origin, AimOrigin1)
	set_pev(g_shoot_vir_ent4, pev_origin, AimOrigin2)		
	
	set_pev(g_shoot_vir_ent3, pev_angles, Angles)
	set_pev(g_shoot_vir_ent4, pev_angles, Angles)
	
	Angles[0] -= Angles[0] * 2
	set_pev(g_shoot_vir_ent3, pev_v_angle, Angles)
	set_pev(g_shoot_vir_ent4, pev_v_angle, Angles)		
}
// End Of Shoot Code

// Missile Code
public starting_missile(ent)
{
	if(g_doing_skill || g_doing_special)
		return PLUGIN_HANDLED
	
	g_doing_skill = 1
	set_entity_anim(ent, 11)
	g_missile_count = MISSILE_TIME
	
	// Make Virtual Entity Function
	g_missile_vir_ent1 = create_entity("info_target")
	g_missile_vir_ent2 = create_entity("info_target")
	
	static Float:Origin1[3], Float:Origin2[3], Float:Angles[3]
	
	get_position(ent, 100.0, 100.0, 450.0, Origin1)
	get_position(ent, 100.0, -100.0, 450.0, Origin2)
	pev(ent, pev_angles, Angles)

	set_pev(g_missile_vir_ent1, pev_origin, Origin1)
	set_pev(g_missile_vir_ent2, pev_origin, Origin2)
	
	Angles[0] -= 10.0
	
	//Angles[1] += 30.0
	set_pev(g_missile_vir_ent1, pev_angles, Angles)
	
	//(Angles[1] += 30.0) + 30.0
	set_pev(g_missile_vir_ent2, pev_angles, Angles)
	
	Angles[0] -= Angles[0] * 2
	set_pev(g_missile_vir_ent1, pev_v_angle, Angles)
	set_pev(g_missile_vir_ent2, pev_v_angle, Angles)	
	// End Of Make Virtual Ent Func
	
	set_task(1.0, "do_rocket", ent+TASK_DO_MISSILE)
	
	return PLUGIN_HANDLED
}

public stop_missile(ent)
{
	remove_task(ent+TASK_DO_MISSILE)
	
	remove_entity(g_missile_vir_ent1)
	remove_entity(g_missile_vir_ent2)
	
	set_entity_anim(ent, 13)
	set_task(1.0, "set_idle", ent+TASK_IDLE)
}

public do_rocket(ent)
{
	ent -= TASK_DO_MISSILE
	
	if(g_missile_count >= 0)
	{
		g_missile_count--
		set_entity_anim(ent, 12)
	
		static Float:Origin1[3], Float:Origin2[3]
	
		pev(g_missile_vir_ent1, pev_origin, Origin1)
		pev(g_missile_vir_ent2, pev_origin, Origin2)
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		write_coord(floatround(Origin1[0]))
		write_coord(floatround(Origin1[1]))
		write_coord(floatround(Origin1[2]))
		write_short(g_smoke_spr_id) 
		write_byte(30) 
		write_byte(100)
		message_end()
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		write_coord(floatround(Origin2[0]))
		write_coord(floatround(Origin2[1]))
		write_coord(floatround(Origin2[2]))
		write_short(g_smoke_spr_id)
		write_byte(30) 
		write_byte(100)
		message_end()		
	
		make_coord_rocket(ent)
			
		set_task(1.0, "do_rocket", ent+TASK_DO_MISSILE)
	} else {
		stop_missile(ent)
		g_missile_count = 0
	}
}

public make_coord_rocket(ent)
{
	static Float:Origin1[5][3], Float:Origin2[5][3]
	
	// Get Coord
	
	// 1st Rocket
	get_position(g_missile_vir_ent1, 0.0, 80.0, 0.0, Origin1[0])
	get_position(g_missile_vir_ent1, 0.0, 80.0, 0.0, Origin1[0])
	
	get_position(g_missile_vir_ent1, 50.0, 40.0, 0.0, Origin1[1])
	get_position(g_missile_vir_ent1, 50.0, 40.0, 0.0, Origin1[1])
	
	get_position(g_missile_vir_ent1, 0.0, 0.0, 0.0, Origin1[2])
	get_position(g_missile_vir_ent1, 0.0, 0.0, 0.0, Origin1[2])
	
	get_position(g_missile_vir_ent1, 50.0, -40.0, 0.0, Origin1[3])
	get_position(g_missile_vir_ent1, 50.0, -40.0, 0.0, Origin1[3])	
	
	get_position(g_missile_vir_ent1, 0.0, -80.0, 0.0, Origin1[4])
	get_position(g_missile_vir_ent1, 0.0, -80.0, 0.0, Origin1[4])	
	
	// 2nd Rocket
	get_position(g_missile_vir_ent2, 0.0, 80.0, 0.0, Origin2[0])
	get_position(g_missile_vir_ent2, 0.0, 80.0, 0.0, Origin2[0])
	
	get_position(g_missile_vir_ent2, 50.0, 40.0, 0.0, Origin2[1])
	get_position(g_missile_vir_ent2, 50.0, 40.0, 0.0, Origin2[1])
	
	get_position(g_missile_vir_ent2, 0.0, 0.0, 0.0, Origin2[2])
	get_position(g_missile_vir_ent2, 0.0, 0.0, 0.0, Origin2[2])
	
	get_position(g_missile_vir_ent2, 50.0, -40.0, 0.0, Origin2[3])
	get_position(g_missile_vir_ent2, 50.0, -40.0, 0.0, Origin2[3])	
	
	get_position(g_missile_vir_ent2, 0.0, -80.0, 0.0, Origin2[4])
	get_position(g_missile_vir_ent2, 0.0, -80.0, 0.0, Origin2[4])	
	
	for(new i = 0; i < sizeof(Origin1); i++)
		make_rocket(g_missile_vir_ent1, Origin1[i])
	for(new i = 0; i < sizeof(Origin2); i++)
		make_rocket(g_missile_vir_ent2, Origin2[i])	
}

public make_rocket(start_ent, Float:Origin[3])
{
	new ent = create_entity("info_target")

	static Float:Angles[3]
	pev(start_ent, pev_angles, Angles)
	
	set_pev(ent, pev_angles, Angles)
	Angles[0] -= Angles[0] * 2
	set_pev(ent, pev_v_angle, Angles)
	set_pev(ent, pev_fuser4, Angles[0])

	entity_set_origin(ent, Origin)
	
	entity_set_string(ent,EV_SZ_classname, MISSILE_CLASSNAME)
	entity_set_model(ent, missile_model)
	entity_set_int(ent, EV_INT_solid, 2)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(ent, mins, maxs)
	
	set_pev(ent, pev_owner, start_ent)
	set_pev(ent, pev_fuser3, random_float(1000.0, 2000.0))
	
	set_entity_anim(ent, 0)
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01)
}

public fw_missile_think(missile)
{
	if(!pev_valid(missile))
		return
		
	static owner
		
	if(pev_valid(pev(missile, pev_owner)))
	{
		owner = pev(missile, pev_owner)
	} else {
		owner = missile
	}
		
	if(entity_range(missile, owner) > 50.0)
	{
		static Float:Angles[3]
		pev(missile, pev_angles, Angles)
		
		if(Angles[0] > pev(missile, pev_fuser4) - 50.0)
		{
			Angles[0] -= 1.0
			set_pev(missile, pev_angles, Angles)
			
			Angles[0] -= Angles[0] * 2
			set_pev(missile, pev_v_angle, Angles)
		}
	}
		
	static Float:AimOrigin[3], Float:Origin[3]
	fm_get_aim_origin(missile, AimOrigin)
	
	pev(missile, pev_origin, Origin)
	
	if(get_distance_f(Origin, AimOrigin) < 100.0)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(g_exp_spr_id) 
		write_byte(30) 
		write_byte(100)
		message_end()
		
		for(new i = 1; i < get_maxplayers(); i++)
		{
			if(is_user_alive(i) && entity_range(i, missile) <= 300.0)
			{
				static Float:Damage
				Damage = ROCKET_DAMAGE
				
				ExecuteHam(Ham_TakeDamage, i, 0, i, Damage, DMG_BULLET)
				hit_screen(i)
			}
		}		
		
		emit_sound(missile, CHAN_BODY, missile_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		remove_entity(missile)	
	} else {
		hook_ent2(missile, AimOrigin, float(pev(missile, pev_fuser3)))
		entity_set_float(missile, EV_FL_nextthink, halflife_time() + 0.01)
	}
}
// End of Missile Code

// FlameThrower Code
public starting_flame(ent)
{
	if(g_doing_skill)
		return PLUGIN_HANDLED
	
	g_doing_skill = 1
	g_virtual_ent1 = create_entity("info_target")
	
	set_pev(ent, pev_controller_0, 140)
	set_entity_anim(ent, 5)
	
	set_task(1.0, "do_fire", ent+TASK_FIRE)	
	set_task(3.0, "do_fire_rotate_m1", ent+TASK_ROTATE)
	
	return PLUGIN_HANDLED
}

public stop_flame(ent)
{
	remove_entity(g_virtual_ent1)
	
	set_pev(ent, pev_controller_0, 125)
	
	remove_task(ent+TASK_FIRE)
	remove_task(ent+TASK_ROTATE)
	remove_task(ent+TASK_ROTATE_M1)
	remove_task(ent+TASK_ROTATE_M2)
	remove_task(ent+TASK_ROTATE_M3)	
	
	set_entity_anim(ent, 7)
	set_task(1.0, "set_idle", ent+TASK_IDLE)
}

public do_fire_rotate_m1(ent)
{
	ent -= TASK_ROTATE

	g_fire_rotate_mode = 1
	g_fire_count = 50
	
	set_entity_anim(ent, 6)
	set_task(0.1, "fire_rotate_m1", ent+TASK_ROTATE_M1)
}

public fire_rotate_m1(ent)
{
	ent -= TASK_ROTATE_M1
	
	if(g_fire_rotate_mode != 1)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_fire_count > 0)
	{
		Angles[1] -= 1.0
		g_fire_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.1, "fire_rotate_m1", ent+TASK_ROTATE_M1)
	} else {
		g_fire_rotate_mode = 2
		g_fire_count = 100
		
		set_task(0.1, "fire_rotate_m2", ent+TASK_ROTATE_M2)
	}
	
	return PLUGIN_HANDLED
}

public fire_rotate_m2(ent)
{
	ent -= TASK_ROTATE_M2
	
	if(g_fire_rotate_mode != 2)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_fire_count > 0)
	{
		Angles[1] += 1.0
		g_fire_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.1, "fire_rotate_m2", ent+TASK_ROTATE_M2)
	} else {
		g_fire_rotate_mode = 3
		g_fire_count = 50
		
		set_task(0.1, "fire_rotate_m3", ent+TASK_ROTATE_M3)
	}
	
	return PLUGIN_HANDLED
}

public fire_rotate_m3(ent)
{
	ent -= TASK_ROTATE_M3
	
	if(g_fire_rotate_mode != 3)
		return PLUGIN_HANDLED
	
	static Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	if(g_fire_count > 0)
	{
		Angles[1] -= 1.0
		g_fire_count--
		
		set_pev(ent, pev_angles, Angles)
		
		Angles[0] -= Angles[0] * 2
		set_pev(ent, pev_v_angle, Angles)
		
		set_task(0.1, "fire_rotate_m3", ent+TASK_ROTATE_M3)
	} else {
		g_fire_rotate_mode = 0
		g_fire_count = 0
		
		stop_flame(ent)
	}
	
	return PLUGIN_HANDLED
}

public do_fire(ent)
{
	ent -= TASK_FIRE

	static Float:rotate_degree[3], Float:Origin[3]
	
	// 1st
	rotate_degree[0] = 125.0
	rotate_degree[1] = 170.0
	rotate_degree[2] = 225.0

	get_position(ent, rotate_degree[0], rotate_degree[1], rotate_degree[2], Origin)
	throw_fire(ent, Origin)
	
	// 2nd
	rotate_degree[0] = 125.0
	rotate_degree[1] = -170.0
	rotate_degree[2] = 225.0
	
	get_position(ent, rotate_degree[0], rotate_degree[1], rotate_degree[2], Origin)
	throw_fire(ent, Origin)
	
	set_task(0.1, "do_fire", ent+TASK_FIRE)
}

public throw_fire(ent, Float:Origin[3])
{
	static iEnt
	iEnt = create_entity("env_sprite")
	static Float:vfVelocity[3], Float:Angles[3]
	pev(ent, pev_angles, Angles)
	
	set_pev(g_virtual_ent1, pev_origin, Origin)
	
	Angles[0] += 25.0
	set_pev(g_virtual_ent1, pev_angles, Angles)
	set_pev(g_virtual_ent1, pev_v_angle, Angles)
	
	velocity_by_aim(g_virtual_ent1, 1000, vfVelocity)
	xs_vec_mul_scalar(vfVelocity, 0.4, vfVelocity)
	
	// add velocity of Owner for ent
	static Float:fOwnerVel[3], Float:vfAngle[3]
	pev(ent, pev_angles, vfAngle)
	
	//vfAttack[1] += 7.0
	fOwnerVel[2] = 0.0
	
	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 150.0)
	set_pev(iEnt, pev_fuser1, get_gametime() + 1.5)
	set_pev(iEnt, pev_scale, 0.2)
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(iEnt, pev_classname, FIRE_CLASSNAME)
	engfunc(EngFunc_SetModel, iEnt, fire_spr_name)
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -36.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 36.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_velocity, vfVelocity)
	vfAngle[1] += 30.0
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_BBOX)
	set_pev(iEnt, pev_owner, ent)
	set_pev(iEnt, pev_iuser2, 1)
}

public fw_fire_think(iEnt)
{
	if ( !pev_valid(iEnt) ) return;

	new Float:fFrame, Float:fScale, Float:fNextThink
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)

	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.015
		fFrame += 1.0
		fScale = floatmax(fScale, 1.0)
		
		if (fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	// effect normal
	else
	{
		fNextThink = 0.045
		fFrame += 1.0
		fFrame = floatmin(21.0, fFrame)
		fScale += 1.0
		fScale = floatmin(fScale, 3.0)
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
// End Of FlameThrower Code

// Main Forward
public fw_touch(ent, id)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	
	static classname[32], classname2[32]
	
	pev(ent, pev_classname, classname, sizeof(classname))
	
	if(pev_valid(id))
		pev(id, pev_classname, classname2, sizeof(classname2))
	
	if(equal(classname, FIRE_CLASSNAME))
	{
		set_pev(ent, pev_solid, SOLID_NOT)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_frame, 0.0)
		set_pev(ent, pev_nextthink, halflife_time() + 0.015)
		
		if(!is_valid_ent(id))
			return FMRES_IGNORED
		
		if(!is_user_alive(id) || !is_user_connected(id))
			return FMRES_IGNORED
			
		if(pev(ent, pev_iuser2) == 1)
		{
			hit_screen(id)
			set_pev(ent, pev_iuser2, 0)
			ExecuteHam(Ham_TakeDamage, id, 0, id, FIRE_DAMAGE, DMG_BULLET)		
		}
	}
	
	return FMRES_HANDLED
}

public fw_think(ent)
{
	if(!is_valid_ent(ent))
	{
		return HAM_IGNORED
	}
		
	if(pev(ent, pev_iuser1) == 1) // Goliath
		return HAM_IGNORED
		
	if(g_doing_skill)
		return HAM_IGNORED
		
	if(pev(ent, pev_health) - 1000.0 <= 0.0)
	{
		set_pev(ent, pev_iuser1, 1)
		
		stop_all_skill(ent)
		goliath_death(ent)
		
		return HAM_IGNORED
	}

	static victim
	static Float:Origin[3], Float:VicOrigin[3], Float:distance
	
	victim = FindClosesEnemy(ent)
	pev(ent, pev_origin, Origin)
	pev(victim, pev_origin, VicOrigin)
	
	distance = get_distance_f(Origin, VicOrigin)
	
	if(is_user_alive(victim))
	{
		if(distance <= 500.0)
		{
			if(!is_valid_ent(ent))
				return FMRES_IGNORED	
		
			new Float:Ent_Origin[3], Float:Vic_Origin[3]
			
			pev(ent, pev_origin, Ent_Origin)
			pev(victim, pev_origin, Vic_Origin)			
		
			npc_turntotarget(ent, Ent_Origin, victim, Vic_Origin)
			
			static random_number
			random_number = random_num(0, 2)
			
			if(!g_doing_skill && !g_doing_special)
			{
				if(random_number == 0)
				{
					starting_flame(ent)
				} else if(random_number == 1) {
					starting_missile(ent)
				} else if(random_number == 2) {
					starting_shoot(ent, 0)
				}
			}
		} else {
			if(g_doing_special)
			{
				if(pev(ent, pev_sequence) != 15)
				{
					entity_set_float(ent, EV_FL_animtime, get_gametime())
					entity_set_float(ent, EV_FL_framerate, 1.0)
					entity_set_int(ent, EV_INT_sequence, 15)
				} 
			} else {
				if(pev(ent, pev_sequence) != 3)
				{
					entity_set_float(ent, EV_FL_animtime, get_gametime())
					entity_set_float(ent, EV_FL_framerate, 1.0)
					entity_set_int(ent, EV_INT_sequence, 3)
				} 				
			}
				
			new Float:Ent_Origin[3], Float:Vic_Origin[3]
			
			pev(ent, pev_origin, Ent_Origin)
			pev(victim, pev_origin, Vic_Origin)
			
			npc_turntotarget(ent, Ent_Origin, victim, Vic_Origin)
			hook_ent(ent, victim, 200.0)
			
			static Float:CurTime
			CurTime = get_gametime()
			
			if(CurTime - 1.0 > g_last_check)
			{
				if(!g_doing_special && !g_doing_skill)
				{
					if(g_special_count < 10)
					{
						g_special_count++
					} else {
						starting_shoot(ent, 1)
						g_doing_special = 1
						
						client_print(0, print_chat, "Special Started")
					}
				} else {
					g_special_count = 0
				}
				
				g_last_check = CurTime
			}
			
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)
		}
	} else {
		if(pev(ent, pev_sequence) != 2)
		{
			set_entity_anim(ent, 2)
		}	
			
		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)
	}	
		
	return HAM_HANDLED
}

public fw_takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(is_user_alive(attacker) && pev_valid(victim))
		client_print(attacker, print_center, "Remain Health: %i", floatround(pev(victim, pev_health) - 1000.0))
}
// Main Stock
stock set_entity_anim(ent, anim)
{
	entity_set_float(ent, EV_FL_animtime, get_gametime())
	entity_set_float(ent, EV_FL_framerate, 1.0)
	entity_set_int(ent, EV_INT_sequence, anim)	
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]

	pev(ent, pev_origin, EntOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)

	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed

		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock hit_screen(id)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()	
}

stock FindClosesEnemy(entid)
{
	new Float:Dist
	new Float:maxdistance=4000.0
	new indexid=0	
	for(new i=1;i<=get_maxplayers();i++){
		if(is_user_alive(i) && is_valid_ent(i) && can_see_fm(entid, i))
		{
			Dist = entity_range(entid, i)
			if(Dist <= maxdistance)
			{
				maxdistance=Dist
				indexid=i
				
				return indexid
			}
		}	
	}	
	return 0
}

stock npc_turntotarget(ent, Float:Ent_Origin[3], target, Float:Vic_Origin[3]) 
{
	if(target) 
	{
		new Float:newAngle[3]
		entity_get_vector(ent, EV_VEC_angles, newAngle)
		new Float:x = Vic_Origin[0] - Ent_Origin[0]
		new Float:z = Vic_Origin[1] - Ent_Origin[1]

		new Float:radians = floatatan(z/x, radian)
		newAngle[1] = radians * (180 / 3.14)
		if (Vic_Origin[0] < Ent_Origin[0])
			newAngle[1] -= 180.0
        
		entity_set_vector(ent, EV_VEC_angles, newAngle)
	}
}

stock bool:can_see_fm(entindex1, entindex2)
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

stock hook_ent(ent, victim, Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:VicOrigin[3], Float:EntOrigin[3]

	pev(ent, pev_origin, EntOrigin)
	pev(victim, pev_origin, VicOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)

	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed

		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock create_tracer(ent, Float:start[3], Float:end[3]) 
{
	new start_[3], end_[3]
	
	FVecIVec(start, start_)
	FVecIVec(end, end_)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_TRACER)
	write_coord(start_[0])
	write_coord(start_[1])
	write_coord(start_[2])
	write_coord(end_[0])
	write_coord(end_[1])
	write_coord(end_[2])
	message_end()
	
	static tr, Float:End_Origin[3], Target
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, -1, tr)	
	
	get_tr2(tr, TR_vecEndPos, End_Origin)
	Target = get_tr2(tr, TR_pHit)
	
	if(is_user_alive(Target))
	{
		static Float:Origin[3]
		pev(Target, pev_origin, Origin)
		
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(Origin[0])) 
		write_coord(floatround(Origin[1])) 
		write_coord(floatround(Origin[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		ExecuteHamB(Ham_TakeDamage, Target, 0, Target, SHOOT_DAMAGE, DMG_BULLET)
	}	

	make_bullet(ent, End_Origin)
}

stock make_bullet(ent, Float:Origin[3])
{
	// Show sparcles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord(floatround(Origin[0]))
	write_coord(floatround(Origin[1]))
	write_coord(floatround(Origin[2]))
	write_short(ent)
	write_byte(41)
	message_end()
}