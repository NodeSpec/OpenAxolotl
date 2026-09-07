class_name CameraRig
extends RefCounted

## The Camera System (REQ-005).
##
## A plain RefCounted holding the framing maths, with a thin Camera3D reading its
## transform. Same reason as the controller: the criteria are numeric statements
## about per-frame deltas, and a bound you cannot assert headlessly is a bound
## nobody will notice breaking.
##
## THE GRAMMAR ARRIVES AS A BOOL, not as a MovementGrammar. The architecture
## declares no edge from this node to the Axolotl Controller — the Game Client is
## the mediator (Core Module Dependency) — so the rig takes `set_in_water(bool)`
## from whoever is driving it. Importing the controller's enum here would create
## a dependency the model does not have and nobody would notice until a world
## tried to use the camera without the controller.
##
## SMOOTHING IS A DAMPED FOLLOW PLUS AN EXPLICIT PER-FRAME CLAMP, not a lerp
## factor tuned until it happens to stay under the bound. The clamp is what makes
## AC-1 structurally true instead of incidentally true: at any frame rate, with
## any damping, with any teleport thrown at it, the camera cannot move further in
## one frame than the tuned metres or turn further than the tuned degrees.

const MAX_POSITION_DELTA_KEY := "camera.smoothing.max_position_delta_m_per_frame"
const MAX_ROTATION_DELTA_KEY := "camera.smoothing.max_rotation_delta_deg_per_frame"
const POSITION_DAMPING_KEY := "camera.smoothing.position_damping_per_second"
const ROTATION_DAMPING_KEY := "camera.smoothing.rotation_damping_per_second"
const WATER_DISTANCE_KEY := "camera.follow.water_distance_m"
const LAND_DISTANCE_KEY := "camera.follow.land_distance_m"
const WATER_PITCH_KEY := "camera.follow.water_pitch_deg"
const LAND_PITCH_KEY := "camera.follow.land_pitch_deg"
const MIN_DISTANCE_KEY := "camera.follow.min_distance_m"
const COLLISION_MARGIN_KEY := "camera.collision.margin_m"

signal framing_changed(framing: CameraFraming)
signal occlusion_pulled_in(from_distance: float, to_distance: float)

var _tuning: TuningData
var _hints: CameraHintStack
var _probe: CameraOccluderProbe = null

var _in_water: bool = false
var _initialised: bool = false

var _position: Vector3 = Vector3.ZERO
var _pitch_deg: float = 0.0
var _yaw_deg: float = 0.0
var _distance: float = 0.0

var _last_position_delta: float = 0.0
var _last_rotation_delta: float = 0.0


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_hints = CameraHintStack.new()


# --- Tuned values (AC-4: read at use time, never cached into a const) --------

func max_position_delta() -> float:
	return _tuning.get_number(MAX_POSITION_DELTA_KEY)


func max_rotation_delta_deg() -> float:
	return _tuning.get_number(MAX_ROTATION_DELTA_KEY)


func position_damping() -> float:
	return _tuning.get_number(POSITION_DAMPING_KEY)


func rotation_damping() -> float:
	return _tuning.get_number(ROTATION_DAMPING_KEY)


func min_distance() -> float:
	return _tuning.get_number(MIN_DISTANCE_KEY)


func collision_margin() -> float:
	return _tuning.get_number(COLLISION_MARGIN_KEY)


## Framing the current grammar asks for, before hints. The two grammars want
## genuinely different framing — water sits further back and closer to level so
## the axolotl can pitch and roll without the camera chasing it; land sits closer
## and looks down more, which reads as a conventional follow.
func base_framing(desired_yaw_deg: float) -> CameraFraming:
	var distance := _tuning.get_number(
		WATER_DISTANCE_KEY if _in_water else LAND_DISTANCE_KEY)
	var pitch := _tuning.get_number(
		WATER_PITCH_KEY if _in_water else LAND_PITCH_KEY)
	return CameraFraming.new(distance, pitch, desired_yaw_deg)


# --- The per-frame update ---------------------------------------------------

## One frame. [param desired_yaw_deg] is supplied by the caller (from the
## movement heading or the player's look input) rather than invented here — the
## rig frames what it is told to frame and never decides where the player wants
## to look.
func update(delta: float, target_position: Vector3, desired_yaw_deg: float) -> void:
	var framing := _resolve_framing(desired_yaw_deg)

	if not _initialised:
		# First frame: there is no previous transform to be smooth relative to,
		# so settling instantly is correct. Clamping here would make every scene
		# open with the camera flying in from the origin.
		_settle(target_position, framing)
		return

	var previous_position := _position
	var previous_pitch := _pitch_deg
	var previous_yaw := _yaw_deg

	_pitch_deg = _clamp_angle_step(previous_pitch,
		_approach_angle(previous_pitch, framing.pitch_deg, delta, rotation_damping()),
		max_rotation_delta_deg())
	_yaw_deg = _clamp_angle_step(previous_yaw,
		_approach_angle(previous_yaw, framing.yaw_deg, delta, rotation_damping()),
		max_rotation_delta_deg())

	_distance = _approach(_distance, framing.distance, delta, position_damping())

	var desired := _orbit_position(target_position, _pitch_deg, _yaw_deg, _distance)
	var stepped := _clamp_step(previous_position, desired, max_position_delta())

	_position = _avoid_geometry(target_position, stepped)

	_last_position_delta = previous_position.distance_to(_position)
	_last_rotation_delta = maxf(
		absf(_shortest_deg(previous_pitch, _pitch_deg)),
		absf(_shortest_deg(previous_yaw, _yaw_deg)))


func _resolve_framing(desired_yaw_deg: float) -> CameraFraming:
	var framing := _hints.resolve(base_framing(desired_yaw_deg))

	# A LOCKED axis holds what the camera already has rather than tracking its
	# target. Locking must never move the camera — a lock that snapped the pitch
	# to some declared value would be an override, and the world already has
	# overrides for that.
	if _initialised:
		if framing.is_locked(CameraFraming.Axis.PITCH):
			framing.pitch_deg = _pitch_deg
		if framing.is_locked(CameraFraming.Axis.YAW):
			framing.yaw_deg = _yaw_deg
		if framing.is_locked(CameraFraming.Axis.DISTANCE):
			framing.distance = _distance

	return framing


func _settle(target_position: Vector3, framing: CameraFraming) -> void:
	_initialised = true
	_pitch_deg = _wrap_deg(framing.pitch_deg)
	_yaw_deg = _wrap_deg(framing.yaw_deg)
	_distance = framing.distance
	_position = _avoid_geometry(target_position,
		_orbit_position(target_position, _pitch_deg, _yaw_deg, _distance))
	_last_position_delta = 0.0
	_last_rotation_delta = 0.0
	framing_changed.emit(framing)


## Collision avoidance runs LAST and is deliberately NOT subject to the per-frame
## clamp. Easing gently into a wall over five frames is precisely the clipping
## AC-2 forbids, so a camera that finds geometry pulls in on the frame it finds
## it. The reverse — returning to the full distance once the wall is gone — goes
## back through the damped, clamped path above, so the asymmetry a player feels
## is "snaps in, eases out", which is the standard and the comfortable one.
func _avoid_geometry(pivot: Vector3, candidate: Vector3) -> Vector3:
	if _probe == null:
		return candidate

	var span := pivot.distance_to(candidate)
	if span <= 0.0:
		return candidate

	var fraction := clampf(_probe.clear_fraction(pivot, candidate), 0.0, 1.0)
	if fraction >= 1.0:
		return candidate

	# Stop short of the contact by the tuned margin: sitting exactly on the
	# surface is a coin flip against the near plane, which reads as clipping.
	var safe := maxf(min_distance(), span * fraction - collision_margin())
	occlusion_pulled_in.emit(span, safe)
	return pivot + (candidate - pivot).normalized() * safe


# --- Public interface: state ------------------------------------------------

## Published by the Game Client from the controller's grammar. See the class
## docstring for why this is a bool rather than a MovementGrammar.
func set_in_water(in_water: bool) -> void:
	_in_water = in_water


func is_in_water() -> bool:
	return _in_water


func get_position() -> Vector3:
	return _position


func get_pitch_deg() -> float:
	return _pitch_deg


func get_yaw_deg() -> float:
	return _yaw_deg


func get_distance() -> float:
	return _distance


## Distance the camera moved on the last update, in metres.
func get_last_position_delta() -> float:
	return _last_position_delta


## Largest single-axis rotation the camera made on the last update, in degrees.
## The larger of the two axes rather than their combined magnitude, because the
## criterion bounds rotation per frame and bounding each axis by the tuned number
## is the stricter reading.
func get_last_rotation_delta_deg() -> float:
	return _last_rotation_delta


func is_settled() -> bool:
	return _initialised


## Re-settles instantly at the next update. For a spawn, a checkpoint respawn or
## a world transition — NOT for ordinary movement, which is what the clamp is
## for. Deliberately does not move the camera itself: the next update does, with
## a target position that is current rather than a frame stale.
func request_resettle() -> void:
	_initialised = false


# --- Public interface: hints ------------------------------------------------

func get_hint_stack() -> CameraHintStack:
	return _hints


func add_hint(hint: CameraHint) -> bool:
	return _hints.add(hint)


func remove_hint(hint_id: String) -> bool:
	return _hints.remove(hint_id)


# --- Public interface: occlusion --------------------------------------------

## Installed once by the Game Client. Without it the rig performs NO collision
## avoidance rather than guessing — see CameraOccluderProbe.
func set_occluder_probe(probe: CameraOccluderProbe) -> void:
	_probe = probe


func get_occluder_probe() -> CameraOccluderProbe:
	return _probe


# --- Maths ------------------------------------------------------------------

## Frame-rate independent exponential approach. Using exp() rather than a raw
## lerp factor means halving the frame time does not halve how fast the camera
## converges, which would make the tuned damping mean something different on
## every machine.
func _approach(current: float, target: float, delta: float, damping: float) -> float:
	if delta <= 0.0:
		return current
	return current + (target - current) * (1.0 - exp(-damping * delta))


func _approach_angle(current: float, target: float, delta: float,
		damping: float) -> float:
	if delta <= 0.0:
		return current
	var difference := _shortest_deg(current, target)
	return _wrap_deg(current + difference * (1.0 - exp(-damping * delta)))


## Signed shortest angular distance in degrees, in -180..180. Without this a yaw
## crossing 180 degrees reads as a 359-degree turn and blows the rotation clamp
## on a frame where the camera barely moved.
static func _shortest_deg(from_deg: float, to_deg: float) -> float:
	return fposmod(to_deg - from_deg + 180.0, 360.0) - 180.0


static func _wrap_deg(value: float) -> float:
	return fposmod(value + 180.0, 360.0) - 180.0


static func _clamp_angle_step(previous: float, proposed: float,
		max_step: float) -> float:
	var difference := _shortest_deg(previous, proposed)
	if absf(difference) <= max_step:
		return _wrap_deg(proposed)
	return _wrap_deg(previous + signf(difference) * max_step)


static func _clamp_step(from: Vector3, to: Vector3, max_length: float) -> Vector3:
	var offset := to - from
	if offset.length() <= max_length:
		return to
	return from + offset.normalized() * max_length


static func _orbit_position(pivot: Vector3, pitch_deg: float, yaw_deg: float,
		distance: float) -> Vector3:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch))
	return pivot + offset * distance
