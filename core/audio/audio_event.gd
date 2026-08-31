class_name AudioEvent
extends RefCounted

## The Audio Event Interface (REQ-023).
##
## Every producer — Regeneration, the Gill Mod framework, Restoration, the
## Axolotl Controller, and world modules — sends a declared event identifier from
## the closed sets below. No producer ever knows a file path or a bus name; this
## node alone decides what an event sounds like.
##
## Keeping the sets CLOSED is what makes coverage testable: a test can assert the
## mapping from events to resolved audio is total, and injective where the
## criteria demand distinct cues. A missing mapping is a test failure rather than
## silence at runtime.

## One-shot cues. Distinctness is a checked criterion for both groups below:
## every capability loss and regrowth is distinct (AC-1), and every Gill Mod
## activation is distinct (AC-4).
enum Cue {
	CAPABILITY_LOST_TAIL,
	CAPABILITY_LOST_GILL,
	CAPABILITY_LOST_LEG,
	CAPABILITY_REGROWN_TAIL,
	CAPABILITY_REGROWN_GILL,
	CAPABILITY_REGROWN_LEG,
	GILL_MOD_BUBBLE_ACTIVATED,
	GILL_MOD_JET_ACTIVATED,
	GILL_MOD_GLOW_ACTIVATED,
}

## Looping beds. Exactly one grammar bed and one region bed play at a time;
## changing either crossfades rather than cutting.
enum Bed {
	GRAMMAR_WATER,
	GRAMMAR_LAND,
	REGION_BARREN,
	REGION_RESOURCED,
	REGION_RESTORED,
}

## Bed channels. A grammar change never disturbs the region soundscape and vice
## versa, so each occupies its own channel.
enum Channel {
	GRAMMAR,
	REGION,
}

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_EFFECTS := "Effects"

## The three independently adjustable buses (AC-6).
const BUSES: PackedStringArray = [BUS_MASTER, BUS_MUSIC, BUS_EFFECTS]

## Cues that must be mutually distinct — the capability layer (AC-1).
const CAPABILITY_CUES: Array[Cue] = [
	Cue.CAPABILITY_LOST_TAIL,
	Cue.CAPABILITY_LOST_GILL,
	Cue.CAPABILITY_LOST_LEG,
	Cue.CAPABILITY_REGROWN_TAIL,
	Cue.CAPABILITY_REGROWN_GILL,
	Cue.CAPABILITY_REGROWN_LEG,
]

## Cues that must be mutually distinct — one per MVP Gill Mod (AC-4).
const GILL_MOD_CUES: Array[Cue] = [
	Cue.GILL_MOD_BUBBLE_ACTIVATED,
	Cue.GILL_MOD_JET_ACTIVATED,
	Cue.GILL_MOD_GLOW_ACTIVATED,
]


## Stable string id for a cue, used as the bank's data key so the mapping file
## stays readable and diffable rather than depending on enum ordinals.
static func cue_id(cue: Cue) -> String:
	return String(Cue.keys()[cue]).to_lower()


static func bed_id(bed: Bed) -> String:
	return String(Bed.keys()[bed]).to_lower()


static func all_cues() -> Array[Cue]:
	var out: Array[Cue] = []
	for value: int in Cue.values():
		out.append(value as Cue)
	return out


static func all_beds() -> Array[Bed]:
	var out: Array[Bed] = []
	for value: int in Bed.values():
		out.append(value as Bed)
	return out


## The bus a cue plays on. Cues are effects; beds are music.
static func bus_for_cue(_cue: Cue) -> String:
	return BUS_EFFECTS


static func bus_for_bed(_bed: Bed) -> String:
	return BUS_MUSIC
