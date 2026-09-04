class_name SaveCheckpointStore
extends CheckpointStore

## Production CheckpointStore backed by the real Save System (REQ-003).
##
## Writes into the world's own namespace through put_world_data, which the Save
## System already refuses to let escape into a reserved profile key — so a
## checkpoint anchor cannot clobber settings or another world's progress even if
## a world id were malformed.
##
## Note what this does NOT do: it never calls save_to_file. Persisting to DISK is
## the Save System's own business on its own schedule, and keeping that decision
## out of here is half of why AC-4 holds — the respawn path could not write the
## file even if it tried, because nothing in this class knows how.

const CHECKPOINT_KEY := "lastCheckpointId"

var _save: SaveSystem


func _init(save: SaveSystem) -> void:
	_save = save


func persist_checkpoint(world_id: String, checkpoint_id: String) -> void:
	if _save == null or world_id.is_empty():
		return
	_save.put_world_data(world_id, {CHECKPOINT_KEY: checkpoint_id})


func load_checkpoint(world_id: String) -> String:
	if _save == null or world_id.is_empty():
		return ""
	var data := _save.get_world_data(world_id)
	return String(data.get(CHECKPOINT_KEY, ""))
