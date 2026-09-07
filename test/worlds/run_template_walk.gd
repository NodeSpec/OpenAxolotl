extends SceneTree

## Headless entry point for the reference template's completability check.
##
##   godot --headless --audio-driver Dummy --path . \\
##       --script test/worlds/run_template_walk.gd
##
## Proves REQ-029 AC-6: the template is completable from spawn to finish
## condition. Exit status is the probe's, so this is CI-shaped the day the CI
## Pipeline node (REQ-018) exists.
##
## The world is instantiated from its path and everything else is found by
## GROUP, exactly as the hub will do it. Nothing here is specific to this
## template beyond the one path, which is the same no-special-case property
## AC-5 asks of the loader.

const WORLD_PATH := "res://worlds/reference_template/world.tscn"
const PROBE_PATH := "res://test/worlds/template_walk_probe.gd"

## A frame ceiling, so a probe that never reaches the finish fails the run
## instead of hanging a CI job forever.
const FRAME_BUDGET := 1200


func _initialize() -> void:
	var packed: PackedScene = load(WORLD_PATH)
	if packed == null:
		print("TEMPLATE WALK: could not load %s" % WORLD_PATH)
		quit(1)
		return

	var world := packed.instantiate()
	root.add_child(world)
	current_scene = world

	var probe := Node.new()
	probe.name = "TemplateWalkProbe"
	probe.set_script(load(PROBE_PATH))
	root.add_child(probe)

	var watchdog := Timer.new()
	watchdog.name = "Watchdog"
	watchdog.wait_time = float(FRAME_BUDGET) \\
		/ float(Engine.physics_ticks_per_second)
	watchdog.one_shot = true
	# Autostart rather than start(): a Timer refuses to start before it is in
	# the tree, and add_child() lands the frame after this runs.
	watchdog.autostart = true
	watchdog.timeout.connect(_on_timeout)
	root.add_child(watchdog)


func _on_timeout() -> void:
	print("TEMPLATE WALK: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
