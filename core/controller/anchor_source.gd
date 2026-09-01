class_name AnchorSource
extends RefCounted

## The port through which the grapple discovers anchors (REQ-001 AC-4).
##
## Discovery is a GROUP QUERY plus a LINE-OF-SIGHT RAY, split into two methods
## here because they are two different costs: the group query is O(anchors in the
## group), and the ray is cast only against the handful that already passed the
## range filter. A proximity scan of the whole scene would be O(scene) every
## frame AND would happily attach through a wall; both failures are structural,
## so the interface makes the cheap, correct order the only order available.
##
## The base class grants NOTHING: no anchors, no line of sight. A half-wired
## source therefore produces a missed grapple, never a free one.

## Anchors currently in [param group]. The group is the tag — membership is what
## makes a node an anchor, not its name or its class.
func query_anchors_in_group(_group: String) -> Array[GrappleAnchor]:
	var none: Array[GrappleAnchor] = []
	return none


## True when nothing solid sits between the two points. Called only for anchors
## already inside the tuned range, so a distant scene never costs a ray.
func has_line_of_sight(_from: Vector3, _to: Vector3) -> bool:
	return false
