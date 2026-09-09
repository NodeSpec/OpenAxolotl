extends GdUnitTestSuite

## Coral Cove's authored presentation beats (REQ-011).
##
## The route walk proves that the greybox is completable. These assertions hold
## the other half of a finished platformer level: the camera intentionally
## reframes the major verbs, and the things the player is meant to notice move
## without ever moving the collision that defines the route.

const CORAL := "res://worlds/coral_cove/world.tscn"
const MOTION := preload("res://core/rendering/presentation_motion.gd")

const CAMERA_BEATS: Array[String] = [
	"OpeningHint",
	"CoveRevealHint",
	"WallRevealHint",
	"GrottoHint",
	"GorgeHint",
	"SeedBedHint",
	"FinishHint",
]

const ANIMATED_READS: Array[String] = [
	"HermitSnail/Mesh",
	"GlowPickup/Mesh",
	"StrayHook/Mesh",
	"LanternShrimp/Mesh",
	"BubblePickup/Mesh",
	"RegenStation/Mesh",
	"Seed1/Mesh",
	"Seed2/Mesh",
	"Seed3/Mesh",
	"Seed4/Mesh",
	"Seed5/Mesh",
	"Seed6/Mesh",
	"Seed7/Mesh",
]


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

	for path: String in ANIMATED_READS:
		var visual := world.get_node_or_null(path)
		assert_object(visual).override_failure_message(
			"Coral Cove lost animated gameplay read '%s'" % path
		).is_not_null()
		if visual == null:
			continue
		assert_bool(visual.get_script() == MOTION).override_failure_message(
			"%s must use the shared visual-only presentation motion" % path
		).is_true()
		assert_bool(not (visual is CollisionObject3D)).override_failure_message(
			"%s is gameplay collision wearing visual motion" % path
		).is_true()

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
		PackedStringArray(["OpeningTreeLeft", "OpeningTreeRight"]),
		PackedStringArray(["CoveBoulderLeft", "HeroKelpLeft"]),
		PackedStringArray(["WallTreeLeft", "WallCoralRight"]),
		PackedStringArray(["GrottoCoralLeft", "GrottoRockFrameRight"]),
		PackedStringArray(["GorgeReedsLeft", "GorgeReedsRight"]),
		PackedStringArray(["SeedGrassLeft", "SeedGrassRight"]),
		PackedStringArray(["FinishCoralLeft", "FinishCoralRight"]),
	]
	for beat: PackedStringArray in beats:
		for node_name: String in beat:
			assert_object(dressing.get_node_or_null(node_name)
				).override_failure_message(
				"Coral Cove composition lost landmark '%s'" % node_name
				).is_not_null()

	world.free()
