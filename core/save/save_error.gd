class_name SaveError
extends RefCounted

## A named save failure (REQ-014).
##
## Stable dotted rule ids, matched by tests and tooling — part of this node's
## public surface, never reworded into free text.

const FILE_UNREADABLE := "save.file_unreadable"
const MALFORMED_JSON := "save.malformed_json"
const UNKNOWN_FORMAT_VERSION := "save.unknown_format_version"
const NO_MIGRATION_PATH := "save.no_migration_path"
const MODULE_BLOB_UNREADABLE := "save.module_blob_unreadable"
const FOREIGN_NAMESPACE_WRITE := "save.foreign_namespace_write"

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
