class_name CameraFraming
extends RefCounted

## One resolved camera framing (REQ-005).
##
## The whole of what a world is allowed to direct: how far back, what pitch, what
## yaw, and which of those the camera may not change. Keeping it a value object
## rather than state on the rig is what lets a hint be resolved, compared and
## asserted without a camera existing.

## Axes a hint can LOCK. A locked axis holds whatever the camera currently has
## rather than tracking its target — that is what "lock axis" means to a world
## author framing a tunnel: stop the camera swinging, do not teleport it.
##
## Values are bit flags so several axes lock in one integer, which is what makes
## the lock declarable as a single exported field on a hint volume.
enum Axis {
	PITCH = 1,
	YAW = 2,
	DISTANCE = 4,
}

## Metres from the axolotl to the camera.
var distance: float = 0.0

## Degrees above the axolotl. Positive pitches the camera up and looks down.
var pitch_deg: float = 0.0

## Degrees around the axolotl.
var yaw_deg: float = 0.0

## Bitwise OR of Axis values.
var locked_axes: int = 0


func _init(p_distance: float = 0.0, p_pitch_deg: float = 0.0,
		p_yaw_deg: float = 0.0, p_locked_axes: int = 0) -> void:
	distance = p_distance
	pitch_deg = p_pitch_deg
	yaw_deg = p_yaw_deg
	locked_axes = p_locked_axes


func is_locked(axis: Axis) -> bool:
	return (locked_axes & int(axis)) != 0


## RefCounted has no duplicate(), and resolving hints must never mutate the base
## framing the rig derived from tuning — otherwise one frame's hint would leak
## into the next frame's defaults.
func copy() -> CameraFraming:
	return CameraFraming.new(distance, pitch_deg, yaw_deg, locked_axes)
