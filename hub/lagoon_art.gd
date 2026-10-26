@tool
class_name LagoonArt
extends Node3D

## Seeded backdrop around saved imported foreground props; the registry owns portals.
const STONE := preload("res://hub/lagoon_stone.gdshader")
const FOLIAGE := preload("res://hub/lagoon_foliage.gdshader")
const GREENS: Array[Color] = [Color("235d36"), Color("367f38"), Color("60983c"), Color("9abd39"), Color("16786b")]

var entrance_only: bool = false
var rng := RandomNumberGenerator.new()
var leaves := SurfaceTool.new()
var leaf_count: int = 0
var rock_shapes: Array[ArrayMesh] = []
var rock_materials: Array[Material] = []
var solid_builder := SurfaceTool.new()
var stone_mats: Array[ShaderMaterial] = []
var foam_mat: StandardMaterial3D
var bark_mat: StandardMaterial3D
var coral_mat: StandardMaterial3D
var material_cache: Dictionary = {}


func _ready() -> void:
	if entrance_only or has_node("BatchedTropicalFoliage"):
		return
	rng.seed = 92371
	_setup()
	_landscape()
	_shore()
	_waterfall_inlet()
	_planting()
	_beach_planting()
	_finish_leaves()
	_batch_meshes()
	_finish_solids()
	_imported_solids()
	if not Engine.is_editor_hint():
		_lagoon_light.call_deferred()


func _setup() -> void:
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	solid_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for kind: String in ["shore_rock","bank_rock","cliff_rock"]:
		var source: Dictionary = LagoonRockKit.model(kind)
		rock_shapes.append(source["mesh"])
		rock_materials.append(source["material"])
		stone_mats.append(_stone(Color("c4a16e")))
	bark_mat = _mat(Color("796044"), 0.87)
	coral_mat = _mat(Color("f27863"), 0.55)
	foam_mat = _mat(Color("d1fff3"), 0.3)
	foam_mat.emission_enabled = true
	foam_mat.emission = Color("459e9a")
	foam_mat.emission_energy_multiplier = 0.22


static func make_tunnel(index: int) -> LagoonArt:
	var art := LagoonArt.new()
	art.entrance_only = true
	art.name = "WaterTunnel"
	art.rng.seed = 432 + index * 129
	art._setup()
	art._tunnel(index)
	art._finish_leaves()
	art._batch_meshes()
	art._finish_solids()
	return art


func _stone(tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STONE
	mat.set_shader_parameter("tint", tint)
	return mat


func _mat(tint: Color, roughness: float) -> StandardMaterial3D:
	var key: String = tint.to_html()+str(roughness)
	if material_cache.has(key):
		return material_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = roughness
	material_cache[key] = mat
	return mat


func _batch_meshes() -> void:
	# Bake transforms into one surface per material, keeping hundreds of details cheap.
	var batches: Dictionary = {}
	var materials: Dictionary = {}
	for child: Node in get_children():
		var visual := child as MeshInstance3D
		if visual == null:
			continue
		var material: Material = visual.material_override
		var key: int = material.get_instance_id()
		if not batches.has(key):
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[key] = builder
			materials[key] = material
		var surface: SurfaceTool = batches[key]
		surface.append_from(visual.mesh,0,visual.transform)
		remove_child(visual)
		visual.free()
	for key: int in batches:
		var surface: SurfaceTool = batches[key]
		_mesh(surface.commit(),materials[key] as Material,Vector3.ZERO)


func _mesh(mesh: Mesh, mat: Material, at: Vector3, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	node.scale = size
	add_child(node)
	return node


func _rock(at: Vector3, size: Vector3, mat: Material = null) -> MeshInstance3D:
	var variant: int = 0 if size.y < 0.7 else (2 if size.y > 2.0 else 1)
	var material: Material = rock_materials[variant]
	if mat != null:
		var key: String = "rock_"+str(mat.get_instance_id())
		if not material_cache.has(key):
			var tinted := material.duplicate() as BaseMaterial3D
			if mat is ShaderMaterial:
				tinted.albedo_color = (mat as ShaderMaterial).get_shader_parameter("tint")
			elif mat is BaseMaterial3D:
				tinted.albedo_color = (mat as BaseMaterial3D).albedo_color
			material_cache[key] = tinted
		material = material_cache[key]
	var node := _mesh(rock_shapes[variant],material,at,size)
	node.rotation = Vector3(rng.randf_range(-0.08,0.08),rng.randf_range(-PI,PI),rng.randf_range(-0.07,0.07))
	if size.length() > 0.45:
		solid_builder.append_from(node.mesh,0,node.transform)
	return node

func _finish_solids() -> void:
	var mesh: ArrayMesh = solid_builder.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	LagoonRockKit.solid(self,mesh,Transform3D.IDENTITY,"SolidRocks")

func _imported_solids() -> void:
	var imported := get_node_or_null("ImportedModels") as Node3D
	if imported == null:
		return
	for prop: Node in imported.get_children():
		if not String(prop.name).begins_with("Boulder") and not String(prop.name).begins_with("Coral"):
			continue
		for node: Node in prop.find_children("*","MeshInstance3D",true,false):
			var visual := node as MeshInstance3D
			if String(prop.name).begins_with("Boulder"):
				LagoonRockKit.solid(visual,visual.mesh,Transform3D.IDENTITY,"RockCollision")
			else:
				var points := PackedVector3Array()
				var vertices: PackedVector3Array = visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var cutoff: float = visual.get_aabb().position.y+visual.get_aabb().size.y*0.43
				for index: int in range(0,vertices.size(),12):
					if vertices[index].y < cutoff:
						points.append(vertices[index])
				var body := StaticBody3D.new()
				body.name = "CoralBaseCollision"
				body.set_meta("footstep_surface","stone")
				var shape := ConvexPolygonShape3D.new()
				shape.points = points
				var collision := CollisionShape3D.new()
				collision.shape = shape
				body.add_child(collision)
				visual.add_child(body)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _tube(points: Array[Vector3], radius: float, mat: Material, tip: float = 0.45) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 8
	for j: int in points.size()-1:
		var tangent := (points[j+1]-points[j]).normalized()
		var side := tangent.cross(Vector3.FORWARD).normalized()
		if side.length_squared() < 0.1:
			side = Vector3.RIGHT
		var other := tangent.cross(side).normalized()
		var r0: float = radius * lerpf(1.0,tip,float(j)/(points.size()-1))
		var r1: float = radius * lerpf(1.0,tip,float(j+1)/(points.size()-1))
		for i: int in sides:
			var a: float = TAU*float(i)/sides
			var b: float = TAU*float(i+1)/sides
			var v0 := side*cos(a)+other*sin(a)
			var v1 := side*cos(b)+other*sin(b)
			_tri(st,points[j]+v0*r0,points[j+1]+v0*r1,points[j]+v1*r0)
			_tri(st,points[j]+v1*r0,points[j+1]+v0*r1,points[j+1]+v1*r1)
	st.generate_normals()
	_mesh(st.commit(),mat,Vector3.ZERO)


func _blade(base: Vector3, direction: Vector3, length: float, width: float, droop: float, tint: Color) -> void:
	var forward := direction.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.1:
		right = Vector3.RIGHT
	var up := forward.cross(right).normalized()
	for j: int in 8:
		var t0: float = float(j)/8.0
		var t1: float = float(j+1)/8.0
		var p0 := base+forward*length*t0+Vector3.UP*(sin(t0*PI)*length*0.18-droop*t0*t0)
		var p1 := base+forward*length*t1+Vector3.UP*(sin(t1*PI)*length*0.18-droop*t1*t1)
		var w0: float = pow(sin(t0*PI),0.75)*width
		var w1: float = pow(sin(t1*PI),0.75)*width
		for s: int in [-1,1]:
			_leaf_tri(p0,p0+right*w0*s-up*w0*0.22,p1,Vector2(0.5,t0),Vector2(0.5+s*0.5,t0),Vector2(0.5,t1),tint)
			_leaf_tri(p1,p0+right*w0*s-up*w0*0.22,p1+right*w1*s-up*w1*0.22,Vector2(0.5,t1),Vector2(0.5+s*0.5,t0),Vector2(0.5+s*0.5,t1),tint)
	leaf_count += 1


func _leaf_tri(a: Vector3,b: Vector3,c: Vector3,ua: Vector2,ub: Vector2,uc: Vector2,tint: Color) -> void:
	var normal := (c-a).cross(b-a).normalized()
	if normal.y < 0.0:
		normal = -normal
	for i: int in 3:
		leaves.set_normal(normal)
		leaves.set_color(tint.srgb_to_linear())
		leaves.set_uv([ua,ub,uc][i])
		leaves.add_vertex([a,b,c][i])


func _finish_leaves() -> void:
	if leaf_count == 0:
		return
	var mat := ShaderMaterial.new()
	mat.shader = FOLIAGE
	var node := _mesh(leaves.commit(),mat,Vector3.ZERO)
	node.name = "BatchedTropicalFoliage"
	leaves = null


func _rosette(at: Vector3, size: float, count: int = 9) -> void:
	for i: int in count:
		var a: float = TAU*float(i)/count+rng.randf()*0.3
		_blade(at,Vector3(cos(a),rng.randf_range(0.2,0.75),sin(a)),size*rng.randf_range(0.75,1.2),size*0.17,size*0.38,GREENS[rng.randi_range(0,4)])


func _palm(at: Vector3, height: float, lean: float) -> void:
	var pts: Array[Vector3] = []
	for j: int in 13:
		var t: float = float(j)/12.0
		pts.append(at+Vector3(lean*t*t,height*t,0.3*sin(t*PI)))
	_tube(pts,0.20,bark_mat,0.52)
	var top: Vector3 = pts[-1]
	for f: int in 10:
		var a: float = TAU*float(f)/10.0+rng.randf()*0.2
		var dir := Vector3(cos(a),0,sin(a))
		var length: float = rng.randf_range(2.4,3.6)
		var rib: Array[Vector3] = []
		for j: int in 9:
			var t: float = float(j)/8.0
			rib.append(top+dir*length*t+Vector3.UP*(sin(t*PI)*0.95-t*t*0.6))
		_tube(rib,0.035,_mat(Color("829738"),0.7),0.12)
		for j: int in range(1,12):
			var t: float = float(j)/12.0
			var origin := top+dir*length*t+Vector3.UP*(sin(t*PI)*0.95-t*t*0.6)
			var side := Vector3(-dir.z,0,dir.x)
			for sign_value: int in [-1,1]:
				_blade(origin,side*sign_value+dir*0.28-Vector3.UP*0.15,0.95*(1.0-t)+0.16,0.09,0.25,GREENS[2+f%2])
	_rosette(top,0.8,7)


func _vine(at: Vector3, length: float) -> void:
	var pts: Array[Vector3] = []
	for j: int in 9:
		var t: float = float(j)/8.0
		var origin := at+Vector3(sin(t*7.0)*0.12,-length*t,0.12*sin(t*4.0))
		pts.append(origin)
		for s: int in [-1,1]:
			_blade(origin,Vector3(s*0.65,-0.8,0.45),rng.randf_range(0.25,0.43),0.12,0.03,GREENS[2+j%2])
	_tube(pts,0.019,_mat(Color("46703b"),0.9),0.4)


func _flower(at: Vector3, scale_value: float) -> void:
	var pink := Color("ff647d")
	for i: int in 5:
		var a: float = TAU*float(i)/5.0
		_blade(at,Vector3(cos(a),0.35,sin(a)),0.45*scale_value,0.16*scale_value,0.02,pink)
	_rock(at+Vector3.UP*0.035,Vector3.ONE*0.07*scale_value,_mat(Color("ffce59"),0.5))


func _coral(at: Vector3, height: float) -> void:
	_tube([at,at+Vector3(0.04,height*0.6,0),at+Vector3(0.1,height,0.03)],0.09,coral_mat,0.45)
	for i: int in 4:
		var a: float = TAU*float(i)/4.0
		var start := at+Vector3.UP*height*(0.25+float(i)*0.13)
		var end := start+Vector3(cos(a)*height*0.38,height*0.5,sin(a)*height*0.38)
		_tube([start,start.lerp(end,0.6)+Vector3.UP*0.06,end],0.065,coral_mat,0.35)


func _landscape() -> void:
	# The back wall starts behind the full tunnel depth, leaving the mouths open.
	for i: int in range(-7,8):
		var x: float = float(i)*3.1
		if absi(i) <= 2:
			x += signf(x)*1.25
		var h: float = 4.7+absf(x)*0.15+rng.randf_range(-0.6,0.8)
		if i != 0:
			_rock(Vector3(x,h*0.45,-15.5),Vector3(2.35,h*0.65,3.0))
		_rock(Vector3(x+0.4,h,-15.0),Vector3(2.1,1.5,2.0))
		for j: int in 5:
			var plant := Vector3(x+rng.randf_range(-1.6,1.6),h+1.05,-14.4+rng.randf_range(-0.6,0.6))
			_rosette(plant,rng.randf_range(1.1,1.9),12)
			if j%2 == 0:
				_vine(plant+Vector3(0,-0.3,1.3),rng.randf_range(1.3,3.1))
	for side: int in [-1,1]:
		for j: int in 9:
			var z: float = -13.0+float(j)*2.75
			var h: float = lerpf(7.0,1.7,float(j)/8.0)
			var x: float = side*(13.0+1.0*sin(float(j)*0.5))
			_rock(Vector3(x,h*0.42,z),Vector3(2.2,h*0.62,2.0))
			_rock(Vector3(x-side*0.6,h,z-0.5),Vector3(1.7,0.9,1.4))
			_rosette(Vector3(x-side*0.5,h+0.5,z),rng.randf_range(1.0,1.8))
			if j%2 == 0:
				_vine(Vector3(x-side*1.7,h+0.4,z+0.6),h*0.7)
			for k: int in 4:
				var p := Vector3(x+rng.randf_range(-1.2,0.8),h+0.5,z+rng.randf_range(-1,1))
				_rosette(p,rng.randf_range(0.9,1.7),12)
				_vine(p+Vector3(-side*0.9,-0.2,0.25),rng.randf_range(1.2,2.8))
	var cloud := SphereMesh.new()
	cloud.radius = 1.0
	cloud.height = 2.0
	cloud.radial_segments = 24
	cloud.rings = 12
	for origin: Vector3 in [Vector3(-42,25,-90),Vector3(13,32,-100),Vector3(45,23,-95)]:
		for j: int in 7:
			var p := origin+Vector3((j-3)*2.6,rng.randf_range(-0.3,2.0),rng.randf_range(-2,2))
			_mesh(cloud,_mat(Color("ffffff"),1.0),p,Vector3(4.2,rng.randf_range(2.0,3.8),2.9))


func _shore() -> void:
	for i: int in 31:
		var a: float = TAU*(float(i)+rng.randf_range(-0.3,0.3))/31.0
		var p := _pool_point(a,1.015)
		if p.z < -6.4 and absf(p.x)<9.2:
			continue
		if p.z > 4.5 and absf(p.x) < 5.5:
			continue
		var size: float = rng.randf_range(0.35,1.8)
		_rock(p-Vector3.UP*0.06,Vector3(size,rng.randf_range(0.24,0.65),size*0.85))
	for side: int in [-1,1]:
		for i: int in 5:
			var p := Vector3(side*(6.8+sin(i*0.9)*1.4),0.13,5.0-i*1.55)
			var size: float = rng.randf_range(0.6,1.15)
			if p.z < 3.0 and absf(absf(p.x)-8.3) < size+0.85:
				continue
			var hydrology := get_parent().get_node("Hydrology") as LagoonHydrology
			var bed: float = hydrology.floor_height(Vector2(p.x,p.z))
			p.y = (bed+0.35)*0.5
			_rock(p,Vector3(size,maxf(0.26,(0.35-bed)/1.7),size*0.82))
	var submerged_stone := _stone(Color("83b4a3"))
	for i: int in 16:
		var p := Vector3(rng.randf_range(-10,10),0.03,rng.randf_range(3.7,6.8))
		_rock(p,Vector3(0.23,0.12,0.2),submerged_stone)


func _pool_point(a: float, r: float) -> Vector3:
	var edge: float = 1.0+0.025*sin(a*7.0)+0.018*cos(a*11.0)
	return Vector3(cos(a)*11.5*r*edge,0.09,sin(a)*8.5*r*edge-1.7)


func _foam(at: Vector3, radius: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offset: float = rng.randf()*TAU
	for i: int in 48:
		if i%13 > 8:
			continue
		var a: float = TAU*float(i)/48.0+offset
		var b: float = a+TAU/48.0
		var r: float = radius*(1.0+0.06*sin(a*7.0))
		var width: float = 0.008+0.009*(1.0+sin(a*9.0))
		var p := Vector3(cos(a),0,sin(a)*0.8)
		var q := Vector3(cos(b),0,sin(b)*0.8)
		_tri(st,p*r,q*r,p*(r+width))
		_tri(st,q*r,q*(r+width),p*(r+width))
	st.generate_normals()
	_mesh(st.commit(),foam_mat,at)


func _planting() -> void:
	for x: float in [-17.0,-13.5,-10.0,-4.2,2.5,8.0,11.0,16.5]:
		_palm(Vector3(x,5.4+absf(x)*0.15,-15.5+rng.randf_range(-1.2,0.4)),rng.randf_range(2.0,4.5),rng.randf_range(-1.6,1.6))
	for side: int in [-1,1]:
		_palm(Vector3(side*13.4,4.7,-5.0),4.7,-side*1.1)
		_palm(Vector3(side*14.0,2.8,2.0),5.1,-side*1.0)
		for i: int in 18:
			var p := Vector3(side*rng.randf_range(10.8,13.2),rng.randf_range(0.15,0.65),rng.randf_range(-9.5,11.0))
			_rosette(p,rng.randf_range(0.7,1.5),9)
			if i%3 == 0:
				_flower(p+Vector3.UP*0.5,1.0)
	for side: int in [-1,1]:
		# Frame the imported flower beds without burying them in oversized leaves.
		_rosette(Vector3(side*9.3,0.2,10.6),1.35,10)
		_rosette(Vector3(side*11.4,0.2,6.4),1.0,9)


func _tunnel(index: int) -> void:
	var source: Dictionary = LagoonRockKit.model("open_arch")
	var material := (source["material"] as BaseMaterial3D).duplicate() as BaseMaterial3D
	material.albedo_color = [Color("fff2d5"),Color.WHITE,Color("b7e1de")][index%3]
	var gate := _mesh(source["mesh"],material,Vector3(0,-0.7,-0.1),Vector3(3.0,4.4,2.3))
	gate.name = "ImportedOpenArch"
	solid_builder.append_from(gate.mesh,0,gate.transform)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0,0.4,-1.4)
	glow.light_color = Color("55aac2")
	glow.light_energy = 0.5
	glow.omni_range = 3.5
	add_child(glow)

func _waterfall_inlet() -> void:
	var source: Dictionary = LagoonRockKit.model("waterfall_arch")
	var original := source["material"] as BaseMaterial3D
	var material := ShaderMaterial.new()
	material.shader = preload("res://hub/lagoon_waterfall.gdshader")
	material.set_shader_parameter("color_map",original.albedo_texture)
	material.set_shader_parameter("normal_map",original.normal_texture)
	material.set_shader_parameter("roughness_map",original.roughness_texture)
	var inlet := _mesh(source["mesh"],material,Vector3(11.3,-0.16,-1.8),Vector3(1.7,2.4,1.7))
	inlet.name = "ShoreWaterfall"
	inlet.rotation.y = -0.9
	# The proxy is the opened arch, never the painted water sheet.
	var open: Dictionary = LagoonRockKit.model("open_arch")
	solid_builder.append_from(open["mesh"],0,inlet.transform)

func _beach_planting() -> void:
	for side: int in [-1,1]:
		for i: int in 6:
			var x: float = side*(14.0+i*1.3)
			var z: float = 15.0+i*2.3
			var y: float = LagoonHydrology.beach_height(Vector2(x,z))
			_rock(Vector3(x,y+0.6,z),Vector3(1.5,1.0,1.3))
			_rosette(Vector3(x,y+1.0,z),1.2)
		_palm(Vector3(side*16,1.2,15.5),5.5,-side*1.1)
		_palm(Vector3(side*11,4.4,29.5),5.0,side*0.8)
	for x: float in [-17.0,-8.0,0.0,9.0,18.0]:
		_rosette(Vector3(x,LagoonHydrology.beach_height(Vector2(x,31)),31),1.5)

func _arch_stone(a: float,b: float,ri: float,ro: float,depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for z: float in [-depth*0.5,depth*0.5]:
		for r: float in [ri,ro]:
			for angle: float in [a,b]:
				pts.append(Vector3(cos(angle)*r,sin(angle)*r,z))
	for f: Array in [[0,2,1,3],[4,5,6,7],[0,4,2,6],[1,3,5,7],[2,6,3,7],[0,1,4,5]]:
		_tri(st,pts[f[0]],pts[f[1]],pts[f[2]])
		_tri(st,pts[f[2]],pts[f[1]],pts[f[3]])
	st.generate_normals()
	return st.commit()


func _lagoon_light() -> void:
	var main := get_tree().current_scene
	if main == null:
		return
	var holder := main.get_node_or_null("WorldLighting/WorldEnvironment") as WorldEnvironment
	if holder != null and holder.environment != null:
		# Hub-local override is restored when a level loads.
		var original: Environment = holder.environment
		var sunny := original.duplicate() as Environment
		sunny.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		sunny.tonemap_exposure = 0.95
		sunny.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		sunny.ambient_light_color = Color("a4c8df")
		sunny.ambient_light_energy = 0.42
		var sky := Sky.new()
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color("176ccc")
		sky_mat.sky_horizon_color = Color("92d8f2")
		sky_mat.sky_curve = 0.25
		sky_mat.ground_horizon_color = Color("92d8f2")
		sky_mat.ground_bottom_color = Color("53716f")
		sky_mat.sun_angle_max = 2.0
		sky.sky_material = sky_mat
		sunny.sky = sky
		sunny.fog_density = 0.0008
		sunny.adjustment_saturation = 1.12
		sunny.fog_sky_affect = 0.0
		sunny.ssao_radius = 0.7
		sunny.ssao_intensity = 1.4
		holder.environment = sunny
		var sun := main.get_node_or_null("WorldLighting/Sun") as DirectionalLight3D
		var original_rotation: Vector3 = sun.rotation
		var original_energy: float = sun.light_energy
		var original_color: Color = sun.light_color
		var original_bias: float = sun.shadow_normal_bias
		var original_depth_bias: float = sun.shadow_bias
		sun.rotation_degrees = Vector3(-48,-35,0)
		sun.light_energy = 1.5
		sun.light_color = Color("fff0cf")
		sun.shadow_normal_bias = 1.5
		sun.shadow_bias = 0.15
		var hub := get_parent() as OpenLagoon
		if hub != null:
			hub.world_entered.connect(func(_id: String) -> void:
				if hub.is_continuous_world():
					return
				holder.environment = original
				sun.rotation = original_rotation
				sun.light_energy = original_energy
				sun.light_color = original_color
				sun.shadow_normal_bias = original_bias
				sun.shadow_bias = original_depth_bias)
			hub.returned_to_hub.connect(func(_id: String) -> void:
				holder.environment = sunny
				sun.rotation_degrees = Vector3(-48,-35,0)
				sun.light_energy = 1.5
				sun.light_color = Color("fff0cf")
				sun.shadow_normal_bias = 1.5
				sun.shadow_bias = 0.15)
