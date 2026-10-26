extends Node3D
## Cosmetic mechanical fragments. Shared meshes, bounded lifetime, no player collision.
static var _cache: Dictionary = {}
static var _sound: AudioStreamWAV
var _age := 0.0
var _parts: Array[RigidBody3D] = []

static func fragments(mesh: Mesh, split: bool) -> Array:
	var key := str(mesh.get_instance_id()) + str(split)
	if _cache.has(key): return _cache[key]
	var result: Array = []
	var bounds := mesh.get_aabb()
	var center := bounds.get_center()
	for cluster: int in (4 if split else 1):
		var piece := ArrayMesh.new()
		for surface: int in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(mesh.surface_get_material(surface))
			var count := 0
			for i: int in range(0, indices.size() if not indices.is_empty() else vertices.size(), 3):
				var ids: Array[int] = []
				for j: int in 3: ids.append(indices[i+j] if not indices.is_empty() else i+j)
				var mid := (vertices[ids[0]]+vertices[ids[1]]+vertices[ids[2]])/3.0
				if split and (int(mid.x>center.x)+2*int(mid.y>center.y)) != cluster: continue
				for id: int in ids:
					if a[Mesh.ARRAY_NORMAL] != null and a[Mesh.ARRAY_NORMAL].size()>id: st.set_normal(a[Mesh.ARRAY_NORMAL][id])
					if a[Mesh.ARRAY_TEX_UV] != null and a[Mesh.ARRAY_TEX_UV].size()>id: st.set_uv(a[Mesh.ARRAY_TEX_UV][id])
					if a[Mesh.ARRAY_COLOR] != null and a[Mesh.ARRAY_COLOR].size()>id: st.set_color(a[Mesh.ARRAY_COLOR][id])
					st.add_vertex(vertices[id]-center); count+=1
			if count>0: st.commit(piece)
		if piece.get_surface_count()>0: result.append({"mesh":piece,"center":center})
	_cache[key]=result
	return result

func burst(visual: Node3D, underwater: bool, direction: Vector3) -> void:
	var rng:=RandomNumberGenerator.new(); rng.seed=visual.get_instance_id()
	for source: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
		if source.name.begins_with("Cable") or source.mesh==null: continue
		for data: Dictionary in fragments(source.mesh,source.name==&"Chassis"):
			var body:=RigidBody3D.new(); body.collision_layer=0; body.collision_mask=1
			body.mass=.25; body.gravity_scale=.22 if underwater else 1.0; body.linear_damp=1.1 if underwater else .3
			var shape:=CollisionShape3D.new(); var sphere:=SphereShape3D.new(); sphere.radius=.13; shape.shape=sphere; body.add_child(shape)
			var mesh:=MeshInstance3D.new(); mesh.mesh=data.mesh; mesh.material_override=source.material_override; body.add_child(mesh)
			add_child(body); body.global_transform=source.global_transform * Transform3D(Basis.IDENTITY,data.center)
			for hero: Node in get_tree().get_nodes_in_group("player"):
				if hero is PhysicsBody3D: body.add_collision_exception_with(hero)
			body.linear_velocity=Vector3(rng.randf_range(-2,2),rng.randf_range(2.5,4),rng.randf_range(-2,2))+direction*1.5
			body.angular_velocity=Vector3(rng.randf_range(-5,5),rng.randf_range(-5,5),rng.randf_range(-5,5))
			_parts.append(body)
	if _sound==null:
		_sound=AudioStreamWAV.new(); _sound.mix_rate=22050; _sound.format=AudioStreamWAV.FORMAT_16_BITS
		var samples:=PackedByteArray(); samples.resize(17640*2)
		for i: int in 17640:
			var t:=float(i)/22050.0
			var v:=(sin(t*TAU*430)+.6*sin(t*TAU*731)+.3*sin(t*TAU*1267))*exp(-t*11)*.22
			v+=rng.randf_range(-.2,.2)*exp(-t*25)
			samples.encode_s16(i*2,int(clampf(v,-1,1)*32760))
		_sound.data=samples
	var sound:=AudioStreamPlayer3D.new(); sound.stream=_sound; sound.max_distance=16; sound.volume_db=-7; sound.bus="Effects" if AudioServer.get_bus_index("Effects")>=0 else "Master"; add_child(sound); sound.global_position=visual.global_position; sound.play()

func _process(delta: float) -> void:
	_age+=delta
	if _age>2.3:
		for part: RigidBody3D in _parts:
			(part.get_child(1) as Node3D).scale=Vector3.ONE*maxf(.001,1.0-(_age-2.3)/.7)
	if _age>=3.0: queue_free()
