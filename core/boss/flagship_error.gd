class_name FlagshipError
extends RefCounted

## A named Flagship declaration failure (REQ-013).
##
## The boss element is OPT-IN and validated, never trusted: a declaration
## that cannot satisfy the encounter criteria is refused at load with a
## stable code, matching the shape EnemyError, GillModError and TuningError
## already use.

## Stable, dotted rule ids — part of this node's public surface.
const MALFORMED := "boss.malformed"
const MISSING_FIELD := "boss.missing_field"
const DUPLICATE_PHASE := "boss.duplicate_phase"
const UNKNOWN_GRAMMAR := "boss.unknown_grammar"
const NO_WATER_PHASE := "boss.no_water_phase"
const NO_LAND_PHASE := "boss.no_land_phase"
const NO_MOD_GATED_PHASE := "boss.no_mod_gated_phase"

var code: String
var subject: String
var detail: String


func _init(p_code: String, p_subject: String, p_detail: String) -> void:
	code = p_code
	subject = p_subject
	detail = p_detail


func _to_string() -> String:
	if subject.is_empty():
		return "[%s] %s" % [code, detail]
	return "[%s] %s: %s" % [code, subject, detail]
