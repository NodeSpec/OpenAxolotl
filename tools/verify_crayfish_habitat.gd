extends SceneTree
var passed:=0
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error("FAIL: "+label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var world:=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D;root.add_child(world)
	await physics_frame;await physics_frame
	var motions: Array[Node3D]=[]
	for node: Node in world.find_children("*","Node3D",true,false):
		if node.get_script()!=null and node.get_script().resource_path=="res://core/rendering/crayfish_motion.gd":motions.append(node as Node3D);node.set_physics_process(false)
	check(motions.size()==14,"all thirteen pickups plus the grotto creature use the new model")
	var records: Dictionary={}
	var shore:=0;var water:=0
	for motion: Node3D in motions:
		motion.call("_physics_process",.1)
		var actor:=motion.get_parent() as Node3D
		var skeleton:=motion.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
		check(skeleton.get_bone_count()==23,"complete rig: "+String(actor.name))
		var swimming: bool=motion.call("is_swimming")
		if swimming:water+=1
		else:shore+=1
		records[motion]={"last":actor.global_position,"distance":0.,"radius":0.,"valid":true,"sync":true,"turn":0.,"previous_heading":float(motion.get("_heading"))}
	# Simulate 45 seconds of local behaviour against the real production collision world.
	for step: int in 450:
		for motion: Node3D in motions:
			motion.call("_physics_process",.1)
			var actor:=motion.get_parent() as Node3D;var data: Dictionary=records[motion]
			data["distance"]=float(data["distance"])+actor.global_position.distance_to(data["last"])
			var offset: Vector3=actor.global_position-(motion.call("home_position") as Vector3)
			data["radius"]=maxf(float(data["radius"]),Vector2(offset.x,offset.z).length())
			data["sync"]=bool(data["sync"]) and motion.global_position.distance_to(actor.global_position)<.001
			if motion.call("is_swimming"):
				data["valid"]=bool(data["valid"]) and motion.call("_water_at",actor.global_position)!=null and absf(offset.y)<=.27
			else:
				var ground: Dictionary=motion.call("_ground_at",actor.global_position)
				data["valid"]=bool(data["valid"]) and not ground.is_empty() and absf((ground.get("position",actor.global_position) as Vector3).y-actor.global_position.y)<.04
			data["last"]=actor.global_position
		if step%30==0:await process_frame
	for motion: Node3D in motions:
		var data: Dictionary=records[motion];var name:=String(motion.get_parent().name)
		print("HABITAT ",name," water ",motion.call("is_swimming")," distance ",snappedf(float(data["distance"]),.01)," radius ",snappedf(float(data["radius"]),.01)," valid ",data["valid"])
		check(float(data["distance"])>.5,"natural roaming is active: "+name)
		check(float(data["radius"])<=1.151,"roaming stays near collectible route: "+name)
		check(bool(data["valid"]),"stays in its environment: "+name)
		check(bool(data["sync"]),"pickup trigger follows creature: "+name)
	check(shore==4,"four shore habitats");check(water==10,"ten underwater habitats including grotto")
	var mesh:=motions[0].find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	check(mesh.mesh.get_surface_count()==3,"three material surfaces in one skinned mesh")
	var triangles:=0
	for surface: int in mesh.mesh.get_surface_count():triangles+=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
	check(triangles>6000 and triangles<10000,"detail remains within an economical mesh budget")
	var shader_found:=false
	for i: int in mesh.mesh.get_surface_count():
		if mesh.mesh.surface_get_material(i) is ShaderMaterial:shader_found=true
	check(shader_found,"detailed shell shader imported")
	# Sweep against a deliberately thin barrier: endpoints alone would miss it.
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.08,2,2);shape.shape=box;wall.add_child(shape);wall.position=Vector3(100,0,0);root.add_child(wall)
	await physics_frame;await physics_frame
	check(not motions[0].call("_clear_path",Vector3(99,.2,0),Vector3(101,.2,0)),"thin walls cannot be crossed between targets")
	var hero:=CharacterBody3D.new();hero.add_to_group("player");root.add_child(hero);hero.position=(motions[0].get_parent() as Node3D).global_position
	motions[0].set("_moving",true);motions[0].call("_physics_process",.1)
	check(not bool(motions[0].get("_moving")),"nearby player can collect without endless fleeing")
	hero.queue_free();wall.queue_free();world.queue_free();await process_frame
	print("CRAYFISH HABITAT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
