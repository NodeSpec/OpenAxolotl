extends SceneTree
var failures: PackedStringArray=[]
var finished := false
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var stage := load("res://hub/open_lagoon.tscn").instantiate() as GameSession
	stage.profile_path=""
	root.add_child(stage)
	current_scene=stage
	for i in range(5):
		await physics_frame
	var hub := stage.get_node("OpenLagoon") as OpenLagoon
	var body := stage.get_node("Axolotl") as AxolotlBody
	hub.world_completed.connect(func(id: String) -> void: finished=id=="coral_cove")
	if not hub.enter_world("coral_cove"):
		print("CORAL WALK: FAIL — world unavailable")
		quit(1)
		return
	for i in range(30):
		await physics_frame
	var pilot := RoutePilot.new(CoralRoute.waypoints(),hub._active_world.global_position)
	var frames := 0
	for i in range(18000):
		await physics_frame
		frames=i
		if finished:
			break
		pilot.step(body)
		if not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for i in range(10):
		await physics_frame
	if not finished or hub.is_in_world():
		failures.append("finish must return to hub: "+pilot.stuck_reason())
	var data := stage.get_save_system().get_world_data("coral_cove")
	if not bool(data.get("completed",false)):
		failures.append("completion was not saved")
	if (data.get("resourceInstances",{}) as Dictionary).size()!=7:
		failures.append("route must collect seven unique seeds")
	if not hub.enter_world("coral_cove"):
		failures.append("completed world cannot be revisited")
	for i in range(10):
		await physics_frame
	var systems: Node = hub._active_world.get_children().back()
	if not (systems is WorldSystems) or not (systems as WorldSystems).get_restoration().all_restored():
		failures.append("restoration must survive hub return")
	print("CORAL WALK: ","PASS" if failures.is_empty() else "FAIL"," (",frames," frames)")
	for failure in failures:
		print("  ",failure)
	quit(0 if failures.is_empty() else 1)
