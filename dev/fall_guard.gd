extends Node

## Puts the axolotl back when it leaves the level. DEVELOPMENT ONLY.
##
## This is NOT the lives system. Falling out of the world is a catastrophic
## event that costs a life and returns the player to the last checkpoint —
## REQ-003 owns that, via pit volumes and CatastrophicSource.PIT_VOLUME, and the
## logic already exists and is tested. What does not exist yet is a world with
## checkpoints in it for that system to return anyone to.
##
## So this is scaffolding with a deliberately short life: it exists so a person
## testing the greybox by hand does not have to restart the game every time they
## walk off the edge. It is replaced, not extended, the moment the reference
## template (REQ-029) gives us a world with real checkpoints.
##
## Kept in dev/ and out of core/ precisely so it cannot quietly become the real
## answer. A respawn that costs nothing is the opposite of what Pillar 1 wants.

@export var target_path: NodePath
@export var floor_y: float = -40.0

var _target: Node3D
var _spawn: Vector3


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		push_error("[dev.fall_guard] no target; set target_path to the axolotl")
		set_physics_process(false)
		return
	_spawn = _target.global_position


func _physics_process(_delta: float) -> void:
	if _target.global_position.y >= floor_y:
		return

	_target.global_position = _spawn
	var body := _target as AxolotlBody
	if body != null:
		body.velocity = Vector3.ZERO
		# Held keys and pending presses go with the fall: arriving back at spawn
		# already moving is how a respawn immediately becomes a second fall.
		body.get_input_system().clear()
		body.get_controller().set_velocity(Vector3.ZERO)
	print("[dev.fall_guard] returned the axolotl to spawn")
