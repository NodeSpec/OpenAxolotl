extends RefCounted
## Authored in the hero's rest frame; reuse its skeleton instead of running a
## second rig. The pack is rigid on the spine; harness weights follow the torso.
const PACK := preload("res://assets/character/explorer_backpack/explorer_backpack.glb")

static func attach(model: Node3D) -> Node3D:
	if model.has_node("ExplorerGear"):
		return model.get_node("ExplorerGear") as Node3D
	var rigs := model.find_children("*", "Skeleton3D", true, false)
	if rigs.is_empty():
		return null
	var skeleton := rigs[0] as Skeleton3D
	if skeleton.find_bone("spine") < 0 or skeleton.find_bone("root") < 0:
		return null
	var source := PACK.instantiate() as Node3D
	var source_rig := source.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var gear := Node3D.new()
	gear.name = "ExplorerGear"
	model.add_child(gear)
	for node: Node in source.find_children("*", "MeshInstance3D", true, false):
		var visual := node as MeshInstance3D
		var rest := visual.transform
		var ancestor := visual.get_parent()
		while ancestor != source and ancestor is Node3D:
			rest = (ancestor as Node3D).transform * rest
			ancestor = ancestor.get_parent()
		var skin := visual.skin.duplicate() as Skin
		for bind: int in skin.get_bind_count():
			if skin.get_bind_name(bind).is_empty():
				skin.set_bind_name(bind, source_rig.get_bone_name(skin.get_bind_bone(bind)))
		visual.owner = null
		visual.get_parent().remove_child(visual)
		gear.add_child(visual)
		visual.transform = source.transform * rest
		visual.skin = skin
		visual.skeleton = visual.get_path_to(skeleton)
		# Fine canvas and leather keep their detail at grazing camera angles.
		for surface: int in visual.mesh.get_surface_count():
			var material := visual.get_active_material(surface) as BaseMaterial3D
			if material != null:
				var fitted := material.duplicate() as BaseMaterial3D
				fitted.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if material.resource_name == "Canvas_olive":
					fitted.albedo_color = Color(0.70,0.68,0.57)
				elif material.resource_name == "Leather_saddle":
					fitted.albedo_color = Color(0.74,0.60,0.48)
				visual.set_surface_override_material(surface, fitted)
	source.free()
	return gear
