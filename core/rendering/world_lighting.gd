class_name WorldLighting
extends Node3D

## The shared lighting rig (core/rendering/world_lighting.tscn): the one
## WorldEnvironment and sun every world is lit with.
##
## Worlds ship geometry; the game client ships the look. The rig therefore
## lives at the MAIN scene level beside the hub, never inside it: the hub
## disables its own subtree while a world is active, and a light parented
## under it would go dark the moment the player stepped through a portal
## (which is exactly what happened before this rig existed — official worlds
## were lit by ambient colour alone). Whatever survives a world transition
## lives beside the hub.
##
## This script carries almost no behaviour of its own. It exists so the rig has
## a type the tests and a future mood system (an underwater tint, a dusk world)
## can find, so the environment and sun are reachable without hard-coded node
## paths, and — since REQ-027 — so the graphics quality level has ONE place to
## be applied from.
##
## QUALITY IS APPLIED HERE because this is the only node that owns both halves
## of the cost. The environment resource carries SDFGI, fog and SSAO; the sun
## carries the shadow filter; and the rig is instanced beside the hub, so it
## survives a world transition and does not have to re-apply on every portal.
## A world never touches it: worlds ship geometry, the client ships the look.

const ENVIRONMENT_PATH := "res://core/rendering/base_environment.tres"

@export var environment_path: NodePath = ^"WorldEnvironment"
@export var sun_path: NodePath = ^"Sun"

## The environment variable that overrides the default, for testing and for a
## player who needs to change the level before there is a menu to change it in
## (OAX_QUALITY=low|medium|high). An options screen is the proper home and is
## follow-up work; until it exists, this is the escape hatch, and it is read
## once rather than polled.
const OVERRIDE_ENV := "OAX_QUALITY"

var _quality: RenderQuality.Level = RenderQuality.DEFAULT


func _ready() -> void:
	var override := OS.get_environment(OVERRIDE_ENV)
	if not override.is_empty():
		_quality = RenderQuality.level_from_name(override)
	set_quality(_quality)


func get_world_environment() -> WorldEnvironment:
	return get_node_or_null(environment_path) as WorldEnvironment


func get_sun() -> DirectionalLight3D:
	return get_node_or_null(sun_path) as DirectionalLight3D


func get_quality() -> RenderQuality.Level:
	return _quality


## Apply a graphics quality level to the whole game.
##
## Deliberately does NOT depend on _ready having run. A node added to the root
## from inside SceneTree._initialize — which is how the test harness and every
## headless probe in this repo build their scenes — is not in the tree yet, so
## its _ready fires a frame later or not at all. Anything that only happened in
## _ready would therefore be true in the game and false under test, which is
## the worst place for a difference to live.
func set_quality(level: RenderQuality.Level) -> void:
	_quality = level
	var holder := get_world_environment()
	var environment: Environment = null
	if holder != null and holder.environment != null:
		# base_environment.tres is a SHARED resource: load() hands every caller
		# the same instance, so applying a level to it in-place would mutate
		# the repo's own file and bake that level in on the next editor save.
		# A duplicate has no resource_path, which is also how this stays
		# idempotent across repeated calls.
		if holder.environment.resource_path == ENVIRONMENT_PATH:
			holder.environment = holder.environment.duplicate()
		environment = holder.environment
	RenderQuality.apply(level, environment, get_sun(),
		get_viewport() if is_inside_tree() else null)
