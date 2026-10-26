extends SceneTree

var frame: int = 0
var stage: Node3D
var camera: Camera3D
var output_dir: String
var views: Array[Vector3] = [Vector3(0,3.6,9.7),Vector3(-9,5,8),Vector3(5,3,-1)]
var targets: Array[Vector3] = [Vector3(0,2.2,-8),Vector3(0,2,-7),Vector3(1,2,-8)]

func _initialize() -> void:
	root.size = Vector2i(1600,900)
	output_dir = ProjectSettings.globalize_path("res://review")
	DirAccess.make_dir_recursive_absolute(output_dir)
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	setup.call_deferred()

func setup() -> void:
	var follow := stage.get_node("Camera") as Camera3D
	follow.set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 65.0
	stage.add_child(camera)
	camera.make_current()
	camera.position = views[0]
	camera.look_at(targets[0])
	var player := stage.get_node("Axolotl") as Node3D
	player.visible = false
	var hud := stage.find_child("PlayerHud",true,false) as CanvasLayer
	if hud != null:
		hud.visible = false

func _process(_delta: float) -> bool:
	frame += 1
	if camera == null:
		return false
	if frame in [100,160,220,280]:
		capture((frame-100)/60)
	return false

func capture(index: int) -> void:
	await RenderingServer.frame_post_draw
	var captured: Image = root.get_texture().get_image()
	var save_result: Error = captured.save_png(output_dir.path_join("lagoon_%d.png" % index))
	if save_result != OK:
		push_error("Capture failed: %s" % error_string(save_result))
		quit(1)
		return
	print("CAPTURE ",index," nodes=",get_node_count()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if index == 3:
		quit(0)
	elif index == 2:
		var follow := stage.get_node("Camera") as Camera3D
		follow.set_physics_process(true)
		follow.make_current()
		(stage.get_node("Axolotl") as Node3D).visible = true
		var hud := stage.find_child("PlayerHud",true,false) as CanvasLayer
		if hud != null:
			hud.visible = true
	else:
		camera.position = views[index+1]
		camera.look_at(targets[index+1])
