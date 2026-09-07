extends GdUnitTestSuite

## Movement is relative to where the camera looks (REQ-005, REQ-024).
##
## THE OTHER HALF OF A LOOK AXIS. Shipping a turnable camera while W still
## meant world -Z would be worse than shipping neither: after any turn the
## player would have to work out which key now goes where they are pointing.
## These assert that "push the stick where you want to go" is actually true —
## and that a scene with no camera keeps the world-relative behaviour every
## headless probe and unit test was written against.

const BODY := "res://core/controller/axolotl_body.tscn"


func _body() -> AxolotlBody:
	var body := (load(BODY) as PackedScene).instantiate() as AxolotlBody
	(Engine.get_main_loop() as SceneTree).root.add_child(body)
	return body


func _release(body: AxolotlBody) -> void:
	(Engine.get_main_loop() as SceneTree).root.remove_child(body)
	body.free()


## A stand-in for the camera: the body only ever asks it for a yaw.
class _Camera extends CameraFollow:
	var yaw := 0.0

	func get_yaw_deg() -> float:
		return yaw


func test_req_005_forward_follows_the_camera_not_the_world() -> void:
	var body := _body()
	var camera := _Camera.new()
	body.set_camera(camera)

	# Forward in screen space is -Z, which with a camera facing along world -Z
	# is also world forward.
	var forward := Vector3(0.0, 0.0, -1.0)
	var straight := body._camera_relative(forward)
	assert_float(straight.z).is_equal_approx(-1.0, 0.001)
	assert_float(straight.x).is_equal_approx(0.0, 0.001)

	# Turn the camera a quarter turn and the SAME key must now drive the body
	# along world -X. This is the whole point: the key did not change meaning,
	# the world did.
	camera.yaw = 90.0
	var turned := body._camera_relative(forward)
	assert_float(turned.x).override_failure_message(
		"with the camera turned 90 degrees, forward must be world -X; got %s"
		% str(turned)).is_equal_approx(-1.0, 0.001)
	assert_float(turned.z).is_equal_approx(0.0, 0.001)

	_release(body)


func test_req_005_a_body_with_no_camera_stays_world_relative() -> void:
	# Every headless probe and unit test in the repo was written against
	# world-space directions. A body with no camera bound must behave exactly
	# as it always did, so the look axis cannot silently change what they mean.
	var body := _body()
	for direction: Vector3 in [Vector3(0.0, 0.0, -1.0), Vector3(1.0, 0.0, 0.0),
			Vector3(0.7, 0.0, -0.7), Vector3.ZERO]:
		assert_bool(body._camera_relative(direction).is_equal_approx(direction)
			).override_failure_message(
			"with no camera bound, %s must pass through unchanged"
			% str(direction)).is_true()
	_release(body)


func test_req_005_the_vertical_axis_is_never_rotated() -> void:
	# In the water grammar the vertical component comes from SPACE and SHIFT,
	# which mean UP AND DOWN IN THE WORLD — not relative to wherever the camera
	# happens to be pitched. A swimmer pressing "up" while looking at the floor
	# wants to rise, not to swim into it.
	var body := _body()
	var camera := _Camera.new()
	camera.yaw = 137.0
	body.set_camera(camera)

	var rising := body._camera_relative(Vector3(0.0, 1.0, -1.0))
	assert_float(rising.y).override_failure_message(
		"the vertical component must survive the rotation untouched"
	).is_equal_approx(1.0, 0.001)

	# A purely vertical direction has no horizontal part to rotate, so it must
	# come back exactly as it went in rather than being normalised or zeroed.
	var straight_up := body._camera_relative(Vector3(0.0, 1.0, 0.0))
	assert_bool(straight_up.is_equal_approx(Vector3(0.0, 1.0, 0.0))).is_true()

	_release(body)


func test_req_005_rotation_preserves_the_magnitude_of_a_steer() -> void:
	# A rotation must not change how HARD the player is pushing: the speed the
	# controller derives from this vector has to be the same in every
	# direction, or the character would be faster along some compass bearings.
	var body := _body()
	var camera := _Camera.new()
	body.set_camera(camera)

	var pushed := Vector3(0.6, 0.0, -0.8)
	for yaw: float in [0.0, 45.0, 90.0, 180.0, -137.0]:
		camera.yaw = yaw
		assert_float(body._camera_relative(pushed).length()
			).override_failure_message(
			"steer magnitude changed at yaw %.0f" % yaw).is_equal_approx(
			pushed.length(), 0.001)

	_release(body)
