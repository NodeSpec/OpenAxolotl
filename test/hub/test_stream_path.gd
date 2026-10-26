extends GdUnitTestSuite

func test_channel_descends_without_a_backwards_segment() -> void:
	var previous: Vector3 = LagoonStreamPath.point(0)
	var length: float = LagoonStreamPath.curve().get_baked_length()
	for i: int in range(1,101):
		var next: Vector3 = LagoonStreamPath.point(length*float(i)/100)
		assert_bool(next.z < previous.z).is_true()
		assert_bool(next.y <= previous.y).is_true()
		assert_bool(absf(next.x) < 5.0).is_true()
		previous = next
	assert_bool(previous.is_equal_approx(Vector3(3,-6.8,-52))).is_true()

func test_stream_meets_existing_lagoon_channel_at_the_same_height() -> void:
	var entrance: Vector3 = LagoonStreamPath.point(0)
	assert_float(entrance.y).is_equal_approx(LagoonHydrology.channel_surface(entrance.z),0.001)
	assert_bool(LagoonStreamPath.curve().get_baked_length() > 43).is_true()

func test_cave_darkness_has_gradual_entrance_and_exit() -> void:
	assert_float(LagoonStreamPath.enclosure(-9)).is_equal_approx(0.0,0.001)
	assert_bool(LagoonStreamPath.enclosure(-12) < LagoonStreamPath.enclosure(-16)).is_true()
	assert_bool(LagoonStreamPath.enclosure(-30) > 0.99).is_true()
	assert_bool(LagoonStreamPath.enclosure(-48) < LagoonStreamPath.enclosure(-44)).is_true()
	assert_float(LagoonStreamPath.enclosure(-54)).is_equal_approx(0.0,0.001)

func test_lagoon_floor_is_excavated_below_the_passage() -> void:
	var ground := LagoonHydrology.new()
	ground.continuous_stream = true
	for z: float in [-12.0,-16.0,-20.0,-23.0]:
		var center: Vector3 = LagoonStreamPath.at_z(z)
		assert_bool(ground.floor_height(Vector2(center.x,z)) < center.y-2.2).is_true()
	ground.free()

func test_flat_water_retains_its_original_slope_and_no_cave_darkening() -> void:
	var water := WaterVolume.new()
	water.surface_gradient = Vector2(0,0.19)
	assert_bool(water.surface_slope_at(Vector3.ZERO).is_equal_approx(Vector2(0,0.19))).is_true()
	assert_float(water.enclosure_at(Vector3.ZERO)).is_equal_approx(0.0,0.001)
	water.free()

func test_cave_shade_contains_air_above_the_stream_but_not_outside_walls() -> void:
	var stream := LagoonStream.new()
	var center: Vector3 = LagoonStreamPath.at_z(-27)
	assert_bool(stream.enclosure_at(center+Vector3.UP*2.0) > 0.99).is_true()
	assert_float(stream.enclosure_at(center+Vector3.UP*5.0)).is_equal_approx(0.0,0.001)
	assert_float(stream.enclosure_at(center+Vector3.RIGHT*5.0)).is_equal_approx(0.0,0.001)
	stream.free()
