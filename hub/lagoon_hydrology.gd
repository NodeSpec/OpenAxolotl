@tool
class_name LagoonHydrology
extends Node3D

const WATER_LEVEL: float = 0.09
const CHANNEL_START: float = -5.5
const CHANNEL_END: float = -13.0
const CHANNEL_GRADE: float = 0.19
const TUNNEL_Y: float = -1.35
const POCKETS: Array[Vector4] = [Vector4(-4.3,0.0,3.5,2.9),Vector4(4.2,-1.0,3.7,3.0),Vector4(0.0,2.4,2.2,1.9)]
const DEPTHS: Array[float] = [1.9,2.0,1.15]
var tunnel_centers: Array[float] = [-6.0,0.0,6.0]
@export var continuous_stream: bool = false
@export var continuous_stream_x: float = 0.0

func _ready() -> void:
	if get_child_count() == 0:
		_rebuild()

func configure_tunnels(centers: Array[float], stream_open: bool = false, stream_x: float = 0.0) -> void:
	if centers == tunnel_centers and continuous_stream == stream_open and is_equal_approx(continuous_stream_x,stream_x) and get_child_count() > 0:
		return
	tunnel_centers = centers
	continuous_stream = stream_open
	continuous_stream_x = stream_x
	_rebuild()

func floor_height(point: Vector2) -> float:
	if point.y > 8.0:
		return beach_height(point)
	var radius: float = Vector2(point.x/11.5,(point.y+1.7)/8.5).length()
	var height: float = lerpf(-0.14,0.20,smoothstep(0.88,1.08,radius))
	for index: int in POCKETS.size():
		var pocket: Vector4 = POCKETS[index]
		var distance: float = Vector2((point.x-pocket.x)/pocket.z,(point.y-pocket.y)/pocket.w).length()
		height -= DEPTHS[index]*(1.0-smoothstep(0.0,1.0,distance))
	for x: float in tunnel_centers:
		var across: float = 1.0-smoothstep(1.65,2.65,absf(point.x-x))
		var approach: float = smoothstep(3.0,6.8,-point.y)
		var bed: float = channel_surface(point.y)-1.65
		height = lerpf(height,minf(height,bed),across*approach)
	if continuous_stream and point.y < -9.0:
		var center: Vector3 = LagoonStreamPath.at_z(point.y)+Vector3(continuous_stream_x,0,0)
		var excavated: float = 1.0-smoothstep(2.35,3.2,absf(point.x-center.x))
		height = lerpf(height,minf(height,center.y-2.3),excavated)
	return height

static func beach_height(point: Vector2) -> float:
	var shore: float = lerpf(0.20,-0.24,smoothstep(14.0,19.0,point.y))
	shore += 0.018*sin(point.x*0.7)*smoothstep(15.0,19.0,point.y)
	var dune: float = smoothstep(25.0,34.0,point.y)*(8.5+0.55*sin(point.x*0.35))
	var side_bank: float = smoothstep(19.0,28.0,absf(point.x))*8.0
	return shore+maxf(dune,side_bank)

static func channel_surface(z: float) -> float:
	return WATER_LEVEL+minf(0.0,z-CHANNEL_START)*CHANNEL_GRADE

func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: int in 132:
		for x: int in 144:
			var p := Vector2(-36.0+x*0.5,-24.0+z*0.5)
			_quad(builder,p,0.5,false)
	builder.generate_normals()
	var mesh: ArrayMesh = builder.commit()
	var ground := StaticBody3D.new()
	ground.name = "BasinFloor"
	ground.add_to_group("surface_sand")
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	ground.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var sand := ShaderMaterial.new()
	sand.shader = preload("res://hub/lagoon_stone.gdshader")
	sand.set_shader_parameter("tint",Color("d8c498"))
	visual.material_override = sand
	ground.add_child(visual)
	add_child(ground)
	var reflections := ReflectionProbe.new()
	reflections.name = "LagoonReflections"
	reflections.position = Vector3(0,2,-2)
	reflections.size = Vector3(30,18,30)
	reflections.max_distance = 45.0
	reflections.box_projection = true
	reflections.enable_shadows = true
	add_child(reflections)
	_make_surface(-1)
	_make_volume("CalmLagoon",AABB(Vector3(-12,-6,-10.5),Vector3(24,6.09,18)),false)
	_beach_surface()
	_make_volume("BeachWading",AABB(Vector3(-24,-2,14),Vector3(48,2.09,15)),false)
	_boundaries()
	for index: int in tunnel_centers.size():
		_make_surface(index)
		var x: float = tunnel_centers[index]
		_make_volume("TunnelCurrent%d" % index,AABB(Vector3(x-2,-6,CHANNEL_END),Vector3(4,6.09,CHANNEL_START-CHANNEL_END)),true)

func _beach_surface() -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: int in 30:
		for x: int in 96:
			var p := Vector2(-24.0+x*0.5,14.0+z*0.5)
			if beach_height(p+Vector2.ONE*0.25) < WATER_LEVEL:
				_quad(builder,p,0.5,true)
	builder.generate_normals()
	var surface := MeshInstance3D.new()
	surface.name = "BeachSurface"
	surface.mesh = builder.commit()
	var material := (load("res://core/rendering/water_surface.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter("mesh_is_surface",true)
	material.set_shader_parameter("wave_height",0.022)
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

func _boundaries() -> void:
	# Backup collision sits behind the visible dunes/cliffs, before any mesh edge.
	var body := StaticBody3D.new()
	body.name = "OuterBoundary"
	var boxes: Array[AABB] = [AABB(Vector3(-30,-10,-24),Vector3(1,70,61)),AABB(Vector3(29,-10,-24),Vector3(1,70,61)),AABB(Vector3(-30,-10,35),Vector3(60,70,1))]
	if continuous_stream:
		boxes.append(AABB(Vector3(-30,-10,-23),Vector3(28.5+continuous_stream_x,70,1)))
		boxes.append(AABB(Vector3(7.5+continuous_stream_x,-10,-23),Vector3(22.5-continuous_stream_x,70,1)))
	else:
		boxes.append(AABB(Vector3(-30,-10,-23),Vector3(60,70,1)))
	for box: AABB in boxes:
		var shape := BoxShape3D.new()
		shape.size = box.size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = box.get_center()
		body.add_child(collision)
	add_child(body)

func _quad(builder: SurfaceTool, p: Vector2, step: float, water: bool, channel: bool = false) -> void:
	for delta: Vector2 in [Vector2.ZERO,Vector2(step,0),Vector2(0,step),Vector2(step,0),Vector2(step,step),Vector2(0,step)]:
		var point: Vector2 = p+delta
		var height: float = (channel_surface(point.y) if channel else WATER_LEVEL) if water else floor_height(point)
		builder.set_uv(point*0.1)
		builder.add_vertex(Vector3(point.x,height,point.y))

func _make_surface(channel_index: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if channel_index < 0:
		for z: int in 72:
			for x: int in 96:
				var p := Vector2(-12.0+x*0.25,-10.5+z*0.25)
				var midpoint: Vector2 = p+Vector2.ONE*0.125
				if floor_height(midpoint) >= WATER_LEVEL:
					continue
				var in_channel: bool = false
				for center: float in tunnel_centers:
					if midpoint.y < CHANNEL_START and absf(midpoint.x-center) < 2.0:
						in_channel = true
				if not in_channel:
					_quad(st,p,0.25,true)
	else:
		for z: int in 30:
			for x: int in 16:
				var point := Vector2(tunnel_centers[channel_index]-2.0+x*0.25,CHANNEL_END+z*0.25)
				if continuous_stream and is_equal_approx(tunnel_centers[channel_index],continuous_stream_x) and point.y < -9.0:
					continue
				_quad(st,point,0.25,true,true)
	st.generate_normals()
	var visual := MeshInstance3D.new()
	visual.name = "LagoonSurface" if channel_index < 0 else "DownstreamSurface%d" % channel_index
	visual.mesh = st.commit()
	var material := (load("res://core/rendering/water_surface.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter("mesh_is_surface",true)
	material.set_shader_parameter("wave_height",0.025 if channel_index < 0 else 0.045)
	if channel_index >= 0:
		material.set_shader_parameter("flow_velocity",Vector2(0,-1.8))
		material.set_shader_parameter("turbulence",0.7)
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)

func _make_volume(label: String, bounds: AABB, flowing: bool) -> void:
	var volume := WaterVolume.new()
	volume.name = label
	volume.explicit_surface = true
	volume.shallow_wading_enabled = true
	volume.surface_height = WATER_LEVEL-CHANNEL_START*CHANNEL_GRADE if flowing else WATER_LEVEL
	volume.surface_gradient = Vector2(0,CHANNEL_GRADE) if flowing else Vector2.ZERO
	volume.depth_lighting_enabled = false
	volume.water_priority = 10 if flowing else 0
	volume.current_velocity = Vector3(0,-1.8*CHANNEL_GRADE,-1.8) if flowing else Vector3.ZERO
	volume.current_ramp_m = 2.2
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bounds.size
	collision.shape = shape
	collision.position = bounds.get_center()
	volume.add_child(collision)
	add_child(volume)
