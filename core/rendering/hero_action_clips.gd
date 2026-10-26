class_name HeroActionClips
extends RefCounted

## Refine the imported actions without rewriting the mesh, skin, or source GLB.
static func install(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	for action: String in ["spin","roll","whack"]:
		if not player.has_animation(action):
			continue
		var source := player.get_animation(action)
		var clip := Animation.new()
		clip.length = 0.55 if action == "spin" else (0.38 if action == "roll" else 0.5)
		for track: int in source.get_track_count():
			if source.track_get_type(track) != Animation.TYPE_ROTATION_3D:
				continue
			var path := source.track_get_path(track)
			var bone_name: String = path.get_subname(0)
			var bone: int = skeleton.find_bone(bone_name)
			if bone < 0:
				continue
			var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
			var target: int = clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(target,path)
			for sample: int in 65:
				var phase: float = float(sample)/64.0
				var rotation: Quaternion = (rest*pose(action,bone_name,phase)).normalized()
				if action == "whack" and bone_name == "root":
					# Turn on the ground plane, not the rig's slightly tilted local Z axis.
					rotation = Quaternion(Vector3.UP,whack_yaw(phase))*rest
				clip.rotation_track_insert_key(target,phase*clip.length,rotation)
		var library := player.get_animation_library(player.find_animation_library(source))
		library.remove_animation(action)
		library.add_animation(action,clip)

static func pose(action: String, bone: String, phase: float) -> Quaternion:
	var u: float = clampf(phase,0.0,1.0)
	var angles := Vector3.ZERO
	var side: float = 1.0 if bone.ends_with("l") else -1.0
	if action in ["spin","roll"]:
		var tuck: float = smoothstep(0.0,0.12,u)*(1.0-smoothstep(0.82,1.0,u))
		if bone == "root":
			# Dense quaternion keys retain every revolution; easing softens entry/exit.
			if action == "spin":
				angles.y = (u-sin(TAU*u)/TAU)*TAU*2.0
			else:
				# The land dodge stays low and slides; it no longer tumbles through the floor.
				angles.z = sin(u*TAU)*0.08*tuck
		elif bone.begins_with("leg_"):
			angles = Vector3(0.18*tuck,0,-0.65*side*tuck)
		elif bone.begins_with("tail_"):
			var index: float = float(bone.trim_prefix("tail_"))
			angles.z = sin(u*TAU-index*0.45)*0.07*tuck
		elif bone.begins_with("gill_"):
			angles.z = side*0.10*tuck
	else:
		var swing: float = whip(u)
		if bone.begins_with("tail_"):
			var index: float = float(bone.trim_prefix("tail_"))
			angles.z = whip(maxf(0,u-(index-1)*0.028))*[1.20,0.28,0.10][int(index)-1]
		elif bone == "root":
			angles.z = whack_yaw(u)
		elif bone == "spine":
			angles.z = swing*0.65
		elif bone == "head":
			angles.z = swing*0.45
		elif bone.begins_with("leg_"):
			angles.z = -swing*side*0.06
	return Quaternion.from_euler(angles)

static func whip(u: float) -> float:
	if u < 0.12:
		return lerpf(0,-0.65,smoothstep(0,0.12,u))
	if u < 0.32:
		return lerpf(-0.65,1.0,smoothstep(0.12,0.32,u))
	if u < 0.48:
		return lerpf(1.0,0.70,smoothstep(0.32,0.48,u))
	return lerpf(0.70,0,smoothstep(0.48,0.94,u))

static func whack_yaw(phase: float) -> float:
	var swing: float = whip(phase)
	# Small anticipation, then a hip-led pivot carrying the long tail in front.
	return -swing*(1.80 if swing > 0.0 else 0.30)

static func whack_root_position(rest_position: Vector3, phase: float) -> Vector3:
	# Orbit the hips about the character centre; rotating at the tail root alone
	# can only curl the fin beside the body and cannot reach a forward target.
	return rest_position.rotated(Vector3.UP,whack_yaw(phase))
