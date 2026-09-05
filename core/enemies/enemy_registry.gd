class_name EnemyRegistry
extends RefCounted

## The Drift Fleet extension interface (REQ-012 AC-5), documented in
## docs/enemies.md.
##
## Registration is DIRECTORY DISCOVERY, exactly like GillModRegistry and for
## the same reason: the criterion says a fixture enemy can be added "without
## modifying any file in the enemy system core", and a registry constant would
## make every new enemy an edit to this file. The four shipped enemies live in
## `roster/` as data and are discovered by the same code path a fixture — or a
## post-MVP enemy — uses.
##
## Three validations carry real weight:
##
##   * Tuning keys are checked against the live tuning surface at
##     registration, so a misspelled key fails at load, not at first contact.
##   * A `dredge` declaration's area-wipe source must resolve through
##     CatastrophicSource's CLOSED set. A declaration cannot widen the set of
##     things that cost a life — REQ-003 AC-1/AC-2 stay structural even with
##     an open enemy roster.
##   * Only the `dredge` behavior may name a catastrophic source at all; the
##     other behaviors have no field for one, so an ordinary enemy cannot
##     even express a life cost.

const ROSTER_DIRECTORY := "res://core/enemies/roster"
const DECLARATION_EXTENSION := "json"

var _tuning: TuningData
var _enemies: Dictionary = {}
var _order: PackedStringArray = []


func _init(tuning: TuningData) -> void:
	_tuning = tuning


## Discovers and registers every declaration in [param directory]. Returns how
## many registered; malformed declarations append named errors and are skipped
## rather than aborting the sweep, so one bad declaration cannot stop the rest
## of the fleet loading.
func load_directory(directory: String,
		out_errors: Array[EnemyError] = []) -> int:
	var dir := DirAccess.open(directory)
	if dir == null:
		out_errors.append(EnemyError.new(EnemyError.FILE_UNREADABLE,
			"", "cannot open roster directory '%s'" % directory))
		return 0

	var loaded := 0
	var names := dir.get_files()
	names.sort()  # Deterministic registration order, independent of the filesystem.

	for name: String in names:
		if name.get_extension() != DECLARATION_EXTENSION:
			continue
		if load_declaration(directory.path_join(name), out_errors):
			loaded += 1

	return loaded


func load_declaration(path: String,
		out_errors: Array[EnemyError] = []) -> bool:
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		out_errors.append(EnemyError.new(EnemyError.FILE_UNREADABLE,
			"", "cannot read '%s'" % path))
		return false

	var text := handle.get_as_text()
	handle.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		out_errors.append(EnemyError.new(EnemyError.MALFORMED_JSON,
			"", "'%s' is not a JSON object" % path))
		return false

	var def := EnemyDef.from_dictionary(parsed as Dictionary, out_errors)
	if def == null:
		return false

	return register(def, out_errors)


func register(def: EnemyDef, out_errors: Array[EnemyError] = []) -> bool:
	if def == null:
		return false

	if _enemies.has(def.id):
		out_errors.append(EnemyError.new(EnemyError.DUPLICATE_ID,
			def.id, "an enemy with this id is already registered"))
		return false

	for key: String in def.cited_tuning_keys():
		if not _tuning.has_key(key):
			out_errors.append(EnemyError.new(EnemyError.UNKNOWN_TUNING_KEY,
				def.id, "cites tuning key '%s', which does not exist" % key))
			return false

	if def.behavior == EnemyDef.Behavior.DREDGE \
			and not CatastrophicSource.is_catastrophic(def.area_wipe_source):
		out_errors.append(EnemyError.new(
			EnemyError.UNSANCTIONED_CATASTROPHE, def.id,
			"area-wipe source '%s' is outside CatastrophicSource's closed "
			% def.area_wipe_source
			+ "set %s — a declaration cannot widen what costs a life"
			% str(CatastrophicSource.all_ids())))
		return false

	_enemies[def.id] = def
	_order.append(def.id)
	return true


func has(enemy_id: String) -> bool:
	return _enemies.has(enemy_id)


func get_enemy(enemy_id: String) -> EnemyDef:
	return _enemies.get(enemy_id, null)


func get_ids() -> PackedStringArray:
	return _order.duplicate()


func size() -> int:
	return _order.size()
