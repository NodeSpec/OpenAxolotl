extends GdUnitTestSuite

## Fighting a Drift Fleet machine (REQ-012, REQ-019).
##
## Until strikes existed the enemy system ran one way: the machines acted on
## the player, and the player's only answer was to route around them. What is
## held here is that a strike is a real answer, that it takes the number of
## them the machine's own declaration asks for, and that the win it earns is
## bounded.
##
##   DURABILITY IS DATA AND IT IS A SPREAD. Every machine declares how many
##   strikes it takes, the runtime reads it rather than knowing it, and the
##   four shipped machines declare four different numbers — a roster where they
##   all took the same number of hits would pass a test that only ever looked
##   at one of them, and would have no texture in play.
##
##   A STRIKE SHORT OF DURABILITY STAGGERS, AND THE MACHINE COMES BACK. That is
##   the feedback that the hit landed. It is not the win, and a test that
##   confused the two would let a one-hit stagger ship as a one-hit kill.
##
##   THE STRIKE THAT REACHES DURABILITY DEFEATS, AND IT STAYS DEFEATED. Every
##   effect lane refuses it, and each lane is asked separately rather than
##   through one shared guard — a check that covered contact and not the aura
##   would leave a beaten drone still venting, which is exactly the kind of gap
##   "it is defeated" hides.
##
##   IT RELEASES WHAT THE MACHINE ALREADY DID, on both outcomes. A Netbot whose
##   net survived the whack that knocked it over would make the strike a thing
##   you do after the danger rather than about it.
##
##   AND IT IS ONLY FOR THE ATTEMPT. These are machines being knocked over, not
##   things being killed (REQ-019 AC-5), and a level a player can permanently
##   empty stops being a route problem the second time they walk it. So the
##   respawn reset is asserted as hard as the defeat.

const TUNING_PATH := "res://core/tuning/tuning.json"

## The ladder the shipped roster declares. Restated here on purpose: this is
## the balance decision REQ-012 names, and a test that read the numbers out of
## the same JSON it is checking would assert only that the file parses.
const DECLARED_DURABILITY := {
	"netbot": 1,
	"hookline_rig": 2,
	"runoff_drone": 3,
	"dredger": 4,
}


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


## Strikes [param enemy_id] until it goes down, asserting it took exactly the
## number of hits it declared and staggered for every one before the last.
func _fell_after(fleet: DriftFleetSystem, enemy_id: String) -> int:
	# The ceiling is generous on purpose: a machine that never goes down should
	# fail with -1 rather than hang the suite.
	var swings := 0
	while swings < EnemyDef.MAX_DURABILITY + 3:
		swings += 1
		var result := fleet.strike(enemy_id, "tail_whack")
		if result == DriftFleetSystem.StrikeResult.DEFEATED:
			return swings
		assert_int(result).override_failure_message(
			"strike %d on '%s' neither staggered nor defeated it"
			% [swings, enemy_id]).is_equal(DriftFleetSystem.StrikeResult.STAGGERED)
	return -1


# --- Durability is declared, and it is a spread ------------------------------

func test_req_012_every_machine_declares_what_it_takes_to_put_down() -> void:
	var registry := EnemyRegistry.new(_tuning())
	var errors: Array[EnemyError] = []
	registry.load_directory(EnemyRegistry.ROSTER_DIRECTORY, errors)
	assert_array(errors).is_empty()

	var seen: Array[int] = []
	for enemy_id: String in registry.get_ids():
		var def := registry.get_enemy(enemy_id)
		assert_bool(DECLARED_DURABILITY.has(enemy_id)).override_failure_message(
			("'%s' is in the shipped roster but not in this test's ladder — a "
			+ "new machine needs a durability decision, not a default")
			% enemy_id).is_true()
		assert_int(def.durability).override_failure_message(
			"'%s' declares durability %d; the ladder says %s"
			% [enemy_id, def.durability, str(DECLARED_DURABILITY.get(enemy_id))]
			).is_equal(int(DECLARED_DURABILITY[enemy_id]))
		assert_int(def.durability).is_between(1, EnemyDef.MAX_DURABILITY)
		seen.append(def.durability)

	# THE SPREAD ITSELF, not just the numbers. A roster where every machine
	# took the same count would satisfy every assertion above and would still
	# be the failure this requirement is about.
	assert_int(seen.min()).override_failure_message(
		"exactly one machine must be a one-hit knockout").is_equal(1)
	assert_int(seen.max()).override_failure_message(
		"and at least one must take several").is_greater_equal(3)
	assert_int(seen.count(1)).override_failure_message(
		"more than one one-hit machine and the payoff stops being special"
		).is_equal(1)


func test_req_012_a_durability_outside_the_range_is_refused_not_clamped() -> void:
	# A roster asking for zero strikes wants a machine that is already beaten
	# when the level loads. Quietly correcting that hides it.
	for bad: Variant in [0, -3, EnemyDef.MAX_DURABILITY + 1, "two", 2.5]:
		var errors: Array[EnemyError] = []
		var def := EnemyDef.from_dictionary({
			"id": "probe",
			"displayName": "Probe",
			"behavior": "entangle",
			"targetCapability": "swim_speed",
			"durationKey": "enemy.netbot.entangle_seconds",
			"factorKey": "enemy.netbot.swim_speed_multiplier",
			"audioCueId": "enemy_probe",
			"durability": bad,
		}, errors)
		assert_object(def).override_failure_message(
			"durability %s must be refused" % str(bad)).is_null()
		assert_array(errors).override_failure_message(
			"and refused with a reason naming the field").is_not_empty()


# --- Stagger, and the recovery that makes it a stagger -----------------------

func test_req_012_a_strike_short_of_durability_staggers_and_wears_off() -> void:
	var tuning := _tuning()
	var seconds := tuning.get_number(DriftFleetSystem.STAGGER_SECONDS_KEY)
	var fleet := _fleet(tuning)
	var reeled: Array = []
	var up: Array = []
	fleet.enemy_staggered.connect(
		func(id: String, kind: String, left: float) -> void:
			reeled.append({"id": id, "kind": kind, "seconds": left}))
	fleet.enemy_recovered.connect(func(id: String) -> void: up.append(id))

	# The Dredger takes four, so the first is unambiguously short of it.
	assert_int(fleet.strike("dredger", "tail_whack")).is_equal(
		DriftFleetSystem.StrikeResult.STAGGERED)
	assert_bool(fleet.is_staggered("dredger")).is_true()
	assert_bool(fleet.is_defeated("dredger")).override_failure_message(
		"one hit on a four-hit machine is not a win").is_false()
	assert_int(fleet.strikes_taken("dredger")).is_equal(1)
	assert_int(fleet.strikes_remaining("dredger")).is_equal(3)

	assert_int(reeled.size()).is_equal(1)
	assert_str(reeled[0]["kind"]).override_failure_message(
		"the strike that landed is named, so a cue can differ by kind"
		).is_equal("tail_whack")
	assert_float(reeled[0]["seconds"]).is_equal_approx(seconds, 0.0001)

	for _step: int in range(int(seconds / 0.1) + 2):
		fleet.tick(0.1)
	assert_bool(fleet.is_staggered("dredger")).override_failure_message(
		"a machine that only reeled must right itself").is_false()
	assert_array(up).contains(["dredger"])

	# And it works again once it has — while REMEMBERING the hit it took.
	assert_bool(fleet.strike_region("dredger", "reef")).is_false()  # no system
	assert_int(fleet.strikes_taken("dredger")).override_failure_message(
		("recovering must not heal: a player who lands three hits, dies to "
		+ "nothing, and comes back would be starting the fight over")
		).is_equal(1)


func test_req_012_a_staggered_machine_can_be_struck_again() -> void:
	# Chaining is what makes a tough machine one long exchange rather than four
	# separate approaches. The window it replaced refused the second hit.
	var fleet := _fleet(_tuning())
	assert_int(fleet.strike("dredger")).is_equal(
		DriftFleetSystem.StrikeResult.STAGGERED)
	assert_int(fleet.strike("dredger")).override_failure_message(
		"a machine still reeling must be hittable, or toughness means waiting"
		).is_equal(DriftFleetSystem.StrikeResult.STAGGERED)
	assert_int(fleet.strikes_taken("dredger")).is_equal(2)


# --- Defeat -------------------------------------------------------------------

func test_req_012_the_netbot_goes_down_to_one_strike() -> void:
	var fleet := _fleet(_tuning())
	var down: Array = []
	fleet.enemy_defeated.connect(
		func(id: String, kind: String) -> void:
			down.append({"id": id, "kind": kind}))

	assert_int(fleet.strike("netbot", "spin_sprint")).override_failure_message(
		"the Netbot is the one-hit knockout; a stagger here is the whole "
		+ "balance decision lost").is_equal(DriftFleetSystem.StrikeResult.DEFEATED)
	assert_bool(fleet.is_defeated("netbot")).is_true()
	assert_bool(fleet.is_staggered("netbot")).override_failure_message(
		"a machine that is down is not also reeling").is_false()
	assert_int(down.size()).is_equal(1)
	assert_str(down[0]["kind"]).is_equal("spin_sprint")


func test_req_012_each_machine_takes_exactly_the_strikes_it_declares() -> void:
	for enemy_id: String in DECLARED_DURABILITY:
		var fleet := _fleet(_tuning())
		assert_int(_fell_after(fleet, enemy_id)).override_failure_message(
			"'%s' declares %d strikes" % [enemy_id,
			int(DECLARED_DURABILITY[enemy_id])]
			).is_equal(int(DECLARED_DURABILITY[enemy_id]))
		assert_int(fleet.strikes_remaining(enemy_id)).override_failure_message(
			"a beaten machine has nothing left in it").is_equal(0)


func test_req_012_a_defeated_machine_never_gets_back_up_on_its_own() -> void:
	# The difference between this and the timed knock-out it replaced. A minute
	# of ticks is far past any window this game has ever tuned.
	var fleet := _fleet(_tuning())
	assert_int(fleet.strike("netbot")).is_equal(
		DriftFleetSystem.StrikeResult.DEFEATED)
	for _step: int in range(600):
		fleet.tick(0.1)
	assert_bool(fleet.is_defeated("netbot")).override_failure_message(
		"defeat must not be a long stagger").is_true()
	assert_bool(fleet.contact("netbot")).is_false()


func test_req_012_striking_an_unknown_machine_is_refused() -> void:
	var fleet := _fleet(_tuning())
	assert_int(fleet.strike("not_a_machine", "stomp")).is_equal(
		DriftFleetSystem.StrikeResult.MISSED)
	assert_bool(fleet.is_defeated("not_a_machine")).is_false()
	assert_bool(fleet.is_inert("not_a_machine")).is_false()


func test_req_012_striking_a_machine_that_is_already_down_is_a_swing_at_air() -> void:
	var fleet := _fleet(_tuning())
	assert_int(fleet.strike("netbot")).is_equal(
		DriftFleetSystem.StrikeResult.DEFEATED)
	assert_int(fleet.strike("netbot")).override_failure_message(
		"a caller must be able to tell a landed hit from a wasted one"
		).is_equal(DriftFleetSystem.StrikeResult.MISSED)


# --- Every effect lane, asked separately --------------------------------------

func test_req_012_a_struck_netbot_neither_entangles_nor_holds_its_net() -> void:
	# The release is the point: the swing that lands on a Netbot is also how
	# you get out of its net. It is a one-hit machine, so this is a defeat.
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

	assert_int(fleet.strike("netbot", "spin_sprint")).is_equal(
		DriftFleetSystem.StrikeResult.DEFEATED)
	assert_bool(fleet.is_entangled()).override_failure_message(
		"knocking the Netbot over must free the player it has caught"
	).is_false()
	assert_array(modifiers.get_factor_ids()).override_failure_message(
		"and take its swim-speed factor off the controller with it"
	).not_contains([factor])
	assert_array(escapes).contains(["netbot"])

	# Down, it cannot catch them again.
	assert_bool(fleet.contact("netbot")).override_failure_message(
		"a defeated machine must be inert, not merely quiet").is_false()


func test_req_012_a_merely_staggered_machine_also_lets_go() -> void:
	# The release is not a side effect of defeat: a hit that only reeled the
	# machine must still be a hit the player can feel. Only a machine tough
	# enough to survive one strike can show this, so the Drone is used.
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var cleared: Array = []
	fleet.aura_cleared.connect(func(id: String) -> void: cleared.append(id))

	assert_bool(fleet.enter_aura("runoff_drone")).is_true()
	assert_float(fleet.vision_factor()).is_less(1.0)

	assert_int(fleet.strike("runoff_drone", "stomp")).is_equal(
		DriftFleetSystem.StrikeResult.STAGGERED)
	assert_bool(fleet.has_active_aura()).override_failure_message(
		"a drone knocked reeling is not venting").is_false()
	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)
	assert_array(cleared).contains(["runoff_drone"])

	# Walking back into the volume of a machine you just hit must not debuff
	# you anyway — the refusal is at entry, not a later clean-up.
	assert_bool(fleet.enter_aura("runoff_drone")).is_false()
	assert_bool(fleet.has_active_aura()).is_false()


func test_req_012_a_defeated_drone_stops_venting_for_good() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	assert_int(_fell_after(fleet, "runoff_drone")).is_equal(3)

	# Past any stagger window, so a lane that recovered would show here.
	for _step: int in range(200):
		fleet.tick(0.1)
	assert_bool(fleet.enter_aura("runoff_drone")).override_failure_message(
		"a beaten drone must stay beaten").is_false()
	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)


func test_req_012_a_defeated_dredger_neither_dredges_nor_costs_a_life() -> void:
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

	assert_int(_fell_after(fleet, "dredger")).is_equal(4)

	var before: int = lives.get_lives()
	assert_bool(fleet.area_wipe("dredger")).override_failure_message(
		"a defeated Dredger must not be able to spend a life").is_false()
	assert_int(lives.get_lives()).is_equal(before)
	assert_bool(fleet.strike_region("dredger", "reef")).override_failure_message(
		"nor revert a region").is_false()


func test_req_012_a_staggered_dredger_is_just_as_harmless_while_it_reels() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var lives := LifeSystem.new(tuning)
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	restoration.declare_from_manifest(
		{"restorableRegions": [{"regionId": "reef"}]}, errors)
	fleet.set_life_system(lives)
	fleet.set_restoration(restoration)

	assert_int(fleet.strike("dredger", "tail_whack")).is_equal(
		DriftFleetSystem.StrikeResult.STAGGERED)
	var before: int = lives.get_lives()
	assert_bool(fleet.area_wipe("dredger")).is_false()
	assert_int(lives.get_lives()).is_equal(before)

	# But it comes back, and this is the half that separates stagger from
	# defeat: after the window it can hurt you again. Asserted through the
	# LIFE lane rather than the region one, because it is the lane where a
	# guard that stayed shut or opened wrongly costs the most.
	for _step: int in range(int(
			tuning.get_number(DriftFleetSystem.STAGGER_SECONDS_KEY) / 0.1) + 2):
		fleet.tick(0.1)
	assert_bool(fleet.area_wipe("dredger")).override_failure_message(
		"a machine that merely reeled must work again").is_true()
	assert_int(lives.get_lives()).is_equal(before - 1)


func test_req_012_a_defeated_hookline_cannot_take_the_equipped_mod() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var registry := GillModRegistry.new(tuning)
	registry.load_directory("res://core/gillmod/mods")
	var mods := GillModSystem.new(tuning, registry)
	fleet.set_gill_mods(mods)

	assert_int(_fell_after(fleet, "hookline_rig")).is_equal(2)
	assert_bool(fleet.contact("hookline_rig")).override_failure_message(
		"a beaten rig has no line to snag with").is_false()


func test_req_012_beating_one_machine_leaves_the_others_alone() -> void:
	# Knocking one machine over must not knock the roster over.
	#
	# This suite names its machines by ROSTER ID, which the runtime resolves as
	# a unit of that name — the one-of-a-kind case. Two machines of the SAME
	# kind being two separate fights is the other half, and it is held where the
	# placement lives: test/hub/test_world_drift_fleet.gd.
	var fleet := _fleet(_tuning())
	assert_int(fleet.strike("netbot", "tail_whack")).is_equal(
		DriftFleetSystem.StrikeResult.DEFEATED)
	assert_bool(fleet.is_defeated("netbot")).is_true()
	assert_bool(fleet.is_inert("dredger")).is_false()
	assert_bool(fleet.is_inert("runoff_drone")).is_false()
	assert_bool(fleet.enter_aura("runoff_drone")).override_failure_message(
		"an untouched machine keeps working").is_true()


# --- REQ-019: the win is for the attempt, not for the save --------------------

func test_req_019_a_respawn_stands_the_whole_roster_back_up() -> void:
	# A level a player can permanently empty stops being a route problem the
	# second time they walk it, and the second time is exactly when a player
	# who died is walking it.
	var fleet := _fleet(_tuning())
	# An ARRAY rather than an int: a GDScript lambda captures by value, so a
	# counter incremented inside one stays zero outside it.
	var resets: Array[int] = []
	fleet.defeats_reset.connect(func() -> void: resets.append(1))

	assert_int(_fell_after(fleet, "netbot")).is_equal(1)
	assert_int(fleet.strike("dredger")).is_equal(
		DriftFleetSystem.StrikeResult.STAGGERED)
	assert_array(fleet.defeated_ids()).contains(["netbot"])

	fleet.reset_defeats()

	assert_int(resets.size()).is_equal(1)
	assert_array(fleet.defeated_ids()).override_failure_message(
		"nothing stays beaten across a respawn").is_empty()
	assert_bool(fleet.is_defeated("netbot")).is_false()
	assert_bool(fleet.contact("netbot")).override_failure_message(
		"and a machine back on its feet works again").is_true()
	assert_int(fleet.strikes_taken("dredger")).override_failure_message(
		("partial damage goes with it — the run that wore the machine down is "
		+ "over, so the fight starts clean")).is_equal(0)
	assert_bool(fleet.is_staggered("dredger")).is_false()


func test_req_019_resetting_an_untouched_roster_says_nothing() -> void:
	# The respawn handler calls this on every death, most of which happen
	# nowhere near a machine. A signal on each one would make the scene
	# rebuild poses it never changed.
	var fleet := _fleet(_tuning())
	var resets: Array[int] = []
	fleet.defeats_reset.connect(func() -> void: resets.append(1))
	fleet.reset_defeats()
	assert_int(resets.size()).is_equal(0)
