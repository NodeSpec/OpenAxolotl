extends SceneTree

var checks: int = 0
var failures: PackedStringArray = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ",message)

func run() -> void:
	var stage := load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var hub := stage.get_node("OpenLagoon") as OpenLagoon
	var dressing := hub.get_node("LagoonArt/ImportedModels") as Node3D
	var hydrology := hub.get_node("Hydrology") as LagoonHydrology
	check(dressing.get_child_count() == 25,"All 25 authored prop instances load")
	check(dressing.find_children("*","StaticBody3D",true,false).size() == 17,"Nine boulders and eight coral bases have collision")
	var meshes: Dictionary = {}
	for child: Node in dressing.get_children():
		var prop := child as Node3D
		var visuals := prop.find_children("*","MeshInstance3D",true,false)
		check(not visuals.is_empty(),"Mesh present: "+prop.name)
		var bounds := AABB()
		var first: bool = true
		for node: Node in visuals:
			var visual := node as MeshInstance3D
			var box: AABB = visual.global_transform*visual.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			if not meshes.has(visual.mesh):
				meshes[visual.mesh] = true
				var local_bounds: AABB = (prop.global_transform.affine_inverse()*visual.global_transform)*visual.get_aabb()
				check(absf(local_bounds.position.y) < 0.01,"Imported root pivot is at the ground")
				for surface: int in visual.mesh.get_surface_count():
					var arrays: Array = visual.mesh.surface_get_arrays(surface)
					check(arrays[Mesh.ARRAY_INDEX].size()/3 <= 65000,"Game mesh respects triangle budget")
					var mat := visual.get_active_material(surface) as BaseMaterial3D
					check(mat != null,"Imported PBR material exists")
					if mat != null:
						check(mat.albedo_texture != null,"Original color map retained")
						check(mat.normal_enabled and mat.normal_texture != null,"Normal detail retained")
						check(mat.roughness_texture != null,"Roughness map retained")
						check(mat.albedo_texture.get_width() <= 2048,"Texture memory budget respected")
		var floor_y: float = hydrology.floor_height(Vector2(prop.position.x,prop.position.z))
		check(bounds.position.y <= floor_y+0.06 and bounds.position.y >= floor_y-0.40,"Grounded base: "+prop.name)
		var expanded: AABB = bounds.grow(0.5)
		check(not _covers_xz(expanded,Vector2(0,6)),"Spawn is clear: "+prop.name)
		for z: float in [1.0,0.0,-1.0,-2.0]:
			check(not _covers_xz(expanded,Vector2(-8.3,z)),"Shallow running route is clear: "+prop.name)
		for center: float in hydrology.tunnel_centers:
			for z: float in [-4.0,-6.0,-8.0,-10.0]:
				check(not _covers_xz(expanded,Vector2(center,z)),"Tunnel swim corridor is clear: "+prop.name)
	check(meshes.size() == 3,"Repeated instances share exactly three source meshes")
	check(hub.enter_world("coral_cove"),"Existing level still loads")
	await process_frame
	check(not dressing.is_visible_in_tree(),"Imported models hide outside lagoon")
	hub.notify_finish_condition_met()
	await process_frame
	await process_frame
	check(dressing.is_visible_in_tree(),"Imported models return with lagoon")
	stage.queue_free()
	await process_frame
	print("IMPORTED DRESSING: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _covers_xz(box: AABB, point: Vector2) -> bool:
	return point.x >= box.position.x and point.x <= box.end.x and point.y >= box.position.z and point.y <= box.end.z
