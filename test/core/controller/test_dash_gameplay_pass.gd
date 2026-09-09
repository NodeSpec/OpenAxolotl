extends GdUnitTestSuite

## Gameplay-feel pass for the water-powered DASH.
##
## REQ-001 AC-5 says the dash is usable in both grammars, consumes a charge,
## and recharges only in water. The original implementation proved the charge
## economy but never moved the body. These tests close that gap and also pin the
## design intent that makes DASH the signature transition skill rather than a
## second resource counter: it is a committed burst and survives the waterline.
##
## REQ-025 remains intact: the movement profile is read from the existing tuned
## grammar burst values (roll on land, spin sprint in water); no gameplay feel
## number is introduced in code.

const TUNING_PATH := "res://core/tuning/tuning.json"


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _intent(direction: Vector3 = Vector3.ZERO,
		verbs: Array[MovementGrammar.Verb] = []) -> PlayerIntent:
	return PlayerIntent.new(direction, verbs, [] as Array[MovementGrammar.Verb])


func test_req_001_dash_on_land_is_a_real_burst_not_only_a_spent_charge() -> void:
	var tuning := _tuning()
	var controller := AxolotlController.new(tuning)
	controller.physics_step(0.016, false, _intent())
	var before := controller.get_dash().get_charges()

	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.DASH]))

	assert_int(controller.get_dash().get_charges()).is_equal(before - 1)
	assert_bool(controller.get_dash().is_active()).is_true()
	assert_float(controller.get_velocity().x).override_failure_message(
		"REQ-001 AC-5: spending DASH on land must actually drive the body"
		).is_equal_approx(tuning.get_number(AxolotlController.ROLL_SPEED_KEY), 0.001)


func test_req_001_water_dash_is_full_3d_and_uses_the_water_burst_profile() -> void:
	var tuning := _tuning()
	var controller := AxolotlController.new(tuning)
	controller.physics_step(0.016, true, _intent())
	var diagonal := Vector3(1.0, 1.0, -1.0).normalized()

	controller.physics_step(0.016, true,
		_intent(diagonal, [MovementGrammar.Verb.DASH]))

	var velocity := controller.get_velocity()
	assert_float(velocity.length()).override_failure_message(
		"the water dash must be a traversal burst, not base swim speed"
		).is_equal_approx(tuning.get_number(AxolotlController.SPIN_SPEED_KEY), 0.001)
	assert_float(velocity.normalized().dot(diagonal)).override_failure_message(
		"REQ-001 water grammar is full 3D; DASH must preserve a 3D heading"
		).is_equal_approx(1.0, 0.001)


func test_req_001_dash_commits_to_its_start_direction_until_the_window_ends() -> void:
	var controller := AxolotlController.new(_tuning())
	controller.physics_step(0.016, true, _intent())
	controller.physics_step(0.016, true,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.DASH]))
	var first := controller.get_velocity().normalized()

	# Steering hard the other way on the next frame cannot bend a committed dash.
	controller.physics_step(0.016, true, _intent(Vector3.LEFT))
	var second := controller.get_velocity().normalized()

	assert_float(first.dot(second)).override_failure_message(
		"a steerable dash is just a faster swim; the signature move must commit"
		).is_equal_approx(1.0, 0.001)


func test_req_001_dash_survives_the_water_land_transition_it_is_meant_to_bind() -> void:
	var tuning := _tuning()
	var controller := AxolotlController.new(tuning)
	controller.physics_step(0.016, true, _intent())
	controller.physics_step(0.016, true,
		_intent(Vector3.FORWARD, [MovementGrammar.Verb.DASH]))
	assert_bool(controller.get_dash().is_active()).is_true()

	# Cross the seam on the next frame. Roll/spin/boost are grammar-specific and
	# get interrupted at this boundary; DASH is explicitly the transition skill.
	controller.physics_step(0.016, false, _intent())

	assert_bool(controller.get_dash().is_active()).override_failure_message(
		"REQ-001: the transition skill must not die on the transition seam"
		).is_true()
	assert_float(Vector2(controller.get_velocity().x,
		controller.get_velocity().z).length()).is_greater(
		tuning.get_number(AxolotlController.WADDLE_SPEED_KEY))


func test_req_001_land_dash_preserves_vertical_momentum_off_a_ledge() -> void:
	var controller := AxolotlController.new(_tuning())
	controller.physics_step(0.016, false, _intent())
	controller.set_velocity(Vector3(0.0, -6.0, 0.0))

	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.DASH]))

	assert_float(controller.get_velocity().y).override_failure_message(
		"a land dash off a ledge must still fall; DASH must not become flight"
		).is_equal_approx(-6.0, 0.001)
	assert_bool(controller.get_velocity().x > 0.0).is_true()


func test_req_001_invalid_water_dash_activation_does_not_spend_a_charge() -> void:
	var dash := WaterDash.new(_tuning())
	var before := dash.get_charges()
	assert_bool(dash.try_activate(Vector3.ZERO, 10.0, 0.25)).is_false()
	assert_int(dash.get_charges()).is_equal(before)
