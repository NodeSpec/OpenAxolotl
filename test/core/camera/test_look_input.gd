extends GdUnitTestSuite

## The player's camera-look axis (REQ-005, REQ-024).
##
## LookInput deliberately holds no camera, no Input singleton and no node —
## samples are pushed in and degrees drained out — which is exactly what lets
## this suite prove the whole axis without a window, a mouse or a gamepad.

const TUNING := "res://core/tuning/tuning.json"


func _look() -> LookInput:
	var errors: Array[TuningError] = []
	var tuning := TuningData.load_from_file(TUNING, errors)
	assert_int(errors.size()).is_equal(0)
	return LookInput.new(tuning)


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	return TuningData.load_from_file(TUNING, errors)


func test_req_005_mouse_motion_turns_the_view_the_way_the_hand_moved() -> void:
	# The sign is the whole usability of a look axis and it is easy to get
	# backwards: moving the mouse RIGHT must turn the view right, which in
	# Godot's left-handed yaw is a NEGATIVE yaw delta.
	var look := _look()
	look.add_mouse(Vector2(10.0, 0.0))
	var right := look.drain()
	assert_bool(right.x < 0.0).override_failure_message(
		"moving the mouse right must turn the view right (negative yaw); "
		+ "got %.3f" % right.x).is_true()

	look.add_mouse(Vector2(-10.0, 0.0))
	assert_bool(look.drain().x > 0.0).is_true()

	# And down must look down, which is also negative pitch here: the rig's
	# pitch is the angle the camera sits ABOVE the axolotl, so less of it is
	# a lower view.
	look.add_mouse(Vector2(0.0, 10.0))
	assert_bool(look.drain().y < 0.0).override_failure_message(
		"pushing the mouse down must lower the view").is_true()


func test_req_005_sensitivity_is_per_pixel_so_a_flick_is_frame_rate_free() -> void:
	# One 100-pixel event and ten 10-pixel ones must come to the same angle.
	# If they did not, a fast flick would turn further on a machine that
	# happened to deliver more motion events.
	var single := _look()
	single.add_mouse(Vector2(100.0, 0.0))
	var once := single.drain()

	var many := _look()
	for step: int in 10:
		many.add_mouse(Vector2(10.0, 0.0))
	var split := many.drain()

	assert_float(split.x).override_failure_message(
		"accumulating motion must be linear, or a flick means different "
		+ "things at different event rates").is_equal_approx(once.x, 0.0001)


func test_req_005_motion_accumulates_between_drains() -> void:
	# Mouse motion arrives on the INPUT timeline; the camera settles on the
	# PHYSICS one. Several events land between two physics frames, and a
	# camera that saw only the last would drop most of a fast flick.
	var look := _look()
	look.add_mouse(Vector2(5.0, 0.0))
	look.add_mouse(Vector2(5.0, 0.0))
	assert_bool(look.has_pending()).is_true()

	var first := look.drain()
	var reference := _look()
	reference.add_mouse(Vector2(10.0, 0.0))
	assert_float(first.x).is_equal_approx(reference.drain().x, 0.0001)

	# Drained means drained: a second read must not re-apply the same motion.
	assert_bool(look.drain().is_zero_approx()).is_true()
	assert_bool(look.has_pending()).is_false()


func test_req_005_the_stick_deadzone_is_on_the_vector_not_the_axes() -> void:
	# A diagonal push must not have to clear the threshold on BOTH axes. Held
	# at 45 degrees just past the deadzone, each axis alone is under it while
	# the vector is over — per-axis testing would ignore the input entirely.
	var deadzone := _tuning().get_number(LookInput.STICK_DEADZONE_KEY)
	var magnitude := deadzone + 0.06
	var diagonal := Vector2(1.0, 1.0).normalized() * magnitude
	assert_bool(absf(diagonal.x) < deadzone).override_failure_message(
		"the fixture must actually put each axis under the deadzone, or this "
		+ "test proves nothing").is_true()

	var look := _look()
	look.add_stick(diagonal, 0.1)
	assert_bool(look.has_pending()).override_failure_message(
		"a diagonal push past the deadzone must register").is_true()

	# And under it, nothing: a resting stick must not drift the view.
	var resting := _look()
	resting.add_stick(Vector2(deadzone * 0.5, 0.0), 0.1)
	assert_bool(resting.has_pending()).override_failure_message(
		"a stick inside the deadzone must not creep the camera").is_false()


func test_req_005_the_stick_turns_at_a_rate_not_a_displacement() -> void:
	# Held over, a stick keeps turning; that is what a stick means. So twice
	# the elapsed time must be twice the angle.
	var short_hold := _look()
	short_hold.add_stick(Vector2(1.0, 0.0), 0.1)
	var short_yaw: float = absf(short_hold.drain().x)

	var long_hold := _look()
	long_hold.add_stick(Vector2(1.0, 0.0), 0.2)
	var long_yaw: float = absf(long_hold.drain().x)

	assert_float(long_yaw).override_failure_message(
		"stick look must be rate-based: %.3f over 0.2 s against %.3f over "
		% [long_yaw, short_yaw] + "0.1 s").is_equal_approx(
		short_yaw * 2.0, 0.001)


func test_req_005_pitch_is_clamped_where_the_view_stays_useful() -> void:
	var look := _look()
	var tuning := _tuning()
	var low := tuning.get_number(LookInput.MIN_PITCH_KEY)
	var high := tuning.get_number(LookInput.MAX_PITCH_KEY)

	assert_float(look.clamp_pitch(high + 40.0)).is_equal_approx(high, 0.0001)
	assert_float(look.clamp_pitch(low - 40.0)).is_equal_approx(low, 0.0001)
	assert_float(look.clamp_pitch(0.0)).is_equal_approx(0.0, 0.0001)

	# The range must leave the player able to look DOWN at a drop, which is
	# the single most useful thing a look axis buys a platformer.
	assert_bool(high >= 45.0).override_failure_message(
		"the player has to be able to look down at a landing; max pitch is "
		+ "only %.1f degrees" % high).is_true()
