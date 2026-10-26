extends SceneTree

var stage: Node3D
var camera: Camera3D
var measurements: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for frame: int in count:
		await process_frame

func capture(label: String) -> void:
	await frames(35)
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	var error: Error = rendered.save_png("res://review/lagoon_imported_%s.png" % label)
	if error != OK:
		push_error("Could not save "+label)
		quit(1)
	print("IMPORTED CAPTURE ",label," size=",rendered.get_size()," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

func run() -> void:
	root.size = Vector2i(1440,900)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	var follow := stage.get_node("Camera") as Camera3D
	follow.set_physics_process(false)
	var hub := stage.get_node("OpenLagoon") as OpenLagoon
	hub.get_hud().visible = false
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.make_current()
	camera.fov = 65
	camera.position = Vector3(0,3.6,9.7)
	camera.look_at(Vector3(0,2.2,-8))
	await capture("hero")
	var dressing := hub.get_node("LagoonArt/ImportedModels") as Node3D
	await measure("hero_with_assets")
	dressing.visible = false
	await measure("hero_assets_hidden")
	dressing.visible = true
	camera.fov = 58
	camera.position = Vector3(-3.0,3.0,11.4)
	camera.look_at(Vector3(-8.0,0.65,6.8))
	await capture("west_garden")
	camera.position = Vector3(3.0,2.8,10.8)
	camera.look_at(Vector3(8.4,0.65,5.8))
	await capture("east_garden")
	camera.position = Vector3(-2.0,2.8,-0.2)
	camera.look_at(Vector3(0.0,0.8,-8.2))
	await capture("tunnels")
	follow.set_physics_process(true)
	follow.make_current()
	hub.get_hud().visible = true
	await capture("gameplay")
	await measure("gameplay_with_assets")
	dressing.visible = false
	await measure("gameplay_assets_hidden")
	dressing.visible = true
	var report := FileAccess.open("res://review/lagoon_imported_gpu.json",FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"gpu_only_ms":measurements},"\t"))
		report.close()
	stage.queue_free()
	await process_frame
	quit()

func measure(label: String) -> void:
	await frames(45)
	var samples: Array[float] = []
	for frame: int in 60:
		await RenderingServer.frame_post_draw
		samples.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	samples.sort()
	var total: float = 0.0
	for value: float in samples:
		total += value
	measurements[label] = {"mean":total/samples.size(),"p95":samples[56],"samples":samples.size()}
	print("IMPORTED GPU ",label," ",measurements[label])
