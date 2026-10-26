extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene=stage
	var lighting := load("res://core/rendering/world_lighting.tscn").instantiate() as WorldLighting
	stage.add_child(lighting)
	lighting.set_quality(RenderQuality.Level.MEDIUM)
	var world := load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D
	stage.add_child(world)
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	body.name="Axolotl"
	stage.add_child(body)
	var camera := CameraFollow.new()
	camera.target_path=NodePath("../Axolotl")
	camera.current=true
	stage.add_child(camera)
	var systems := WorldSystems.new()
	systems.world_id="coral_cove"
	systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json")) as Dictionary
	world.add_child(systems)
	await physics_frame
	for row: Array in [["arrival",Vector3(3,1.2,-8),0.0],["garden",Vector3(-22,1.2,-25),0.0],["root_exit",Vector3(13,1.6,-56),-30.0],["crown",Vector3(24,7.6,-94),0.0],["crown_restored",Vector3(24,7.6,-96),0.0],["finish",Vector3(-36,1.8,-106),130.0]]:
		if String(row[0])=="crown_restored":
			systems.get_restoration().deliver_resources("coral_shelf",7)
		body.clear_water_contacts()
		body.global_position=row[1] as Vector3
		body.velocity=Vector3.ZERO
		body.get_controller().set_velocity(Vector3.ZERO)
		camera.set_yaw_deg(float(row[2]))
		camera.get_rig().request_resettle()
		for i in range(100):
			await physics_frame
		await RenderingServer.frame_post_draw
		var label := String(row[0])
		root.get_texture().get_image().save_png("res://review/cascade_%s.png" % label)
		print("CAPTURE ",label," body=",body.global_position," camera=",camera.global_position)
	var overview := Camera3D.new()
	stage.add_child(overview)
	overview.global_position=Vector3(66,87,15)
	overview.look_at(Vector3(0,0,-57))
	overview.fov=64
	overview.environment=lighting.get_world_environment().environment.duplicate() as Environment
	overview.environment.fog_enabled=false
	overview.current=true
	for i in range(25):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://review/cascade_overview.png")
	print("CAPTURE COMPLETE ",RenderingServer.get_video_adapter_name())
	quit()
