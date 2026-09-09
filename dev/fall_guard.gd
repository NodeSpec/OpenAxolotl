extends Node

## Puts the axolotl back when it leaves the greybox. DEVELOPMENT ONLY.
##
## ITS ORIGINAL JOB IS DONE AND THIS IS WHAT IS LEFT. It was written as
## scaffolding, to be "replaced, not extended, the moment the reference
## template gives us a world with real checkpoints", because falling out of a
## WORLD is a catastrophic event that costs a life and returns the player to a
## checkpoint — REQ-003, via pit volumes and CatastrophicSource.PIT_VOLUME.
##
## That moment came. Both official worlds now carry a pit volume sized as a
## floor under their whole playable area, so REQ-003 handles the fall there,
## and the hub — which owns no LifeSystem and so had nothing to charge — grew
## its own recovery in OpenLagoon._recover_fallen_player. Neither of those is
## this file, and this file is not used by either.
##
## What it still does is the one case those do not cover: dev/greybox.tscn is
## a bare proving ground with no checkpoints, no life system and no hub, and a
## person testing the controller by hand there should not have to restart the
## game every time they walk off the edge.
##
## Kept in dev/ and out of core/ precisely so it cannot quietly become the real
## answer. A respawn that costs nothing is the opposite of what Pillar 1 wants,
## and the greybox is the only place where nothing is what it should cost.

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
