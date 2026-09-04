class_name TongueGrapple
extends RefCounted

## Tongue grapple: discovery, range, attachment and the pull (REQ-001 AC-4).
##
## Range comes from the tuning surface and is tested INCLUSIVELY: an anchor
## exactly at max range attaches, one beyond it is rejected. The criterion says
## "at or within", and an off-by-a-hair exclusive test would make the documented
## number a lie at exactly the distance a player aims for.
##
## Discovery is a group query plus a line-of-sight ray, in that order and with the
## range filter between them (see AnchorSource). The criterion's third clause —
## "pulls the axolotl to the attached anchor" — is the pull below: attaching
## without moving would satisfy the first two clauses and still leave the verb
## doing nothing, which is precisely the gap this file has to not have.

const MAX_RANGE_KEY := "controller.grapple.max_range_m"
const PULL_SPEED_KEY := "controller.grapple.pull_speed_m_per_s"
const ARRIVAL_RADIUS_KEY := "controller.grapple.arrival_radius_m"

## The group a world tags anchor nodes with. Membership IS the tag.
const ANCHOR_GROUP := "grapple_anchor"

var _tuning: TuningData
var _anchor: GrappleAnchor = null


func _init(tuning: TuningData) -> void:
	_tuning = tuning


func max_range() -> float:
	return _tuning.get_number(MAX_RANGE_KEY)


func pull_speed() -> float:
	return _tuning.get_number(PULL_SPEED_KEY)


func arrival_radius() -> float:
	return _tuning.get_number(ARRIVAL_RADIUS_KEY)


## True when an anchor at [param distance] is attachable. Inclusive at the bound.
func is_in_range(distance: float) -> bool:
	return distance <= max_range()


## The nearest anchor that is in the group, within range, and in line of sight.
## Returns null when nothing qualifies — the caller plays a miss rather than the
## grapple silently doing nothing.
##
## Range is filtered BEFORE the ray so an out-of-reach anchor across the level
## never costs a physics query, and the nearest-first ordering means the ray
## budget is spent on the anchors most likely to win.
func find_anchor(origin: Vector3, source: AnchorSource) -> GrappleAnchor:
	if source == null:
		return null

	var reachable: Array[GrappleAnchor] = []
	for anchor: GrappleAnchor in source.query_anchors_in_group(ANCHOR_GROUP):
		if is_in_range(origin.distance_to(anchor.position)):
			reachable.append(anchor)

	reachable.sort_custom(func(a: GrappleAnchor, b: GrappleAnchor) -> bool:
		return origin.distance_to(a.position) < origin.distance_to(b.position))

	for anchor: GrappleAnchor in reachable:
		if source.has_line_of_sight(origin, anchor.position):
			return anchor

	return null


## Attaches to a resolved anchor. Attaching to null is a no-op so a missed grapple
## cannot leave the controller believing it is attached.
func attach(anchor: GrappleAnchor) -> bool:
	if anchor == null or anchor.id.is_empty():
		return false
	_anchor = anchor
	return true


func detach() -> void:
	_anchor = null


func is_attached() -> bool:
	return _anchor != null


func get_attached_anchor() -> String:
	return "" if _anchor == null else _anchor.id


func get_anchor_position() -> Vector3:
	return Vector3.ZERO if _anchor == null else _anchor.position


## True once the body is inside the tuned arrival radius. Without a radius the
## pull would overshoot and oscillate around the anchor forever, since the
## velocity is constant rather than damped.
func has_arrived(from: Vector3) -> bool:
	if _anchor == null:
		return false
	return from.distance_to(_anchor.position) <= arrival_radius()


## Velocity that carries the body toward the anchor. Constant speed straight down
## the tongue: the tongue is taut, so the pull does not steer, and a player who
## fires it commits to the arc. Vector3.ZERO when detached or already arrived.
func pull_velocity(from: Vector3) -> Vector3:
	if _anchor == null or has_arrived(from):
		return Vector3.ZERO
	return (_anchor.position - from).normalized() * pull_speed()
