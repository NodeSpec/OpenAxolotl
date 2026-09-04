class_name CapabilityState
extends RefCounted

## Which capabilities are currently lost (REQ-002 AC-1).
##
## THERE IS NO HEALTH VALUE HERE. Not a hidden one, not a hit counter that maps
## to a loss at three, not a float that happens to be named something else. The
## criterion is "strips a specific capability RATHER THAN reducing a health
## value", and the only way to make that true rather than merely claimed is for
## there to be nothing in this file that could be decremented. A test scans the
## whole node's source for the health vocabulary and fails on a match.
##
## Three independent booleans. Order does not matter, combinations are legal, and
## the all-lost case is an ordinary state rather than a terminal one.

var _lost: Dictionary = {}


func is_lost(kind: Capability.Kind) -> bool:
	return _lost.get(kind, false)


func is_intact(kind: Capability.Kind) -> bool:
	return not is_lost(kind)


## Marks a capability lost. Returns false when it was already lost, so a caller
## can tell a real loss from a repeat hit and avoid replaying the cue — being hit
## twice in the same spot should not pop the same tail twice.
func lose(kind: Capability.Kind) -> bool:
	if is_lost(kind):
		return false
	_lost[kind] = true
	return true


## Regrows one capability. Returns false when it was already intact.
func restore(kind: Capability.Kind) -> bool:
	if not is_lost(kind):
		return false
	_lost.erase(kind)
	return true


## Regrows everything, returning what was actually restored so the caller emits
## a cue per real regrowth rather than three cues regardless.
func restore_all() -> Array[Capability.Kind]:
	var restored: Array[Capability.Kind] = []
	for kind: Capability.Kind in Capability.ALL:
		if restore(kind):
			restored.append(kind)
	return restored


func get_lost_kinds() -> Array[Capability.Kind]:
	var out: Array[Capability.Kind] = []
	for kind: Capability.Kind in Capability.ALL:
		if is_lost(kind):
			out.append(kind)
	return out


func count_lost() -> int:
	return get_lost_kinds().size()


func is_fully_intact() -> bool:
	return count_lost() == 0


func copy() -> CapabilityState:
	var out := CapabilityState.new()
	for kind: Capability.Kind in get_lost_kinds():
		out.lose(kind)
	return out
