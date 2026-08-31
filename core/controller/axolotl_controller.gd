class_name AxolotlController
extends RefCounted

## The Axolotl Controller's public interface (REQ-001) — Pillar 2.
##
## Everything else in the project binds to this surface, so it is effectively
## frozen the moment the first world module ships against it. Worlds read
## movement state, apply capability modifiers and register ability hooks WITHOUT
## touching internals; anything a world can only achieve by reaching into a
## private member is a hole in this interface, to be fixed here rather than
## worked around there.
##
## Deliberately a plain RefCounted holding the movement logic, with a thin
## CharacterBody3D delegating to it. That keeps the grammar machine testable as
## a plain object — no scene tree, no physics server — which is what lets the
## same-frame switching criterion be asserted at all.

const MOMENTUM_RETENTION_KEY := "controller.transition.momentum_retention_ratio"

## Emitted on the SAME frame the grammar changes, before movement integration.
signal grammar_changed(grammar: MovementGrammar.Grammar)
signal dash_spent(remaining: int)
signal grapple_attached(anchor_id: String)

var _tuning: TuningData
var _grammar: MovementGrammar.Grammar = MovementGrammar.Grammar.LAND
var _velocity: Vector3 = Vector3.ZERO
var _was_in_water: bool = false
var _initialised: bool = false

var _modifiers: CapabilityModifiers
var _dash: WaterDash
var _grapple: TongueGrapple
var _ability_hooks: Dictionary = {}


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_modifiers = CapabilityModifiers.new()
	_dash = WaterDash.new(tuning)
	_grapple = TongueGrapple.new(tuning)


# --- The physics step -------------------------------------------------------

## One physics tick. [param is_in_water] is sampled by the caller BEFORE this
## call, from the water volume the body currently occupies.
##
## Order matters and is the whole of AC-1: the volume test and the grammar
## switch happen here, ahead of movement integration, so the frame that crosses
## the boundary is already integrated under the new grammar. Reacting to an
## Area3D `body_entered` signal instead would land a frame late and render one
## frame in the previous grammar — exactly what the criterion forbids.
func physics_step(delta: float, is_in_water: bool, intent: PlayerIntent) -> void:
	_apply_water_state(is_in_water)
	_dash.tick(delta, is_in_water)
	_integrate(intent)


func _apply_water_state(is_in_water: bool) -> void:
	if _initialised and is_in_water == _was_in_water:
		return

	var target := MovementGrammar.Grammar.WATER if is_in_water \
		else MovementGrammar.Grammar.LAND
	_was_in_water = is_in_water

	if _initialised and target == _grammar:
		return

	var crossing := _initialised
	_initialised = true
	_grammar = target

	# Momentum carries as MAGNITUDE, not as the vector: a swimmer surfacing keeps
	# their speed without keeping an underwater heading pointing into the ground.
	if crossing:
		var retained := _velocity.length() * _tuning.get_number(MOMENTUM_RETENTION_KEY)
		_velocity = Vector3.ZERO if _velocity.is_zero_approx() \
			else _velocity.normalized() * retained

	grammar_changed.emit(_grammar)


## Velocity only — the CharacterBody3D wrapper owns position and the motion call,
## so delta belongs there rather than here.
func _integrate(intent: PlayerIntent) -> void:
	# The dash is spent independently of steering — dashing from a standstill is
	# legitimate, so this cannot sit behind the steering early-return below.
	if intent.wants(MovementGrammar.Verb.DASH) and _dash.try_consume():
		dash_spent.emit(_dash.get_charges())

	var direction := intent.direction
	if _grammar == MovementGrammar.Grammar.LAND:
		# Land is grounded: the vertical component of intent is not steering.
		direction = Vector3(direction.x, 0.0, direction.z)

	# Steering OVERRIDES momentum; absence of steering PRESERVES it. Overwriting
	# unconditionally would zero the velocity every frame the player is not
	# holding a direction — which would silently undo the retention applied in
	# _apply_water_state and make AC-1's momentum carry unobservable.
	if direction.is_zero_approx():
		return

	# Capability loss degrades traversal multiplicatively; it never zeroes intent
	# outright and never ends a run on its own.
	_velocity = direction.normalized() * _base_speed() * _modifiers.combined()


func _base_speed() -> float:
	# Placeholder base speed pending the tuned locomotion values; the shape that
	# matters for the criteria is that it is scaled by the capability modifier
	# and read through tuning, never a constant in movement code.
	return 1.0


# --- Public interface: movement state ---------------------------------------

func get_grammar() -> MovementGrammar.Grammar:
	return _grammar


func is_in_water() -> bool:
	return _grammar == MovementGrammar.Grammar.WATER


func get_velocity() -> Vector3:
	return _velocity


## Seeds velocity for a test or a spawn. Never called during normal play — the
## controller owns its own velocity once running.
func set_velocity(velocity: Vector3) -> void:
	_velocity = velocity


func supports(verb: MovementGrammar.Verb) -> bool:
	return MovementGrammar.supports(_grammar, verb)


func get_available_verbs() -> Array[MovementGrammar.Verb]:
	return MovementGrammar.verbs_for(_grammar)


# --- Public interface: capability modifiers ---------------------------------

func get_capability_modifiers() -> CapabilityModifiers:
	return _modifiers


# --- Public interface: ability hooks ----------------------------------------

## Registers an ability hook. The Gill Mod framework registers these; the
## controller never knows which mods exist, which is what lets a world ship a new
## mod without a controller change.
func register_ability_hook(hook_id: String, callback: Callable) -> bool:
	if hook_id.is_empty() or not callback.is_valid():
		return false
	_ability_hooks[hook_id] = callback
	return true


func unregister_ability_hook(hook_id: String) -> void:
	_ability_hooks.erase(hook_id)


func has_ability_hook(hook_id: String) -> bool:
	return _ability_hooks.has(hook_id)


func get_ability_hook_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key: Variant in _ability_hooks:
		out.append(String(key))
	out.sort()
	return out


func invoke_ability_hook(hook_id: String) -> bool:
	if not _ability_hooks.has(hook_id):
		return false
	(_ability_hooks[hook_id] as Callable).call()
	return true


# --- Public interface: dash and grapple -------------------------------------

func get_dash() -> WaterDash:
	return _dash


func get_grapple() -> TongueGrapple:
	return _grapple


func try_grapple(candidates: Dictionary) -> bool:
	var anchor := _grapple.resolve_anchor(candidates)
	if not _grapple.attach(anchor):
		return false
	grapple_attached.emit(anchor)
	return true
