class_name MutationLoadout
extends RefCounted

## A temporary alternate configuration a regen station can hand out
## (REQ-002 AC-5).
##
## This is what turns healing from a chore into a build-crafting moment: the
## station restores what you lost AND can reshape you for a while. A loadout is
## declared as targeted multipliers, the same currency capability losses use, so
## the two compose through one interface rather than through a second parallel
## system the controller would also have to learn.
##
## Multipliers here may legitimately exceed 1.0 — a mutation is usually a
## trade-up, not a debuff. That is the one place in this node where a factor
## above one is expected, and it is why nothing clamps to 1.0.

var id: String = ""

var _factors: Dictionary = {}


func _init(p_id: String = "") -> void:
	id = p_id


## Declares a multiplier for one target. Returns self so a station can declare a
## whole loadout in a single expression.
func set_factor(target: CapabilityModifiers.Target, value: float) -> MutationLoadout:
	_factors[int(target)] = maxf(0.0, value)
	return self


func has_factor(target: CapabilityModifiers.Target) -> bool:
	return _factors.has(int(target))


## 1.0 for a target this loadout says nothing about, so a caller multiplies
## unconditionally and never branches on presence.
func factor_for(target: CapabilityModifiers.Target) -> float:
	return float(_factors.get(int(target), 1.0))


func get_targets() -> Array[int]:
	var out: Array[int] = []
	for key: Variant in _factors:
		out.append(int(key))
	out.sort()
	return out


func is_empty() -> bool:
	return _factors.is_empty()
