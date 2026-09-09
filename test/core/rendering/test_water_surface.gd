extends GdUnitTestSuite

## The water reacting to the world (REQ-034, REQ-039, REQ-001).
##
## Three things are held here, and each one is a way the water has already
## silently stopped working:
##
##   THE SURFACE HAS SOMETHING TO BEND. The shader lifts the top face along a
##   wave field, and a bare BoxMesh's top face has four corners — the shader
##   would be perfect and the water would still be a flat plane. Subdivision
##   is the half of that feature that lives in the scene, so it is asserted
##   in the scene.
##
##   THE UV ATLAS IS WHAT THE SHADER THINKS IT IS. The shore falloff reads
##   face-local coordinates out of Godot's own BoxMesh unwrapping, which is a
##   fixed three-by-two grid that no documentation promises will stay fixed.
##   That assumption is cheap to hold Godot to and expensive to discover from
##   a screenshot, so it is held here.
##
##   CROSSING THE SURFACE IS ANNOUNCED. A splash and a named audio cue, from
##   the volume, on both edges.
##
## What is NOT tested here is what the water LOOKS like. A shader's output is
## not something a headless suite can see — the renderer is a dummy and
## compiles nothing — so these hold the inputs the look depends on and the
## look itself was reviewed in rendered captures.

const CORAL := "res://worlds/coral_cove/world.tscn"
const WATERED: Array[String] = [
	"res://worlds/coral_cove/world.tscn",
	"res://worlds/bubble_bay/world.tscn",
]

## What the shader's TOP_FACE_UV_ORIGIN and TOP_FACE_UV_SPAN encode.
const TOP_FACE_U := Vector2(1.0 / 3.0, 2.0 / 3.0)
const TOP_FACE_V := Vector2(0.5, 1.0)

## The coarsest surface cell that still carries the broad ripple band, whose
## wavelength is about seven metres. Three samples per wave is the floor for
## anything to read as a wave rather than as a fold.
const MAX_CELL_M := 2.5


func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _water_meshes(scene: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	for node: Node in scene.find_children("*", "WaterVolume", true, false):
		for child: Node in node.find_children("*", "MeshInstance3D", true, false):
			found.append(child as MeshInstance3D)
	return found


func test_req_034_every_water_surface_is_subdivided_enough_to_ripple() -> void:
	for path: String in WATERED:
		var scene := (load(path) as PackedScene).instantiate()
		var meshes := _water_meshes(scene)
		assert_int(meshes.size()).override_failure_message(
			"%s declares no water mesh" % path).is_greater_equal(1)

		for mesh_node: MeshInstance3D in meshes:
			var box := mesh_node.mesh as BoxMesh
			assert_object(box).override_failure_message(
				"%s: water must stay a BoxMesh" % path).is_not_null()
			if box == null:
				continue
			# The cell size the subdivision actually produces, in metres.
			var cell_x := box.size.x / float(box.subdivide_width + 1)
			var cell_z := box.size.z / float(box.subdivide_depth + 1)
			assert_float(maxf(cell_x, cell_z)).override_failure_message(
				("%s/%s: %.1f m surface cells are too coarse to carry a wave "
				+ "— an unsubdivided water box has four corners on its top "
				+ "face and the displacement has nothing to bend")
				% [path, mesh_node.name, maxf(cell_x, cell_z)]
				).is_less_equal(MAX_CELL_M)
		scene.free()


func test_req_034_godot_still_lays_a_box_top_face_out_where_the_shader_looks() -> void:
	"""The one assumption in the shader that an engine upgrade could remove.

	The shore falloff and therefore the wave damping both read face-local
	coordinates from Godot's BoxMesh UV atlas. If that layout ever moves, the
	water does not error — it damps its waves against the wrong edges, which
	is the kind of thing that gets noticed months later in a screenshot.
	"""
	# Four deliberately different proportions: the atlas is meant to be fixed,
	# so a layout that depended on the box's shape would show up here.
	for size: Vector3 in [Vector3(26, 17, 57.5), Vector3(22, 5.6, 10.2),
			Vector3(2, 40, 3), Vector3.ONE]:
		var box := BoxMesh.new()
		box.size = size
		box.subdivide_width = 2
		box.subdivide_depth = 2
		var arrays := box.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]

		var seen := 0
		for index: int in verts.size():
			if normals[index].y < 0.9:
				continue
			seen += 1
			var uv := uvs[index]
			assert_bool(uv.x >= TOP_FACE_U.x - 0.001
				and uv.x <= TOP_FACE_U.y + 0.001
				and uv.y >= TOP_FACE_V.x - 0.001
				and uv.y <= TOP_FACE_V.y + 0.001).override_failure_message(
				("a box %s has a top-face vertex at uv %s, outside the "
				+ "u %s v %s window water_surface.gdshader assumes")
				% [size, uv, TOP_FACE_U, TOP_FACE_V]).is_true()

			# And the mapping across that window is LINEAR in metres, which is
			# what makes the falloff a real distance rather than a gradient.
			var face := Vector2((uv.x - TOP_FACE_U.x) * 3.0, (uv.y - 0.5) * 2.0)
			assert_float(absf((0.5 - face.x) * size.x - verts[index].x)
				).override_failure_message(
				"box %s: top-face u is no longer linear in x" % size
				).is_less(0.001)
			assert_float(absf((0.5 - face.y) * size.z - verts[index].z)
				).override_failure_message(
				"box %s: top-face v is no longer linear in z" % size
				).is_less(0.001)
		assert_int(seen).override_failure_message(
			"box %s produced no top face to check" % size).is_greater(0)


func test_req_034_a_splash_scales_with_how_hard_the_water_is_hit() -> void:
	# A step off a shore and a dive from a ledge are not the same event. Both
	# ends are asserted, because a splash that ignored speed would pass a test
	# that only ever looked at one of them.
	#
	# Built directly rather than through erupt(), which needs a running tree
	# and therefore cannot be reached from a suite at all — see the note on
	# crown_for. What is under test is the shape of the effect, and that is
	# entirely in these two builders.
	assert_float(WaterSplash.force_of(0.0)).is_equal_approx(0.0, 0.0001)
	assert_float(WaterSplash.force_of(WaterSplash.FULL_SPEED * 4.0)
		).override_failure_message(
		"force must cap, or a terminal-velocity arrival is absurd rather than "
		+ "dramatic").is_equal_approx(1.0, 0.0001)

	var wade := WaterSplash.crown_for(WaterSplash.force_of(1.0), false)
	var plunge := WaterSplash.crown_for(WaterSplash.force_of(20.0), true)
	assert_int(plunge.amount).override_failure_message(
		"a plunge must throw more water than a wade").is_greater(wade.amount)
	assert_float(plunge.initial_velocity_max).override_failure_message(
		"and throw it harder").is_greater(wade.initial_velocity_max)
	assert_float(wade.direction.y).override_failure_message(
		"a crown goes UP; a full sphere sends half the water into the riverbed"
		).is_greater(0.5)

	# The ring stays FLAT. A ring that arced would leave the surface, which is
	# the one thing it exists to stay on.
	var ring := WaterSplash.ring_for(1.0)
	assert_float(ring.gravity.length()).override_failure_message(
		"the surface ring must not fall").is_equal_approx(0.0, 0.0001)
	assert_float(ring.flatness).is_equal_approx(1.0, 0.0001)
	assert_object(ring.scale_amount_curve).override_failure_message(
		"the ring tapers as it spreads, or it reads as drifting debris"
		).is_not_null()

	wade.free()
	plunge.free()
	ring.free()


func test_req_034_a_splash_outside_the_tree_makes_nothing() -> void:
	# Every headless unit test builds nodes outside the tree, and an effect
	# that parented itself anyway would leak one per crossing.
	var orphan := Node3D.new()
	assert_array(WaterSplash.erupt(orphan, Vector3.ZERO, 10.0, true)
		).override_failure_message(
		"a host outside the tree must get nothing, never an orphan").is_empty()
	orphan.free()


func test_req_023_crossing_the_surface_asks_for_a_cue_by_name() -> void:
	# The volume names the EVENT; the Audio System alone decides what water
	# sounds like. A file path here would be the whole point of REQ-023 lost.
	var scene := (load(CORAL) as PackedScene).instantiate()
	_tree_root().add_child(scene)
	var volume := scene.find_children("*", "WaterVolume", true, false)[0] as WaterVolume

	var body := AxolotlBody.new()
	body.add_to_group("player")
	_tree_root().add_child(body)
	body.initialise()

	var cues: Array[String] = []
	volume.audio_cue_requested.connect(func(id: String) -> void: cues.append(id))

	volume._on_body_entered(body)
	volume._on_body_exited(body)

	assert_int(cues.size()).override_failure_message(
		"one cue on the way in and one on the way out (got %s)" % str(cues)
		).is_equal(2)
	assert_array(cues).override_failure_message(
		"entering and leaving are different sounds and must be different ids"
		).contains([WaterVolume.CUE_ENTER])
	assert_array(cues).contains([WaterVolume.CUE_EXIT])
	for cue: String in cues:
		assert_bool(cue.contains("://") or cue.contains(".")
			).override_failure_message(
			"'%s' looks like a path; cues are semantic ids" % cue).is_false()

	scene.free()
	body.free()


func test_req_001_the_volume_still_owns_only_the_grammar_crossing() -> void:
	# The splash is presentation bolted onto the same edges, and it must not
	# have changed what the crossing DOES: the body's water count is the whole
	# of the volume's authority.
	var scene := (load(CORAL) as PackedScene).instantiate()
	_tree_root().add_child(scene)
	var volume := scene.find_children("*", "WaterVolume", true, false)[0] as WaterVolume

	var body := AxolotlBody.new()
	body.add_to_group("player")
	_tree_root().add_child(body)
	body.initialise()

	assert_bool(body.is_in_water()).is_false()
	volume._on_body_entered(body)
	assert_bool(body.is_in_water()).is_true()
	volume._on_body_exited(body)
	assert_bool(body.is_in_water()).override_failure_message(
		"leaving the volume must still end the water grammar").is_false()

	scene.free()
	body.free()
