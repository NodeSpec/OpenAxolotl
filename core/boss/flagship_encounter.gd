class_name FlagshipEncounter
extends RefCounted

## The Flagship Boss Encounter (REQ-013) — the regional set piece that ties
## boss design directly to the restoration pillar.
##
## The Flagship is the source vessel anchoring a region's Drift Fleet
## presence: the largest piece of extraction machinery, still faceless,
## still unmanned. Defeating it flips the region's restoration UNLOCKED
## flag — the boss is the gate on the restoration payoff, not a detached
## spectacle.
##
## AN ENCOUNTER IS A DECLARATION, and this class is the de-facto schema of
## the Level Contract's optional `boss` element (logged as friction F-7 —
## the shape belongs in the contract before any world declares one):
##
##   {
##     "regionId": "<the region this Flagship holds locked>",
##     "phases": [
##       {"phaseId": "hull_breach", "grammar": "water"},
##       {"phaseId": "deck_assault", "grammar": "land"},
##       {"phaseId": "core_purge", "grammar": "any",
##        "requiresAffordance": "bubble_platform"}
##     ]
##   }
##
## AC-3 AND AC-4 ARE STRUCTURAL: a declaration without at least one
## water-only phase, one land-only phase, AND one affordance-gated phase is
## REFUSED at validation with a named error — an accepted encounter cannot
## fail those criteria, and the behavior tests then prove the gates bite.
##
## Every effect flows through a seam a core system publishes, exactly like
## the Drift Fleet: ordinary attacks strip capability through
## RegenSystem.apply_damage (never a health value); the finisher reports
## BOSS_FINISHER through LifeSystem's closed catastrophic lane — the
## declaration cannot choose a different source, so an encounter cannot
## widen what costs a life; defeat calls RestorationSystem.unlock_region.
##
## CHECKPOINTS RESUME, NEVER RESTART (AC-5): the encounter listens to the
## life system it is wired to — a checkpoint activation snapshots the phase
## index, and the respawn that follows exhausted lives returns the fight to
## that snapshot. Lives and capability restoration are the life system's
## own checkpoint semantics (REQ-003); this node adds only the phase anchor.

const FIELD_REGION := "regionId"
const FIELD_PHASES := "phases"
const FIELD_PHASE_ID := "phaseId"
const FIELD_GRAMMAR := "grammar"
const FIELD_AFFORDANCE := "requiresAffordance"

const GRAMMAR_WATER := "water"
const GRAMMAR_LAND := "land"
const GRAMMAR_ANY := "any"
const GRAMMARS: PackedStringArray = [GRAMMAR_WATER, GRAMMAR_LAND, GRAMMAR_ANY]

const ATTACK_SOURCE := "flagship"

signal phase_completed(phase_id: String, index: int)
signal encounter_defeated(region_id: String)
signal attack_landed(capability: Capability.Kind)
signal finisher_landed(life_lost: bool)
signal resumed_at_phase(index: int)

var region_id: String = ""

## Each: {phaseId: String, grammar: String, requiresAffordance: String}.
var _phases: Array[Dictionary] = []

var _current: int = 0
var _checkpoint_phase: int = 0
var _defeated := false

var _regen: RegenSystem = null
var _lives: LifeSystem = null
var _restoration: RestorationSystem = null
var _mods: GillModSystem = null


# --- Validation (AC-3/AC-4's structural half) --------------------------------

static func from_declaration(declaration: Dictionary,
		out_errors: Array[FlagshipError] = []) -> FlagshipEncounter:
	var region: Variant = declaration.get(FIELD_REGION)
	if not (region is String) or String(region).is_empty():
		out_errors.append(FlagshipError.new(FlagshipError.MISSING_FIELD,
			FIELD_REGION, "a Flagship must name the region it holds locked"))
		return null

	var raw_phases: Variant = declaration.get(FIELD_PHASES)
	if not (raw_phases is Array) or (raw_phases as Array).is_empty():
		out_errors.append(FlagshipError.new(FlagshipError.MISSING_FIELD,
			FIELD_PHASES, "a Flagship must declare at least one phase"))
		return null

	var encounter := FlagshipEncounter.new()
	encounter.region_id = String(region)

	var seen: PackedStringArray = []
	var has_water := false
	var has_land := false
	var has_mod_gate := false
	for raw: Variant in (raw_phases as Array):
		if not (raw is Dictionary):
			out_errors.append(FlagshipError.new(FlagshipError.MALFORMED,
				FIELD_PHASES, "every phase must be an object"))
			return null
		var phase := raw as Dictionary
		var phase_id := String(phase.get(FIELD_PHASE_ID, ""))
		if phase_id.is_empty():
			out_errors.append(FlagshipError.new(FlagshipError.MISSING_FIELD,
				FIELD_PHASE_ID, "a phase is missing its id"))
			return null
		if seen.has(phase_id):
			out_errors.append(FlagshipError.new(FlagshipError.DUPLICATE_PHASE,
				phase_id, "phase ids must be unique — a checkpoint anchors "
				+ "to them"))
			return null
		seen.append(phase_id)

		var grammar := String(phase.get(FIELD_GRAMMAR, GRAMMAR_ANY))
		if not GRAMMARS.has(grammar):
			out_errors.append(FlagshipError.new(FlagshipError.UNKNOWN_GRAMMAR,
				phase_id, "grammar '%s' is not one of %s"
				% [grammar, str(GRAMMARS)]))
			return null
		has_water = has_water or grammar == GRAMMAR_WATER
		has_land = has_land or grammar == GRAMMAR_LAND

		var affordance := String(phase.get(FIELD_AFFORDANCE, ""))
		has_mod_gate = has_mod_gate or not affordance.is_empty()

		encounter._phases.append({
			FIELD_PHASE_ID: phase_id,
			FIELD_GRAMMAR: grammar,
			FIELD_AFFORDANCE: affordance,
		})

	# The criteria the encounter must CONTAIN are refused at the door, not
	# hoped for at runtime (AC-3, AC-4).
	if not has_water:
		out_errors.append(FlagshipError.new(FlagshipError.NO_WATER_PHASE,
			encounter.region_id, "REQ-013 AC-3: at least one phase must be "
			+ "completable only in the water grammar"))
		return null
	if not has_land:
		out_errors.append(FlagshipError.new(FlagshipError.NO_LAND_PHASE,
			encounter.region_id, "REQ-013 AC-3: at least one phase must be "
			+ "completable only in the land grammar"))
		return null
	if not has_mod_gate:
		out_errors.append(FlagshipError.new(FlagshipError.NO_MOD_GATED_PHASE,
			encounter.region_id, "REQ-013 AC-4: at least one phase must be "
			+ "gated on a Gill Mod affordance"))
		return null

	return encounter


# --- Wiring (installed by the Game Client) -----------------------------------

func set_regen(regen: RegenSystem) -> void:
	_regen = regen


## Wires the life system, and with it the resume behavior: a checkpoint
## snapshots the phase the fight has reached; the respawn after exhausted
## lives returns to that snapshot, never to phase zero (AC-5).
func set_life_system(lives: LifeSystem) -> void:
	_lives = lives
	if _lives == null:
		return
	_lives.checkpoint_activated.connect(
		func(_checkpoint_id: String) -> void:
			_checkpoint_phase = _current)
	_lives.respawned.connect(
		func(_position: Vector3, _checkpoint_id: String,
				_replenished: int) -> void:
			if _defeated:
				return
			_current = _checkpoint_phase
			resumed_at_phase.emit(_current))


func set_restoration(restoration: RestorationSystem) -> void:
	_restoration = restoration


func set_gill_mods(mods: GillModSystem) -> void:
	_mods = mods


# --- AC-1: the two attack layers ---------------------------------------------

## An ordinary attack strips a capability — the same layer every Drift Fleet
## unit fights on. Never a health value, never a life.
func ordinary_attack(capability: Capability.Kind) -> bool:
	if _regen == null:
		return false
	var landed := _regen.apply_damage(
		DamageEvent.new(ATTACK_SOURCE, capability, false))
	if landed:
		attack_landed.emit(capability)
	return landed


## A designated finishing move — one of the few catastrophic events in the
## game. The source is BOSS_FINISHER by construction: the declaration has no
## field for it, so an encounter cannot widen what costs a life.
func finisher() -> bool:
	if _lives == null:
		return false
	var lost := _lives.lose_life(CatastrophicSource.Kind.BOSS_FINISHER)
	finisher_landed.emit(lost)
	return lost


# --- AC-3/AC-4: phase progression, gated at the moment of completion ---------

## Attempts to complete the CURRENT phase. Refused when the fight is already
## won, when [param grammar] does not satisfy a grammar-locked phase, or
## when the phase's required affordance is not in an ACTIVE window on the
## wired Gill Mod system. Phases are sequential and every one is mandatory.
func complete_phase(grammar: MovementGrammar.Grammar) -> bool:
	if _defeated or _current >= _phases.size():
		return false

	var phase := _phases[_current]
	var required := String(phase[FIELD_GRAMMAR])
	if required == GRAMMAR_WATER and grammar != MovementGrammar.Grammar.WATER:
		return false
	if required == GRAMMAR_LAND and grammar != MovementGrammar.Grammar.LAND:
		return false

	var affordance := String(phase[FIELD_AFFORDANCE])
	if not affordance.is_empty():
		if _mods == null or not _mods.has_affordance(affordance):
			return false

	var phase_id := String(phase[FIELD_PHASE_ID])
	_current += 1
	phase_completed.emit(phase_id, _current - 1)

	if _current >= _phases.size():
		_defeat()
	return true


## AC-2: defeat permits restoration to BEGIN — the unlocked flag flips; the
## region's state stays wherever it was, and the resources still have to be
## earned.
func _defeat() -> void:
	_defeated = true
	if _restoration != null:
		_restoration.unlock_region(region_id)
	encounter_defeated.emit(region_id)


# --- Read-back ---------------------------------------------------------------

func is_defeated() -> bool:
	return _defeated


func phase_count() -> int:
	return _phases.size()


func get_current_phase_index() -> int:
	return _current


func get_current_phase_id() -> String:
	if _current >= _phases.size():
		return ""
	return String(_phases[_current][FIELD_PHASE_ID])


func get_checkpoint_phase_index() -> int:
	return _checkpoint_phase
