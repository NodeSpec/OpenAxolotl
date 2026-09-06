class_name SaveCollectibleStore
extends CollectibleStore

## Production CollectibleStore backed by the real Save System (REQ-010 AC-3).
##
## Writes the world's `collectibles` field through put_world_data, which the
## Save System already refuses to let escape into a reserved profile key — so
## a collected id can never clobber settings or another world's progress.
##
## Like the checkpoint store, this never calls save_to_file: persisting to
## DISK is the Save System's own business on its own schedule. What this
## store guarantees is that the collection is in the PROFILE the instant it
## happens, which is what lets it survive the life layer (AC-4) — a respawn
## discards no run-scoped buffer because there is no run-scoped buffer.

var _save: SaveSystem


func _init(save: SaveSystem) -> void:
	_save = save


func load_collected(world_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	if _save == null or world_id.is_empty():
		return out
	var data := _save.get_world_data(world_id)
	var raw: Variant = data.get(FIELD, [])
	if raw is Array:
		for entry: Variant in (raw as Array):
			out.append(String(entry))
	return out


func persist_collected(world_id: String, ids: PackedStringArray) -> void:
	if _save == null or world_id.is_empty():
		return
	# A plain Array, so the in-memory profile and its JSON round trip carry
	# the same shape — the save-compat shape reader depends on that.
	var plain: Array = []
	for id: String in ids:
		plain.append(id)
	_save.put_world_data(world_id, {FIELD: plain})
