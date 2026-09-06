extends GdUnitTestSuite

## The look foundation: one shared lighting rig (core/rendering/) on the
## Forward+ renderer, instanced beside the hub so it lights every world.
##
## These are STRUCTURE tests — what the resource and scenes ship. The runner
## adds nodes before the tree iterates and headless CI renders nothing, so
## whether the result LOOKS right is the human half (docs/asset-contract.md,
## "Style and art direction"); what a machine can hold is that the rig exists,
## carries the settings the art direction depends on, and sits where a world
## transition cannot switch it off.

const RIG_PATH := "res://core/rendering/world_lighting.tscn"
const ENVIRONMENT_PATH := "res://core/rendering/base_environment.tres"
const HUB_PATH := "res://hub/open_lagoon.tscn"
const GREYBOX_PATH := "res://dev/greybox.tscn"
const TEMPLATE_PATH := "res://worlds/reference_template/world.tscn"
const WATER_MATERIAL_PATH := "res://core/rendering/water_surface.tres"
const WATER_SCENES: Array[String] = [
	"res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn",
	GREYBOX_PATH,
]

# Godot's Environment enums, spelled out so a silent renumbering is a failure.
const BG_SKY := 2
const AMBIENT_FROM_SKY := 3
const REFLECTIONS_FROM_SKY := 2
const TONEMAP_AGX := 4
const SHADOW_PARALLEL_2_SPLITS := 1


func test_the_project_renders_with_forward_plus_and_a_mobile_fallback() -> void:
	# The rig's expensive half (GI, occlusion, volumetric fog) exists only on
	# Forward+; the Mobile fallback keeps weaker hardware running rather than
	# crashing. Compatibility (OpenGL) is not a target.
	assert_str(str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method"))).is_equal("forward_plus")
	assert_str(str(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method.mobile"))).is_equal("mobile")
	assert_bool(bool(ProjectSettings.get_setting(
		"rendering/anti_aliasing/quality/use_taa"))).is_true()


func test_the_shared_environment_carries_the_look_the_art_direction_needs() -> void:
	var environment: Environment = load(ENVIRONMENT_PATH)
	assert_object(environment).is_not_null()

	# Lit by a sky, not a flat colour: ambient and reflections both read it.
	assert_int(environment.background_mode).is_equal(BG_SKY)
	assert_object(environment.sky).override_failure_message(
		"the environment must carry a sky for ambient light to come from"
		).is_not_null()
	assert_int(environment.ambient_light_source).is_equal(AMBIENT_FROM_SKY)
	assert_int(environment.reflected_light_source).is_equal(REFLECTIONS_FROM_SKY)

	# Saturated albedo must not clip: AgX is the tonemapper that keeps it.
	assert_int(environment.tonemap_mode).is_equal(TONEMAP_AGX)

	# Contact shading, bounced light, restrained glow, teal depth fog, and
	# the light shafts — each one on. Their strengths are art direction, not
	# a contract; only their presence is held here.
	assert_bool(environment.ssao_enabled).is_true()
	assert_bool(environment.sdfgi_enabled).is_true()
	assert_bool(environment.glow_enabled).is_true()
	assert_float(environment.glow_hdr_threshold).override_failure_message(
		"glow must only reach highlights brighter than white, never albedo"
		).is_greater_equal(1.0)
	assert_bool(environment.fog_enabled).is_true()
	assert_bool(environment.volumetric_fog_enabled).is_true()


func test_the_rig_ships_one_environment_and_a_soft_shadowed_sun() -> void:
	var packed: PackedScene = load(RIG_PATH)
	assert_object(packed).is_not_null()
	var rig := packed.instantiate() as WorldLighting
	assert_object(rig).override_failure_message(
		"the rig root must be the WorldLighting type tests and moods find"
		).is_not_null()

	var world_environment := rig.get_world_environment()
	assert_object(world_environment).is_not_null()
	assert_str(world_environment.environment.resource_path).is_equal(
		ENVIRONMENT_PATH)

	var sun := rig.get_sun()
	assert_object(sun).is_not_null()
	assert_bool(sun.shadow_enabled).is_true()
	assert_int(sun.directional_shadow_mode).is_equal(SHADOW_PARALLEL_2_SPLITS)
	assert_float(sun.light_angular_distance).override_failure_message(
		"a sun with no angular size casts razor shadows; the toy look needs "
		+ "soft penumbrae").is_greater(0.0)
	assert_float(sun.shadow_blur).is_greater(0.0)

	rig.free()


func test_the_hub_instances_the_rig_beside_itself_not_inside_it() -> void:
	# The hub disables its own subtree while a world is active. A light under
	# it would go dark the moment the player entered a world, which is what
	# lit official worlds by ambient colour alone before the rig existed.
	var packed: PackedScene = load(HUB_PATH)
	var main := packed.instantiate()

	var rigs := main.find_children("*", "WorldLighting", true, false)
	assert_int(rigs.size()).override_failure_message(
		"the main scene must instance exactly one shared lighting rig"
		).is_equal(1)
	var rig := rigs[0] as Node
	assert_str(rig.scene_file_path).is_equal(RIG_PATH)
	assert_bool(rig.get_parent() == main).override_failure_message(
		"the rig must be a direct child of the main scene, beside the hub"
		).is_true()

	var hub := main.find_children("*", "OpenLagoon", true, false)[0] as Node
	assert_int(hub.find_children("*", "WorldEnvironment", true, false).size()
		).override_failure_message(
		"no environment may live under the hub's own subtree").is_equal(0)
	assert_int(hub.find_children("*", "DirectionalLight3D", true, false).size()
		).override_failure_message(
		"no sun may live under the hub's own subtree").is_equal(0)

	main.free()


func test_the_greybox_instances_the_rig_and_worlds_ship_no_lighting() -> void:
	var greybox := (load(GREYBOX_PATH) as PackedScene).instantiate()
	assert_int(greybox.find_children("*", "WorldLighting", true, false).size()
		).is_equal(1)
	greybox.free()

	# Worlds ship geometry; the client lights it. The template is the proof
	# a world needs no sun of its own to be complete and playable.
	var template := (load(TEMPLATE_PATH) as PackedScene).instantiate()
	assert_int(template.find_children("*", "DirectionalLight3D", true, false
		).size()).override_failure_message(
		"the reference template must not ship a sun; the client's rig lights "
		+ "every world").is_equal(0)
	assert_int(template.find_children("*", "WorldLighting", true, false
		).size()).is_equal(0)
	template.free()


func test_every_water_volume_wears_the_shared_unshaded_water_surface() -> void:
	# A lit translucent box under the rig's sun blows out to near-opaque and
	# hides the axolotl in water. The tint is the client's, in one unshaded
	# material every WaterVolume mesh references.
	var material: StandardMaterial3D = load(WATER_MATERIAL_PATH)
	assert_object(material).is_not_null()
	assert_int(material.shading_mode).override_failure_message(
		"the water surface must be unshaded so lighting cannot blow it out"
		).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_int(material.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)

	for scene_path: String in WATER_SCENES:
		var scene := (load(scene_path) as PackedScene).instantiate()
		var volumes := scene.find_children("*", "WaterVolume", true, false)
		assert_int(volumes.size()).override_failure_message(
			"%s must carry a WaterVolume for this test to mean anything"
			% scene_path).is_greater(0)
		for volume: Node in volumes:
			for mesh: Node in volume.find_children("*", "MeshInstance3D", true, false):
				var worn := (mesh as MeshInstance3D).get_surface_override_material(0)
				assert_object(worn).is_not_null()
				assert_str(worn.resource_path).override_failure_message(
					("%s: a water mesh wears its own tint instead of the shared "
					+ "surface") % scene_path).is_equal(WATER_MATERIAL_PATH)
		scene.free()
