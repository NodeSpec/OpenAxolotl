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

## --- Legs with joints (REQ-002 AC-9) ----------------------------------------
##
## A rig extended by tools/extend_hero_rig.py carries upper, shin, foot and toe
## bones under each leg. Where they are present a foot is PLACED: it lands on a point
## of ground, stays on that point while the body travels over it, and lifts
## when the leg can no longer reach. Where they are absent everything below
## falls through to `_place_foot`, the bounded one-bone correction this file
## has always had, unchanged.
##
## Presentation only, like the rest of this modifier: it reads the body's
## velocity and the ground under the feet and writes transient bone poses. It
## never moves the capsule, and the only thing it hands back to the body is the
## few centimetres of `visual_offset` every posture here already uses.
const UPPERS: Array[String] = ["upper_fl","upper_fr","upper_bl","upper_br"]
const SHINS: Array[String] = ["shin_fl","shin_fr","shin_bl","shin_br"]
const ANKLES: Array[String] = ["foot_fl","foot_fr","foot_bl","foot_br"]
const TOES: Array[String] = ["toe_fl","toe_fr","toe_bl","toe_br"]

enum {FOOT_FREE, FOOT_STANCE, FOOT_SWING}

## How far the body settles toward the ground once it is walking, in metres.
## A leg sculpted almost straight has nowhere to reach from standing height;
## these three centimetres are what buy a stride, and a scurrying animal
## carries itself low anyway.
const CROUCH := 0.03

## Feet stand a little inside where the sculpt happens to have left them, and
## the same distance out on both sides: the sculpt is frozen mid-stride, and a
## stance copied from it would limp.
const STANCE_WIDTH := 0.9

## How far ahead of or behind its own pivot a foot's resting place may sit, in
## the model's units. A leg reaches equally far both ways only from under its
## pivot, so every bit of this is paid for in stride.
const HOME_LEAD := 0.10

## A standing foot this far from where it belongs takes a step to get there.
const IDLE_TOLERANCE := 0.05
const IDLE_STEP_SECONDS := 0.14

## How high a foot clears the ground mid-step, walking and at a scurry, and
## how far it tips: toe down as it leaves and toe up as it arrives.
const STEP_LIFT := 0.045
const STEP_LIFT_FAST := 0.075
const TOE_PITCH := 0.30

## A planted foot further than this from its place has been left behind by a
## teleport, not by a step.
const ABANDON_DISTANCE := 0.9

## Walk cycles per second the waddle clip's body sway was drawn for. Faster
## than this the sway keeps its tempo and gives up amplitude: a spine swinging
## twelve centimetres five times a second is a vibration, not a walk.
const SWAY_CADENCE := 1.8

var _chains: Array[Dictionary] = [{},{},{},{}]
var _foot_state: Array[int] = [FOOT_FREE,FOOT_FREE,FOOT_FREE,FOOT_FREE]
var _foot_weight: Array[float] = [0.0,0.0,0.0,0.0]
var _foot_from: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var _foot_now: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var _foot_probe: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var _foot_lift_phase: Array[float] = [0.0,0.0,0.0,0.0]
var _foot_last_phase: Array[float] = [0.0,0.0,0.0,0.0]
var _foot_swing: Array[float] = [0.0,0.0,0.0,0.0]
var _foot_timed: Array[bool] = [false,false,false,false]
var _foot_drive: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var _grounded: bool = false
var _planar := Vector3.ZERO
var _crouch: float = 0.0

func bind(owner_body: AxolotlBody, visual: Node3D) -> void:
	body = owner_body
	model = visual
	_fit_feet()
	_fit_chains()
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
	_crouch = 0.0
	_release_feet()

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
	_grounded = grounded
	_planar = Vector3(relative_velocity.x,0.0,relative_velocity.z)
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
	# Legs that can bend need somewhere to bend from: walking carries the body
	# a little lower, eased in so starting to move never drops it.
	var walking_low: bool = has_leg_chains() and grounded and not in_water and action.is_empty()
	_crouch = lerpf(_crouch,CROUCH*smoothstep(0.15,0.8,_planar.length()) if walking_low else 0.0,1.0-exp(-delta*10))
	visual_offset -= _crouch
	for foot: int in 4:
		_foot_heights[foot] = INF
		if not grounded or in_water or not action.is_empty(): _foot_planted[foot] = false
		if body != null and body.is_inside_tree() and grounded and not in_water and action not in ["roll","dance"]:
			# A placed foot asks about the ground where it IS or is about to
			# be, which is not where the clip would have put it.
			var point: Vector3 = _foot_probe[foot] if _foot_state[foot] != FOOT_FREE else foot_position(foot)
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

func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or body == null:
		return
	var action: String = body.get_animator().get_current_action()
	if action == HeroAnimator.DANCE:
		_release_feet()
		return
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
	if has_leg_chains():
		_retarget_legs(skeleton)
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
	if has_leg_chains():
		_settle_sway(skeleton)
		for foot: int in 4:
			_step_leg(foot,delta)
	else:
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
		var reach: Vector3 = _feet[FEET[foot]]
		if not _chains[foot].is_empty():
			# Swing the limb about the shoulder it grows from, not about the
			# pivot buried in the body, so it stays attached where it leaves.
			bone = int(_chains[foot]["upper"])
			reach = _chains[foot]["reach"]
		var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
		var direction: Vector3 = skeleton.get_bone_global_rest(bone).basis.inverse()*swim_foot_direction(foot,swim_phase,drive)
		var aim := Quaternion(reach.normalized(),direction.normalized())
		var pose: Quaternion = (rest*aim).normalized()
		skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_pose_rotation(bone).slerp(pose,weight))
		# A paddling limb is not a ramrod: where there is a shin, it folds on
		# the recovery and opens on the push, and trails nearly straight once
		# the tail is doing the work.
		if not _chains[foot].is_empty():
			var cycle: float = TAU*(swim_phase+[0.0,0.5,0.55,0.05][foot])
			_fold_shin(foot,weight*lerpf(0.42+0.26*sin(cycle-0.9),0.16,clampf(drive,0,1)))

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
	if not _chains[index].is_empty():
		# Where the foot was last PUT, while it is being put anywhere: outside
		# the skeleton's own update the bones only remember the clip.
		if _foot_weight[index] > 0.0:
			return _foot_now[index]
		return skeleton.global_transform*skeleton.get_bone_global_pose(int(_chains[index]["toe"])).origin
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
		# A rig that carries its own contact bone has already answered this,
		# exactly; fitting it again from skin weights could only be less right.
		var toe: int = skeleton.find_bone("toe_"+foot.trim_prefix("leg_"))
		if toe >= 0:
			_feet[foot] = skeleton.get_bone_global_rest(bone).affine_inverse()*skeleton.get_bone_global_rest(toe).origin
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


# --- Legs with joints ---------------------------------------------------------

func has_leg_chains() -> bool:
	return not _chains[0].is_empty()


## [elbow, ankle] for a two-bone limb rooted at `root` and reaching for
## `target`, its middle joint leaning toward `pole`.
##
## The reach is clamped rather than refused: a target too far away gets the
## limb at full stretch along the way to it, and one too close gets it folded
## as far as its two lengths allow. The lengths themselves never change, which
## is the difference between a leg bending and a skin stretching.
static func solve_leg(root: Vector3, target: Vector3, upper: float, lower: float, pole: Vector3) -> Array[Vector3]:
	var to_target := target-root
	var along: Vector3 = to_target.normalized() if to_target.length_squared() > 0.0000001 else Vector3.DOWN
	var distance: float = clampf(to_target.length(),absf(upper-lower)+0.0005,(upper+lower)*0.999)
	var bend := pole-along*pole.dot(along)
	if bend.length_squared() < 0.0000001:
		bend = along.cross(Vector3.RIGHT)
		if bend.length_squared() < 0.0000001:
			bend = along.cross(Vector3.UP)
	bend = bend.normalized()
	var reach: float = (upper*upper+distance*distance-lower*lower)/(2.0*distance)
	var rise: float = sqrt(maxf(0.0,upper*upper-reach*reach))
	return [root+along*reach+bend*rise,root+along*distance]


## Half the length of ground a foot can stay planted over, for a leg whose
## pivot sits `height` above its ankle and `aside` from it. Zero when the foot
## cannot reach that far out at all.
static func stride_reach(upper: float, lower: float, height: float, aside: float) -> float:
	var limb: float = (upper+lower)*0.999
	return sqrt(maxf(0.0,limb*limb-height*height-aside*aside))


## How far the body can travel over this foot while it stays planted at a
## walk, in metres: the length of ground, centred on where the foot stands,
## that the leg can reach from the height the body walks at. `world_per_unit`
## is the model's scale, since a rig is measured in its own units.
func planted_span(foot: int, world_per_unit: float) -> float:
	var chain: Dictionary = _chains[foot]
	if chain.is_empty():
		return 0.0
	var pivot: Vector3 = chain["pivot"]
	var ankle: Vector3 = (chain["home"] as Vector3)-(chain["sole"] as Vector3)
	var reach: float = stride_reach(float(chain["l1"]),float(chain["l2"]),
		pivot.y-ankle.y-CROUCH/world_per_unit,absf(ankle.x-pivot.x))
	return maxf(0.0,reach-absf(ankle.z-pivot.z))*2.0*world_per_unit


func _fit_chains(given: Skeleton3D = null) -> void:
	# A modifier only knows its skeleton once it is in the tree; a caller that
	# already holds one may hand it over.
	var skeleton: Skeleton3D = given if given != null else get_skeleton()
	_chains = [{},{},{},{}]
	if skeleton == null:
		return
	var fitted: Array[Dictionary] = [{},{},{},{}]
	for foot: int in 4:
		var base: int = skeleton.find_bone(FEET[foot])
		var upper: int = skeleton.find_bone(UPPERS[foot])
		var shin: int = skeleton.find_bone(SHINS[foot])
		var ankle: int = skeleton.find_bone(ANKLES[foot])
		var toe: int = skeleton.find_bone(TOES[foot])
		# All four legs or none: a walk with three placed feet and one swung
		# one is worse than either.
		if base < 0 or upper < 0 or shin < 0 or ankle < 0 or toe < 0:
			return
		var pivot: Vector3 = skeleton.get_bone_global_rest(upper).origin
		var elbow: Vector3 = skeleton.get_bone_global_rest(shin).origin
		var heel: Vector3 = skeleton.get_bone_global_rest(ankle).origin
		var contact: Vector3 = skeleton.get_bone_global_rest(toe).origin
		var side: float = 1.0 if pivot.x >= 0.0 else -1.0
		fitted[foot] = {
			"base":base,"upper":upper,"shin":shin,"ankle":ankle,"toe":toe,
			"l1":pivot.distance_to(elbow),"l2":elbow.distance_to(heel),
			"pivot":pivot,"contact":contact,"sole":contact-heel,
			"reach":skeleton.get_bone_global_rest(upper).affine_inverse()*contact,
			"basis":skeleton.get_bone_global_rest(ankle).basis.orthonormalized(),
			# Sprawled, the way a salamander stands: elbows out, up and back,
			# knees out, up and forward. The model faces -Z.
			"pole":Vector3(side*0.55,0.75,0.35 if foot < 2 else -0.35).normalized(),
		}
	for pair: Array in [[0,1],[2,3]]:
		var left: Dictionary = fitted[pair[0]]
		var right: Dictionary = fitted[pair[1]]
		var out: float = minf(absf((left["contact"] as Vector3).x),absf((right["contact"] as Vector3).x))*STANCE_WIDTH
		# With the ANKLES under the shoulders, not where the sculpt's feet
		# happen to be: its front-left foot is reaching a full hand's length
		# ahead. A leg reaches as far forward as back only from under its own
		# shoulder, and the pair shares one line so the walk does not limp.
		var along: float = ((left["pivot"] as Vector3).z+(right["pivot"] as Vector3).z \
			+(left["sole"] as Vector3).z+(right["sole"] as Vector3).z)*0.5
		for foot: int in pair:
			var pivot: Vector3 = fitted[foot]["pivot"]
			var under: float = pivot.z+(fitted[foot]["sole"] as Vector3).z
			fitted[foot]["home"] = Vector3(
				(1.0 if pivot.x >= 0.0 else -1.0)*out,
				(fitted[foot]["contact"] as Vector3).y,
				clampf(along,under-HOME_LEAD,under+HOME_LEAD))
	_chains = fitted


## Clips key the leg on `leg_xx`, a pivot inside the body. On a rig with a real
## shoulder the same swing is handed to `upper_xx`, so the limb turns where it
## is attached instead of sweeping its root across the skin. The two bones
## share a rest frame, so the rotation carries over as it is.
func _retarget_legs(skeleton: Skeleton3D) -> void:
	for chain: Dictionary in _chains:
		var base: int = chain["base"]
		var upper: int = chain["upper"]
		var rest: Quaternion = skeleton.get_bone_rest(base).basis.get_rotation_quaternion()
		var swing: Quaternion = rest.inverse()*skeleton.get_bone_pose_rotation(base)
		skeleton.set_bone_pose_rotation(base,rest)
		skeleton.set_bone_pose_rotation(upper,(skeleton.get_bone_rest(upper).basis.get_rotation_quaternion()*swing).normalized())


func _release_feet() -> void:
	for foot: int in 4:
		_foot_state[foot] = FOOT_FREE
		_foot_weight[foot] = 0.0
		_foot_timed[foot] = false


## The waddle clip's sway was drawn for a slow cycle. Keep it at the tempo the
## feet now step at, and take its amplitude down as that tempo climbs.
func _settle_sway(skeleton: Skeleton3D) -> void:
	var animator := body.get_animator()
	if animator.get_current_clip() != HeroAnimator.WADDLE or not animator.get_current_action().is_empty():
		return
	var cadence: float = animator.get_gait_cadence()
	if cadence <= SWAY_CADENCE:
		return
	var keep: float = clampf(SWAY_CADENCE/cadence,0.3,1.0)
	for bone_name: String in ["root","spine","head","tail_1","tail_2","tail_3"]:
		var bone: int = skeleton.find_bone(bone_name)
		if bone < 0:
			continue
		var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(bone,rest.slerp(skeleton.get_bone_pose_rotation(bone),keep))


func _set_global_basis(skeleton: Skeleton3D, bone: int, wanted: Basis) -> void:
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	skeleton.set_bone_pose_rotation(bone,(parent_basis.inverse()*wanted).orthonormalized().get_rotation_quaternion())


## How much of a fold the upper leg gives back by leaning the other way, so the
## foot stays on the line the limb was aimed along and only the elbow moves.
const FOLD_COUNTER := 0.55

## Folds the leg at its middle joint by `angle`, elbow toward the pole, on top
## of wherever the limb has already been aimed. The foot keeps the direction
## it was aimed in: the paddling directions were tuned on a straight limb and
## a fold that swung the foot off them would retune them by accident.
func _fold_shin(foot: int, angle: float) -> void:
	var skeleton := get_skeleton()
	var chain: Dictionary = _chains[foot]
	var upper: Transform3D = skeleton.get_bone_global_pose(int(chain["upper"]))
	var shin: Transform3D = skeleton.get_bone_global_pose(int(chain["shin"]))
	var along: Vector3 = (shin.origin-upper.origin).normalized()
	var pole: Vector3 = chain["pole"]
	var hinge: Vector3 = along.cross(pole-along*pole.dot(along))
	if hinge.length_squared() < 0.000001:
		return
	hinge = hinge.normalized()
	_set_global_basis(skeleton,int(chain["upper"]),Basis(hinge,angle*FOLD_COUNTER)*upper.basis.orthonormalized())
	shin = skeleton.get_bone_global_pose(int(chain["shin"]))
	_set_global_basis(skeleton,int(chain["shin"]),Basis(hinge,-angle)*shin.basis.orthonormalized())


## Whether the leg could put its toe on this point of the world right now.
func _within_reach(foot: int, to_skeleton: Transform3D, toe: Vector3, slack: float) -> bool:
	var chain: Dictionary = _chains[foot]
	var root: Vector3 = get_skeleton().get_bone_global_pose(int(chain["upper"])).origin
	var ankle: Vector3 = to_skeleton*toe-(chain["sole"] as Vector3)
	return root.distance_to(ankle) <= (float(chain["l1"])+float(chain["l2"]))*slack


func _neighbour_stepping(foot: int) -> bool:
	# The foot across the body and the foot ahead or behind on the same side.
	# The diagonal partner is free to go at the same moment; that is a trot.
	return _foot_state[foot^1] == FOOT_SWING or _foot_state[(foot+2)%4] == FOOT_SWING


func _step_leg(foot: int, delta: float) -> void:
	var skeleton := get_skeleton()
	var chain: Dictionary = _chains[foot]
	var animator := body.get_animator()
	var action: String = animator.get_current_action()
	var to_world: Transform3D = skeleton.global_transform
	var to_skeleton: Transform3D = to_world.affine_inverse()
	var ground: float = _foot_heights[foot]
	var clip_toe: Vector3 = to_world*skeleton.get_bone_global_pose(int(chain["toe"])).origin

	# Locomotion only. Every action moves the body in ways a stance was not
	# fitted for — the tail whack swings the hips through a hundred degrees —
	# so the feet go back to the clip for its length and re-take the ground
	# after it.
	var placing: bool = _grounded and swim_weight < 0.1 and not is_inf(ground) and action.is_empty()
	if not placing:
		_foot_state[foot] = FOOT_FREE
		_foot_timed[foot] = false
	_foot_weight[foot] = move_toward(_foot_weight[foot],1.0 if placing else 0.0,delta/(0.10 if placing else 0.08))
	if _foot_weight[foot] <= 0.0:
		return

	var target: Vector3 = _foot_now[foot]
	var pitch: float = 0.0
	if placing:
		var home: Vector3 = to_world*(chain["home"] as Vector3)
		home.y = ground
		var anchor: Vector3 = _foot_anchors[foot]
		if _foot_state[foot] == FOOT_FREE or Vector2(anchor.x-home.x,anchor.z-home.z).length() > ABANDON_DISTANCE:
			# Taking the ground for the first time since a jump, a swim or a
			# respawn: stand where the clip has the foot and step from there.
			_foot_state[foot] = FOOT_STANCE
			_foot_timed[foot] = false
			anchor = Vector3(clip_toe.x,ground,clip_toe.z)
		anchor.y = ground

		var walking: bool = animator.has_walking_feet() and _planar.length() > HeroAnimator.MOVING_SPEED
		var phase: float = fposmod(animator.get_gait_phase()-FOOT_PHASE[foot],1.0)
		var landing: Vector3 = home
		var swing: float = 0.0
		if walking:
			var duty: float = animator.get_gait_duty()
			var cadence: float = maxf(animator.get_gait_cadence(),0.1)
			# Land ahead of home by half a stance, so the body is over the foot
			# at mid-stance — and no further ahead than the leg can reach.
			var ahead: Vector3 = _planar*(duty/cadence)*0.5
			var fraction: float = 1.0
			for attempt: int in 5:
				if _within_reach(foot,to_skeleton,home+ahead*fraction,0.97):
					break
				fraction -= 0.2
			landing = home+ahead*maxf(fraction,0.0)
			if _foot_state[foot] == FOOT_STANCE:
				# Lift when the cycle says so, or sooner when the leg has run
				# out: a foot that cannot stay is let go, never dragged.
				if phase >= duty or not _within_reach(foot,to_skeleton,anchor,0.998):
					_foot_state[foot] = FOOT_SWING
					_foot_from[foot] = anchor
					_foot_lift_phase[foot] = phase
					# A lifting foot is being carried by the body, so it leaves
					# the ground already moving with it.
					_foot_drive[foot] = _planar*((1.0-phase)/cadence)
			elif _foot_timed[foot]:
				_foot_timed[foot] = false
				_foot_from[foot] = _foot_now[foot]
				_foot_lift_phase[foot] = phase
				_foot_drive[foot] = Vector3.ZERO
			elif phase < _foot_last_phase[foot]-0.25:
				_foot_state[foot] = FOOT_STANCE
				anchor = landing
			if _foot_state[foot] == FOOT_SWING:
				swing = clampf((phase-_foot_lift_phase[foot])/maxf(0.05,1.0-_foot_lift_phase[foot]),0.0,1.0)
				# Aim at where the landing spot will BE when the foot gets
				# there. Chasing where it is now would bring the foot in at the
				# body's speed and skate it onto the ground.
				landing += _planar*((1.0-phase)/cadence)
		else:
			if _foot_state[foot] == FOOT_STANCE:
				if Vector2(anchor.x-home.x,anchor.z-home.z).length() > IDLE_TOLERANCE and not _neighbour_stepping(foot):
					_foot_state[foot] = FOOT_SWING
					_foot_timed[foot] = true
					_foot_from[foot] = anchor
					_foot_swing[foot] = 0.0
					_foot_drive[foot] = Vector3.ZERO
			elif not _foot_timed[foot]:
				# Caught mid-step by the animal stopping: finish the step, to
				# where a standing foot belongs.
				_foot_timed[foot] = true
				_foot_from[foot] = _foot_now[foot]
				_foot_swing[foot] = 0.0
				_foot_drive[foot] = Vector3.ZERO
			if _foot_state[foot] == FOOT_SWING:
				_foot_swing[foot] += delta/IDLE_STEP_SECONDS
				swing = _foot_swing[foot]
				if swing >= 1.0:
					_foot_state[foot] = FOOT_STANCE
					_foot_timed[foot] = false
					anchor = home
		_foot_last_phase[foot] = phase
		_foot_anchors[foot] = anchor

		if _foot_state[foot] == FOOT_SWING:
			# Leaves at the body's speed and ARRIVES STILL: a foot that reaches
			# the ground with no speed over it is the whole of not skating.
			var eased: float = swing*swing*(3.0-2.0*swing)
			var from: Vector3 = _foot_from[foot]
			var carried: float = swing*(1.0-swing)*(1.0-swing)
			var lift: float = lerpf(STEP_LIFT,STEP_LIFT_FAST,smoothstep(0.5,3.5,_planar.length()))
			target = from.lerp(landing,eased)+_foot_drive[foot]*carried
			target.y = lerpf(from.y,landing.y,eased)+lift*pow(sin(PI*swing),0.65)
			pitch = -sin(TAU*swing)*TOE_PITCH
			_foot_probe[foot] = landing
		else:
			target = anchor
			_foot_probe[foot] = anchor

	# Ease between the clip's foot and the placed one, so taking and leaving
	# the ground is a blend rather than a cut.
	var weight: float = _foot_weight[foot]
	var toe: Vector3 = to_skeleton*clip_toe.lerp(target,weight)
	var flat: Basis = Basis(Vector3.RIGHT,pitch)*(chain["basis"] as Basis)
	var sole: Vector3 = Basis(Vector3.RIGHT,pitch)*(chain["sole"] as Vector3)
	var upper: Transform3D = skeleton.get_bone_global_pose(int(chain["upper"]))
	var solved: Array[Vector3] = solve_leg(upper.origin,toe-sole,float(chain["l1"]),float(chain["l2"]),chain["pole"])

	var shin_rest: Transform3D = skeleton.get_bone_rest(int(chain["shin"]))
	var aim_upper := Quaternion((upper.basis*shin_rest.origin).normalized(),(solved[0]-upper.origin).normalized())
	_set_global_basis(skeleton,int(chain["upper"]),Basis(aim_upper)*upper.basis.orthonormalized())

	var shin: Transform3D = skeleton.get_bone_global_pose(int(chain["shin"]))
	var ankle_rest: Transform3D = skeleton.get_bone_rest(int(chain["ankle"]))
	var aim_shin := Quaternion((shin.basis*ankle_rest.origin).normalized(),(solved[1]-shin.origin).normalized())
	_set_global_basis(skeleton,int(chain["shin"]),Basis(aim_shin)*shin.basis.orthonormalized())

	var ankle: Transform3D = skeleton.get_bone_global_pose(int(chain["ankle"]))
	_set_global_basis(skeleton,int(chain["ankle"]),ankle.basis.orthonormalized().slerp(flat,weight))
	_foot_now[foot] = to_world*skeleton.get_bone_global_pose(int(chain["toe"])).origin
