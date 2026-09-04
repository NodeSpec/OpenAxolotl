@tool
class_name WaterVolume
extends Area3D

## A region of water, placed by a world (REQ-001 AC-1).
##
## Which grammar the axolotl is in is a property of WHERE IT IS, so a world
## declares water by placing a volume rather than by scripting a state change.
## That is the same shape CameraHintVolume uses for framing, and it is what lets
## a contributor build a lagoon without touching controller code.
##
## The volume tells the body it entered; the body counts overlaps and the
## controller decides what a grammar change means. Nothing here knows about
## swimming — a volume that tried to set the grammar directly would be a second
## authority on the transition, and the momentum carry would depend on which one
## ran first.
##
## `@tool` so the shape is visible while editing. It does nothing in the editor
## beyond existing.

signal body_entered_water(body: AxolotlBody)
signal body_exited_water(body: AxolotlBody)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	axolotl.enter_water()
	body_entered_water.emit(axolotl)


func _on_body_exited(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	axolotl.exit_water()
	body_exited_water.emit(axolotl)
