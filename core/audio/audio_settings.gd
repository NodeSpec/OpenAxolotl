class_name AudioSettings
extends RefCounted

## Master, music and effects volumes — independently adjustable and persisted
## across sessions (REQ-023 AC-6).
##
## Persistence goes through the Save Integration Interface's settings path,
## alongside input bindings, NOT a private file of this node's own. The Save
## System supplies the concrete store; this node declares only the port it needs,
## so Audio can be built and tested before Save exists.

const SETTINGS_SECTION := "audio"
const DEFAULT_VOLUME := 0.8

var _volumes: Dictionary = {}


func _init() -> void:
	for bus: String in AudioEvent.BUSES:
		_volumes[bus] = DEFAULT_VOLUME


## Volumes are linear 0.0–1.0; the sink converts to dB. Out-of-range input is
## clamped rather than rejected — a settings slider cannot produce a meaningful
## error, and refusing to load a profile over a bad volume would be worse than
## clamping it.
func set_volume(bus: String, linear: float) -> void:
	if not AudioEvent.BUSES.has(bus):
		push_error("[audio.unknown_bus] %s: not one of Master/Music/Effects" % bus)
		return
	_volumes[bus] = clampf(linear, 0.0, 1.0)


func get_volume(bus: String) -> float:
	return float(_volumes.get(bus, DEFAULT_VOLUME))


## The payload handed to the settings store. Flat and primitive so the save
## format stays readable and versionable.
func to_dictionary() -> Dictionary:
	return _volumes.duplicate()


func from_dictionary(stored: Dictionary) -> void:
	for bus: String in AudioEvent.BUSES:
		if stored.has(bus):
			set_volume(bus, float(stored[bus]))
