extends GdUnitTestSuite

## The Drift Fleet and the Flagship, reached through a WORLD (REQ-036).
##
## The enemy framework, its roster and the Flagship encounter were all built
## and tested headless, and every one of those tests passed while no world
## could reach any of it: WorldSystems had no enemy group, never built a
## DriftFleetSystem, and never read the `boss` element. These tests hold the
## join specifically — a scene node and a manifest entry reaching the real
## systems — because that is the half that was missing.

const PLAYER_GROUP := "player"

const REGION_MANIFEST := {
	"worldId": "fleet_test",
	"restorableRegions": [
		{
			"regionId": "reef",
			"traversalGates": [{"gateId": "reef_wall", "opensAt": "restored"}],
		},
	],
}

## A valid encounter: the declaration is refused without one water-only
## phase, one land-only phase and one affordance-gated phase.
const BOSS := {
	"regionId": "reef",
	"phases": [
		{"phaseId": "hull_breach", "grammar": "water"},
		{"phaseId": "deck_assault", "grammar": "land"},
		{"phaseId": "core_purge", "grammar": "any",
			"requiresAffordance": "bubble_platform"},
	],
}


func _root() -> Node:
	return Engine.get_main_loop().root


func _enemy_node(enemy_id: String, region_id: String = "") -> Area3D:
	var node := Area3D.new()
	node.name = "Enemy_" + enemy_id
	node.add_to_group("enemy")
	node.set_meta("enemy_id", enemy_id)
	if not region_id.is_empty():
		node.set_meta("region_id", region_id)
	return node


func _build(manifest: Dictionary, enemies: Array[Area3D]) -> Array:
	var world := Node3D.new()
	for enemy: Area3D in enemies:
		world.add_child(enemy)
	_root().add_child(world)
	var systems := WorldSystems.new()
	systems.manifest = manifest
	world.add_child(systems)
	# The runner adds nodes before the tree's first iteration, so _ready never
	# fires; wire() is the same entry point, idempotent by design.
	systems.wire()
	return [world, systems]


func _teardown(world: Node) -> void:
	_root().remove_child(world)
	world.free()


func test_req_036_a_world_declaring_no_enemies_still_has_a_working_fleet() -> void:
	# The contract's absent default is "no Drift Fleet units spawn", not "no
	# system": the accessor must never hand back null, or every caller and the
	# tick loop grow a special case.
	var built := _build(REGION_MANIFEST, [])
	var systems := built[1] as WorldSystems
	assert_object(systems.get_drift_fleet()).override_failure_message(
		"the fleet must exist even with nothing declared").is_not_null()
	assert_object(systems.get_flagship()).override_failure_message(
		"a world with no boss element has no encounter").is_null()
	_teardown(built[0])


func test_req_036_the_roster_is_loaded_so_a_world_can_name_a_unit() -> void:
	var built := _build(REGION_MANIFEST, [])
	var registry := (built[1] as WorldSystems).get_drift_fleet().get_registry()
	for enemy_id: String in ["netbot", "hookline_rig", "dredger",
			"runoff_drone"]:
		assert_bool(registry.has(enemy_id)).override_failure_message(
			"the shipped roster must carry %s" % enemy_id).is_true()
	_teardown(built[0])


func test_req_036_contact_with_a_declared_netbot_entangles_the_player() -> void:
	# The entangle lane writes a timed factor through the Capability Modifier
	# Interface. Driven through the runtime's own seam rather than by calling
	# DriftFleetSystem directly, because the seam is what was missing.
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["enemies"] = [{"enemyId": "netbot"}]
	var netbot := _enemy_node("netbot")
	var built := _build(manifest, [netbot] as Array[Area3D])
	var systems := built[1] as WorldSystems

	var fleet := systems.get_drift_fleet()
	assert_bool(fleet.is_entangled()).is_false()
	systems._on_enemy_contact(netbot)
	assert_bool(fleet.is_entangled()).override_failure_message(
		"touching a netbot must entangle; the scene node reached no lane"
		).is_true()
	_teardown(built[0])


func test_req_036_an_undeclared_enemy_node_is_inert() -> void:
	# Placing a node is not a declaration. A world that drops a netbot into
	# the scene without declaring it must not get a working netbot, the same
	# rule a collectible pickup naming an undeclared id follows.
	var netbot := _enemy_node("netbot")
	var built := _build(REGION_MANIFEST, [netbot] as Array[Area3D])
	var systems := built[1] as WorldSystems

	systems._on_enemy_contact(netbot)
	assert_bool(systems.get_drift_fleet().is_entangled()
		).override_failure_message(
		"an undeclared unit must stay inert").is_false()
	_teardown(built[0])


func test_req_036_a_dredger_reverts_the_region_its_node_names() -> void:
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["enemies"] = [{"enemyId": "dredger"}]
	var dredger := _enemy_node("dredger", "reef")
	var built := _build(manifest, [dredger] as Array[Area3D])
	var systems := built[1] as WorldSystems
	var restoration := systems.get_restoration()
	# Asserted explicitly: an invalid region declaration is only a warning, so
	# without this every state assertion below would pass trivially against a
	# region that does not exist. That is how the first draft of this suite
	# went green while proving nothing.
	assert_bool(restoration.has_region("reef")).override_failure_message(
		"the test manifest must declare a real region").is_true()

	# Drive the region up to restored first: a dredger reverting an already
	# barren region proves nothing. Delivered in bulk rather than counted out,
	# so the test does not restate the tuned per-stage costs.
	restoration.unlock_region("reef")
	restoration.deliver_resources("reef", 64)
	assert_int(int(restoration.get_state("reef"))
		).override_failure_message("the region must reach restored first"
		).is_equal(int(RegionState.State.RESTORED))

	systems._on_dredger_touched(dredger)
	assert_int(int(restoration.get_state("reef"))
		).override_failure_message(
		"a dredger strike must flatten the region back to barren"
		).is_equal(int(RegionState.State.BARREN))
	# REQ-008 AC-6: the unlock survives, so restoration can be redone without
	# refighting the Flagship.
	assert_bool(restoration.is_unlocked("reef")).override_failure_message(
		"a dredger must not re-lock the region").is_true()
	_teardown(built[0])


func test_req_036_a_declared_boss_builds_an_encounter_and_gates_the_region() -> void:
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["boss"] = BOSS
	var built := _build(manifest, [])
	var systems := built[1] as WorldSystems

	var flagship := systems.get_flagship()
	assert_object(flagship).override_failure_message(
		"a valid boss declaration must build an encounter").is_not_null()
	assert_int(flagship.phase_count()).is_equal(3)
	assert_bool(systems.get_restoration().has_region("reef")
		).override_failure_message(
		"locked must mean a real region is locked, not that none exists"
		).is_true()
	assert_bool(systems.get_restoration().is_unlocked("reef")
		).override_failure_message(
		"the Flagship is the gate: its region starts locked").is_false()
	_teardown(built[0])


func test_req_036_boss_phase_volumes_drive_the_encounter_to_defeat() -> void:
	# The encounter's phase logic was complete and reachable only from a test.
	# This is the seam that makes it drivable from a SCENE, so it is proven
	# the same way a player would clear it: by arriving at each phase volume.
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["boss"] = BOSS
	var built := _build(manifest, [])
	var systems := built[1] as WorldSystems
	var flagship := systems.get_flagship()

	# A player is needed: the grammar is read off the controller at contact.
	var player := (load("res://core/controller/axolotl_body.tscn")
		as PackedScene).instantiate() as AxolotlBody
	player.add_to_group(PLAYER_GROUP)
	(built[0] as Node).add_child(player)
	# The runner adds nodes before the tree's first iteration, so _ready never
	# fires; initialise() is the same entry point, idempotent by design.
	player.initialise()

	var volume := Area3D.new()
	volume.add_to_group("boss_phase")

	# The grammar is driven the way the game drives it — a physics step told
	# whether the body is in water — rather than through a setter added for
	# the test. A test-only door into the controller would prove the door
	# works, not the game.
	var controller: AxolotlController = player.get_controller()
	var intent := PlayerIntent.new(
		Vector3.ZERO, [] as Array[MovementGrammar.Verb])

	# Phase one is water-only. On land it must refuse, which is the gate
	# doing its job rather than a failure.
	controller.physics_step(1.0 / 60.0, false, intent)
	assert_int(int(controller.get_grammar())
		).is_equal(int(MovementGrammar.Grammar.LAND))
	systems._on_boss_phase_touched(volume)
	assert_int(flagship.get_current_phase_index()).override_failure_message(
		"a water phase must not clear on land").is_equal(0)

	controller.physics_step(1.0 / 60.0, true, intent)
	assert_int(int(controller.get_grammar())
		).is_equal(int(MovementGrammar.Grammar.WATER))
	systems._on_boss_phase_touched(volume)
	assert_int(flagship.get_current_phase_index()).override_failure_message(
		"arriving in water must clear the water phase").is_equal(1)

	volume.free()
	_teardown(built[0])


func test_req_036_a_refused_boss_declaration_leaves_the_region_locked() -> void:
	# A boss that failed to build has not been beaten. Opening the region
	# because the declaration was malformed would hand the player the payoff
	# for free, which is the failure worth catching.
	var manifest := REGION_MANIFEST.duplicate(true)
	manifest["boss"] = {"regionId": "reef", "phases": []}
	var built := _build(manifest, [])
	var systems := built[1] as WorldSystems

	assert_object(systems.get_flagship()).is_null()
	assert_bool(systems.get_restoration().has_region("reef")).is_true()
	assert_bool(systems.get_restoration().is_unlocked("reef")
		).override_failure_message(
		"a refused declaration must not open the region").is_false()
	_teardown(built[0])
