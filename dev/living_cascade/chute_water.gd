@tool
extends WaterVolume
const Profile = preload("res://dev/living_cascade/chute_profile.gd")

func surface_at(point: Vector3) -> float:
	return float(Profile.sample((get_parent() as Node3D).to_local(point))["surface"]) + (get_parent() as Node3D).global_position.y

func surface_slope_at(point: Vector3) -> Vector2:
	return Profile.sample((get_parent() as Node3D).to_local(point))["slope"] as Vector2

func flow_at(point: Vector3) -> Vector3:
	if not contains_point(point):
		return Vector3.ZERO
	var local_point := (get_parent() as Node3D).to_local(point)
	var row := Profile.sample(local_point)
	var s := float(row["s"])
	# A still approach pocket prevents surface-following velocity from pushing
	# a blocked player down the bar. Diving remains an explicit player action.
	var bar_s := float(Profile.sample(Vector3(-12,3.6,-116))["s"])
	if absf(s-bar_s)<2.8 and local_point.y>2.15:
		return Vector3.ZERO
	# Smooth entry/exit current, with still side eddies inside the retaining banks.
	var speed := smoothstep(0,2,s) * smoothstep(0,4,Profile.distances.back()-s)
	speed *= 1.0-smoothstep(2.0,3.0,absf(float(row["lateral"])))
	return (row["direction"] as Vector3)*speed
