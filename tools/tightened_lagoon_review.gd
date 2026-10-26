extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var camera: Camera3D
var follow_body: bool = false
var submerged: bool = false
var checks: int = 0
var failures: PackedStringArray = []
var tested_spray: bool = false

func _initialize() -> void:
	run.call_deferred()

func _process(_delta: float) -> bool:
	if follow_body and is_instance_valid(camera):
		camera.position = body.position+Vector3(2.0,0.06 if submerged else 1.2,2.1)
		camera.look_at(body.position+Vector3(0,-0.03 if submerged else -0.35,0))
	return false

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

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://review/tightened_%s.png" % label)
	check(result == OK,"Saved "+label)

func record(label: String, count: int) -> void:
	for index: int in count:
		await physics_frame
		await capture("%s_%02d" % [label,index])
		for node: Node in stage.find_children("RunningSpray*","CPUParticles3D",true,false):
			var spray := node as CPUParticles3D
			var box: AABB = spray.capture_aabb()
			if box.size.length() < 0.01:
				continue
			var world_box: AABB = spray.global_transform*box
			var origin: Vector3 = spray.get_meta("emission_origin")
			check(Vector2(world_box.get_center().x-origin.x,world_box.get_center().z-origin.z).length() < 1.5,"Particles originate near their actual contact, not world origin")
			if not tested_spray:
				print("PARTICLE BOUNDS origin=",origin," local=",box," world=",world_box)
				tested_spray = true

func run() -> void:
	root.size = Vector2i(1280,720)
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	body.get_camera().set_physics_process(false)
	hub.get_hud().visible = false
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.make_current()
	camera.fov = 65
	camera.position = Vector3(0,3.8,10.5)
	camera.look_at(Vector3(0,1.8,-8))
	await frames(40)
	await capture("hero")
	camera.position = Vector3(0,5.5,10)
	camera.look_at(Vector3(0,1.2,26))
	await frames(20)
	await capture("beach")
	camera.position = Vector3(6,3,3)
	camera.look_at(Vector3(11.2,1.2,-1.8))
	await frames(20)
	await capture("inlet")
	place(Vector3(-7.4,3.5,7.6))
	follow_body = true
	camera.fov = 54
	await frames(100)
	await capture("on_boulder")
	place(Vector3(0.6,1.0,5.0))
	await frames(40)
	key(KEY_D,true)
	await record("splash",24)
	key(KEY_D,false)
	check(tested_spray,"Actual moving CPU particles were inspected")
	place(Vector3(-4.8,-0.55,-0.3))
	submerged = true
	await frames(55)
	check(body.is_in_water(),"Review is in a real swimming pocket")
	await record("tread",24)
	key(KEY_D,true)
	await record("kick",24)
	key(KEY_D,false)
	check(body.get_visual_motion().swim_drive > 0.65,"Moving swim blends into tucked kicking")
	place(Vector3(0,1.2,21))
	submerged = false
	await frames(65)
	key(KEY_D,true)
	await record("beach_wade",18)
	key(KEY_D,false)
	check(not body.is_in_water(),"Beach remains wading-only")
	print("TIGHTENED REVIEW: %d checks, %d failures" % [checks,failures.size()])
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
