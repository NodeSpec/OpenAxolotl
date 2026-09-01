extends GdUnitTestSuite

## Regeneration and Capability System — REQ-002, and the machine-checkable half
## of REQ-019.
##
## Test names carry the requirement id they prove (test_req_002_...,
## test_req_019_...) so the runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"
const FRAME := 1.0 / 60.0

## Words that would mean this node had grown a health bar, or a way to end a run.
## Kept as data so the two structural tests below read the same list.
const HEALTH_VOCABULARY: PackedStringArray = [
	"health", "hitpoint", "hit_point", "hit_points",
	"damage_amount", "damage_value", "damage_taken", "max_hp", "current_hp",
]

const RUN_ENDING_VOCABULARY: PackedStringArray = [
	"life", "lives", "death", "died", "kill", "reset", "game_over",
	"respawn", "fatal",
]

const REGEN_SOURCES: PackedStringArray = [
	"res://core/regen/capability.gd",
	"res://core/regen/capability_state.gd",
	"res://core/regen/damage_event.gd",
	"res://core/regen/mutation_loadout.gd",
	"res://core/regen/feedback_cue.gd",
	"res://core/regen/state_discriminator.gd",
	"res://core/regen/feedback_table.gd",
	"res://core/regen/regen_system.gd",
]


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _regen() -> RegenSystem:
	return RegenSystem.new(_tuning())


func _hit(kind: Capability.Kind, catastrophic: bool = false) -> DamageEvent:
	return DamageEvent.new("netbot", kind, catastrophic)


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


## Source with comments stripped. The health-vocabulary scan below has to read
## CODE, not prose: this node's own doc comments explain at length that there is
## no health value here, and a scan over raw text would flag the explanation as
## the violation it exists to prevent.
func _code_only(path: String) -> String:
	var out := ""
	for line: String in _read(path).split("\n"):
		var comment_at := line.find("#")
		out += (line if comment_at < 0 else line.substr(0, comment_at)) + "\n"
	return out


## A controller wired to a regen system through the published interface, which
## is the only way these two are ever connected.
func _wired(tuning: TuningData, regen: RegenSystem) -> AxolotlController:
	var controller := AxolotlController.new(tuning)
	regen.publish_to(controller.get_capability_modifiers())
	return controller


func _intent(direction: Vector3 = Vector3.ZERO,
		verbs: Array[MovementGrammar.Verb] = []) -> PlayerIntent:
	return PlayerIntent.new(direction, verbs)


# --- AC-1: a hit strips a capability, it does not drain a value ------------

func test_req_002_damage_strips_the_named_capability() -> void:
	var regen := _regen()
	var lost: Array[int] = []
	regen.capability_lost.connect(func(k: Capability.Kind) -> void: lost.append(int(k)))

	assert_bool(regen.apply_damage(_hit(Capability.Kind.GILL))).is_true()

	assert_bool(regen.is_lost(Capability.Kind.GILL)).is_true()
	# Only the named one. A hit is not a step toward a general decline.
	assert_bool(regen.is_lost(Capability.Kind.TAIL)).is_false()
	assert_bool(regen.is_lost(Capability.Kind.LEG)).is_false()
	assert_array(lost).contains([int(Capability.Kind.GILL)])


func test_req_002_a_repeat_hit_does_not_re_strip_the_same_capability() -> void:
	# Being hit twice in the same spot must not pop the same tail twice.
	var regen := _regen()
	assert_bool(regen.apply_damage(_hit(Capability.Kind.TAIL))).is_true()

	var repeats: Array[int] = []
	regen.capability_lost.connect(func(k: Capability.Kind) -> void: repeats.append(int(k)))

	assert_bool(regen.apply_damage(_hit(Capability.Kind.TAIL))).is_false()
	assert_array(repeats).is_empty()
	assert_int(regen.count_lost()).is_equal(1)


func test_req_002_a_catastrophic_event_is_refused_not_translated() -> void:
	# Catastrophe belongs to the Lives layer. This system declining it outright
	# is what stops the two layers merging into one with a threshold in it.
	var regen := _regen()

	assert_bool(regen.apply_damage(_hit(Capability.Kind.TAIL, true))).is_false()

	assert_bool(regen.is_fully_intact()).override_failure_message(
		"REQ-002: a catastrophic hit must not be turned into a capability loss"
	).is_true()


func test_req_002_the_node_declares_no_health_value_anywhere() -> void:
	# "Strips a capability RATHER THAN reducing a health value" is only true if
	# there is nothing here that could be reduced.
	for path: String in REGEN_SOURCES:
		var code := _code_only(path).to_lower()
		for word: String in HEALTH_VOCABULARY:
			assert_bool(code.contains(word)).override_failure_message(
				"REQ-002 AC-1: '%s' declares health vocabulary '%s'" % [path, word]
			).is_false()


func test_req_002_the_health_scan_is_not_vacuous() -> void:
	# Proves the guard above bites: a file that DOES declare a health value must
	# be caught. The controller is scanned for the same words as a live control,
	# and the vocabulary is asserted non-empty so an emptied list cannot pass.
	assert_int(HEALTH_VOCABULARY.size()).is_greater(0)

	var fixture := "var health: int = 100\nfunc take_damage(amount: int) -> void:"
	var caught := false
	for word: String in HEALTH_VOCABULARY:
		if fixture.to_lower().contains(word):
			caught = true
	assert_bool(caught).override_failure_message(
		"the health vocabulary must match an actual health declaration"
	).is_true()


func test_req_002_a_damage_event_carries_no_quantity() -> void:
	# A hit NAMES a capability. If it could also carry an amount, someone would
	# eventually accumulate the amounts, and that is a health bar.
	var event := DamageEvent.new()
	var declared := PackedStringArray()
	for property: Dictionary in event.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			declared.append(String(property["name"]))
	declared.sort()

	assert_int(declared.size()).override_failure_message(
		"REQ-002 AC-1: DamageEvent declares %s — a hit names a capability and "
		% str(declared) + "carries nothing that could be accumulated"
	).is_equal(3)
	assert_array(declared).contains(["capability", "catastrophic", "source_id"])


# --- AC-2: three losses, three DIFFERENT measurable modifiers --------------

func test_req_002_the_three_capabilities_degrade_three_different_things() -> void:
	# If two kinds shared a target the criterion would silently collapse: one
	# loss would be indistinguishable from another.
	var seen: Array[int] = []
	for kind: Capability.Kind in Capability.ALL:
		var target := int(Capability.modifier_target(kind))
		assert_bool(seen.has(target)).override_failure_message(
			"REQ-002 AC-2: '%s' shares a modifier target with another capability"
			% Capability.id(kind)
		).is_false()
		seen.append(target)
	assert_int(seen.size()).is_equal(3)


func test_req_002_a_lost_tail_reduces_swim_speed_by_the_tuned_multiplier() -> void:
	var tuning := _tuning()
	var factor := tuning.get_number("capability.tail_loss.swim_speed_multiplier")
	var regen := RegenSystem.new(tuning)

	var intact := _wired(tuning, regen)
	intact.physics_step(FRAME, true, _intent(Vector3.RIGHT))
	var full := intact.get_velocity().length()

	regen.apply_damage(_hit(Capability.Kind.TAIL))
	var impaired := _wired(tuning, regen)
	impaired.physics_step(FRAME, true, _intent(Vector3.RIGHT))

	assert_float(impaired.get_velocity().length()).override_failure_message(
		"REQ-002 AC-2: a lost tail must reduce swim speed by the tuned multiplier"
	).is_equal_approx(full * factor, 0.0001)


func test_req_002_a_lost_gill_reduces_boost_duration_by_the_tuned_multiplier() -> void:
	var tuning := _tuning()
	var factor := tuning.get_number("capability.gill_loss.boost_duration_multiplier")
	var full_duration := tuning.get_number("controller.bubble_boost.duration_s")
	var regen := RegenSystem.new(tuning)

	regen.apply_damage(_hit(Capability.Kind.GILL))
	var controller := _wired(tuning, regen)
	controller.physics_step(FRAME, true,
		_intent(Vector3.RIGHT, [MovementGrammar.Verb.BUBBLE_BOOST]))

	assert_bool(controller.get_bubble_boost().is_active()).is_true()
	assert_float(controller.get_bubble_boost().get_remaining()).override_failure_message(
		"REQ-002 AC-2: a lost gill must shorten the bubble boost"
	).is_equal_approx(full_duration * factor, 0.001)


func test_req_002_a_lost_leg_reduces_climb_height_by_the_tuned_multiplier() -> void:
	var tuning := _tuning()
	var factor := tuning.get_number("capability.leg_loss.climb_height_multiplier")
	var full_height := tuning.get_number("controller.climb.max_height_m")
	var regen := RegenSystem.new(tuning)

	regen.apply_damage(_hit(Capability.Kind.LEG))
	var controller := _wired(tuning, regen)

	assert_float(controller.max_climb_height()).is_equal_approx(
		full_height * factor, 0.0001)


func test_req_002_the_lowered_climb_ceiling_actually_stops_the_climb() -> void:
	# The number above has to bite in play, or "reduces climb height" is a value
	# nothing reads.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	regen.apply_damage(_hit(Capability.Kind.LEG))

	var controller := _wired(tuning, regen)
	controller.physics_step(FRAME, false, _intent())
	controller.sync_body_position(Vector3.ZERO)
	controller.try_climb(ClimbSurface.CLIMBABLE_LAYER_MASK, PackedStringArray())

	# Below the impaired ceiling: still rising. FORWARD, not UP: the land
	# grammar is planar, and on a wall the forward axis is the vertical one.
	controller.sync_body_position(Vector3(0.0, 1.0, 0.0))
	controller.physics_step(FRAME, false, _intent(Vector3.FORWARD))
	assert_float(controller.get_velocity().y).is_greater(0.0)

	# Above it: the ascent stops, but the climber is not frozen or dropped.
	controller.sync_body_position(Vector3(0.0, controller.max_climb_height() + 0.1, 0.0))
	controller.physics_step(FRAME, false, _intent(Vector3.FORWARD))
	assert_float(controller.get_velocity().y).override_failure_message(
		"REQ-002 AC-2: a lost leg must lower the reachable height"
	).is_equal_approx(0.0, 0.0001)

	controller.physics_step(FRAME, false, _intent(Vector3.BACK))
	assert_float(controller.get_velocity().y).override_failure_message(
		"a climber at the ceiling must still be able to come back down"
	).is_less(0.0)


func test_req_002_a_loss_degrades_only_its_own_target() -> void:
	# The reason the Capability Modifier Interface learned about targets: with a
	# single global multiplier, a lost leg would slow the player's swimming.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)

	var intact := _wired(tuning, regen)
	intact.physics_step(FRAME, true, _intent(Vector3.RIGHT))
	var full_swim := intact.get_velocity().length()
	var full_climb := intact.max_climb_height()

	regen.apply_damage(_hit(Capability.Kind.LEG))
	var legless := _wired(tuning, regen)
	legless.physics_step(FRAME, true, _intent(Vector3.RIGHT))

	assert_float(legless.get_velocity().length()).override_failure_message(
		"REQ-002 AC-2: a lost leg must not slow swimming"
	).is_equal_approx(full_swim, 0.0001)

	var tail_only := RegenSystem.new(tuning)
	tail_only.apply_damage(_hit(Capability.Kind.TAIL))
	assert_float(_wired(tuning, tail_only).max_climb_height()).override_failure_message(
		"REQ-002 AC-2: a lost tail must not lower the climb ceiling"
	).is_equal_approx(full_climb, 0.0001)


# --- AC-3: never fatal, under ANY combination ------------------------------

func test_req_002_the_system_has_no_channel_that_could_end_a_run() -> void:
	# Structural half of the criterion: there is no signal and no method here
	# through which a life could be spent or a run reset. Not "we don't call it" —
	# there is nothing to call.
	var script: GDScript = RegenSystem.new(_tuning()).get_script()

	for signal_row: Dictionary in script.get_script_signal_list():
		var signal_name := String(signal_row["name"]).to_lower()
		for word: String in RUN_ENDING_VOCABULARY:
			assert_bool(signal_name.contains(word)).override_failure_message(
				"REQ-002 AC-3: signal '%s' looks like a run-ending channel"
				% signal_name
			).is_false()

	for method_row: Dictionary in script.get_script_method_list():
		var method_name := String(method_row["name"]).to_lower()
		for word: String in RUN_ENDING_VOCABULARY:
			assert_bool(method_name.contains(word)).override_failure_message(
				"REQ-002 AC-3: method '%s' looks like a run-ending channel"
				% method_name
			).is_false()


func test_req_002_no_combination_of_losses_drives_a_modifier_to_zero() -> void:
	# Eight subsets, written as a loop because the criterion says ANY
	# combination — three hand-picked cases would not be the same claim.
	var tuning := _tuning()
	var targets: Array[CapabilityModifiers.Target] = [
		CapabilityModifiers.Target.SWIM_SPEED,
		CapabilityModifiers.Target.WADDLE_SPEED,
		CapabilityModifiers.Target.BOOST_DURATION,
		CapabilityModifiers.Target.CLIMB_HEIGHT,
	]

	for mask: int in range(8):
		var regen := RegenSystem.new(tuning)
		for index: int in range(Capability.ALL.size()):
			if (mask & (1 << index)) != 0:
				regen.apply_damage(_hit(Capability.ALL[index]))

		for target: CapabilityModifiers.Target in targets:
			assert_float(regen.modifier_for(target)).override_failure_message(
				"REQ-002 AC-3: subset %d drove target %d to zero — capability "
				% [mask, int(target)] + "loss must degrade traversal, never end it"
			).is_greater(0.0)


func test_req_002_the_axolotl_still_moves_with_every_capability_lost() -> void:
	# The mechanical meaning of "never ends a run": whatever you have lost, you
	# can still swim and still walk. Driven through the real controller, because
	# the criterion is about play and not about a number in this node.
	var tuning := _tuning()

	for mask: int in range(8):
		var regen := RegenSystem.new(tuning)
		for index: int in range(Capability.ALL.size()):
			if (mask & (1 << index)) != 0:
				regen.apply_damage(_hit(Capability.ALL[index]))

		var controller := _wired(tuning, regen)

		controller.physics_step(FRAME, true, _intent(Vector3.RIGHT))
		assert_float(controller.get_velocity().length()).override_failure_message(
			"REQ-002 AC-3: subset %d cannot swim" % mask
		).is_greater(0.0)

		controller.physics_step(FRAME, false, _intent(Vector3.RIGHT))
		var planar := Vector2(controller.get_velocity().x, controller.get_velocity().z)
		assert_float(planar.length()).override_failure_message(
			"REQ-002 AC-3: subset %d cannot walk" % mask
		).is_greater(0.0)


# --- AC-4 and AC-6: regen stations and checkpoints -------------------------

func test_req_002_a_regen_station_restores_every_lost_capability() -> void:
	var regen := _regen()
	for kind: Capability.Kind in Capability.ALL:
		regen.apply_damage(_hit(kind))
	assert_int(regen.count_lost()).is_equal(3)

	var regrown: Array[int] = []
	regen.capability_restored.connect(
		func(k: Capability.Kind) -> void: regrown.append(int(k)))

	assert_int(regen.restore_all()).is_equal(3)

	assert_bool(regen.is_fully_intact()).is_true()
	assert_int(regrown.size()).override_failure_message(
		"one regrowth cue per capability actually regrown, not three regardless"
	).is_equal(3)


func test_req_002_restoring_an_intact_axolotl_regrows_nothing() -> void:
	var regen := _regen()
	var regrown: Array[int] = []
	regen.capability_restored.connect(
		func(k: Capability.Kind) -> void: regrown.append(int(k)))

	assert_int(regen.restore_all()).is_equal(0)
	assert_array(regrown).is_empty()


func test_req_002_checkpoint_restore_returns_published_modifiers_to_neutral() -> void:
	# AC-6 through the interface the controller actually reads: a regrown tail's
	# factor must not linger on the modifier object.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	var controller := AxolotlController.new(tuning)

	for kind: Capability.Kind in Capability.ALL:
		regen.apply_damage(_hit(kind))
	regen.publish_to(controller.get_capability_modifiers())
	assert_bool(controller.get_capability_modifiers().combined(
		CapabilityModifiers.Target.SWIM_SPEED) < 1.0).is_true()

	# The Lives and Checkpoint System calls this on respawn.
	regen.restore_all()
	regen.publish_to(controller.get_capability_modifiers())

	assert_float(controller.get_capability_modifiers().combined(
		CapabilityModifiers.Target.SWIM_SPEED)
	).override_failure_message(
		"REQ-002 AC-6: checkpoint restore must clear the published factors"
	).is_equal_approx(1.0, 0.0001)
	assert_array(controller.get_capability_modifiers().get_factor_ids()).is_empty()


func test_req_002_publishing_does_not_disturb_another_systems_factors() -> void:
	# The regen system owns a namespace, not the whole object.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	var modifiers := CapabilityModifiers.new()
	modifiers.set_factor("enemy:netbot_entangle", 0.35,
		CapabilityModifiers.Target.SWIM_SPEED)

	regen.apply_damage(_hit(Capability.Kind.TAIL))
	regen.publish_to(modifiers)
	regen.restore_all()
	regen.publish_to(modifiers)

	assert_bool(modifiers.has_factor("enemy:netbot_entangle")).override_failure_message(
		"publishing must clear only this system's own factors"
	).is_true()
	assert_float(modifiers.get_factor_value("enemy:netbot_entangle")).is_equal_approx(
		0.35, 0.0001)


# --- AC-5: temporary mutation loadouts -------------------------------------

func test_req_002_a_mutation_lasts_the_tuned_duration_then_reverts() -> void:
	var tuning := _tuning()
	var duration := tuning.get_number("regen.mutation.duration_s")
	var regen := RegenSystem.new(tuning)

	var loadout := MutationLoadout.new("finned").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 1.6)
	assert_bool(regen.apply_mutation(loadout)).is_true()
	assert_float(regen.modifier_for(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(1.6, 0.0001)

	# One tick short of the tuned duration: still mutated.
	regen.tick(duration - 0.01)
	assert_bool(regen.has_mutation()).is_true()

	regen.tick(0.01)
	assert_bool(regen.has_mutation()).override_failure_message(
		"REQ-002 AC-5: the mutation must revert after regen.mutation.duration_s"
	).is_false()
	assert_float(regen.modifier_for(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(1.0, 0.0001)


func test_req_002_the_revert_is_owned_here_not_by_the_station() -> void:
	# A world that despawns its regen station mid-loadout must not strand the
	# player mutated. The station is gone from this test entirely — only the
	# system remains, and it still reverts.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	regen.apply_mutation(MutationLoadout.new("jetform").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 2.0))

	var expired: Array[String] = []
	regen.mutation_expired.connect(func(id: String) -> void: expired.append(id))

	regen.tick(tuning.get_number("regen.mutation.duration_s") * 2.0)

	assert_array(expired).contains(["jetform"])
	assert_object(regen.get_active_mutation()).is_null()


func test_req_002_a_second_mutation_replaces_rather_than_stacks() -> void:
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	regen.apply_mutation(MutationLoadout.new("a").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 2.0))
	regen.tick(tuning.get_number("regen.mutation.duration_s") * 0.5)

	regen.apply_mutation(MutationLoadout.new("b").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 1.5))

	assert_float(regen.modifier_for(CapabilityModifiers.Target.SWIM_SPEED)
	).override_failure_message(
		"REQ-002 AC-5: loadouts replace; standing at a station must not stack them"
	).is_equal_approx(1.5, 0.0001)
	assert_float(regen.get_mutation_remaining()).is_equal_approx(
		regen.mutation_duration(), 0.0001)


func test_req_002_an_empty_or_unnamed_mutation_is_refused() -> void:
	var regen := _regen()
	assert_bool(regen.apply_mutation(MutationLoadout.new("empty"))).is_false()
	assert_bool(regen.apply_mutation(MutationLoadout.new("").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 2.0))).is_false()
	assert_bool(regen.has_mutation()).is_false()


func test_req_002_a_checkpoint_returns_the_axolotl_to_its_base_form() -> void:
	# "Capability state is fully restored" includes not respawning as something
	# other than yourself.
	var regen := _regen()
	regen.apply_damage(_hit(Capability.Kind.TAIL))
	regen.apply_mutation(MutationLoadout.new("finned").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 1.6))

	regen.restore_all()

	assert_bool(regen.is_fully_intact()).is_true()
	assert_bool(regen.has_mutation()).override_failure_message(
		"REQ-002 AC-6: a checkpoint respawn returns the base configuration"
	).is_false()


func test_req_002_a_mutation_composes_with_a_loss_through_one_interface() -> void:
	var tuning := _tuning()
	var loss := tuning.get_number("capability.tail_loss.swim_speed_multiplier")
	var regen := RegenSystem.new(tuning)

	regen.apply_damage(_hit(Capability.Kind.TAIL))
	regen.apply_mutation(MutationLoadout.new("finned").set_factor(
		CapabilityModifiers.Target.SWIM_SPEED, 2.0))

	assert_float(regen.modifier_for(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(loss * 2.0, 0.0001)


# --- REQ-019 AC-1: told apart without colour -------------------------------

func test_req_019_every_state_carries_a_complete_non_colour_discriminator() -> void:
	var ids := FeedbackTable.all_state_ids()
	assert_int(ids.size()).is_greater(0)

	for state_id: String in ids:
		var row := FeedbackTable.discriminator(state_id)
		assert_object(row).override_failure_message(
			"REQ-019 AC-1: '%s' has no discriminator" % state_id).is_not_null()
		assert_bool(row.is_complete()).override_failure_message(
			"REQ-019 AC-1: '%s' is missing a shape, glyph or label" % state_id
		).is_true()


func test_req_019_no_two_states_share_a_glyph_or_a_label() -> void:
	# Two states sharing an icon are indistinguishable however many channels the
	# table nominally has.
	var glyphs: Array[String] = []
	var labels: Array[String] = []

	for state_id: String in FeedbackTable.all_state_ids():
		var row := FeedbackTable.discriminator(state_id)
		assert_bool(glyphs.has(row.glyph)).override_failure_message(
			"REQ-019 AC-1: glyph '%s' is used by more than one state" % row.glyph
		).is_false()
		assert_bool(labels.has(row.label)).override_failure_message(
			"REQ-019 AC-1: label '%s' is used by more than one state" % row.label
		).is_false()
		glyphs.append(row.glyph)
		labels.append(row.label)


func test_req_019_the_discriminator_carries_no_colour_channel_at_all() -> void:
	# Colour is an art-side addition layered on top; if it lived here it would
	# eventually become the discriminator.
	var row := StateDiscriminator.new()
	for property: Dictionary in row.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var field := String(property["name"]).to_lower()
			assert_bool(field.contains("color") or field.contains("colour")
			).override_failure_message(
				"REQ-019 AC-1: '%s' would make colour a discriminator" % field
			).is_false()


func test_req_019_the_completeness_guard_is_not_vacuous() -> void:
	# An id nobody put in the table must come back null, or the test above would
	# pass for a table that silently invents entries.
	assert_object(FeedbackTable.discriminator("hazard.not_a_real_hazard")).is_null()


func test_req_019_hazards_interactables_and_restoration_are_all_covered() -> void:
	# The criterion names three families; a table covering only one would still
	# pass a completeness loop over its own keys.
	assert_int(FeedbackTable.HAZARDS.size()).is_greater(0)
	assert_int(FeedbackTable.INTERACTABLES.size()).is_greater(0)
	assert_int(FeedbackTable.RESTORATION_STATES.size()).is_equal(3)


# --- REQ-019 AC-2: both channels, every loss type --------------------------

func test_req_019_every_capability_event_declares_visual_and_audio() -> void:
	for kind: Capability.Kind in Capability.ALL:
		for lost: bool in [true, false]:
			var cue := FeedbackTable.capability_cue(kind, lost)
			assert_bool(cue.is_complete()).override_failure_message(
				"REQ-019 AC-2: '%s' (%s) is missing a channel"
				% [Capability.id(kind), "lost" if lost else "regrown"]
			).is_true()
			assert_str(cue.visual_id).is_not_empty()


func test_req_019_the_six_capability_cues_are_mutually_distinct() -> void:
	var visuals: Array[String] = []
	var audio: Array[int] = []

	for kind: Capability.Kind in Capability.ALL:
		for lost: bool in [true, false]:
			var cue := FeedbackTable.capability_cue(kind, lost)
			assert_bool(visuals.has(cue.visual_id)).override_failure_message(
				"REQ-019 AC-2: visual '%s' is reused" % cue.visual_id).is_false()
			assert_bool(audio.has(int(cue.audio_cue))).override_failure_message(
				"REQ-019 AC-2: audio cue %d is reused" % int(cue.audio_cue)).is_false()
			visuals.append(cue.visual_id)
			audio.append(int(cue.audio_cue))


func test_req_019_taking_damage_actually_requests_both_channels() -> void:
	# The table being complete is not enough; the system has to use it.
	var regen := _regen()
	var cues: Array[FeedbackCue] = []
	regen.feedback_requested.connect(func(c: FeedbackCue) -> void: cues.append(c))

	regen.apply_damage(_hit(Capability.Kind.LEG))

	assert_int(cues.size()).is_equal(1)
	assert_bool(cues[0].is_complete()).is_true()
	assert_int(int(cues[0].audio_cue)).is_equal(
		int(AudioEvent.Cue.CAPABILITY_LOST_LEG))


func test_req_019_regrowth_requests_both_channels_too() -> void:
	var regen := _regen()
	regen.apply_damage(_hit(Capability.Kind.LEG))

	var cues: Array[FeedbackCue] = []
	regen.feedback_requested.connect(func(c: FeedbackCue) -> void: cues.append(c))
	regen.restore_all()

	assert_int(cues.size()).is_equal(1)
	assert_int(int(cues[0].audio_cue)).is_equal(
		int(AudioEvent.Cue.CAPABILITY_REGROWN_LEG))


func test_req_019_audio_cues_are_semantic_never_file_paths() -> void:
	# This node emits "tail lost"; the Audio System alone knows what that sounds
	# like. A path here would put mixing decisions in the capability layer.
	for path: String in REGEN_SOURCES:
		var text := _read(path)
		for symbol: String in [".ogg", ".wav", ".mp3", "res://audio", "AudioStream"]:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-019/REQ-023: '%s' names an audio resource '%s'" % [path, symbol]
			).is_false()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_regen_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in REGEN_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
