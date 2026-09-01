class_name CheckpointGraph
extends RefCounted

## A world's checkpoints in play order, and the AC-7 spacing check over them.
##
## The Level Contract makes checkpoints REQUIRED rather than optional, which is
## the reason this can be a total check: every world has one of these, so the
## compliance test never has to special-case a world that declared none.
##
## The spacing check reports WHICH segments are too long rather than a bare
## boolean. A world author who fails CI needs to know which stretch to break up,
## and "checkpoint spacing failed" tells them nothing they can act on.

var world_id: String = ""

var _checkpoints: Array[Checkpoint] = []


func _init(p_world_id: String = "") -> void:
	world_id = p_world_id


## Appends in play order. Refuses an invalid checkpoint and a duplicate id: two
## checkpoints sharing an id would make the recorded respawn anchor ambiguous.
func add(checkpoint: Checkpoint) -> bool:
	if checkpoint == null or not checkpoint.is_valid():
		return false
	if has(checkpoint.id):
		return false
	_checkpoints.append(checkpoint)
	return true


func has(checkpoint_id: String) -> bool:
	return find(checkpoint_id) != null


func find(checkpoint_id: String) -> Checkpoint:
	for checkpoint: Checkpoint in _checkpoints:
		if checkpoint.id == checkpoint_id:
			return checkpoint
	return null


func size() -> int:
	return _checkpoints.size()


func is_empty() -> bool:
	return _checkpoints.is_empty()


func get_checkpoints() -> Array[Checkpoint]:
	return _checkpoints.duplicate()


func get_checkpoint_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for checkpoint: Checkpoint in _checkpoints:
		out.append(checkpoint.id)
	return out


## The longest declared replay segment, in seconds. 0.0 for an empty graph.
func worst_segment_seconds() -> float:
	var worst := 0.0
	for checkpoint: Checkpoint in _checkpoints:
		worst = maxf(worst, checkpoint.replay_seconds_from_previous)
	return worst


## Ids of the checkpoints whose incoming segment exceeds [param max_seconds]
## (REQ-003 AC-7). Empty means the world conforms.
##
## Strictly greater than: the criterion says "at or below", so a segment landing
## exactly on the bound passes.
func segments_over(max_seconds: float) -> PackedStringArray:
	var offenders := PackedStringArray()
	for checkpoint: Checkpoint in _checkpoints:
		if checkpoint.replay_seconds_from_previous > max_seconds:
			offenders.append(checkpoint.id)
	return offenders


## Whether this world's spacing conforms to the tuned bound.
##
## An EMPTY graph does not conform. A world with no checkpoints has unbounded
## replay by definition, and returning true for it would let the compliance test
## pass vacuously over exactly the worlds most in need of the check.
func conforms_to(max_seconds: float) -> bool:
	if is_empty():
		return false
	return segments_over(max_seconds).is_empty()
