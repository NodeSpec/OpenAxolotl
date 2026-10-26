extends SceneTree
var passed:=0
var failed:=0
var stage: Node3D
var world: Node3D
var body: AxolotlBody
var systems: WorldSystems
func check(ok: bool,message: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error(message)
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i: int in n: await physics_frame
func park(p: Vector3,water: bool=false) -> void:
	body.clear_water_contacts(); body.global_position=p; body.velocity=Vector3.ZERO; body.get_controller().set_velocity(Vector3.ZERO); body.get_controller().sync_body_position(p)
	if water: body.resample_water_contacts()
func clear_body(p: Vector3) -> bool:
	var q:=PhysicsShapeQueryParameters3D.new(); var shape:=CapsuleShape3D.new(); shape.radius=.48; shape.height=1.55; q.shape=shape; q.collision_mask=1; q.exclude=[body.get_rid()]; q.transform=Transform3D(Basis.IDENTITY,p)
	return world.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func step(seconds: float) -> void:
	for i: int in ceili(seconds*60):
		for enemy: FleetEncounter in get_nodes_in_group("fleet_encounters"):
			enemy.visual.get_node("AnimationPlayer").advance(1./60.)
			enemy._physics_process(1./60.)
		systems._physics_process(1./60.)
func run() -> void:
	stage=Node3D.new(); root.add_child(stage)
	world=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D; stage.add_child(world)
	body=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody; body.position=Vector3(4,1.3,-11); stage.add_child(body)
	systems=WorldSystems.new(); systems.world_id="coral_cove"; systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json")); world.add_child(systems)
	await frames(4); body.set_physics_process(false); systems.set_physics_process(false)
	var enemies:=get_nodes_in_group("fleet_encounters")
	check(enemies.size()==8,"eight unique production robots")
	for enemy: FleetEncounter in enemies:
		enemy.set_physics_process(false); enemy.visual.get_node("AnimationPlayer").callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		check(systems.get_drift_fleet().roster_id_of(String(enemy.name))==String(enemy.get_meta("enemy_id")),"independent roster registration "+String(enemy.name))
		var floor_hit:=enemy.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.home+Vector3.UP,enemy.home-Vector3.UP*4,1))
		print("PLACEMENT ",enemy.name," ",enemy.home," floor=",floor_hit.get("position")," collider=",floor_hit.get("collider"))
		check(not floor_hit.is_empty(),"floor beneath "+String(enemy.name))
		var q:=PhysicsShapeQueryParameters3D.new(); var shell:=SphereShape3D.new(); shell.radius=.75 if enemy.underwater else .5; q.shape=shell; q.transform=Transform3D(Basis.IDENTITY,enemy.home); q.collision_mask=1; q.exclude=[body.get_rid()]
		check(world.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"body clear of dressed asset collisions "+String(enemy.name))
		if not enemy.underwater: check(absf(enemy.home.y-.54-floor_hit.position.y)<.15,"grounded "+String(enemy.name))
		else:
			var inside:=false
			for volume: Node in get_nodes_in_group("water_volumes"):
				if volume.contains_point(enemy.home,-.3): inside=true
			check(inside,"submerged placement "+String(enemy.name))
	step(3)
	for enemy: FleetEncounter in enemies: check(enemy.state==&"idle","safe arrival / remote dormancy "+String(enemy.name))
	var net:=world.get_node("EnemyPopulation/S02_N01") as FleetEncounter
	park(net.home+Vector3(0,0,3.2)); step(.15); check(net.state==&"notice","visible player inside radius wakes Netbot")
	check(not systems._net_capture.active(),"notice has no contact damage")
	park(Vector3(4,1.3,-11)); step(5); check(net.state==&"idle","lost player returns to home")
	# Wall occlusion applies both to awareness and strikes.
	park(net.home+Vector3(0,0,2.0))
	var wall:=StaticBody3D.new(); var cs:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=Vector3(4,4,.15); cs.shape=box; wall.add_child(cs); stage.add_child(wall); wall.global_position=net.home+Vector3(0,0,1)
	await frames(2); step(2); check(net.state==&"idle","wall blocks awareness")
	wall.queue_free(); await frames(2)
	# Complete telegraph and actual animated basket contact.
	park(net.home+Vector3(0,0,1.3)); net.rotation.y=PI
	step(.3); check(not systems._net_capture.active(),"player can dodge during warning")
	step(2); check(systems._net_capture.active(),"animated net contact starts capture")
	for i: int in 3: systems._on_strike_opened(CombatStrike.Kind.TAIL_WHACK,body.global_position,2.)
	check(not systems._net_capture.active(),"three whacks escape capture")
	check(not systems.get_drift_fleet().is_defeated(String(net.name)),"escape whacks tear net without killing robot")
	# Kill at the visible forward swing, once, and split real mesh pieces.
	systems._return_player_to(net.home+Vector3(0,0,1.0),""); body.get_controller()._heading_yaw=0.0
	systems._on_strike_opened(CombatStrike.Kind.TAIL_WHACK,body.global_position,2.)
	check(net.state!=&"disabled","tail anticipation does not strike early")
	step(.3); check(net.state==&"disabled","forward whack defeats actual encounter")
	check(is_instance_valid(net._debris) and net._debris._parts.size()>=6,"actual chassis, arm and net fragment")
	check(not systems.get_drift_fleet().is_defeated("S02_N02"),"same-type neighbor survives independently")
	await frames(200); check(not is_instance_valid(net._debris),"debris cleans up after three seconds")
	systems._return_player_to(Vector3(4,1.3,-11),""); check(net.state==&"idle" and net.visual.visible,"checkpoint reset restores defeated robot")
	# Probe every encounter's acquisition from a clear local approach.
	for enemy: FleetEncounter in enemies:
		var found:=false
		for offset: Vector3 in [Vector3(-1.8,0,-1.8),Vector3(0,0,2),Vector3(0,0,-2),Vector3(2,0,0),Vector3(-2,0,0)]:
			park(enemy.home+offset+Vector3.UP*(0 if enemy.underwater else .3),enemy.underwater)
			if enemy._eligible() and enemy._visible_player() and clear_body(body.global_position): found=true; break
		check(found,"reachable line of sight "+String(enemy.name))
		for e: FleetEncounter in enemies: e.reset_encounter(); e._cooldown=0
		step(.2); check(enemy.state==&"notice","acquisition "+String(enemy.name))
		check(enemy.global_position.distance_to(enemy.home)<=enemy.leash_radius+.01,"bounded pursuit "+String(enemy.name))
	# A close wall still blocks the forward tail probe even if its center crosses it.
	systems._return_player_to(net.home+Vector3(0,0,1.0),""); body.get_controller()._heading_yaw=0
	wall=StaticBody3D.new(); cs=CollisionShape3D.new(); box=BoxShape3D.new(); box.size=Vector3(3,3,.08); cs.shape=box; wall.add_child(cs); stage.add_child(wall); wall.global_position=net.home+Vector3(0,0,.7)
	await frames(2); systems._on_strike_opened(CombatStrike.Kind.TAIL_WHACK,body.global_position,2); step(.45)
	check(not systems.get_drift_fleet().is_defeated(String(net.name)),"tail cannot hit through a close wall")
	wall.queue_free(); await frames(2)
	park(net.home-Vector3(0,0,1.0)); systems._on_strike_opened(CombatStrike.Kind.TAIL_WHACK,body.global_position,2); step(.45)
	check(not systems.get_drift_fleet().is_defeated(String(net.name)),"forward whack does not hit behind hero")
	# Charge sweeps hit a machine reached AFTER activation, with no proximity damage before release.
	var swimmer:=world.get_node("EnemyPopulation/S03_H02") as FleetEncounter
	systems._return_player_to(Vector3(4,1.3,-11),""); park(swimmer.home+Vector3(0,0,3),true)
	check(body.get_controller().get_spin_sprint().try_activate(Vector3.FORWARD),"start charge window")
	systems._on_strike_opened(CombatStrike.Kind.SPIN_SPRINT,body.global_position,2); systems._tick_encounter_strikes(.02)
	check(not systems.get_drift_fleet().is_defeated(String(swimmer.name)),"distant robot survives charge activation")
	body.global_position=swimmer.home-Vector3(0,0,.5); systems._tick_encounter_strikes(.08)
	check(systems.get_drift_fleet().is_defeated(String(swimmer.name)),"swept charge catches later collision")
	body.get_controller().get_spin_sprint().interrupt()
	# Hookline throws actual hooks, applies a mod snag, then retracts for three seconds.
	var hook:=world.get_node("EnemyPopulation/S03_H01") as FleetEncounter
	systems._return_player_to(Vector3(4,1.3,-11),""); park(hook.home+Vector3(0,0,2.1),true)
	for offset: Vector3 in [Vector3(-1.8,0,-1.8),Vector3(0,0,2),Vector3(0,0,-2),Vector3(2,0,0),Vector3(-2,0,0)]:
		park(hook.home+offset,true)
		if hook._eligible() and hook._visible_player() and clear_body(body.global_position): print("HOOK APPROACH ",offset); break
	systems._mods.equip("glow"); hook._cooldown=0
	step(1.4); check(hook.state==&"warn" or hook.state==&"attack","Hookline telegraphs before release")
	step(.65); check(hook._hit,"physical thrown hook contact")
	check(systems._mods.is_stripped(),"hook temporarily snags equipped mod")
	var locked:=hook.visual._throw_target
	park(body.global_position+Vector3(1,0,0),true)
	check(not hook.visual.lock_attack_target(body.global_position) and hook.visual._throw_target==locked,"released hooks cannot retarget dodging player")
	step(.4); check(hook.state==&"recover","Hookline begins slow recovery")
	step(1.0); check(hook.state==&"recover" and hook.visual.cable_extension>0,"hooks remain extended during slow retraction")
	step(2.3); check(not hook.visual.attack_active,"retracted hooks are harmless")
	# Retry clears the population's attempt state and active attack windows.
	systems._on_enemy_contact(net); check(systems._net_capture.active(),"capture available for timeout test")
	systems._net_capture.tick(2.01); check(not systems._net_capture.active(),"capture timeout resets player")
	for enemy: FleetEncounter in enemies: check(enemy.state==&"idle" and not enemy.visual.attack_active,"retry resets "+String(enemy.name))
	park(Vector3(4,1.3,-11)); stage.queue_free(); await frames(3)
	print("POPULATION: %d passed, %d failed"%[passed,failed]); quit(1 if failed else 0)
