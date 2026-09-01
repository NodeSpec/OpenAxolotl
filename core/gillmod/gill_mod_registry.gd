class_name GillModRegistry
extends RefCounted

## The extension interface, which is this node's real deliverable (REQ-004 AC-2).
##
## Registration is DIRECTORY DISCOVERY, not a constant listing the three MVP
## mods. That distinction is the whole criterion: a fixture mod must be addable
## "without modifying any file in the ability system core", and a registry
## constant would make every new mod an edit to this file. The three shipped mods
## live in `mods/` as data and are discovered by the same code path a community
## mod uses, so the path a fourth mod takes is the path that is already tested
## every run rather than one nobody has walked.
##
## Two validations are worth their weight:
##
##   * Tuning keys are checked against the live tuning surface at registration.
##     A mod citing a key that does not exist would otherwise fail at the moment
##     the player first activates it, which is the worst possible time and the
##     hardest to attribute back to the declaration.
##   * Affordances must be UNIQUE across registered mods. The criterion says each
##     mod unlocks an affordance "unavailable without it" — if two mods granted
##     the same one, neither would satisfy that, and the failure would look like
##     a gate bug in a world rather than a registration mistake here.
##
## Export note: DirAccess over res:// only sees files the export preset actually
## included. The mods directory must be in the export filter, or a shipped build
## discovers nothing. register() stays public so a world (or a test) can add a
## mod it holds in memory without touching the filesystem at all.

const MODS_DIRECTORY := "res://core/gillmod/mods"
const DECLARATION_EXTENSION := "json"

var _tuning: TuningData
var _mods: Dictionary = {}
var _order: PackedStringArray = []


func _init(tuning: TuningData) -> void:
	_tuning = tuning


## Discovers and registers every declaration in [param directory]. Returns how
## many registered; malformed declarations append named errors and are skipped
## rather than aborting the sweep, so one bad community mod cannot stop the
## other twenty loading.
func load_directory(directory: String,
		out_errors: Array[GillModError] = []) -> int:
	var dir := DirAccess.open(directory)
	if dir == null:
		out_errors.append(GillModError.new(GillModError.FILE_UNREADABLE,
			"", "cannot open mods directory '%s'" % directory))
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
		out_errors: Array[GillModError] = []) -> bool:
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		out_errors.append(GillModError.new(GillModError.FILE_UNREADABLE,
			"", "cannot read '%s'" % path))
		return false

	var text := handle.get_as_text()
	handle.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		out_errors.append(GillModError.new(GillModError.MALFORMED_JSON,
			"", "'%s' is not a JSON object" % path))
		return false

	var mod := GillMod.from_dictionary(parsed as Dictionary, out_errors)
	if mod == null:
		return false

	return register(mod, out_errors)


## The Level Contract's optional custom-ability element (AC-3). A world hands
## over the same declaration shape a file would carry, and it travels the same
## validation — a world's mod is not privileged, and not second-class either.
func register_from_contract(declaration: Dictionary,
		out_errors: Array[GillModError] = []) -> bool:
	var mod := GillMod.from_dictionary(declaration, out_errors)
	if mod == null:
		return false
	return register(mod, out_errors)


func register(mod: GillMod, out_errors: Array[GillModError] = []) -> bool:
	if mod == null:
		return false

	if _mods.has(mod.id):
		out_errors.append(GillModError.new(GillModError.DUPLICATE_ID,
			mod.id, "a mod with this id is already registered"))
		return false

	for key: String in [mod.duration_key, mod.cooldown_key]:
		if not _tuning.has_key(key):
			out_errors.append(GillModError.new(GillModError.UNKNOWN_TUNING_KEY,
				mod.id, "cites tuning key '%s', which does not exist" % key))
			return false

	for affordance: String in mod.affordances:
		var owner := find_affordance_owner(affordance)
		if not owner.is_empty():
			out_errors.append(GillModError.new(
				GillModError.AFFORDANCE_ALREADY_GRANTED, mod.id,
				"affordance '%s' is already granted by '%s', so neither mod "
				% [affordance, owner] + "would unlock it exclusively"))
			return false

	_mods[mod.id] = mod
	_order.append(mod.id)
	return true


## The mod that grants [param affordance], or "" when nothing does.
func find_affordance_owner(affordance: String) -> String:
	for mod_id: String in _order:
		if (_mods[mod_id] as GillMod).grants(affordance):
			return mod_id
	return ""


func has(mod_id: String) -> bool:
	return _mods.has(mod_id)


func get_mod(mod_id: String) -> GillMod:
	return _mods.get(mod_id, null)


func get_ids() -> PackedStringArray:
	return _order.duplicate()


func size() -> int:
	return _order.size()


## Every affordance any registered mod grants. The union a world's gates may
## reference; an id outside it is a world referencing a mod that is not installed.
func get_all_affordances() -> PackedStringArray:
	var out := PackedStringArray()
	for mod_id: String in _order:
		for affordance: String in (_mods[mod_id] as GillMod).affordances:
			out.append(affordance)
	out.sort()
	return out
