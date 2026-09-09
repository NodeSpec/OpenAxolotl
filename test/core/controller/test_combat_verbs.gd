extends GdUnitTestSuite

## The roll, the spin sprint and the tail whack (REQ-001, REQ-012, REQ-019).
##
## Three verbs the axolotl did not have, and two of them are also how it hits
## back. What is held here is what makes each one a VERB rather than a faster
## way of walking:
##
##   COMMITMENT.   A burst drives the direction it was started with and
##                 ignores steering until it ends. A roll you can steer is a
##                 sprint; a dodge you can steer is not a dodge.
##   A COOLDOWN.   Every one of them makes the player wait, so timing is a
##                 decision rather than a key being held.
##   A GRAMMAR.    The roll and the whack are land; the spin sprint is water.
##                 A verb used in the wrong grammar does nothing AND spends
##                 nothing — a refused verb that still burned its cooldown
##                 would read to the player as the button being broken.
##
## The strike windows are asserted through the signal the controller actually
## publishes, because the controller has no scene and no enemies in it: it
## says a swing happened and how far it reaches, and something with a scene
## decides what was inside that reach. Testing it any other way would be
## testing a different design.

const TUNING_PATH := "res://core/tuning/tuning.json"


func _tuning() -> TuningData:
	return TuningData.load_from_file(TUNING_PATH)


func _controller() -> AxolotlController:
	return AxolotlController.new(_tuning())


func _intent(direction: Vector3 = Vector3.ZERO,
		verbs: Array[MovementGrammar.Verb] = [],
		sustained: Array[MovementGrammar.Verb] = []) -> PlayerIntent:
	return PlayerIntent.new(direction, verbs, sustained)


## Every strike the controller opened, as {kind, reach}.
func _record_strikes(controller: AxolotlController) -> Array:
	var strikes: Array = []
	controller.strike_opened.connect(
		func(kind: CombatStrike.Kind, reach: float) -> void:
			strikes.append({"kind": kind, "reach": reach}))
	return strikes


# --- The grammars own their verbs -------------------------------------------

func test_req_001_each_new_verb_belongs_to_exactly_one_grammar() -> void:
	# The roll and the whack are land verbs; the spin sprint is a water verb.
	# Declared in the grammar table rather than inferred from a branch inside
	# the integrator, so this can be asked at all.
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	assert_bool(controller.supports(MovementGrammar.Verb.ROLL)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.TAIL_WHACK)).is_true()
	assert_bool(controller.supports(
		MovementGrammar.Verb.SPIN_SPRINT)).is_false()

	controller.physics_step(0.016, true, _intent())
	assert_bool(controller.supports(
		MovementGrammar.Verb.SPIN_SPRINT)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.ROLL)).is_false()
	assert_bool(controller.supports(
		MovementGrammar.Verb.TAIL_WHACK)).is_false()


# --- The roll ---------------------------------------------------------------

func test_req_001_a_roll_drives_the_direction_it_started_with() -> void:
	var tuning := _tuning()
	var speed := tuning.get_number("controller.roll.speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_bool(controller.get_roll().is_active()).is_true()
	assert_float(controller.get_velocity().x).override_failure_message(
		"a roll must move at its own tuned speed, not the waddle's"
	).is_equal_approx(speed, 0.0001)

	# AND IT IGNORES STEERING while it runs. This is the commitment: the
	# player chose a direction when they pressed, and the roll honours that
	# choice rather than the key they are holding two frames later.
	controller.physics_step(0.016, false, _intent(Vector3.LEFT))
	assert_float(controller.get_velocity().x).override_failure_message(
		"steering must not turn a roll around mid-dodge"
	).is_equal_approx(speed, 0.0001)


func test_req_001_a_roll_ends_and_then_has_to_wait() -> void:
	var tuning := _tuning()
	var duration := tuning.get_number("controller.roll.duration_s")
	var cooldown := tuning.get_number("controller.roll.cooldown_s")
	var controller := AxolotlController.new(tuning)
	var rolls: Array[bool] = []
	controller.rolled.connect(func() -> void: rolls.append(true))

	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_int(rolls.size()).is_equal(1)

	# Asked again mid-roll: refused, and no second announcement.
	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_int(rolls.size()).override_failure_message(
		"a roll cannot be extended by pressing again").is_equal(1)

	for _step: int in range(int(duration / 0.016) + 2):
		controller.physics_step(0.016, false, _intent())
	assert_bool(controller.get_roll().is_cooling()).override_failure_message(
		"a finished roll must rest before the next one").is_true()

	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_int(rolls.size()).is_equal(1)

	for _step: int in range(int(cooldown / 0.016) + 2):
		controller.physics_step(0.016, false, _intent())
	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_int(rolls.size()).override_failure_message(
		"and after the rest it must be available again").is_equal(2)


func test_req_001_a_roll_with_no_steering_goes_where_the_body_faces() -> void:
	# A burst that spent its cooldown and moved nothing would read as the
	# button being broken, so a direction is always found.
	var controller := _controller()
	for _step: int in range(60):
		controller.physics_step(0.016, false, _intent(Vector3.RIGHT))
	controller.physics_step(0.016, false,
		_intent(Vector3.ZERO, [MovementGrammar.Verb.ROLL]))
	assert_bool(controller.get_roll().is_active()).is_true()
	assert_float(controller.get_velocity().length()).is_greater(0.0)


func test_req_001_a_roll_does_not_survive_into_water() -> void:
	# Each burst belongs to one grammar; a land dodge carried into water is a
	# swim speed the water grammar never granted.
	var controller := _controller()
	controller.physics_step(0.016, false,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.ROLL]))
	assert_bool(controller.get_roll().is_active()).is_true()

	controller.physics_step(0.016, true, _intent())
	assert_bool(controller.get_roll().is_active()).override_failure_message(
		"crossing into water must end a roll").is_false()


# --- The spin sprint, which is also the water strike ------------------------

func test_req_012_a_spin_sprint_drives_and_opens_a_strike() -> void:
	var tuning := _tuning()
	var speed := tuning.get_number("controller.spin_sprint.speed_m_per_s")
	var reach := tuning.get_number("combat.spin_sprint.reach_m")
	var controller := AxolotlController.new(tuning)
	var strikes := _record_strikes(controller)

	controller.physics_step(0.016, true,
		_intent(Vector3.FORWARD, [MovementGrammar.Verb.SPIN_SPRINT]))

	assert_bool(controller.get_spin_sprint().is_active()).is_true()
	assert_float(controller.get_velocity().length()).override_failure_message(
		"the spin sprint drives at its own speed, above the swim's"
	).is_equal_approx(speed, 0.0001)
	assert_int(strikes.size()).override_failure_message(
		"the spin IS the water strike; sprinting without one would make the "
		+ "water grammar the only one that cannot hit back").is_equal(1)
	assert_int(strikes[0]["kind"]).is_equal(CombatStrike.Kind.SPIN_SPRINT)
	assert_float(strikes[0]["reach"]).is_equal_approx(reach, 0.0001)


func test_req_012_a_spin_sprint_is_refused_on_land_and_spends_nothing() -> void:
	var controller := _controller()
	var strikes := _record_strikes(controller)
	controller.physics_step(0.016, false,
		_intent(Vector3.FORWARD, [MovementGrammar.Verb.SPIN_SPRINT]))

	assert_bool(controller.get_spin_sprint().is_active()).is_false()
	assert_bool(controller.get_spin_sprint().is_ready()).override_failure_message(
		"a verb the grammar does not own must not burn its cooldown"
	).is_true()
	assert_array(strikes).is_empty()


# --- The tail whack ---------------------------------------------------------

func test_req_012_a_tail_whack_swings_without_moving_the_axolotl() -> void:
	# The whack plants its feet: it is a swing, not a lunge, and a strike that
	# also carried the player would be a second dodge wearing an attack.
	var tuning := _tuning()
	var reach := tuning.get_number("combat.tail_whack.reach_m")
	var controller := AxolotlController.new(tuning)
	var strikes := _record_strikes(controller)

	controller.set_velocity(Vector3.ZERO)
	controller.physics_step(0.016, false,
		_intent(Vector3.ZERO, [MovementGrammar.Verb.TAIL_WHACK]))

	assert_int(strikes.size()).is_equal(1)
	assert_int(strikes[0]["kind"]).is_equal(CombatStrike.Kind.TAIL_WHACK)
	assert_float(strikes[0]["reach"]).is_equal_approx(reach, 0.0001)
	assert_bool(controller.is_whacking()).is_true()
	assert_float(Vector2(controller.get_velocity().x,
		controller.get_velocity().z).length()).override_failure_message(
		"a tail whack must not move the axolotl").is_equal_approx(0.0, 0.0001)


func test_req_012_a_tail_whack_cannot_be_held_down() -> void:
	var tuning := _tuning()
	var window := tuning.get_number("combat.tail_whack.window_s")
	var cooldown := tuning.get_number("combat.tail_whack.cooldown_s")
	var controller := AxolotlController.new(tuning)
	var strikes := _record_strikes(controller)

	# Pressed every frame for the whole window and the whole rest: exactly one
	# swing may come out of it.
	for _step: int in range(int((window + cooldown) / 0.016)):
		controller.physics_step(0.016, false,
			_intent(Vector3.ZERO, [MovementGrammar.Verb.TAIL_WHACK]))
	assert_int(strikes.size()).override_failure_message(
		"a held button must not be a stream of strikes").is_equal(1)

	# And once the rest is over, a second swing is available.
	for _step: int in range(int((window + cooldown) / 0.016) + 4):
		controller.physics_step(0.016, false, _intent())
	controller.physics_step(0.016, false,
		_intent(Vector3.ZERO, [MovementGrammar.Verb.TAIL_WHACK]))
	assert_int(strikes.size()).is_equal(2)


func test_req_012_a_tail_whack_is_refused_underwater() -> void:
	var controller := _controller()
	var strikes := _record_strikes(controller)
	controller.physics_step(0.016, true,
		_intent(Vector3.ZERO, [MovementGrammar.Verb.TAIL_WHACK]))
	assert_array(strikes).override_failure_message(
		"the land strike must not swing underwater").is_empty()
	assert_bool(controller.is_whacking()).is_false()


# --- The stomp bounce -------------------------------------------------------

func test_req_012_a_stomp_bounces_the_same_height_however_far_you_fell() -> void:
	# The bounce is a reward for landing the hit, not a payout scaled by how
	# badly the drop was misjudged — and it stays below the hop impulse, or
	# machines would be the best way up.
	var tuning := _tuning()
	var bounce := tuning.get_number("combat.stomp.bounce_m_per_s")
	var controller := AxolotlController.new(tuning)

	for fall_speed: float in [-2.0, -14.0, -30.0]:
		controller.set_velocity(Vector3(0.0, fall_speed, 0.0))
		controller.apply_stomp_bounce()
		assert_float(controller.get_velocity().y).override_failure_message(
			"a stomp from %.0f m/s must bounce the tuned amount" % fall_speed
		).is_equal_approx(bounce, 0.0001)

	assert_float(bounce).override_failure_message(
		"the bounce must stay below the hop, or enemies become a staircase"
	).is_less(tuning.get_number("controller.hop.impulse_m_per_s"))


func test_req_012_the_strike_kinds_are_bound_to_their_grammars() -> void:
	# The table the controller gates on, asserted directly so a new strike
	# cannot be added without deciding where it is usable.
	assert_bool(CombatStrike.allowed_in(CombatStrike.Kind.TAIL_WHACK,
		MovementGrammar.Grammar.LAND)).is_true()
	assert_bool(CombatStrike.allowed_in(CombatStrike.Kind.STOMP,
		MovementGrammar.Grammar.LAND)).is_true()
	assert_bool(CombatStrike.allowed_in(CombatStrike.Kind.SPIN_SPRINT,
		MovementGrammar.Grammar.WATER)).is_true()
	assert_bool(CombatStrike.allowed_in(CombatStrike.Kind.SPIN_SPRINT,
		MovementGrammar.Grammar.LAND)).is_false()
	assert_bool(CombatStrike.allowed_in(CombatStrike.Kind.TAIL_WHACK,
		MovementGrammar.Grammar.WATER)).is_false()
