extends GdUnitTestSuite

## Camera System — REQ-005.
##
## Test names carry the requirement id they prove (test_req_005_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"
const FRAME := 1.0 / 60.0

## Every tuning key the rig reads, with its permitted range, so AC-4 can be
## proven by loading the SAME code against DIFFERENT data.
const CAMERA_KEYS: Dictionary = {
	"camera.smoothing.max_position_delta_m_per_frame": [0.35, 0.01, 5.0],
	"camera.smoothing.max_rotation_delta_deg_per_frame": [4.0, 0.1, 45.0],
	"camera.smoothing.position_damping_per_second": [6.0, 0.1, 60.0],
	"camera.smoothing.rotation_damping_per_second": [8.0, 0.1, 60.0],
	"camera.follow.water_distance_m": [4.5, 0.5, 30.0],
	"camera.follow.land_distance_m": [3.0, 0.5, 30.0],
	"camera.follow.water_pitch_deg": [10.0, -80.0, 80.0],
	"camera.follow.land_pitch_deg": [20.0, -80.0, 80.0],
	"camera.follow.min_distance_m": [0.8, 0.1, 10.0],
	"camera.collision.margin_m": [0.25, 0.05, 2.0],
}

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("camera")


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _rig() -> CameraRig:
	return CameraRig.new(_tuning())


## A tuning surface holding only the camera keys, so a single value can be varied
## without touching the shipped file.
func _fixture_tuning(overrides: Dictionary = {}) -> TuningData:
	var values := {}
	for key: Variant in CAMERA_KEYS:
		var spec := CAMERA_KEYS[key] as Array
		var value := float(overrides[key]) if overrides.has(key) else float(spec[0])
		values[String(key)] = {
			"value": value,
			"unit": "fixture",
			"min": float(spec[1]),
			"max": float(spec[2]),
			"description": "fixture value for %s" % key,
		}

	var path := _temp_dir.path_join("camera_%d.json" % Time.get_ticks_usec())
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(JSON.stringify({
		"schemaVersion": "1.0", "worldOverridable": [], "values": values,
	}))
	handle.close()

	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(path, errors)
	assert_array(errors).is_empty()
	return data


## Stands in for level geometry so AC-2 can be asserted without a physics server.
class FakeOccluderProbe extends CameraOccluderProbe:
	var fraction: float = 1.0
	var calls: int = 0

	func clear_fraction(_from: Vector3, _to: Vector3) -> float:
		calls += 1
		return fraction


func _probe(fraction: float = 1.0) -> FakeOccluderProbe:
	var probe := FakeOccluderProbe.new()
	probe.fraction = fraction
	return probe


# --- AC-1: follows in both grammars ----------------------------------------

func test_req_005_camera_settles_behind_the_axolotl_on_the_first_frame() -> void:
	# No previous transform means nothing to be smooth relative to; clamping the
	# first frame would open every scene with the camera flying in from origin.
	var rig := _rig()
	rig.update(FRAME, Vector3(10.0, 2.0, -4.0), 0.0)

	assert_bool(rig.is_settled()).is_true()
	assert_float(rig.get_last_position_delta()).is_equal_approx(0.0, 0.0001)
	assert_float(rig.get_position().distance_to(Vector3(10.0, 2.0, -4.0))
	).is_equal_approx(rig.get_distance(), 0.0001)


func test_req_005_camera_follows_a_moving_axolotl_in_the_land_grammar() -> void:
	var rig := _rig()
	rig.set_in_water(false)
	rig.update(FRAME, Vector3.ZERO, 0.0)

	var target := Vector3.ZERO
	for _frame: int in range(240):
		target += Vector3(0.01, 0.0, 0.0)
		rig.update(FRAME, target, 0.0)

	# It trails, but it keeps station: still the tuned distance from the axolotl.
	assert_float(rig.get_position().distance_to(target)).override_failure_message(
		"REQ-005 AC-1: the camera must keep station on a moving axolotl"
	).is_equal_approx(rig.get_distance(), 0.05)


func test_req_005_camera_follows_the_axolotl_in_the_water_grammar() -> void:
	var rig := _rig()
	rig.set_in_water(true)
	rig.update(FRAME, Vector3.ZERO, 0.0)

	var target := Vector3.ZERO
	for _frame: int in range(240):
		target += Vector3(0.0, 0.01, 0.008)  # a full-3D underwater climb
		rig.update(FRAME, target, 0.0)

	assert_float(rig.get_position().distance_to(target)).is_equal_approx(
		rig.get_distance(), 0.05)


func test_req_005_the_two_grammars_frame_the_axolotl_differently() -> void:
	# If both grammars framed identically the transition would be a no-op and
	# AC-1's delta bound would be vacuously satisfied.
	var tuning := _tuning()
	assert_bool(tuning.get_number("camera.follow.water_distance_m")
		!= tuning.get_number("camera.follow.land_distance_m")
	).override_failure_message(
		"REQ-005 AC-1: water and land must frame differently, or the transition "
		+ "the criterion measures does not exist"
	).is_true()


# --- AC-1: the per-frame bound, which is the measured case -----------------

func test_req_005_grammar_transition_never_exceeds_the_tuned_per_frame_deltas() -> void:
	var tuning := _tuning()
	var max_position := tuning.get_number("camera.smoothing.max_position_delta_m_per_frame")
	var max_rotation := tuning.get_number("camera.smoothing.max_rotation_delta_deg_per_frame")
	var rig := CameraRig.new(tuning)

	var target := Vector3(3.0, 1.0, 2.0)
	rig.set_in_water(true)
	rig.update(FRAME, target, 0.0)

	# The controller switches grammar within one physics frame. The camera must
	# not: it interpolates toward the new framing over several.
	rig.set_in_water(false)
	for frame: int in range(180):
		rig.update(FRAME, target, 0.0)
		assert_float(rig.get_last_position_delta()).override_failure_message(
			"REQ-005 AC-1: frame %d moved the camera %f m, over the tuned %f"
			% [frame, rig.get_last_position_delta(), max_position]
		).is_less_equal(max_position + 0.000001)
		assert_float(rig.get_last_rotation_delta_deg()).override_failure_message(
			"REQ-005 AC-1: frame %d turned the camera %f deg, over the tuned %f"
			% [frame, rig.get_last_rotation_delta_deg(), max_rotation]
		).is_less_equal(max_rotation + 0.000001)

	# ...and it actually arrives, rather than satisfying the bound by not moving.
	assert_float(rig.get_distance()).override_failure_message(
		"the camera must reach the land framing, not merely stay under the bound"
	).is_equal_approx(tuning.get_number("camera.follow.land_distance_m"), 0.01)
	assert_float(rig.get_pitch_deg()).is_equal_approx(
		tuning.get_number("camera.follow.land_pitch_deg"), 0.01)


func test_req_005_a_teleport_cannot_break_the_per_frame_position_bound() -> void:
	# The bound is structural, not incidental: no input, however violent, gets
	# the camera to move further in one frame than the tuned metres.
	var rig := _rig()
	rig.update(FRAME, Vector3.ZERO, 0.0)

	rig.update(FRAME, Vector3(1000.0, -500.0, 750.0), 0.0)

	assert_float(rig.get_last_position_delta()).override_failure_message(
		"REQ-005 AC-1: a 1km teleport must still respect the per-frame clamp"
	).is_less_equal(rig.max_position_delta() + 0.000001)


func test_req_005_a_full_reversal_cannot_break_the_per_frame_rotation_bound() -> void:
	var rig := _rig()
	rig.update(FRAME, Vector3.ZERO, 0.0)

	for _frame: int in range(120):
		rig.update(FRAME, Vector3.ZERO, 180.0)
		assert_float(rig.get_last_rotation_delta_deg()).is_less_equal(
			rig.max_rotation_delta_deg() + 0.000001)


func test_req_005_yaw_turns_the_short_way_across_the_wrap() -> void:
	# 179 to -179 is a two-degree turn. Taken the long way it is 358 degrees,
	# which the clamp would happily pay out over ninety frames while the player
	# watches the world spin. The clamp alone cannot catch this; convergence can.
	var rig := _rig()
	rig.update(FRAME, Vector3.ZERO, 179.0)
	assert_float(rig.get_yaw_deg()).is_equal_approx(179.0, 0.0001)

	for _frame: int in range(20):
		rig.update(FRAME, Vector3.ZERO, -179.0)
		assert_float(rig.get_last_rotation_delta_deg()).is_less_equal(
			rig.max_rotation_delta_deg() + 0.000001)

	assert_float(rig.get_yaw_deg()).override_failure_message(
		"REQ-005 AC-1: yaw must take the shortest path across the 180 boundary"
	).is_equal_approx(-179.0, 0.5)


func test_req_005_a_resettle_request_re_frames_at_the_current_target() -> void:
	# Spawn, checkpoint respawn and world transition are not smoothing cases.
	var rig := _rig()
	rig.update(FRAME, Vector3.ZERO, 0.0)

	rig.request_resettle()
	assert_bool(rig.is_settled()).is_false()

	var elsewhere := Vector3(200.0, 0.0, 0.0)
	rig.update(FRAME, elsewhere, 0.0)

	assert_float(rig.get_position().distance_to(elsewhere)).is_equal_approx(
		rig.get_distance(), 0.0001)


# --- AC-2: collision avoidance ---------------------------------------------

func test_req_005_camera_stops_short_of_geometry_rather_than_clipping_it() -> void:
	var rig := _rig()
	rig.set_in_water(false)
	rig.set_occluder_probe(_probe(0.5))

	var target := Vector3.ZERO
	rig.update(FRAME, target, 0.0)

	var full := rig.get_distance()
	var contact := full * 0.5
	var actual := rig.get_position().distance_to(target)

	assert_float(actual).override_failure_message(
		"REQ-005 AC-2: the camera resolved at %f m with geometry at %f m"
		% [actual, contact]
	).is_less(contact)
	assert_float(actual).is_equal_approx(contact - rig.collision_margin(), 0.0001)


func test_req_005_the_pull_in_is_immediate_not_eased_into_the_wall() -> void:
	# Easing gently into a wall over five frames IS the clipping AC-2 forbids,
	# so the pull deliberately bypasses the per-frame clamp. Asserted, not
	# assumed, because it is the one place the camera may exceed that bound.
	var rig := _rig()
	rig.set_in_water(false)
	var probe := _probe(1.0)
	rig.set_occluder_probe(probe)
	rig.update(FRAME, Vector3.ZERO, 0.0)
	var before := rig.get_position().distance_to(Vector3.ZERO)

	probe.fraction = 0.4  # a wall appears
	rig.update(FRAME, Vector3.ZERO, 0.0)

	var after := rig.get_position().distance_to(Vector3.ZERO)
	assert_float(after).is_less(before)
	assert_float(rig.get_last_position_delta()).override_failure_message(
		"REQ-005 AC-2: the camera must pull in on the frame it finds geometry"
	).is_greater(rig.max_position_delta())


func test_req_005_returning_to_full_distance_is_damped_and_clamped() -> void:
	# Snaps in, eases out. The reverse would be a lurch every time the player
	# clears a doorway.
	var rig := _rig()
	rig.set_in_water(false)
	var probe := _probe(0.4)
	rig.set_occluder_probe(probe)
	rig.update(FRAME, Vector3.ZERO, 0.0)

	probe.fraction = 1.0  # the wall is behind us now
	for _frame: int in range(120):
		rig.update(FRAME, Vector3.ZERO, 0.0)
		assert_float(rig.get_last_position_delta()).override_failure_message(
			"REQ-005: easing back out must respect the per-frame clamp"
		).is_less_equal(rig.max_position_delta() + 0.000001)

	assert_float(rig.get_position().distance_to(Vector3.ZERO)).is_equal_approx(
		rig.get_distance(), 0.01)


func test_req_005_collision_pull_in_is_floored_at_the_minimum_distance() -> void:
	# Jammed into a corner, the floor wins: closer than this the camera would be
	# inside the axolotl, which is a worse failure than a clipped near plane.
	var rig := _rig()
	rig.set_in_water(false)
	rig.set_occluder_probe(_probe(0.01))
	rig.update(FRAME, Vector3.ZERO, 0.0)

	assert_float(rig.get_position().distance_to(Vector3.ZERO)).is_equal_approx(
		rig.min_distance(), 0.0001)


func test_req_005_a_rig_with_no_probe_performs_no_avoidance() -> void:
	# Documented degenerate: absent a probe the camera does not guess. Unlike the
	# grapple's anchor source, "grant nothing" would be the wrong default here —
	# it would slam the camera into the axolotl's face.
	var rig := _rig()
	rig.set_in_water(false)
	assert_object(rig.get_occluder_probe()).is_null()

	rig.update(FRAME, Vector3.ZERO, 0.0)

	assert_float(rig.get_position().distance_to(Vector3.ZERO)).is_equal_approx(
		rig.get_distance(), 0.0001)


func test_req_005_collision_margin_cannot_be_tuned_away() -> void:
	# "Never clipping" is only true if the margin cannot be zeroed: on the
	# surface exactly, the near plane makes clipping a floating-point coin flip.
	var bounds := _tuning().get_permitted_range("camera.collision.margin_m")
	assert_int(bounds.size()).is_equal(2)
	assert_bool(bounds[0] > 0.0).override_failure_message(
		"REQ-005 AC-2: the tuned collision margin minimum must be above zero"
	).is_true()


func test_req_005_the_camera_probes_from_the_axolotl_outward() -> void:
	# Direction matters: probing from the camera toward the player would find the
	# far side of a wall the camera is already inside and report it clear.
	var rig := _rig()
	var probe := _probe(1.0)
	rig.set_occluder_probe(probe)
	rig.update(FRAME, Vector3(5.0, 0.0, 0.0), 0.0)

	assert_int(probe.calls).is_greater(0)


# --- AC-3: declarative hint volumes ----------------------------------------

func test_req_005_a_hint_overrides_only_the_fields_it_declares() -> void:
	var base := CameraFraming.new(3.0, 20.0, 45.0, 0)
	var hint := CameraHint.new("tunnel", 0).set_distance(1.5)

	var stack := CameraHintStack.new()
	stack.add(hint)
	var resolved := stack.resolve(base)

	assert_float(resolved.distance).is_equal_approx(1.5, 0.0001)
	assert_float(resolved.pitch_deg).override_failure_message(
		"REQ-005 AC-3: a distance-only hint must not clobber the pitch"
	).is_equal_approx(20.0, 0.0001)
	assert_float(resolved.yaw_deg).is_equal_approx(45.0, 0.0001)
	# ...and the base is untouched, so one frame's hint cannot leak into the next.
	assert_float(base.distance).is_equal_approx(3.0, 0.0001)


func test_req_005_the_highest_priority_hint_wins() -> void:
	var stack := CameraHintStack.new()
	stack.add(CameraHint.new("wide", 1).set_distance(8.0))
	stack.add(CameraHint.new("tunnel", 5).set_distance(1.5))

	var resolved := stack.resolve(CameraFraming.new(3.0, 20.0, 0.0, 0))
	assert_float(resolved.distance).is_equal_approx(1.5, 0.0001)


func test_req_005_hint_resolution_does_not_depend_on_enter_order() -> void:
	# The criterion this test exists for: a world whose framing depended on which
	# way the player walked in would be unauthorable and untestable.
	var base := CameraFraming.new(3.0, 20.0, 0.0, 0)

	var forwards := CameraHintStack.new()
	forwards.add(CameraHint.new("wide", 1).set_distance(8.0))
	forwards.add(CameraHint.new("tunnel", 5).set_distance(1.5))

	var backwards := CameraHintStack.new()
	backwards.add(CameraHint.new("tunnel", 5).set_distance(1.5))
	backwards.add(CameraHint.new("wide", 1).set_distance(8.0))

	assert_float(forwards.resolve(base).distance).override_failure_message(
		"REQ-005 AC-3: overlapping hints must resolve by declared priority, "
		+ "never by enter order"
	).is_equal_approx(backwards.resolve(base).distance, 0.0001)


func test_req_005_equal_priorities_still_resolve_deterministically() -> void:
	# A world that forgets to give two volumes distinct priorities gets one
	# answer, not a coin flip.
	var base := CameraFraming.new(3.0, 20.0, 0.0, 0)

	var first := CameraHintStack.new()
	first.add(CameraHint.new("alpha", 2).set_distance(4.0))
	first.add(CameraHint.new("beta", 2).set_distance(6.0))

	var second := CameraHintStack.new()
	second.add(CameraHint.new("beta", 2).set_distance(6.0))
	second.add(CameraHint.new("alpha", 2).set_distance(4.0))

	assert_float(first.resolve(base).distance).is_equal_approx(
		second.resolve(base).distance, 0.0001)


func test_req_005_leaving_a_volume_restores_the_framing_underneath() -> void:
	var base := CameraFraming.new(3.0, 20.0, 0.0, 0)
	var stack := CameraHintStack.new()
	stack.add(CameraHint.new("wide", 1).set_distance(8.0))
	stack.add(CameraHint.new("tunnel", 5).set_distance(1.5))

	assert_bool(stack.remove("tunnel")).is_true()

	assert_float(stack.resolve(base).distance).is_equal_approx(8.0, 0.0001)
	assert_array(stack.get_hint_ids()).contains(["wide"])


func test_req_005_re_entering_a_volume_does_not_stack_duplicates() -> void:
	var stack := CameraHintStack.new()
	stack.add(CameraHint.new("tunnel", 5).set_distance(1.5))
	stack.add(CameraHint.new("tunnel", 5).set_distance(2.0))

	assert_int(stack.size()).is_equal(1)
	assert_float(stack.resolve(CameraFraming.new(3.0, 0.0, 0.0, 0)).distance
	).is_equal_approx(2.0, 0.0001)


func test_req_005_an_unnameable_hint_is_refused() -> void:
	# A hint with no id could never be removed again when the player leaves.
	var stack := CameraHintStack.new()
	assert_bool(stack.add(CameraHint.new("", 0).set_distance(1.0))).is_false()
	assert_int(stack.size()).is_equal(0)


func test_req_005_a_locked_axis_holds_rather_than_snapping() -> void:
	var rig := _rig()
	rig.set_in_water(false)
	rig.update(FRAME, Vector3.ZERO, 0.0)
	var held := rig.get_yaw_deg()

	rig.add_hint(CameraHint.new("tunnel", 1).set_locked_axes(
		int(CameraFraming.Axis.YAW)))

	# The player swings the stick hard; the lock holds the camera where it was.
	for _frame: int in range(60):
		rig.update(FRAME, Vector3.ZERO, 90.0)

	assert_float(rig.get_yaw_deg()).override_failure_message(
		"REQ-005 AC-3: a locked axis holds its current value; it must neither "
		+ "track the target nor teleport to some declared one"
	).is_equal_approx(held, 0.0001)


func test_req_005_a_lock_releases_when_the_player_leaves_the_volume() -> void:
	var rig := _rig()
	rig.set_in_water(false)
	rig.update(FRAME, Vector3.ZERO, 0.0)
	rig.add_hint(CameraHint.new("tunnel", 1).set_locked_axes(
		int(CameraFraming.Axis.YAW)))
	for _frame: int in range(30):
		rig.update(FRAME, Vector3.ZERO, 90.0)

	assert_bool(rig.remove_hint("tunnel")).is_true()
	for _frame: int in range(120):
		rig.update(FRAME, Vector3.ZERO, 90.0)

	assert_float(rig.get_yaw_deg()).is_equal_approx(90.0, 0.5)


func test_req_005_a_hint_volume_declares_only_the_boxes_a_world_ticked() -> void:
	var volume := CameraHintVolume.new()
	volume.name = "TunnelCam"
	volume.hint_priority = 7
	volume.override_distance = true
	volume.distance_m = 1.25
	volume.lock_yaw = true

	var hint := volume.to_hint()

	# A hint with an empty id is silently refused by the stack, so an id that
	# only resolves once the node is in the tree would produce a volume that
	# never applies and never complains.
	assert_str(hint.id).override_failure_message(
		"a hint volume must always yield a usable id"
	).is_not_empty()
	assert_int(hint.priority).is_equal(7)
	assert_bool(hint.overrides(CameraHint.FIELD_DISTANCE)).is_true()
	assert_bool(hint.overrides(CameraHint.FIELD_PITCH)).override_failure_message(
		"REQ-005 AC-3: an unticked field must not be declared as an override"
	).is_false()
	assert_bool(hint.overrides(CameraHint.FIELD_YAW)).is_false()

	var framing := CameraFraming.new(3.0, 20.0, 45.0, 0)
	hint.apply_to(framing)
	assert_float(framing.distance).is_equal_approx(1.25, 0.0001)
	assert_float(framing.pitch_deg).is_equal_approx(20.0, 0.0001)
	assert_bool(framing.is_locked(CameraFraming.Axis.YAW)).is_true()
	assert_bool(framing.is_locked(CameraFraming.Axis.PITCH)).is_false()

	volume.free()


# --- AC-4: behavior is driven by configuration, not constants --------------

func test_req_005_changing_a_configured_value_changes_framing_with_no_code_change() -> void:
	# Same class, same call, different data file.
	var near := CameraRig.new(_fixture_tuning({"camera.follow.land_distance_m": 3.0}))
	near.set_in_water(false)
	near.update(FRAME, Vector3.ZERO, 0.0)

	var far := CameraRig.new(_fixture_tuning({"camera.follow.land_distance_m": 12.0}))
	far.set_in_water(false)
	far.update(FRAME, Vector3.ZERO, 0.0)

	assert_float(near.get_position().distance_to(Vector3.ZERO)).is_equal_approx(
		3.0, 0.0001)
	assert_float(far.get_position().distance_to(Vector3.ZERO)).override_failure_message(
		"REQ-005 AC-4: framing must follow the configured value, not a constant"
	).is_equal_approx(12.0, 0.0001)


func test_req_005_the_per_frame_bound_itself_is_configured() -> void:
	var tight := CameraRig.new(_fixture_tuning({
		"camera.smoothing.max_position_delta_m_per_frame": 0.02,
	}))
	tight.update(FRAME, Vector3.ZERO, 0.0)
	tight.update(FRAME, Vector3(100.0, 0.0, 0.0), 0.0)

	assert_float(tight.get_last_position_delta()).is_equal_approx(0.02, 0.000001)


func test_req_005_every_camera_tuning_key_exists_in_the_surface() -> void:
	var data := _tuning()
	var keys: PackedStringArray = [
		CameraRig.MAX_POSITION_DELTA_KEY,
		CameraRig.MAX_ROTATION_DELTA_KEY,
		CameraRig.POSITION_DAMPING_KEY,
		CameraRig.ROTATION_DAMPING_KEY,
		CameraRig.WATER_DISTANCE_KEY,
		CameraRig.LAND_DISTANCE_KEY,
		CameraRig.WATER_PITCH_KEY,
		CameraRig.LAND_PITCH_KEY,
		CameraRig.MIN_DISTANCE_KEY,
		CameraRig.COLLISION_MARGIN_KEY,
	]
	for key: String in keys:
		assert_bool(data.has_key(key)).override_failure_message(
			"REQ-005: the camera reads '%s', which the tuning surface lacks" % key
		).is_true()


func test_req_005_camera_declares_no_balance_constants() -> void:
	var source := FileAccess.open("res://core/camera/camera_rig.gd", FileAccess.READ)
	var text := source.get_as_text()
	source.close()
	assert_bool(text.contains("_tuning.get_number")).override_failure_message(
		"REQ-005 AC-4: the rig must read its numbers from the tuning surface"
	).is_true()


func test_req_005_every_hint_volume_field_is_exported() -> void:
	# AC-4 for the world-facing half: if a framing field were a plain var, a
	# world author could not set it without writing camera code.
	var source := FileAccess.open(
		"res://core/camera/camera_hint_volume.gd", FileAccess.READ)
	var text := source.get_as_text()
	source.close()

	for field: String in ["hint_priority", "override_distance", "distance_m",
			"override_pitch", "pitch_deg", "override_yaw", "yaw_deg",
			"lock_pitch", "lock_yaw", "lock_distance"]:
		assert_bool(text.contains("@export var %s" % field)
			or text.contains("@export_range(") and text.contains("var %s" % field)
		).override_failure_message(
			"REQ-005 AC-4: hint volume field '%s' must be exported" % field
		).is_true()


func test_req_005_a_world_cannot_run_camera_code_through_a_hint() -> void:
	# The hint carries data only. A Callable field would turn the declarative
	# surface into a script hook and put camera control outside the sanctioned
	# world API surface (REQ-020).
	var source := FileAccess.open("res://core/camera/camera_hint.gd", FileAccess.READ)
	var text := source.get_as_text()
	source.close()

	for symbol: String in ["Callable", "call(", "load(", "GDScript"]:
		assert_bool(text.contains(symbol)).override_failure_message(
			"REQ-005 AC-3: a camera hint must be data, never a script hook "
			+ "(found '%s')" % symbol
		).is_false()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_camera_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	var sources: PackedStringArray = [
		"res://core/camera/camera_framing.gd",
		"res://core/camera/camera_hint.gd",
		"res://core/camera/camera_hint_stack.gd",
		"res://core/camera/camera_hint_volume.gd",
		"res://core/camera/camera_occluder_probe.gd",
		"res://core/camera/scene_occluder_probe.gd",
		"res://core/camera/camera_rig.gd",
	]
	for path: String in sources:
		var handle := FileAccess.open(path, FileAccess.READ)
		var text := handle.get_as_text()
		handle.close()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
