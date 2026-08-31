class_name SaveSystem
extends SettingsStore

## The Save Integration Interface (REQ-014).
##
## Every system persists through this node; nothing else touches the save file.
## That single rule is what makes forked and divergent worlds survivable, and it
## is a checked criterion rather than a convention.
##
## Extends [SettingsStore] so it satisfies the port the Audio System declared —
## audio volumes and input bindings live in the profile's settings section
## alongside everything else, not in private files of their own.
##
## Deliberately NOT an autoload: it takes its policy by construction so the
## compatibility decision is swappable and testable.

const SETTINGS_KEY := "settings"
const WORLDS_KEY := "worlds"
const GILL_MODS_KEY := "unlockedGillMods"

var _profile: Dictionary = {}
var _policy: SaveCompatibilityPolicy
var _unavailable_modules: PackedStringArray = []
var _quarantined_modules: PackedStringArray = []
var _reconciled_modules: PackedStringArray = []


func _init(policy: SaveCompatibilityPolicy = null) -> void:
	_policy = policy if policy != null else TieredCompatibilityPolicy.new()
	_profile = _empty_profile()


static func _empty_profile() -> Dictionary:
	return {
		"saveFormatVersion": SaveMigrations.CURRENT_VERSION,
		SETTINGS_KEY: {},
		WORLDS_KEY: {},
		GILL_MODS_KEY: [],
	}


# --- Load / save ------------------------------------------------------------

## Loads a profile, migrating it forward if needed.
##
## A malformed or absent file yields a fresh profile plus a named error rather
## than a crash — losing a save is bad, but refusing to start is worse.
func load_from_file(path: String, out_errors: Array[SaveError] = []) -> bool:
	if not FileAccess.file_exists(path):
		_profile = _empty_profile()
		out_errors.append(SaveError.new(
			SaveError.FILE_UNREADABLE, "", "no save file at '%s'" % path))
		return false

	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		_profile = _empty_profile()
		out_errors.append(SaveError.new(
			SaveError.FILE_UNREADABLE, "", "could not open '%s'" % path))
		return false

	var text := handle.get_as_text()
	handle.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_profile = _empty_profile()
		out_errors.append(SaveError.new(
			SaveError.MALFORMED_JSON, "", "'%s' is not a JSON object" % path))
		return false

	var migrated := SaveMigrations.migrate_to_current(parsed as Dictionary, out_errors)
	if migrated.is_empty():
		_profile = _empty_profile()
		return false

	_profile = migrated
	_ensure_shape()
	return true


func save_to_file(path: String) -> bool:
	var handle := FileAccess.open(path, FileAccess.WRITE)
	if handle == null:
		push_error("[%s] could not write '%s'" % [SaveError.FILE_UNREADABLE, path])
		return false
	handle.store_string(JSON.stringify(_profile, "  "))
	handle.close()
	return true


func _ensure_shape() -> void:
	if not _profile.has(SETTINGS_KEY):
		_profile[SETTINGS_KEY] = {}
	if not _profile.has(WORLDS_KEY):
		_profile[WORLDS_KEY] = {}
	if not _profile.has(GILL_MODS_KEY):
		_profile[GILL_MODS_KEY] = []


# --- World namespaces -------------------------------------------------------

## Reconciles an installed world against its stored progress, applying the
## compatibility policy (AC-4).
##
## [param declared] is the world's CURRENT contract-visible shape. Returns the
## outcome the policy chose so a caller can surface it.
func open_world(module_id: String, declared: Dictionary) -> SaveCompatibilityPolicy.Outcome:
	var worlds := _profile[WORLDS_KEY] as Dictionary
	var current := WorldContractShape.from_dictionary(declared)

	if not worlds.has(module_id):
		worlds[module_id] = _fresh_world(current)
		return SaveCompatibilityPolicy.Outcome.LOAD

	var entry := worlds[module_id] as Dictionary
	var stored := WorldContractShape.from_dictionary(
		entry.get("declared", {}) as Dictionary)
	var outcome := _policy.decide(stored.classify(current))

	match outcome:
		SaveCompatibilityPolicy.Outcome.LOAD:
			pass
		SaveCompatibilityPolicy.Outcome.RECONCILE:
			# The world only gained elements: keep every stored value and let the
			# new ids take their defaults simply by being absent.
			entry["declared"] = current.to_dictionary()
			if not _reconciled_modules.has(module_id):
				_reconciled_modules.append(module_id)
		SaveCompatibilityPolicy.Outcome.QUARANTINE:
			# Set the blob aside INTACT rather than deleting it — reverting the
			# fork must restore the player's progress.
			var fresh := _fresh_world(current)
			fresh["quarantined"] = entry.duplicate(true)
			worlds[module_id] = fresh
			if not _quarantined_modules.has(module_id):
				_quarantined_modules.append(module_id)

	return outcome


static func _fresh_world(shape: WorldContractShape) -> Dictionary:
	return {
		"declared": shape.to_dictionary(),
		"unlocked": false,
		"completed": false,
		"lastCheckpoint": "",
		"regions": {},
		"collectibles": [],
		"quarantined": null,
	}


## Reads a world's namespaced data. A world can only ever address its own
## namespace — there is no call that takes another module's id.
func get_world_data(module_id: String) -> Dictionary:
	var worlds := _profile[WORLDS_KEY] as Dictionary
	if not worlds.has(module_id):
		return {}
	return (worlds[module_id] as Dictionary).duplicate(true)


## Writes a world's namespaced data. Reserved profile keys are refused so a world
## can never reach outside its namespace and clobber the profile (AC-2).
func put_world_data(
	module_id: String, data: Dictionary, out_errors: Array[SaveError] = []
) -> bool:
	if module_id == SETTINGS_KEY or module_id == GILL_MODS_KEY \
			or module_id == WORLDS_KEY or module_id == "saveFormatVersion":
		out_errors.append(SaveError.new(
			SaveError.FOREIGN_NAMESPACE_WRITE, module_id,
			"a world may not write to a reserved profile key"))
		return false

	var worlds := _profile[WORLDS_KEY] as Dictionary
	if not worlds.has(module_id):
		out_errors.append(SaveError.new(
			SaveError.FOREIGN_NAMESPACE_WRITE, module_id,
			"world was never opened; call open_world first"))
		return false

	var entry := worlds[module_id] as Dictionary
	for key: Variant in data:
		entry[String(key)] = data[key]
	return true


## Module ids present in the save that are not currently installed.
##
## Their data is RETAINED, never pruned: a world removed and later reinstalled
## finds its progress waiting (AC-3).
func find_orphaned_modules(installed_ids: PackedStringArray) -> PackedStringArray:
	var orphans := PackedStringArray()
	for key: Variant in (_profile[WORLDS_KEY] as Dictionary):
		var id := String(key)
		if not installed_ids.has(id):
			orphans.append(id)
	orphans.sort()
	return orphans


## Marks a module whose blob could not be read. The profile stays loadable and
## every other world stays playable — mirroring how the hub surfaces an
## unloadable module as an unavailable portal rather than failing the hub.
func mark_unavailable(module_id: String) -> void:
	if not _unavailable_modules.has(module_id):
		_unavailable_modules.append(module_id)


func get_unavailable_modules() -> PackedStringArray:
	return _unavailable_modules.duplicate()


func get_quarantined_modules() -> PackedStringArray:
	return _quarantined_modules.duplicate()


func get_reconciled_modules() -> PackedStringArray:
	return _reconciled_modules.duplicate()


func has_quarantined_blob(module_id: String) -> bool:
	var worlds := _profile[WORLDS_KEY] as Dictionary
	if not worlds.has(module_id):
		return false
	return (worlds[module_id] as Dictionary).get("quarantined", null) != null


# --- Profile-level state ----------------------------------------------------

func set_gill_mod_unlocked(mod_id: String) -> void:
	var mods := _profile[GILL_MODS_KEY] as Array
	if not mods.has(mod_id):
		mods.append(mod_id)


func get_unlocked_gill_mods() -> PackedStringArray:
	var out := PackedStringArray()
	for entry: Variant in (_profile[GILL_MODS_KEY] as Array):
		out.append(String(entry))
	out.sort()
	return out


func get_format_version() -> int:
	return int(_profile.get("saveFormatVersion", SaveMigrations.CURRENT_VERSION))


# --- SettingsStore (the port the Audio System declared) ---------------------

func load_section(section: String) -> Dictionary:
	var settings := _profile[SETTINGS_KEY] as Dictionary
	if not settings.has(section):
		return {}
	return (settings[section] as Dictionary).duplicate(true)


func save_section(section: String, payload: Dictionary) -> void:
	var settings := _profile[SETTINGS_KEY] as Dictionary
	settings[section] = payload.duplicate(true)
