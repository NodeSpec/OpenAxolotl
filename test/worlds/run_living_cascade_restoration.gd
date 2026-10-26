extends SceneTree
var failures: PackedStringArray = []
var scene: Node3D
var body: AxolotlBody
var session: Node
var garden: Node3D
var disk_path := "res://review/living-cascade-save-test-%d.json" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("_run")

func start_scene(path: String) -> void:
	if scene != null:
		scene.queue_free()
		await process_frame
	scene = (load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	session = scene.get_node("PreviewSession")
	session.set("save_path",path)
	root.add_child(scene)
	current_scene = scene
	body = scene.get_node("Axolotl") as AxolotlBody
	garden = scene.get_node("Sections/S05/RestorationGarden") as Node3D
	for frame in range(30):
		await physics_frame

func _run() -> void:
	for extras in range(3):
		await start_scene(disk_path if extras == 0 else "")
		# Setup only: the terrace traversal test proves these two touch pickups.
		for id: String in (["terrace_SeedA","terrace_SeedB"] as Array[String]).slice(0,extras):
			session.call("_on_seed",body,id)
		await reset_body(Vector3(24,7.65,-92))
		await drive([Vector3(24,7.6,-95.5)],"mandatory checkpoint approach")
		check(String(session.get("checkpoint")) == "CP_03","CP_03 cannot be missed on entry")
		var points: Array[Array] = [
			[Vector3(27,7.6,-95)],
			[Vector3(31,7.6,-99)],
			[Vector3(31,7.6,-105),Vector3(29,7.6,-105)],
			[Vector3(21,7.6,-107)],
			[Vector3(16,7.8,-107),Vector3(13,7.8,-103)],
			[Vector3(16,7.8,-97)],
			[Vector3(12,7.8,-101)],
		]
		for i in range(7):
			await drive(points[i],"%d extras / garden seed %d" % [extras,i+1])
			var total := extras+i+1
			check((session.get("taken") as Dictionary).size() == total,"unique pickup count %d" % total)
			var restoration := session.get("restoration") as RestorationSystem
			var state := restoration.get_state("coral_shelf")
			var expected := RegionState.State.BARREN if total<3 else (RegionState.State.RESOURCED if total<7 else RegionState.State.RESTORED)
			check(state==expected,"automatic phase at total %d" % total)
			var spent := 0 if total<3 else (3 if total<7 else 7)
			check(restoration.get_region("coral_shelf").get_resources()==total-spent,"exact balance after spending")
			check((garden.get_node("Gate/Collision") as CollisionShape3D).disabled==(total>=7),"gate tracks restored state")
			if extras==0 and i==2:
				var loaded := SaveSystem.new()
				check(loaded.load_from_file(disk_path),"saved after first automatic spend")
				var data := loaded.get_world_data("living_cascade_development_v1")
				var region: Dictionary = (data["regions"] as Dictionary)["coral_shelf"] as Dictionary
				check(String(region["state"])=="resourced","disk preserves partial phase")
			if extras==0 and i==5:
				await start_scene(disk_path)
				check(body.global_position.distance_to(Vector3(24,7.6,-94))<0.3,"reload returns to CP_03")
				check((session.get("taken") as Dictionary).size()==6,"six seed identities survive reload")
				check((session.get("restoration") as RestorationSystem).get_region("coral_shelf").get_resources()==3,"banked resources survive reload")
				for n in range(1,7):
					check(not (garden.get_node("Seed%d" % n) as Area3D).visible,"spent seed stays absent")
				await drive([Vector3(24,7.6,-95.5),Vector3(16,7.8,-96),Vector3(16,7.8,-97)],"revisit collected seed after reload")
				check((session.get("taken") as Dictionary).size()==6,"retry cannot duplicate a seed")
				check((session.get("restoration") as RestorationSystem).get_state("coral_shelf")==RegionState.State.RESOURCED,"duplicate cannot open gate")
		await drive([Vector3(12,7.8,-104),Vector3(8,7.8,-104)],"open gate to JOIN_56")
		check(body.is_on_floor() and not body.is_in_water(),"JOIN_56 has dry support")
		if extras==0:
			await start_scene(disk_path)
			check((garden.get_node("Gate/Collision") as CollisionShape3D).disabled,"restored gate remains open after reload")
			var count := int(session.get("recoveries"))
			body.global_position=Vector3(20,-3.5,-75)
			for frame in range(30):
				await physics_frame
			check(int(session.get("recoveries"))==count+1,"unexpected fall returns once")
			check(body.global_position.distance_to(Vector3(24,7.6,-94))<0.3,"fall returns to latest checkpoint")
			check((session.get("taken") as Dictionary).size()==7,"retry retains pickups")
		# Both 4m basin exits, using the real controller from underwater starts.
		for end: Vector3 in [Vector3(16,7.8,-101),Vector3(28,7.6,-101)]:
			await reset_body(Vector3(22,5.1,-101))
			await drive([end],"garden basin exit")
			check(body.is_on_floor() and not body.is_in_water(),"basin exit reaches dry bank")
	print("LIVING CASCADE RESTORATION: ","PASS" if failures.is_empty() else "FAIL")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)

func drive(points: Array,label: String) -> void:
	var route: Array[RoutePilot.Waypoint] = []
	for p: Vector3 in points:
		route.append(RoutePilot.at("walk",p,label))
	var pilot := RoutePilot.new(route)
	var before := int(session.get("recoveries"))
	for frame in range(2500):
		await physics_frame
		pilot.step(body)
		if pilot.is_done() or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	for frame in range(40):
		await physics_frame
	check(pilot.is_done(),label+": "+pilot.stuck_reason())
	check(int(session.get("recoveries"))==before,label+" does not use fallback recovery")
	print(label," / ",body.global_position)

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
