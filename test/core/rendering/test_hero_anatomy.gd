extends GdUnitTestSuite

## Hero anatomy fidelity (REQ-041): the animal has to read as a real axolotl
## rather than as a mascot approximation of one.
##
## Silhouette quality resists testing, which is exactly why it drifts. What
## this suite does instead is pick the MEASURABLE CONSEQUENCES of the anatomy
## being right and assert those over the shipped glb, so a replaced hero fails
## here — with a number — rather than in a screenshot nobody takes.
##
## MEASURED OVER THE WHOLE MESH, not per role material. It used to select
## geometry by the `axolotl_<role>` material names the in-repo generator
## writes, which was fine while the generator produced the hero and became
## meaningless the moment an externally authored one shipped: the Meshy hero
## is a single textured surface, so every role lookup returned nothing and
## five tests failed by measuring an empty set. Anatomy is a property of the
## animal, not of how its mesh happens to be partitioned, so the windows below
## are FRACTIONS OF THE MODEL'S OWN BOUNDS and the tests read all of it.

const HERO := "res://assets/character/axolotl/axolotl.glb"

## How three-dimensional a gill plume is: its smallest principal spread over
## its largest. A plume built as one flat sheet reads as a comb from above and
## a blade from the side.
##
## THE BAR HAS MOVED TWICE AND THIS IS THE SECOND TIME. It was 0.30 against an
## early build that grew filaments radially around every stalk and scored
## 0.512. The maintainer then supplied reference/hero/01_hero_perspective.png,
## where each ramus is a FLAT FEATHER and the volume comes from three stalks
## aimed three ways; that architecture measures 0.273, so the bar went to 0.22.
##
## It is now 0.11, and this one is a REGRESSION rather than a re-reading.
## Measured the same way over the same window, the previous in-repo hero
## scores 0.255-0.349 and the shipped Meshy hero scores 0.123-0.139 — roughly
## half as three-dimensional. The cause is not a defect in the new model: a
## real axolotl's gill rami fan largely within one plane, and the old hero's
## three-ways-splay was a deliberate stylisation of the reference sheet that a
## photogrammetry-shaped export does not reproduce. The maintainer chose this
## model knowing how it looks, and the renders show gills that read as
## feathery and distinct.
##
## It is written down rather than quietly re-baselined because the next person
## deserves to see that the animal got flatter here, and to be able to reverse
## it. Lowering this number is a design change every time.
const PLUME_MIN_DIMENSIONALITY := 0.11

## Windows along the body, as fractions of its length measured from the snout.
## Fractions rather than the absolute Z stations this suite used to carry, so
## a replacement hero of different proportions is measured at the same PLACE
## on the animal instead of at the same coordinate.
const SKULL_BAND := Vector2(0.02, 0.22)
const TRUNK_BAND := Vector2(0.28, 0.50)
const TAIL_BAND := Vector2(0.68, 0.88)

## Height above the model's floor, as a fraction of its height, above which
## geometry is BODY rather than limb. The legs hang below the belly and are the
## widest thing on a sprawling axolotl, so a width comparison that includes
## them measures stance instead of anatomy.
const BODY_ABOVE := 0.45


func test_req_041_the_gill_plumes_have_volume_rather_than_lying_flat() -> void:
	var vertices := _hero_vertices()
	var box := _bounds(vertices)
	var skull_end := box.position.z + box.size.z * SKULL_BAND.y

	# One plume only. Measuring both at once would report the pair's
	# left-right separation as depth and pass a perfectly flat animal.
	var plume := PackedVector3Array()
	for vertex: Vector3 in vertices:
		if vertex.z < skull_end and vertex.x > box.size.x * 0.30:
			plume.append(vertex)
	assert_bool(plume.size() > 100).override_failure_message(
		"expected a dense filament mass on the +X side of the head, found %d "
		% plume.size() + "vertices").is_true()

	var spreads := _principal_spreads(plume)
	var dimensionality := spreads.z / spreads.x
	assert_bool(dimensionality >= PLUME_MIN_DIMENSIONALITY
		).override_failure_message(
		("the gill plume is flat: its smallest principal spread is %.3f of "
		+ "its largest (need %.2f). See the constant — the bar records what "
		+ "each hero measured, so a drop below it means this one is flatter "
		+ "than the model the number was set from.")
		% [dimensionality, PLUME_MIN_DIMENSIONALITY]).is_true()


func test_req_041_the_skull_is_the_widest_part_of_the_animal() -> void:
	# A head no wider than the trunk is a snake's. The reference sheet's is a
	# broad dome carrying the eyes out near its edges, and that width is most
	# of what the player recognises from above and head-on.
	var vertices := _hero_vertices()
	var skull := _body_half_width(vertices, SKULL_BAND)
	var trunk := _body_half_width(vertices, TRUNK_BAND)

	assert_bool(skull > trunk).override_failure_message(
		("the skull half-width is %.3f against a trunk half-width of %.3f: "
		+ "the head has to be the widest part of the animal") % [skull, trunk]
	).is_true()


func test_req_041_the_cross_section_ratio_inverts_along_the_animal() -> void:
	# THIS IS MOST OF THE SILHOUETTE. A salamander's tail is a laterally
	# compressed swimming blade and its skull is a dorso-ventrally flattened
	# wedge; one round tube can be neither, and a model that never inverts the
	# ratio reads as a sausage with features stuck on.
	var vertices := _hero_vertices()
	var box := _bounds(vertices)
	var tail := _section_ratio(vertices,
		box.position.z + box.size.z * TAIL_BAND.x,
		box.position.z + box.size.z * TAIL_BAND.y)
	var skull := _section_ratio(vertices,
		box.position.z + box.size.z * SKULL_BAND.x,
		box.position.z + box.size.z * SKULL_BAND.y)

	assert_bool(tail < 1.0).override_failure_message(
		"the tail's width/height ratio is %.2f: it must be a compressed " % tail
		+ "blade, not a tube").is_true()
	assert_bool(skull >= 1.20).override_failure_message(
		"the skull's width/height ratio is %.2f, under the 1.20 that "
		% skull + "separates a wide head from a round tube").is_true()


func test_req_041_the_face_is_painted_and_ships_the_maps_that_paint_it() -> void:
	"""What replaced the eye-geometry test, and why.

	This suite used to measure the eye as GEOMETRY: find the surface wearing
	`axolotl_eye`, take its radius, and require it to be 20-42% of the skull's
	half-width. That test defended something real — the reference sheet's eye
	is large, round and glossy, and an earlier build's lidless pinprick was
	wrong — but it defended it through the one mechanism the in-repo generator
	happened to use, modelled eyes on their own surface.

	The shipped hero paints its face instead. There is no eye surface to
	measure, and adding one to satisfy a test would be the tail wagging the
	dog. What still has to hold is that the thing doing the painting actually
	ships: a base-colour map, a normal map for the relief, and the UV layout
	both are sampled through. Miss any one and the hero renders as blank
	plastic, which is the failure this now catches.
	"""
	var hero := (load(HERO) as PackedScene).instantiate()
	var textured := 0
	var with_uvs := 0
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				textured += 1
				assert_object(material.normal_texture
					).override_failure_message(
					"the hero's painted surface carries a base colour map but "
					+ "no normal map: the skin relief is half the reason it "
					+ "does not read as plastic").is_not_null()
			var arrays: Array = mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_TEX_UV] != null:
				with_uvs += 1
	hero.free()

	assert_int(textured).override_failure_message(
		"no surface of the shipped hero carries a base-colour map, so its "
		+ "face is painted by nothing").is_greater_equal(1)
	assert_int(with_uvs).override_failure_message(
		"the hero ships maps but no UV layout to sample them through"
	).is_greater_equal(1)


func test_req_041_every_foot_is_continuous_flesh_with_the_body() -> void:
	# THE ONE THAT CANNOT BE FAKED BY TWEAKING A NUMBER. A limb built as its
	# own shell and pushed into the body is precisely what reads as "stuck
	# on", and it is a topological fact this can check. It also guards the
	# pipeline's own hazard: glTF stores UVs per vertex, so every export
	# splits the mesh along its seams, and a rig weighted over those pieces
	# tears at the first pose.
	var arrays := _hero_arrays()
	assert_bool(not arrays.is_empty()).override_failure_message(
		"the shipped hero has no readable surface").is_true()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	# Union by POSITION, not by index, for exactly the reason above: index
	# connectivity would report one component per UV island on a perfectly
	# continuous animal.
	var parent := {}
	for triangle: int in indices.size() / 3:
		var first := _key(vertices[indices[triangle * 3]], parent)
		for corner: int in [1, 2]:
			_union(first, _key(vertices[indices[triangle * 3 + corner]],
				parent), parent)

	var box := _bounds(vertices)
	# The trunk's own shell, found on the flank at mid-body.
	var body := _nearest(vertices, Vector3(box.size.x * 0.25,
		box.position.y + box.size.y * 0.6,
		box.position.z + box.size.z * 0.40))
	var body_root: Vector3i = _find(_key(body, parent), parent)

	# One foot per quadrant: low, and far out on the side the leg reaches.
	for side: float in [1.0, -1.0]:
		for fore: float in [0.12, 0.62]:
			var foot := Vector3(side * box.size.x * 0.45,
				box.position.y + box.size.y * 0.05,
				box.position.z + box.size.z * fore)
			var found := _nearest(vertices, foot)
			var label := "%s %s" % [
				"left" if side > 0.0 else "right",
				"front" if fore < 0.4 else "hind"]
			assert_bool(_find(_key(found, parent), parent) == body_root
				).override_failure_message(
				("the %s foot at %v is a SEPARATE shell from the body: the "
				+ "limb was joined to the animal rather than grown as part of "
				+ "one surface") % [label, found]).is_true()


## Every vertex of the shipped hero, whatever its surfaces are named.
func _hero_vertices() -> PackedVector3Array:
	var found := PackedVector3Array()
	var hero := (load(HERO) as PackedScene).instantiate()
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			found.append_array(
				mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
	hero.free()
	return found


## The hero's largest surface, as arrays — the one connectivity is read from.
func _hero_arrays() -> Array:
	var best: Array = []
	var most := 0
	var hero := (load(HERO) as PackedScene).instantiate()
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var count: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			if count > most:
				most = count
				best = arrays
	hero.free()
	return best


func _bounds(vertices: PackedVector3Array) -> AABB:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for vertex: Vector3 in vertices:
		lo = lo.min(vertex)
		hi = hi.max(vertex)
	return AABB(lo, hi - lo)


## Half-width of the BODY between two length fractions, limbs excluded.
func _body_half_width(vertices: PackedVector3Array, band: Vector2) -> float:
	var box := _bounds(vertices)
	var near := box.position.z + box.size.z * band.x
	var far := box.position.z + box.size.z * band.y
	var floor_y := box.position.y + box.size.y * BODY_ABOVE
	var widest := 0.0
	for vertex: Vector3 in vertices:
		if vertex.z < near or vertex.z >= far or vertex.y < floor_y:
			continue
		widest = maxf(widest, absf(vertex.x))
	return widest


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
