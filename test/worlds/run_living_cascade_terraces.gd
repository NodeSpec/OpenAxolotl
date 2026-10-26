extends SceneTree
var failures: PackedStringArray = []
var body: AxolotlBody
var scene: Node3D
var terraces: Node3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	scene = (load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	scene.get_node("PreviewSession").set("save_path", "")
	root.add_child(scene)
	current_scene = scene
	body = scene.get_node("Axolotl") as AxolotlBody
	terraces = scene.get_node("Sections/S04/Terraces") as Node3D
	for frame in range(30):
		await physics_frame
	# Compare against the design reference, not against another copy of scene data.
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://dev/living_cascade/design_reference.json"))
	var spec: Dictionary = raw as Dictionary
	var joins: Array = spec.get("joins", []) as Array
	for i in range(7):
		var row: Dictionary = joins[i] as Dictionary
		var xyz: Array = row["xyz"] as Array
		var expected := Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2]))
		var markers := scene.find_children(String(row["id"]), "Marker3D", true, false)
		_check(markers.size() == 1, "one marker for " + String(row["id"]))
		if markers.size() == 1:
			_check((markers[0] as Node3D).global_position.is_equal_approx(expected), "reference join " + String(row["id"]))
	_check(scene.global_basis.is_equal_approx(Basis.IDENTITY), "world-aligned coordinate basis")
	var garden := scene.get_node("Sections/S02/Garden") as Node3D
	var stones: Array[String] = ["P21","P22","P23","P24"]
	var expected_gaps: Array[float] = [1.2,1.6,2.0]
	for i in range(3):
		var a := garden.get_node(stones[i]) as Node3D
		var b := garden.get_node(stones[i+1]) as Node3D
		_check(is_equal_approx(absf(a.position.z-b.position.z)-3.0,expected_gaps[i]), "reference garden gap %d" % i)
	var prefix: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("swim",Vector3(-4,-0.8,-7),"arrival"),
		RoutePilot.at("walk",Vector3(4,1.2,-8),"shore"),
		RoutePilot.at("walk",Vector3(4,1.2,-16),"bank"),
		RoutePilot.at("walk",Vector3(-10.5,1.2,-18),"garden turn"),
		RoutePilot.at("walk",Vector3(-10.5,1.2,-22),"approach"),
		RoutePilot.at("walk",Vector3(-22,1.2,-22),"P21 approach"),
		RoutePilot.at("walk",Vector3(-22,1.2,-25),"P21"),
		RoutePilot.at("jump",Vector3(-22,1.3,-29.2),"P22"),
		RoutePilot.at("jump",Vector3(-22,1.45,-33.8),"P23"),
		RoutePilot.at("jump",Vector3(-22,1.6,-38.8),"P24"),
		RoutePilot.at("walk",Vector3(-22,1.6,-44),"JOIN_23"),
		RoutePilot.at("swim",Vector3(-22,-1.6,-50),"dive"),
		RoutePilot.at("swim",Vector3(-18,-1.6,-55),"root entry"),
		RoutePilot.at("swim",Vector3(-10,-1.6,-58),"root bend"),
		RoutePilot.at("swim",Vector3(4,-1.6,-58),"root exit"),
		RoutePilot.at("swim",Vector3(8,-0.1,-56),"resurface"),
		RoutePilot.at("walk",Vector3(13,1.6,-56),"JOIN_34"),
		RoutePilot.at("walk",Vector3(16,1.6,-57),"CP_02"),
		RoutePilot.at("walk",Vector3(22,1.6,-57.5),"A approach"),
	]
	await drive(prefix, "continuous sections 1–3 and CP_02")
	await jump(Vector3(22,2.4,-61.9),"A1 +0.8")
	await jump(Vector3(22,3.2,-66),"A2 +0.8")
	var to_climb: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk",Vector3(22,3.2,-68.2),"A rest"),
		RoutePilot.at("walk",Vector3(30,3.2,-70),"B approach"),
		RoutePilot.at("climb",Vector3(30,3.2,-75),"2m climb face"),
		RoutePilot.at("walk",Vector3(30,5.2,-78.5),"B seed ledge"),
	]
	await drive(to_climb, "cluster B climb")
	_check(int(terraces.get("seeds_collected")) == 2, "two terrace seeds collected")
	await drive(pool_b_route(), "required pool B dive")
	_check(body.is_on_floor() and not body.is_in_water(),"B exit dry")
	await jump(Vector3(21,6,-88),"C1 +0.8")
	await jump(Vector3(16.5,6.8,-88),"C2 +0.8")
	await jump(Vector3(16.5,7.6,-92),"C3 +0.8")
	await drive([RoutePilot.at("walk",Vector3(24,7.6,-92),"JOIN_45")],"terrace exit")
	_check(body.is_on_floor() and not body.is_in_water(),"JOIN_45 supported")
	# Continue across the new seam with the two seeds actually collected above.
	var session := scene.get_node("PreviewSession")
	var before_garden := int(session.get("recoveries"))
	var garden_route: Array[RoutePilot.Waypoint] = []
	for p: Vector3 in [Vector3(24,7.6,-95.5),Vector3(27,7.6,-95),Vector3(31,7.6,-99),Vector3(31,7.6,-105),Vector3(29,7.6,-105),Vector3(21,7.6,-107),Vector3(16,7.8,-107),Vector3(13,7.8,-103),Vector3(12,7.8,-104),Vector3(8,7.8,-104)]:
		garden_route.append(RoutePilot.at("walk",p,"restoration garden"))
	await drive(garden_route,"continuous S01–S05 to JOIN_56")
	_check(int(session.get("recoveries"))==before_garden,"garden seam needs no fallback")
	_check((session.get("taken") as Dictionary).size()==7,"two terrace plus five garden seeds")
	_check((session.get("restoration") as RestorationSystem).all_restored(),"continuous run opens gate")
	_check(String(session.get("checkpoint"))=="CP_03","continuous run activates garden checkpoint")
	_check(body.is_on_floor() and not body.is_in_water(),"JOIN_56 supported")
	await drive(chute_route(),"continuous S01–S06 to JOIN_OUT")
	_check(bool(session.get("completed")),"reach_volume callback completes continuous route")
	_check(int(session.get("recoveries"))==before_garden,"finale needs no fallback")
	_check(body.is_on_floor() and not body.is_in_water(),"JOIN_OUT supported")
	# Independent cases start at their approach; traversal itself uses input.
	await reset_body(Vector3(22,3.25,-70))
	var bypass: Array[RoutePilot.Waypoint] = [
		RoutePilot.at("walk",Vector3(22,3.2,-77),"bypass ramp base"),
		RoutePilot.at("walk",Vector3(30,5.2,-77),"bypass ramp top"),
	]
	body.get_controller().get_capability_modifiers().set_factor("test_leg_loss",0.5,CapabilityModifiers.Target.CLIMB_HEIGHT)
	await drive(bypass,"reduced-climb ramp bypass")
	body.get_controller().get_capability_modifiers().clear_factor("test_leg_loss")
	_check(body.global_position.y > 5.0,"bypass reaches upper ledge")
	var recovery_cases: Array[Array] = [
		[Vector3(22,2.45,-61.9),Vector3(24,-0.7,-61),Vector3(27,1.6,-61)],
		[Vector3(22,3.25,-66),Vector3(17,1,-66),Vector3(22,3.2,-66)],
		[Vector3(21,6.05,-88),Vector3(23,3,-88),Vector3(26,5.2,-91.5)],
		[Vector3(16.5,6.85,-88),Vector3(13.3,5,-88),Vector3(16.5,6.8,-88)],
		[Vector3(16.5,7.65,-92),Vector3(18.8,3,-89.8),Vector3(26,5.2,-91.5)],
	]
	for i in range(recovery_cases.size()):
		var c: Array = recovery_cases[i]
		await reset_body(c[0] as Vector3)
		var r: Array[RoutePilot.Waypoint] = [
			RoutePilot.at("swim",c[1] as Vector3,"miss into catch pool"),
			RoutePilot.at("walk",c[2] as Vector3,"local recovery ramp"),
		]
		if i == 2 or i == 4:
			r.insert(1,RoutePilot.at("swim",Vector3(18,3,-91.5),"line up with ramp foot"))
		var result: Dictionary = await drive(r,"local miss recovery %d" % (i+1))
		_check(body.global_position.y > 0.5,"miss is safely caught by pool or recovery ramp")
		_check(body.is_on_floor() and not body.is_in_water(),"recovery returns to dry support")
	# Higher water regions must not leak onto lower takeoffs.
	for p: Vector3 in [Vector3(22,1.6,-57),Vector3(22,2.4,-61.9),Vector3(30,3.2,-71),Vector3(21,6,-88)]:
		await reset_body(p+Vector3.UP*0.05)
		_check(not body.is_in_water(),"dry support stays dry at "+str(p))
	print("LIVING CASCADE TERRACES: ","PASS" if failures.is_empty() else "FAIL")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)

func pool_b_route() -> Array[RoutePilot.Waypoint]:
	return [
		RoutePilot.at("swim",Vector3(30,2.1,-81),"dive before brow"),
		RoutePilot.at("swim",Vector3(30,2.1,-85.3),"under brow"),
		RoutePilot.at("swim",Vector3(34.5,2.1,-85.5),"side basin"),
		RoutePilot.at("walk",Vector3(34.5,5.2,-92.7),"pool exit ramp"),
		RoutePilot.at("walk",Vector3(26.5,5.2,-92.7),"bank link"),
		RoutePilot.at("walk",Vector3(26.5,5.2,-88),"C start"),
	]
func drive(route: Array[RoutePilot.Waypoint],label: String) -> Dictionary:
	var pilot := RoutePilot.new(route)
	var wet := false
	for frame in range(9000):
		await physics_frame
		wet = wet or body.is_in_water()
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for frame in range(40):
		await physics_frame
		wet = wet or body.is_in_water()
	_check(pilot.is_done(),label+": "+pilot.stuck_reason())
	print(label," / ",body.global_position)
	return {"water":wet}
func jump(target: Vector3,label: String) -> void:
	var result: Dictionary = await drive([RoutePilot.at("jump",target,label)],label)
	_check(not bool(result["water"]),label+" stays dry")
	_check(body.is_on_floor() and body.global_position.distance_to(target)<1.8,label+" lands")
func reset_body(p: Vector3) -> void:
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.global_position=p
	body.velocity=Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.resample_water_contacts()
	for frame in range(20):
		await physics_frame
func _check(ok: bool,label: String) -> void:
	if not ok:
		failures.append(label)


func chute_route(boosted: bool = false) -> Array[RoutePilot.Waypoint]:
	var result: Array[RoutePilot.Waypoint] = []
	for p: Vector3 in [Vector3(4,5.1,-106),Vector3(0,4.6,-110),Vector3(-7,3.3,-113.5),Vector3(-10,2.3,-115),Vector3(-13,1.7,-116.5),Vector3(-16,1,-118),Vector3(-19,0.9,-118),Vector3(-23,-0.6,-114),Vector3(-27,-0.8,-109),Vector3(-28,-0.8,-104)]:
		result.append(RoutePilot.at("swim",p,"downstream"))
		if boosted and p.x==-7:
			result.append(RoutePilot.at("boost",Vector3(-13,1.7,-116.5),"boost before bar"))
	result.append(RoutePilot.at("swim",Vector3(-29,-0.8,-106),"line up with shore ramp"))
	for p: Vector3 in [Vector3(-36,1.8,-106),Vector3(-38,1.8,-106),Vector3(-38,1.8,-110)]:
		result.append(RoutePilot.at("walk",p,"final bank"))
	return result
