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
## This script carries no behaviour of its own. It exists so the rig has a
## type the tests and a future mood system (an underwater tint, a dusk world)
## can find, and so the environment and sun are reachable without hard-coded
## node paths.

const ENVIRONMENT_PATH := "res://core/rendering/base_environment.tres"

@export var environment_path: NodePath = ^"WorldEnvironment"
@export var sun_path: NodePath = ^"Sun"


func get_world_environment() -> WorldEnvironment:
	return get_node_or_null(environment_path) as WorldEnvironment


func get_sun() -> DirectionalLight3D:
	return get_node_or_null(sun_path) as DirectionalLight3D
