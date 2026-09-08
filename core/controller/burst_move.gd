class_name BurstMove
extends RefCounted

## A committed burst: a fixed window it drives the body through, then a rest
## before it can be asked for again (REQ-001).
##
## Two verbs have exactly this shape and neither of them is the bubble boost —
## the land ROLL and the water SPIN SPRINT. Both take the body over for a
## tuned duration, both send it somewhere the player chose at the moment they
## pressed, and both make the player wait afterwards. Writing them twice would
## have been two copies of the same three-state timer drifting apart, so the
## timer is here and the two differ only in which tuning keys they read.
##
## WHY THE DIRECTION IS STORED RATHER THAN READ EACH FRAME, which is the whole
## difference between a burst and a fast walk: the direction is captured on the
## frame the burst starts and does not change. A roll you can steer is a
## sprint, and a dodge you can steer is not a dodge — the commitment is what
## makes the timing of it a decision. It is also what makes the animation
## honest: the model rolls about the axis it is actually travelling along.
##
## The BubbleBoost next door is the same three states with a different job, and
## the two stay separate on purpose: the boost is a MULTIPLIER on steering the
## player keeps doing, this REPLACES steering for its window.

enum State {
	READY,     ## usable now
	ACTIVE,    ## driving; direction() is the committed heading
	COOLING,   ## resting; activation is refused
}

var _tuning: TuningData
var _speed_key: String
var _duration_key: String
var _cooldown_key: String

var _state: State = State.READY
var _remaining: float = 0.0
var _direction: Vector3 = Vector3.ZERO


func _init(tuning: TuningData, speed_key: String, duration_key: String,
		cooldown_key: String) -> void:
	_tuning = tuning
	_speed_key = speed_key
	_duration_key = duration_key
	_cooldown_key = cooldown_key


func speed() -> float:
	return _tuning.get_number(_speed_key)


func duration_seconds() -> float:
	return _tuning.get_number(_duration_key)


func cooldown_seconds() -> float:
	return _tuning.get_number(_cooldown_key)


func get_state() -> State:
	return _state


func is_active() -> bool:
	return _state == State.ACTIVE


func is_ready() -> bool:
	return _state == State.READY


func is_cooling() -> bool:
	return _state == State.COOLING


func get_remaining() -> float:
	return _remaining


## The heading committed to at activation. Zero while not active.
func get_direction() -> Vector3:
	return _direction


## The velocity to drive with this frame. Zero outside an active burst, so a
## caller can ask unconditionally and never branch on state.
func velocity() -> Vector3:
	return _direction * speed() if _state == State.ACTIVE else Vector3.ZERO


## Starts a burst along [param direction]. Refused while ACTIVE or COOLING —
## and refused for a direction of zero, because a burst with no heading is a
## spent cooldown that moved nothing, which reads to the player as the button
## being broken.
func try_activate(direction: Vector3) -> bool:
	if _state != State.READY or direction.is_zero_approx():
		return false
	_state = State.ACTIVE
	_remaining = duration_seconds()
	_direction = direction.normalized()
	return true


## Advances the timer. Overshoot CARRIES from the active window into the
## cooldown, so the rest a player experiences is the tuned number at any frame
## rate — the same rule the bubble boost's timer follows.
func tick(delta: float) -> void:
	if delta <= 0.0 or _state == State.READY:
		return

	_remaining -= delta
	while _remaining <= 0.0:
		if _state == State.ACTIVE:
			_state = State.COOLING
			_direction = Vector3.ZERO
			_remaining += cooldown_seconds()
			if cooldown_seconds() <= 0.0:
				break
		else:
			break

	if _remaining <= 0.0:
		_state = State.READY
		_remaining = 0.0
		_direction = Vector3.ZERO


## Cuts a burst short and starts its rest. Used when the grammar changes under
## it: a roll must not carry on into water, and a spin sprint must not carry on
## onto land, for the same reason the bubble boost is interrupted there — each
## belongs to one grammar, and a burst that outlives its grammar hands the
## player a speed the other grammar never granted.
func interrupt() -> void:
	if _state != State.ACTIVE:
		return
	_direction = Vector3.ZERO
	_state = State.COOLING
	_remaining = cooldown_seconds()
	if _remaining <= 0.0:
		_state = State.READY
		_remaining = 0.0
