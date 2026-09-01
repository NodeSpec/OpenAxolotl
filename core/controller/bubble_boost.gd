class_name BubbleBoost
extends RefCounted

## The bubble boost — the water grammar's burst verb (REQ-001 AC-2).
##
## The criterion is not "a boost exists" but "a boost GOVERNED BY A COOLDOWN",
## so the cooldown is modelled as an explicit state rather than as a timestamp
## comparison scattered through the controller. Three states, one timer: a boost
## is either usable, running, or recovering, and there is no fourth case where a
## caller can smuggle a second activation in.
##
## The tuned cooldown minimum is deliberately above zero (see tuning.json). A
## tuning file that zeroed it would produce a boost that is nominally governed
## and actually spammable — exactly the failure this criterion guards against —
## so the range refuses to load it at all.

const DURATION_KEY := "controller.bubble_boost.duration_s"
const COOLDOWN_KEY := "controller.bubble_boost.cooldown_s"
const SPEED_MULTIPLIER_KEY := "controller.bubble_boost.speed_multiplier"

enum State {
	READY,     ## usable now
	ACTIVE,    ## boosting; speed_multiplier() is above 1.0
	COOLING,   ## recovering; activation is refused
}

var _tuning: TuningData
var _state: State = State.READY
var _remaining: float = 0.0

## Capability scaling on the ACTIVE duration, authored by the Regeneration and
## Capability System (capability.gill_loss.boost_duration_multiplier) and merely
## consumed here. The cooldown is deliberately NOT scaled: losing a gill should
## shorten the payoff, not also shorten the penalty.
var _duration_scale: float = 1.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning


func duration_seconds() -> float:
	return _tuning.get_number(DURATION_KEY) * _duration_scale


func cooldown_seconds() -> float:
	return _tuning.get_number(COOLDOWN_KEY)


func set_duration_scale(scale: float) -> void:
	_duration_scale = maxf(0.0, scale)


func get_state() -> State:
	return _state


func is_active() -> bool:
	return _state == State.ACTIVE


func is_ready() -> bool:
	return _state == State.READY


func is_cooling() -> bool:
	return _state == State.COOLING


## Seconds left in whichever phase is running; 0.0 while READY.
func get_remaining() -> float:
	return _remaining


## Starts a boost. Returns false while ACTIVE or COOLING so the caller can play a
## denied cue rather than the boost silently not happening — the same contract
## the dash uses for an unavailable charge.
func try_activate() -> bool:
	if _state != State.READY:
		return false
	_state = State.ACTIVE
	_remaining = duration_seconds()
	return true


## Advances the timer. Overshoot CARRIES: a long frame that outlasts the active
## window spends the surplus against the cooldown instead of discarding it, so
## the cooldown a player experiences is the tuned number at any frame rate.
func tick(delta: float) -> void:
	if delta <= 0.0 or _state == State.READY:
		return

	_remaining -= delta
	while _remaining <= 0.0:
		if _state == State.ACTIVE:
			_state = State.COOLING
			_remaining += cooldown_seconds()
			if cooldown_seconds() <= 0.0:
				break
		else:
			break

	if _remaining <= 0.0:
		_state = State.READY
		_remaining = 0.0


## The swim speed multiplier to apply this frame. Exactly 1.0 outside an active
## boost, so the caller multiplies unconditionally and never branches on state.
func speed_multiplier() -> float:
	return _tuning.get_number(SPEED_MULTIPLIER_KEY) if _state == State.ACTIVE else 1.0


## Cancels a boost and starts the cooldown. Used when the axolotl leaves water
## mid-boost: the boost is a water verb, and letting it run on land would hand
## the player a land speed burst the land grammar never granted.
func interrupt() -> void:
	if _state != State.ACTIVE:
		return
	_state = State.COOLING
	_remaining = cooldown_seconds()
	if _remaining <= 0.0:
		_state = State.READY
		_remaining = 0.0
