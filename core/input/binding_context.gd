class_name BindingContext
extends RefCounted

## The scope a binding is active in (REQ-024 AC-2).
##
## This is the structural heart of the requirement. Water-only and land-only
## verbs "may share a physical input without conflict", which is impossible in
## one flat action map: Godot's InputMap has no notion of a binding that applies
## only while swimming. So context is a FIRST-CLASS FIELD on every binding, and
## intent resolves as (context, physical input) -> verb.
##
## The consequence that matters is in the conflict check: two bindings collide
## only when their contexts INTERSECT. W meaning swim-forward in water and
## waddle-forward on land is not a conflict and must never be reported as one,
## or the scheme the design depends on becomes impossible to configure.
##
## ANY exists for the verbs MovementGrammar calls universal — dash and grapple
## work in either grammar — plus the Gill Mod verbs, which are not grammar-bound
## at all. ANY intersects everything, so a universal verb genuinely cannot share
## an input with anything else.

enum Context {
	WATER,
	LAND,
	ANY,
}

const UNKNOWN := -1


static func context_id(context: Context) -> String:
	return String(Context.keys()[context]).to_lower()


static func from_id(id: String) -> int:
	for value: int in Context.values():
		if context_id(value as Context) == id:
			return value
	return UNKNOWN


## True when the two contexts can be active at the same moment, which is exactly
## when a shared physical input would be ambiguous.
static func intersects(a: Context, b: Context) -> bool:
	if a == Context.ANY or b == Context.ANY:
		return true
	return a == b


static func for_grammar(grammar: MovementGrammar.Grammar) -> Context:
	return Context.WATER if grammar == MovementGrammar.Grammar.WATER else Context.LAND


## True when a binding in [param context] is live while the player is in
## [param grammar].
static func admits(context: Context, grammar: MovementGrammar.Grammar) -> bool:
	return context == Context.ANY or context == for_grammar(grammar)
