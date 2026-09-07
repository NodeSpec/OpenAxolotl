extends SceneTree

## Headless entry point for the performance regression gate (REQ-027).
##
##   godot --headless --audio-driver Dummy --path . \
##       --script test/perf/run_perf_gate.gd
##
## Loads the hub, and the probe traverses an official world measuring the
## three documented targets from contracts/performance_targets.v1.json.
## Exit status is the probe's, so this is CI-shaped. What headless CI can
## and cannot claim about the baseline machine is documented in
## docs/performance.md -- this gate is a regression tripwire.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const PROBE_PATH := "res://test/perf/perf_gate_probe.gd"

## A frame ceiling, so a probe that never completes fails the run instead of
## hanging a CI job.
## Sized for the piloted valley route, which is several times bubble_bay's
## corridor (the probe's own per-world journey budgets do the fine policing;
## this is the wall-clock backstop).
const FRAME_BUDGET := 16000


func _initialize() -> void:
	var packed: PackedScene = load(HUB_PATH)
	if packed == null:
		print("PERF GATE: could not load %s" % HUB_PATH)
		quit(1)
		return

	var hub := packed.instantiate()
	root.add_child(hub)
	current_scene = hub

	var probe := Node.new()
	probe.name = "PerfGateProbe"
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
	print("PERF GATE: the probe never finished within %d physics frames"
		% FRAME_BUDGET)
	quit(1)
