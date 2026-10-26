class_name WaterDepthLighting
extends Node

var lighting: WorldLighting
var _camera: Camera3D
var _previous: Environment
var _base: Environment
var _graded: Environment
var _source: Environment
var _blend: float = 0.0
var _enclosure: float = 0.0

static func depth_weight(depth: float, enabled: bool) -> float:
	return smoothstep(0.0,8.0,maxf(0.0,depth)) if enabled else 0.0

func _process(delta: float) -> void:
	if lighting == null:
		return
	var body := get_tree().get_first_node_in_group("player") as AxolotlBody
	var camera: Camera3D = get_viewport().get_camera_3d()
	var volume: WaterVolume = body.get_water_volume() if body != null else null
	var holder: WorldEnvironment = lighting.get_world_environment()
	if camera == null or holder == null:
		_release()
		return
	if _camera != null and (_camera != camera or _source != holder.environment):
		_release()
	var depth: float = volume.surface_at(camera.global_position)-camera.global_position.y if volume != null else 0.0
	var target: float = depth_weight(depth,volume != null and volume.depth_lighting_enabled and volume.contains_point(camera.global_position))
	var cave: float = volume.enclosure_at(body.global_position) if volume != null else 0.0
	if body != null:
		for node: Node in get_tree().get_nodes_in_group("lighting_enclosures"):
			var enclosure := node as WaterVolume
			if enclosure != null and enclosure.can_process():
				cave = maxf(cave,enclosure.enclosure_at(body.global_position))
	_blend = lerpf(_blend,target,1.0-exp(-delta*6.0))
	_enclosure = lerpf(_enclosure,cave,1.0-exp(-delta*3.0))
	if _blend < 0.0001 and target <= 0.0 and _enclosure < 0.0001 and cave <= 0.0:
		_release()
		return
	if _graded == null:
		_camera = camera
		_previous = camera.environment
		_source = holder.environment
		_base = _previous if _previous != null else _source
		if _base == null:
			return
		_graded = _base.duplicate() as Environment
		camera.environment = _graded
	_graded.tonemap_exposure = _base.tonemap_exposure*(1.0-_blend*0.13-_enclosure*0.24)
	_graded.ambient_light_energy = _base.ambient_light_energy*(1.0-_blend*0.22)*(1.0-_enclosure*0.79)
	_graded.fog_enabled = true
	_graded.fog_density = _base.fog_density+_blend*0.025+_enclosure*0.009
	_graded.fog_light_color = _base.fog_light_color.lerp(Color("287f9b"),sqrt(_blend)*0.85)
	_graded.adjustment_saturation = _base.adjustment_saturation*(1.0-_blend*0.10)

func _release() -> void:
	if is_instance_valid(_camera) and _camera.environment == _graded:
		_camera.environment = _previous
	_camera = null
	_previous = null
	_base = null
	_graded = null
	_source = null
	_blend = 0.0
	_enclosure = 0.0

func _exit_tree() -> void:
	_release()
