class_name WorldRegistry
extends RefCounted

## Runtime world discovery for the Open Lagoon (REQ-009 AC-1, AC-3, AC-4).
##
## Scans a worlds directory at runtime, validates each module against the
## loaded Level Contract, and builds the portal list from what it finds. THERE
## IS NO WORLD LIST IN CODE, and no world's id appears anywhere in `hub/` —
## including no special case for the reference template, which must ride the
## identical path because that is what proves the path is generic. Adding,
## removing or replacing a module changes the portals on the next scan with no
## edit here (AC-3), which is the property that lets a world be forked or
## replaced without touching the hub.
##
## A module that fails to load or fails validation becomes an UNAVAILABLE
## portal carrying its failure reasons; it never propagates an error into the
## hub (AC-4). The scan itself cannot crash on a module's content: validation
## reads files as text and data, and a module's scene is only ever instantiated
## AFTER it has passed.
##
## The directory is a constructor argument (defaulting to res://worlds) so the
## discovery behaviour itself is testable against a scratch directory — the
## add/remove/replace criterion is proven by actually adding and removing
## modules, not by reading this comment.

const DEFAULT_WORLDS_DIR := "res://worlds"

var _worlds_dir: String
var _validator: ContractValidator
var _portals: Array[WorldPortal] = []


func _init(worlds_dir: String = DEFAULT_WORLDS_DIR,
		validator: ContractValidator = null) -> void:
	_worlds_dir = worlds_dir
	_validator = validator if validator != null else ContractValidator.new()


## Scans the directory and rebuilds the portal list. Safe to call again at any
## time — the hub refreshes rather than restarting. A missing worlds directory
## yields an empty hub, not an error: a fresh fork with no worlds yet is a
## legitimate state.
func discover() -> Array[WorldPortal]:
	_portals = []
	var dir := DirAccess.open(_worlds_dir)
	if dir == null:
		return _portals

	var names := dir.get_directories()
	names.sort()
	for name: String in names:
		_portals.append(_build_portal(name))
	return _portals


func _build_portal(name: String) -> WorldPortal:
	var module_dir := _worlds_dir.path_join(name)
	var portal := WorldPortal.new(name, module_dir)

	var errors: Array[HubError] = []
	var conforming := _validator.validate_module(module_dir, errors)

	# Read the manifest for presentation fields even when validation failed —
	# an unavailable portal with its declared name is easier to debug than a
	# bare directory id. Never for anything load-bearing.
	var manifest := _read_manifest(module_dir)
	portal.display_name = String(manifest.get("displayName", name))
	portal.tier = PortalTier.from_manifest(manifest, errors)

	portal.failures = errors
	portal.available = conforming and errors.is_empty()
	if portal.available:
		portal.world_id = String(manifest.get("worldId", name))
	return portal


func get_portals() -> Array[WorldPortal]:
	return _portals.duplicate()


func get_available() -> Array[WorldPortal]:
	var out: Array[WorldPortal] = []
	for portal: WorldPortal in _portals:
		if portal.available:
			out.append(portal)
	return out


func get_unavailable() -> Array[WorldPortal]:
	var out: Array[WorldPortal] = []
	for portal: WorldPortal in _portals:
		if not portal.available:
			out.append(portal)
	return out


func get_portal(world_id: String) -> WorldPortal:
	for portal: WorldPortal in _portals:
		if portal.world_id == world_id:
			return portal
	return null


## Fills each portal's completion and restoration progress from the Save
## Integration Interface (AC-6). The hub reads a world's namespaced data
## through the save system's API and NEVER opens the save file itself — the
## save format stays the Save System's private business.
func apply_progress(save: SaveSystem) -> void:
	for portal: WorldPortal in _portals:
		var data := save.get_world_data(portal.world_id)
		portal.completed = bool(data.get("completed", false))

		var regions := data.get("regions", {}) as Dictionary
		portal.regions_total = regions.size()
		portal.regions_restored = 0
		for key: Variant in regions:
			var region: Variant = regions[key]
			if region is Dictionary \
					and String((region as Dictionary).get("state", "")) == "restored":
				portal.regions_restored += 1


func _read_manifest(module_dir: String) -> Dictionary:
	var path := module_dir.path_join("world.json")
	if not FileAccess.file_exists(path):
		return {}
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		return {}
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	return parsed as Dictionary if parsed is Dictionary else {}
