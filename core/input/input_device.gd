class_name InputDevice
extends RefCounted

## The two PC schemes, and the physical-input id encoding they share (REQ-024).
##
## PC only, so the device set is closed: keyboard-and-mouse, and gamepad. Every
## verb is bound in BOTH (AC-1), which is why the scheme is a device-keyed table
## rather than one map with alternates — "every verb bound in both schemes" is
## then a property a test can walk rather than a hope.
##
## PHYSICAL INPUT IDS are stable strings, not Godot keycodes. Three reasons:
## a saved profile survives an engine upgrade that renumbers a constant; a
## binding file stays readable to a contributor editing it by hand; and the
## conflict check compares ids rather than event objects, which have no useful
## equality. `event_id()` is the one place raw Godot input types are inspected.

enum Kind {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

const UNKNOWN := -1

## Prompt-set ids the HUD resolves to glyphs. Semantic, never file paths — the
## same rule the Gill Mod visual ids follow.
const PROMPT_SETS: Dictionary = {
	Kind.KEYBOARD_MOUSE: "prompts.keyboard_mouse",
	Kind.GAMEPAD: "prompts.gamepad",
}


static func all() -> Array[Kind]:
	var out: Array[Kind] = []
	for value: int in Kind.values():
		out.append(value as Kind)
	return out


static func device_id(kind: Kind) -> String:
	return String(Kind.keys()[kind]).to_lower()


static func from_id(id: String) -> int:
	for value: int in Kind.values():
		if device_id(value as Kind) == id:
			return value
	return UNKNOWN


static func prompt_set(kind: Kind) -> String:
	return String(PROMPT_SETS.get(kind, ""))


## The device an event came from, or UNKNOWN for an event neither scheme uses.
##
## Mouse MOTION is deliberately excluded while mouse BUTTONS are not: a gamepad
## player whose mouse is nudged on the desk must not have the prompts flip to
## keyboard glyphs mid-fight. A button press is intent; motion is furniture.
static func from_event(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Kind.KEYBOARD_MOUSE
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Kind.GAMEPAD
	return UNKNOWN


## The stable id for the physical input an event represents, or "" when the event
## carries none. This is the ONLY function in the project that reads Godot's raw
## input types; everything downstream works in ids and verbs.
static func event_id(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var name := OS.get_keycode_string(key.physical_keycode)
		if name.is_empty():
			name = OS.get_keycode_string(key.keycode)
		if name.is_empty():
			return ""
		return "key.%s" % name.to_lower()

	if event is InputEventMouseButton:
		return "mouse.%d" % (event as InputEventMouseButton).button_index

	if event is InputEventJoypadButton:
		return "pad.button.%d" % (event as InputEventJoypadButton).button_index

	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		# Sign is part of the id: a stick pushed left and the same stick pushed
		# right are different bindings, or a directional scheme cannot be built.
		return "pad.axis.%d.%s" % [motion.axis, "+" if motion.axis_value >= 0.0 else "-"]

	return ""


## Both signed ids for a stick axis, in `+`, `-` order. An axis has two bindings
## and only one physical control, so the two are mutually exclusive: pushing a
## stick right must release the left it was holding, and returning it to centre
## must release whichever side was held. Neither release arrives as its own
## event, so the caller derives both ids from the axis rather than from the
## value — which is what event_id() alone cannot give it, since a value of 0.0
## reads as the `+` side.
static func axis_ids(event: InputEventJoypadMotion) -> PackedStringArray:
	return PackedStringArray([
		"pad.axis.%d.+" % event.axis,
		"pad.axis.%d.-" % event.axis,
	])


## Whether an event reads as pressed. Axis motion counts as pressed past a
## deadzone, so a stick can drive the same edge-triggered path a button does.
const AXIS_DEADZONE := 0.5


static func is_pressed(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) >= AXIS_DEADZONE
	if event is InputEventKey:
		return (event as InputEventKey).pressed
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false
