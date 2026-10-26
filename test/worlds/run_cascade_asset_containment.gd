extends SceneTree
var failures: PackedStringArray = []
var probes := 0
var world: Node3D
var body: AxolotlBody
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool,label: String) -> void:
	probes+=1
	if not ok:
		failures.append(label)
func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene=stage
	world=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D
	stage.add_child(world)
	body=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	body.name="Axolotl"
	stage.add_child(body)
	var camera := CameraFollow.new()
	camera.target_path=NodePath("../Axolotl")
	stage.add_child(camera)
	var systems := WorldSystems.new()
	systems.world_id="coral_cove"
	systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json")) as Dictionary
	world.add_child(systems)
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	for x in range(-41,40,2):
		for z in range(-126,6,2):
			var q := PhysicsRayQueryParameters3D.create(Vector3(x,-3.5,z),Vector3(x,-7,z),1,[body.get_rid()])
			q.hit_from_inside=true
			check(not space.intersect_ray(q).is_empty(),"foundation %d/%d" % [x,z])
	for y: float in [-3.8,0,7.8,10.5,15.5]:
		for z in range(-126,6,3):
			for pair: Vector2 in [Vector2(-41,-44),Vector2(39,42)]:
				check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(pair.x,y,z),Vector3(pair.y,y,z),1)).is_empty(),"east/west perimeter")
		for x in range(-41,40,3):
			for pair: Vector2 in [Vector2(5,8),Vector2(-126,-129)]:
				if pair.x==5 and x>=-5 and x<=4:
					continue # Authored open inlet to the starting cove.
				check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,y,pair.x),Vector3(x,y,pair.y),1)).is_empty(),"north/south perimeter")
	for rock: Node3D in world.get_node("SuppliedAssets").get_children():
		if not rock.has_meta("landing_support_y"):
			continue
		var top := float(rock.get_meta("landing_support_y"))
		for x: float in [-0.45,0,0.45]:
			for z: float in [-0.45,0,0.45]:
				var p := Vector3(rock.position.x+x,top+0.7,rock.position.z+z)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p-Vector3.UP*1.2,1))
				check(not hit.is_empty(),"landing support "+String(rock.name))
				if not hit.is_empty():
					check(absf((hit.position as Vector3).y-top)<0.25,"landing height "+String(rock.name))
	for mode: String in ["walk","jump","climb"]:
		await reset(Vector3(12,7.85,-104))
		var pilot := RoutePilot.new([RoutePilot.at(mode,Vector3(7,7.8,-104),"closed gate")])
		for i in range(180):
			await physics_frame
			pilot.step(body)
		pilot.release_all()
		check(body.position.x>9.8,"closed gate blocks "+mode)
		print("CLOSED GATE ",mode," ",body.position)
	# The optional grotto has a real full-depth opening and remains reversible.
	var rescued := {"hit":false}
	for area: Area3D in world.find_children("*","Area3D",true,false):
		if String(area.get_meta("collectible_id",""))=="lantern_shrimp":
			area.body_entered.connect(func(n: Node3D) -> void:
				if n==body:
					rescued.hit=true)
	await reset(Vector3(-10,-1.6,-58))
	var grotto := RoutePilot.new([RoutePilot.at("swim",Vector3(-7.3,-1.6,-60.6),"grotto approach"),RoutePilot.at("swim",Vector3(-13,-1.6,-66),"grotto rescue"),RoutePilot.at("swim",Vector3(-7.3,-1.6,-60.6),"grotto return"),RoutePilot.at("swim",Vector3(-10,-1.6,-58),"main passage")])
	for i in range(1200):
		await physics_frame
		grotto.step(body)
		if grotto.is_done() or not grotto.stuck_reason().is_empty():
			break
	grotto.release_all()
	check(grotto.is_done() and grotto.stuck_reason().is_empty() and body.position.distance_to(Vector3(-10,-1.6,-58))<2,"grotto round trip: "+grotto.stuck_reason()+" "+str(body.position))
	check(bool(rescued.hit),"lantern shrimp is physically reachable at (-12,-1.6,-65)")
	print("CASCADE ASSET CONTAINMENT: ","PASS" if failures.is_empty() else "FAIL"," / ",probes," checks")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)
func reset(p: Vector3) -> void:
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.position=p
	body.velocity=Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.resample_water_contacts()
	for i in range(5):
		await physics_frame
