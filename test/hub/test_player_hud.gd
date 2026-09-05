extends GdUnitTestSuite

## Player HUD — REQ-022.
##
## Every readout is proven against the REAL system it consumes, and the
## same-frame criteria are proven STRUCTURALLY: the system's mutator is
## called and the label text is asserted in the very next statement — no
## frame is processed in between, so a HUD that waited for _process would
## fail these tests.

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


func _restoration(tuning: TuningData) -> RestorationSystem:
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	assert_bool(restoration.declare_from_manifest(
		{"restorableRegions": [{"regionId": "reef", "traversalGates": [
			{"gateId": "reef_gate", "opensAt": "restored"}]}]},
		errors)).is_true()
	return restoration


var _spawned: Array[Node] = []


func after_test() -> void:
	for node: Node in _spawned:
		node.free()
	_spawned.clear()


func _hud() -> PlayerHud:
	# Freed by the suite, not the tree: the HUD is exercised entirely
	# off-tree, which is itself evidence the readout logic has no tree
	# dependency.
	var hud := PlayerHud.new()
	_spawned.append(hud)
	return hud


# --- AC-1: lives, reflected in the same frame --------------------------------

func test_req_022_lives_display_updates_in_the_emitting_frame() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var lives := LifeSystem.new(tuning)
	hud.set_life_system(lives)

	var total := lives.get_lives_per_attempt()
	assert_str(hud.get_lives_text()).is_equal(
		"Lives: %d of %d" % [total, total])

	# The mutation and the assertion are adjacent statements: no _process
	# ran, so the update happened inside the signal's own call stack.
	assert_bool(lives.lose_life(CatastrophicSource.Kind.PIT_VOLUME)).is_true()
	assert_str(hud.get_lives_text()).is_equal(
		"Lives: %d of %d" % [total - 1, total])

	# Losing the last life replenishes through the respawn — also same-frame.
	for _index: int in range(total - 1):
		lives.lose_life(CatastrophicSource.Kind.PIT_VOLUME)
	assert_str(hud.get_lives_text()).is_equal(
		"Lives: %d of %d" % [total, total])


# --- AC-2: capabilities, reflected in the same frame -------------------------

func test_req_022_capability_display_updates_in_the_emitting_frame() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var regen := RegenSystem.new(tuning)
	hud.set_regen(regen)

	for kind: Capability.Kind in Capability.ALL:
		assert_str(hud.get_capability_text(kind)).contains(PlayerHud.INTACT_MARK)

	var hit := DamageEvent.new()
	hit.capability = Capability.Kind.TAIL
	assert_bool(regen.apply_damage(hit)).is_true()
	assert_str(hud.get_capability_text(Capability.Kind.TAIL)).contains(
		PlayerHud.LOST_MARK)
	# Only the struck capability changed.
	assert_str(hud.get_capability_text(Capability.Kind.GILL)).contains(
		PlayerHud.INTACT_MARK)

	assert_bool(regen.restore(Capability.Kind.TAIL)).is_true()
	assert_str(hud.get_capability_text(Capability.Kind.TAIL)).contains(
		PlayerHud.INTACT_MARK)


# --- AC-3: the equipped mod and its charge or cooldown -----------------------

func test_req_022_mod_display_names_the_mod_and_its_window() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var mods := _mods(tuning)
	hud.set_gill_mods(mods)

	assert_str(hud.get_mod_text()).is_equal("Mod: none")

	assert_bool(mods.equip("bubble")).is_true()
	assert_str(hud.get_mod_text()).is_equal("Mod: bubble [READY]")

	assert_bool(mods.activate()).is_true()
	assert_str(hud.get_mod_text()).contains("Mod: bubble [ACTIVE")

	# The window expires -> the cooldown is what remains to show.
	mods.tick(tuning.get_number("gillmod.bubble.duration_s") + 0.01)
	assert_str(hud.get_mod_text()).contains("Mod: bubble [COOLING")

	mods.tick(tuning.get_number("gillmod.bubble.cooldown_s") + 0.01)
	assert_str(hud.get_mod_text()).is_equal("Mod: bubble [READY]")


func test_req_022_mod_display_shows_a_hookline_snag() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var mods := _mods(tuning)
	hud.set_gill_mods(mods)

	assert_bool(mods.equip("glow")).is_true()
	assert_bool(mods.snag()).is_true()
	assert_str(hud.get_mod_text()).contains("Mod: glow [SNAGGED")

	mods.tick(tuning.get_number("enemy.hookline.mod_strip_seconds") + 0.01)
	assert_str(hud.get_mod_text()).is_equal("Mod: glow [READY]")


# --- AC-4: the active region's state and progress ----------------------------

func test_req_022_region_display_shows_state_and_progress_to_next() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var restoration := _restoration(tuning)
	hud.set_tuning(tuning)
	hud.set_restoration(restoration, "reef")

	var to_resourced := tuning.get_count("restoration.resourced.resource_cost")
	assert_str(hud.get_region_text()).is_equal(
		"Region reef: barren (0/%d to next) [LOCKED]" % to_resourced)

	restoration.unlock_region("reef")
	# Progress within a state has no state-change signal; the HUD polls it
	# each frame, which one processed frame stands in for here.
	restoration.deliver_resources("reef", to_resourced - 1)
	hud._process(0.016)
	assert_str(hud.get_region_text()).is_equal(
		"Region reef: barren (%d/%d to next)"
		% [to_resourced - 1, to_resourced])

	# A state CHANGE updates in the emitting frame, no poll needed.
	restoration.deliver_resources("reef", 1)
	assert_str(hud.get_region_text()).contains("Region reef: resourced")

	restoration.deliver_resources("reef",
		tuning.get_count("restoration.restored.resource_cost"))
	assert_str(hud.get_region_text()).is_equal(
		"Region reef: restored [COMPLETE]")


func test_req_022_a_world_with_no_regions_shows_an_honest_placeholder() -> void:
	var hud := _hud()
	hud.set_restoration(RestorationSystem.new(_tuning()))
	assert_str(hud.get_region_text()).is_equal("Region: none")


# --- AC-6: the dash charge and its recharge state ----------------------------

func test_req_022_dash_display_tracks_charges_and_recharge() -> void:
	var tuning := _tuning()
	var hud := _hud()
	var dash := WaterDash.new(tuning)
	hud.set_tuning(tuning)
	hud.set_dash(dash)

	var maximum := dash.max_charges()
	assert_str(hud.get_dash_text()).is_equal(
		"Dash: %d of %d [FULL]" % [maximum, maximum])

	assert_bool(dash.try_consume()).is_true()
	hud._process(0.016)
	assert_str(hud.get_dash_text()).contains(
		"Dash: %d of %d [RECHARGING" % [maximum - 1, maximum])

	# Half the tuned recharge in water reads as ~50%.
	var needed := tuning.get_number(WaterDash.RECHARGE_SECONDS_KEY)
	dash.tick(needed * 0.5, true)
	hud._process(0.016)
	assert_str(hud.get_dash_text()).contains("[RECHARGING 50%]")

	dash.tick(needed * 0.5 + 0.01, true)
	hud._process(0.016)
	assert_str(hud.get_dash_text()).is_equal(
		"Dash: %d of %d [FULL]" % [maximum, maximum])


# --- AC-5: never color alone -------------------------------------------------

func test_req_022_every_state_pair_differs_as_text_not_only_color() -> void:
	# The criterion's testable core: for every readout, two different game
	# states must produce two different STRINGS. A HUD distinguishing them
	# only by tint would fail every pair below.
	var tuning := _tuning()
	var hud := _hud()

	var lives := LifeSystem.new(tuning)
	hud.set_life_system(lives)
	var lives_full := hud.get_lives_text()
	lives.lose_life(CatastrophicSource.Kind.PIT_VOLUME)
	assert_str(hud.get_lives_text()).is_not_equal(lives_full)

	var regen := RegenSystem.new(tuning)
	hud.set_regen(regen)
	var intact := hud.get_capability_text(Capability.Kind.TAIL)
	var hit := DamageEvent.new()
	hit.capability = Capability.Kind.TAIL
	regen.apply_damage(hit)
	assert_str(hud.get_capability_text(Capability.Kind.TAIL)
	).is_not_equal(intact)

	var mods := _mods(tuning)
	hud.set_gill_mods(mods)
	mods.equip("jet")
	var ready := hud.get_mod_text()
	mods.activate()
	assert_str(hud.get_mod_text()).is_not_equal(ready)

	hud.set_tuning(tuning)
	var restoration := _restoration(tuning)
	hud.set_restoration(restoration, "reef")
	var locked := hud.get_region_text()
	restoration.unlock_region("reef")
	hud._process(0.016)
	assert_str(hud.get_region_text()).is_not_equal(locked)

	var dash := WaterDash.new(tuning)
	hud.set_dash(dash)
	var full := hud.get_dash_text()
	dash.try_consume()
	hud._process(0.016)
	assert_str(hud.get_dash_text()).is_not_equal(full)


# --- An unwired HUD lies about nothing ---------------------------------------

func test_req_022_an_unwired_hud_shows_placeholders_not_fabrications() -> void:
	var hud := _hud()
	assert_str(hud.get_lives_text()).is_equal("Lives: --")
	assert_str(hud.get_capability_text(Capability.Kind.TAIL)).contains("--")
	assert_str(hud.get_mod_text()).is_equal("Mod: --")
	assert_str(hud.get_region_text()).is_equal("Region: none")
	assert_str(hud.get_dash_text()).is_equal("Dash: --")
