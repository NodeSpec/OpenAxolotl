class_name CheckpointStore
extends RefCounted

## The Save Integration Interface as the Lives system needs it (REQ-003).
##
## Checkpoint state persists across sessions, so ACTIVATING a checkpoint writes.
## Reaching zero lives does NOT — AC-4 says a respawn never modifies or penalises
## the save file, and the way to make that true rather than remembered is for the
## respawn path to hold no reference to this at all.
##
## Narrow on purpose: two methods, one world's checkpoint anchor. A port shaped
## like the whole save system would invite the respawn path to reach for it.

## Records the world's current respawn anchor. Called on checkpoint activation
## and nowhere else.
func persist_checkpoint(_world_id: String, _checkpoint_id: String) -> void:
	pass


## The anchor recorded in a previous session, or "" when the world has never been
## played. Empty means spawn, not an error.
func load_checkpoint(_world_id: String) -> String:
	return ""
