@tool
extends WaterVolume
const ProfileScript = preload("res://core/controller/channel_profile.gd")
@export_file("*.json") var profile_path := ""
@export var flow_speed := 1.0
var Profile := ProfileScript.new()

func _ready() -> void:
	Profile.source_path = profile_path
	super._ready()

func surface_at(point: Vector3) -> float:
	Profile.source_path = profile_path
	return float(Profile.sample((get_parent() as Node3D).to_local(point))["surface"]) + (get_parent() as Node3D).global_position.y

func surface_slope_at(point: Vector3) -> Vector2:
	Profile.source_path = profile_path
	return Profile.sample((get_parent() as Node3D).to_local(point))["slope"] as Vector2

func flow_at(point: Vector3) -> Vector3:
	if not contains_point(point):
		return Vector3.ZERO
	Profile.source_path = profile_path
	var local_point := (get_parent() as Node3D).to_local(point)
	var row := Profile.sample(local_point)
	var s := float(row["s"])
	# A still approach pocket prevents surface-following velocity from pushing
	# a blocked player down the bar. Diving remains an explicit player action.
	for obstacle: Dictionary in Profile.still_obstacles:
		var xyz: Array = obstacle["position"] as Array
		var center := Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2]))
		var bar_s := float(Profile.sample(center)["s"])
		if absf(s-bar_s)<float(obstacle["half_length"]) and local_point.y>float(obstacle["dive_center_y"]):
			return Vector3.ZERO
	# Smooth entry/exit current, with still side eddies inside the retaining banks.
	var speed := smoothstep(0,2,s) * smoothstep(0,4,Profile.distances.back()-s)
	speed *= 1.0-smoothstep(Profile.half_width-2.0,Profile.half_width-1.0,absf(float(row["lateral"])))
	return (row["direction"] as Vector3)*speed*flow_speed
