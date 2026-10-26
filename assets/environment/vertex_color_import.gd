@tool
extends EditorScenePostImport
## Preserve the existing kit's vertex palette after a fresh Godot import.
func _post_import(scene: Node) -> Object:
	for node: MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		for index in range(node.mesh.get_surface_count()):
			var colors: Variant = node.mesh.surface_get_arrays(index)[Mesh.ARRAY_COLOR]
			if colors == null or (colors as PackedColorArray).is_empty():
				continue
			var material := node.mesh.surface_get_material(index) as BaseMaterial3D
			material=material.duplicate() as BaseMaterial3D if material != null else StandardMaterial3D.new()
			material.vertex_color_use_as_albedo=true
			(node.mesh as ArrayMesh).surface_set_material(index,material)
	return scene
