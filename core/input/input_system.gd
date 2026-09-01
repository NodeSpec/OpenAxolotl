class_name InputSystem
extends RefCounted

## The Player Input Interface (REQ-024).
##
## The ONE place raw input becomes meaning. The controller consumes PlayerIntent
## and worlds consume nothing at all — that indirection is AC-6, and it is what
## makes context-sensitive bindings and remapping possible in the first place: a
## world gating on "the player pressed W" could never be rebound.
##
## Events are PUSHED IN through handle_event() rather than pulled from Godot's
## `Input` singleton. Three things fall out of that choice:
##
##   * The whole node is testable headlessly. Constructed events drive the real
##     resolution path, so the binding table, the context rule and the device
##     switch are all covered without a display, a window or a scene.
##   * `Input` appears nowhere in `core/`, which turns AC-6 from a convention
##     into a property a scan can prove.
##   * A future scene node forwards _unhandled_input here and adds nothing else,
##     so the engine-facing surface stays one function wide.
##
## HELD versus EDGE. Directional verbs are held state — the player steers for as
## long as the key is down — while every other verb is edge-triggered and appears
## once, on the frame it was pressed. PlayerIntent already draws that line, so
## this node tracks held physical inputs and drains a pressed-this-frame set.

const SETTINGS_SECTION := "input"

## Emitted when the active device changes mid-session (AC-5). Carries the prompt
## set so the HUD can follow without knowing what a device is.
signal device_changed(device_id: String, prompt_set: String)

## Ability verbs never reach the controller. The Gill Mod system subscribes here
## rather than reading input itself.
signal ability_verb_requested(verb_id: String)

var _bindings: BindingTable
var _grammar: MovementGrammar.Grammar = MovementGrammar.Grammar.WATER
var _device: InputDevice.Kind = InputDevice.Kind.KEYBOARD_MOUSE

## Physical input ids currently down, for the active device only.
var _held: Dictionary = {}

## Movement verbs pressed since the last poll_intent().
var _pressed: Array[MovementGrammar.Verb] = []


func _init(bindings: BindingTable) -> void:
	_bindings = bindings


func get_bindings() -> BindingTable:
	return _bindings


# --- Grammar context (AC-2) --------------------------------------------------

## Reported by the controller when the axolotl crosses between water and land.
##
## Held inputs are DELIBERATELY kept across the change. A player holding W
## through the surface transition is steering continuously; dropping the held set
## would make them re-press to keep swimming, and the water/land seam is exactly
## where the game must not stutter. The binding those keys resolve through
## changes with the context, which is the point.
func set_grammar(grammar: MovementGrammar.Grammar) -> void:
	_grammar = grammar


func get_grammar() -> MovementGrammar.Grammar:
	return _grammar


# --- Device tracking (AC-5) --------------------------------------------------

func get_device() -> InputDevice.Kind:
	return _device


func active_prompt_set() -> String:
	return InputDevice.prompt_set(_device)


## Switches the active device. Held inputs are dropped, because they belong to
## the device that is no longer driving: a key held when the player picks up the
## gamepad would otherwise stay held forever, and no keyboard release event is
## coming to clear it.
func _switch_device(device: InputDevice.Kind) -> void:
	if device == _device:
		return
	_device = device
	_held.clear()
	device_changed.emit(InputDevice.device_id(device),
		InputDevice.prompt_set(device))


# --- The event path ----------------------------------------------------------

## Feeds one raw event through the bindings. Returns true when the event mapped
## to something, so a caller can mark it handled.
##
## No restart is needed to change device (AC-5): the first event from the other
## device switches the active scheme and re-publishes the prompt set. That is
## also why resolution is keyed on the ACTIVE device rather than the event's —
## the switch happens first, then the event resolves under the new scheme.
func handle_event(event: InputEvent) -> bool:
	if event == null:
		return false

	# Key repeat is not a new press. Without this a held key would re-fire an
	# edge verb every repeat interval, so holding SPACE would machine-gun hops.
	if event is InputEventKey and (event as InputEventKey).echo:
		return false

	var source := InputDevice.from_event(event)
	if source == InputDevice.UNKNOWN:
		return false
	_switch_device(source as InputDevice.Kind)

	if event is InputEventJoypadMotion:
		return _handle_axis(event as InputEventJoypadMotion)

	var physical := InputDevice.event_id(event)
	if physical.is_empty():
		return false

	if not InputDevice.is_pressed(event):
		return _release(physical)

	return _press(physical)


## A stick axis carries two bindings on one physical control, so its two signed
## ids are mutually exclusive. Pushing one way releases the other; returning to
## centre releases both. Deriving the ids from the axis rather than from the
## value is what makes the centre case work at all — a value of 0.0 reads as the
## `+` side, so releasing "the id this event carries" would leave a stick pushed
## left held forever.
func _handle_axis(event: InputEventJoypadMotion) -> bool:
	var ids := InputDevice.axis_ids(event)
	var positive := ids[0]
	var negative := ids[1]

	if not InputDevice.is_pressed(event):
		var released := _release(positive)
		return _release(negative) or released

	var active := positive if event.axis_value >= 0.0 else negative
	_release(negative if active == positive else positive)
	return _press(active)


func _press(physical: String) -> bool:
	var handled := false

	# A directional component is held state, not a press.
	if _bindings.direction_for(_device, _grammar, physical) != Vector3.ZERO:
		_held[physical] = true
		handled = true

	var verb := _bindings.resolve_press(_device, _grammar, physical)
	if verb == InputVerb.UNKNOWN:
		return handled

	var typed := verb as InputVerb.Verb
	if InputVerb.is_movement(typed):
		var movement := InputVerb.movement_equivalent(typed)
		if not _pressed.has(movement):
			_pressed.append(movement)
	else:
		ability_verb_requested.emit(InputVerb.verb_id(typed))

	return true


func _release(physical: String) -> bool:
	if not _held.has(physical):
		return false
	_held.erase(physical)
	return true


# --- The frame ---------------------------------------------------------------

## The intent for this frame, draining the edge-triggered set.
##
## Direction is summed from the held components and normalised HERE rather than
## in the controller, so a diagonal is not faster than a straight line no matter
## which scheme produced it — a keyboard's two full-deflection keys and a stick's
## single deflection must feel the same.
func poll_intent() -> PlayerIntent:
	var direction := Vector3.ZERO
	for physical: String in _held:
		direction += _bindings.direction_for(_device, _grammar, physical)

	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	# The land grammar is planar; a held swim-up carried onto land would push the
	# axolotl into the ground rather than doing nothing.
	if _grammar == MovementGrammar.Grammar.LAND:
		direction.y = 0.0
		if direction.length_squared() > 0.0:
			direction = direction.normalized()

	var intent := PlayerIntent.new(direction, _pressed)
	_pressed.clear()
	return intent


## Held inputs and pending presses, dropped. For a respawn or a menu close, where
## carrying a stale held key into the new state would move the player on the
## frame they regain control.
func clear() -> void:
	_held.clear()
	_pressed.clear()


func is_held(physical: String) -> bool:
	return _held.has(physical)


# --- Persistence (AC-3) ------------------------------------------------------

## Loads remapped bindings from the save profile's settings path. Absent or
## unreadable, the table already holding the defaults is kept — a player whose
## profile is new or damaged gets the default scheme, never no scheme.
func load_bindings(store: SettingsStore,
		out_errors: Array[InputError] = []) -> bool:
	var stored := store.load_section(SETTINGS_SECTION)
	if stored.is_empty():
		return false

	var table := BindingTable.from_dictionary(stored, out_errors)
	if table == null or table.size() == 0:
		return false

	_bindings = table
	return true


## Persists the current table. Goes through the Save Integration Interface's
## settings path rather than a private file of this node's, so one profile
## carries bindings and volumes together.
func save_bindings(store: SettingsStore) -> void:
	store.save_section(SETTINGS_SECTION, _bindings.to_dictionary())
