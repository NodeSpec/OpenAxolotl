@tool
class_name LagoonStreamPath
extends RefCounted

const HALF_WIDTH: float = 2.35
static var _curve: Curve3D
static var _points: PackedVector3Array

static func curve() -> Curve3D:
	if _curve != null:
		return _curve
	_curve = Curve3D.new()
	_curve.bake_interval = 0.18
	var knots: Array[Vector3] = [Vector3(0,-0.575,-9),Vector3(0.25,-1.45,-13),Vector3(1.8,-3.0,-20),Vector3(4.4,-4.45,-29),Vector3(4.0,-5.65,-38),Vector3(3.0,-6.5,-46),Vector3(3.0,-6.8,-52)]
	for i: int in knots.size():
		var handle: Vector3 = (knots[mini(i+1,knots.size()-1)]-knots[maxi(0,i-1)])/6.0
		_curve.add_point(knots[i],-handle,handle)
	_points = _curve.get_baked_points()
	return _curve

static func at_z(z: float) -> Vector3:
	curve()
	var low: int = 0
	var high: int = _points.size()-1
	while high-low > 1:
		var mid: int = (low+high)/2
		if _points[mid].z > z:
			low = mid
		else:
			high = mid
	var weight: float = clampf((z-_points[low].z)/(_points[high].z-_points[low].z),0,1)
	return _points[low].lerp(_points[high],weight)

static func tangent(z: float) -> Vector3:
	return (at_z(z-0.15)-at_z(z+0.15)).normalized()

static func point(distance: float) -> Vector3:
	return curve().sample_baked(clampf(distance,0,curve().get_baked_length()),true)

static func enclosure(z: float) -> float:
	return smoothstep(9.5,18.0,-z)*(1.0-smoothstep(43.0,53.0,-z))

static func exit_position() -> Vector3:
	return point(curve().get_baked_length())
