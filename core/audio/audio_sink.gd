class_name AudioSink
extends RefCounted

## Where resolved audio actually goes (REQ-023).
##
## Headless CI has no audio device, so [AudioSystem] never touches the engine
## directly — it resolves an event to a path and a bus and hands the request to a
## sink. Production uses [GodotAudioSink]; tests substitute a recording double and
## assert on the resolved playback REQUESTS rather than on sound.
##
## This is also what keeps the criteria checkable at all: "a distinct cue plays
## for every capability loss" is an assertion about what was requested, which a
## test can make, rather than about what was heard, which it cannot.

## Plays a one-shot cue.
func play_oneshot(_stream_path: String, _bus: String) -> void:
	pass


## Sets the looping bed on a channel, crossfading from whatever it held.
## Passing the same path the channel already holds is a no-op, so a redundant
## grammar signal never restarts the bed.
func set_bed(_channel: AudioEvent.Channel, _stream_path: String, _bus: String) -> void:
	pass


func set_bus_volume_linear(_bus: String, _linear: float) -> void:
	pass
