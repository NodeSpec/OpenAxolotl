class_name CollectibleKind
extends RefCounted

## The two kinds of collectible, and the whole reason they are two (REQ-010).
##
##   * RESOURCE  — a restoration resource. SPENT: delivered to a region and
##                 consumed to advance its restoration state. Declared as a
##                 TYPE ("kelp_seed") that the scene may place any number of
##                 times, because a consumable has no identity worth
##                 persisting — the region's banked count is what persists.
##   * DISCOVERY — a rescued creature or a secret. KEPT: counted per world and
##                 persisted to the profile by id, so each declaration is one
##                 instance the scene places exactly once.
##
## A CLOSED set: a world names a kind from these ids or its declaration is
## refused. Collapsing the two into one kind would force either resources to
## carry identities or discoveries to be spendable, and both are wrong.

enum Kind {
	RESOURCE,
	DISCOVERY,
}

const UNKNOWN := -1

const _IDS: Dictionary = {
	Kind.RESOURCE: "resource",
	Kind.DISCOVERY: "discovery",
}


static func id(kind: Kind) -> String:
	return String(_IDS[kind])


## Resolves a declared kind id. Exact match only — "resources" is not a kind.
static func from_id(text: String) -> int:
	for kind: Kind in _IDS:
		if _IDS[kind] == text:
			return kind
	return UNKNOWN


static func is_known_id(text: String) -> bool:
	return from_id(text) != UNKNOWN


static func all_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for kind: Kind in _IDS:
		out.append(String(_IDS[kind]))
	return out
