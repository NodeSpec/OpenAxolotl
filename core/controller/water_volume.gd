@tool
class_name WaterVolume
extends Area3D

## A region of water, placed by a world (REQ-001 AC-1, REQ-034, REQ-039).
##
## Which grammar the axolotl is in is a property of WHERE IT IS, so a world
## declares water by placing a volume rather than by scripting a state change.
## That is the same shape CameraHintVolume uses for framing, and it is what lets
## a contributor build a lagoon without touching controller code.
##
## The body tracks overlapping volumes and samples immersion with hysteresis;
## the controller remains the authority on movement grammar. Surface height
## comes from the original BoxMesh, or an explicit plane for shaped waterways.
## Currents are opt-in, spatially bounded, and independent of visual ripples.
##
## WHAT IT ANNOUNCES. Crossing the surface is the most physical thing that
## happens in this game and for a long time it happened in silence: the grammar
## changed, the animation changed, and the water itself did not react at all.
## Entering and leaving now raise a splash at the crossing point through
## WaterSplash, and ask for an audio cue by NAME — never a file path, because
## the Audio System alone decides what water sounds like (REQ-023).
##
## `@tool` so the shape is visible while editing. It does nothing in the editor
## beyond existing.

signal body_entered_water(body: AxolotlBody)
signal body_exited_water(body: AxolotlBody)

## Semantic audio ids, resolved by the Audio System. A dive and a surfacing are
## different sounds — one is a body arriving, the other is water closing behind
## it — so they are different ids rather than one "splash".
const CUE_ENTER := "water_enter"
const CUE_EXIT := "water_exit"

signal audio_cue_requested(cue_id: String)

## Below this vertical speed a crossing is a wade rather than a plunge, and it
## gets the smaller splash. A number rather than a boolean because the two ends
## of it are genuinely different events: stepping off a shore into shallows
## should not throw the same sheet of water as falling in from a ledge.
const PLUNGE_SPEED := 6.0

@export var explicit_surface: bool = false
@export var surface_height: float = 0.0
@export var surface_gradient: Vector2 = Vector2.ZERO
@export var water_priority: int = 0
@export var depth_lighting_enabled: bool = true
@export var shallow_wading_enabled: bool = false
@export var swim_enter_depth: float = -0.10
@export var swim_exit_depth: float = -0.26
@export var current_velocity: Vector3 = Vector3.ZERO
@export var current_ramp_m: float = 2.0

var _bodies: Array[AxolotlBody] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("water_volumes")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	if _bodies.has(axolotl):
		return
	track_body(axolotl)
	_splash(axolotl, true)
	body_entered_water.emit(axolotl)


func _on_body_exited(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	if not _bodies.has(axolotl):
		return
	_bodies.erase(axolotl)
	axolotl.unregister_water(self)
	_splash(axolotl, false)
	body_exited_water.emit(axolotl)


## Raises a splash where the body met the surface.
##
## AT THE SURFACE, NOT AT THE BODY. A player who dives in fast is already half
## a metre under by the frame the area reports it, and a splash centred on them
## appears underwater where nobody sees it. The crossing point is the body's
## own x and z at the height of this volume's top face, which is where the
## water was actually disturbed.
func _splash(body: AxolotlBody, entering: bool) -> void:
	var top := surface_at(body.global_position if body.is_inside_tree() else body.position)
	if is_inf(top):
		return
	var position_3d: Vector3 = body.global_position if body.is_inside_tree() else body.position
	var at := Vector3(position_3d.x, top, position_3d.z)
	var speed := absf(body.velocity.y)

	# DEFERRED, because this is inside the physics flush. body_entered fires
	# while the physics server is iterating its own state, and adding a node
	# to the tree during that is refused outright — "parent node is busy
	# setting up children" — so the splash simply never appeared. Every other
	# reaction to a volume in this game is deferred for the same reason; the
	# splash is the newest one to learn it.
	#
	# The crossing is measured NOW and the effect raised next frame: a
	# deferred call that read the body's velocity when it finally ran would
	# read it a frame late, by which point a dive has already changed speed.
	#
	# Through a method on this node rather than a bound Callable on
	# WaterSplash's static: binding one failed at runtime, and because it
	# failed INSIDE the crossing handler it took the rest of the handler with
	# it — the water grammar still switched, and every signal after this line
	# silently stopped being emitted.
	_raise_splash.call_deferred(at, speed, speed >= PLUNGE_SPEED)
	audio_cue_requested.emit(CUE_ENTER if entering else CUE_EXIT)


func _raise_splash(at: Vector3, speed: float, plunging: bool) -> void:
	WaterSplash.erupt(self, at, speed, plunging)


## The world height of this volume's top face, or INF when it has no box to
## take one from.
func _surface_height() -> float:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var box := (node as MeshInstance3D).mesh as BoxMesh
		if box != null:
			var visual := node as Node3D
			return (visual.global_position.y if visual.is_inside_tree() else position.y + visual.position.y) + box.size.y * 0.5
	return INF


func surface_at(point: Vector3) -> float:
	if not explicit_surface:
		return _surface_height()
	var local: Vector3 = to_local(point) if is_inside_tree() else point - position
	var height: float = surface_height + surface_gradient.dot(Vector2(local.x, local.z))
	return (to_global(Vector3(local.x,height,local.z)).y if is_inside_tree() else height + position.y)


func should_swim(point: Vector3, was_swimming: bool) -> bool:
	# Existing deep-water routes were authored around capsule overlap, including
	# launching out of the surface. Shallow banks opt into immersion thresholds.
	if not shallow_wading_enabled:
		return true
	var top: float = surface_at(point)
	return not is_inf(top) and top-point.y >= (swim_exit_depth if was_swimming else swim_enter_depth)


func surface_slope_at(_point: Vector3) -> Vector2:
	return surface_gradient


func enclosure_at(_point: Vector3) -> float:
	return 0.0


func contains_point(point: Vector3, margin: float = 0.0) -> bool:
	for child: Node in get_children():
		var collision := child as CollisionShape3D
		if collision == null or collision.disabled or not collision.shape is BoxShape3D:
			continue
		var box := collision.shape as BoxShape3D
		var local: Vector3 = collision.to_local(point) if collision.is_inside_tree() else point-position-collision.position
		# Include the capsule's bottom while the body wades above the surface.
		if absf(local.x) <= box.size.x*0.5+margin and absf(local.z) <= box.size.z*0.5+margin and local.y >= -box.size.y*0.5-0.8 and local.y <= box.size.y*0.5+0.8:
			return true
	return false


func flow_at(point: Vector3) -> Vector3:
	if current_velocity.is_zero_approx() or not contains_point(point):
		return Vector3.ZERO
	for child: Node in get_children():
		var collision := child as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			continue
		var box := collision.shape as BoxShape3D
		var local: Vector3 = collision.to_local(point) if collision.is_inside_tree() else point-position-collision.position
		var direction := Vector2(current_velocity.x,current_velocity.z).normalized()
		var half_length: float = absf(direction.x)*box.size.x*0.5+absf(direction.y)*box.size.z*0.5
		var along: float = Vector2(local.x,local.z).dot(direction)+half_length
		var lateral: float = absf(Vector2(local.x,local.z).dot(Vector2(-direction.y,direction.x)))
		var half_width: float = absf(direction.y)*box.size.x*0.5+absf(direction.x)*box.size.z*0.5
		var weight: float = smoothstep(0.0,maxf(0.01,current_ramp_m),along)*smoothstep(0.0,0.45,half_width-lateral)
		return (global_basis * current_velocity if is_inside_tree() else current_velocity)*weight
	return Vector3.ZERO


func forget_body(body: AxolotlBody) -> void:
	_bodies.erase(body)


func track_body(body: AxolotlBody) -> void:
	if not _bodies.has(body):
		_bodies.append(body)
	body.register_water(self)


func _exit_tree() -> void:
	for body: AxolotlBody in _bodies.duplicate():
		if is_instance_valid(body):
			body.unregister_water(self)
	_bodies.clear()
