class_name WorldLoader
extends RefCounted

## Instantiates a validated world module and finds its contract landmarks
## (REQ-009 AC-2).
##
## The loader runs AFTER validation — the registry has already refused anything
## non-conforming — but it still guards its own steps, because a scene can be
## unloadable for reasons no manifest check can see (a corrupt file, a missing
## sub-resource). Every failure is a named HubError handed back to the caller;
## nothing here crashes the hub (AC-4's load-time half).
##
## Landmarks are found by GROUP, never by node name, and nothing in this file
## names any world: the reference template, an official world and a community
## module all ride the identical path. That absence of special cases is itself
## a checked criterion (AC-5 of REQ-029, AC-1 here) — a structural test scans
## `hub/` for world ids and fails on a match.

const SPAWN_GROUP := "spawn_point"
const FINISH_GROUP := "finish_volume"

const REACH_VOLUME := "reach_volume"


## Loads and instantiates a module's scene. Returns null with errors appended
## rather than raising — the hub surfaces failures, it never wears them.
func instantiate_world(module_dir: String,
		out_errors: Array[HubError]) -> Node3D:
	var scene_path := module_dir.path_join("world.tscn")
	if not FileAccess.file_exists(scene_path):
		out_errors.append(HubError.new(
			HubError.MISSING_SCENE, scene_path, "world.tscn is missing"))
		return null

	var packed := load(scene_path) as PackedScene
	if packed == null:
		out_errors.append(HubError.new(
			HubError.UNLOADABLE_SCENE, scene_path,
			"world.tscn exists but could not be loaded as a scene"))
		return null

	var instance := packed.instantiate()
	if not (instance is Node3D):
		out_errors.append(HubError.new(
			HubError.UNLOADABLE_SCENE, scene_path,
			"the world's root must be a Node3D"))
		if instance != null:
			instance.free()
		return null
	return instance as Node3D


## The spawn transform the player is placed at (AC-2: "loads the corresponding
## world at its spawn point"). Exactly one node in the spawn group — the
## contract guarantees it for validated modules, and the guard stays for the
## load-time failure the contract cannot see.
func find_spawn_position(world: Node3D, out_errors: Array[HubError]) -> Vector3:
	var spawns := _in_group(world, SPAWN_GROUP)
	if spawns.is_empty():
		out_errors.append(HubError.new(
			HubError.MISSING_SPAWN, world.name,
			"no node in group '%s'" % SPAWN_GROUP))
		return Vector3.ZERO
	return (spawns[0] as Node3D).global_position


## Wires the world's finish condition to [param on_finished].
##
## `reach_volume` is wired here: every finish_volume Area3D fires the callback
## when a body in the player group enters it. The other three kinds
## (defeat_boss, restore_all_regions, collect_all) are completed by the systems
## that own those mechanics calling the returned callback through the hub —
## the loader exposes the hook rather than reaching into systems it does not
## own. A reach_volume world with no finish volume is a load failure, since it
## would be unwinnable.
func wire_finish_condition(world: Node3D, kind: String,
		on_finished: Callable, out_errors: Array[HubError]) -> bool:
	if kind != REACH_VOLUME:
		return true

	var volumes := _in_group(world, FINISH_GROUP)
	if volumes.is_empty():
		out_errors.append(HubError.new(
			HubError.MISSING_FINISH, world.name,
			"finishCondition is reach_volume but no node is in group '%s'"
			% FINISH_GROUP))
		return false

	for volume: Node in volumes:
		if volume is Area3D:
			# Deferred: completing tears the world down and rebuilds the hub's
			# pedestals, none of which may happen while the physics space is
			# mid-flush emitting this very signal.
			(volume as Area3D).body_entered.connect(
				func(body: Node3D) -> void:
					if body.is_in_group("player"):
						on_finished.call_deferred())
	return true


static func _in_group(world: Node, group: String) -> Array[Node]:
	var out: Array[Node] = []
	if world.is_in_group(group):
		out.append(world)
	for node: Node in world.find_children("*", "", true, false):
		if node.is_in_group(group):
			out.append(node)
	return out
