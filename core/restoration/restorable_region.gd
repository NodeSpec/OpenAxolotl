class_name RestorableRegion
extends RefCounted

## One region of a world, and the whole of pillar three's state (REQ-008).
##
## TWO INDEPENDENT AXES, and their independence is the design:
##
##   * `state` is the three-step progression barren -> resourced -> restored.
##   * `unlocked` is a separate boolean gating whether progression may begin.
##
## A locked region cannot leave barren however many resources are delivered
## (AC-2) — that is the Flagship's gate. A reverted region drops to barren but
## KEEPS its unlock (AC-6), so a Dredger costs the player the restoration and
## not the boss fight. Collapse the two into one enum and the second of those
## becomes impossible to express.
##
## Every transition, advancement and reversion alike, goes through
## [method _set_state]. Routing them separately is how the two drift: one path
## remembers to close the traversal gates and the other does not, and a reverted
## region keeps a route it should have lost. There is exactly one place where
## state changes and the geometry follows it.

signal state_changed(region_id: String, from: RegionState.State, to: RegionState.State)
signal unlocked_changed(region_id: String, unlocked: bool)
signal traversal_changed(region_id: String, gate_id: String, open: bool)

const STATE_FIELD := "state"
const UNLOCKED_FIELD := "unlocked"
const RESOURCES_FIELD := "resources"

var region_id: String = ""

var _state: RegionState.State = RegionState.State.BARREN
var _unlocked: bool = false
var _resources: int = 0
var _gates: Array[TraversalGate] = []


func _init(p_region_id: String = "", p_gates: Array[TraversalGate] = []) -> void:
	region_id = p_region_id
	_gates = p_gates
	_apply_gates()


# --- Queries (AC-1) ---------------------------------------------------------

func get_state() -> RegionState.State:
	return _state


func is_unlocked() -> bool:
	return _unlocked


func get_resources() -> int:
	return _resources


func is_restored() -> bool:
	return _state == RegionState.State.RESTORED


func get_gates() -> Array[TraversalGate]:
	return _gates.duplicate()


func get_open_gate_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for gate: TraversalGate in _gates:
		if gate.is_open():
			out.append(gate.gate_id)
	return out


# --- The Flagship's gate ----------------------------------------------------

## Sets the unlocked flag. Returns true when it actually changed, so a caller
## emits a cue for a real unlock rather than for every re-assertion.
func set_unlocked(unlocked: bool) -> bool:
	if _unlocked == unlocked:
		return false
	_unlocked = unlocked
	unlocked_changed.emit(region_id, unlocked)
	return true


# --- Advancement ------------------------------------------------------------

## Banks [param count] resources and advances as far as they pay for.
##
## Returns the number of states advanced, which is zero for a locked region no
## matter how much is delivered (AC-2). The resources are still banked in that
## case: the player has not wasted them, they simply cannot spend them until the
## Flagship falls.
func deliver_resources(count: int, tuning: TuningData) -> int:
	if count > 0:
		_resources += count

	if not _unlocked:
		return 0

	var advanced := 0
	while not RegionState.is_terminal(_state):
		var target := RegionState.next(_state)
		var cost := tuning.get_count(RegionState.cost_key(target))
		if _resources < cost:
			break
		_resources -= cost
		_set_state(target)
		advanced += 1
	return advanced


## The cost of the next step, or 0 when already restored. Read by the HUD to
## show progress toward the next state rather than a bare state name.
func cost_to_next(tuning: TuningData) -> int:
	if RegionState.is_terminal(_state):
		return 0
	return tuning.get_count(RegionState.cost_key(RegionState.next(_state)))


# --- Reversion (AC-5, AC-6) -------------------------------------------------

## A Dredger flattens the region back to barren.
##
## The unlock SURVIVES — that is AC-6, and it is what stops a reversion from
## silently costing the player a boss fight. The banked resources do NOT: the
## region was levelled, and the delivered material went with it. That is what
## gives the encounter its stakes rather than making it an inconvenience.
func revert_to_barren() -> bool:
	if _state == RegionState.State.BARREN:
		return false
	_resources = 0
	_set_state(RegionState.State.BARREN)
	return true


# --- The one transition path ------------------------------------------------

func _set_state(to: RegionState.State) -> void:
	var from := _state
	if from == to:
		return
	_state = to
	_apply_gates()
	state_changed.emit(region_id, from, to)


## Drives every gate to match the current state. Called on construction too, so
## a region loaded as restored comes back with its routes already open rather
## than needing a transition to re-open them.
func _apply_gates() -> void:
	for gate: TraversalGate in _gates:
		if gate.apply_state(_state):
			traversal_changed.emit(region_id, gate.gate_id, gate.is_open())


# --- Persistence (AC-4) -----------------------------------------------------

func to_dictionary() -> Dictionary:
	return {
		STATE_FIELD: RegionState.id(_state),
		UNLOCKED_FIELD: _unlocked,
		RESOURCES_FIELD: _resources,
	}


## Restores from a saved payload. The state is written as its string id rather
## than its ordinal so that reordering the enum can never silently reinterpret
## every existing save as a different state.
func from_dictionary(stored: Dictionary) -> void:
	if stored.has(UNLOCKED_FIELD):
		_unlocked = bool(stored[UNLOCKED_FIELD])
	if stored.has(RESOURCES_FIELD):
		_resources = maxi(0, int(stored[RESOURCES_FIELD]))
	if stored.has(STATE_FIELD):
		_state = RegionState.from_id(String(stored[STATE_FIELD]))
	_apply_gates()
