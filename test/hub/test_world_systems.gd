extends GdUnitTestSuite

## WorldSystems — the runtime a world's declarations bind to (REQ-011,
## serving REQ-004 and REQ-008 at world scope).
##
## These tests build tiny declared worlds in code and drive the SEAMS —
## equip/activate, deliver, revert — rather than physics; the end-to-end
## physics path (pickup volumes, a real body, a real route) is the coral walk
## probe's job. Barrier openness is asserted through visibility: a visible
## barrier is a closed one, and collision follows it on the deferred flush.

const REGION_MANIFEST := {
	"restorableRegions": [
		{
			"regionId": "reef",
			"traversalGates": [{"gateId": "reef_wall", "opensAt": "restored"}],
		},
	],
	"tuningOverrides": {
		"restoration.resourced.resource_cost": 3,
		"restoration.restored.resource_cost": 4,
	},
}


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _barrier(group: String, metas: Dictionary) -> StaticBody3D:
	var barrier := StaticBody3D.new()
	barrier.add_to_group(group)
	for key: String in metas:
		barrier.set_meta(key, metas[key])
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	barrier.add_child(shape)
	return barrier


func _build_world(manifest: Dictionary,
		barriers: Array[StaticBody3D]) -> Array:
	var world := Node3D.new()
	for barrier in barriers:
		world.add_child(barrier)
	_root().add_child(world)
	var systems := WorldSystems.new()
	systems.manifest = manifest
	world.add_child(systems)
	# The runner adds nodes before the tree's first iteration, so _ready never
	# fires here; wire() is the same entry point, idempotent by design.
	systems.wire()
	return [world, systems]


func _teardown(world: Node) -> void:
	_root().remove_child(world)
	world.free()


func test_req_011_world_tuning_overrides_are_applied() -> void:
	var built := _build_world(REGION_MANIFEST, [])
	var systems := built[1] as WorldSystems
	assert_int(systems.get_tuning().get_count(
		"restoration.resourced.resource_cost")).is_equal(3)
	assert_int(systems.get_tuning().get_count(
		"restoration.restored.resource_cost")).is_equal(4)
	_teardown(built[0])


func test_req_011_a_world_without_a_boss_has_unlocked_regions() -> void:
	# The interim unlock policy: nothing exists to gate on, so restoration
	# can begin at entry. Recorded in the contract friction log.
	var built := _build_world(REGION_MANIFEST, [])
	var systems := built[1] as WorldSystems
	assert_bool(systems.get_restoration().is_unlocked("reef")).is_true()
	_teardown(built[0])


func test_req_008_a_boss_declared_world_keeps_regions_locked() -> void:
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["boss"] = {"kind": "flagship"}
	var built := _build_world(manifest, [])
	var systems := built[1] as WorldSystems
	assert_bool(systems.get_restoration().is_unlocked("reef")).is_false()
	# And locked means locked: resources accumulate but nothing advances.
	systems.get_restoration().deliver_resources("reef", 99)
	assert_int(int(systems.get_restoration().get_state("reef"))) \
		.is_equal(int(RegionState.State.BARREN))
	_teardown(built[0])


func test_req_008_restoring_the_region_opens_its_scene_gate() -> void:
	var wall := _barrier("restoration_gate",
		{"region_id": "reef", "gate_id": "reef_wall"})
	var built := _build_world(REGION_MANIFEST, [wall])
	var systems := built[1] as WorldSystems

	assert_bool(wall.visible).is_true()  # closed while barren
	systems.get_restoration().deliver_resources("reef", 3)
	assert_bool(wall.visible).is_true()  # resourced is not restored
	systems.get_restoration().deliver_resources("reef", 4)
	assert_bool(wall.visible).is_false()  # restored -> open
	_teardown(built[0])


func test_req_008_a_dredger_reversion_closes_the_gate_again() -> void:
	# Both directions, because a reverted region keeping its route open would
	# make reversion cosmetic — exactly what REQ-008 AC-5 forbids.
	var wall := _barrier("restoration_gate",
		{"region_id": "reef", "gate_id": "reef_wall"})
	var built := _build_world(REGION_MANIFEST, [wall])
	var systems := built[1] as WorldSystems

	systems.get_restoration().deliver_resources("reef", 7)
	assert_bool(wall.visible).is_false()
	systems.get_restoration().dredger_attack("reef")
	assert_bool(wall.visible).is_true()
	# The unlock survives the reversion, so restoration can be redone.
	assert_bool(systems.get_restoration().is_unlocked("reef")).is_true()
	_teardown(built[0])


func test_req_011_an_affordance_gate_follows_the_active_window() -> void:
	var gate := _barrier("affordance_gate",
		{"affordance": "reveal_bioluminescent"})
	var built := _build_world({}, [gate])
	var systems := built[1] as WorldSystems

	assert_bool(gate.visible).is_true()  # closed with nothing equipped

	systems.get_mods().equip("glow")
	systems.get_mods().activate()
	assert_bool(gate.visible).is_false()  # open while the window is active

	# The window closes when the activation expires — an affordance is never
	# a permanent upgrade, per the Gill Mod framework's own doctrine.
	systems.get_mods().tick(3600.0)
	assert_bool(gate.visible).is_true()
	_teardown(built[0])


func test_req_011_the_wrong_mod_opens_nothing() -> void:
	var gate := _barrier("affordance_gate",
		{"affordance": "reveal_bioluminescent"})
	var built := _build_world({}, [gate])
	var systems := built[1] as WorldSystems

	systems.get_mods().equip("jet")
	systems.get_mods().activate()
	assert_bool(gate.visible).is_true()  # jet grants no reveal
	_teardown(built[0])


func test_req_011_wiring_is_scoped_to_its_own_world() -> void:
	# Two worlds could momentarily coexist in a tree (tests, transitions);
	# a WorldSystems must never reach into a neighbour's gates.
	var foreign_gate := _barrier("affordance_gate",
		{"affordance": "reveal_bioluminescent"})
	var foreign_world := Node3D.new()
	foreign_world.add_child(foreign_gate)
	_root().add_child(foreign_world)

	var built := _build_world({}, [])
	var systems := built[1] as WorldSystems
	systems.get_mods().equip("glow")
	systems.get_mods().activate()
	assert_bool(foreign_gate.visible).is_true()  # untouched

	_teardown(built[0])
	_root().remove_child(foreign_world)
	foreign_world.free()


# --- REQ-010: the `collectible` convention binds to the Collectibles System -

const COLLECTIBLE_MANIFEST := {
	"finishCondition": {"kind": "collect_all"},
	"restorableRegions": [
		{
			"regionId": "reef",
			"traversalGates": [{"gateId": "reef_wall", "opensAt": "restored"}],
		},
	],
	"tuningOverrides": {
		"restoration.resourced.resource_cost": 3,
		"restoration.restored.resource_cost": 4,
	},
	"collectibles": [
		{"collectibleId": "kelp_seed", "kind": "resource", "regionId": "reef"},
		{"collectibleId": "hermit_snail", "kind": "discovery"},
		{"collectibleId": "lantern_shrimp", "kind": "discovery"},
	],
}


func _pickup(collectible_id: String) -> Area3D:
	var area := Area3D.new()
	area.add_to_group("collectible")
	area.set_meta("collectible_id", collectible_id)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	area.add_child(shape)
	return area


func _build_collectible_world(pickups: Array[Area3D], save: SaveSystem = null,
		world_id: String = "reef_world") -> Array:
	var world := Node3D.new()
	for pickup in pickups:
		world.add_child(pickup)
	_root().add_child(world)
	var systems := WorldSystems.new()
	systems.manifest = COLLECTIBLE_MANIFEST
	systems.world_id = world_id
	systems.save_system = save
	if save != null:
		save.open_world(world_id, COLLECTIBLE_MANIFEST)
	world.add_child(systems)
	systems.wire()
	return [world, systems]


func test_req_010_a_placed_resource_delivers_to_its_region_and_opens_the_gate() -> void:
	# Seven scene seeds, one declared type: each pickup delivers to the reef,
	# and the seventh restores it — the declaration, not a script, did that.
	var wall := _barrier("restoration_gate",
		{"region_id": "reef", "gate_id": "reef_wall"})
	var seeds: Array[Area3D] = []
	for _index: int in range(7):
		seeds.append(_pickup("kelp_seed"))
	var built := _build_collectible_world(seeds)
	var world := built[0] as Node3D
	world.add_child(wall)
	var systems := built[1] as WorldSystems
	systems._restoration_gates["reef_wall"] = wall
	var delivered: Array[int] = []
	systems.resource_delivered.connect(
		func(_region: String, held: int) -> void: delivered.append(held))

	for seed in seeds:
		assert_bool(systems.collect_node(seed)).is_true()
		assert_bool(seed.is_queued_for_deletion()).is_true()

	assert_int(delivered.size()).is_equal(7)
	assert_int(int(systems.get_restoration().get_state("reef"))).is_equal(
		int(RegionState.State.RESTORED))
	assert_bool(wall.visible).override_failure_message(
		"REQ-010 AC-1: spending the seeds must open the declared gate").is_false()
	_teardown(world)


func test_req_010_a_placed_discovery_is_persisted_and_absent_on_re_entry() -> void:
	var save := SaveSystem.new()
	var snail := _pickup("hermit_snail")
	var first := _build_collectible_world([snail], save)
	var systems := first[1] as WorldSystems

	assert_bool(systems.collect_node(snail)).is_true()
	assert_bool(snail.is_queued_for_deletion()).is_true()
	assert_array(save.get_world_data("reef_world")["collectibles"] as Array
		).is_equal(["hermit_snail"])
	# Collected once: a second touch of the same id changes nothing.
	var twin := _pickup("hermit_snail")
	assert_bool(systems.collect_node(twin)).is_false()
	twin.free()
	_teardown(first[0])

	# Re-entering the world over the same profile: the snail is already
	# rescued, so its node is gone at wire time and the shrimp remains.
	var snail_again := _pickup("hermit_snail")
	var shrimp := _pickup("lantern_shrimp")
	var second := _build_collectible_world([snail_again, shrimp], save)
	assert_bool(snail_again.is_queued_for_deletion()).override_failure_message(
		"REQ-010 AC-2: a rescued creature must not be in the world next time"
	).is_true()
	assert_bool(shrimp.is_queued_for_deletion()).is_false()
	assert_int((second[1] as WorldSystems).get_collectibles().get_collected_count()
		).is_equal(1)
	_teardown(second[0])


func test_req_010_an_undeclared_collectible_id_is_refused_and_left_in_place() -> void:
	var rogue := _pickup("golden_axolotl")
	var built := _build_collectible_world([rogue])
	assert_bool((built[1] as WorldSystems).collect_node(rogue)).is_false()
	assert_bool(rogue.is_queued_for_deletion()).is_false()
	_teardown(built[0])


func test_req_010_collect_all_finishes_the_world_on_the_last_discovery() -> void:
	# The finish kind owned by this system: the hub's callback fires exactly
	# when the declared discovery set is complete — not on a resource, and
	# not before the last creature.
	var snail := _pickup("hermit_snail")
	var shrimp := _pickup("lantern_shrimp")
	var seed := _pickup("kelp_seed")
	var built := _build_collectible_world([snail, shrimp, seed])
	var systems := built[1] as WorldSystems
	var finished: Array[bool] = []  # an Array: lambdas capture ints by value
	systems.on_finish_condition = func() -> void: finished.append(true)

	systems.collect_node(seed)
	systems.collect_node(snail)
	assert_array(finished).is_empty()
	systems.collect_node(shrimp)
	assert_int(finished.size()).override_failure_message(
		"REQ-010: collect_all must complete the world on the final discovery"
	).is_equal(1)
	_teardown(built[0])


func test_req_010_a_world_without_collectibles_wires_an_inert_system() -> void:
	var built := _build_world(REGION_MANIFEST, [])
	var systems := built[1] as WorldSystems
	assert_bool(systems.get_collectibles().is_engaged()).is_false()
	assert_bool(systems.get_collectibles().all_collected()).is_false()
	_teardown(built[0])


# --- REQ-002 / REQ-003: pillar one bound to the scene and the real player ---

## A player body in the tree, the way the hub ships one: beside the world,
## never inside it. A bare CharacterBody3D is enough for position tests.
func _player_body() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.add_to_group("player")
	_root().add_child(body)
	return body


func _volume(group: String, metas: Dictionary = {}) -> Area3D:
	var area := Area3D.new()
	area.add_to_group(group)
	for key: String in metas:
		area.set_meta(key, metas[key])
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	area.add_child(shape)
	return area


func _marker(group: String, name: String, at: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = name
	marker.add_to_group(group)
	marker.position = at
	return marker


func _build_pillar_world(nodes: Array[Node3D], save: SaveSystem = null,
		world_id: String = "reef_world") -> Array:
	var world := Node3D.new()
	for node in nodes:
		world.add_child(node)
	_root().add_child(world)
	var systems := WorldSystems.new()
	systems.manifest = REGION_MANIFEST
	systems.world_id = world_id
	systems.save_system = save
	if save != null:
		save.open_world(world_id, REGION_MANIFEST)
	world.add_child(systems)
	systems.wire()
	return [world, systems]


func test_req_003_a_marker_checkpoint_gets_a_trigger_and_activation_records_the_anchor() -> void:
	var save := SaveSystem.new()
	var spawn := _marker("spawn_point", "Spawn", Vector3(0, 1, 2))
	var reef := _marker("checkpoint", "CheckpointReef", Vector3(0, 1, -20))
	var built := _build_pillar_world([spawn, reef], save)
	var systems := built[1] as WorldSystems

	# A bare marker is not a volume; the runtime gave it one so the player can
	# actually touch it. An Area3D checkpoint would be its own trigger.
	assert_bool(reef.get_node_or_null("Trigger") is Area3D).override_failure_message(
		"REQ-003: a Marker3D checkpoint must receive a generated trigger").is_true()
	assert_array(Array(systems.get_lives().get_checkpoint_graph().get_checkpoint_ids())
		).is_equal(["CheckpointReef"])
	# Before any activation the anchor is the spawn point, never a stale one.
	assert_bool(systems.get_lives().get_respawn_position().is_equal_approx(
		Vector3(0, 1, 2))).is_true()

	assert_bool(systems.activate_checkpoint_node(reef)).is_true()
	assert_str(systems.get_lives().get_active_checkpoint()).is_equal("CheckpointReef")
	assert_bool(systems.get_lives().get_respawn_position().is_equal_approx(
		Vector3(0, 1, -20))).is_true()
	# AC-5: the activation persisted through the real Save Integration Interface.
	assert_str(String(save.get_world_data("reef_world").get("lastCheckpointId", ""))
		).is_equal("CheckpointReef")
	_teardown(built[0])


func test_req_003_a_pit_costs_a_life_and_returns_the_player_to_the_checkpoint() -> void:
	var player := _player_body()
	var reef := _marker("checkpoint", "CheckpointReef", Vector3(0, 1, -20))
	var pit := _volume("pit_volume")
	var built := _build_pillar_world([reef, pit])
	var systems := built[1] as WorldSystems
	var lost: Array[int] = []
	systems.life_lost.connect(
		func(remaining: int, _source: CatastrophicSource.Kind) -> void:
			lost.append(remaining))
	var per_attempt := systems.get_lives().get_lives_per_attempt()

	systems.activate_checkpoint_node(reef)
	player.position = Vector3(5, -30, -40)  # fell off the route
	systems._on_catastrophe_touched(pit)

	assert_array(lost).override_failure_message(
		"REQ-003 AC-1: a pit volume must cost exactly one life").is_equal(
		[per_attempt - 1] as Array[int])
	assert_bool(player.position.is_equal_approx(Vector3(0, 1, -20))
		).override_failure_message(
			"REQ-003: every spent life returns the player to the last anchor").is_true()

	# The respawn lands inside the checkpoint's own trigger. Re-touching the
	# ACTIVE checkpoint must not refill the life the pit just cost, or the
	# stakes layer is free.
	assert_bool(systems.activate_checkpoint_node(reef)).is_false()
	assert_int(systems.get_lives().get_lives()).override_failure_message(
		"REQ-003: re-touching the active checkpoint after a respawn must not refill"
	).is_equal(per_attempt - 1)

	_teardown(built[0])
	_root().remove_child(player)
	player.free()


func test_req_003_zero_lives_refills_and_respawns_at_the_checkpoint_never_the_start() -> void:
	var player := _player_body()
	var spawn := _marker("spawn_point", "Spawn", Vector3(0, 1, 2))
	var reef := _marker("checkpoint", "CheckpointReef", Vector3(0, 1, -20))
	var pit := _volume("pit_volume")
	var built := _build_pillar_world([spawn, reef, pit])
	var systems := built[1] as WorldSystems
	var anchors: Array[String] = []
	systems.returned_to_anchor.connect(
		func(_p: Vector3, checkpoint_id: String) -> void: anchors.append(checkpoint_id))
	var per_attempt := systems.get_lives().get_lives_per_attempt()

	systems.activate_checkpoint_node(reef)
	for _fall: int in range(per_attempt):
		player.position = Vector3(0, -30, -40)
		systems._on_catastrophe_touched(pit)

	assert_int(systems.get_lives().get_lives()).override_failure_message(
		"REQ-003 AC-3: reaching zero refills the count").is_equal(per_attempt)
	assert_int(anchors.size()).is_equal(per_attempt)
	for anchor: String in anchors:
		assert_str(anchor).is_equal("CheckpointReef")
	assert_bool(player.position.is_equal_approx(Vector3(0, 1, -20))
		).override_failure_message(
			"REQ-003 AC-4: the setback lands on the checkpoint, not the world start"
		).is_true()

	_teardown(built[0])
	_root().remove_child(player)
	player.free()


func test_req_003_an_ordinary_hazard_strips_a_capability_and_never_costs_a_life() -> void:
	var player := _player_body()
	var hook := _volume("hazard", {"capability": "leg", "hazard_id": "stray_hook"})
	var built := _build_pillar_world([hook])
	var systems := built[1] as WorldSystems
	var lost_lives: Array[int] = []
	systems.life_lost.connect(
		func(remaining: int, _s: CatastrophicSource.Kind) -> void:
			lost_lives.append(remaining))
	var start := systems.get_lives().get_lives()

	assert_bool(systems.apply_hazard_node(hook)).is_true()
	assert_bool(systems.get_regen().is_lost(Capability.Kind.LEG)).override_failure_message(
		"REQ-002 AC-1: a hazard strips the capability it names").is_true()
	assert_bool(systems.get_regen().is_lost(Capability.Kind.TAIL)).is_false()
	# A second touch of the same spot does not re-pop the same leg.
	assert_bool(systems.apply_hazard_node(hook)).is_false()

	assert_int(systems.get_lives().get_lives()).override_failure_message(
		"REQ-003 AC-2: ordinary hazard contact never decrements lives").is_equal(start)
	assert_array(lost_lives).is_empty()
	# And a hazard cannot smuggle a catastrophe through its lane: the
	# catastrophe lane refuses anything outside the closed set.
	assert_bool(systems.report_catastrophe("stray_hook")).is_false()
	assert_int(systems.get_lives().get_lives()).is_equal(start)

	_teardown(built[0])
	_root().remove_child(player)
	player.free()


func test_req_002_a_regen_station_and_a_checkpoint_both_regrow_everything() -> void:
	var hook := _volume("hazard", {"capability": "tail"})
	var gill_snag := _volume("hazard", {"capability": "gill"})
	var station := _volume("regen_station")
	var reef := _marker("checkpoint", "CheckpointReef", Vector3(0, 1, -20))
	var built := _build_pillar_world([hook, gill_snag, station, reef])
	var systems := built[1] as WorldSystems
	var cues: Array[String] = []
	systems.feedback_requested.connect(
		func(cue: FeedbackCue) -> void: cues.append(cue.visual_id))

	systems.apply_hazard_node(hook)
	systems.apply_hazard_node(gill_snag)
	assert_int(systems.get_regen().count_lost()).is_equal(2)
	systems._on_station_touched(station)
	assert_bool(systems.get_regen().is_fully_intact()).override_failure_message(
		"REQ-002 AC-4: a regen station restores every lost capability").is_true()

	systems.apply_hazard_node(hook)
	systems.activate_checkpoint_node(reef)
	assert_bool(systems.get_regen().is_fully_intact()).override_failure_message(
		"REQ-002 AC-6 / REQ-003 AC-5: a checkpoint restores capability state").is_true()

	# Every loss and regrowth asked for its feedback, both channels declared.
	assert_array(cues).is_equal(["vfx.pop_sparkle_tail", "vfx.pop_sparkle_gill",
		"vfx.bloom_regrow_tail", "vfx.bloom_regrow_gill",
		"vfx.pop_sparkle_tail", "vfx.bloom_regrow_tail"] as Array[String])
	_teardown(built[0])


func test_req_002_a_lost_tail_slows_the_real_controller_through_the_modifier_interface() -> void:
	# The integration the unit suite cannot prove: the world's regeneration
	# state reaches the PLAYER'S controller, which is what makes a lost tail
	# a slower swim in the running game rather than a flag in a test.
	var body := AxolotlBody.new()
	body.add_to_group("player")
	_root().add_child(body)
	body._ready()  # the runner adds nodes before the tree iterates
	assert_object(body.get_controller()).is_not_null()
	var modifiers := body.get_controller().get_capability_modifiers()

	var hook := _volume("hazard", {"capability": "tail"})
	var built := _build_pillar_world([hook])
	var systems := built[1] as WorldSystems
	var tuning := systems.get_tuning()

	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
		).is_equal_approx(1.0, 0.0001)
	systems.apply_hazard_node(hook)
	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
		).override_failure_message(
			"REQ-002 AC-2: a lost tail must reach the controller as a swim-speed factor"
		).is_equal_approx(tuning.get_number(Capability.TAIL_MODIFIER_KEY), 0.0001)
	assert_float(modifiers.combined(CapabilityModifiers.Target.CLIMB_HEIGHT)
		).is_equal_approx(1.0, 0.0001)

	# Leaving the world takes its factors with it: the hub is not a slower
	# place. At runtime _exit_tree and the hub both call this; the runner never
	# puts nodes in the tree, so the seam is driven directly here.
	systems.release_player_factors()
	_teardown(built[0])
	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
		).override_failure_message(
			"a world's capability factors must not follow the player into the hub"
		).is_equal_approx(1.0, 0.0001)
	_root().remove_child(body)
	body.free()


func test_req_014_restoration_reload_opens_real_gate_and_preserves_resources() -> void:
	var save := SaveSystem.new()
	save.open_world("save_probe", REGION_MANIFEST)
	var path := create_temp_dir("world_save").path_join("profile.json")
	var world := Node3D.new()
	_root().add_child(world)
	var systems := WorldSystems.new()
	systems.world_id = "save_probe"
	systems.manifest = REGION_MANIFEST
	systems.save_system = save
	world.add_child(systems)
	systems.wire()
	systems.get_restoration().deliver_resources("reef", 9)
	systems.get_mods().equip("jet")
	systems.persist_progress()
	assert_bool(save.save_to_file(path)).is_true()
	_teardown(world)

	var reloaded := SaveSystem.new()
	assert_bool(reloaded.load_from_file(path)).is_true()
	assert_array(reloaded.get_unlocked_gill_mods()).contains(["jet"])
	var wall := _barrier("restoration_gate",
		{"region_id": "reef", "gate_id": "reef_wall"})
	var second_world := Node3D.new()
	second_world.add_child(wall)
	_root().add_child(second_world)
	var second := WorldSystems.new()
	second.world_id = "save_probe"
	second.manifest = REGION_MANIFEST
	second.save_system = reloaded
	second_world.add_child(second)
	second.wire()
	assert_bool(second.get_restoration().get_region("reef").is_restored()).is_true()
	assert_int(second.get_restoration().get_region("reef").get_resources()).is_equal(2)
	assert_bool(wall.visible).is_false()
	_teardown(second_world)
