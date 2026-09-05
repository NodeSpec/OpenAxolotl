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
