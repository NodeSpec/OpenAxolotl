extends GdUnitTestSuite

## Hero anatomy fidelity (REQ-041): the animal has to read as a real axolotl
## rather than as a mascot approximation of one.
##
## Silhouette quality resists testing, which is exactly why it drifts. What
## this suite does instead is pick the MEASURABLE CONSEQUENCES of the anatomy
## being right and assert those over the shipped glb, so a regenerated hero
## fails here — with a number — rather than in a screenshot nobody takes.
##
## Every measurement is taken from the model as the game loads it, not from
## tools/blender/make_axolotl.py's tables, because the tables are only a
## claim about the mesh until the mesh is measured.

const HERO := "res://assets/character/axolotl/axolotl.glb"

## The sharpest of the four. A plume whose filaments grow radially around its
## ramus has real spread on all three principal axes; one built as two
## opposed rows of filaments — which is what shipped before REQ-041 — lies in
## a plane and reads as a comb from above and a blade from the side. On this
## statistic the flat build scores 0.147 and the rebuilt plume 0.512, so the
## threshold discriminates the actual defect with room either side.
const PLUME_MIN_DIMENSIONALITY := 0.30

## Stations in the model's own space. The hero faces -Z, so the head is at
## negative Z and the tail at positive Z.
##
## Both windows are placed to see BODY and nothing else. The limbs are the
## widest thing on the animal — the feet reach |x| 0.83 against a skull's
## 0.47 — and the skin modifier flares each branch point into a shoulder, so
## a window that clips a limb measures the limb. SKULL_Z sits forward of
## where the front legs branch (their topmost row reaches Z -0.37); the
## trunk window sits in the clear span between the shoulders and the hips
## (which branch at Z +0.58). Measured over the shipped mesh, that is a
## 0.470 skull against a 0.361 trunk.
const SKULL_Z := -0.75
const TRUNK_Z := Vector2(0.0, 0.40)

## An axolotl's eye is tiny, lidless and set high on the side of the skull.
## The build this supersedes used radius 0.155 against a 0.49 half-width —
## nearly a third of the head, and the single loudest cartoon signal on the
## animal.
const EYE_MAX_SHARE_OF_SKULL := 1.0 / 6.0


func test_req_041_the_gill_plumes_have_volume_rather_than_lying_flat() -> void:
	var vertices := _role_vertices("axolotl_gill")
	assert_bool(vertices.size() > 0).override_failure_message(
		"no surface wearing 'axolotl_gill' was found in the shipped hero"
	).is_true()

	# One plume only. Measuring both at once would report the pair's
	# left-right spread as depth and pass a perfectly flat animal.
	var plume := PackedVector3Array()
	for vertex: Vector3 in vertices:
		if vertex.x > 0.05:
			plume.append(vertex)
	assert_bool(plume.size() > 100).override_failure_message(
		"expected a dense filament mass on the +X side, found %d vertices"
		% plume.size()).is_true()

	var spreads := _principal_spreads(plume)
	var dimensionality := spreads.z / spreads.x
	assert_bool(dimensionality >= PLUME_MIN_DIMENSIONALITY
		).override_failure_message(
		("the gill plume is flat: its smallest principal spread is %.3f of "
		+ "its largest (need %.2f). Filaments must grow RADIALLY around each "
		+ "ramus; two opposed rows put every one of them in one plane.")
		% [dimensionality, PLUME_MIN_DIMENSIONALITY]).is_true()


func test_req_041_the_skull_is_the_widest_part_of_the_animal() -> void:
	# A head no wider than the trunk is a mascot's dome. The animal's is a
	# broad flat wedge, and that wedge is most of what the player recognises
	# from above and head-on.
	var skin := _role_vertices("axolotl_skin")
	var skull := 0.0
	var trunk := 0.0
	for vertex: Vector3 in skin:
		# The limbs branch off the trunk and would win any width contest, so
		# the comparison is taken along the body itself.
		if absf(vertex.y - 0.55) > 0.30:
			continue
		if vertex.z < SKULL_Z:
			skull = maxf(skull, absf(vertex.x))
		elif vertex.z >= TRUNK_Z.x and vertex.z < TRUNK_Z.y:
			trunk = maxf(trunk, absf(vertex.x))

	assert_bool(skull > trunk).override_failure_message(
		("the skull half-width is %.3f against a trunk half-width of %.3f: "
		+ "the head has to be the widest part of the animal") % [skull, trunk]
	).is_true()


func test_req_041_the_cross_section_ratio_inverts_along_the_animal() -> void:
	# THIS IS MOST OF THE SILHOUETTE. A salamander's tail is a laterally
	# compressed swimming blade and its skull is a dorso-ventrally flattened
	# wedge; one round tube can be neither, and a model that never inverts
	# the ratio reads as a sausage with features stuck on.
	var skin := _role_vertices("axolotl_skin")
	var tail := _section_ratio(skin, 1.60, 2.20)
	var skull := _section_ratio(skin, -1.40, -0.85)

	assert_bool(tail < 1.0).override_failure_message(
		"the tail's width/height ratio is %.2f: it must be a compressed "
		% tail + "blade, not a tube").is_true()
	assert_bool(skull >= 1.5).override_failure_message(
		"the skull's width/height ratio is %.2f, under the 1.5 a flat wedge "
		% skull + "needs").is_true()


func test_req_041_the_eye_is_an_amphibians_rather_than_a_cartoons() -> void:
	var eyes := _role_vertices("axolotl_eye")
	assert_bool(eyes.size() > 0).override_failure_message(
		"no surface wearing 'axolotl_eye' was found in the shipped hero"
	).is_true()

	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for vertex: Vector3 in eyes:
		if vertex.x <= 0.0:
			continue  # one eye, so the pair's separation is not read as size
		lo = lo.min(vertex)
		hi = hi.max(vertex)
	var radius := (hi - lo).x * 0.5

	var skin := _role_vertices("axolotl_skin")
	var skull := 0.0
	for vertex: Vector3 in skin:
		if vertex.z < SKULL_Z and absf(vertex.y - 0.55) <= 0.30:
			skull = maxf(skull, absf(vertex.x))

	assert_bool(radius <= skull * EYE_MAX_SHARE_OF_SKULL
		).override_failure_message(
		("the eye's radius is %.3f against a %.3f skull half-width — %.0f%% "
		+ "of the head, where an amphibian's is under %.0f%%")
		% [radius, skull, 100.0 * radius / skull,
			100.0 * EYE_MAX_SHARE_OF_SKULL]).is_true()

	# Dorso-lateral: high on the side of the skull, never forward-facing on
	# the centreline where a cartoon puts them.
	var centre := (lo + hi) * 0.5
	assert_bool(centre.x > radius).override_failure_message(
		"the eye sits at x=%.3f, on or across the centreline" % centre.x
	).is_true()


func test_req_041_every_foot_is_continuous_flesh_with_the_body() -> void:
	# THE ONE THAT CANNOT BE FAKED BY TWEAKING A NUMBER. Building each leg as
	# its own skinned object and calling bpy.ops.object.join() merges mesh
	# data — it neither welds nor blends — so every limb was a separate shell
	# pushed into the body, which is precisely what read as "stuck on". A
	# limb grown as a BRANCH of the body's own edge skeleton shares one
	# surface with it, and that is a topological fact this can check.
	var arrays := _role_arrays("axolotl_skin")
	assert_bool(not arrays.is_empty()).override_failure_message(
		"no surface wearing 'axolotl_skin' was found in the shipped hero"
	).is_true()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	# Union by POSITION, not by index. The bake's UV unwrap splits vertices
	# along every island boundary, so index-space connectivity would report
	# one component per UV island on a perfectly continuous animal.
	var parent := {}
	for triangle: int in indices.size() / 3:
		var first := _key(vertices[indices[triangle * 3]], parent)
		for corner: int in [1, 2]:
			_union(first, _key(vertices[indices[triangle * 3 + corner]],
				parent), parent)

	# The trunk's own shell, found from a vertex on the flank at mid-body.
	var body := _nearest(vertices, Vector3(0.30, 0.55, 0.10))
	var body_root: Vector3i = _find(_key(body, parent), parent)

	# One foot per quadrant: low, and far out on the side the leg reaches.
	for side: float in [1.0, -1.0]:
		for fore: float in [-1.0, 1.0]:
			var foot := Vector3(side * 0.80, 0.05, fore * 0.45)
			var found := _nearest(vertices, foot)
			var label := "%s %s" % [
				"left" if side > 0.0 else "right",
				"front" if fore < 0.0 else "hind"]
			assert_bool(_find(_key(found, parent), parent) == body_root
				).override_failure_message(
				("the %s foot at %v is a SEPARATE shell from the body: the "
				+ "limb was joined to the animal rather than grown as a "
				+ "branch of its skeleton") % [label, found]).is_true()


## Quantised to a 0.5 mm grid, which merges the unwrap's split duplicates
## back together without merging anything a person would call distinct.
func _key(point: Vector3, parent: Dictionary) -> Vector3i:
	var key := Vector3i((point * 2000.0).round())
	if not parent.has(key):
		parent[key] = key
	return key


func _find(key: Vector3i, parent: Dictionary) -> Vector3i:
	var root: Vector3i = key
	while parent[root] != root:
		root = parent[root]
	while parent[key] != root:  # path compression, so deep chains stay cheap
		var next: Vector3i = parent[key]
		parent[key] = root
		key = next
	return root


func _union(a: Vector3i, b: Vector3i, parent: Dictionary) -> void:
	var ra := _find(a, parent)
	var rb := _find(b, parent)
	if ra != rb:
		parent[rb] = ra


func _nearest(vertices: PackedVector3Array, target: Vector3) -> Vector3:
	var best := vertices[0]
	var best_distance := INF
	for vertex: Vector3 in vertices:
		var distance := vertex.distance_squared_to(target)
		if distance < best_distance:
			best_distance = distance
			best = vertex
	return best


func _role_arrays(material_name: String) -> Array:
	var found: Array = []
	var hero := (load(HERO) as PackedScene).instantiate()
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface)
			if material != null and material.resource_name == material_name:
				found = mesh.surface_get_arrays(surface)
	hero.free()
	return found


func _role_vertices(material_name: String) -> PackedVector3Array:
	var found := PackedVector3Array()
	var hero := (load(HERO) as PackedScene).instantiate()
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface)
			if material == null or material.resource_name != material_name:
				continue
			found.append_array(
				mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
	hero.free()
	return found


## Width/height of the body's cross-section between two Z stations.
func _section_ratio(vertices: PackedVector3Array,
		near: float, far: float) -> float:
	var width := 0.0
	var lo := 1e9
	var hi := -1e9
	for vertex: Vector3 in vertices:
		if vertex.z < near or vertex.z > far:
			continue
		width = maxf(width, absf(vertex.x))
		lo = minf(lo, vertex.y)
		hi = maxf(hi, vertex.y)
	var height := (hi - lo) * 0.5
	return width / height if height > 0.0 else 0.0


## The three principal standard deviations, largest first.
##
## Eigenvalues of the 3x3 covariance, closed form (Smith 1961) rather than
## iterated: a symmetric 3x3 has an exact solution, and an iteration here
## would make the threshold above depend on how many rounds it ran.
func _principal_spreads(points: PackedVector3Array) -> Vector3:
	var mean := Vector3.ZERO
	for point: Vector3 in points:
		mean += point
	mean /= float(points.size())

	var xx := 0.0
	var yy := 0.0
	var zz := 0.0
	var xy := 0.0
	var xz := 0.0
	var yz := 0.0
	for point: Vector3 in points:
		var d := point - mean
		xx += d.x * d.x
		yy += d.y * d.y
		zz += d.z * d.z
		xy += d.x * d.y
		xz += d.x * d.z
		yz += d.y * d.z
	var n := float(points.size())
	xx /= n
	yy /= n
	zz /= n
	xy /= n
	xz /= n
	yz /= n

	var eigenvalues := PackedFloat64Array()
	var off := xy * xy + xz * xz + yz * yz
	if off < 1e-18:
		eigenvalues = PackedFloat64Array([xx, yy, zz])
	else:
		var q := (xx + yy + zz) / 3.0
		var p2 := ((xx - q) * (xx - q) + (yy - q) * (yy - q)
			+ (zz - q) * (zz - q) + 2.0 * off)
		var p := sqrt(p2 / 6.0)
		# B = (A - qI) / p, whose determinant halved is the cosine the
		# closed form turns into the three roots.
		var b00 := (xx - q) / p
		var b11 := (yy - q) / p
		var b22 := (zz - q) / p
		var b01 := xy / p
		var b02 := xz / p
		var b12 := yz / p
		var determinant := (b00 * (b11 * b22 - b12 * b12)
			- b01 * (b01 * b22 - b12 * b02)
			+ b02 * (b01 * b12 - b11 * b02))
		var r: float = clampf(determinant / 2.0, -1.0, 1.0)
		var phi := acos(r) / 3.0
		var first := q + 2.0 * p * cos(phi)
		var third := q + 2.0 * p * cos(phi + TAU / 3.0)
		eigenvalues = PackedFloat64Array([first, 3.0 * q - first - third, third])

	var sorted := Array(eigenvalues)
	sorted.sort()
	sorted.reverse()
	return Vector3(
		sqrt(maxf(float(sorted[0]), 0.0)),
		sqrt(maxf(float(sorted[1]), 0.0)),
		sqrt(maxf(float(sorted[2]), 0.0)))
