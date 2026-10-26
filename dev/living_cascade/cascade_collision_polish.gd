extends RefCounted
## Collision follows the large rock forms, excluding moss, coral and root fingers.
## Authored in each asset's normalized frame; visual meshes stay untouched.

func apply(world: Node3D) -> void:
	for asset: Node3D in world.get_node("SuppliedAssets").get_children():
		var id := String(asset.get_meta("source_asset", ""))
		if id not in ["reef_arch", "root_bridge", "crown_arch", "mossy_stone"]:
			continue
		var body := asset.get_node("AssetCollision") as StaticBody3D
		var bounds := AABB()
		var first := true
		for model: Node3D in asset.get_children():
			if not model.has_meta("cascade_asset_instance"): continue
			for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				var pose := relative_pose(mesh, asset)
				var box := pose * mesh.get_aabb()
				bounds = box if first else bounds.merge(box)
				first = false
		if first: continue
		for child: Node in body.get_children():
			body.remove_child(child)
			child.free()
		if id == "mossy_stone":
			rock(body, bounds, asset)
		else:
			arch(body, bounds, id)
		asset.set_meta("collision_profile", "smooth_structure_v1")
		for child: Node in body.get_children(): child.owner = world

func relative_pose(node: Node3D, ancestor: Node3D) -> Transform3D:
	var pose := node.transform
	var parent := node.get_parent()
	while parent != ancestor and parent is Node3D:
		pose = (parent as Node3D).transform * pose
		parent = parent.get_parent()
	return pose

func hull(body: StaticBody3D, label: String, points: PackedVector3Array) -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	shape.margin = 0.01
	var collider := CollisionShape3D.new()
	collider.name = label + "_%02d" % body.get_child_count()
	collider.shape = shape
	body.add_child(collider)

func rock(body: StaticBody3D, b: AABB, asset: Node3D) -> void:
	var top := b.position.y + b.size.y * 0.86
	if asset.has_meta("landing_support_y"):
		top = float(asset.get_meta("landing_support_y")) - asset.position.y
	var points := PackedVector3Array()
	# One solid hull, a level crown and a broad bevel: no triangle seams or leaves.
	for ring: Vector2 in [Vector2(b.position.y, 0.88), Vector2(top - minf(0.18, b.size.y * 0.15), 0.94), Vector2(top, 0.79)]:
		for i in range(16):
			var angle := TAU * float(i) / 16.0
			points.append(Vector3(b.get_center().x + cos(angle) * b.size.x * 0.5 * ring.y, ring.x, b.get_center().z + sin(angle) * b.size.z * 0.5 * ring.y))
	hull(body, "SmoothRock", points)

func arch(body: StaticBody3D, b: AABB, id: String) -> void:
	var width := b.size.x
	var inner := width * (0.245 if id == "reef_arch" else 0.27)
	var spring := b.position.y + b.size.y * 0.40
	var rise := b.size.y * 0.26
	var outer := width * 0.43
	var roof := b.position.y + b.size.y * 0.89
	var depth := b.size.z * 0.35
	var center := b.get_center()
	# Wooden bridges have four separate feet and open sides. Never turn those
	# side openings into a long invisible wall beneath the canopy.
	var spans: Array[Vector2] = [Vector2(-depth, depth)]
	if id != "reef_arch":
		spans = [Vector2(-depth, -depth * 0.58), Vector2(depth * 0.58, depth)]
	for span: Vector2 in spans:
		arch_span(body, b, inner, spring, rise, outer, roof, center, width, span)

func arch_span(body: StaticBody3D, b: AABB, inner: float, spring: float, rise: float, outer: float, roof: float, center: Vector3, width: float, span: Vector2) -> void:
	var depth := (span.y - span.x) * 0.5
	var middle := (span.x + span.y) * 0.5
	# The entrance flares outward at both ends, so oblique approaches don't hook
	# on square jambs. The opening remains hollow at every depth.
	for side: float in [-1.0, 1.0]:
		var points := PackedVector3Array()
		for z: float in [-depth, -depth * 0.78, depth * 0.78, depth]:
			var inset := 0.15 * width if absf(z) > depth * 0.9 else 0.0
			for p: Vector2 in [Vector2(inner + inset, b.position.y), Vector2(outer, b.position.y), Vector2(outer, spring), Vector2(inner + inset, spring)]:
				points.append(arch_point(center, b, p.x * side, p.y, z + middle))
		hull(body, "PierLeft" if side < 0 else "PierRight", points)
	# Adjacent convex wedges describe a continuous rounded vault; a single convex
	# hull would incorrectly seal the tunnel.
	for i in range(8):
		var a := PI * float(i) / 8.0
		var c := PI * float(i + 1) / 8.0
		var points := PackedVector3Array()
		for z: float in [-depth, -depth * 0.65, depth * 0.65, depth]:
			var mouth := 0.14 * width if absf(z) > depth * 0.9 else 0.0
			for p: Vector2 in [Vector2(cos(a) * (inner + mouth), spring + sin(a) * rise + mouth * 0.45), Vector2(cos(c) * (inner + mouth), spring + sin(c) * rise + mouth * 0.45), Vector2(cos(c) * outer, spring + sin(c) * (roof - spring)), Vector2(cos(a) * outer, spring + sin(a) * (roof - spring))]:
				points.append(arch_point(center, b, p.x, p.y, z + middle))
		hull(body, "Vault%02d" % i, points)

func arch_point(center: Vector3, b: AABB, x: float, y: float, z: float) -> Vector3:
	# The scanned arch rises inward from its four broad feet. A straight
	# extrusion would project an invisible wall in front of the visible crown.
	var height := clampf((y - b.position.y) / b.size.y, 0.0, 1.0)
	return Vector3(center.x + x, y, center.z + z * (1.0 - height * 0.65))
