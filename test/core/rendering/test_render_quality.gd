extends GdUnitTestSuite

## Graphics quality levels (REQ-027).
##
## The GPU gate (test/perf/run_gpu_gate.gd) proves the levels are actually
## CHEAPER than one another, by measuring. It needs a real rasteriser and
## about fifteen minutes, so it is not in the default chain. This suite is the
## cheap half that IS: it proves the levels differ in the specific ways that
## make them cheaper, so the expensive one cannot be quietly re-enabled at
## MEDIUM by an edit nobody profiles.

const RIG := "res://core/rendering/world_lighting.tscn"


## The shim's suite is a RefCounted, not a Node, so anything that needs
## _ready to fire is parented to the running tree's root instead.
func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _environment() -> Environment:
	# A fresh copy per call, because RenderQuality.apply mutates in place and
	# a test that shared one would depend on the order the others ran in.
	return (load("res://core/rendering/base_environment.tres")
		as Environment).duplicate()


func test_req_027_sdfgi_and_volumetric_fog_are_high_only() -> void:
	# THE TWO THAT MATTER MOST. SDFGI re-voxelises as the camera travels, so a
	# 128-metre level pays for it every frame rather than once; volumetric fog
	# is the next-largest. Together they are most of the gap the GPU gate
	# measures between MEDIUM and HIGH.
	for level: RenderQuality.Level in [RenderQuality.Level.LOW,
			RenderQuality.Level.MEDIUM]:
		var environment := _environment()
		RenderQuality.apply(level, environment, null, null)
		assert_bool(environment.sdfgi_enabled).override_failure_message(
			"SDFGI must be off below HIGH: it is the single most expensive "
			+ "thing in the frame and it re-voxelises as the camera moves"
		).is_false()
		assert_bool(environment.volumetric_fog_enabled
			).override_failure_message(
			"volumetric fog must be off below HIGH").is_false()

	var high := _environment()
	RenderQuality.apply(RenderQuality.Level.HIGH, high, null, null)
	assert_bool(high.sdfgi_enabled).override_failure_message(
		"HIGH is the authored look; it keeps SDFGI").is_true()
	assert_bool(high.volumetric_fog_enabled).is_true()


func test_req_027_every_level_keeps_the_look_the_same_game() -> void:
	# A quality level REMOVES EFFECTS; it never re-grades the picture. Sky,
	# tonemap, exposure and distance fog carry "one world, one voice"
	# (docs/asset-contract.md), so a level that shifted them would make the
	# game look like a different game on a slower machine rather than the
	# same game rendered more cheaply.
	var reference := _environment()
	for level: RenderQuality.Level in [RenderQuality.Level.LOW,
			RenderQuality.Level.MEDIUM, RenderQuality.Level.HIGH]:
		var environment := _environment()
		RenderQuality.apply(level, environment, null, null)
		assert_bool(environment.tonemap_mode == reference.tonemap_mode
			).override_failure_message(
			"the tonemap must not change with quality").is_true()
		assert_float(environment.tonemap_exposure).is_equal_approx(
			reference.tonemap_exposure, 0.001)
		assert_bool(environment.fog_enabled).override_failure_message(
			"distance fog is a cheap per-pixel blend and carries the valley's "
			+ "aerial perspective; it survives at every level").is_true()
		assert_bool(environment.fog_light_color.is_equal_approx(
			reference.fog_light_color)).is_true()


func test_req_027_the_shipped_default_is_not_the_expensive_one() -> void:
	# The omission this whole requirement exists to correct: the authored look
	# shipped as the ONLY option, so the first thing a player met was stutter,
	# and there was no setting to find.
	assert_bool(RenderQuality.DEFAULT != RenderQuality.Level.HIGH
		).override_failure_message(
		"the default must be a level a mid-range desktop can hold; HIGH is "
		+ "the authored look and is one menu entry away").is_true()


func test_req_027_the_rig_applies_a_level_without_editing_the_shared_file() -> void:
	# base_environment.tres is a SHARED resource: load() hands every caller the
	# same instance. If the rig applied a level to it in place, the running
	# game would mutate the repo's own file and bake that level in on the next
	# editor save.
	var rig := (load(RIG) as PackedScene).instantiate() as WorldLighting
	_tree_root().add_child(rig)

	var shipped := load("res://core/rendering/base_environment.tres") as Environment
	var authored_sdfgi := shipped.sdfgi_enabled

	# Applied explicitly rather than left to _ready: a node added to the root
	# from SceneTree._initialize — which is how this harness builds its scene —
	# is not in the tree yet, so _ready has not run at this point.
	rig.set_quality(RenderQuality.Level.LOW)

	var mounted := rig.get_world_environment().environment
	assert_bool(mounted != shipped).override_failure_message(
		"the rig must mount its OWN copy before applying a level; writing to "
		+ "the shared resource writes through to the repo").is_true()
	assert_bool(mounted.sdfgi_enabled).override_failure_message(
		"LOW must actually reach the mounted environment").is_false()
	assert_bool(shipped.sdfgi_enabled == authored_sdfgi
		).override_failure_message(
		"the shipped resource must still carry the authored look").is_true()

	# Idempotent: a second call must not re-duplicate and lose the first.
	var before := mounted
	rig.set_quality(RenderQuality.Level.HIGH)
	assert_bool(rig.get_world_environment().environment == before
		).override_failure_message(
		"re-applying must reuse the rig's copy, not make a fresh one each time"
	).is_true()
	assert_bool(rig.get_world_environment().environment.sdfgi_enabled
		).is_true()

	_tree_root().remove_child(rig)
	rig.free()


func test_req_027_the_sun_sheds_its_area_softness_below_high() -> void:
	# A 1.5-degree angular size makes the sun an area light and the cost is in
	# filter taps at every shadowed pixel — far more than the atlas size.
	var sun := DirectionalLight3D.new()

	RenderQuality.apply(RenderQuality.Level.HIGH, null, sun, null)
	assert_float(sun.light_angular_distance).is_equal_approx(1.5, 0.001)

	for level: RenderQuality.Level in [RenderQuality.Level.LOW,
			RenderQuality.Level.MEDIUM]:
		RenderQuality.apply(level, null, sun, null)
		assert_float(sun.light_angular_distance).override_failure_message(
			"below HIGH the sun becomes a point light with a blur"
		).is_equal_approx(0.0, 0.001)
		assert_bool(sun.shadow_enabled).override_failure_message(
			"shadows never turn off entirely: a shadowless axolotl floats"
		).is_true()

	sun.free()


func test_req_027_a_level_name_round_trips() -> void:
	# The name is what an override and a future options screen persist, so it
	# has to survive the trip in both directions.
	for level: RenderQuality.Level in [RenderQuality.Level.LOW,
			RenderQuality.Level.MEDIUM, RenderQuality.Level.HIGH]:
		assert_bool(RenderQuality.level_from_name(
			RenderQuality.level_name(level)) == level).is_true()
	assert_bool(RenderQuality.level_from_name("nonsense")
		== RenderQuality.DEFAULT).override_failure_message(
		"an unreadable name falls back to the default rather than failing"
	).is_true()
