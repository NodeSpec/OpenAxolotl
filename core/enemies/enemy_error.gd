class_name EnemyError
extends RefCounted

## A named enemy registration failure (REQ-012).
##
## Registration is the extension interface, and an extension interface that
## fails silently is worse than one that fails loudly: a contributor or an AI
## coding agent whose enemy simply never appears has nothing to debug. Every
## refusal carries a stable code and the offending enemy id, matching the shape
## GillModError, TuningError and SaveError already use.

## Stable, dotted rule ids. Matched by tests and by tooling, so they are part
## of this node's public surface — never reword them into free text.
const FILE_UNREADABLE := "enemy.file_unreadable"
const MALFORMED_JSON := "enemy.malformed_json"
const MISSING_FIELD := "enemy.missing_field"
const UNKNOWN_BEHAVIOR := "enemy.unknown_behavior"
const DUPLICATE_ID := "enemy.duplicate_id"
const UNKNOWN_TUNING_KEY := "enemy.unknown_tuning_key"
const UNSANCTIONED_CATASTROPHE := "enemy.unsanctioned_catastrophe"

var code: String
var enemy_id: String
var detail: String


func _init(p_code: String, p_enemy_id: String, p_detail: String) -> void:
	code = p_code
	enemy_id = p_enemy_id
	detail = p_detail


func _to_string() -> String:
	if enemy_id.is_empty():
		return "[%s] %s" % [code, detail]
	return "[%s] %s: %s" % [code, enemy_id, detail]
