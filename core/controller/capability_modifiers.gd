class_name CapabilityModifiers
extends RefCounted

## Multiplicative movement factors the controller CONSUMES but never authors
## (REQ-001, REQ-002, Capability Modifier Interface).
##
## The Regeneration and Capability System owns which capabilities are lost; this
## node only asks "what should my swim speed be multiplied by right now". Keeping
## authorship out of the controller is what stops capability loss logic leaking
## into movement code, and it is why a world can never desync from the capability
## system by reading a stale copy.
##
## Factors are TARGETED. REQ-002 requires three genuinely different effects — a
## lost tail slows swimming, a lost gill shortens the bubble boost, a lost leg
## lowers the climb ceiling — so a single global multiplier cannot express the
## criterion: it would make a lost leg slow the player's swimming, which is not
## what the loss means. Target.ALL is the default and applies everywhere, so a
## caller that does not care about targeting behaves exactly as before.
##
## Multiplicative, not additive, so several simultaneous losses compose without
## any one of them being able to drive a factor negative. That composition is
## also what makes REQ-002's never-fatal criterion structurally true rather than
## defended by a clamp: a product of positive factors is always positive, so
## "every capability lost" degrades traversal without ever reaching zero.

## What a factor affects. ALL is deliberately first so it is the zero value and
## therefore the natural default.
enum Target {
	ALL,
	SWIM_SPEED,
	WADDLE_SPEED,
	BOOST_DURATION,
	CLIMB_HEIGHT,
}

const _VALUE := "value"
const _TARGET := "target"

var _factors: Dictionary = {}


## Sets one named factor. Values are clamped to be non-negative: a negative
## multiplier would invert movement, which is never a meaningful capability
## effect and would be a very confusing bug to chase.
func set_factor(source_id: String, value: float,
		target: Target = Target.ALL) -> void:
	_factors[source_id] = {_VALUE: maxf(0.0, value), _TARGET: int(target)}


func clear_factor(source_id: String) -> void:
	_factors.erase(source_id)


func clear_all() -> void:
	_factors.clear()


## The composed multiplier for [param target]. Factors targeting ALL always
## count; a targeted factor counts only for its own target.
##
## 1.0 when nothing applies — an intact axolotl moves at its tuned base speed
## with no special case.
func combined(target: Target = Target.ALL) -> float:
	var product := 1.0
	for key: Variant in _factors:
		var entry: Dictionary = _factors[key]
		var entry_target := int(entry[_TARGET])
		if entry_target == int(Target.ALL) or entry_target == int(target):
			product *= float(entry[_VALUE])
	return product


func has_factor(source_id: String) -> bool:
	return _factors.has(source_id)


func get_factor_target(source_id: String) -> Target:
	if not _factors.has(source_id):
		return Target.ALL
	return (_factors[source_id] as Dictionary)[_TARGET] as Target


func get_factor_value(source_id: String) -> float:
	if not _factors.has(source_id):
		return 1.0
	return float((_factors[source_id] as Dictionary)[_VALUE])


func get_factor_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key: Variant in _factors:
		out.append(String(key))
	out.sort()
	return out
