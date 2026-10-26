extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var checks: int = 0
var failures: PackedStringArray = []

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for frame: int in count:
		await physics_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ",message)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func place(point: Vector3) -> void:
	body.get_input_system().clear()
	hub._move_player_to(point)
	body.get_camera().set_yaw_deg(0)

func run() -> void:
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	var art := hub.get_node("LagoonArt") as LagoonArt
	check(art.has_node("SolidRocks"),"Reshaped rock dressing has real collision")
	var solids := art.find_children("*","StaticBody3D",true,false)
	check(solids.size() >= 18,"Imported boulders and coral bases are solid")
	place(Vector3(-7.4,3.5,7.6))
	await frames(100)
	check(body.is_on_floor() and body.position.y > 1.65,"Character can stand on the supplied boulder: "+str(body.position))
	place(Vector3(-4.6,1.1,7.6))
	await frames(40)
	key(KEY_A,true)
	await frames(95)
	key(KEY_A,false)
	check(body.position.x > -6.7,"Boulder blocks walking through its side: "+str(body.position))
	for x: float in [-10.0,0.0,10.0]:
		place(Vector3(x,1.5,21))
		await frames(90)
		check(body.get_water_volume() != null,"Beach shelf is wet at "+str(x))
		check(body.is_on_floor() and not body.is_in_water(),"Beach shelf only allows wading at "+str(x))
	place(Vector3(0,1.5,21))
	await frames(60)
	key(KEY_S,true)
	var low: float = body.position.y
	for frame: int in 480:
		await physics_frame
		low = minf(low,body.position.y)
	key(KEY_S,false)
	check(body.position.z < 35.0 and low > -0.5,"Dunes stop the player before any map edge: "+str(body.position))
	for side: int in [-1,1]:
		place(Vector3(side*22,8,22))
		await frames(100)
		key(KEY_A if side < 0 else KEY_D,true)
		await frames(400)
		key(KEY_A if side < 0 else KEY_D,false)
		check(absf(body.position.x) < 29.0 and body.position.y > -0.5,"Side boundary contains the player: "+str(body.position))
	place(Vector3(-4.3,-0.5,0))
	await frames(100)
	check(body.is_in_water(),"Original lagoon pocket still supports swimming")
	check(body.get_visual_motion().swim_drive < 0.2,"Stationary swimmer settles into treading")
	var first: float = body.get_visual_motion().swim_phase
	await frames(20)
	check(not is_equal_approx(first,body.get_visual_motion().swim_phase),"Treading keeps moving at rest")
	check(hub.enter_world("coral_cove"),"Existing level opens")
	await frames(4)
	check(not art.can_process() and not art.is_visible_in_tree(),"Hub collision and art disable outside the lagoon")
	hub.notify_finish_condition_met()
	await frames(4)
	check(art.can_process() and art.is_visible_in_tree(),"Hub collision and art return together")
	stage.queue_free()
	await process_frame
	print("TIGHTENED LAGOON: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
