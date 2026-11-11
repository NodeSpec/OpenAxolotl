extends GdUnitTestSuite

## Legs with joints (REQ-002 AC-9): the shipped rig, the solver that bends it,
## and the gait timing that keeps a planted foot inside its leg's reach.
##
## tools/test_extend_hero_rig.py proves the rig tool writes what it promises.
## This suite proves the GODOT half — that what reaches the engine after import
## still has it, and that the runtime asks the legs only for what they can do:
##
##   * every leg has its chain, hung in order under the bone clips already key;
##   * every sole follows its own foot bone and nothing else;
##   * a solved leg keeps its bone lengths, reaches what it can and folds or
##     stretches honestly at what it cannot;
##   * the walk never asks a foot to stay planted further than a leg reaches,
##     which is the arithmetic the old cadence got wrong by a factor of four.
##
## What is NOT here is the look of the walk. That is REQ-002 AC-10, a reel a
## person approves; tools/hero_gait_probe.gd measures the sliding and
## docs/hero-rig-audit.md records it.

const HERO := "res://assets/character/axolotl/axolotl.glb"
const BODY := "res://core/controller/axolotl_body.tscn"

const LEGS: Array[String] = ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
const ORIGINAL_BONES: Array[String] = [
	"root", "spine", "head", "gill_l", "gill_r",
	"leg_fl", "leg_fr", "leg_bl", "leg_br", "tail_1", "tail_2", "tail_3"]

## How close to the model's floor a vertex has to be to count as sole, in the
## model's own units. The same band the rig tool fits against.
const SOLE_BAND := 0.04


func _hero() -> Node3D:
	return (load(HERO) as PackedScene).instantiate() as Node3D


func _skeleton(model: Node3D) -> Skeleton3D:
	return model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D


func _fitted(model: Node3D) -> HeroMotion:
	var motion := HeroMotion.new()
	motion._fit_chains(_skeleton(model))
	return motion


func test_req_002_every_leg_carries_a_chain_from_shoulder_to_toe() -> void:
	var model := _hero()
	var skeleton := _skeleton(model)
	for name: String in ORIGINAL_BONES:
		assert_bool(skeleton.find_bone(name) >= 0).override_failure_message(
			"the rig lost `%s`, a bone every clip and half the engine code "
			% name + "finds by name").is_true()
	for leg: String in LEGS:
		var suffix := leg.trim_prefix("leg_")
		var parent := skeleton.find_bone(leg)
		for part: String in ["upper", "shin", "foot", "toe"]:
			var bone := skeleton.find_bone("%s_%s" % [part, suffix])
			assert_bool(bone >= 0).override_failure_message(
				"%s has no %s bone: run oax-extend-rig on the hero"
				% [leg, part]).is_true()
			if bone < 0:
				break
			assert_int(skeleton.get_bone_parent(bone)).override_failure_message(
				"%s_%s must hang from the bone before it in the chain"
				% [part, suffix]).is_equal(parent)
			parent = bone
	model.free()


func test_req_002_every_sole_follows_its_own_foot_and_nothing_else() -> void:
	# The defect this rig was rebuilt for, asserted on the mesh the renderer
	# gets: the front-left sole used to be bound 57% to the HEAD and 28% to its
	# leg, so it swung when the head turned and barely stepped.
	var model := _hero()
	var skeleton := _skeleton(model)
	var owned: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var total: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var middle: float = (skeleton.get_bone_global_rest(skeleton.find_bone("leg_fl")).origin.z
		+ skeleton.get_bone_global_rest(skeleton.find_bone("leg_bl")).origin.z) * 0.5
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null or instance.skin == null:
			continue
		var bind_names: Array[String] = []
		for bind: int in instance.skin.get_bind_count():
			var bind_name := String(instance.skin.get_bind_name(bind))
			if bind_name.is_empty():
				bind_name = skeleton.get_bone_name(instance.skin.get_bind_bone(bind))
			bind_names.append(bind_name)
		for surface: int in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var floor_height: float = INF
			for vertex: Vector3 in vertices:
				floor_height = minf(floor_height, vertex.y)
			var influences: int = bones.size() / vertices.size()
			for index: int in vertices.size():
				var vertex: Vector3 = vertices[index]
				if vertex.y >= floor_height + SOLE_BAND:
					continue
				var foot: int = (0 if vertex.z < middle else 2) + (0 if vertex.x > 0.0 else 1)
				var own := "foot_" + LEGS[foot].trim_prefix("leg_")
				for slot: int in influences:
					var weight: float = weights[index * influences + slot]
					total[foot] += weight
					if bind_names[bones[index * influences + slot]] == own:
						owned[foot] += weight
	for foot: int in 4:
		assert_bool(total[foot] > 0.0).override_failure_message(
			"found no sole under %s at all" % LEGS[foot]).is_true()
		var share: float = owned[foot] / maxf(total[foot], 0.0001)
		assert_bool(share >= 0.99).override_failure_message(
			"only %.1f%% of the sole under %s follows its own foot bone"
			% [share * 100.0, LEGS[foot]]).is_true()
	model.free()


func test_req_002_a_solved_leg_reaches_its_target_without_changing_length() -> void:
	var root := Vector3(0.2, 0.25, -0.8)
	var pole := Vector3(0.55, 0.75, 0.35).normalized()
	for sample: int in 40:
		var angle: float = TAU * sample / 40.0
		var target := root + Vector3(0.08 + 0.05 * cos(angle), -0.17, 0.12 * sin(angle))
		var solved := HeroMotion.solve_leg(root, target, 0.126, 0.143, pole)
		assert_float(root.distance_to(solved[0])).is_equal_approx(0.126, 0.0001)
		assert_float(solved[0].distance_to(solved[1])).is_equal_approx(0.143, 0.0001)
		assert_float(solved[1].distance_to(target)).override_failure_message(
			"a target inside the leg's reach has to be reached exactly: a "
			+ "planted foot that is nearly on its mark is a sliding foot"
			).is_less(0.0001)
		# The joint leans toward the pole: out and up, the way the animal
		# sprawls, never folding through its own belly.
		var middle := root.lerp(solved[1], 0.5)
		assert_float((solved[0] - middle).dot(pole)).is_greater(0.0)


func test_req_002_a_leg_asked_for_too_much_stretches_or_folds_but_never_breaks() -> void:
	var root := Vector3.ZERO
	var pole := Vector3(1, 1, 0).normalized()
	# Too far: full stretch along the way to it, and not one millimetre more.
	var far := HeroMotion.solve_leg(root, Vector3(0, -5, 0), 0.12, 0.14, pole)
	assert_float(root.distance_to(far[1])).is_less(0.26)
	assert_float(root.distance_to(far[1])).is_greater(0.2585)
	assert_float(root.distance_to(far[0])).is_equal_approx(0.12, 0.0001)
	assert_float(far[0].distance_to(far[1])).is_equal_approx(0.14, 0.0001)
	# Too close: folded as far as two unequal bones allow.
	var near := HeroMotion.solve_leg(root, Vector3(0, -0.001, 0), 0.12, 0.14, pole)
	assert_float(root.distance_to(near[0])).is_equal_approx(0.12, 0.0001)
	assert_float(near[0].distance_to(near[1])).is_equal_approx(0.14, 0.0001)
	# On top of its own root, or with a pole along the limb: still a pose.
	for target: Vector3 in [Vector3.ZERO, Vector3(0.1, 0.1, 0)]:
		for hint: Vector3 in [pole, Vector3(0.1, 0.1, 0).normalized(), Vector3.DOWN]:
			var solved := HeroMotion.solve_leg(root, target, 0.12, 0.14, hint)
			assert_bool(solved[0].is_finite() and solved[1].is_finite()).is_true()


func test_req_002_the_walk_never_asks_a_foot_to_outstay_its_leg() -> void:
	# The body may travel STANCE_TRAVEL over one planted foot and no further.
	# Below the cadence cap the cycle is timed to honour that exactly; above
	# it the cycle stops shortening and the foot is let go early instead
	# (HeroMotion._step_leg), so the bound that matters here is the cap.
	var previous_cadence := 0.0
	var previous_duty := 1.0
	for step: int in range(1, 85):
		var speed: float = step * 0.05
		var cadence := HeroAnimator.gait_cadence(speed)
		var duty := HeroAnimator.gait_duty(speed)
		assert_float(cadence).is_less_equal(HeroAnimator.CADENCE_MAX + 0.0001)
		assert_bool(cadence >= previous_cadence - 0.0001).override_failure_message(
			"the walk slowed its step as the animal sped up, at %.2f m/s" % speed
			).is_true()
		assert_bool(duty <= previous_duty + 0.0001).is_true()
		if cadence < HeroAnimator.CADENCE_MAX - 0.0001:
			assert_float(speed * duty / cadence).override_failure_message(
				"at %.2f m/s a stance covers more ground than a leg reaches"
				% speed).is_equal_approx(HeroAnimator.STANCE_TRAVEL, 0.0005)
		previous_cadence = cadence
		previous_duty = duty
	assert_float(HeroAnimator.gait_cadence(0.0)).is_equal_approx(0.0, 0.0001)
	assert_float(HeroAnimator.gait_duty(0.0)).is_equal_approx(HeroAnimator.DUTY_WALK, 0.0001)
	assert_float(HeroAnimator.gait_duty(9.0)).is_equal_approx(HeroAnimator.DUTY_SCURRY, 0.0001)


func test_req_002_every_leg_can_cover_most_of_the_stance_it_is_timed_for() -> void:
	# STANCE_TRAVEL is a promise the animator makes on the legs' behalf, so it
	# is checked against the legs: measured on the shipped rig, at the scale
	# the body scene shows it and the height it walks at. A re-rigged or
	# re-proportioned hero that cannot keep it fails here with the number,
	# instead of quietly lifting its feet early on every step.
	var body := (load(BODY) as PackedScene).instantiate() as Node3D
	var model := body.get_node("Model") as Node3D
	var scale: float = model.scale.y
	var motion := _fitted(model)
	assert_bool(motion.has_leg_chains()).is_true()
	for foot: int in 4:
		var span: float = motion.planted_span(foot, scale)
		assert_bool(span >= HeroAnimator.STANCE_TRAVEL * 0.8).override_failure_message(
			("%s can stay planted over %.3f m of travel; the walk is timed "
			+ "for %.2f m") % [LEGS[foot], span, HeroAnimator.STANCE_TRAVEL]
			).is_true()
	motion.free()
	body.free()


func test_req_002_both_feet_of_a_pair_stand_on_one_line() -> void:
	# The sculpt is frozen mid-stride — front-left reaching ahead, hind-right
	# tucked under — and a stance copied from it limps. Standing places are
	# fitted per pair instead, mirrored across the body.
	var model := _hero()
	var motion := _fitted(model)
	for pair: Array in [[0, 1], [2, 3]]:
		var left: Vector3 = motion._chains[pair[0]]["home"]
		var right: Vector3 = motion._chains[pair[1]]["home"]
		assert_float(left.x).is_equal_approx(-right.x, 0.0001)
		assert_float(left.z).is_equal_approx(right.z, 0.0001)
		assert_float(left.x).is_greater(0.0)
	motion.free()
	model.free()


func test_req_002_a_rig_without_leg_joints_keeps_the_walk_it_had() -> void:
	# The one-bone correction and its slower cadence stay for any hero that
	# has not been through the extender; nothing here may make such a rig
	# step at a tempo its legs cannot plant at.
	var skeleton := Skeleton3D.new()
	for name: String in ORIGINAL_BONES:
		skeleton.add_bone(name)
	var motion := HeroMotion.new()
	motion._fit_chains(skeleton)
	assert_bool(motion.has_leg_chains()).is_false()
	assert_float(motion.planted_span(0, 0.5)).is_equal_approx(0.0, 0.0001)

	var animator := HeroAnimator.new()
	animator._planar = 2.4
	assert_bool(animator.has_jointed_legs()).is_false()
	assert_float(animator.get_gait_cadence()).is_equal_approx(2.0, 0.0001)
	motion.free()
	skeleton.free()


func test_req_002_the_shipped_hero_walks_at_the_cadence_its_legs_can_plant() -> void:
	# The animator and the motion layer each decide for themselves whether the
	# rig has jointed legs. They have to reach the same answer: a quick step
	# on legs that are not being placed would only skate faster.
	var body := (load(BODY) as PackedScene).instantiate() as Node3D
	var model := body.get_node("Model") as Node3D
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(model)).is_true()
	var motion := _fitted(model)
	assert_bool(animator.has_jointed_legs()).is_true()
	assert_bool(motion.has_leg_chains()).is_true()
	animator._planar = 1.0
	assert_float(animator.get_gait_cadence()).is_equal_approx(HeroAnimator.gait_cadence(1.0), 0.0001)
	motion.free()
	body.free()
