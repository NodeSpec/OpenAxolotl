extends SceneTree

const MODELS: Array[String] = ["boulder_cluster", "coral_rock", "flower_cluster"]
var stage: Node3D

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var arch_only: bool = OS.get_cmdline_user_args().has("--arch")
	var models: Array[String] = []
	models.assign(["waterfall_arch"] if arch_only else MODELS)
	root.size = Vector2i(1440,900)
	stage = Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var holder := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8aafb8")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dae5f3")
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	holder.environment = environment
	stage.add_child(holder)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-35,0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	stage.add_child(sun)
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(20,20)
	plane.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("a3b6b2")
	material.roughness = 0.9
	plane.material_override = material
	plane.position.y = -0.02
	stage.add_child(plane)
	var camera := Camera3D.new()
	camera.position = Vector3(3.8,3.4,7.2)
	stage.add_child(camera)
	camera.look_at(Vector3(0,0.65,0))
	camera.fov = 47
	if arch_only:
		camera.position = Vector3(2.5,2.4,3.4)
		camera.look_at(Vector3(0,0.55,0))
	for index: int in models.size():
		var asset := load("res://assets/environment/lagoon_meshy/%s.glb" % models[index]) as PackedScene
		var model := asset.instantiate() as Node3D
		model.position.x = (index-(models.size()-1)*0.5)*2.65
		stage.add_child(model)
		for node: Node in model.find_children("*","MeshInstance3D",true,false):
			var visual := node as MeshInstance3D
			print("MODEL ",models[index]," bounds=",visual.get_aabb()," surfaces=",visual.mesh.get_surface_count())
			for surface: int in visual.mesh.get_surface_count():
				var mat := visual.get_active_material(surface) as BaseMaterial3D
				print("MATERIAL base=",mat.albedo_texture.get_size() if mat.albedo_texture else Vector2.ZERO," normal=",mat.normal_enabled," roughness_map=",mat.roughness_texture != null)
	for frame: int in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://review/lagoon_arch_catalog.png" if arch_only else "res://review/lagoon_asset_catalog.png")
	print("ASSET CATALOG saved=",result == OK)
	stage.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
