class_name WaterTrail
extends Node

var _distance: float = 0.0
var _side: float = 1.0

func _ready() -> void:
	process_physics_priority = 10

func _physics_process(delta: float) -> void:
	var body := get_parent() as AxolotlBody
	if body == null:
		return
	var volume: WaterVolume = body.get_water_volume()
	if volume == null:
		RenderingServer.global_shader_parameter_set("water_actor",Vector4.ZERO)
		_distance = 0.0
		return
	var surface: float = volume.surface_at(body.global_position)
	# Drifting with the stream does not displace water like swimming against it.
	var relative_velocity: Vector3 = body.velocity-volume.flow_at(body.global_position)
	var speed: float = Vector2(relative_velocity.x,relative_velocity.z).length()
	var near_surface: bool = body.global_position.y-0.8 < surface and absf(body.global_position.y-surface) < 0.95
	var strength: float = clampf(speed/7.0,0.0,1.0) if near_surface else 0.0
	RenderingServer.global_shader_parameter_set("water_actor",Vector4(body.global_position.x,surface,body.global_position.z,strength))
	RenderingServer.global_shader_parameter_set("water_motion",Vector4(relative_velocity.x,0.0,relative_velocity.z,0.0))
	if not near_surface or speed < 0.65:
		_distance = 0.0
		return
	# Rigged footfalls own shallow-water splashes; this layer owns swimming wakes.
	if not body.is_in_water() and body.get_visual_motion() != null:
		return
	_distance += speed*delta
	var spinning: bool = body.get_controller().get_spin_sprint().is_active()
	if _distance < (0.40 if spinning else (1.15 if body.is_in_water() else 0.85)):
		return
	_distance = 0.0
	var direction := Vector3(relative_velocity.x,0,relative_velocity.z).normalized()
	var at := Vector3(body.global_position.x,surface+0.035,body.global_position.z)
	if not body.is_in_water():
		at += Vector3(-direction.z,0,direction.x)*_side*0.3
		_side = -_side
	WaterSplash.trail(self,at,relative_velocity,body.is_in_water())

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("water_actor",Vector4.ZERO)
