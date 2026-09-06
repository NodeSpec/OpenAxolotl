class_name HeroSquash
extends RefCounted

## Squash and stretch for the hero's visual (REQ-019's comedic register,
## applied to motion): a hop stretches the model tall and thin, a landing
## squashes it short and wide, and both recover to rest within a fraction of
## a second. Pure arithmetic on one number, so it is testable without a scene
## and the body only has to multiply the model's scale by what `step` returns.
##
## The deformation is VOLUME-PRESERVING: a stretch of s along y is paired
## with 1 / sqrt(1 + s) along x and z, so the axolotl never looks like it
## gained or lost mass — the toy reads as rubber, not as a balloon.
##
## Physics never sees this. The capsule is untouched; only the Model child
## scales, exactly like facing.

const HOP_STRETCH_KEY := "controller.squash.hop_stretch"
const LAND_SQUASH_KEY := "controller.squash.land_squash"
const RECOVER_RATE_KEY := "controller.squash.recover_rate_per_s"

## Below this the deformation snaps to rest, so a scale of 1.0000001 never
## lingers as a floating-point tail.
const REST_EPSILON := 0.002

var _tuning: TuningData
## Signed: positive stretches along y, negative squashes.
var _deform: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning


func on_hop() -> void:
	_deform = _tuning.get_number(HOP_STRETCH_KEY)


func on_land() -> void:
	_deform = -_tuning.get_number(LAND_SQUASH_KEY)


func get_deform() -> float:
	return _deform


func is_at_rest() -> bool:
	return is_zero_approx(_deform)


## Advances the recovery and returns the scale MULTIPLIER for this frame,
## Vector3.ONE at rest.
func step(delta: float) -> Vector3:
	if _deform != 0.0:
		_deform *= exp(-_tuning.get_number(RECOVER_RATE_KEY) * delta)
		if absf(_deform) < REST_EPSILON:
			_deform = 0.0
	var tall := 1.0 + _deform
	var wide := 1.0 / sqrt(tall)
	return Vector3(wide, tall, wide)
