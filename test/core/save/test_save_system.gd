extends GdUnitTestSuite

## Save System — REQ-014.
##
## Test names carry the requirement id they prove (test_req_014_...) so the
## harness reports it as the failing rule (REQ-026 AC-6).

var _dir: String = ""


## Probe policy proving the decision point is genuinely injectable: it quarantines
## on ANY change, which is not what the project shipped.
class StrictProbe extends SaveCompatibilityPolicy:
	func decide(change: WorldContractShape.Change) -> Outcome:
		if change == WorldContractShape.Change.NONE:
			return Outcome.LOAD
		return Outcome.QUARANTINE


func before_test() -> void:
	_dir = create_temp_dir("save")


func _path(tag: String) -> String:
	return _dir.path_join("%s_%d.json" % [tag, Time.get_ticks_usec()])


func _shape(regions: Array, collectibles: Array, checkpoints: Array) -> Dictionary:
	return {"regions": regions, "collectibles": collectibles, "checkpoints": checkpoints}


func _write_raw(path: String, body: Variant) -> void:
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(body if body is String else JSON.stringify(body))
	handle.close()


# --- AC-1: everything the profile must persist -----------------------------

func test_req_014_profile_round_trips_all_persisted_state() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], ["shell_01"], ["cp_1"]))
	save.put_world_data("coral_cove", {
		"unlocked": true,
		"completed": true,
		"lastCheckpoint": "cp_1",
		"regions": {"reef": {"state": "restored", "unlockedFlag": true}},
		"collectibles": ["shell_01"],
	})
	save.set_gill_mod_unlocked("bubble")
	save.save_section("audio", {"Master": 0.4})

	var path := _path("profile")
	assert_bool(save.save_to_file(path)).is_true()

	var reloaded := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(reloaded.load_from_file(path, errors)).is_true()
	assert_array(errors).is_empty()

	var world := reloaded.get_world_data("coral_cove")
	assert_bool(bool(world["unlocked"])).is_true()
	assert_bool(bool(world["completed"])).is_true()
	assert_str(String(world["lastCheckpoint"])).is_equal("cp_1")
	assert_bool((world["regions"] as Dictionary).has("reef")).is_true()
	assert_array(reloaded.get_unlocked_gill_mods()).contains(["bubble"])
	assert_float(float(reloaded.load_section("audio")["Master"])).is_equal_approx(0.4, 0.0001)


# --- AC-2: one interface, no back doors ------------------------------------

func test_req_014_a_world_cannot_write_a_reserved_profile_key() -> void:
	var save := SaveSystem.new()
	var errors: Array[SaveError] = []

	assert_bool(save.put_world_data("settings", {"hacked": true}, errors)).is_false()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(SaveError.FOREIGN_NAMESPACE_WRITE)


func test_req_014_a_world_must_be_opened_before_it_can_be_written() -> void:
	var save := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(save.put_world_data("never_opened", {"unlocked": true}, errors)).is_false()
	assert_str(errors[0].code).is_equal(SaveError.FOREIGN_NAMESPACE_WRITE)


func test_req_014_worlds_are_namespaced_and_cannot_see_each_other() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], [], []))
	save.open_world("bubble_bay", _shape(["bay"], [], []))
	save.put_world_data("coral_cove", {"unlocked": true})

	assert_bool(bool(save.get_world_data("bubble_bay")["unlocked"])).is_false()


# --- AC-3: missing or renamed module degrades gracefully -------------------

func test_req_014_save_referencing_an_uninstalled_module_still_loads() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], [], []))
	save.open_world("gone_world", _shape(["x"], [], []))
	save.put_world_data("gone_world", {"unlocked": true, "completed": true})
	var path := _path("orphan")
	save.save_to_file(path)

	var reloaded := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(reloaded.load_from_file(path, errors)).is_true()
	assert_array(errors).is_empty()
	# The installed world is still playable.
	assert_dict(reloaded.get_world_data("coral_cove")).is_not_empty()


func test_req_014_uninstalled_module_progress_is_retained_not_pruned() -> void:
	# A world removed and later reinstalled must find its progress waiting.
	var save := SaveSystem.new()
	save.open_world("gone_world", _shape(["x"], [], []))
	save.put_world_data("gone_world", {"completed": true})
	var path := _path("retain")
	save.save_to_file(path)

	var reloaded := SaveSystem.new()
	reloaded.load_from_file(path, [] as Array[SaveError])

	var orphans := reloaded.find_orphaned_modules(PackedStringArray(["coral_cove"]))
	assert_array(orphans).contains(["gone_world"])
	assert_bool(bool(reloaded.get_world_data("gone_world")["completed"])).override_failure_message(
		"REQ-014 AC-3: an uninstalled module's progress must be retained, not pruned"
	).is_true()


func test_req_014_an_unreadable_module_is_marked_without_failing_the_profile() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], [], []))
	save.mark_unavailable("broken_world")

	assert_array(save.get_unavailable_modules()).contains(["broken_world"])
	assert_dict(save.get_world_data("coral_cove")).is_not_empty()


# --- AC-4: the documented save-compatibility policy ------------------------

func test_req_014_unchanged_world_shape_loads_as_is() -> void:
	var save := SaveSystem.new()
	save.open_world("bubble_bay", _shape(["bay"], [], ["cp_1"]))
	save.put_world_data("bubble_bay", {"unlocked": true})

	var outcome := save.open_world("bubble_bay", _shape(["bay"], [], ["cp_1"]))

	assert_int(int(outcome)).is_equal(SaveCompatibilityPolicy.Outcome.LOAD)
	assert_bool(bool(save.get_world_data("bubble_bay")["unlocked"])).is_true()


func test_req_014_additive_world_change_reconciles_and_keeps_progress() -> void:
	# Adding content is the common case in a forkable project; it must not cost
	# players their progress.
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], ["shell_01"], ["cp_1"]))
	save.put_world_data("coral_cove", {"unlocked": true, "collectibles": ["shell_01"]})

	var outcome := save.open_world(
		"coral_cove", _shape(["reef", "lagoon"], ["shell_01", "shell_02"], ["cp_1"]))

	assert_int(int(outcome)).is_equal(SaveCompatibilityPolicy.Outcome.RECONCILE)
	var world := save.get_world_data("coral_cove")
	assert_bool(bool(world["unlocked"])).is_true()
	assert_array(world["collectibles"] as Array).contains(["shell_01"])
	assert_array(save.get_reconciled_modules()).contains(["coral_cove"])


func test_req_014_destructive_world_change_quarantines_and_starts_fresh() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], ["shell_01"], ["cp_1"]))
	save.put_world_data("coral_cove", {"unlocked": true, "completed": true})

	# A rename is indistinguishable from a removal at the id level, deliberately.
	var outcome := save.open_world(
		"coral_cove", _shape(["reef_alpha"], ["shell_01"], ["cp_1"]))

	assert_int(int(outcome)).is_equal(SaveCompatibilityPolicy.Outcome.QUARANTINE)
	assert_bool(bool(save.get_world_data("coral_cove")["completed"])).is_false()
	assert_array(save.get_quarantined_modules()).contains(["coral_cove"])


func test_req_014_quarantined_progress_is_retained_so_reverting_a_fork_restores_it() -> void:
	var save := SaveSystem.new()
	save.open_world("coral_cove", _shape(["reef"], [], []))
	save.put_world_data("coral_cove", {"completed": true})
	save.open_world("coral_cove", _shape(["reef_alpha"], [], []))

	assert_bool(save.has_quarantined_blob("coral_cove")).override_failure_message(
		"REQ-014 AC-4: quarantine sets the blob aside, it never deletes it"
	).is_true()
	var blob := save.get_world_data("coral_cove")["quarantined"] as Dictionary
	assert_bool(bool(blob["completed"])).is_true()


func test_req_014_compatibility_policy_is_a_single_injectable_decision_point() -> void:
	# The shipped policy reconciles an additive change; this probe quarantines it.
	# If the decision were baked into the load path this could not differ.
	var save := SaveSystem.new(StrictProbe.new())
	save.open_world("w", _shape(["a"], [], []))
	save.put_world_data("w", {"unlocked": true})

	var outcome := save.open_world("w", _shape(["a", "b"], [], []))

	assert_int(int(outcome)).is_equal(SaveCompatibilityPolicy.Outcome.QUARANTINE)


func test_req_014_shape_classifies_identically_from_memory_and_from_disk() -> void:
	# A shape must not classify differently depending on where it came from.
	var save := SaveSystem.new()
	save.open_world("w", _shape(["a"], ["c"], ["cp"]))
	save.put_world_data("w", {"unlocked": true})
	var path := _path("shape")
	save.save_to_file(path)

	var reloaded := SaveSystem.new()
	reloaded.load_from_file(path, [] as Array[SaveError])
	var outcome := reloaded.open_world("w", _shape(["a"], ["c"], ["cp"]))

	assert_int(int(outcome)).override_failure_message(
		"an unchanged shape read back from disk must still classify as unchanged"
	).is_equal(SaveCompatibilityPolicy.Outcome.LOAD)


# --- AC-5: version field and upgrade path ----------------------------------

func test_req_014_new_profile_carries_the_current_format_version() -> void:
	assert_int(SaveSystem.new().get_format_version()).is_equal(
		SaveMigrations.CURRENT_VERSION)


func test_req_014_unversioned_legacy_save_migrates_forward() -> void:
	var path := _path("legacy")
	_write_raw(path, {
		"settings": {"audio": {"Master": 0.5}},
		"unlockedGillMods": ["glow"],
		"coral_cove": {"unlocked": true, "completed": true},
	})

	var save := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(save.load_from_file(path, errors)).is_true()
	assert_array(errors).is_empty()

	assert_int(save.get_format_version()).is_equal(SaveMigrations.CURRENT_VERSION)
	# v0's flat world data is namespaced under "worlds" and survives intact.
	assert_bool(bool(save.get_world_data("coral_cove")["completed"])).is_true()
	assert_array(save.get_unlocked_gill_mods()).contains(["glow"])
	assert_float(float(save.load_section("audio")["Master"])).is_equal_approx(0.5, 0.0001)


func test_req_014_a_future_version_save_is_refused_rather_than_guessed_at() -> void:
	var path := _path("future")
	_write_raw(path, {"saveFormatVersion": 99, "worlds": {}})

	var save := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(save.load_from_file(path, errors)).is_false()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(SaveError.UNKNOWN_FORMAT_VERSION)


func test_req_014_malformed_save_yields_a_named_error_and_a_usable_profile() -> void:
	# Losing a save is bad; refusing to start is worse.
	var path := _path("junk")
	_write_raw(path, "not json at all")

	var save := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(save.load_from_file(path, errors)).is_false()
	assert_str(errors[0].code).is_equal(SaveError.MALFORMED_JSON)
	assert_int(save.get_format_version()).is_equal(SaveMigrations.CURRENT_VERSION)


# --- The SettingsStore port (closes REQ-023 AC-6 end to end) ---------------

func test_req_023_audio_volumes_persist_through_the_real_save_system() -> void:
	var store := SaveSystem.new()
	store.save_section("audio", {"Master": 0.33, "Music": 0.8, "Effects": 0.8})
	var path := _path("audio")
	store.save_to_file(path)

	var reopened := SaveSystem.new()
	reopened.load_from_file(path, [] as Array[SaveError])

	assert_float(float(reopened.load_section("audio")["Master"])).is_equal_approx(
		0.33, 0.0001)


func test_req_014_save_system_satisfies_the_settings_store_port() -> void:
	var store: SettingsStore = SaveSystem.new()
	store.save_section("input", {"jump": "space"})
	assert_str(String(store.load_section("input")["jump"])).is_equal("space")
	assert_dict(store.load_section("never_written")).is_empty()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_save_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	var sources: PackedStringArray = [
		"res://core/save/save_error.gd",
		"res://core/save/world_contract_shape.gd",
		"res://core/save/save_compatibility_policy.gd",
		"res://core/save/tiered_compatibility_policy.gd",
		"res://core/save/save_migrations.gd",
		"res://core/save/save_system.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
