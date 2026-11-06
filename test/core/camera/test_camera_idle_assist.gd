extends GdUnitTestSuite

func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	return TuningData.load_from_file("res://core/tuning/tuning.json", errors)


func test_sustained_strafe_and_backward_motion_never_turn_camera() -> void:
	for travel: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var assist := CameraIdleAssist.new(_tuning())
		var yaw := 0.0
		for tick: int in range(300):
			yaw = assist.step(1.0 / 60.0, yaw, travel, false)
		assert_float(yaw).is_equal_approx(0.0, 0.00001)


func test_idle_waits_then_turns_toward_remembered_heading() -> void:
	var tuning := _tuning()
	var assist := CameraIdleAssist.new(tuning)
	assist.step(0.1, 0.0, Vector3.RIGHT, false)
	var delay := tuning.get_number(LookInput.ASSIST_DELAY_KEY)
	assert_float(assist.step(delay, 0.0, Vector3.ZERO, false)).is_equal_approx(0.0, 0.00001)
	var yaw := assist.step(0.1, 0.0, Vector3.ZERO, false)
	assert_float(yaw).is_equal_approx(-tuning.get_number(LookInput.ASSIST_SPEED_KEY) * 0.1, 0.00001)


func test_manual_look_restarts_the_full_idle_delay() -> void:
	var tuning := _tuning()
	var assist := CameraIdleAssist.new(tuning)
	var delay := tuning.get_number(LookInput.ASSIST_DELAY_KEY)
	assist.step(0.1, 0.0, Vector3.RIGHT, false)
	assist.step(delay, 0.0, Vector3.ZERO, false)
	assert_float(assist.step(0.1, 20.0, Vector3.ZERO, true)).is_equal_approx(20.0, 0.00001)
	assert_float(assist.step(delay, 20.0, Vector3.ZERO, false)).is_equal_approx(20.0, 0.00001)


func test_starting_stationary_never_invents_a_heading() -> void:
	var assist := CameraIdleAssist.new(_tuning())
	assert_float(assist.step(10.0, 42.0, Vector3.ZERO, false)).is_equal_approx(42.0, 0.00001)


func test_delay_boundary_is_independent_of_step_size() -> void:
	var fine := CameraIdleAssist.new(_tuning())
	var coarse := CameraIdleAssist.new(_tuning())
	fine.step(0.1, 0.0, Vector3.RIGHT, false)
	coarse.step(0.1, 0.0, Vector3.RIGHT, false)
	var fine_yaw := 0.0
	for tick: int in range(120):
		fine_yaw = fine.step(1.0 / 60.0, fine_yaw, Vector3.ZERO, false)
	var coarse_yaw := coarse.step(2.0, 0.0, Vector3.ZERO, false)
	assert_float(fine_yaw).is_equal_approx(coarse_yaw, 0.00001)


func test_idle_turn_takes_shortest_arc_and_does_not_overshoot() -> void:
	var assist := CameraIdleAssist.new(_tuning())
	var travel := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(-179.0))
	assist.step(0.1, 179.0, travel, false)
	assert_float(assist.step(10.0, 179.0, Vector3.ZERO, false)).is_equal_approx(-179.0, 0.00001)


func test_follow_camera_uses_idle_assist_after_manual_look() -> void:
	var source := FileAccess.get_file_as_string("res://core/camera/camera_follow.gd")
	assert_str(source).contains("_idle_assist.step(delta, _yaw_deg, travel, not look.is_zero_approx(), steering)")
	assert_bool(source.contains("func _assist(delta:")).is_false()


func test_steering_into_a_wall_still_blocks_idle_turning() -> void:
	var assist := CameraIdleAssist.new(_tuning())
	assist.step(0.1, 0.0, Vector3.RIGHT, false)
	assert_float(assist.step(10.0, 0.0, Vector3.ZERO, false, true)).is_equal_approx(0.0, 0.00001)


func test_explicit_camera_reset_forgets_previous_travel_heading() -> void:
	var assist := CameraIdleAssist.new(_tuning())
	assist.step(0.1, 0.0, Vector3.RIGHT, false)
	assist.reset(true)
	assert_float(assist.step(10.0, 42.0, Vector3.ZERO, false)).is_equal_approx(42.0, 0.00001)


func test_zero_assist_speed_disables_turning() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://core/tuning/tuning.json"))
	raw["values"][LookInput.ASSIST_SPEED_KEY]["value"] = 0.0
	var errors: Array[TuningError] = []
	var assist := CameraIdleAssist.new(TuningData._from_dictionary(raw, errors))
	assist.step(0.1, 0.0, Vector3.RIGHT, false)
	assert_float(assist.step(10.0, 42.0, Vector3.ZERO, false)).is_equal_approx(42.0, 0.00001)


func test_teleport_seams_clear_remembered_camera_heading() -> void:
	for path: String in ["res://hub/open_lagoon.gd", "res://hub/world_systems.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_str(source).contains("camera.set_yaw_deg(camera.get_yaw_deg())")
