@tool
class_name LagoonStream
extends WaterVolume

const CAMERA_HINT_ID := "lagoon_downstream"
var _camera_rig: CameraRig

func _ready() -> void:
	explicit_surface = true
	shallow_wading_enabled = true
	depth_lighting_enabled = false
	water_priority = 30
	current_velocity = Vector3(0,-0.45,-3.2)
	if get_child_count() == 0:
		_build()
	super._ready()
	if not Engine.is_editor_hint():
		add_to_group("lighting_enclosures")

func surface_at(point: Vector3) -> float:
	return to_global(LagoonStreamPath.at_z(to_local(point).z)).y

func surface_slope_at(point: Vector3) -> Vector2:
	if to_local(point).z < -52.0:
		return Vector2.ZERO
	var direction: Vector3 = LagoonStreamPath.tangent(to_local(point).z)
	return Vector2(0,direction.y/minf(-0.001,direction.z))

func enclosure_at(point: Vector3) -> float:
	var p: Vector3 = to_local(point) if is_inside_tree() else point-position
	var center: Vector3 = LagoonStreamPath.at_z(p.z)
	if p.z > -9.0 or p.z < -53.0 or absf(p.x-center.x) > 3.3:
		return 0.0
	if p.y < center.y-2.8 or p.y > center.y+3.5:
		return 0.0
	return LagoonStreamPath.enclosure(p.z)

func contains_point(point: Vector3, margin: float = 0.0) -> bool:
	var p: Vector3 = to_local(point) if is_inside_tree() else point-position
	if p.z > -8.95+margin or p.z < -56.0-margin:
		return false
	var center: Vector3 = LagoonStreamPath.at_z(p.z)
	return absf(p.x-center.x) < LagoonStreamPath.HALF_WIDTH+margin and p.y > center.y-2.8 and p.y < center.y+0.85

func flow_at(point: Vector3) -> Vector3:
	if not contains_point(point):
		return Vector3.ZERO
	var p: Vector3 = to_local(point)
	var center: Vector3 = LagoonStreamPath.at_z(p.z)
	var direction: Vector3 = LagoonStreamPath.tangent(maxf(-51.8,p.z))
	if p.z < -52.0:
		direction = Vector3.FORWARD
	var strength: float = lerpf(1.8,3.4,smoothstep(9.0,15.0,-p.z))
	strength *= lerpf(1.0,0.24,smoothstep(48.0,52.0,-p.z))
	strength *= 1.0-smoothstep(53.0,56.0,-p.z)
	var result: Vector3 = direction*strength
	# A gentle cross-stream correction keeps a drifting swimmer off the banks.
	result.x += clampf((center.x-p.x)*1.1,-1.4,1.4)
	return global_basis*result

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var body := get_tree().get_first_node_in_group("player") as AxolotlBody
	# Curved containment is narrower than its overlapping broad-phase boxes.
	# Reconcile the analytical bank when a capsule moves within those boxes.
	if body != null and contains_point(body.global_position,0.55) and overlaps_body(body) and not _bodies.has(body):
		super._on_body_entered(body)
	if body == null or body.get_camera() == null:
		return
	_camera_rig = body.get_camera().get_rig()
	if contains_point(body.global_position,0.5):
		var hint := CameraHint.new(CAMERA_HINT_ID,40)
		hint.set_distance(4.5)
		hint.set_pitch_deg(28.0)
		_camera_rig.get_hint_stack().add(hint)
	else:
		_camera_rig.get_hint_stack().remove(CAMERA_HINT_ID)

func _on_body_entered(body: Node3D) -> void:
	if contains_point(body.global_position,0.55):
		super._on_body_entered(body)

func _exit_tree() -> void:
	release_camera_hint()
	super._exit_tree()

func release_camera_hint() -> void:
	if _camera_rig != null:
		_camera_rig.get_hint_stack().remove(CAMERA_HINT_ID)

func _build() -> void:
	var shell := SurfaceTool.new()
	var collision_shell := SurfaceTool.new()
	var water := SurfaceTool.new()
	shell.begin(Mesh.PRIMITIVE_TRIANGLES)
	collision_shell.begin(Mesh.PRIMITIVE_TRIANGLES)
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = LagoonStreamPath.curve().get_baked_length()
	var segments: int = ceili(length/0.6)
	for i: int in segments:
		var d0: float = length*float(i)/segments
		var d1: float = length*float(i+1)/segments
		var a: Vector3 = LagoonStreamPath.point(d0)
		var b: Vector3 = LagoonStreamPath.point(d1)
		var right: Vector3 = _right_at(a.z)
		var next_right: Vector3 = _right_at(b.z)
		for j: int in 32:
			var angle0: float = TAU*float(j)/32
			var angle1: float = TAU*float(j+1)/32
			var points: Array[Vector3] = [_wall_point(a,right,angle0,d0),_wall_point(a,right,angle1,d0),_wall_point(b,next_right,angle0,d1),_wall_point(b,next_right,angle1,d1)]
			var collision_points: Array[Vector3] = [_wall_point(a,right,angle0,d0,true),_wall_point(a,right,angle1,d0,true),_wall_point(b,next_right,angle0,d1,true),_wall_point(b,next_right,angle1,d1,true)]
			var uvs: Array[Vector2] = [Vector2(angle0*1.1,d0*0.36),Vector2(angle1*1.1,d0*0.36),Vector2(angle0*1.1,d1*0.36),Vector2(angle1*1.1,d1*0.36)]
			for corner: int in [0,2,1,1,2,3]:
				var angle: float = angle0 if corner%2 == 0 else angle1
				shell.set_normal(-((right if corner < 2 else next_right)*cos(angle)+Vector3.UP*sin(angle)))
				shell.set_uv(uvs[corner])
				shell.add_vertex(points[corner])
				collision_shell.add_vertex(collision_points[corner])
		var water_points: Array[Vector3] = [a-right*2.9,a+right*2.9,b-next_right*2.9,b+next_right*2.9]
		for corner: int in [0,2,1,1,2,3]:
			water.set_normal(Vector3.UP)
			water.set_uv(Vector2(-2.9 if corner%2 == 0 else 2.9,-d0 if corner < 2 else -d1))
			water.add_vertex(water_points[corner])
		if i%3 == 0:
			var shape := BoxShape3D.new()
			shape.size = Vector3(5.3,5.5,2.2)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = a+Vector3.DOWN*1.5
			collision.rotation.y = atan2(-(b-a).x,-(b-a).z)
			add_child(collision)
	var outlet_shape := BoxShape3D.new()
	outlet_shape.size = Vector3(5.3,5.5,4.5)
	var outlet_collision := CollisionShape3D.new()
	outlet_collision.shape = outlet_shape
	outlet_collision.position = LagoonStreamPath.exit_position()+Vector3(0,-1.5,-2)
	add_child(outlet_collision)
	shell.generate_tangents()
	var shell_mesh: ArrayMesh = shell.commit()
	var original := LagoonRockKit.model("bank_rock")["material"] as BaseMaterial3D
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://hub/lagoon_stream_rock.gdshader")
	stone.set_shader_parameter("color_map",original.albedo_texture)
	stone.set_shader_parameter("normal_map",original.normal_texture)
	stone.set_shader_parameter("roughness_map",original.roughness_texture)
	var backing := StandardMaterial3D.new()
	backing.albedo_color = Color("414a48")
	backing.roughness = 0.86
	backing.cull_mode = BaseMaterial3D.CULL_DISABLED
	_visual("CaveBacking",shell_mesh,backing)
	var lining := MultiMeshInstance3D.new()
	lining.name = "TexturedCave"
	lining.multimesh = _rock_lining(length)
	lining.material_override = stone
	add_child(lining)
	var solid := StaticBody3D.new()
	solid.name = "CaveWalls"
	solid.collision_layer = 1 | SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	var collision := CollisionShape3D.new()
	# A fitted inner shell blocks bodies and cameras without cooking every rock.
	var shape := collision_shell.commit().create_trimesh_shape()
	shape.backface_collision = true
	collision.shape = shape
	solid.add_child(collision)
	add_child(solid)
	var material := (load("res://core/rendering/water_surface.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter("mesh_is_surface",true)
	material.set_shader_parameter("flow_uses_uv",true)
	material.set_shader_parameter("flow_exit_z",LagoonStreamPath.exit_position().z)
	material.set_shader_parameter("flow_velocity",Vector2(0,-3.2))
	material.set_shader_parameter("wave_height",0.045)
	material.set_shader_parameter("turbulence",0.5)
	_visual("ContinuousWater",water.commit(),material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for distance: float in [8.0,15.5,23.0,30.5,37.0]:
		var light := OmniLight3D.new()
		light.name = "MossLight%d" % int(distance)
		light.position = LagoonStreamPath.point(distance)+Vector3(1.65,0.8,0)
		light.light_color = Color("6adeae")
		light.light_energy = 1.15
		light.omni_range = 5.5
		add_child(light)
	for distance: float in [12.0,31.0]:
		var reflection := ReflectionProbe.new()
		reflection.position = LagoonStreamPath.point(distance)+Vector3.UP
		reflection.size = Vector3(11,10,22)
		reflection.max_distance = 18.0
		reflection.box_projection = true
		add_child(reflection)

func _right_at(z: float) -> Vector3:
	var direction: Vector3 = LagoonStreamPath.tangent(z)
	return Vector3(-direction.z,0,direction.x).normalized()

func _rock_lining(length: float) -> MultiMesh:
	var mesh := LagoonRockKit.model("bank_rock")["mesh"] as ArrayMesh
	var random := RandomNumberGenerator.new()
	random.seed = 18721
	var rings: int = ceili(length/2.4)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = rings*9
	for ring: int in rings:
		var distance: float = length*(ring+0.5)/rings
		var center: Vector3 = LagoonStreamPath.point(distance)
		var right: Vector3 = _right_at(center.z)
		for sector: int in 9:
			var angle: float = TAU*(sector+0.5*(ring%2))/9.0
			var radial: Vector3 = right*cos(angle)+Vector3.UP*sin(angle)
			var across: Vector3 = -right*sin(angle)+Vector3.UP*cos(angle)
			var inward: Vector3 = -radial
			var basis := Basis(across,inward,across.cross(inward))
			basis *= Basis(Vector3.UP,random.randf_range(-0.22,0.22))
			var size := Vector3(random.randf_range(1.0,1.35),random.randf_range(0.48,0.7),random.randf_range(1.4,1.7))
			var at: Vector3 = center+right*cos(angle)*3.12+Vector3.UP*(0.65+sin(angle)*3.28)
			instances.set_instance_transform(ring*9+sector,Transform3D(basis.scaled_local(size),at))
	return instances

func _wall_point(center: Vector3, right: Vector3, angle: float, distance: float, collision: bool = false) -> Vector3:
	var variation: float = 0.11*sin(angle*5.0+distance*1.3)+0.065*sin(angle*11-distance*2.4)
	# The backing must sit outside the textured lining, not obscure its faces.
	var horizontal: float = (2.4 if collision else 3.5)+variation
	var vertical: float = (2.65 if collision else 3.55)+variation
	return center+right*cos(angle)*horizontal+Vector3.UP*(0.65+sin(angle)*vertical)

func _visual(label: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)
	return visual
