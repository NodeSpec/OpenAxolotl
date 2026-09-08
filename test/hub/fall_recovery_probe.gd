extends Node

## Falling out of the hub has to end (REQ-009), proven by DOING it.
##
## WHY THIS IS A PROBE AND NOT A UNIT TEST. The bug it guards was invisible to
## unit tests, and that is the whole lesson: every system involved — lives,
## checkpoints, the catastrophic lane — was individually tested and correct,
## and the hub still had no floor under it. Measured in the shipped build, a
## player teleported off the lagoon fell 583 units in twenty seconds and was
## still accelerating, with no way back except quitting the game. Nothing
## failed, because nothing asked the running game a question.
##
## The property is about a scene and a physics loop, so it is checked in a
## scene with a physics loop. A direct call to the recovery function was tried
## first and made a worse test: it passed on a hub that had never ticked,
## which is exactly the state the real bug could not occur in.
##
## Both worlds already handle this, by a different and better mechanism: each
## carries a pit volume sized as a floor under its whole playable area, so a
## fall there costs a life and returns the player to their last checkpoint.
## That is REQ-003 doing its job and is covered by test_fall_recovery.gd. The
## hub owns no LifeSystem and nothing to be punished for, so it recovers
## instead — and this proves the recovery both fires and leaves the player at
## rest, since a body returned mid-fall keeps its velocity and is off the edge
## again within a second.

const SETTLE_FRAMES := 60
const OBSERVE_FRAMES := 420

## How far out to throw the player. Two hundred metres sideways is well beyond
## any geometry, so nothing catches them by accident and the fall being
## measured is a real one.
const THROW := Vector3(200.0, 6.0, 0.0)

## The velocity they carry into it. Non-zero on purpose: arriving back at
## spawn still moving is the failure mode that turns one fall into a loop.
const THROW_VELOCITY := Vector3(4.0, -30.0, 2.0)

var _hub: OpenLagoon
var _save := SaveSystem.new()
var _body: CharacterBody3D
var _frame := 0
var _dropped_from := Vector3.ZERO
var _lowest := INF
var _failures: PackedStringArray = []
var _checks := 0
var _reported := false


func _ready() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		for node: Node in scene.find_children("*", "", true, false):
			if node is OpenLagoon:
				_hub = node as OpenLagoon
				break
	if _hub == null:
		_fail("the hub scene did not load an OpenLagoon node")
		_report()
		return
	_hub.set_save_system(_save)
	_body = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_check(_body != null, "the hub ships a player body")
	if _body == null:
		_report()


func _physics_process(_delta: float) -> void:
	if _reported or _body == null:
		return
	_frame += 1

	if _frame == SETTLE_FRAMES:
		_dropped_from = _body.global_position + THROW
		_body.global_position = _dropped_from
		_body.velocity = THROW_VELOCITY
		return

	if _frame > SETTLE_FRAMES:
		_lowest = minf(_lowest, _body.global_position.y)

	if _frame >= SETTLE_FRAMES + OBSERVE_FRAMES:
		var landed := _body.global_position
		_check(landed.y > OpenLagoon.RECOVERY_FLOOR_Y,
			"a player thrown off the lagoon ended above the recovery floor "
			+ "(y %.2f, floor %.1f)" % [landed.y, OpenLagoon.RECOVERY_FLOOR_Y])
		_check(_lowest < _dropped_from.y,
			"the player actually fell before being recovered (lowest %.2f, "
			% _lowest + "dropped from %.2f)" % _dropped_from.y)
		_check(_body.velocity.is_zero_approx(),
			"the recovered player is at rest rather than still falling "
			+ "(velocity %v)" % _body.velocity)
		var spawn := get_tree().get_first_node_in_group("hub_spawn") as Node3D
		if spawn != null:
			_check(landed.distance_to(spawn.global_position) < 2.0,
				"the player was returned to the hub spawn (%.2f m away)"
				% landed.distance_to(spawn.global_position))
		_report()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	_reported = true
	for failure: String in _failures:
		print("FALL RECOVERY: FAILED — %s" % failure)
	if _failures.is_empty():
		print("FALL RECOVERY: %d checks passed (fell to %.2f, recovered to "
			% [_checks, _lowest] + "%.2f)" % _body.global_position.y)
	get_tree().quit(1 if not _failures.is_empty() else 0)
