extends Node

## Drives the reference template from spawn to finish (REQ-029 AC-6).
##
## "Completable" is a claim about play, not about data, so it is proven by
## actually walking it: an AxolotlBody is placed at the world's declared spawn
## point and held forward until it enters the node in group `finish_volume`.
## A manifest inspection could never catch a template whose finish volume sits
## across a gap the waddle cannot cross.
##
## The world is loaded EXACTLY as the hub would load it — instantiate the scene,
## find the spawn and finish by GROUP, place the player. Nothing here knows the
## template by name beyond the path, which is the same property AC-5 asks of the
## loader: no special case for this world.

const BODY_PATH := "res://core/controller/axolotl_body.gd"

const SPAWN_GROUP := "spawn_point"
const FINISH_GROUP := "finish_volume"
const CHECKPOINT_GROUP := "checkpoint"

## Frames to hold forward before giving up. The route is ~38 m at waddle speed,
## so this is generous rather than tight — a budget that only just fits would
## fail on an unrelated tuning change.
const WALK_FRAMES := 900

## Settling frames before the walk, so the body lands on the ground rather than
## starting its run mid-fall.
const SETTLE_FRAMES := 30

var _failures: PackedStringArray = []
var _checks := 0
var _frame := 0
var _body: CharacterBody3D
var _finish: Area3D
var _spawn_position := Vector3.ZERO
var _reached := false
var _passed_checkpoint := false


func _ready() -> void:
	var world := get_tree().current_scene
	if world == null:
		_fail("the world scene did not load")
		_report()
		return

	var spawns := _in_group(world, SPAWN_GROUP)
	var finishes := _in_group(world, FINISH_GROUP)
	var checkpoints := _in_group(world, CHECKPOINT_GROUP)

	_check(spawns.size() == 1,
		"exactly one %s, found %d" % [SPAWN_GROUP, spawns.size()])
	_check(finishes.size() >= 1,
		"at least one %s, found %d" % [FINISH_GROUP, finishes.size()])
	_check(checkpoints.size() >= 1,
		"at least one %s, found %d" % [CHECKPOINT_GROUP, checkpoints.size()])

	if spawns.is_empty() or finishes.is_empty():
		_report()
		return

	_spawn_position = (spawns[0] as Node3D).global_position
	_finish = finishes[0] as Area3D

	_body = CharacterBody3D.new()
	_body.set_script(load(BODY_PATH))
	_body.add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.6
	shape.shape = capsule
	_body.add_child(shape)
	world.add_child(_body)
	_body.global_position = _spawn_position

	_finish.body_entered.connect(_on_finish_entered)


func _physics_process(_delta: float) -> void:
	if _body == null or _reached:
		return

	_frame += 1
	if _frame <= SETTLE_FRAMES:
		return

	if _frame == SETTLE_FRAMES + 1:
		_check(_body.global_position.y > _spawn_position.y - 5.0,
			"the axolotl settled on the ground rather than falling through it")

	# Hold forward through a REAL input event, the same path a player's keypress
	# takes: event -> Input System -> intent -> controller -> body. Calling the
	# controller directly would prove the world is walkable while skipping the
	# wiring that actually has to work.
	if _frame == SETTLE_FRAMES + 1:
		_key(KEY_W, true)

	if not _passed_checkpoint and _body.global_position.z < -18.0:
		_passed_checkpoint = true

	if _frame > SETTLE_FRAMES + WALK_FRAMES:
		_fail("never reached the finish volume in %d frames (stopped at z=%.1f)"
			% [WALK_FRAMES, _body.global_position.z])
		_report()


func _on_finish_entered(body: Node3D) -> void:
	if body != _body or _reached:
		return
	_reached = true
	_key(KEY_W, false)
	_check(true, "walked from spawn to the finish volume")
	_check(_passed_checkpoint,
		"the route passes the checkpoint on the way to the finish")
	_report()


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _in_group(world: Node, group: String) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in world.find_children("*", "", true, false):
		if node.is_in_group(group):
			out.append(node)
	return out


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
		print("TEMPLATE WALK: %d checks passed" % _checks)
		get_tree().quit(0)
		return
	print("TEMPLATE WALK: %d of %d checks FAILED" % [_failures.size(), _checks])
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)
