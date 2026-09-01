extends SceneTree

## Headless entry point for the greybox smoke check.
##
##   godot --headless --audio-driver Dummy --path . --script dev/run_smoke.gd
##
## Loads the development scene, attaches the probe that drives it, and lets the
## normal frame loop run. Exit status is the probe's: non-zero on any failed
## check, so this is CI-shaped the day the CI Pipeline node (REQ-018) exists.
##
## The scene is instantiated here rather than relying on run/main_scene so the
## check keeps working if the project's main scene changes.

const SCENE_PATH := "res://dev/greybox.tscn"
const PROBE_PATH := "res://dev/smoke_probe.gd"

## A frame ceiling, so a probe that never reaches its last phase fails the run
## instead of hanging a CI job forever.
const FRAME_BUDGET := 900


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		print("GREYBOX SMOKE: could not load %s" % SCENE_PATH)
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene

	var probe := Node.new()
	probe.name = "SmokeProbe"
	probe.set_script(load(PROBE_PATH))
	root.add_child(probe)

	var watchdog := Timer.new()
	watchdog.name = "Watchdog"
	watchdog.wait_time = float(FRAME_BUDGET) \
		/ float(Engine.physics_ticks_per_second)
	watchdog.one_shot = true
	# Autostart rather than start(): a Timer refuses to start before it is in the
	# tree, and add_child() is the frame after this runs.
	watchdog.autostart = true
	watchdog.timeout.connect(_on_timeout)
	root.add_child(watchdog)


func _on_timeout() -> void:
	print("GREYBOX SMOKE: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
