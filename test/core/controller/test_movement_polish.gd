extends GdUnitTestSuite
func tuning() -> TuningData:
	return TuningData.load_from_file("res://core/tuning/tuning.json")
func simulate(controller: AxolotlController, seconds: float, hz: int, water: bool, direction: Vector3) -> void:
	for i in roundi(seconds * hz): controller.physics_step(1.0 / hz, water, PlayerIntent.new(direction))
func test_motion_starts_immediately_but_builds_to_speed_on_land_and_in_water() -> void:
	for water: bool in [false,true]:
		var c := AxolotlController.new(tuning())
		c.physics_step(1.0/60, water, PlayerIntent.new(Vector3.FORWARD))
		var first := c.get_velocity().length()
		assert_float(first).is_greater(0.0)
		assert_float(first).is_less(1.0)
		simulate(c,0.5,60,water,Vector3.FORWARD)
		assert_float(c.get_velocity().length()).is_greater(first * 4.0)
func test_acceleration_is_consistent_at_30_60_and_120_hz() -> void:
	for water: bool in [false,true]:
		var speeds: Array[float] = []
		for hz: int in [30,60,120]:
			var c := AxolotlController.new(tuning())
			simulate(c,0.1,hz,water,Vector3.FORWARD)
			speeds.append(c.get_velocity().length())
		assert_float(speeds[0]).is_equal_approx(speeds[1],0.001)
		assert_float(speeds[1]).is_equal_approx(speeds[2],0.001)
func test_reversal_brakes_without_a_one_frame_velocity_flip() -> void:
	var c := AxolotlController.new(tuning())
	simulate(c,0.5,60,false,Vector3.RIGHT)
	c.physics_step(1.0/60,false,PlayerIntent.new(Vector3.LEFT))
	assert_float(c.get_velocity().x).is_greater(0.0)
	simulate(c,0.3,60,false,Vector3.LEFT)
	assert_float(c.get_velocity().x).is_less(-4.0)
func test_analog_deflection_survives_input_and_controller() -> void:
	var input := InputSystem.new(BindingTable.load_from_file(BindingTable.DEFAULTS_PATH))
	input.set_grammar(MovementGrammar.Grammar.LAND)
	var event := InputEventJoypadMotion.new(); event.axis = JOY_AXIS_LEFT_X; event.axis_value = 0.59
	input.handle_event(event)
	var direction := input.poll_intent().direction
	assert_float(direction.length()).is_equal_approx(0.5,0.001)
	var c := AxolotlController.new(tuning())
	simulate(c,0.5,60,false,direction)
	assert_float(c.get_velocity().length()).is_equal_approx(2.1,0.001)
	event.axis_value = 0.1; input.handle_event(event)
	assert_float(input.poll_intent().direction.length()).is_equal_approx(0.0,0.001)
func test_jump_release_cuts_once_then_leaves_gravity_in_control() -> void:
	var jump := JumpFeel.new(tuning()); jump.consume()
	var cut := jump.cut_rise(9.0,false)
	assert_float(cut).is_less(9.0)
	for i in 30: assert_float(jump.cut_rise(cut,false)).is_equal_approx(cut,0.0001)
	jump.consume()
	assert_float(jump.cut_rise(9.0,false)).is_equal_approx(cut,0.0001)
func test_suit_mount_does_not_replace_the_existing_character_or_collision() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	assert_object(body.get_suit_mount()).is_not_null()
	assert_int(body.get_suit_mount().get_child_count()).is_equal(0)
	assert_float((body.get_node("Collision").shape as CapsuleShape3D).radius).is_equal_approx(0.5,0.001)
	body.free()
func test_swim_turn_builds_angular_speed_instead_of_snapping() -> void:
	var motion := HeroMotion.new(); motion.reset_pose(0.0)
	motion.prepare(1.0/60,true,false,Vector3.RIGHT*6,PI/2,0,Vector3.UP)
	var first := motion.visual_rotation.y
	assert_float(first).is_greater(0.0)
	assert_float(first).is_less(deg_to_rad(1.0))
	motion.prepare(1.0/60,true,false,Vector3.RIGHT*6,PI/2,0,Vector3.UP)
	assert_float(motion.visual_rotation.y-first).is_greater(first)
	motion.free()
func test_swim_turn_settles_without_overshoot_and_limits_neck_twist() -> void:
	var motion := HeroMotion.new(); motion.reset_pose(0.0)
	var previous := 0.0
	for i in 180:
		motion.prepare(1.0/60,true,false,Vector3.RIGHT*6,PI/2,0,Vector3.UP)
		assert_float(motion.visual_rotation.y).is_less(PI/2+0.001)
		assert_float(absf(motion.visual_rotation.y-previous)).is_less(deg_to_rad(4.01))
		assert_float(absf(motion._head_lead)).is_less(0.551)
		previous=motion.visual_rotation.y
	assert_float(motion.visual_rotation.y).is_equal_approx(PI/2,0.005)
	assert_float(absf(motion.bank)).is_less(0.01)
	motion.free()
func test_respawn_clears_swim_turn_momentum() -> void:
	var motion := HeroMotion.new(); motion.reset_pose(0.0)
	for i in 20:motion.prepare(1.0/60,true,false,Vector3.RIGHT*6,PI/2,0,Vector3.UP)
	motion.reset_pose(0.0)
	motion.prepare(1.0/60,true,false,Vector3.ZERO,0.0,0,Vector3.UP)
	assert_float(motion.visual_rotation.y).is_equal_approx(0.0,0.0001)
	assert_float(motion.bank).is_equal_approx(0.0,0.0001)
	motion.free()
