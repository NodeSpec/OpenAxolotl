extends GdUnitTestSuite

## The visible water boundary and the movement-grammar boundary must be the
## same place. WaterVolume changes the player's physics grammar; its child mesh
## tells the player where that change will happen. If those drift apart, the
## axolotl can start swimming in air or keep waddling below a visible surface,
## which feels like broken physics even though both systems work independently.

const WATERED_SCENES: Array[String] = [
	"res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn",
]
const EPSILON := 0.001


func test_visible_water_matches_every_official_water_volume() -> void:
	for scene_path: String in WATERED_SCENES:
		var scene := (load(scene_path) as PackedScene).instantiate()
		var volumes := scene.find_children("*", "WaterVolume", true, false)
		assert_int(volumes.size()).override_failure_message(
			"%s must declare at least one WaterVolume" % scene_path
		).is_greater_equal(1)

		var checked_shared: Dictionary = {}
		for node: Node in volumes:
			var volume := node as WaterVolume
			var meshes := volume.find_children("*", "MeshInstance3D", true, false)
			var colliders := volume.find_children("*", "CollisionShape3D", true, false)
			if volume.has_meta("shared_water_surface"):
				var shared := volume.get_node_or_null(volume.get_meta("shared_water_surface") as NodePath) as MeshInstance3D
				assert_object(shared).is_not_null()
				if shared!=null:
					meshes.append(shared)
			assert_int(meshes.size()).override_failure_message(
				"%s/%s has physics water but no visible water mesh"
				% [scene_path, volume.name]).is_greater_equal(1)
			assert_int(colliders.size()).override_failure_message(
				"%s/%s has visible water but no grammar-transition collider"
				% [scene_path, volume.name]).is_greater_equal(1)
			if meshes.is_empty() or colliders.is_empty():
				continue

			var mesh_node := meshes[0] as MeshInstance3D
			var collider := colliders[0] as CollisionShape3D
			assert_bool(mesh_node.visible).is_true()
			if mesh_node.mesh is ArrayMesh:
				if volume.has_meta("shared_water_surface"):
					_check_shared_coverage(volume,mesh_node)
					if checked_shared.has(mesh_node): continue
					checked_shared[mesh_node]=true
				_check_channel_mesh(volume,mesh_node)
				continue
			if mesh_node.mesh is PlaneMesh:
				_check_plane(volume,mesh_node,collider)
				continue
			var box_mesh := mesh_node.mesh as BoxMesh
			var box_shape := collider.shape as BoxShape3D
			assert_bool(box_mesh != null).override_failure_message(
				"%s/%s water visual must expose box bounds for alignment testing"
				% [scene_path, volume.name]).is_true()
			assert_bool(box_shape != null).override_failure_message(
				"%s/%s water collision must expose box bounds for alignment testing"
				% [scene_path, volume.name]).is_true()
			if box_mesh == null or box_shape == null:
				continue

			assert_bool(box_mesh.size.is_equal_approx(box_shape.size)
				).override_failure_message(
				("%s/%s visible water size %s differs from grammar volume %s; "
				+ "the player will change movement before or after the surface says so")
				% [scene_path, volume.name, str(box_mesh.size), str(box_shape.size)]
				).is_true()
			assert_bool(mesh_node.position.distance_to(collider.position) <= EPSILON
				).override_failure_message(
				("%s/%s visible water is offset from its grammar collider by %.3fm")
				% [scene_path, volume.name,
					mesh_node.position.distance_to(collider.position)]).is_true()

		scene.free()

func _check_plane(volume: WaterVolume, visual: MeshInstance3D, collider: CollisionShape3D) -> void:
	var plane := visual.mesh as PlaneMesh
	var box := collider.shape as BoxShape3D
	assert_object(box).is_not_null()
	var sample_profile: bool = volume.get_script().resource_path.ends_with("channel_water_volume.gd")
	var profile := preload("res://core/controller/channel_profile.gd").new()
	if sample_profile:
		profile.source_path=String(volume.get("profile_path"))
	for row: Vector2 in [Vector2.ZERO, Vector2(0.35,0), Vector2(-0.35,0), Vector2(0,0.35), Vector2(0,-0.35)]:
		var local_point := visual.transform*Vector3(row.x*plane.size.x,0,row.y*plane.size.y)
		var expected := volume.surface_height+volume.surface_gradient.dot(Vector2(local_point.x,local_point.z))
		if sample_profile:
			expected=float(profile.sample(volume.transform*local_point)["surface"])-volume.position.y
		assert_float(absf(local_point.y-expected)).override_failure_message("%s water visual differs from sampled swimming surface" % volume.name).is_less_equal(0.12)
		var in_shape := collider.transform.affine_inverse()*local_point
		assert_bool(absf(in_shape.x)<=box.size.x*0.5+0.01 and absf(in_shape.z)<=box.size.z*0.5+0.01).is_true()
		assert_bool(in_shape.y<=box.size.y*0.5+0.01 and in_shape.y>=-box.size.y*0.5).is_true()

func _check_channel_mesh(volume: WaterVolume,visual: MeshInstance3D) -> void:
	assert_bool(volume.get_script().resource_path.ends_with("channel_water_volume.gd")).is_true()
	var profile := preload("res://core/controller/channel_profile.gd").new()
	profile.source_path=String(volume.get("profile_path"))
	var arrays := visual.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	assert_int(vertices.size()).is_greater(4)
	var relative := _scene_pose(volume.get_parent() as Node3D).affine_inverse()*_scene_pose(visual)
	for vertex: Vector3 in vertices:
		var point := relative*vertex
		assert_float(absf(point.y-float(profile.sample(point)["surface"]))).is_less_equal(0.001)
	for i in range(0,indices.size(),3):
		var center := (vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3.0
		var point := relative*center
		assert_float(absf(point.y-float(profile.sample(point)["surface"]))).override_failure_message("%s surface triangle deviates from the shared swimming field" % volume.name).is_less_equal(0.12)

func _scene_pose(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent is Node3D:
		result=(parent as Node3D).transform*result
		parent=parent.get_parent()
	return result

func _check_shared_coverage(volume: WaterVolume,visual: MeshInstance3D) -> void:
	assert_bool(volume.get_script().resource_path.ends_with("channel_water_volume.gd")).is_true()
	var profile := preload("res://core/controller/channel_profile.gd").new()
	profile.source_path=String(volume.get("profile_path"))
	var relative := _scene_pose(volume.get_parent() as Node3D).affine_inverse()*_scene_pose(visual)
	var arrays := visual.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var center := Vector2(volume.position.x,volume.position.z)
	var covered := false
	for i in range(0,indices.size(),3):
		var a := relative*vertices[indices[i]]
		var b := relative*vertices[indices[i+1]]
		var c := relative*vertices[indices[i+2]]
		var v0 := Vector2(b.x-a.x,b.z-a.z)
		var v1 := Vector2(c.x-a.x,c.z-a.z)
		var v2 := center-Vector2(a.x,a.z)
		var denominator := v0.cross(v1)
		if absf(denominator)<0.000001: continue
		var u := v2.cross(v1)/denominator
		var v := v0.cross(v2)/denominator
		if u>=-0.001 and v>=-0.001 and u+v<=1.001:
			var height := a.y+u*(b.y-a.y)+v*(c.y-a.y)
			assert_float(absf(height-float(profile.sample(volume.position)["surface"]))).is_less_equal(0.12)
			covered=true
			break
	assert_bool(covered).override_failure_message("%s shared water does not cover its channel center" % volume.name).is_true()
