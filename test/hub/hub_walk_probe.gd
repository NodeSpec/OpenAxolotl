extends Node

## Drives the full Open Lagoon loop (REQ-009 AC-2): spawn in the hub, walk
## into a portal, arrive at the world's spawn point, complete its finish
## condition, and come back to the hub.
##
## The whole journey is made with ONE held key. The player walks forward into
## the pedestal's entry volume, is placed at the world's spawn (the template's
## route also runs forward), walks to the finish volume, and is returned. No
## teleports are scripted by the probe — every relocation is the hub's doing,
## which is the thing under test.
##
## Nothing here names a world. The probe enters whichever available portal the
## registry discovered first, so the harness works identically on a fork with
## different worlds installed — the same no-hardcoded-list property the hub
## itself is held to.

const SETTLE_FRAMES := 30
const JOURNEY_FRAMES := 2400

var _failures: PackedStringArray = []
var _checks := 0
var _frame := 0

var _hub: OpenLagoon
var _save := SaveSystem.new()
var _body: CharacterBody3D
var _hub_spawn := Vector3.ZERO

var _entered_id := ""
var _completed_id := ""
var _returned := false
var _position_in_world := Vector3.ZERO


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

	var available := _hub.get_registry().get_available()
	_check(available.size() >= 1,
		"the hub discovered at least one available world")
	if available.is_empty():
		_report()
		return

	_hub.world_entered.connect(func(world_id: String) -> void:
		_entered_id = world_id
		_position_in_world = _body.global_position)
	_hub.world_completed.connect(func(world_id: String) -> void:
		_completed_id = world_id)
	_hub.returned_to_hub.connect(func(_world_id: String) -> void:
		_returned = true
		_key(KEY_W, false))

	var spawn := get_tree().get_first_node_in_group("hub_spawn")
	_hub_spawn = (spawn as Node3D).global_position if spawn is Node3D \
		else Vector3.ZERO

	# The scene ships its own player; the probe drives that one rather than
	# adding a second body two systems would then disagree about.
	_body = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_check(_body != null, "the hub scene ships a player body")
	if _body == null:
		_report()


func _physics_process(_delta: float) -> void:
	if _body == null or not _body.is_inside_tree():
		return

	_frame += 1
	if _frame == SETTLE_FRAMES:
		_key(KEY_W, true)
		return

	if _returned and _frame > SETTLE_FRAMES:
		# Give the return a few frames to settle before judging positions.
		if _frame < SETTLE_FRAMES + 5:
			return
		_finish_checks()
		return

	if _frame > SETTLE_FRAMES + JOURNEY_FRAMES:
		_fail("the loop never completed (entered='%s' completed='%s' z=%.1f)"
			% [_entered_id, _completed_id, _body.global_position.z])
		_report()


func _finish_checks() -> void:
	_check(not _entered_id.is_empty(),
		"walking into the pedestal entered its world")
	_check(_entered_id == _completed_id,
		"the world entered is the world completed")
	_check(_position_in_world.distance_to(Vector3.ZERO) > 100.0,
		"on entry the player stood at the world's spawn, away from the hub")
	_check(_returned, "completion returned control to the hub")
	_check(_body.global_position.distance_to(_hub_spawn) < 6.0,
		"the player is back at the hub spawn (%.1f m away)"
		% _body.global_position.distance_to(_hub_spawn))
	_check(_hub.visible and not _hub.is_in_world(),
		"the hub is visible and idle again")

	# AC-6, end to end: the completion the loop just earned is visible on the
	# portal, read back through the save-integration interface.
	var portal := _hub.get_registry().get_portal(_completed_id)
	_check(portal != null and portal.completed,
		"the portal now shows the world completed")

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
		print("HUB WALK: %d checks passed" % _checks)
		get_tree().quit(0)
		return
	print("HUB WALK: %d of %d checks FAILED" % [_failures.size(), _checks])
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)
