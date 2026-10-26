extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var checks: int = 0
var failures: PackedStringArray = []
var entered: String = ""

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ",message)

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func place(point: Vector3) -> void:
	hub._move_player_to(point)
	body.get_input_system().clear()
	var camera: CameraFollow = body.get_camera()
	if camera != null:
		camera.set_yaw_deg(0.0)

func run() -> void:
	stage = (load("res://hub/open_lagoon.tscn") as PackedScene).instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	var surface := hub.get_node("Hydrology/LagoonSurface") as MeshInstance3D
	var normals: PackedVector3Array = surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].y > 0.9,"Water normals point toward the sky: "+str(normals[0]))
	hub.world_entered.connect(func(id: String) -> void: entered = id)
	place(Vector3(-8.3,1.0,1.0))
	await frames(70)
	check(not body.is_in_water(),"Shallow water keeps land movement")
	check(body.get_water_volume() != null,"Shallows still register as wet")
	var resting: Vector3 = body.global_position
	await frames(60)
	check(body.global_position.distance_to(resting) < 0.04,"Idle player does not drift in lagoon")
	key(KEY_W,true)
	await frames(35)
	check(not body.is_in_water(),"Running through shallows does not activate swimming")
	check(not stage.find_children("RunningSpray*","",true,false).is_empty(),"Running creates repeated spray")
	key(KEY_W,false)
	place(Vector3(-4.3,-0.5,0))
	await frames(15)
	check(body.is_in_water(),"Teleport within one volume preserves swimming contact")
	place(Vector3(-4.3,1.0,4.7))
	await frames(30)
	key(KEY_W,true)
	for i: int in 180:
		await physics_frame
		if body.is_in_water():
			break
	check(body.is_in_water(),"Walking down a pocket slope activates swimming")
	key(KEY_W,false)
	key(KEY_S,true)
	for i: int in 180:
		await physics_frame
		if not body.is_in_water():
			break
	check(not body.is_in_water(),"Returning up a pocket slope restores running")
	key(KEY_S,false)
	var portals: Array[WorldPortal] = hub.get_registry().get_available()
	for portal: WorldPortal in portals:
		var entrance := hub.find_child("Portal_%s" % portal.world_id,true,false) as Node3D
		entered = ""
		place(Vector3(entrance.position.x,1.0,-3.5))
		await frames(30)
		key(KEY_W,true)
		var swam: bool = false
		var felt_current: bool = false
		var frame_budget: int = 1600 if portal.world_id == hub._stream_world_id else 360
		for i: int in frame_budget:
			await physics_frame
			if not entered.is_empty():
				break
			swam = swam or body.is_in_water()
			var water: WaterVolume = body.get_water_volume()
			if water != null:
				felt_current = felt_current or not water.flow_at(body.global_position).is_zero_approx()
		key(KEY_W,false)
		check(swam,"Swam into "+portal.world_id)
		check(felt_current,"Localized current reached "+portal.world_id)
		check(entered == portal.world_id,"Downstream passage selected "+portal.world_id+" at "+str(body.global_position))
		if hub.is_in_world():
			hub.notify_finish_condition_met()
		await frames(30)
		check(not hub.is_in_world(),"Returned from "+portal.world_id)
	print("WATER WALK: %d checks, %d failures" % [checks,failures.size()])
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
