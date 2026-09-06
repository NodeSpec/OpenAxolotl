class_name ContractValidator
extends RefCounted

## The hub's runtime Level Contract validation (REQ-009 AC-4, REQ-006 AC-1).
##
## The Python compliance checker guards the MERGE; this guards the LOAD. They
## are two engines over ONE data file — `contracts/level_contract.v1.json` —
## because "fork it" is the project's premise: a forked repo with a world
## dropped straight into `worlds/` never went through anyone's CI, and the hub
## still must refuse to load what does not conform rather than crash on it.
##
## Same design law as the Python engine: this class knows rule KINDS, never
## contract elements. There is no `_check_spawn_point()` here and never will
## be — adding a conformance rule is an edit to the contract file only, and an
## element this engine has never heard of validates fine the day it appears.
## A rule KIND this engine does not implement is reported as its own named
## error instead of being skipped, because a skipped rule is a rule that
## silently stopped protecting anyone.
##
## Violations carry the same stable dotted ids the Python checker emits
## (`<element>.<kind>`), so an agent self-correcting against either gate is
## reading one vocabulary.

const DEFAULT_SCHEMA_PATH := "res://contracts/level_contract.v1.json"

var _schema: Dictionary = {}
var _schema_ok := false


func _init(schema_path: String = DEFAULT_SCHEMA_PATH) -> void:
	var text := _read_file(schema_path)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_schema = parsed as Dictionary
		_schema_ok = true


func is_ready() -> bool:
	return _schema_ok


func contract_version() -> String:
	return String(_schema.get("contractVersion", "unknown"))


## Validates one module directory. Returns true when it conforms; every
## violation is appended to [param out_errors]. A missing or unreadable schema
## refuses ALL modules with a named error — a hub that loads worlds unchecked
## because its contract went missing would be strictly worse than one that
## loads nothing.
func validate_module(module_dir: String,
		out_errors: Array[HubError]) -> bool:
	if not _schema_ok:
		out_errors.append(HubError.new(
			HubError.SCHEMA_UNAVAILABLE, DEFAULT_SCHEMA_PATH,
			"the Level Contract schema could not be loaded; refusing to "
			+ "validate rather than loading worlds unchecked"))
		return false

	var before := out_errors.size()
	var manifest: Variant = _load_manifest(module_dir, out_errors)
	if manifest == null:
		return false

	for pair: Array in _collect_rules():
		_apply_rule(String(pair[0]), pair[1] as Dictionary,
			module_dir, manifest as Dictionary, out_errors)

	return out_errors.size() == before


## (element, rule) pairs in the same stable order the Python checker walks:
## moduleLayout first, then required and optional elements sorted by name.
func _collect_rules() -> Array[Array]:
	var pairs: Array[Array] = []
	var layout := _schema.get("moduleLayout", {}) as Dictionary
	for rule: Variant in layout.get("rules", []) as Array:
		pairs.append(["moduleLayout", rule])

	for section: String in ["required", "optional"]:
		var elements := _schema.get(section, {}) as Dictionary
		var names := elements.keys()
		names.sort()
		for name: Variant in names:
			var body: Variant = elements[name]
			if not (body is Dictionary):
				continue
			for rule: Variant in (body as Dictionary).get("rules", []) as Array:
				pairs.append([String(name), rule])
	return pairs


func _apply_rule(element: String, rule: Dictionary, module_dir: String,
		manifest: Dictionary, out_errors: Array[HubError]) -> void:
	var kind := String(rule.get("kind", ""))
	var subject := "%s.%s" % [element, kind]

	match kind:
		"file_present":
			var path := module_dir.path_join(String(rule["path"]))
			if not FileAccess.file_exists(path):
				_violation(out_errors, subject,
					"required file '%s' is missing" % String(rule["path"]))
		"file_absent":
			var path := module_dir.path_join(String(rule["path"]))
			if FileAccess.file_exists(path):
				_violation(out_errors, subject,
					"forbidden file '%s' is present" % String(rule["path"]))
		"manifest_field_present":
			if _read_path(manifest, String(rule["field"])) == null:
				_violation(out_errors, subject,
					"manifest field '%s' is missing" % String(rule["field"]))
		"manifest_field_type":
			var value: Variant = _read_path(manifest, String(rule["field"]))
			if value != null and not _type_matches(value, String(rule["type"])):
				_violation(out_errors, subject,
					"manifest field '%s' must be of type %s"
					% [String(rule["field"]), String(rule["type"])])
		"manifest_field_matches":
			var value: Variant = _read_path(manifest, String(rule["field"]))
			if value is String:
				var regex := RegEx.create_from_string(String(rule["pattern"]))
				if regex.search(String(value)) == null:
					_violation(out_errors, subject,
						"'%s' does not match %s"
						% [String(value), String(rule["pattern"])])
		"manifest_field_in_set":
			var value: Variant = _read_path(manifest, String(rule["field"]))
			if value != null:
				var allowed := rule.get("values", []) as Array
				if not allowed.has(value):
					_violation(out_errors, subject,
						"'%s' is not one of %s" % [str(value), str(allowed)])
		"manifest_field_equals_directory_name":
			var value: Variant = _read_path(manifest, String(rule["field"]))
			var dir_name := module_dir.rstrip("/").get_file()
			if value is String and String(value) != dir_name:
				_violation(out_errors, subject,
					"'%s' must equal the module directory name '%s'"
					% [String(value), dir_name])
		"manifest_array_min_length":
			var value: Variant = _read_path(manifest, String(rule["field"]))
			if value is Array and (value as Array).size() < int(rule["min"]):
				_violation(out_errors, subject,
					"'%s' needs at least %d entr(ies)"
					% [String(rule["field"]), int(rule["min"])])
		"manifest_array_items_prefixed_by":
			_rule_items_prefixed(rule, manifest, subject, out_errors)
		"manifest_keys_subset_of":
			_rule_keys_subset(rule, manifest, subject, out_errors)
		"scene_group_count":
			_rule_scene_group_count(rule, module_dir, subject, out_errors)
		_:
			# A kind this engine cannot enforce means the CONTRACT is newer
			# than the hub. Refusing the module with the gap named beats
			# loading a world a rule was supposed to have screened.
			out_errors.append(HubError.new(
				HubError.UNKNOWN_RULE_KIND, subject,
				"this hub does not implement rule kind '%s'" % kind))


func _rule_items_prefixed(rule: Dictionary, manifest: Dictionary,
		subject: String, out_errors: Array[HubError]) -> void:
	var value: Variant = _read_path(manifest, String(rule["field"]))
	if not (value is Array):
		return
	var prefix_value: Variant = _read_path(manifest, String(rule["prefixFrom"]))
	if not (prefix_value is String):
		return
	var prefix := String(prefix_value) + "."
	for item: Variant in (value as Array):
		if not (item is String) or not String(item).begins_with(prefix):
			_violation(out_errors, subject,
				"'%s' must begin with '%s'" % [str(item), prefix])


func _rule_keys_subset(rule: Dictionary, manifest: Dictionary,
		subject: String, out_errors: Array[HubError]) -> void:
	var value: Variant = _read_path(manifest, String(rule["field"]))
	if not (value is Dictionary):
		return
	var source := String(rule.get("allowedFrom", ""))
	var parts := source.split("#")
	var text := _read_file("res://" + parts[0])
	var allowed: Array = []
	if not text.is_empty():
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary and parts.size() > 1:
			allowed = (parsed as Dictionary).get(parts[1], []) as Array
	for key: Variant in (value as Dictionary):
		if not allowed.has(String(key)):
			_violation(out_errors, subject,
				"'%s' is not a world-overridable key" % String(key))


func _rule_scene_group_count(rule: Dictionary, module_dir: String,
		subject: String, out_errors: Array[HubError]) -> void:
	var group := String(rule["group"])
	var count := _count_scene_group(module_dir.path_join("world.tscn"), group)
	if rule.has("min") and count < int(rule["min"]):
		_violation(out_errors, subject,
			"group '%s' needs at least %d node(s), found %d"
			% [group, int(rule["min"]), count])
	if rule.has("max") and count > int(rule["max"]):
		_violation(out_errors, subject,
			"group '%s' allows at most %d node(s), found %d"
			% [group, int(rule["max"]), count])


## Counts group memberships the same way the Python checker does: from the
## scene FILE, not an instantiated tree — validation must never execute a
## module's content before it has passed.
func _count_scene_group(scene_path: String, group: String) -> int:
	var text := _read_file(scene_path)
	if text.is_empty():
		return 0
	var count := 0
	var node_line := RegEx.create_from_string("^\\[node\\s+.*\\]\\s*$")
	var groups_attr := RegEx.create_from_string("groups\\s*=\\s*\\[([^\\]]*)\\]")
	var quoted := RegEx.create_from_string("\"([^\"]*)\"")
	for line: String in text.split("\n"):
		if node_line.search(line) == null:
			continue
		var attr := groups_attr.search(line)
		if attr == null:
			continue
		for match_: RegExMatch in quoted.search_all(attr.get_string(1)):
			if match_.get_string(1) == group:
				count += 1
	return count


func _load_manifest(module_dir: String,
		out_errors: Array[HubError]) -> Variant:
	var path := module_dir.path_join("world.json")
	if not FileAccess.file_exists(path):
		out_errors.append(HubError.new(
			HubError.MISSING_MANIFEST, module_dir,
			"no world.json in this module"))
		return null
	var text := _read_file(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		out_errors.append(HubError.new(
			HubError.MALFORMED_MANIFEST, path,
			"world.json is not a JSON object"))
		return null
	return parsed


func _violation(out_errors: Array[HubError], subject: String,
		message: String) -> void:
	out_errors.append(HubError.new(
		HubError.CONTRACT_VIOLATION, subject, message))


static func _read_path(data: Dictionary, dotted: String) -> Variant:
	var current: Variant = data
	for part: String in dotted.split("."):
		if not (current is Dictionary) or not (current as Dictionary).has(part):
			return null
		current = (current as Dictionary)[part]
	return current


static func _type_matches(value: Variant, type_name: String) -> bool:
	match type_name:
		"array":
			return value is Array
		"object":
			return value is Dictionary
		"string":
			return value is String
		"number":
			return value is float or value is int
		"boolean":
			return value is bool
		_:
			return false


static func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		return ""
	var text := handle.get_as_text()
	handle.close()
	return text
