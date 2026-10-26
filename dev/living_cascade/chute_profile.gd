extends RefCounted
## One height/flow field shared by every unrotated chute water Area.
## Using the same field makes the selected Area irrelevant at overlaps.
static var points: Array[Vector3] = []
static var distances: Array[float] = []
static func initialize() -> void:
	if not points.is_empty():
		return
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dev/living_cascade/chute_profile.json")) as Dictionary
	var s := 0.0
	for row: Array in raw["points"]:
		var p := Vector3(float(row[0]),float(row[1]),float(row[2]))
		if not points.is_empty():
			var d: Vector3 = p-points.back()
			s += Vector2(d.x,d.z).length()
		points.append(p)
		distances.append(s)

static func sample(p: Vector3) -> Dictionary:
	initialize()
	var best := INF
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var d := Vector2(b.x-a.x,b.z-a.z)
		var delta := Vector2(p.x-a.x,p.z-a.z)
		var t := clampf(delta.dot(d)/d.length_squared(),0,1)
		best=minf(best,(delta-d*t).length_squared())
	var weight_sum := 0.0
	var height_sum := 0.0
	var height_gradient := Vector2.ZERO
	var weight_gradient := Vector2.ZERO
	var direction_sum := Vector2.ZERO
	var distance_sum := 0.0
	var lateral_sum := 0.0
	# Blend nearby segment planes, so the inside of a rounded bend has one
	# continuous height field. Straight sections retain their exact linear grade.
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var d := Vector2(b.x-a.x,b.z-a.z)
		var delta := Vector2(p.x-a.x,p.z-a.z)
		var projection := delta.dot(d)/d.length_squared()
		var t := clampf(projection,0,1)
		var offset := delta-d*t
		var weight := exp(-2.0*maxf(0,offset.length_squared()-best))
		if weight<0.000001:
			continue
		var direction := d.normalized()
		var slope := direction*((b.y-a.y)/d.length())
		var height := a.y+(b.y-a.y)*projection
		var derivative := -4.0*offset*weight
		weight_sum+=weight
		height_sum+=weight*height
		height_gradient+=weight*slope+derivative*height
		weight_gradient+=derivative
		direction_sum+=direction*weight
		distance_sum+=lerpf(distances[i],distances[i+1],t)*weight
		lateral_sum+=offset.dot(Vector2(-direction.y,direction.x))*weight
	var height := height_sum/weight_sum
	var direction := direction_sum.normalized()
	return {"surface":height,"slope":(height_gradient-height*weight_gradient)/weight_sum,"direction":Vector3(direction.x,0,direction.y),"s":distance_sum/weight_sum,"lateral":lateral_sum/weight_sum,"distance":sqrt(best)}
