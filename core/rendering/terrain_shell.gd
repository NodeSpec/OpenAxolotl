@tool
class_name TerrainShell
extends Node3D

## The VISUAL skin wrapped around a greybox collision proxy (REQ-030, REQ-034).
##
## Gameplay owns the BoxShape3D. This node owns only the thing the player sees.
## The separation is deliberate: measured jump distances, walk probes and world
## contracts keep addressing the collision proxy while the final-facing art can
## become organic without moving a single gameplay surface.
##
## The walkable cap stays EXACTLY on the proxy's top plane. The final edge now
## has three zones rather than one flat overhang:
##
##   * CAP — follows the collision footprint exactly and stays perfectly flat;
##   * WEATHERED RIM — pushes OUTSIDE the collision and drops slightly, so the
##     eye sees an edge before the feet run out of floor instead of seeing a
##     walkable-looking shelf hanging over empty space;
##   * SKIRT — pulls inward as it descends, breaking the box silhouette below.
##
## That small dropped rim is a gameplay-readability detail, not decoration. A
## platformer feels fair when the visible lip and the physical lip agree.
##
## THE MESHY INTERFACE. `visual_kit` is a drop-in slot: set it to a PackedScene
## and that art is used instead of the generated shell, fitted to the proxy's
## bounds by the same anchor rule. The collision, route markers and tests never
## move.
##
## ADDS NO COLLISION, EVER.

@export var proxy_path: NodePath = ^"..":
	set(value):
		proxy_path = value
		_rebuild()

@export var visual_kit: PackedScene:
	set(value):
		visual_kit = value
		_rebuild()

@export var surface_material: Material:
	set(value):
		surface_material = value
		_rebuild()

## Maximum horizontal overhang beyond the collision footprint.
@export var rim_margin: float = 0.55:
	set(value):
		rim_margin = maxf(value, 0.0)
		_rebuild()

## Vertical drop of the cosmetic outer rim. It is clamped again against the
## proxy thickness while building, so a thin step can never bevel through its
## own underside.
@export var rim_drop: float = 0.14:
	set(value):
		rim_drop = maxf(value, 0.0)
		_rebuild()

## Cosmetic rock below the proxy.
@export var skirt_depth: float = 1.8:
	set(value):
		skirt_depth = maxf(value, 0.0)
		_rebuild()

## Target spacing between rim samples. A spacing works for both tiny steps and
## the lagoon floor; a fixed segment count does not.
@export var rim_spacing_m: float = 3.0:
	set(value):
		rim_spacing_m = maxf(value, 0.25)
		_rebuild()

const MIN_RIM_SEGMENTS := 8
const MAX_RIM_SEGMENTS := 64

@export var shell_seed: int = 0:
	set(value):
		shell_seed = value
		_rebuild()

var _visual: Node3D


func _ready() -> void:
	_rebuild()


func proxy_bounds() -> AABB:
	var proxy := get_node_or_null(proxy_path)
	if proxy == null:
		return AABB()
	for child: Node in proxy.find_children("*", "CollisionShape3D", true, false):
		var shape := (child as CollisionShape3D).shape as BoxShape3D
		if shape == null:
			continue
		var offset := (child as CollisionShape3D).position
		return AABB(offset - shape.size * 0.5, shape.size)
	return AABB()


func get_visual() -> Node3D:
	return _visual


## Triangles readable without adding the shell to the tree. The performance
## gate uses this when it counts a world before playing it.
func shell_triangles() -> int:
	var mesh := _build_mesh()
	if mesh == null:
		return 0
	var total := 0
	for surface: int in mesh.get_surface_count():
		var indices: Variant = mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
		if indices != null:
			total += (indices as PackedInt32Array).size() / 3
	return total


func _rebuild() -> void:
	if _visual != null:
		remove_child(_visual)
		_visual.free()
		_visual = null

	var bounds := proxy_bounds()
	if bounds.size == Vector3.ZERO:
		return

	_visual = _kit_instance(bounds) if visual_kit != null else _generated(bounds)
	if _visual == null:
		return
	_visual.name = "Shell"
	add_child(_visual)


## Drop-in authored art. Its top face is fitted to the proxy top and its
## footprint covers the proxy plus the allowed cosmetic rim.
func _kit_instance(bounds: AABB) -> Node3D:
	var instance := visual_kit.instantiate() as Node3D
	if instance == null:
		return null
	var kit_bounds := _instance_bounds(instance)
	if kit_bounds.size.x <= 0.0 or kit_bounds.size.z <= 0.0:
		return instance

	var wanted := Vector3(bounds.size.x + rim_margin * 2.0,
		bounds.size.y + skirt_depth, bounds.size.z + rim_margin * 2.0)
	instance.scale = Vector3(
		wanted.x / kit_bounds.size.x,
		wanted.y / maxf(kit_bounds.size.y, 0.0001),
		wanted.z / kit_bounds.size.z)
	var scaled_top := (kit_bounds.position.y + kit_bounds.size.y) * instance.scale.y
	instance.position = Vector3(
		bounds.get_center().x, bounds.position.y + bounds.size.y - scaled_top,
		bounds.get_center().z)
	if surface_material != null:
		for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
			(node as MeshInstance3D).material_override = surface_material
	return instance


func _generated(bounds: AABB) -> Node3D:
	var mesh := _build_mesh()
	if mesh == null:
		return null
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	if surface_material != null:
		instance.material_override = surface_material
	return instance


func _instance_bounds(instance: Node3D) -> AABB:
	var total := AABB()
	var first := true
	for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		var box := mesh.get_aabb()
		total = box if first else total.merge(box)
		first = false
	return total


## Flat collision-matched cap -> lowered organic rim -> rocky skirt.
func _build_mesh() -> ArrayMesh:
	var bounds := proxy_bounds()
	if bounds.size == Vector3.ZERO:
		return null

	var centre := bounds.get_center()
	var top := bounds.position.y + bounds.size.y
	var half := Vector2(bounds.size.x * 0.5, bounds.size.z * 0.5)
	var floor_y := bounds.position.y - skirt_depth
	var segments := _segment_count(half)
	var safe_rim_drop := minf(rim_drop, bounds.size.y * 0.45)

	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()

	# Hub of the walkable top.
	vertices.append(Vector3(centre.x, top, centre.z))
	colours.append(Color(0.86, 0.88, 0.82))

	# CAP RING: exactly the collision footprint. This is the important change
	# from the first shell pass: the last vertex that still looks walkable is
	# now exactly where the physical floor ends.
	var cap_start := vertices.size()
	for step: int in segments:
		var t := float(step) / float(segments)
		var edge := _perimeter_point(t, half)
		vertices.append(Vector3(centre.x + edge.x, top, centre.z + edge.y))
		colours.append(Color(0.84, 0.86, 0.79))

	# WEATHERED RIM: always outside, always a little lower. Variation is split
	# between horizontal overhang and drop so repeated shells do not share the
	# same silhouette or the same perfectly level ledge.
	var rim_start := vertices.size()
	for step: int in segments:
		var t := float(step) / float(segments)
		var edge := _perimeter_point(t, half)
		var outward := _perimeter_normal(t, half)
		var jitter := _noise(step, 0) * rim_margin
		var out := edge + outward * (rim_margin * 0.45 + jitter)
		var drop := safe_rim_drop * (0.72 + _noise(step, 3) * 0.56)
		vertices.append(Vector3(
			centre.x + out.x, top - drop, centre.z + out.y))
		colours.append(Color(0.74, 0.77, 0.70))

	# SKIRT: pulls inward as it descends. It is wholly cosmetic and may vary
	# freely because the player cannot stand on it.
	var skirt_start := vertices.size()
	for step: int in segments:
		var t := float(step) / float(segments)
		var edge := _perimeter_point(t, half)
		var pull := 0.74 + _noise(step, 1) * 0.20
		var out := edge * pull
		vertices.append(Vector3(
			centre.x + out.x,
			floor_y + _noise(step, 2) * skirt_depth * 0.3,
			centre.z + out.y))
		colours.append(Color(0.55, 0.56, 0.53))

	for step: int in segments:
		var next := (step + 1) % segments
		# Flat walkable cap.
		indices.append_array([0, cap_start + step, cap_start + next])
		# Bevel from the true collision edge down to the weathered overhang.
		indices.append_array([
			cap_start + next, cap_start + step, rim_start + step,
			rim_start + step, rim_start + next, cap_start + next])
		# Rock skirt.
		indices.append_array([
			rim_start + next, rim_start + step, skirt_start + step,
			skirt_start + step, skirt_start + next, rim_start + next])

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in vertices.size():
		surface.set_color(colours[index])
		surface.add_vertex(vertices[index])
	for index: int in indices:
		surface.add_index(index)
	# Shared vertices across cap/rim/skirt intentionally soften the edge under
	# light without moving it. Shape carries the silhouette; normals carry the
	# weathering.
	surface.generate_normals()
	return surface.commit()


func _segment_count(half: Vector2) -> int:
	var perimeter := 4.0 * (half.x + half.y)
	return clampi(int(round(perimeter / rim_spacing_m)),
		MIN_RIM_SEGMENTS, MAX_RIM_SEGMENTS)


## A point on the rectangle outline, spaced uniformly by perimeter length.
static func _perimeter_point(t: float, half: Vector2) -> Vector2:
	var width := half.x * 2.0
	var depth := half.y * 2.0
	var along := fposmod(t, 1.0) * (width + depth) * 2.0
	if along < width:
		return Vector2(-half.x + along, -half.y)
	along -= width
	if along < depth:
		return Vector2(half.x, -half.y + along)
	along -= depth
	if along < width:
		return Vector2(half.x - along, half.y)
	along -= width
	return Vector2(-half.x, half.y - along)


## Outward normal for the perimeter edge. At exact corners both face normals
## contribute, giving a diagonal rather than a one-axis spike.
static func _perimeter_normal(t: float, half: Vector2) -> Vector2:
	var point := _perimeter_point(t, half)
	var normal := Vector2.ZERO
	if is_equal_approx(point.y, -half.y):
		normal += Vector2(0.0, -1.0)
	if is_equal_approx(point.y, half.y):
		normal += Vector2(0.0, 1.0)
	if is_equal_approx(point.x, -half.x):
		normal += Vector2(-1.0, 0.0)
	if is_equal_approx(point.x, half.x):
		normal += Vector2(1.0, 0.0)
	return normal.normalized() if normal != Vector2.ZERO else Vector2(1.0, 0.0)


## Deterministic in (seed, index, channel).
func _noise(index: int, channel: int) -> float:
	var hashed := float(
		(shell_seed * 73856093) ^ (index * 19349663) ^ (channel * 83492791))
	return fposmod(sin(hashed) * 43758.5453, 1.0)
