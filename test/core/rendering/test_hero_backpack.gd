extends GdUnitTestSuite
const ATTACHMENT := preload("res://core/rendering/hero_backpack.gd")

func _free_preview(model: Node3D) -> void:
	# Retain overrides while an off-tree preview releases its mesh. Godot's
	# dummy renderer otherwise inspects already-released material RIDs on free.
	var materials: Array[Material] = []
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		var visual := node as MeshInstance3D
		for surface: int in visual.mesh.get_surface_count():
			materials.append(visual.get_active_material(surface))
	model.free()

func test_equipment_reuses_the_hero_rig_without_changing_collision() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	body.initialise()
	var model := body.get_node("Model") as Node3D
	var gear := model.get_node("ExplorerGear") as Node3D
	assert_bool(ATTACHMENT.attach(model) == gear).is_true()
	assert_int(model.find_children("*", "Skeleton3D", true, false).size()).is_equal(1)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	assert_int(skeleton.get_bone_count()).is_equal(12)
	assert_int(body.find_children("*", "CollisionShape3D", true, false).size()).is_equal(1)
	var capsule := (body.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	assert_float(capsule.radius).is_equal_approx(0.5,0.0001)
	assert_float(capsule.height).is_equal_approx(1.6,0.0001)
	var visual := gear.get_child(0) as MeshInstance3D
	assert_bool(visual.get_node(visual.skeleton) == skeleton).is_true()
	for bind: int in visual.skin.get_bind_count():
		var bone := skeleton.find_bone(visual.skin.get_bind_name(bind))
		assert_bool(bone >= 0).is_true()
		var rest := skeleton.get_bone_global_rest(bone)*visual.skin.get_bind_pose(bind)
		assert_float(rest.origin.length()).is_less(0.0001)
		assert_float(rest.basis.x.distance_to(Vector3.RIGHT)).is_less(0.0001)
		assert_float(rest.basis.y.distance_to(Vector3.UP)).is_less(0.0001)
		assert_float(rest.basis.z.distance_to(Vector3.BACK)).is_less(0.0001)
	body.free()

func test_backpack_has_normalized_skin_weights_and_detail_maps() -> void:
	var model := load("res://assets/character/axolotl/axolotl.glb").instantiate() as Node3D
	var gear := ATTACHMENT.attach(model)
	var visual := gear.get_child(0) as MeshInstance3D
	var vertices := 0
	var blended := 0
	var textured_surfaces := 0
	var triangles := 0
	for surface: int in visual.mesh.get_surface_count():
		var a := visual.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		triangles += indices.size()/3
		var influences := weights.size()/points.size()
		for vertex: int in points.size():
			var total := 0.0
			var used := 0
			for slot: int in influences:
				var weight := weights[vertex*influences+slot]
				total += weight
				if weight > 0.001: used += 1
			assert_float(total).is_equal_approx(1.0,0.001)
			if used > 1: blended += 1
		vertices += points.size()
		var mat := visual.get_active_material(surface) as BaseMaterial3D
		if mat.albedo_texture != null:
			textured_surfaces += 1
			assert_bool(mat.normal_enabled).is_true()
			assert_object(mat.normal_texture).is_not_null()
			assert_int(mat.albedo_texture.get_width()).is_equal(1024)
	assert_int(vertices).is_greater(0)
	assert_int(blended).is_greater(100)
	assert_int(textured_surfaces).is_equal(2)
	assert_bool(triangles < 20000).is_true()
	_free_preview(model)

func test_missing_rig_is_supported_and_materials_are_per_character() -> void:
	var bare := Node3D.new()
	assert_bool(ATTACHMENT.attach(bare) == null).is_true()
	bare.free()
	var first := load("res://assets/character/axolotl/axolotl.glb").instantiate() as Node3D
	var second := load("res://assets/character/axolotl/axolotl.glb").instantiate() as Node3D
	var a := ATTACHMENT.attach(first).get_child(0) as MeshInstance3D
	var b := ATTACHMENT.attach(second).get_child(0) as MeshInstance3D
	assert_bool(a.get_active_material(0) != b.get_active_material(0)).is_true()
	_free_preview(first)
	_free_preview(second)
