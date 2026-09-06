extends GdUnitTestSuite

## Squash and stretch (core/controller/hero_squash.gd): pure arithmetic the
## body multiplies onto the model's scale. Proven here without a scene.

const TUNING_PATH := "res://core/tuning/tuning.json"

var _tuning: TuningData


func before_test() -> void:
	var errors: Array[TuningError] = []
	_tuning = TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()


func _volume(scale: Vector3) -> float:
	return scale.x * scale.y * scale.z


func test_at_rest_the_model_is_left_at_its_authored_scale() -> void:
	var squash := HeroSquash.new(_tuning)
	assert_bool(squash.is_at_rest()).is_true()
	var scale := squash.step(1.0 / 60.0)
	assert_bool(scale.is_equal_approx(Vector3.ONE)).is_true()


func test_a_hop_stretches_tall_and_thin_without_changing_volume() -> void:
	var squash := HeroSquash.new(_tuning)
	squash.on_hop()
	var scale := squash.step(0.0)
	assert_float(scale.y).override_failure_message(
		"a hop must stretch the model taller").is_greater(1.0)
	assert_float(scale.x).is_less(1.0)
	assert_float(scale.z).is_equal_approx(scale.x, 0.0001)
	assert_float(_volume(scale)).override_failure_message(
		"stretch must preserve volume: rubber, not a balloon"
		).is_equal_approx(1.0, 0.001)
	assert_float(scale.y - 1.0).is_equal_approx(
		_tuning.get_number(HeroSquash.HOP_STRETCH_KEY), 0.0001)


func test_a_landing_squashes_short_and_wide_without_changing_volume() -> void:
	var squash := HeroSquash.new(_tuning)
	squash.on_land()
	var scale := squash.step(0.0)
	assert_float(scale.y).override_failure_message(
		"a landing must squash the model shorter").is_less(1.0)
	assert_float(scale.x).is_greater(1.0)
	assert_float(_volume(scale)).is_equal_approx(1.0, 0.001)
	assert_float(1.0 - scale.y).is_equal_approx(
		_tuning.get_number(HeroSquash.LAND_SQUASH_KEY), 0.0001)


func test_a_deformation_recovers_to_rest_within_a_second() -> void:
	var squash := HeroSquash.new(_tuning)
	squash.on_land()
	var previous := absf(squash.get_deform())
	var frames_to_rest := -1
	for frame: int in 60:
		squash.step(1.0 / 60.0)
		var now := absf(squash.get_deform())
		assert_float(now).override_failure_message(
			"recovery must be monotonic; frame %d grew" % frame
			).is_less_equal(previous)
		previous = now
		if squash.is_at_rest() and frames_to_rest < 0:
			frames_to_rest = frame
	assert_int(frames_to_rest).override_failure_message(
		"a landing squash must fully recover within a second at 60 Hz"
		).is_greater_equal(1)
	assert_int(frames_to_rest).is_less_equal(59)
	assert_bool(squash.step(0.0).is_equal_approx(Vector3.ONE)).is_true()


func test_a_new_event_replaces_the_deformation_rather_than_stacking() -> void:
	var squash := HeroSquash.new(_tuning)
	squash.on_hop()
	squash.on_hop()
	assert_float(squash.get_deform()).is_equal_approx(
		_tuning.get_number(HeroSquash.HOP_STRETCH_KEY), 0.0001)
	squash.on_land()
	assert_float(squash.get_deform()).override_failure_message(
		"landing mid-stretch squashes; it never adds to the stretch"
		).is_less(0.0)


func test_squash_and_stretch_are_tuning_keys_with_documented_units() -> void:
	# Balance data, not constants (REQ-025): each amount carries a unit and a
	# range, so a designer can tune the feel without touching code.
	assert_str(_tuning.get_unit(HeroSquash.HOP_STRETCH_KEY)).is_equal("ratio")
	assert_str(_tuning.get_unit(HeroSquash.LAND_SQUASH_KEY)).is_equal("ratio")
	assert_str(_tuning.get_unit(HeroSquash.RECOVER_RATE_KEY)).is_equal("per_second")
	assert_float(_tuning.get_number(HeroSquash.HOP_STRETCH_KEY)).is_greater(0.0)
	assert_float(_tuning.get_number(HeroSquash.LAND_SQUASH_KEY)).is_greater(0.0)
