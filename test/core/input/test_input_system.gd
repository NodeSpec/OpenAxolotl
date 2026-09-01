extends GdUnitTestSuite

## Input and Control Scheme — REQ-024.
##
## Test names carry the requirement id they prove (test_req_024_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).
##
## Events are constructed and fed through the real resolution path rather than
## calling the system's internals, so the device detection, the physical-input
## encoding, the context rule and the held/edge split are all covered by the same
## call a scene node would make.

const DEFAULTS := BindingTable.DEFAULTS_PATH

## Every source file that IS the input system, for the REQ-030 scan and for the
## AC-6 scan's exemption list.
const INPUT_SOURCES: PackedStringArray = [
	"res://core/input/input_error.gd",
	"res://core/input/input_verb.gd",
	"res://core/input/binding_context.gd",
	"res://core/input/input_device.gd",
	"res://core/input/input_binding.gd",
	"res://core/input/binding_table.gd",
	"res://core/input/input_system.gd",
]

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("input")


func _path(tag: String) -> String:
	return _temp_dir.path_join("%s.json" % tag)


func _table() -> BindingTable:
	var errors: Array[InputError] = []
	var table := BindingTable.load_from_file(DEFAULTS, errors)
	assert_object(table).override_failure_message(
		"the shipped default scheme must load").is_not_null()
	assert_array(errors).override_failure_message(
		"the shipped default scheme must load with no errors").is_empty()
	return table


func _system() -> InputSystem:
	return InputSystem.new(_table())


# --- Event construction ------------------------------------------------------

func _key(keycode: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	return event


func _mouse(index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	return event


func _pad_button(index: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index as JoyButton
	event.pressed = pressed
	return event


func _pad_axis(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis as JoyAxis
	event.axis_value = value
	return event


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


# --- AC-1: every verb bound in both schemes ---------------------------------

func test_req_024_every_verb_is_bound_in_both_schemes() -> void:
	var table := _table()

	# Anti-vacuity: a shrunken verb enum would make "all verbs bound" trivially
	# true. The axolotl's wide verb set is the reason this requirement exists.
	assert_int(InputVerb.all().size()).override_failure_message(
		"REQ-024: the verb set should cover two grammars plus the ability verbs"
	).is_greater_equal(11)

	for device: InputDevice.Kind in InputDevice.all():
		var missing := table.unbound_verbs(device)
		var names: Array[String] = []
		for verb: InputVerb.Verb in missing:
			names.append(InputVerb.verb_id(verb))
		assert_array(names).override_failure_message(
			"REQ-024 AC-1: '%s' leaves verbs unbound: %s"
			% [InputDevice.device_id(device), ", ".join(names)]).is_empty()
		assert_bool(table.is_complete(device)).is_true()


func test_req_024_a_scheme_missing_a_verb_is_reported_unbound() -> void:
	# The anti-vacuity control for the test above: prove the coverage check bites
	# when a verb really is missing, rather than always finding nothing.
	var declaration: Variant = JSON.parse_string(_read(DEFAULTS))
	var kept: Array = []
	for entry: Variant in (declaration as Dictionary)["bindings"] as Array:
		var binding := entry as Dictionary
		if String(binding["verb"]) == "climb" \
				and String(binding["device"]) == "gamepad":
			continue
		kept.append(binding)

	var errors: Array[InputError] = []
	var table := BindingTable.from_dictionary({"bindings": kept}, errors)

	assert_bool(table.is_complete(InputDevice.Kind.GAMEPAD)).override_failure_message(
		"the coverage check must notice a dropped binding").is_false()
	assert_bool(table.is_complete(InputDevice.Kind.KEYBOARD_MOUSE)).is_true()

	var names: Array[String] = []
	for verb: InputVerb.Verb in table.unbound_verbs(InputDevice.Kind.GAMEPAD):
		names.append(InputVerb.verb_id(verb))
	assert_array(names).is_equal(["climb"] as Array[String])


# --- AC-2: context-sensitive bindings ---------------------------------------

func test_req_024_the_same_key_means_different_verbs_by_grammar() -> void:
	var table := _table()
	var kbm := InputDevice.Kind.KEYBOARD_MOUSE
	var water := MovementGrammar.Grammar.WATER
	var land := MovementGrammar.Grammar.LAND

	# E: bubble boost in water, climb on land. One physical input, two verbs,
	# no conflict — this is the criterion in one line.
	assert_int(table.resolve_press(kbm, water, "key.e")).override_failure_message(
		"REQ-024 AC-2: E must be bubble boost in water").is_equal(
			InputVerb.Verb.BUBBLE_BOOST)
	assert_int(table.resolve_press(kbm, land, "key.e")).override_failure_message(
		"REQ-024 AC-2: E must be climb on land").is_equal(InputVerb.Verb.CLIMB)

	# SPACE crosses the kinds too: a direction component in water, a press verb
	# on land. Nothing in the binding format privileges one over the other.
	assert_int(table.resolve_press(kbm, land, "key.space")).is_equal(
		InputVerb.Verb.HOP)
	assert_int(table.resolve_press(kbm, water, "key.space")).override_failure_message(
		"SPACE is swim-up in water, not a press verb").is_equal(InputVerb.UNKNOWN)

	assert_bool(table.direction_for(kbm, water, "key.space") == Vector3.UP
		).override_failure_message("SPACE must steer upward in water").is_true()
	assert_bool(table.direction_for(kbm, land, "key.space") == Vector3.ZERO
		).is_true()

	# And WASD steers in both, through two different bindings.
	assert_bool(table.direction_for(kbm, water, "key.w") == Vector3.FORWARD
		).is_true()
	assert_bool(table.direction_for(kbm, land, "key.w") == Vector3.FORWARD
		).is_true()


func test_req_024_the_shipped_defaults_hold_no_conflicts() -> void:
	var errors: Array[InputError] = []
	var table := BindingTable.load_from_file(DEFAULTS, errors)
	assert_array(errors).override_failure_message(
		"a shipped default that conflicts with itself would ship a dead verb"
	).is_empty()
	# 11 verbs on each of two devices.
	assert_int(table.size()).is_equal(22)


func test_req_024_sharing_an_input_inside_one_context_is_refused() -> void:
	# The anti-vacuity control for the sharing above: contexts make W/E/SPACE
	# legal across grammars, and must NOT make everything legal.
	var table := _table()
	var errors: Array[InputError] = []

	var clashing := InputBinding.from_dictionary({
		"verb": "grapple", "context": "water",
		"device": "keyboard_mouse", "input": "key.e",
	}, errors)
	assert_object(clashing).is_not_null()

	assert_bool(table.add(clashing, errors)).override_failure_message(
		"REQ-024: two verbs sharing an input in the SAME context is a conflict"
	).is_false()
	assert_array(errors).is_not_empty()
	assert_str(errors[0].code).is_equal(InputError.BINDING_CONFLICT)
	assert_str(errors[0].detail).contains("bubble_boost")


func test_req_024_an_any_context_binding_conflicts_with_both_grammars() -> void:
	# ANY is the case that must NOT benefit from context scoping: a universal
	# verb is live in water and on land, so it genuinely cannot share.
	var table := _table()
	for context: String in ["water", "land"]:
		var errors: Array[InputError] = []
		var clashing := InputBinding.from_dictionary({
			"verb": "gill_mod_next", "context": context,
			"device": "keyboard_mouse", "input": "key.q",
		}, errors)
		assert_bool(table.add(clashing, errors)).override_failure_message(
			"a '%s' binding must still conflict with the ANY-context grapple"
			% context).is_false()
		assert_str(errors[errors.size() - 1].code).is_equal(
			InputError.BINDING_CONFLICT)


func test_req_024_held_direction_survives_a_grammar_change() -> void:
	var system := _system()
	system.set_grammar(MovementGrammar.Grammar.WATER)
	system.handle_event(_key(KEY_W, true))

	assert_bool(system.poll_intent().direction == Vector3.FORWARD
		).is_true()

	# Crossing the surface must not require re-pressing: the key stays held and
	# resolves through the land binding instead.
	system.set_grammar(MovementGrammar.Grammar.LAND)
	assert_bool(system.poll_intent().direction == Vector3.FORWARD
		).override_failure_message(
			"REQ-024 AC-2: a held direction must carry across the grammar seam"
		).is_true()


# --- AC-3: remappable, and persisted ----------------------------------------

func test_req_024_a_binding_is_remappable() -> void:
	var table := _table()
	var kbm := InputDevice.Kind.KEYBOARD_MOUSE
	var water := MovementGrammar.Grammar.WATER
	var errors: Array[InputError] = []

	assert_bool(table.rebind(InputVerb.Verb.DIVE, kbm, "key.z", errors)
		).override_failure_message("REQ-024 AC-3: every binding is remappable"
		).is_true()
	assert_array(errors).is_empty()

	assert_str(table.binding_for(InputVerb.Verb.DIVE, kbm).input).is_equal("key.z")
	assert_int(table.resolve_press(kbm, water, "key.z")).is_equal(
		InputVerb.Verb.DIVE)
	assert_int(table.resolve_press(kbm, water, "key.c")).override_failure_message(
		"the old input must stop working, or the remap only added a binding"
	).is_equal(InputVerb.UNKNOWN)


func test_req_024_a_direction_component_is_remappable() -> void:
	var table := _table()
	var kbm := InputDevice.Kind.KEYBOARD_MOUSE
	var water := MovementGrammar.Grammar.WATER
	var errors: Array[InputError] = []

	assert_bool(table.rebind_direction(InputVerb.Verb.SWIM, kbm, "up",
		"key.z", errors)).is_true()
	assert_array(errors).is_empty()
	assert_bool(table.direction_for(kbm, water, "key.z") == Vector3.UP).is_true()
	assert_bool(table.direction_for(kbm, water, "key.space") == Vector3.ZERO
		).is_true()


func test_req_024_remapped_bindings_persist_through_the_real_save_system() -> void:
	# Integration tier: the real SaveSystem, through the SettingsStore port,
	# written to a real file and reopened — not a double (REQ-026 AC-3).
	var system := _system()
	var errors: Array[InputError] = []
	assert_bool(system.get_bindings().rebind(InputVerb.Verb.DIVE,
		InputDevice.Kind.KEYBOARD_MOUSE, "key.z", errors)).is_true()

	var store := SaveSystem.new()
	system.save_bindings(store)
	var path := _path("profile")
	store.save_to_file(path)

	var reopened := SaveSystem.new()
	reopened.load_from_file(path, [] as Array[SaveError])

	# A fresh session: defaults in hand, then the profile applied over them.
	var restored := _system()
	assert_str(restored.get_bindings().binding_for(InputVerb.Verb.DIVE,
		InputDevice.Kind.KEYBOARD_MOUSE).input).is_equal("key.c")

	assert_bool(restored.load_bindings(reopened, errors)).override_failure_message(
		"REQ-024 AC-3: a remap must survive the session that made it").is_true()
	assert_str(restored.get_bindings().binding_for(InputVerb.Verb.DIVE,
		InputDevice.Kind.KEYBOARD_MOUSE).input).is_equal("key.z")

	# And the whole scheme came back, not just the verb that changed.
	assert_bool(restored.get_bindings().is_complete(
		InputDevice.Kind.GAMEPAD)).is_true()


func test_req_024_a_new_profile_keeps_the_default_scheme() -> void:
	var system := _system()
	var errors: Array[InputError] = []
	# An untouched store holds no input section.
	assert_bool(system.load_bindings(SaveSystem.new(), errors)).is_false()
	assert_bool(system.get_bindings().is_complete(
		InputDevice.Kind.KEYBOARD_MOUSE)).override_failure_message(
			"a new player must get the default scheme, never no scheme").is_true()


# --- AC-4: conflicts are rejected, not silently applied ---------------------

func test_req_024_rebinding_onto_a_taken_input_is_refused() -> void:
	var table := _table()
	var kbm := InputDevice.Kind.KEYBOARD_MOUSE
	var errors: Array[InputError] = []

	# E is bubble boost, in water. Dive is also water, so this must be refused.
	assert_bool(table.rebind(InputVerb.Verb.DIVE, kbm, "key.e", errors)
		).override_failure_message(
			"REQ-024 AC-4: a conflicting assignment must be rejected").is_false()

	assert_array(errors).is_not_empty()
	assert_str(errors[0].code).is_equal(InputError.BINDING_CONFLICT)
	assert_str(errors[0].verb_id).is_equal("dive")
	assert_str(errors[0].detail).override_failure_message(
		"'that key is taken' is unactionable without naming what took it"
	).contains("bubble_boost")

	# "Rather than silently overriding it": BOTH bindings must be untouched.
	assert_str(table.binding_for(InputVerb.Verb.DIVE, kbm).input).is_equal("key.c")
	assert_str(table.binding_for(InputVerb.Verb.BUBBLE_BOOST, kbm).input
		).is_equal("key.e")


func test_req_024_rebinding_across_contexts_is_allowed() -> void:
	# The conflict check is context-scoped, so the same rebind that is refused
	# above is permitted when the contexts cannot both be live.
	var table := _table()
	var kbm := InputDevice.Kind.KEYBOARD_MOUSE
	var errors: Array[InputError] = []

	# C is dive, in WATER. Hop is LAND, so it may take C.
	assert_bool(table.rebind(InputVerb.Verb.HOP, kbm, "key.c", errors)
		).override_failure_message(
			"REQ-024 AC-2: a context-scoped conflict check must permit this"
		).is_true()
	assert_array(errors).is_empty()

	assert_int(table.resolve_press(kbm, MovementGrammar.Grammar.LAND, "key.c")
		).is_equal(InputVerb.Verb.HOP)
	assert_int(table.resolve_press(kbm, MovementGrammar.Grammar.WATER, "key.c")
		).is_equal(InputVerb.Verb.DIVE)


func test_req_024_a_directional_verb_cannot_bind_one_key_twice() -> void:
	var table := _table()
	var errors: Array[InputError] = []
	# W already drives swim-forward; binding it to up as well would leave the
	# player unable to steer the two apart.
	assert_bool(table.rebind_direction(InputVerb.Verb.SWIM,
		InputDevice.Kind.KEYBOARD_MOUSE, "up", "key.w", errors)).is_false()
	assert_str(errors[0].code).is_equal(InputError.BINDING_CONFLICT)
	assert_str(table.binding_for(InputVerb.Verb.SWIM,
		InputDevice.Kind.KEYBOARD_MOUSE).directions["up"]).is_equal("key.space")


func test_req_024_a_rejected_rebind_names_a_rule_rather_than_failing_silently() -> void:
	var table := _table()
	var errors: Array[InputError] = []
	assert_bool(table.rebind(InputVerb.Verb.DIVE,
		InputDevice.Kind.KEYBOARD_MOUSE, "", errors)).is_false()
	assert_str(errors[0].code).is_equal(InputError.NO_PHYSICAL_INPUT)

	# A directional verb refuses the press-verb remap path rather than
	# half-applying it.
	errors.clear()
	assert_bool(table.rebind(InputVerb.Verb.SWIM,
		InputDevice.Kind.KEYBOARD_MOUSE, "key.z", errors)).is_false()
	assert_str(errors[0].code).is_equal(InputError.MALFORMED_BINDING)


# --- AC-5: device switching mid-session -------------------------------------

func test_req_024_device_switches_mid_session_and_prompts_follow() -> void:
	var system := _system()
	var announced: Array[String] = []
	system.device_changed.connect(
		func(_id: String, prompts: String) -> void: announced.append(prompts))

	assert_str(system.active_prompt_set()).is_equal("prompts.keyboard_mouse")

	# A gamepad press, with no restart and no reconfiguration.
	system.handle_event(_pad_button(3, true))
	assert_int(system.get_device()).is_equal(InputDevice.Kind.GAMEPAD)
	assert_str(system.active_prompt_set()).override_failure_message(
		"REQ-024 AC-5: on-screen prompts must follow the active device"
	).is_equal("prompts.gamepad")

	# And back again.
	system.handle_event(_key(KEY_Q, true))
	assert_int(system.get_device()).is_equal(InputDevice.Kind.KEYBOARD_MOUSE)

	assert_array(announced).is_equal(
		["prompts.gamepad", "prompts.keyboard_mouse"] as Array[String])


func test_req_024_switching_device_drops_the_other_devices_held_inputs() -> void:
	var system := _system()
	system.handle_event(_key(KEY_W, true))
	assert_bool(system.is_held("key.w")).is_true()

	# No keyboard release event is ever coming for a key held while the player
	# picks up a pad, so the held set must be dropped at the switch.
	system.handle_event(_pad_button(3, true))
	assert_bool(system.is_held("key.w")).override_failure_message(
		"a key held at the device switch would steer the axolotl forever"
	).is_false()
	assert_bool(system.poll_intent().direction == Vector3.ZERO).is_true()


func test_req_024_mouse_motion_does_not_flip_the_prompt_set() -> void:
	var system := _system()
	system.handle_event(_pad_button(3, true))
	assert_int(system.get_device()).is_equal(InputDevice.Kind.GAMEPAD)

	# A nudged mouse on the desk is not a decision to play on keyboard.
	assert_bool(system.handle_event(InputEventMouseMotion.new())).is_false()
	assert_int(system.get_device()).override_failure_message(
		"mouse MOTION must not switch the scheme; a mouse BUTTON must"
	).is_equal(InputDevice.Kind.GAMEPAD)

	assert_bool(system.handle_event(_mouse(MOUSE_BUTTON_RIGHT, true))).is_true()
	assert_int(system.get_device()).is_equal(InputDevice.Kind.KEYBOARD_MOUSE)


# --- AC-6: nothing else reads raw input -------------------------------------

func _files_under(root: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := root.path_join(entry)
		if dir.current_is_dir():
			_files_under(path, out)
		elif entry.ends_with(".gd"):
			out.append(path)
		entry = dir.get_next()
	dir.list_dir_end()


## The raw-input singleton access this criterion forbids. `Input.` with the dot
## is the whole point: InputEvent, InputBinding and this node's own class names
## all begin with the same letters and are not the thing being banned.
const RAW_INPUT_MARKERS: PackedStringArray = [
	"Input.is_action_pressed", "Input.is_action_just_pressed",
	"Input.get_vector", "Input.get_axis", "Input.is_key_pressed",
	"Input.get_connected_joypads",
]


func _reads_raw_input(text: String) -> bool:
	for marker: String in RAW_INPUT_MARKERS:
		if text.contains(marker):
			return true
	return false


func test_req_024_no_system_outside_this_node_reads_raw_input() -> void:
	var sources := PackedStringArray()
	_files_under("res://core", sources)
	# worlds/ does not exist yet; when it does it is covered by the same sweep.
	_files_under("res://worlds", sources)

	assert_int(sources.size()).override_failure_message(
		"the sweep found no source files, so it would pass vacuously"
	).is_greater_equal(30)

	var offenders: Array[String] = []
	for path: String in sources:
		if _reads_raw_input(_read(path)):
			offenders.append(path)

	assert_array(offenders).override_failure_message(
		"REQ-024 AC-6: these read raw input instead of consuming intent: %s"
		% ", ".join(offenders)).is_empty()


func test_req_024_the_raw_input_scan_bites() -> void:
	# The anti-vacuity control: a scan that never fires proves nothing. Prove it
	# catches the exact idiom a contributor following ordinary Godot guidance
	# would reach for.
	var fixture := "func _physics_process(_d: float) -> void:\n" \
		+ "\tif Input.is_action_pressed(\"ui_up\"):\n\t\tpass\n"
	assert_bool(_reads_raw_input(fixture)).override_failure_message(
		"the AC-6 scan must catch a world reading input directly").is_true()
	assert_bool(_reads_raw_input("var intent := PlayerIntent.none()")).is_false()


func test_req_024_the_controller_consumes_intent_not_input() -> void:
	# The other half of AC-6: worlds have somewhere else to read from. The
	# controller's frame entry point takes PlayerIntent, which is what this node
	# produces, so the indirection is real rather than merely documented.
	var intent := _system().poll_intent()
	assert_object(intent).is_not_null()

	var found := false
	for method: Dictionary in AxolotlController.new(
			TuningData.load_from_file("res://core/tuning/tuning.json",
				[] as Array[TuningError])).get_method_list():
		if String(method["name"]) == "physics_step":
			found = true
	assert_bool(found).override_failure_message(
		"the controller must expose an intent-consuming frame entry point"
	).is_true()


# --- The frame: held versus edge --------------------------------------------

func test_req_024_an_edge_verb_fires_once_per_press() -> void:
	var system := _system()
	system.set_grammar(MovementGrammar.Grammar.LAND)

	system.handle_event(_key(KEY_SPACE, true))
	assert_array(system.poll_intent().verbs).contains(
		[MovementGrammar.Verb.HOP])

	# Still held, but the press was consumed. A second frame is not a second hop.
	assert_array(system.poll_intent().verbs).override_failure_message(
		"REQ-024: an edge verb must not repeat while the key stays down"
	).is_empty()


func test_req_024_key_repeat_is_not_a_new_press() -> void:
	var system := _system()
	system.set_grammar(MovementGrammar.Grammar.LAND)

	system.handle_event(_key(KEY_SPACE, true))
	assert_array(system.poll_intent().verbs).has_size(1)

	# The OS repeat that arrives while a key is held down.
	assert_bool(system.handle_event(_key(KEY_SPACE, true, true))).is_false()
	assert_array(system.poll_intent().verbs).override_failure_message(
		"holding SPACE would machine-gun hops if echo counted as a press"
	).is_empty()


func test_req_024_a_stick_returned_to_centre_releases_its_direction() -> void:
	var system := _system()
	system.handle_event(_pad_axis(1, -1.0))
	assert_bool(system.is_held("pad.axis.1.-")).is_true()

	# A centred stick reports 0.0, whose sign reads as '+'. Releasing only the id
	# the event carries would leave the '-' side held forever.
	system.handle_event(_pad_axis(1, 0.0))
	assert_bool(system.is_held("pad.axis.1.-")).override_failure_message(
		"a centred stick must release the direction it was pushed in").is_false()
	assert_bool(system.poll_intent().direction == Vector3.ZERO).is_true()


func test_req_024_pushing_a_stick_the_other_way_releases_the_first() -> void:
	var system := _system()
	system.handle_event(_pad_axis(0, -1.0))
	system.handle_event(_pad_axis(0, 1.0))

	assert_bool(system.is_held("pad.axis.0.-")).override_failure_message(
		"one stick cannot be pushed both ways at once").is_false()
	assert_bool(system.poll_intent().direction == Vector3.RIGHT).is_true()


func test_req_024_a_diagonal_is_not_faster_than_a_straight_line() -> void:
	var system := _system()
	system.handle_event(_key(KEY_W, true))
	system.handle_event(_key(KEY_D, true))

	var direction := system.poll_intent().direction
	assert_float(direction.length()).override_failure_message(
		"a keyboard diagonal must not out-run a stick at full deflection"
	).is_equal_approx(1.0, 0.0001)


func test_req_024_a_held_vertical_does_not_push_into_the_ground_on_land() -> void:
	var system := _system()
	system.handle_event(_key(KEY_W, true))
	system.handle_event(_key(KEY_SPACE, true))
	assert_float(system.poll_intent().direction.y).is_greater(0.0)

	system.set_grammar(MovementGrammar.Grammar.LAND)
	var landed := system.poll_intent().direction
	assert_float(landed.y).override_failure_message(
		"the land grammar is planar; a carried swim-up would burrow"
	).is_equal_approx(0.0, 0.0001)
	assert_float(landed.length()).is_equal_approx(1.0, 0.0001)


func test_req_024_ability_verbs_never_reach_the_controller() -> void:
	var system := _system()
	var requested: Array[String] = []
	system.ability_verb_requested.connect(
		func(verb: String) -> void: requested.append(verb))

	system.handle_event(_mouse(MOUSE_BUTTON_LEFT, true))
	system.handle_event(_key(KEY_TAB, true))

	assert_array(requested).is_equal(
		["gill_mod_activate", "gill_mod_next"] as Array[String])
	assert_array(system.poll_intent().verbs).override_failure_message(
		"a Gill Mod verb is not a movement verb and must not reach the controller"
	).is_empty()


func test_req_024_clear_drops_held_state_for_a_respawn() -> void:
	var system := _system()
	system.handle_event(_key(KEY_W, true))
	system.set_grammar(MovementGrammar.Grammar.LAND)
	system.handle_event(_key(KEY_SPACE, true))

	system.clear()
	var intent := system.poll_intent()
	assert_bool(intent.direction == Vector3.ZERO).is_true()
	assert_array(intent.verbs).override_failure_message(
		"a key held through a respawn would move the player on the frame they "
		+ "regain control").is_empty()


# --- Declaration validation --------------------------------------------------

func test_req_024_a_malformed_binding_is_refused_with_a_named_error() -> void:
	var cases: Array[Dictionary] = [
		{"source": {"verb": "flap", "context": "water",
			"device": "keyboard_mouse", "input": "key.z"},
			"code": InputError.UNKNOWN_VERB},
		{"source": {"verb": "dive", "context": "lava",
			"device": "keyboard_mouse", "input": "key.z"},
			"code": InputError.UNKNOWN_CONTEXT},
		{"source": {"verb": "dive", "context": "water",
			"device": "steering_wheel", "input": "key.z"},
			"code": InputError.UNKNOWN_DEVICE},
		{"source": {"verb": "dive", "context": "water",
			"device": "keyboard_mouse"},
			"code": InputError.NO_PHYSICAL_INPUT},
		{"source": {"verb": "swim", "context": "water",
			"device": "keyboard_mouse", "input": "key.z"},
			"code": InputError.MALFORMED_BINDING},
		{"source": {"verb": "swim", "context": "water",
			"device": "keyboard_mouse", "directions": {"forward": "key.w"}},
			"code": InputError.INCOMPLETE_DIRECTIONS},
	]

	for row: Dictionary in cases:
		var errors: Array[InputError] = []
		var binding := InputBinding.from_dictionary(
			row["source"] as Dictionary, errors)
		assert_object(binding).override_failure_message(
			"expected %s to be refused" % row["code"]).is_null()
		assert_str(errors[0].code).is_equal(String(row["code"]))


func test_req_024_one_bad_binding_does_not_cost_the_whole_scheme() -> void:
	var errors: Array[InputError] = []
	var table := BindingTable.from_dictionary({"bindings": [
		{"verb": "flap", "context": "water", "device": "keyboard_mouse",
			"input": "key.z"},
		{"verb": "dive", "context": "water", "device": "keyboard_mouse",
			"input": "key.c"},
	]}, errors)

	assert_int(table.size()).override_failure_message(
		"a hand-edited file with one bad line must not cost every binding"
	).is_equal(1)
	assert_str(errors[0].code).is_equal(InputError.UNKNOWN_VERB)


func test_req_024_a_round_trip_through_the_save_shape_is_lossless() -> void:
	var table := _table()
	var errors: Array[InputError] = []
	var restored := BindingTable.from_dictionary(table.to_dictionary(), errors)

	assert_array(errors).is_empty()
	assert_int(restored.size()).is_equal(table.size())
	for device: InputDevice.Kind in InputDevice.all():
		assert_bool(restored.is_complete(device)).is_true()
	assert_str(restored.binding_for(InputVerb.Verb.SWIM,
		InputDevice.Kind.GAMEPAD).directions["up"]).is_equal("pad.axis.5.+")


# --- REQ-025: no balance constants live here --------------------------------

func test_req_025_the_input_node_declares_no_balance_constants() -> void:
	# The deadzone is an input-hardware threshold, not balance, so it stays here.
	# What must NOT appear is a speed, duration or cooldown — those belong to the
	# tuning surface, and a copy here would silently win over a retune.
	for path: String in INPUT_SOURCES:
		var text := _read(path)
		for banned: String in ["_SPEED", "_DURATION", "_COOLDOWN", "_METERS"]:
			assert_bool(text.contains(banned)).override_failure_message(
				"REQ-025: '%s' declares '%s'; balance lives in tuning.json"
				% [path, banned]).is_false()


# --- REQ-030: no multiplayer surface in this node ---------------------------

func test_req_030_input_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in INPUT_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden symbol '%s'" % [path, symbol]
			).is_false()
