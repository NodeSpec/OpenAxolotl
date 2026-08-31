class_name TuningData
extends RefCounted

## The single authoritative tuning surface (REQ-025).
##
## Every balance value the game uses is defined in data and read through this
## interface at use time. Consumers must NOT copy a value into a [code]const[/code] at
## load — caching defeats the criterion that changing a tuning value alters
## observable behavior with no code change and no recompile.
##
## Construct with [method load_from_file]; it returns [code]null[/code] and populates
## [method get_load_errors] rather than raising, so a caller decides how to
## surface the failure. A file with a missing or out-of-range value never loads
## partially — strictness is this node's entire value.

const DEFAULT_TUNING_PATH := "res://core/tuning/tuning.json"

## Required per-entry fields. An entry missing any of these is malformed:
## "every value carries a documented name, unit, and permitted range".
const _REQUIRED_ENTRY_FIELDS: PackedStringArray = [
	"value", "unit", "min", "max", "description"
]

var _values: Dictionary = {}
var _world_overridable: PackedStringArray = []
var _schema_version: String = ""
var _errors: Array[TuningError] = []


## Loads and fully validates a tuning file. Returns null on any failure; the
## reasons are available from [method get_load_errors] on the returned instance
## only when loading succeeded, so failures are reported via [param out_errors].
static func load_from_file(path: String, out_errors: Array[TuningError] = []) -> TuningData:
	if not FileAccess.file_exists(path):
		out_errors.append(TuningError.new(
			TuningError.FILE_UNREADABLE, "", "no tuning file at '%s'" % path))
		return null

	var handle: FileAccess = FileAccess.open(path, FileAccess.READ)
	if handle == null:
		out_errors.append(TuningError.new(
			TuningError.FILE_UNREADABLE,
			"",
			"could not open '%s' (error %d)" % [path, FileAccess.get_open_error()]))
		return null

	var text: String = handle.get_as_text()
	handle.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		out_errors.append(TuningError.new(
			TuningError.MALFORMED_JSON, "", "'%s' is not a JSON object" % path))
		return null

	return _from_dictionary(parsed as Dictionary, out_errors)


static func _from_dictionary(root: Dictionary, out_errors: Array[TuningError]) -> TuningData:
	var data := TuningData.new()
	data._schema_version = String(root.get("schemaVersion", ""))

	var raw_overridable: Variant = root.get("worldOverridable", [])
	if raw_overridable is Array:
		for entry: Variant in (raw_overridable as Array):
			data._world_overridable.append(String(entry))

	var raw_values: Variant = root.get("values", null)
	if not (raw_values is Dictionary):
		out_errors.append(TuningError.new(
			TuningError.MALFORMED_ENTRY, "", "tuning file has no 'values' object"))
		return null

	for key: Variant in (raw_values as Dictionary):
		var name: String = String(key)
		var entry: Variant = (raw_values as Dictionary)[key]
		if not (entry is Dictionary):
			out_errors.append(TuningError.new(
				TuningError.MALFORMED_ENTRY, name, "entry is not an object"))
			continue
		data._validate_entry(name, entry as Dictionary, out_errors)

	# An entry naming an override target that does not exist is a drifted list —
	# exactly what declaring the set in the data is meant to prevent.
	for name: String in data._world_overridable:
		if not data._values.has(name):
			out_errors.append(TuningError.new(
				TuningError.UNKNOWN_KEY,
				name,
				"listed in worldOverridable but absent from values"))

	if not out_errors.is_empty():
		return null
	return data


func _validate_entry(name: String, entry: Dictionary, out_errors: Array[TuningError]) -> void:
	for field: String in _REQUIRED_ENTRY_FIELDS:
		if not entry.has(field):
			out_errors.append(TuningError.new(
				TuningError.MALFORMED_ENTRY, name, "missing required field '%s'" % field))
			return

	var raw_value: Variant = entry["value"]
	if not (raw_value is float or raw_value is int):
		out_errors.append(TuningError.new(
			TuningError.MALFORMED_ENTRY, name, "value is not numeric"))
		return

	var value: float = float(raw_value)
	var minimum: float = float(entry["min"])
	var maximum: float = float(entry["max"])

	if minimum > maximum:
		out_errors.append(TuningError.new(
			TuningError.MALFORMED_ENTRY,
			name,
			"declared range is inverted (min %s > max %s)" % [minimum, maximum]))
		return

	if value < minimum or value > maximum:
		out_errors.append(TuningError.new(
			TuningError.OUT_OF_RANGE,
			name,
			"value %s outside permitted range [%s, %s]" % [value, minimum, maximum]))
		return

	_values[name] = entry.duplicate(true)


## Returns the value for [param key]. Read at use time — never cache the result.
## Pushes an error and returns 0.0 for an unknown key rather than inventing a
## default, so a typo surfaces instead of silently tuning nothing.
func get_number(key: String) -> float:
	if not _values.has(key):
		push_error("[%s] %s: not present in the tuning data" % [TuningError.MISSING_KEY, key])
		return 0.0
	return float((_values[key] as Dictionary)["value"])


## Integer-valued convenience for counts (lives, charges, resource costs).
func get_count(key: String) -> int:
	return int(round(get_number(key)))


func has_key(key: String) -> bool:
	return _values.has(key)


func get_unit(key: String) -> String:
	if not _values.has(key):
		return ""
	return String((_values[key] as Dictionary)["unit"])


func get_description(key: String) -> String:
	if not _values.has(key):
		return ""
	return String((_values[key] as Dictionary)["description"])


## Returns the inclusive permitted range as [code][min, max][/code], or an empty
## array for an unknown key.
func get_permitted_range(key: String) -> PackedFloat64Array:
	if not _values.has(key):
		return PackedFloat64Array()
	var entry := _values[key] as Dictionary
	return PackedFloat64Array([float(entry["min"]), float(entry["max"])])


func get_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for key: Variant in _values:
		keys.append(String(key))
	keys.sort()
	return keys


## The closed set a world may override through the Level Contract. Declared in
## the tuning data so the contract references one list rather than keeping a
## second that drifts.
func get_world_overridable_keys() -> PackedStringArray:
	return _world_overridable.duplicate()


func is_world_overridable(key: String) -> bool:
	return _world_overridable.has(key)


func get_schema_version() -> String:
	return _schema_version


func get_load_errors() -> Array[TuningError]:
	return _errors.duplicate()


## Applies a world's declared tuning overrides. An override of a key outside the
## sanctioned set, of an unknown key, or of a value outside the declared range is
## REJECTED — the whole override set is refused and nothing is applied, so a world
## never runs half-overridden. Returns true only when every override was applied.
func apply_world_overrides(
	overrides: Dictionary, out_errors: Array[TuningError] = []
) -> bool:
	var staged: Dictionary = {}

	for key: Variant in overrides:
		var name: String = String(key)

		if not _values.has(name):
			out_errors.append(TuningError.new(
				TuningError.UNKNOWN_KEY, name, "world overrides a key that does not exist"))
			continue

		if not is_world_overridable(name):
			out_errors.append(TuningError.new(
				TuningError.OVERRIDE_NOT_PERMITTED,
				name,
				"key is not in the sanctioned world-overridable set"))
			continue

		var raw: Variant = overrides[key]
		if not (raw is float or raw is int):
			out_errors.append(TuningError.new(
				TuningError.MALFORMED_ENTRY, name, "override value is not numeric"))
			continue

		var value: float = float(raw)
		var bounds := get_permitted_range(name)
		if value < bounds[0] or value > bounds[1]:
			out_errors.append(TuningError.new(
				TuningError.OUT_OF_RANGE,
				name,
				"override %s outside permitted range [%s, %s]" % [value, bounds[0], bounds[1]]))
			continue

		staged[name] = value

	if not out_errors.is_empty():
		return false

	for name: Variant in staged:
		(_values[name] as Dictionary)["value"] = staged[name]
	return true
