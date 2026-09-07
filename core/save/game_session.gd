class_name GameSession
extends Node3D

## Owns the profile for the shipped game (REQ-014). It lives beside the hub,
## so saving continues while the hub's scene and physics are disabled.
## Tests may supply a temporary path, or an empty path for an in-memory run.
@export var profile_path: String = "user://profile.json"

var _save := SaveSystem.new()
var _can_write: bool = true


func _ready() -> void:
	if not profile_path.is_empty() and FileAccess.file_exists(profile_path):
		var errors: Array[SaveError] = []
		_can_write = _save.load_from_file(profile_path, errors)
		if not _can_write:
			push_warning("Could not load your save. Playing a temporary session; the existing file will be preserved.")
	var hub := get_node("OpenLagoon") as OpenLagoon
	hub.set_save_system(_save)
	hub.world_completed.connect(func(_world_id: String) -> void: save_progress())
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(save_progress)
	add_child(timer)


func get_save_system() -> SaveSystem:
	return _save


func save_progress() -> bool:
	if not is_inside_tree():
		return false
	for node: Node in get_tree().get_nodes_in_group("world_systems"):
		var systems := node as WorldSystems
		if systems != null and systems.save_system == _save:
			systems.persist_progress()
	if profile_path.is_empty() or not _can_write:
		return false
	return _save.save_to_file(profile_path)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_progress()
