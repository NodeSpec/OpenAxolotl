class_name TraversalGate
extends RefCounted

## A path that restoration opens (REQ-008 AC-3).
##
## The criterion is that advancing state "changes traversable geometry or opens
## paths that were not previously available, NOT ONLY VISUALS". This class is
## how that is made true structurally rather than promised: a region cannot be
## declared without at least one gate, so there is no way to author a region
## whose restoration is a material swap.
##
## Note what is deliberately absent: there is no colour, material, mesh or
## particle field here. If one existed it would eventually become the whole
## implementation of a state change, and pillar three would quietly degrade into
## a reskin. Art rides along on the transition signal; it is not what the
## transition IS.
##
## This is a PORT. The base tracks the open/closed boolean so the system can be
## driven and asserted with no scene tree and no physics server, which is what
## keeps the criteria testable under GdUnit4. A scene subclass overrides
## [method _apply_open] to toggle the real CollisionShape3D and
## NavigationRegion3D.

var gate_id: String = ""

## The state at which this path becomes traversable. Comparing ordinals rather
## than enumerating states is what lets a region open some routes at RESOURCED
## and more at RESTORED without a branch per combination.
var opens_at: RegionState.State = RegionState.State.RESTORED

var _open: bool = false

## Whether the open/closed value has ever been pushed to the scene side.
##
## This exists because the scene's defaults do not agree with a gate's. A
## NavigationRegion3D is `enabled` by default while a new gate is CLOSED, so a
## gate that only pushed on change would leave a barren region's navmesh live
## from the moment it loaded — the route walkable by every Drift Fleet unit
## before the player has restored anything. The first application is therefore
## unconditional, whatever the value.
var _applied: bool = false


func _init(p_gate_id: String = "",
		p_opens_at: RegionState.State = RegionState.State.RESTORED) -> void:
	gate_id = p_gate_id
	opens_at = p_opens_at


func is_open() -> bool:
	return _open


## True when [param state] has reached this gate's threshold.
func should_open_at(state: RegionState.State) -> bool:
	return int(state) >= int(opens_at)


## Drives the gate to match [param state]. Returns true when the open/closed
## value actually changed, so a caller can tell a real traversal change from a
## no-op re-application — the difference between "restoring opened a path" and
## "restoring was re-announced".
func apply_state(state: RegionState.State) -> bool:
	return set_open(should_open_at(state))


## Returns whether the open/closed VALUE changed, which is what a caller emits a
## traversal signal for. That is deliberately not the same question as whether
## the scene was written to: the first application always pushes, but it is not
## a transition and must not be announced as one.
func set_open(open: bool) -> bool:
	var value_changed := _open != open
	if value_changed or not _applied:
		_open = open
		_applied = true
		_apply_open(open)
	return value_changed


## Overridden by the scene-side gate to enable or disable collision and
## navigation. The base does nothing, so a system driven without a scene still
## tracks state correctly instead of failing.
func _apply_open(_open_now: bool) -> void:
	pass
