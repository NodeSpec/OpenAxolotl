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
## Side portals load at the world's spawn and hide the hub (AC-2). A middle
## world with a stream_entry landmark is instead joined to the lagoon before
## play and activated in place. Completion still returns to the hub.
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

## How far below the lagoon the player may fall before the hub takes them
## back. See _recover_fallen_player.
##
## Forty metres, which is roughly two seconds of falling: far enough below the
## lagoon floor that no jump, dive or knockback reaches it by accident, close
## enough that a player who has clearly left the level is not left watching
## the sky for long. It is the value dev/fall_guard.gd used while it was
## standing in for this, kept so the behaviour a person tested by hand is the
## behaviour that shipped.
const RECOVERY_FLOOR_Y := -40.0

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
var _stream_world: Node3D
var _stream_world_id: String = ""
var _continuous_active: bool = false


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
	# The hub disables its own processing while a world runs. Countdown and
	# recharge readouts must keep updating during that world.
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
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
	# Authored presentation order is independent of directory discovery order.
	portals.sort_custom(func(a: WorldPortal,b: WorldPortal) -> bool:
		var a_order := int((_read_manifest(a.module_dir).get("hubEntry",{}) as Dictionary).get("order",1000))
		var b_order := int((_read_manifest(b.module_dir).get("hubEntry",{}) as Dictionary).get("order",1000))
		return a_order<b_order if a_order!=b_order else a.world_id<b.world_id)
	_prepare_stream_world(portals)
	var spacing := 6.0
	var offset := (portals.size() - 1) * spacing * 0.5
	var centers: Array[float] = []
	for index: int in portals.size():
		centers.append(index * spacing - offset)
		_portals_root.add_child(
			_build_pedestal(portals[index], index * spacing - offset, index))
	var hydrology := get_node_or_null("Hydrology") as LagoonHydrology
	if hydrology != null:
		var passage := get_node_or_null("DownstreamPassage") as Node3D
		hydrology.configure_tunnels(centers,_stream_world != null,passage.position.x if passage != null else 0.0)


func is_continuous_world() -> bool:
	return _continuous_active


func _prepare_stream_world(portals: Array[WorldPortal]) -> void:
	var passage := get_node_or_null("DownstreamPassage") as LagoonStream
	if passage == null or _continuous_active:
		return
	var portal: WorldPortal
	for candidate: WorldPortal in portals:
		var entry := _read_manifest(candidate.module_dir).get("hubEntry",{}) as Dictionary
		if bool(entry.get("continuous",false)):
			portal=candidate
			break
	if portal == null and portals.size()%2 == 1:
		portal = portals[portals.size()/2]
	if portal != null:
		passage.position.x=float(portals.find(portal))*6.0-float(portals.size()-1)*3.0
	if _stream_world != null:
		if portal != null and portal.available and portal.world_id == _stream_world_id:
			var old_entry := WorldLoader._in_group(_stream_world,"stream_entry")[0] as Node3D
			_stream_world.global_position += passage.to_global(LagoonStreamPath.exit_position())-old_entry.global_position
			return
		remove_child(_stream_world)
		_stream_world.queue_free()
		_stream_world = null
		_stream_world_id = ""
	passage.visible = false
	passage.process_mode = Node.PROCESS_MODE_DISABLED
	if portal == null or not portal.available:
		return
	var errors: Array[HubError] = []
	var world: Node3D = _loader.instantiate_world(portal.module_dir,errors)
	if world == null:
		return
	var anchors: Array[Node] = WorldLoader._in_group(world,"stream_entry")
	if anchors.size() != 1 or not anchors[0] is Node3D:
		world.free()
		return
	var anchor := anchors[0] as Node3D
	var entry: Vector3 = anchor.position
	var ancestor: Node = anchor.get_parent()
	while ancestor != world and ancestor is Node3D:
		entry = (ancestor as Node3D).transform*entry
		ancestor = ancestor.get_parent()
	# Both scenes occupy the same physics space before the swimmer arrives.
	world.position = passage.position+LagoonStreamPath.exit_position()-entry
	world.name = "ConnectedWorld"
	add_child(world)
	_stream_world = world
	_stream_world_id = portal.world_id
	passage.visible = true
	passage.process_mode = Node.PROCESS_MODE_INHERIT


func _activate_stream_world() -> void:
	if _active_world != null or not is_instance_valid(_stream_world):
		return
	var portal: WorldPortal = _registry.get_portal(_stream_world_id)
	if portal == null or not portal.available:
		return
	var errors: Array[HubError] = []
	_loader.wire_finish_condition(_stream_world,_finish_kind(portal.module_dir),_on_world_finished,errors)
	if not errors.is_empty():
		push_warning("Connected world could not activate: %s" % errors)
		return
	_active_world = _stream_world
	_active_world_id = _stream_world_id
	_continuous_active = true
	_start_world_systems(_active_world,portal)
	# No teleport, water-contact reset, camera reset, or hub teardown here.
	world_entered.emit(_active_world_id)


func _start_world_systems(world: Node3D, portal: WorldPortal) -> void:
	var manifest := _read_manifest(portal.module_dir)
	if _save != null:
		_save.open_world(portal.world_id,manifest)
	var systems := WorldSystems.new()
	systems.manifest = manifest
	systems.world_id = portal.world_id
	systems.save_system = _save
	systems.on_finish_condition = _on_world_finished
	world.add_child(systems)
	_wire_hud_to(systems,manifest)


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
			_start_world_systems(world,portal)
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
		(systems as WorldSystems).persist_progress()
		(systems as WorldSystems).release_player_factors()
	if _active_world == _stream_world:
		_stream_world = null
		_stream_world_id = ""
	_continuous_active = false
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


func get_active_world() -> Node3D:
	return _active_world


# --- Pedestals --------------------------------------------------------------

func _build_pedestal(portal: WorldPortal, x: float, art_index: int = 0) -> Node3D:
	var pedestal := Node3D.new()
	pedestal.name = "Portal_%s" % portal.world_id
	pedestal.position = Vector3(x, LagoonHydrology.TUNNEL_Y, -8.0)
	pedestal.add_child(LagoonArt.make_tunnel(art_index))

	var mesh := MeshInstance3D.new()
	mesh.mesh = _mesh_for_shape(PortalTier.shape_id(portal.tier))
	var material := StandardMaterial3D.new()
	var tint := PortalTier.color(portal.tier)
	# An unavailable portal is dimmed AND relabelled — the colour change never
	# carries the state alone.
	material.albedo_color = tint if portal.available else tint.darkened(0.6)
	mesh.material_override = material
	# Tier silhouette becomes a small crest on the arch's keystone.
	mesh.position = Vector3(0.0, 4.35, 0.68)
	mesh.scale = Vector3.ONE * 0.13
	pedestal.add_child(mesh)

	var label := Label3D.new()
	label.text = portal.portal_label()
	label.position = Vector3(0.0, 4.9, 0.3)
	label.font_size = 32
	label.pixel_size = 0.007
	label.modulate = Color(1.0, 0.94, 0.76)
	label.outline_size = 7
	label.visibility_range_end = 17.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pedestal.add_child(label)

	# Only an available portal can be entered: no entry volume, no entry.
	if portal.available:
		var area := Area3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(3.0, 3.0, 1.0)
		shape.shape = box
		area.add_child(shape)
		area.position = Vector3(0.0, 0.15, -2.3)
		# Deferred: body_entered fires while the physics space is being
		# flushed, and entering a world adds a scene to the tree — doing that
		# mid-flush is an error. The deferral lands the same frame.
		area.body_entered.connect(
			func(body: Node3D) -> void:
				if portal.world_id == _stream_world_id:
					return
				if body.is_in_group(PLAYER_GROUP) and body is AxolotlBody and (body as AxolotlBody).is_in_water():
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
	var passage := get_node_or_null("DownstreamPassage") as LagoonStream
	if not active and passage != null:
		passage.release_camera_hint()
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active \
		else Node.PROCESS_MODE_DISABLED


## Take the player back to the lagoon when they leave it downwards.
##
## THE HUB HAD NO FLOOR AND FALLING OUT OF IT WAS UNRECOVERABLE. Both official
## worlds carry a pit volume — a 600x600 and a 400x400 kill slab under the
## whole playable area — so a fall there costs a life and returns the player
## to their last checkpoint, which is REQ-003 working exactly as designed.
## The hub carries no pit volume, owns no LifeSystem, and had nothing else
## watching: measured, the player fell 583 units in twenty seconds and was
## still accelerating, with no way back except quitting the game.
##
## It returns rather than costing a life on purpose. The hub is not a
## challenge space: it holds the portals, the save, and no hazards, so there
## is nothing here to be punished for failing. A lives cost would also have
## nowhere to go — the LifeSystem belongs to a loaded world, and in the hub
## there is not one to charge.
##
## Skipped entirely while a world is loaded, because that world's pit volume
## and checkpoint graph own the fall and are better at it: they charge a life
## and return the player to progress, which is the designed consequence.
func _recover_fallen_player() -> void:
	if _active_world != null:
		return
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if player == null or player.global_position.y >= RECOVERY_FLOOR_Y:
		return
	_move_player_to(_hub_spawn_position())

	# HELD KEYS ARE DROPPED HERE AND NOWHERE ELSE. The walk that carried
	# someone off an edge is still being pressed when they land back on it, so
	# a recovery that keeps the input queue sends them straight back over —
	# which is what dev/fall_guard.gd found and cleared. It belongs to the
	# FALL and not to _move_player_to, because that function also runs on
	# world entry, where the player pressed forward on purpose and expects to
	# keep walking: clearing it there froze the hub walk probe at its spawn
	# with the world entered and the level never completed.
	var body := player as AxolotlBody
	if body != null and body.get_input_system() != null:
		body.get_input_system().clear()


func _physics_process(_delta: float) -> void:
	_recover_fallen_player()
	if _active_world == null and _stream_world != null:
		var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as AxolotlBody
		var passage := get_node_or_null("DownstreamPassage") as LagoonStream
		if player != null and passage != null and player.global_position.z < -47.0 and passage.contains_point(player.global_position):
			_activate_stream_world.call_deferred()


## Put the player somewhere, and make sure they ARRIVE there at rest.
##
## Position alone is not enough and this used to set only position. A body
## teleported mid-fall keeps its downward velocity, so it arrives at the spawn
## marker already moving and is off the edge again within a second — the
## respawn becomes the next fall. Every teleport the hub does wants this:
## arriving at a world's spawn point already falling is no better than
## arriving at the lagoon's.
##
## The controller is told too, not just the body. It integrates its own
## velocity and tracks its own position, so a body moved out from under it
## would be dragged back toward where the controller still thinks it is.
func _move_player_to(position_3d: Vector3) -> void:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player is Node3D:
		(player as Node3D).global_position = position_3d
	var body := player as AxolotlBody
	if body == null:
		return
	body.clear_water_contacts()
	body.reset_visual_motion()
	body.resample_water_contacts.call_deferred()
	body.velocity = Vector3.ZERO
	var controller := body.get_controller()
	if controller != null:
		controller.set_velocity(Vector3.ZERO)
		controller.sync_body_position(position_3d)


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
