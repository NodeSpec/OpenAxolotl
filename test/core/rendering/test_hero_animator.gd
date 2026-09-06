extends GdUnitTestSuite

## The hero's animation set (REQ-035): the rig's clips, chosen from the state
## the controller already knows.
##
## The state table is a pure function, so most of this needs no scene at all.
## The binding half is proven against the SHIPPED model, because a rig that
## exports clips the client never finds is the failure worth catching.

const SCENE_PATH := "res://core/controller/axolotl_body.tscn"


func test_the_state_table_maps_every_movement_state_to_its_clip() -> void:
	# Water wins over everything: the swim cycle is the water grammar.
	assert_str(HeroAnimator.choose_clip(true, false, 0.0, 0.0)
		).is_equal(HeroAnimator.SWIM)
	assert_str(HeroAnimator.choose_clip(true, true, 5.0, 4.0)
		).override_failure_message(
		"a swimmer brushing the seabed is still swimming"
		).is_equal(HeroAnimator.SWIM)

	# Airborne splits on which way the axolotl is going.
	assert_str(HeroAnimator.choose_clip(false, false, 4.0, 0.0)
		).is_equal(HeroAnimator.HOP)
	assert_str(HeroAnimator.choose_clip(false, false, -4.0, 0.0)
		).is_equal(HeroAnimator.FALL)
	assert_str(HeroAnimator.choose_clip(false, false, 0.0, 0.0)
		).override_failure_message(
		"at the apex the arc is falling, not hovering"
		).is_equal(HeroAnimator.FALL)

	# Grounded splits on whether it is going anywhere.
	assert_str(HeroAnimator.choose_clip(false, true, 0.0, 2.5)
		).is_equal(HeroAnimator.WADDLE)
	assert_str(HeroAnimator.choose_clip(false, true, 0.0, 0.0)
		).is_equal(HeroAnimator.IDLE)
	assert_str(HeroAnimator.choose_clip(false, true, 0.0, 0.05)
		).override_failure_message(
		"a hair of residual drift is standing still, not walking"
		).is_equal(HeroAnimator.IDLE)


func test_an_unbound_animator_is_inert_rather_than_broken() -> void:
	# The walk probes build bare bodies with no model at all; that must be
	# quiet, not a crash.
	var animator := HeroAnimator.new()
	assert_bool(animator.bind(null)).is_false()
	assert_bool(animator.is_bound()).is_false()
	animator.step(1.0 / 60.0, false, true, Vector3.ZERO)
	animator.play_hurt()
	assert_str(animator.get_current_clip()).is_empty()


func test_the_shipped_hero_binds_every_clip_the_animator_plays() -> void:
	var body := (load(SCENE_PATH) as PackedScene).instantiate()
	var model := body.get_node("Model") as Node3D

	var animator := HeroAnimator.new()
	assert_bool(animator.bind(model)).override_failure_message(
		"the shipped hero must carry an AnimationPlayer").is_true()

	var players := model.find_children("*", "AnimationPlayer", true, false)
	var player := players[0] as AnimationPlayer
	for clip: String in [HeroAnimator.IDLE, HeroAnimator.WADDLE,
			HeroAnimator.SWIM, HeroAnimator.HOP, HeroAnimator.FALL,
			HeroAnimator.HURT]:
		assert_bool(player.has_animation(clip)).override_failure_message(
			"the rig is missing the %s clip the animator plays" % clip
			).is_true()

	# The ongoing states must loop: glTF import leaves every clip one-shot,
	# so an idle that does not loop freezes the axolotl after four seconds.
	for clip: String in HeroAnimator.LOOPING:
		assert_int(player.get_animation(clip).loop_mode
			).override_failure_message("%s must loop" % clip
			).is_equal(Animation.LOOP_LINEAR)

	body.free()


func test_the_shipped_hero_is_skinned_to_a_skeleton() -> void:
	# Clips that drive a skeleton nothing is bound to move nothing at all.
	var body := (load(SCENE_PATH) as PackedScene).instantiate()
	var model := body.get_node("Model") as Node3D

	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	assert_int(skeletons.size()).override_failure_message(
		"the hero must import a Skeleton3D").is_equal(1)
	var skeleton := skeletons[0] as Skeleton3D
	assert_int(skeleton.get_bone_count()).override_failure_message(
		"the documented rig is eleven bones plus a root").is_greater_equal(8)
	for bone: String in ["root", "spine", "head", "tail_1"]:
		assert_int(skeleton.find_bone(bone)).override_failure_message(
			"the rig must carry the %s bone the clips key" % bone
			).is_greater_equal(0)

	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	assert_int(meshes.size()).is_greater_equal(1)
	for node: Node in meshes:
		assert_object((node as MeshInstance3D).skin).override_failure_message(
			"%s is not skinned; the rig would pose nothing" % node.name
			).is_not_null()

	body.free()


func test_the_eye_and_its_highlight_are_bound_rigidly_to_the_head() -> void:
	# The eye sits a few centimetres from where the gill bones start, so the
	# rigger's nearest-two rule USED to hand it 77% to the fronds — and the
	# highlight a different 70%, so the two rode apart and the glint slid off
	# the pupil whenever the gills swung. Both are rigid features of the head
	# and are bound whole to it; this is what stops that regressing.
	var body := (load(SCENE_PATH) as PackedScene).instantiate()
	var model := body.get_node("Model") as Node3D

	var seen := PackedStringArray()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not (mesh_instance.name in ["axolotl_eye", "axolotl_gleam"]):
			continue
		seen.append(String(mesh_instance.name))

		var skin := mesh_instance.skin
		assert_object(skin).is_not_null()
		var arrays: Array = (mesh_instance.mesh as ArrayMesh
			).surface_get_arrays(0)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]

		var driving := PackedStringArray()
		for index: int in bones.size():
			if weights[index] <= 0.001:
				continue
			var bind := String(skin.get_bind_name(bones[index]))
			if not (bind in driving):
				driving.append(bind)

		assert_int(driving.size()).override_failure_message(
			"%s is driven by %s; a rigid feature must ride one bone"
			% [mesh_instance.name, driving]).is_equal(1)
		assert_str(driving[0]).is_equal("head")

	assert_int(seen.size()).override_failure_message(
		"the eye and the gleam must both survive the merge as named meshes"
		).is_equal(2)

	body.free()


func test_the_hurt_flinch_overrides_locomotion_until_it_finishes() -> void:
	var body := (load(SCENE_PATH) as PackedScene).instantiate()
	var model := body.get_node("Model") as Node3D
	var animator := HeroAnimator.new()
	animator.bind(model)

	animator.step(1.0 / 60.0, false, true, Vector3.ZERO)
	assert_str(animator.get_current_clip()).is_equal(HeroAnimator.IDLE)

	animator.play_hurt()
	assert_str(animator.get_current_clip()).is_equal(HeroAnimator.HURT)

	# Even a state change mid-flinch must not cut the flinch short.
	animator.step(1.0 / 60.0, false, true, Vector3(3.0, 0.0, 0.0))
	assert_str(animator.get_current_clip()).override_failure_message(
		"a flinch the player cannot see is not feedback"
		).is_equal(HeroAnimator.HURT)

	# Once its length has elapsed, locomotion resumes.
	animator.step(2.0, false, true, Vector3(3.0, 0.0, 0.0))
	animator.step(1.0 / 60.0, false, true, Vector3(3.0, 0.0, 0.0))
	assert_str(animator.get_current_clip()).is_equal(HeroAnimator.WADDLE)

	body.free()
