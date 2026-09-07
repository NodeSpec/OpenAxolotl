extends GdUnitTestSuite

## Drift Fleet Enemy Framework — REQ-012.
##
## Every enemy is proven against the REAL core system it was designed
## against — the capability modifiers Netbots write, the Gill Mod slot
## Hooklines take, the restoration and life systems Dredgers strike, the
## factors Runoff Drones publish — never against a mock of it.

const TUNING_PATH := "res://core/tuning/tuning.json"

const ROSTER: PackedStringArray = [
	"dredger", "hookline_rig", "netbot", "runoff_drone",
]

## Every file that IS the enemy system core. AC-5 says a fixture enemy can be
## added without modifying any of these, so the list is named here and hashed
## across a registration.
const CORE_SOURCES: PackedStringArray = [
	"res://core/enemies/enemy_error.gd",
	"res://core/enemies/enemy_def.gd",
	"res://core/enemies/enemy_registry.gd",
	"res://core/enemies/drift_fleet_system.gd",
]

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("enemies")


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


## The four shipped enemies, discovered from the roster directory exactly as
## a fixture enemy would be.
func _registry(tuning: TuningData) -> EnemyRegistry:
	var registry := EnemyRegistry.new(tuning)
	var errors: Array[EnemyError] = []
	var loaded := registry.load_directory(EnemyRegistry.ROSTER_DIRECTORY, errors)
	assert_array(errors).is_empty()
	assert_int(loaded).is_equal(4)
	return registry


func _mods(tuning: TuningData) -> GillModSystem:
	var registry := GillModRegistry.new(tuning)
	var errors: Array[GillModError] = []
	registry.load_directory(GillModRegistry.MODS_DIRECTORY, errors)
	assert_array(errors).is_empty()
	return GillModSystem.new(tuning, registry)


func _fleet(tuning: TuningData) -> DriftFleetSystem:
	return DriftFleetSystem.new(tuning, _registry(tuning))


func _region_manifest() -> Dictionary:
	return {"restorableRegions": [{"regionId": "reef", "traversalGates": [
		{"gateId": "reef_gate", "opensAt": "restored"}]}]}


func _restored_restoration(tuning: TuningData) -> RestorationSystem:
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	assert_bool(restoration.declare_from_manifest(
		_region_manifest(), errors)).is_true()
	assert_bool(restoration.unlock_region("reef")).is_true()
	restoration.deliver_resources("reef",
		tuning.get_count("restoration.resourced.resource_cost")
		+ tuning.get_count("restoration.restored.resource_cost"))
	assert_int(int(restoration.get_state("reef"))).is_equal(
		int(RegionState.State.RESTORED))
	return restoration


# --- The roster --------------------------------------------------------------

func test_req_012_the_four_drift_fleet_enemies_are_registered() -> void:
	var registry := _registry(_tuning())
	for enemy_id: String in ROSTER:
		assert_bool(registry.has(enemy_id)).override_failure_message(
			"REQ-012: '%s' is not registered" % enemy_id).is_true()
	assert_int(registry.size()).is_equal(4)


# --- AC-1: Netbots entangle; Jet Gills counter -------------------------------

func test_req_012_netbot_entangles_and_strips_swim_speed() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var modifiers := CapabilityModifiers.new()
	fleet.set_capability_modifiers(modifiers)

	assert_bool(fleet.contact("netbot")).is_true()
	assert_bool(fleet.is_entangled()).is_true()
	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(
		tuning.get_number("enemy.netbot.swim_speed_multiplier"), 0.0001)
	# Targeted: the net drags the swimmer, it does not slow waddling.
	assert_float(modifiers.combined(CapabilityModifiers.Target.WADDLE_SPEED)
	).is_equal_approx(1.0, 0.0001)

	# A net cannot extend its own window by re-touching.
	assert_bool(fleet.contact("netbot")).is_false()

	# The entanglement expires after the tuned window, factor and all.
	fleet.tick(tuning.get_number("enemy.netbot.entangle_seconds") + 0.01)
	assert_bool(fleet.is_entangled()).is_false()
	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(1.0, 0.0001)


func test_req_012_active_jet_refuses_the_entanglement() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var mods := _mods(tuning)
	fleet.set_gill_mods(mods)
	fleet.set_capability_modifiers(CapabilityModifiers.new())

	assert_bool(mods.equip("jet")).is_true()
	assert_bool(mods.activate()).is_true()
	assert_bool(mods.has_affordance("net_escape")).is_true()

	assert_bool(fleet.contact("netbot")).is_false()
	assert_bool(fleet.is_entangled()).is_false()


func test_req_012_activating_jet_mid_net_releases_early() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var mods := _mods(tuning)
	fleet.set_gill_mods(mods)
	var modifiers := CapabilityModifiers.new()
	fleet.set_capability_modifiers(modifiers)

	assert_bool(mods.equip("jet")).is_true()
	assert_bool(fleet.contact("netbot")).is_true()

	var escaped: Array[String] = []
	fleet.entangle_escaped.connect(func(enemy_id: String) -> void:
		escaped.append(enemy_id))

	# One second in — far short of the tuned window — the player fires the
	# Jet. The very next frame frees them.
	fleet.tick(1.0)
	assert_bool(fleet.is_entangled()).is_true()
	assert_bool(mods.activate()).is_true()
	fleet.tick(0.01)

	assert_bool(fleet.is_entangled()).is_false()
	assert_array(escaped).contains(["netbot"])
	assert_float(modifiers.combined(CapabilityModifiers.Target.SWIM_SPEED)
	).is_equal_approx(1.0, 0.0001)


# --- AC-2: Hookline Rigs snag; Glow Gills reveal -----------------------------

func test_req_012_hookline_snags_the_mod_for_the_tuned_window() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var mods := _mods(tuning)
	fleet.set_gill_mods(mods)

	assert_bool(mods.equip("bubble")).is_true()
	assert_bool(fleet.contact("hookline_rig")).is_true()

	assert_bool(mods.is_stripped()).is_true()
	assert_bool(mods.has_equipped()).is_false()
	assert_float(mods.get_strip_remaining()).is_equal_approx(
		tuning.get_number("enemy.hookline.mod_strip_seconds"), 0.0001)

	# The window elapses and the mod comes back on its own.
	mods.tick(tuning.get_number("enemy.hookline.mod_strip_seconds") + 0.01)
	assert_bool(mods.is_stripped()).is_false()
	assert_str(mods.get_equipped_id()).is_equal("bubble")

	# Nothing equipped means nothing to take.
	mods.unequip()
	assert_bool(fleet.contact("hookline_rig")).is_false()


func test_req_012_glow_reveals_the_line_before_it_triggers() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var mods := _mods(tuning)
	fleet.set_gill_mods(mods)

	# No Glow: the line is hidden.
	assert_bool(fleet.is_line_revealed("hookline_rig")).is_false()

	# Glow ACTIVE: revealed — before any snag has happened, which is the
	# point: the player sees the line and routes around it.
	assert_bool(mods.equip("glow")).is_true()
	assert_bool(mods.activate()).is_true()
	assert_bool(fleet.is_line_revealed("hookline_rig")).is_true()

	var changes: Array = []
	fleet.line_reveal_changed.connect(
		func(enemy_id: String, revealed: bool) -> void:
			changes.append([enemy_id, revealed]))
	fleet.tick(0.01)
	assert_array(changes).contains([["hookline_rig", true]])

	# Revealing does NOT disarm: contact while revealed still snags.
	assert_bool(fleet.contact("hookline_rig")).is_true()
	assert_bool(mods.is_stripped()).is_true()

	# The reveal window closes with the affordance.
	mods.tick(tuning.get_number("enemy.hookline.mod_strip_seconds") + 0.01)
	mods.tick(tuning.get_number("gillmod.glow.duration_s") + 0.01)
	assert_bool(fleet.is_line_revealed("hookline_rig")).is_false()


# --- AC-3: Dredgers revert regions and their wipe costs a life ---------------

func test_req_012_dredger_reverts_a_restored_region_to_barren() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var restoration := _restored_restoration(tuning)
	fleet.set_restoration(restoration)

	var closed: Array = []
	restoration.region_traversal_changed.connect(
		func(region_id: String, gate_id: String, open: bool) -> void:
			closed.append([region_id, gate_id, open]))

	assert_bool(fleet.strike_region("dredger", "reef")).is_true()
	assert_int(int(restoration.get_state("reef"))).is_equal(
		int(RegionState.State.BARREN))
	# Real traversal closed, not just visuals.
	assert_array(closed).contains([["reef", "reef_gate", false]])
	# The unlock survives (REQ-008 AC-6): restoration can be redone.
	assert_bool(restoration.is_unlocked("reef")).is_true()


func test_req_012_dredger_area_wipe_decrements_a_life() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var lives := LifeSystem.new(tuning)
	fleet.set_life_system(lives)

	var before := lives.get_lives()
	assert_bool(fleet.area_wipe("dredger")).is_true()
	assert_int(lives.get_lives()).is_equal(before - 1)


func test_req_012_no_other_enemy_can_reach_the_life_system() -> void:
	# The closed catastrophic set, exercised from the enemy side: only the
	# dredge behavior HAS an area-wipe lane, and the framework refuses the
	# call for every other enemy before the life system is even asked.
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var lives := LifeSystem.new(tuning)
	fleet.set_life_system(lives)

	var before := lives.get_lives()
	for enemy_id: String in ["netbot", "hookline_rig", "runoff_drone"]:
		assert_bool(fleet.area_wipe(enemy_id)).override_failure_message(
			"REQ-012/REQ-003: '%s' reached the life system" % enemy_id
		).is_false()
	assert_int(lives.get_lives()).is_equal(before)


# --- AC-4: the Runoff Drone toxin aura ---------------------------------------

func test_req_012_runoff_aura_applies_tuned_debuffs_and_lingers() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)

	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)
	assert_float(fleet.gill_recharge_scale()).is_equal_approx(1.0, 0.0001)

	assert_bool(fleet.enter_aura("runoff_drone")).is_true()
	assert_float(fleet.vision_factor()).is_equal_approx(
		tuning.get_number("enemy.runoff.vision_debuff_factor"), 0.0001)
	assert_float(fleet.gill_recharge_scale()).is_equal_approx(
		tuning.get_number("enemy.runoff.gill_recharge_multiplier"), 0.0001)

	# Inside, time does not clear it — the volume does.
	fleet.tick(60.0)
	assert_bool(fleet.has_active_aura()).is_true()

	# Leaving starts the tuned linger; the debuff holds, then clears.
	assert_bool(fleet.exit_aura("runoff_drone")).is_true()
	var duration := tuning.get_number("enemy.runoff.duration_s")
	fleet.tick(duration * 0.5)
	assert_bool(fleet.has_active_aura()).is_true()
	fleet.tick(duration * 0.5 + 0.01)
	assert_bool(fleet.has_active_aura()).is_false()
	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)


func test_req_012_runoff_aura_slows_only_the_recharge_phase() -> void:
	var tuning := _tuning()
	var fleet := _fleet(tuning)
	var mods := _mods(tuning)
	fleet.set_gill_mods(mods)

	assert_bool(mods.equip("bubble")).is_true()
	assert_bool(mods.activate()).is_true()
	assert_bool(fleet.enter_aura("runoff_drone")).is_true()

	# ACTIVE window: undebuffed — the aura debuffs recharge, not the window
	# the player already opened.
	assert_float(fleet.scaled_mod_delta(1.0)).is_equal_approx(1.0, 0.0001)
	mods.tick(tuning.get_number("gillmod.bubble.duration_s") + 0.01)
	assert_bool(mods.is_cooling()).is_true()

	# COOLING: the same second of wall time recharges at the tuned fraction,
	# driven through the mods system exactly as the game client ticks it.
	var scale := tuning.get_number("enemy.runoff.gill_recharge_multiplier")
	assert_float(fleet.scaled_mod_delta(1.0)).is_equal_approx(scale, 0.0001)

	var cooldown := tuning.get_number("gillmod.bubble.cooldown_s")
	mods.tick(fleet.scaled_mod_delta(cooldown))
	assert_bool(mods.is_cooling()).override_failure_message(
		"a full nominal cooldown of debuffed time should NOT finish the "
		+ "recharge").is_true()
	mods.tick(fleet.scaled_mod_delta(cooldown / scale))
	assert_bool(mods.is_ready()).is_true()


# --- AC-5: the extension interface -------------------------------------------

func _fixture_declaration(enemy_id: String = "fixture_crawler") -> Dictionary:
	# An enemy that does not exist in this repository, on an existing
	# behavior. Like a fixture mod it brings no balance data of its own —
	# it cites keys that exist.
	return {
		"id": enemy_id,
		"displayName": "Fixture Crawler",
		"behavior": "entangle",
		"audioCueId": "enemy_fixture_crawler",
		"entangle": {
			"factorKey": "enemy.netbot.swim_speed_multiplier",
			"durationKey": "enemy.netbot.entangle_seconds",
			"target": "waddle_speed",
			"escapeAffordance": "jet_dash",
		},
	}


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


func test_req_012_a_fixture_enemy_registers_without_touching_the_core() -> void:
	var tuning := _tuning()
	var sources_before: Array[String] = []
	for path: String in CORE_SOURCES:
		sources_before.append(_read(path))

	# The fixture arrives as a file in a directory, discovered by the same
	# sweep the shipped roster uses.
	var path := _temp_dir.path_join("fixture_crawler.json")
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(JSON.stringify(_fixture_declaration()))
	handle.close()

	var registry := EnemyRegistry.new(tuning)
	var errors: Array[EnemyError] = []
	assert_int(registry.load_directory(_temp_dir, errors)).is_equal(1)
	assert_array(errors).is_empty()
	assert_bool(registry.has("fixture_crawler")).is_true()

	# And it WORKS through the same runtime, untouched core and all.
	var fleet := DriftFleetSystem.new(tuning, registry)
	var modifiers := CapabilityModifiers.new()
	fleet.set_capability_modifiers(modifiers)
	assert_bool(fleet.contact("fixture_crawler")).is_true()
	assert_float(modifiers.combined(CapabilityModifiers.Target.WADDLE_SPEED)
	).is_equal_approx(
		tuning.get_number("enemy.netbot.swim_speed_multiplier"), 0.0001)

	for index: int in CORE_SOURCES.size():
		assert_str(_read(CORE_SOURCES[index])).override_failure_message(
			"REQ-012 AC-5: registering a fixture enemy modified core file %s"
			% CORE_SOURCES[index]).is_equal(sources_before[index])


func test_req_012_registration_refuses_bad_declarations_by_name() -> void:
	var tuning := _tuning()
	var registry := _registry(tuning)
	var errors: Array[EnemyError] = []

	var unknown_behavior := _fixture_declaration("bad_behavior")
	unknown_behavior["behavior"] = "instakill"
	assert_bool(registry.register(
		EnemyDef.from_dictionary(unknown_behavior, errors), errors)).is_false()

	var bad_key := _fixture_declaration("bad_key")
	(bad_key["entangle"] as Dictionary)["durationKey"] = "enemy.nope.seconds"
	assert_bool(registry.register(
		EnemyDef.from_dictionary(bad_key, errors), errors)).is_false()

	var duplicate := _fixture_declaration("netbot")
	assert_bool(registry.register(
		EnemyDef.from_dictionary(duplicate, errors), errors)).is_false()

	var codes: Array[String] = []
	for error: EnemyError in errors:
		codes.append(error.code)
	assert_array(codes).contains([EnemyError.UNKNOWN_BEHAVIOR,
		EnemyError.UNKNOWN_TUNING_KEY, EnemyError.DUPLICATE_ID])


func test_req_012_a_declaration_cannot_widen_the_catastrophic_set() -> void:
	var tuning := _tuning()
	var registry := EnemyRegistry.new(tuning)
	var errors: Array[EnemyError] = []

	var rogue := {
		"id": "rogue_wiper",
		"displayName": "Rogue Wiper",
		"behavior": "dredge",
		"audioCueId": "enemy_rogue",
		"dredge": {"areaWipeSource": "rogue_contact"},
	}
	assert_bool(registry.register(
		EnemyDef.from_dictionary(rogue, errors), errors)).is_false()

	var codes: Array[String] = []
	for error: EnemyError in errors:
		codes.append(error.code)
	assert_array(codes).contains([EnemyError.UNSANCTIONED_CATASTROPHE])


# --- AC-6: a world declaring no enemies stays valid and completable ----------

func test_req_012_no_installed_world_declares_enemies() -> void:
	# The completability half is proven every run by the template, coral and
	# bubble walks; this pins the declaration half: every installed world
	# omits the optional element, and the framework treats absence as a
	# well-defined no-op rather than an error.
	var dir := DirAccess.open("res://worlds")
	assert_object(dir).is_not_null()
	var modules := dir.get_directories()
	assert_int(modules.size()).is_greater_equal(3)
	for module: String in modules:
		var manifest: Variant = JSON.parse_string(
			_read("res://worlds/%s/world.json" % module))
		assert_bool(manifest is Dictionary
			and not (manifest as Dictionary).has("enemies")
		).override_failure_message(
			"world '%s' unexpectedly declares enemies" % module).is_true()

	var fleet := _fleet(_tuning())
	fleet.tick(1.0)
	assert_bool(fleet.is_entangled()).is_false()
	assert_bool(fleet.has_active_aura()).is_false()
	assert_float(fleet.vision_factor()).is_equal_approx(1.0, 0.0001)
