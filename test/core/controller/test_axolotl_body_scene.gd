extends GdUnitTestSuite

## The axolotl's scene (core/controller/axolotl_body.tscn): the body wrapper
## carrying the hero model. The runner adds nodes before the tree iterates,
## so this proves STRUCTURE — what the scene ships — rather than motion; the
## motion is the controller suite's and the walk probes' to prove.

const SCENE_PATH := "res://core/controller/axolotl_body.tscn"
const MODEL_PATH := "res://assets/character/axolotl/axolotl.glb"
const PROVENANCE_PATH := "res://assets/character/axolotl/provenance.json"


func test_req_001_the_axolotl_scene_carries_the_hero_model_over_the_body() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	assert_object(packed).is_not_null()
	var root := packed.instantiate()

	assert_bool(root is AxolotlBody).override_failure_message(
		"the scene root must be the body wrapper the controller drives").is_true()
	assert_bool(root.is_in_group("player")).override_failure_message(
		"the hub, the HUD and every world find the player by group").is_true()

	var model := root.get_node_or_null("Model") as Node3D
	assert_object(model).override_failure_message(
		"the body must carry a Model child for the wrapper to turn").is_not_null()
	assert_int(model.find_children("*", "MeshInstance3D", true, false).size()
		).override_failure_message("the model must actually contain meshes"
		).is_greater(0)
	assert_bool(model.scale.is_equal_approx(Vector3.ONE * 0.5)).is_true()
	# Feet on the capsule's bottom (half of 1.6 below the origin).
	assert_float(model.position.y).is_between(-0.85, -0.7)

	# The physics footprint is unchanged from the greybox body: the capsule
	# every probe and tuning value was proven against.
	var collision := root.get_node_or_null("Collision") as CollisionShape3D
	assert_object(collision).is_not_null()
	var capsule := collision.shape as CapsuleShape3D
	assert_object(capsule).is_not_null()
	assert_float(capsule.radius).is_equal_approx(0.5, 0.0001)
	assert_float(capsule.height).is_equal_approx(1.6, 0.0001)

	root.free()


func test_req_015_the_hero_asset_is_laid_out_per_the_asset_contract() -> void:
	# assets/<category>/<name>/ with its provenance beside it (REQ-015).
	assert_bool(ResourceLoader.exists(MODEL_PATH)).is_true()
	assert_bool(FileAccess.file_exists(PROVENANCE_PATH)).is_true()
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(PROVENANCE_PATH))
	assert_bool(parsed is Dictionary).is_true()
	for field: String in ["author", "generationMethod", "licenseTerms"]:
		assert_bool((parsed as Dictionary).has(field)).override_failure_message(
			"provenance.json must record %s" % field).is_true()
