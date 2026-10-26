extends RefCounted
## Surface refinement for the six Coralvine Arch tunnel instances only.
static var shared_materials: Dictionary = {}

static func apply(model: Node3D) -> void:
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if original==null: continue
			if not shared_materials.has(original):
				var mat := ShaderMaterial.new()
				mat.resource_name="Cascade tunnel / blue mineral, algae and preserved coral"
				mat.shader=load("res://core/rendering/cascade_tunnel.gdshader")
				mat.set_shader_parameter("atlas_color",original.albedo_texture)
				mat.set_shader_parameter("atlas_normal",original.normal_texture)
				mat.set_shader_parameter("atlas_roughness",original.roughness_texture)
				var root := "res://assets/environment/cascade_surfaces/rock_face_03"
				mat.set_shader_parameter("stone_color",load(root+"_diff_2k.jpg"))
				mat.set_shader_parameter("stone_normal",load(root+"_nor_gl_2k.png"))
				mat.set_shader_parameter("stone_arm",load(root+"_arm_2k.png"))
				mat.set_shader_parameter("moss_color",load("res://assets/environment/cascade_surfaces/mossy_rock_diff_2k.jpg"))
				mat.set_shader_parameter("grain_color",load("res://assets/environment/cascade_surfaces/dry_river_pebbles_diff_2k.jpg"))
				mat.set_shader_parameter("grain_normal",load("res://assets/environment/cascade_surfaces/dry_river_pebbles_nor_gl_2k.png"))
				shared_materials[original]=mat
			mesh.set_surface_override_material(surface,shared_materials[original])
		mesh.set_meta("cascade_tunnel_surface",true)
