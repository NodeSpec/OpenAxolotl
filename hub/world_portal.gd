class_name WorldPortal
extends RefCounted

## One portal in the Open Lagoon (REQ-009).
##
## A portal is a RECORD, not a scene node: the hub scene renders these, the
## tests assert on them, and the two can never disagree about what a portal
## knows. Unavailability is first-class rather than an absence — a world that
## failed to load is SHOWN as an unavailable portal with its reasons attached
## (AC-4), because a world silently missing from the hub is indistinguishable
## from a world that was never installed, and a contributor debugging their
## module needs the difference.

var world_id: String = ""
var display_name: String = ""
var module_dir: String = ""
var tier: PortalTier.Tier = PortalTier.Tier.OFFICIAL

var available: bool = false
var failures: Array[HubError] = []

## Read through the Save Integration Interface, never from the save file
## (AC-6). Filled by the registry when a save system is attached; a hub with
## no save wired shows everything unvisited rather than erroring.
var completed: bool = false
var regions_restored: int = 0
var regions_total: int = 0


func _init(p_world_id: String = "", p_module_dir: String = "") -> void:
	world_id = p_world_id
	module_dir = p_module_dir


func failure_summary() -> String:
	var parts := PackedStringArray()
	for failure: HubError in failures:
		parts.append(failure.to_string_id())
	return "; ".join(parts)


## The label a pedestal renders. Tier is carried in TEXT here as well as in
## shape and colour on the pedestal itself — three channels, because REQ-019
## forbids colour-only encoding project-wide.
func portal_label() -> String:
	var name := display_name if not display_name.is_empty() else world_id
	if not available:
		return "%s\n(unavailable)" % name
	return "%s\n%s" % [name, PortalTier.label(tier)]
