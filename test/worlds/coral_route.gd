class_name CoralRoute
extends RefCounted
## Canonical Living Cascade route shared by gameplay and performance probes.
static func waypoints() -> Array[RoutePilot.Waypoint]:
	var result: Array[RoutePilot.Waypoint] = []
	for row: Array in [
		["swim",-4,-0.8,-7],["walk",4,1.2,-8],["walk",4,1.2,-16],["walk",-10.5,1.2,-18],["walk",-10.5,1.2,-22],["walk",-22,1.2,-22],["walk",-22,1.2,-25],
		["jump",-22,1.3,-29.2],["jump",-22,1.45,-33.8],["jump",-22,1.6,-38.8],["walk",-22,1.6,-44],
		["swim",-22,-1.6,-50],["swim",-18,-1.6,-55],["swim",-10,-1.6,-58],["swim",4,-1.6,-58],["swim",8,-0.1,-56],["walk",13,1.6,-56],["walk",16,1.6,-57],["walk",22,1.6,-57.5],
		["jump",22,2.4,-61.9],["jump",22,3.2,-66],["walk",22,3.2,-68.2],["walk",30,3.2,-70],["climb",30,3.2,-75],["walk",30,5.2,-78.5],
		["swim",30,2.1,-81],["swim",30,2.1,-86.9],["swim",34.5,3.1,-86.8],["walk",34.5,5.2,-92.7],["walk",26.5,5.2,-92.7],["walk",26.5,5.2,-88],
		["jump",21,6,-88],["jump",16.5,6.8,-88],["jump",16.5,7.6,-92],["walk",24,7.6,-92],
		["walk",24,7.6,-95.5],["walk",27,7.6,-95],["walk",31,7.6,-99],["walk",31,7.6,-105],["walk",29,7.6,-105],["walk",21,7.6,-107],["walk",16,7.8,-107],["walk",13,7.8,-103],["walk",12,7.8,-104],["walk",8,7.8,-104],
		["swim",4,5.1,-106],["swim",0,4.6,-110],["swim",-7,3.3,-113.5],["swim",-10,2.3,-115],["swim",-13,1.7,-116.5],["swim",-16,1,-118],["swim",-19,0.9,-118],["swim",-23,-0.6,-114],["swim",-27,-0.8,-109],["swim",-28,-0.8,-104],["swim",-29,-0.8,-106],
		["walk",-36,1.8,-106],["walk",-38,1.8,-106],["walk",-38,1.8,-110]
	]:
		result.append(RoutePilot.at(String(row[0]),Vector3(float(row[1]),float(row[2]),float(row[3])),"Living Cascade %d" % result.size()))
	return result


