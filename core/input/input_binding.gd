class_name InputBinding
extends RefCounted

## One verb bound to one physical input, in one context, on one device.
##
## Pure DATA, and serializable to the shape the bindings file and the save
## profile both carry. Keeping a binding data rather than behaviour is what makes
## AC-3 ("every binding is remappable, and remapped bindings persist") a property
## of the format rather than a feature someone has to remember to implement per
## verb: a remap rewrites one field, and persistence is the same dictionary the
## defaults were read from.
##
## TWO SHAPES, because two kinds of verb exist. A press verb carries one `input`;
## a directional verb carries a `directions` map from named component to physical
## input. The alternative — a positional array — reads fine to code and terribly
## to the contributor editing the file, which is the reader this project actually
## optimises for.

const FIELD_VERB := "verb"
const FIELD_CONTEXT := "context"
const FIELD_DEVICE := "device"
const FIELD_INPUT := "input"
const FIELD_DIRECTIONS := "directions"

var verb: InputVerb.Verb
var context: BindingContext.Context
var device: InputDevice.Kind

## The physical input for a press verb. Empty for a directional verb.
var input: String = ""

## component name -> physical input id. Empty for a press verb.
var directions: Dictionary = {}


func _init(p_verb: InputVerb.Verb, p_context: BindingContext.Context,
		p_device: InputDevice.Kind) -> void:
	verb = p_verb
	context = p_context
	device = p_device


## Parses a declaration. Returns null and appends a NAMED error rather than a
## half-built binding — a binding that parsed partially would present as bound
## and do nothing, which is the failure mode hardest for a player to describe.
static func from_dictionary(source: Dictionary,
		out_errors: Array[InputError] = []) -> InputBinding:
	var declared_verb := String(source.get(FIELD_VERB, ""))

	var verb_value := InputVerb.from_id(declared_verb)
	if verb_value == InputVerb.UNKNOWN:
		out_errors.append(InputError.new(InputError.UNKNOWN_VERB,
			declared_verb, "not a player verb"))
		return null

	var context_value := BindingContext.from_id(String(source.get(FIELD_CONTEXT, "")))
	if context_value == BindingContext.UNKNOWN:
		out_errors.append(InputError.new(InputError.UNKNOWN_CONTEXT,
			declared_verb, "context '%s' is not water, land or any"
			% String(source.get(FIELD_CONTEXT, ""))))
		return null

	var device_value := InputDevice.from_id(String(source.get(FIELD_DEVICE, "")))
	if device_value == InputDevice.UNKNOWN:
		out_errors.append(InputError.new(InputError.UNKNOWN_DEVICE,
			declared_verb, "device '%s' is not keyboard_mouse or gamepad"
			% String(source.get(FIELD_DEVICE, ""))))
		return null

	var binding := InputBinding.new(verb_value as InputVerb.Verb,
		context_value as BindingContext.Context,
		device_value as InputDevice.Kind)

	if InputVerb.is_directional(binding.verb):
		if not source.has(FIELD_DIRECTIONS):
			out_errors.append(InputError.new(InputError.MALFORMED_BINDING,
				declared_verb, "a directional verb needs a '%s' map"
				% FIELD_DIRECTIONS))
			return null

		var declared: Dictionary = source[FIELD_DIRECTIONS] as Dictionary
		for component: String in InputVerb.required_components(binding.verb):
			var bound := String(declared.get(component, ""))
			if bound.is_empty():
				out_errors.append(InputError.new(
					InputError.INCOMPLETE_DIRECTIONS, declared_verb,
					"'%s' is unbound, so the player could not steer that way"
					% component))
				return null
			binding.directions[component] = bound
		return binding

	binding.input = String(source.get(FIELD_INPUT, ""))
	if binding.input.is_empty():
		out_errors.append(InputError.new(InputError.NO_PHYSICAL_INPUT,
			declared_verb, "no '%s' declared, so the verb is unreachable"
			% FIELD_INPUT))
		return null

	return binding


func to_dictionary() -> Dictionary:
	var out: Dictionary = {
		FIELD_VERB: InputVerb.verb_id(verb),
		FIELD_CONTEXT: BindingContext.context_id(context),
		FIELD_DEVICE: InputDevice.device_id(device),
	}
	if is_directional():
		out[FIELD_DIRECTIONS] = directions.duplicate()
	else:
		out[FIELD_INPUT] = input
	return out


func is_directional() -> bool:
	return InputVerb.is_directional(verb)


## Every physical input this binding occupies. The conflict check compares these
## sets, so a directional binding correctly conflicts on any one of its six
## components rather than only as a whole.
func physical_inputs() -> PackedStringArray:
	if is_directional():
		var out := PackedStringArray()
		for component: String in InputVerb.required_components(verb):
			out.append(String(directions[component]))
		return out
	return PackedStringArray([input])


## The component [param physical] drives, or "" when this binding does not use it.
func component_for(physical: String) -> String:
	if not is_directional():
		return ""
	for component: String in InputVerb.required_components(verb):
		if String(directions[component]) == physical:
			return component
	return ""


func uses(physical: String) -> bool:
	return physical_inputs().has(physical)


func duplicate_binding() -> InputBinding:
	var copy := InputBinding.new(verb, context, device)
	copy.input = input
	copy.directions = directions.duplicate()
	return copy
