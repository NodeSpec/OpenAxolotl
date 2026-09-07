extends Node

## The performance regression gate (REQ-027 AC-3/AC-4/AC-5's mechanism).
##
## Enters an official world through the hub, traverses it to completion with
## one held key, and measures the three documented targets from
## contracts/performance_targets.v1.json (docs/performance.md is the prose
## authority; tools/test_performance_targets.py keeps the two in agreement):
##
##   * LOAD: wall-clock from the enter_world call to the first physics frame
##     with the player in the world, vs worldLoadTimeBudgetMs.
##   * SPIKE: wall-clock deltas between consecutive physics frames after a
##     settle window; the single largest is discarded per the documented
##     protocol (one scheduler hiccup on a shared runner is noise), the
##     next-largest is checked vs maxFrameTimeSpikeMs. The delta of the
##     frame in which the restoration transition fired is ALSO checked on
##     its own -- that frame swaps region geometry, the REQ-027 risk case,
##     and never gets the outlier discard.
##   * RATE: physics frames / elapsed wall seconds vs frameRateTargetFps
##     with the documented tolerance. A regression tripwire ONLY -- headless
##     CI hardware is not the baseline specification and renders nothing,
##     so this cannot prove the baseline frame-rate criterion and does not
##     claim to (see docs/performance.md).
##
## Exit 0 when every measurable target holds; exit 1 with the measured
## numbers when any is breached.

## The world under measurement. bubble_bay stays the default, and the
## harness runs the gate AGAIN with OAX_PERF_WORLD=coral_cove: the valley is
## the heaviest official scene (forest, two rivers, the flown route's
## geometry), and a perf gate that never loads the heaviest world is a gate
## on the wrong door.
const DEFAULT_WORLD_ID := "bubble_bay"

var _world_id := DEFAULT_WORLD_ID
const TARGETS_PATH := "res://contracts/performance_targets.v1.json"
const SETTLE_FRAMES := 30

## Frame budget for the traversal. The piloted route through the valley is
## several times longer than bubble_bay's corridor, and slower per metre —
## climbs, dives and pillar detours — so it gets the same budget the coral
## walk itself runs under.
const JOURNEY_FRAMES := 4200
const PILOTED_JOURNEY_FRAMES := 14000

var _failures: PackedStringArray = []
var _frame := 0

var _hub: OpenLagoon
var _save := SaveSystem.new()
var _body: CharacterBody3D

## Coral Cove is flown rather than walked: it is a platforming route, and a
## held forward key stalls at the first gap. The SAME waypoints the coral
## walk proves completability with drive the measurement here — the perf
## gate must measure the route that exists, not the corridor that used to.
var _pilot: RoutePilot

var _fps_target := 0.0


func _resolve_world_id() -> void:
	var requested := OS.get_environment("OAX_PERF_WORLD")
	if not requested.is_empty():
		_world_id = requested
var _spike_budget_ms := 0.0
var _load_budget_ms := 0.0
var _rate_tolerance := 1.0
var _discard_spikes := 0
var _settle_after_entry := 0

var _entered := false
var _returned := false
var _enter_started_usec := 0
var _load_ms := -1.0

var _last_tick_usec := 0
var _deltas_ms: PackedFloat64Array = []
var _measure_started_usec := 0
var _restore_pending := false
var _restore_delta_ms := -1.0


func _ready() -> void:
	_resolve_world_id()
	var scene := get_tree().current_scene
	_hub = scene as OpenLagoon
	if _hub == null and scene != null:
		for node: Node in scene.find_children("*", "", true, false):
			if node is OpenLagoon:
				_hub = node as OpenLagoon
				break
	if _hub == null:
		_fail_now("the hub scene did not load an OpenLagoon node")
		return

	if not _load_targets():
		return

	_hub.set_save_system(_save)

	var portal := _hub.get_registry().get_portal(_world_id)
	if portal == null or not portal.available:
		_fail_now("world '%s' is not an available portal" % _world_id)
		return

	_body = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _body == null:
		_fail_now("the hub scene ships no player body")
		return

	_hub.returned_to_hub.connect(func(_world_id: String) -> void:
		_returned = true
		_key(KEY_W, false))


func _load_targets() -> bool:
	var text := FileAccess.get_file_as_string(TARGETS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is not Dictionary:
		_fail_now("could not parse %s" % TARGETS_PATH)
		return false
	var targets := parsed as Dictionary
	for key: String in ["frameRateTargetFps", "maxFrameTimeSpikeMs",
			"worldLoadTimeBudgetMs"]:
		if not (targets.get(key) is float and float(targets[key]) > 0.0):
			_fail_now("%s must carry a positive number '%s'"
				% [TARGETS_PATH, key])
			return false
	_fps_target = float(targets["frameRateTargetFps"])
	_spike_budget_ms = float(targets["maxFrameTimeSpikeMs"])
	_load_budget_ms = float(targets["worldLoadTimeBudgetMs"])
	var protocol: Dictionary = targets.get("headlessProtocol", {})
	_rate_tolerance = float(protocol.get("sustainedRateTolerance", 1.0))
	_discard_spikes = int(protocol.get("discardLargestSpikes", 0))
	_settle_after_entry = int(protocol.get("settleFrames", 60))
	return true


func _physics_process(_delta: float) -> void:
	if _body == null or not _body.is_inside_tree():
		return

	_frame += 1
	if _frame == SETTLE_FRAMES:
		_enter_started_usec = Time.get_ticks_usec()
		_entered = _hub.enter_world(_world_id)
		if not _entered:
			_fail_now("enter_world(%s) failed" % _world_id)
		return

	if _entered and _load_ms < 0.0:
		# First physics frame with the player in the world: the load claim.
		_load_ms = float(Time.get_ticks_usec() - _enter_started_usec) / 1000.0
		_wire_restoration()
		if _world_id == "coral_cove":
			_pilot = RoutePilot.new(CoralRoute.waypoints(), _world_origin())
		else:
			_key(KEY_W, true)
		return

	if _entered and not _returned:
		if _pilot != null:
			_pilot.step(_body)
			if not _pilot.stuck_reason().is_empty():
				_fail_now("the route stalled: %s" % _pilot.stuck_reason())
				return
		_record_frame_delta()

	if _returned:
		if _frame < SETTLE_FRAMES + 8:
			return
		_evaluate()
		return

	var journey := PILOTED_JOURNEY_FRAMES if _pilot != null else JOURNEY_FRAMES
	if _frame > SETTLE_FRAMES + journey:
		_fail_now("the traversal never completed (z=%.1f)"
			% _body.global_position.z)


func _wire_restoration() -> void:
	var systems := get_tree().get_first_node_in_group("world_systems") \
		as WorldSystems
	if systems == null:
		_fail_now("no WorldSystems runtime attached to the world")
		return
	systems.get_restoration().region_state_changed.connect(
		func(_region: String, _from: RegionState.State,
				to: RegionState.State) -> void:
			if to == RegionState.State.RESTORED:
				# The geometry swap this signal triggers lands within the
				# current physics frame; the NEXT recorded delta is that
				# frame's wall cost.
				_restore_pending = true)


func _record_frame_delta() -> void:
	var now := Time.get_ticks_usec()
	if _last_tick_usec == 0:
		_last_tick_usec = now
		return
	var delta_ms := float(now - _last_tick_usec) / 1000.0
	_last_tick_usec = now
	if _restore_pending:
		_restore_pending = false
		_restore_delta_ms = delta_ms
	# The settle window keeps world-entry instantiation noise out of the
	# traversal sample; entry cost is the LOAD claim, measured above.
	if _frame < SETTLE_FRAMES + _settle_after_entry:
		return
	if _measure_started_usec == 0:
		_measure_started_usec = now
		return
	_deltas_ms.append(delta_ms)


func _evaluate() -> void:
	# LOAD vs budget.
	if _load_ms < 0.0:
		_failures.append("load time was never measured")
	elif _load_ms > _load_budget_ms:
		_failures.append("LOAD breached: %.1f ms > %.0f ms budget"
			% [_load_ms, _load_budget_ms])

	# SPIKE vs budget, largest outlier(s) discarded per protocol.
	if _deltas_ms.size() < 100:
		_failures.append("too few frame samples (%d) to judge spikes"
			% _deltas_ms.size())
	else:
		var sorted := _deltas_ms.duplicate()
		sorted.sort()
		var index := sorted.size() - 1 - _discard_spikes
		var spike: float = sorted[index]
		if spike > _spike_budget_ms:
			_failures.append(
				"SPIKE breached: %.1f ms > %.0f ms budget (worst %.1f ms)"
				% [spike, _spike_budget_ms, sorted[sorted.size() - 1]])

	# The restoration-transition frame, on its own, no discard.
	if _restore_delta_ms < 0.0:
		_failures.append("the restoration transition was never observed")
	elif _restore_delta_ms > _spike_budget_ms:
		_failures.append(
			"RESTORE SPIKE breached: %.1f ms > %.0f ms budget"
			% [_restore_delta_ms, _spike_budget_ms])

	# RATE vs target with tolerance -- the regression tripwire.
	var elapsed_s := float(Time.get_ticks_usec() - _measure_started_usec) \
		/ 1000000.0
	var rate := float(_deltas_ms.size()) / elapsed_s if elapsed_s > 0.0 \
		else 0.0
	if rate < _fps_target * _rate_tolerance:
		_failures.append(
			"RATE breached: %.1f physics fps < %.0f x %.2f tolerance"
			% [rate, _fps_target, _rate_tolerance])

	print("==================================================================")
	print("PERF GATE (%s): load %.1f ms (budget %.0f) | restore frame %.1f ms"
		% [_world_id, _load_ms, _load_budget_ms, _restore_delta_ms])
	if _deltas_ms.size() >= 100:
		var sorted := _deltas_ms.duplicate()
		sorted.sort()
		print("  spike (after discarding %d) %.1f ms, worst %.1f ms "
			% [_discard_spikes, sorted[sorted.size() - 1 - _discard_spikes],
				sorted[sorted.size() - 1]]
			+ "(budget %.0f) | rate %.1f fps over %d frames"
			% [_spike_budget_ms, float(_deltas_ms.size()) \
				/ (float(Time.get_ticks_usec() - _measure_started_usec) \
				/ 1000000.0), _deltas_ms.size()])
	if _failures.is_empty():
		print("PERF GATE: all measurable targets hold")
		get_tree().quit(0)
		return
	print("PERF GATE: %d target(s) BREACHED" % _failures.size())
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)


func _fail_now(description: String) -> void:
	print("==================================================================")
	print("PERF GATE: %s" % description)
	get_tree().quit(1)


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


## The active world's placement offset: the spawn marker is a direct child
## of the world root, so its parent's global position is the offset the
## route's level-space waypoints need (the same resolution the walk uses).
func _world_origin() -> Vector3:
	var spawn := get_tree().get_first_node_in_group("spawn_point")
	if spawn == null:
		return Vector3.ZERO
	var world_root := (spawn as Node).get_parent() as Node3D
	return world_root.global_position if world_root != null else Vector3.ZERO
