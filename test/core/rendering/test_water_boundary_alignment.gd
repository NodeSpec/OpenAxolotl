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

		for node: Node in volumes:
			var volume := node as WaterVolume
			var meshes := volume.find_children("*", "MeshInstance3D", true, false)
			var colliders := volume.find_children("*", "CollisionShape3D", true, false)
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
