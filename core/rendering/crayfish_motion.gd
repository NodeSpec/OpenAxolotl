extends Node3D
## Local habitat-aware wandering. The pickup Area moves with the visible animal.
enum Habitat { AUTO, SHORE, WATER }
@export var phase: float = 0.0
@export var habitat: Habitat = Habitat.AUTO
@export_range(.25,2.0) var roam_radius: float = 1.15
var _actor: Area3D
var _home:=Vector3.ZERO
var _goal:=Vector3.ZERO
var _time:=0.0
var _wait:=0.0
var _moving:=false
var _water:=false
var _initialized:=false
var _speed:=0.0
var _heading:=0.0
var _escape:=0.0
var _escape_cooldown:=0.0
var _stride:=0.0
var _normal:=Vector3.UP
var _rng:=RandomNumberGenerator.new()
var _waters: Array[WaterVolume]=[]
var _skeleton: Skeleton3D
var _bones: Dictionary={}
var _rest: Dictionary={}
var _axes: Dictionary={}
var _clearance:=SphereShape3D.new()

func _ready() -> void:
	position=Vector3.ZERO # Discard the old preview bob saved into scene instances.
	_actor=get_parent() as Area3D
	var skeletons:=find_children("*","Skeleton3D",true,false)
	if not skeletons.is_empty():
		_skeleton=skeletons[0] as Skeleton3D
		for i: int in _skeleton.get_bone_count():
			var name:=_skeleton.get_bone_name(i)
			_bones[name]=i;_rest[name]=_skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
			_axes[name]=_skeleton.get_bone_global_rest(i).basis.inverse()
	_heading=phase*1.73
	_rng.seed=abs(int(phase*10007.0))+19427

func _physics_process(delta: float) -> void:
	_time+=delta
	if not _initialized and _time>.07:_initialize_habitat()
	if _initialized and _actor!=null:_wander(delta)
	_animate(delta)

func _initialize_habitat() -> void:
	for node: Node in get_tree().get_nodes_in_group("water_volumes"):
		if node is WaterVolume:_waters.append(node as WaterVolume)
	_home=_actor.global_position if _actor!=null else global_position
	_rng.seed=absi(hash(_home)+int(phase*10007.))+19427
	_water=habitat==Habitat.WATER or (habitat==Habitat.AUTO and _water_at(_home)!=null)
	_clearance.radius=.28 if _water else .15
	_goal=_home;_wait=_rng.randf_range(.4,2.4)
	if not _water and _actor!=null:
		var ground:=_ground_at(_home)
		if not ground.is_empty():
			_actor.global_position.y=(ground["position"] as Vector3).y-.012
			_home=_actor.global_position;_normal=ground["normal"]
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		mesh.set_instance_shader_parameter("wetness",1.0 if _water else 0.0)
	_initialized=true

func _water_at(point: Vector3) -> WaterVolume:
	for water: WaterVolume in _waters:
		if is_instance_valid(water) and water.contains_point(point,-.18) and point.y<water.surface_at(point)-.10:return water
	return null

func _excluded() -> Array[RID]:
	var out: Array[RID]=[]
	var hero:=get_tree().get_first_node_in_group("player") as CollisionObject3D
	if hero!=null:out.append(hero.get_rid())
	return out

func _ground_at(point: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.5,point+Vector3.DOWN*.85,1,_excluded())
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit["collider"] is StaticBody3D or (hit["normal"] as Vector3).y<.82:return {}
	return hit

func _safe_point(point: Vector3) -> Dictionary:
	if Vector2(point.x-_home.x,point.z-_home.z).length()>roam_radius+.001:return {}
	if _water:
		if absf(point.y-_home.y)>.26 or _water_at(point)==null:return {}
	else:
		var ground:=_ground_at(point)
		if ground.is_empty():return {}
		point.y=(ground["position"] as Vector3).y-.012
		if absf(point.y-_home.y)>.28 or _water_at(point+Vector3.DOWN*.13)!=null:return {}
		# Four feet-support samples reject banks and narrow rock lips.
		for offset: Vector3 in [Vector3(.21,0,.22),Vector3(-.21,0,.22),Vector3(.21,0,-.22),Vector3(-.21,0,-.22)]:
			var edge:=_ground_at(point+offset)
			if edge.is_empty() or absf((edge["position"] as Vector3).y-point.y)>.14:return {}
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=_clearance;query.collision_mask=1;query.exclude=_excluded();query.transform.origin=point+Vector3.UP*(.12 if _water else .18)
	if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return {}
	return {"point":point}

func _clear_path(from: Vector3,to: Vector3) -> bool:
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=_clearance;query.collision_mask=1;query.exclude=_excluded();query.transform.origin=from+Vector3.UP*(.12 if _water else .18);query.motion=to-from
	var travel:=get_world_3d().direct_space_state.cast_motion(query)
	return travel[0]>.995

func _choose_goal() -> void:
	for attempt: int in 14:
		var angle:=_rng.randf()*TAU;var radius:=sqrt(_rng.randf())*roam_radius*.9
		var candidate:=_home+Vector3(cos(angle)*radius,_rng.randf_range(-.19,.19) if _water else 0.,sin(angle)*radius)
		var result:=_safe_point(candidate)
		if result.is_empty():continue
		candidate=result["point"]
		if _actor.global_position.distance_to(candidate)<.22 or not _clear_path(_actor.global_position,candidate):continue
		_goal=candidate;_moving=true;return
	_wait=_rng.randf_range(.7,1.5)

func _wander(delta: float) -> void:
	_escape_cooldown=maxf(0.,_escape_cooldown-delta)
	_escape=maxf(0.,_escape-delta)
	var hero:=get_tree().get_first_node_in_group("player") as Node3D
	var distance:=hero.global_position.distance_to(_actor.global_position) if hero!=null else INF
	# Never turn a friendly pickup into a frustrating chase at collection distance.
	if distance<.95:
		_moving=false;_wait=maxf(_wait,.65)
	elif _water and distance<1.9 and _escape_cooldown<=0.:
		var away:=(_actor.global_position-hero.global_position).normalized()
		var result:=_safe_point(_actor.global_position+away*.38)
		if not result.is_empty() and _clear_path(_actor.global_position,result["point"]):
			_goal=result["point"];_moving=true;_escape=.50;_escape_cooldown=7.
	if not _moving:
		_speed=move_toward(_speed,0.,delta*1.4);_wait-=delta
		if _wait<=0. and distance>=.95:_choose_goal()
		return
	var difference:=_goal-_actor.global_position
	if difference.length()<.045:
		_moving=false;_wait=_rng.randf_range(1.0,3.3);return
	var desired_speed:=.27 if _water else .17
	if _escape>0.:desired_speed=.70
	_speed=move_toward(_speed,desired_speed,delta*.8)
	var step:=difference.normalized()*minf(_speed*delta,difference.length())
	var candidate:=_safe_point(_actor.global_position+step)
	if candidate.is_empty() or not _clear_path(_actor.global_position,candidate.get("point",_actor.global_position)):
		_moving=false;_wait=.65;_speed=0.;return
	_actor.global_position=candidate["point"]
	var direction:=difference.normalized()*(-1. if _escape>0. else 1.)
	_heading=rotate_toward(_heading,atan2(-direction.x,-direction.z),delta*1.8)
	if not _water:
		var ground:=_ground_at(_actor.global_position)
		if not ground.is_empty():_normal=_normal.lerp(ground["normal"],1.-exp(-delta*8.)).normalized()

func _rotate_bone(name: String,axis: Vector3,angle: float) -> void:
	if not _bones.has(name):return
	var local_axis: Vector3=(_axes[name] as Basis)*axis
	_skeleton.set_bone_pose_rotation(int(_bones[name]),(_rest[name] as Quaternion)*Quaternion(local_axis.normalized(),angle))

func _animate(delta: float) -> void:
	_stride+=delta*(_speed*36. if not _water else 4.2+_speed*5.)
	var forward:=Vector3(-sin(_heading),0,-cos(_heading))
	var up:=Vector3.UP if _water else _normal
	var right:=forward.cross(up).normalized();basis=Basis(right,up,right.cross(up)).orthonormalized().scaled(scale)
	# Small swimming pitch comes from the tail cycle; shore bodies remain grounded.
	if _water:rotate_object_local(Vector3.RIGHT,sin(_time*1.6+phase)*.028)
	for side: String in ["L","R"]:
		var sign_value: float=1. if side=="L" else -1.
		for i: int in 4:
			var cycle:=_stride+float(i)*PI*.72+(PI if side=="R" else 0.)
			var swing:=sin(cycle)*(.17 if _water else .27)*clampf(_speed/.13,0.,1.)
			if _water:swing+=sin(cycle)*.085
			var bone:="Leg"+side+str(i)
			_rotate_bone(bone,Vector3.UP,swing)
			if _bones.has(bone):
				var lift:=maxf(0.,cos(cycle))*(.22 if _water else .18)*clampf(_speed/.10,0.,1.)
				var axis: Vector3=(_axes[bone] as Basis)*Vector3.FORWARD
				_skeleton.set_bone_pose_rotation(int(_bones[bone]),_skeleton.get_bone_pose_rotation(int(_bones[bone]))*Quaternion(axis.normalized(),sign_value*lift))
		var forage:=.5+.5*sin(_time*1.1+phase+sign_value)
		_rotate_bone("Claw"+side,Vector3.UP,sign_value*(.04+.09*sin(_time*1.7+phase+sign_value)))
		_rotate_bone("Pincer"+side,Vector3.UP,sign_value*(.035+.19*forage))
		_rotate_bone("Antenna"+side,Vector3.UP,sign_value*(.07*sin(_time*1.8+phase)+.045*sin(_time*3.1)))
		_rotate_bone("Eye"+side,Vector3.UP,.10*sin(_time*.75+phase+sign_value))
	for i: int in 6:
		var curl:=sin(_time*2.2+phase-float(i)*.45)*(.025 if _water else .006)
		if _escape>0.:curl+=sin((_escape/.5)*PI)*.19
		_rotate_bone("Tail%d"%i,Vector3.RIGHT,curl)

func is_swimming() -> bool:return _water
func home_position() -> Vector3:return _home
func movement_speed() -> float:return _speed

