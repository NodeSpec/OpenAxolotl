class_name BindingTable
extends RefCounted

## Both control schemes, the conflict rule, and remapping (REQ-024 AC-1/2/3/4).
##
## The table is this node's own data rather than Godot's InputMap, because
## InputMap cannot express a binding scoped to a movement grammar and the whole
## scheme depends on that scoping. Intent resolves here as
## (device, context, physical input) -> verb; a scene-facing adapter can project
## the currently-active slice into InputMap actions when one is needed, but the
## authority is this table.
##
## THE CONFLICT RULE, which is the only subtle thing in this file: two bindings
## collide when they are on the same device, share a physical input, and their
## contexts intersect. Context intersection is what lets W be swim-forward in
## water and waddle-forward on land (AC-2) while still refusing to let W be two
## different things in the same context (AC-4). Getting this scoped wrong in
## either direction breaks a criterion: too strict and the shared-input scheme
## cannot be configured at all, too loose and a rebind silently steals an input
## the player is still using.
##
## Defaults live in `default_bindings.json` as DATA, discovered and parsed the
## same way a player's saved remap is. A remap is not a special case of the
## defaults; both are the same dictionary through the same validation.

const DEFAULTS_PATH := "res://core/input/default_bindings.json"
const FIELD_BINDINGS := "bindings"

var _bindings: Array[InputBinding] = []


static func load_from_file(path: String,
		out_errors: Array[InputError] = []) -> BindingTable:
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
			"", "cannot read bindings file '%s'" % path))
		return null

	var text := handle.get_as_text()
	handle.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
			"", "'%s' is not a JSON object" % path))
		return null

	return BindingTable.from_dictionary(parsed as Dictionary, out_errors)


## Builds a table from a declaration. A binding that fails validation or
## conflicts is REFUSED with a named error and the rest still load — one bad
## entry in a hand-edited file must not cost the player every other binding.
static func from_dictionary(source: Dictionary,
		out_errors: Array[InputError] = []) -> BindingTable:
	var table := BindingTable.new()

	if not source.has(FIELD_BINDINGS):
		out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
			"", "declaration has no '%s' array" % FIELD_BINDINGS))
		return table

	for entry: Variant in (source[FIELD_BINDINGS] as Array):
		if not (entry is Dictionary):
			out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
				"", "a binding entry is not an object"))
			continue
		var binding := InputBinding.from_dictionary(entry as Dictionary, out_errors)
		if binding != null:
			table.add(binding, out_errors)

	return table


func to_dictionary() -> Dictionary:
	var out: Array[Dictionary] = []
	for binding: InputBinding in _bindings:
		out.append(binding.to_dictionary())
	return {FIELD_BINDINGS: out}


# --- The conflict rule -------------------------------------------------------

## The binding [param candidate] would collide with, or null when it is free.
## [param ignoring] is skipped, so re-checking a binding against the table it
## already lives in does not report it conflicting with itself.
func find_conflict(candidate: InputBinding,
		ignoring: InputBinding = null) -> InputBinding:
	for existing: InputBinding in _bindings:
		if existing == ignoring or existing == candidate:
			continue
		if existing.device != candidate.device:
			continue
		if not BindingContext.intersects(existing.context, candidate.context):
			continue
		for physical: String in candidate.physical_inputs():
			if existing.uses(physical):
				return existing
	return null


## Adds a binding, refusing a conflicting one (AC-4). Returns false and appends a
## named error naming BOTH verbs, since "W is taken" is unactionable without
## knowing what took it.
func add(binding: InputBinding, out_errors: Array[InputError] = []) -> bool:
	if binding == null:
		return false

	var clash := find_conflict(binding)
	if clash != null:
		out_errors.append(InputError.new(InputError.BINDING_CONFLICT,
			InputVerb.verb_id(binding.verb),
			"conflicts with '%s' in context '%s' on device '%s'" % [
				InputVerb.verb_id(clash.verb),
				BindingContext.context_id(clash.context),
				InputDevice.device_id(clash.device),
			]))
		return false

	_bindings.append(binding)
	return true


# --- Remapping (AC-3) --------------------------------------------------------

## Rebinds a press verb. The candidate is checked BEFORE anything is written, so
## a rejected rebind leaves the previous binding exactly as it was — AC-4 says
## reject "rather than silently overriding", and a rollback after a partial write
## is how that promise usually gets broken.
func rebind(verb: InputVerb.Verb, device: InputDevice.Kind, physical: String,
		out_errors: Array[InputError] = []) -> bool:
	var existing := binding_for(verb, device)
	if existing == null:
		out_errors.append(InputError.new(InputError.UNBOUND_VERB,
			InputVerb.verb_id(verb),
			"no binding on device '%s' to remap" % InputDevice.device_id(device)))
		return false

	if existing.is_directional():
		out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
			InputVerb.verb_id(verb),
			"is directional; remap one component with rebind_direction()"))
		return false

	if physical.is_empty():
		out_errors.append(InputError.new(InputError.NO_PHYSICAL_INPUT,
			InputVerb.verb_id(verb), "cannot rebind to an empty input"))
		return false

	var candidate := existing.duplicate_binding()
	candidate.input = physical

	var clash := find_conflict(candidate, existing)
	if clash != null:
		out_errors.append(InputError.new(InputError.BINDING_CONFLICT,
			InputVerb.verb_id(verb),
			"'%s' is already bound to '%s' in context '%s'" % [
				physical, InputVerb.verb_id(clash.verb),
				BindingContext.context_id(clash.context),
			]))
		return false

	existing.input = physical
	return true


## Rebinds one component of a directional verb, under the same rule.
func rebind_direction(verb: InputVerb.Verb, device: InputDevice.Kind,
		component: String, physical: String,
		out_errors: Array[InputError] = []) -> bool:
	var existing := binding_for(verb, device)
	if existing == null or not existing.is_directional():
		out_errors.append(InputError.new(InputError.UNBOUND_VERB,
			InputVerb.verb_id(verb), "no directional binding on device '%s'"
			% InputDevice.device_id(device)))
		return false

	if not InputVerb.required_components(verb).has(component):
		out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
			InputVerb.verb_id(verb), "'%s' is not one of its components"
			% component))
		return false

	if physical.is_empty():
		out_errors.append(InputError.new(InputError.NO_PHYSICAL_INPUT,
			InputVerb.verb_id(verb), "cannot rebind to an empty input"))
		return false

	var candidate := existing.duplicate_binding()
	candidate.directions[component] = physical

	var clash := find_conflict(candidate, existing)
	if clash != null:
		out_errors.append(InputError.new(InputError.BINDING_CONFLICT,
			InputVerb.verb_id(verb),
			"'%s' is already bound to '%s' in context '%s'" % [
				physical, InputVerb.verb_id(clash.verb),
				BindingContext.context_id(clash.context),
			]))
		return false

	# A directional verb may also collide with ITSELF: binding two components to
	# the same key would leave the player unable to steer apart the two.
	for other: String in InputVerb.required_components(verb):
		if other != component and String(existing.directions[other]) == physical:
			out_errors.append(InputError.new(InputError.BINDING_CONFLICT,
				InputVerb.verb_id(verb),
				"'%s' already drives its own '%s' component" % [physical, other]))
			return false

	existing.directions[component] = physical
	return true


# --- Lookup ------------------------------------------------------------------

func binding_for(verb: InputVerb.Verb, device: InputDevice.Kind) -> InputBinding:
	for binding: InputBinding in _bindings:
		if binding.verb == verb and binding.device == device:
			return binding
	return null


func bindings_for_device(device: InputDevice.Kind) -> Array[InputBinding]:
	var out: Array[InputBinding] = []
	for binding: InputBinding in _bindings:
		if binding.device == device:
			out.append(binding)
	return out


## The press verb [param physical] triggers in [param grammar], or UNKNOWN.
## Directional bindings are resolved separately, through direction_for().
func resolve_press(device: InputDevice.Kind, grammar: MovementGrammar.Grammar,
		physical: String) -> int:
	for binding: InputBinding in _bindings:
		if binding.device != device or binding.is_directional():
			continue
		if not BindingContext.admits(binding.context, grammar):
			continue
		if binding.input == physical:
			return binding.verb
	return InputVerb.UNKNOWN


## The direction [param physical] contributes in [param grammar], or ZERO.
func direction_for(device: InputDevice.Kind, grammar: MovementGrammar.Grammar,
		physical: String) -> Vector3:
	for binding: InputBinding in _bindings:
		if binding.device != device or not binding.is_directional():
			continue
		if not BindingContext.admits(binding.context, grammar):
			continue
		var component := binding.component_for(physical)
		if not component.is_empty():
			return InputVerb.component_vector(component)
	return Vector3.ZERO


# --- Coverage (AC-1) ---------------------------------------------------------

## Verbs with no binding on [param device]. AC-1 is the assertion that this is
## empty for both devices, which is a property of the table rather than a
## checklist someone maintains by hand.
func unbound_verbs(device: InputDevice.Kind) -> Array[InputVerb.Verb]:
	var out: Array[InputVerb.Verb] = []
	for verb: InputVerb.Verb in InputVerb.all():
		if binding_for(verb, device) == null:
			out.append(verb)
	return out


func is_complete(device: InputDevice.Kind) -> bool:
	return unbound_verbs(device).is_empty()


func size() -> int:
	return _bindings.size()
