class_name TongueGrapple
extends RefCounted

## Tongue grapple anchor resolution (REQ-001 AC-4).
##
## Range comes from the tuning surface and is tested INCLUSIVELY: an anchor
## exactly at max range attaches, one beyond it is rejected. The criterion says
## "at or within", and an off-by-a-hair exclusive test would make the documented
## number a lie at exactly the distance a player aims for.
##
## Anchor discovery is a group query plus a line-of-sight check, never a
## proximity scan of the whole scene — a scan is O(scene) every frame and would
## happily attach through a wall.

const MAX_RANGE_KEY := "controller.grapple.max_range_m"
const ANCHOR_GROUP := "grapple_anchor"

var _tuning: TuningData
var _attached_anchor: Variant = null


func _init(tuning: TuningData) -> void:
	_tuning = tuning


func max_range() -> float:
	return _tuning.get_number(MAX_RANGE_KEY)


## True when an anchor at [param distance] is attachable. Inclusive at the bound.
func is_in_range(distance: float) -> bool:
	return distance <= max_range()


## Picks the nearest in-range anchor from candidates already filtered by group
## and line of sight. [param candidates] maps an anchor id to its distance.
##
## Returns an empty string when nothing is reachable — the caller plays a miss
## rather than the grapple silently doing nothing.
func resolve_anchor(candidates: Dictionary) -> String:
	var best_id := ""
	var best_distance := INF

	for key: Variant in candidates:
		var distance := float(candidates[key])
		if not is_in_range(distance):
			continue
		if distance < best_distance:
			best_distance = distance
			best_id = String(key)

	return best_id


## Attaches to a resolved anchor. Attaching to an empty id is a no-op so a missed
## grapple cannot leave the controller believing it is attached.
func attach(anchor_id: String) -> bool:
	if anchor_id.is_empty():
		return false
	_attached_anchor = anchor_id
	return true


func detach() -> void:
	_attached_anchor = null


func is_attached() -> bool:
	return _attached_anchor != null


func get_attached_anchor() -> String:
	return "" if _attached_anchor == null else String(_attached_anchor)
