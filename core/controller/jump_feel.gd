class_name JumpFeel
extends RefCounted

## The three forgiveness rules that separate "the character jumps" from "the
## jump feels fair" (REQ-037).
##
## None of these change where the axolotl CAN go on a perfectly-timed input;
## they change how much timing precision the player is asked for. That is why
## they matter for a platformer built around gaps: without them, a gap the
## arc can clear still reads as broken, because the player's honest attempt
## gets eaten by a one-frame window.
##
##   COYOTE TIME. Walking off a ledge leaves a brief window in which the hop
##   still fires. Players press jump a few frames after the edge far more
##   often than a few frames before it, and without this those presses vanish
##   silently — the single most common "the controls are broken" complaint in
##   a 3D platformer.
##
##   JUMP BUFFERING. A hop pressed while still falling is REMEMBERED and
##   fires on landing. Without it, arriving on a platform and immediately
##   jumping again requires hitting the exact landing frame, which makes
##   chained jumps feel like a dice roll.
##
##   VARIABLE HEIGHT. Releasing the button while still rising cuts the climb.
##   One button then expresses a whole range of heights, which is what lets a
##   level ask for a small hop onto a low ledge and a full leap across a gap
##   without adding a second verb.
##
## THE TIMERS LIVE HERE, not in the controller, for the same reason the
## entanglement timer lives in the Drift Fleet: this is pure arithmetic over
## time and can be proven frame by frame in a test with no scene, no physics
## server and no floor to stand on.
##
## Every window is a tuning key read live (REQ-025), so the feel can be
## retuned without a recompile — and set to zero, every rule disables itself
## and the jump reverts to the strict grounded-only hop.

const COYOTE_KEY := "controller.hop.coyote_seconds"
const BUFFER_KEY := "controller.hop.buffer_seconds"
const CUT_KEY := "controller.hop.release_cut_ratio"

var _tuning: TuningData

## Seconds of coyote window still available. Counts down only while airborne
## and only when the fall was NOT started by a hop.
var _coyote_remaining: float = 0.0

## Seconds a remembered hop press stays valid.
var _buffer_remaining: float = 0.0

## Whether the hop verb was held on the previous step, so a RELEASE can be
## distinguished from simply never having pressed it.
var _was_holding: bool = false

## Set when a hop fires and cleared on landing: a jump the player chose to
## end early must not also be eligible for coyote time on the way down.
var _airborne_by_hop: bool = false


func _init(tuning: TuningData) -> void:
	_tuning = tuning


## Advances the windows. `grounded` is the body's own floor flag, and
## `pressed` is the EDGE-triggered hop verb — true on the frame the button went
## down and not while it stays down. `cut_rise` takes the held state instead;
## the two are separate arguments because they answer different questions.
func step(delta: float, grounded: bool, pressed: bool) -> void:
	if grounded:
		# Landing refills the coyote window and ends the hop's ownership of
		# the fall, so the next step off a ledge is forgiven again.
		_coyote_remaining = _tuning.get_number(COYOTE_KEY)
		_airborne_by_hop = false
	else:
		_coyote_remaining = maxf(_coyote_remaining - delta, 0.0)

	# A press is remembered on the RISING edge only. The Input System already
	# delivers hop as an edge verb, so this is belt and braces: were a caller
	# ever to pass a held flag here, a player who never let go would hop again
	# the instant they touched anything, forever.
	if pressed and not _was_holding:
		_buffer_remaining = _tuning.get_number(BUFFER_KEY)
	else:
		_buffer_remaining = maxf(_buffer_remaining - delta, 0.0)
	_was_holding = pressed


## True when a hop should fire this step: the player asked (now, or recently
## enough to still be buffered) and the ground is either under them or was
## under them recently enough to be forgiven.
func should_hop(grounded: bool, pressed: bool) -> bool:
	var asked := pressed or _buffer_remaining > 0.0
	var footing := grounded or (_coyote_remaining > 0.0 and not _airborne_by_hop)
	return asked and footing


## Called by the controller when it actually applies the impulse, so the
## windows that authorised it are spent rather than authorising a second one.
func consume() -> void:
	_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	_airborne_by_hop = true


## The vertical velocity after applying the release cut. `holding` is the
## SUSTAINED hop input, not the edge verb — an edge verb is false on every frame
## after launch, so reading it here would cut every jump.
##
## Only ever reduces a RISING velocity: cutting a fall would be a mid-air brake,
## and cutting a rise the player is still asking for would steal the full jump.
func cut_rise(vertical_speed: float, holding: bool) -> float:
	if holding or vertical_speed <= 0.0 or not _airborne_by_hop:
		return vertical_speed
	return vertical_speed * clampf(_tuning.get_number(CUT_KEY), 0.0, 1.0)


func get_coyote_remaining() -> float:
	return _coyote_remaining


func get_buffer_remaining() -> float:
	return _buffer_remaining
