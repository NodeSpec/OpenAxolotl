extends GdUnitTestSuite

## Scattered dressing (REQ-027, REQ-034).
##
## Two things have to hold for the conversion from individual prop instances to
## MultiMesh to have been safe: every prop must still stand exactly where it
## stood, and the wind must be fitted to the plant it is moving. The first is
## what makes the change invisible to a route that was already proven flyable;
## the second is a bug this suite exists because of.

const CORAL := "res://worlds/coral_cove/world.tscn"
const FOREST_MATERIAL := "res://core/rendering/materials/forest_canopy.tres"
const TREE := "res://assets/environment/canopy_tree/canopy_tree.glb"
const FERN := "res://assets/environment/understory_fern/understory_fern.glb"


func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _fields(scene: Node) -> Array:
	var found: Array = []
	for node: Node in scene.find_children("*", "Node3D", true, false):
		if node is ScatterField:
			found.append(node)
	return found


func test_req_034_the_valley_is_dressed_through_scatter_fields() -> void:
	var scene := (load(CORAL) as PackedScene).instantiate()
	var fields := _fields(scene)
	assert_int(fields.size()).override_failure_message(
		"the valley must dress itself through scatter fields; found none"
	).is_greater_equal(4)

	var instances := 0
	for field: ScatterField in fields:
		instances += field.instance_count()
	# One draw call per field against one per instance is the whole point.
	assert_bool(instances >= fields.size() * 4).override_failure_message(
		"%d instances across %d fields is barely more than one each, which "
		% [instances, fields.size()] + "buys nothing over plain instancing"
	).is_true()
	scene.free()


func test_req_034_every_scattered_transform_is_a_real_placement() -> void:
	# The conversion preserved each prop's transform to the float. A field whose
	# transforms had been mangled would show up here as degenerate bases —
	# zero-scale instances are invisible, which is the failure that would
	# otherwise be discovered by looking at an empty forest.
	var scene := (load(CORAL) as PackedScene).instantiate()
	for field: ScatterField in _fields(scene):
		assert_int(field.transforms.size() % 12).override_failure_message(
			"%s: transforms must be twelve floats per instance" % field.name
		).is_equal(0)
		assert_int(field.instance_count()).is_greater(0)
		for index: int in field.instance_count():
			var basis := field._transform_at(index).basis
			assert_bool(basis.determinant() > 0.0001).override_failure_message(
				"%s instance %d has a degenerate basis and would render as "
				% [field.name, index] + "nothing").is_true()
	scene.free()


func test_req_027_the_wind_is_fitted_to_the_plant_it_moves() -> void:
	# THE BUG THIS SUITE EXISTS FOR. The shader needs the plant's own height to
	# know where the lever ends, and the kit spans a factor of thirty: a canopy
	# tree is 21.9 model units and a fern is 0.74. With one shared height the
	# tree's lever saturated a tenth of the way up its trunk — everything above
	# translating as a rigid block with a kink under it — while fifty ferns sat
	# at eighteen percent of their sway and read as frozen.
	var tall := _built_field(TREE, load(FOREST_MATERIAL))
	var short := _built_field(FERN, load(FOREST_MATERIAL))

	var tall_height: float = _model_height_of(tall)
	var short_height: float = _model_height_of(short)

	assert_bool(tall_height > short_height * 4.0).override_failure_message(
		("each field must take its height from its OWN mesh: the tree got "
		+ "%.2f and the fern %.2f, which are too close to be two different "
		+ "plants") % [tall_height, short_height]).is_true()

	# And each must match the mesh it actually draws, not merely differ.
	assert_float(tall_height).is_equal_approx(
		tall.get_source_mesh().get_aabb().size.y, 0.01)
	assert_float(short_height).is_equal_approx(
		short.get_source_mesh().get_aabb().size.y, 0.01)

	_drop(tall)
	_drop(short)


func test_req_027_rigid_props_never_wear_the_wind() -> void:
	# A swaying boulder is worse than a still one. Rocks, boulders and fallen
	# logs scatter with no surface material so they keep the kit's own.
	var scene := (load(CORAL) as PackedScene).instantiate()
	var rigid := 0
	for field: ScatterField in _fields(scene):
		var name := String(field.name).to_lower()
		if name.contains("boulder") or name.contains("rock") \
				or name.contains("log"):
			rigid += 1
			assert_object(field.surface_material).override_failure_message(
				"%s must not wear the vegetation material: geology does not "
				% field.name + "sway").is_null()
	assert_int(rigid).override_failure_message(
		"expected the valley to carry rigid scatter fields too").is_greater(0)
	scene.free()


func test_req_034_variation_is_deterministic_and_per_instance() -> void:
	# A field of one mesh must not read as one mesh repeated, and it must
	# scatter identically every run — a forest that reshuffles itself between
	# launches is not a place.
	var field := _built_field(FERN, null)
	var first := field._variation_at(0)
	var second := field._variation_at(1)
	assert_bool(first != second).override_failure_message(
		"neighbouring instances must not share a phase, or the whole field "
		+ "sways in lockstep").is_true()
	assert_bool(field._variation_at(0) == first).override_failure_message(
		"variation must be derived, not random: the same instance has to get "
		+ "the same phase every time it is asked").is_true()
	_drop(field)


## A field in the tree with two instances, so _ready has actually built it.
func _built_field(prop_path: String, material: Variant) -> ScatterField:
	var field := ScatterField.new()
	field.prop_scene = load(prop_path)
	if material != null:
		field.surface_material = material as Material
	field.transforms = PackedFloat32Array([
		1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
		1, 0, 0, 0, 1, 0, 0, 0, 1, 3.5, 0, 2.5])
	_tree_root().add_child(field)
	# add_child from inside SceneTree._initialize (how this harness builds its
	# scene) defers _ready, so the build is asked for explicitly.
	field._rebuild()
	return field


func _model_height_of(field: ScatterField) -> float:
	var instances := field.get_multimesh_instance()
	var material := instances.material_override as ShaderMaterial
	return material.get_shader_parameter("model_height")


func _drop(field: ScatterField) -> void:
	_tree_root().remove_child(field)
	field.free()
