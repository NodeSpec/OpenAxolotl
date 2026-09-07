extends SceneTree

## The GPU half of the performance gate (REQ-027) — the half that was missing.
##
##   godot --audio-driver Dummy --rendering-driver vulkan --resolution 1920x1080 \
##       --path . --script test/perf/run_gpu_gate.gd
##
## NOTE THE ABSENT --headless. That flag is the whole reason this file exists.
## `test/perf/run_perf_gate.gd` runs headless, which selects Godot's DUMMY
## rendering server: it measures script and physics time and never rasterises
## a pixel. It says so in its own docstring, and it is a perfectly good
## regression tripwire for what it measures — but it means the entire GPU cost
## of the shared environment (SDFGI, volumetric fog, SSAO, TAA, soft shadows)
## was invisible to every gate in the repo, and a stack that a mid-range
## desktop cannot hold at 60 fps reached a player before it reached a test.
##
## WHAT THIS MEASURES. The camera is flown along the same waypoints the coral
## route uses — the places the player actually stands — and the viewport's own
## measured GPU time is sampled at each. That isolates rendering cost from
## physics and script, which is the number a quality level moves.
##
## WHAT THIS CANNOT CLAIM, and does not. CI here rasterises through llvmpipe, a
## SOFTWARE renderer. Absolute milliseconds off it are not the baseline
## machine's and are not comparable to a GTX 1650's; treating them as an fps
## figure would repeat exactly the over-claim this file exists to correct. So:
##
##   * the ASSERTION is on the ORDERING — LOW cheaper than MEDIUM cheaper than
##     HIGH, by a real margin. That is a property of the quality levels
##     themselves and it holds on any rasteriser, so a change that makes
##     MEDIUM cost what HIGH costs fails here regardless of the hardware.
##   * the ABSOLUTE numbers are REPORTED, never gated. Run this on the target
##     machine and read them; that is the only place they mean anything.

const HUB_PATH := "res://hub/open_lagoon.tscn"
const LIGHTING_PATH := "res://core/rendering/world_lighting.tscn"
const WORLD_PATH := "res://worlds/coral_cove/world.tscn"

## Frames to let the renderer settle before sampling. SDFGI needs considerably
## more than a couple: its cascades voxelise over many frames after the camera
## moves, and sampling into that ramp measures the warm-up rather than the
## steady state.
const WARMUP_FRAMES := 45

## Frames sampled at each waypoint once warm.
const SAMPLE_FRAMES := 12

## How much cheaper each level must be than the one above it, as a ratio of
## GPU time. Deliberately modest: the point is to catch a level that has
## stopped meaning anything, not to pin a number that varies by rasteriser.
const REQUIRED_MARGIN := 1.12

var _camera: Camera3D
var _lighting: WorldLighting
var _waypoints: Array[Vector3] = []

var _levels: Array = [
	RenderQuality.Level.LOW,
	RenderQuality.Level.MEDIUM,
	RenderQuality.Level.HIGH,
]
var _results: Dictionary = {}

var _level_index := 0
var _waypoint_index := 0
var _frame := 0
var _samples: Array[float] = []


func _initialize() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	current_scene = scene

	_lighting = (load(LIGHTING_PATH) as PackedScene).instantiate() as WorldLighting
	scene.add_child(_lighting)
	scene.add_child((load(WORLD_PATH) as PackedScene).instantiate())

	_camera = Camera3D.new()
	_camera.fov = 70.0
	scene.add_child(_camera)
	_camera.current = true

	# Every eighth waypoint: enough of the valley to catch the heavy stretches
	# (the forest, both rivers) without paying the warm-up cost forty-five
	# times over.
	var route: Array = CoralRoute.waypoints()
	for index: int in range(0, route.size(), 8):
		_waypoints.append((route[index] as RoutePilot.Waypoint).target)

	RenderingServer.viewport_set_measure_render_time(
		root.get_viewport_rid(), true)
	_begin_level()


func _begin_level() -> void:
	_lighting.set_quality(_levels[_level_index] as RenderQuality.Level)
	_waypoint_index = 0
	_frame = 0
	_samples = []
	_place_camera()


func _place_camera() -> void:
	var here: Vector3 = _waypoints[_waypoint_index]
	# Behind and above, looking along the route — the framing the follow
	# camera actually holds, so the measurement is of what the player sees.
	var ahead: Vector3 = _waypoints[mini(
		_waypoint_index + 1, _waypoints.size() - 1)]
	var along := here - ahead
	# At the last waypoint `ahead` IS `here`, so the offset would be straight
	# up and looking_at would be asked for a forward vector parallel to UP.
	if along.length_squared() < 0.01:
		along = Vector3(0.0, 0.0, 1.0)
	var back := along.normalized() * 6.0 + Vector3(0.0, 3.0, 0.0)
	_camera.global_transform = Transform3D(Basis(), here + back) \
		.looking_at(here, Vector3.UP)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame <= WARMUP_FRAMES:
		return false

	_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(
		root.get_viewport_rid()))

	if _samples.size() % SAMPLE_FRAMES != 0:
		return false

	_waypoint_index += 1
	if _waypoint_index < _waypoints.size():
		_place_camera()
		# A shorter re-warm between waypoints: the cascades are already built,
		# only the near one moves.
		_frame = WARMUP_FRAMES - 12
		return false

	_results[_levels[_level_index]] = _summarise(_samples)
	_level_index += 1
	if _level_index < _levels.size():
		_begin_level()
		return false

	return _report()


func _summarise(samples: Array[float]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0.0
	for value: float in sorted:
		total += value
	return {
		"mean": total / maxf(float(sorted.size()), 1.0),
		# The 95th percentile is the number a player feels as a hitch; a mean
		# that hides a fifth of the frames at double it is not a useful gate.
		"p95": sorted[mini(int(float(sorted.size()) * 0.95), sorted.size() - 1)],
		"worst": sorted[sorted.size() - 1],
		"frames": sorted.size(),
	}


func _report() -> bool:
	print("GPU GATE (coral_cove, %dx%d, %s)" % [
		root.size.x, root.size.y,
		RenderingServer.get_video_adapter_name()])

	var failures: PackedStringArray = []
	for level: RenderQuality.Level in _levels:
		var row: Dictionary = _results[level]
		print("  %-6s  mean %6.2f ms  p95 %6.2f ms  worst %6.2f ms  (%d frames)"
			% [RenderQuality.level_name(level), row["mean"], row["p95"],
				row["worst"], row["frames"]])

	# The assertion: each level must be materially cheaper than the one above.
	for index: int in range(_levels.size() - 1):
		var cheaper: Dictionary = _results[_levels[index]]
		var dearer: Dictionary = _results[_levels[index + 1]]
		var ratio: float = (dearer["mean"] as float) \
			/ maxf(cheaper["mean"] as float, 0.0001)
		var names := "%s vs %s" % [
			RenderQuality.level_name(_levels[index] as RenderQuality.Level),
			RenderQuality.level_name(_levels[index + 1] as RenderQuality.Level)]
		if ratio < REQUIRED_MARGIN:
			failures.append(
				"%s: only %.2fx apart, needs %.2fx — a quality level that "
				% [names, ratio, REQUIRED_MARGIN]
				+ "costs what the one above it costs is not a quality level")
		else:
			print("  %s: %.2fx apart (needs %.2fx) OK" % [names, ratio,
				REQUIRED_MARGIN])

	# Advisory only, and labelled as such: see the header on why an absolute
	# millisecond figure off this rasteriser is not a claim about a player's.
	var medium: Dictionary = _results[RenderQuality.Level.MEDIUM]
	print("  ADVISORY: medium p95 is %.2f ms here. On a 60 fps budget of "
		% (medium["p95"] as float)
		+ "16.67 ms this is only meaningful when run on the target machine.")

	if failures.is_empty():
		print("GPU GATE: PASS")
		quit(0)
		return true
	for failure: String in failures:
		print("  - %s" % failure)
	print("GPU GATE: FAIL")
	quit(1)
	return true
