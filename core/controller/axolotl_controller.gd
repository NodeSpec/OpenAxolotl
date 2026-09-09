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
const DIVE_ACCELERATION_KEY := "controller.dive.acceleration_m_per_s2"
const SURFACE_ACCELERATION_KEY := "controller.surface.acceleration_m_per_s2"
const PITCH_MAX_KEY := "controller.pitch.max_deg"
const PITCH_RATE_KEY := "controller.pitch.rate_deg_per_s"
const PITCH_FULL_SPEED_KEY := "controller.pitch.full_speed_m_per_s"
const ROLL_SPEED_KEY := "controller.roll.speed_m_per_s"
const ROLL_DURATION_KEY := "controller.roll.duration_s"
const ROLL_COOLDOWN_KEY := "controller.roll.cooldown_s"
const SPIN_SPEED_KEY := "controller.spin_sprint.speed_m_per_s"
const SPIN_DURATION_KEY := "controller.spin_sprint.duration_s"
const SPIN_COOLDOWN_KEY := "controller.spin_sprint.cooldown_s"
const WHACK_WINDOW_KEY := "combat.tail_whack.window_s"
const WHACK_COOLDOWN_KEY := "combat.tail_whack.cooldown_s"
const STOMP_BOUNCE_KEY := "combat.stomp.bounce_m_per_s"
const HOP_IMPULSE_KEY := "controller.hop.impulse_m_per_s"
const CLIMB_SPEED_KEY := "controller.climb.speed_m_per_s"
const CLIMB_ADHESION_KEY := "controller.climb.adhesion_m_per_s"
const CLIMB_GRACE_KEY := "controller.climb.contact_grace_seconds"
const MAX_CLIMB_HEIGHT_KEY := "controller.climb.max_height_m"
const TURN_RATE_KEY := "controller.facing.turn_rate_deg_per_s"

## Below this horizontal speed the heading HOLDS. A zero-length velocity has no
## direction, and the arbitrary atan2 it would yield spins a standing axolotl
## on the spot — the camera guards against the same thing with its own bound.
const HEADING_HOLD_SPEED := 0.25

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
signal rolled()
signal spin_sprint_started()

## A strike window opened. Whatever owns the scene answers this by finding the
## machines within [param reach] of the body — the controller has no scene and
## never learns which, or whether, anything was hit.
signal strike_opened(kind: CombatStrike.Kind, reach: float)

var _tuning: TuningData
var _grammar: MovementGrammar.Grammar = MovementGrammar.Grammar.LAND
var _velocity: Vector3 = Vector3.ZERO
var _was_in_water: bool = false

## The yaw the body should FACE, in radians about +Y, turned toward the
## horizontal direction of travel at the tuned rate. Zero faces down -Z,
## Godot's forward, which is also the direction every greybox route runs.
var _heading_yaw: float = 0.0

## The pitch the model should wear, in radians: negative noses down, which is
## what a descending axolotl does. Visual only, like the heading — the capsule
## is round and never rotates — and the thing the heading's own comment used to
## call "a follow-up".
var _pitch: float = 0.0

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

## Seconds since the body last reported wall contact while climbing. Reset on
## every contact and on every attach.
var _wall_lost_for: float = 0.0

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
var _jump_feel: JumpFeel
var _roll: BurstMove
var _spin: BurstMove
var _anchor_source: AnchorSource = null
var _ability_hooks: Dictionary = {}

## The tail whack's live window and its rest. It is not a BurstMove because it
## moves nothing: the axolotl plants its feet and swings, so there is no
## direction to commit to and no velocity to drive. What it shares with the
## bursts is only the shape of the timer, which is small enough to keep here.
var _whack_window: float = 0.0
var _whack_cooldown: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_modifiers = CapabilityModifiers.new()
	_dash = WaterDash.new(tuning)
	_boost = BubbleBoost.new(tuning)
	_grapple = TongueGrapple.new(tuning)
	_jump_feel = JumpFeel.new(tuning)
	_roll = BurstMove.new(tuning, ROLL_SPEED_KEY, ROLL_DURATION_KEY,
		ROLL_COOLDOWN_KEY)
	_spin = BurstMove.new(tuning, SPIN_SPEED_KEY, SPIN_DURATION_KEY,
		SPIN_COOLDOWN_KEY)


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
	_roll.tick(delta)
	_spin.tick(delta)
	_tick_whack(delta)
	_integrate(delta, intent)
	_update_heading(delta)
	_update_pitch(delta)


## The body turns toward where it is going, never instantly: the heading chases
## the travel direction at [constant TURN_RATE_KEY], so a reversal is a visible
## flick rather than a teleport. Yaw only — pitch while diving is a follow-up.
## The formula is the trailing camera's own, so the camera sits behind the
## direction the body faces rather than behind some other axis.
func _update_heading(delta: float) -> void:
	var travel := Vector2(_velocity.x, _velocity.z)
	if travel.length() < HEADING_HOLD_SPEED:
		return
	var target := atan2(-travel.x, -travel.y)
	var max_step := deg_to_rad(_tuning.get_number(TURN_RATE_KEY)) * delta
	var difference := wrapf(target - _heading_yaw, -PI, PI)
	_heading_yaw = wrapf(
		_heading_yaw + clampf(difference, -max_step, max_step), -PI, PI)


## The model noses into where it is going vertically.
##
## THIS IS WHAT MAKES A DIVE READ AS A DIVE. The glide below gives the descent
## a shape; without a body that tips into it, an axolotl sinking at five metres
## a second is still an axolotl held perfectly level being lowered, which is
## the posture of a lift rather than of an animal. The pitch is proportional to
## vertical speed and chased rather than set, for the same reason the heading
## is chased: matching it instantly turns every ripple in vertical speed into a
## visible flick of the whole body.
##
## Water only. On land the vertical axis is gravity and the hop, both of which
## the fall and hop clips already answer with the head and the legs, and a
## model pitched forty degrees down while standing on a slope reads as broken.
func _update_pitch(delta: float) -> void:
	var wanted := 0.0
	var full := _tuning.get_number(PITCH_FULL_SPEED_KEY)
	if _grammar == MovementGrammar.Grammar.WATER and full > 0.0:
		wanted = deg_to_rad(_tuning.get_number(PITCH_MAX_KEY)) \
			* clampf(_velocity.y / full, -1.0, 1.0)
	var max_step := deg_to_rad(_tuning.get_number(PITCH_RATE_KEY)) * delta
	_pitch += clampf(wanted - _pitch, -max_step, max_step)


func _tick_whack(delta: float) -> void:
	if delta <= 0.0:
		return
	_whack_window = maxf(0.0, _whack_window - delta)
	_whack_cooldown = maxf(0.0, _whack_cooldown - delta)


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
		# A roll is a land verb. Carried into water it would be a swim burst
		# nobody granted, and it would keep driving a heading that was chosen
		# against the ground.
		_roll.interrupt()
		_whack_window = 0.0
	else:
		_boost.interrupt()
		_spin.interrupt()

	# The universal water-powered dash is deliberately NOT interrupted here.
	# REQ-001 names it as the transition skill joining the grammars; a burst that
	# dies exactly on the seam would make the transition skill fail at transition.
	grammar_changed.emit(_grammar)


## Velocity only — the CharacterBody3D wrapper owns position and the motion call,
## so delta belongs there rather than here.
func _integrate(delta: float, intent: PlayerIntent) -> void:
	if intent.wants(MovementGrammar.Verb.GRAPPLE) and not _grapple.is_attached():
		try_grapple()

	# The tongue is already a committed traversal state. Do not spend a dash
	# charge into a grapple pull that will immediately overwrite it.
	if _grapple.is_attached():
		if _grapple.has_arrived(_body_position):
			_end_grapple(true)
		else:
			_velocity = _grapple.pull_velocity(_body_position)
			return

	# REQ-001 AC-5: DASH is not merely a charge counter. It is the signature
	# transition burst and therefore has to move the body in both grammars.
	#
	# To stay inside REQ-025's single tuning surface without inventing a second
	# set of unreviewed balance values, the dash deliberately borrows the existing
	# short-burst profile of the active grammar: roll profile on land, spin profile
	# in water. The dash remains mechanically distinct because it spends the
	# water-earned universal charge economy and survives grammar boundaries.
	if intent.wants(MovementGrammar.Verb.DASH) and not _dash.is_active():
		var dash_direction := intent.direction
		if _grammar == MovementGrammar.Grammar.LAND:
			dash_direction.y = 0.0
		if dash_direction.is_zero_approx():
			dash_direction = _facing_direction()

		var dash_speed_key := SPIN_SPEED_KEY if _grammar == MovementGrammar.Grammar.WATER \
			else ROLL_SPEED_KEY
		var dash_duration_key := SPIN_DURATION_KEY \
			if _grammar == MovementGrammar.Grammar.WATER else ROLL_DURATION_KEY
		if _dash.try_activate(dash_direction,
				_tuning.get_number(dash_speed_key),
				_tuning.get_number(dash_duration_key)):
			# Dashing away from a wall releases the climb. The dash is universal;
			# making it dead while clinging would contradict that public grammar.
			_end_climb()
			dash_spent.emit(_dash.get_charges())

	# The committed dash dominates ordinary steering for its live window. On land
	# only the planar component is driven so a dash off a ledge still falls; in
	# water the whole 3D direction is the movement, so a rising or diving dash is
	# genuinely three-dimensional.
	if _dash.is_active():
		var driven := _dash.velocity()
		if _grammar == MovementGrammar.Grammar.WATER:
			_velocity = driven
		else:
			_velocity = Vector3(driven.x, _velocity.y, driven.z)
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

	# THE SPIN SPRINT DOMINATES, like the grapple pull above it. It is a
	# commitment: the body is spinning, so steering out of it mid-flight would
	# both look wrong and take the timing out of the one verb whose timing is
	# the whole skill.
	if intent.wants(MovementGrammar.Verb.SPIN_SPRINT):
		var heading := direction if not direction.is_zero_approx() \
			else _facing_direction()
		if _spin.try_activate(heading):
			spin_sprint_started.emit()
			_open_strike(CombatStrike.Kind.SPIN_SPRINT)
	if _spin.is_active():
		_velocity = _spin.velocity()
		return

	# Steering OVERRIDES momentum; absence of steering PRESERVES it. Overwriting
	# unconditionally would zero the velocity every frame the player is not
	# holding a direction — which would silently undo the retention applied in
	# _apply_water_state and make AC-1's momentum carry unobservable.
	var target: Vector3
	if not direction.is_zero_approx():
		target = direction.normalized() * _swim_speed()
	else:
		# Momentum is PRESERVED but not forever. Water glides, so the drag here
		# is gentle — but without any the axolotl would coast at its entry speed
		# until it hit something, which is what a fall into a pool did before
		# this existed.
		target = _dragged(_velocity, _tuning.get_number(SWIM_DRAG_KEY), delta)

	# A dive is a deliberate descent, not steering: it SETS the vertical target
	# rather than adding to it, so diving from a standstill still descends and a
	# dive held against upward steering still goes down. It is read from BOTH
	# halves of the intent — the press announces it, the hold sustains it — so
	# holding the key is a dive rather than a series of taps.
	if intent.wants(MovementGrammar.Verb.DIVE):
		dived.emit()
	if intent.wants(MovementGrammar.Verb.DIVE) \
			or intent.sustains(MovementGrammar.Verb.DIVE):
		target.y = -_tuning.get_number(DIVE_SPEED_KEY)

	# THE GLIDE. Horizontal steering stays immediate — that is the swim's
	# responsiveness and every route was measured against it — but the VERTICAL
	# component is eased into. Setting velocity.y outright moved the axolotl
	# from level flight to five metres a second downward between two rendered
	# frames, which is not a dive: it is a cut. Easing gives the descent and the
	# rise a shape the player can see beginning, and it is what _update_pitch
	# above has to work with.
	_velocity.x = target.x
	_velocity.z = target.z
	_velocity.y = _glide(_velocity.y, target.y, delta)


## Eases a vertical speed toward its target, downward faster than upward.
##
## The asymmetry is deliberate: an axolotl drops with gravity behind it and
## climbs against buoyancy, so a surface that eased in as hard as a dive read
## as being winched rather than swum.
func _glide(current: float, target: float, delta: float) -> float:
	var rate := _tuning.get_number(DIVE_ACCELERATION_KEY) if target < current \
		else _tuning.get_number(SURFACE_ACCELERATION_KEY)
	if rate <= 0.0 or delta <= 0.0:
		return target
	return current + clampf(target - current, -rate * delta, rate * delta)


## The way the body is pointing, as a direction. What a burst uses when the
## player asked for one without holding a direction: rolling or spinning on
## the spot would spend the cooldown and move nothing, which reads as the
## button being broken rather than as a decision.
func _facing_direction() -> Vector3:
	return Vector3(-sin(_heading_yaw), 0.0, -cos(_heading_yaw))


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

	# The tail whack plants the feet and swings, so it is checked before the
	# roll and does not touch velocity at all: the axolotl keeps whatever it
	# was doing horizontally, and the swing happens on top of it.
	if intent.wants(MovementGrammar.Verb.TAIL_WHACK):
		_try_whack()

	# THE ROLL DOMINATES steering for its window, exactly as the spin sprint
	# does in water and for the same reason: a dodge you can steer out of is
	# not a dodge, and the commitment is what makes when you press it a
	# decision rather than a direction.
	if intent.wants(MovementGrammar.Verb.ROLL):
		var heading := direction if not direction.is_zero_approx() \
			else _facing_direction()
		if _roll.try_activate(heading):
			rolled.emit()
	if _roll.is_active():
		var driven := _roll.velocity()
		# Vertical is left to gravity and the hop: a roll off a ledge is a
		# roll that falls, not one that flies.
		_velocity = Vector3(driven.x, _velocity.y, driven.z)
		return
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

	# The hop, with its forgiveness windows (REQ-037). JumpFeel owns the
	# timers; this owns the impulse. A hop still cannot be chained in mid-air
	# into a free ascent — `should_hop` requires footing that is either the
	# real floor or an unspent coyote window, and firing spends both.
	#
	# The press and the hold are read from DIFFERENT halves of the intent. The
	# press is edge-triggered and fires the impulse; the hold is what the cut
	# reads, and taking the cut from the press instead would cut every jump on
	# the frame after launch, because an edge verb is by definition gone by
	# then. That is not a hypothetical — it is the bug this split fixes.
	var pressed_hop := intent.wants(MovementGrammar.Verb.HOP)
	var holds_hop := intent.sustains(MovementGrammar.Verb.HOP)
	_jump_feel.step(delta, _is_grounded, pressed_hop)
	if _jump_feel.should_hop(_is_grounded, pressed_hop):
		_velocity.y = _tuning.get_number(HOP_IMPULSE_KEY)
		_is_grounded = false
		_jump_feel.consume()
		hopped.emit()
	else:
		# Variable height: releasing the button mid-climb cuts the rise, so
		# one button expresses a range of heights.
		_velocity.y = _jump_feel.cut_rise(_velocity.y, holds_hop)


## The velocity that holds the climber against the wall.
##
## The body ends a climb when it stops touching the wall, which is the honest
## end condition — but a climber moving purely ALONG the surface (straight up,
## or sideways) generates no contact, so without this the climb detached on its
## second frame, every time. It rose 0.12 m ballistically and fell back down,
## and no unit test could see it because detachment is a scene-tree fact.
##
## move_and_slide absorbs this component against the wall, so it costs no
## motion; it only guarantees the collision that keeps `is_on_wall()` true.
func _climb_adhesion() -> Vector3:
	return -_climb_normal * _tuning.get_number(CLIMB_ADHESION_KEY)


func _integrate_climb(intent: PlayerIntent) -> void:
	var steer := intent.direction
	if steer.is_zero_approx():
		# A climber clings rather than sliding: no steering means no motion
		# along the wall, not the retained momentum the grounded grammar keeps.
		# The adhesion is not motion — it is what keeps the cling attached.
		_velocity = _climb_adhesion()
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
	_velocity = direction * _tuning.get_number(CLIMB_SPEED_KEY) + _climb_adhesion()

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


# --- Combat: three strikes, none of them a new button ------------------------

## Opens a strike window and announces it. Refused for a strike the current
## grammar does not own, so a land verb underwater neither swings nor spends
## anything.
func _open_strike(kind: CombatStrike.Kind) -> bool:
	if not CombatStrike.allowed_in(kind, _grammar):
		return false
	strike_opened.emit(kind, _tuning.get_number(CombatStrike.reach_key(kind)))
	return true


func _try_whack() -> bool:
	if _whack_cooldown > 0.0 or _whack_window > 0.0:
		return false
	if not _open_strike(CombatStrike.Kind.TAIL_WHACK):
		return false
	_whack_window = _tuning.get_number(WHACK_WINDOW_KEY)
	_whack_cooldown = _whack_window + _tuning.get_number(WHACK_COOLDOWN_KEY)
	return true


## Whether a tail whack is mid-swing. Read by the animator, and by anything
## that wants to know the axolotl is busy.
func is_whacking() -> bool:
	return _whack_window > 0.0


## The bounce off a machine the axolotl landed on.
##
## Called by whatever owns the scene, because only it knows the landing
## happened — the controller has no enemies in it. It is a SET rather than an
## add, so the bounce is the same height however fast the player was falling:
## a stomp from six metres up must not fling them further than a stomp from
## one, or the reward for the hit depends on how badly they misjudged the drop.
func apply_stomp_bounce() -> void:
	_velocity.y = _tuning.get_number(STOMP_BOUNCE_KEY)
	_is_grounded = false
	_jump_feel.consume()


func get_roll() -> BurstMove:
	return _roll


func get_spin_sprint() -> BurstMove:
	return _spin


# --- Public interface: movement state ---------------------------------------

func get_grammar() -> MovementGrammar.Grammar:
	return _grammar


func is_in_water() -> bool:
	return _grammar == MovementGrammar.Grammar.WATER


func get_velocity() -> Vector3:
	return _velocity


## Radians about +Y; zero faces -Z. Applied by the body wrapper to the model.
func get_heading_yaw() -> float:
	return _heading_yaw


## Radians about the model's own +X; negative noses DOWN. Applied by the body
## wrapper to the model beside the heading, and visual only — the capsule the
## whole game was measured against does not rotate.
func get_pitch() -> float:
	return _pitch


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


## The body reporting, once a frame, whether it is still touching the wall.
##
## Losing contact for a SINGLE frame must not drop a climber. Two ordinary
## situations produce exactly that: a wall with a seam or a curve, where the
## capsule swings clear for a frame; and the top-out, where contact is lost
## while the feet are still below the lip. In the second case the grace is
## what carries the climber the last few centimetres over the edge instead of
## dropping them the whole way back down — which is what Coral Cove's coral
## wall did, from four metres up, every single time.
##
## It is the same idea as coyote time and it earns its keep the same way: it
## changes no reachable height, only how much precision the geometry demands.
func report_wall_contact(has_wall: bool, delta: float) -> void:
	if not _climbing:
		_wall_lost_for = 0.0
		return
	if has_wall:
		_wall_lost_for = 0.0
		return
	_wall_lost_for += delta
	if _wall_lost_for >= _tuning.get_number(CLIMB_GRACE_KEY):
		_end_climb()


func is_climbing() -> bool:
	return _climbing


func _end_climb() -> void:
	if not _climbing:
		return
	_climbing = false
	_wall_lost_for = 0.0
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
