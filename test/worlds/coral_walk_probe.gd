extends Node

## Drives Coral Cove from spawn to finish (REQ-011 AC-2/AC-4/AC-5).
##
## Unlike the hub walk — which deliberately names no world — this probe IS
## about one world: it enters coral_cove by id and proves the world's own
## claims. One held forward key carries the whole route, because the world was
## designed for exactly that: completability is a regression test, not a hope.
##
## What one traversal proves, because the route makes each of these MANDATORY:
##   * both movement grammars ran (the lagoon spans the route — AC-4),
##   * the glow and bubble gates opened, which can only happen by equipping
##     those mods (AC-5's per-world half),
##   * region coral_shelf reached `restored`, which is the only thing that
##     opens the shelf wall in front of the finish (AC-4's region half),
##   * the finish condition returned the player to the hub (AC-2).

const WORLD_ID := "coral_cove"
const SETTLE_FRAMES := 30
const JOURNEY_FRAMES := 4200

var _failures: PackedStringArray = []
var _checks := 0
var _frame := 0

var _hub: OpenLagoon
var _save := SaveSystem.new()
var _body: CharacterBody3D
var _hub_spawn := Vector3.ZERO

var _entered := false
var _completed_id := ""
var _returned := false
var _grammars_seen: Dictionary = {}
var _mods_equipped: PackedStringArray = []
var _gates_opened: PackedStringArray = []
var _region_restored := false


func _ready() -> void:
	var scene := get_tree().current_scene
	_hub = scene as OpenLagoon
	if _hub == null and scene != null:
		for node: Node in scene.find_children("*", "", true, false):
			if node is OpenLagoon:
				_hub = node as OpenLagoon
				break
	if _hub == null:
		_fail("the hub scene did not load an OpenLagoon node")
		_report()
		return

	_hub.set_save_system(_save)

	var portal := _hub.get_registry().get_portal(WORLD_ID)
	_check(portal != null and portal.available,
		"the hub discovered coral_cove as an available portal")
	if portal == null or not portal.available:
		_report()
		return

	_body = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_check(_body != null, "the hub scene ships a player body")
	if _body == null:
		_report()
		return
	if _body.has_signal("grammar_changed"):
		_body.connect("grammar_changed",
			func(grammar: MovementGrammar.Grammar) -> void:
				_grammars_seen[grammar] = true)

	_hub.world_completed.connect(func(world_id: String) -> void:
		_completed_id = world_id)
	_hub.returned_to_hub.connect(func(_world_id: String) -> void:
		_returned = true
		_key(KEY_W, false))

	var spawn := get_tree().get_first_node_in_group("hub_spawn")
	_hub_spawn = (spawn as Node3D).global_position if spawn is Node3D \
		else Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if _body == null or not _body.is_inside_tree():
		return

	_frame += 1
	if _frame == SETTLE_FRAMES:
		# Enter by id — this probe tests the world, not portal geometry.
		_entered = _hub.enter_world(WORLD_ID)
		_check(_entered, "enter_world(coral_cove) succeeded")
		if not _entered:
			_report()
		return

	if _frame == SETTLE_FRAMES + 2:
		_wire_world_systems()
		_key(KEY_W, true)
		return

	if _returned:
		if _frame < SETTLE_FRAMES + 8:
			return
		_finish_checks()
		return

	if _frame > SETTLE_FRAMES + JOURNEY_FRAMES:
		_fail("the walk never completed (z=%.1f, grammars=%s, mods=%s, "
			% [_body.global_position.z, str(_grammars_seen.keys()),
				str(_mods_equipped)]
			+ "gates=%s, restored=%s)"
			% [str(_gates_opened), str(_region_restored)])
		_report()


func _wire_world_systems() -> void:
	var systems := get_tree().get_first_node_in_group("world_systems") \
		as WorldSystems
	_check(systems != null, "the hub attached a WorldSystems runtime")
	if systems == null:
		return
	systems.mod_equipped.connect(func(mod_id: String) -> void:
		if not _mods_equipped.has(mod_id):
			_mods_equipped.append(mod_id))
	systems.gate_changed.connect(
		func(kind: String, ref: String, open: bool) -> void:
			var tag := "%s:%s" % [kind, ref]
			if open and not _gates_opened.has(tag):
				_gates_opened.append(tag))
	systems.get_restoration().region_state_changed.connect(
		func(_region: String, _from: RegionState.State,
				to: RegionState.State) -> void:
			if to == RegionState.State.RESTORED:
				_region_restored = true)


func _finish_checks() -> void:
	_check(_completed_id == WORLD_ID,
		"the completed world is coral_cove (got '%s')" % _completed_id)
	_check(_grammars_seen.has(MovementGrammar.Grammar.WATER)
		and _grammars_seen.has(MovementGrammar.Grammar.LAND),
		"both movement grammars ran on the route (saw %s)"
		% str(_grammars_seen.keys()))
	_check(_mods_equipped.has("glow") and _mods_equipped.has("bubble"),
		"the route equipped both Glow and Bubble (got %s)"
		% str(_mods_equipped))
	_check(_gates_opened.has("affordance:reveal_bioluminescent")
		and _gates_opened.has("affordance:bubble_platform"),
		"both mod-gated barriers opened (got %s)" % str(_gates_opened))
	_check(_gates_opened.has("restoration:shelf_wall"),
		"restoring coral_shelf opened the shelf wall")
	_check(_region_restored, "region coral_shelf reached restored")
	_check(_returned, "the finish condition returned control to the hub")
	_check(_body.global_position.distance_to(_hub_spawn) < 6.0,
		"the player is back at the hub spawn (%.1f m away)"
		% _body.global_position.distance_to(_hub_spawn))

	# The completion is visible through the save-integration interface.
	var portal := _hub.get_registry().get_portal(WORLD_ID)
	_check(portal != null and portal.completed,
		"the coral_cove portal now shows completed")

	_report()


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _fail(description: String) -> void:
	_checks += 1
	_failures.append(description)


func _report() -> void:
	print("==================================================================")
	if _failures.is_empty():
		print("CORAL WALK: %d checks passed" % _checks)
		get_tree().quit(0)
		return
	print("CORAL WALK: %d of %d checks FAILED" % [_failures.size(), _checks])
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)
