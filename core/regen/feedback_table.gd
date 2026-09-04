class_name FeedbackTable
extends RefCounted

## The state table REQ-019 makes machine-checkable.
##
## Two halves, one per criterion:
##
## AC-2 — every capability-loss type triggers BOTH a visual and an audio cue.
## Six events (three losses, three regrowths), each with both channels filled.
##
## AC-1 — hazards, interactables and restoration state are distinguishable
## without relying on colour alone. Every state the player must tell apart is
## enumerated here with a silhouette, an icon and a label, and NO colour. A test
## asserts the enumeration is total and that glyphs and labels are unique, so a
## new hazard added without a discriminator fails CI rather than shipping as
## "the red one".
##
## Keeping this as data rather than as art metadata is what lets the test exist
## at all: a table can be walked, a shader cannot.

# --- AC-1: everything the player must tell apart ---------------------------

const HAZARDS: PackedStringArray = [
	"hazard.hookline_rig",
	"hazard.runoff_drone",
	"hazard.netbot",
	"hazard.dredger",
	"hazard.flagship",
]

const INTERACTABLES: PackedStringArray = [
	"interactable.regen_station",
	"interactable.checkpoint",
	"interactable.resource",
	"interactable.discovery",
	"interactable.portal",
	"interactable.grapple_anchor",
	"interactable.climbable",
]

const RESTORATION_STATES: PackedStringArray = [
	"restoration.barren",
	"restoration.resourced",
	"restoration.restored",
]

const _DISCRIMINATORS: Dictionary = {
	# shape, glyph, label
	"hazard.hookline_rig": ["dangling_line", "icon.hazard.hook", "Hookline Rig"],
	"hazard.runoff_drone": ["billowing_plume", "icon.hazard.plume", "Runoff Drone"],
	"hazard.netbot": ["woven_mesh", "icon.hazard.mesh", "Netbot"],
	"hazard.dredger": ["toothed_scoop", "icon.hazard.scoop", "Dredger"],
	"hazard.flagship": ["towering_hull", "icon.hazard.hull", "Flagship"],

	"interactable.regen_station": ["budding_pod", "icon.use.pod", "Regen Station"],
	"interactable.checkpoint": ["standing_reed", "icon.use.reed", "Checkpoint"],
	"interactable.resource": ["clustered_seed", "icon.pickup.seed", "Restoration Resource"],
	"interactable.discovery": ["curled_shell", "icon.pickup.shell", "Discovery"],
	"interactable.portal": ["ringed_arch", "icon.use.arch", "Portal"],
	"interactable.grapple_anchor": ["hooked_knob", "icon.use.knob", "Grapple Anchor"],
	"interactable.climbable": ["ridged_face", "icon.use.ridge", "Climbable Surface"],

	"restoration.barren": ["bare_stubble", "icon.region.stubble", "Barren"],
	"restoration.resourced": ["sprouting_shoots", "icon.region.shoots", "Resourced"],
	"restoration.restored": ["full_canopy", "icon.region.canopy", "Restored"],
}

# --- AC-2: capability feedback, both channels ------------------------------

const _LOST_VISUALS: Dictionary = {
	Capability.Kind.TAIL: ["vfx.pop_sparkle_tail",
		"cartoon POP and a puff of sparkles; the tail bounces off frame"],
	Capability.Kind.GILL: ["vfx.pop_sparkle_gill",
		"a bubble bursts with a squeak; sparkles drift upward"],
	Capability.Kind.LEG: ["vfx.pop_sparkle_leg",
		"a springy BOING; the leg cartwheels away and vanishes in glitter"],
}

const _REGROWN_VISUALS: Dictionary = {
	Capability.Kind.TAIL: ["vfx.bloom_regrow_tail",
		"the tail unfurls like a fern with a rising chime"],
	Capability.Kind.GILL: ["vfx.bloom_regrow_gill",
		"gills reinflate in a ring of tiny bubbles"],
	Capability.Kind.LEG: ["vfx.bloom_regrow_leg",
		"the leg pops back with a rubbery spring and a shower of sparks"],
}


## Every state id the player must be able to tell apart.
static func all_state_ids() -> PackedStringArray:
	var out := PackedStringArray()
	out.append_array(HAZARDS)
	out.append_array(INTERACTABLES)
	out.append_array(RESTORATION_STATES)
	return out


## The non-colour discriminator for a state. Returns null for an unknown id
## rather than a blank placeholder, so a missing entry surfaces as an absence a
## test can catch instead of an empty-looking state that renders as nothing.
static func discriminator(state_id: String) -> StateDiscriminator:
	if not _DISCRIMINATORS.has(state_id):
		return null
	var row := _DISCRIMINATORS[state_id] as Array
	return StateDiscriminator.new(
		state_id, String(row[0]), String(row[1]), String(row[2]))


## The cue for losing or regrowing [param kind]. Both channels always populated.
static func capability_cue(kind: Capability.Kind, lost: bool) -> FeedbackCue:
	var table := _LOST_VISUALS if lost else _REGROWN_VISUALS
	var row := table[kind] as Array
	var audio := Capability.lost_cue(kind) if lost else Capability.regrown_cue(kind)
	return FeedbackCue.new(
		AudioEvent.cue_id(audio), String(row[0]), audio, String(row[1]))
