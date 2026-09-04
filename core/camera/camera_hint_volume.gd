@tool
class_name CameraHintVolume
extends Area3D

## The node a world places to direct framing (REQ-005 AC-3, AC-4).
##
## This is the entire authoring surface for camera control in a world module:
## drop the node, set exported values in the inspector, done. There is no
## script to write, no callback to implement and no camera API to call — which
## is what makes "declaratively without custom camera code" true rather than
## aspirational, and what keeps world modules inside the sanctioned API surface.
##
## Every field is @export, so AC-4's "driven by exported configuration values"
## is satisfied structurally: there is nothing else here to drive it with.
##
## The volume does NOT hold a CameraRig reference and never calls it. It emits;
## the Game Client wires those signals to the rig. That keeps CameraRig free of
## the scene tree (so its criteria stay headlessly assertable) and means a world
## cannot reach the camera object even if it wanted to.

signal hint_entered(hint: CameraHint)
signal hint_exited(hint_id: String)

## Higher wins where volumes overlap. Declared, never inferred from enter order.
##
## NOT named `priority`: Area3D already has a `priority` property (its audio-bus
## processing order), and shadowing it is a parse error rather than a silent
## surprise — but only because GDScript catches it. The rename is the fix, and
## the prefix also reads better in the inspector next to the framing fields.
@export var hint_priority: int = 0

@export_group("Framing overrides")
## Leave false and the field below is not overridden at all — the camera keeps
## whatever the grammar default or a lower-priority hint gave it.
@export var override_distance: bool = false
@export_range(0.1, 30.0, 0.05) var distance_m: float = 3.0

@export var override_pitch: bool = false
@export_range(-80.0, 80.0, 0.5) var pitch_deg: float = 20.0

@export var override_yaw: bool = false
@export_range(-180.0, 180.0, 0.5) var yaw_deg: float = 0.0

@export_group("Axis locks")
## A locked axis HOLDS its current value while the player is inside the volume.
## Use it to stop the camera swinging in a tunnel; use an override above to point
## it somewhere specific.
@export var lock_pitch: bool = false
@export var lock_yaw: bool = false
@export var lock_distance: bool = false

## Group the player body must belong to for this volume to fire. A group rather
## than a class check or a name, for the same reason ClimbSurface uses one: it is
## inspectable, declarable per world, and checkable by static analysis.
const PLAYER_GROUP := "player"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Stable id derived from the scene-unique path: two worlds may each hold a
## "TunnelCam", and an ambiguous id would let one volume evict the other from the
## hint stack.
func hint_id() -> String:
	# get_path() is only valid inside the tree, and outside it returns empty —
	# which CameraHintStack silently REFUSES, so a volume asked for its hint
	# before _ready would produce a hint that never applies and never errors.
	# Falling back to the node name keeps the object usable and inspectable.
	if is_inside_tree():
		return String(get_path())
	return name


## The declared overrides as data. Only the boxes actually ticked are declared,
## which is what lets a distance-only volume sit on top of a pitch-only one
## without either erasing the other.
func to_hint() -> CameraHint:
	var hint := CameraHint.new(hint_id(), hint_priority)

	if override_distance:
		hint.set_distance(distance_m)
	if override_pitch:
		hint.set_pitch_deg(pitch_deg)
	if override_yaw:
		hint.set_yaw_deg(yaw_deg)

	var locked := 0
	if lock_pitch:
		locked |= int(CameraFraming.Axis.PITCH)
	if lock_yaw:
		locked |= int(CameraFraming.Axis.YAW)
	if lock_distance:
		locked |= int(CameraFraming.Axis.DISTANCE)
	if locked != 0:
		hint.set_locked_axes(locked)

	return hint


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	hint_entered.emit(to_hint())


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	hint_exited.emit(hint_id())
