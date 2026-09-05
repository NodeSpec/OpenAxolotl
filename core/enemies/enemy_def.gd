class_name EnemyDef
extends RefCounted

## One Drift Fleet enemy, declared entirely as DATA (REQ-012 AC-5).
##
## The same shape the Gill Mod extensibility claim rests on: an enemy is a
## declaration — an identity, a BEHAVIOR from the closed set the framework
## implements, and the tuning keys and affordance ids that behavior needs — and
## NOT a script. A fifth enemy arrives as a file dropped in the roster
## directory, never as a case added to a match statement in the runtime.
##
## The BEHAVIOR SET IS CLOSED on purpose. Every behavior is designed against a
## specific core system (movement factors, the Gill Mod slot, restoration
## state, the catastrophic-source lane), and those seams are the sanctioned
## surface. An open "run my script" behavior would hand world content the same
## unverifiable power the sanctioned world API surface exists to deny.
##
##   * `entangle`   — a timed movement factor with an affordance counter
##                    (Netbots: ghost nets vs Jet Gills' `net_escape`).
##   * `snag`       — takes the equipped Gill Mod for the framework's tuned
##                    window; an affordance reveals the line (Hookline Rigs vs
##                    Glow Gills' `reveal_hookline`).
##   * `dredge`     — reverts a restored region, and carries the ONLY
##                    catastrophic lane an enemy may have: an area wipe naming
##                    a source from CatastrophicSource's closed set.
##   * `toxin_aura` — factors published while the player is inside the volume,
##                    lingering for a tuned duration after leaving (Runoff
##                    Drones: vision and gill-recharge debuffs).

enum Behavior {
	ENTANGLE,
	SNAG,
	DREDGE,
	TOXIN_AURA,
}

const FIELD_ID := "id"
const FIELD_NAME := "displayName"
const FIELD_BEHAVIOR := "behavior"
const FIELD_AUDIO_CUE := "audioCueId"

const FIELD_ENTANGLE := "entangle"
const FIELD_FACTOR_KEY := "factorKey"
const FIELD_DURATION_KEY := "durationKey"
const FIELD_TARGET := "target"
const FIELD_ESCAPE_AFFORDANCE := "escapeAffordance"

const FIELD_SNAG := "snag"
const FIELD_REVEAL_AFFORDANCE := "revealAffordance"

const FIELD_DREDGE := "dredge"
const FIELD_AREA_WIPE_SOURCE := "areaWipeSource"

const FIELD_TOXIN := "toxinAura"
const FIELD_VISION_FACTOR_KEY := "visionFactorKey"
const FIELD_RECHARGE_FACTOR_KEY := "rechargeFactorKey"

const BEHAVIOR_IDS := {
	"entangle": Behavior.ENTANGLE,
	"snag": Behavior.SNAG,
	"dredge": Behavior.DREDGE,
	"toxin_aura": Behavior.TOXIN_AURA,
}

const TARGET_IDS := {
	"all": CapabilityModifiers.Target.ALL,
	"swim_speed": CapabilityModifiers.Target.SWIM_SPEED,
	"waddle_speed": CapabilityModifiers.Target.WADDLE_SPEED,
}

var id: String = ""
var display_name: String = ""
var behavior: Behavior = Behavior.ENTANGLE
var audio_cue_id: String = ""

## entangle
var factor_key: String = ""
var duration_key: String = ""
var target: CapabilityModifiers.Target = CapabilityModifiers.Target.ALL
var escape_affordance: String = ""

## snag
var reveal_affordance: String = ""

## dredge
var area_wipe_source: String = ""

## toxin_aura
var vision_factor_key: String = ""
var recharge_factor_key: String = ""


static func from_dictionary(data: Dictionary,
		out_errors: Array[EnemyError] = []) -> EnemyDef:
	for field: String in [FIELD_ID, FIELD_NAME, FIELD_BEHAVIOR, FIELD_AUDIO_CUE]:
		if not (data.get(field) is String) or String(data[field]).is_empty():
			out_errors.append(EnemyError.new(EnemyError.MISSING_FIELD,
				String(data.get(FIELD_ID, "")),
				"missing or empty field '%s'" % field))
			return null

	var behavior_id := String(data[FIELD_BEHAVIOR])
	if not BEHAVIOR_IDS.has(behavior_id):
		out_errors.append(EnemyError.new(EnemyError.UNKNOWN_BEHAVIOR,
			String(data[FIELD_ID]),
			"behavior '%s' is not in the framework's closed set %s"
			% [behavior_id, str(BEHAVIOR_IDS.keys())]))
		return null

	var def := EnemyDef.new()
	def.id = String(data[FIELD_ID])
	def.display_name = String(data[FIELD_NAME])
	def.behavior = BEHAVIOR_IDS[behavior_id]
	def.audio_cue_id = String(data[FIELD_AUDIO_CUE])

	match def.behavior:
		Behavior.ENTANGLE:
			var params: Variant = data.get(FIELD_ENTANGLE)
			if not _require_params(def, params, [FIELD_FACTOR_KEY,
					FIELD_DURATION_KEY, FIELD_ESCAPE_AFFORDANCE],
					FIELD_ENTANGLE, out_errors):
				return null
			var entangle := params as Dictionary
			def.factor_key = String(entangle[FIELD_FACTOR_KEY])
			def.duration_key = String(entangle[FIELD_DURATION_KEY])
			def.escape_affordance = String(entangle[FIELD_ESCAPE_AFFORDANCE])
			var target_id := String(entangle.get(FIELD_TARGET, "all"))
			if not TARGET_IDS.has(target_id):
				out_errors.append(EnemyError.new(EnemyError.MISSING_FIELD,
					def.id, "entangle target '%s' is not one of %s"
					% [target_id, str(TARGET_IDS.keys())]))
				return null
			def.target = TARGET_IDS[target_id]
		Behavior.SNAG:
			var params: Variant = data.get(FIELD_SNAG)
			if not _require_params(def, params, [FIELD_REVEAL_AFFORDANCE],
					FIELD_SNAG, out_errors):
				return null
			def.reveal_affordance = String(
				(params as Dictionary)[FIELD_REVEAL_AFFORDANCE])
		Behavior.DREDGE:
			var params: Variant = data.get(FIELD_DREDGE)
			if not _require_params(def, params, [FIELD_AREA_WIPE_SOURCE],
					FIELD_DREDGE, out_errors):
				return null
			def.area_wipe_source = String(
				(params as Dictionary)[FIELD_AREA_WIPE_SOURCE])
		Behavior.TOXIN_AURA:
			var params: Variant = data.get(FIELD_TOXIN)
			if not _require_params(def, params, [FIELD_VISION_FACTOR_KEY,
					FIELD_RECHARGE_FACTOR_KEY, FIELD_DURATION_KEY],
					FIELD_TOXIN, out_errors):
				return null
			var toxin := params as Dictionary
			def.vision_factor_key = String(toxin[FIELD_VISION_FACTOR_KEY])
			def.recharge_factor_key = String(toxin[FIELD_RECHARGE_FACTOR_KEY])
			def.duration_key = String(toxin[FIELD_DURATION_KEY])

	return def


## Every tuning key this declaration cites, for the registry to validate
## against the live tuning surface at registration — never at the moment the
## player is first hit, which is the worst possible time to learn a key is
## misspelled.
func cited_tuning_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for key: String in [factor_key, duration_key, vision_factor_key,
			recharge_factor_key]:
		if not key.is_empty():
			keys.append(key)
	return keys


static func _require_params(def: EnemyDef, params: Variant,
		fields: PackedStringArray, block: String,
		out_errors: Array[EnemyError]) -> bool:
	if not (params is Dictionary):
		out_errors.append(EnemyError.new(EnemyError.MISSING_FIELD, def.id,
			"behavior block '%s' is missing or not an object" % block))
		return false
	for field: String in fields:
		var value: Variant = (params as Dictionary).get(field)
		if not (value is String) or String(value).is_empty():
			out_errors.append(EnemyError.new(EnemyError.MISSING_FIELD, def.id,
				"'%s' is missing or empty in the '%s' block" % [field, block]))
			return false
	return true
