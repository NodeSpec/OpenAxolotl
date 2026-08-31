class_name AudioBank
extends RefCounted

## Resolves an [AudioEvent] to the audio resource that should play (REQ-023).
##
## A world may declare its own music and ambience through the Level Contract; a
## world declaring none falls back to defaults rather than to silence (AC-5).
## Resolution happens ONCE at world load — [method resolve] holds the resolved
## set — so the fallback path is taken at load rather than re-tested on every
## playback.
##
## The bank is total by construction: [method resolve] refuses a default set that
## does not cover every declared cue and bed, because a gap would surface at
## runtime as silence instead of as a failure.

var _cues: Dictionary = {}
var _beds: Dictionary = {}
var _world_overridden: PackedStringArray = []
var _errors: Array[TuningError] = []


## Builds the resolved bank. [param defaults] must cover every cue and bed;
## [param world_declared] may override any subset and may be empty.
##
## Returns null and populates [param out_errors] when the defaults are
## incomplete — a world is allowed to declare nothing, but the project is never
## allowed to ship an incomplete default set.
static func resolve(
	defaults: Dictionary,
	world_declared: Dictionary,
	out_errors: Array[TuningError] = []
) -> AudioBank:
	var bank := AudioBank.new()

	for cue: AudioEvent.Cue in AudioEvent.all_cues():
		var id := AudioEvent.cue_id(cue)
		if not defaults.has(id) or String(defaults[id]).is_empty():
			out_errors.append(TuningError.new(
				"audio.default_missing", id,
				"default audio bank has no entry for cue '%s'" % id))
			continue
		bank._cues[cue] = String(defaults[id])

	for bed: AudioEvent.Bed in AudioEvent.all_beds():
		var id := AudioEvent.bed_id(bed)
		if not defaults.has(id) or String(defaults[id]).is_empty():
			out_errors.append(TuningError.new(
				"audio.default_missing", id,
				"default audio bank has no entry for bed '%s'" % id))
			continue
		bank._beds[bed] = String(defaults[id])

	if not out_errors.is_empty():
		return null

	# A world declaring nothing is legal and common — the reference template
	# declares no optional elements at all, and it must still be audible.
	for key: Variant in world_declared:
		var id := String(key)
		var path := String(world_declared[key])
		if path.is_empty():
			out_errors.append(TuningError.new(
				"audio.world_entry_empty", id,
				"world declared an empty audio path; omit the key to take the default"))
			continue

		var matched := false
		for cue: AudioEvent.Cue in AudioEvent.all_cues():
			if AudioEvent.cue_id(cue) == id:
				bank._cues[cue] = path
				matched = true
				break
		if not matched:
			for bed: AudioEvent.Bed in AudioEvent.all_beds():
				if AudioEvent.bed_id(bed) == id:
					bank._beds[bed] = path
					matched = true
					break

		if not matched:
			out_errors.append(TuningError.new(
				"audio.unknown_event", id,
				"world declared audio for an event that does not exist"))
			continue

		bank._world_overridden.append(id)

	if not out_errors.is_empty():
		return null
	return bank


func cue_path(cue: AudioEvent.Cue) -> String:
	return String(_cues.get(cue, ""))


func bed_path(bed: AudioEvent.Bed) -> String:
	return String(_beds.get(bed, ""))


## True when this entry came from the world rather than the defaults. Used by
## tests to prove the fallback actually fell back.
func is_world_supplied(id: String) -> bool:
	return _world_overridden.has(id)


func get_world_supplied_ids() -> PackedStringArray:
	return _world_overridden.duplicate()


## Every cue resolves to a non-empty path — the property that makes "falls back
## to defaults rather than silence" checkable.
func is_total() -> bool:
	for cue: AudioEvent.Cue in AudioEvent.all_cues():
		if cue_path(cue).is_empty():
			return false
	for bed: AudioEvent.Bed in AudioEvent.all_beds():
		if bed_path(bed).is_empty():
			return false
	return true
