class_name RegenSystem
extends CapabilityRestorer

## The Regeneration and Capability System (REQ-002, REQ-019) — Pillar 1.
##
## Damage strips a capability. It never drains anything, and it never ends a run.
## That second half is the single most important boundary in the game's design,
## and this class defends it STRUCTURALLY rather than by promising:
##
##   * There is no health value here, in any spelling, anywhere in this node.
##   * There is no signal, method or return path by which this system could
##     report a death, spend a life, or request a reset. A test walks the signal
##     and method lists and fails on the vocabulary.
##   * A catastrophic hit is REFUSED, not handled. Catastrophe belongs to the
##     Lives and Checkpoint System, and the only way the two layers cannot
##     quietly merge is for this one to be unable to express the other's outcome.
##   * Modifiers compose multiplicatively from positive factors, so "everything
##     lost" degrades traversal without reaching zero. The never-fatal property
##     falls out of the arithmetic instead of being rescued by a clamp.
##
## This node never touches the controller's internals. It publishes factors
## through the Capability Modifier Interface and emits semantic audio events; who
## consumes them and what they sound like is not its business.
##
## Extends CapabilityRestorer, the port the Lives and Checkpoint System declares
## for the one thing it needs here: restore_all() on a checkpoint respawn. The
## consumer declares the port and the provider implements it, the same shape the
## Audio system uses for its settings store — so Lives can be tested against a
## fake, and the real RegenSystem is passed straight in with no adapter.

const MUTATION_DURATION_KEY := "regen.mutation.duration_s"

## Namespace for every factor this system owns. publish_to() clears only these,
## so it can refresh its own contribution without dropping factors another
## system put on the same object.
const FACTOR_PREFIX := "regen:"

signal capability_lost(kind: Capability.Kind)
signal capability_restored(kind: Capability.Kind)

## Both channels for one event, emitted together so a listener cannot wire the
## visual and forget the audio (REQ-019 AC-2).
signal feedback_requested(cue: FeedbackCue)

signal mutation_applied(loadout_id: String)
signal mutation_expired(loadout_id: String)

var _tuning: TuningData
var _state: CapabilityState
var _mutation: MutationLoadout = null

## Time the current loadout has been running.
##
## ELAPSED, not a countdown. Decrementing a remaining-time float leaves residue:
## ticking 19.99 then 0.01 against a 20-second duration lands on 1e-15 rather
## than 0, and the mutation survives a frame past its tuned duration. Summing
## upward and comparing against the duration puts the residue on the other side
## of the comparison, where it expires on time instead of late. Reading the
## duration at comparison time also means retuning it mid-mutation takes effect,
## which matches how every other value in this project is read.
var _mutation_elapsed: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_state = CapabilityState.new()


# --- Taking damage ----------------------------------------------------------

## Applies one hit. Returns true when a capability was actually stripped.
##
## Returns FALSE, changing nothing, when the event is catastrophic: that is the
## Lives layer's event and this system declines it rather than translating it
## into some maximal capability loss. Also false when the named capability is
## already gone, so a second hit in the same spot does not re-pop the same tail.
func apply_damage(event: DamageEvent) -> bool:
	if event == null or event.catastrophic:
		return false
	if not _state.lose(event.capability):
		return false

	capability_lost.emit(event.capability)
	feedback_requested.emit(FeedbackTable.capability_cue(event.capability, true))
	return true


# --- Restoring --------------------------------------------------------------

## Regen station use, and the entry the Lives and Checkpoint System calls on a
## checkpoint respawn. Returns how many capabilities were actually regrown.
##
## This node does NOT watch for respawns itself — it exposes this and waits to be
## told. A system that listened for respawns would need to know the Lives
## system's signals, which is a dependency the architecture does not declare and
## a second place for the two layers to entangle.
##
## Ending any active mutation is part of "fully restored": a checkpoint returns
## the axolotl to its BASE configuration, and leaving a mutation running would
## mean respawning as something other than yourself.
func restore_all() -> int:
	_end_mutation()

	var restored := _state.restore_all()
	for kind: Capability.Kind in restored:
		capability_restored.emit(kind)
		feedback_requested.emit(FeedbackTable.capability_cue(kind, false))
	return restored.size()


func restore(kind: Capability.Kind) -> bool:
	if not _state.restore(kind):
		return false
	capability_restored.emit(kind)
	feedback_requested.emit(FeedbackTable.capability_cue(kind, false))
	return true


# --- Mutation loadouts ------------------------------------------------------

func mutation_duration() -> float:
	return _tuning.get_number(MUTATION_DURATION_KEY)


## Applies a temporary loadout. Replacing a running one restarts the timer rather
## than stacking, so a player standing at a station cannot accumulate mutations.
func apply_mutation(loadout: MutationLoadout) -> bool:
	if loadout == null or loadout.id.is_empty() or loadout.is_empty():
		return false

	_mutation = loadout
	_mutation_elapsed = 0.0
	mutation_applied.emit(loadout.id)
	return true


## Advances the mutation timer. THIS NODE owns the revert, not the station that
## handed the loadout out: a world that despawns its station mid-loadout — or a
## player who walks into the next region — must not be stranded in a mutated
## configuration forever.
func tick(delta: float) -> void:
	if _mutation == null or delta <= 0.0:
		return

	_mutation_elapsed += delta
	if _mutation_elapsed >= mutation_duration():
		_end_mutation()


func _end_mutation() -> void:
	if _mutation == null:
		return
	var ended := _mutation.id
	_mutation = null
	_mutation_elapsed = 0.0
	mutation_expired.emit(ended)


func get_active_mutation() -> MutationLoadout:
	return _mutation


func has_mutation() -> bool:
	return _mutation != null


func get_mutation_remaining() -> float:
	if _mutation == null:
		return 0.0
	return maxf(0.0, mutation_duration() - _mutation_elapsed)


func get_mutation_elapsed() -> float:
	return _mutation_elapsed


# --- The Capability Modifier Interface --------------------------------------

## The composed multiplier for one target: every lost capability that degrades
## it, times any mutation factor for it.
##
## Strictly positive for any combination of losses, because every input is a
## positive tuned multiplier and the composition is a product. That is the
## arithmetic REQ-002 AC-3 rests on.
func modifier_for(target: CapabilityModifiers.Target) -> float:
	var product := 1.0

	for kind: Capability.Kind in Capability.ALL:
		if _state.is_lost(kind) and Capability.modifier_target(kind) == target:
			product *= _tuning.get_number(Capability.modifier_key(kind))

	if _mutation != null:
		product *= _mutation.factor_for(target)

	return product


## Writes this system's factors onto the object the controller reads.
##
## Clears only its OWN namespace first, so the published set is always current —
## a regrown tail's factor cannot linger — while a factor some other system put
## on the same object survives untouched.
func publish_to(modifiers: CapabilityModifiers) -> void:
	if modifiers == null:
		return

	for factor_id: String in modifiers.get_factor_ids():
		if factor_id.begins_with(FACTOR_PREFIX):
			modifiers.clear_factor(factor_id)

	for kind: Capability.Kind in Capability.ALL:
		if not _state.is_lost(kind):
			continue
		modifiers.set_factor(
			loss_factor_id(kind),
			_tuning.get_number(Capability.modifier_key(kind)),
			Capability.modifier_target(kind))

	if _mutation != null:
		for target: int in _mutation.get_targets():
			modifiers.set_factor(
				mutation_factor_id(target),
				_mutation.factor_for(target as CapabilityModifiers.Target),
				target as CapabilityModifiers.Target)


static func loss_factor_id(kind: Capability.Kind) -> String:
	return "%sloss:%s" % [FACTOR_PREFIX, Capability.id(kind)]


static func mutation_factor_id(target: int) -> String:
	return "%smutation:%d" % [FACTOR_PREFIX, target]


# --- The HUD State Interface ------------------------------------------------

func get_state() -> CapabilityState:
	return _state


func is_lost(kind: Capability.Kind) -> bool:
	return _state.is_lost(kind)


func count_lost() -> int:
	return _state.count_lost()


func is_fully_intact() -> bool:
	return _state.is_fully_intact()
