extends RefCounted
## Authored terrain volumes and seeded planting, baked into the production scene.
var world: Node3D
var holder: Node3D
var materials: Dictionary = {}
var grass: Dictionary = {}
var stones: Dictionary = {}
var foliage: Dictionary = {}
var vines: Dictionary = {}
var route: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var stats := {"terrain_volumes":0,"grass_tufts":0,"pebbles":0}

func begin(target: Node3D) -> void:
	world=target
	holder=Node3D.new()
	holder.name="CustomLandscape"
	world.add_child(holder)
	for waypoint: RoutePilot.Waypoint in CoralRoute.waypoints():
		route.append(waypoint.target)
	rng.seed=932607

func material(section: String, kind: String) -> ShaderMaterial:
	var key := section+kind
	if materials.has(key):
		return materials[key] as ShaderMaterial
	var result := ShaderMaterial.new()
	result.shader=load("res://core/rendering/cascade_ground.gdshader")
	var rock := Color("a7987a")
	var turf := Color("53833b")
	var sand := Color("dfcd9f")
	if section=="S03":
		rock=Color("718e88"); turf=Color("386c60"); sand=Color("b7c3b0")
	elif section=="S04":
		rock=Color("949c86"); turf=Color("5c8c43")
	elif section=="S05":
		rock=Color("b0a17f"); turf=Color("639541")
	elif section=="S06":
		rock=Color("99a58c"); turf=Color("478650")
	result.set_shader_parameter("rock_tint",rock)
	result.set_shader_parameter("grass_tint",turf)
	result.set_shader_parameter("sand_tint",sand)
	result.set_shader_parameter("surface_kind",0.0 if kind=="sand" else (1.0 if kind=="bank" else 2.0))
	result.set_shader_parameter("water_level",4.0 if section=="S05" else (2.4 if section=="S04" else 0.0))
	preload("res://dev/living_cascade/cascade_surface_library.gd").apply(result,section)
	materials[key]=result
	return result

func pose(node: Node3D) -> Transform3D:
	var t := node.transform
	var parent := node.get_parent()
	while parent!=world and parent is Node3D:
		t=(parent as Node3D).transform*t
		parent=parent.get_parent()
	return t

func noise(p: Vector3) -> float:
	return sin(p.x*0.83+p.z*0.39)*0.48+sin(p.z*1.31-p.x*0.29)*0.30+sin(p.x*2.14+p.z*1.87)*0.22

func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	for p: Vector3 in [a,b,c]:
		var cover := 0.0 if near_route(p,1.05) else smoothstep(-0.30,0.45,noise(p*0.35))
		st.set_color(Color(cover,0,0,1)); st.add_vertex(p)

func quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	triangle(st,a,b,c); triangle(st,c,b,d)

func finish_mesh(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	st.index()
	return st.commit()

func replace(solid: StaticBody3D,size: Vector3,section: String,kind: String) -> void:
	var t := pose(solid)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall := kind=="wall"
	var nx := maxi(2,ceili(size.x/1.2))
	var nz := maxi(2,ceili(size.z/1.2))
	var top := size.y*0.5
	var bottom := -size.y*0.5
	if kind=="bank" and solid.rotation.length()<0.02:
		bottom=minf(bottom,-3.2-t.origin.y if section=="S03" else -2.1-t.origin.y)
	var points: Array[Vector3] = []
	for z in range(nz+1):
		for x in range(nx+1):
			var p := Vector3((float(x)/nx-0.5)*size.x,top,(float(z)/nz-0.5)*size.z)
			var world_p := t*p
			var edge := minf(size.x*0.5-absf(p.x),size.z*0.5-absf(p.z))
			if wall:
				p.y+=0.15+(noise(world_p*0.45)+1.0)*0.52
			else:
				p.y+=noise(world_p)*0.025*smoothstep(0,0.8,edge)
				if kind=="bank" and section in preload("res://dev/living_cascade/cascade_surface_library.gd").POLISHED and solid.rotation.length()<0.02 and not near_route(world_p,1.15):
					p.y-=0.17*(1.0-smoothstep(0.0,0.70,edge))
					var radius := minf(0.7,minf(size.x,size.z)*0.18)
					var corner := Vector2(absf(p.x)-size.x*0.5+radius,absf(p.z)-size.z*0.5+radius)
					if corner.x>0 and corner.y>0:
						corner=corner.normalized()*radius
						p.x=signf(p.x)*(size.x*0.5-radius+corner.x)
						p.z=signf(p.z)*(size.z*0.5-radius+corner.y)
			points.append(p)
	for z in range(nz):
		for x in range(nx):
			var i := z*(nx+1)+x
			quad(st,t*points[i],t*points[i+1],t*points[i+nx+1],t*points[i+nx+2])
	var rim: Array[Vector3] = []
	for x in range(nx+1): rim.append(points[x])
	for z in range(1,nz+1): rim.append(points[z*(nx+1)+nx])
	for x in range(nx-1,-1,-1): rim.append(points[nz*(nx+1)+x])
	for z in range(nz-1,0,-1): rim.append(points[z*(nx+1)])
	var layers := maxi(7,ceili(size.y/1.0)) if wall else 4
	for ring in range(layers):
		for j in range(rim.size()):
			var next := (j+1)%rim.size()
			var a := side_point(rim[j],bottom,float(ring)/layers,size,t,wall)
			var b := side_point(rim[next],bottom,float(ring)/layers,size,t,wall)
			var c := side_point(rim[j],bottom,float(ring+1)/layers,size,t,wall)
			var d := side_point(rim[next],bottom,float(ring+1)/layers,size,t,wall)
			quad(st,t*a,t*b,t*c,t*d)
	var mesh := finish_mesh(st)
	for child: Node in solid.get_children():
		if child is VisualInstance3D or child is TerrainShell:
			solid.remove_child(child); child.free()
	var visual := MeshInstance3D.new()
	visual.name="SculptedTerrain"
	visual.mesh=mesh
	visual.material_override=material(section,kind)
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.transform=t.affine_inverse()
	solid.add_child(visual)
	var shadow := MeshInstance3D.new()
	shadow.name="TerrainShadow"
	var shadow_box := BoxMesh.new(); shadow_box.size=size*Vector3(0.96,0.93,0.96)
	shadow.mesh=shadow_box
	if not wall: shadow.position.y=-0.1
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	solid.add_child(shadow)
	# Vertices are in world-local coordinates; bring both render and physics
	# back into this original body's frame, retaining groups and stable paths.
	var collision := solid.get_node("Collision") as CollisionShape3D
	if wall:
		var backup := CollisionShape3D.new(); backup.name="InteriorBackstop"
		var backup_box := BoxShape3D.new(); backup_box.size=size*Vector3(0.98,0.98,0.98)
		backup.shape=backup_box; solid.add_child(backup)
	collision.shape=mesh.create_trimesh_shape()
	collision.transform=t.affine_inverse()
	collision.disabled=false
	solid.set_meta("custom_terrain",true)
	solid.set_meta("terrain_section",section)
	solid.set_meta("terrain_kind",kind)
	stats.terrain_volumes+=1
	if not wall and solid.rotation.length()<0.02 and kind!="sand":
		plant_bank(t,size,section)
	elif kind=="sand" and size.x*size.z<800 and solid.rotation.length()<0.02:
		pebble_bed(t,size,section)
	if wall:
		wall_outcrops(t,size,section)
		var occluder := OccluderInstance3D.new()
		occluder.name="RockOccluder"
		var box := BoxOccluder3D.new()
		box.size=size*Vector3(0.8,0.85,0.8)
		occluder.occluder=box
		solid.add_child(occluder)

func side_point(p: Vector3,bottom: float,f: float,size: Vector3,t: Transform3D,wall: bool) -> Vector3:
	var q := p
	q.y=lerpf(bottom,p.y,f)
	var wave := sin(f*PI)
	var direction := Vector3(p.x/maxf(size.x,0.1),0,p.z/maxf(size.z,0.1)).normalized()
	# Irregular, broad cliff folds replace rows of repeated imported formations.
	# Outward-only relief keeps the retained solid volume inside the new mesh.
	var relief := (0.10+0.5*(noise(t*q)+1.0))*wave
	if wall:
		var along := (t*q).z if size.z>size.x else (t*q).x
		var lobe := 0.5+0.5*sin(along*1.02+sin(along*0.31)*1.6+q.y*0.23)
		relief=(0.16+lobe*1.7+noise(t*q*0.6)*0.18)*pow(maxf(wave,0.0),0.45)*minf(1.0,minf(size.x,size.z))
		if minf(size.x,size.z)<=1.05: relief*=0.18
	else: relief*=0.28
	q+=direction*relief
	return q

func wall_outcrops(t: Transform3D,size: Vector3,section: String) -> void:
	# Planting stays independent from the continuous, sculpted cliff faces.
	if not foliage.has(section): foliage[section]=[]
	if not vines.has(section): vines[section]=[]
	var along_z := size.z>size.x
	var length := maxf(size.x,size.z)
	var count := maxi(1,int(length/3.7))
	for i in range(count):
		var p := t.origin
		var along := (float(i)+0.5)/count*length-length*0.5
		if along_z: p.z+=along
		else: p.x+=along
		p.y+=size.y*0.5+0.15+(noise(p*0.45)+1.0)*0.52
		(foliage[section] as Array).append(p)
		if i%3==1:
			var nearest := route[0]; var distance := INF
			for route_point: Vector3 in route:
				var d := Vector2(p.x,p.z).distance_squared_to(Vector2(route_point.x,route_point.z))
				if d<distance: distance=d; nearest=route_point
			var side := Vector3(signf(nearest.x-p.x),0,0) if along_z else Vector3(0,0,signf(nearest.z-p.z))
			var edge := p+side*(minf(size.x,size.z)*0.5+0.06)
			(vines[section] as Array).append(edge)

func near_route(p: Vector3,clearance: float) -> bool:
	for i in range(route.size()-1):
		var a := Vector2(route[i].x,route[i].z)
		var b := Vector2(route[i+1].x,route[i+1].z)
		if Vector2(p.x,p.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),a,b))<clearance and absf(p.y-route[i].y)<2.0:
			return true
	return false

func plant_bank(t: Transform3D,size: Vector3,section: String) -> void:
	if minf(size.x,size.z)<2.2: return
	if not grass.has(section): grass[section]=[]
	var count := mini(1800,int(size.x*size.z*5.0))
	for i in range(count):
		var p := Vector3(rng.randf_range(-size.x*0.5+0.28,size.x*0.5-0.28),size.y*0.5,rng.randf_range(-size.z*0.5+0.28,size.z*0.5-0.28))
		p=t*p
		if p.y<0.05 or near_route(p,1.05): continue
		if noise(p*0.35)<-0.15: continue
		p.y+=0.015
		(grass[section] as Array).append(Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*rng.randf_range(0.55,1.25)),p))

func pebble_bed(t: Transform3D,size: Vector3,section: String) -> void:
	if not stones.has(section): stones[section]=[]
	for i in range(mini(120,int(size.x*size.z*0.24))):
		var p := t*Vector3(rng.randf_range(-size.x*0.48,size.x*0.48),size.y*0.5,rng.randf_range(-size.z*0.48,size.z*0.48))
		if near_route(p,0.9) or noise(p*0.6)<-0.3: continue
		var s := rng.randf_range(0.10,0.32)
		(stones[section] as Array).append(Transform3D(Basis.from_euler(Vector3(0,rng.randf_range(-PI,PI),0)).scaled(Vector3(s*1.5,s*0.55,s)),p))

func column(label: String,base: Vector3,top: float,radius: float,section: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := maxi(2,ceili((top-base.y)/0.8))
	for y in range(rows):
		for i in range(14):
			var a := column_point(base,top,radius,float(y)/rows,float(i)/14)
			var b := column_point(base,top,radius,float(y)/rows,float(i+1)/14)
			var c := column_point(base,top,radius,float(y+1)/rows,float(i)/14)
			var d := column_point(base,top,radius,float(y+1)/rows,float(i+1)/14)
			quad(st,a,b,c,d)
	var body := StaticBody3D.new()
	body.name=label
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	holder.add_child(body)
	var mesh := finish_mesh(st)
	var visual := MeshInstance3D.new()
	visual.name="SculptedColumn"; visual.mesh=mesh; visual.material_override=material(section,"wall")
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape=mesh.create_trimesh_shape()
	body.add_child(collision)

func column_point(base: Vector3,top: float,radius: float,f: float,a: float) -> Vector3:
	var angle := TAU*a
	var r := radius*(1.0+0.09*sin(a*TAU*3+base.x)+0.05*sin(f*12))
	return Vector3(base.x+cos(angle)*r,lerpf(base.y,top,f),base.z+sin(angle)*r)

func stream_bank(parent: Node3D,side: String) -> void:
	var profiles: Array[PackedVector3Array] = []
	for i in range(50):
		var solid := parent.get_node("Bank%d_%s" % [i,side]) as StaticBody3D
		var t := pose(solid)
		var size := (solid.get_node("Collision").shape as BoxShape3D).size
		var out := t.basis.z.normalized()*(1 if side=="L" else -1)
		var stations: Array = [-size.x*0.5,0.0] if i==0 else [0.0]
		if i==49: stations.append(size.x*0.5)
		for distance: float in stations:
			var p := t.origin+t.basis.x*distance
			var bottom := p.y-size.y*0.5-0.15
			var top := p.y+size.y*0.5+0.25+(noise(p*0.4)+1)*0.4
			var inner := p-out*0.52
			var width := 4.8+noise(p*0.23)*1.1
			profiles.append(PackedVector3Array([
				Vector3(inner.x,bottom,inner.z),
				Vector3(inner.x,lerpf(bottom,top,0.35),inner.z)+out*0.16,
				Vector3(inner.x,lerpf(bottom,top,0.8),inner.z)+out*0.10,
				Vector3(inner.x,top-0.15,inner.z)+out*0.4,
				Vector3(inner.x,top+0.08,inner.z)+out*width*0.45,
				Vector3(inner.x,top-0.35,inner.z)+out*width,
				Vector3(inner.x,bottom,inner.z)+out*width
			]))
		for child: Node in solid.get_children():
			if child is VisualInstance3D or child is TerrainShell:
				solid.remove_child(child); child.free()
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(profiles.size()-1):
		for j in range(6):
			var a := profiles[i][j]; var b := profiles[i+1][j]
			var c := profiles[i][j+1]; var d := profiles[i+1][j+1]
			if side=="R": quad(st,a,c,b,d)
			else: quad(st,a,b,c,d)
	var mesh := finish_mesh(st)
	var body := StaticBody3D.new(); body.name="S06_ChannelBank"+side
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	holder.add_child(body)
	var visual := MeshInstance3D.new(); visual.name="CarvedChannel"
	visual.mesh=mesh; visual.material_override=material("S06","bank"); body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.shape=mesh.create_trimesh_shape(); body.add_child(collision)

func finish() -> void:
	stream_bed()
	var blades := SurfaceTool.new()
	blades.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		var a := float(i)*2.399
		var right := Vector3(cos(a),0,sin(a))*0.055
		var offset := Vector3(sin(a),0,cos(a))*float(i)*0.025
		var tip := offset+Vector3(cos(a)*0.13,0.30+float(i%3)*0.085,sin(a)*0.13)
		blades.set_uv(Vector2(0,0)); blades.add_vertex(offset-right)
		blades.set_uv(Vector2(1,0)); blades.add_vertex(offset+right)
		blades.set_uv(Vector2(0.5,1)); blades.add_vertex(tip)
	var grass_mesh := finish_mesh(blades)
	var curved_grass := grass_blades()
	var grass_mat := ShaderMaterial.new()
	grass_mat.shader=load("res://core/rendering/cascade_grass.gdshader")
	for section: String in grass:
		batch(section+"_Meadow",curved_grass if section in preload("res://dev/living_cascade/cascade_surface_library.gd").POLISHED else grass_mesh,grass[section],grass_mat,true)
		stats.grass_tufts+=(grass[section] as Array).size()
	var pebble := SphereMesh.new()
	pebble.radius=1; pebble.height=2; pebble.radial_segments=9; pebble.rings=4
	for section: String in stones:
		batch(section+"_BedPebbles",pebble,stones[section],material(section,"wall"),false)
		stats.pebbles+=(stones[section] as Array).size()
		var lagoon := LagoonRockKit.model("shore_rock")
		var selected: Array = []
		for i in range(0,(stones[section] as Array).size(),12):
			var t := (stones[section] as Array)[i] as Transform3D
			t.basis=t.basis.scaled(Vector3.ONE*2.4)
			selected.append(t)
		batch(section+"_LagoonStones",lagoon["mesh"] as Mesh,selected,lagoon["material"] as Material,false)
		stats["lagoon_stones"]=int(stats.get("lagoon_stones",0))+selected.size()
	for section: String in foliage:
		if section in preload("res://dev/living_cascade/cascade_surface_library.gd").POLISHED:
			lagoon_planting(section)
			continue
		var field := ScatterField.new()
		field.name=section+"_CliffFerns"
		field.prop_scene=load("res://assets/environment/understory_fern/understory_fern.glb") as PackedScene
		field.surface_material=load("res://core/rendering/materials/forest_canopy.tres")
		var transforms := PackedFloat32Array()
		for p: Vector3 in foliage[section]:
			var b := Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*rng.randf_range(0.8,1.4))
			transforms.append_array(PackedFloat32Array([b.x.x,b.x.y,b.x.z,b.y.x,b.y.y,b.y.z,b.z.x,b.z.y,b.z.z,p.x,p.y,p.z]))
		field.transforms=transforms
		holder.add_child(field)
	holder.set_meta("terrain_statistics",stats)
	print("CUSTOM LANDSCAPE: ",JSON.stringify(stats))

func lagoon_planting(section: String) -> void:
	# Bake the same broad leaf geometry and material used by the starting lagoon.
	var planting := LagoonArt.new()
	planting.entrance_only=true; planting.rng.seed=19291+section.hash()
	planting.leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Vector3 in foliage[section]:
		planting._rosette(p,planting.rng.randf_range(0.85,1.35),7)
	for p: Vector3 in vines[section]:
		planting._vine(p,planting.rng.randf_range(1.8,3.3))
	stats["lagoon_leaves"]=int(stats.get("lagoon_leaves",0))+planting.leaf_count
	planting._finish_leaves(); planting._batch_meshes()
	planting.set_script(null)
	planting.name=section+"_CliffPlanting"
	holder.add_child(planting)

func grass_blades() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var angle := float(i)*2.399
		var forward := Vector3(cos(angle),0,sin(angle))
		var right := Vector3(-sin(angle),0,cos(angle))
		var base := forward*float(i%3)*0.035
		var height := 0.22+float(i%4)*0.046
		for j in range(3):
			var t0 := float(j)/3.0; var t1 := float(j+1)/3.0
			var a := base+Vector3.UP*height*t0+forward*0.17*t0*t0
			var b := base+Vector3.UP*height*t1+forward*0.17*t1*t1
			var width0 := 0.023*(1.0-t0)*sin(0.7+t0*1.3)
			var width1 := 0.023*(1.0-t1)*sin(0.7+t1*1.3)
			for row: Array in [[a-right*width0,Vector2(0,t0)],[a+right*width0,Vector2(1,t0)],[b-right*width1,Vector2(0,t1)]]:
				st.set_uv(row[1]); st.add_vertex(row[0])
			if j<2:
				for row: Array in [[b-right*width1,Vector2(0,t1)],[a+right*width0,Vector2(1,t0)],[b+right*width1,Vector2(1,t1)]]:
					st.set_uv(row[1]); st.add_vertex(row[0])
	return finish_mesh(st)

func batch(label: String,mesh: Mesh,transforms: Array,mat: Material,is_grass: bool) -> void:
	if transforms.is_empty(): return
	var center := Vector3.ZERO
	for t: Transform3D in transforms: center+=t.origin
	center/=float(transforms.size())
	var saved := PackedFloat32Array()
	for i in range(transforms.size()):
		var local := transforms[i] as Transform3D
		local.origin-=center
		var b := local.basis; var p := local.origin
		saved.append_array(PackedFloat32Array([b.x.x,b.x.y,b.x.z,b.y.x,b.y.y,b.y.z,b.z.x,b.z.y,b.z.z,p.x,p.y,p.z]))
	var field := load("res://core/rendering/cascade_mesh_field.gd").new() as ScatterField
	field.name=label; field.position=center
	field.set("source_mesh",mesh); field.surface_material=mat; field.transforms=saved
	field.set_meta("custom_scatter",true)
	field.set_meta("grass",is_grass)
	holder.add_child(field)

func block(label: String,p: Vector3,size: Vector3,section: String,kind: String) -> void:
	var body := StaticBody3D.new(); body.name=label; body.position=p
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	var shape := CollisionShape3D.new(); shape.name="Collision"
	var box := BoxShape3D.new(); box.size=size; shape.shape=box
	body.add_child(shape); holder.add_child(body)
	replace(body,size,section,kind)

func stream_bed() -> void:
	var profile: RefCounted = load("res://core/controller/channel_profile.gd").new()
	profile.source_path="res://worlds/coral_cove/channel_profile.json"
	profile.initialize()
	var rows: Array[PackedVector3Array] = []
	for i in range(profile.points.size()):
		var p: Vector3=profile.points[i]
		var tangent: Vector3=profile.points[mini(i+1,profile.points.size()-1)]-profile.points[maxi(0,i-1)]
		var across := Vector3(-tangent.z,0,tangent.x).normalized()
		var row := PackedVector3Array()
		for j in range(11):
			var v := p+across*(float(j)/10.0-0.5)*8.15
			v.y=float(profile.sample(v)["surface"])-2.8
			row.append(v)
		rows.append(row)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows.size()-1):
		for j in range(10):
			var a := rows[i][j]; var b := rows[i][j+1]
			var c := rows[i+1][j]; var d := rows[i+1][j+1]
			if (c-a).cross(b-a).y>0: quad(st,a,b,c,d)
			else: quad(st,a,c,b,d)
	var mesh := finish_mesh(st)
	var body := StaticBody3D.new(); body.name="S06_ContinuousChannelBed"
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	holder.add_child(body)
	var visual := MeshInstance3D.new(); visual.name="ChannelBed"
	visual.mesh=mesh; visual.material_override=material("S06","sand")
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.shape=mesh.create_trimesh_shape(); body.add_child(collision)
	# One surface avoids overlapping transparent water strips at the bends.
	# Physics/current areas still sample the original shared channel profile.
	var source := mesh.surface_get_arrays(0)
	var vertices := source[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices := source[Mesh.ARRAY_INDEX] as PackedInt32Array
	var water_st := SurfaceTool.new(); water_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,indices.size(),3):
		var a := vertices[indices[i]]; var b := vertices[indices[i+1]]; var c := vertices[indices[i+2]]
		water_triangle(water_st,a,b,c,profile,0)
	var water_mesh := finish_mesh(water_st)
	var water := MeshInstance3D.new(); water.name="S06_ContinuousChannelWater"
	water.mesh=water_mesh; water.material_override=load("res://core/rendering/water_plane.tres")
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(water)
	for old: MeshInstance3D in world.get_node("Sections/S06/Chute").find_children("Surface*","MeshInstance3D",true,false):
		var parent_script := old.get_parent().get_script() as Script
		if parent_script!=null and parent_script.resource_path.ends_with("channel_water_volume.gd"):
			old.get_parent().set_meta("shared_water_surface",old.get_parent().get_path_to(water))
			old.get_parent().remove_child(old); old.free()
	for i in range(50):
		var old := world.get_node("Sections/S06/Chute/Bed%d" % i) as StaticBody3D
		old.remove_meta("custom_terrain")
		for child: Node in old.get_children():
			if child is VisualInstance3D:
				old.remove_child(child); child.free()
			elif child is CollisionShape3D: (child as CollisionShape3D).disabled=true
	stats.terrain_volumes-=49

func water_triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,profile: RefCounted,depth: int) -> void:
	a.y=float(profile.sample(a)["surface"])
	b.y=float(profile.sample(b)["surface"])
	c.y=float(profile.sample(c)["surface"])
	var ab := (a+b)*0.5; var bc := (b+c)*0.5; var ca := (c+a)*0.5
	var error := 0.0
	for p: Vector3 in [ab,bc,ca,(a+b+c)/3.0]:
		error=maxf(error,absf(p.y-float(profile.sample(p)["surface"])))
	if depth<6 and (depth<1 or error>0.025):
		water_triangle(st,a,ab,ca,profile,depth+1)
		water_triangle(st,ab,b,bc,profile,depth+1)
		water_triangle(st,ca,bc,c,profile,depth+1)
		water_triangle(st,ab,bc,ca,profile,depth+1)
	else:
		for p: Vector3 in [a,b,c]:
			st.set_uv(Vector2(p.x,p.z)); st.add_vertex(p)

func water_plane(label: String,p: Vector3,size: Vector2) -> void:
	var mesh := PlaneMesh.new(); mesh.size=size
	var visual := MeshInstance3D.new(); visual.name=label; visual.position=p
	visual.mesh=mesh
	var mat := load("res://core/rendering/water_surface.tres").duplicate() as ShaderMaterial
	mat.set_shader_parameter("mesh_is_surface",true)
	mat.set_shader_parameter("wave_height",0.015)
	mat.set_shader_parameter("flow_velocity",Vector2(0,1.1))
	visual.material_override=mat
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(visual)

func waterfall_sources() -> void:
	# Seal the sides of the lagoon connection, leaving the swim corridor open.
	block("S01_InletWestShoulder",Vector3(-4.75,-0.2,5.8),Vector3(2,7.2,4.8),"S01","wall")
	block("S01_InletEastShoulder",Vector3(4.3,-0.2,5.8),Vector3(2,7.2,4.8),"S01","wall")
	block("S05_HeadwaterBed",Vector3(23,11.3,-113.5),Vector3(8.4,8,8.2),"S05","sand")
	block("S05_HeadwaterWestRim",Vector3(18.4,15.1,-114),Vector3(1,2.6,9.2),"S05","wall")
	block("S05_HeadwaterEastRim",Vector3(27.6,15.1,-114),Vector3(1,2.6,9.2),"S05","wall")
	water_plane("S05_HeadwaterFlow",Vector3(23,15.55,-113.8),Vector2(8,9.3))
	water_plane("S05_ShallowRunoff",Vector3(23,6.85,-106.7),Vector2(2.5,5.7))
	for n: MeshInstance3D in world.find_children("CrownWaterfall*","MeshInstance3D",true,false):
		n.position.y=11.18; n.position.z=-109.10
		var sheet := QuadMesh.new(); sheet.size=Vector2(1.6,8.72); n.mesh=sheet
	var drop := MeshInstance3D.new(); drop.name="S05_BasinInflow"
	var drop_mesh := QuadMesh.new(); drop_mesh.size=Vector2(2.5,0.65)
	drop.mesh=drop_mesh; drop.position=Vector3(23,6.52,-103.84)
	var fall_mat := ShaderMaterial.new(); fall_mat.shader=load("res://core/rendering/cascade_sheet.gdshader")
	drop.material_override=fall_mat; drop.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; holder.add_child(drop)
	block("S04_HeadwaterBed",Vector3(8,3.15,-90),Vector3(8,7,8),"S04","sand")
	water_plane("S04_HeadwaterFlow",Vector3(8,6.82,-90),Vector2(6.7,8.2))
	block("S04_HeadwaterRimWest",Vector3(3.8,6.8,-90),Vector3(1.2,2.4,8),"S04","wall")
	block("S04_HeadwaterRimEast",Vector3(12.2,6.8,-91),Vector3(1.0,2.4,6),"S04","wall")
	for n: MeshInstance3D in world.find_children("ScenicWaterfall*","MeshInstance3D",true,false):
		n.position.y=2.46
		var sheet := QuadMesh.new(); sheet.size=Vector2(1.2,8.68); n.mesh=sheet
	water_plane("S04_ImpactPool",Vector3(8,-1.85,-83),Vector2(8,6))
