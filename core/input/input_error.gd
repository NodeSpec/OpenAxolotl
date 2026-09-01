class_name InputError
extends RefCounted

## A named input-binding failure (REQ-024).
##
## Rebinding is a player-facing operation that can legitimately be REFUSED —
## AC-4 requires a conflicting assignment to be rejected rather than silently
## overriding the binding already there. A refusal the player cannot see is
## indistinguishable from a rebind that did not take, so every refusal carries a
## stable code and the verb it concerns, matching the shape TuningError,
## SaveError and GillModError already use.

## Stable, dotted rule ids. Matched by tests and by tooling, so they are part of
## this node's public surface — never reword them into free text.
const UNKNOWN_VERB := "input.unknown_verb"
const UNKNOWN_DEVICE := "input.unknown_device"
const UNKNOWN_CONTEXT := "input.unknown_context"
const MALFORMED_BINDING := "input.malformed_binding"
const NO_PHYSICAL_INPUT := "input.no_physical_input"
const BINDING_CONFLICT := "input.binding_conflict"
const UNBOUND_VERB := "input.unbound_verb"
const INCOMPLETE_DIRECTIONS := "input.incomplete_directions"

var code: String
var verb_id: String
var detail: String


func _init(p_code: String, p_verb_id: String, p_detail: String) -> void:
	code = p_code
	verb_id = p_verb_id
	detail = p_detail


func _to_string() -> String:
	if verb_id.is_empty():
		return "[%s] %s" % [code, detail]
	return "[%s] %s: %s" % [code, verb_id, detail]
