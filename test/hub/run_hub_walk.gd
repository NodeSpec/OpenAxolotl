extends SceneTree

## Headless entry point for the Open Lagoon loop check.
##
##   godot --headless --audio-driver Dummy --path . \
##       --script test/hub/run_hub_walk.gd
##
## Proves REQ-009 AC-2 end to end: portal in, world at its spawn point, finish
## condition met, player returned to the hub. Exit status is the probe's, so
## this is CI-shaped the day the CI Pipeline node (REQ-018) exists.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const PROBE_PATH := "res://test/hub/hub_walk_probe.gd"

## A frame ceiling, so a probe that never completes the loop fails the run
## instead of hanging a CI job forever.
const FRAME_BUDGET := 3000


func _initialize() -> void:
	var packed: PackedScene = load(HUB_PATH)
	if packed == null:
		print("HUB WALK: could not load %s" % HUB_PATH)
		quit(1)
		return

	var hub := packed.instantiate()
	hub.set("profile_path", "")
	root.add_child(hub)
	current_scene = hub

	var probe := Node.new()
	probe.name = "HubWalkProbe"
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
	print("HUB WALK: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
