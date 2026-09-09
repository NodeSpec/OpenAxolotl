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

## Verbs whose input is STILL DOWN this frame, for as long as it is down.
##
## Edge triggering answers "did they ask for this?", which is the right question
## for almost every verb. It cannot answer "are they still asking?", and one
## thing needs that: variable jump height reads the moment the player LETS GO
## (REQ-037). Carrying both is what lets the controller distinguish a tap from a
## hold without the controller learning what a key is.
##
## A verb that fires and is released within one frame appears in `verbs` and
## never in `sustained`; a held verb appears in `verbs` once and in `sustained`
## every frame until release.
var sustained: Array[MovementGrammar.Verb] = []


func _init(p_direction: Vector3 = Vector3.ZERO,
		p_verbs: Array[MovementGrammar.Verb] = [],
		p_sustained: Array[MovementGrammar.Verb] = []) -> void:
	direction = p_direction
	verbs = p_verbs.duplicate()
	sustained = p_sustained.duplicate()


func wants(verb: MovementGrammar.Verb) -> bool:
	return verbs.has(verb)


## Whether the input behind [param verb] is still held. Deliberately NOT implied
## by `wants`: a caller asking "is it still down" on the press frame of a verb
## the player already released must get false, or a one-frame tap would read as
## a hold.
func sustains(verb: MovementGrammar.Verb) -> bool:
	return sustained.has(verb)


static func none() -> PlayerIntent:
	return PlayerIntent.new()
