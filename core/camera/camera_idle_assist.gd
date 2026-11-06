class_name CameraIdleAssist
extends RefCounted

## Idle-only framing. Never chase velocity while it is steering the player:
## movement is camera-relative, so doing that bends a held direction into a loop.
const HEADING_HOLD_SPEED := 0.25

var _tuning: TuningData
var _idle_seconds: float = 0.0
var _last_heading_deg: float = 0.0
var _has_heading: bool = false


func _init(tuning: TuningData) -> void:
	_tuning = tuning


func reset(clear_heading: bool = false) -> void:
	_idle_seconds = 0.0
	if clear_heading:
		_has_heading = false


func step(delta: float, yaw_deg: float, velocity: Vector3, looking: bool, steering: bool = false) -> float:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var moving := horizontal.length() >= HEADING_HOLD_SPEED
	if moving:
		_last_heading_deg = rad_to_deg(atan2(-horizontal.x, -horizontal.z))
		_has_heading = true
	if moving or looking or steering:
		reset()
		return yaw_deg
	if not _has_heading:
		return yaw_deg

	var delay := maxf(0.0, _tuning.get_number(LookInput.ASSIST_DELAY_KEY))
	var previous := _idle_seconds
	_idle_seconds += maxf(0.0, delta)
	# Only the part of this tick after the delay may turn. This keeps crossing
	# the delay boundary consistent across different physics step sizes.
	var active_delta := maxf(0.0, _idle_seconds - delay) - maxf(0.0, previous - delay)
	var turn := maxf(0.0, _tuning.get_number(LookInput.ASSIST_SPEED_KEY)) * active_delta
	var difference := wrapf(_last_heading_deg - yaw_deg, -180.0, 180.0)
	return wrapf(yaw_deg + clampf(difference, -turn, turn), -180.0, 180.0)
