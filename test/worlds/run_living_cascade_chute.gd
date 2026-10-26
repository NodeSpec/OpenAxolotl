extends SceneTree
const Profile = preload("res://dev/living_cascade/chute_profile.gd")
var failures: PackedStringArray = []
var scene: Node3D
var body: AxolotlBody
var session: Node
var chute: Node3D
var peak_speed := 0.0
var boost_seen := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await new_scene("")
	for i in range(1,8):
		session.call("_on_seed",body,"garden_%d" % i)
	session.set("checkpoint","CP_03")
	for frame in range(10):
		await physics_frame
	# Check shared surfaces and axis alignment at every adjoining volume pair.
	var water: Array[WaterVolume] = []
	for n: Node in chute.get_children():
		if n is WaterVolume and n.name != "RewardWater":
			water.append(n as WaterVolume)
	for i in range(water.size()-1):
		var p := (water[i].global_position+water[i+1].global_position)*0.5
		check(water[i].global_basis.is_equal_approx(Basis.IDENTITY),"water stays unrotated")
		check(water[i].water_priority != water[i+1].water_priority,"deterministic overlap priority")
		check(is_equal_approx(water[i].surface_at(p),water[i+1].surface_at(p)),"identical seam height")
	check(absf(float(Profile.sample(Vector3(-12,0,-116))["surface"])-3.6)<0.001,"reference bar surface")
	chute.position=Vector3(60,3,20)
	check(absf(water[0].surface_at(Vector3(48,4.9,-96))-6.6)<0.001,"shared water field supports translation")
	chute.position=Vector3.ZERO
	check(water[0].flow_at(Vector3(6,5,-104)).length()<0.01,"entry current ramps from zero")
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.5
	capsule.height=1.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.collision_mask=1
	query.exclude=[body.get_rid()]
	query.transform=Transform3D(Basis.IDENTITY,Vector3(-12,1.9,-116))
	check(body.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"capsule clears bar and bed")
	for mode: String in ["normal","tail_loss","boosted"]:
		await reset_body(Vector3(8,7.85,-104))
		if mode=="tail_loss":
			body.get_controller().get_capability_modifiers().set_factor("chute_tail_loss",0.6,CapabilityModifiers.Target.SWIM_SPEED)
		peak_speed=0
		boost_seen=false
		await drive(route(mode=="boosted"),mode+" chute and final bank")
		check(bool(session.get("completed")),"finish callback completes without pearl")
		check(not (session.get("collectibles") as CollectiblesSystem).is_collected("tide_pearl"),"pearl is optional")
		check(body.is_on_floor() and body.global_position.distance_to(Vector3(-38,1.8,-110))<1.4,"JOIN_OUT has dry support")
		if mode=="boosted":
			check(boost_seen,"boost actually engaged")
		body.get_controller().get_capability_modifiers().clear_factor("chute_tail_loss")
	await reset_body(Vector3(-28,-0.8,-104))
	body.get_controller().get_capability_modifiers().set_factor("chute_tail_loss",0.6,CapabilityModifiers.Target.SWIM_SPEED)
	var reverse_route: Array[RoutePilot.Waypoint] = []
	for p: Vector3 in [Vector3(-27,-0.8,-109),Vector3(-23,-0.6,-114),Vector3(-19,0.9,-118),Vector3(-16,1,-118),Vector3(-13,1.7,-116.5),Vector3(-10,2.3,-115),Vector3(-7,3.3,-113.5),Vector3(0,4.6,-110),Vector3(4,5.1,-106)]:
		reverse_route.append(RoutePilot.at("swim",p,"upstream bends"))
	reverse_route.append(RoutePilot.at("walk",Vector3(4,5.9,-104),"intake ramp"))
	reverse_route.append(RoutePilot.at("walk",Vector3(8,7.8,-104),"garden lip"))
	await drive(reverse_route,"full reverse route with tail loss")
	body.get_controller().get_capability_modifiers().clear_factor("chute_tail_loss")
	# Reversible obstruction: surface travel is stopped, then the dive succeeds.
	await reset_body(Vector3(-9,4.05,-114.5))
	var pilot := RoutePilot.new([RoutePilot.at("swim",Vector3(-15,3.5,-117.5),"surface attempt")])
	for frame in range(200):
		await physics_frame
		pilot.step(body)
	pilot.release_all()
	print("surface attempt / ",body.global_position, " / ",body.get_water_volume())
	check(body.global_position.x>-12,"bar refuses surface-height passage")
	await drive([RoutePilot.at("swim",Vector3(-8,3.7,-114),"reverse from obstacle"),RoutePilot.at("swim",Vector3(-10,2.3,-115),"dive"),RoutePilot.at("swim",Vector3(-14,1.55,-117),"clear bar")],"reverse and deliberate dive")
	body.get_controller().get_capability_modifiers().set_factor("chute_tail_loss",0.6,CapabilityModifiers.Target.SWIM_SPEED)
	await drive([RoutePilot.at("swim",Vector3(-10,2.3,-115),"upstream dive"),RoutePilot.at("swim",Vector3(-5,3.7,-112.5),"upstream seam"),RoutePilot.at("swim",Vector3(0,4.6,-110),"upstream first bend")],"reverse seams with tail loss")
	body.get_controller().get_capability_modifiers().clear_factor("chute_tail_loss")
	# Still margin at a bend and zero-flow reward pool let the player stop.
	var p := Profile.points[Profile.points.size()/2]
	var row := Profile.sample(p)
	var dir := row["direction"] as Vector3
	var eddy := p+Vector3(-dir.z,0,dir.x)*3.25-Vector3.UP*1.3
	for target: Vector3 in [eddy,Vector3(-28,-0.8,-103)]:
		await reset_body(target)
		var start := body.global_position
		for frame in range(180):
			await physics_frame
		check(body.global_position.distance_to(start)<0.3,"neutral input stops in eddy/pool")
		check(body.is_in_water(),"rest point stays in water")
	# Optional reward and completion use the real isolated save profile.
	await reset_body(Vector3(-36,1.85,-104))
	await drive([RoutePilot.at("walk",Vector3(-36,1.8,-102),"optional pearl")],"optional pearl pickup")
	check((session.get("collectibles") as CollectiblesSystem).is_collected("tide_pearl"),"pearl collected")
	var disk := "res://review/living-cascade-finish-test-%d.json" % Time.get_ticks_usec()
	session.set("save_path",disk)
	check(bool(session.call("commit")),"completion saved to disk")
	await new_scene(disk)
	check(bool(session.get("completed")),"completion survives reload")
	check((session.get("collectibles") as CollectiblesSystem).is_collected("tide_pearl"),"pearl survives reload")
	check(not (chute.get_node("TidePearl") as Area3D).visible,"saved pearl stays absent")
	print("LIVING CASCADE CHUTE: ","PASS" if failures.is_empty() else "FAIL")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)

func route(boosted: bool = false) -> Array[RoutePilot.Waypoint]:
	var result: Array[RoutePilot.Waypoint] = []
	for p: Vector3 in [Vector3(4,5.1,-106),Vector3(0,4.6,-110),Vector3(-7,3.3,-113.5),Vector3(-10,2.3,-115),Vector3(-13,1.7,-116.5),Vector3(-16,1,-118),Vector3(-19,0.9,-118),Vector3(-23,-0.6,-114),Vector3(-27,-0.8,-109),Vector3(-28,-0.8,-104)]:
		result.append(RoutePilot.at("swim",p,"downstream"))
		if boosted and p.x==-7:
			result.append(RoutePilot.at("boost",Vector3(-13,1.7,-116.5),"boost before bar"))
	result.append(RoutePilot.at("swim",Vector3(-29,-0.8,-106),"line up with shore ramp"))
	for p: Vector3 in [Vector3(-36,1.8,-106),Vector3(-38,1.8,-106),Vector3(-38,1.8,-110)]:
		result.append(RoutePilot.at("walk",p,"final bank"))
	return result

func drive(route_points: Array[RoutePilot.Waypoint],label: String) -> void:
	var pilot := RoutePilot.new(route_points)
	var before := int(session.get("recoveries"))
	var dry_frames := 0
	for frame in range(9000):
		await physics_frame
		if label.ends_with("chute and final bank") and pilot.get_leg()>1 and pilot.current()!=null and pilot.current().note=="downstream" and not body.is_in_water():
			dry_frames += 1
		peak_speed=maxf(peak_speed,body.velocity.length())
		boost_seen = boost_seen or body.get_controller().get_bubble_boost().is_active()
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for frame in range(30):
		await physics_frame
	check(dry_frames==0,label+" maintains continuous immersion")
	check(pilot.is_done(),label+": "+pilot.stuck_reason())
	check(int(session.get("recoveries"))==before,label+" needs no fallback")
	print(label," / ",body.global_position," / peak ",peak_speed)

func new_scene(path: String) -> void:
	if scene != null:
		scene.queue_free()
		await process_frame
	scene=(load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	session=scene.get_node("PreviewSession")
	session.set("save_path",path)
	root.add_child(scene)
	current_scene=scene
	body=scene.get_node("Axolotl") as AxolotlBody
	chute=scene.get_node("Sections/S06/Chute") as Node3D
	for frame in range(30):
		await physics_frame

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
