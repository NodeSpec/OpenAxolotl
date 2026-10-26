extends SceneTree
var failures: PackedStringArray = []
var stage: Node3D
var world: Node3D
var body: AxolotlBody
var systems: WorldSystems
var save := SaveSystem.new()
var finished := false
var origin := Vector3(70,-6.8,30)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json")) as Dictionary
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dev/archive/coral_cove_before_cascade/world.json")) as Dictionary
	# A real legacy-shaped profile is migrated without dropping matching rewards.
	save.open_world("coral_cove",old)
	save.put_world_data("coral_cove",{"completed":true,"regions":{"coral_shelf":{"state":"resourced","unlocked":true,"resources":2},"open_sea":{"state":"restored"}},"collectibles":["hermit_snail","fleet_beacon"],"lastCheckpoint":"OldAnchor"})
	save.open_world("coral_cove",manifest)
	var migrated := save.get_world_data("coral_cove")
	check(bool(migrated["completed"]),"legacy completion preserved")
	check((migrated["regions"] as Dictionary).has("coral_shelf") and not (migrated["regions"] as Dictionary).has("open_sea"),"only current region remains active")
	check("hermit_snail" in migrated["collectibles"] and not "fleet_beacon" in migrated["collectibles"],"matching discovery preserved")
	check((migrated["quarantined"] as Dictionary).get("lastCheckpoint","")=="OldAnchor","complete old blob archived")
	save=SaveSystem.new()
	save.open_world("coral_cove",manifest)
	stage=Node3D.new()
	root.add_child(stage)
	current_scene=stage
	stage.add_child((load("res://core/rendering/world_lighting.tscn") as PackedScene).instantiate())
	body=(load("res://core/controller/axolotl_body.tscn") as PackedScene).instantiate() as AxolotlBody
	body.name="Axolotl"
	stage.add_child(body)
	var camera := CameraFollow.new()
	camera.name="Camera"
	camera.target_path=NodePath("../Axolotl")
	camera.current=true
	stage.add_child(camera)
	world=(load("res://worlds/coral_cove/world.tscn") as PackedScene).instantiate() as Node3D
	world.position=origin
	stage.add_child(world)
	body.global_position=origin+Vector3(0,-0.4,1)
	systems=WorldSystems.new()
	systems.manifest=manifest
	systems.world_id="coral_cove"
	systems.save_system=save
	world.add_child(systems)
	var errors: Array[HubError]=[]
	check(WorldLoader.new().wire_finish_condition(world,"reach_volume",func() -> void: finished=true,errors),"production finish wired")
	for frame in range(30):
		await physics_frame
	check(world.find_children("PreviewSession","",true,false).is_empty(),"no development adapter")
	check(world.find_children("Axolotl","",true,false).is_empty(),"only hub player")
	var pilot := RoutePilot.new(CoralRoute.waypoints(),origin)
	for frame in range(18000):
		await physics_frame
		pilot.step(body)
		if finished or not pilot.stuck_reason().is_empty():
			break
	pilot.release_all()
	check(finished,"translated full production route: "+pilot.stuck_reason()+" at "+str(body.global_position-origin))
	check(systems.get_restoration().all_restored(),"real restoration opens gate")
	check(systems.get_lives().get_active_checkpoint()=="CP_03","production checkpoint activated")
	check((save.get_world_data("coral_cove").get("resourceInstances",{}) as Dictionary).size()==7,"seven unique physical pickups persisted")
	var before := systems.get_lives().get_lives()
	body.clear_water_contacts()
	body.global_position=origin+Vector3(20,-6.8,-75)
	body.velocity=Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	for frame in range(35):
		await physics_frame
	check(systems.get_lives().get_lives()==before,"escape failsafe preserves lives")
	check(body.global_position.distance_to(origin+Vector3(24,7.6,-94))<0.4,"escape failsafe returns to dry CP_03")
	check(not body.is_in_water(),"checkpoint clears stale water contact")
	check(camera.get_rig().get_hint_stack().has((world.get_node("CrownView") as CameraHintVolume).hint_id()),"real overlap applies crown camera hint")
	check(absf(camera.get_rig().get_pitch_deg()-8.0)<1.0,"crown framing reaches authored pitch")
	systems.persist_progress()
	var disk := "res://review/cascade-production-save-%d.json" % Time.get_ticks_usec()
	check(save.save_to_file(disk),"production profile writes")
	var reopened := SaveSystem.new()
	check(reopened.load_from_file(disk),"production profile reloads")
	world.queue_free()
	await process_frame
	check(camera.get_rig().get_hint_stack().size()==0,"unloaded world releases all camera hints")
	world=(load("res://worlds/coral_cove/world.tscn") as PackedScene).instantiate() as Node3D
	world.position=origin
	stage.add_child(world)
	systems=WorldSystems.new()
	systems.manifest=manifest
	systems.world_id="coral_cove"
	systems.save_system=reopened
	world.add_child(systems)
	for frame in range(10):
		await physics_frame
	check(systems.get_restoration().all_restored(),"gate state survives reload")
	var remaining := 0
	for n: Node in world.find_children("*","Area3D",true,false):
		if n.is_in_group("collectible") and String(n.get_meta("collectible_id",""))=="kelp_seed":
			remaining+=1
	check(remaining==2,"collected seed instances stay absent")
	print("CASCADE PRODUCTION: ","PASS" if failures.is_empty() else "FAIL")
	for f in failures:
		print("  ",f)
	quit(0 if failures.is_empty() else 1)
func check(ok: bool,label: String) -> void:
	if not ok:
		failures.append(label)
