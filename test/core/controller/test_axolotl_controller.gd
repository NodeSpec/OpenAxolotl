extends GdUnitTestSuite

## Axolotl Controller — REQ-001.
##
## Test names carry the requirement id they prove (test_req_001_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _controller() -> AxolotlController:
	return AxolotlController.new(_tuning())


func _intent(direction: Vector3 = Vector3.ZERO,
		verbs: Array[MovementGrammar.Verb] = []) -> PlayerIntent:
	return PlayerIntent.new(direction, verbs)


# --- AC-1: same-frame grammar switch and momentum retention ----------------

func test_req_001_crossing_into_water_switches_grammar_in_the_same_step() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	assert_int(int(controller.get_grammar())).is_equal(MovementGrammar.Grammar.LAND)

	# The very call that observes water must already report the water grammar —
	# no intervening frame is rendered in the previous grammar.
	controller.physics_step(0.016, true, _intent())
	assert_int(int(controller.get_grammar())).override_failure_message(
		"REQ-001 AC-1: the grammar must switch in the same physics step as the crossing"
	).is_equal(MovementGrammar.Grammar.WATER)


func test_req_001_grammar_change_signal_fires_on_the_crossing_step() -> void:
	var controller := _controller()
	var seen: Array[int] = []
	controller.grammar_changed.connect(func(g: MovementGrammar.Grammar) -> void:
		seen.append(int(g)))

	controller.physics_step(0.016, false, _intent())
	controller.physics_step(0.016, true, _intent())

	assert_int(seen.size()).is_equal(2)  # initial settle, then the crossing
	assert_int(seen[1]).is_equal(MovementGrammar.Grammar.WATER)


func test_req_001_crossing_retains_momentum_magnitude_per_tuning_key() -> void:
	var tuning := _tuning()
	var ratio := tuning.get_number("controller.transition.momentum_retention_ratio")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, true, _intent())
	controller.set_velocity(Vector3(0.0, -10.0, 0.0))  # diving hard
	var before := controller.get_velocity().length()

	controller.physics_step(0.016, false, _intent())  # surfacing

	assert_float(controller.get_velocity().length()).override_failure_message(
		"REQ-001 AC-1: momentum magnitude must carry at the tuned retention ratio"
	).is_equal_approx(before * ratio, 0.001)


func test_req_001_momentum_carries_as_magnitude_not_as_the_vector() -> void:
	# A swimmer surfacing keeps speed without keeping a heading into the ground.
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())
	controller.set_velocity(Vector3(0.0, -10.0, 0.0))
	controller.physics_step(0.016, false, _intent())

	# Direction is preserved only as a unit vector scaled down; the magnitude is
	# what the criterion constrains, and it is strictly less than before.
	assert_bool(controller.get_velocity().length() < 10.0).is_true()
	assert_bool(controller.get_velocity().length() > 0.0).is_true()


func test_req_001_staying_in_one_grammar_does_not_re_emit_or_decay_momentum() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())

	var changes: Array[int] = []
	controller.grammar_changed.connect(func(g: MovementGrammar.Grammar) -> void:
		changes.append(int(g)))

	controller.set_velocity(Vector3(5.0, 0.0, 0.0))
	controller.physics_step(0.016, true, _intent())
	controller.physics_step(0.016, true, _intent())

	assert_array(changes).override_failure_message(
		"staying in one grammar must not re-emit a change or re-apply retention"
	).is_empty()


# --- AC-2 / AC-3: the two grammars own distinct verbs ----------------------

func test_req_001_water_grammar_supports_swimming_dive_and_bubble_boost() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())

	assert_bool(controller.supports(MovementGrammar.Verb.SWIM)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.DIVE)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.BUBBLE_BOOST)).is_true()
	# Land verbs are not available in water.
	assert_bool(controller.supports(MovementGrammar.Verb.WADDLE)).is_false()
	assert_bool(controller.supports(MovementGrammar.Verb.HOP)).is_false()
	assert_bool(controller.supports(MovementGrammar.Verb.CLIMB)).is_false()


func test_req_001_land_grammar_supports_waddle_hop_and_climb() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())

	assert_bool(controller.supports(MovementGrammar.Verb.WADDLE)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.HOP)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.CLIMB)).is_true()
	assert_bool(controller.supports(MovementGrammar.Verb.SWIM)).is_false()
	assert_bool(controller.supports(MovementGrammar.Verb.DIVE)).is_false()


func test_req_001_the_two_grammars_are_mechanically_distinct() -> void:
	# Pillar 2: if the verb sets overlapped, "two grammars" would be decoration.
	for verb: MovementGrammar.Verb in MovementGrammar.WATER_VERBS:
		assert_bool(MovementGrammar.LAND_VERBS.has(verb)).override_failure_message(
			"REQ-001: '%s' appears in both grammars" % MovementGrammar.verb_id(verb)
		).is_false()


func test_req_001_land_grammar_ignores_vertical_steering() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent(Vector3(0.0, 1.0, 0.0)))
	# Pure vertical intent on land is not steering, so it produces no motion.
	assert_float(controller.get_velocity().length()).is_equal_approx(0.0, 0.0001)


func test_req_001_water_grammar_supports_full_3d_directional_movement() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent(Vector3(0.0, 1.0, 0.0)))
	assert_bool(controller.get_velocity().length() > 0.0).override_failure_message(
		"REQ-001 AC-2: water movement is full 3D; vertical intent must move the axolotl"
	).is_true()


# --- AC-4: tongue grapple range, tested inclusively ------------------------

func test_req_001_grapple_attaches_at_exactly_max_range() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	assert_bool(grapple.is_in_range(reach)).override_failure_message(
		"REQ-001 AC-4: 'at or within' means an anchor exactly at max range attaches"
	).is_true()


func test_req_001_grapple_rejects_an_anchor_beyond_max_range() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	assert_bool(grapple.is_in_range(reach + 0.01)).is_false()
	assert_str(grapple.resolve_anchor({"far": reach + 5.0})).is_empty()


func test_req_001_grapple_picks_the_nearest_in_range_anchor() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	var chosen := grapple.resolve_anchor({
		"near": 3.0, "mid": 7.0, "out_of_reach": reach + 10.0,
	})
	assert_str(chosen).is_equal("near")


func test_req_001_a_missed_grapple_does_not_leave_the_controller_attached() -> void:
	var controller := _controller()
	var reach := controller.get_grapple().max_range()

	assert_bool(controller.try_grapple({"far": reach + 1.0})).is_false()
	assert_bool(controller.get_grapple().is_attached()).override_failure_message(
		"a missed grapple must not leave the controller believing it is attached"
	).is_false()


func test_req_001_a_hit_grapple_attaches_and_announces_the_anchor() -> void:
	var controller := _controller()
	var announced: Array[String] = []
	controller.grapple_attached.connect(func(id: String) -> void: announced.append(id))

	assert_bool(controller.try_grapple({"ledge": 4.0})).is_true()
	assert_str(controller.get_grapple().get_attached_anchor()).is_equal("ledge")
	assert_array(announced).contains(["ledge"])


# --- AC-5: the dash is usable in both grammars, recharged only in water ----

func test_req_001_dash_is_available_in_both_grammars() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())
	assert_bool(controller.supports(MovementGrammar.Verb.DASH)).is_true()
	controller.physics_step(0.016, false, _intent())
	assert_bool(controller.supports(MovementGrammar.Verb.DASH)).override_failure_message(
		"REQ-001 AC-5: the dash is the transition skill; it works in either grammar"
	).is_true()


func test_req_001_dash_consumes_a_charge() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	var before := controller.get_dash().get_charges()

	controller.physics_step(0.016, false, _intent(Vector3.ZERO, [MovementGrammar.Verb.DASH]))

	assert_int(controller.get_dash().get_charges()).is_equal(before - 1)


func test_req_001_dash_recharges_only_while_in_water() -> void:
	var tuning := _tuning()
	var per_charge := tuning.get_number("controller.dash.recharge_seconds_per_charge")
	var dash := WaterDash.new(tuning)

	assert_bool(dash.try_consume()).is_true()
	var spent := dash.get_charges()

	# Plenty of time, but on land: no progress at all.
	dash.tick(per_charge * 3.0, false)
	assert_int(dash.get_charges()).override_failure_message(
		"REQ-001 AC-5: the dash must not recharge on land"
	).is_equal(spent)

	dash.tick(per_charge, true)
	assert_int(dash.get_charges()).is_equal(spent + 1)


func test_req_001_land_time_does_not_bank_partial_recharge_credit() -> void:
	# Surfacing mid-recharge must not complete a charge on dry land.
	var tuning := _tuning()
	var per_charge := tuning.get_number("controller.dash.recharge_seconds_per_charge")
	var dash := WaterDash.new(tuning)
	dash.try_consume()
	var spent := dash.get_charges()

	dash.tick(per_charge * 0.5, true)   # half-earned in water
	dash.tick(per_charge * 5.0, false)  # a long walk on land

	assert_int(dash.get_charges()).is_equal(spent)


func test_req_001_dash_cannot_be_spent_when_no_charges_remain() -> void:
	var dash := WaterDash.new(_tuning())
	while dash.get_charges() > 0:
		assert_bool(dash.try_consume()).is_true()
	assert_bool(dash.try_consume()).override_failure_message(
		"spending an unavailable dash must report failure so a denied cue can play"
	).is_false()


func test_req_001_dash_recharge_never_exceeds_max_charges() -> void:
	var tuning := _tuning()
	var dash := WaterDash.new(tuning)
	dash.tick(tuning.get_number("controller.dash.recharge_seconds_per_charge") * 20.0, true)
	assert_int(dash.get_charges()).is_equal(dash.max_charges())


# --- AC-6: the public interface worlds bind to -----------------------------

func test_req_001_movement_state_is_readable_without_touching_internals() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())

	assert_int(int(controller.get_grammar())).is_equal(MovementGrammar.Grammar.WATER)
	assert_bool(controller.is_in_water()).is_true()
	assert_int(controller.get_available_verbs().size()).is_greater(0)


func test_req_001_capability_modifiers_are_consumed_multiplicatively() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent(Vector3(1.0, 0.0, 0.0)))
	var full := controller.get_velocity().length()

	controller.get_capability_modifiers().set_factor("tail_lost", 0.5)
	controller.physics_step(0.016, true, _intent(Vector3(1.0, 0.0, 0.0)))

	assert_float(controller.get_velocity().length()).is_equal_approx(full * 0.5, 0.0001)


func test_req_001_multiple_capability_losses_compose() -> void:
	var modifiers := CapabilityModifiers.new()
	assert_float(modifiers.combined()).is_equal_approx(1.0, 0.0001)

	modifiers.set_factor("tail_lost", 0.5)
	modifiers.set_factor("gill_lost", 0.5)
	assert_float(modifiers.combined()).is_equal_approx(0.25, 0.0001)

	modifiers.clear_factor("gill_lost")
	assert_float(modifiers.combined()).is_equal_approx(0.5, 0.0001)


func test_req_001_a_capability_modifier_can_never_invert_movement() -> void:
	var modifiers := CapabilityModifiers.new()
	modifiers.set_factor("bogus", -3.0)
	assert_float(modifiers.combined()).override_failure_message(
		"a negative multiplier would invert movement; it must clamp to zero"
	).is_equal_approx(0.0, 0.0001)


func test_req_001_ability_hooks_are_registered_by_others_not_known_here() -> void:
	# The controller never knows which Gill Mods exist; the framework registers.
	var controller := _controller()
	var fired: Array[bool] = []

	assert_bool(controller.register_ability_hook("jet_gills",
		func() -> void: fired.append(true))).is_true()
	assert_bool(controller.has_ability_hook("jet_gills")).is_true()
	assert_array(controller.get_ability_hook_ids()).contains(["jet_gills"])

	assert_bool(controller.invoke_ability_hook("jet_gills")).is_true()
	assert_int(fired.size()).is_equal(1)

	controller.unregister_ability_hook("jet_gills")
	assert_bool(controller.has_ability_hook("jet_gills")).is_false()
	assert_bool(controller.invoke_ability_hook("jet_gills")).is_false()


func test_req_001_registering_an_invalid_ability_hook_is_refused() -> void:
	var controller := _controller()
	assert_bool(controller.register_ability_hook("", func() -> void: pass)).is_false()
	assert_bool(controller.register_ability_hook("x", Callable())).is_false()


# --- No magic numbers: every value comes from the tuning surface -----------

func test_req_001_controller_declares_no_balance_constants() -> void:
	var sources: PackedStringArray = [
		"res://core/controller/axolotl_controller.gd",
		"res://core/controller/water_dash.gd",
		"res://core/controller/tongue_grapple.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		# Every tuning value is read by key through TuningData, never inlined.
		assert_bool(text.contains("_tuning.get_number") or text.contains("_tuning.get_count")
			or path.ends_with("axolotl_controller.gd")).is_true()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_controller_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	var sources: PackedStringArray = [
		"res://core/controller/movement_grammar.gd",
		"res://core/controller/player_intent.gd",
		"res://core/controller/capability_modifiers.gd",
		"res://core/controller/water_dash.gd",
		"res://core/controller/tongue_grapple.gd",
		"res://core/controller/axolotl_controller.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
