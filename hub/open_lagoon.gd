class_name OpenLagoon
extends Node3D

## The Open Lagoon — the hub that makes the modular architecture visible as a
## place (REQ-009).
##
## Portal pedestals are BUILT from the registry's records every refresh; no
## portal exists in the scene file, because a portal authored by hand would be
## a world list in disguise. Each pedestal renders its tier through THREE
## channels — silhouette, text label, colour — since REQ-019 forbids
## colour-only encoding, and an unavailable module still gets a pedestal,
## dimmed and labelled, with no entry volume: a broken world is shown, never
## hidden and never fatal (AC-4).
##
## Entering a portal loads that world at its spawn point; completing its finish
## condition returns the player here (AC-2). The hub is HIDDEN while a world is
## active rather than freed, so returning restores it exactly as it was.
##
## Completion and restoration progress are read through the Save Integration
## Interface when a SaveSystem is attached (AC-6); the hub never opens the
## save file itself.

signal world_entered(world_id: String)
signal world_completed(world_id: String)
signal returned_to_hub(world_id: String)

const HUB_SPAWN_GROUP := "hub_spawn"
const PLAYER_GROUP := "player"

## Where an active world is placed. The hub is hidden while a world runs, but
## two scenes still share one physics space — without an offset the world's
## floor would interpenetrate the lagoon's and the player could stand on
## geometry that is not supposed to exist right now.
const WORLD_OFFSET := Vector3(0.0, 0.0, -200.0)

## The scanned directory. Exported so a test scene can point the same hub at a
## scratch directory — the hub code itself must work against any of them.
@export var worlds_dir: String = WorldRegistry.DEFAULT_WORLDS_DIR

var _registry: WorldRegistry
var _loader := WorldLoader.new()
var _save: SaveSystem

var _portals_root: Node3D
var _active_world: Node3D
var _active_world_id: String = ""


func _ready() -> void:
	_registry = WorldRegistry.new(worlds_dir)
	_portals_root = Node3D.new()
	_portals_root.name = "Portals"
	add_child(_portals_root)
	refresh()


## Attaches the save system. Progress annotations appear on the next refresh;
## a hub with no save wired shows every world unvisited rather than failing.
func set_save_system(save: SaveSystem) -> void:
	_save = save
	refresh()


func get_registry() -> WorldRegistry:
	return _registry


## Rescans the worlds directory and rebuilds every pedestal. Adding, removing
## or replacing a module changes the portals HERE, with no code edit (AC-3).
func refresh() -> void:
	_registry.discover()
	if _save != null:
		_registry.apply_progress(_save)

	for child: Node in _portals_root.get_children():
		child.queue_free()

	var portals := _registry.get_portals()
	var spacing := 6.0
	var offset := (portals.size() - 1) * spacing * 0.5
	for index: int in portals.size():
		_portals_root.add_child(
			_build_pedestal(portals[index], index * spacing - offset))


## Enters a world by id. Failures surface as an unavailable portal on refresh
## rather than as a crash — a world that validated but no longer loads is the
## exact case AC-4 exists for.
func enter_world(world_id: String) -> bool:
	if _active_world != null:
		return false
	var portal := _registry.get_portal(world_id)
	if portal == null or not portal.available:
		return false

	var errors: Array[HubError] = []
	var world := _loader.instantiate_world(portal.module_dir, errors)
	if world != null:
		world.position = WORLD_OFFSET
		get_parent().add_child(world)
		var spawn := _loader.find_spawn_position(world, errors)
		var kind := _finish_kind(portal.module_dir)
		_loader.wire_finish_condition(
			world, kind, _on_world_finished, errors)
		if errors.is_empty():
			_active_world = world
			_active_world_id = world_id
			if _save != null:
				_save.open_world(world_id, _read_manifest(portal.module_dir))
			_move_player_to(spawn)
			_set_hub_active(false)
			world_entered.emit(world_id)
			return true
		world.queue_free()

	portal.available = false
	portal.failures.append_array(errors)
	push_warning("world '%s' failed to load: %s"
		% [world_id, portal.failure_summary()])
	refresh()
	return false


## The completion hook for finish kinds owned by other systems: the boss
## encounter, restoration and collectibles call this through the hub when
## their condition is met. reach_volume worlds fire it from the wired volume.
func notify_finish_condition_met() -> void:
	_on_world_finished()


func _on_world_finished() -> void:
	if _active_world == null:
		return
	var finished_id := _active_world_id

	if _save != null:
		_save.put_world_data(finished_id, {"completed": true})

	_active_world.queue_free()
	_active_world = null
	_active_world_id = ""

	_set_hub_active(true)
	_move_player_to(_hub_spawn_position())
	world_completed.emit(finished_id)
	refresh()
	returned_to_hub.emit(finished_id)


func is_in_world() -> bool:
	return _active_world != null


# --- Pedestals --------------------------------------------------------------

func _build_pedestal(portal: WorldPortal, x: float) -> Node3D:
	var pedestal := Node3D.new()
	pedestal.name = "Portal_%s" % portal.world_id
	pedestal.position = Vector3(x, 0.0, -8.0)

	var mesh := MeshInstance3D.new()
	mesh.mesh = _mesh_for_shape(PortalTier.shape_id(portal.tier))
	var material := StandardMaterial3D.new()
	var tint := PortalTier.color(portal.tier)
	# An unavailable portal is dimmed AND relabelled — the colour change never
	# carries the state alone.
	material.albedo_color = tint if portal.available else tint.darkened(0.6)
	mesh.material_override = material
	mesh.position = Vector3(0.0, 1.5, 0.0)
	pedestal.add_child(mesh)

	var label := Label3D.new()
	label.text = portal.portal_label()
	label.position = Vector3(0.0, 3.4, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pedestal.add_child(label)

	# Only an available portal can be entered: no entry volume, no entry.
	if portal.available:
		var area := Area3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(3.0, 3.0, 3.0)
		shape.shape = box
		area.add_child(shape)
		area.position = Vector3(0.0, 1.5, 0.0)
		# Deferred: body_entered fires while the physics space is being
		# flushed, and entering a world adds a scene to the tree — doing that
		# mid-flush is an error. The deferral lands the same frame.
		area.body_entered.connect(
			func(body: Node3D) -> void:
				if body.is_in_group(PLAYER_GROUP):
					enter_world.call_deferred(portal.world_id))
		pedestal.add_child(area)

	return pedestal


## Tier silhouettes. Distinct primitives, not one primitive recoloured — the
## shape is a discrimination channel in its own right.
func _mesh_for_shape(shape_id: String) -> Mesh:
	match shape_id:
		"pedestal_ring":
			return TorusMesh.new()
		"pedestal_spire":
			var spire := CylinderMesh.new()
			spire.top_radius = 0.05
			spire.bottom_radius = 0.9
			spire.height = 3.0
			return spire
		_:
			var arch := BoxMesh.new()
			arch.size = Vector3(2.4, 3.0, 0.6)
			return arch


# --- Plumbing ---------------------------------------------------------------

## Hiding is not enough: an invisible StaticBody still collides and an
## invisible portal volume still triggers. Disabling the hub's process mode
## removes its collision objects from the physics space entirely (their
## default disable mode is REMOVE), so an active world and a dormant hub can
## never interact. Signal handlers on this node still run — process mode
## gates processing and physics, not incoming calls — which is how the finish
## callback wakes the hub back up.
func _set_hub_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active \
		else Node.PROCESS_MODE_DISABLED


func _move_player_to(position_3d: Vector3) -> void:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player is Node3D:
		(player as Node3D).global_position = position_3d


func _hub_spawn_position() -> Vector3:
	var spawn := get_tree().get_first_node_in_group(HUB_SPAWN_GROUP)
	if spawn is Node3D:
		return (spawn as Node3D).global_position
	return Vector3.ZERO


func _finish_kind(module_dir: String) -> String:
	var manifest := _read_manifest(module_dir)
	var condition := manifest.get("finishCondition", {}) as Dictionary
	return String(condition.get("kind", WorldLoader.REACH_VOLUME))


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
