class_name PresentationMotion
extends Node3D

## Shared, visual-only ambient motion for presentation polish (REQ-011).
##
## This script belongs on a MeshInstance3D or a decoration wrapper, NEVER on
## the CollisionObject3D that owns gameplay. Platformer readability depends on
## collision staying still while the eye gets enough motion to distinguish a
## pickup, a living plant, or a hero landmark from the background.
##
## All motion is deterministic from elapsed time + phase. There is no RNG, no
## physics query, and no gameplay signal. Two instances with the same exported
## values move the same way every run.

@export_group("Float")
@export_range(0.0, 2.0, 0.01) var bob_height_m: float = 0.0
@export_range(0.0, 4.0, 0.01) var bob_speed_hz: float = 0.5

@export_group("Turn")
@export_range(-360.0, 360.0, 1.0) var yaw_speed_deg_per_s: float = 0.0

@export_group("Sway")
@export_range(0.0, 20.0, 0.1) var sway_degrees: float = 0.0
@export_range(0.0, 4.0, 0.01) var sway_speed_hz: float = 0.4

@export_group("Pulse")
@export_range(0.0, 0.25, 0.005) var scale_pulse_ratio: float = 0.0

@export_group("Variation")
## Normalized cycle offset. Use different phases to keep nearby props from
## bobbing in lockstep without introducing nondeterministic animation.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _base_scale := Vector3.ONE
var _elapsed := 0.0


func _ready() -> void:
	_base_position = position
	_base_rotation = rotation
	_base_scale = scale


func _process(delta: float) -> void:
	_elapsed += delta

	var bob_phase := TAU * (_elapsed * bob_speed_hz + phase)
	var sway_phase := TAU * (_elapsed * sway_speed_hz + phase)

	position = _base_position + Vector3.UP * sin(bob_phase) * bob_height_m

	var yaw := fmod(deg_to_rad(yaw_speed_deg_per_s) * _elapsed, TAU)
	rotation = _base_rotation + Vector3(
		deg_to_rad(sin(sway_phase) * sway_degrees),
		yaw,
		deg_to_rad(cos(sway_phase * 0.91) * sway_degrees * 0.35)
	)

	var pulse := 1.0 + sin(bob_phase) * scale_pulse_ratio
	scale = _base_scale * pulse
