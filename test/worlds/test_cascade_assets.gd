extends GdUnitTestSuite
const WORLD := "res://worlds/coral_cove/world.tscn"

func test_all_nine_assets_are_full_proportioned_models_in_every_section() -> void:
	var world := load(WORLD).instantiate() as Node3D
	var assets: Dictionary = {}
	var sections: Dictionary = {}
	for n: Node3D in world.get_node("SuppliedAssets").get_children():
		if not n.has_meta("source_asset"):
			continue
		assets[String(n.get_meta("source_asset"))]=true
		sections[String(n.get_meta("section"))]=true
		assert_bool(bool(n.get_meta("full_3d_asset",false))).is_true()
		var found := false
		for child: Node in n.get_children():
			if child.has_meta("cascade_asset_instance"):
				found=true
				assert_bool(child.scene_file_path.ends_with(".glb")).is_true()
				var scale := (child as Node3D).scale
				assert_float(scale.x).is_equal_approx(scale.y,0.0001)
				assert_float(scale.x).is_equal_approx(scale.z,0.0001)
		assert_bool(found).override_failure_message(String(n.name)+" lost its linked GLB").is_true()
		assert_object(n.get_node_or_null("AssetCollision")).is_not_null()
	assert_int(assets.size()).is_equal(9)
	for section: String in ["S01","S02","S03","S04","S05","S06"]:
		assert_bool(sections.has(section)).is_true()
	world.free()

func test_landing_collision_comes_from_the_stone_not_the_old_box() -> void:
	var world := load(WORLD).instantiate() as Node3D
	for pair: Array in [["S02","Garden","P21"],["S02","Garden","P22"],["S02","Garden","P23"],["S02","Garden","P24"],["S02","Garden","O1"],["S04","Terraces","A1"],["S04","Terraces","A2"],["S04","Terraces","C1"],["S04","Terraces","C2"],["S04","Terraces","C3"]]:
		var path := "Sections/%s/%s/%s" % pair
		var old := world.get_node(path) as StaticBody3D
		assert_bool((old.get_node("Collision") as CollisionShape3D).disabled).is_true()
		assert_object(old.get_node_or_null("Mesh")).is_null()
		assert_object(old.get_node_or_null("TerrainSkin")).is_null()
		var body := world.get_node("SuppliedAssets/%s_%s/AssetCollision" % [pair[0],pair[2]]) as StaticBody3D
		assert_int(body.get_child_count()).is_greater(0)
		assert_bool((body.get_child(0) as CollisionShape3D).shape is ConvexPolygonShape3D).is_true()
	var climb := world.get_node("Sections/S04/Terraces/BClimb") as StaticBody3D
	assert_bool(climb.is_in_group("climbable")).is_true()
	assert_bool(ClimbSurface.layer_is_climbable(climb.collision_layer)).is_true()
	world.free()

func test_relief_panels_and_solid_prototype_roofs_are_retired() -> void:
	var scene := FileAccess.get_file_as_string(WORLD)
	assert_bool(scene.contains("facade_color") or scene.contains("facade_depth") or scene.contains("cascade_terrain.gdshader")).is_false()
	var world := load(WORLD).instantiate() as Node3D
	for path: String in ["Sections/S03/RootDive/RootRoof","Sections/S03/RootDive/SecretRoof","Sections/S04/Terraces/DiveBrow","Sections/S06/Chute/DiveBar"]:
		assert_bool((world.get_node(path+"/Collision") as CollisionShape3D).disabled).is_true()
	for path: String in ["S03_EntryTunnel","S03_MiddleTunnel","S03_ExitTunnel","S03_GrottoArch","S04_DiveArch","S06_DiveTunnel"]:
		var body := world.get_node("SuppliedAssets/"+path+"/AssetCollision") as StaticBody3D
		assert_bool((body.get_child(0) as CollisionShape3D).shape is ConvexPolygonShape3D).is_true()
	world.free()

func test_custom_terrain_has_collision_and_persistent_planted_sections() -> void:
	var world := load(WORLD).instantiate() as Node3D
	var sections: Dictionary = {}
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if not body.has_meta("custom_terrain"): continue
		sections[String(body.get_meta("terrain_section"))]=true
		assert_bool((body.get_node("SculptedTerrain") as MeshInstance3D).mesh is ArrayMesh).is_true()
		var collider := body.get_node("Collision") as CollisionShape3D
		assert_bool(collider.shape is ConcavePolygonShape3D).is_true()
		assert_bool(collider.disabled).is_false()
	for section: String in ["S01","S02","S03","S04","S05","S06"]:
		assert_bool(sections.has(section)).is_true()
		var grass := world.get_node("CustomLandscape/"+section+"_Meadow") as ScatterField
		assert_int(grass.instance_count()).is_greater(0)
		assert_object(grass.get_source_mesh()).is_not_null()
		assert_int(grass.transforms.size()).is_greater(12)
	# Prevent another blanket of the distinctive assembled rock-and-plant models.
	var placements := 0
	for n: Node in world.get_node("SuppliedAssets").get_children():
		if n.has_meta("source_asset"): placements+=1
	assert_int(placements).is_less(90)
	world.free()

func test_polished_sections_have_real_mipmapped_surface_maps() -> void:
	var world := load(WORLD).instantiate() as Node3D
	var sections: Dictionary = {}
	var textures: Dictionary = {}
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if not body.has_meta("custom_terrain"): continue
		var mat := (body.get_node("SculptedTerrain") as MeshInstance3D).material_override as ShaderMaterial
		assert_bool(mat.shader.resource_path.ends_with("cascade_pbr_ground.gdshader")).is_true()
		sections[String(body.get_meta("terrain_section"))]=true
		for channel: String in ["rock_color","rock_normal","sand_color","sand_normal","turf_color","turf_normal","gravel_color","gravel_normal"]:
			var texture := mat.get_shader_parameter(channel) as Texture2D
			assert_object(texture).is_not_null()
			if texture==null or textures.has(texture): continue
			textures[texture]=true
			assert_int(texture.get_width()).is_equal(2048)
			assert_bool(texture.get_image().has_mipmaps()).override_failure_message(texture.resource_path+" needs mipmaps for stable distant detail").is_true()
	for section: String in ["S01","S02","S03","S04","S05","S06"]:
		assert_bool(sections.has(section)).is_true()
	world.free()

func test_ordinary_cascade_falls_have_no_life_costing_pit() -> void:
	var world := load(WORLD).instantiate() as Node3D
	for area: Area3D in world.find_children("*","Area3D",true,false):
		assert_bool(area.is_in_group("pit_volume")).override_failure_message("The future whirlpool is not built; ordinary shores must not cost a life").is_false()
	var recovery := world.get_node("SafetyRecovery") as Area3D
	assert_bool(recovery.is_in_group("safe_return_volume")).is_true()
	var box := (recovery.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_float(recovery.position.y+box.size.y*0.5).is_less(-3.3)
	assert_float(box.size.x).override_failure_message("Cascade recovery must not reach across the connected lagoon").is_less(150.0)
	assert_float(box.size.z).is_less(200.0)
	world.free()
