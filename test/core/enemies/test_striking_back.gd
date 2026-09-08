extends GdUnitTestSuite

## Knocking a Drift Fleet machine over (REQ-012, REQ-019).
##
## Until this existed the enemy system ran one way: the machines acted on the
## player, and the player's only answer was to route around them. What is held
## here is that a strike is a real answer and a bounded one.
##
##   IT STOPS THE MACHINE. Every effect lane refuses while it is down, and
##   each lane is asked separately rather than through one shared guard — a
##   check that covered contact and not the aura would leave a knocked-over
##   drone still venting, which is exactly the kind of gap "it is disabled"
##   hides.
##
##   IT RELEASES WHAT THE MACHINE ALREADY DID. A Netbot whose net survived the
##   whack that knocked it over would make the strike a thing you do after the
##   danger rather than about it.
##
##   IT WEARS OFF. These are machines being knocked over, not things being
##   killed (REQ-019 AC-5), and a level a player can permanently empty stops
##   being a route problem the second time they walk it. So recovery is
##   asserted as hard as the knock-out.

const TUNING_PATH := "res://core/tuning/tuning.json"


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _fleet(tuning: TuningData) -> DriftFleetSystem:
	var registry := EnemyRegistry.new(tuning)
	var errors: Array[EnemyError] = []
	registry.load_directory(EnemyRegistry.ROSTER_DIRECTORY, errors)
	assert_array(errors).is_empty()
	return DriftFleetSystem.new(tuning, registry)


func test_req_012_a_struck_machine_is_disabled_and_then_recovers() -> void:
	var tuning := _tuning()
	var seconds := tuning.get_number("enemy.disabled_seconds")
	var fleet := _fleet(tuning)
	var down: Array = []
	var up: Array = []
	fleet.enemy_disabled.connect(
		func(id: String, kind: String, left: float) -> void:
			down.append({"id": id, "kind": kind, "seconds": left}))
	fleet.enemy_recovered.connect(func(id: String) -> void: up.append(id))

	assert_bool(fleet.strike("netbot", "tail_whack")).is_true()
	assert_bool(fleet.is_disabled("netbot")).is_true()
	assert_int(down.size()).is_equal(1)
	assert_str(down[0]["kind"]).override_failure_message(
		"the strike that landed is named, so a cue can differ by kind"
	).is_equal("tail_whack")
	assert_float(down[0]["seconds"]).is_equal_approx(seconds, 0.0001)

	# A second strike on a machine already down is refused, so a player
	# hammering the button cannot stack knock-outs into a permanent one.
	assert_bool(fleet.strike("netbot", "tail_whack")).override_failure_message(
		"a machine already down cannot be knocked further down").is_false()

	for _step: int in range(int(seconds / 0.1) + 2):
		fleet.tick(0.1)
	assert_bool(fleet.is_disabled("netbot")).override_failure_message(
		"a knocked-over machine must right itself").is_false()
	assert_array(up).contains(["netbot"])

	# And it works again once it has.
	assert_bool(fleet.contact("netbot")).is_true()


func test_req_012_striking_an_unknown_machine_is_refused() -> void:
	var fleet := _fleet(_tuning())
	assert_bool(fleet.strike("not_a_machine", "stomp")).is_false()
	assert_bool(fleet.is_disabled("not_a_machine")).is_false()


func test_req_012_a_disabled_netbot_neither_entangles_nor_holds_its_net() -> void:
	# The release is the point: the swing that lands on a Netbot is also how
	# you get out of its net.
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var modifiers := CapabilityModifiers.new()
	fleet.set_capability_modifiers(modifiers)
	var escapes: Array = []
	fleet.entangle_escaped.connect(func(id: String) -> void: escapes.append(id))

	assert_bool(fleet.contact("netbot")).is_true()
	assert_bool(fleet.is_entangled()).is_true()
	var factor := DriftFleetSystem.entangle_factor_id("netbot")
	assert_array(modifiers.get_factor_ids()).contains([factor])

	assert_bool(fleet.strike("netbot", "spin_sprint")).is_true()
	assert_bool(fleet.is_entangled()).override_failure_message(
		"knocking the Netbot over must free the player it has caught"
	).is_false()
	assert_array(modifiers.get_factor_ids()).override_failure_message(
		"and take its swim-speed factor off the controller with it"
	).not_contains([factor])
	assert_array(escapes).contains(["netbot"])

	# Down, it cannot catch them again.
	assert_bool(fleet.contact("netbot")).override_failure_message(
		"a disabled machine must be inert, not merely quiet").is_false()


func test_req_012_a_disabled_drone_stops_venting_and_stays_stopped() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var cleared: Array = []
	fleet.aura_cleared.connect(func(id: String) -> void: cleared.append(id))

	assert_bool(fleet.enter_aura("runoff_drone")).is_true()
	assert_bool(fleet.has_active_aura()).is_true()
	assert_float(fleet.vision_factor()).is_less(1.0)

	assert_bool(fleet.strike("runoff_drone", "stomp")).is_true()
	assert_bool(fleet.has_active_aura()).override_failure_message(
		"a knocked-over drone is not venting").is_false()
	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)
	assert_array(cleared).contains(["runoff_drone"])

	# Walking back into the volume of a machine you just disabled must not
	# debuff you anyway — the refusal is at entry, not a later clean-up.
	assert_bool(fleet.enter_aura("runoff_drone")).is_false()
	assert_bool(fleet.has_active_aura()).is_false()


func test_req_012_a_disabled_dredger_neither_dredges_nor_costs_a_life() -> void:
	# The area wipe is the only enemy lane that can take a life, so it is the
	# one where a missed guard costs the most.
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var lives := LifeSystem.new(tuning)
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	restoration.declare_from_manifest(
		{"restorableRegions": [{"regionId": "reef"}]}, errors)
	fleet.set_life_system(lives)
	fleet.set_restoration(restoration)

	assert_bool(fleet.strike("dredger", "tail_whack")).is_true()

	var before: int = lives.get_lives()
	assert_bool(fleet.area_wipe("dredger")).override_failure_message(
		"a disabled Dredger must not be able to spend a life").is_false()
	assert_int(lives.get_lives()).is_equal(before)
	assert_bool(fleet.strike_region("dredger", "reef")).override_failure_message(
		"nor revert a region").is_false()


func test_req_012_a_disabled_hookline_cannot_take_the_equipped_mod() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var registry := GillModRegistry.new(tuning)
	registry.load_directory("res://core/gillmod/mods")
	var mods := GillModSystem.new(tuning, registry)
	fleet.set_gill_mods(mods)

	assert_bool(fleet.strike("hookline_rig", "stomp")).is_true()
	assert_bool(fleet.contact("hookline_rig")).override_failure_message(
		"a knocked-over rig has no line to snag with").is_false()


func test_req_012_disabling_one_machine_leaves_the_others_alone() -> void:
	# Knocking one machine over must not knock the roster over.
	#
	# A LIMITATION WORTH NAMING RATHER THAN HIDING: the knock-out is keyed by
	# ROSTER ID, not by placed node, so two Netbots in one level share a single
	# disabled state and striking either one disables both. No shipped world
	# places two of anything, so nothing is wrong today; a world that wanted a
	# pair of Netbots would need the strike lane keyed by node, which is a
	# change to how WorldSystems resolves a strike rather than to this file.
	var fleet := _fleet(_tuning())
	assert_bool(fleet.strike("netbot", "tail_whack")).is_true()
	assert_bool(fleet.is_disabled("netbot")).is_true()
	assert_bool(fleet.is_disabled("dredger")).is_false()
	assert_bool(fleet.is_disabled("runoff_drone")).is_false()
	assert_bool(fleet.enter_aura("runoff_drone")).override_failure_message(
		"an untouched machine keeps working").is_true()
