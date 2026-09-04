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


## Stands in for the live scene so AC-4's discovery order — group query, range
## filter, then line of sight — can be asserted without a scene tree or a
## physics server. It also COUNTS rays, which is how the test proves discovery
## is not a proximity scan: an out-of-range anchor must never cost a ray.
class FakeAnchorSource extends AnchorSource:
	var anchors: Array[GrappleAnchor] = []
	var group_queried: String = ""
	var blocked_ids: PackedStringArray = []
	var rays_cast: int = 0

	func query_anchors_in_group(group: String) -> Array[GrappleAnchor]:
		group_queried = group
		var out: Array[GrappleAnchor] = []
		# Only anchors in the queried group are visible — membership is the tag.
		out.assign(anchors)
		return out

	func has_line_of_sight(_from: Vector3, to: Vector3) -> bool:
		rays_cast += 1
		for anchor: GrappleAnchor in anchors:
			if anchor.position.is_equal_approx(to) \
					and blocked_ids.find(anchor.id) != -1:
				return false
		return true


func _source(anchors: Array[GrappleAnchor]) -> FakeAnchorSource:
	var source := FakeAnchorSource.new()
	source.anchors = anchors
	return source


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


func test_req_001_swimming_moves_at_the_tuned_speed_in_any_of_three_axes() -> void:
	var tuning := _tuning()
	var speed := tuning.get_number("controller.swim.base_speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	for direction: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD,
			Vector3(1.0, 1.0, 1.0)]:
		controller.physics_step(0.016, true, _intent(direction))
		assert_float(controller.get_velocity().length()).override_failure_message(
			"REQ-001 AC-2: full 3D steering must reach tuned swim speed on %s"
			% str(direction)
		).is_equal_approx(speed, 0.0001)


# --- AC-2: dive ------------------------------------------------------------

func test_req_001_dive_descends_at_the_tuned_speed_from_a_standstill() -> void:
	var tuning := _tuning()
	var dive_speed := tuning.get_number("controller.dive.speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, true, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.DIVE]))

	assert_float(controller.get_velocity().y).override_failure_message(
		"REQ-001 AC-2: a dive is a deliberate descent, so it must work with no steering"
	).is_equal_approx(-dive_speed, 0.0001)


func test_req_001_dive_overrides_upward_steering() -> void:
	# A dive held against "up" descends: it SETS the vertical component rather
	# than adding to it, or the verb would cancel itself out.
	var controller := _controller()
	controller.physics_step(0.016, true,
		_intent(Vector3.UP, [MovementGrammar.Verb.DIVE]))

	assert_bool(controller.get_velocity().y < 0.0).override_failure_message(
		"REQ-001 AC-2: DIVE must override upward steering, not blend with it"
	).is_true()


func test_req_001_dive_announces_itself_and_does_nothing_on_land() -> void:
	var controller := _controller()
	var dives: Array[bool] = []
	controller.dived.connect(func() -> void: dives.append(true))

	controller.physics_step(0.016, true, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.DIVE]))
	assert_int(dives.size()).is_equal(1)

	# DIVE is not a land verb; a land step must not descend or re-announce.
	controller.set_velocity(Vector3.ZERO)
	controller.physics_step(0.016, false, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.DIVE]))
	assert_int(dives.size()).override_failure_message(
		"REQ-001 AC-2: DIVE belongs to the water grammar only"
	).is_equal(1)
	assert_float(controller.get_velocity().y).is_equal_approx(0.0, 0.0001)


# --- AC-2: bubble boost, governed by a cooldown ----------------------------

func test_req_001_bubble_boost_multiplies_swim_speed_while_active() -> void:
	var tuning := _tuning()
	var multiplier := tuning.get_number("controller.bubble_boost.speed_multiplier")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, true, _intent(Vector3.RIGHT))
	var unboosted := controller.get_velocity().length()

	controller.physics_step(0.016, true, _intent(Vector3.RIGHT,
		[MovementGrammar.Verb.BUBBLE_BOOST]))

	assert_bool(controller.get_bubble_boost().is_active()).is_true()
	assert_float(controller.get_velocity().length()).is_equal_approx(
		unboosted * multiplier, 0.001)


func test_req_001_bubble_boost_is_governed_by_a_cooldown() -> void:
	var tuning := _tuning()
	var duration := tuning.get_number("controller.bubble_boost.duration_s")
	var cooldown := tuning.get_number("controller.bubble_boost.cooldown_s")
	var boost := BubbleBoost.new(tuning)

	assert_bool(boost.try_activate()).is_true()
	# A second activation while boosting is refused, not queued.
	assert_bool(boost.try_activate()).is_false()

	# The instant the active window ends, the boost is COOLING, not READY.
	boost.tick(duration)
	assert_bool(boost.is_cooling()).override_failure_message(
		"REQ-001 AC-2: the boost must enter a cooldown when it expires"
	).is_true()
	assert_bool(boost.try_activate()).override_failure_message(
		"REQ-001 AC-2: an expired boost must not be immediately re-usable"
	).is_false()

	# Still cooling one tick short of the tuned cooldown.
	boost.tick(cooldown - 0.01)
	assert_bool(boost.is_ready()).is_false()

	boost.tick(0.01)
	assert_bool(boost.is_ready()).override_failure_message(
		"REQ-001 AC-2: the boost must become usable again after the tuned cooldown"
	).is_true()
	assert_bool(boost.try_activate()).is_true()


func test_req_001_bubble_boost_cooldown_cannot_be_tuned_away() -> void:
	# "Governed by a cooldown" is only true if the cooldown cannot be zeroed, so
	# the permitted range itself has to forbid it.
	var bounds := _tuning().get_permitted_range("controller.bubble_boost.cooldown_s")
	assert_int(bounds.size()).is_equal(2)
	assert_bool(bounds[0] > 0.0).override_failure_message(
		"REQ-001 AC-2: a zero-cooldown boost would be ungoverned; the tuned "
		+ "minimum must be above zero"
	).is_true()


func test_req_001_long_frame_does_not_shorten_the_boost_cooldown() -> void:
	# Overshoot must carry into the cooldown, or a low frame rate would hand the
	# player a shorter cooldown than the tuned number.
	var tuning := _tuning()
	var duration := tuning.get_number("controller.bubble_boost.duration_s")
	var cooldown := tuning.get_number("controller.bubble_boost.cooldown_s")
	var boost := BubbleBoost.new(tuning)

	boost.try_activate()
	boost.tick(duration + cooldown * 0.5)  # one very long frame
	assert_bool(boost.is_cooling()).is_true()
	assert_float(boost.get_remaining()).is_equal_approx(cooldown * 0.5, 0.001)


func test_req_001_bubble_boost_is_refused_on_land() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent(Vector3.RIGHT,
		[MovementGrammar.Verb.BUBBLE_BOOST]))

	assert_bool(controller.get_bubble_boost().is_active()).override_failure_message(
		"REQ-001 AC-2: BUBBLE_BOOST belongs to the water grammar only"
	).is_false()


func test_req_001_leaving_water_interrupts_an_active_boost() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent(Vector3.RIGHT,
		[MovementGrammar.Verb.BUBBLE_BOOST]))
	assert_bool(controller.get_bubble_boost().is_active()).is_true()

	controller.physics_step(0.016, false, _intent(Vector3.RIGHT))

	assert_bool(controller.get_bubble_boost().is_active()).override_failure_message(
		"a boost surviving onto land would grant a land speed burst the land "
		+ "grammar never offers"
	).is_false()


func test_req_001_capability_loss_shortens_the_boost_but_not_its_cooldown() -> void:
	var tuning := _tuning()
	var scale := tuning.get_number("capability.gill_loss.boost_duration_multiplier")
	var full := tuning.get_number("controller.bubble_boost.duration_s")
	var boost := BubbleBoost.new(tuning)

	boost.set_duration_scale(scale)
	assert_float(boost.duration_seconds()).is_equal_approx(full * scale, 0.001)
	assert_float(boost.cooldown_seconds()).override_failure_message(
		"losing a gill shortens the payoff, not the penalty"
	).is_equal_approx(tuning.get_number("controller.bubble_boost.cooldown_s"), 0.001)


# --- AC-3: waddle, hop, and climbing on tagged surfaces --------------------

func test_req_001_waddle_moves_at_the_tuned_land_speed_in_the_plane() -> void:
	var tuning := _tuning()
	var waddle := tuning.get_number("controller.waddle.base_speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, false, _intent(Vector3(1.0, 0.0, 1.0)))

	var velocity := controller.get_velocity()
	assert_float(velocity.y).is_equal_approx(0.0, 0.0001)
	assert_float(Vector2(velocity.x, velocity.z).length()).is_equal_approx(
		waddle, 0.0001)


func test_req_001_the_two_grammars_move_at_different_speeds() -> void:
	# Pillar 2: if water and land moved at the same speed, "mechanically
	# distinct" would be an animation claim rather than a mechanical one.
	var tuning := _tuning()
	assert_bool(tuning.get_number("controller.swim.base_speed_m_per_s")
		> tuning.get_number("controller.waddle.base_speed_m_per_s")
	).override_failure_message(
		"REQ-001: water is the fast grammar; the gap is what makes them distinct"
	).is_true()


func test_req_001_hop_imparts_the_tuned_upward_impulse_when_grounded() -> void:
	var tuning := _tuning()
	var impulse := tuning.get_number("controller.hop.impulse_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, false, _intent())
	controller.set_grounded(true)
	controller.physics_step(0.016, false, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.HOP]))

	assert_float(controller.get_velocity().y).is_equal_approx(impulse, 0.0001)


func test_req_001_hop_cannot_be_chained_in_mid_air() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.set_grounded(true)

	var hops: Array[bool] = []
	controller.hopped.connect(func() -> void: hops.append(true))

	controller.physics_step(0.016, false, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.HOP]))
	# Still airborne — the second hop must be refused.
	controller.physics_step(0.016, false, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.HOP]))

	assert_int(hops.size()).override_failure_message(
		"REQ-001 AC-3: a hop is grounded-only, or it becomes a free ascent"
	).is_equal(1)


func test_req_001_waddling_does_not_erase_hop_momentum() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.set_grounded(true)
	controller.physics_step(0.016, false, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.HOP]))
	var rise := controller.get_velocity().y

	# Steering mid-hop must move you horizontally without cancelling the hop.
	controller.physics_step(0.016, false, _intent(Vector3.RIGHT))

	assert_float(controller.get_velocity().y).is_equal_approx(rise, 0.0001)
	assert_bool(controller.get_velocity().x > 0.0).is_true()


func test_req_001_climb_attaches_to_a_surface_on_the_climbable_physics_layer() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())

	assert_bool(controller.try_climb(ClimbSurface.CLIMBABLE_LAYER_MASK,
		PackedStringArray())).is_true()
	assert_bool(controller.is_climbing()).is_true()


func test_req_001_climb_attaches_to_a_surface_in_the_climbable_group() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())

	assert_bool(controller.try_climb(0,
		PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))).is_true()
	assert_bool(controller.is_climbing()).is_true()


func test_req_001_climb_is_refused_on_an_untagged_surface() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())

	# Some other layer, some other group: not climbable.
	assert_bool(controller.try_climb(1 << 7,
		PackedStringArray(["scenery", "wet"]))).is_false()
	assert_bool(controller.is_climbing()).is_false()


func test_req_001_climbable_is_a_tag_never_a_name_check() -> void:
	# A world author who names a wall "climbable_rock_02" but forgets the layer
	# and the group must get a refusal. The moment a name substring is enough,
	# the Level Contract depends on a naming convention no schema can validate.
	assert_bool(ClimbSurface.is_climbable(0,
		PackedStringArray(["climbable_rock_02", "Climbable", "CLIMBABLE"]))
	).override_failure_message(
		"REQ-001 AC-3: the climbable tag is a physics layer or an exact group, "
		+ "never a node name or a substring of one"
	).is_false()

	# And the exact group still works, so the check is not simply always-false.
	assert_bool(ClimbSurface.is_climbable(0,
		PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))).is_true()


func test_req_001_climbing_restores_vertical_steering_on_land() -> void:
	var tuning := _tuning()
	var climb_speed := tuning.get_number("controller.climb.speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, false, _intent())
	controller.try_climb(ClimbSurface.CLIMBABLE_LAYER_MASK, PackedStringArray())

	# The same pure-vertical intent that produces no motion on the ground.
	controller.physics_step(0.016, false, _intent(Vector3.FORWARD))

	assert_float(controller.get_velocity().y).override_failure_message(
		"REQ-001 AC-3: the wall IS the vertical route; climbing must restore it"
	).is_equal_approx(climb_speed, 0.0001)


func test_req_001_a_climber_clings_rather_than_sliding() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.try_climb(0, PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))
	controller.physics_step(0.016, false, _intent(Vector3.FORWARD))

	controller.physics_step(0.016, false, _intent())  # let go of the stick

	assert_float(controller.get_velocity().length()).is_equal_approx(0.0, 0.0001)


func test_req_001_entering_water_ends_a_climb() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.try_climb(0, PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))

	var ended: Array[bool] = []
	controller.climb_ended.connect(func() -> void: ended.append(true))
	controller.physics_step(0.016, true, _intent())

	assert_bool(controller.is_climbing()).override_failure_message(
		"a climb surviving into water would let the player scale a wall while swimming"
	).is_false()
	assert_int(ended.size()).is_equal(1)


func test_req_001_climb_is_refused_in_water() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())
	assert_bool(controller.try_climb(ClimbSurface.CLIMBABLE_LAYER_MASK,
		PackedStringArray())).is_false()


# --- AC-4: tongue grapple range, discovery, and the pull -------------------

func test_req_001_grapple_attaches_at_exactly_max_range() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	assert_bool(grapple.is_in_range(reach)).override_failure_message(
		"REQ-001 AC-4: 'at or within' means an anchor exactly at max range attaches"
	).is_true()

	var source := _source([GrappleAnchor.new("edge", Vector3(reach, 0.0, 0.0))])
	var found := grapple.find_anchor(Vector3.ZERO, source)
	assert_object(found).is_not_null()
	assert_str(found.id).is_equal("edge")


func test_req_001_grapple_rejects_an_anchor_beyond_max_range() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	assert_bool(grapple.is_in_range(reach + 0.01)).is_false()

	var source := _source([GrappleAnchor.new("far", Vector3(reach + 5.0, 0.0, 0.0))])
	assert_object(grapple.find_anchor(Vector3.ZERO, source)).is_null()
	assert_int(source.rays_cast).override_failure_message(
		"REQ-001 AC-4: discovery filters by range BEFORE casting; an unreachable "
		+ "anchor must never cost a ray"
	).is_equal(0)


func test_req_001_grapple_discovery_queries_the_anchor_group() -> void:
	# Group membership is the tag: discovery asks the group index, it does not
	# scan the scene and it does not inspect node names.
	var grapple := TongueGrapple.new(_tuning())
	var source := _source([GrappleAnchor.new("ledge", Vector3(4.0, 0.0, 0.0))])

	grapple.find_anchor(Vector3.ZERO, source)

	assert_str(source.group_queried).is_equal(TongueGrapple.ANCHOR_GROUP)


func test_req_001_grapple_picks_the_nearest_in_range_anchor() -> void:
	var tuning := _tuning()
	var reach := tuning.get_number("controller.grapple.max_range_m")
	var grapple := TongueGrapple.new(tuning)

	var source := _source([
		GrappleAnchor.new("mid", Vector3(7.0, 0.0, 0.0)),
		GrappleAnchor.new("near", Vector3(3.0, 0.0, 0.0)),
		GrappleAnchor.new("out_of_reach", Vector3(reach + 10.0, 0.0, 0.0)),
	])

	var found := grapple.find_anchor(Vector3.ZERO, source)
	assert_object(found).is_not_null()
	assert_str(found.id).is_equal("near")


func test_req_001_grapple_will_not_attach_through_an_obstruction() -> void:
	var grapple := TongueGrapple.new(_tuning())
	var source := _source([
		GrappleAnchor.new("behind_wall", Vector3(3.0, 0.0, 0.0)),
		GrappleAnchor.new("visible", Vector3(6.0, 0.0, 0.0)),
	])
	source.blocked_ids = PackedStringArray(["behind_wall"])

	var found := grapple.find_anchor(Vector3.ZERO, source)

	assert_object(found).is_not_null()
	assert_str(found.id).override_failure_message(
		"REQ-001 AC-4: a nearer anchor with no line of sight must be skipped, "
		+ "not attached through the wall"
	).is_equal("visible")


func test_req_001_grapple_with_no_anchor_source_misses_rather_than_guessing() -> void:
	var controller := _controller()
	assert_bool(controller.try_grapple()).is_false()
	assert_bool(controller.get_grapple().is_attached()).is_false()


func test_req_001_a_missed_grapple_does_not_leave_the_controller_attached() -> void:
	var controller := _controller()
	var reach := controller.get_grapple().max_range()
	controller.set_anchor_source(_source([
		GrappleAnchor.new("far", Vector3(reach + 1.0, 0.0, 0.0))]))

	assert_bool(controller.try_grapple()).is_false()
	assert_bool(controller.get_grapple().is_attached()).override_failure_message(
		"a missed grapple must not leave the controller believing it is attached"
	).is_false()


func test_req_001_a_hit_grapple_attaches_and_announces_the_anchor() -> void:
	var controller := _controller()
	var announced: Array[String] = []
	controller.grapple_attached.connect(func(id: String) -> void: announced.append(id))

	controller.set_anchor_source(_source([
		GrappleAnchor.new("ledge", Vector3(4.0, 0.0, 0.0))]))

	assert_bool(controller.try_grapple()).is_true()
	assert_str(controller.get_grapple().get_attached_anchor()).is_equal("ledge")
	assert_array(announced).contains(["ledge"])


func test_req_001_an_attached_grapple_pulls_toward_the_anchor() -> void:
	var tuning := _tuning()
	var pull_speed := tuning.get_number("controller.grapple.pull_speed_m_per_s")
	var controller := AxolotlController.new(tuning)

	controller.physics_step(0.016, false, _intent())
	controller.sync_body_position(Vector3.ZERO)
	controller.set_anchor_source(_source([
		GrappleAnchor.new("ledge", Vector3(0.0, 8.0, 0.0))]))
	assert_bool(controller.try_grapple()).is_true()

	controller.physics_step(0.016, false, _intent())

	var velocity := controller.get_velocity()
	assert_float(velocity.length()).override_failure_message(
		"REQ-001 AC-4: attaching is not enough; the grapple must PULL the axolotl"
	).is_equal_approx(pull_speed, 0.0001)
	assert_float(velocity.normalized().dot(Vector3.UP)).is_equal_approx(1.0, 0.0001)


func test_req_001_the_pull_overrides_steering() -> void:
	# The tongue is taut: a player who fires it commits to the arc.
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.sync_body_position(Vector3.ZERO)
	controller.set_anchor_source(_source([
		GrappleAnchor.new("ledge", Vector3(0.0, 8.0, 0.0))]))
	controller.try_grapple()

	controller.physics_step(0.016, false, _intent(Vector3.RIGHT))

	assert_float(controller.get_velocity().x).is_equal_approx(0.0, 0.0001)
	assert_bool(controller.get_velocity().y > 0.0).is_true()


func test_req_001_arriving_at_the_anchor_detaches_the_grapple() -> void:
	var tuning := _tuning()
	var radius := tuning.get_number("controller.grapple.arrival_radius_m")
	var controller := AxolotlController.new(tuning)

	var detached: Array[bool] = []
	controller.grapple_detached.connect(func(_id: String, arrived: bool) -> void:
		detached.append(arrived))

	controller.physics_step(0.016, false, _intent())
	controller.sync_body_position(Vector3.ZERO)
	controller.set_anchor_source(_source([
		GrappleAnchor.new("ledge", Vector3(0.0, 8.0, 0.0))]))
	controller.try_grapple()

	# The wrapper has carried the body to the anchor.
	controller.sync_body_position(Vector3(0.0, 8.0 - radius * 0.5, 0.0))
	controller.physics_step(0.016, false, _intent())

	assert_bool(controller.get_grapple().is_attached()).override_failure_message(
		"without an arrival radius the pull oscillates around the anchor forever"
	).is_false()
	assert_array(detached).contains([true])


func test_req_001_the_grapple_verb_fires_the_tongue_from_intent() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent())
	controller.sync_body_position(Vector3.ZERO)
	controller.set_anchor_source(_source([
		GrappleAnchor.new("ledge", Vector3(5.0, 0.0, 0.0))]))

	# GRAPPLE is universal — it works in the water grammar too.
	assert_bool(controller.supports(MovementGrammar.Verb.GRAPPLE)).is_true()
	controller.physics_step(0.016, true, _intent(Vector3.ZERO,
		[MovementGrammar.Verb.GRAPPLE]))

	assert_str(controller.get_grapple().get_attached_anchor()).is_equal("ledge")


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
		"res://core/controller/bubble_boost.gd",
		"res://core/controller/tongue_grapple.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		# Every tuning value is read by key through TuningData, never inlined.
		assert_bool(text.contains("_tuning.get_number")
			or text.contains("_tuning.get_count")
		).override_failure_message(
			"REQ-025: '%s' must read its numbers from the tuning surface" % path
		).is_true()


func test_req_001_every_controller_tuning_key_exists_in_the_surface() -> void:
	# A key constant that no longer matches the tuning file would fail at runtime
	# on the frame the verb is first used, which is the worst possible time.
	var data := _tuning()
	var keys: PackedStringArray = [
		AxolotlController.MOMENTUM_RETENTION_KEY,
		AxolotlController.SWIM_SPEED_KEY,
		AxolotlController.WADDLE_SPEED_KEY,
		AxolotlController.DIVE_SPEED_KEY,
		AxolotlController.HOP_IMPULSE_KEY,
		AxolotlController.CLIMB_SPEED_KEY,
		WaterDash.MAX_CHARGES_KEY,
		WaterDash.RECHARGE_SECONDS_KEY,
		BubbleBoost.DURATION_KEY,
		BubbleBoost.COOLDOWN_KEY,
		BubbleBoost.SPEED_MULTIPLIER_KEY,
		TongueGrapple.MAX_RANGE_KEY,
		TongueGrapple.PULL_SPEED_KEY,
		TongueGrapple.ARRIVAL_RADIUS_KEY,
	]
	for key: String in keys:
		assert_bool(data.has_key(key)).override_failure_message(
			"REQ-001: the controller reads '%s', which the tuning surface lacks" % key
		).is_true()


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
		"res://core/controller/bubble_boost.gd",
		"res://core/controller/climb_surface.gd",
		"res://core/controller/grapple_anchor.gd",
		"res://core/controller/anchor_source.gd",
		"res://core/controller/scene_anchor_source.gd",
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


# --- Drag: momentum is preserved, but not forever ---------------------------
#
# These exist because of a bug found by hand rather than by this suite. Both
# grammars documented "absence of steering PRESERVES momentum", and nothing
# ever took that momentum away — so releasing the key left the axolotl coasting
# at full waddle speed until it walked off the level, and falling into water
# sank at entry speed until it hit the floor. The suite missed it because every
# test steered on the frame it asserted; none released and then waited.

func _coast(controller: AxolotlController, in_water: bool, seconds: float) -> void:
	var frames := int(seconds / 0.016)
	for _i: int in range(frames):
		controller.physics_step(0.016, in_water, _intent())


func test_req_001_an_unsteered_waddle_comes_to_a_stop() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent(Vector3.FORWARD))
	var moving := controller.get_velocity()
	assert_float(Vector2(moving.x, moving.z).length()).override_failure_message(
		"the axolotl should be waddling before we test that it stops"
	).is_greater(0.5)

	_coast(controller, false, 1.0)

	var rested := controller.get_velocity()
	assert_float(Vector2(rested.x, rested.z).length()).override_failure_message(
		"REQ-001: releasing the key must stop the axolotl. Coasting forever is "
		+ "how it walks off the edge of a level.").is_equal_approx(0.0, 0.001)


func test_req_001_an_unsteered_swim_glides_further_than_a_waddle() -> void:
	# Not merely "both stop" — the CONTRAST is the point. Water is the grammar
	# that glides, and that difference is a large part of what makes the two
	# read as mechanically distinct rather than one speed with two animations.
	var water := _controller()
	water.physics_step(0.016, true, _intent(Vector3.FORWARD))
	var water_start := water.get_velocity().length()
	_coast(water, true, 0.25)
	var water_kept := water.get_velocity().length() / water_start

	var land := _controller()
	land.physics_step(0.016, false, _intent(Vector3.FORWARD))
	var land_moving := land.get_velocity()
	var land_start := Vector2(land_moving.x, land_moving.z).length()
	_coast(land, false, 0.25)
	var land_rested := land.get_velocity()
	var land_kept := Vector2(land_rested.x, land_rested.z).length() / land_start

	assert_float(water_kept).override_failure_message(
		"after a quarter second of no steering, water kept %.3f of its speed "
		% water_kept + "and land kept %.3f — water must glide further"
		% land_kept).is_greater(land_kept)
	assert_float(water_kept).override_failure_message(
		"water should still be gliding after a quarter second").is_greater(0.5)


func test_req_001_an_unsteered_swim_still_comes_to_rest() -> void:
	var controller := _controller()
	controller.physics_step(0.016, true, _intent(Vector3.FORWARD))
	_coast(controller, true, 12.0)
	assert_float(controller.get_velocity().length()).override_failure_message(
		"a gentle drag is still a drag: a fall into water must not sink at its "
		+ "entry speed forever").is_equal_approx(0.0, 0.001)


func test_req_001_land_drag_never_touches_the_vertical() -> void:
	# Gravity and the hop own velocity.y on land, and the wrapper owns gravity.
	# Dragging the vertical would make the axolotl float down.
	var controller := _controller()
	controller.set_grounded(true)
	controller.physics_step(0.016, false,
		_intent(Vector3.ZERO, [MovementGrammar.Verb.HOP] as Array[MovementGrammar.Verb]))
	var launched := controller.get_velocity().y
	assert_float(launched).is_greater(1.0)

	controller.physics_step(0.016, false, _intent())
	assert_float(controller.get_velocity().y).override_failure_message(
		"the hop's rise was dragged away; only the horizontal plane may be slowed"
	).is_equal_approx(launched, 0.001)


func test_req_001_drag_does_not_erase_the_transition_momentum_carry() -> void:
	# The regression guard for AC-1, and a statement of how the two rules
	# compose. The carry is INSTANTANEOUS and the drag acts over time, so a
	# horizontal crossing shows the retained magnitude with exactly one frame of
	# land drag on top — momentum carries, then decays like any other momentum.
	# (The AC-1 test above crosses with a purely vertical velocity, which land
	# drag deliberately spares, so it still reads the ratio exactly.)
	var tuning := _tuning()
	var controller := AxolotlController.new(tuning)
	controller.physics_step(0.016, true, _intent(Vector3.FORWARD))
	var before := controller.get_velocity().length()

	controller.physics_step(0.016, false, _intent())  # surfacing, unsteered
	var after := Vector2(controller.get_velocity().x,
		controller.get_velocity().z).length()

	var ratio := tuning.get_number(AxolotlController.MOMENTUM_RETENTION_KEY)
	var drag := tuning.get_number(AxolotlController.WADDLE_DRAG_KEY)
	var expected := before * ratio * exp(-drag * 0.016)

	assert_float(after).override_failure_message(
		"expected %.3f (%.2f carried at %.2f, then one frame of %.1f/s drag), "
			% [expected, before, ratio, drag] + "got %.3f" % after
	).is_equal_approx(expected, 0.01)

	# And the carry must still dominate: if drag ate most of it, the seam would
	# read as a stop rather than as momentum crossing it.
	assert_float(after / before).override_failure_message(
		"only %.0f%% of the speed survived the crossing" % [(after / before) * 100.0]
	).is_greater(0.6)


# --- Climb steering: the land grammar is planar -----------------------------
#
# The anti-vacuity control for the climb tests above. They used to feed
# Vector3.UP, which the land grammar CANNOT produce — its bindings are
# forward/back/left/right and nothing else. So the tests were green against an
# imaginary input while a real wall did nothing. These pin the actual mapping.

func test_req_001_the_land_grammar_never_produces_a_vertical_intent() -> void:
	# If this ever becomes false, the forward-is-up mapping below is the wrong
	# design and should be revisited rather than quietly kept.
	var table := BindingTable.load_from_file(BindingTable.DEFAULTS_PATH,
		[] as Array[InputError])
	var waddle := table.binding_for(InputVerb.Verb.WADDLE,
		InputDevice.Kind.KEYBOARD_MOUSE)

	assert_object(waddle).is_not_null()
	for component: String in InputVerb.required_components(InputVerb.Verb.WADDLE):
		assert_bool(InputVerb.component_vector(component).y == 0.0
			).override_failure_message(
				"waddle component '%s' carries a vertical" % component).is_true()


func test_req_001_pushing_forward_on_a_wall_climbs_it() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.try_climb(0, PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))
	controller.set_climb_surface_normal(Vector3.BACK)

	controller.physics_step(0.016, false, _intent(Vector3.FORWARD))

	assert_float(controller.get_velocity().y).override_failure_message(
		"REQ-001 AC-3: forward against a wall must climb it. Before this, "
		+ "forward drove the axolotl into the wall and it never rose."
	).is_greater(0.1)


func test_req_001_lateral_steering_runs_along_the_wall_not_into_it() -> void:
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.try_climb(0, PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))
	controller.set_climb_surface_normal(Vector3.BACK)  # wall face pointing +Z

	controller.physics_step(0.016, false, _intent(Vector3.RIGHT))
	var sideways := controller.get_velocity()

	assert_float(absf(sideways.x)).override_failure_message(
		"lateral steering should traverse the wall").is_greater(0.1)
	assert_float(absf(sideways.z)).override_failure_message(
		"lateral steering must not push into or off the wall (z=%.3f)" % sideways.z
	).is_equal_approx(0.0, 0.001)


func test_req_001_the_climb_basis_follows_the_surface_normal() -> void:
	# A wall facing a different way must climb just as well — the basis comes
	# from the normal the body reports, not from a world axis.
	var controller := _controller()
	controller.physics_step(0.016, false, _intent())
	controller.try_climb(0, PackedStringArray([ClimbSurface.CLIMBABLE_GROUP]))
	controller.set_climb_surface_normal(Vector3.RIGHT)  # wall face pointing +X

	controller.physics_step(0.016, false, _intent(Vector3.FORWARD))
	assert_float(controller.get_velocity().y).override_failure_message(
		"forward must climb regardless of which way the wall faces").is_greater(0.1)

	controller.physics_step(0.016, false, _intent(Vector3.RIGHT))
	assert_float(absf(controller.get_velocity().x)).override_failure_message(
		"lateral must not push into a wall whose normal is +X"
	).is_equal_approx(0.0, 0.001)
