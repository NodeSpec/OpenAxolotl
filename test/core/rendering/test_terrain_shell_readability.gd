extends GdUnitTestSuite

## Regression guard for the final-facing platform lip (REQ-030 / REQ-034).
##
## The collision proxy is the gameplay truth. Generated art may overhang it,
## but that overhang must not sit on the same horizontal plane as the walkable
## floor or it visually promises footing that physics does not provide. The
## shell therefore keeps a cap ring exactly on the collision footprint and
## drops every cosmetic vertex outside that footprint below the top plane.


func _tree_root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func test_cosmetic_overhang_is_visibly_below_the_walkable_collision_edge() -> void:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 2.0, 5.0)
	collider.shape = box
	body.add_child(collider)
	_tree_root().add_child(body)

	var shell := TerrainShell.new()
	shell.rim_margin = 0.6
	shell.rim_drop = 0.14
	body.add_child(shell)
	shell._rebuild()

	var visual := shell.get_visual() as MeshInstance3D
	assert_object(visual).is_not_null()
	assert_object(visual.mesh).is_not_null()

	var bounds := shell.proxy_bounds()
	var top := bounds.position.y + bounds.size.y
	var half := Vector2(bounds.size.x * 0.5, bounds.size.z * 0.5)
	var centre := bounds.get_center()
	var vertices: PackedVector3Array = \
		visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

	var found_true_edge := false
	var found_dropped_overhang := false
	for vertex: Vector3 in vertices:
		var out := Vector2(absf(vertex.x - centre.x), absf(vertex.z - centre.z))
		var outside := out.x > half.x + 0.001 or out.y > half.y + 0.001
		var on_proxy_edge := (
			absf(out.x - half.x) < 0.001 or absf(out.y - half.y) < 0.001)

		if on_proxy_edge and not outside and absf(vertex.y - top) < 0.001:
			found_true_edge = true
		if outside:
			found_dropped_overhang = true
			assert_bool(vertex.y < top - 0.01).override_failure_message(
				("cosmetic shell vertex %s sits at the walkable top %.3f; "
				+ "visible art extends beyond collision without a readable drop")
				% [str(vertex), top]).is_true()

	assert_bool(found_true_edge).override_failure_message(
		"the generated shell must expose a top-plane ring at the true collision edge"
	).is_true()
	assert_bool(found_dropped_overhang).override_failure_message(
		"the generated shell must include a dropped cosmetic rim outside collision"
	).is_true()

	_tree_root().remove_child(body)
	body.free()
