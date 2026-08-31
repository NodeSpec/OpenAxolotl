class_name GodotAudioSink
extends AudioSink

## The production [AudioSink]: routes resolved requests to the engine.
##
## Beds crossfade rather than cut, and re-setting a channel to the path it
## already holds is a no-op — a redundant grammar signal must not restart the
## ambience mid-swim.

const CROSSFADE_SECONDS := 0.75

var _root: Node
var _bed_players: Dictionary = {}
var _bed_paths: Dictionary = {}


## [param root] is the node the sink parents its players to. Passed in rather
## than resolved from a singleton, so the sink stays testable and a scene owns
## its own lifetime.
func _init(root: Node) -> void:
	_root = root


func play_oneshot(stream_path: String, bus: String) -> void:
	var stream := _load_stream(stream_path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	_root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func set_bed(channel: AudioEvent.Channel, stream_path: String, bus: String) -> void:
	if String(_bed_paths.get(channel, "")) == stream_path:
		return  # already playing this bed on this channel

	var stream := _load_stream(stream_path)
	if stream == null:
		return

	var outgoing: AudioStreamPlayer = _bed_players.get(channel, null) as AudioStreamPlayer
	var incoming := AudioStreamPlayer.new()
	incoming.stream = stream
	incoming.bus = bus
	incoming.volume_db = -60.0
	_root.add_child(incoming)
	incoming.play()

	var tween := _root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_SECONDS)
	if outgoing != null:
		tween.tween_property(outgoing, "volume_db", -60.0, CROSSFADE_SECONDS)
		tween.chain().tween_callback(outgoing.queue_free)

	_bed_players[channel] = incoming
	_bed_paths[channel] = stream_path


func set_bus_volume_linear(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_error("[audio.unknown_bus] %s: no such audio bus" % bus)
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))


func _load_stream(stream_path: String) -> AudioStream:
	if not ResourceLoader.exists(stream_path):
		push_error("[audio.stream_missing] %s: no audio resource at that path" % stream_path)
		return null
	return ResourceLoader.load(stream_path) as AudioStream
