@tool
extends Node3D
## Preserve the supplied atlas while restoration brings its vegetation to life.
var _materials: Array[StandardMaterial3D] = []
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source!=null:
				var material := source.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface,material)
				_materials.append(material)
	apply_state(0)
func _process(_delta: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("world_systems"):
		if node is WorldSystems and node.get_parent().is_ancestor_of(self):
			var restoration := (node as WorldSystems).get_restoration()
			if restoration!=null:
				restoration.region_state_changed.connect(_state_changed)
				apply_state(restoration.get_state("coral_shelf"))
				set_process(false)
				return
func _state_changed(id: String,_from: int,to: int) -> void:
	if id=="coral_shelf":
		apply_state(to)
func apply_state(state: int) -> void:
	for material in _materials:
		material.albedo_color=[Color(0.48,0.43,0.33),Color(0.73,0.85,0.66),Color.WHITE][clampi(state,0,2)]
