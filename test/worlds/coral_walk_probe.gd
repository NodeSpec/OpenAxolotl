extends Node

## Drives Coral Cove from spawn to finish (REQ-011 AC-2/AC-4/AC-5).
##
## Unlike the hub walk — which deliberately names no world — this probe IS
## about one world: it enters coral_cove by id and proves the world's own
## claims. One held forward key carries the whole route, because the world was
## designed for exactly that: completability is a regression test, not a hope.
##
## What one traversal proves, because the route makes each of these MANDATORY:
##   * both movement grammars ran (the lagoon spans the route — AC-4),
##   * the glow and bubble gates opened, which can only happen by equipping
##     those mods (AC-5's per-world half),
##   * region coral_shelf reached `restored`, which is the only thing that
##     opens the shelf wall in front of the finish (AC-4's region half),
##   * the finish condition returned the player to the hub (AC-2).

const WORLD_ID := "coral_cove"
const SETTLE_FRAMES := 30
const JOURNEY_FRAMES := 4200

var _failures: PackedStringArray = []
var _checks := 0
var _frame := 0

var _hub: OpenLagoon
var _systems: WorldSystems
var _save := SaveSystem.new()
var _body: CharacterBody3D
var _hub_spawn := Vector3.ZERO

var _entered := false
var _completed_id := ""
var _returned := false
var _grammars_seen: Dictionary = {}
var _mods_equipped: PackedStringArray = []
var _gates_opened: PackedStringArray = []
var _region_restored := false

## REQ-010: every collectible the route collected, by id, in order — the
## resource type once per seed, a discovery once ever.
var _collected: PackedStringArray = []

## REQ-002/REQ-003: pillar one on the route — capabilities lost and regrown,
## checkpoints activated by touch, and lives (which the route never spends).
var _lost: PackedStringArray = []
var _regrown: PackedStringArray = []
var _checkpoints_hit: PackedStringArray = []
var _lives_spent := 0
var _lives_at_entry := -1

## REQ-003 AC-7: checkpoint spacing, MEASURED. World-space z of every
## checkpoint in route order (the route runs down -z), and the second at
## which the walk reached each anchor — spawn, each checkpoint, finish.
const TUNING_PATH := "res://core/tuning/tuning.json"
const MAX_RETRY_KEY := "progression.max_retry_seconds"
var _checkpoint_z: PackedFloat64Array = []
var _next_checkpoint := 0
var _anchor_seconds: PackedFloat64Array = [0.0]
var _walk_start_frame := 0


func _ready() -> void:
	var scene := get_tree().current_scene
	_hub = scene as OpenLagoon
	if _hub == null and scene != null:
		for node: Node in scene.find_children("*", "", true, false):
			if node is OpenLagoon:
				_hub = node as OpenLagoon
				break
	if _hub == null:
		_fail("the hub scene did not load an OpenLagoon node")
		_report()
		return

	_hub.set_save_system(_save)

	var portal := _hub.get_registry().get_portal(WORLD_ID)
	_check(portal != null and portal.available,
		"the hub discovered coral_cove as an available portal")
	if portal == null or not portal.available:
		_report()
		return

	_body = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_check(_body != null, "the hub scene ships a player body")
	if _body == null:
		_report()
		return
	if _body.has_signal("grammar_changed"):
		_body.connect("grammar_changed",
			func(grammar: MovementGrammar.Grammar) -> void:
				_grammars_seen[grammar] = true)

	_hub.world_completed.connect(func(world_id: String) -> void:
		_completed_id = world_id)
	_hub.returned_to_hub.connect(func(_world_id: String) -> void:
		_returned = true
		_key(KEY_W, false))

	var spawn := get_tree().get_first_node_in_group("hub_spawn")
	_hub_spawn = (spawn as Node3D).global_position if spawn is Node3D \
		else Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if _body == null or not _body.is_inside_tree():
		return

	_frame += 1
	if _frame == SETTLE_FRAMES:
		# Enter by id — this probe tests the world, not portal geometry.
		_entered = _hub.enter_world(WORLD_ID)
		_check(_entered, "enter_world(coral_cove) succeeded")
		if not _entered:
			_report()
		return

	if _frame == SETTLE_FRAMES + 2:
		_wire_world_systems()
		_collect_checkpoints()
		_walk_start_frame = _frame
		_key(KEY_W, true)
		return

	if not _returned:
		_mark_checkpoints_passed()

	if _returned:
		if _anchor_seconds.size() == _checkpoint_z.size() + 1:
			_anchor_seconds.append(_elapsed_seconds())
		if _frame < SETTLE_FRAMES + 8:
			return
		_finish_checks()
		return

	if _frame > SETTLE_FRAMES + JOURNEY_FRAMES:
		_fail("the walk never completed (z=%.1f, grammars=%s, mods=%s, "
			% [_body.global_position.z, str(_grammars_seen.keys()),
				str(_mods_equipped)]
			+ "gates=%s, restored=%s)"
			% [str(_gates_opened), str(_region_restored)])
		_report()


func _wire_world_systems() -> void:
	var systems := get_tree().get_first_node_in_group("world_systems") \
		as WorldSystems
	_check(systems != null, "the hub attached a WorldSystems runtime")
	if systems == null:
		return
	systems.mod_equipped.connect(func(mod_id: String) -> void:
		if not _mods_equipped.has(mod_id):
			_mods_equipped.append(mod_id))
	systems.gate_changed.connect(
		func(kind: String, ref: String, open: bool) -> void:
			var tag := "%s:%s" % [kind, ref]
			if open and not _gates_opened.has(tag):
				_gates_opened.append(tag))
	systems.get_restoration().region_state_changed.connect(
		func(_region: String, _from: RegionState.State,
				to: RegionState.State) -> void:
			if to == RegionState.State.RESTORED:
				_region_restored = true)
	systems.collectible_collected.connect(
		func(collectible_id: String, _kind: CollectibleKind.Kind) -> void:
			_collected.append(collectible_id))
	systems.get_regen().capability_lost.connect(
		func(kind: Capability.Kind) -> void: _lost.append(Capability.id(kind)))
	systems.get_regen().capability_restored.connect(
		func(kind: Capability.Kind) -> void: _regrown.append(Capability.id(kind)))
	systems.checkpoint_activated.connect(
		func(id: String) -> void: _checkpoints_hit.append(id))
	systems.life_lost.connect(
		func(_remaining: int, _source: CatastrophicSource.Kind) -> void:
			_lives_spent += 1)
	_lives_at_entry = systems.get_lives().get_lives()
	_systems = systems


func _finish_checks() -> void:
	_check(_completed_id == WORLD_ID,
		"the completed world is coral_cove (got '%s')" % _completed_id)
	_check(_grammars_seen.has(MovementGrammar.Grammar.WATER)
		and _grammars_seen.has(MovementGrammar.Grammar.LAND),
		"both movement grammars ran on the route (saw %s)"
		% str(_grammars_seen.keys()))
	_check(_mods_equipped.has("glow") and _mods_equipped.has("bubble"),
		"the route equipped both Glow and Bubble (got %s)"
		% str(_mods_equipped))
	_check(_gates_opened.has("affordance:reveal_bioluminescent")
		and _gates_opened.has("affordance:bubble_platform"),
		"both mod-gated barriers opened (got %s)" % str(_gates_opened))
	_check(_gates_opened.has("restoration:shelf_wall"),
		"restoring coral_shelf opened the shelf wall")
	_check(_region_restored, "region coral_shelf reached restored")
	_check_collectibles()
	_check_pillar_one()
	_check(_returned, "the finish condition returned control to the hub")
	_check(_body.global_position.distance_to(_hub_spawn) < 6.0,
		"the player is back at the hub spawn (%.1f m away)"
		% _body.global_position.distance_to(_hub_spawn))

	# The completion is visible through the save-integration interface.
	var portal := _hub.get_registry().get_portal(WORLD_ID)
	_check_checkpoint_spacing()

	_check(portal != null and portal.completed,
		"the coral_cove portal now shows completed")

	_report()


## REQ-010, end to end through the real runtime and the real save interface:
## the seven seeds were collected as the ONE declared resource type and
## spent (the shelf restored above proves the spending); the on-route
## discovery was rescued once and is in the profile; the off-route one was
## not — an optional branch stays optional.
func _check_collectibles() -> void:
	_check(_collected.count("kelp_seed") == 7,
		"all seven kelp seeds were collected as the declared resource (got %d)"
		% _collected.count("kelp_seed"))
	_check(_collected.count("hermit_snail") == 1,
		"the hermit snail was rescued exactly once (got %d)"
		% _collected.count("hermit_snail"))
	_check(not _collected.has("lantern_shrimp"),
		"the off-route lantern shrimp was NOT collected by the straight walk")
	var recorded: Variant = _save.get_world_data(WORLD_ID).get("collectibles", [])
	_check(recorded is Array and (recorded as Array).has("hermit_snail"),
		"the rescued snail is recorded in the profile through the save interface (%s)"
		% str(recorded))
	_check(recorded is Array and not (recorded as Array).has("kelp_seed"),
		"a spent resource is never recorded by id")


## REQ-002/REQ-003 on the real route: the stray hook stripped the leg once
## and never cost a life; the regen station regrew it; every checkpoint was
## activated by walking through it; the lives count is untouched at the end.
func _check_pillar_one() -> void:
	_check(_lost == PackedStringArray(["leg"]),
		"the stray hook stripped exactly the leg (got %s)" % str(_lost))
	_check(_regrown == PackedStringArray(["leg"]),
		"the regen station regrew the leg (got %s)" % str(_regrown))
	_check(_lives_spent == 0,
		"ordinary hazard contact spent no life (spent %d)" % _lives_spent)
	_check(_checkpoints_hit.size() == _checkpoint_z.size(),
		"every checkpoint was activated by touch (%d of %d: %s)"
		% [_checkpoints_hit.size(), _checkpoint_z.size(), str(_checkpoints_hit)])
	_check(_lives_at_entry > 0,
		"the world opened with a positive life count (%d)" % _lives_at_entry)
	var recorded: Variant = _save.get_world_data(WORLD_ID).get("lastCheckpointId", "")
	_check(String(recorded) != "" and _checkpoints_hit.has(String(recorded)),
		"the last activated checkpoint is recorded in the profile (%s)" % str(recorded))


func _elapsed_seconds() -> float:
	return float(_frame - _walk_start_frame) \
		/ float(Engine.physics_ticks_per_second)


## Every node the world put in the `checkpoint` group, in route order.
func _collect_checkpoints() -> void:
	var zs: Array[float] = []
	for node: Node in get_tree().get_nodes_in_group("checkpoint"):
		if node is Node3D:
			zs.append((node as Node3D).global_position.z)
	zs.sort()
	zs.reverse()  # the route runs down -z: highest z first
	_checkpoint_z = PackedFloat64Array(zs)


func _mark_checkpoints_passed() -> void:
	while _next_checkpoint < _checkpoint_z.size() \
			and _body.global_position.z <= _checkpoint_z[_next_checkpoint]:
		_anchor_seconds.append(_elapsed_seconds())
		_next_checkpoint += 1


## REQ-003 AC-7: the replay from any anchor to the next — spawn to the first
## checkpoint, checkpoint to checkpoint, last checkpoint to the finish — at
## normal traversal speed must fit inside progression.max_retry_seconds.
## Measured from this very walk, never estimated from geometry.
func _check_checkpoint_spacing() -> void:
	var errors: Array[TuningError] = []
	var tuning := TuningData.load_from_file(TUNING_PATH, errors)
	if tuning == null:
		_fail("tuning failed to load for the spacing check")
		return
	var bound := tuning.get_number(MAX_RETRY_KEY)

	_check(_checkpoint_z.size() >= 1, "the world declares at least one checkpoint")
	_check(_anchor_seconds.size() == _checkpoint_z.size() + 2,
		"every checkpoint was passed on the route (%d of %d anchors marked)"
		% [_anchor_seconds.size(), _checkpoint_z.size() + 2])

	var longest := 0.0
	var segments: PackedStringArray = []
	for index: int in range(1, _anchor_seconds.size()):
		var segment := _anchor_seconds[index] - _anchor_seconds[index - 1]
		longest = maxf(longest, segment)
		segments.append("%.1f" % segment)
	_check(longest <= bound,
		"checkpoint spacing: longest replay segment %.1fs is within %s = %.1fs (segments: %s)"
		% [longest, MAX_RETRY_KEY, bound, ", ".join(segments)])
	print("%s: checkpoint segments (s): %s (bound %.1f)"
		% ["CORAL WALK", ", ".join(segments), bound])


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _fail(description: String) -> void:
	_checks += 1
	_failures.append(description)


func _report() -> void:
	print("==================================================================")
	if _failures.is_empty():
		print("CORAL WALK: %d checks passed" % _checks)
		get_tree().quit(0)
		return
	print("CORAL WALK: %d of %d checks FAILED" % [_failures.size(), _checks])
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)
