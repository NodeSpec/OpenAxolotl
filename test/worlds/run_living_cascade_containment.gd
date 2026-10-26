extends SceneTree
var failures: PackedStringArray = []
var scene: Node3D
var body: AxolotlBody
var session: Node
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	scene = (load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	session=scene.get_node("PreviewSession")
	session.set("save_path","")
	root.add_child(scene)
	current_scene=scene
	body=scene.get_node("Axolotl") as AxolotlBody
	for frame in range(30):
		await physics_frame
	var space := body.get_world_3d().direct_space_state
	var probes := 0
	for x in range(-41,40,2):
		for z in range(-126,6,2):
			var q := PhysicsRayQueryParameters3D.create(Vector3(x,-3.5,z),Vector3(x,-7,z),1,[body.get_rid()])
			q.hit_from_inside=true
			check(not space.intersect_ray(q).is_empty(),"continuous foundation %d/%d" % [x,z])
			probes+=1
	print("foundation coverage probes: ",probes)
	# The outer perimeter connects below the foundation and above all supports.
	for y: float in [-3.8,0,7.8,10.5,15.5]:
		for z in range(-126,6,3):
			for pair: Vector2 in [Vector2(-41,-44),Vector2(39,42)]:
				check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(pair.x,y,z),Vector3(pair.y,y,z),1)).is_empty(),"outer east/west closure")
		for x in range(-41,40,3):
			for pair: Vector2 in [Vector2(5,8),Vector2(-126,-129)]:
				check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,y,pair.x),Vector3(x,y,pair.y),1)).is_empty(),"outer north/south closure")
	# Probe the full west dividing ridge at standing and boosted-jump heights.
	for z in range(-109,-94):
		for y: float in [7.8,9.5,11.5]:
			check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(12,y,z),Vector3(7,y,z),1)).is_empty(),"closed garden ridge/gate")
	for mode: String in ["walk","jump","climb"]:
		await reset_body(Vector3(12,7.85,-104))
		var pilot := RoutePilot.new([RoutePilot.at(mode,Vector3(7,7.8,-104),"closed gate attempt")])
		for frame in range(240):
			await physics_frame
			pilot.step(body)
		pilot.release_all()
		check(body.global_position.x>9.8 and body.global_position.y<11.3,"gate blocks "+mode)
		print("closed gate ",mode," / ",body.global_position)
	# Wide misses outside local pools hit the safety recovery, never the void.
	for p: Vector3 in [Vector3(7,1.5,-14),Vector3(-32,2,-22),Vector3(20,4,-72),Vector3(35,8,-109)]:
		await reset_body(p)
		for frame in range(150):
			await physics_frame
		check(body.global_position.y>=-3.1,"wide miss remains above fallback plane")
	print("LIVING CASCADE CONTAINMENT: ","PASS" if failures.is_empty() else "FAIL")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)
func reset_body(p: Vector3) -> void:
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.global_position=p
	body.velocity=Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.resample_water_contacts()
	for frame in range(20):
		await physics_frame
func check(ok: bool,label: String) -> void:
	if not ok:
		failures.append(label)
