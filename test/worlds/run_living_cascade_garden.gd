extends SceneTree

var failures: PackedStringArray = []
var body: AxolotlBody
var scene: Node3D
var garden: Node3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://dev/living_cascade/blockout.tscn") as PackedScene
	scene = packed.instantiate() as Node3D
	scene.get_node("PreviewSession").set("save_path", "")
	root.add_child(scene)
	current_scene = scene
	body = scene.get_node("Axolotl") as AxolotlBody
	garden = scene.get_node("Sections/S02/Garden") as Node3D
	for frame in range(30):
		await physics_frame
	# Full continuous arrival-to-garden route, no teleports.
	var approach: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim", Vector3(-4,-0.8,-7), "arrival pool"),
		RoutePilot.at("walk", Vector3(4,1.2,-8), "arrival shore"),
		RoutePilot.at("walk", Vector3(4,1.2,-16), "arrival bank"),
		RoutePilot.at("walk", Vector3(-10.5,1.2,-18), "turn into garden"),
		RoutePilot.at("walk", Vector3(-10.5,1.2,-22), "garden approach east"),
		RoutePilot.at("walk", Vector3(-22,1.2,-22), "garden approach west"),
		RoutePilot.at("walk", Vector3(-22,1.2,-25), "P21"),
	]
	await drive(approach, "continuous approach")
	_check(not body.is_in_water(), "P21 is dry")
	# Require actual grounded arrivals and zero water contact on each jump.
	await jump_to(Vector3(-22,1.3,-29.2), "P21 to P22")
	await jump_to(Vector3(-27.4,1.7,-29.2), "optional rescue spur")
	_check(bool(garden.get("rescued")), "rescue triggered by player contact")
	await jump_to(Vector3(-22,1.3,-29.2), "optional spur return")
	await jump_to(Vector3(-22,1.45,-33.8), "P22 to P23")
	await jump_to(Vector3(-22,1.6,-38.8), "P23 to P24")
	var finish: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk", Vector3(-22,1.6,-44), "JOIN_23"),
	]
	await drive(finish, "dry exit")
	_check(body.is_on_floor() and not body.is_in_water(), "dry route ends grounded")
	# Deliberate misses from every main platform. Teleports only reset independent
	# cases to settled takeoff platforms; each miss and recovery is input-driven.
	var cases: Array[Vector3] = [
		Vector3(-22,1.3,-25), Vector3(-22,1.4,-29.2),
		Vector3(-22,1.55,-33.8), Vector3(-22,1.7,-38.8)]
	for i in range(cases.size()):
		await reset_body(cases[i])
		var ramp_z := -27.5 if i < 2 else -36.5
		var recovery: Array[RoutePilot.Waypoint] = [
			RoutePilot.at("swim", Vector3(-19,-0.8,cases[i].z), "miss into water"),
			RoutePilot.at("swim", Vector3(-19,-0.8,ramp_z), "reach recovery ramp"),
			RoutePilot.at("walk", Vector3(-11,1.2,ramp_z), "return to bank"),
		]
		var result: Dictionary = await drive(recovery, "miss recovery %d" % (i+1))
		_check(bool(result["water"]), "miss %d enters recovery water" % (i+1))
		_check(body.is_on_floor() and not body.is_in_water(), "miss %d exits onto dry bank" % (i+1))
		_check(int(result["frames"]) <= 600, "miss %d recovers within ten seconds" % (i+1))
	# Accessible swimming alternative starts at the section entry and reaches
	# the same JOIN_23 without collecting the optional discovery.
	await reset_body(Vector3(-10.5,1.3,-22))
	var alternative: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk", Vector3(-17,1.2,-22), "approach swimming lane"),
		RoutePilot.at("swim", Vector3(-19.25,-0.8,-26), "enter bypass water"),
		RoutePilot.at("swim", Vector3(-19.25,-0.8,-32), "swim alongside stones"),
		RoutePilot.at("swim", Vector3(-19,-0.8,-36.5), "last recovery ramp"),
		RoutePilot.at("walk", Vector3(-11,1.2,-36.5), "onto recovery bank"),
		RoutePilot.at("walk", Vector3(-11,1.6,-43), "onto exit bank"),
		RoutePilot.at("walk", Vector3(-22,1.6,-44), "shared exit"),
	]
	await drive(alternative, "swimming alternative")
	_check(body.global_position.distance_to(Vector3(-22,1.6,-44)) < 2.0, "swim alternative reaches JOIN_23")

	# Variable jump-height check: a brief release may shorten reach, but must
	# either land safely or leave an input-driven recovery route.
	for i in range(3):
		await reset_body(cases[i])
		var target := cases[i+1]
		var short_route: Array[RoutePilot.Waypoint] = [
			RoutePilot.at("jump", target, "short-tap jump")]
		var short_pilot := RoutePilot.new(short_route)
		var rising_frames := 0
		var released := false
		var splashed := false
		for frame in range(240):
			await physics_frame
			short_pilot.step(body)
			if not body.is_on_floor() and body.velocity.y > 0.0:
				rising_frames += 1
			if rising_frames == 3 and not released:
				var release := InputEventKey.new()
				release.physical_keycode = KEY_SPACE
				release.pressed = false
				Input.parse_input_event(release)
				released = true
			if body.is_in_water():
				splashed = true
				break
			if short_pilot.is_done():
				break
		short_pilot.release_all()
		_check(released, "short-tap %d actually releases in flight" % (i+1))
		_check(short_pilot.is_done() or splashed, "short-tap %d lands or reaches safe water" % (i+1))
		if splashed:
			var ramp_z := -27.5 if i == 0 else -36.5
			var recover: Array[RoutePilot.Waypoint] = [
				RoutePilot.at("swim", Vector3(-19.25,-0.8,body.global_position.z), "clear stone"),
				RoutePilot.at("swim", Vector3(-19,-0.8,ramp_z), "recovery ramp"),
				RoutePilot.at("walk", Vector3(-11,1.2,ramp_z), "recover shortened jump")]
			await drive(recover, "short-tap recovery %d" % (i+1))
			_check(body.is_on_floor() and not body.is_in_water(), "short-tap recovery returns to bank")
		print("short-tap ", i+1, " / ", "water recovery" if splashed else "landed")

	print("LIVING CASCADE GARDEN: ", "PASS" if failures.is_empty() else "FAIL")
	for failure in failures:
		print("  ", failure)
	quit(0 if failures.is_empty() else 1)

func drive(route: Array[RoutePilot.Waypoint], label: String) -> Dictionary:
	var pilot := RoutePilot.new(route)
	var touched_water := false
	var frames := 0
	for frame in range(3600):
		await physics_frame
		frames += 1
		touched_water = touched_water or body.is_in_water()
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for frame in range(20):
		await physics_frame
		touched_water = touched_water or body.is_in_water()
	_check(pilot.is_done(), label + ": " + pilot.stuck_reason())
	print(label, " / ", frames, " frames / ", body.global_position)
	return {"water": touched_water, "frames": frames}

func jump_to(target: Vector3, label: String) -> void:
	var route: Array[RoutePilot.Waypoint] = [RoutePilot.at("jump", target, label)]
	var result: Dictionary = await drive(route, label)
	_check(not bool(result["water"]), label + " stays above water")
	_check(body.is_on_floor() and body.global_position.distance_to(target) < 1.7,
		label + " lands on target")

func reset_body(position: Vector3) -> void:
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.global_position = position
	body.velocity = Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.resample_water_contacts()
	for frame in range(20):
		await physics_frame

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
