class_name SaveRestorationStore
extends RestorationStore

## Binds restoration's existing persistence port to its world namespace.
var _save: SaveSystem
var _world_id: String


func _init(save: SaveSystem, world_id: String) -> void:
	_save = save
	_world_id = world_id


func load_regions() -> Dictionary:
	return _save.get_world_data(_world_id).get("regions", {}) as Dictionary


func save_regions(payload: Dictionary) -> void:
	_save.put_world_data(_world_id, {"regions": payload})
