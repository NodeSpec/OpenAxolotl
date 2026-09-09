extends GdUnitTestSuite

## Gameplay/presentation synchronization pass (REQ-035).
##
## Controller action windows are gameplay truth; imported clip lengths are art
## authoring truth. The animator must reconcile them so control never returns
## while the model is visibly still committed to a roll/spin, and the visual
## motion never finishes early while the gameplay burst continues.


func _model_with_actions(authored_length: float) -> Dictionary:
	var model := Node3D.new()
	var player := AnimationPlayer.new()
	model.add_child(player)

	var library := AnimationLibrary.new()
	for name: String in [HeroAnimator.ROLL, HeroAnimator.SPIN, HeroAnimator.IDLE]:
		var animation := Animation.new()
		animation.length = authored_length
		library.add_animation(name, animation)
	player.add_animation_library("", library)
	return {"model": model, "player": player}


func test_req_035_action_clip_speeds_up_to_match_a_short_gameplay_window() -> void:
	var fixture := _model_with_actions(1.0)
	var model := fixture["model"] as Node3D
	var player := fixture["player"] as AnimationPlayer
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(model)).is_true()

	assert_bool(animator.play_action(HeroAnimator.ROLL, 0.4)).is_true()
	assert_float(player.speed_scale).override_failure_message(
		"a 1.0 s authored roll targeting 0.4 s must play at 2.5x"
		).is_equal_approx(2.5, 0.001)
	assert_str(animator.get_current_action()).is_equal(HeroAnimator.ROLL)

	animator.step(0.39, false, true, Vector3.ZERO)
	assert_str(animator.get_current_action()).is_equal(HeroAnimator.ROLL)
	animator.step(0.02, false, true, Vector3.ZERO)
	assert_str(animator.get_current_action()).override_failure_message(
		"the visual commitment must end with the gameplay window"
		).is_empty()
	model.free()


func test_req_035_action_clip_slows_down_to_match_a_longer_gameplay_window() -> void:
	var fixture := _model_with_actions(0.25)
	var model := fixture["model"] as Node3D
	var player := fixture["player"] as AnimationPlayer
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(model)).is_true()

	assert_bool(animator.play_action(HeroAnimator.SPIN, 0.5)).is_true()
	assert_float(player.speed_scale).override_failure_message(
		"a 0.25 s authored spin targeting 0.5 s must play at half speed"
		).is_equal_approx(0.5, 0.001)
	model.free()


func test_req_035_legacy_actions_without_a_target_keep_authored_timing() -> void:
	var fixture := _model_with_actions(0.75)
	var model := fixture["model"] as Node3D
	var player := fixture["player"] as AnimationPlayer
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(model)).is_true()

	assert_bool(animator.play_action(HeroAnimator.ROLL)).is_true()
	assert_float(player.speed_scale).is_equal_approx(1.0, 0.001)
	model.free()


func test_req_035_body_wires_roll_and_spin_to_their_tuned_burst_durations() -> void:
	var path := "res://core/controller/axolotl_body.gd"
	var handle := FileAccess.open(path, FileAccess.READ)
	assert_object(handle).is_not_null()
	var source := handle.get_as_text()
	handle.close()

	assert_bool(source.contains("get_roll().duration_seconds()")
		).override_failure_message(
		"roll animation must be tied to the tuned roll gameplay window").is_true()
	assert_bool(source.contains("get_spin_sprint().duration_seconds()")
		).override_failure_message(
		"spin animation must be tied to the tuned spin gameplay window").is_true()
