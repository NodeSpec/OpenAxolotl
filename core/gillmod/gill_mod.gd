class_name GillMod
extends RefCounted

## One Gill Mod, declared entirely as DATA (REQ-004).
##
## This is the shape the whole extensibility claim rests on. A mod is a
## declaration — an identity, the affordances it grants, the tuning keys holding
## its duration and cooldown, and the semantic ids the audio, HUD and visual
## layers resolve — and NOT a script. That is what lets a fourth mod arrive as a
## file dropped in a directory rather than as a case added to a match statement
## somewhere in this node.
##
## The AFFORDANCE is the mechanism. A mod does not carry behaviour; it names
## capabilities, and the world gates a path on `has_affordance("jet_dash")`. A
## post-MVP mod, or a world's custom one, plugs into exactly the same gate
## without this directory knowing it exists.
##
## Audio and visual ids are SEMANTIC strings rather than typed enum members on
## purpose. The Audio System's cue enum is a closed set covering the three MVP
## mods; a fourth mod cannot add to it, so a mod declares an id and the Audio
## System resolves it through its bank — an unknown id surfaces as that node's
## named audio.unknown_event error rather than as silence. A world shipping a
## custom mod ships its bank entry too.

const FIELD_ID := "id"
const FIELD_NAME := "displayName"
const FIELD_AFFORDANCES := "affordances"
const FIELD_DURATION_KEY := "durationKey"
const FIELD_COOLDOWN_KEY := "cooldownKey"
const FIELD_AUDIO_CUE := "audioCueId"
const FIELD_VISUAL := "visualId"
const FIELD_HUD_ICON := "hudIcon"

const REQUIRED_FIELDS: PackedStringArray = [
	FIELD_ID, FIELD_NAME, FIELD_AFFORDANCES, FIELD_DURATION_KEY,
	FIELD_COOLDOWN_KEY, FIELD_AUDIO_CUE, FIELD_VISUAL, FIELD_HUD_ICON,
]

var id: String = ""
var display_name: String = ""

## What this mod unlocks. At least one, and no two registered mods may grant the
## same affordance — see GillModRegistry for why that is enforced rather than
## merely hoped for.
var affordances: PackedStringArray = []

## Tuning keys, not values. Read at activation so retuning takes effect with no
## recompile (REQ-025).
var duration_key: String = ""
var cooldown_key: String = ""

## Semantic ids for the layers that present this mod. Never file paths.
var audio_cue_id: String = ""
var visual_id: String = ""
var hud_icon: String = ""


## Parses a declaration. Returns null and appends a NAMED error rather than a
## half-built mod, so a malformed declaration cannot register as something that
## looks equipped and does nothing.
static func from_dictionary(source: Dictionary,
		out_errors: Array[GillModError] = []) -> GillMod:
	var declared_id := String(source.get(FIELD_ID, ""))

	for field: String in REQUIRED_FIELDS:
		if not source.has(field):
			out_errors.append(GillModError.new(GillModError.MISSING_FIELD,
				declared_id, "declaration is missing '%s'" % field))
			return null

	var mod := GillMod.new()
	mod.id = declared_id
	mod.display_name = String(source[FIELD_NAME])
	mod.duration_key = String(source[FIELD_DURATION_KEY])
	mod.cooldown_key = String(source[FIELD_COOLDOWN_KEY])
	mod.audio_cue_id = String(source[FIELD_AUDIO_CUE])
	mod.visual_id = String(source[FIELD_VISUAL])
	mod.hud_icon = String(source[FIELD_HUD_ICON])

	for entry: Variant in (source[FIELD_AFFORDANCES] as Array):
		mod.affordances.append(String(entry))

	if mod.id.is_empty():
		out_errors.append(GillModError.new(GillModError.MISSING_FIELD,
			"", "a mod declaration needs a non-empty id"))
		return null

	# A mod granting nothing could be equipped and activated and change nothing,
	# which is the "shallow one-note gimmick" the requirement rules out at its
	# most extreme. The criterion says each mod unlocks AT LEAST ONE affordance.
	if mod.affordances.is_empty():
		out_errors.append(GillModError.new(GillModError.NO_AFFORDANCES,
			mod.id, "a mod must unlock at least one affordance"))
		return null

	for field: String in [FIELD_NAME, FIELD_DURATION_KEY, FIELD_COOLDOWN_KEY,
			FIELD_AUDIO_CUE, FIELD_VISUAL, FIELD_HUD_ICON]:
		if String(source[field]).is_empty():
			out_errors.append(GillModError.new(GillModError.MISSING_FIELD,
				mod.id, "'%s' is declared but empty" % field))
			return null

	return mod


func grants(affordance: String) -> bool:
	return affordances.find(affordance) != -1


func to_dictionary() -> Dictionary:
	var out: Array[String] = []
	for affordance: String in affordances:
		out.append(affordance)
	return {
		FIELD_ID: id,
		FIELD_NAME: display_name,
		FIELD_AFFORDANCES: out,
		FIELD_DURATION_KEY: duration_key,
		FIELD_COOLDOWN_KEY: cooldown_key,
		FIELD_AUDIO_CUE: audio_cue_id,
		FIELD_VISUAL: visual_id,
		FIELD_HUD_ICON: hud_icon,
	}
