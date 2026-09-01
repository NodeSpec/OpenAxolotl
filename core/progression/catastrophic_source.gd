class_name CatastrophicSource
extends RefCounted

## The CLOSED set of things that may cost a life (REQ-003 AC-1, AC-2).
##
## Four members, enumerated from the requirement verbatim. Everything else in the
## game — every enemy, every ordinary hazard, every capability loss — is outside
## this set by construction rather than by anyone remembering to check.
##
## Two criteria rest on this being closed, and they pull in opposite directions:
## AC-1 says lives decrement ONLY from these, AC-2 says ordinary contact NEVER
## decrements. A single enumeration satisfies both at once, and it makes the
## negative criterion testable as an exhaustive allowlist instead of as a handful
## of spot checks that would miss the enemy added next month.
##
## The string lane exists because enemies and hazards identify themselves by id
## across an interface, not by passing a GDScript enum. `from_id` is the gate:
## an unrecognised id resolves to UNKNOWN and the life system refuses it. The
## typed lane (`Kind`) is for callers inside core, where the compiler can check.

enum Kind {
	PIT_VOLUME,
	CRUSH_HAZARD,
	BOSS_FINISHER,
	DREDGER_AREA_WIPE,
}

const ALL: Array[Kind] = [
	Kind.PIT_VOLUME,
	Kind.CRUSH_HAZARD,
	Kind.BOSS_FINISHER,
	Kind.DREDGER_AREA_WIPE,
]

## Returned by from_id for anything outside the set. Deliberately not a member of
## Kind: there is no such thing as an "unknown catastrophe", only a source that
## is not catastrophic.
const UNKNOWN := -1


static func id(kind: Kind) -> String:
	return String(Kind.keys()[kind]).to_lower()


static func all_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for kind: Kind in ALL:
		out.append(id(kind))
	return out


## Resolves a source id from the interface. Returns UNKNOWN for anything not in
## the closed set — which is every ordinary enemy and hazard in the game.
##
## Exact match only. A prefix or substring rule would let "pit_volume_decoration"
## through, and the whole value of a closed set is that widening it takes an edit
## to this file rather than a lucky string.
static func from_id(source_id: String) -> int:
	for kind: Kind in ALL:
		if id(kind) == source_id:
			return int(kind)
	return UNKNOWN


static func is_catastrophic(source_id: String) -> bool:
	return from_id(source_id) != UNKNOWN
