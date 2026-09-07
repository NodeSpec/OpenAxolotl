extends GdUnitTestSuite

## The world dressing (REQ-034): the shared environment kit and the rule
## that keeps it safe — decoration is VISUAL ONLY. A prop that collided
## would invalidate every tuned probe and walk; a prop that grouped would
## become a contract element by accident. So the structure held here is:
## every dressed scene carries kit instances under a Dressing container,
## and that container's whole subtree has no physics and no groups.

const KIT_PROPS: Array[String] = [
	"rock_cluster", "coral_branch", "kelp_strand", "seagrass_tuft",
]
const DRESSED_SCENES: Array[String] = [
	"res://hub/open_lagoon.tscn",
	"res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn",
]
const WATERED_SCENES: Array[String] = [
	"res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn",
]


func test_every_kit_prop_loads_with_meshes_and_vertex_colour_albedo() -> void:
	for prop: String in KIT_PROPS:
		var path := "res://assets/environment/%s/%s.glb" % [prop, prop]
		var packed: PackedScene = load(path)
		assert_object(packed).override_failure_message(
			"%s failed to load" % path).is_not_null()
		var root := packed.instantiate()
		var meshes := root.find_children("*", "MeshInstance3D", true, false)
		assert_int(meshes.size()).is_greater_equal(1)
		for node: Node in meshes:
			var material := (node as MeshInstance3D).mesh.surface_get_material(0)
			assert_bool(material is BaseMaterial3D
				and (material as BaseMaterial3D).vertex_color_use_as_albedo
				).override_failure_message(
				"%s must read its palette from vertex colours; a kit prop "
				% prop + "without them renders white").is_true()
		root.free()


func test_dressed_scenes_carry_props_and_the_dressing_is_visual_only() -> void:
	for scene_path: String in DRESSED_SCENES:
		var scene := (load(scene_path) as PackedScene).instantiate()
		var containers := scene.find_children("Dressing", "", true, false)
		assert_int(containers.size()).override_failure_message(
			"%s must carry one Dressing container" % scene_path).is_equal(1)
		var dressing := containers[0] as Node

		var instanced := 0
		for node: Node in dressing.get_children():
			if node.scene_file_path.begins_with("res://assets/environment/"):
				instanced += 1
		assert_int(instanced).override_failure_message(
			"%s: a Dressing container with fewer than a dozen props is not "
			% scene_path + "dressed").is_greater_equal(12)

		# Visual only: no physics object and no group anywhere beneath it.
		for node: Node in dressing.find_children("*", "", true, false):
			assert_int((node.get_groups() as Array).size()
				).override_failure_message(
				"%s: dressing node %s carries a group; decoration must "
				% [scene_path, node.name]
				+ "never become a contract element").is_equal(0)
		assert_int(dressing.find_children("*", "CollisionObject3D", true,
			false).size()).override_failure_message(
			"%s: dressing must not collide" % scene_path).is_equal(0)
		scene.free()


func test_water_volumes_in_official_worlds_carry_bubbles() -> void:
	for scene_path: String in WATERED_SCENES:
		var scene := (load(scene_path) as PackedScene).instantiate()
		var volumes := scene.find_children("*", "WaterVolume", true, false)
		assert_int(volumes.size()).is_greater_equal(1)
		for volume: Node in volumes:
			var particles := volume.find_children("*", "GPUParticles3D",
				true, false)
			assert_int(particles.size()).override_failure_message(
				"%s: the water volume must carry its bubble particles"
				% scene_path).is_greater_equal(1)
			var bubbles := particles[0] as GPUParticles3D
			assert_object(bubbles.process_material).is_not_null()
			assert_object(bubbles.draw_pass_1).is_not_null()
		scene.free()
