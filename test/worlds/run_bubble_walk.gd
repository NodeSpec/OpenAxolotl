extends SceneTree

## Headless entry point for the Bubble Bay playthrough check.
##
##   godot --headless --audio-driver Dummy --path . \
##       --script test/worlds/run_bubble_walk.gd
##
## Proves REQ-028's claims for bubble_bay end to end: both grammars, the
## mandatory Jet gate, the restorable region on DEFAULT costs, the no-boss
## optional path, and completion back to the hub. Exit status is the
## probe's, so this is CI-shaped.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const PROBE_PATH := "res://test/worlds/bubble_walk_probe.gd"

## A frame ceiling, so a probe that never completes fails the run instead of
## hanging a CI job. Bubble Bay's route matches Coral Cove's length.
const FRAME_BUDGET := 4800


func _initialize() -> void:
	var packed: PackedScene = load(HUB_PATH)
	if packed == null:
		print("BUBBLE WALK: could not load %s" % HUB_PATH)
		quit(1)
		return

	var hub := packed.instantiate()
	root.add_child(hub)
	current_scene = hub

	var probe := Node.new()
	probe.name = "BubbleWalkProbe"
	probe.set_script(load(PROBE_PATH))
	root.add_child(probe)

	var watchdog := Timer.new()
	watchdog.name = "Watchdog"
	watchdog.wait_time = float(FRAME_BUDGET) \
		/ float(Engine.physics_ticks_per_second)
	watchdog.one_shot = true
	# Autostart rather than start(): a Timer refuses to start before it is in
	# the tree, and add_child() lands the frame after this runs.
	watchdog.autostart = true
	watchdog.timeout.connect(_on_timeout)
	root.add_child(watchdog)


func _on_timeout() -> void:
	print("BUBBLE WALK: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
