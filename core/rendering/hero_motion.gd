class_name HeroMotion
extends SkeletonModifier3D

var body: AxolotlBody
var model: Node3D
var visual_rotation := Vector3.ZERO
var visual_offset: float = 0.0
var wetness: float = 0.0
var swim_weight: float = 0.0
var bank: float = 0.0
var turn_rate: float = 0.0
var _initialized: bool = false
var _speed: float = 0.0
var swim_drive: float = 0.0
var swim_phase: float = 0.0
var _time: float = 0.0
var _bend: Array[float] = [0.0,0.0,0.0]
var _head_lead: float = 0.0
var _feet: Dictionary = {}
var _foot_heights: Array[float] = [INF,INF,INF,INF]
var _materials: Array[Dictionary] = []
var _foot_planted: Array[bool] = [false,false,false,false]
var _foot_anchors: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var _last_velocity := Vector3.ZERO
var _acceleration_lean := 0.0
var _swim_yaw_velocity := 0.0
const FEET: Array[String] = ["leg_fl","leg_fr","leg_bl","leg_br"]
const FOOT_PHASE: Array[float] = [0.0,0.5,0.62,0.12]

func bind(owner_body: AxolotlBody, visual: Node3D) -> void:
	body = owner_body
	model = visual
	_fit_feet()
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if original == null:
				continue
			var material := original.duplicate() as BaseMaterial3D
			mesh.set_surface_override_material(surface,material)
			_materials.append({"material":material,"roughness":original.roughness,"coat":original.clearcoat,"coat_enabled":original.clearcoat_enabled,"coat_roughness":original.clearcoat_roughness})

func reset_pose(yaw: float) -> void:
	visual_rotation = Vector3(0,yaw,0)
	_initialized = true
	turn_rate = 0.0
	bank = 0.0
	_bend = [0.0,0.0,0.0]
	_head_lead = 0.0
	_foot_heights = [INF,INF,INF,INF]
	_foot_planted = [false,false,false,false]
	_last_velocity = Vector3.ZERO
	_acceleration_lean = 0.0
	_swim_yaw_velocity = 0.0

func prepare(delta: float, in_water: bool, grounded: bool, velocity: Vector3, yaw: float, pitch: float, floor_normal: Vector3) -> void:
	if delta <= 0:
		return
	if not _initialized:
		reset_pose(yaw)
	_time += delta
	var old_yaw: float = visual_rotation.y
	var action: String = body.get_animator().get_current_action() if body != null else ""
	var response: float = 22.0 if action in ["spin","roll"] else 13.0
	if in_water and action.is_empty():
		# Ease angular speed as well as orientation: the torso begins, carries
		# through, and settles into a turn rather than swivelling in one tick.
		var difference := wrapf(yaw-old_yaw,-PI,PI)
		var wanted_rate := clampf(difference*6.0,-deg_to_rad(240.0),deg_to_rad(240.0))
		_swim_yaw_velocity = move_toward(_swim_yaw_velocity,wanted_rate,deg_to_rad(850.0)*delta)
		var step := _swim_yaw_velocity*delta
		if step*difference > 0.0 and absf(step) > absf(difference):
			step = difference
			_swim_yaw_velocity = 0.0
		visual_rotation.y = wrapf(old_yaw+step,-PI,PI)
	else:
		_swim_yaw_velocity = 0.0
		visual_rotation.y = wrapf(lerp_angle(old_yaw,yaw,1.0-exp(-delta*response)),-PI,PI)
	turn_rate = lerpf(turn_rate,clampf(wrapf(visual_rotation.y-old_yaw,-PI,PI)/delta,-6,6),1.0-exp(-delta*9))
	swim_weight = lerpf(swim_weight,1.0 if in_water else 0.0,1.0-exp(-delta*9))
	var contact_water: WaterVolume = body.get_water_volume() if body != null else null
	var relative_velocity: Vector3 = velocity-contact_water.flow_at(body.global_position) if contact_water != null and body.is_inside_tree() else velocity
	var acceleration := ((relative_velocity - _last_velocity) / delta).rotated(Vector3.UP, -visual_rotation.y)
	_last_velocity = relative_velocity
	var lean_target := clampf(acceleration.z * 0.006, -0.10, 0.08) if grounded and not in_water and action.is_empty() else 0.0
	_acceleration_lean = lerpf(_acceleration_lean, lean_target, 1.0-exp(-delta*12))
	_speed = lerpf(_speed,relative_velocity.length(),1.0-exp(-delta*10))
	swim_drive = smoothstep(0.25,3.5,_speed)
	swim_phase = fposmod(swim_phase+delta*lerpf(0.48,1.55,swim_drive),1.0)
	var action_damping: float = 0.0 if not action.is_empty() else 1.0
	bank = lerpf(bank,clampf(turn_rate*(0.085 if in_water else 0.014),-0.28,0.28)*action_damping,1.0-exp(-delta*9))
	var lead := wrapf(yaw-visual_rotation.y,-PI,PI)
	if in_water: lead = clampf(lead,-0.55,0.55)
	_head_lead = lerpf(_head_lead,lead*action_damping,1.0-exp(-delta*(8.0 if in_water else 12.0)))
	for i: int in 3:
		var wanted: float = -turn_rate*(0.055 if in_water else 0.035)*action_damping if i == 0 else _bend[i-1]
		_bend[i] = lerpf(_bend[i],clampf(wanted,-0.24,0.24),1.0-exp(-delta*((6.5-i*1.4) if in_water else (8.0-i*1.7))))
	var normal: Vector3 = floor_normal.rotated(Vector3.UP,-visual_rotation.y) if grounded else Vector3.UP
	var slope_pitch: float = clampf(atan2(normal.z,maxf(0.1,normal.y)),-0.25,0.25)*(1.0-swim_weight)
	var slope_roll: float = -clampf(atan2(normal.x,maxf(0.1,normal.y)),-0.20,0.20)*(1.0-swim_weight)
	visual_rotation.x = lerp_angle(visual_rotation.x,pitch*swim_weight+slope_pitch+_acceleration_lean,1.0-exp(-delta*11))
	visual_rotation.z = bank+slope_roll
	# Bring the torso toward the capsule centre while swimming; feet anchor land poses.
	visual_offset = swim_weight*(0.55+sin(_time*2.4)*0.015)
	if action == HeroAnimator.ROLL and grounded and not in_water:
		var phase: float = body.get_animator().get_action_phase()
		visual_offset -= 0.055*smoothstep(0.0,0.12,phase)*(1.0-smoothstep(0.75,1.0,phase))
	for foot: int in 4:
		_foot_heights[foot] = INF
		if not grounded or in_water or not action.is_empty(): _foot_planted[foot] = false
		if body != null and body.is_inside_tree() and grounded and not in_water and action not in ["roll","dance"]:
			var point: Vector3 = foot_position(foot)
			var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.4,point+Vector3.DOWN*0.5,body.collision_mask,[body.get_rid()])
			var hit: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and (hit["normal"] as Vector3).y > 0.55:
				_foot_heights[foot] = (hit["position"] as Vector3).y+0.008
	var water: WaterVolume = body.get_water_volume() if body != null else null
	var wet_target: float = 1.0 if in_water else 0.0
	if water != null and body.global_position.y-0.8 < water.surface_at(body.global_position):
		wet_target = maxf(wet_target,0.45)
	wetness = move_toward(wetness,wet_target,delta*(3.0 if wet_target > wetness else 0.075))
	for row: Dictionary in _materials:
		var material := row["material"] as BaseMaterial3D
		material.roughness = float(row["roughness"])*lerpf(1.0,0.38,wetness)
		material.clearcoat_enabled = bool(row["coat_enabled"]) or wetness > 0.01
		material.clearcoat = lerpf(float(row["coat"]),0.5,wetness)
		material.clearcoat_roughness = lerpf(float(row["coat_roughness"]),0.18,wetness)

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or body == null:
		return
	var action: String = body.get_animator().get_current_action()
	if action == HeroAnimator.DANCE:return
	if action == HeroAnimator.WHACK:
		var root: int = skeleton.find_bone("root")
		if root >= 0:
			# Modifier poses are transient, so this pivot cannot leave an offset in
			# the next locomotion clip or move the CharacterBody collision capsule.
			skeleton.set_bone_pose_position(root,HeroActionClips.whack_root_position(skeleton.get_bone_rest(root).origin,body.get_animator().get_action_phase()))
	if action == HeroAnimator.WHACK and body.get_animator().has_walking_feet():
		for foot: String in FEET:
			var bone: int = skeleton.find_bone(foot)
			if bone >= 0:
				skeleton.set_bone_pose_rotation(bone,body.get_animator().walking_leg_pose(foot))
	var free_motion: float = 1.0 if action.is_empty() else 0.12
	if action.is_empty() and swim_weight > 0.001:
		_swimming_feet()
		# Replace the moving clip's oscillation with one coherent wave. Keep its
		# gentle idle tail motion and the original idle paddling unchanged.
		for bone_name: String in ["spine","head","tail_1","tail_2","tail_3"]:
			var bone: int = skeleton.find_bone(bone_name)
			if bone < 0:
				continue
			var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
			var idle_weight: float = 0.22 if bone_name.begins_with("tail_") else 1.0
			var clip_weight: float = lerpf(1.0,idle_weight*(1.0-swim_drive),swim_weight)
			skeleton.set_bone_pose_rotation(bone,rest.slerp(skeleton.get_bone_pose_rotation(bone),clip_weight))
			_rotate(bone_name,Vector3.UP,swim_bend(bone_name,swim_phase,swim_drive)*swim_weight)
	if action in [HeroAnimator.ROLL,HeroAnimator.SPIN]:
		var phase: float = body.get_animator().get_action_phase()
		_aim_feet(1.0,smoothstep(0.0,0.12,phase)*(1.0-smoothstep(0.75,1.0,phase)))
	_rotate("head",Vector3.UP,_head_lead*0.50)
	_rotate("spine",Vector3.UP,_head_lead*0.22)
	for i: int in 3:
		_rotate("tail_%d" % (i+1),Vector3.UP,_bend[i])
		_rotate("tail_%d" % (i+1),Vector3.RIGHT,sin(_time*2.0-i*0.65)*0.015*swim_weight*free_motion)
	for i: int in 2:
		var side: float = 1.0 if i == 0 else -1.0
		_rotate("gill_l" if i == 0 else "gill_r",Vector3.FORWARD,side*sin(_time*3.0-i*0.8)*(0.025+swim_weight*0.025)*free_motion)
	for foot: int in 4:
		_place_foot(foot)

static func swim_foot_direction(foot: int, phase: float, drive: float) -> Vector3:
	var side: float = 1.0 if foot%2 == 0 else -1.0
	var cycle: float = TAU*(phase+[0.0,0.5,0.55,0.05][foot])
	var tread := Vector3(side*(0.34+0.06*sin(cycle)),-0.15+0.07*cos(cycle),0.10+0.10*sin(cycle))
	var kick := Vector3(side*(0.040+0.012*cos(cycle)),-0.035+0.008*sin(cycle),0.46+0.018*sin(cycle))
	return tread.lerp(kick,clampf(drive,0,1)).normalized()

static func swim_bend(bone: String, phase: float, drive: float) -> float:
	# Phase travels from torso to tail tip, with greater amplitude toward the fin.
	var wave: float = TAU*phase
	match bone:
		"spine": return sin(wave)*0.12*drive
		"head": return -sin(wave)*0.085*drive
		"tail_1": return sin(wave-0.80)*0.24*drive
		"tail_2": return sin(wave-1.60)*0.34*drive
		"tail_3": return sin(wave-2.40)*0.44*drive
	return 0.0

func _swimming_feet() -> void:
	_aim_feet(swim_drive,swim_weight)

func _aim_feet(drive: float, weight: float) -> void:
	var skeleton := get_skeleton()
	for foot: int in 4:
		var bone: int = skeleton.find_bone(FEET[foot])
		if bone < 0 or not _feet.has(FEET[foot]):
			continue
		var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
		var direction: Vector3 = skeleton.get_bone_global_rest(bone).basis.inverse()*swim_foot_direction(foot,swim_phase,drive)
		var aim := Quaternion((_feet[FEET[foot]] as Vector3).normalized(),direction.normalized())
		var pose: Quaternion = (rest*aim).normalized()
		skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_pose_rotation(bone).slerp(pose,weight))

static func contact_weight(phase: float) -> float:
	return smoothstep(0.0,0.05,phase)*(1.0-smoothstep(0.55,0.62,phase))

func _place_foot(foot: int) -> void:
	if is_inf(_foot_heights[foot]) or not _feet.has(FEET[foot]):
		_foot_planted[foot] = false
		return
	var animator := body.get_animator()
	var weight: float = contact_weight(fposmod(animator.get_gait_phase()-FOOT_PHASE[foot],1)) if animator.has_walking_feet() else 1.0
	var skeleton := get_skeleton()
	var bone: int = skeleton.find_bone(FEET[foot])
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_transform: Transform3D = skeleton.global_transform*(skeleton.get_bone_global_pose(parent) if parent >= 0 else Transform3D.IDENTITY)
	var pose: Transform3D = skeleton.get_bone_pose(bone)
	var current: Vector3 = foot_position(foot)
	var target: Vector3 = current
	var locomotion := animator.get_current_action().is_empty() and swim_weight < 0.1
	if weight < 0.1 or not locomotion:
		_foot_planted[foot] = false
	elif not _foot_planted[foot]:
		_foot_anchors[foot] = Vector3(current.x, _foot_heights[foot], current.z)
		_foot_planted[foot] = true
	if _foot_planted[foot]:
		var offset := _foot_anchors[foot] - current
		# This rig has one bone per leg: release unreachable anchors instead of
		# stretching the skin or leaving a foot behind through a sharp turn.
		if Vector2(offset.x, offset.z).length() > 0.28 or absf(turn_rate) > 2.5:
			_foot_planted[foot] = false
		else:
			target.x = _foot_anchors[foot].x
			target.z = _foot_anchors[foot].z
	target.y += clampf(_foot_heights[foot]-current.y,-0.08,0.08)
	var from: Vector3 = parent_transform.affine_inverse()*current-pose.origin
	var to: Vector3 = parent_transform.affine_inverse()*target-pose.origin
	if from.length_squared() < 0.0001 or to.length_squared() < 0.0001:
		return
	# One joint per limb: cap correction instead of stretching the imported skin.
	var correction := Quaternion(from.normalized(),to.normalized())
	var angle: float = correction.angle_to(Quaternion.IDENTITY)
	var limited: float = minf(1.0,0.38/maxf(angle,0.0001))*weight*(1.0-swim_weight)
	skeleton.set_bone_pose_rotation(bone,(Quaternion.IDENTITY.slerp(correction,limited)*skeleton.get_bone_pose_rotation(bone)).normalized())

func _rotate(bone_name: String, axis: Vector3, amount: float) -> void:
	var skeleton := get_skeleton()
	var bone: int = skeleton.find_bone(bone_name)
	if bone < 0:
		return
	var local_axis: Vector3 = (skeleton.get_bone_global_rest(bone).basis.inverse()*axis).normalized()
	skeleton.set_bone_pose_rotation(bone,(skeleton.get_bone_pose_rotation(bone)*Quaternion(local_axis,amount)).normalized())

func foot_position(index: int) -> Vector3:
	var skeleton := get_skeleton()
	var bone: int = skeleton.find_bone(FEET[index])
	if bone < 0 or not _feet.has(FEET[index]):
		return body.global_position+Vector3.DOWN*0.8
	return skeleton.global_transform*(skeleton.get_bone_global_pose(bone)*(_feet[FEET[index]] as Vector3))

func tail_position() -> Vector3:
	var skeleton := get_skeleton()
	var bone: int = skeleton.find_bone("tail_3")
	return skeleton.global_transform*(skeleton.get_bone_global_pose(bone)*Vector3(0,0.50,0)) if bone >= 0 else body.global_position

func _fit_feet() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for foot: String in FEET:
		var bone: int = skeleton.find_bone(foot)
		if bone < 0:
			continue
		var sum := Vector3.ZERO
		var weight_sum: float = 0.0
		for node: Node in model.find_children("*","MeshInstance3D",true,false):
			var instance := node as MeshInstance3D
			# Harness weights follow the legs, but equipment is not a foot contact.
			if instance.name == "ExplorerBackpack" or instance.skin == null or instance.mesh == null:
				continue
			var bind_index: int = -1
			for bind_id: int in instance.skin.get_bind_count():
				if String(instance.skin.get_bind_name(bind_id)) == foot or instance.skin.get_bind_bone(bind_id) == bone:
					bind_index = bind_id
			if bind_index < 0:
				continue
			for surface: int in instance.mesh.get_surface_count():
				var arrays: Array = instance.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				if vertices.is_empty() or bones.is_empty():
					continue
				var influences: int = bones.size()/vertices.size()
				for vertex: int in vertices.size():
					if vertices[vertex].y > instance.get_aabb().position.y+0.22:
						continue
					for slot: int in influences:
						var offset: int = vertex*influences+slot
						if bones[offset] == bind_index and weights[offset] > 0.35:
							sum += vertices[vertex]*weights[offset]
							weight_sum += weights[offset]
		var point: Vector3 = sum/weight_sum if weight_sum > 0 else Vector3(0.55 if foot.ends_with("l") else -0.55,0,-0.55 if foot.begins_with("leg_f") else 0.55)
		_feet[foot] = skeleton.get_bone_global_rest(bone).affine_inverse()*point
