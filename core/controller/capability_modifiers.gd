class_name CapabilityModifiers
extends RefCounted

## Multiplicative movement factors the controller CONSUMES but never authors
## (REQ-001, Capability Modifier Interface).
##
## The Regeneration and Capability System owns which capabilities are lost; this
## node only asks "what should my swim speed be multiplied by right now". Keeping
## authorship out of the controller is what stops capability loss logic leaking
## into movement code, and it is why a world can never desync from the capability
## system by reading a stale copy.
##
## Multiplicative, not additive, so several simultaneous losses compose without
## any one of them being able to drive a factor negative.

var _factors: Dictionary = {}


## Sets one named factor. Values are clamped to be non-negative: a negative
## multiplier would invert movement, which is never a meaningful capability
## effect and would be a very confusing bug to chase.
func set_factor(source_id: String, value: float) -> void:
	_factors[source_id] = maxf(0.0, value)


func clear_factor(source_id: String) -> void:
	_factors.erase(source_id)


func clear_all() -> void:
	_factors.clear()


## The composed multiplier. 1.0 when nothing is applied — an intact axolotl moves
## at its tuned base speed with no special case.
func combined() -> float:
	var product := 1.0
	for key: Variant in _factors:
		product *= float(_factors[key])
	return product


func has_factor(source_id: String) -> bool:
	return _factors.has(source_id)


func get_factor_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key: Variant in _factors:
		out.append(String(key))
	out.sort()
	return out
