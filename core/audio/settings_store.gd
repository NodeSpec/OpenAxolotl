class_name SettingsStore
extends RefCounted

## The port Audio needs from the Save Integration Interface (REQ-023 AC-6).
##
## Audio settings persist alongside input bindings through the save system, not
## in a private file of the Audio node's own. The Save System (REQ-014) supplies
## the concrete implementation; declaring the port here lets Audio be built and
## fully tested before Save exists, and keeps the dependency pointing the way the
## architecture says it does — Audio depends on an interface, never on Save's
## internals.
##
## Until the Save System lands, nothing in production implements this, so volumes
## are adjustable but not yet durable. That is a real, temporary gap: AC-6's
## persistence half is proven against a double here and becomes true end to end
## when Save implements this port.

## Returns the stored section, or an empty Dictionary when nothing is saved yet.
func load_section(_section: String) -> Dictionary:
	return {}


func save_section(_section: String, _payload: Dictionary) -> void:
	pass
