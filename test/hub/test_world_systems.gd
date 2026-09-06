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
