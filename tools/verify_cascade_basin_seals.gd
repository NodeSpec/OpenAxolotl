extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var stage:=load("res://hub/open_lagoon.tscn").instantiate() as Node3D;stage.set("profile_path","");root.add_child(stage)
	for i in 8:await physics_frame
	var world: Node3D=stage.get_node("OpenLagoon").get("_stream_world") as Node3D
	var space:=world.get_world_3d().direct_space_state
	var capsule:=CapsuleShape3D.new();capsule.radius=.5;capsule.height=1.6
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.margin=.015
	var data: Dictionary={"waters":[]}
	for node: Node in world.find_children("*","Area3D",true,false):
		if not node is WaterVolume:continue
		for shape: CollisionShape3D in node.find_children("*","CollisionShape3D",true,false):
			if not shape.shape is BoxShape3D:continue
			var box:=shape.shape as BoxShape3D
			var bounds: AABB=(world.global_transform.affine_inverse()*shape.global_transform)*AABB(-box.size/2,box.size)
			(data["waters"] as Array).append({"path":str(world.get_path_to(node)),"min":[bounds.position.x,bounds.position.y,bounds.position.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]})
	var results: Array=[];var cases: Array[Dictionary]=[];var escapes:=0
	for row: Dictionary in data.waters:
		if str(row.path).contains("/Chute/"):continue
		for y: float in [float(row.min[1])+.94,float(row.min[1])+float(row.size[1])-.55]:
			var test:=row.duplicate();test["probe_y"]=y;cases.append(test)
	for water: Dictionary in cases:
		var origin:=Vector3(water.min[0],water.min[1],water.min[2]);var size:=Vector3(water.size[0],water.size[1],water.size[2])
		var y:=float(water.probe_y)
		var queue: Array[Vector2i]=[];var parents: Dictionary={};var checked: Dictionary={};var start:=Vector2i.ZERO;var found:=false
		for zi in range(2,int(size.z*2)-1):
			for xi in range(2,int(size.x*2)-1):
				var p:=Vector3(origin.x+xi*.5,y,origin.z+zi*.5)
				q.transform=Transform3D(Basis(),world.to_global(p));q.motion=Vector3.ZERO
				if space.intersect_shape(q,1).is_empty():
					start=Vector2i(roundi(p.x*2),roundi(p.z*2));found=true
					if not parents.has(start):queue.append(start);parents[start]=start
		if not found:continue
		var cursor:=0;var escape:=Vector2i.ZERO;var escaped:=false
		while cursor<queue.size() and cursor<10000:
			var key:=queue[cursor];cursor+=1
			var p:=Vector3(key.x*.5,y,key.y*.5)
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(world.to_global(p),world.to_global(p-Vector3.UP*8),1))
			if hit.is_empty() or (str(world.get_path_to(hit.collider)).contains("ContinuousFoundation") and not str(water.path).contains("Chute")):
				escape=key;escaped=true;break
			for dir: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next:=key+dir
				if parents.has(next):continue
				var to:=Vector3(next.x*.5,y,next.y*.5)
				if absf(to.x)>46 or to.z>10 or to.z<-132:continue
				q.transform=Transform3D(Basis(),world.to_global(to));q.motion=Vector3.ZERO
				if not space.intersect_shape(q,1).is_empty():continue
				q.transform=Transform3D(Basis(),world.to_global(p));q.motion=to-p
				var fractions:=space.cast_motion(q)
				if fractions[0]<.999:continue
				parents[next]=key;queue.append(next)
		var path: Array=[]
		if escaped:
			var at:=escape
			while at!=parents[at]:path.push_front([at.x*.5,y,at.y*.5]);at=parents[at]
			path.push_front([at.x*.5,y,at.y*.5]);escapes+=1
		results.append({"water":water.path,"height":y,"escaped":escaped,"visited":cursor,"path":path})
		print(water.path," y=",y," escape=",escaped," steps=",cursor," at=",escape if escaped else start)
	if results.size()<25:escapes+=1;push_error("Expected all 25 reachable depth sweeps")
	print("CAPSULE ESCAPES: ",escapes," / ",results.size()," depth sweeps")
	stage.queue_free();await process_frame;quit(1 if escapes else 0)
