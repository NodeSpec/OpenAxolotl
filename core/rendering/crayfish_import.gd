@tool
extends EditorScenePostImport
## The GLB contains COLOR_0; explicitly retain it on every shell surface.
func _post_import(scene: Node) -> Object:
	for mesh: MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		for surface: int in mesh.mesh.get_surface_count():
			var material:=mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if material!=null:
				material.vertex_color_use_as_albedo=true
				if material.resource_name=="CrayfishShell":
					var shell:=ShaderMaterial.new();shell.shader=load("res://core/rendering/crayfish_shell.gdshader") as Shader
					mesh.mesh.surface_set_material(surface,shell)
	return scene
