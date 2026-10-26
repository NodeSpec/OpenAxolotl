extends SceneTree
var passed:=0
var failed:=0
func check(ok: bool,label: String) -> void:
	if ok: passed+=1; print("PASS ",label)
	else: failed+=1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var world: Node3D=load("res://worlds/coral_cove/world.tscn").instantiate();root.add_child(world)
	for i: int in 3: await physics_frame
	var net:=world.get_node("EnemyPopulation/S02_N02") as FleetEncounter
	var ends: Array[Vector3]=[]
	for hz: int in [30,60,120]:
		net.reset_encounter();net.state=&"pursue"
		var old_velocity:=Vector3.ZERO
		var bounded:=true
		for i: int in hz:
			net._move_toward(net.home+Vector3(.8,0,0),1.0/hz)
			bounded=bounded and net._move_velocity.distance_to(old_velocity)<=2.81/hz
			old_velocity=net._move_velocity
		check(bounded,"acceleration bounded at %d Hz"%hz)
		check(net.global_position.distance_to(net.home)>.4,"supported land patrol advances at %d Hz"%hz)
		ends.append(net.global_position)
		for i: int in hz: net._move_toward(net.global_position,1.0/hz)
		check(net._move_velocity.length()<.002,"braking settles at %d Hz"%hz)
	check(ends[0].distance_to(ends[2])<.025,"30/120 Hz travel agrees within 2.5 cm")
	net.reset_encounter()
	var max_turn:=0.0
	for i: int in 180:
		var old:=net.rotation.y; net._turn_toward(PI,1./60.)
		max_turn=maxf(max_turn,absf(angle_difference(old,net.rotation.y)))
	check(max_turn<=2.21/60.,"180 degree turn has no angular snap")
	check(absf(angle_difference(net.rotation.y,PI))<.02,"turn settles on target heading")
	for e: FleetEncounter in get_nodes_in_group("fleet_encounters"):
		check(e.visual.enemy_kind!=&"netbot" or not e.underwater,"Netbot land-only policy "+str(e.name))
	for kind: String in ["netbot","hookline_rig"]:
		var actor:=load("res://core/enemies/visuals/%s_visual.tscn"%kind).instantiate() as FleetEnemyVisual;root.add_child(actor)
		var player:=actor.get_node("AnimationPlayer") as AnimationPlayer
		player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		actor.play_state(&"warn");player.advance(player.get_animation(&"warn").length)
		var path: String="Facing/Body/CaptureArm" if kind=="netbot" else "Facing/Body/HookRight"
		var part:=actor.get_node(path) as Node3D
		var before:=part.rotation
		actor.play_state(&"idle")
		check(part.rotation.distance_to(before)<.025,kind+" warning cancellation blends pose")
		player.advance(.3)
		actor.play_state(&"warn"); player.advance(1.01)
		var start:=part.global_position
		actor.lock_attack_target(Vector3(-1.8,.3,1.8));actor.play_state(&"attack")
		check(part.global_position.distance_to(start)<.025,kind+" locked release has no position pop")
		var active_frames:=0
		for i: int in 48:
			player.advance(1./120.)
			if actor.attack_active: active_frames+=1
		check(active_frames>15,kind+" attack retains contact interval")
		actor.play_state(&"stagger")
		var safe:=true
		for i: int in 24:
			player.advance(1./120.);safe=safe and not actor.attack_active
		check(safe,kind+" interrupted blends cannot reopen hit window")
		if kind=="hookline_rig":
			actor.play_state(&"recover")
			var extension:=actor.cable_extension
			var monotone:=true
			for i: int in 179:
				player.advance(1./60.);monotone=monotone and actor.cable_extension<=extension+.0001;extension=actor.cable_extension
			check(monotone and extension<.002,"three-second retraction stays smooth and monotone")
		actor.free()
	world.queue_free();await process_frame
	print("ENEMY MOTION: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
