class_name WaterDash
extends RefCounted

## The water-powered dash (REQ-001 AC-5) — the signature transition skill.
##
## Usable in BOTH grammars, but recharging only while submerged. That asymmetry
## is the whole design: the dash is spent anywhere and earned only in water, so
## a land route is something you plan your water time around rather than a
## separate mode. A dash that recharged on land would be a generic ability.
##
## The charge economy and the movement burst deliberately live together here.
## Before the gameplay-feel pass, consuming DASH only decremented a counter and
## never changed velocity, which satisfied the resource bookkeeping while
## violating the actual traversal intent of REQ-001. Activation now captures a
## direction, speed and duration supplied by the controller from the existing
## grammar-specific tuning surface, then drives that committed burst until the
## window expires. Crossing the waterline does NOT interrupt it: the dash is the
## transition skill, so carrying it through the seam is part of its identity.
##
## All balance values still come from tuning; this class owns no speed or timing
## constants. The controller chooses the land or water burst profile when the
## dash begins, while the charge/recharge values remain the dedicated dash keys.

const MAX_CHARGES_KEY := "controller.dash.max_charges"
const RECHARGE_SECONDS_KEY := "controller.dash.recharge_seconds_per_charge"

var _tuning: TuningData
var _charges: int = 0
var _recharge_progress: float = 0.0

var _active_remaining: float = 0.0
var _active_direction: Vector3 = Vector3.ZERO
var _active_speed: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_charges = max_charges()


func max_charges() -> int:
	return _tuning.get_count(MAX_CHARGES_KEY)


func get_charges() -> int:
	return _charges


## Spends a charge. Returns false when none are available, so a caller can play a
## "denied" cue rather than silently doing nothing. Kept public because the HUD
## and existing tests reason about the charge economy independently of motion.
func try_consume() -> bool:
	if _charges <= 0:
		return false
	_charges -= 1
	return true


## Starts the committed movement half of the dash and spends one charge.
##
## Direction is captured once, like the other burst moves: steering cannot bend
## a dash after it starts. Speed and duration are supplied from TuningData by the
## controller so this class does not invent a second balance surface. A zero
## direction, speed, or duration refuses activation WITHOUT spending a charge.
func try_activate(direction: Vector3, speed: float, duration_seconds: float) -> bool:
	if is_active() or direction.is_zero_approx() or speed <= 0.0 \
			or duration_seconds <= 0.0:
		return false
	if not try_consume():
		return false
	_active_direction = direction.normalized()
	_active_speed = speed
	_active_remaining = duration_seconds
	return true


func is_active() -> bool:
	return _active_remaining > 0.0


func get_active_remaining() -> float:
	return _active_remaining


func get_active_direction() -> Vector3:
	return _active_direction if is_active() else Vector3.ZERO


## Velocity commanded while the dash is active. Zero outside the window so the
## controller can ask unconditionally without leaking stale direction or speed.
func velocity() -> Vector3:
	return _active_direction * _active_speed if is_active() else Vector3.ZERO


## Advances recharge AND the live burst. Recharge progress accrues ONLY while in
## water; the active dash itself is grammar-agnostic and therefore survives a
## water/land boundary.
func tick(delta: float, is_in_water: bool) -> void:
	if delta <= 0.0:
		return

	if _active_remaining > 0.0:
		_active_remaining = maxf(0.0, _active_remaining - delta)
		if _active_remaining <= 0.0:
			_active_direction = Vector3.ZERO
			_active_speed = 0.0

	if not is_in_water:
		return
	if _charges >= max_charges():
		_recharge_progress = 0.0
		return

	_recharge_progress += delta
	var needed := _tuning.get_number(RECHARGE_SECONDS_KEY)
	while _recharge_progress >= needed and _charges < max_charges():
		_recharge_progress -= needed
		_charges += 1

	if _charges >= max_charges():
		_recharge_progress = 0.0


func get_recharge_progress() -> float:
	return _recharge_progress
