extends RefCounted
## Baked terrain closures. Preserve swim lanes, ramps, pickups and the lagoon inlet.
var world: Node3D
var holder: Node3D
var terrain: RefCounted
var core_count := 0

func apply(target: Node3D) -> void:
	world=target
	var old:=world.get_node_or_null("BasinSeals")
	if old!=null:world.remove_child(old);old.free()
	holder=Node3D.new();holder.name="BasinSeals";world.add_child(holder)
	terrain=preload("res://dev/living_cascade/cascade_landscape.gd").new()
	terrain.world=world;terrain.holder=holder
	for waypoint: RoutePilot.Waypoint in CoralRoute.waypoints():terrain.route.append(waypoint.target)
	# These shoulders close measured breaches, not the intended water entrances.
	block("GardenFarShore",Vector3(-30.1,-1.8,-43.45),Vector3(8.6,5.2,6.0),"S02","bank")
	block("GardenApproachSeam",Vector3(-29.1,-2.0,-22.15),Vector3(10.6,4.8,2.8),"S02","bank")
	block("RootExitSouthSeal",Vector3(14.8,-.1,-53.1),Vector3(6.8,8.6,1.2),"S03","wall")
	block("RootExitNorthSeal",Vector3(14.8,-.1,-59.7),Vector3(6.8,8.6,1.2),"S03","wall")
	block("PoolAWestShoulder",Vector3(12.7,-1.0,-66.85),Vector3(2.8,6.8,5.1),"S04","bank")
	block("PoolABackCliff",Vector3(16.0,.65,-69.8),Vector3(9.2,10.5,.8),"S04","wall")
	block("PoolBEntryShoulder",Vector3(29.4,0,-78.75),Vector3(7.8,8.8,2.6),"S04","bank")
	block("CatchPoolNorthRim",Vector3(20.45,1.5,-85.4),Vector3(11.3,11.8,.8),"S04","wall")
	block("CatchPoolNorthApron",Vector3(20.5,-1.7,-86.1),Vector3(11.4,5.4,2.5),"S04","sand")
	block("PoolCNorthRim",Vector3(13.5,2.3,-82.65),Vector3(3.5,13.4,.8),"S04","wall")
	block("CrownBasinWestSeal",Vector3(17.0,1.15,-101),Vector3(2.35,11.1,6.6),"S05","bank")
	# Join the existing B catch pool to the side channel beneath the exit bank.
	block("PoolBConnectedCatchBed",Vector3(29.55,-1.7,-89.85),Vector3(7.4,5.4,6.7),"S04","sand")
	var catch_water:=world.get_node("Sections/S04/Terraces/PoolBCatch") as WaterVolume
	var volume:=catch_water.get_node("Collision") as CollisionShape3D
	var shape:=volume.shape.duplicate() as BoxShape3D
	# Existing catch covers x=15..26; extend its east edge to the side pool at 33.
	shape.size.x=18.2;volume.shape=shape
	catch_water.position.x=24.1
	for surface: MeshInstance3D in catch_water.find_children("*","MeshInstance3D",true,false):
		if surface.mesh is PlaneMesh:
			var plane:=surface.mesh.duplicate() as PlaneMesh;plane.size.x=18.2;surface.mesh=plane
	# Widen the landing under the tunnel mouth and taper back to the real tunnel.
	block("InletSeamBed",Vector3(0,-3.2,5.5),Vector3(6.2,2.4,8.2),"S01","sand")
	throat("InletWestCollar",-1.0)
	throat("InletEastCollar",1.0)
	# Concave terrain shells have no solid interior. Add inset cores under their
	# real surfaces so diving beside a raised floor cannot enter its empty volume.
	for solid: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if not solid.has_meta("custom_terrain"):continue
		if str(solid.get_meta("terrain_kind",""))=="wall":continue
		core(solid)
	assign_owner(holder)
	holder.set_meta("sealed_terrain_cores",core_count)
	print("BASIN SEALS: ",core_count," solid terrain cores; textured basin shoulders and inlet collar")

func assign_owner(node: Node) -> void:
	node.owner=world
	for child: Node in node.get_children():assign_owner(child)

func block(label: String,center: Vector3,size: Vector3,section: String,kind: String) -> void:
	var body:=StaticBody3D.new();body.name=label;body.position=center
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK;holder.add_child(body)
	var collision:=CollisionShape3D.new();collision.name="Collision"
	var shape:=BoxShape3D.new();shape.size=size;collision.shape=shape;body.add_child(collision)
	terrain.replace(body,size,section,kind)
	body.set_meta("fallthrough_seal",true)

func core(body: StaticBody3D) -> void:
	var old:=body.get_node_or_null("SolidTerrainCore")
	if old!=null:body.remove_child(old);old.free()
	var shadow:=body.get_node_or_null("TerrainShadow") as MeshInstance3D
	if shadow==null or not shadow.mesh is BoxMesh:return
	var size: Vector3=(shadow.mesh as BoxMesh).size/Vector3(.96,.93,.96)
	var t: Transform3D=terrain.pose(body)
	var sand:=str(body.get_meta("terrain_kind",""))=="sand"
	var inset:=.025 if sand else minf(.32,minf(size.x,size.z)*.10)
	var points:=PackedVector3Array()
	for x: float in [-size.x*.5+inset,size.x*.5-inset]:
		for z: float in [-size.z*.5+inset,size.z*.5-inset]:
			var top:=t*Vector3(x,size.y*.5-(.06 if sand else .24),z)
			var bottom:=t*Vector3(x,-size.y*.5,z)
			bottom.y=minf(bottom.y,-4.4)
			points.append(t.affine_inverse()*top);points.append(t.affine_inverse()*bottom)
	var shape:=ConvexPolygonShape3D.new();shape.points=points;shape.margin=.01
	var collision:=CollisionShape3D.new();collision.name="SolidTerrainCore";collision.shape=shape
	body.add_child(collision);collision.owner=world;core_count+=1

func throat(label: String,side: float) -> void:
	var points:=PackedVector3Array()
	# Inside x narrows from 3.05 m at the pool to 1.55 m inside the cave.
	var polygon: Array[Vector2]=[Vector2(3.05*side,3.6),Vector2(1.55*side,9.5),Vector2(4.2*side,9.5),Vector2(4.2*side,3.6)]
	for y: float in [-4.4,3.0]:
		for p: Vector2 in polygon:points.append(Vector3(p.x,y,p.y))
	var shape:=ConvexPolygonShape3D.new();shape.points=points
	var body:=StaticBody3D.new();body.name=label;body.collision_layer=17;holder.add_child(body)
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	var mesh:=MeshInstance3D.new();mesh.name="RockCollar";mesh.mesh=shape.get_debug_mesh()
	# Use a solid triangulated mesh, not the physics wireframe debug representation.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in [[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]:
		for index: int in [face[0],face[1],face[2],face[0],face[2],face[3]]:
			st.set_color(Color(0,0,0,1));st.add_vertex(points[index])
	st.generate_normals();mesh.mesh=st.commit()
	var mat:=terrain.material("S01","wall") as ShaderMaterial
	mesh.material_override=mat;body.add_child(mesh)
