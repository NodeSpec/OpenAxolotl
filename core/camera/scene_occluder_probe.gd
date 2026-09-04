class_name SceneOccluderProbe
extends CameraOccluderProbe

## Production CameraOccluderProbe, cast against the live physics world
## (REQ-005 AC-2).
##
## The ray runs against a DEDICATED camera-collision physics layer rather than
## the player's. That separation is what lets a world mark a thin decorative
## railing as something the camera may pass through, or a distant backdrop as
## something it may not, without touching how the axolotl collides with either —
## and it means a world tunes framing by painting a layer, not by writing code.
##
## This is the only file in core/camera that touches the physics server.
## Everything the criteria constrain lives in CameraRig and CameraHintStack as
## plain objects, so the clamp, the hint order and the pull-in are all assertable
## headlessly.

## Physics layer NUMBER (1-based, as shown in the inspector) holding geometry the
## camera must not pass through.
const CAMERA_COLLISION_PHYSICS_LAYER := 5
const CAMERA_COLLISION_LAYER_MASK := 1 << (CAMERA_COLLISION_PHYSICS_LAYER - 1)

var _host: Node3D


## [param host] supplies the 3D world to cast in — normally the axolotl body,
## whose own collider is excluded so it never occludes its own camera.
func _init(host: Node3D) -> void:
	_host = host


func clear_fraction(from: Vector3, to: Vector3) -> float:
	if _host == null or not _host.is_inside_tree():
		return 1.0

	var span := from.distance_to(to)
	if span <= 0.0:
		return 1.0

	var space := _host.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		from, to, CAMERA_COLLISION_LAYER_MASK)
	query.hit_from_inside = false

	var body := _host as CollisionObject3D
	if body != null:
		query.exclude = [body.get_rid()]

	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return 1.0

	var contact: Vector3 = hit["position"]
	return clampf(from.distance_to(contact) / span, 0.0, 1.0)
