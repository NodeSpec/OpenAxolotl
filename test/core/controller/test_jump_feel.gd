extends GdUnitTestSuite

## The jump forgiveness rules (REQ-037).
##
## These are pure arithmetic over time, so every window is asserted frame by
## frame with no scene, no physics server and no floor — which is the point of
## keeping the timers in JumpFeel rather than in the controller.
##
## The final two tests drive the REAL controller, because a forgiveness rule
## that works in isolation and never reaches the impulse is worth nothing.

const STEP := 1.0 / 60.0


func _tuning() -> TuningData:
	return TuningData.load_from_file("res://core/tuning/tuning.json")


func _feel() -> JumpFeel:
	return JumpFeel.new(_tuning())


func _controller() -> AxolotlController:
	return AxolotlController.new(_tuning())


func _intent(verbs: Array[MovementGrammar.Verb] = [],
		sustained: Array[MovementGrammar.Verb] = []) -> PlayerIntent:
	return PlayerIntent.new(Vector3.ZERO, verbs, sustained)


func _hop() -> Array[MovementGrammar.Verb]:
	return [MovementGrammar.Verb.HOP] as Array[MovementGrammar.Verb]


func test_req_037_coyote_time_forgives_a_press_just_after_the_ledge() -> void:
	var feel := _feel()
	# Standing, then the ground goes away without a hop — walked off a ledge.
	feel.step(STEP, true, false)
	assert_float(feel.get_coyote_remaining()).is_greater(0.0)

	feel.step(STEP, false, false)
	assert_bool(feel.should_hop(false, true)).override_failure_message(
		"a press just after the ledge must still hop").is_true()


func test_req_037_the_coyote_window_expires() -> void:
	# Forgiveness is a WINDOW, not a free mid-air jump: past it, nothing.
	var feel := _feel()
	feel.step(STEP, true, false)
	for _i: int in 60:
		feel.step(STEP, false, false)
	assert_float(feel.get_coyote_remaining()).is_equal_approx(0.0, 0.0001)
	assert_bool(feel.should_hop(false, true)).override_failure_message(
		"a whole second later is not a ledge, it is mid-air").is_false()


func test_req_037_a_hop_spends_the_coyote_window() -> void:
	# Otherwise the window that authorised the jump would authorise a second
	# one on the way up, which is a double jump nobody asked for.
	var feel := _feel()
	feel.step(STEP, true, false)
	assert_bool(feel.should_hop(true, true)).is_true()
	feel.consume()
	feel.step(STEP, false, false)
	assert_bool(feel.should_hop(false, true)).override_failure_message(
		"the spent window must not authorise a second hop").is_false()


func test_req_037_a_press_in_mid_air_is_buffered_until_landing() -> void:
	var feel := _feel()
	# Falling, and the player presses early.
	feel.step(STEP, false, true)
	assert_float(feel.get_buffer_remaining()).is_greater(0.0)
	# Still falling, button released.
	feel.step(STEP, false, false)
	# Now they land, asking for nothing this frame.
	assert_bool(feel.should_hop(true, false)).override_failure_message(
		"the buffered press must fire on touchdown").is_true()


func test_req_037_the_buffer_expires_rather_than_firing_late() -> void:
	var feel := _feel()
	feel.step(STEP, false, true)
	for _i: int in 60:
		feel.step(STEP, false, false)
	assert_float(feel.get_buffer_remaining()).is_equal_approx(0.0, 0.0001)
	assert_bool(feel.should_hop(true, false)).override_failure_message(
		"a press a second ago must not fire on landing"
		).is_false()


func test_req_037_holding_the_button_does_not_refill_the_buffer() -> void:
	# Remembered on the RISING edge only. A player who never lets go would
	# otherwise hop again the instant they touched anything, forever.
	var feel := _feel()
	feel.step(STEP, false, true)
	var after_press := feel.get_buffer_remaining()
	for _i: int in 30:
		feel.step(STEP, false, true)
	assert_float(feel.get_buffer_remaining()).override_failure_message(
		"a held button must not keep topping the buffer up"
		).is_less(after_press)


func test_req_037_releasing_mid_climb_cuts_the_rise() -> void:
	var feel := _feel()
	feel.step(STEP, true, true)
	feel.consume()
	# Rising, button released.
	assert_float(feel.cut_rise(9.0, false)).override_failure_message(
		"releasing must cut the climb").is_less(9.0)
	# Rising, button still held: the full jump is the player's to keep.
	assert_float(feel.cut_rise(9.0, true)).is_equal_approx(9.0, 0.0001)


func test_req_037_the_cut_never_touches_a_fall_or_an_unowned_rise() -> void:
	var feel := _feel()
	feel.step(STEP, true, true)
	feel.consume()
	# Cutting a descent would be a mid-air brake.
	assert_float(feel.cut_rise(-9.0, false)).is_equal_approx(-9.0, 0.0001)

	# A rise this jump does not own — a launcher, a boost — is not the
	# player's button to cut.
	var other := _feel()
	assert_float(other.cut_rise(9.0, false)).override_failure_message(
		"only a rise this hop started may be cut").is_equal_approx(9.0, 0.0001)


func test_req_037_the_controller_hops_from_a_buffered_press_on_landing() -> void:
	# Through the REAL controller: the rule has to reach the impulse.
	var controller := _controller()
	controller.set_grounded(false)
	controller.physics_step(STEP, false, _intent(_hop()))
	controller.physics_step(STEP, false, _intent())
	assert_float(controller.get_velocity().y).override_failure_message(
		"the press was made in mid-air and must not hop there").is_less_equal(0.0)

	controller.set_grounded(true)
	controller.physics_step(STEP, false, _intent())
	assert_float(controller.get_velocity().y).override_failure_message(
		"landing must cash in the buffered press").is_greater(1.0)


func test_req_037_the_controller_gives_a_released_jump_less_height() -> void:
	# The whole point of variable height: one button, a range of arcs.
	# The press frame is identical for both. What differs is only whether the
	# button is still down on the NEXT frame, which is the sustained set.
	var held := _controller()
	held.set_grounded(true)
	held.physics_step(STEP, false, _intent(_hop(), _hop()))
	held.physics_step(STEP, false, _intent([], _hop()))
	var held_rise := held.get_velocity().y

	var tapped := _controller()
	tapped.set_grounded(true)
	tapped.physics_step(STEP, false, _intent(_hop(), _hop()))
	tapped.physics_step(STEP, false, _intent())
	var tapped_rise := tapped.get_velocity().y

	assert_float(tapped_rise).override_failure_message(
		"a tapped jump must rise less than a held one").is_less(held_rise)
	assert_float(tapped_rise).override_failure_message(
		"a tapped jump must still leave the ground").is_greater(0.0)
