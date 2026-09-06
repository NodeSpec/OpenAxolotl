extends GdUnitTestSuite

## Flagship Boss Encounter — REQ-013.
##
## The encounter is proven against the REAL systems it escalates through:
## the regen system its ordinary attacks strip, the life system its
## finishers spend and its checkpoints resume through, the restoration
## system its defeat unlocks, and the Gill Mod system its gated phase reads.

const TUNING_PATH := "res://core/tuning/tuning.json"


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


func _mods(tuning: TuningData) -> GillModSystem:
	var registry := GillModRegistry.new(tuning)
	var errors: Array[GillModError] = []
	registry.load_directory(GillModRegistry.MODS_DIRECTORY, errors)
	assert_array(errors).is_empty()
	return GillModSystem.new(tuning, registry)


## The declaration the docstring publishes as the boss element's de-facto
## shape: a water phase, a land phase, and a Bubble-gated free phase.
func _declaration() -> Dictionary:
	return {
		"regionId": "reef",
		"phases": [
			{"phaseId": "hull_breach", "grammar": "water"},
			{"phaseId": "deck_assault", "grammar": "land"},
			{"phaseId": "core_purge", "grammar": "any",
				"requiresAffordance": "bubble_platform"},
		],
	}


func _encounter() -> FlagshipEncounter:
	var errors: Array[FlagshipError] = []
	var encounter := FlagshipEncounter.from_declaration(_declaration(), errors)
	assert_array(errors).is_empty()
	assert_object(encounter).is_not_null()
	return encounter


func _restoration_with_reef(tuning: TuningData) -> RestorationSystem:
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	assert_bool(restoration.declare_from_manifest(
		{"restorableRegions": [{"regionId": "reef", "traversalGates": [
			{"gateId": "reef_gate", "opensAt": "restored"}]}]},
		errors)).is_true()
	return restoration


## Beats the declared encounter: water, land, then Bubble-gated.
func _win(encounter: FlagshipEncounter, mods: GillModSystem) -> void:
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.LAND)).is_true()
	assert_bool(mods.equip("bubble")).is_true()
	assert_bool(mods.activate()).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()


# --- Validation: AC-3/AC-4 are refused at the door ---------------------------

func test_req_013_a_conforming_declaration_is_accepted() -> void:
	var encounter := _encounter()
	assert_int(encounter.phase_count()).is_equal(3)
	assert_str(encounter.region_id).is_equal("reef")
	assert_str(encounter.get_current_phase_id()).is_equal("hull_breach")


func test_req_013_a_declaration_missing_a_required_shape_is_refused() -> void:
	var cases := {
		FlagshipError.NO_WATER_PHASE: [
			{"phaseId": "a", "grammar": "land"},
			{"phaseId": "b", "grammar": "any",
				"requiresAffordance": "jet_dash"}],
		FlagshipError.NO_LAND_PHASE: [
			{"phaseId": "a", "grammar": "water"},
			{"phaseId": "b", "grammar": "any",
				"requiresAffordance": "jet_dash"}],
		FlagshipError.NO_MOD_GATED_PHASE: [
			{"phaseId": "a", "grammar": "water"},
			{"phaseId": "b", "grammar": "land"}],
		FlagshipError.DUPLICATE_PHASE: [
			{"phaseId": "a", "grammar": "water"},
			{"phaseId": "a", "grammar": "land",
				"requiresAffordance": "jet_dash"}],
		FlagshipError.UNKNOWN_GRAMMAR: [
			{"phaseId": "a", "grammar": "amphibious"}],
	}
	for expected_code: String in cases:
		var errors: Array[FlagshipError] = []
		var refused := FlagshipEncounter.from_declaration(
			{"regionId": "reef", "phases": cases[expected_code]}, errors)
		assert_object(refused).override_failure_message(
			"a declaration violating %s was accepted" % expected_code
		).is_null()
		var codes: Array[String] = []
		for error: FlagshipError in errors:
			codes.append(error.code)
		assert_array(codes).contains([expected_code])


func test_req_013_a_declaration_without_a_region_is_refused() -> void:
	var errors: Array[FlagshipError] = []
	assert_object(FlagshipEncounter.from_declaration(
		{"phases": [{"phaseId": "a", "grammar": "water"}]}, errors)).is_null()


# --- AC-1: ordinary attacks strip capability; finishers cost a life ----------

func test_req_013_ordinary_attacks_strip_capability_never_lives() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var regen := RegenSystem.new(tuning)
	var lives := LifeSystem.new(tuning)
	encounter.set_regen(regen)
	encounter.set_life_system(lives)

	var lives_before := lives.get_lives()
	assert_bool(encounter.ordinary_attack(Capability.Kind.TAIL)).is_true()
	assert_bool(regen.is_lost(Capability.Kind.TAIL)).is_true()
	# The same spot cannot be re-stripped.
	assert_bool(encounter.ordinary_attack(Capability.Kind.TAIL)).is_false()
	assert_bool(encounter.ordinary_attack(Capability.Kind.GILL)).is_true()
	# Two layers, never blurred: ordinary attacks touched no life.
	assert_int(lives.get_lives()).is_equal(lives_before)


func test_req_013_the_finisher_decrements_a_life() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var lives := LifeSystem.new(tuning)
	encounter.set_life_system(lives)

	var before := lives.get_lives()
	assert_bool(encounter.finisher()).is_true()
	assert_int(lives.get_lives()).is_equal(before - 1)


# --- AC-3: grammar-locked phases ---------------------------------------------

func test_req_013_grammar_locked_phases_refuse_the_wrong_grammar() -> void:
	var encounter := _encounter()

	# hull_breach is water-only: the land grammar bounces off it.
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.LAND)).is_false()
	assert_str(encounter.get_current_phase_id()).is_equal("hull_breach")
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()

	# deck_assault is land-only: the water grammar bounces off it.
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_false()
	assert_str(encounter.get_current_phase_id()).is_equal("deck_assault")
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.LAND)).is_true()


# --- AC-4: the mod-gated phase -----------------------------------------------

func test_req_013_the_mod_gated_phase_requires_the_active_window() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var mods := _mods(tuning)
	encounter.set_gill_mods(mods)

	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.LAND)).is_true()

	# core_purge requires bubble_platform: refused bare, refused with the
	# mod merely EQUIPPED (affordances are active windows), refused with
	# the WRONG mod active — completed only inside Bubble's window.
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_false()
	assert_bool(mods.equip("jet")).is_true()
	assert_bool(mods.activate()).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_false()
	mods.tick(tuning.get_number("gillmod.jet.duration_s")
		+ tuning.get_number("gillmod.jet.cooldown_s") + 0.01)
	assert_bool(mods.equip("bubble")).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_false()
	assert_bool(mods.activate()).is_true()
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()
	assert_bool(encounter.is_defeated()).is_true()


# --- AC-2: defeat unlocks the region -----------------------------------------

func test_req_013_defeat_flips_the_unlocked_flag_and_restoration_begins() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var mods := _mods(tuning)
	var restoration := _restoration_with_reef(tuning)
	encounter.set_gill_mods(mods)
	encounter.set_restoration(restoration)

	# Before the defeat the region is locked: resources advance NOTHING
	# (REQ-008 AC-2), which is exactly what makes the boss the gate.
	restoration.deliver_resources("reef", 99)
	assert_int(int(restoration.get_state("reef"))).is_equal(
		int(RegionState.State.BARREN))
	assert_bool(restoration.is_unlocked("reef")).is_false()

	var defeated: Array[String] = []
	encounter.encounter_defeated.connect(func(region_id: String) -> void:
		defeated.append(region_id))
	_win(encounter, mods)

	assert_array(defeated).contains(["reef"])
	assert_bool(restoration.is_unlocked("reef")).is_true()
	# Restoration BEGINS: the defeat grants no state by itself, but the
	# resources banked while the region was locked now count — the next
	# delivery advances all the way on what was already gathered.
	assert_int(int(restoration.get_state("reef"))).is_equal(
		int(RegionState.State.BARREN))
	restoration.deliver_resources("reef", 1)
	assert_int(int(restoration.get_state("reef"))).is_equal(
		int(RegionState.State.RESTORED))


# --- AC-5: checkpoints resume the encounter ----------------------------------

func test_req_013_a_checkpoint_resumes_at_the_last_completed_phase() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var regen := RegenSystem.new(tuning)
	var lives := LifeSystem.new(tuning)
	lives.set_capability_restorer(regen)
	encounter.set_regen(regen)
	encounter.set_life_system(lives)

	var graph := CheckpointGraph.new("boss_arena")
	assert_bool(graph.add(Checkpoint.new(
		"mid_fight", Vector3(0, 0, -10)))).is_true()
	lives.open_world("boss_arena", graph)

	# Phase 0 falls; the world grants a mid-fight checkpoint.
	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()
	assert_bool(lives.activate_checkpoint("mid_fight")).is_true()
	assert_int(encounter.get_checkpoint_phase_index()).is_equal(1)

	# The fight turns: capability stripped, every life spent.
	assert_bool(encounter.ordinary_attack(Capability.Kind.TAIL)).is_true()
	for _index: int in range(lives.get_lives()):
		encounter.finisher()

	# The respawn is a SETBACK, not a restart: lives replenished and
	# capabilities restored by the life system's own checkpoint semantics,
	# and the encounter resumes at the snapshot — phase 1, never phase 0.
	assert_int(lives.get_lives()).is_equal(lives.get_lives_per_attempt())
	assert_bool(regen.is_fully_intact()).is_true()
	assert_int(encounter.get_current_phase_index()).is_equal(1)
	assert_str(encounter.get_current_phase_id()).is_equal("deck_assault")


func test_req_013_without_a_checkpoint_the_resume_anchor_is_phase_zero() -> void:
	var tuning := _tuning()
	var encounter := _encounter()
	var lives := LifeSystem.new(tuning)
	encounter.set_life_system(lives)

	assert_bool(encounter.complete_phase(
		MovementGrammar.Grammar.WATER)).is_true()
	for _index: int in range(lives.get_lives()):
		encounter.finisher()

	# No checkpoint was reached, so the only honest anchor is the start —
	# and that is a property of the snapshot, not a world restart.
	assert_int(encounter.get_current_phase_index()).is_equal(0)


# --- AC-6: a world declaring no boss stays valid and completable -------------

func test_req_013_no_installed_world_declares_a_boss() -> void:
	# The completability half is proven every run by the template, coral and
	# bubble walks (and the no-boss unlock path by the WorldSystems suite);
	# this pins the declaration half across every installed module.
	var dir := DirAccess.open("res://worlds")
	assert_object(dir).is_not_null()
	var modules := dir.get_directories()
	assert_int(modules.size()).is_greater_equal(3)
	for module: String in modules:
		var handle := FileAccess.open(
			"res://worlds/%s/world.json" % module, FileAccess.READ)
		var manifest: Variant = JSON.parse_string(handle.get_as_text())
		handle.close()
		assert_bool(manifest is Dictionary
			and not (manifest as Dictionary).has("boss")
		).override_failure_message(
			"world '%s' unexpectedly declares a boss" % module).is_true()
