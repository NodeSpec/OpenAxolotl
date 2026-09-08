class_name DriftFleetSystem
extends RefCounted

## The Drift Fleet enemy runtime (REQ-012) — the antagonist faction as
## faceless industrial machinery, each enemy designed AGAINST a specific core
## system rather than being a generic damage-dealer.
##
## This node owns no enemy placement and no geometry: a world places enemies
## (or declares none — both official worlds do, deliberately), and whatever
## binds the scene calls the lanes below. Every effect flows through a seam a
## core system already publishes:
##
##   * ENTANGLE (Netbots) writes a timed factor through the Capability
##     Modifier Interface — the same object capability losses use, in its own
##     `drift:` namespace. The counter is an AFFORDANCE: contact while
##     `net_escape` is active is refused, and activating it mid-entanglement
##     releases early. The release timer lives HERE, not in the enemy, for
##     the same reason the Hookline restore timer lives in GillModSystem: a
##     despawned enemy must not strand the player debuffed forever.
##   * SNAG (Hookline Rigs) calls GillModSystem.snag() — the strip window and
##     its restore timer already live there (REQ-004 AC-6). The Glow counter
##     is a REVEAL: `is_line_revealed()` follows the `reveal_hookline`
##     affordance window, so the line is visible BEFORE it triggers and the
##     player routes around it; revealing does not disarm.
##   * DREDGE (Dredgers) calls RestorationSystem.dredger_attack() — reverting
##     traversable geometry, with the unlock surviving (REQ-008 AC-5/AC-6) —
##     and its area wipe reports through LifeSystem's catastrophic lane. That
##     lane is the ONLY way any enemy touches lives, and the registry refuses
##     a declaration naming a source outside CatastrophicSource's closed set.
##   * TOXIN AURA (Runoff Drones) publishes a vision factor and a
##     gill-recharge scale while the player is inside the volume, lingering
##     for the tuned duration after leaving. The vision factor is read by
##     presentation layers; the recharge scale is applied by whoever ticks
##     the Gill Mod system, via [method scaled_mod_delta].
##
## STRIKING BACK (REQ-012, REQ-019). Until recently every one of those lanes
## ran one way: the machines acted on the player and the player routed around
## them. A strike is now a real answer, and it lands in one of two ways.
##
## A STRIKE BELOW A MACHINE'S DURABILITY STAGGERS IT. The machine reels for a
## tuned window — its effect is refused, and whatever it was already doing to
## the player is released on the spot, so the tail whack that lands on a Netbot
## is also how you get out of its net — and then it rights itself and works
## again. Stagger is the feedback that the hit landed; it is not the win.
##
## THE STRIKE THAT REACHES ITS DURABILITY DEFEATS IT, for good. The machine
## goes inert and stays inert: every lane refuses it forever, and no tick
## brings it back. That is what makes clearing an area mean something, and it
## is the whole reason durability is worth having — a roster where every
## machine reels and returns has no fight in it, only interruptions.
##
## HOW MANY STRIKES IS THE WORLD'S DECISION, NOT THIS FILE'S. Durability is a
## field on the enemy declaration (see EnemyDef), so the Netbot goes down to a
## single whack and the Dredger takes four because their JSON says so. Reading
## it here rather than knowing it is what lets a forked world ship a machine
## with its own weight without touching the runtime.
##
## DEFEAT IS A KNOCK-OUT THAT STAYS DOWN, NOT A DESTRUCTION. These are faceless
## industrial machines and the game may not depict violence done to anything
## that reads as alive (REQ-019 AC-5). And "for good" means for the ATTEMPT:
## [method reset_defeats] puts the whole roster back on its feet, and the Game
## Client calls it on a checkpoint respawn — so a player who dies re-fights the
## stretch they died in rather than walking an emptied level.
##
## All magnitudes and windows are tuning KEYS read live at the moment of
## contact (REQ-025): retuning an enemy takes effect with no recompile.

const FACTOR_PREFIX := "drift:"
const STAGGER_SECONDS_KEY := "enemy.stagger_seconds"

## What a strike did. Returned rather than a bool because "the hit landed" and
## "the machine is down" are different events to a caller: the first wants a
## reel animation and a light cue, the second wants the node taken out of the
## scene. Collapsing them into true/false is what would make a presentation
## layer guess.
enum StrikeResult {
	## Nothing to hit: an unknown machine, or one already defeated.
	MISSED,
	## The machine reeled and will recover.
	STAGGERED,
	## The machine reached its durability and is out for the attempt.
	DEFEATED,
}

signal entangled(enemy_id: String, seconds: float)
signal entangle_escaped(enemy_id: String)
signal entangle_expired(enemy_id: String)
signal line_reveal_changed(enemy_id: String, revealed: bool)
signal region_dredged(enemy_id: String, region_id: String)
signal area_wipe_struck(enemy_id: String, life_lost: bool)
signal aura_entered(enemy_id: String)
signal aura_cleared(enemy_id: String)
signal enemy_staggered(enemy_id: String, kind: String, seconds: float)
signal enemy_recovered(enemy_id: String)
signal enemy_defeated(enemy_id: String, kind: String)
signal defeats_reset()

## Semantic audio event id, emitted on every effect an enemy lands. Never a
## file path; the Audio System resolves it (REQ-023).
signal audio_cue_requested(cue_id: String)

var _tuning: TuningData
var _registry: EnemyRegistry

var _modifiers: CapabilityModifiers = null
var _mods: GillModSystem = null
var _restoration: RestorationSystem = null
var _lives: LifeSystem = null

## enemy_id -> remaining seconds of the active entanglement.
var _entangles: Dictionary = {}

## enemy_id -> remaining LINGER seconds; INF while the player is inside.
var _auras: Dictionary = {}

## snag-behavior enemy_id -> whether its line is currently revealed.
var _revealed: Dictionary = {}

## enemy_id -> remaining seconds of the stagger a strike landed.
var _staggered: Dictionary = {}

## enemy_id -> strikes taken so far, short of its durability. Cleared when the
## machine goes down, because a defeated machine has no partial damage left to
## remember.
var _damage: Dictionary = {}

## enemy_id -> true for every machine out for this attempt. A separate set from
## _damage rather than a count that reached durability: "defeated" is a state
## every lane asks about on every call, and a set lookup says it plainly.
var _defeated: Dictionary = {}


func _init(tuning: TuningData, registry: EnemyRegistry) -> void:
	_tuning = tuning
	_registry = registry


# --- Wiring (installed by the Game Client) -----------------------------------

func set_capability_modifiers(modifiers: CapabilityModifiers) -> void:
	_modifiers = modifiers


func set_gill_mods(mods: GillModSystem) -> void:
	_mods = mods


func set_restoration(restoration: RestorationSystem) -> void:
	_restoration = restoration


func set_life_system(lives: LifeSystem) -> void:
	_lives = lives


func get_registry() -> EnemyRegistry:
	return _registry


# --- AC-1: entangle, and its affordance counter ------------------------------

## Ghost-net contact. Returns true when the entanglement lands: refused when
## the counter affordance is ACTIVE (the Jet window is the escape), when this
## enemy already has one running (a net cannot extend its own window), or when
## the behavior does not entangle.
func contact(enemy_id: String) -> bool:
	var def := _registry.get_enemy(enemy_id)
	if def == null or is_inert(enemy_id):
		return false

	match def.behavior:
		EnemyDef.Behavior.ENTANGLE:
			return _entangle(def)
		EnemyDef.Behavior.SNAG:
			return _snag(def)
		_:
			# Dredge and aura effects have their own lanes below; plain
			# contact with those machines is an ordinary non-event.
			return false


func _entangle(def: EnemyDef) -> bool:
	if _entangles.has(def.id):
		return false
	if _counter_active(def.escape_affordance):
		return false

	var seconds := _tuning.get_number(def.duration_key)
	_entangles[def.id] = seconds
	if _modifiers != null:
		_modifiers.set_factor(entangle_factor_id(def.id),
			_tuning.get_number(def.factor_key), def.target)

	entangled.emit(def.id, seconds)
	audio_cue_requested.emit(def.audio_cue_id)
	return true


func _snag(def: EnemyDef) -> bool:
	if _mods == null or not _mods.snag():
		return false
	audio_cue_requested.emit(def.audio_cue_id)
	return true


func _counter_active(affordance: String) -> bool:
	return _mods != null and not affordance.is_empty() \
		and _mods.has_affordance(affordance)


func is_entangled() -> bool:
	return not _entangles.is_empty()


func _release_entangle(enemy_id: String, escaped: bool) -> void:
	_entangles.erase(enemy_id)
	if _modifiers != null:
		_modifiers.clear_factor(entangle_factor_id(enemy_id))
	if escaped:
		entangle_escaped.emit(enemy_id)
	else:
		entangle_expired.emit(enemy_id)


static func entangle_factor_id(enemy_id: String) -> String:
	return "%sentangle:%s" % [FACTOR_PREFIX, enemy_id]


# --- Striking back -----------------------------------------------------------

## A strike landed on [param enemy_id]. Returns what it did.
##
## RELEASING THE ACTIVE EFFECT IS THE POINT, not a tidy-up, and it happens on
## BOTH outcomes. A Netbot whose net survived the whack that knocked it over
## would make the strike a thing you do after the danger rather than about it;
## releasing means the swing is both the answer to being caught and the reason
## to aim for the machine instead of swimming around it. A stagger that left
## the net on would be a hit the player cannot feel.
##
## A STAGGERED MACHINE CAN BE HIT AGAIN, and that is the difference between
## this and the window it replaced. Chaining strikes while a machine reels is
## how a durability-4 Dredger goes down in one exchange instead of four
## separate approaches; refusing them would make toughness mean "wait" rather
## than "keep going". What is refused is a strike on a machine already
## defeated, which is a swing at nothing.
func strike(enemy_id: String, kind: String = "") -> StrikeResult:
	var def := _registry.get_enemy(enemy_id)
	if def == null or is_defeated(enemy_id):
		return StrikeResult.MISSED

	var taken := int(_damage.get(enemy_id, 0)) + 1
	_release_everything(enemy_id)

	if taken >= def.durability:
		_damage.erase(enemy_id)
		_staggered.erase(enemy_id)
		_defeated[enemy_id] = true
		enemy_defeated.emit(enemy_id, kind)
		return StrikeResult.DEFEATED

	var seconds := _tuning.get_number(STAGGER_SECONDS_KEY)
	_damage[enemy_id] = taken
	# Re-set rather than accumulated: a second hit lands the machine back at a
	# full reel, so a player who keeps swinging keeps it down. Adding the
	# windows together would let a fast player bank a stagger longer than the
	# fight.
	_staggered[enemy_id] = seconds
	enemy_staggered.emit(enemy_id, kind, seconds)
	return StrikeResult.STAGGERED


## Stops whatever [param enemy_id] is currently doing to the player. Shared by
## both strike outcomes, because a hit that landed must be felt either way.
func _release_everything(enemy_id: String) -> void:
	if _entangles.has(enemy_id):
		_release_entangle(enemy_id, true)
	if _auras.has(enemy_id):
		_auras.erase(enemy_id)
		aura_cleared.emit(enemy_id)


## Whether [param enemy_id] cannot act right now — reeling from a strike, or
## out for the attempt. Every effect lane asks this first, so a struck machine
## is inert rather than merely quiet.
func is_inert(enemy_id: String) -> bool:
	return _staggered.has(enemy_id) or _defeated.has(enemy_id)


## Whether [param enemy_id] is reeling and will recover.
func is_staggered(enemy_id: String) -> bool:
	return _staggered.has(enemy_id)


## Whether [param enemy_id] is out for the rest of this attempt.
func is_defeated(enemy_id: String) -> bool:
	return _defeated.has(enemy_id)


func stagger_remaining(enemy_id: String) -> float:
	return float(_staggered.get(enemy_id, 0.0))


## Strikes [param enemy_id] has taken and survived. Zero once it is defeated —
## a machine that is down has no partial damage left to carry.
func strikes_taken(enemy_id: String) -> int:
	return int(_damage.get(enemy_id, 0))


## How many more strikes [param enemy_id] has in it, or 0 when it is already
## down. Published so a presentation layer can show wear without duplicating
## the arithmetic — and so a world author can check the ladder they declared.
func strikes_remaining(enemy_id: String) -> int:
	var def := _registry.get_enemy(enemy_id)
	if def == null or is_defeated(enemy_id):
		return 0
	return maxi(0, def.durability - strikes_taken(enemy_id))


## Puts the whole roster back on its feet.
##
## Called by whatever binds the scene on a checkpoint respawn. Defeat lasting
## "for good" has to mean for the ATTEMPT and not for the save, or a player who
## dies once walks the rest of the level unopposed — which is the same failure
## the old recover-on-a-timer model was avoiding, arrived at from the other
## side. Partial damage goes with it: a Dredger you got to three hits is a
## fresh Dredger after you die, because the run that wore it down is over.
func reset_defeats() -> void:
	if _defeated.is_empty() and _damage.is_empty() and _staggered.is_empty():
		return
	_defeated.clear()
	_damage.clear()
	_staggered.clear()
	defeats_reset.emit()


## Every machine currently out for this attempt.
func defeated_ids() -> Array[String]:
	var ids: Array[String] = []
	for enemy_id: String in _defeated:
		ids.append(enemy_id)
	return ids


# --- AC-2: the reveal half of the Hookline counter ---------------------------

## Whether [param enemy_id]'s line is revealed right now. Follows the reveal
## affordance's ACTIVE window; state changes are also emitted from tick() so a
## presentation layer can subscribe instead of polling.
func is_line_revealed(enemy_id: String) -> bool:
	var def := _registry.get_enemy(enemy_id)
	if def == null or def.behavior != EnemyDef.Behavior.SNAG:
		return false
	return _counter_active(def.reveal_affordance)


# --- AC-3: the Dredger's two attacks -----------------------------------------

## Reverts [param region_id] to barren through the restoration system —
## closing real traversable geometry, with the region's unlock surviving.
func strike_region(enemy_id: String, region_id: String) -> bool:
	var def := _registry.get_enemy(enemy_id)
	if def == null or def.behavior != EnemyDef.Behavior.DREDGE:
		return false
	if is_inert(enemy_id):
		return false
	if _restoration == null or not _restoration.dredger_attack(region_id):
		return false

	region_dredged.emit(def.id, region_id)
	audio_cue_requested.emit(def.audio_cue_id)
	return true


## The area wipe — the ONLY enemy lane that can cost a life, and only because
## the declaration names a source LifeSystem's closed set recognises. Any
## other behavior calling this is refused before the life system is asked.
func area_wipe(enemy_id: String) -> bool:
	var def := _registry.get_enemy(enemy_id)
	if def == null or def.behavior != EnemyDef.Behavior.DREDGE:
		return false
	if _lives == null or is_inert(enemy_id):
		return false

	var lost := _lives.report_catastrophe(def.area_wipe_source)
	area_wipe_struck.emit(def.id, lost)
	if lost:
		audio_cue_requested.emit(def.audio_cue_id)
	return lost


# --- AC-4: the Runoff Drone toxin aura ---------------------------------------

## The player entered [param enemy_id]'s toxin volume. Debuffs hold while
## inside and linger for the tuned duration after leaving.
func enter_aura(enemy_id: String) -> bool:
	var def := _registry.get_enemy(enemy_id)
	if def == null or def.behavior != EnemyDef.Behavior.TOXIN_AURA:
		return false
	# A knocked-over drone is not venting. Refusing entry here rather than
	# clearing it later is what stops the player walking back into the volume
	# of the machine they just disabled and being debuffed by it anyway.
	if is_inert(enemy_id):
		return false

	var fresh := not _auras.has(enemy_id)
	_auras[enemy_id] = INF
	if fresh:
		aura_entered.emit(def.id)
		audio_cue_requested.emit(def.audio_cue_id)
	return true


func exit_aura(enemy_id: String) -> bool:
	if not _auras.has(enemy_id) or not is_inf(float(_auras[enemy_id])):
		return false
	var def := _registry.get_enemy(enemy_id)
	_auras[enemy_id] = _tuning.get_number(def.duration_key)
	return true


## The composed vision factor from every active aura. 1.0 when clear; a
## presentation layer multiplies visibility/fog by this.
func vision_factor() -> float:
	var product := 1.0
	for enemy_id: String in _auras:
		product *= _tuning.get_number(
			_registry.get_enemy(enemy_id).vision_factor_key)
	return product


## The composed gill-recharge scale from every active aura. 1.0 when clear.
func gill_recharge_scale() -> float:
	var product := 1.0
	for enemy_id: String in _auras:
		product *= _tuning.get_number(
			_registry.get_enemy(enemy_id).recharge_factor_key)
	return product


## The delta the Gill Mod system should be ticked with: scaled down while a
## toxin aura holds AND the mod is recharging. Only the COOLING phase slows —
## the aura debuffs recharge, not the active window the player already opened.
func scaled_mod_delta(delta: float) -> float:
	if _mods == null or not _mods.is_cooling():
		return delta
	return delta * gill_recharge_scale()


func has_active_aura() -> bool:
	return not _auras.is_empty()


# --- The frame ---------------------------------------------------------------

func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	for enemy_id: String in _entangles.keys():
		var def := _registry.get_enemy(enemy_id)
		# The counter works mid-entanglement too: opening the escape window
		# frees the player immediately rather than waiting out the net.
		if def != null and _counter_active(def.escape_affordance):
			_release_entangle(enemy_id, true)
			continue
		var remaining := float(_entangles[enemy_id]) - delta
		if remaining <= 0.0:
			_release_entangle(enemy_id, false)
		else:
			_entangles[enemy_id] = remaining

	for enemy_id: String in _auras.keys():
		var remaining := float(_auras[enemy_id])
		if is_inf(remaining):
			continue  # Still inside the volume.
		remaining -= delta
		if remaining <= 0.0:
			_auras.erase(enemy_id)
			aura_cleared.emit(enemy_id)
		else:
			_auras[enemy_id] = remaining

	# Only STAGGER counts down. A defeated machine is not in this dictionary at
	# all, which is what makes "for good" a property of the data rather than a
	# timer somebody has to remember not to start.
	for enemy_id: String in _staggered.keys():
		var left := float(_staggered[enemy_id]) - delta
		if left <= 0.0:
			_staggered.erase(enemy_id)
			enemy_recovered.emit(enemy_id)
		else:
			_staggered[enemy_id] = left

	for enemy_id: String in _registry.get_ids():
		var def := _registry.get_enemy(enemy_id)
		if def.behavior != EnemyDef.Behavior.SNAG:
			continue
		var revealed := _counter_active(def.reveal_affordance)
		if revealed != bool(_revealed.get(enemy_id, false)):
			_revealed[enemy_id] = revealed
			line_reveal_changed.emit(enemy_id, revealed)
