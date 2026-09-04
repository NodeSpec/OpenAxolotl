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
## same-frame switching criterion be asserted at all. The one place that must
## touch the scene, anchor discovery, is behind the AnchorSource port.

const MOMENTUM_RETENTION_KEY := "controller.transition.momentum_retention_ratio"
const SWIM_SPEED_KEY := "controller.swim.base_speed_m_per_s"
const WADDLE_SPEED_KEY := "controller.waddle.base_speed_m_per_s"
const WADDLE_DRAG_KEY := "controller.waddle.drag_per_second"
const SWIM_DRAG_KEY := "controller.swim.drag_per_second"
const DIVE_SPEED_KEY := "controller.dive.speed_m_per_s"
const HOP_IMPULSE_KEY := "controller.hop.impulse_m_per_s"
const CLIMB_SPEED_KEY := "controller.climb.speed_m_per_s"
const MAX_CLIMB_HEIGHT_KEY := "controller.climb.max_height_m"

## Emitted on the SAME frame the grammar changes, before movement integration.
signal grammar_changed(grammar: MovementGrammar.Grammar)
signal dash_spent(remaining: int)
signal dived()
signal boost_started(duration: float)
signal hopped()
signal climb_started()
signal climb_ended()
signal grapple_attached(anchor_id: String)
signal grapple_detached(anchor_id: String, arrived: bool)

var _tuning: TuningData
var _grammar: MovementGrammar.Grammar = MovementGrammar.Grammar.LAND
var _velocity: Vector3 = Vector3.ZERO
var _was_in_water: bool = false
var _initialised: bool = false

## Published by the CharacterBody3D wrapper each step. The wrapper still OWNS the
## transform — this is a read-only copy — but anchor discovery and the grapple
## pull both need a frame of reference, and threading it through every call would
## put a Vector3 on methods that have nothing to do with position.
var _body_position: Vector3 = Vector3.ZERO

## Published by the wrapper from `is_on_floor()`. Defaults true because a spawned
## axolotl stands on the ground; a wrapper that never publishes it gets a hop that
## works, not one that is silently dead.
var _is_grounded: bool = true

var _climbing: bool = false

## Body height at the moment the climb started. The climb CEILING is measured
## from here rather than from world zero, so "a lost leg reduces climb height"
## means the axolotl reaches less far up THIS wall, not that it cannot climb at
## altitude (REQ-002).
var _climb_anchor_y: float = 0.0

## Outward normal of the surface being climbed, supplied by the body wrapper.
## Defaults to a wall facing +Z so a headless test can climb without a scene.
var _climb_normal: Vector3 = Vector3.BACK

var _modifiers: CapabilityModifiers
var _dash: WaterDash
var _boost: BubbleBoost
var _grapple: TongueGrapple
var _anchor_source: AnchorSource = null
var _ability_hooks: Dictionary = {}


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_modifiers = CapabilityModifiers.new()
	_dash = WaterDash.new(tuning)
	_boost = BubbleBoost.new(tuning)
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
	_boost.tick(delta)
	_integrate(delta, intent)


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

	# Each grammar's exclusive verbs end at the boundary. A climb surviving into
	# water would let the player scale a wall while swimming; a boost surviving
	# onto land would hand them a land speed burst the land grammar never grants.
	if target == MovementGrammar.Grammar.WATER:
		if _climbing:
			_end_climb()
	else:
		_boost.interrupt()

	grammar_changed.emit(_grammar)


## Velocity only — the CharacterBody3D wrapper owns position and the motion call,
## so delta belongs there rather than here.
func _integrate(delta: float, intent: PlayerIntent) -> void:
	# The dash is spent independently of steering — dashing from a standstill is
	# legitimate, so this cannot sit behind the steering early-returns below.
	if intent.wants(MovementGrammar.Verb.DASH) and _dash.try_consume():
		dash_spent.emit(_dash.get_charges())

	if intent.wants(MovementGrammar.Verb.GRAPPLE) and not _grapple.is_attached():
		try_grapple()

	# The pull DOMINATES steering: the tongue is taut, so a player who fires it
	# commits to the arc rather than steering out of it mid-flight.
	if _grapple.is_attached():
		if _grapple.has_arrived(_body_position):
			_end_grapple(true)
		else:
			_velocity = _grapple.pull_velocity(_body_position)
			return

	if _climbing:
		_integrate_climb(intent)
		return

	if _grammar == MovementGrammar.Grammar.WATER:
		_integrate_water(delta, intent)
	else:
		_integrate_land(delta, intent)


# --- AC-2: the water grammar ------------------------------------------------

func _integrate_water(delta: float, intent: PlayerIntent) -> void:
	# Republished every frame rather than cached: the capability system may strip
	# a gill between frames, and a boost that started on a stale scale would run
	# at the intact duration (REQ-002).
	_boost.set_duration_scale(
		_modifiers.combined(CapabilityModifiers.Target.BOOST_DURATION))

	if intent.wants(MovementGrammar.Verb.BUBBLE_BOOST) and _boost.try_activate():
		boost_started.emit(_boost.get_remaining())

	# Full 3D: the vertical component of intent IS steering in water, and is the
	# difference between swimming and a land grammar wearing a swim animation.
	var direction := intent.direction

	# Steering OVERRIDES momentum; absence of steering PRESERVES it. Overwriting
	# unconditionally would zero the velocity every frame the player is not
	# holding a direction — which would silently undo the retention applied in
	# _apply_water_state and make AC-1's momentum carry unobservable.
	if not direction.is_zero_approx():
		_velocity = direction.normalized() * _swim_speed()
	else:
		# Momentum is PRESERVED but not forever. Water glides, so the drag here
		# is gentle — but without any the axolotl would coast at its entry speed
		# until it hit something, which is what a fall into a pool did before
		# this existed.
		_velocity = _dragged(_velocity, _tuning.get_number(SWIM_DRAG_KEY), delta)

	if intent.wants(MovementGrammar.Verb.DIVE):
		# A dive is a deliberate descent, not steering: it SETS the vertical
		# component rather than adding to it, so diving from a standstill still
		# descends and a dive held against upward steering still goes down.
		_velocity.y = -_tuning.get_number(DIVE_SPEED_KEY)
		dived.emit()


func _swim_speed() -> float:
	return _tuning.get_number(SWIM_SPEED_KEY) \
		* _modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED) \
		* _boost.speed_multiplier()


# --- AC-3: the land grammar -------------------------------------------------

func _integrate_land(delta: float, intent: PlayerIntent) -> void:
	# Land is grounded: the vertical component of intent is not steering. The
	# vertical component of VELOCITY is preserved, because that is the hop and
	# gravity, which steering has no business erasing.
	var direction := Vector3(intent.direction.x, 0.0, intent.direction.z)
	if not direction.is_zero_approx():
		var waddle := direction.normalized() \
			* _tuning.get_number(WADDLE_SPEED_KEY) \
			* _modifiers.combined(CapabilityModifiers.Target.WADDLE_SPEED)
		_velocity = Vector3(waddle.x, _velocity.y, waddle.z)
	else:
		# Horizontal only: the vertical component is gravity and the hop, and
		# dragging it would make the axolotl float down. Land drag is brisk, so
		# releasing the key stops you rather than launching a long coast off the
		# edge of the level.
		var slowed := _dragged(Vector3(_velocity.x, 0.0, _velocity.z),
			_tuning.get_number(WADDLE_DRAG_KEY), delta)
		_velocity = Vector3(slowed.x, _velocity.y, slowed.z)

	# Grounded-only, so a hop cannot be chained in mid-air into a free ascent.
	# The wrapper clears the flag again from is_on_floor() on landing.
	if intent.wants(MovementGrammar.Verb.HOP) and _is_grounded:
		_velocity.y = _tuning.get_number(HOP_IMPULSE_KEY)
		_is_grounded = false
		hopped.emit()


func _integrate_climb(intent: PlayerIntent) -> void:
	var steer := intent.direction
	if steer.is_zero_approx():
		# A climber clings rather than sliding: no steering means no motion,
		# not the retained momentum the grounded grammar keeps.
		_velocity = Vector3.ZERO
		return

	# The land grammar's intent is PLANAR — it never carries a vertical
	# component, because there is no up on the ground and the bindings reflect
	# that. So on a wall the FORWARD axis becomes the vertical one: pushing
	# toward the surface climbs it, which is both the platformer convention and
	# the only mapping the existing bindings can express.
	#
	# This was the second half of a bug where climbing did nothing in a real
	# scene. The first half was that nothing called try_climb; this half was
	# that even attached, forward steering drove the axolotl INTO the wall
	# rather than up it. The unit test missed it by feeding Vector3.UP — an
	# intent the land grammar cannot produce.
	var lateral := Vector3.UP.cross(_climb_normal)
	lateral = Vector3.RIGHT if lateral.length_squared() < 0.0001 \
		else lateral.normalized()

	var direction := (Vector3.UP * -steer.z + lateral * steer.x).normalized()
	_velocity = direction * _tuning.get_number(CLIMB_SPEED_KEY)

	# The reach ceiling. A lost leg lowers it (REQ-002), and a climber at the
	# ceiling can still traverse sideways and descend — it is a limit on how high
	# this wall goes, not a freeze. Blocking ascent rather than detaching keeps
	# the player in control of when they let go.
	if _velocity.y > 0.0 and _climb_rise() >= max_climb_height():
		_velocity.y = 0.0


## Speed below which the remainder is simply dropped. Exponential decay never
## actually reaches zero, and "the axolotl eventually stops" has to be a fact a
## test can assert rather than an asymptote it approaches.
const REST_SPEED := 0.05


## Exponential decay toward rest, frame-rate independent: the tuned rate means
## the same thing at 30 fps and at 240.
##
## Both grammars call this when the player is not steering. Before it existed,
## "absence of steering PRESERVES momentum" meant preserved FOREVER — releasing
## the key left the axolotl coasting at full waddle speed until it walked off
## the level, and a fall into water sank at its entry speed until it hit the
## floor. The rates differ by an order of magnitude on purpose: water glides,
## land is planted, and that contrast is part of what makes the two grammars
## read as mechanically distinct.
static func _dragged(velocity: Vector3, rate: float, delta: float) -> Vector3:
	if delta <= 0.0 or rate <= 0.0:
		return velocity
	var slowed := velocity * exp(-rate * delta)
	return Vector3.ZERO if slowed.length() < REST_SPEED else slowed


## How far the axolotl has risen since attaching to the current surface.
func _climb_rise() -> float:
	return _body_position.y - _climb_anchor_y


## Reachable height on one surface, after capability modifiers. Read at use time
## so a leg lost mid-climb lowers the ceiling on the very next frame.
func max_climb_height() -> float:
	return _tuning.get_number(MAX_CLIMB_HEIGHT_KEY) \
		* _modifiers.combined(CapabilityModifiers.Target.CLIMB_HEIGHT)


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


## Published by the wrapper each step, before physics_step.
func sync_body_position(position: Vector3) -> void:
	_body_position = position


func get_body_position() -> Vector3:
	return _body_position


## Published by the wrapper from is_on_floor(), before physics_step.
func set_grounded(grounded: bool) -> void:
	_is_grounded = grounded


func is_grounded() -> bool:
	return _is_grounded


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


# --- Public interface: dash and bubble boost --------------------------------

func get_dash() -> WaterDash:
	return _dash


func get_bubble_boost() -> BubbleBoost:
	return _boost


# --- Public interface: climbing ---------------------------------------------

## Attempts to attach to the surface a collision reported. Refused in water
## (CLIMB is a land verb) and refused on any surface not carrying the climbable
## PHYSICS LAYER or GROUP — never a name check; see ClimbSurface.
func try_climb(collision_layer: int, groups: PackedStringArray) -> bool:
	if _grammar != MovementGrammar.Grammar.LAND:
		return false
	if not ClimbSurface.is_climbable(collision_layer, groups):
		return false
	if _climbing:
		return true

	_climbing = true
	_climb_anchor_y = _body_position.y
	climb_started.emit()
	return true


## Supplied by the body wrapper from the wall it is touching. The controller
## stays scene-free: it is told the normal, it never queries for one.
func set_climb_surface_normal(normal: Vector3) -> void:
	if not normal.is_zero_approx():
		_climb_normal = normal.normalized()


func get_climb_surface_normal() -> Vector3:
	return _climb_normal


func release_climb() -> void:
	_end_climb()


func is_climbing() -> bool:
	return _climbing


func _end_climb() -> void:
	if not _climbing:
		return
	_climbing = false
	climb_ended.emit()


# --- Public interface: tongue grapple ---------------------------------------

func get_grapple() -> TongueGrapple:
	return _grapple


## Installed once by the wrapper. Without it a grapple always misses rather than
## falling back to some looser discovery rule.
func set_anchor_source(source: AnchorSource) -> void:
	_anchor_source = source


func get_anchor_source() -> AnchorSource:
	return _anchor_source


## Fires the tongue: group query, range filter, line of sight, nearest wins.
## Returns false on a miss so the caller can play a miss cue.
func try_grapple() -> bool:
	var anchor := _grapple.find_anchor(_body_position, _anchor_source)
	if not _grapple.attach(anchor):
		return false

	# A grapple overrides a climb: you let go of the wall to fire the tongue.
	_end_climb()
	grapple_attached.emit(anchor.id)
	return true


## Lets go early — the player cancelling, or a Hookline Rig cutting the tongue.
func release_grapple() -> void:
	_end_grapple(false)


func _end_grapple(arrived: bool) -> void:
	if not _grapple.is_attached():
		return
	var anchor_id := _grapple.get_attached_anchor()
	_grapple.detach()
	grapple_detached.emit(anchor_id, arrived)
