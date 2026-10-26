extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var stage:=load("res://hub/open_lagoon.tscn").instantiate() as Node3D;stage.set("profile_path","");root.add_child(stage)
	for i in 8:await physics_frame
	var hub:=stage.get_node("OpenLagoon") as OpenLagoon
	var world:=hub.get("_stream_world") as Node3D
	var body:=stage.get_node("Axolotl") as AxolotlBody
	hub._move_player_to(world.to_global(Vector3(0,.3,11.5)))
	var pilot:=RoutePilot.new([RoutePilot.at("swim",Vector3(0,-.5,3),"inlet in"),RoutePilot.at("swim",Vector3(0,-.8,-1),"pool join"),RoutePilot.at("swim",Vector3(0,-.5,3),"inlet return"),RoutePilot.at("swim",Vector3(0,.3,11.5),"tunnel return")],world.global_position)
	for i in 1600:
		await physics_frame;pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():break
	pilot.release_all()
	var ok:=pilot.is_done() and pilot.stuck_reason().is_empty()
	print("SEALED INLET ROUND TRIP: ","PASS" if ok else "FAIL "+pilot.stuck_reason()," at ",world.to_local(body.global_position))
	stage.queue_free();await process_frame;quit(0 if ok else 1)
