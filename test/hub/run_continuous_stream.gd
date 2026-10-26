extends SceneTree

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var stream: LagoonStream
var checks: int = 0
var failures: PackedStringArray = []
var entries: int = 0
var capture_enabled: bool = false
var captured: Dictionary = {}

func _initialize() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
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

func capture(label: String) -> void:
	if not capture_enabled or captured.has(label):
		return
	captured[label] = true
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	print("VIEW ",label," player=",body.global_position," camera=",body.get_camera().global_position," pitch=",body.get_camera().get_rig().get_pitch_deg())
	check(picture.save_png("res://review/stream_%s.png" % label) == OK,"Saved "+label)
	var samples: Dictionary = {}
	for y: int in range(80,picture.get_height()-80,30):
		for x: int in range(80,picture.get_width()-80,30):
			samples[picture.get_pixel(x,y).to_html()] = true
	check(samples.size() > 80,"Rendered scene is nonblank: "+label)

func run() -> void:
	root.size = Vector2i(1280,720)
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	stream = hub.get_node("DownstreamPassage") as LagoonStream
	var faces: PackedVector3Array = (stream.get_node("ContinuousWater") as MeshInstance3D).mesh.get_faces()
	var faces_up: bool = true
	for i: int in range(0,faces.size(),3):
		# Godot treats clockwise triangle winding as the front face.
		faces_up = faces_up and (faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]).normalized().y < -0.9
	check(faces_up,"Water faces upward for front-face refraction along the entire channel")
	hub.get_hud().visible = false
	check(hub._stream_world != null,"First level geometry exists before approaching the tunnel")
	if hub._stream_world == null:
		quit(1)
		return
	var portal_root := hub.get_node("Portals")
	var left := portal_root.get_child(0) as Node3D
	check(left.name=="Portal_coral_cove" and is_equal_approx(left.position.x,-6.0),"Living Cascade is the leftmost tunnel")
	check(is_equal_approx(stream.position.x,left.position.x),"Physical stream starts at the leftmost entrance")
	check(is_equal_approx((hub.get_node("Hydrology") as LagoonHydrology).continuous_stream_x,left.position.x),"Receiving floor cut follows the moved passage")
	var world_id: int = hub._stream_world.get_instance_id()
	var player_id: int = body.get_instance_id()
	var camera_id: int = body.get_camera().get_instance_id()
	var entry := hub._stream_world.get_node("StreamEntry") as Node3D
	check(entry.global_position.distance_to(stream.to_global(LagoonStreamPath.exit_position())) < 0.01,"Destination water is physically aligned with the outlet")
	var holder := stage.get_node("WorldLighting/WorldEnvironment") as WorldEnvironment
	var daylight: Environment = holder.environment
	hub.world_entered.connect(func(_id: String) -> void: entries += 1)
	check(not hub.is_in_world(),"Preloading does not start level gameplay or save progress")
	check(LagoonStreamPath.enclosure(-27) > 0.95 and LagoonStreamPath.enclosure(-9) == 0,"Cave darkness is spatially bounded")
	check(stream.flow_at(Vector3(0,0,0)).is_zero_approx(),"Lagoon center is not pulled into the current")
	check(LagoonStreamPath.at_z(-29).x > 4,"Passage has a real bend")
	await frames(60)
	await capture("lagoon")
	hub._move_player_to(Vector3(stream.position.x,1,-3.5))
	body.get_input_system().clear()
	body.get_camera().set_yaw_deg(0)
	await frames(60)
	key(KEY_W,true)
	for i: int in 240:
		await physics_frame
		if body.position.z < -9.2:
			break
	key(KEY_W,false)
	check(body.position.z < -9.2,"Swimmer enters through the leftmost arch")
	check(not hub.is_in_world(),"Old mouth trigger does not teleport or activate the level")
	var previous: Vector3 = body.position
	var largest_step: float = 0.0
	var deepest: float = body.position.y
	var max_lateral: float = 0.0
	var was_active: bool = false
	var activation_speed: float = 0.0
	var camera_step: float = 0.0
	var previous_camera: Vector3 = body.get_camera().global_position
	for i: int in 1800:
		await physics_frame
		largest_step = maxf(largest_step,body.position.distance_to(previous))
		camera_step = maxf(camera_step,body.get_camera().global_position.distance_to(previous_camera))
		previous = body.position
		previous_camera = body.get_camera().global_position
		deepest = minf(deepest,body.position.y)
		if body.position.z > -50:
			max_lateral = maxf(max_lateral,absf(stream.to_local(body.global_position).x-LagoonStreamPath.at_z(stream.to_local(body.global_position).z).x))
		if hub.is_in_world() and not was_active:
			activation_speed = body.velocity.length()
			was_active = true
		if i%240 == 0:
			print("STREAM tick=",i," position=",body.position," current=",stream.flow_at(body.position)," swimming=",body.is_in_water())
		if i == 240:
			check(stage.find_children("MotionRipple","",true,false).is_empty(),"Passive current drift does not emit full swimming wakes")
		for milestone: Dictionary in [{"z":-15.0,"name":"entrance"},{"z":-26.0,"name":"moss_bend"},{"z":-39.0,"name":"downstream"},{"z":-48.0,"name":"outlet"}]:
			if body.position.z < float(milestone["z"]):
				await capture(String(milestone["name"]))
		if body.position.z < -52.2:
			break
	check(body.position.z < -52.2,"Current alone carries the player into the first level: "+str(body.position))
	check(deepest < -6.5,"The channel descends into the level")
	check(max_lateral < 1.8,"Current guides a passive swimmer around the bend")
	check(largest_step < 0.7,"No teleport or discontinuous player displacement: "+str(largest_step))
	check(camera_step < 0.9,"Camera remains continuous through world activation: "+str(camera_step))
	check(entries == 1 and hub.is_continuous_world(),"Level activates exactly once at the far end")
	check(activation_speed > 0.5,"World activation preserves movement")
	check(hub._active_world.get_instance_id() == world_id if hub._active_world != null else false,"The preloaded scene becomes the active scene without replacement")
	check(body.get_instance_id() == player_id and body.get_camera().get_instance_id() == camera_id,"Player and camera are never replaced")
	check(hub.visible and hub.can_process(),"The lagoon and passage remain connected and solid")
	check(holder.environment == daylight,"There is no sky or sunlight cut at world activation")
	await frames(30)
	await capture("first_level")
	check(body.get_water_volume() != null,"Arrival retains water contact")
	if not capture_enabled:
		body.get_camera().set_yaw_deg(0)
		key(KEY_W,true)
		await frames(90)
		key(KEY_W,false)
		check(body.global_position.z < -57.0,"Player can steer out of the outlet into level water")
		check(stream.flow_at(body.global_position).is_zero_approx(),"Tunnel current ends inside the receiving waterway")
		check(body.get_water_volume() != stream and body.is_in_water(),"Receiving level owns water contact after leaving the passage")
		var pilot := RoutePilot.new(CoralRoute.waypoints(),hub._active_world.global_position)
		for frame: int in 18000:
			await physics_frame
			if not hub.is_in_world():
				break
			pilot.step(body)
			if not pilot.stuck_reason().is_empty():
				break
		pilot.release_all()
		check(not hub.is_in_world(),"Left-tunnel arrival continues through the full Living Cascade to its actual finish: "+pilot.stuck_reason())
		await frames(10)
		check(not hub.is_in_world() and hub._stream_world != null,"Completion resets and prepares a fresh connected world")
		check(hub.enter_world("bubble_bay"),"Side tunnel world remains usable")
		await frames(5)
		check(not hub.visible and not stream.can_process(),"Side-world entry disables the connected lagoon")
		hub.notify_finish_condition_met()
		await frames(10)
		check(hub.visible and stream.can_process(),"Returning restores the continuous route")
		hub._prepare_stream_world([])
		check(hub._stream_world == null and not stream.visible and not stream.can_process(),"Removing the connected module closes the connected passage")
		hub.refresh()
		await frames(5)
		check(hub._stream_world != null and stream.visible and stream.can_process(),"Registry refresh restores an available connected module")
	print("CONTINUOUS STREAM: %d checks, %d failures" % [checks,failures.size()])
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
