extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var camera: Camera3D
var checks: int = 0
var failures: PackedStringArray = []

func _initialize() -> void:
	root.size = Vector2i(1280,720)
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ",message)

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame

func aim(position: Vector3, target: Vector3) -> void:
	camera.global_position = position
	camera.look_at(target)

func capture(label: String) -> Image:
	await RenderingServer.frame_post_draw
	var result: Image = root.get_texture().get_image()
	check(result.save_png("res://review/water_%s.png" % label) == OK,"Saved "+label)
	return result

func run() -> void:
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	(stage.get_node("Camera") as Camera3D).set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 65.0
	stage.add_child(camera)
	camera.make_current()
	hub.get_hud().visible = false
	aim(Vector3(-9,2.5,5),Vector3(-6.5,0,-1))
	hub._move_player_to(Vector3(-8.3,1,1))
	await frames(50)
	var still: Image = await capture("still")
	await frames(50)
	var later: Image = await capture("animated")
	var changed: int = 0
	var samples: int = 0
	for y: int in range(later.get_height()/2,later.get_height()-30,6):
		for x: int in range(50,later.get_width()-50,6):
			var a: Color = still.get_pixel(x,y)
			var b: Color = later.get_pixel(x,y)
			if Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length() > 0.015:
				changed += 1
			samples += 1
	check(changed > samples/25,"Visible water animation in fixed-camera pixels: %d/%d" % [changed,samples])
	print("WATER PIXELS: %d/%d changed" % [changed,samples])
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await frames(24)
	check(not body.is_in_water(),"Wading retains land animation")
	check(not stage.find_children("RunningSpray*","",true,false).is_empty(),"Running spray exists in rendered scene")
	await capture("wading")
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	Input.parse_input_event(event)
	body.get_input_system().clear()
	hub._move_player_to(Vector3(-4.3,-0.5,0))
	await frames(15)
	check(body.is_in_water(),"Lagoon pocket enables swimming")
	aim(Vector3(-2,2.3,3),Vector3(-4.3,0,-0.5))
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await frames(24)
	check(body.is_in_water() and body.velocity.length() > 1.0,"Swimming moves through the pocket")
	check(not stage.find_children("MotionRipple*","",true,false).is_empty(),"Swimming emits surface ripples")
	await capture("swimming")
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	Input.parse_input_event(event)
	body.get_input_system().clear()
	aim(Vector3(-4.3,-0.8,1.3),Vector3(-4.3,-0.8,-3))
	await frames(50)
	check(camera.environment == null,"Deep lagoon camera has no depth grade")
	check(hub.enter_world("coral_cove"),"Coral Cove entered for depth review")
	await frames(15)
	var volume := hub._active_world.get_node("Waterway") as WaterVolume
	var point: Vector3 = volume.global_position
	var surface: float = volume.surface_at(point)
	hub._move_player_to(Vector3(point.x,surface-2.5,point.z))
	body.set_physics_process(false)
	body.register_water(volume)
	aim(Vector3(point.x,surface+0.7,point.z+3),Vector3(point.x,surface,point.z-6))
	await frames(60)
	check(camera.environment == null,"Above-water camera remains ungraded")
	await capture("level_surface")
	aim(Vector3(point.x,surface-1,point.z+3),Vector3(point.x,surface-1,point.z-6))
	await frames(90)
	check(camera.environment != null,"Underwater camera obtains local grade")
	var shallow_exposure: float = camera.environment.tonemap_exposure if camera.environment != null else 0.0
	await capture("level_shallow")
	aim(Vector3(point.x,surface-6,point.z+3),Vector3(point.x,surface-6,point.z-6))
	await frames(90)
	check(camera.environment != null and camera.environment.tonemap_exposure < shallow_exposure,"Deeper camera subtly reduces exposure")
	await capture("level_deep")
	aim(Vector3(point.x,surface+1,point.z+3),Vector3(point.x,surface,point.z-6))
	await frames(130)
	check(camera.environment == null,"Surfacing restores camera environment")
	hub.notify_finish_condition_met()
	await frames(10)
	check(camera.environment == null,"Returning to lagoon clears depth grade")
	print("WATER REVIEW: %d checks, %d failures" % [checks,failures.size()])
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
