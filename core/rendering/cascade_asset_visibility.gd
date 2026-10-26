@tool
extends Node3D
## The visible model stays intact. Solid rocks use a cheap volume for shadows.
func _ready() -> void:
	var proxy := get_node_or_null("RockShadow") as MeshInstance3D
	if proxy==null:
		return
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		if mesh!=proxy:
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
