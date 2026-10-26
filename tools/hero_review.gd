extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var camera: Camera3D
var effects: HeroSurfaceEffects
var checks: int = 0
var failures: PackedStringArray = []
var spin_travel: float = 0.0
var previous_spin: Quaternion
var measuring_spin: bool = false
var underwater_review: bool = false

func _initialize() -> void:
	root.size = Vector2i(1280,720)
	run.call_deferred()

func _process(_delta: float) -> bool:
	if is_instance_valid(camera) and is_instance_valid(body):
		camera.global_position = body.global_position+Vector3(2.2,0.05 if underwater_review else 1.1,2.4)
		camera.look_at(body.global_position+Vector3(0,0.0 if underwater_review else -0.32,0.15))
	return false

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
	body.get_input_system().clear()
	hub._move_player_to(point)
	body.get_camera().set_yaw_deg(0.0)

func record(label: String, count: int) -> void:
	var first: Image
	for frame: int in count:
		await physics_frame
		camera.global_position = body.global_position+Vector3(2.2,0.05 if underwater_review else 1.1,2.4)
		camera.look_at(body.global_position+Vector3(0,0.0 if underwater_review else -0.32,0.15))
		await RenderingServer.frame_post_draw
		var rendered: Image = root.get_texture().get_image()
		check(rendered.save_png("res://review/hero_%s_%02d.png" % [label,frame]) == OK,"Capture "+label)
		if frame == 0:
			first = rendered
		if frame == count-1:
			var difference: float = 0.0
			for y: int in range(140,580,20):
				for x: int in range(380,900,20):
					var a: Color = first.get_pixel(x,y)
					var b: Color = rendered.get_pixel(x,y)
					difference += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
			check(difference > 1.0,"Nonblank moving character pixels in "+label)
	print("HERO CAPTURE ",label," clip=",body.get_animator().get_current_clip()," feet=",effects.footfalls," sand=",effects.sand_steps," wet=",effects.wet_steps," bubbles=",effects.bubble_bursts)

func run() -> void:
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	effects = body.get_node("HeroSurfaceEffects") as HeroSurfaceEffects
	body.get_camera().set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 52
	stage.add_child(camera)
	camera.make_current()
	hub.get_hud().visible = false
	place(Vector3(-3,1.1,9))
	await frames(35)
	check(body.is_on_floor() and not body.is_in_water(),"Dry shore has land contact")
	var start_sand: int = effects.sand_steps
	key(KEY_D,true)
	await record("walk",24)
	key(KEY_D,false)
	check(effects.sand_steps > start_sand+2,"Gait contacts kick sand on dry shore")
	check(not stage.find_children("SandFootprint*","",true,false).is_empty(),"Dry ground carries fading footprints")
	var yaw: float = body.get_visual_motion().visual_rotation.y
	key(KEY_W,true)
	await record("turn",10)
	key(KEY_W,false)
	check(absf(wrapf(body.get_visual_motion().visual_rotation.y-yaw,-PI,PI)) > 0.2,"Actual input turns the visual gradually")
	place(Vector3(0,1.1,9))
	await frames(30)
	key(KEY_F,true)
	await frames(3)
	key(KEY_F,false)
	check(body.get_animator().get_current_action() == HeroAnimator.WHACK,"Tail combat starts from the real F binding")
	var still: Vector3 = body.global_position
	await record("whack",14)
	check(body.global_position.distance_to(still) < 0.08,"Tail attack does not displace physics capsule")
	await frames(30)
	key(KEY_D,true)
	await frames(12)
	key(KEY_F,true)
	await frames(3)
	key(KEY_F,false)
	var contacts: int = effects.footfalls
	await record("moving_whack",14)
	key(KEY_D,false)
	check(effects.footfalls > contacts,"Moving tail attack retains gait contacts")
	place(Vector3(-8.3,1.0,1))
	await frames(30)
	var start_wet: int = effects.wet_steps
	start_sand = effects.sand_steps
	key(KEY_W,true)
	await record("wade",16)
	key(KEY_W,false)
	check(effects.wet_steps > start_wet,"Shallow foot contacts produce water spray")
	check(effects.sand_steps == start_sand,"Submerged sand does not emit dry dust")
	check(hub.enter_world("coral_cove"),"Deep-water level opens for full spin review")
	underwater_review = true
	await frames(15)
	var volume := hub._active_world.get_node("Waterway") as WaterVolume
	var centre: Vector3 = volume.global_position
	var top: float = volume.surface_at(centre)
	place(Vector3(-9,top-0.30,centre.z))
	await frames(20)
	check(body.is_in_water(),"Swimming camera uses real deep-water volume")
	key(KEY_D,true)
	await record("swim",16)
	check(body.get_visual_motion().swim_weight > 0.95,"Swimming body posture has blended in")
	var motion := body.get_visual_motion()
	var skeleton := motion.get_skeleton()
	var root_bone: int = skeleton.find_bone("root")
	motion.modification_processed.connect(func() -> void:
		if measuring_spin:
			var rotation: Quaternion = skeleton.get_bone_pose_rotation(root_bone)
			spin_travel += previous_spin.angle_to(rotation)
			previous_spin = rotation)
	previous_spin = skeleton.get_bone_pose_rotation(root_bone)
	measuring_spin = true
	key(KEY_F,true)
	await frames(3)
	key(KEY_F,false)
	check(body.get_controller().get_spin_sprint().is_active(),"Spin is driven by the actual combat burst")
	await record("spin",20)
	measuring_spin = false
	key(KEY_D,false)
	check(spin_travel > TAU*1.5,"Rendered skeleton turns through the barrel roll: "+str(spin_travel))
	check(effects.bubble_bursts >= 3,"Spinning emits trailing bubbles")
	check(body.get_visual_motion().wetness > 0.95,"Swimming wets the authored skin")
	place(Vector3(0,top+3,centre.z))
	await frames(4)
	check(body.get_animator().get_current_action() != HeroAnimator.SPIN,"Spin does not remain stuck after leaving water")
	print("HERO REVIEW: %d checks, %d failures" % [checks,failures.size()])
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
