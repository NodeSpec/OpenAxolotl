extends RefCounted
## A 32-beat shore dance at the same 112 BPM as crayfish_groove.wav.
const BPM := 112.0
const LENGTH := 32.0 * 60.0 / BPM
static func install(player: AnimationPlayer, skeleton: Skeleton3D, feet: Dictionary) -> void:
	var clip:=Animation.new();clip.length=LENGTH
	var source:=player.get_animation("idle")
	var path_to_skeleton:=NodePath("")
	for track: int in source.get_track_count():
		var path:=source.track_get_path(track)
		if path.get_subname_count()>0:
			path_to_skeleton=NodePath(path.get_concatenated_names());break
	# Other clips must explicitly reset the translation introduced by this action.
	for name: StringName in player.get_animation_list():
		if name==&"dance":continue
		var other:=player.get_animation(name)
		var path:=NodePath(String(path_to_skeleton)+":root")
		if other.find_track(path,Animation.TYPE_POSITION_3D)<0:
			var track:=other.add_track(Animation.TYPE_POSITION_3D)
			other.track_set_path(track,path)
			other.position_track_insert_key(track,0.,skeleton.get_bone_rest(0).origin)
	var tracks: Dictionary={}
	for bone: int in skeleton.get_bone_count():
		var index:=clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(index,NodePath(String(path_to_skeleton)+":"+skeleton.get_bone_name(bone)))
		tracks[bone]=index
	var root_track:=clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(root_track,NodePath(String(path_to_skeleton)+":root"))
	for sample: int in 513:
		var phase:=float(sample)/512.0
		var pose:=sample_pose(skeleton,feet,phase)
		for bone: int in skeleton.get_bone_count():clip.rotation_track_insert_key(int(tracks[bone]),phase*LENGTH,(pose[bone] as Transform3D).basis.get_rotation_quaternion().normalized())
		clip.position_track_insert_key(root_track,phase*LENGTH,(pose[0] as Transform3D).origin)
	var library:=player.get_animation_library(player.find_animation_library(source))
	if library.has_animation(&"dance"):library.remove_animation(&"dance")
	library.add_animation(&"dance",clip)

static func sample_pose(skeleton: Skeleton3D, feet: Dictionary, phase: float) -> Array[Transform3D]:
	var beat:=phase*32.0
	var stand:=smoothstep(0.,2.,beat)*(1.0-smoothstep(30.,32.,beat))
	var groove:=smoothstep(2.,3.,beat)*(1.0-smoothstep(29.,30.,beat))
	var step:=sin(TAU*(beat-2.)/8.)*.12*groove
	var bounce:=absf(sin(PI*beat))*.045*groove
	var twist:=sin(TAU*beat/8.)*.14*groove
	var rest_root:=skeleton.get_bone_rest(0)
	var rise:=Quaternion(Vector3.UP,twist)*Quaternion(Vector3.RIGHT,.20*stand)
	var root_position:=rest_root.origin+Vector3(step,-.10*stand+bounce*.30,0.)
	var local: Array[Transform3D]=[]
	var global: Array[Transform3D]=[]
	for bone: int in skeleton.get_bone_count():
		var name:=skeleton.get_bone_name(bone)
		var rest:=skeleton.get_bone_rest(bone)
		var parent:=skeleton.get_bone_parent(bone)
		var parent_pose:=global[parent] if parent>=0 else Transform3D.IDENTITY
		var pose:=rest
		if name=="root":pose=Transform3D(Basis(rise)*rest.basis,root_position)
		elif name=="spine":
			# Rise through the waist; the pelvis stays over the supporting hind feet.
			var desired:=Basis(Quaternion(Vector3.UP,twist)*Quaternion(Vector3.RIGHT,1.10*stand))*skeleton.get_bone_global_rest(bone).basis
			pose.basis=parent_pose.basis.inverse()*desired
		elif name=="head":
			var desired:=Basis(Quaternion(Vector3.UP,twist*.5)*Quaternion(Vector3.RIGHT,.23*stand+.06*sin(TAU*beat)*groove))*skeleton.get_bone_global_rest(bone).basis
			pose.basis=parent_pose.basis.inverse()*desired
		elif name=="tail_1":
			var desired:=Basis(Quaternion(Vector3.UP,-.22*sin(TAU*beat/4.)*groove)*Quaternion(Vector3.RIGHT,-.035*stand))*skeleton.get_bone_global_rest(bone).basis
			pose.basis=parent_pose.basis.inverse()*desired
		elif name.begins_with("tail_"):
			pose.basis=rest.basis*Basis(Vector3.FORWARD,.08*sin(TAU*beat/4.-bone*.35)*groove)
		elif name.begins_with("leg_b") and feet.has(name):
			var side:=1.0 if name.ends_with("l") else -1.0
			var rest_tip:=skeleton.get_bone_global_rest(bone)*(feet[name] as Vector3)
			# Alternating side steps, heel taps, and a short forward/back shuffle.
			var lift:=maxf(0.,sin(PI*beat+side*PI*.5))*.11*groove
			var target:=rest_tip+Vector3(step*1.15,lift,sin(TAU*beat/4.+side)*.10*groove)
			var start:=parent_pose*rest.origin
			var from: Vector3=parent_pose.basis*rest.basis*(feet[name] as Vector3)
			var correction:=Basis(Quaternion(from.normalized(),(target-start).normalized()))
			pose.basis=parent_pose.basis.inverse()*correction*parent_pose.basis*rest.basis
		elif name.begins_with("leg_f"):
			var side:=1.0 if name.ends_with("l") else -1.0
			var desired:=Basis(Quaternion(Vector3.FORWARD,side*(.36*stand+.30*sin(PI*beat)*groove))*Quaternion(Vector3.RIGHT,-.2*stand))*skeleton.get_bone_global_rest(bone).basis
			pose.basis=parent_pose.basis.inverse()*desired
		elif name.begins_with("gill_"):
			pose.basis=rest.basis*Basis(Vector3.FORWARD,.06*sin(PI*beat)*groove)
		local.append(pose);global.append(parent_pose*pose)
	return local
