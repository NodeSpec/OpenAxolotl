class_name HeroAnimator
extends RefCounted

## Plays the hero's animation clips from the state the controller already
## knows (REQ-035).
##
## The rig ships six clips (tools/blender/rig_model.py writes them by these
## names, and tools/rig_model.py fails the build if one is missing). Nothing
## here decides gameplay: the body hands over the four facts it has each
## physics step — in water, on the floor, how fast vertically, how fast along
## the ground — and this picks the clip that matches.
##
##   swim     the water grammar, whatever else is true
##   hop      airborne and still rising
##   fall     airborne and descending
##   waddle   grounded and moving
##   idle     grounded and still
##
## HURT is the exception: a one-shot that OVERRIDES the locomotion choice for
## its own length, because a flinch the player cannot see is not feedback. It
## is triggered by the world's capability-loss signal, not by motion.
##
## `choose_clip` is static and pure so the whole state table is testable
## without a scene, an AnimationPlayer, or a frame of simulation.

const IDLE := "idle"
const WADDLE := "waddle"
const SWIM := "swim"
const HOP := "hop"
const FALL := "fall"
const HURT := "hurt"

## Clips that describe an ongoing state rather than an event. Godot's glTF
## import leaves every clip non-looping, so the ongoing ones are set to loop
## here — a one-shot idle would freeze the axolotl after four seconds.
const LOOPING: Array[String] = [IDLE, WADDLE, SWIM, FALL]

## Below this vertical speed a body in the air is neither rising nor falling
## in any way worth animating, and the clip would flicker at the apex.
const RISING_SPEED := 0.5

## Below this planar speed the axolotl is standing still, not waddling. Kept
## in step with the facing hold so the model does not waddle on the spot
## while its heading is frozen.
const MOVING_SPEED := 0.25

## How long clips take to cross-fade. Long enough to hide the switch, short
## enough that a hop still reads as instant.
const BLEND_SECONDS := 0.12

var _player: AnimationPlayer
var _current: String = ""
var _hurt_remaining: float = 0.0


## Which clip a body in this state should be playing.
static func choose_clip(in_water: bool, grounded: bool,
		vertical_speed: float, planar_speed: float) -> String:
	if in_water:
		return SWIM
	if not grounded:
		return HOP if vertical_speed > RISING_SPEED else FALL
	return WADDLE if planar_speed > MOVING_SPEED else IDLE


## Binds the AnimationPlayer the model imported, if it has one. A body with
## no rig (the template walk builds a bare one) simply never animates.
func bind(model: Node) -> bool:
	if model == null:
		return false
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return false
	_player = players[0] as AnimationPlayer
	for name: String in LOOPING:
		if _player.has_animation(name):
			_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	return true


func is_bound() -> bool:
	return _player != null


func get_current_clip() -> String:
	return _current


## The flinch. Overrides locomotion for the clip's own length, so it always
## plays through rather than being cut off by the next step's state.
func play_hurt() -> void:
	if _player == null or not _player.has_animation(HURT):
		return
	_hurt_remaining = _player.get_animation(HURT).length
	_current = HURT
	_player.play(HURT, BLEND_SECONDS)


func step(delta: float, in_water: bool, grounded: bool,
		velocity: Vector3) -> void:
	if _player == null:
		return
	if _hurt_remaining > 0.0:
		_hurt_remaining -= delta
		return

	var planar := Vector2(velocity.x, velocity.z).length()
	var wanted := choose_clip(in_water, grounded, velocity.y, planar)
	if wanted != _current and _player.has_animation(wanted):
		_current = wanted
		_player.play(wanted, BLEND_SECONDS)

	# A waddle at half speed should not play at full tempo: tying playback to
	# travel is what stops the legs from skating over the ground.
	if _current == WADDLE:
		_player.speed_scale = clampf(planar / 2.5, 0.6, 1.8)
	elif _current == SWIM:
		_player.speed_scale = clampf(velocity.length() / 6.0, 0.5, 1.8)
	else:
		_player.speed_scale = 1.0
