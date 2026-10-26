@tool
extends MeshInstance3D
@export var region_id := ""
var _bound := false
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _bound:
		return
	for n: Node in get_tree().get_nodes_in_group("world_systems"):
		if n is WorldSystems and n.get_parent().is_ancestor_of(self):
			var system := (n as WorldSystems).get_restoration()
			if system == null:
				return
			system.region_state_changed.connect(_on_state)
			apply_state(system.get_state(region_id))
			_bound=true
			set_process(false)
			return
func _on_state(id: String,_from: int,to: int) -> void:
	if id==region_id:
		apply_state(to)
func apply_state(state: int) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color=[Color(0.33,0.32,0.2),Color(0.35,0.63,0.24),Color(1,0.55,0.42)][state]
	m.roughness=0.85
	material_override=m
