extends GdUnitTestSuite

## Visual shells over greybox collision proxies (REQ-030, REQ-034).
##
## A shell is ART wrapped around a collision proxy that never moves. Two
## properties make that safe, and they are the whole reason this suite exists,
## because both fail SILENTLY — the render looks fine and the player falls
## through something, or lands on nothing:
##
##   1. THE CAP IS AT THE PROXY'S TOP PLANE. Not above it (the player would
##      sink into visible ground before stopping) and not below it (they would
##      stop in mid-air above visible ground).
##   2. THE RIM ONLY EVER GOES OUTWARD. Every point of collision has to be
##      under visible geometry. A rim pulled inside the footprint shows floor
##      the player falls through at the edge — the exact place a platformer
##      player spends their time.

const HUB := "res://hub/open_lagoon.tscn"


func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## A shell over a proxy of the given size, built and ready to interrogate.
func _shell(size: Vector3, offset := Vector3.ZERO) -> TerrainShell:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	collider.position = offset
	body.add_child(collider)
	_tree_root().add_child(body)

	var shell := TerrainShell.new()
	body.add_child(shell)
	# Explicit: add_child from SceneTree._initialize defers _ready, so the
	# build has to be asked for rather than assumed.
	shell._rebuild()
	return shell


func _drop(shell: TerrainShell) -> void:
	var body := shell.get_parent()
	_tree_root().remove_child(body)
	body.free()


func _shell_vertices(shell: TerrainShell) -> PackedVector3Array:
	var visual := shell.get_visual() as MeshInstance3D
	if visual == null or visual.mesh == null:
		return PackedVector3Array()
	return visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func test_req_030_the_walkable_cap_sits_exactly_on_the_proxys_top() -> void:
	# Displacing the surface a player lands on makes every landing a lie: the
	# foot stops somewhere the eye did not predict. The cap is flat, at the
	# proxy's own top plane, and that is not negotiable.
	for size: Vector3 in [Vector3(48, 2, 32), Vector3(4, 2, 4),
			Vector3(2.4, 6, 18)]:
		var shell := _shell(size)
		var bounds := shell.proxy_bounds()
		var top := bounds.position.y + bounds.size.y

		var cap_points := 0
		for vertex: Vector3 in _shell_vertices(shell):
			# Cap vertices are the ones at the top plane; the skirt hangs well
			# below it. Anything ABOVE the plane is the failure being hunted.
			assert_bool(vertex.y <= top + 0.001).override_failure_message(
				("a shell vertex sits %.3f ABOVE the proxy top on a %s proxy: "
				+ "the player would sink into visible ground before stopping")
				% [vertex.y - top, str(size)]).is_true()
			if absf(vertex.y - top) < 0.001:
				cap_points += 1
		assert_int(cap_points).override_failure_message(
			"a %s proxy produced no vertices at its top plane, so there is "
			% str(size) + "nothing to stand on visually").is_greater(3)
		_drop(shell)


func test_req_030_the_rim_never_pulls_inside_the_footprint() -> void:
	# The other half. Collision reaches the proxy's corner, so visible geometry
	# must too — a rim inside the footprint shows the player floor they fall
	# through, right at the edge where they spend their time.
	for size: Vector3 in [Vector3(48, 2, 32), Vector3(3, 2, 9)]:
		var shell := _shell(size)
		var bounds := shell.proxy_bounds()
		var top := bounds.position.y + bounds.size.y
		var half := Vector2(bounds.size.x * 0.5, bounds.size.z * 0.5)

		for vertex: Vector3 in _shell_vertices(shell):
			if absf(vertex.y - top) > 0.001:
				continue  # skirt: allowed to pull in, it is below the surface
			var out := Vector2(absf(vertex.x - bounds.get_center().x),
				absf(vertex.z - bounds.get_center().z))
			# The fan's hub sits at the centre of the cap by construction and
			# is the one top-plane vertex that is legitimately inside. It is
			# not a rim point, and it is what the surface fans out FROM.
			if out.x < 0.001 and out.y < 0.001:
				continue
			# On a rectangle, a rim point is outside the footprint when it
			# clears the half-extent on the axis it lies along. Being clear on
			# EITHER axis is enough; the corner cases clear both.
			assert_bool(out.x >= half.x - 0.001 or out.y >= half.y - 0.001
				).override_failure_message(
				("a %s proxy has a cap vertex at (%.2f, %.2f) inside its "
				+ "half-extents (%.2f, %.2f): collision reaches further than "
				+ "the art, so the player falls through a visible edge")
				% [str(size), out.x, out.y, half.x, half.y]).is_true()
		_drop(shell)


func test_req_030_a_shell_never_adds_collision() -> void:
	# A shell that could collide would be gameplay geometry wearing an art
	# costume, and the proxy would no longer be the authority on where the
	# player can stand.
	var shell := _shell(Vector3(6, 2, 6))
	assert_int(shell.find_children("*", "CollisionObject3D", true, false).size()
		).override_failure_message(
		"a visual shell must contain no collision of any kind").is_equal(0)
	assert_int(shell.find_children("*", "CollisionShape3D", true, false).size()
		).is_equal(0)
	_drop(shell)


func test_req_030_a_shell_follows_a_collider_that_is_not_centred() -> void:
	# Colliders are not always at their body's origin. A shell that assumed
	# they were would drift off its own platform, and the drift would be
	# invisible in any scene where the offset happened to be zero.
	var offset := Vector3(3.0, 0.0, -2.0)
	var shell := _shell(Vector3(4, 2, 4), offset)
	var bounds := shell.proxy_bounds()
	assert_bool(bounds.get_center().is_equal_approx(offset)
		).override_failure_message(
		"the shell read a centre of %s for a collider offset to %s"
		% [str(bounds.get_center()), str(offset)]).is_true()
	_drop(shell)


func test_req_030_the_kit_slot_replaces_the_generated_shell() -> void:
	# THE MESHY INTERFACE. Dropping a replacement kit in must not require
	# touching level logic — so the slot has to actually take over, and the
	# generated geometry has to step aside.
	var shell := _shell(Vector3(6, 2, 6))
	var generated := _shell_vertices(shell).size()
	assert_int(generated).is_greater(0)

	shell.visual_kit = load(
		"res://assets/environment/river_boulder/river_boulder.glb")
	shell._rebuild()

	var visual := shell.get_visual()
	assert_object(visual).override_failure_message(
		"setting visual_kit must produce a visual").is_not_null()
	assert_bool(visual.find_children("*", "MeshInstance3D", true, false).size() > 0
		).override_failure_message(
		"the kit's own meshes must be what renders").is_true()
	# The kit is fitted to the proxy rather than dropped in at its own scale.
	assert_bool(visual.scale != Vector3.ONE).override_failure_message(
		"a kit must be scaled onto the proxy's bounds, not used raw"
	).is_true()
	_drop(shell)


func test_req_030_shells_are_deterministic() -> void:
	# Two shells with the same seed and bounds must be the same rock. A level
	# whose silhouettes reshuffle between launches is not a place.
	var first := _shell(Vector3(8, 2, 5))
	first.shell_seed = 4242
	first._rebuild()
	var second := _shell(Vector3(8, 2, 5))
	second.shell_seed = 4242
	second._rebuild()
	assert_bool(_shell_vertices(first) == _shell_vertices(second)
		).override_failure_message(
		"the same seed and bounds must generate the same shell").is_true()

	second.shell_seed = 99
	second._rebuild()
	assert_bool(_shell_vertices(first) != _shell_vertices(second)
		).override_failure_message(
		"a different seed must give a different silhouette, or every platform "
		+ "in a level is the same rock").is_true()
	_drop(first)
	_drop(second)


func test_req_030_the_hub_ground_is_shelled_and_its_proxy_is_hidden() -> void:
	# The vertical slice: no raw BoxMesh may be visible in the hub.
	var scene := (load(HUB) as PackedScene).instantiate()
	var shells := 0
	for node: Node in scene.find_children("*", "Node3D", true, false):
		if node is TerrainShell:
			shells += 1
	assert_int(shells).override_failure_message(
		"Open Lagoon must dress its collision proxies with shells"
	).is_greater_equal(1)

	for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh is BoxMesh and (node as MeshInstance3D).visible:
			assert_bool(false).override_failure_message(
				("%s is a VISIBLE raw BoxMesh: a collision proxy is greybox, "
				+ "not final art") % node.name).is_true()
	scene.free()
