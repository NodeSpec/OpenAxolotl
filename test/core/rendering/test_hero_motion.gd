extends GdUnitTestSuite

func test_swimming_feet_tread_when_idle_and_stream_back_when_moving() -> void:
	for foot: int in 4:
		var idle: Vector3 = HeroMotion.swim_foot_direction(foot,0.0,0.0)
		var later: Vector3 = HeroMotion.swim_foot_direction(foot,0.25,0.0)
		assert_float(idle.distance_to(later)).is_greater(0.1)
		for sample: int in 12:
			var kick: Vector3 = HeroMotion.swim_foot_direction(foot,float(sample)/12,1.0)
			assert_float(kick.z).is_greater(0.8)
			assert_float(absf(kick.x)).is_less(0.55)

func test_particle_builders_do_not_emit_before_placement() -> void:
	var crown := WaterSplash.crown_for(0.5,false)
	var ring := WaterSplash.ring_for(0.5)
	assert_bool(crown.emitting).is_false()
	assert_bool(ring.emitting).is_false()
	crown.free()
	ring.free()

func test_visual_turn_uses_shortest_arc_and_settles() -> void:
	var motion := HeroMotion.new()
	motion.reset_pose(deg_to_rad(175))
	motion.prepare(1.0/60,false,true,Vector3(2,0,0),deg_to_rad(-175),0,Vector3.UP)
	assert_float(absf(wrapf(motion.visual_rotation.y-deg_to_rad(175),-PI,PI))).is_less(0.1)
	for i: int in 120:
		motion.prepare(1.0/60,false,true,Vector3.ZERO,deg_to_rad(-175),0,Vector3.UP)
	assert_float(absf(wrapf(motion.visual_rotation.y-deg_to_rad(-175),-PI,PI))).is_less(0.001)
	motion.free()

func test_swim_posture_blends_instead_of_snapping() -> void:
	var motion := HeroMotion.new()
	motion.prepare(1.0/60,true,false,Vector3(0,0,-4),0,0,Vector3.UP)
	assert_float(motion.swim_weight).is_greater(0.0)
	assert_float(motion.swim_weight).is_less(0.5)
	for i: int in 120:
		motion.prepare(1.0/60,true,false,Vector3(0,0,-4),0,0,Vector3.UP)
	assert_float(motion.visual_offset).is_greater(0.5)
	motion.free()

func test_wetness_acquires_quickly_and_dries_gradually() -> void:
	var motion := HeroMotion.new()
	for i: int in 60:
		motion.prepare(1.0/60,true,false,Vector3.ZERO,0,0,Vector3.UP)
	assert_float(motion.wetness).is_equal_approx(1.0,0.001)
	for i: int in 60:
		motion.prepare(1.0/60,false,true,Vector3.ZERO,0,0,Vector3.UP)
	assert_float(motion.wetness).is_greater(0.8)
	assert_float(motion.wetness).is_less(1.0)
	motion.free()

func test_foot_contact_uses_gait_phase_including_wrap() -> void:
	assert_bool(HeroSurfaceEffects.crossed_contact(0.95,0.04,0.0)).is_true()
	assert_bool(HeroSurfaceEffects.crossed_contact(0.47,0.53,0.5)).is_true()
	assert_bool(HeroSurfaceEffects.crossed_contact(0.20,0.24,0.5)).is_false()
	assert_bool(HeroSurfaceEffects.crossed_contact(0.2,0.2,0.0)).is_false()
	assert_float(HeroMotion.contact_weight(0.25)).is_equal_approx(1.0,0.0001)
	assert_float(HeroMotion.contact_weight(0.8)).is_equal_approx(0.0,0.0001)
	assert_float(HeroMotion.contact_weight(0.0)).is_equal_approx(0.0,0.0001)

func test_spin_contains_two_full_revolutions_without_large_key_jumps() -> void:
	var previous: Quaternion = HeroActionClips.pose("spin","root",0)
	var travel: float = 0.0
	for sample: int in range(1,65):
		var next: Quaternion = HeroActionClips.pose("spin","root",float(sample)/64.0)
		var step: float = previous.angle_to(next)
		assert_float(step).is_less(PI/2)
		travel += step
		previous = next
	assert_float(travel).is_equal_approx(TAU*2,0.01)
	assert_float(previous.angle_to(Quaternion.IDENTITY)).is_less(0.001)

func test_whack_energy_occurs_inside_existing_strike_window_and_recovers() -> void:
	assert_float(HeroActionClips.whip(0.12)).is_less(0.0)
	assert_float(HeroActionClips.whip(0.32)).is_greater(0.9)
	assert_float(HeroActionClips.whip(1)).is_equal_approx(0.0,0.0001)
	for bone: String in ["root","spine","head","tail_1","tail_2","tail_3"]:
		assert_float(HeroActionClips.pose("whack",bone,1).angle_to(Quaternion.IDENTITY)).is_less(0.001)

func test_refinement_does_not_mutate_imported_animation_resources() -> void:
	var packed := load("res://core/controller/axolotl_body.tscn") as PackedScene
	var first := packed.instantiate()
	var second := packed.instantiate()
	var source := second.get_node("Model").find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	var original: float = source.get_animation("spin").length
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(first.get_node("Model"))).is_true()
	assert_float(source.get_animation("spin").length).is_equal_approx(original,0.0001)
	first.free()
	second.free()

func test_water_actions_cancel_on_land_and_whack_cancels_in_water() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as Node3D
	var animator := HeroAnimator.new()
	animator.bind(body.get_node("Model"))
	assert_bool(animator.play_action(HeroAnimator.SPIN,0.55)).is_true()
	animator.step(0.02,false,true,Vector3.ZERO)
	assert_str(animator.get_current_action()).is_empty()
	assert_str(animator.get_current_clip()).is_equal(HeroAnimator.IDLE)
	assert_bool(animator.play_action(HeroAnimator.WHACK)).is_true()
	animator.step(0.02,true,false,Vector3.ZERO)
	assert_str(animator.get_current_clip()).is_equal(HeroAnimator.SWIM)
	body.free()

func test_moving_tail_attack_keeps_a_separate_leg_cycle() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as Node3D
	var animator := HeroAnimator.new()
	animator.bind(body.get_node("Model"))
	animator.play_action(HeroAnimator.WHACK)
	animator.step(0.05,false,true,Vector3(3,0,0))
	assert_bool(animator.has_walking_feet()).is_true()
	var first: Quaternion = animator.walking_leg_pose("leg_fl")
	animator.step(0.10,false,true,Vector3(3,0,0))
	assert_float(first.angle_to(animator.walking_leg_pose("leg_fl"))).is_greater(0.01)
	assert_str(animator.get_current_action()).is_equal(HeroAnimator.WHACK)
	body.free()

func test_idle_paddling_is_preserved_and_fast_swim_limbs_hug_the_body() -> void:
	for foot: int in 4:
		for sample: int in 24:
			var phase: float = float(sample)/24.0
			var cycle: float = TAU*(phase+[0.0,0.5,0.55,0.05][foot])
			var side: float = 1.0 if foot%2 == 0 else -1.0
			var original := Vector3(side*(0.34+0.06*sin(cycle)),-0.15+0.07*cos(cycle),0.10+0.10*sin(cycle)).normalized()
			assert_float(HeroMotion.swim_foot_direction(foot,phase,0).distance_to(original)).is_less(0.00001)
			var moving := HeroMotion.swim_foot_direction(foot,phase,1)
			assert_float(moving.z).is_greater(0.98)
			assert_float(absf(moving.x)).is_less(0.13)
			assert_float(absf(moving.y)).is_less(0.10)

func test_swimming_wave_travels_down_tail_and_scales_with_effort() -> void:
	for sample: int in 24:
		var phase: float = float(sample)/24.0
		assert_float(HeroMotion.swim_bend("spine",phase,0)).is_equal_approx(0,0.0001)
		var first := HeroMotion.swim_bend("tail_1",phase,1)/0.24
		var delayed := HeroMotion.swim_bend("tail_2",phase+0.8/TAU,1)/0.34
		assert_float(absf(first-delayed)).is_less(0.0001)
		assert_float(absf(HeroMotion.swim_bend("tail_3",phase,0.5)*2-HeroMotion.swim_bend("tail_3",phase,1))).is_less(0.0001)
	assert_float(absf(HeroMotion.swim_bend("head",0.25,1))).is_less(absf(HeroMotion.swim_bend("spine",0.25,1)))

func test_land_slide_stays_upright_and_tail_strike_has_larger_sweep() -> void:
	for sample: int in 32:
		var q := HeroActionClips.pose("roll","root",float(sample)/31.0)
		assert_float(q.angle_to(Quaternion.IDENTITY)).is_less(0.10)
	assert_float(HeroActionClips.pose("whack","tail_1",0.32).angle_to(Quaternion.IDENTITY)).is_greater(0.80)
	assert_float(HeroActionClips.pose("whack","tail_1",0.12).angle_to(Quaternion.IDENTITY)).is_greater(0.50)
	assert_float(HeroActionClips.pose("roll","root",1).angle_to(Quaternion.IDENTITY)).is_less(0.0001)

func test_current_frame_is_valid_when_stopped_or_swimming_vertically() -> void:
	for direction: Vector3 in [Vector3.ZERO,Vector3.UP,Vector3.DOWN,Vector3.FORWARD,Vector3(0.01,1,0),Vector3(1,2,3)]:
		var frame := HeroSurfaceEffects.flow_basis(direction)
		assert_bool(frame.is_finite()).is_true()
		assert_float(frame.determinant()).is_equal_approx(1.0,0.0001)
		assert_float(frame.x.dot(frame.y)).is_equal_approx(0.0,0.0001)
		assert_float(frame.y.length()).is_equal_approx(1.0,0.0001)


func test_whack_reaches_a_forward_target_instead_of_curling_behind() -> void:
	var model := load("res://assets/character/axolotl/axolotl.glb").instantiate() as Node3D
	var animator := HeroAnimator.new()
	animator.bind(model)
	var skeleton := model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	var clip: Animation = animator._player.get_animation(HeroAnimator.WHACK)
	var tracks: Dictionary = {}
	for track: int in clip.get_track_count():
		if clip.track_get_type(track)==Animation.TYPE_ROTATION_3D:
			tracks[String(clip.track_get_path(track).get_subname(0))]=track
	var best_forward: float = -INF
	var best_head_clearance: float = -INF
	for sample: int in 65:
		var phase: float = float(sample)/64.0
		var globals: Array[Transform3D] = []
		for bone: int in skeleton.get_bone_count():
			var name: String = skeleton.get_bone_name(bone)
			var rest := skeleton.get_bone_rest(bone)
			var rotation: Quaternion = clip.rotation_track_interpolate(int(tracks[name]),phase*clip.length) if tracks.has(name) else rest.basis.get_rotation_quaternion()
			var at: Vector3 = HeroActionClips.whack_root_position(rest.origin,phase) if name=="root" else rest.origin
			var local := Transform3D(Basis(rotation),at)
			var parent: int = skeleton.get_bone_parent(bone)
			globals.append(globals[parent]*local if parent>=0 else local)
		var tip: Vector3 = globals[skeleton.find_bone("tail_3")]*Vector3(0,0.5,0)
		var head: Vector3 = globals[skeleton.find_bone("head")]*Vector3(0,0.7,0)
		best_forward=maxf(best_forward,-tip.z*0.5)
		best_head_clearance=maxf(best_head_clearance,(head.z-tip.z)*0.5)
		assert_float(tip.y).is_greater(0.0)
	assert_float(best_forward).is_greater(0.80)
	assert_float(best_head_clearance).is_greater(0.25)
	var root_rest: Vector3 = skeleton.get_bone_rest(skeleton.find_bone("root")).origin
	assert_float(HeroActionClips.whack_root_position(root_rest,1.0).distance_to(root_rest)).is_less(0.0001)
	model.free()
