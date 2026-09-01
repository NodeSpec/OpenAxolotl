class_name Capability
extends RefCounted

## The three capabilities and what losing each one costs (REQ-002).
##
## There is no fourth thing here and no ordering between them: they are
## INDEPENDENT flags, not stages of a health bar being worked through. A design
## where losing the tail led to losing the gill led to death would be a health
## bar wearing three names, which is exactly what Pillar 1 rejects.
##
## Each kind declares its own tuning key and its own modifier TARGET, and those
## targets are deliberately all different — swim speed, boost duration, climb
## height. That is the whole of REQ-002 AC-2, and it is why the Capability
## Modifier Interface had to learn about targets: one global multiplier would
## make a lost leg slow the player's swimming, which is not what a leg is for.

enum Kind {
	TAIL,
	GILL,
	LEG,
}

const ALL: Array[Kind] = [Kind.TAIL, Kind.GILL, Kind.LEG]

const TAIL_MODIFIER_KEY := "capability.tail_loss.swim_speed_multiplier"
const GILL_MODIFIER_KEY := "capability.gill_loss.boost_duration_multiplier"
const LEG_MODIFIER_KEY := "capability.leg_loss.climb_height_multiplier"


static func id(kind: Kind) -> String:
	return String(Kind.keys()[kind]).to_lower()


## The tuning key holding this loss's multiplier. Read through TuningData at use
## time; never copied into a constant here (REQ-025).
static func modifier_key(kind: Kind) -> String:
	match kind:
		Kind.TAIL:
			return TAIL_MODIFIER_KEY
		Kind.GILL:
			return GILL_MODIFIER_KEY
		_:
			return LEG_MODIFIER_KEY


## What this loss degrades. Three kinds, three distinct targets — asserted by a
## test, because two kinds sharing a target would quietly collapse the criterion.
static func modifier_target(kind: Kind) -> CapabilityModifiers.Target:
	match kind:
		Kind.TAIL:
			return CapabilityModifiers.Target.SWIM_SPEED
		Kind.GILL:
			return CapabilityModifiers.Target.BOOST_DURATION
		_:
			return CapabilityModifiers.Target.CLIMB_HEIGHT


## Semantic audio event for losing this capability. A semantic id, never a file
## path: this node does not know what anything sounds like (REQ-023).
static func lost_cue(kind: Kind) -> AudioEvent.Cue:
	match kind:
		Kind.TAIL:
			return AudioEvent.Cue.CAPABILITY_LOST_TAIL
		Kind.GILL:
			return AudioEvent.Cue.CAPABILITY_LOST_GILL
		_:
			return AudioEvent.Cue.CAPABILITY_LOST_LEG


static func regrown_cue(kind: Kind) -> AudioEvent.Cue:
	match kind:
		Kind.TAIL:
			return AudioEvent.Cue.CAPABILITY_REGROWN_TAIL
		Kind.GILL:
			return AudioEvent.Cue.CAPABILITY_REGROWN_GILL
		_:
			return AudioEvent.Cue.CAPABILITY_REGROWN_LEG
