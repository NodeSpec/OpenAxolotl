extends GdUnitTestSuite

## Audio System — REQ-023.
##
## Headless CI has no audio device, so every assertion is about the resolved
## playback REQUEST, not about sound. That is what the AudioSink port exists for.

const BANK_PATH := "res://core/audio/default_bank.json"


## Recording double for [AudioSink]. Captures what the system asked for.
class RecordingSink extends AudioSink:
	var oneshots: Array[Dictionary] = []
	var beds: Array[Dictionary] = []
	var volumes: Dictionary = {}

	func play_oneshot(stream_path: String, bus: String) -> void:
		oneshots.append({"path": stream_path, "bus": bus})

	func set_bed(channel: AudioEvent.Channel, stream_path: String, bus: String) -> void:
		beds.append({"channel": channel, "path": stream_path, "bus": bus})

	func set_bus_volume_linear(bus: String, linear: float) -> void:
		volumes[bus] = linear


## In-memory double for the Save Integration Interface's settings path.
class FakeStore extends SettingsStore:
	var sections: Dictionary = {}

	func load_section(section: String) -> Dictionary:
		return (sections.get(section, {}) as Dictionary).duplicate()

	func save_section(section: String, payload: Dictionary) -> void:
		sections[section] = payload.duplicate()


func _defaults() -> Dictionary:
	var handle := FileAccess.open(BANK_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	var root := parsed as Dictionary
	var flat: Dictionary = {}
	for key: Variant in (root["cues"] as Dictionary):
		flat[String(key)] = String((root["cues"] as Dictionary)[key])
	for key: Variant in (root["beds"] as Dictionary):
		flat[String(key)] = String((root["beds"] as Dictionary)[key])
	return flat


func _bank(world_declared: Dictionary = {}) -> AudioBank:
	var errors: Array[TuningError] = []
	var bank := AudioBank.resolve(_defaults(), world_declared, errors)
	assert_array(errors).is_empty()
	assert_object(bank).is_not_null()
	return bank


func _system(world_declared: Dictionary = {}) -> Array:
	var sink := RecordingSink.new()
	var store := FakeStore.new()
	return [AudioSystem.new(_bank(world_declared), sink, store), sink, store]


# --- AC-1: distinct cue for every capability loss and regrowth --------------

func test_req_023_every_capability_cue_resolves_and_is_distinct() -> void:
	var bank := _bank()
	var seen: Dictionary = {}

	for cue: AudioEvent.Cue in AudioEvent.CAPABILITY_CUES:
		var path := bank.cue_path(cue)
		assert_str(path).override_failure_message(
			"REQ-023 AC-1: capability cue '%s' resolves to nothing"
			% AudioEvent.cue_id(cue)).is_not_empty()
		assert_bool(seen.has(path)).override_failure_message(
			"REQ-023 AC-1: '%s' shares a stream with '%s' — cues must be distinct"
			% [AudioEvent.cue_id(cue), String(seen.get(path, ""))]).is_false()
		seen[path] = AudioEvent.cue_id(cue)

	assert_int(seen.size()).is_equal(AudioEvent.CAPABILITY_CUES.size())


func test_req_023_playing_a_capability_cue_requests_its_stream_on_the_effects_bus() -> void:
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.play_cue(AudioEvent.Cue.CAPABILITY_LOST_TAIL)

	assert_int(sink.oneshots.size()).is_equal(1)
	assert_str(String(sink.oneshots[0]["bus"])).is_equal(AudioEvent.BUS_EFFECTS)
	assert_str(String(sink.oneshots[0]["path"])).is_not_empty()


# --- AC-4: per-mod distinct Gill Mod cue ------------------------------------

func test_req_023_every_gill_mod_has_a_distinct_activation_cue() -> void:
	var bank := _bank()
	var seen: Dictionary = {}

	for cue: AudioEvent.Cue in AudioEvent.GILL_MOD_CUES:
		var path := bank.cue_path(cue)
		assert_str(path).is_not_empty()
		assert_bool(seen.has(path)).override_failure_message(
			"REQ-023 AC-4: Gill Mod cue '%s' is not distinct"
			% AudioEvent.cue_id(cue)).is_false()
		seen[path] = true

	assert_int(seen.size()).is_equal(3)  # Bubble, Jet, Glow at MVP


# --- AC-2: grammar beds switch with the transition -------------------------

func test_req_023_grammar_change_switches_the_bed() -> void:
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.set_grammar(true)
	system.set_grammar(false)

	assert_int(sink.beds.size()).is_equal(2)
	assert_str(String(sink.beds[0]["path"])).is_not_equal(String(sink.beds[1]["path"]))
	assert_int(int(sink.beds[0]["channel"])).is_equal(AudioEvent.Channel.GRAMMAR)


func test_req_023_redundant_grammar_signal_does_not_restart_the_bed() -> void:
	# A controller may re-assert its grammar; the ambience must not stutter.
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.set_grammar(true)
	system.set_grammar(true)
	system.set_grammar(true)

	assert_int(sink.beds.size()).is_equal(1)


# --- AC-3: restoration state shifts the ambient soundscape ------------------

func test_req_023_region_state_change_shifts_ambience() -> void:
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.set_region_state(AudioEvent.Bed.REGION_BARREN)
	system.set_region_state(AudioEvent.Bed.REGION_RESOURCED)
	system.set_region_state(AudioEvent.Bed.REGION_RESTORED)

	assert_int(sink.beds.size()).is_equal(3)
	var paths: Dictionary = {}
	for entry: Dictionary in sink.beds:
		assert_int(int(entry["channel"])).is_equal(AudioEvent.Channel.REGION)
		paths[String(entry["path"])] = true
	assert_int(paths.size()).override_failure_message(
		"REQ-023 AC-3: the three restoration states must sound different").is_equal(3)


func test_req_023_grammar_and_region_beds_occupy_separate_channels() -> void:
	# Crossing into water must not reset a region's restored soundscape.
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.set_region_state(AudioEvent.Bed.REGION_RESTORED)
	system.set_grammar(true)

	assert_int(sink.beds.size()).is_equal(2)
	assert_int(int(sink.beds[0]["channel"])).is_equal(AudioEvent.Channel.REGION)
	assert_int(int(sink.beds[1]["channel"])).is_equal(AudioEvent.Channel.GRAMMAR)
	assert_int(int(system.get_region_bed())).is_equal(AudioEvent.Bed.REGION_RESTORED)


# --- AC-5: world-declared audio, with a real fallback ----------------------

func test_req_023_world_declaring_no_audio_falls_back_to_defaults_not_silence() -> void:
	var bank := _bank({})  # the reference template declares nothing

	assert_bool(bank.is_total()).override_failure_message(
		"REQ-023 AC-5: a world declaring no audio must still resolve every event"
	).is_true()
	assert_array(bank.get_world_supplied_ids()).is_empty()


func test_req_023_world_declared_audio_overrides_only_what_it_declares() -> void:
	var custom := "res://worlds/coral_cove/audio/cove_water.ogg"
	var bank := _bank({"grammar_water": custom})

	assert_str(bank.bed_path(AudioEvent.Bed.GRAMMAR_WATER)).is_equal(custom)
	assert_bool(bank.is_world_supplied("grammar_water")).is_true()
	# Everything it did not declare still resolves, from the defaults.
	assert_bool(bank.is_total()).is_true()
	assert_bool(bank.is_world_supplied("grammar_land")).is_false()
	assert_str(bank.bed_path(AudioEvent.Bed.GRAMMAR_LAND)).is_not_empty()


func test_req_023_world_declaring_an_unknown_event_is_rejected() -> void:
	var errors: Array[TuningError] = []
	var bank := AudioBank.resolve(
		_defaults(), {"grammar_lava": "res://nope.ogg"}, errors)

	assert_object(bank).is_null()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal("audio.unknown_event")


func test_req_023_incomplete_default_bank_is_rejected() -> void:
	# A world may declare nothing, but the project may never ship an incomplete
	# default set — that would be silence at runtime instead of a failure.
	var defaults := _defaults()
	defaults.erase("grammar_land")

	var errors: Array[TuningError] = []
	var bank := AudioBank.resolve(defaults, {}, errors)

	assert_object(bank).is_null()
	assert_int(errors.size()).is_greater(0)
	assert_str(errors[0].code).is_equal("audio.default_missing")


# --- AC-6: independent, persisted volumes ----------------------------------

func test_req_023_the_three_buses_are_independently_adjustable() -> void:
	var parts := _system()
	var system := parts[0] as AudioSystem
	var sink := parts[1] as RecordingSink

	system.set_volume(AudioEvent.BUS_MUSIC, 0.25)

	assert_float(system.get_volume(AudioEvent.BUS_MUSIC)).is_equal_approx(0.25, 0.0001)
	# Adjusting one bus leaves the others where they were.
	assert_float(system.get_volume(AudioEvent.BUS_MASTER)).is_equal_approx(
		AudioSettings.DEFAULT_VOLUME, 0.0001)
	assert_float(system.get_volume(AudioEvent.BUS_EFFECTS)).is_equal_approx(
		AudioSettings.DEFAULT_VOLUME, 0.0001)
	assert_float(float(sink.volumes[AudioEvent.BUS_MUSIC])).is_equal_approx(0.25, 0.0001)


func test_req_023_volumes_persist_across_sessions() -> void:
	var store := FakeStore.new()
	var first := AudioSystem.new(_bank(), RecordingSink.new(), store)
	first.set_volume(AudioEvent.BUS_MASTER, 0.4)
	first.set_volume(AudioEvent.BUS_EFFECTS, 0.6)

	# A new session over the same store — the save file survived, the object did not.
	var second := AudioSystem.new(_bank(), RecordingSink.new(), store)

	assert_float(second.get_volume(AudioEvent.BUS_MASTER)).is_equal_approx(0.4, 0.0001)
	assert_float(second.get_volume(AudioEvent.BUS_EFFECTS)).is_equal_approx(0.6, 0.0001)
	assert_float(second.get_volume(AudioEvent.BUS_MUSIC)).is_equal_approx(
		AudioSettings.DEFAULT_VOLUME, 0.0001)


func test_req_023_volume_is_clamped_rather_than_rejected() -> void:
	var parts := _system()
	var system := parts[0] as AudioSystem

	system.set_volume(AudioEvent.BUS_MASTER, 4.2)
	assert_float(system.get_volume(AudioEvent.BUS_MASTER)).is_equal_approx(1.0, 0.0001)

	system.set_volume(AudioEvent.BUS_MASTER, -3.0)
	assert_float(system.get_volume(AudioEvent.BUS_MASTER)).is_equal_approx(0.0, 0.0001)


func test_req_023_settings_persist_under_the_save_systems_section() -> void:
	# Audio settings live in the save system's settings path alongside input
	# bindings, not in a private file of this node's own.
	var store := FakeStore.new()
	var system := AudioSystem.new(_bank(), RecordingSink.new(), store)
	system.set_volume(AudioEvent.BUS_MUSIC, 0.1)

	assert_bool(store.sections.has(AudioSettings.SETTINGS_SECTION)).is_true()


# --- Closed event set: totality --------------------------------------------

func test_req_023_default_bank_covers_the_entire_closed_event_set() -> void:
	var bank := _bank()
	for cue: AudioEvent.Cue in AudioEvent.all_cues():
		assert_str(bank.cue_path(cue)).override_failure_message(
			"no default for cue '%s'" % AudioEvent.cue_id(cue)).is_not_empty()
	for bed: AudioEvent.Bed in AudioEvent.all_beds():
		assert_str(bank.bed_path(bed)).override_failure_message(
			"no default for bed '%s'" % AudioEvent.bed_id(bed)).is_not_empty()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_audio_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	var sources: PackedStringArray = [
		"res://core/audio/audio_event.gd",
		"res://core/audio/audio_bank.gd",
		"res://core/audio/audio_sink.gd",
		"res://core/audio/godot_audio_sink.gd",
		"res://core/audio/audio_settings.gd",
		"res://core/audio/settings_store.gd",
		"res://core/audio/audio_system.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
