class_name Checkpoint
extends RefCounted

## One checkpoint, as queryable DATA (REQ-003 AC-5, AC-7).
##
## Deliberately a value object rather than a scene node. AC-7 bounds the replay
## time between consecutive checkpoints, and a criterion phrased as a number can
## only be checked by walking a list — a headless test cannot walk a scene tree
## looking for Area3Ds, and a designer eyeballing a level is not a check. So a
## world declares its checkpoints as data the compliance test can read, and the
## scene nodes reference these rather than being them.

## Stable id, unique within a world. Used as the respawn anchor recorded in the
## save and as the key AC-7's report names when a segment is too long.
var id: String = ""

## Where the axolotl reappears. Recorded on activation (AC-5).
var position: Vector3 = Vector3.ZERO

## Seconds of play to get here from the PREVIOUS checkpoint — or from the world
## spawn, for the first one.
##
## Declared by the world rather than measured, because it bounds the replay a
## player faces after losing all lives, and that has to be knowable at build time
## for CI to enforce it. A world that lies here fails its own playthrough test.
var replay_seconds_from_previous: float = 0.0


func _init(p_id: String = "", p_position: Vector3 = Vector3.ZERO,
		p_replay_seconds_from_previous: float = 0.0) -> void:
	id = p_id
	position = p_position
	replay_seconds_from_previous = p_replay_seconds_from_previous


## A checkpoint with no id could never be recorded as a respawn anchor or named
## in a spacing report, and a negative replay time is a declaration error.
func is_valid() -> bool:
	return not id.is_empty() and replay_seconds_from_previous >= 0.0
