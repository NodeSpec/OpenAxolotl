extends GdUnitTestSuite

func volume() -> WaterVolume:
	var water := WaterVolume.new()
	water.explicit_surface = true
	water.shallow_wading_enabled = true
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4,8,8)
	collision.shape = shape
	collision.position.y = -4.0
	water.add_child(collision)
	return water

func test_shallows_stay_on_land_and_immersion_has_hysteresis() -> void:
	var water := volume()
	assert_bool(water.should_swim(Vector3(0,0.55,0),false)).is_false()
	assert_bool(water.should_swim(Vector3(0,0.09,0),false)).is_true()
	assert_bool(water.should_swim(Vector3(0,0.18,0),false)).is_false()
	assert_bool(water.should_swim(Vector3(0,0.18,0),true)).is_true()
	assert_bool(water.should_swim(Vector3(0,0.28,0),true)).is_false()
	water.free()

func test_existing_deep_volumes_preserve_surface_launches() -> void:
	var water := volume()
	water.shallow_wading_enabled = false
	assert_bool(water.should_swim(Vector3(0,0.55,0),false)).is_true()
	water.free()

func test_currents_are_opt_in_local_and_ramped() -> void:
	var water := volume()
	assert_bool(water.flow_at(Vector3(0,-1,0)).is_zero_approx()).is_true()
	water.current_velocity = Vector3(0,-0.3,-1.8)
	assert_bool(water.flow_at(Vector3(0,-1,5)).is_zero_approx()).is_true()
	assert_bool(water.flow_at(Vector3(3,-1,0)).is_zero_approx()).is_true()
	assert_bool(water.flow_at(Vector3(0,-1,4)).is_zero_approx()).is_true()
	assert_float(water.flow_at(Vector3(0,-1,3.8)).length()).is_less(water.flow_at(Vector3(0,-1,0)).length())
	assert_float(water.flow_at(Vector3(0,-1,0)).z).is_less(0.0)
	water.free()

func test_water_contacts_are_deduplicated_and_teleports_clear_them() -> void:
	var water := volume()
	var body := AxolotlBody.new()
	body.register_water(water)
	body.register_water(water)
	assert_bool(body.is_in_water()).is_true()
	body.unregister_water(water)
	assert_bool(body.is_in_water()).is_false()
	body.register_water(water)
	body.clear_water_contacts()
	assert_bool(body.is_in_water()).is_false()
	assert_object(body.get_water_volume()).is_null()
	body.free()
	water.free()

func test_channel_surface_overrides_the_overlapping_lagoon_surface() -> void:
	var pool := volume()
	var channel := volume()
	channel.water_priority = 10
	channel.surface_height = -1.0
	var body := AxolotlBody.new()
	body.register_water(pool)
	body.register_water(channel)
	assert_bool(body.get_water_volume() == channel).is_true()
	assert_bool(body.is_in_water()).is_false()
	body.unregister_water(channel)
	assert_bool(body.is_in_water()).is_true()
	body.clear_water_contacts()
	body.free()
	pool.free()
	channel.free()

func test_lagoon_has_deep_pockets_and_a_majority_of_shallow_water() -> void:
	var terrain := LagoonHydrology.new()
	assert_float(terrain.floor_height(Vector2(-4.3,0))).is_less(-1.8)
	assert_float(terrain.floor_height(Vector2(4.2,-1))).is_less(-1.8)
	assert_float(terrain.floor_height(Vector2(-8.3,1))).is_greater(-0.3)
	var wet: int = 0
	var shallow: int = 0
	for z: int in range(-8,7):
		for x: int in range(-11,12):
			var depth: float = LagoonHydrology.WATER_LEVEL-terrain.floor_height(Vector2(x,z))
			if depth > 0.0:
				wet += 1
				if depth < 0.65:
					shallow += 1
	assert_float(float(shallow)/wet).is_greater(0.5)
	assert_float(LagoonHydrology.channel_surface(-10.0)).is_less(LagoonHydrology.channel_surface(-6.0))
	terrain.free()

func test_depth_grade_increases_gradually_and_can_be_disabled() -> void:
	assert_float(WaterDepthLighting.depth_weight(-1.0,true)).is_equal_approx(0.0,0.0001)
	assert_float(WaterDepthLighting.depth_weight(8.0,false)).is_equal_approx(0.0,0.0001)
	assert_float(WaterDepthLighting.depth_weight(1.0,true)).is_less(WaterDepthLighting.depth_weight(6.0,true))
	assert_float(WaterDepthLighting.depth_weight(100.0,true)).is_equal_approx(1.0,0.0001)
