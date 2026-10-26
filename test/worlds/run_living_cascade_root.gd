extends SceneTree

var failures: PackedStringArray = []
var body: AxolotlBody
var scene: Node3D
var root_dive: Node3D
var deepest_main_y := 100.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	scene = (load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	scene.get_node("PreviewSession").set("save_path", "")
	root.add_child(scene)
	current_scene = scene
	body = scene.get_node("Axolotl") as AxolotlBody
	root_dive = scene.get_node("Sections/S03/RootDive") as Node3D
	for frame in range(30):
		await physics_frame
	var arrival_and_garden: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim", Vector3(-4,-0.8,-7), "arrival pool"),
		RoutePilot.at("walk", Vector3(4,1.2,-8), "arrival shore"),
		RoutePilot.at("walk", Vector3(4,1.2,-16), "arrival bank"),
		RoutePilot.at("walk", Vector3(-10.5,1.2,-18), "garden turn"),
		RoutePilot.at("walk", Vector3(-10.5,1.2,-22), "garden approach"),
		RoutePilot.at("walk", Vector3(-22,1.2,-22), "first landing approach"),
		RoutePilot.at("walk", Vector3(-22,1.2,-25), "P21"),
		RoutePilot.at("jump", Vector3(-22,1.3,-29.2), "P22"),
		RoutePilot.at("jump", Vector3(-22,1.45,-33.8), "P23"),
		RoutePilot.at("jump", Vector3(-22,1.6,-38.8), "P24"),
		RoutePilot.at("walk", Vector3(-22,1.6,-44), "JOIN_23"),
	]
	await drive(arrival_and_garden, "continuous chunks 1 and 2")
	var main_route := root_route()
	await drive(main_route, "root dive to JOIN_34")
	_check(deepest_main_y <= -1.3, "main route actually dives beneath roof")
	_check(body.is_on_floor() and not body.is_in_water(), "exit is grounded and dry")
	_check(not bool(root_dive.get("rescued")), "optional rescue is not required")
	_check(body.global_position.distance_to(Vector3(13,1.6,-56)) < 2.0, "east exit reaches audited join")
	# Reverse passage with the existing tail-loss swim factor, not a retuned controller.
	var tuning := TuningData.load_from_file("res://core/tuning/tuning.json")
	body.get_controller().get_capability_modifiers().set_factor("test_tail_loss",
		tuning.get_number("capability.tail_loss.swim_speed_multiplier"), CapabilityModifiers.Target.SWIM_SPEED)
	var back: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim", Vector3(4,-1.6,-56), "reverse exit ramp"),
		RoutePilot.at("swim", Vector3(-2,-1.6,-58), "reverse middle"),
		RoutePilot.at("swim", Vector3(-10,-1.6,-58), "reverse bend"),
		RoutePilot.at("swim", Vector3(-22,-1.6,-50), "reverse entry"),
		RoutePilot.at("swim", Vector3(-27,-1.4,-50), "return ramp foot"),
		RoutePilot.at("walk", Vector3(-27,1.6,-44), "return bank"),
		RoutePilot.at("walk", Vector3(-22,1.6,-44), "back to JOIN_23"),
	]
	await drive(back, "reverse route with tail-loss speed")
	await drive(main_route, "forward route with tail-loss speed")
	body.get_controller().get_capability_modifiers().clear_factor("test_tail_loss")
	# Independent branch case: reset only the starting position.
	await reset_body(Vector3(-10,-1.6,-58))
	var optional: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim", Vector3(-12,-1.6,-66.5), "swim through lantern shrimp"),
		RoutePilot.at("swim", Vector3(-2,-1.6,-65), "optional loop east"),
		RoutePilot.at("swim", Vector3(0,-1.6,-59), "rejoin main passage"),
		RoutePilot.at("swim", Vector3(4,-1.6,-58), "main passage exit"),
		RoutePilot.at("walk", Vector3(13,1.6,-56), "optional route exit"),
	]
	await drive(optional, "optional rescue loop")
	_check(bool(root_dive.get("rescued")), "lantern shrimp rescued by contact")
	# Hold forward at surface height: collision must prevent an undived bypass.
	await reset_body(Vector3(-22,0.0,-49))
	body.get_camera().set_yaw_deg(0.0)
	key(KEY_W, true)
	for frame in range(120):
		await physics_frame
	key(KEY_W, false)
	for frame in range(10):
		await physics_frame
	_check(body.global_position.z > -52.1 or body.global_position.y <= -1.25,
		"surface travel cannot bypass the root roof")
	# Spec capsule fit queries, including the previously inconsistent optional depth.
	for p: Vector3 in [Vector3(-18,-1.6,-55), Vector3(-10,-1.6,-58), Vector3(-12,-1.6,-65)]:
		var shape := CapsuleShape3D.new()
		shape.radius = 0.5
		shape.height = 1.6
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, p)
		query.collision_mask = 1
		query.exclude = [body.get_rid()]
		_check(body.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),
			"audited capsule clearance at " + str(p))

	# Stationary camera clearance at the designed turn and chamber views.
	for view: Vector3 in [Vector3(-18,-1.6,-55), Vector3(-10,-1.6,-58),
			Vector3(-12,-1.6,-65), Vector3(4,-1.6,-58)]:
		await reset_body(view)
		body.get_camera().set_yaw_deg(-90.0)
		for frame in range(90):
			await physics_frame
		var camera := body.get_camera()
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position,
			body.global_position + Vector3.UP * 0.3)
		ray.exclude = [body.get_rid()]
		ray.collision_mask = 1
		_check(body.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),
			"camera sightline clear at " + str(view))

	# Additional S01 spec checks: both shore routes remain accessible with tail-loss speed.
	body.get_controller().get_capability_modifiers().set_factor("test_tail_loss", 0.6,
		CapabilityModifiers.Target.SWIM_SPEED)
	await reset_body(Vector3(-2,-0.8,-4))
	var shallow: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk", Vector3(-8,0.5,-4), "shallow shelf"),
		RoutePilot.at("walk", Vector3(-8,0.5,-7), "shelf south edge"),
		RoutePilot.at("walk", Vector3(-8,1.2,-15), "second shore exit"),
	]
	await drive(shallow, "arrival second exit with tail-loss speed")
	_check(body.is_on_floor() and not body.is_in_water(), "second arrival exit is dry")
	await reset_body(Vector3(-4,-0.8,-7))
	var first_exit: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk", Vector3(4,1.2,-8), "main shore ramp"),
	]
	await drive(first_exit, "arrival first exit with tail-loss speed")
	_check(body.is_on_floor() and not body.is_in_water(), "first arrival exit is dry")
	body.get_controller().get_capability_modifiers().clear_factor("test_tail_loss")
	print("LIVING CASCADE ROOT: ", "PASS" if failures.is_empty() else "FAIL",
		" / deepest route Y ", deepest_main_y)
	for failure in failures:
		print("  ", failure)
	quit(0 if failures.is_empty() else 1)

func root_route() -> Array[RoutePilot.Waypoint]:
	return [
		RoutePilot.at("swim", Vector3(-22,-1.6,-50), "dive before root"),
		RoutePilot.at("swim", Vector3(-18,-1.6,-55), "under root entrance"),
		RoutePilot.at("swim", Vector3(-10,-1.6,-58), "wide turn"),
		RoutePilot.at("swim", Vector3(-2,-1.6,-58), "main chamber"),
		RoutePilot.at("swim", Vector3(4,-1.6,-58), "root exit"),
		RoutePilot.at("swim", Vector3(8,-0.1,-56), "resurface on ramp"),
		RoutePilot.at("walk", Vector3(13,1.6,-56), "JOIN_34 bank"),
	]

func drive(route: Array[RoutePilot.Waypoint], label: String) -> void:
	var pilot := RoutePilot.new(route)
	for frame in range(7200):
		await physics_frame
		if body.global_position.z < -52:
			deepest_main_y = minf(deepest_main_y, body.global_position.y)
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for frame in range(20):
		await physics_frame
	_check(pilot.is_done(), label + ": " + pilot.stuck_reason())
	_check(body.get_camera().global_position.is_finite(), label + " camera position stays finite")
	print(label, " / ", body.global_position)

func reset_body(p: Vector3) -> void:
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.global_position = p
	body.velocity = Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.resample_water_contacts()
	for frame in range(20):
		await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
