class_name CollectibleError
extends RefCounted

## A named failure from declaring or collecting collectibles (REQ-010).
##
## Codes are stable dotted ids rather than prose, for the same reason the
## restoration and static-gate errors are: an AI coding agent submitting a
## world parses the code, maps it back to the contract element it broke, and
## self-corrects. The message is for a human reading a log.

const MALFORMED_DECLARATION := "collectibles.malformed_declaration"
const MISSING_FIELD := "collectibles.missing_field"
const UNKNOWN_KIND := "collectibles.unknown_kind"
const DUPLICATE_ID := "collectibles.duplicate_id"
const UNKNOWN_REGION := "collectibles.unknown_region"

var code: String = ""
var subject: String = ""
var message: String = ""


func _init(p_code: String = "", p_subject: String = "", p_message: String = "") -> void:
	code = p_code
	subject = p_subject
	message = p_message


func to_string_id() -> String:
	return "[%s] %s: %s" % [code, subject, message]
