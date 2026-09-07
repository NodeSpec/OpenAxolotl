@tool
class_name TerrainShell
extends Node3D

## The VISUAL skin wrapped around a greybox collision proxy (REQ-030, REQ-034).
##
## THE SEPARATION THIS ESTABLISHES. Every platform in the game is a
## StaticBody3D carrying a BoxShape3D — and, until now, a BoxMesh of the same
## size standing in for its art. That box is a COLLISION PROXY: it defines
## where the player may stand, the routes are measured against it, and the walk
## probes fly it. It is not, and was never meant to be, the thing the player
## looks at. This node is what they look at; the box keeps its job and loses
## its visibility.
##
## THE WALKABLE TOP STAYS EXACTLY FLAT, at the proxy's own top plane. This is
## the rule the whole design turns on and it is not negotiable in a platformer:
## displacing the surface a player lands on — even by a few centimetres, even
## only downward — makes every landing a lie, because the foot stops somewhere
## the eye did not predict. So the organic shaping happens in the only two
## places it can happen for free:
##
##   * THE RIM. The outline is pushed OUT beyond the proxy's footprint by an
##     irregular margin, so no straight box edge is ever on screen while every
##     point the player can stand on is still over solid collision. Pushing the
##     rim inward would show floor the player falls through.
##   * BELOW. A rocky skirt hangs off that rim with its own displacement, which
##     is where a platform gets to look like rock instead of a slab.
##
## THE MESHY INTERFACE. `visual_kit` is a drop-in slot: set it to a PackedScene
## and that art is used instead of the generated shell, fitted to the proxy's
## bounds by the same anchor rule (top face on the proxy's top plane, footprint
## at least the proxy's). A replacement environment kit therefore lands without
## a single change to level logic — the collision, the markers, the routes and
## the tests all address the proxy, which never moved. Leave it null and the
## shell generates its own geometry so a world is never blocked on art.
##
## ADDS NO COLLISION, EVER. A shell is a MeshInstance3D and nothing else. If it
## could collide, it would be gameplay geometry wearing an art costume, and the
## proxy's authority over where the player can stand would be gone.

## Where the collision proxy is. Empty means "my parent", which is the shape
## every converted platform takes.
@export var proxy_path: NodePath = ^"..":
	set(value):
		proxy_path = value
		_rebuild()

## OPTIONAL replacement art. The whole point of the interface: drop a kit in
## here and the generated shell steps aside.
@export var visual_kit: PackedScene:
	set(value):
		visual_kit = value
		_rebuild()

@export var surface_material: Material:
	set(value):
		surface_material = value
		_rebuild()

## How far the rim may push out past the proxy footprint, in metres. Outward
## only — see the header on why inward would show the player a floor they fall
## through.
@export var rim_margin: float = 0.55:
	set(value):
		rim_margin = maxf(value, 0.0)
		_rebuild()

## How far the skirt hangs below the proxy's underside. Cosmetic depth, so a
## platform reads as a slab of rock rather than a floating lid.
@export var skirt_depth: float = 1.8:
	set(value):
		skirt_depth = maxf(value, 0.0)
		_rebuild()

## Target spacing between rim points, in metres. A SPACING rather than a
## count, because the proxies this wraps run from a two-metre step to a
## forty-eight-metre lagoon floor: one segment count cannot serve both. Twelve
## segments on a 48x32 ground is a dodecagon; the same twelve on a 2m step is
## wasted geometry.
@export var rim_spacing_m: float = 3.0:
	set(value):
		rim_spacing_m = maxf(value, 0.25)
		_rebuild()

## Bounds on the derived count, so a huge floor cannot generate hundreds of
## segments and a tiny step still gets enough to read as irregular.
const MIN_RIM_SEGMENTS := 8
const MAX_RIM_SEGMENTS := 64

## Deterministic per-shell variation. Two shells with the same seed and bounds
## are identical, which is what keeps a level the same place every launch.
@export var shell_seed: int = 0:
	set(value):
		shell_seed = value
		_rebuild()

var _visual: Node3D


func _ready() -> void:
	_rebuild()


## The proxy's local-space box: size, and the offset of its centre.
## Returns an empty AABB when there is no box to wrap.
func proxy_bounds() -> AABB:
	var proxy := get_node_or_null(proxy_path)
	if proxy == null:
		return AABB()
	for child: Node in proxy.find_children("*", "CollisionShape3D", true, false):
		var shape := (child as CollisionShape3D).shape as BoxShape3D
		if shape == null:
			continue
		# The shape's own offset relative to the body, so a collider that is
		# not centred on its body still gets a shell in the right place.
		var offset := (child as CollisionShape3D).position
		return AABB(offset - shape.size * 0.5, shape.size)
	return AABB()


func get_visual() -> Node3D:
	return _visual


## Triangles this shell will draw, readable without it ever being built — the
## scene budget counter inspects worlds that were never added to a tree.
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


## The drop-in path: a kit scene fitted to the proxy.
##
## THE ANCHOR RULE, which is the whole contract a replacement kit has to meet:
## the kit is scaled so its own bounds cover the proxy's footprint plus the rim
## margin, and translated so its TOP face lands on the proxy's top plane. A kit
## authored to any size therefore lands correctly, and a kit that models its
## own overhang keeps it.
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
	# Top face onto the proxy's top plane.
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


## The generated shell: a flat cap at the proxy's top plane, an irregular rim
## pushed outward, and a skirt hanging below it.
func _build_mesh() -> ArrayMesh:
	var bounds := proxy_bounds()
	if bounds.size == Vector3.ZERO:
		return null

	var centre := bounds.get_center()
	var top := bounds.position.y + bounds.size.y
	var half := Vector2(bounds.size.x * 0.5, bounds.size.z * 0.5)
	var floor_y := bounds.position.y - skirt_depth
	var segments := _segment_count(half)

	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()

	vertices.append(Vector3(centre.x, top, centre.z))
	colours.append(Color(0.86, 0.88, 0.82))

	var rim_start := vertices.size()
	for step: int in segments:
		var t := float(step) / float(segments)
		var edge := _perimeter_point(t, half)
		var outward := _perimeter_normal(t, half)
		# Outward ONLY: a rim pulled inward would show the player a floor they
		# fall through, since the collision still reaches the proxy's corner.
		var jitter := _noise(step, 0) * rim_margin
		var out := edge + outward * (rim_margin * 0.45 + jitter)
		vertices.append(Vector3(centre.x + out.x, top, centre.z + out.y))
		colours.append(Color(0.80, 0.83, 0.76))

	var skirt_start := vertices.size()
	for step: int in segments:
		var t := float(step) / float(segments)
		var edge := _perimeter_point(t, half)
		# The skirt pulls IN as it descends, so the platform reads as a slab
		# with an overhanging lip rather than a column.
		var pull := 0.74 + _noise(step, 1) * 0.20
		var out := edge * pull
		vertices.append(Vector3(centre.x + out.x,
			floor_y + _noise(step, 2) * skirt_depth * 0.3,
			centre.z + out.y))
		colours.append(Color(0.55, 0.56, 0.53))

	# WINDING, verified by reading the generated normals rather than reasoned
	# from a convention: the first attempt wound the cap the other way and its
	# centre normal came out (0, -1, 0). A top face pointing down is culled
	# from above, so the shell rendered as a rim and a skirt around a hole
	# exactly where the player stands.
	for step: int in segments:
		var next := (step + 1) % segments
		indices.append_array([0, rim_start + step, rim_start + next])
		indices.append_array([
			rim_start + next, rim_start + step, skirt_start + step,
			skirt_start + step, skirt_start + next, rim_start + next])

	# THROUGH SurfaceTool, for the normals. A mesh committed straight from
	# arrays with ARRAY_NORMAL left null renders BLACK under any real light —
	# the geometry was correct the first time this ran and the shell still came
	# out as an unreadable dark shape, because there was nothing for the
	# lighting to work with.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in vertices.size():
		surface.set_color(colours[index])
		surface.add_vertex(vertices[index])
	for index: int in indices:
		surface.add_index(index)
	# Smooth across the rim on purpose: the seam between the flat cap and the
	# sloping skirt is where a box gives itself away, and a soft normal there
	# is what turns the corner into a weathered edge.
	surface.generate_normals()
	return surface.commit()


func _segment_count(half: Vector2) -> int:
	var perimeter := 4.0 * (half.x + half.y)
	return clampi(int(round(perimeter / rim_spacing_m)),
		MIN_RIM_SEGMENTS, MAX_RIM_SEGMENTS)


## A point on the rectangle's outline at `t` around its PERIMETER.
##
## Perimeter-uniform rather than angle-uniform, and the difference is the whole
## silhouette. Sampling by angle puts most of the points near the ends of a
## long thin proxy and almost none along its sides, so a 48x32 ground came out
## as a splayed star rather than an island. Walking the outline spaces them
## evenly however extreme the aspect ratio.
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


## The outward normal of the edge `t` sits on. Corners get the diagonal, so a
## rim point at a corner pushes out along it rather than along one face.
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


## Deterministic in (seed, index, channel): the same shell is the same rock
## every launch, and no two shells in a level share a silhouette.
func _noise(index: int, channel: int) -> float:
	var hashed := float(
		(shell_seed * 73856093) ^ (index * 19349663) ^ (channel * 83492791))
	return fposmod(sin(hashed) * 43758.5453, 1.0)
