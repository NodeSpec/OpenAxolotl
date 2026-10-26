extends RefCounted
## Bake local water depth into unused terrain vertex colour channels.
## Geometry, collision, planting masks and runtime water authority stay intact.
var world: Node3D
var zones: Array[Dictionary] = []
var materials: Dictionary = {}
var stats := {"meshes":0,"vertices":0,"submerged_vertices":0,"sections":{}}

func pose(node: Node3D) -> Transform3D:
	var t := node.transform
	var parent := node.get_parent()
	while parent!=world and parent is Node3D:
		t=(parent as Node3D).transform*t
		parent=parent.get_parent()
	return t

func collect(target: Node3D) -> void:
	world=target
	zones.clear()
	var channels: Dictionary = {}
	for volume: WaterVolume in world.find_children("*","WaterVolume",true,false):
		var vt := pose(volume)
		var zone := {"pose":vt,"inverse":vt.affine_inverse(),"height":volume.surface_height,"gradient":volume.surface_gradient,"priority":volume.water_priority,"boxes":[],"profile":null}
		var script := volume.get_script() as Script
		var is_channel := script!=null and script.resource_path.ends_with("channel_water_volume.gd")
		if is_channel:
			var path := String(volume.get("profile_path"))
			if channels.has(path):
				zone=channels[path]
			else:
				var profile := preload("res://core/controller/channel_profile.gd").new()
				profile.source_path=path; profile.initialize()
				zone["profile"]=profile
				zone["pose"]=pose(volume.get_parent() as Node3D)
				zone["inverse"]=(zone["pose"] as Transform3D).affine_inverse()
				channels[path]=zone
				zones.append(zone)
		elif not volume.explicit_surface:
			var found := false
			for visual: MeshInstance3D in volume.find_children("*","MeshInstance3D",true,false):
				if visual.mesh is BoxMesh:
					var mt := pose(visual)
					zone["height"]=(mt*Vector3(0,(visual.mesh as BoxMesh).size.y*0.5,0)).y-vt.origin.y
					found=true; break
			if not found: continue
		if not is_channel: zones.append(zone)
		for shape: CollisionShape3D in volume.find_children("*","CollisionShape3D",true,false):
			if shape.disabled or not shape.shape is BoxShape3D: continue
			var t := pose(shape)
			zone["boxes"].append({"inverse":t.affine_inverse(),"half":(shape.shape as BoxShape3D).size*0.5})
	# Scenic source pools have visible water but intentionally no gameplay Area.
	for visual: MeshInstance3D in world.get_node("CustomLandscape").find_children("*","MeshInstance3D",true,false):
		if not visual.mesh is PlaneMesh: continue
		if not String(visual.name) in ["S04_HeadwaterFlow","S04_ImpactPool","S05_HeadwaterFlow","S05_ShallowRunoff"]: continue
		var t := pose(visual)
		var size := (visual.mesh as PlaneMesh).size
		zones.append({"pose":t,"inverse":t.affine_inverse(),"height":0.0,"gradient":Vector2.ZERO,"priority":100,"profile":null,"boxes":[{"inverse":t.affine_inverse(),"half":Vector3(size.x*0.5,0.5,size.y*0.5)}]})

func sample(point: Vector3) -> Dictionary:
	var selected := false
	var best_priority := -100000
	var height := -INF
	var nearest_distance := INF
	var nearest_height := -INF
	for zone: Dictionary in zones:
		var inside := false
		var zone_distance := INF
		for box: Dictionary in zone["boxes"]:
			var p: Vector3=(box["inverse"] as Transform3D)*point
			var half: Vector3=box["half"]
			# A narrow tolerance includes the bed skin. The lower bound keeps a
			# raised source pool from tinting unrelated ground beneath it.
			if p.y< -half.y-0.40:continue
			zone_distance=minf(zone_distance,Vector2(maxf(absf(p.x)-half.x,0),maxf(absf(p.z)-half.z,0)).length_squared())
			if absf(p.x)<=half.x+0.08 and absf(p.z)<=half.z+0.08:
				inside=true;break
		if not inside and zone_distance>=nearest_distance: continue
		var local: Vector3=(zone["inverse"] as Transform3D)*point
		var surface: float=zone["height"]
		if zone["profile"]!=null:
			surface=float(zone["profile"].sample(local)["surface"])
		else:
			surface+=(zone["gradient"] as Vector2).dot(Vector2(local.x,local.z))
		surface=((zone["pose"] as Transform3D)*Vector3(local.x,surface,local.z)).y
		if zone_distance<nearest_distance:
			nearest_distance=zone_distance;nearest_height=surface
		if not inside:continue
		var priority := int(zone["priority"])
		if not selected or priority>best_priority or (priority==best_priority and surface>height):
			selected=true;best_priority=priority;height=surface
	# Keep the depth field continuous across shoreline triangles. Coverage still
	# prevents the neighbouring dry ground from receiving underwater shading.
	var reference := height if selected else nearest_height
	return {"covered":selected,"depth":reference-point.y if not is_inf(reference) else -4.0,"surface":reference}

func apply(target: Node3D) -> void:
	collect(target)
	for visual: MeshInstance3D in world.find_children("*","MeshInstance3D",true,false):
		var mat := visual.material_override as ShaderMaterial
		if mat==null or not mat.shader.resource_path.ends_with("cascade_pbr_ground.gdshader"): continue
		# Only authored floor, ramp and bank meshes; leave wall and prop materials.
		if not String(visual.name) in ["SculptedTerrain","ChannelBed","CarvedChannel"]: continue
		if float(mat.get_shader_parameter("surface_kind"))>=1.5: continue
		var source := visual.mesh as ArrayMesh
		if source==null: continue
		var mesh := ArrayMesh.new()
		var transform := pose(visual)
		var section := String((visual.get_parent() as Node).get_meta("terrain_section","S06"))
		for i in range(source.get_surface_count()):
			var arrays := source.surface_get_arrays(i)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
			if colors.size()!=vertices.size():colors.resize(vertices.size());colors.fill(Color(0,0,0,1))
			for v in range(vertices.size()):
				var row := sample(transform*vertices[v])
				var color := colors[v]
				color.g=clampf((float(row["depth"])+4.0)/8.0,0.0,1.0)
				color.b=1.0 if row["covered"] else 0.0
				colors[v]=color
				stats["vertices"]+=1
				if row["covered"] and float(row["depth"])>0:stats["submerged_vertices"]+=1
			arrays[Mesh.ARRAY_COLOR]=colors
			mesh.add_surface_from_arrays(source.surface_get_primitive_type(i),arrays)
			mesh.surface_set_material(i,source.surface_get_material(i))
		visual.mesh=mesh
		if not materials.has(mat):
			var detailed := mat.duplicate() as ShaderMaterial
			detailed.set_shader_parameter("depth_blend_enabled",true)
			materials[mat]=detailed
		visual.material_override=materials[mat]
		stats["meshes"]+=1
		stats["sections"][section]=int(stats["sections"].get(section,0))+1
	world.get_node("CustomLandscape").set_meta("ground_depth_statistics",stats)
	print("GROUND DEPTH: ",JSON.stringify(stats))
