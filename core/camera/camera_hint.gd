class_name CameraHint
extends RefCounted

## A world's declarative framing override (REQ-005 AC-3).
##
## A hint overrides ONLY the fields it declares. That partial-override shape is
## the point: a tunnel hint that pulls the camera in must not also silently reset
## the pitch a boss-arena hint set, and a world author who wanted to change one
## number should not have to restate the other three to avoid clobbering them.
##
## Every field is data. There is no callback, no script hook and no way for a
## world to run camera code — which is what keeps camera control inside the
## sanctioned world API surface (REQ-020) rather than becoming an escape hatch.

const FIELD_DISTANCE := "distance"
const FIELD_PITCH := "pitch_deg"
const FIELD_YAW := "yaw_deg"
const FIELD_LOCKED_AXES := "locked_axes"

## Stable identity. Also the tie-break when two hints share a priority, so the
## resolved framing never depends on which way the player walked in.
var id: String = ""

## Higher wins. Declared by the world, never inferred from enter order.
var priority: int = 0

var _overrides: Dictionary = {}


func _init(p_id: String = "", p_priority: int = 0) -> void:
	id = p_id
	priority = p_priority


# --- Declaring overrides ----------------------------------------------------
# Each returns self so a volume can declare a hint in one expression.

func set_distance(value: float) -> CameraHint:
	_overrides[FIELD_DISTANCE] = value
	return self


func set_pitch_deg(value: float) -> CameraHint:
	_overrides[FIELD_PITCH] = value
	return self


func set_yaw_deg(value: float) -> CameraHint:
	_overrides[FIELD_YAW] = value
	return self


func set_locked_axes(value: int) -> CameraHint:
	_overrides[FIELD_LOCKED_AXES] = value
	return self


func overrides(field: String) -> bool:
	return _overrides.has(field)


func get_overridden_fields() -> PackedStringArray:
	var out := PackedStringArray()
	for key: Variant in _overrides:
		out.append(String(key))
	out.sort()
	return out


## Writes this hint's declared fields onto [param framing], leaving everything
## else exactly as it was.
func apply_to(framing: CameraFraming) -> void:
	if _overrides.has(FIELD_DISTANCE):
		framing.distance = float(_overrides[FIELD_DISTANCE])
	if _overrides.has(FIELD_PITCH):
		framing.pitch_deg = float(_overrides[FIELD_PITCH])
	if _overrides.has(FIELD_YAW):
		framing.yaw_deg = float(_overrides[FIELD_YAW])
	if _overrides.has(FIELD_LOCKED_AXES):
		framing.locked_axes = int(_overrides[FIELD_LOCKED_AXES])
