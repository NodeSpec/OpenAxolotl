extends GdUnitTestSuite

## Leaving a level downwards has to end somewhere (REQ-003, REQ-009).
##
## WHY THIS SUITE EXISTS, and it is not hypothetical. Measured in the shipped
## hub before this was written: teleported off the lagoon, the player fell 583
## units in twenty seconds and was still accelerating. No life was charged, no
## respawn fired, nothing was watching. The only way out of the game was to
## quit it. Every unit test passed while that was true, because every unit test
## asked about a system and none asked about the SCENE.
##
## Both official worlds were fine, which is the interesting part: each carries
## a pit volume sized as a floor under its whole playable area — 600x600 under
## Coral Cove, 400x400 under Bubble Bay — so a fall there costs a life and
## returns the player to a checkpoint, exactly as REQ-003 designs. The hub
## carries no pit volume and owns no LifeSystem, so it needed a different
## answer rather than a copy of theirs.
##
## What is held here is the PROPERTY, in both places it has to hold:
##
##   1. The hub takes a fallen player back, at rest.
##   2. Every world has a floor under all of it, positioned below the level
##      rather than merely present somewhere in the file.
##
## The second is what stops this recurring. A world that grows a new arm past
## the edge of its kill slab fails here with a number, rather than in the one
## playthrough where somebody walks off that particular corner.

const HUB := "res://hub/open_lagoon.tscn"
const WORLDS := ["res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn"]

## Groups whose members mark playable space. A floor must reach under all of
## it; scenery and the kill slab itself are deliberately not in the list.
const PLAYABLE_GROUPS := ["spawn_point", "checkpoint", "collectible",
	"gill_mod_pickup", "enemy", "finish_volume", "regen_station"]


func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## THE HUB SCENE'S ROOT IS NOT THE HUB. open_lagoon.tscn is rooted at `Main`,
## with the OpenLagoon node and the player Axolotl as SIBLINGS under it — the
## scene's own comment explains why, and it means instantiating the file and
## casting the result to OpenLagoon returns null.
func _hub_in(scene: Node) -> OpenLagoon:
	if scene is OpenLagoon:
		return scene as OpenLagoon
	for node: Node in scene.find_children("*", "", true, false):
		if node is OpenLagoon:
			return node as OpenLagoon
	return null


## The player, found by the SAME group the production code looks it up by.
##
## This used to take the first CharacterBody3D in the scene, which is not
## necessarily the same node: the test then placed one body and
## _recover_fallen_player read another, so a player standing safely at y 1 was
## reported as teleported and a zeroed velocity was read off a body nobody had
## touched. Both halves have to agree on which node is the player.
func _player_in(scene: Node) -> Node3D:
	for node: Node in scene.find_children("*", "Node3D", true, false):
		if node.is_in_group("player"):
			return node as Node3D
	return null


func _first_in_group(scene: Node, group: String) -> Node3D:
	for node: Node in scene.find_children("*", "Node3D", true, false):
		if node.is_in_group(group):
			return node as Node3D
	return null


## Where a node sits relative to its scene root, accumulated from the
## transforms themselves.
##
## global_position is not usable here. A scene added from SceneTree._initialize
## has had no frame, so Godot has not refreshed its global transforms and every
## one of them reads as its local value: the pit slab centred at y -18 measured
## as if it sat at the origin, which made the floor look like it was ABOVE the
## level. Multiplying up the chain needs no frame and cannot be wrong about it.
func _local_to_scene(node: Node3D, root: Node) -> Vector3:
	var accumulated := Transform3D()
	var current: Node3D = node
	while current != null and current != root:
		accumulated = current.transform * accumulated
		current = current.get_parent() as Node3D
	return accumulated.origin


## WHAT THIS SUITE DELIBERATELY DOES NOT TEST, and where it went instead.
##
## Three cases here used to call OpenLagoon._recover_fallen_player() directly
## against a freshly instantiated hub, and they were a worse test than no test.
## A scene added from SceneTree._initialize has had no frame: its global
## transforms are stale, so a player placed at y 1 was read as somewhere else
## entirely and a standing player came back "recovered". They were failing on
## the harness, not on the code — the same code that, driven for real, catches
## a fall at the floor and returns the player to spawn at rest.
##
## The property is about a scene running physics, so it is proven in one:
## test/hub/run_fall_recovery.gd throws the player off the lagoon and watches
## what happens. That is also the shape the bug had — every unit test passed
## while the hub had no floor at all — so the lesson and the coverage now
## match.
##
## What stays here is the half that IS static: whether each world's declared
## floor actually reaches under everything the player can stand on.


func test_req_003_every_world_has_a_floor_under_all_of_its_playable_space() -> void:
	# THE ONE THAT STOPS THIS COMING BACK. A pit volume that merely EXISTS
	# proves nothing: it has to reach under everywhere the player can be, and
	# sit below them. A level that grows past the edge of its kill slab fails
	# here, naming the marker that hangs over nothing.
	for path: String in WORLDS:
		var world := (load(path) as PackedScene).instantiate()
		_tree_root().add_child(world)

		var floors: Array[Area3D] = []
		for node: Node in world.find_children("*", "Area3D", true, false):
			if (node as Area3D).is_in_group("pit_volume"):
				floors.append(node as Area3D)
		assert_int(floors.size()).override_failure_message(
			"%s declares no pit_volume, so a fall in it never ends" % path
			).is_greater_equal(1)

		var covered := AABB()
		var first := true
		for area: Area3D in floors:
			for shape_node: Node in area.find_children(
					"*", "CollisionShape3D", true, false):
				var box := (shape_node as CollisionShape3D).shape as BoxShape3D
				if box == null:
					continue
				var centre := _local_to_scene(
					shape_node as CollisionShape3D, world)
				var slab := AABB(centre - box.size * 0.5, box.size)
				covered = slab if first else covered.merge(slab)
				first = false
		assert_bool(not first).override_failure_message(
			"%s has a pit_volume with no box shape to cover anything" % path
			).is_true()

		for group: String in PLAYABLE_GROUPS:
			for node: Node in world.find_children("*", "Node3D", true, false):
				if not node.is_in_group(group):
					continue
				var spot := _local_to_scene(node as Node3D, world)
				assert_bool(spot.x >= covered.position.x
					and spot.x <= covered.position.x + covered.size.x
					and spot.z >= covered.position.z
					and spot.z <= covered.position.z + covered.size.z
					).override_failure_message(
					("%s: %s (%s) sits at %v, outside the floor that spans "
					+ "x %.0f..%.0f z %.0f..%.0f — a player who falls off it "
					+ "never lands") % [path, node.name, group, spot,
					covered.position.x, covered.position.x + covered.size.x,
					covered.position.z, covered.position.z + covered.size.z]
					).is_true()
				assert_bool(spot.y > covered.position.y + covered.size.y
					).override_failure_message(
					("%s: %s (%s) is at y %.1f, at or below the floor's top "
					+ "of %.1f — the floor is not under it")
					% [path, node.name, group, spot.y,
					covered.position.y + covered.size.y]).is_true()

		_tree_root().remove_child(world)
		world.free()
