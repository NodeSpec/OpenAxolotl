class_name HubError
extends RefCounted

## A named failure from world discovery, validation, or loading (REQ-009).
##
## Codes are stable dotted ids rather than prose, the same convention every
## validator in this project uses: an AI coding agent whose world came up as an
## unavailable portal parses the code, maps it back to the contract element it
## broke, and self-corrects. The message is for the human reading the portal's
## tooltip; the code is the machine-readable half.

const MISSING_MANIFEST := "hub.missing_manifest"
const UNREADABLE_MANIFEST := "hub.unreadable_manifest"
const MALFORMED_MANIFEST := "hub.malformed_manifest"
const CONTRACT_VIOLATION := "hub.contract_violation"
const UNSUPPORTED_VERSION := "hub.unsupported_version"
const UNKNOWN_RULE_KIND := "hub.unknown_rule_kind"
const UNKNOWN_TIER := "hub.unknown_tier"
const MISSING_SCENE := "hub.missing_scene"
const UNLOADABLE_SCENE := "hub.unloadable_scene"
const MISSING_SPAWN := "hub.missing_spawn"
const MISSING_FINISH := "hub.missing_finish"
const SCHEMA_UNAVAILABLE := "hub.schema_unavailable"

var code: String = ""
var subject: String = ""
var message: String = ""


func _init(p_code: String = "", p_subject: String = "", p_message: String = "") -> void:
	code = p_code
	subject = p_subject
	message = p_message


func to_string_id() -> String:
	return "[%s] %s: %s" % [code, subject, message]
