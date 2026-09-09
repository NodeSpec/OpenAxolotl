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
## ACTIONS are the exception: one-shots that OVERRIDE the locomotion choice for
## their own length, because a movement the player asked for and cannot see did
## not happen as far as they are concerned. Four of them, and none is chosen
## from motion — each is triggered by the controller announcing the verb:
##
##   hurt   the flinch, from the world's capability-loss signal
##   roll   the land dodge
##   spin   the water sprint, which is also the water strike
##   whack  the tail swing
##
## A model whose rig predates one of these simply does not play it (the clip is
## absent, `has_animation` says so, and locomotion carries on) — which is the
## same rule that lets a body with no AnimationPlayer at all keep running.
##
## `choose_clip` is static and pure so the whole state table is testable
## without a scene, an AnimationPlayer, or a frame of simulation.

const IDLE := "idle"
const WADDLE := "waddle"
const SWIM := "swim"
const HOP := "hop"
const FALL := "fall"
const HURT := "hurt"
const ROLL := "roll"
const SPIN := "spin"
const WHACK := "whack"

## Clips that describe an ongoing state rather than an event. Godot's glTF
## import leaves every clip non-looping, so the ongoing ones are set to loop
## here — a one-shot idle would freeze the axolotl after four seconds.
const LOOPING: Array[String] = [IDLE, WADDLE, SWIM, FALL]

## The one-shots, in the order a clash is resolved: a flinch outranks a dodge,
## because being hit interrupts what you were doing. Anything already playing
## from this list is otherwise left to finish.
const ACTIONS: Array[String] = [HURT, ROLL, SPIN, WHACK]

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

## The one-shot currently overriding locomotion, and how much of it is left.
var _action: String = ""
var _action_remaining: float = 0.0


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
	play_action(HURT)


## Plays a one-shot over locomotion.
##
## When [param target_duration] is positive, the imported clip is time-scaled
## so its visible motion lasts exactly as long as the gameplay action that
## triggered it. This is the gameplay/presentation seam for REQ-035: a 0.38 s
## dodge must not keep showing a one-second roll after control has returned, and
## a short clip must not visibly finish while the body is still committed.
##
## A negative target keeps legacy behaviour and uses the authored clip length.
## Returns false when there is nothing to play — no player, no such clip, or a
## higher-ranked action already running.
func play_action(action: String, target_duration: float = -1.0) -> bool:
	if _player == null or not _player.has_animation(action):
		return false
	if not ACTIONS.has(action):
		return false
	# A flinch interrupts a dodge; a dodge does not interrupt a flinch. Being
	# hit is the more important thing to have seen.
	if _action_remaining > 0.0 \
			and ACTIONS.find(_action) <= ACTIONS.find(action):
		return false

	var clip := _player.get_animation(action)
	var authored_length := clip.length
	var visible_duration := target_duration if target_duration > 0.0 \
		else authored_length
	if visible_duration <= 0.0:
		return false

	_action = action
	_action_remaining = visible_duration
	_current = action
	# AnimationPlayer speed_scale multiplies playback rate. A 1.0 s authored
	# clip targeting a 0.5 s gameplay window therefore runs at 2x; a 0.25 s clip
	# targeting 0.5 s runs at 0.5x. The visual and the mechanic end together.
	_player.speed_scale = authored_length / visible_duration
	_player.play(action, BLEND_SECONDS)
	return true


## The one-shot currently overriding locomotion, or "".
func get_current_action() -> String:
	return _action if _action_remaining > 0.0 else ""


func step(delta: float, in_water: bool, grounded: bool,
		velocity: Vector3) -> void:
	if _player == null:
		return
	if _action_remaining > 0.0:
		_action_remaining -= delta
		if _action_remaining > 0.0:
			return
		_action = ""

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
