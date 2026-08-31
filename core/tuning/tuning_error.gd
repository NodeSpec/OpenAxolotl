class_name TuningError
extends RefCounted

## A named tuning failure (REQ-025).
##
## The loader never substitutes a default for a bad value — a silent default
## turns a balance bug into a mystery. Every refusal carries a stable [member code]
## and the offending [member key], so a contributor or an AI agent can map the
## failure back to the exact tuning entry that caused it.

## Stable, dotted rule ids. These are matched by tests and by tooling, so they
## are part of this node's public surface — never reword them into free text.
const FILE_UNREADABLE := "tuning.file_unreadable"
const MALFORMED_JSON := "tuning.malformed_json"
const MALFORMED_ENTRY := "tuning.malformed_entry"
const MISSING_KEY := "tuning.missing_key"
const OUT_OF_RANGE := "tuning.out_of_range"
const UNKNOWN_KEY := "tuning.unknown_key"
const OVERRIDE_NOT_PERMITTED := "tuning.override_not_permitted"

var code: String
var key: String
var detail: String


func _init(p_code: String, p_key: String, p_detail: String) -> void:
	code = p_code
	key = p_key
	detail = p_detail


func _to_string() -> String:
	if key.is_empty():
		return "[%s] %s" % [code, detail]
	return "[%s] %s: %s" % [code, key, detail]
