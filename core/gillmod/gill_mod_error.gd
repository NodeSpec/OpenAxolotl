class_name GillModError
extends RefCounted

## A named Gill Mod registration failure (REQ-004).
##
## Registration is the extension interface, and an extension interface that fails
## silently is worse than one that fails loudly: a contributor or an AI coding
## agent whose mod simply never appears has nothing to debug. Every refusal
## carries a stable code and the offending mod id, matching the shape TuningError
## and SaveError already use.

## Stable, dotted rule ids. Matched by tests and by tooling, so they are part of
## this node's public surface — never reword them into free text.
const FILE_UNREADABLE := "gillmod.file_unreadable"
const MALFORMED_JSON := "gillmod.malformed_json"
const MISSING_FIELD := "gillmod.missing_field"
const NO_AFFORDANCES := "gillmod.no_affordances"
const DUPLICATE_ID := "gillmod.duplicate_id"
const UNKNOWN_TUNING_KEY := "gillmod.unknown_tuning_key"
const AFFORDANCE_ALREADY_GRANTED := "gillmod.affordance_already_granted"

var code: String
var mod_id: String
var detail: String


func _init(p_code: String, p_mod_id: String, p_detail: String) -> void:
	code = p_code
	mod_id = p_mod_id
	detail = p_detail


func _to_string() -> String:
	if mod_id.is_empty():
		return "[%s] %s" % [code, detail]
	return "[%s] %s: %s" % [code, mod_id, detail]
