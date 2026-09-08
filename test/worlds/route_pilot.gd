class_name RoutePilot
extends RefCounted

## Drives a world's route by pressing KEYS, one waypoint at a time.
##
## The old walk probes held W from spawn to finish. That was honest for a
## corridor, and it is exactly what stopped Coral Cove ever becoming a
## platformer: a level a held key can finish is a level with no gaps, no
## climbs and no reason to leave the ground. Making the route demand jumping,
## diving and climbing means the probe has to be able to jump, dive and climb.
##
## WHY KEYS AND NOT INTENT. The pilot pushes InputEventKey through
## `Input.parse_input_event`, the same path a player's keyboard takes, so the
## whole chain — bindings, grammar context, the Input System, PlayerIntent,
## the controller, move_and_slide — is under test. Calling the controller
## directly would skip the seams most likely to be miswired, which is the one
## thing a completability probe exists to catch.
##
## WHY WAYPOINTS AND NOT A SOLVER. A pathfinder would prove that SOME route
## exists; a waypoint list proves the route the level was DESIGNED around is
## walkable, which is the claim the level's comments make. When a waypoint
## stops being reachable the probe says which one and where the body got to,
## and that is a level bug report rather than a mystery.
##
## The pilot knows nothing about any particular world. The route is data.

## What the pilot does on arriving at a waypoint, and how it travels there.
##   WALK   steer over the ground (or through water) and move on
##   JUMP   steer, and hop when the target is within jumping range
##   SWIM   steer in three dimensions; the grammar must already be water
##   BOOST  ask for the bubble boost, then move on immediately
##   CLIMB  walk into the wall, then ask to climb once actually against it
##   FIGHT  close on the machine and swing until it goes down
##   MOD    open the equipped Gill Mod's window, then move on
##   FINISH steer at it and never advance — the world ends the walk
enum Move { WALK, JUMP, SWIM, BOOST, CLIMB, FIGHT, MOD, FINISH }

const MOVE_ID: Dictionary = {
	"walk": Move.WALK, "jump": Move.JUMP, "swim": Move.SWIM,
	"boost": Move.BOOST, "climb": Move.CLIMB, "fight": Move.FIGHT,
	"mod": Move.MOD, "finish": Move.FINISH,
}

## Frames between swings on a FIGHT leg, and how many are budgeted.
##
## TAPPED LIKE THE CLIMB, AND FOR THE SAME REASON: the strike verb is
## edge-triggered, so a key held down asks once and never again. The cadence is
## slower than the climb's because a swing has a real window — hammering faster
## than the animation only queues presses the controller drops.
##
## The budget is per leg and generous: the toughest shipped machine takes four
## strikes, and a leg that has swung fifteen times without one landing is a
## broken encounter rather than a slow one, which is what the probe exists to
## say out loud.
## Thirty-six frames is 0.6 s, just over combat.tail_whack.cooldown_s (0.55).
## Tapping FASTER than the cooldown is not faster: the verb is edge-triggered
## and a press inside the cooldown is simply dropped, so half the swings did
## nothing and the fights ran twice as long as they needed to.
const SWING_TAP := 36
const MAX_SWINGS := 15

## Frames the mod-activate button is held. Long enough that the press and the
## release land on different frames, short enough that the window it opens is
## still open when the next leg reaches the volume it gates.
const MOD_PRESS := 8

## How close the pilot gets before swinging, in metres.
##
## An ABSOLUTE distance, deliberately, and inside the shortest strike reach
## (the spin sprint's 1.9 m; the tail whack has 2.3). Adding it to the
## arrival tolerance instead — which is what this did first — let the pilot
## swing from three metres and miss, so a leg that was really "close, then
## hit" became "flail from wherever you happen to be" and reported a reach
## problem as a slow fight.
const STRIKE_RANGE := 1.6

## Steering deadband. Below this the axis is left alone, so the pilot does not
## chatter a key on and off either side of a target it is already on.
const DEADBAND := 0.35

## How close counts as arrived. Generous on purpose: the point is to prove the
## route is traversable, not to prove the pilot can land on a coin.
const REACH_XZ := 1.1
const REACH_Y := 1.6
const REACH_SWIM := 1.8

## How far ahead the pilot feels for ground before committing to a hop.
##
## Jumping at a fixed DISTANCE from the target does not work, and the way it
## fails is instructive: the target is a platform's centre, so the takeoff
## edge is the gap plus half the landing platform away, and one number cannot
## be right for a 3 m pillar and a 12 m terrace at once. Too small and the
## pilot walks off the edge without jumping; too large and it launches early
## and lands in the gap.
##
## So it looks instead. A short ray straight down, this far ahead along the
## direction of travel, answers the only question that matters — "does the
## floor stop just there?" — and the hop fires on the last stride before it
## does. The lookahead is deliberately short: every metre spent hopping early
## is a metre off the 3.15 m the jump can actually cover.
const EDGE_LOOKAHEAD := 0.35
const EDGE_PROBE_DROP := 1.6

## Below this the pilot is close enough that a hop would only overshoot.
const HOP_TO := 0.7

## Frames between climb taps, and how far the body must rise before the climb
## counts as attached rather than merely asked for.
const CLIMB_TAP := 12
const CLIMB_PROOF := 0.4

## Frames a single leg may take before the pilot calls it stuck. Sixteen
## seconds is far longer than any leg needs and short enough that a broken
## route reports rather than hangs.
const LEG_LIMIT := 960


class Waypoint:
	var move: Move
	var target: Vector3
	var note: String

	## What this leg acts ON, when it acts on something nameable: the unit id
	## of the machine a FIGHT leg has to put down. Empty for every other move,
	## because nothing else in the route needs to name a thing rather than a
	## place.
	var subject: String

	func _init(p_move: Move, p_target: Vector3, p_note: String,
			p_subject: String = "") -> void:
		move = p_move
		target = p_target
		note = p_note
		subject = p_subject


var _route: Array[Waypoint] = []
var _leg := 0

## The camera that defines forward. Optional: a scene without one keeps
## world-relative movement, and then aiming is a no-op rather than a crash.
var _camera: CameraFollow = null
var _leg_frames := 0
var _held: Dictionary = {}

## Set once the leg's own action has fired, so a hop or a climb request is made
## once per leg rather than every frame it is eligible.
var _acted := false

## Frames the body has been off the floor since this leg's hop. The hop key is
## HELD across the rise, because releasing it cuts the jump short (REQ-037),
## and released on landing, because the verb is edge-triggered and a key that
## is never released can never press again.
var _airborne := 0

## Where the body was when this leg began, so a climb can be judged by whether
## it actually went UP rather than by asking the controller how it feels.
var _leg_start := Vector3.ZERO

var _stuck := ""

## Swings taken on the current FIGHT leg.
var _swings := 0

## Asked, on a FIGHT leg, whether the named machine is down yet. Supplied by
## the walk that owns the world — the pilot presses keys and knows nothing
## about enemy systems, exactly as it knows nothing about checkpoints or
## collectibles.
var _fight_won: Callable = Callable()

## Where the world module was instanced. The hub places an active world at an
## offset so its floor cannot interpenetrate the lagoon's, which means a
## waypoint written in the level's own coordinates — the numbers a reader can
## check against world.tscn — is not a global position. Resolving the offset
## here keeps the route readable and keeps the probe honest about which space
## it is measuring in.
var _origin := Vector3.ZERO


func _init(route: Array[Waypoint], origin: Vector3 = Vector3.ZERO) -> void:
	_route = route
	_origin = origin


## Builds a waypoint from the compact form the world probes declare.
static func at(move_id: String, target: Vector3, note: String) -> Waypoint:
	return Waypoint.new(MOVE_ID.get(move_id, Move.WALK) as Move, target, note)


## A leg that ends when [param unit_id] is down. Its own constructor rather
## than a fifth argument on at(), so a route reads as "fight THIS machine here"
## and a fight leg cannot be written without naming what it fights.
static func fight(unit_id: String, target: Vector3, note: String) -> Waypoint:
	return Waypoint.new(Move.FIGHT, target, note, unit_id)


func is_done() -> bool:
	return _leg >= _route.size()


func get_leg() -> int:
	return _leg


func current() -> Waypoint:
	return _route[_leg] if _leg < _route.size() else null


## Non-empty once a leg has run out of time. The message names the waypoint and
## where the body actually got to, which is what makes a failure actionable.
func stuck_reason() -> String:
	return _stuck


## One physics frame of driving. `body` is the player CharacterBody3D; the
## pilot reads only its public state.
func step(body: CharacterBody3D) -> void:
	if is_done() or not _stuck.is_empty():
		return

	# Resolved from the body rather than passed in, so every existing caller
	# keeps its signature. Looked up once: the camera is bound at _ready and
	# does not change for the life of a run.
	if _camera == null and body.has_method("get_camera"):
		_camera = body.call("get_camera") as CameraFollow

	var wp := _route[_leg]
	var here := body.global_position
	var delta := wp.target + _origin - here
	var flat := Vector2(delta.x, delta.z).length()
	var in_water: bool = body.has_method("is_in_water") \
		and bool(body.call("is_in_water"))

	_leg_frames += 1
	if _leg_frames == 1:
		_leg_start = here
	if _leg_frames > LEG_LIMIT:
		_stuck = ("leg %d (%s) timed out: wanted %s, reached %s (%.1f m away, "
			% [_leg, wp.note, str(wp.target),
				str((here - _origin).snapped(Vector3.ONE * 0.1)),
				here.distance_to(wp.target + _origin)]
			+ "water=%s, floor=%s, wall=%s)"
			% [str(in_water), str(body.is_on_floor()), str(body.is_on_wall())])
		release_all()
		return

	_steer(delta, in_water)
	_act(body, wp, flat, delta, in_water)

	if _arrived(wp, here, delta, flat, in_water):
		_advance()


## AIM THE CAMERA, THEN PUSH FORWARD — which is what a player does, and what
## the pilot has to do now that movement is camera-relative.
##
## It used to press W/A/S/D against WORLD axes, which worked only while
## forward meant world -Z. With a look axis that is no longer true: the body
## rotates its intent by the camera's yaw, so the same four keys pressed under
## a turned camera go somewhere else entirely. Leg 34 — the only leg on the
## coral route that asks for a purely lateral move — is where that first showed
## up, eight metres wide of a pillar.
##
## Pointing the camera at the target and holding W is both simpler and more
## faithful than solving for which keys happen to compose the right world
## vector: it exercises the same camera-relative path a player's hands do,
## rather than a world-space path nothing in the shipped game uses any more.
##
## The vertical pair is pressed in water alone: on land the grammar drops the
## component anyway, and holding SPACE there would be a hop request rather
## than a steer.
func _steer(delta: Vector3, in_water: bool) -> void:
	var flat := Vector3(delta.x, 0.0, delta.z)
	if flat.length() > DEADBAND:
		# Godot's -Z forward: the yaw that points the camera along `flat`.
		_aim(rad_to_deg(atan2(-flat.x, -flat.z)))
	_hold(KEY_W, flat.length() > DEADBAND)
	_hold(KEY_SHIFT, in_water and delta.y < -DEADBAND)


## Point the camera, if this scene has one. Set outright rather than eased:
## the pilot is proving the ROUTE is flyable, not that a human can swing a
## camera smoothly, and easing would make every leg's timeout depend on the
## camera's turn rate.
func _aim(yaw_deg: float) -> void:
	if _camera == null:
		return
	_camera.set_yaw_deg(yaw_deg)


func _act(body: CharacterBody3D, wp: Waypoint, flat: float, delta: Vector3,
		in_water: bool) -> void:
	match wp.move:
		Move.SWIM, Move.FINISH, Move.WALK:
			# SPACE is swim-up in water and a hop on land, so it is only ever
			# held here while actually submerged.
			_hold(KEY_SPACE, in_water and delta.y > DEADBAND)

		Move.JUMP:
			if body.is_on_floor():
				if _airborne > 2:
					# Landed. Let go so the edge-triggered verb can fire again.
					_hold(KEY_SPACE, false)
					_airborne = 0
					_acted = false
				elif not _acted and flat >= HOP_TO and _at_an_edge(body, delta):
					_hold(KEY_SPACE, true)
					_acted = true
			else:
				_airborne += 1

		Move.BOOST:
			_hold(KEY_E, not _acted)
			_acted = true

		Move.MOD:
			# THE ONE VERB BOUND TO A MOUSE BUTTON, not a key: gill_mod_activate
			# is mouse.1 in the default scheme, so this is the only leg that
			# cannot be driven by the keyboard path the rest of the pilot uses.
			# It exists because the Flagship's third phase is gated on the
			# Bubble mod's ACTIVE window (REQ-013 AC-4) — equipping it is not
			# enough, and a probe that only walked into the volume proved the
			# gate refuses rather than that the fight can be finished.
			#
			# HELD ACROSS FRAMES, not pressed and released inside one. Parsed
			# input is processed on the following frame, so a press and a
			# release in the same frame can cancel each other and the verb
			# never fires — which is exactly how this first failed.
			_click(_leg_frames <= MOD_PRESS)

		Move.FIGHT:
			# Close first, then swing: a strike opened at four metres is a
			# strike that misses, and a probe that swung from wherever it
			# happened to be would pass a level whose machines are out of
			# reach — which is precisely the bug this leg exists to catch.
			if _in_range(delta, in_water):
				_hold(KEY_F, _leg_frames % SWING_TAP < 3)
				if _leg_frames % SWING_TAP == 0:
					_swings += 1
			else:
				_hold(KEY_F, false)
			# SPACE still steers upward in water, so a machine above the pilot
			# can be reached rather than swum under.
			_hold(KEY_SPACE, in_water and delta.y > DEADBAND)

		Move.CLIMB:
			# TAPPED, on a cadence, for as long as the body is against the wall
			# and has not started rising — which is exactly what a player does.
			#
			# A single press does not do: the climb verb is edge-triggered, so
			# a press that arrives on a frame where the body is not yet
			# reporting the wall is simply lost, and nothing would ever ask
			# again. Waiting for `is_on_wall()` before the first tap is still
			# right; it is the ASSUMPTION THAT ONE TAP LANDS that was wrong,
			# and it cost a climb that was correctly wired at both ends.
			_hold(KEY_E, body.is_on_wall() and _leg_frames % CLIMB_TAP < 3)


## True when the ground runs out just ahead along the way the pilot is going.
##
## The ray starts slightly above the feet and reaches below them, so a step
## DOWN still counts as ground and only a real drop reads as an edge. The body
## itself is excluded, or every cast would hit the capsule it started in.
func _at_an_edge(body: CharacterBody3D, delta: Vector3) -> bool:
	var heading := Vector3(delta.x, 0.0, delta.z)
	if heading.length_squared() < 0.0001:
		return false
	var ahead := body.global_position + heading.normalized() * EDGE_LOOKAHEAD
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		ahead + Vector3.UP * 0.1, ahead + Vector3.DOWN * EDGE_PROBE_DROP)
	query.exclude = [body.get_rid()]
	query.collision_mask = body.collision_mask
	return space.intersect_ray(query).is_empty()


## Whether the machine this leg names is inside striking distance.
func _in_range(delta: Vector3, in_water: bool) -> bool:
	if in_water:
		return delta.length() < STRIKE_RANGE
	return Vector2(delta.x, delta.z).length() < STRIKE_RANGE


func _arrived(wp: Waypoint, here: Vector3, delta: Vector3, flat: float,
		in_water: bool) -> bool:
	match wp.move:
		Move.FINISH:
			return false
		Move.FIGHT:
			# ENDS ON THE WORLD SAYING SO, not on a swing count. The probe
			# reports what it did; whether the machine went down is the
			# world's answer, delivered through the callback the walk installs.
			# A fight that ends because the pilot ran out of swings is a
			# failure with a name, not a leg quietly moving on.
			if _swings > MAX_SWINGS:
				_stuck = ("leg %d (%s) swung %d times without putting '%s' "
					% [_leg, wp.note, _swings, wp.subject]
					+ "down — it is out of reach of the waypoint, or tougher "
					+ "than the route assumes")
				release_all()
				return false
			return _fight_won.is_valid() and bool(_fight_won.call(wp.subject))
		Move.BOOST:
			return _acted
		Move.MOD:
			return _leg_frames > MOD_PRESS + 2
		Move.CLIMB:
			# Ends when the body has actually STARTED to rise. Ending it on the
			# request instead would call a climb that never attached a success.
			# Getting the rest of the way up belongs to the next waypoint,
			# which is on top of the wall.
			return here.y > _leg_start.y + CLIMB_PROOF
		Move.SWIM:
			return delta.length() < REACH_SWIM
		_:
			if in_water:
				return delta.length() < REACH_SWIM
			return flat < REACH_XZ and absf(delta.y) < REACH_Y
	return false


## Installs the "is this machine down?" question a FIGHT leg ends on. Called
## with the leg's subject — the unit id of the machine it is fighting.
func set_fight_test(test: Callable) -> void:
	_fight_won = test


## The standard question, for a world whose enemies a WorldSystems runs.
##
## Offered here rather than written out in each probe for the same reason the
## coral route itself lives in one file: two probes fly this route, and two
## copies of "is it down yet" could disagree about what down means. The pilot
## still knows nothing — it holds a Callable and calls it.
static func fleet_defeat_test(systems: Node) -> Callable:
	if systems == null or not systems.has_method("get_drift_fleet"):
		return Callable()
	var fleet: DriftFleetSystem = systems.call("get_drift_fleet")
	if fleet == null:
		return Callable()
	return func(unit_id: String) -> bool: return fleet.is_defeated(unit_id)


## Presses or releases the primary mouse button, the same way _hold presses a
## key: through Input.parse_input_event, so the whole binding chain is under
## test rather than bypassed.
func _click(down: bool) -> void:
	if bool(_held.get(MOUSE_BUTTON_LEFT, false)) == down:
		return
	_held[MOUSE_BUTTON_LEFT] = down
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)


func _advance() -> void:
	_leg += 1
	_leg_frames = 0
	_acted = false
	_airborne = 0
	_swings = 0
	_hold(KEY_F, false)
	_click(false)
	# ALWAYS released, including into another jump leg. Leaving it held there
	# looks harmless and is not: the hop verb is edge-triggered, so a key that
	# was never released cannot press again, and the second jump of a pair
	# silently became a walk off the edge.
	_hold(KEY_SPACE, false)
	_hold(KEY_E, false)


## Presses or releases a key, and ONLY on a change of state. Re-sending a press
## every frame would look like key repeat to anything counting edges.
func _hold(keycode: Key, pressed: bool) -> void:
	if bool(_held.get(keycode, false)) == pressed:
		return
	_held[keycode] = pressed
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func release_all() -> void:
	for keycode: Variant in _held.keys():
		_hold(keycode as Key, false)
