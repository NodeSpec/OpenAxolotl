extends "res://test/run_tests.gd"

## Asset-independent input and camera regression pass. No scene, editor or rendering.
## godot --headless --audio-driver Dummy --path . --script test/run_input_checks.gd
func _initialize() -> void:
	_run_suite("res://test/core/input/test_input_system.gd")
	_run_suite("res://test/core/camera/test_look_input.gd")
	_run_suite("res://test/core/camera/test_camera_rig.gd")
	_run_suite("res://test/core/camera/test_camera_idle_assist.gd")
	print("\n%d passed, %d failed, %d total" % [_passed, _failed, _passed + _failed])
	quit(1 if _failed > 0 else 0)
