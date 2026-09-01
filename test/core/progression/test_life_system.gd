extends GdUnitTestSuite

## Lives and Checkpoint System — REQ-003.
##
## Test names carry the requirement id they prove (test_req_003_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"

## Sources that must NEVER cost a life. The criterion is negative, so this is an
## exhaustive allowlist rather than a handful of spot checks — the enemy added
## next month is the one a spot check would miss.
const ORDINARY_SOURCES: PackedStringArray = [
	"netbot", "hookline_rig", "runoff_drone", "dredger", "flagship",
	"toxin_cloud", "ghost_net", "spike", "enemy_contact", "collision",
	"tail", "gill", "leg", "capability_loss", "fall", "water", "",
	# Near-misses: the closed set is matched EXACTLY, so none of these leak.
	"pit", "pit_volume_decoration", "PIT_VOLUME", "crush", "boss",
	"dredger_area", "dredger_area_wipe_zone",
]

## Words that would mean this node had grown a way to restart a world or punish
## a save. AC-4 forbids both.
const RESTART_VOCABULARY: PackedStringArray = [
	"restart", "reload_world", "reset_world", "new_game", "wipe_save",
	"penal", "erase", "delete_save",
]

const PROGRESSION_SOURCES: PackedStringArray = [
	"res://core/progression/catastrophic_source.gd",
	"res://core/progression/checkpoint.gd",
	"res://core/progression/checkpoint_graph.gd",
	"res://core/progression/capability_restorer.gd",
	"res://core/progression/checkpoint_store.gd",
	"res://core/progression/save_checkpoint_store.gd",
	"res://core/progression/life_system.gd",
]

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("progression")


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


## A three-checkpoint world whose segments all sit inside the tuned bound.
func _graph(max_seconds: float) -> CheckpointGraph:
	var graph := CheckpointGraph.new("coral_cove")
	graph.add(Checkpoint.new("cp_reef", Vector3(10.0, 0.0, 0.0), max_seconds * 0.5))
	graph.add(Checkpoint.new("cp_trench", Vector3(20.0, -5.0, 0.0), max_seconds * 0.8))
	graph.add(Checkpoint.new("cp_shelf", Vector3(30.0, 2.0, 0.0), max_seconds))
	return graph


func _system(contract: Dictionary = {}) -> LifeSystem:
	var tuning := _tuning()
	var system := LifeSystem.new(tuning)
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")), contract)
	return system


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


## Counts what it was asked to do, so a test can assert a path was NOT taken.
class CountingRestorer extends CapabilityRestorer:
	var calls: int = 0

	func restore_all() -> int:
		calls += 1
		return 3


class CountingStore extends CheckpointStore:
	var writes: int = 0
	var remembered: String = ""

	func persist_checkpoint(_world_id: String, checkpoint_id: String) -> void:
		writes += 1
		remembered = checkpoint_id

	func load_checkpoint(_world_id: String) -> String:
		return remembered


# --- AC-1: lives decrement only from the designated catastrophic sources ---

func test_req_003_every_designated_catastrophic_source_costs_a_life() -> void:
	for source_id: String in CatastrophicSource.all_ids():
		var system := _system()
		var before := system.get_lives()

		assert_bool(system.report_catastrophe(source_id)).override_failure_message(
			"REQ-003 AC-1: '%s' is designated catastrophic and must cost a life"
			% source_id
		).is_true()
		assert_int(system.get_lives()).is_equal(before - 1)


func test_req_003_the_catastrophic_set_is_exactly_the_four_named_sources() -> void:
	# The requirement names four. A fifth appearing here without the requirement
	# changing would widen the hard-failure layer silently.
	var ids := CatastrophicSource.all_ids()
	assert_int(ids.size()).is_equal(4)
	assert_array(ids).contains([
		"pit_volume", "crush_hazard", "boss_finisher", "dredger_area_wipe"])


func test_req_003_source_matching_is_exact_never_a_prefix() -> void:
	# A prefix rule would let "pit_volume_decoration" spend a life, and the whole
	# value of a closed set is that widening it takes an edit to the file.
	assert_bool(CatastrophicSource.is_catastrophic("pit_volume")).is_true()
	assert_bool(CatastrophicSource.is_catastrophic("pit_volume_decoration")).is_false()
	assert_bool(CatastrophicSource.is_catastrophic("pit")).is_false()
	assert_int(CatastrophicSource.from_id("nonsense")).is_equal(
		CatastrophicSource.UNKNOWN)


# --- AC-2: ordinary enemy and hazard contact never decrements lives --------

func test_req_003_no_ordinary_source_can_ever_cost_a_life() -> void:
	var system := _system()
	var full := system.get_lives()
	var losses: Array[int] = []
	system.life_lost.connect(
		func(remaining: int, _s: CatastrophicSource.Kind) -> void:
			losses.append(remaining))

	for source_id: String in ORDINARY_SOURCES:
		assert_bool(system.report_catastrophe(source_id)).override_failure_message(
			"REQ-003 AC-2: '%s' must never decrement a life" % source_id
		).is_false()

	assert_int(system.get_lives()).override_failure_message(
		"REQ-003 AC-2: %d ordinary sources left the life count changed"
		% ORDINARY_SOURCES.size()
	).is_equal(full)
	assert_array(losses).is_empty()


func test_req_003_every_declared_hazard_is_refused_unless_designated() -> void:
	# Tied to the hazard vocabulary REQ-019 already declares, so a hazard added
	# to the game later cannot quietly become life-costing without someone
	# noticing here. Ordinary Dredger contact is refused; only its area-wipe
	# attack is in the set, which is exactly the distinction the requirement draws.
	var system := _system()
	var full := system.get_lives()

	for state_id: String in FeedbackTable.HAZARDS:
		var hazard := state_id.trim_prefix("hazard.")
		assert_bool(system.report_catastrophe(hazard)).override_failure_message(
			"REQ-003 AC-2: hazard '%s' must not cost a life by contact" % hazard
		).is_false()

	assert_int(system.get_lives()).is_equal(full)


func test_req_003_capability_loss_and_a_life_loss_are_separate_layers() -> void:
	# The boundary REQ-002 refuses to cross from its side, asserted from this one:
	# the real Regeneration system strips every capability and the life count is
	# untouched.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	var system := LifeSystem.new(tuning)
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")))
	var full := system.get_lives()

	for kind: Capability.Kind in Capability.ALL:
		regen.apply_damage(DamageEvent.new("netbot", kind))

	assert_int(regen.count_lost()).is_equal(3)
	assert_int(system.get_lives()).override_failure_message(
		"REQ-003 AC-2: losing every capability must not cost a single life"
	).is_equal(full)


# --- AC-3: zero lives respawns at the last checkpoint, replenished --------

func test_req_003_zero_lives_respawns_at_the_last_activated_checkpoint() -> void:
	var system := _system()
	assert_bool(system.activate_checkpoint("cp_trench")).is_true()

	var landed: Array[Vector3] = []
	var anchors: Array[String] = []
	system.respawned.connect(
		func(position: Vector3, checkpoint_id: String, _n: int) -> void:
			landed.append(position)
			anchors.append(checkpoint_id))

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("pit_volume")

	assert_int(landed.size()).override_failure_message(
		"REQ-003 AC-3: reaching zero lives must respawn exactly once"
	).is_equal(1)
	assert_array(anchors).contains(["cp_trench"])
	assert_bool(landed[0].is_equal_approx(Vector3(20.0, -5.0, 0.0))).is_true()


func test_req_003_the_life_count_is_replenished_on_respawn() -> void:
	var system := _system()
	system.activate_checkpoint("cp_reef")
	var per_attempt := system.get_lives_per_attempt()

	for _spend: int in range(per_attempt):
		system.report_catastrophe("crush_hazard")

	assert_int(system.get_lives()).override_failure_message(
		"REQ-003 AC-3: the life count must come back full, not stay at zero"
	).is_equal(per_attempt)


func test_req_003_exhaustion_is_announced_before_the_respawn() -> void:
	# The setback beat needs somewhere to hang; it is not a failure state.
	var system := _system()
	system.activate_checkpoint("cp_reef")
	var order: Array[String] = []
	system.lives_exhausted.connect(func() -> void: order.append("exhausted"))
	system.respawned.connect(
		func(_p: Vector3, _c: String, _n: int) -> void: order.append("respawned"))

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("boss_finisher")

	assert_array(order).is_equal(["exhausted", "respawned"] as Array[String])


func test_req_003_without_a_checkpoint_the_respawn_falls_back_to_spawn() -> void:
	var system := _system()
	system.set_spawn_point(Vector3(1.0, 2.0, 3.0))
	assert_bool(system.has_active_checkpoint()).is_false()

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("dredger_area_wipe")

	assert_bool(system.get_respawn_position().is_equal_approx(Vector3(1.0, 2.0, 3.0))
	).override_failure_message(
		"before the first checkpoint the spawn is the only anchor that exists"
	).is_true()


# --- AC-4: never a world restart, never a save write ----------------------

func test_req_003_the_system_has_no_channel_that_could_restart_a_world() -> void:
	var script: GDScript = LifeSystem.new(_tuning()).get_script()

	for method_row: Dictionary in script.get_script_method_list():
		var method_name := String(method_row["name"]).to_lower()
		for word: String in RESTART_VOCABULARY:
			assert_bool(method_name.contains(word)).override_failure_message(
				"REQ-003 AC-4: method '%s' looks like a world restart" % method_name
			).is_false()

	for signal_row: Dictionary in script.get_script_signal_list():
		var signal_name := String(signal_row["name"]).to_lower()
		for word: String in RESTART_VOCABULARY:
			assert_bool(signal_name.contains(word)).override_failure_message(
				"REQ-003 AC-4: signal '%s' looks like a world restart" % signal_name
			).is_false()


func test_req_003_a_respawn_writes_nothing_to_the_checkpoint_store() -> void:
	var system := _system()
	var store := CountingStore.new()
	system.set_checkpoint_store(store)

	system.activate_checkpoint("cp_reef")
	var writes_after_activation := store.writes
	assert_int(writes_after_activation).is_greater(0)

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("pit_volume")

	assert_int(store.writes).override_failure_message(
		"REQ-003 AC-4: reaching zero lives must not touch the save"
	).is_equal(writes_after_activation)


func test_req_003_a_respawn_leaves_the_real_save_file_byte_identical() -> void:
	# The strongest form of the criterion: a real SaveSystem, a real file on
	# disk, and the actual bytes compared across the respawn. A well-meaning
	# "autosave on death" added later fails here.
	var path := _temp_dir.path_join("profile.json")
	var save := SaveSystem.new()
	save.open_world("coral_cove", {})
	assert_bool(save.save_to_file(path)).is_true()
	var before := _read(path)

	var tuning := _tuning()
	var system := LifeSystem.new(tuning)
	system.set_checkpoint_store(SaveCheckpointStore.new(save))
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")))
	system.activate_checkpoint("cp_shelf")

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("crush_hazard")

	assert_str(_read(path)).override_failure_message(
		"REQ-003 AC-4: the save file changed across a zero-lives respawn"
	).is_equal(before)


func test_req_003_a_respawn_does_not_return_the_player_to_the_world_start() -> void:
	# "Never restarts the world from the beginning", asserted positionally: the
	# respawn lands on the checkpoint, not on the spawn point.
	var system := _system()
	system.set_spawn_point(Vector3.ZERO)
	system.activate_checkpoint("cp_shelf")

	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("pit_volume")

	assert_bool(system.get_respawn_position().is_equal_approx(Vector3.ZERO)
	).override_failure_message(
		"REQ-003 AC-4: a respawn must not send the player back to the start"
	).is_false()
	assert_str(system.get_active_checkpoint()).is_equal("cp_shelf")


# --- AC-5: activating a checkpoint -----------------------------------------

func test_req_003_activation_records_the_respawn_position() -> void:
	var system := _system()
	assert_bool(system.activate_checkpoint("cp_trench")).is_true()

	assert_str(system.get_active_checkpoint()).is_equal("cp_trench")
	assert_bool(system.get_respawn_position().is_equal_approx(Vector3(20.0, -5.0, 0.0))
	).is_true()


func test_req_003_activation_replenishes_lives() -> void:
	var system := _system()
	system.report_catastrophe("pit_volume")
	assert_int(system.get_lives()).is_less(system.get_lives_per_attempt())

	system.activate_checkpoint("cp_reef")

	assert_int(system.get_lives()).is_equal(system.get_lives_per_attempt())


func test_req_003_activation_restores_capability_through_the_interface() -> void:
	var system := _system()
	var restorer := CountingRestorer.new()
	system.set_capability_restorer(restorer)

	system.activate_checkpoint("cp_reef")

	assert_int(restorer.calls).override_failure_message(
		"REQ-003 AC-5: activation must restore capability state"
	).is_equal(1)


func test_req_003_a_checkpoint_restores_the_real_regeneration_system() -> void:
	# Integration tier: the actual RegenSystem, reached only through the port.
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	var system := LifeSystem.new(tuning)
	system.set_capability_restorer(regen)
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")))

	for kind: Capability.Kind in Capability.ALL:
		regen.apply_damage(DamageEvent.new("netbot", kind))
	assert_int(regen.count_lost()).is_equal(3)

	system.activate_checkpoint("cp_reef")

	assert_bool(regen.is_fully_intact()).override_failure_message(
		"REQ-003 AC-5: a checkpoint must restore capability state for real"
	).is_true()


func test_req_003_a_respawn_also_restores_capability_state() -> void:
	var tuning := _tuning()
	var regen := RegenSystem.new(tuning)
	var system := LifeSystem.new(tuning)
	system.set_capability_restorer(regen)
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")))
	system.activate_checkpoint("cp_reef")

	regen.apply_damage(DamageEvent.new("netbot", Capability.Kind.TAIL))
	for _spend: int in range(system.get_lives_per_attempt()):
		system.report_catastrophe("pit_volume")

	assert_bool(regen.is_fully_intact()).is_true()


func test_req_003_an_undeclared_checkpoint_cannot_be_activated() -> void:
	var system := _system()
	assert_bool(system.activate_checkpoint("cp_nowhere")).is_false()
	assert_bool(system.has_active_checkpoint()).is_false()


func test_req_003_a_remembered_checkpoint_is_restored_on_world_load() -> void:
	var tuning := _tuning()
	var store := CountingStore.new()
	var max_retry := tuning.get_number("progression.max_retry_seconds")

	var first := LifeSystem.new(tuning)
	first.set_checkpoint_store(store)
	first.open_world("coral_cove", _graph(max_retry))
	first.activate_checkpoint("cp_trench")

	# A later session, same store.
	var second := LifeSystem.new(tuning)
	second.set_checkpoint_store(store)
	second.open_world("coral_cove", _graph(max_retry))

	assert_str(second.get_active_checkpoint()).is_equal("cp_trench")


# --- AC-6: the lives-per-attempt override ---------------------------------

func test_req_003_the_global_default_applies_when_a_world_declares_nothing() -> void:
	var tuning := _tuning()
	var system := _system()

	assert_int(system.get_lives_per_attempt()).is_equal(
		tuning.get_count("progression.default_lives_per_attempt"))


func test_req_003_a_world_can_declare_a_lives_override() -> void:
	var system := _system({LifeSystem.CONTRACT_LIVES_FIELD: 5})

	assert_int(system.get_lives_per_attempt()).override_failure_message(
		"REQ-003 AC-6: a world's declared override must be honoured"
	).is_equal(5)
	assert_int(system.get_lives()).is_equal(5)


func test_req_003_an_out_of_range_override_falls_back_to_the_default() -> void:
	# The permitted range in the tuning data is the balance decision; a world does
	# not get to leave it by declaring 9999 lives.
	var tuning := _tuning()
	var default_lives := tuning.get_count("progression.default_lives_per_attempt")
	var bounds := tuning.get_permitted_range("progression.default_lives_per_attempt")

	for absurd: int in [int(bounds[1]) + 1, int(bounds[0]) - 1, -5, 0]:
		var system := _system({LifeSystem.CONTRACT_LIVES_FIELD: absurd})
		assert_int(system.get_lives_per_attempt()).override_failure_message(
			"REQ-003 AC-6: override %d is outside the permitted range and must "
			% absurd + "fall back to the global default"
		).is_equal(default_lives)


func test_req_003_the_override_is_resolved_once_at_world_load() -> void:
	# "Resolve at world load and hold one effective value" — a contract mutated
	# afterwards must not change the attempt in progress.
	var tuning := _tuning()
	var contract := {LifeSystem.CONTRACT_LIVES_FIELD: 5}
	var system := LifeSystem.new(tuning)
	system.open_world("coral_cove",
		_graph(tuning.get_number("progression.max_retry_seconds")), contract)

	contract[LifeSystem.CONTRACT_LIVES_FIELD] = 99

	assert_int(system.get_lives_per_attempt()).override_failure_message(
		"the effective value must be resolved once, not re-read per decrement"
	).is_equal(5)


func test_req_003_the_override_set_is_the_tuning_surfaces_closed_list() -> void:
	# One list, not two. If lives ever stopped being world-overridable in the
	# tuning data, this node must stop honouring the override.
	assert_bool(_tuning().is_world_overridable(
		"progression.default_lives_per_attempt")
	).is_true()


# --- AC-7: checkpoint spacing ----------------------------------------------

func test_req_003_a_conforming_world_reports_no_failing_segments() -> void:
	var system := _system()

	assert_array(system.failing_checkpoint_segments()).is_empty()
	assert_bool(system.world_spacing_conforms()).is_true()


func test_req_003_a_segment_over_the_bound_is_named() -> void:
	var tuning := _tuning()
	var max_retry := tuning.get_number("progression.max_retry_seconds")
	var graph := CheckpointGraph.new("bad_world")
	graph.add(Checkpoint.new("cp_ok", Vector3.ZERO, max_retry * 0.5))
	graph.add(Checkpoint.new("cp_long", Vector3.ONE, max_retry + 0.1))

	var offenders := graph.segments_over(max_retry)

	assert_array(offenders).override_failure_message(
		"REQ-003 AC-7: the report must name WHICH stretch to break up"
	).contains(["cp_long"])
	assert_int(offenders.size()).is_equal(1)
	assert_bool(graph.conforms_to(max_retry)).is_false()


func test_req_003_a_segment_exactly_on_the_bound_conforms() -> void:
	# The criterion says "at or below".
	var max_retry := _tuning().get_number("progression.max_retry_seconds")
	var graph := CheckpointGraph.new("edge_world")
	graph.add(Checkpoint.new("cp_edge", Vector3.ZERO, max_retry))

	assert_bool(graph.conforms_to(max_retry)).is_true()


func test_req_003_a_world_with_no_checkpoints_does_not_conform() -> void:
	# The guard against a vacuous pass: a world with no checkpoints has unbounded
	# replay, and returning true for it would let the compliance check succeed
	# over exactly the worlds most in need of it.
	var graph := CheckpointGraph.new("empty_world")

	assert_bool(graph.conforms_to(
		_tuning().get_number("progression.max_retry_seconds"))
	).override_failure_message(
		"REQ-003 AC-7: an empty checkpoint graph must not pass the spacing check"
	).is_false()


func test_req_003_the_checkpoint_list_is_queryable_data() -> void:
	# AC-7 can only be checked by walking a list. A headless test cannot walk a
	# scene tree looking for Area3Ds, so the world declares data.
	var system := _system()
	var graph := system.get_checkpoint_graph()

	assert_int(graph.size()).is_equal(3)
	assert_array(graph.get_checkpoint_ids()).contains(
		["cp_reef", "cp_trench", "cp_shelf"])
	assert_object(graph.find("cp_reef")).is_not_null()


func test_req_003_a_graph_refuses_duplicate_or_invalid_checkpoints() -> void:
	var graph := CheckpointGraph.new("w")
	assert_bool(graph.add(Checkpoint.new("cp", Vector3.ZERO, 1.0))).is_true()
	assert_bool(graph.add(Checkpoint.new("cp", Vector3.ONE, 2.0))).override_failure_message(
		"a duplicate id would make the recorded respawn anchor ambiguous"
	).is_false()
	assert_bool(graph.add(Checkpoint.new("", Vector3.ZERO, 1.0))).is_false()
	assert_bool(graph.add(Checkpoint.new("neg", Vector3.ZERO, -1.0))).is_false()
	assert_int(graph.size()).is_equal(1)


# --- No magic numbers ------------------------------------------------------

func test_req_003_every_progression_tuning_key_exists_in_the_surface() -> void:
	var data := _tuning()
	for key: String in [LifeSystem.DEFAULT_LIVES_KEY, LifeSystem.MAX_RETRY_KEY]:
		assert_bool(data.has_key(key)).override_failure_message(
			"REQ-003: the life system reads '%s', which the tuning surface lacks" % key
		).is_true()


func test_req_003_life_system_declares_no_balance_constants() -> void:
	var text := _read("res://core/progression/life_system.gd")
	assert_bool(text.contains("_tuning.get_count")
		or text.contains("_tuning.get_number")).is_true()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_progression_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in PROGRESSION_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
