@tool
extends ScatterField
## Store source mesh and authored transforms even when built headlessly.
@export var source_mesh: Mesh:
	set(value):
		source_mesh=value
		_rebuild()
func _extract_mesh() -> Mesh:
	return source_mesh
