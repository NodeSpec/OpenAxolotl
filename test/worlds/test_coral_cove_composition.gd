extends GdUnitTestSuite

## Coral Cove's authored presentation beats (REQ-011).
##
## The route walk proves that the greybox is completable. These assertions hold
## the other half of a finished platformer level: the camera intentionally
## reframes the major verbs, and the things the player is meant to notice move
## without ever moving the collision that defines the route.

const CORAL := "res://worlds/coral_cove/world.tscn"
const MOTION := preload("res://core/rendering/presentation_motion.gd")

const CAMERA_BEATS: Array[String] = ["ArrivalView", "GardenView", "RootView", "TerraceView", "CrownView", "FinishView"]



func test_req_011_coral_cove_frames_every_major_platforming_beat() -> void:
	var world := (load(CORAL) as PackedScene).instantiate()

	for path: String in CAMERA_BEATS:
		var hint := world.get_node_or_null(path)
		assert_object(hint).override_failure_message(
			"Coral Cove lost authored camera beat '%s'" % path
		).is_not_null()
		if hint == null:
			continue
		assert_bool(hint is CameraHintVolume).override_failure_message(
			"%s must remain a declarative CameraHintVolume" % path
		).is_true()
		assert_int(hint.find_children("*", "CollisionShape3D", true, false).size()
			).override_failure_message(
			"%s has no volume, so its framing can never trigger" % path
		).is_greater_equal(1)

	world.free()


func test_req_011_gameplay_reads_move_but_gameplay_authority_does_not() -> void:
	var world := (load(CORAL) as PackedScene).instantiate()

	var pickups := 0
	for area: Area3D in world.find_children("*", "Area3D", true, false):
		if not area.is_in_group("collectible"):
			continue
		pickups += 1
		var meshes := area.find_children("*", "MeshInstance3D", true, false)
		assert_int(meshes.size()).is_greater(0)
		for visual: Node in meshes:
			assert_bool(visual.get_script() == MOTION).is_true()
	assert_int(pickups).is_equal(12) # Nine seeds, two rescues, one optional pearl.

	# The same script may also animate plants in Dressing, but never a body or
	# area that decides where the player may stand, swim, collect or take damage.
	for node: Node in world.find_children("*", "CollisionObject3D", true, false):
		assert_bool(node.get_script() != MOTION).override_failure_message(
			"%s moves gameplay authority with presentation animation" % node.name
		).is_true()

	world.free()


func test_req_011_dressing_is_authored_in_distinct_route_beats() -> void:
	var world := (load(CORAL) as PackedScene).instantiate()
	var dressing := world.get_node_or_null("Dressing")
	assert_object(dressing).is_not_null()
	if dressing == null:
		world.free()
		return

	# These are not arbitrary density targets. One named landmark cluster per
	# traversal beat means a contributor can reason about composition in the
	# scene instead of editing an opaque random scatter cloud.
	var beats: Array[PackedStringArray] = [
		PackedStringArray(["Dressing/ArrivalRocks", "Dressing/GardenRocks"]),
		PackedStringArray(["SuppliedAssets/S03_RootBridge", "SuppliedAssets/S03_GrottoArch"]),
		PackedStringArray(["SuppliedAssets/S04_LowerShelf", "Dressing/ScenicWaterfall0"]),
		PackedStringArray(["SuppliedAssets/S05_CrownArch", "SuppliedAssets/S05_CrownBankLedge"]),
		PackedStringArray(["Dressing/FinishRocks", "Dressing/FinishGuidance", "SuppliedAssets/S06_FinishReef"]),
	]
	for beat: PackedStringArray in beats:
		for node_name: String in beat:
			assert_object(world.get_node_or_null(node_name)
				).override_failure_message(
				"Coral Cove composition lost landmark '%s'" % node_name
				).is_not_null()

	world.free()
