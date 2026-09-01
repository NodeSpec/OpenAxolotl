class_name InputVerb
extends RefCounted

## The complete player verb set (REQ-024 AC-1).
##
## This is deliberately a SUPERSET of MovementGrammar.Verb. The controller's verb
## enum covers locomotion, which is all the controller needs; the input scheme
## also has to bind the Gill Mod verbs, which belong to REQ-004 and never reach
## the controller. Binding those through this node rather than letting the HUD or
## the Gill Mod system read input directly is what keeps AC-6 true — there is one
## place in the codebase that touches raw input, and this is it.
##
## The bridge to MovementGrammar.Verb is an EXPLICIT table rather than a shared
## ordinal. The two enums are owned by different nodes and will drift; a
## positional correspondence would break silently the first time either grows,
## and would break as a wrong verb firing rather than as an error.

enum Verb {
	## Directional locomotion. Full 3D in water, planar on land.
	SWIM,
	WADDLE,

	## Movement verbs, edge-triggered.
	DIVE,
	BUBBLE_BOOST,
	HOP,
	CLIMB,
	GRAPPLE,
	DASH,

	## Ability verbs. These never reach the controller; the Gill Mod system
	## consumes them through this node's published surface.
	GILL_MOD_ACTIVATE,
	GILL_MOD_NEXT,
	GILL_MOD_PREV,
}

## Verbs that resolve to a direction rather than a press. Their binding carries a
## direction map instead of a single physical input.
const DIRECTIONAL: Array[Verb] = [Verb.SWIM, Verb.WADDLE]

## The named components of a directional binding. SWIM binds all six; WADDLE
## binds the four planar ones, because there is no up or down on land.
const DIRECTION_COMPONENTS: PackedStringArray = [
	"forward", "back", "left", "right", "up", "down",
]
const PLANAR_COMPONENTS: PackedStringArray = ["forward", "back", "left", "right"]

## Verb -> MovementGrammar.Verb, for the subset the controller consumes. A verb
## absent from this table is an ability verb and is delivered separately.
const MOVEMENT_EQUIVALENT: Dictionary = {
	Verb.SWIM: MovementGrammar.Verb.SWIM,
	Verb.WADDLE: MovementGrammar.Verb.WADDLE,
	Verb.DIVE: MovementGrammar.Verb.DIVE,
	Verb.BUBBLE_BOOST: MovementGrammar.Verb.BUBBLE_BOOST,
	Verb.HOP: MovementGrammar.Verb.HOP,
	Verb.CLIMB: MovementGrammar.Verb.CLIMB,
	Verb.GRAPPLE: MovementGrammar.Verb.GRAPPLE,
	Verb.DASH: MovementGrammar.Verb.DASH,
}


static func all() -> Array[Verb]:
	var out: Array[Verb] = []
	for value: int in Verb.values():
		out.append(value as Verb)
	return out


static func verb_id(verb: Verb) -> String:
	return String(Verb.keys()[verb]).to_lower()


## Parses a verb id. Returns UNKNOWN (-1) rather than defaulting to a real verb —
## a malformed binding must not silently become a working binding for something
## the player did not ask for.
const UNKNOWN := -1


static func from_id(id: String) -> int:
	for value: int in Verb.values():
		if verb_id(value as Verb) == id:
			return value
	return UNKNOWN


static func is_directional(verb: Verb) -> bool:
	return DIRECTIONAL.has(verb)


## The direction components this verb requires. A directional binding missing any
## of them is refused at load rather than producing a direction the player cannot
## fully steer.
static func required_components(verb: Verb) -> PackedStringArray:
	if verb == Verb.SWIM:
		return DIRECTION_COMPONENTS
	if verb == Verb.WADDLE:
		return PLANAR_COMPONENTS
	return PackedStringArray()


static func is_movement(verb: Verb) -> bool:
	return MOVEMENT_EQUIVALENT.has(verb)


## The controller-facing verb, for the movement subset. Callers must check
## is_movement() first; an ability verb has no controller equivalent by design.
static func movement_equivalent(verb: Verb) -> MovementGrammar.Verb:
	return MOVEMENT_EQUIVALENT[verb] as MovementGrammar.Verb


## The unit direction a component contributes, in the controller's space.
static func component_vector(component: String) -> Vector3:
	match component:
		"forward":
			return Vector3.FORWARD
		"back":
			return Vector3.BACK
		"left":
			return Vector3.LEFT
		"right":
			return Vector3.RIGHT
		"up":
			return Vector3.UP
		"down":
			return Vector3.DOWN
	return Vector3.ZERO
