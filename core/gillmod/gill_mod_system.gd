class_name GillModSystem
extends RefCounted

## The Gill Mod runtime (REQ-004).
##
## Holds what is equipped, runs the duration and cooldown, and answers the one
## question worlds actually ask: `has_affordance("jet_dash")`. Everything a mod
## does mechanically flows through that gate, which is why a fourth mod needs no
## code here — it declares affordances and the same gate answers for it.
##
## TWO EXTERNAL FORCES MODIFY MODS, and both are timers this node owns:
##
##   * A lost gill shortens the boost. The multiplier is CONSUMED through the
##     Capability Modifier Interface and applied AT ACTIVATION — never written
##     back into the mod, which is data shared by every future activation. A mod
##     mutated by damage would stay short after the gill regrew.
##   * A Hookline Rig snag strips the equipped mod for a tuned window and then
##     restores it. That restore timer lives HERE rather than in the enemy: an
##     enemy despawned mid-snag (killed, or its region unloaded) must not be able
##     to strand the player without a mod forever.
##
## Because the multiplier is read live at activation, the interaction of the two
## falls out for free: snagged while gill-damaged and then restored, the next
## activation lands on the damaged duration, not on the base one.

enum State {
	READY,
	ACTIVE,
	COOLING,
}

const STRIP_SECONDS_KEY := "enemy.hookline.mod_strip_seconds"

signal equipped(mod_id: String)
signal unequipped(mod_id: String)

## Emitted with the mod's declared visual id, so the axolotl's appearance follows
## the equipped mod without this node knowing what a mesh is (AC-4).
signal visual_changed(visual_id: String)

signal activated(mod_id: String, duration: float)
signal expired(mod_id: String)
signal ready_again(mod_id: String)

## Semantic audio event id. Never a file path; the Audio System resolves it.
signal audio_cue_requested(cue_id: String)

signal stripped(mod_id: String, seconds: float)
signal restored(mod_id: String)

var _tuning: TuningData
var _registry: GillModRegistry
var _modifiers: CapabilityModifiers = null

var _equipped: GillMod = null
var _state: State = State.READY
var _remaining: float = 0.0

## The mod a Hookline snag took, held here so it can be handed back.
var _stripped_mod: GillMod = null
var _strip_remaining: float = 0.0


func _init(tuning: TuningData, registry: GillModRegistry) -> void:
	_tuning = tuning
	_registry = registry


## Installed by the Game Client. Absent, the boost runs at its full tuned
## duration — an unwired capability system means no damage, not no mods.
func set_capability_modifiers(modifiers: CapabilityModifiers) -> void:
	_modifiers = modifiers


# --- AC-4: equipping and switching ------------------------------------------

## Equips a registered mod. Player-available and callable at any time; switching
## mid-cooldown is allowed, and the new mod arrives READY rather than inheriting
## the old one's cooldown — a cooldown belongs to a use, not to the slot.
##
## Refused while stripped: a Hookline snag has taken the slot, and letting the
## player equip around it would make the snag a non-event.
func equip(mod_id: String) -> bool:
	if is_stripped():
		return false

	var mod := _registry.get_mod(mod_id)
	if mod == null:
		return false
	if _equipped != null and _equipped.id == mod_id:
		return true

	_equipped = mod
	_state = State.READY
	_remaining = 0.0

	equipped.emit(mod.id)
	visual_changed.emit(mod.visual_id)
	return true


func unequip() -> void:
	if _equipped == null:
		return
	var previous := _equipped.id
	_equipped = null
	_state = State.READY
	_remaining = 0.0
	unequipped.emit(previous)
	visual_changed.emit("")


func get_equipped() -> GillMod:
	return _equipped


func get_equipped_id() -> String:
	return "" if _equipped == null else _equipped.id


func has_equipped() -> bool:
	return _equipped != null


# --- AC-5: activation, and the gill-loss multiplier -------------------------

## The tuned duration for the equipped mod, after capability modifiers.
##
## Read at call time from the live modifier object rather than cached: a gill
## stripped between activations must shorten the very next one.
func effective_duration() -> float:
	if _equipped == null:
		return 0.0
	var base := _tuning.get_number(_equipped.duration_key)
	if _modifiers == null:
		return base
	return base * _modifiers.combined(CapabilityModifiers.Target.BOOST_DURATION)


func cooldown_seconds() -> float:
	if _equipped == null:
		return 0.0
	return _tuning.get_number(_equipped.cooldown_key)


## Activates the equipped mod. Returns false when nothing is equipped, when the
## slot is stripped, or when the mod is still running or cooling — so a caller
## can play a denied cue rather than the activation silently doing nothing.
func activate() -> bool:
	if _equipped == null or is_stripped() or _state != State.READY:
		return false

	_state = State.ACTIVE
	_remaining = effective_duration()

	activated.emit(_equipped.id, _remaining)
	audio_cue_requested.emit(_equipped.audio_cue_id)
	return true


func is_active() -> bool:
	return _state == State.ACTIVE


func is_ready() -> bool:
	return _state == State.READY


func is_cooling() -> bool:
	return _state == State.COOLING


func get_state() -> State:
	return _state


func get_remaining() -> float:
	return _remaining


# --- AC-1: the affordance gate ----------------------------------------------

## True when the equipped mod is ACTIVE and grants [param affordance].
##
## Active rather than merely equipped: every mod carries a duration and a
## cooldown, so its affordance is a window the player opens, not a permanent
## upgrade. A world gates a path on this and needs to know nothing else about
## Gill Mods at all.
func has_affordance(affordance: String) -> bool:
	if _equipped == null or _state != State.ACTIVE:
		return false
	return _equipped.grants(affordance)


## Affordances the equipped mod would grant if activated. For the HUD, which
## shows what is available rather than what is running right now.
func get_available_affordances() -> PackedStringArray:
	if _equipped == null:
		return PackedStringArray()
	return _equipped.affordances.duplicate()


# --- AC-6: the Hookline Rig snag --------------------------------------------

func strip_seconds() -> float:
	return _tuning.get_number(STRIP_SECONDS_KEY)


## A Hookline Rig snag. Takes the equipped mod for the tuned window; tick()
## hands it back. Returns false when there was nothing to take or a snag is
## already running, so a rig cannot extend its own window by re-snagging.
func snag() -> bool:
	if _equipped == null or is_stripped():
		return false

	_stripped_mod = _equipped
	_strip_remaining = strip_seconds()

	_equipped = null
	_state = State.READY
	_remaining = 0.0

	stripped.emit(_stripped_mod.id, _strip_remaining)
	visual_changed.emit("")
	return true


func is_stripped() -> bool:
	return _stripped_mod != null


func get_strip_remaining() -> float:
	return _strip_remaining


func get_stripped_mod_id() -> String:
	return "" if _stripped_mod == null else _stripped_mod.id


func _restore_stripped() -> void:
	if _stripped_mod == null:
		return

	var returning := _stripped_mod
	_stripped_mod = null
	_strip_remaining = 0.0

	_equipped = returning
	_state = State.READY
	_remaining = 0.0

	restored.emit(returning.id)
	equipped.emit(returning.id)
	visual_changed.emit(returning.visual_id)


# --- The frame --------------------------------------------------------------

## Advances both timers.
##
## Overshoot CARRIES from the active window into the cooldown, for the same
## reason the bubble boost does it: a long frame must not shorten the cooldown a
## player experiences below the tuned number.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	if _stripped_mod != null:
		_strip_remaining -= delta
		if _strip_remaining <= 0.0:
			_restore_stripped()
		return

	if _state == State.READY or _equipped == null:
		return

	_remaining -= delta
	while _remaining <= 0.0:
		if _state == State.ACTIVE:
			_state = State.COOLING
			expired.emit(_equipped.id)
			var cooldown := cooldown_seconds()
			_remaining += cooldown
			if cooldown <= 0.0:
				break
		else:
			break

	if _remaining <= 0.0 and _state == State.COOLING:
		_state = State.READY
		_remaining = 0.0
		ready_again.emit(_equipped.id)


# --- The HUD State Interface ------------------------------------------------

func get_hud_icon() -> String:
	return "" if _equipped == null else _equipped.hud_icon


func get_registry() -> GillModRegistry:
	return _registry
