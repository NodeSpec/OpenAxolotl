extends SceneTree

## Headless entry point for the hub fall-recovery check.
##
##   godot --headless --audio-driver Dummy --path . \
##       --script test/hub/run_fall_recovery.gd
##
## Proves REQ-009's floor end to end: a player thrown off the lagoon comes
## back, and comes back at rest. Exit status is the probe's, so this is
## CI-shaped like the walk probes beside it.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const PROBE_PATH := "res://test/hub/fall_recovery_probe.gd"

## A frame ceiling, so a probe that never resolves fails the run rather than
## hanging a CI job. The probe itself reports at 480 frames.
const FRAME_BUDGET := 900

var _frames := 0


func _initialize() -> void:
	var packed: PackedScene = load(HUB_PATH)
	if packed == null:
		print("FALL RECOVERY: could not load %s" % HUB_PATH)
		quit(1)
		return

	var hub := packed.instantiate()
	hub.set("profile_path", "")
	root.add_child(hub)
	current_scene = hub

	var probe := Node.new()
	probe.name = "FallRecoveryProbe"
	probe.set_script(load(PROBE_PATH))
	root.add_child(probe)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames > FRAME_BUDGET:
		print("FALL RECOVERY: FAILED — the probe did not resolve within "
			+ "%d frames" % FRAME_BUDGET)
		quit(1)
		return true
	return false
