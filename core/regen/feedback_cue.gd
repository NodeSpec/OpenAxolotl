class_name FeedbackCue
extends RefCounted

## The feedback one capability event asks for (REQ-019 AC-2).
##
## BOTH channels are mandatory, and the criterion says so: "triggers both a
## visual and an audio feedback cue". A player with the sound off must still see
## the tail go, and a player looking elsewhere must still hear it. Either field
## left empty is a test failure, not a soft default — silence and stillness are
## how a signature mechanic becomes invisible.
##
## The audio side is a SEMANTIC event id from the Audio Event Interface's closed
## set, never a file path. This node emits "tail lost"; the Audio System alone
## decides what that sounds like (REQ-023).

## Stable event id, e.g. "capability_lost_tail". Also the key the table is
## indexed by.
var event_id: String = ""

## Particle or animation id the visual layer resolves. Never a file path here
## either, for the same reason the audio side is not one.
var visual_id: String = ""

## AudioEvent.Cue.
var audio_cue: AudioEvent.Cue = AudioEvent.Cue.CAPABILITY_LOST_TAIL

## Short description of the intended read. Carried as data so the tone review
## (REQ-019, manual) has something concrete to check each cue against rather than
## re-deriving intent from a particle name.
var tone_note: String = ""


func _init(p_event_id: String = "", p_visual_id: String = "",
		p_audio_cue: AudioEvent.Cue = AudioEvent.Cue.CAPABILITY_LOST_TAIL,
		p_tone_note: String = "") -> void:
	event_id = p_event_id
	visual_id = p_visual_id
	audio_cue = p_audio_cue
	tone_note = p_tone_note


## True only when BOTH channels are populated. The criterion is "both", so a cue
## that is half-declared is not a cue.
func is_complete() -> bool:
	return not event_id.is_empty() \
		and not visual_id.is_empty() \
		and not tone_note.is_empty()
