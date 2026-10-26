class_name FleetEnemyVisual
extends Node3D
## Presentation only. No detection, movement, damage, or fleet-state ownership.
signal attack_window_changed(active: bool)
signal cue(name: StringName)
signal state_finished(state: StringName)

@export var enemy_kind: StringName = &"netbot"
@export var autoplay_idle: bool = true
@export var attack_active: bool = false:
	set(value):
		value = value and state == &"attack"
		if attack_active == value: return
		attack_active = value
		attack_window_changed.emit(value)
@export var cable_extension: float = 0.0:
	set(value):
		cable_extension = maxf(value, 0.0)
		_update_cables()
var _throw_target := Vector3(0.0, -0.06, 2.72)
var state: StringName = &"reset"
var _player: AnimationPlayer
var _travel_phase := 0.0
var _motion_weight := 0.0
var _water_pose := false
var _rest_facing := Vector3.ZERO

func _ready() -> void:
	_player = get_node("AnimationPlayer") as AnimationPlayer
	_player.animation_finished.connect(_on_finished)
	_rest_facing=(get_node("Facing") as Node3D).rotation
	_update_cables()
	if autoplay_idle: play_state(&"idle")

func play_state(next: StringName) -> bool:
	if not is_instance_valid(_player) or not _player.has_animation(next): return false
	if state == &"disabled" and next != &"reset": return false
	if next == state and _player.is_playing(): return true
	# A hit, cancel, or disable must close the old animation's active interval now.
	attack_active = false
	state = next
	# Attacks start exactly at their authored release timing. Matching attack/recover
	# endpoints need no blend; other state changes ease out the current pose.
	var blend := .18
	if next in [&"attack", &"recover", &"reset", &"disabled"]: blend=0.0
	elif next == &"stagger": blend=.06
	_player.play(next, blend)
	_player.advance(0.0)
	return true

func reset_locomotion() -> void:
	_motion_weight=0.0
	var facing:=get_node("Facing") as Node3D
	facing.position=Vector3.ZERO; facing.rotation=_rest_facing

func set_locomotion(local_velocity: Vector3,turn_speed: float,water: bool,delta: float) -> void:
	_water_pose=water
	var moving:=state==&"idle"
	var speed:=local_velocity.length() if moving else 0.0
	_motion_weight=lerpf(_motion_weight,clampf(speed,0.0,1.0),1.0-exp(-8.0*delta))
	_travel_phase+=delta*(3.0+speed*4.0)
	var facing:=get_node("Facing") as Node3D
	# Secondary chassis motion follows actual speed; it never translates the actor.
	var bob:=sin(_travel_phase)*(.028 if water else .007)*_motion_weight
	var pitch:=clampf(local_velocity.z*.045,-.04,.04)*_motion_weight
	var bank:=clampf(-turn_speed*.025,-.045,.045)*_motion_weight
	facing.position.y=lerpf(facing.position.y,bob,1.0-exp(-10.0*delta))
	facing.rotation.x=lerpf(facing.rotation.x,pitch,1.0-exp(-8.0*delta))
	facing.rotation.z=lerpf(facing.rotation.z,bank,1.0-exp(-8.0*delta))

func _on_finished(finished: StringName) -> void:
	attack_active = false
	state_finished.emit(finished)
	# Notice and warning hold until an encounter controller explicitly advances them.
	if state != finished: return
	if finished in [&"recover", &"stagger", &"reset"]: play_state(&"idle")
	elif finished == &"attack": play_state(&"recover")

func emit_cue(value: StringName) -> void:
	cue.emit(value)

## Call during notice/warn to commit the throw to the observed player position.
## Once thrown, the hooks cannot home toward a moving player during retraction.
func lock_attack_target(world_position: Vector3) -> bool:
	if enemy_kind != &"hookline_rig" or state in [&"attack", &"recover", &"disabled"]: return false
	var body := get_node("Facing/Body") as Node3D
	_throw_target = body.to_local(world_position).limit_length(3.5)
	return true

func _update_cables() -> void:
	if enemy_kind != &"hookline_rig": return
	var travel := clampf(cable_extension / 0.68, 0.0, 1.0)
	for side: String in ["Left", "Right"]:
		var hook := get_node_or_null("Facing/Body/Hook" + side) as Node3D
		var cable := get_node_or_null("Facing/Body/Cable" + side) as MeshInstance3D
		if hook == null or cable == null: continue
		var sign_x := -1.0 if side == "Left" else 1.0
		var socket := Vector3(sign_x * 0.69, 0.09, 0.0)
		var home := Vector3(sign_x * 0.69, 0.04, 0.0)
		var target := _throw_target + Vector3(sign_x * 0.23, 0.0, 0.0)
		hook.position = home.lerp(target,travel) + Vector3.UP * sin(travel*PI) * (.1 if _water_pose else .22)
		var line := hook.position - socket
		var alignment := Basis(Quaternion(Vector3.UP,line.normalized()))
		cable.transform = Transform3D(Basis(alignment.x,alignment.y*line.length(),alignment.z),(socket+hook.position)*0.5)
