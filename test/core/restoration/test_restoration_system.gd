extends GdUnitTestSuite

## World Restoration State System — REQ-008, pillar three.
##
## Test names carry the requirement id they prove (test_req_008_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"

const RESTORATION_SOURCES: PackedStringArray = [
	"res://core/restoration/region_state.gd",
	"res://core/restoration/restoration_error.gd",
	"res://core/restoration/traversal_gate.gd",
	"res://core/restoration/scene_traversal_gate.gd",
	"res://core/restoration/restoration_store.gd",
	"res://core/restoration/restorable_region.gd",
	"res://core/restoration/restoration_system.gd",
]


## In-memory double for the Save Integration Interface's restoration section.
class FakeStore extends RestorationStore:
	var payload: Dictionary = {}
	var saves: int = 0

	func load_regions() -> Dictionary:
		return payload.duplicate(true)

	func save_regions(p_payload: Dictionary) -> void:
		payload = p_payload.duplicate(true)
		saves += 1


## Records what the scene side would actually do to collision and navigation,
## so "the path opened" is asserted as a real effect rather than as a flag.
class RecordingGate extends TraversalGate:
	var applied: Array[bool] = []

	func _apply_open(open_now: bool) -> void:
		applied.append(open_now)


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


## One region, two gates at different thresholds, so partial progress can be
## told apart from completion.
func _manifest() -> Dictionary:
	return {
		"restorableRegions": [
			{
				"regionId": "kelp_shallows",
				"traversalGates": [
					{"gateId": "silt_channel", "opensAt": "resourced"},
					{"gateId": "kelp_bridge", "opensAt": "restored"},
				],
			},
		],
	}


func _system(store: RestorationStore = null) -> RestorationSystem:
	var system := RestorationSystem.new(_tuning(), store)
	var errors: Array[RestorationError] = []
	assert_bool(system.declare_from_manifest(_manifest(), errors)).is_true()
	assert_array(errors).is_empty()
	return system


func _unlocked_system(store: RestorationStore = null) -> RestorationSystem:
	var system := _system(store)
	system.unlock_region("kelp_shallows")
	return system


func _restore_fully(system: RestorationSystem) -> void:
	var tuning := _tuning()
	var total := tuning.get_count(RegionState.RESOURCED_COST_KEY) \
		+ tuning.get_count(RegionState.RESTORED_COST_KEY)
	system.deliver_resources("kelp_shallows", total)


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


# --- AC-1: exactly three states, plus a SEPARATE boolean flag ---------------

func test_req_008_the_progression_has_exactly_three_states() -> void:
	assert_int(RegionState.ALL.size()).override_failure_message(
		"REQ-008 AC-1: the progression is barren, resourced, restored and "
		+ "nothing else — no intermediate, no 'restoring' transient"
	).is_equal(3)
	assert_array(RegionState.State.keys()).is_equal(
		["BARREN", "RESOURCED", "RESTORED"])


func test_req_008_the_unlocked_flag_is_not_a_fourth_state() -> void:
	# The flag lives on the region as a boolean, never in the enum. If it were a
	# state, AC-6 (revert to barren while STAYING unlocked) could not be
	# expressed at all.
	for state: RegionState.State in RegionState.ALL:
		var id := RegionState.id(state)
		assert_bool(id.contains("lock")).override_failure_message(
			"REQ-008 AC-1: '%s' reads as a lock state; the flag must be separate"
			% id
		).is_false()

	var region := RestorableRegion.new("r", [TraversalGate.new("g")])
	assert_int(typeof(region.is_unlocked())).override_failure_message(
		"the unlocked flag must be a boolean, independent of the state enum"
	).is_equal(TYPE_BOOL)


func test_req_008_a_region_exposes_its_state_and_flag_for_query() -> void:
	var system := _system()
	assert_bool(system.has_region("kelp_shallows")).is_true()
	assert_int(int(system.get_state("kelp_shallows"))).is_equal(
		RegionState.State.BARREN)
	assert_bool(system.is_unlocked("kelp_shallows")).is_false()


# --- AC-2: locked regions cannot progress ----------------------------------

func test_req_008_a_locked_region_cannot_leave_barren_at_any_resource_count() -> void:
	var system := _system()
	var tuning := _tuning()
	var enough := (tuning.get_count(RegionState.RESOURCED_COST_KEY)
		+ tuning.get_count(RegionState.RESTORED_COST_KEY)) * 100

	assert_int(system.deliver_resources("kelp_shallows", enough)).is_equal(0)
	assert_int(int(system.get_state("kelp_shallows"))).override_failure_message(
		"REQ-008 AC-2: the Flagship gates progression; resources alone must "
		+ "never advance a locked region"
	).is_equal(RegionState.State.BARREN)


func test_req_008_resources_delivered_while_locked_are_banked_not_burned() -> void:
	# The player has not wasted them; they simply cannot be spent yet. If they
	# were discarded, unlocking would silently cost the player everything
	# delivered beforehand.
	var system := _system()
	var tuning := _tuning()
	var cost := tuning.get_count(RegionState.RESOURCED_COST_KEY)

	system.deliver_resources("kelp_shallows", cost)
	assert_int(system.get_region("kelp_shallows").get_resources()).is_equal(cost)

	# SPENT BY THE UNLOCK, not merely spendable after it. This used to assert
	# that a later zero-delivery would advance; nothing performed that delivery,
	# so on a boss-gated region the encounter's whole payoff was a no-op — the
	# Flagship fell, the region unlocked, and visibly nothing happened.
	system.unlock_region("kelp_shallows")
	assert_int(int(system.get_state("kelp_shallows"))).override_failure_message(
		"banked resources must be spent the moment the region unlocks"
	).is_equal(int(RegionState.State.RESOURCED))
	assert_int(system.deliver_resources("kelp_shallows", 0)).override_failure_message(
		"and spent once: a second flush must find nothing left to advance on"
	).is_equal(0)


func test_req_008_unlocking_with_nothing_banked_advances_nothing() -> void:
	# The other half of the rule above: the unlock spends what the player
	# already earned, and invents nothing they did not.
	var system := _unlocked_system()
	assert_int(int(system.get_state("kelp_shallows"))).is_equal(
		RegionState.State.BARREN)


# --- AC-3: restoration opens PATHS, not only visuals -----------------------

func test_req_008_advancing_state_opens_a_path_that_was_closed() -> void:
	var system := _unlocked_system()
	var region := system.get_region("kelp_shallows")
	assert_array(region.get_open_gate_ids()).override_failure_message(
		"a barren region must have every gated route closed"
	).is_empty()

	var tuning := _tuning()
	system.deliver_resources(
		"kelp_shallows", tuning.get_count(RegionState.RESOURCED_COST_KEY))
	assert_array(region.get_open_gate_ids()).contains(["silt_channel"])
	assert_bool(region.get_open_gate_ids().has("kelp_bridge")).override_failure_message(
		"the restored-tier route must stay closed at resourced"
	).is_false()

	system.deliver_resources(
		"kelp_shallows", tuning.get_count(RegionState.RESTORED_COST_KEY))
	assert_array(region.get_open_gate_ids()).contains(
		["silt_channel", "kelp_bridge"])


func test_req_008_the_open_path_is_applied_to_geometry_not_just_recorded() -> void:
	# The scene side has to actually be driven, or "opens paths" is a boolean
	# nothing reads. The recording gate stands in for collision and navigation.
	var gate := RecordingGate.new("kelp_bridge", RegionState.State.RESTORED)
	var gates: Array[TraversalGate] = [gate]
	var region := RestorableRegion.new("kelp_shallows", gates)
	region.set_unlocked(true)

	_restore_region(region)

	# [false, true], not [true]: the gate pushes its CLOSED state on construction
	# before ever opening. That first push is not optional — the scene's defaults
	# do not agree with a gate's, so a barren region that never pushed would load
	# with its navmesh already live.
	assert_array(gate.applied).override_failure_message(
		"REQ-008 AC-3: the gate must be driven open, not merely marked open"
	).is_equal([false, true])
	assert_bool(gate.is_open()).is_true()


func test_req_008_restoring_disables_a_real_collision_barrier() -> void:
	# The end-to-end half of AC-3, against actual Godot nodes rather than a
	# recording double: restoring must flip real collision and navigation, which
	# is what makes the path traversable at all.
	var barrier := CollisionShape3D.new()
	barrier.shape = BoxShape3D.new()
	var navigation := NavigationRegion3D.new()

	var gate := SceneTraversalGate.new(
		"kelp_bridge", RegionState.State.RESTORED, barrier, navigation)
	var gates: Array[TraversalGate] = [gate]
	var region := RestorableRegion.new("kelp_shallows", gates)
	region.set_unlocked(true)

	assert_bool(barrier.disabled).override_failure_message(
		"a barren region's barrier must be solid"
	).is_false()
	assert_bool(navigation.enabled).is_false()

	_restore_region(region)

	assert_bool(barrier.disabled).override_failure_message(
		"REQ-008 AC-3: restoring must REMOVE the barrier, not recolour it"
	).is_true()
	assert_bool(navigation.enabled).override_failure_message(
		"navigation must open with collision, or enemies never path the route"
	).is_true()

	region.revert_to_barren()
	assert_bool(barrier.disabled).override_failure_message(
		"REQ-008 AC-5: reversion must put the barrier back"
	).is_false()
	assert_bool(navigation.enabled).is_false()

	barrier.free()
	navigation.free()


func test_req_008_a_region_declaring_no_traversal_gate_is_refused() -> void:
	# The structural half of AC-3, and the reason it is enforced rather than
	# hoped for: a region whose restoration changes nothing traversable cannot
	# satisfy "opens paths that were not previously available".
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	var accepted := system.declare_from_manifest({
		"restorableRegions": [{"regionId": "cosmetic_only"}],
	}, errors)

	assert_bool(accepted).is_false()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(RestorationError.NO_TRAVERSAL_EFFECT)


func test_req_008_a_gate_that_opens_at_barren_is_refused() -> void:
	# Such a gate is never closed, so it opens no path — it would let a region
	# satisfy the traversal requirement while changing nothing.
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	var accepted := system.declare_from_manifest({
		"restorableRegions": [{
			"regionId": "always_open",
			"traversalGates": [{"gateId": "g", "opensAt": "barren"}],
		}],
	}, errors)

	assert_bool(accepted).is_false()
	assert_str(errors[0].code).is_equal(RestorationError.NO_TRAVERSAL_EFFECT)


func test_req_008_a_traversal_gate_carries_no_cosmetic_channel() -> void:
	# If a colour or material lived on the gate it would eventually become the
	# whole implementation of a state change, and the pillar would degrade into
	# a reskin. Art rides on the transition signal; it is not what the
	# transition IS.
	var gate := TraversalGate.new("g")
	for property: Dictionary in gate.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var field := String(property["name"]).to_lower()
			for word: String in ["color", "colour", "material", "mesh", "texture"]:
				assert_bool(field.contains(word)).override_failure_message(
					"REQ-008 AC-3: '%s' would make restoration cosmetic" % field
				).is_false()


# --- AC-4: persistence through the save-integration interface --------------

func test_req_008_state_and_flag_persist_across_sessions() -> void:
	var store := FakeStore.new()
	var first := _unlocked_system(store)
	_restore_fully(first)
	assert_int(int(first.get_state("kelp_shallows"))).is_equal(
		RegionState.State.RESTORED)
	first.save()

	# A whole new session: fresh system, same store.
	var second := _system(store)
	assert_int(int(second.get_state("kelp_shallows"))).is_equal(
		RegionState.State.BARREN)
	second.load_saved()

	assert_int(int(second.get_state("kelp_shallows"))).override_failure_message(
		"REQ-008 AC-4: restoration state must survive a session boundary"
	).is_equal(RegionState.State.RESTORED)
	assert_bool(second.is_unlocked("kelp_shallows")).is_true()


func test_req_008_a_loaded_region_comes_back_with_its_routes_open() -> void:
	# Loading must re-apply geometry, not only the state value. Otherwise a
	# player reloading into a restored region finds the path they earned shut.
	var store := FakeStore.new()
	var first := _unlocked_system(store)
	_restore_fully(first)
	first.save()

	var second := _system(store)
	second.load_saved()

	assert_array(second.get_region("kelp_shallows").get_open_gate_ids()
	).override_failure_message(
		"a restored region must load with its traversal gates already open"
	).contains(["silt_channel", "kelp_bridge"])


func test_req_008_state_is_persisted_by_name_not_by_ordinal() -> void:
	# Reordering the enum must never silently reinterpret every existing save.
	var store := FakeStore.new()
	var system := _unlocked_system(store)
	_restore_fully(system)
	system.save()

	var stored: Dictionary = store.payload["kelp_shallows"]
	assert_str(String(stored[RestorableRegion.STATE_FIELD])).is_equal("restored")


func test_req_008_a_region_absent_from_the_save_keeps_its_defaults() -> void:
	# A world that gained a region since the save was written must still load.
	var store := FakeStore.new()
	store.payload = {"some_other_region": {"state": "restored", "unlocked": true}}
	var system := _system(store)
	system.load_saved()

	assert_int(int(system.get_state("kelp_shallows"))).is_equal(
		RegionState.State.BARREN)
	assert_bool(system.is_unlocked("kelp_shallows")).is_false()


# --- AC-5 and AC-6: reversion under pressure -------------------------------

func test_req_008_a_dredger_reverts_a_restored_region_to_barren() -> void:
	var system := _unlocked_system()
	_restore_fully(system)

	assert_bool(system.dredger_attack("kelp_shallows")).is_true()
	assert_int(int(system.get_state("kelp_shallows"))).override_failure_message(
		"REQ-008 AC-5: a Dredger flattens a restored region back to barren"
	).is_equal(RegionState.State.BARREN)


func test_req_008_reversion_closes_the_paths_restoration_opened() -> void:
	# "Reflected in traversal" — a reverted region must lose the routes, or the
	# encounter costs the player nothing that matters.
	var system := _unlocked_system()
	_restore_fully(system)
	var region := system.get_region("kelp_shallows")
	assert_int(region.get_open_gate_ids().size()).is_equal(2)

	system.dredger_attack("kelp_shallows")

	assert_array(region.get_open_gate_ids()).override_failure_message(
		"REQ-008 AC-5: reversion must close the geometry it opened"
	).is_empty()


func test_req_008_reversion_is_reflected_in_persistence() -> void:
	var store := FakeStore.new()
	var system := _unlocked_system(store)
	_restore_fully(system)
	system.save()

	system.dredger_attack("kelp_shallows")
	system.save()

	var stored: Dictionary = store.payload["kelp_shallows"]
	assert_str(String(stored[RestorableRegion.STATE_FIELD])).override_failure_message(
		"REQ-008 AC-5: the reverted state must be what a reload restores"
	).is_equal("barren")
	assert_bool(bool(stored[RestorableRegion.UNLOCKED_FIELD])).is_true()


func test_req_008_reversion_leaves_the_unlocked_flag_set() -> void:
	var system := _unlocked_system()
	_restore_fully(system)
	system.dredger_attack("kelp_shallows")

	assert_bool(system.is_unlocked("kelp_shallows")).override_failure_message(
		"REQ-008 AC-6: a Dredger costs the restoration, never the boss fight"
	).is_true()


func test_req_008_a_reverted_region_can_be_restored_again_without_the_flagship() -> void:
	# The mechanical meaning of AC-6, driven rather than asserted on the flag.
	var system := _unlocked_system()
	_restore_fully(system)
	system.dredger_attack("kelp_shallows")

	_restore_fully(system)

	assert_int(int(system.get_state("kelp_shallows"))).override_failure_message(
		"a reverted region must be re-restorable by delivering resources alone"
	).is_equal(RegionState.State.RESTORED)


func test_req_008_reverting_a_barren_region_is_a_no_op() -> void:
	var system := _unlocked_system()
	var changes: Array[int] = []
	system.region_state_changed.connect(
		func(_r: String, _f: RegionState.State, to: RegionState.State) -> void:
			changes.append(int(to)))

	assert_bool(system.dredger_attack("kelp_shallows")).is_false()
	assert_array(changes).is_empty()


# --- AC-7: declared through the contract, never scripted -------------------

func test_req_008_regions_are_built_from_the_manifest_declaration() -> void:
	var system := _system()
	assert_array(system.get_region_ids()).is_equal(
		PackedStringArray(["kelp_shallows"]))


func test_req_008_an_absent_element_means_no_progression_not_an_error() -> void:
	# The contract's defined default for an omitted optional element.
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	assert_bool(system.declare_from_manifest({}, errors)).is_true()
	assert_array(errors).is_empty()
	assert_int(system.get_region_ids().size()).is_equal(0)


func test_req_008_the_system_offers_no_hook_for_bespoke_world_logic() -> void:
	# AC-7's structural half. A world author writes DATA; every state machine
	# lives in core where it can be tested. If a world could install its own
	# progression logic it would be unverifiable by construction, and the
	# sanctioned world API surface could no longer be checked statically.
	var script: GDScript = RestorationSystem.new(_tuning()).get_script()
	var forbidden: PackedStringArray = [
		"register", "add_region", "set_callback", "set_handler", "install",
	]
	for method_row: Dictionary in script.get_script_method_list():
		var method_name := String(method_row["name"]).to_lower()
		for word: String in forbidden:
			assert_bool(method_name.contains(word)).override_failure_message(
				"REQ-008 AC-7: '%s' would let a world script its own progression"
				% method_name
			).is_false()


func test_req_008_a_malformed_declaration_is_refused_wholesale() -> void:
	# A partially declared world is worse than a refused one: the missing
	# regions surface later as silently absent progression.
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	var accepted := system.declare_from_manifest({
		"restorableRegions": [
			{
				"regionId": "good",
				"traversalGates": [{"gateId": "g", "opensAt": "restored"}],
			},
			{"regionId": "bad"},
		],
	}, errors)

	assert_bool(accepted).is_false()
	assert_int(system.get_region_ids().size()).override_failure_message(
		"a refused declaration must leave the system empty, not half-built"
	).is_equal(0)


func test_req_008_a_duplicate_region_id_is_refused() -> void:
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	var gates := [{"gateId": "g", "opensAt": "restored"}]
	assert_bool(system.declare_from_manifest({
		"restorableRegions": [
			{"regionId": "twice", "traversalGates": gates},
			{"regionId": "twice", "traversalGates": gates},
		],
	}, errors)).is_false()
	assert_str(errors[0].code).is_equal(RestorationError.DUPLICATE_REGION)


func test_req_008_an_unknown_gate_state_is_named_in_the_error() -> void:
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	assert_bool(system.declare_from_manifest({
		"restorableRegions": [{
			"regionId": "r",
			"traversalGates": [{"gateId": "g", "opensAt": "sparkling"}],
		}],
	}, errors)).is_false()
	assert_str(errors[0].code).is_equal(RestorationError.UNKNOWN_GATE_STATE)
	assert_str(errors[0].message).contains("sparkling")


# --- Tuning, signals and the finish condition ------------------------------

func test_req_025_the_costs_come_from_the_tuning_surface() -> void:
	var tuning := _tuning()
	for key: String in [RegionState.RESOURCED_COST_KEY,
			RegionState.RESTORED_COST_KEY]:
		assert_bool(tuning.has_key(key)).override_failure_message(
			"REQ-025: restoration reads '%s', which the tuning surface lacks" % key
		).is_true()
		assert_bool(tuning.is_world_overridable(key)).override_failure_message(
			"a world must be able to tune its own restoration economy"
		).is_true()


func test_req_025_changing_the_cost_changes_the_behaviour() -> void:
	# The anti-vacuity control for the key check above: a key that exists but
	# that nothing reads would still pass it.
	var tuning := _tuning()
	var cost := tuning.get_count(RegionState.RESOURCED_COST_KEY)
	var gates: Array[TraversalGate] = [
		TraversalGate.new("g", RegionState.State.RESOURCED)]
	var region := RestorableRegion.new("r", gates)
	region.set_unlocked(true)

	assert_int(region.deliver_resources(cost - 1, tuning)).override_failure_message(
		"one short of the tuned cost must not advance the region"
	).is_equal(0)
	assert_int(region.deliver_resources(1, tuning)).is_equal(1)


func test_req_023_a_transition_requests_the_matching_ambience() -> void:
	# Semantic bed ids only; this node never names an audio file.
	var system := _unlocked_system()
	var beds: Array[int] = []
	system.ambience_requested.connect(
		func(_r: String, bed: AudioEvent.Bed) -> void: beds.append(int(bed)))

	_restore_fully(system)

	assert_array(beds).is_equal([
		int(AudioEvent.Bed.REGION_RESOURCED),
		int(AudioEvent.Bed.REGION_RESTORED),
	])


func test_req_023_restoration_names_no_audio_resource() -> void:
	for path: String in RESTORATION_SOURCES:
		var text := _read(path)
		for symbol: String in [".ogg", ".wav", ".mp3", "res://audio", "AudioStream"]:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-023: '%s' names an audio resource '%s'" % [path, symbol]
			).is_false()


func test_req_006_all_restored_backs_the_finish_condition() -> void:
	var system := _unlocked_system()
	assert_bool(system.all_restored()).is_false()
	_restore_fully(system)
	assert_bool(system.all_restored()).override_failure_message(
		"the restore_all_regions finish condition reads this"
	).is_true()


func test_req_030_restoration_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in RESTORATION_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'"
				% [path, symbol]
			).is_false()


func _restore_region(region: RestorableRegion) -> void:
	var tuning := _tuning()
	region.deliver_resources(
		tuning.get_count(RegionState.RESOURCED_COST_KEY)
		+ tuning.get_count(RegionState.RESTORED_COST_KEY), tuning)


# --- F-2: what lifts a region's lock is DECLARED, not inferred ---------------

func _declared(rows: Array) -> RestorationSystem:
	var system := RestorationSystem.new(_tuning())
	var errors: Array[RestorationError] = []
	assert_bool(system.declare_from_manifest(
		{"restorableRegions": rows}, errors)).override_failure_message(
		"declaration refused: %s" % str(errors)).is_true()
	return system


const GATE: Array = [{"gateId": "wall", "opensAt": "restored"}]


func test_req_008_a_region_declares_what_lifts_its_lock() -> void:
	var system := _declared([
		{"regionId": "shelf", "traversalGates": GATE, "unlockedBy": "entry"},
		{"regionId": "sea", "traversalGates": GATE, "unlockedBy": "boss"},
	])
	# The world declares a boss, so under the old inference BOTH would be
	# locked. That is the deadlock this field exists to break: a level with
	# restoration on its critical path AND a Flagship at its end.
	assert_bool(system.unlocks_at_entry("shelf", true)).override_failure_message(
		"a region declaring 'entry' unlocks on arrival even in a boss world"
		).is_true()
	assert_bool(system.unlocks_at_entry("sea", true)).is_false()
	# And the declaration wins in the other direction too.
	assert_bool(system.unlocks_at_entry("sea", false)).override_failure_message(
		"a region declaring 'boss' stays locked even where nothing inferred it"
		).is_false()


func test_req_008_a_region_declaring_nothing_keeps_the_old_inference() -> void:
	# Every world and fixture written before this field existed must still mean
	# what it meant: no boss anywhere, unlock at entry; a boss, wait for it.
	var system := _declared([{"regionId": "reef", "traversalGates": GATE}])
	assert_str(system.unlock_policy_of("reef")).is_equal("")
	assert_bool(system.unlocks_at_entry("reef", false)).is_true()
	assert_bool(system.unlocks_at_entry("reef", true)).is_false()


func test_req_008_an_unknown_unlock_policy_is_refused_not_defaulted() -> void:
	# A misspelled policy is a level that unlocks at the wrong moment, which
	# surfaces as an unreachable route rather than an error — the most
	# expensive kind of typo this contract can carry.
	for bad: String in ["Entry", "flagship", "on_entry", ""]:
		var system := RestorationSystem.new(_tuning())
		var errors: Array[RestorationError] = []
		assert_bool(system.declare_from_manifest({"restorableRegions": [
			{"regionId": "reef", "traversalGates": GATE, "unlockedBy": bad}]},
			errors)).override_failure_message(
			"'unlockedBy: %s' must be refused" % bad).is_false()
		assert_array(errors).is_not_empty()
		assert_str(errors[0].code).is_equal(
			RestorationError.UNKNOWN_UNLOCK_POLICY)
