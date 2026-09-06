extends Node

## Drives Bubble Bay from spawn to finish (REQ-028 AC-3/AC-4/AC-5/AC-6).
##
## Like the coral walk, this probe IS about one world: it enters bubble_bay
## by id and proves the world's own claims with one held forward key.
##
## What one traversal proves, because the route makes each of these MANDATORY:
##   * both movement grammars ran (the bay spans the route — AC-4),
##   * the jet gate opened, which can only happen by equipping the Jet mod —
##     the mod Coral Cove does not emphasize (AC-5),
##   * region kelp_nursery reached `restored` on the DEFAULT resource costs
##     (the manifest carries no tuningOverrides), which is the only thing
##     that opens the nursery boom in front of the finish (AC-4's region
##     half),
##   * the finish condition returned the player to the hub (AC-3),
##   * the manifest declares NO boss, and the completion above happened
##     anyway — the optional-boss path proven end to end (AC-6).

const WORLD_ID := "bubble_bay"
const MANIFEST_PATH := "res://worlds/bubble_bay/world.json"
const SETTLE_FRAMES := 30
const JOURNEY_FRAMES := 4200

var _failures: PackedStringArray = []
var _checks := 0
var _frame := 0

var _hub: OpenLagoon
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

## REQ-010: pearls collected as the declared `pearl` resource type.
var _pearls := 0

## REQ-003: checkpoints activated by touch; lives never spent on this route.
var _checkpoints_hit: PackedStringArray = []
var _lives_spent := 0

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
		"the hub discovered bubble_bay as an available portal")
	if portal == null or not portal.available:
		_report()
		return

	# AC-6's declaration half: the manifest genuinely carries no boss element.
	# The completion the walk earns below is the proof the absence is viable.
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest: Variant = JSON.parse_string(manifest_text)
	_check(manifest is Dictionary and not (manifest as Dictionary).has("boss"),
		"the bubble_bay manifest declares no boss")
	_check(manifest is Dictionary
		and not (manifest as Dictionary).has("tuningOverrides"),
		"the bubble_bay manifest declares no tuningOverrides "
		+ "(the walk below runs on default restoration costs)")

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
		_check(_entered, "enter_world(bubble_bay) succeeded")
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
			if collectible_id == "pearl":
				_pearls += 1)
	systems.checkpoint_activated.connect(
		func(id: String) -> void: _checkpoints_hit.append(id))
	systems.life_lost.connect(
		func(_remaining: int, _source: CatastrophicSource.Kind) -> void:
			_lives_spent += 1)


func _finish_checks() -> void:
	_check(_completed_id == WORLD_ID,
		"the completed world is bubble_bay (got '%s')" % _completed_id)
	_check(_grammars_seen.has(MovementGrammar.Grammar.WATER)
		and _grammars_seen.has(MovementGrammar.Grammar.LAND),
		"both movement grammars ran on the route (saw %s)"
		% str(_grammars_seen.keys()))
	_check(_mods_equipped.has("jet"),
		"the route equipped the Jet mod (got %s)" % str(_mods_equipped))
	_check(_gates_opened.has("affordance:jet_dash"),
		"the jet-gated barrier opened (got %s)" % str(_gates_opened))
	_check(_gates_opened.has("restoration:nursery_boom"),
		"restoring kelp_nursery opened the nursery boom")
	_check(_region_restored,
		"region kelp_nursery reached restored on default costs")
	_check(_pearls == 13,
		"all thirteen pearls were collected as the declared resource (got %d)"
		% _pearls)
	var recorded: Variant = _save.get_world_data(WORLD_ID).get("collectibles", [])
	_check(recorded is Array and (recorded as Array).is_empty(),
		"a resource-only world records no collectible ids in the profile (%s)"
		% str(recorded))
	_check(_checkpoints_hit.size() == _checkpoint_z.size(),
		"every checkpoint was activated by touch (%d of %d)"
		% [_checkpoints_hit.size(), _checkpoint_z.size()])
	_check(_lives_spent == 0, "no life was spent on the route (spent %d)" % _lives_spent)
	_check(_returned, "the finish condition returned control to the hub")
	_check(_body.global_position.distance_to(_hub_spawn) < 6.0,
		"the player is back at the hub spawn (%.1f m away)"
		% _body.global_position.distance_to(_hub_spawn))

	# The completion is visible through the save-integration interface.
	var portal := _hub.get_registry().get_portal(WORLD_ID)
	_check_checkpoint_spacing()

	_check(portal != null and portal.completed,
		"the bubble_bay portal now shows completed")

	_report()


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
		% ["BUBBLE WALK", ", ".join(segments), bound])


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
		print("BUBBLE WALK: %d checks passed" % _checks)
		get_tree().quit(0)
		return
	print("BUBBLE WALK: %d of %d checks FAILED" % [_failures.size(), _checks])
	for failure: String in _failures:
		print("  - %s" % failure)
	get_tree().quit(1)
