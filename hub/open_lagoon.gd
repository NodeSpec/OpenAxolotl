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
var _hud: PlayerHud


func _ready() -> void:
	_registry = WorldRegistry.new(worlds_dir)
	_portals_root = Node3D.new()
	_portals_root.name = "Portals"
	add_child(_portals_root)
	# The game-state readout (REQ-022). Created empty here; each world entry
	# wires the systems that world actually runs, and the return unwires
	# them, so the HUD shows honest placeholders in the hub rather than a
	# dead world's last numbers.
	_hud = PlayerHud.new()
	_hud.name = "PlayerHud"
	add_child(_hud)
	refresh()


func get_hud() -> PlayerHud:
	return _hud


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
		# Detach before freeing: a queue_freed child keeps its name until the
		# end of the frame, and a replacement added meanwhile would be
		# auto-renamed — leaving pedestals unfindable by their portal name.
		_portals_root.remove_child(child)
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
			var manifest := _read_manifest(portal.module_dir)
			# The world's save namespace must exist BEFORE its runtime wires:
			# the collectibles system reads what the profile already records
			# for this world at wire time, and writes into that namespace at
			# every pickup.
			if _save != null:
				_save.open_world(world_id, manifest)
			# The runtime the world's declarations bind to: Gill Mods,
			# restoration, collectibles, tuning overrides. A child of the
			# world, so it lives and dies with the world it serves.
			var systems := WorldSystems.new()
			systems.manifest = manifest
			systems.world_id = world_id
			systems.save_system = _save
			systems.on_finish_condition = _on_world_finished
			world.add_child(systems)
			_wire_hud_to(systems, manifest)
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


## Points the readout at the world's live systems. The active region is the
## first the manifest declares — the interim answer to friction entry F-2's
## missing per-region activation declaration; a world declaring none shows
## the honest "Region: none".
func _wire_hud_to(systems: WorldSystems, manifest: Dictionary) -> void:
	if _hud == null:
		return
	_hud.set_gill_mods(systems.get_mods())
	_hud.set_tuning(systems.get_tuning())
	# Pillar one: lives and capabilities are the world's; the dash is the
	# player's own controller's, which lives beside the hub.
	_hud.set_life_system(systems.get_lives())
	_hud.set_regen(systems.get_regen())
	var body := get_tree().get_first_node_in_group(PLAYER_GROUP) as AxolotlBody
	if body != null and body.get_controller() != null:
		_hud.set_dash(body.get_controller().get_dash())
	var regions: Variant = manifest.get("restorableRegions", [])
	var first_region := ""
	if regions is Array and not (regions as Array).is_empty():
		first_region = String(
			((regions as Array)[0] as Dictionary).get("regionId", ""))
	_hud.set_restoration(systems.get_restoration(), first_region)


func _unwire_hud() -> void:
	if _hud == null:
		return
	_hud.set_gill_mods(null)
	_hud.set_restoration(null)
	_hud.set_life_system(null)
	_hud.set_regen(null)
	_hud.set_dash(null)
	_hud.set_tuning(null)


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

	# The world's capability factors leave with the world, not with the player.
	for systems: Node in _active_world.find_children("*", "WorldSystems", true, false):
		(systems as WorldSystems).release_player_factors()
	_active_world.queue_free()
	_active_world = null
	_active_world_id = ""
	_unwire_hud()

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
