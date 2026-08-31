class_name AudioSystem
extends RefCounted

## The Audio Event Interface implementation (REQ-023).
##
## Producers send declared events; this node decides what they sound like. No
## producer knows a file path or a bus name.
##
## Deliberately NOT an autoload: it takes its bank, sink and settings store by
## construction, which is what makes it testable under GdUnit4 without
## process-level teardown.

signal cue_played(cue: AudioEvent.Cue, stream_path: String)
signal bed_changed(channel: AudioEvent.Channel, stream_path: String)

var _bank: AudioBank
var _sink: AudioSink
var _store: SettingsStore
var _settings: AudioSettings

var _grammar_bed: AudioEvent.Bed = AudioEvent.Bed.GRAMMAR_LAND
var _region_bed: AudioEvent.Bed = AudioEvent.Bed.REGION_BARREN
var _grammar_bed_set: bool = false
var _region_bed_set: bool = false


func _init(bank: AudioBank, sink: AudioSink, store: SettingsStore = null) -> void:
	_bank = bank
	_sink = sink
	_store = store if store != null else SettingsStore.new()
	_settings = AudioSettings.new()
	_settings.from_dictionary(_store.load_section(AudioSettings.SETTINGS_SECTION))
	_apply_all_volumes()


# --- Cues -------------------------------------------------------------------

## Plays the cue for a declared event. Every cue in the closed set resolves to a
## real stream, so this can never silently do nothing (AC-1, AC-4).
func play_cue(cue: AudioEvent.Cue) -> void:
	var path := _bank.cue_path(cue)
	if path.is_empty():
		push_error("[audio.unresolved_cue] %s: no audio resolved for this cue"
			% AudioEvent.cue_id(cue))
		return
	_sink.play_oneshot(path, AudioEvent.bus_for_cue(cue))
	cue_played.emit(cue, path)


# --- Beds -------------------------------------------------------------------

## Switches the grammar soundscape. Driven off the controller's grammar-change
## signal rather than sampling a water volume independently, so audio can never
## disagree with the controller about which grammar is active (AC-2).
func set_grammar(is_water: bool) -> void:
	var bed := AudioEvent.Bed.GRAMMAR_WATER if is_water else AudioEvent.Bed.GRAMMAR_LAND
	if _grammar_bed_set and bed == _grammar_bed:
		return
	_grammar_bed = bed
	_grammar_bed_set = true
	_set_bed(AudioEvent.Channel.GRAMMAR, bed)


## Shifts the ambient soundscape with a region's restoration state (AC-3).
func set_region_state(bed: AudioEvent.Bed) -> void:
	if bed != AudioEvent.Bed.REGION_BARREN \
			and bed != AudioEvent.Bed.REGION_RESOURCED \
			and bed != AudioEvent.Bed.REGION_RESTORED:
		push_error("[audio.not_a_region_bed] %s: not a restoration state"
			% AudioEvent.bed_id(bed))
		return
	if _region_bed_set and bed == _region_bed:
		return
	_region_bed = bed
	_region_bed_set = true
	_set_bed(AudioEvent.Channel.REGION, bed)


func _set_bed(channel: AudioEvent.Channel, bed: AudioEvent.Bed) -> void:
	var path := _bank.bed_path(bed)
	if path.is_empty():
		push_error("[audio.unresolved_bed] %s: no audio resolved for this bed"
			% AudioEvent.bed_id(bed))
		return
	_sink.set_bed(channel, path, AudioEvent.bus_for_bed(bed))
	bed_changed.emit(channel, path)


func get_grammar_bed() -> AudioEvent.Bed:
	return _grammar_bed


func get_region_bed() -> AudioEvent.Bed:
	return _region_bed


# --- Volumes ----------------------------------------------------------------

## Sets one bus's volume and persists all three. Independently adjustable:
## changing one bus never disturbs another (AC-6).
func set_volume(bus: String, linear: float) -> void:
	_settings.set_volume(bus, linear)
	_sink.set_bus_volume_linear(bus, _settings.get_volume(bus))
	_store.save_section(AudioSettings.SETTINGS_SECTION, _settings.to_dictionary())


func get_volume(bus: String) -> float:
	return _settings.get_volume(bus)


func _apply_all_volumes() -> void:
	for bus: String in AudioEvent.BUSES:
		_sink.set_bus_volume_linear(bus, _settings.get_volume(bus))
