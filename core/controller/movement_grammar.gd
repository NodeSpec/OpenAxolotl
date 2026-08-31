class_name MovementGrammar
extends RefCounted

## The two movement grammars and the verbs each one owns (REQ-001).
##
## Water and land are mechanically distinct — that distinction is Pillar 2 and
## the answer to "why is this not a cute skin on generic platformer mechanics."
## The verb sets are declared here rather than inferred from branches inside
## `_physics_process`, so a test can assert each grammar supports exactly its own
## verbs and a world can query what is available without reading internals.

enum Grammar {
	WATER,
	LAND,
}

## Every player verb. DASH is deliberately outside both per-grammar sets below:
## it works in either grammar, which is what makes it read as the transition
## skill binding the two together rather than a generic ability.
enum Verb {
	SWIM,        ## full 3D directional movement
	DIVE,
	BUBBLE_BOOST,
	WADDLE,      ## grounded locomotion
	HOP,
	CLIMB,
	GRAPPLE,
	DASH,
}

const WATER_VERBS: Array[Verb] = [Verb.SWIM, Verb.DIVE, Verb.BUBBLE_BOOST]
const LAND_VERBS: Array[Verb] = [Verb.WADDLE, Verb.HOP, Verb.CLIMB]

## Usable in both grammars.
const UNIVERSAL_VERBS: Array[Verb] = [Verb.DASH, Verb.GRAPPLE]


static func verbs_for(grammar: Grammar) -> Array[Verb]:
	var out: Array[Verb] = []
	out.assign(WATER_VERBS if grammar == Grammar.WATER else LAND_VERBS)
	out.append_array(UNIVERSAL_VERBS)
	return out


static func supports(grammar: Grammar, verb: Verb) -> bool:
	return verbs_for(grammar).has(verb)


static func grammar_id(grammar: Grammar) -> String:
	return String(Grammar.keys()[grammar]).to_lower()


static func verb_id(verb: Verb) -> String:
	return String(Verb.keys()[verb]).to_lower()
