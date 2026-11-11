extends SceneTree

## Close-up frames of the hero's feet: standing, walking, scurrying, stopping
## and swimming.
##
##     godot --path . --audio-driver Dummy --fixed-fps 60 \
##           --script tools/hero_feet_review.gd
##
## tools/hero_review.gd films the whole animal from across the beach, which is
## the right distance for posture and the wrong one for feet: at that range a
## planted foot and a skating one are the same four pixels. This puts a low
## camera a body-length away and follows the animal, so consecutive frames
## show whether a foot on the ground STAYS where it was while the body moves
## past it. It is the picture that goes with tools/hero_gait_probe.gd's number.
##
## Writes res://review/feet_<label>_NN.png. Needs a renderer (it reads the
## viewport back), so run it under a display or xvfb rather than --headless.
## It asserts nothing: REQ-002 AC-10 is a person's approval, and this is what
## they look at.

const CAMERA_OFFSET := Vector3(0.9, -0.36, 2.0)
const CAMERA_TARGET := Vector3(0.1, -0.66, 0.0)

## Swimming, the model rides at the capsule's centre instead of on its floor.
const SWIM_CAMERA_OFFSET := Vector3(0.9, 0.25, 2.2)
const SWIM_CAMERA_TARGET := Vector3(0.1, -0.15, 0.0)

## Open water in the hub deep enough to swim in, a little under the surface.
## Treading water here frames well. Swimming from here does not: the animal
## heads for a bank that ends up between it and the camera, so the swim frames
## show the hind limbs and hide the front ones. A better lane is worth finding.
const SWIM_SPOT := Vector3(0.0, -1.3, -1.5)

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var camera: Camera3D
var swimming := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	run.call_deferred()


func _process(_delta: float) -> bool:
	_follow()
	return false


func _follow() -> void:
	if is_instance_valid(camera) and is_instance_valid(body):
		camera.global_position = body.global_position + (SWIM_CAMERA_OFFSET if swimming else CAMERA_OFFSET)
		camera.look_at(body.global_position + (SWIM_CAMERA_TARGET if swimming else CAMERA_TARGET))


func frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func stick(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)


## `count` frames, `every` physics frames apart.
##
## Only the frames that are kept get drawn. The game keeps simulating in
## between, so the motion is the same; a software renderer just does not spend
## ten seconds a frame on two hundred frames nobody will see.
func record(label: String, count: int, every: int) -> void:
	for frame: int in count:
		await frames(every)
		_follow()
		RenderingServer.render_loop_enabled = true
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://review/feet_%s_%02d.png" % [label, frame])
		RenderingServer.render_loop_enabled = false
	print("FEET CAPTURE ", label, " clip=", body.get_animator().get_current_clip(),
		" speed=", snappedf(Vector2(body.velocity.x, body.velocity.z).length(), 0.01))


func run() -> void:
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	body.get_camera().set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 34
	stage.add_child(camera)
	camera.make_current()
	hub.get_hud().visible = false
	RenderingServer.render_loop_enabled = false
	body.get_input_system().clear()
	hub._move_player_to(Vector3(-3, 1.1, 9))
	body.get_camera().set_yaw_deg(0.0)
	await frames(40)
	# A tap of the stick so the animal is side-on to the camera, then long
	# enough standing for its feet to have settled.
	stick(1.0)
	await frames(14)
	stick(0.0)
	await frames(70)
	# The first frames a renderer draws can arrive before its lighting has
	# settled; spend three on that so the first kept frame is not one of them.
	RenderingServer.render_loop_enabled = true
	for warm: int in 3:
		await RenderingServer.frame_post_draw
	RenderingServer.render_loop_enabled = false
	await record("stand", 1, 1)

	stick(0.35)
	await frames(40)
	await record("walk", 8, 3)

	stick(1.0)
	await frames(40)
	await record("scurry", 8, 2)

	stick(0.0)
	await frames(6)
	await record("stop", 3, 8)

	swimming = true
	hub._move_player_to(SWIM_SPOT)
	await frames(50)
	if body.is_in_water():
		await record("tread", 2, 14)
		stick(1.0)
		await frames(24)
		await record("swim", 3, 5)
		stick(0.0)
	else:
		print("FEET CAPTURE swim skipped: no water at ", SWIM_SPOT)

	stage.queue_free()
	await process_frame
	quit(0)
