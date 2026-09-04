class_name WorldContractShape
extends RefCounted

## The contract-visible shape of a world module: the element ids a save can
## legitimately refer to (REQ-014 AC-4).
##
## Stored alongside a world's progress so a later load can tell what changed.
## Comparing the stored shape to the world's current declarations is what
## classifies a change as additive or destructive, which is what the
## save-compatibility policy acts on.

var regions: PackedStringArray = []
var collectibles: PackedStringArray = []
var checkpoints: PackedStringArray = []


static func from_dictionary(source: Dictionary) -> WorldContractShape:
	var shape := WorldContractShape.new()
	shape.regions = _sorted_ids(source.get("regions", []))
	shape.collectibles = _sorted_ids(source.get("collectibles", []))
	shape.checkpoints = _sorted_ids(source.get("checkpoints", []))
	return shape


## Accepts both Array and PackedStringArray. PackedStringArray is NOT an Array
## in GDScript, so testing only `is Array` silently yields an empty shape — and
## an empty stored shape makes every later comparison look additive, including
## the renames that must quarantine.
static func _sorted_ids(raw: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if raw is PackedStringArray:
		out = (raw as PackedStringArray).duplicate()
	elif raw is Array:
		for entry: Variant in (raw as Array):
			out.append(String(entry))
	out.sort()
	return out


## Emits plain Arrays rather than packed ones so the in-memory shape and the
## JSON round trip are byte-identical — a shape must not classify differently
## depending on whether it came from memory or from disk.
func to_dictionary() -> Dictionary:
	return {
		"regions": _as_plain_array(regions),
		"collectibles": _as_plain_array(collectibles),
		"checkpoints": _as_plain_array(checkpoints),
	}


static func _as_plain_array(ids: PackedStringArray) -> Array:
	var out: Array = []
	for id: String in ids:
		out.append(id)
	return out


## How a stored shape differs from the world's current one.
enum Change {
	NONE,        ## identical
	ADDITIVE,    ## the world only gained elements; every stored id still exists
	DESTRUCTIVE, ## an id the save may reference was removed or renamed
}


## Classifies [param current] against this stored shape.
##
## A rename is indistinguishable from a removal plus an addition at the id level,
## and deliberately so: both mean an id the save references is gone, and both
## must be treated the same way. Guessing that "reef_a" became "reef_alpha"
## would be exactly the silent wrongness the policy exists to prevent.
func classify(current: WorldContractShape) -> Change:
	var change := Change.NONE

	for field: String in ["regions", "collectibles", "checkpoints"]:
		var stored_ids: PackedStringArray = get(field)
		var current_ids: PackedStringArray = current.get(field)

		for id: String in stored_ids:
			if not current_ids.has(id):
				return Change.DESTRUCTIVE  # something the save may point at is gone

		if current_ids.size() > stored_ids.size():
			change = Change.ADDITIVE

	return change


func equals(other: WorldContractShape) -> bool:
	return classify(other) == Change.NONE and other.classify(self) == Change.NONE
