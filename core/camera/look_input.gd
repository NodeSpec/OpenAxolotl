class_name LookInput
extends RefCounted

## The player's camera-look axis (REQ-005, REQ-024).
##
## THE GAP THIS CLOSES. Until now the camera's yaw simply trailed the direction
## of travel and there was no way to turn it — camera_follow.gd said so in its
## own header. In a 3D platformer that is not a missing luxury: you cannot look
## before you leap, line a gap up, or see what is beside you, so every jump is
## taken on faith. No amount of coyote time or input buffering fixes a jump the
## player could not aim, which is why the controls read as thin despite eight
## bound verbs and sixty tuning keys behind them.
##
## WHY THIS IS NOT AN INPUT VERB, since camera_follow.gd predicted it would be
## ("it lands as one more input verb feeding desired_yaw here"). The binding
## table's model is DISCRETE inputs summed into a unit direction: a key is down
## or it is not. Look is an ANALOG AXIS PAIR whose magnitude IS the signal — a
## two-pixel mouse delta and a two-hundred-pixel one are the same "verb" and
## completely different inputs. Pushing it through resolve_press would either
## quantise it to eight directions or bolt a parallel analog path into a table
## whose conflict rules are written for discrete inputs. So look reads its
## devices directly and the binding table keeps meaning one thing. The cost is
## that look is not remappable yet; that is the honest trade and it is written
## down rather than discovered later.
##
## Deliberately holds NO reference to a camera, an Input singleton or a node:
## callers push samples in and drain degrees out, which is what lets the whole
## thing be tested without a window, a mouse or a gamepad.

const MOUSE_SENSITIVITY_KEY := "camera.look.mouse_deg_per_pixel"
const STICK_SPEED_KEY := "camera.look.stick_deg_per_second"
const STICK_DEADZONE_KEY := "camera.look.stick_deadzone"
const MIN_PITCH_KEY := "camera.look.min_pitch_deg"
const MAX_PITCH_KEY := "camera.look.max_pitch_deg"
const INVERT_Y_KEY := "camera.look.invert_pitch"

## The idle assist's keys. They live here rather than in CameraFollow because
## they belong to the look axis's contract: the assist exists only to undo what
## the look axis did, and turning look off means turning these off too.
const ASSIST_DELAY_KEY := "camera.look.assist_delay_seconds"
const ASSIST_SPEED_KEY := "camera.look.assist_deg_per_second"

var _tuning: TuningData

## Degrees accumulated since the last drain: x is yaw, y is pitch.
var _pending := Vector2.ZERO


func _init(tuning: TuningData) -> void:
	_tuning = tuning


## Mouse motion, in pixels, exactly as InputEventMouseMotion reports it.
##
## Accumulated rather than applied because mouse motion arrives on the INPUT
## timeline and the camera settles on the PHYSICS one: several events can land
## between two physics frames, and a camera that acted on only the last would
## drop most of a fast flick.
func add_mouse(relative: Vector2) -> void:
	var degrees := _tuning.get_number(MOUSE_SENSITIVITY_KEY)
	# Screen-right is +x and should turn the view right, which in Godot's
	# left-handed yaw is NEGATIVE. Screen-down is +y and should look down.
	_pending.x -= relative.x * degrees
	_pending.y -= relative.y * degrees * _pitch_sign()


## A gamepad stick sample in [-1, 1] per axis, over `delta` seconds.
##
## Rate-based rather than displacement-based: a stick held at full deflection
## turns at a constant speed, which is what a stick means. The deadzone is
## applied to the VECTOR's length, not per axis, so a diagonal push does not
## need to clear the threshold twice.
func add_stick(sample: Vector2, delta: float) -> void:
	var deadzone := _tuning.get_number(STICK_DEADZONE_KEY)
	var magnitude := sample.length()
	if magnitude <= deadzone:
		return
	# Rescale from the deadzone edge so the first movement past it is slow
	# rather than a jump to full rate.
	var scaled := sample.normalized() * ((magnitude - deadzone)
		/ maxf(1.0 - deadzone, 0.0001))
	var speed := _tuning.get_number(STICK_SPEED_KEY) * delta
	_pending.x -= scaled.x * speed
	_pending.y -= scaled.y * speed * _pitch_sign()


## Take everything accumulated since the last call, in degrees (yaw, pitch).
func drain() -> Vector2:
	var out := _pending
	_pending = Vector2.ZERO
	return out


## True when the player is actively looking. The camera uses this to stop its
## own assist from fighting the hand that is steering it.
func has_pending() -> bool:
	return not _pending.is_zero_approx()


## Hold a pitch inside the tuned range.
##
## The clamp is the camera's, not the mouse's: clamping the DELTA would let
## pitch accumulate past the limit and then need the same number of pixels back
## before the view moved at all, which feels like the input has stuck.
func clamp_pitch(pitch_deg: float) -> float:
	return clampf(pitch_deg, _tuning.get_number(MIN_PITCH_KEY),
		_tuning.get_number(MAX_PITCH_KEY))


func _pitch_sign() -> float:
	return -1.0 if _tuning.get_number(INVERT_Y_KEY) >= 0.5 else 1.0
