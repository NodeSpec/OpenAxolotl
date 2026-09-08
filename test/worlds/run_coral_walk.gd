extends SceneTree

## Headless entry point for the Coral Cove playthrough check.
##
##   godot --headless --audio-driver Dummy --path . \
##       --script test/worlds/run_coral_walk.gd
##
## Proves REQ-011's per-world claims for coral_cove end to end: both grammars,
## both mod gates, the restorable region, and completion back to the hub.
## Exit status is the probe's, so this is CI-shaped.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const PROBE_PATH := "res://test/worlds/coral_walk_probe.gd"

## A frame ceiling, so a probe that never completes fails the run instead of
## hanging a CI job. Coral Cove's route is the longest in the game so far, and
## it now stops to FIGHT eight times: closing on a machine, swinging on a
## cadence, and waiting out the stagger between strikes is real time the old
## budget had no room for. Raised once, from a measured run, rather than
## guessed at — see the walk's own reported frame count.
const FRAME_BUDGET := 14000


func _initialize() -> void:
	var packed: PackedScene = load(HUB_PATH)
	if packed == null:
		print("CORAL WALK: could not load %s" % HUB_PATH)
		quit(1)
		return

	var hub := packed.instantiate()
	hub.set("profile_path", "")
	root.add_child(hub)
	current_scene = hub

	var probe := Node.new()
	probe.name = "CoralWalkProbe"
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
	print("CORAL WALK: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
