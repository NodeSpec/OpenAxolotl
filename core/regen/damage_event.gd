class_name DamageEvent
extends RefCounted

## What an enemy or hazard sends when it hits the axolotl (REQ-002 AC-1).
##
## Note what is NOT here: no amount, no magnitude, no damage value of any kind.
## A hit NAMES the capability it strips. That is the criterion — "strips a
## specific capability rather than reducing a health value" — expressed as a type
## rather than as a promise, and a test asserts by reflection that this class
## declares exactly these three fields and nothing resembling a quantity.
##
## `catastrophic` is the boundary to the Lives layer, and it is a flag rather
## than a large damage number for the same reason: a threshold would make the two
## layers one layer with a cutoff in it. A catastrophic event is refused by this
## system outright and belongs to the Lives and Checkpoint System.

## Who hit us — an enemy id, a hazard id. For cues and telemetry, never parsed
## for meaning.
var source_id: String = ""

## Which capability this hit strips.
var capability: Capability.Kind = Capability.Kind.TAIL

## True for the rare run-ending events (a Flagship finisher, a crush hazard).
## The Regeneration system REFUSES these rather than handling them, so the two
## layers cannot quietly merge.
var catastrophic: bool = false


func _init(p_source_id: String = "",
		p_capability: Capability.Kind = Capability.Kind.TAIL,
		p_catastrophic: bool = false) -> void:
	source_id = p_source_id
	capability = p_capability
	catastrophic = p_catastrophic
