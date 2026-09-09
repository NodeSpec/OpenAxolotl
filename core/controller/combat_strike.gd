class_name CombatStrike
extends RefCounted

## What the axolotl can hit a Drift Fleet machine with (REQ-012, REQ-019).
##
## THREE STRIKES, ONE PER THING THE PLAYER ALREADY KNOWS HOW TO DO. None of
## them is a new button pretending to be a weapon:
##
##   TAIL_WHACK   the land strike. A swing of the longest part of the animal,
##                from a standing position, with a reach to match.
##   STOMP        landing on a machine from above. The oldest verb in the
##                genre and the first thing a player tries; it costs a hop
##                they already had, and pays a bounce back off it.
##   SPIN_SPRINT  the water strike, which is also the water dodge. The body
##                becomes the attack because underwater there is nothing to
##                plant your feet against and swing from.
##
## WHAT A STRIKE DOES, and this is a design decision worth stating rather than
## burying: it KNOCKS A MACHINE OUT for a while. It does not destroy it, it
## does not damage it, and nothing has hit points. The Drift Fleet are faceless
## industrial machinery (REQ-012) and the game may not depict violence done to
## anything that reads as alive (REQ-019 AC-5) — a knocked-over machine that
## rights itself is both of those constraints honoured, and it keeps a level
## replayable instead of letting a player empty it once and walk it unopposed
## forever after.
##
## The strike itself is deliberately a plain value with no scene in it. The
## controller opens a window and says how far it reaches; whatever owns the
## scene decides which machines are inside that reach. That split is the same
## one the grapple already uses for anchor discovery, and it is what lets the
## whole combat lane be tested without a physics world.

enum Kind {
	TAIL_WHACK,
	STOMP,
	SPIN_SPRINT,
}

## Tuning keys for each kind's reach. The reach is the ONLY spatial fact a
## strike carries: everything else about where it lands is the position of the
## body at the moment the window is open.
const REACH_KEYS: Dictionary = {
	Kind.TAIL_WHACK: "combat.tail_whack.reach_m",
	Kind.STOMP: "combat.stomp.reach_m",
	Kind.SPIN_SPRINT: "combat.spin_sprint.reach_m",
}

## The grammar each strike belongs to. A land strike underwater and a water
## strike on dry land are both refused, which is the movement grammars' own
## rule applied to combat rather than a second rule invented for it.
const GRAMMAR: Dictionary = {
	Kind.TAIL_WHACK: MovementGrammar.Grammar.LAND,
	Kind.STOMP: MovementGrammar.Grammar.LAND,
	Kind.SPIN_SPRINT: MovementGrammar.Grammar.WATER,
}


static func kind_id(kind: Kind) -> String:
	return String(Kind.keys()[kind]).to_lower()


static func reach_key(kind: Kind) -> String:
	return String(REACH_KEYS[kind])


static func grammar_for(kind: Kind) -> MovementGrammar.Grammar:
	return GRAMMAR[kind] as MovementGrammar.Grammar


## Whether [param kind] is usable in [param grammar]. Asked by the controller
## before a window opens, so a strike that could not land never opens one and
## never spends a cooldown.
static func allowed_in(kind: Kind, grammar: MovementGrammar.Grammar) -> bool:
	return grammar_for(kind) == grammar
