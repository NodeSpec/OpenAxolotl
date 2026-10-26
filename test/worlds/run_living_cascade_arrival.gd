extends SceneTree

# Exercises the real input/controller/physics chain; no waypoint teleports.
var _failures: PackedStringArray = []
var _seen_water := false
var _seen_land := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://dev/living_cascade/blockout.tscn") as PackedScene
	if packed == null:
		push_error("Living Cascade scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	scene.get_node("PreviewSession").set("save_path", "")
	root.add_child(scene)
	current_scene = scene
	var body := scene.get_node("Axolotl") as AxolotlBody
	for frame in range(30):
		await physics_frame
	_check(body.is_in_water(), "player starts swimming")
	_check(body.get_camera() != null, "existing camera binds to player")
	_check(scene.get_node("Sections").get_child_count() == 6, "six section roots")
	var join_marker := scene.get_node("Sections/S02/JOIN_12") as Marker3D
	_check(join_marker.position.is_equal_approx(Vector3(-8,0.4,-18)), "join matches audited spec")
	var route: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim", Vector3(-4,-0.8,-7), "enter open pool"),
		RoutePilot.at("swim", Vector3(-3,-0.8,-8), "reach ramp foot"),
		RoutePilot.at("walk", Vector3(4,1.2,-8), "walk up ramp to dry pad"),
		RoutePilot.at("walk", Vector3(4,1.2,-16), "follow east bank"),
		RoutePilot.at("walk", Vector3(-8,1.2,-18), "reach next section join"),
	]
	var pilot := RoutePilot.new(route)
	for frame in range(3600):
		await physics_frame
		_seen_water = _seen_water or body.is_in_water()
		_seen_land = _seen_land or (not body.is_in_water() and body.is_on_floor())
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	_check(pilot.is_done(), "arrival route completes: " + pilot.stuck_reason())
	for frame in range(30):
		await physics_frame
	_check(_seen_water and _seen_land, "swim-to-grounded-land transition")
	_check(not body.is_in_water() and body.is_on_floor(), "finish standing on bank")
	_check(body.global_position.distance_to(Vector3(-8,1.2,-18)) < 2.0, "arrive at JOIN_12")
	print("LIVING CASCADE ARRIVAL: ", "PASS" if _failures.is_empty() else "FAIL",
		" / final position ", body.global_position)
	for failure in _failures:
		print("  ", failure)
	quit(0 if _failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)

