extends SceneTree
func _initialize() -> void:
	var scene := load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D
	var profile := preload("res://core/controller/channel_profile.gd").new()
	profile.source_path="res://worlds/coral_cove/channel_profile.json"
	var maximum := 0.0
	var point := Vector3.ZERO
	for volume: WaterVolume in scene.find_children("*","WaterVolume",true,false):
		for visual: MeshInstance3D in volume.find_children("*","MeshInstance3D",true,false):
			if not visual.mesh is ArrayMesh:
				continue
			var arrays := visual.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var ids: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in range(0,ids.size(),3):
				var center := volume.transform*visual.transform*((verts[ids[i]]+verts[ids[i+1]]+verts[ids[i+2]])/3.0)
				var deviation := absf(center.y-float(profile.sample(center)["surface"]))
				if deviation>maximum:
					maximum=deviation
					point=center
	print("MAX WATER MESH DEVIATION ",maximum," at ",point)
	scene.free()
	quit()
