class_name RestorationError
extends RefCounted

## A named failure from declaring or driving restoration regions.
##
## Codes are stable dotted ids rather than prose, for the same reason the static
## gate's rule ids are: an AI coding agent submitting a world parses the code,
## maps it back to the contract element it broke, and self-corrects. A message
## string is for a human reading a log; the code is the machine-readable half.

const UNKNOWN_REGION := "restoration.unknown_region"
const DUPLICATE_REGION := "restoration.duplicate_region"
const MISSING_FIELD := "restoration.missing_field"
const MALFORMED_DECLARATION := "restoration.malformed_declaration"
const UNKNOWN_STATE := "restoration.unknown_state"
const NO_TRAVERSAL_EFFECT := "restoration.no_traversal_effect"
const UNKNOWN_GATE_STATE := "restoration.unknown_gate_state"
const UNKNOWN_UNLOCK_POLICY := "restoration.unknown_unlock_policy"

var code: String = ""
var subject: String = ""
var message: String = ""


func _init(p_code: String = "", p_subject: String = "", p_message: String = "") -> void:
	code = p_code
	subject = p_subject
	message = p_message


func to_string_id() -> String:
	return "[%s] %s: %s" % [code, subject, message]
