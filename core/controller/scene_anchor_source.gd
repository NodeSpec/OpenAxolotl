class_name SceneAnchorSource
extends AnchorSource

## Production AnchorSource backed by the live scene (REQ-001 AC-4).
##
## `get_nodes_in_group` is the group query — Godot maintains the group index, so
## this never walks the scene. The ray is cast through the physics space state
## against the world's static geometry only, which is what stops the tongue
## reaching through a wall.
##
## This is the ONLY file in the controller that touches the scene tree or the
## physics server. Everything the criteria constrain lives in TongueGrapple and
## AxolotlController as plain objects, so the range, the pick and the pull are all
## assertable headlessly and this class stays thin enough to read at a glance.

## Physics layer NUMBER (1-based) holding line-of-sight blockers.
const OCCLUDER_PHYSICS_LAYER := 1
const OCCLUDER_LAYER_MASK := 1 << (OCCLUDER_PHYSICS_LAYER - 1)

var _host: Node3D


## [param host] is the node the tongue is cast from — normally the axolotl body.
## It supplies the tree for the group query, the 3D world for the ray, and the
## rid to exclude so the axolotl never occludes its own tongue.
func _init(host: Node3D) -> void:
	_host = host


func query_anchors_in_group(group: String) -> Array[GrappleAnchor]:
	var out: Array[GrappleAnchor] = []
	if _host == null or not _host.is_inside_tree():
		return out

	for node: Node in _host.get_tree().get_nodes_in_group(group):
		var spatial := node as Node3D
		if spatial == null:
			# A non-spatial node in the anchor group has no position to grapple
			# to. Skipping it beats crashing a world for one mis-tagged node.
			continue
		# The scene-unique path, not the name: two worlds may each hold a "Ledge",
		# and an ambiguous id would misattribute a cue or a telemetry row.
		out.append(GrappleAnchor.new(String(spatial.get_path()),
			spatial.global_position))

	return out


func has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	if _host == null or not _host.is_inside_tree():
		return false

	var space := _host.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, OCCLUDER_LAYER_MASK)
	query.hit_from_inside = false

	var body := _host as CollisionObject3D
	if body != null:
		query.exclude = [body.get_rid()]

	# An empty result means the ray reached the anchor unobstructed.
	return space.intersect_ray(query).is_empty()
