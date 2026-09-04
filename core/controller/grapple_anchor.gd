class_name GrappleAnchor
extends RefCounted

## One resolved tongue-grapple anchor (REQ-001 AC-4).
##
## A value object rather than a Node3D reference on purpose: the grapple needs a
## position and an identity, and nothing else. Holding the node would let the
## controller reach into world scene structure — the exact coupling the published
## interface exists to prevent — and would make the pull untestable without a
## scene tree.

## Stable identity for cues, HUD and telemetry. Not a tag and never parsed for
## meaning; the climbable check (ClimbSurface) is where tags belong.
var id: String = ""

## World-space position of the anchor point.
var position: Vector3 = Vector3.ZERO


func _init(p_id: String = "", p_position: Vector3 = Vector3.ZERO) -> void:
	id = p_id
	position = p_position
