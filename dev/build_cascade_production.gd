extends SceneTree
var world: Node3D
var dressing: Node3D
var rng := RandomNumberGenerator.new()
var bark: Material
var leaves: Material
var flowers: Material
func _initialize() -> void:
	call_deferred("build")
func build() -> void:
	rng.seed=71423
	world=(load("res://dev/living_cascade/blockout.tscn") as PackedScene).instantiate() as Node3D
	world.name="LivingCascade"
	world.get_node("Sections/S01/JOIN_00").remove_from_group("stream_entry")
	for path: String in ["Axolotl","Camera","Lighting","PreviewSession","Containment/InletEnd","Sections/S01/EntryBackstop"]:
		erase(world.get_node(path))
	for i in range(6):
		erase(world.get_node("Sections/S05/RestorationGarden/Crown%d" % i))
	# The lagoon inlet stays open; flanking walls still contain its 6m channel.
	var outer := world.get_node("Containment/OuterNorth") as Node3D
	var template := outer.duplicate() as Node3D
	erase(outer)
	for row: Array in [[-23.5,37.0],[22.0,36.0]]:
		var n := template.duplicate() as Node3D
		n.name="InletFlank%d" % int(row[0])
		n.position.x=float(row[0])
		(n.get_node("Mesh") as MeshInstance3D).mesh=(n.get_node("Mesh") as MeshInstance3D).mesh.duplicate()
		((n.get_node("Mesh") as MeshInstance3D).mesh as BoxMesh).size.x=float(row[1])
		(n.get_node("Collision") as CollisionShape3D).shape=(n.get_node("Collision") as CollisionShape3D).shape.duplicate()
		((n.get_node("Collision") as CollisionShape3D).shape as BoxShape3D).size.x=float(row[1])
		world.get_node("Containment").add_child(n)
	template.free()
	for path: String in ["Sections/S02/Garden","Sections/S03/RootDive","Sections/S04/Terraces"]:
		world.get_node(path).set_script(null)
	for n: Node in world.find_children("*","",true,false):
		if n is Label3D:
			(n as Label3D).visible=false
		if n is WaterVolume and n.get_script().resource_path.begins_with("res://dev/"):
			n.set_script(load("res://core/controller/channel_water_volume.gd"))
			n.set("profile_path","res://worlds/coral_cove/channel_profile.json")
		if n is Area3D and n.has_meta("collectible_id"):
			n.add_to_group("collectible",true)
			if String(n.get_meta("collectible_id"))=="kelp_seed":
				n.set_meta("resource_instance_id",String(world.get_path_to(n)))
			for visual: Node in n.find_children("*","MeshInstance3D",true,false):
				visual.set_script(load("res://core/rendering/presentation_motion.gd"))
				visual.set("bob_height_m",0.12)
				visual.set("yaw_speed_deg_per_s",24.0)
	for id: String in ["CP_01","CP_02","CP_03"]:
		var marker := world.find_child(id,true,false) as Marker3D
		var area := Area3D.new()
		area.name=id
		area.position=marker.position+Vector3.UP*0.85
		area.collision_layer=0
		area.collision_mask=1
		area.add_to_group("checkpoint",true)
		var parent := marker.get_parent()
		erase(marker)
		parent.add_child(area)
		shape(area,Vector3(4,2,4))
	var spawn := Marker3D.new()
	spawn.name="SpawnPoint"
	spawn.position=Vector3(0,-0.4,1)
	spawn.add_to_group("spawn_point",true)
	world.add_child(spawn)
	var stream := Marker3D.new()
	stream.name="StreamEntry"
	stream.add_to_group("stream_entry",true)
	world.add_child(stream)
	var gate := world.get_node("Sections/S05/RestorationGarden/Gate")
	gate.add_to_group("restoration_gate",true)
	gate.set_meta("region_id","coral_shelf")
	gate.set_meta("gate_id","cascade_finale")
	var pit := Area3D.new()
	pit.name="SafetyRecovery"
	pit.position=Vector3(-1,-6.0,-60.5)
	pit.collision_layer=0
	pit.collision_mask=1
	pit.add_to_group("safe_return_volume",true)
	world.add_child(pit)
	# Limit recovery to this level and a 20 m escape margin so it cannot
	# intercept falls in the connected lagoon or another loaded world.
	shape(pit,Vector3(126,5,177))
	# The visible foundation overlaps every wall foot and inlet seam. The
	# nonlethal return begins below the deepest authored bed. It also clears
	# inaccessible pockets on the backup floor without charging a life.
	var foundation := world.get_node("Containment/ContinuousFoundation") as StaticBody3D
	foundation.position.y=-5.25
	var foundation_mesh := (foundation.get_node("Mesh") as MeshInstance3D)
	foundation_mesh.mesh=foundation_mesh.mesh.duplicate()
	(foundation_mesh.mesh as BoxMesh).size=Vector3(86,3,137)
	var foundation_collision := foundation.get_node("Collision") as CollisionShape3D
	foundation_collision.shape=foundation_collision.shape.duplicate()
	(foundation_collision.shape as BoxShape3D).size=Vector3(86,3,137)
	for solid: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		solid.collision_layer |= SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	# Existing procedural terrain materials keep land, moss and submerged beds distinct.
	for mesh: MeshInstance3D in world.find_children("*","MeshInstance3D",true,false):
		if mesh.get_parent() is StaticBody3D:
			var id := String(mesh.get_parent().name).to_lower()
			mesh.material_override=load("res://core/rendering/terrain/mossy_stone.tres")
			if "bed" in id or "foundation" in id:
				mesh.material_override=load("res://core/rendering/terrain/river_sand.tres")
			if "wall" in id or "ridge" in id or "boundary" in id:
				mesh.material_override=load("res://core/rendering/terrain/mossy_stone.tres")
	dressing=Node3D.new()
	dressing.name="Dressing"
	world.add_child(dressing)
	prepare_water()
	prepare_land()
	bark=mat(Color(0.26,0.16,0.075))
	leaves=mat(Color(0.28,0.48,0.15))
	flowers=mat(Color(1.0,0.55,0.42))
	# Authored landmark: a broad root bridge, rising crown and separate scenic cascade.
	arch("RootBridge",Vector3(-7,4,-54),25,10,1.4)
	arch("Crown",Vector3(15,6.8,-97),12,6.5,0.85)
	branch("RisingRoot",Vector3(2,1,-59),Vector3(10,18,-97),1.4)
	branch("RisingRootEast",Vector3(38,1,-60),Vector3(35,17,-97),1.8)
	for i in range(20):
		var t := float(i)/19.0*PI
		var p := Vector3(15+cos(t)*12,6.8+sin(t)*6.5,-97)
		var bloom := ball("CrownBloom%d" % i,p,Vector3(1.2,0.8,1.1),flowers)
		bloom.set_script(load("res://core/rendering/restoration_bloom.gd"))
		bloom.set("region_id","coral_shelf")
	var cascade_material := ShaderMaterial.new()
	cascade_material.shader=load("res://core/rendering/cascade_sheet.gdshader")
	for i in range(7):
		var mesh := MeshInstance3D.new()
		mesh.name="ScenicWaterfall%d" % i
		var plane := QuadMesh.new()
		plane.size=Vector2(1.2,11.0-float(i%3)*0.2)
		mesh.mesh=plane
		mesh.material_override=cascade_material
		mesh.position=Vector3(5+float(i),1.3,-86+float(i%2)*0.2)
		dressing.add_child(mesh)
	scatter("ArrivalFerns","understory_fern",Vector3(5,0.4,-12),Vector3(1,0,4),20,1.3,true)
	scatter("GardenFerns","understory_fern",Vector3(-30,0.4,-32),Vector3(2,0,10),42,1.5,true)
	scatter("TerraceReeds","river_reed",Vector3(36,4.4,-79),Vector3(0.7,0,7),24,0.8,true)
	scatter("CrownFerns","understory_fern",Vector3(33,6.8,-100),Vector3(1,0,6),32,1.6,true)
	scatter("FinishFerns","understory_fern",Vector3(-33,1,-100),Vector3(3,0,0.7),20,1.2,true)
	scatter("GardenRocks","river_boulder",Vector3(-34,0.4,-33),Vector3(1,0,11),12,0.7,false)
	scatter("CentralGrove","canopy_tree",Vector3(9,-4.2,-33),Vector3(10,0,9),16,0.85,true)
	for i in range(8):
		ball("CascadeCliff%d" % i,Vector3(3+float(i)*1.4,0.8,-89),Vector3(1.6,6.5+rng.randf(),3.0),load("res://core/rendering/terrain/mossy_stone.tres"))
	for i in range(24):
		var side := -37.0 if i%2==0 else 39.0
		var p := Vector3(side,6,-8-float(i/2)*8)
		ball("Cliff%d" % i,p,Vector3(4,8+rng.randf_range(0,3),5),load("res://core/rendering/terrain/mossy_stone.tres"))
		ball("Canopy%d" % i,p+Vector3(0,9,0),Vector3(5,3,5),leaves)
		for lobe in range(3):
			ball("CanopyLobe%d_%d" % [i,lobe],p+Vector3(rng.randf_range(-3,3),10+rng.randf(),rng.randf_range(-3,3)),Vector3(3.4,2.5,3.4),leaves)
	for row: Array in [["ArrivalView",Vector3(-3,1,-8),Vector3(14,5,12),4.5,12.0],["GardenView",Vector3(-22,2,-32),Vector3(16,5,24),4.5,20.0],["RootView",Vector3(-12,-1,-56),Vector3(32,4,12),4.0,5.0],["TerraceView",Vector3(25,5,-74),Vector3(20,10,28),4.6,18.0],["CrownView",Vector3(22,8,-101),Vector3(26,5,16),6.5,8.0],["FinishView",Vector3(-31,1,-105),Vector3(20,5,14),4.5,15.0]]:
		var hint := CameraHintVolume.new()
		hint.name=String(row[0])
		hint.position=row[1] as Vector3
		hint.collision_layer=0
		hint.collision_mask=1
		hint.hint_priority=10
		hint.override_distance=true
		hint.distance_m=float(row[3])
		hint.override_pitch=true
		hint.pitch_deg=float(row[4])
		world.add_child(hint)
		shape(hint,row[2] as Vector3)
	# Keep only player-facing guidance; development coordinates remain in the dev scene.
	label("GardenGuidance",Vector3(29,8.5,-101),"Restore the crown")
	label("DiveGuidance",Vector3(-2,7,-110),"Dive beneath the root")
	label("FinishGuidance",Vector3(-38,3,-110),"The Living Cascade")
	preload("res://dev/living_cascade/cascade_asset_dressing.gd").new().apply(world)
	preload("res://dev/living_cascade/cascade_ground_depth.gd").new().apply(world)
	if not world.has_node("CustomLandscape") or not world.has_node("SuppliedAssets") or not world.get_node("CustomLandscape").has_meta("terrain_statistics") or not world.get_node("CustomLandscape").has_meta("ground_depth_statistics"):
		push_error("Custom terrain build incomplete; keeping the existing production scene.")
		world.free()
		quit(1)
		return
	for n: Node in world.find_children("*","",true,false):
		# Retain imported GLB instances and their internal owners. Baking these
		# meshes into the level would duplicate the asset data and detach updates.
		if n.has_meta("cascade_asset_instance"):
			n.owner=world
			if String(n.get_parent().get_meta("source_asset",""))=="reef_arch":
				world.set_editable_instance(n,true)
			continue
		var ancestor := n.get_parent()
		var imported_child := false
		while ancestor!=null and ancestor!=world:
			if ancestor.has_meta("cascade_asset_instance"):
				imported_child=true
				break
			ancestor=ancestor.get_parent()
		if imported_child:
			continue
		if (n is MultiMeshInstance3D and n.get_parent() is ScatterField) or n.get_parent() is TerrainShell:
			continue # ScatterField rebuilds this runtime child from its saved transforms.
		n.owner=world
		if n is Node3D:
			(n as Node3D).scene_file_path=""
	world.scene_file_path=""
	var packed := PackedScene.new()
	var result := packed.pack(world)
	if result==OK:
		result=ResourceSaver.save(packed,"res://worlds/coral_cove/world.tscn")
	print("PRODUCTION PACK: ",result," / nodes ",world.find_children("*","",true,false).size())
	world.free()
	quit(0 if result==OK else 1)

func erase(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()
func shape(parent: Node, size: Vector3) -> void:
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size=size
	c.shape=s
	parent.add_child(c)
func mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.88
	return m
func ball(id: String,p: Vector3,scale_value: Vector3,m: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name=id
	n.position=p
	n.scale=scale_value
	var mesh := SphereMesh.new()
	mesh.radius=1
	mesh.height=2
	mesh.radial_segments=12
	mesh.rings=6
	n.mesh=mesh
	n.material_override=m
	dressing.add_child(n)
	return n
func branch(id: String,a: Vector3,b: Vector3,r: float) -> void:
	var n := MeshInstance3D.new()
	n.name=id
	var mesh := CylinderMesh.new()
	mesh.top_radius=r*0.7
	mesh.bottom_radius=r
	mesh.height=a.distance_to(b)
	mesh.radial_segments=12
	n.mesh=mesh
	n.material_override=bark
	n.position=(a+b)*0.5
	n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	dressing.add_child(n)
func arch(id: String,c: Vector3,w: float,h: float,r: float) -> void:
	for i in range(16):
		var a := float(i)/16*PI
		var b := float(i+1)/16*PI
		branch(id+str(i),c+Vector3(cos(a)*w,sin(a)*h,0),c+Vector3(cos(b)*w,sin(b)*h,0),r)
		ball(id+"Knot"+str(i),c+Vector3(cos(a)*w,sin(a)*h,0),Vector3.ONE*r,bark)
func fern(p: Vector3,s: float) -> void:
	for i in range(5):
		var a := float(i)*TAU/5
		ball("Foliage",p+Vector3(cos(a)*s,0.3,sin(a)*s),Vector3(s,0.18,s*0.4),leaves)
	ball("Flower",p+Vector3(0,0.6,0),Vector3(0.2,0.2,0.2),flowers)
func label(id: String,p: Vector3,text: String) -> void:
	var n := Label3D.new()
	n.name=id
	n.position=p
	n.text=text
	n.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	n.pixel_size=0.006
	n.font_size=32
	dressing.add_child(n)

func scatter(id: String,prop: String,center: Vector3,spread: Vector3,count: int,size: float,wind: bool) -> void:
	var field := ScatterField.new()
	field.name=id
	field.prop_scene=load("res://assets/environment/%s/%s.glb" % [prop,prop])
	if wind:
		field.surface_material=load("res://core/rendering/materials/forest_canopy.tres")
	var values := PackedFloat32Array()
	for i in range(count):
		var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size*rng.randf_range(0.8,1.2))
		var p := center+Vector3(rng.randf_range(-spread.x,spread.x),0,rng.randf_range(-spread.z,spread.z))
		values.append_array(PackedFloat32Array([basis.x.x,basis.x.y,basis.x.z,basis.y.x,basis.y.y,basis.y.z,basis.z.x,basis.z.y,basis.z.z,p.x,p.y,p.z]))
	field.transforms=values
	dressing.add_child(field)

func prepare_water() -> void:
	var chute := world.get_node("Sections/S06/Chute")
	for node: Node in chute.get_children():
		if node is MeshInstance3D and String(node.name).begins_with("Surface"):
			var suffix := String(node.name).trim_prefix("Surface")
			var volume := chute.get_node_or_null("Water"+suffix) as Node3D
			if volume == null:
				volume=chute.get_node_or_null("Junction"+suffix) as Node3D
			if volume != null:
				var original := (node as Node3D).transform
				node.owner=null
				chute.remove_child(node)
				volume.add_child(node)
				(node as Node3D).transform=volume.transform.affine_inverse()*original
	for volume: WaterVolume in world.find_children("*","WaterVolume",true,false):
		for mesh: MeshInstance3D in volume.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh is PlaneMesh:
				var plane := mesh.mesh.duplicate() as PlaneMesh
				var cell := 0.2 if mesh.get_parent().get_script().resource_path.ends_with("channel_water_volume.gd") else 1.5
				plane.subdivide_width=maxi(4,ceili(plane.size.x/cell))
				plane.subdivide_depth=maxi(4,ceili(plane.size.y/cell))
				mesh.mesh=plane
				if volume.get_script().resource_path.ends_with("channel_water_volume.gd"):
					mesh.mesh=channel_mesh(plane,mesh,volume)
				mesh.material_override=load("res://core/rendering/water_plane.tres")
		var shapes := volume.find_children("*","CollisionShape3D",true,false)
		if shapes.is_empty():
			continue
		var c := shapes[0] as CollisionShape3D
		var box := c.shape as BoxShape3D
		if box == null:
			continue
		var particles := GPUParticles3D.new()
		particles.name="Bubbles"
		particles.amount=4
		particles.lifetime=2.5
		particles.transform=c.transform
		particles.visibility_aabb=AABB(-box.size*0.5,box.size)
		particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var process := ParticleProcessMaterial.new()
		process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
		process.emission_box_extents=Vector3(box.size.x*0.4,0.1,box.size.z*0.4)
		process.direction=Vector3.UP
		process.gravity=Vector3.ZERO
		process.initial_velocity_min=0.15
		process.initial_velocity_max=0.3
		particles.process_material=process
		var bubble := SphereMesh.new()
		bubble.radius=0.035
		bubble.height=0.07
		bubble.radial_segments=6
		bubble.rings=3
		bubble.material=mat(Color(0.55,0.87,0.91))
		particles.draw_pass_1=bubble
		volume.add_child(particles)

func channel_mesh(plane: PlaneMesh,visual: MeshInstance3D,volume: WaterVolume) -> ArrayMesh:
	var profile := preload("res://core/controller/channel_profile.gd").new()
	profile.source_path="res://worlds/coral_cove/channel_profile.json"
	var arrays := plane.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var placed := volume.transform*visual.transform
	for i in range(vertices.size()):
		var point := placed*vertices[i]
		var sample := profile.sample(point)
		point.y=float(sample["surface"])
		vertices[i]=placed.affine_inverse()*point
		var slope := sample["slope"] as Vector2
		normals[i]=(placed.basis.inverse()*Vector3(-slope.x,1,-slope.y)).normalized()
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func prepare_land() -> void:
	for solid: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		var visual := solid.get_node_or_null("Mesh") as MeshInstance3D
		if visual == null or not visual.mesh is BoxMesh:
			continue
		var box := visual.mesh as BoxMesh
		var id := String(solid.name).to_lower()
		if box.size.y>2.0 or "bed" in id or "roof" in id or "foundation" in id or box.size.x<2 or box.size.z<2:
			continue
		var shell := TerrainShell.new()
		shell.name="TerrainSkin"
		shell.rim_margin=0.10
		shell.rim_drop=0.08
		shell.skirt_depth=0.05
		shell.surface_material=visual.material_override
		shell.shell_seed=String(world.get_path_to(solid)).hash()%999
		solid.add_child(shell)
		shell._rebuild()
		visual.visible=false
