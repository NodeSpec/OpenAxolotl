class_name PlayerIntent
extends RefCounted

## Player intent as delivered by the Input System's Player Input Interface
## (REQ-001, REQ-024).
##
## The controller never reaches into Godot's `Input` singleton for a gameplay
## verb, and worlds never read raw input at all. That indirection is what makes
## rebinding and context-sensitive bindings possible: the same physical button
## can mean DIVE in water and HOP on land because the Input System resolves it
## against the active grammar before the controller ever sees it.

## Desired movement direction, already normalised by the Input System. Full 3D
## in water; the vertical component is ignored by the land grammar.
var direction: Vector3 = Vector3.ZERO

## Verbs requested THIS frame. Edge-triggered, not held state — a verb appears
## once on the frame it was pressed.
var verbs: Array[MovementGrammar.Verb] = []


func _init(p_direction: Vector3 = Vector3.ZERO,
		p_verbs: Array[MovementGrammar.Verb] = []) -> void:
	direction = p_direction
	verbs = p_verbs.duplicate()


func wants(verb: MovementGrammar.Verb) -> bool:
	return verbs.has(verb)


static func none() -> PlayerIntent:
	return PlayerIntent.new()
