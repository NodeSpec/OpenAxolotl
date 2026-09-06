extends GdUnitTestSuite

## The hero's material pass (docs/asset-contract.md, "Toy materials"): the
## client dresses the imported model in its own materials, per part role.
## Structure tests: the classification, the materials each role wears, and
## that the shipped hero model is read the way the palette intends.

const SCENE_PATH := "res://core/controller/axolotl_body.tscn"

# The hero palette as the raw export carries it (mean vertex colour per part).
const PALETTE_SKIN := Color(0.97, 0.83, 0.82)
const PALETTE_BODY := Color(0.96, 0.71, 0.72)
const PALETTE_SPOT := Color(0.87, 0.54, 0.59)
const PALETTE_GILL := Color(0.90, 0.43, 0.53)
const PALETTE_EYE := Color(0.07, 0.08, 0.11)
const PALETTE_GLEAM := Color(1.0, 1.0, 1.0)
const PALETTE_MOUTH := Color(0.37, 0.21, 0.28)


func test_the_palette_classifies_every_part_kind_of_the_hero() -> void:
	assert_int(HeroSkin.classify_color(PALETTE_SKIN)).is_equal(HeroSkin.Role.SKIN)
	assert_int(HeroSkin.classify_color(PALETTE_BODY)).is_equal(HeroSkin.Role.SKIN)
	assert_int(HeroSkin.classify_color(PALETTE_SPOT)).override_failure_message(
		"a spot is skin, not a gill: it must not go translucent"
		).is_equal(HeroSkin.Role.SKIN)
	assert_int(HeroSkin.classify_color(PALETTE_GILL)).is_equal(HeroSkin.Role.GILL)
	assert_int(HeroSkin.classify_color(PALETTE_EYE)).is_equal(HeroSkin.Role.EYE)
	assert_int(HeroSkin.classify_color(PALETTE_GLEAM)).is_equal(HeroSkin.Role.GLEAM)
	assert_int(HeroSkin.classify_color(PALETTE_MOUTH)).is_equal(HeroSkin.Role.DETAIL)


func test_each_role_wears_the_material_the_art_direction_asks_for() -> void:
	var skin := HeroSkin.material_for(HeroSkin.Role.SKIN) as StandardMaterial3D
	assert_object(skin).is_not_null()
	assert_bool(skin.vertex_color_use_as_albedo).override_failure_message(
		"skin takes its colour from the model, so a repainted model keeps it"
		).is_true()
	assert_bool(skin.subsurf_scatter_enabled).is_true()
	assert_bool(skin.clearcoat_enabled).is_true()
	assert_float(skin.roughness).is_between(0.2, 0.6)

	var eye := HeroSkin.material_for(HeroSkin.Role.EYE) as StandardMaterial3D
	assert_bool(eye.vertex_color_use_as_albedo).override_failure_message(
		"an eye stays an eye under any palette").is_false()
	assert_float(eye.roughness).override_failure_message(
		"a wet eye needs a sharp reflection").is_less_equal(0.1)
	assert_bool(eye.clearcoat_enabled).is_true()
	assert_float(eye.albedo_color.get_luminance()).is_less(0.1)

	var gleam := HeroSkin.material_for(HeroSkin.Role.GLEAM) as StandardMaterial3D
	assert_int(gleam.shading_mode).override_failure_message(
		"the catchlight must not go grey in shadow"
		).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)

	var gill := HeroSkin.material_for(HeroSkin.Role.GILL) as StandardMaterial3D
	assert_bool(gill.subsurf_scatter_enabled).is_true()
	assert_bool(gill.backlight_enabled).override_failure_message(
		"gills between the sun and the camera must glow from behind").is_true()
	assert_bool(gill.vertex_color_use_as_albedo).is_true()

	var detail := HeroSkin.material_for(HeroSkin.Role.DETAIL) as StandardMaterial3D
	assert_float(detail.roughness).is_greater_equal(0.7)


func test_the_shipped_hero_model_is_dressed_by_role() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	var body := packed.instantiate()
	var model := body.get_node("Model") as Node3D

	var counts := HeroSkin.apply(model)

	# The shipped asset is the REFINED form (one mesh per role, named by the
	# pipeline); a raw re-upload would count one surface per part instead.
	# Either way every role must be present: an axolotl with no eyes, no
	# gleams or no translucent gills was read wrong.
	for role: String in ["skin", "eye", "gleam", "gill", "detail"]:
		assert_int(counts[role]).override_failure_message(
			"no surface read as %s; got %s" % [role, str(counts)]
			).is_greater_equal(1)

	# Every surface now wears a client material, and the eyes wear the eye.
	var eye_material := HeroSkin.material_for(HeroSkin.Role.EYE)
	var eyes_found := 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface: int in instance.mesh.get_surface_count():
			var worn := instance.get_surface_override_material(surface)
			assert_object(worn).override_failure_message(
				"%s surface %d was left undressed" % [instance.name, surface]
				).is_not_null()
			if worn == eye_material:
				eyes_found += 1
	assert_int(eyes_found).is_greater_equal(1)
	assert_int(eyes_found).is_less_equal(2)

	body.free()


func _mesh_with(color: Color, material_name: String = "") -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray([color, color, color])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not material_name.is_empty():
		var material := StandardMaterial3D.new()
		material.resource_name = material_name
		mesh.surface_set_material(0, material)
	return mesh


func test_a_raw_model_is_read_by_vertex_colour_and_a_refined_one_by_name() -> void:
	# The fallback: a file that names nothing is classified by its colours.
	assert_int(HeroSkin.role_for_surface(_mesh_with(PALETTE_EYE), 0)
		).is_equal(HeroSkin.Role.EYE)
	assert_int(HeroSkin.role_for_surface(_mesh_with(PALETTE_GILL), 0)
		).is_equal(HeroSkin.Role.GILL)
	# The contract: the pipeline's material name wins over the colours, so a
	# repainted gill stays a gill.
	assert_int(HeroSkin.role_for_surface(
		_mesh_with(PALETTE_SKIN, "axolotl_gill"), 0)).is_equal(HeroSkin.Role.GILL)
	# An unknown name falls back to colour rather than failing.
	assert_int(HeroSkin.role_for_surface(
		_mesh_with(PALETTE_MOUTH, "Material.001"), 0)
		).is_equal(HeroSkin.Role.DETAIL)
