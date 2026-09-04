class_name WaterDash
extends RefCounted

## The water-powered dash (REQ-001 AC-5) — the signature transition skill.
##
## Usable in BOTH grammars, but recharging only while submerged. That asymmetry
## is the whole design: the dash is spent anywhere and earned only in water, so
## a land route is something you plan your water time around rather than a
## separate mode. A dash that recharged on land would be a generic ability.
##
## All values come from the tuning surface; nothing here is a constant.

const MAX_CHARGES_KEY := "controller.dash.max_charges"
const RECHARGE_SECONDS_KEY := "controller.dash.recharge_seconds_per_charge"

var _tuning: TuningData
var _charges: int = 0
var _recharge_progress: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_charges = max_charges()


func max_charges() -> int:
	return _tuning.get_count(MAX_CHARGES_KEY)


func get_charges() -> int:
	return _charges


## Spends a charge. Returns false when none are available, so a caller can play a
## "denied" cue rather than silently doing nothing.
func try_consume() -> bool:
	if _charges <= 0:
		return false
	_charges -= 1
	return true


## Advances recharge. Progress accrues ONLY while in water; on land the timer
## does not merely pause, it makes no progress at all, so surfacing mid-recharge
## does not bank partial credit that completes on dry land.
func tick(delta: float, is_in_water: bool) -> void:
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
