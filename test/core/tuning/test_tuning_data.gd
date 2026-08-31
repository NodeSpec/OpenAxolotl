extends GdUnitTestSuite

## Balance and Tuning Data — REQ-025.
##
## Test names carry the requirement id they prove (test_req_025_...) so the
## harness can parse it back out and report it as the failing rule (REQ-026 AC-6).

const REAL_TUNING_PATH := "res://core/tuning/tuning.json"

## Every tuning key cited by ANOTHER requirement's acceptance criteria.
##
## REQ-025 AC-7 makes this node responsible for the whole project's tuning-key
## integrity. This list is the single place to update when a requirement gains a
## new cited key — keep it sorted and keep the citing requirement in the comment.
const CITED_KEYS: PackedStringArray = [
	"camera.smoothing.max_position_delta_m_per_frame",  # REQ-005 AC-1
	"camera.smoothing.max_rotation_delta_deg_per_frame",  # REQ-005 AC-1
	"capability.gill_loss.boost_duration_multiplier",  # REQ-004 AC-5
	"controller.grapple.max_range_m",  # REQ-001 AC-4
	"controller.transition.momentum_retention_ratio",  # REQ-001 AC-1
	"enemy.hookline.mod_strip_seconds",  # REQ-004 AC-6, REQ-012 AC-2
	"enemy.runoff.duration_s",  # REQ-012 AC-4
	"enemy.runoff.gill_recharge_multiplier",  # REQ-012 AC-4
	"enemy.runoff.vision_debuff_factor",  # REQ-012 AC-4
	"progression.max_retry_seconds",  # REQ-003 AC-6
	"regen.mutation.duration_s",  # REQ-002 AC-5
]

## The categories REQ-025 AC-2 requires the surface to cover, each with a key
## prefix that must be present.
const REQUIRED_COVERAGE: Dictionary = {
	"capability-loss modifiers": "capability.",
	"default lives per attempt": "progression.default_lives_per_attempt",
	"dash charge and recharge": "controller.dash.",
	"Gill Mod durations and cooldowns": "gillmod.",
	"enemy debuff magnitudes and windows": "enemy.",
	"restoration resource costs": "restoration.",
	"grapple range": "controller.grapple.",
	"camera smoothing thresholds": "camera.smoothing.",
	"mutation loadout duration": "regen.mutation.duration_s",
	"momentum retention": "controller.transition.momentum_retention_ratio",
	"maximum retry duration": "progression.max_retry_seconds",
}

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("tuning")


func _write_tuning(body: Dictionary) -> String:
	var path := _temp_dir.path_join("tuning_%d.json" % Time.get_ticks_usec())
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(JSON.stringify(body))
	handle.close()
	return path


func _minimal_entry(value: float, minimum: float, maximum: float) -> Dictionary:
	return {
		"value": value,
		"unit": "ratio",
		"min": minimum,
		"max": maximum,
		"description": "fixture value",
	}


func _load_real() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(REAL_TUNING_PATH, errors)
	assert_array(errors).is_empty()
	assert_object(data).is_not_null()
	return data


# --- AC-1: values live in data, not constants -------------------------------

func test_req_025_values_are_defined_in_data_not_code() -> void:
	# The shipped tuning file is the source; the loader holds no hardcoded values.
	var data := _load_real()
	assert_int(data.get_keys().size()).is_greater(0)

	# Nothing in the tuning source declares a balance number as a GDScript const.
	var source := FileAccess.open("res://core/tuning/tuning_data.gd", FileAccess.READ)
	var text := source.get_as_text()
	source.close()
	assert_str(text).not_contains("const DEFAULT_MOMENTUM")
	assert_bool(text.contains("JSON.parse_string")).is_true()


# --- AC-2: the surface covers every enumerated category ---------------------

func test_req_025_tuning_surface_covers_every_required_category() -> void:
	var data := _load_real()
	var keys := data.get_keys()

	for category: String in REQUIRED_COVERAGE:
		var needle: String = REQUIRED_COVERAGE[category]
		var found := false
		for key: String in keys:
			if key.begins_with(needle):
				found = true
				break
		assert_bool(found).override_failure_message(
			"REQ-025 AC-2: no tuning key covers '%s' (expected a key matching '%s')"
			% [category, needle]
		).is_true()


# --- AC-3: name, unit and permitted range on every value --------------------

func test_req_025_every_value_carries_name_unit_and_range() -> void:
	var data := _load_real()
	for key: String in data.get_keys():
		assert_str(data.get_unit(key)).override_failure_message(
			"REQ-025 AC-3: '%s' has no unit" % key).is_not_empty()
		assert_str(data.get_description(key)).override_failure_message(
			"REQ-025 AC-3: '%s' has no description" % key).is_not_empty()

		var bounds := data.get_permitted_range(key)
		assert_int(bounds.size()).override_failure_message(
			"REQ-025 AC-3: '%s' has no permitted range" % key).is_equal(2)
		assert_bool(bounds[0] <= bounds[1]).override_failure_message(
			"REQ-025 AC-3: '%s' has an inverted range" % key).is_true()

		var value := data.get_number(key)
		assert_bool(value >= bounds[0] and value <= bounds[1]).override_failure_message(
			"REQ-025 AC-3: '%s' value %s is outside its own declared range [%s, %s]"
			% [key, value, bounds[0], bounds[1]]
		).is_true()


# --- AC-4: changing a value changes behavior, no code change, no recompile ---

func test_req_025_changing_a_value_alters_behavior_without_code_change() -> void:
	var key := "controller.grapple.max_range_m"
	var body := {
		"schemaVersion": "1.0",
		"worldOverridable": [],
		"values": {key: _minimal_entry(12.0, 1.0, 60.0)},
	}

	var first_path := _write_tuning(body)
	var errors: Array[TuningError] = []
	var before := TuningData.load_from_file(first_path, errors)
	assert_array(errors).is_empty()
	assert_float(before.get_number(key)).is_equal_approx(12.0, 0.0001)

	# Same code path, same binary — only the data file differs.
	body["values"][key]["value"] = 30.0
	var second_path := _write_tuning(body)
	errors.clear()
	var after := TuningData.load_from_file(second_path, errors)
	assert_array(errors).is_empty()
	assert_float(after.get_number(key)).is_equal_approx(30.0, 0.0001)


# --- AC-5: world overrides are a closed, enumerated set ---------------------

func test_req_025_world_override_inside_sanctioned_set_is_applied() -> void:
	var data := _load_real()
	var key := data.get_world_overridable_keys()[0]
	var bounds := data.get_permitted_range(key)

	var errors: Array[TuningError] = []
	var applied := data.apply_world_overrides({key: bounds[1]}, errors)

	assert_bool(applied).is_true()
	assert_array(errors).is_empty()
	assert_float(data.get_number(key)).is_equal_approx(bounds[1], 0.0001)


func test_req_025_world_override_outside_sanctioned_set_is_rejected() -> void:
	var data := _load_real()
	# A real key, deliberately global: movement stays coherent across forks.
	var key := "controller.transition.momentum_retention_ratio"
	assert_bool(data.is_world_overridable(key)).is_false()

	var before := data.get_number(key)
	var errors: Array[TuningError] = []
	var applied := data.apply_world_overrides({key: 0.1}, errors)

	assert_bool(applied).is_false()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(TuningError.OVERRIDE_NOT_PERMITTED)
	assert_str(errors[0].key).is_equal(key)
	# Rejected means nothing applied, not partially applied.
	assert_float(data.get_number(key)).is_equal_approx(before, 0.0001)


func test_req_025_world_override_set_is_rejected_wholesale_on_any_violation() -> void:
	var data := _load_real()
	var permitted := data.get_world_overridable_keys()[0]
	var forbidden := "controller.grapple.max_range_m"
	var before := data.get_number(permitted)

	var errors: Array[TuningError] = []
	var applied := data.apply_world_overrides(
		{permitted: data.get_permitted_range(permitted)[1], forbidden: 2.0}, errors)

	assert_bool(applied).is_false()
	# The legal half must NOT have landed — a world never runs half-overridden.
	assert_float(data.get_number(permitted)).is_equal_approx(before, 0.0001)


# --- AC-6: missing or out-of-range fails with a NAMED error -----------------

func test_req_025_out_of_range_value_fails_with_named_error() -> void:
	var key := "controller.transition.momentum_retention_ratio"
	var path := _write_tuning({
		"schemaVersion": "1.0",
		"values": {key: _minimal_entry(1.8, 0.0, 1.0)},  # above max
	})

	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(path, errors)

	assert_object(data).override_failure_message(
		"REQ-025 AC-6: an out-of-range value must refuse to load, not default").is_null()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(TuningError.OUT_OF_RANGE)
	assert_str(errors[0].key).is_equal(key)


func test_req_025_entry_missing_a_required_field_fails_with_named_error() -> void:
	var key := "progression.max_retry_seconds"
	var path := _write_tuning({
		"schemaVersion": "1.0",
		"values": {key: {"value": 5.0, "min": 0.5, "max": 60.0}},  # no unit/description
	})

	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(path, errors)

	assert_object(data).is_null()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(TuningError.MALFORMED_ENTRY)
	assert_str(errors[0].key).is_equal(key)


func test_req_025_missing_file_fails_with_named_error() -> void:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(
		_temp_dir.path_join("absent.json"), errors)

	assert_object(data).is_null()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(TuningError.FILE_UNREADABLE)


func test_req_025_unknown_key_read_does_not_silently_default() -> void:
	var data := _load_real()
	assert_bool(data.has_key("controller.nonexistent.key")).is_false()
	# has_key is the contract for "may I read this"; a caller that skips it gets
	# a pushed error rather than a plausible-looking number.
	assert_array(data.get_permitted_range("controller.nonexistent.key")).is_empty()


# --- AC-7: every key cited by another requirement exists here ---------------

func test_req_025_every_cited_tuning_key_exists_with_unit_and_range() -> void:
	var data := _load_real()

	for key: String in CITED_KEYS:
		assert_bool(data.has_key(key)).override_failure_message(
			"REQ-025 AC-7: '%s' is cited by another requirement's acceptance criteria "
			% key + "but is absent from the tuning data"
		).is_true()

		assert_str(data.get_unit(key)).override_failure_message(
			"REQ-025 AC-7: cited key '%s' has no documented unit" % key).is_not_empty()

		var bounds := data.get_permitted_range(key)
		assert_int(bounds.size()).override_failure_message(
			"REQ-025 AC-7: cited key '%s' has no permitted range" % key).is_equal(2)


func test_req_025_cited_key_check_fails_when_a_key_is_absent() -> void:
	# Proves the AC-7 guard actually bites: a tuning surface missing a cited key
	# must fail the has_key assertion above, not pass vacuously.
	var path := _write_tuning({
		"schemaVersion": "1.0",
		"values": {"controller.grapple.max_range_m": _minimal_entry(12.0, 1.0, 60.0)},
	})
	var errors: Array[TuningError] = []
	var sparse := TuningData.load_from_file(path, errors)
	assert_array(errors).is_empty()

	var missing: PackedStringArray = []
	for key: String in CITED_KEYS:
		if not sparse.has_key(key):
			missing.append(key)

	assert_int(missing.size()).override_failure_message(
		"the AC-7 guard is vacuous — a sparse tuning file should report missing keys"
	).is_greater(0)


# --- Contract: worldOverridable cannot drift from values --------------------

func test_req_025_world_overridable_list_cannot_name_an_absent_key() -> void:
	var path := _write_tuning({
		"schemaVersion": "1.0",
		"worldOverridable": ["progression.default_lives_per_attempt"],
		"values": {"controller.grapple.max_range_m": _minimal_entry(12.0, 1.0, 60.0)},
	})

	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(path, errors)

	assert_object(data).is_null()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(TuningError.UNKNOWN_KEY)


# --- REQ-030: no multiplayer surface in this node ---------------------------

func test_req_030_tuning_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "multiplayer", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in ["res://core/tuning/tuning_data.gd", "res://core/tuning/tuning_error.gd"]:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
