class_name HeroSurfaceEffects
extends Node

var footfalls: int = 0
var sand_steps: int = 0
var wet_steps: int = 0
var bubble_bursts: int = 0
var slide_contacts: int = 0
var _slide_distance: float = 0.0
var _sliding: bool = false
var _current_strength: float = 0.0
var _current: MeshInstance3D
var _grit_mesh: SphereMesh
var _body: AxolotlBody
var _phase: float = 0.0
var _walking: bool = false
var _grounded: bool = true
var _last_velocity := Vector3.ZERO
var _last_position := Vector3.ZERO
var _spin: bool = false
var _bubble_clock: float = 0.0
var _clock: float = 0.0
var _marks: Array[WeakRef] = []
var _ribbon: MeshInstance3D
var _tail_points: Array[Vector3] = []
var _tail_times: Array[float] = []
var _tail_contacted: bool = false
var _droplet_mesh: SphereMesh

func _ready() -> void:
	process_physics_priority = 20
	_body = get_parent() as AxolotlBody
	if _body != null:
		_last_position = _body.global_position
	_droplet_mesh = SphereMesh.new()
	_droplet_mesh.radius = 0.5
	_droplet_mesh.height = 1.0
	_droplet_mesh.radial_segments = 8
	_droplet_mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.10
	_droplet_mesh.material = material
	_grit_mesh = _droplet_mesh.duplicate() as SphereMesh
	var grit_material := material.duplicate() as StandardMaterial3D
	grit_material.roughness = 1.0
	_grit_mesh.material = grit_material

static func crossed_contact(previous: float, current: float, offset: float) -> bool:
	return fposmod(current-offset,1.0) < fposmod(previous-offset,1.0)

func _physics_process(delta: float) -> void:
	if _body == null or _body.get_visual_motion() == null:
		return
	_clock += delta
	var teleported: bool = _body.global_position.distance_to(_last_position) > 4.0
	_last_position = _body.global_position
	if teleported:
		_walking = false
		_tail_points.clear()
		_tail_times.clear()
		_grounded = _body.is_on_floor()
		_current_strength = 0.0
		_sliding = false
		_slide_distance = 0.0
	var animator := _body.get_animator()
	var walking: bool = not _body.is_in_water() and _body.is_on_floor() and animator.has_walking_feet()
	var phase: float = animator.get_gait_phase()
	if walking and _walking:
		for foot: int in 4:
			if crossed_contact(_phase,phase,HeroMotion.FOOT_PHASE[foot]):
				_touch(foot,1.0)
	_phase = phase
	_walking = walking
	if _body.is_on_floor() and not _grounded and not _body.is_in_water() and not teleported:
		var impact: float = clampf(-_last_velocity.y/8.0,0.5,2.0)
		_touch(0,impact)
		_touch(1,impact)
	_grounded = _body.is_on_floor()
	_last_velocity = _body.velocity
	var spin: bool = _body.get_controller().get_spin_sprint().is_active()
	var water: WaterVolume = _body.get_water_volume()
	if spin and water != null and _body.is_in_water() and not teleported:
		_bubble_clock -= delta
		if _bubble_clock <= 0.0:
			_bubble_clock = 0.070
			_spin_bubbles()
		var surface: float = water.surface_at(_body.global_position)
		if not _spin and absf(surface-_body.global_position.y) < 0.65:
			WaterSplash.erupt(self,Vector3(_body.global_position.x,surface,_body.global_position.z),4.0,false)
	else:
		_bubble_clock = 0.0
	_spin = spin
	_update_current(delta,spin and water != null and _body.is_in_water() and not teleported)
	_update_slide(delta,animator,teleported)
	_update_tail(animator)

func _touch(foot: int, strength: float) -> void:
	var point: Vector3 = _body.get_visual_motion().foot_position(foot)
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.45,point+Vector3.DOWN*0.55,_body.collision_mask,[_body.get_rid()])
	var hit: Dictionary = _body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var position: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	if normal.y < 0.5:
		return
	footfalls += 1
	var water: WaterVolume = _body.get_water_volume()
	if water != null and water.surface_at(position) > position.y+0.025:
		wet_steps += 1
		position.y = water.surface_at(position)+0.025
		WaterSplash.trail(self,position,_body.velocity*strength,false)
		return
	var collider := hit["collider"] as Node
	if collider == null or not (collider.is_in_group("surface_sand") or collider.get_meta("footstep_surface","") == "sand"):
		return
	sand_steps += 1
	_sand(position,normal,strength)
	_footprint(position,normal,foot)

func _sand(at: Vector3, normal: Vector3, strength: float) -> void:
	var water: WaterVolume = _body.get_water_volume()
	if water != null and water.contains_point(at) and water.surface_at(at) > at.y+0.025:
		return
	var particles := CPUParticles3D.new()
	particles.name = "SandKick"
	particles.mesh = _grit_mesh
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = int(6*strength)
	particles.lifetime = 0.35
	particles.direction = (normal-Vector3(_body.velocity.x,0,_body.velocity.z)*0.07).normalized()
	particles.spread = 42.0
	particles.gravity = Vector3(0,-8,0)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.9*strength
	particles.scale_amount_min = 0.018
	particles.scale_amount_max = 0.045
	particles.color = Color(0.66,0.51,0.30,0.65)
	_spawn(particles,at+normal*0.015)

func _footprint(at: Vector3, normal: Vector3, foot: int) -> void:
	var mark := MeshInstance3D.new()
	mark.name = "SandFootprint"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.16,0.20)
	mark.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = preload("res://core/rendering/hero_footprint.gdshader")
	material.set_shader_parameter("toes",4.0 if foot < 2 else 5.0)
	mark.material_override = material
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mark)
	var forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP,_body.get_visual_motion().visual_rotation.y)
	var right: Vector3 = forward.cross(normal).normalized()
	mark.global_transform = Transform3D(Basis(right,normal,right.cross(normal).normalized()),at+normal*0.008)
	_retain_mark(mark,material)

func _retain_mark(mark: MeshInstance3D, material: ShaderMaterial) -> void:
	_marks = _marks.filter(func(reference: WeakRef) -> bool: return reference.get_ref() != null)
	_marks.append(weakref(mark))
	while _marks.size() > 32:
		var old := (_marks.pop_front() as WeakRef).get_ref() as MeshInstance3D
		if is_instance_valid(old):
			old.queue_free()
	var tween := mark.create_tween()
	tween.tween_method(func(age: float) -> void: material.set_shader_parameter("age",age),0.0,1.0,3.0)
	tween.tween_callback(mark.queue_free)

func _swim_axis() -> Vector3:
	var water := _body.get_water_volume()
	var relative: Vector3 = _body.velocity-water.flow_at(_body.global_position) if water != null else _body.velocity
	return relative.normalized() if relative.length_squared() > 0.04 else -_body.get_node("Model").global_basis.z.normalized()

static func flow_basis(axis: Vector3) -> Basis:
	var forward := axis.normalized() if not axis.is_zero_approx() else Vector3.FORWARD
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.01:
		right = forward.cross(Vector3.RIGHT)
	right = right.normalized()
	return Basis(right,right.cross(forward).normalized(),-forward)

func _spin_bubbles() -> void:
	bubble_bursts += 1
	var frame := flow_basis(_swim_axis())
	for strand: int in 3:
		var angle: float = _clock*23.0+TAU*float(strand)/3.0
		var radial: Vector3 = frame.x*cos(angle)+frame.y*sin(angle)
		var tangent: Vector3 = -frame.x*sin(angle)+frame.y*cos(angle)
		var particles := CPUParticles3D.new()
		particles.name = "SpinBubbles"
		particles.mesh = _droplet_mesh
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 5
		particles.lifetime = 0.55
		particles.direction = (tangent*0.8+frame.z*0.55+Vector3.UP*0.20).normalized()
		particles.spread = 22.0
		particles.gravity = Vector3(0,0.7,0)
		particles.initial_velocity_min = 0.35
		particles.initial_velocity_max = 1.0
		particles.scale_amount_min = 0.028
		particles.scale_amount_max = 0.075
		particles.color = Color(0.70,0.92,1.0,0.65)
		var fade := Gradient.new()
		fade.set_color(0,Color(1,1,1,0.9))
		fade.set_color(1,Color(1,1,1,0))
		particles.color_ramp = fade
		_spawn(particles,_body.global_position+radial*0.43+frame.z*(float(strand)-1.0)*0.40)

func _update_current(delta: float, active: bool) -> void:
	_current_strength = move_toward(_current_strength,1.0 if active else 0.0,delta*(12.0 if active else 7.0))
	if not _body.is_in_water():
		_current_strength = 0.0
	if _current_strength <= 0.001:
		if is_instance_valid(_current): _current.visible = false
		return
	if not is_instance_valid(_current):
		_current = MeshInstance3D.new()
		_current.name = "SpinCurrent"
		_current.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_current.material_override = material
		get_tree().current_scene.add_child(_current)
	_current.visible = true
	var frame := flow_basis(_swim_axis())
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three tapered ribbons wrap around the torso; the head remains readable.
	for strand: int in 3:
		for segment: int in 24:
			for corner: Vector2i in [Vector2i(0,-1),Vector2i(1,-1),Vector2i(0,1),Vector2i(1,-1),Vector2i(1,1),Vector2i(0,1)]:
				var t: float = float(segment+corner.x)/24.0
				var taper: float = sin(PI*t)
				var angle: float = _clock*23.0+float(strand)*TAU/3.0-t*TAU*0.80
				var radius: float = 0.36+0.14*taper+float(corner.y)*0.014*taper
				var radial: Vector3 = frame.x*cos(angle)+frame.y*sin(angle)
				builder.set_color(Color(0.64,0.91,1.0,0.38*taper*_current_strength))
				builder.add_vertex(_body.global_position+frame.z*lerpf(-0.60,0.95,t)+radial*radius)
	_current.mesh = builder.commit()

func _update_slide(delta: float, animator: HeroAnimator, teleported: bool) -> void:
	var speed: float = Vector2(_body.velocity.x,_body.velocity.z).length()
	var active: bool = animator.get_current_action() == HeroAnimator.ROLL and _body.is_on_floor() and not _body.is_in_water() and speed > 0.65 and not teleported
	if not active:
		_sliding = false
		_slide_distance = 0.0
		return
	_slide_distance += speed*delta
	if not _sliding or _slide_distance >= 0.16:
		_slide_distance = fmod(_slide_distance,0.16)
		_slide_contact()
	_sliding = true

func _slide_contact() -> void:
	var center: Vector3 = _body.global_position
	var query := PhysicsRayQueryParameters3D.create(center,center+Vector3.DOWN*1.05,_body.collision_mask,[_body.get_rid()])
	var hit := _body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.5:
		return
	var at: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var forward: Vector3 = _body.velocity.slide(normal).normalized()
	if forward.is_zero_approx(): return
	slide_contacts += 1
	var water := _body.get_water_volume()
	if water != null and water.contains_point(at) and water.surface_at(at) > at.y+0.025:
		WaterSplash.trail(self,Vector3(at.x,water.surface_at(at)+0.025,at.z),_body.velocity,false)
		return
	var collider := hit["collider"] as Node
	var sand: bool = collider != null and (collider.is_in_group("surface_sand") or collider.get_meta("footstep_surface","") == "sand")
	var particles := CPUParticles3D.new()
	particles.name = "SlideGrit"
	particles.mesh = _grit_mesh
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 7 if sand else 3
	particles.lifetime = 0.38
	particles.direction = (-forward+normal*0.35).normalized()
	particles.spread = 38.0
	particles.gravity = Vector3(0,-7,0)
	particles.initial_velocity_min = 0.65
	particles.initial_velocity_max = 1.7
	particles.scale_amount_min = 0.015
	particles.scale_amount_max = 0.045 if sand else 0.026
	particles.color = Color(0.67,0.53,0.33,0.7) if sand else Color(0.46,0.47,0.44,0.35)
	_spawn(particles,at+normal*0.035-forward*0.12)
	if not sand: return
	var mark := MeshInstance3D.new()
	mark.name = "SlideScuff"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.42,0.30)
	mark.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = preload("res://core/rendering/hero_slide_scuff.gdshader")
	mark.material_override = material
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mark)
	var right: Vector3 = forward.cross(normal).normalized()
	mark.global_transform = Transform3D(Basis(right,normal,right.cross(normal).normalized()),at+normal*0.010)
	_retain_mark(mark,material)

func _spawn(particles: CPUParticles3D, at: Vector3) -> void:
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	WaterSplash.start_particles(get_tree().current_scene,particles,at)
	WaterSplash._reap(self,particles,particles.lifetime)

func _update_tail(animator: HeroAnimator) -> void:
	if animator.get_current_action() != HeroAnimator.WHACK:
		_tail_contacted = false
	var sweeping: bool = animator.get_current_action() == HeroAnimator.WHACK and animator.get_action_phase() > 0.08 and animator.get_action_phase() < 0.56
	if sweeping:
		var tip: Vector3 = _body.get_visual_motion().tail_position()
		_tail_points.append(tip)
		_tail_times.append(_clock)
		if not _tail_contacted:
			_tail_contacted = _tail_surface_contact(tip)
	while not _tail_times.is_empty() and _clock-_tail_times[0] > 0.16:
		_tail_times.pop_front()
		_tail_points.pop_front()
	if _tail_points.size() < 2:
		if is_instance_valid(_ribbon):
			_ribbon.visible = false
		return
	if not is_instance_valid(_ribbon):
		_ribbon = MeshInstance3D.new()
		_ribbon.name = "TailSweep"
		_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ribbon.material_override = material
		get_tree().current_scene.add_child(_ribbon)
	_ribbon.visible = true
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in range(1,_tail_points.size()):
		for corner: Vector2i in [Vector2i(0,-1),Vector2i(1,-1),Vector2i(0,1),Vector2i(1,-1),Vector2i(1,1),Vector2i(0,1)]:
			var index: int = segment-1+corner.x
			var alpha: float = (1.0-(_clock-_tail_times[index])/0.16)*0.40
			builder.set_color(Color(1.0,0.80,0.68,alpha))
			builder.add_vertex(_tail_points[index]+Vector3.UP*float(corner.y)*0.055)
	_ribbon.mesh = builder.commit()

func _tail_surface_contact(tip: Vector3) -> bool:
	var water: WaterVolume = _body.get_water_volume()
	if water != null and water.contains_point(tip) and absf(water.surface_at(tip)-tip.y) < 0.18:
		WaterSplash.erupt(self,Vector3(tip.x,water.surface_at(tip),tip.z),3.0,false)
		return true
	var query := PhysicsRayQueryParameters3D.create(tip+Vector3.UP*0.1,tip+Vector3.DOWN*0.16,_body.collision_mask,[_body.get_rid()])
	var hit: Dictionary = _body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider := hit["collider"] as Node
		if collider != null and (collider.is_in_group("surface_sand") or collider.get_meta("footstep_surface","") == "sand"):
			_sand(hit["position"],hit["normal"],0.75)
			return true
	return false

func _exit_tree() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	if is_instance_valid(_ribbon):
		_ribbon.queue_free()
	for reference: WeakRef in _marks:
		var mark := reference.get_ref() as MeshInstance3D
		if is_instance_valid(mark):
			mark.queue_free()
