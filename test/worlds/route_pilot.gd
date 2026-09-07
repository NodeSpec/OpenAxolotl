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
##   FINISH steer at it and never advance — the world ends the walk
enum Move { WALK, JUMP, SWIM, BOOST, CLIMB, FINISH }

const MOVE_ID: Dictionary = {
	"walk": Move.WALK, "jump": Move.JUMP, "swim": Move.SWIM,
	"boost": Move.BOOST, "climb": Move.CLIMB, "finish": Move.FINISH,
}

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

	func _init(p_move: Move, p_target: Vector3, p_note: String) -> void:
		move = p_move
		target = p_target
		note = p_note


var _route: Array[Waypoint] = []
var _leg := 0
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


## Directional keys only. The vertical pair is pressed in water alone: on land
## the grammar drops the component anyway, and holding SPACE there would be a
## hop request rather than a steer.
func _steer(delta: Vector3, in_water: bool) -> void:
	_hold(KEY_W, delta.z < -DEADBAND)
	_hold(KEY_S, delta.z > DEADBAND)
	_hold(KEY_A, delta.x < -DEADBAND)
	_hold(KEY_D, delta.x > DEADBAND)
	_hold(KEY_SHIFT, in_water and delta.y < -DEADBAND)


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


func _arrived(wp: Waypoint, here: Vector3, delta: Vector3, flat: float,
		in_water: bool) -> bool:
	match wp.move:
		Move.FINISH:
			return false
		Move.BOOST:
			return _acted
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


func _advance() -> void:
	_leg += 1
	_leg_frames = 0
	_acted = false
	_airborne = 0
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
