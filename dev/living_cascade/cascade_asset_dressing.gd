extends RefCounted
## Section-authored, volumetric GLB composition. No facade bakes or texture skins.
const ASSETS := "res://assets/environment/cascade_"
var world: Node3D
var holder: Node3D
var models: Dictionary = {}
var boxes: Dictionary = {}
var shapes: Dictionary = {}
var heights: Dictionary = {}
var shadow_hulls: Dictionary = {}
var shadow_meshes: Dictionary = {}
var placements: Array[Dictionary] = []
var section := ""
var terrain: RefCounted

func apply(target: Node3D) -> void:
	world=target
	terrain=preload("res://dev/living_cascade/cascade_landscape.gd").new()
	terrain.begin(world)
	DirAccess.make_dir_recursive_absolute("res://core/rendering/cascade_collision")
	shadow_hulls=JSON.parse_string(FileAccess.get_file_as_string("res://dev/living_cascade/cascade-shadow-hulls.json")) as Dictionary
	holder=Node3D.new()
	holder.name="SuppliedAssets"
	world.add_child(holder)
	# The generated prototype landmarks and large fern fields compete with the kit.
	var old := world.get_node("Dressing")
	for n: Node in old.get_children():
		var id := String(n.name)
		if id.begins_with("RootBridge") or id.begins_with("Crown") or id.begins_with("Cliff") or id.begins_with("Canopy") or id.begins_with("RisingRoot") or id.begins_with("CascadeCliff") or id=="CentralGrove" or id=="GardenRocks":
			erase(n)
		elif n is ScatterField:
			erase(n)
	# Banks retain the established route outline but are built from whole rocks.
	# Ramps and sand beds remain continuous terrain between these formations.
	for solid: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		var visual := solid.get_node_or_null("Mesh") as MeshInstance3D
		if visual==null or not visual.mesh is BoxMesh:
			continue
		var size := (visual.mesh as BoxMesh).size
		var id := String(solid.name)
		var path := String(world.get_path_to(solid))
		section=path.get_slice("/",1) if path.begins_with("Sections/") else "Perimeter"
		# The garden's front is a balcony over the preceding catch pools. The
		# old 16 m dividing boxes leave no room for a full-depth cliff on either
		# side without blocking the stair or seed loop. Its 2.4 m bank rise is
		# the actual edge; the west divider and restoration gate remain closed.
		if section=="S05" and id in ["NorthRidgeWest","NorthRidgeEast"]:
			hide_solid(solid,true)
			continue
		if id=="CheckpointPad":
			hide_solid(solid,true)
			continue
		if solid.rotation.length()>0.02 or "Bed" in id or "Foundation" in id or "Roof" in id or id=="Gate" or id=="DiveBrow":
			continue
		if (size.y<=2.9 or id in ["RewardWestBank","GateFloor"]) and size.x>=2 and size.z>=2:
			if id in ["P21","P22","P23","P24","O1","A1","A2","C1","C2","C3"]:
				landing(solid,3.65)
			else:
				bank(solid,size)
		elif is_wall(id,size):
			wall(solid,size)
	section="S01"
	arrival()
	section="S02"
	garden()
	section="S03"
	root_dive()
	section="S04"
	terraces()
	section="S05"
	crown()
	section="S06"
	chute()
	# Replace the remaining authored beds and sloping connectors with real
	# subdivided terrain meshes. The original paths and body groups stay stable.
	for solid: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		var visual := solid.get_node_or_null("Mesh") as MeshInstance3D
		if visual==null or not visual.mesh is BoxMesh: continue
		var id := String(solid.name)
		if "Roof" in id or id in ["DiveBrow","DiveBar"]: continue
		var path := String(world.get_path_to(solid))
		section=path.get_slice("/",1) if path.begins_with("Sections/") else "Perimeter"
		if id=="Gate":
			visual.material_override=terrain.material("S05","wall")
			continue
		var kind := "sand" if "Bed" in id or "Foundation" in id else "bank"
		terrain.replace(solid,(visual.mesh as BoxMesh).size,section,kind)
	terrain.waterfall_sources()
	terrain.finish()
	preload("res://dev/living_cascade/cascade_collision_polish.gd").new().apply(world)
	preload("res://dev/living_cascade/cascade_basin_seals.gd").new().apply(world)
	# Small whole-model stones remain decorative; the traversable assets above
	# own collision. Four batches keep the stream beds readable without clutter.
	for row: Array in [["ArrivalRocks","mossy_stone",Vector3(-5,-1.94,-9)], ["GardenRocks","mossy_stone",Vector3(-29,-1.94,-35)], ["GrottoRocks","reef_ledge",Vector3(-11,-3.12,-61)], ["FinishRocks","reef_ledge",Vector3(-25,-2.32,-102)]]:
		var field := ScatterField.new()
		field.name=String(row[0])
		field.prop_scene=load(ASSETS+String(row[1])+"/"+String(row[1])+".glb") as PackedScene
		var transforms := PackedFloat32Array()
		for i in range(4):
			var p: Vector3=(row[2] as Vector3)+Vector3(float(i%2)*1.3,0,float(i/2)*1.4)
			var s := 0.18+float(i%2)*0.04
			transforms.append_array(PackedFloat32Array([s,0,0,0,s,0,0,0,s,p.x,p.y,p.z]))
		field.transforms=transforms
		world.get_node("Dressing").add_child(field)
	FileAccess.open("res://review/cascade-asset-placements.json",FileAccess.WRITE).store_string(JSON.stringify(placements,"\t"))
	print("SOLID ASSETS: ",placements.size()," linked full-mesh placements")

func arrival() -> void:
	place("cliff_garden","S01_PlantedShoreCliff",Vector3(-13,-2,-6),7.5,90)
	# Shelves flank both recovery ramps; their stepped edge is visible under water.
	place("bank_terrace","S01_BankLedge",Vector3(7.2,-1.8,-10),5.8,90)
	place("bank_terrace","S01_WestShelf",Vector3(-9,-2.1,-6),4.4,-90)
	place("mossy_stone","S01_SubmergedStone",Vector3(-4,-2,-5.9),1.8,30)
	place("mossy_stone","S01_PoolRock",Vector3(-6.7,-2,-7.7),1.5,-25)

func garden() -> void:
	place("cliff_garden","S02_PlantedGardenCorner",Vector3(-37,-2,-34),8.5,90)
	# Whole underwater rocks give the stepping sequence a submerged foundation.
	for row: Array in [[-29.5,-33.7,2.0],[-25.2,-35.9,1.6],[-19.5,-31.4,1.7],[-31,-26.5,2.2]]:
		place("mossy_stone","S02_PoolStone%d" % placements.size(),Vector3(float(row[0]),-2.0,float(row[1])),float(row[2]),float(placements.size()*23%360))
	place("bank_terrace","S02_RecoveryLedge",Vector3(-11,-1.8,-32),5.5,90)
	place("stone_ruins","S02_OptionalOutcrop",Vector3(-32,-2,-30),4.8,35)

func root_dive() -> void:
	place("reef_wall","S03_GrottoCoralFace",Vector3(-10,-3.2,-68.8),3.7)
	place("reef_wall","S03_WestCoralFace",Vector3(-29.5,-3.2,-56),3.2,90)
	# Replace the two solid ceiling boxes with genuine hollow cave modules.
	for id: String in ["RootRoof","SecretRoof"]:
		hide_solid(world.get_node("Sections/S03/RootDive/"+id),true)
	# Preserve the root model's full depth and all four feet. Its roots meet water.
	place("root_bridge","S03_RootBridge",Vector3(-14,-0.25,-58),34.0)
	place("reef_arch","S03_EntryTunnel",Vector3(-20,-3.2,-52.5),7.6,-38.66)
	place("reef_arch","S03_MiddleTunnel",Vector3(-14,-3.2,-56.5),7.6,-69.44)
	place("reef_arch","S03_ExitTunnel",Vector3(-2.8,-3.2,-58),7.6,90)
	place("reef_arch","S03_GrottoArch",Vector3(-10.7,-3.2,-64.4),7.6,48.0)
	place("reef_ledge","S03_ReefShelf",Vector3(-25.5,-3.2,-59.5),3.4,25)
	place("reef_ledge","S03_GrottoShelf",Vector3(-14.3,-3.2,-67.4),1.7,90)
	place("reef_ledge","S03_ExitShelf",Vector3(2,-3.2,-61.3),2.7,-45)
	for row: Array in [["GrottoFill",Vector3(-7,-1,-65),1.3,9.0],["RootWaterFill",Vector3(-18,-1,-55),1.1,11.0]]:
		var light := OmniLight3D.new()
		light.name=String(row[0])
		light.position=row[1] as Vector3
		light.light_color=Color(0.58,0.86,1)
		light.light_energy=float(row[2])
		light.omni_range=float(row[3])
		holder.add_child(light)

func terraces() -> void:
	# Actual shelf and corner geometry frames the climb without entering its lane.
	place("bank_terrace","S04_LowerShelf",Vector3(27.6,-1.5,-65),5.1,90)
	place("stone_ruins","S04_ClimbButtress",Vector3(33.5,0.6,-76),5.3,90)
	place("bank_terrace","S04_UpperShelf",Vector3(19.2,3.4,-94.7),6.0,180)
	# A low rock arch replaces the rectangular brow of the mandatory dive pool.
	hide_solid(world.get_node("Sections/S04/Terraces/DiveBrow"),true)
	place("reef_arch","S04_DiveArch",Vector3(30,1,-83.8),4.7)
	# The scenic waterfall now falls down the faces of full cliff modules.
	place("cliff_garden","S04_WaterfallBluff",Vector3(5,-4.2,-91.5),17.0)
	place("stone_ruins","S04_WaterfallApron",Vector3(7,-4.2,-86.8),10.0)

func crown() -> void:
	place("cliff_garden","S05_PlantedCrownCorner",Vector3(37.4,6.35,-106),8,-90)
	place("bank_terrace","S05_BalconyWest",Vector3(10.5,5.8,-95.4),3.4,180)
	place("bank_terrace","S05_BalconyEast",Vector3(35,5.8,-95.4),3.4,180)
	var arch := place("crown_arch","S05_CrownArch",Vector3(23,8.1,-119.5),26.0)
	arch.set_script(load("res://core/rendering/cascade_crown_state.gd"))
	place("cliff_garden","S05_CrownPedestalWest",Vector3(15,-4.2,-120),17.8,12)
	place("cliff_garden","S05_CrownPedestalEast",Vector3(32,-4.2,-120),18.4,-12)
	place("bank_terrace","S05_CrownBankLedge",Vector3(34,4.4,-106.5),5.2,90)
	place("reef_ledge","S05_BasinShelf",Vector3(22,4.2,-103),2.0,180)
	var falling_water := ShaderMaterial.new()
	falling_water.shader=load("res://core/rendering/cascade_sheet.gdshader")
	for i in range(5):
		var ribbon := MeshInstance3D.new()
		ribbon.name="CrownWaterfall%d" % i
		var sheet := QuadMesh.new()
		sheet.size=Vector2(1.6,8.0-float(i%2)*0.4)
		ribbon.mesh=sheet
		ribbon.material_override=falling_water
		ribbon.position=Vector3(20+float(i)*1.48,11.5,-110.1+float(i%2)*0.03)
		ribbon.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(ribbon)

func chute() -> void:
	var parent := world.get_node("Sections/S06/Chute")
	for side: String in ["L","R"]:
		terrain.stream_bank(parent,side)
	# Sparse whole outcrops anchor the bends, with continuous carved banks between.
	place("stone_ruins","S06_OuterBendRock",Vector3(-10,-1,-124),8.0,25)
	place("bank_terrace","S06_RewardBankLedge",Vector3(-40,-2.4,-102),4.8,90)
	# The dive obstacle remains the same location; real roots now span its width.
	var bar := parent.get_node("DiveBar") as StaticBody3D
	hide_solid(bar,true)
	var dive := place("root_bridge","S06_DiveRoot",Vector3(-12,3.0,-116),11.7,63.435)
	# A naturally low submerged arch provides the actual dive ceiling.
	place("reef_arch","S06_DiveTunnel",Vector3(-12,0.7,-116),6.8,63.435)
	dive.set_meta("role","surface landmark over dive tunnel")
	place("reef_ledge","S06_FinishReef",Vector3(-23.4,-2.4,-101.5),4.4,-65)
	place("mossy_stone","S06_PearlRock",Vector3(-30,-2.4,-101),1.7,45)

func is_wall(id: String,size: Vector3) -> bool:
	return size.y>3.0 and ("Wall" in id or "Boundary" in id or "Ridge" in id or "Retain" in id or id.begins_with("Outer") or id.begins_with("InletFlank") or id.begins_with("Entrance") or id.begins_with("GateNorth") or id.begins_with("GateSouth") or id in ["FinishLaneWest","RewardNorthBank","RewardEastBank","RewardSouthWestBank","ExitLaneEast","ExitEnd","PoolBEastBlock"])

func wall(solid: StaticBody3D,size: Vector3) -> void:
	terrain.replace(solid,size,section,"wall")

func landing(solid: StaticBody3D,width: float) -> void:
	var visual := solid.get_node("Mesh") as MeshInstance3D
	var size := (visual.mesh as BoxMesh).size
	var p := local_transform(solid).origin
	var top := p.y+size.y*0.5
	var b := asset_box("mossy_stone")
	var factor := width/b.size.x
	var base := Vector3(p.x,top-(surface_height("mossy_stone")-b.position.y)*factor,p.z)
	var rock := place("mossy_stone",section+"_"+String(solid.name),base,width)
	transfer_collision_role(solid,rock)
	rock.set_meta("landing_support_y",top)
	rock.set_meta("replaces_body",String(world.get_path_to(solid)))
	# The columns reach the bed: high landing stones must not float above pools.
	var bed := 1.0 if section=="S04" and String(solid.name).begins_with("C") else -2.0
	if base.y>bed+0.1:
		terrain.column(section+"_"+String(solid.name)+"_StoneColumn",Vector3(p.x,bed,p.z),base.y+0.2,1.3,section)
	hide_solid(solid,true)

func bank(solid: StaticBody3D,size: Vector3) -> void:
	terrain.replace(solid,size,section,"bank")

func place(id: String,label: String,base: Vector3,width: float,yaw: float=0) -> Node3D:
	var b := asset_box(id)
	var container := Node3D.new()
	container.name=label
	holder.add_child(container)
	# Imported ownership plus editable instance state saves material overrides
	# without embedding a second copy of the mesh in the production scene.
	var edit_state := PackedScene.GEN_EDIT_STATE_INSTANCE if id=="reef_arch" else PackedScene.GEN_EDIT_STATE_DISABLED
	var model := (models[id] as PackedScene).instantiate(edit_state) as Node3D
	model.set_meta("cascade_asset_instance",true)
	container.add_child(model)
	var factor := width/b.size.x
	model.scale=Vector3.ONE*factor
	model.position=-Vector3(b.get_center().x,b.position.y,b.get_center().z)*factor
	container.position=base
	container.rotation_degrees.y=yaw
	if id=="reef_arch":
		preload("res://dev/living_cascade/cascade_tunnel_material.gd").apply(model)
	container.set_meta("source_asset",id)
	container.set_meta("section",section)
	container.set_meta("full_3d_asset",true)
	if shadow_hulls.has(id):
		if not shadow_meshes.has(id):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for v: Array in shadow_hulls[id]:
				surface.add_vertex(Vector3(float(v[0]),float(v[1]),float(v[2])))
			surface.generate_normals()
			surface.index()
			shadow_meshes[id]=surface.commit()
		var shadow := MeshInstance3D.new()
		shadow.name="RockShadow"
		shadow.mesh=shadow_meshes[id] as ArrayMesh
		shadow.transform=model.transform
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		container.add_child(shadow)
		container.set_script(load("res://core/rendering/cascade_asset_visibility.gd"))
	var body := StaticBody3D.new()
	body.name="AssetCollision"
	body.collision_layer=1|SceneOccluderProbe.CAMERA_COLLISION_LAYER_MASK
	container.add_child(body)
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var key := id+String(mesh.name)
		if not shapes.has(key):
			# Hollow arches and landing stones need their actual concave surface.
			# Solid outcrops use a hull, avoiding collisions on individual leaves.
			shapes[key]=mesh.mesh.create_trimesh_shape() if "arch" in id or id=="root_bridge" or id=="mossy_stone" else mesh.mesh.create_convex_shape(true,true)
			ResourceSaver.save(shapes[key] as Shape3D,"res://core/rendering/cascade_collision/"+id+".res",ResourceSaver.FLAG_COMPRESS|ResourceSaver.FLAG_CHANGE_PATH)
			(shapes[key] as Shape3D).take_over_path("res://core/rendering/cascade_collision/"+id+".res")
		var collider := CollisionShape3D.new()
		collider.shape=shapes[key] as Shape3D
		collider.transform=model_transform(mesh,container)
		body.add_child(collider)
	placements.append({"name":label,"section":section,"asset":id,"base":[base.x,base.y,base.z],"width":width,"uniform_scale":factor,"yaw":yaw,"size":[b.size.x*factor,b.size.y*factor,b.size.z*factor],"collision":"mesh" if "arch" in id or id=="root_bridge" or id=="mossy_stone" else "hull"})
	return container

func transfer_collision_role(source: StaticBody3D,rock: Node3D) -> void:
	var body := rock.get_node("AssetCollision") as StaticBody3D
	body.collision_layer=source.collision_layer
	for group: StringName in source.get_groups():
		body.add_to_group(group,true)

func asset_box(id: String) -> AABB:
	if boxes.has(id):
		return boxes[id] as AABB
	models[id]=load(ASSETS+id+"/"+id+".glb") as PackedScene
	var model := (models[id] as PackedScene).instantiate() as Node3D
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var b := model_transform(mesh,model)*mesh.get_aabb()
		box=b if first else box.merge(b)
		first=false
	boxes[id]=box
	model.free()
	return box

func surface_height(id: String) -> float:
	if heights.has(id):
		return float(heights[id])
	var b := asset_box(id)
	var model := (models[id] as PackedScene).instantiate() as Node3D
	var highest := b.position.y
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var faces := mesh.mesh.get_faces()
		var t := model_transform(mesh,model)
		var start := Vector3(b.get_center().x,b.end.y+1,b.get_center().z)
		var end := start-Vector3.UP*(b.size.y+2)
		for i in range(0,faces.size(),3):
			var hit: Variant=Geometry3D.segment_intersects_triangle(start,end,t*faces[i],t*faces[i+1],t*faces[i+2])
			if hit!=null:
				highest=maxf(highest,(hit as Vector3).y)
	model.free()
	heights[id]=highest
	return highest

func hide_solid(solid: Node,disable_collision: bool) -> void:
	for n: Node in solid.get_children():
		if n is VisualInstance3D or n is TerrainShell:
			erase(n)
		elif disable_collision and n is CollisionShape3D:
			(n as CollisionShape3D).disabled=true

func local_transform(node: Node3D) -> Transform3D:
	return model_transform(node,world)

func model_transform(node: Node3D,ancestor: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent!=ancestor and parent is Node3D:
		result=(parent as Node3D).transform*result
		parent=parent.get_parent()
	return result

func erase(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()




