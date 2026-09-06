class_name RegionState
extends RefCounted

## The three restoration states, and nothing else (REQ-008 AC-1).
##
## EXACTLY three: barren, resourced, restored. No intermediate, no "restoring"
## transient, and no fourth value standing in for "locked". Whether a region may
## progress at all is a SEPARATE boolean flag on the region itself, and keeping
## the two axes apart is load-bearing rather than tidy: a region reverted by a
## Dredger must drop to barren while STAYING unlocked, so the player redoes the
## restoration without refighting the Flagship (AC-6). The moment the flag is
## folded into this enum as a fourth state, that criterion becomes unsatisfiable
## — reverting would either clear the unlock or need a special case that lies
## about which state the region is in.
##
## The ordering is meaningful: a state's ordinal is its progress, which is what
## lets a traversal gate declare the state it opens at and compare rather than
## enumerate.

enum State {
	BARREN,
	RESOURCED,
	RESTORED,
}

const ALL: Array[State] = [State.BARREN, State.RESOURCED, State.RESTORED]

## Tuning keys for the cost of advancing INTO each state. Read through
## TuningData at use time and never copied into a constant (REQ-025); both are
## world-overridable, so a world may tune its own economy without touching core.
const RESOURCED_COST_KEY := "restoration.resourced.resource_cost"
const RESTORED_COST_KEY := "restoration.restored.resource_cost"


static func id(state: State) -> String:
	return String(State.keys()[state]).to_lower()


static func from_id(text: String) -> State:
	var wanted := text.strip_edges().to_lower()
	for state: State in ALL:
		if id(state) == wanted:
			return state
	return State.BARREN


static func is_known_id(text: String) -> bool:
	var wanted := text.strip_edges().to_lower()
	for state: State in ALL:
		if id(state) == wanted:
			return true
	return false


## The state after this one, or RESTORED when already there. Advancement is a
## single step so the resource cost of each step stays separately tunable.
static func next(state: State) -> State:
	return State.RESTORED if state == State.RESTORED else (state + 1) as State


static func is_terminal(state: State) -> bool:
	return state == State.RESTORED


## The tuning key holding the cost of advancing into [param state]. BARREN has
## no cost because nothing advances into it — a revert is not a purchase.
static func cost_key(state: State) -> String:
	match state:
		State.RESOURCED:
			return RESOURCED_COST_KEY
		State.RESTORED:
			return RESTORED_COST_KEY
		_:
			return ""


## The ambience this state asks for. A semantic bed id from the Audio Event
## Interface's closed set, never a file path — this node says "restored", and
## the Audio System alone decides what that sounds like (REQ-023).
static func audio_bed(state: State) -> AudioEvent.Bed:
	match state:
		State.RESOURCED:
			return AudioEvent.Bed.REGION_RESOURCED
		State.RESTORED:
			return AudioEvent.Bed.REGION_RESTORED
		_:
			return AudioEvent.Bed.REGION_BARREN
