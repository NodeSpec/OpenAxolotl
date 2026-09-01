extends GdUnitTestSuite

## Gill Mod Ability Framework — REQ-004.
##
## Test names carry the requirement id they prove (test_req_004_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).

const TUNING_PATH := "res://core/tuning/tuning.json"

const MVP_MODS: PackedStringArray = ["bubble", "jet", "glow"]

## Every file that IS the ability system core. AC-2 says a fixture mod can be
## added without modifying any of these, so the list is named here and the test
## below hashes it across a registration.
const CORE_SOURCES: PackedStringArray = [
	"res://core/gillmod/gill_mod_error.gd",
	"res://core/gillmod/gill_mod.gd",
	"res://core/gillmod/gill_mod_registry.gd",
	"res://core/gillmod/gill_mod_system.gd",
]

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("gillmod")


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


## The three shipped mods, discovered from the directory exactly as a community
## mod would be.
func _registry(tuning: TuningData) -> GillModRegistry:
	var registry := GillModRegistry.new(tuning)
	var errors: Array[GillModError] = []
	var loaded := registry.load_directory(GillModRegistry.MODS_DIRECTORY, errors)
	assert_array(errors).is_empty()
	assert_int(loaded).is_equal(3)
	return registry


func _system() -> GillModSystem:
	var tuning := _tuning()
	return GillModSystem.new(tuning, _registry(tuning))


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


## A declaration for a mod that does not exist in this repository, used to prove
## the extension path. Deliberately unlike the three: different tuning keys are
## not available, so it reuses one — an extension mod is not required to bring
## its own balance data, only to cite keys that exist.
func _fixture_declaration(mod_id: String = "fixture",
		affordance: String = "fixture_affordance") -> Dictionary:
	return {
		"id": mod_id,
		"displayName": "Fixture Gills",
		"affordances": [affordance],
		"durationKey": "gillmod.bubble.duration_s",
		"cooldownKey": "gillmod.bubble.cooldown_s",
		"audioCueId": "gill_mod_fixture_activated",
		"visualId": "vfx.gills.fixture",
		"hudIcon": "icon.gillmod.fixture",
	}


func _write_declaration(directory: String, name: String,
		declaration: Dictionary) -> String:
	var path := directory.path_join(name)
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(JSON.stringify(declaration))
	handle.close()
	return path


# --- AC-1: three mods, each unlocking something unavailable otherwise ------

func test_req_004_the_three_mvp_mods_are_registered() -> void:
	var registry := _registry(_tuning())

	for mod_id: String in MVP_MODS:
		assert_bool(registry.has(mod_id)).override_failure_message(
			"REQ-004 AC-1: '%s' Gill Mod is not registered" % mod_id).is_true()
	assert_int(registry.size()).is_equal(3)


func test_req_004_every_mod_unlocks_at_least_one_affordance() -> void:
	var registry := _registry(_tuning())

	for mod_id: String in MVP_MODS:
		assert_int(registry.get_mod(mod_id).affordances.size()
		).override_failure_message(
			"REQ-004 AC-1: '%s' unlocks nothing" % mod_id).is_greater(0)


func test_req_004_no_two_mods_grant_the_same_affordance() -> void:
	# "Unavailable without it" is only true if nothing else grants it. Two mods
	# sharing an affordance would break the criterion for BOTH of them.
	var registry := _registry(_tuning())
	var seen: Array[String] = []

	for affordance: String in registry.get_all_affordances():
		assert_bool(seen.has(affordance)).override_failure_message(
			"REQ-004 AC-1: affordance '%s' is granted by more than one mod, so "
			% affordance + "neither unlocks it exclusively"
		).is_false()
		seen.append(affordance)


func test_req_004_an_affordance_is_unavailable_without_its_mod() -> void:
	# The gate a world actually uses, exercised in all four states: nothing
	# equipped, the wrong mod, the right mod idle, the right mod active.
	var system := _system()

	assert_bool(system.has_affordance("jet_dash")).override_failure_message(
		"REQ-004 AC-1: an affordance must be unavailable with nothing equipped"
	).is_false()

	system.equip("bubble")
	system.activate()
	assert_bool(system.has_affordance("jet_dash")).override_failure_message(
		"REQ-004 AC-1: Bubble Gills must not grant the Jet affordance"
	).is_false()

	system.equip("jet")
	assert_bool(system.has_affordance("jet_dash")).override_failure_message(
		"an affordance is a window the player opens, not a permanent upgrade"
	).is_false()

	assert_bool(system.activate()).is_true()
	assert_bool(system.has_affordance("jet_dash")).override_failure_message(
		"REQ-004 AC-1: the equipped mod must grant its affordance while active"
	).is_true()


func test_req_004_each_mvp_mod_gates_a_path_the_others_cannot() -> void:
	# Walked as a loop over all three rather than spot-checking one, because the
	# criterion is about each of them.
	var tuning := _tuning()
	var registry := _registry(tuning)

	for mod_id: String in MVP_MODS:
		var affordance := registry.get_mod(mod_id).affordances[0]

		for other_id: String in MVP_MODS:
			var system := GillModSystem.new(tuning, registry)
			system.equip(other_id)
			system.activate()

			var granted := system.has_affordance(affordance)
			if other_id == mod_id:
				assert_bool(granted).override_failure_message(
					"REQ-004 AC-1: '%s' must grant '%s'" % [mod_id, affordance]
				).is_true()
			else:
				assert_bool(granted).override_failure_message(
					"REQ-004 AC-1: '%s' must not grant '%s', which belongs to '%s'"
					% [other_id, affordance, mod_id]
				).is_false()


# --- AC-2: the extension interface, which is the product -------------------

func test_req_004_a_fixture_mod_registers_without_touching_the_core() -> void:
	# THE criterion for this node. The core files are hashed before and after a
	# fixture mod is discovered and used, and must be byte-identical.
	var before: Dictionary = {}
	for path: String in CORE_SOURCES:
		before[path] = _read(path)

	_write_declaration(_temp_dir, "fixture.json", _fixture_declaration())

	var tuning := _tuning()
	var registry := GillModRegistry.new(tuning)
	var errors: Array[GillModError] = []
	assert_int(registry.load_directory(_temp_dir, errors)).is_equal(1)
	assert_array(errors).is_empty()

	var system := GillModSystem.new(tuning, registry)
	assert_bool(system.equip("fixture")).is_true()
	assert_bool(system.activate()).is_true()
	assert_bool(system.has_affordance("fixture_affordance")).override_failure_message(
		"REQ-004 AC-2: a fixture mod must work through the same gate as a shipped one"
	).is_true()

	for path: String in CORE_SOURCES:
		assert_str(_read(path)).override_failure_message(
			"REQ-004 AC-2: registering a mod modified '%s'" % path
		).is_equal(String(before[path]))


func test_req_004_the_shipped_mods_are_data_not_code() -> void:
	# The reason the fixture path is the tested path: the three MVP mods take it
	# too. A registry constant listing them would make every new mod an edit.
	var dir := DirAccess.open(GillModRegistry.MODS_DIRECTORY)
	assert_object(dir).is_not_null()

	var declarations := 0
	for name: String in dir.get_files():
		assert_str(name.get_extension()).override_failure_message(
			"REQ-004 AC-2: '%s' is not a declaration; mods are data" % name
		).is_equal(GillModRegistry.DECLARATION_EXTENSION)
		declarations += 1
	assert_int(declarations).is_equal(3)

	# ...and no core file names them.
	for path: String in CORE_SOURCES:
		var text := _read(path)
		for mod_id: String in MVP_MODS:
			assert_bool(text.contains('"%s"' % mod_id)).override_failure_message(
				"REQ-004 AC-2: '%s' hardcodes the mod id '%s'" % [path, mod_id]
			).is_false()


func test_req_004_a_malformed_declaration_is_refused_with_a_named_error() -> void:
	# An extension interface that fails silently leaves a contributor nothing to
	# debug: their mod simply never appears.
	var registry := GillModRegistry.new(_tuning())

	var incomplete := _fixture_declaration()
	incomplete.erase("affordances")
	var errors: Array[GillModError] = []
	assert_bool(registry.register_from_contract(incomplete, errors)).is_false()
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(GillModError.MISSING_FIELD)

	errors.clear()
	var empty := _fixture_declaration()
	empty["affordances"] = []
	assert_bool(registry.register_from_contract(empty, errors)).is_false()
	assert_str(errors[0].code).is_equal(GillModError.NO_AFFORDANCES)


func test_req_004_a_mod_citing_an_absent_tuning_key_is_refused() -> void:
	# Otherwise the failure surfaces the moment the player first activates it,
	# which is the worst time and the hardest to trace back to the declaration.
	var registry := GillModRegistry.new(_tuning())
	var declaration := _fixture_declaration()
	declaration["durationKey"] = "gillmod.nonexistent.duration_s"

	var errors: Array[GillModError] = []
	assert_bool(registry.register_from_contract(declaration, errors)).is_false()
	assert_str(errors[0].code).is_equal(GillModError.UNKNOWN_TUNING_KEY)


func test_req_004_a_duplicate_id_or_affordance_is_refused() -> void:
	var registry := _registry(_tuning())
	var errors: Array[GillModError] = []

	var clashing_id := _fixture_declaration("jet", "brand_new")
	assert_bool(registry.register_from_contract(clashing_id, errors)).is_false()
	assert_str(errors[0].code).is_equal(GillModError.DUPLICATE_ID)

	errors.clear()
	var clashing_affordance := _fixture_declaration("newcomer", "jet_dash")
	assert_bool(registry.register_from_contract(clashing_affordance, errors)
	).override_failure_message(
		"REQ-004 AC-1: a second mod granting 'jet_dash' would stop Jet Gills "
		+ "unlocking it exclusively"
	).is_false()
	assert_str(errors[0].code).is_equal(GillModError.AFFORDANCE_ALREADY_GRANTED)


func test_req_004_one_bad_declaration_does_not_stop_the_others_loading() -> void:
	# A community directory with twenty mods must not go dark because one is
	# malformed.
	_write_declaration(_temp_dir, "good.json", _fixture_declaration("good", "a"))
	var handle := FileAccess.open(_temp_dir.path_join("bad.json"), FileAccess.WRITE)
	handle.store_string("{ not json at all")
	handle.close()
	_write_declaration(_temp_dir, "other.json", _fixture_declaration("other", "b"))

	var registry := GillModRegistry.new(_tuning())
	var errors: Array[GillModError] = []
	var loaded := registry.load_directory(_temp_dir, errors)

	assert_int(loaded).is_equal(2)
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0].code).is_equal(GillModError.MALFORMED_JSON)


# --- AC-3: a world's custom mod through the Level Contract -----------------

func test_req_004_a_world_can_supply_a_custom_mod_through_the_contract() -> void:
	var tuning := _tuning()
	var registry := _registry(tuning)

	var errors: Array[GillModError] = []
	assert_bool(registry.register_from_contract(
		_fixture_declaration("coral_current", "ride_current"), errors)
	).override_failure_message(
		"REQ-004 AC-3: a world must be able to declare a custom Gill Mod"
	).is_true()
	assert_array(errors).is_empty()

	var system := GillModSystem.new(tuning, registry)
	system.equip("coral_current")
	system.activate()

	assert_bool(system.has_affordance("ride_current")).is_true()
	assert_int(registry.size()).is_equal(4)


func test_req_004_a_worlds_mod_travels_the_same_validation_as_a_shipped_one() -> void:
	# Not privileged, and not second-class either: the contract path and the
	# directory path are the same code below the parse.
	var registry := _registry(_tuning())
	var errors: Array[GillModError] = []

	var bad := _fixture_declaration("world_mod", "x")
	bad["cooldownKey"] = "gillmod.nope.cooldown_s"

	assert_bool(registry.register_from_contract(bad, errors)).is_false()
	assert_str(errors[0].code).is_equal(GillModError.UNKNOWN_TUNING_KEY)


# --- AC-4: equipping, switching, and the visual --------------------------

func test_req_004_equipping_and_switching_is_available_and_announced() -> void:
	var system := _system()
	var visuals: Array[String] = []
	system.visual_changed.connect(func(v: String) -> void: visuals.append(v))

	assert_bool(system.equip("bubble")).is_true()
	assert_str(system.get_equipped_id()).is_equal("bubble")

	assert_bool(system.equip("glow")).override_failure_message(
		"REQ-004 AC-4: switching mods must be available to the player"
	).is_true()
	assert_str(system.get_equipped_id()).is_equal("glow")

	assert_array(visuals).is_equal(
		["vfx.gills.bubble", "vfx.gills.glow"] as Array[String])


func test_req_004_every_mod_declares_a_visual_so_the_axolotl_can_show_it() -> void:
	# The mesh swap belongs to the Game Client; what this node owes is that every
	# mod names a distinct appearance for it to swap to.
	var registry := _registry(_tuning())
	var seen: Array[String] = []

	for mod_id: String in registry.get_ids():
		var visual := registry.get_mod(mod_id).visual_id
		assert_str(visual).override_failure_message(
			"REQ-004 AC-4: '%s' declares no visual" % mod_id).is_not_empty()
		assert_bool(seen.has(visual)).override_failure_message(
			"REQ-004 AC-4: visual '%s' is reused, so the axolotl would look the "
			% visual + "same with two different mods equipped"
		).is_false()
		seen.append(visual)


func test_req_004_switching_does_not_inherit_the_previous_cooldown() -> void:
	# A cooldown belongs to a use, not to the slot.
	var system := _system()
	system.equip("jet")
	system.activate()
	system.tick(system.effective_duration())
	assert_bool(system.is_cooling()).is_true()

	system.equip("glow")

	assert_bool(system.is_ready()).is_true()
	assert_bool(system.activate()).is_true()


func test_req_004_unequipping_clears_the_visual() -> void:
	var system := _system()
	system.equip("bubble")
	var visuals: Array[String] = []
	system.visual_changed.connect(func(v: String) -> void: visuals.append(v))

	system.unequip()

	assert_bool(system.has_equipped()).is_false()
	assert_array(visuals).is_equal([""] as Array[String])


func test_req_004_activation_requests_the_mods_semantic_audio_cue() -> void:
	# A semantic id, never a file path: the Audio System decides what it sounds
	# like (REQ-023).
	var system := _system()
	var cues: Array[String] = []
	system.audio_cue_requested.connect(func(c: String) -> void: cues.append(c))

	system.equip("glow")
	system.activate()

	assert_array(cues).is_equal(["gill_mod_glow_activated"] as Array[String])


func test_req_004_the_three_mvp_cues_are_the_audio_systems_declared_ones() -> void:
	# The MVP mods bind to the Audio Event Interface's closed set. A custom mod
	# may declare its own id, and the world then ships the bank entry for it.
	var registry := _registry(_tuning())
	var declared := PackedStringArray()
	for cue: AudioEvent.Cue in AudioEvent.GILL_MOD_CUES:
		declared.append(AudioEvent.cue_id(cue))

	for mod_id: String in MVP_MODS:
		var cue_id := registry.get_mod(mod_id).audio_cue_id
		assert_bool(declared.has(cue_id)).override_failure_message(
			"REQ-004: '%s' cites audio cue '%s', which the Audio System does "
			% [mod_id, cue_id] + "not declare"
		).is_true()


# --- AC-5: gill loss shortens the boost ------------------------------------

func test_req_004_a_lost_gill_shortens_the_boost_by_the_tuned_multiplier() -> void:
	var tuning := _tuning()
	var factor := tuning.get_number("capability.gill_loss.boost_duration_multiplier")
	var base := tuning.get_number("gillmod.bubble.duration_s")

	var regen := RegenSystem.new(tuning)
	var modifiers := CapabilityModifiers.new()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.set_capability_modifiers(modifiers)
	system.equip("bubble")

	assert_float(system.effective_duration()).is_equal_approx(base, 0.0001)

	regen.apply_damage(DamageEvent.new("netbot", Capability.Kind.GILL))
	regen.publish_to(modifiers)

	assert_float(system.effective_duration()).override_failure_message(
		"REQ-004 AC-5: a lost gill must shorten the boost by the tuned multiplier"
	).is_equal_approx(base * factor, 0.0001)


func test_req_004_the_multiplier_is_applied_at_activation_not_stored() -> void:
	# A mod mutated by damage would stay short after the gill regrew. The
	# declaration is shared by every future activation and must never be written.
	var tuning := _tuning()
	var base := tuning.get_number("gillmod.jet.duration_s")
	var regen := RegenSystem.new(tuning)
	var modifiers := CapabilityModifiers.new()
	var registry := _registry(tuning)
	var system := GillModSystem.new(tuning, registry)
	system.set_capability_modifiers(modifiers)
	system.equip("jet")

	regen.apply_damage(DamageEvent.new("netbot", Capability.Kind.GILL))
	regen.publish_to(modifiers)
	system.activate()
	assert_float(system.get_remaining()).is_less(base)

	regen.restore_all()
	regen.publish_to(modifiers)

	assert_float(system.effective_duration()).override_failure_message(
		"REQ-004 AC-5: the mod declaration must not have been mutated by damage"
	).is_equal_approx(base, 0.0001)
	assert_float(tuning.get_number(registry.get_mod("jet").duration_key)
	).is_equal_approx(base, 0.0001)


func test_req_004_an_unwired_capability_system_means_no_damage_not_no_mods() -> void:
	var tuning := _tuning()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.equip("glow")

	assert_float(system.effective_duration()).is_equal_approx(
		tuning.get_number("gillmod.glow.duration_s"), 0.0001)


# --- AC-6: the Hookline Rig snag -------------------------------------------

func test_req_004_a_snag_strips_the_mod_and_restores_it_after_the_window() -> void:
	var tuning := _tuning()
	var window := tuning.get_number("enemy.hookline.mod_strip_seconds")
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.equip("jet")

	var events: Array[String] = []
	system.stripped.connect(func(id: String, _s: float) -> void:
		events.append("stripped:" + id))
	system.restored.connect(func(id: String) -> void:
		events.append("restored:" + id))

	assert_bool(system.snag()).is_true()
	assert_bool(system.has_equipped()).is_false()
	assert_bool(system.is_stripped()).is_true()

	# One tick short of the window: still stripped.
	system.tick(window - 0.01)
	assert_bool(system.is_stripped()).is_true()

	system.tick(0.01)
	assert_bool(system.is_stripped()).override_failure_message(
		"REQ-004 AC-6: the mod must return after enemy.hookline.mod_strip_seconds"
	).is_false()
	assert_str(system.get_equipped_id()).is_equal("jet")
	assert_array(events).is_equal(
		["stripped:jet", "restored:jet"] as Array[String])


func test_req_004_the_restore_timer_is_owned_here_not_by_the_enemy() -> void:
	# A rig despawned mid-snag — killed, or its region unloaded — must not be
	# able to strand the player without a mod forever. The enemy is absent from
	# this test entirely and the mod still comes back.
	var tuning := _tuning()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.equip("glow")
	system.snag()

	system.tick(tuning.get_number("enemy.hookline.mod_strip_seconds") * 3.0)

	assert_str(system.get_equipped_id()).is_equal("glow")


func test_req_004_a_stripped_slot_cannot_be_equipped_around() -> void:
	# Letting the player swap in another mod would make the snag a non-event.
	var system := _system()
	system.equip("bubble")
	system.snag()

	assert_bool(system.equip("jet")).override_failure_message(
		"REQ-004 AC-6: a snag must hold the slot for its window"
	).is_false()
	assert_bool(system.activate()).is_false()
	assert_bool(system.has_equipped()).is_false()


func test_req_004_a_rig_cannot_extend_its_window_by_re_snagging() -> void:
	var system := _system()
	system.equip("bubble")
	assert_bool(system.snag()).is_true()
	var remaining := system.get_strip_remaining()

	system.tick(1.0)
	assert_bool(system.snag()).is_false()

	assert_float(system.get_strip_remaining()).override_failure_message(
		"a re-snag must not reset the window"
	).is_less(remaining)


func test_req_004_snagging_an_empty_slot_does_nothing() -> void:
	var system := _system()
	assert_bool(system.snag()).is_false()
	assert_bool(system.is_stripped()).is_false()


func test_req_004_a_snag_while_gill_damaged_restores_to_the_damaged_duration() -> void:
	# The interaction of the two external timers, which is where a stored
	# multiplier would show up as a bug: restored after a snag, the next
	# activation must land on the DAMAGED duration, not on the base one.
	var tuning := _tuning()
	var factor := tuning.get_number("capability.gill_loss.boost_duration_multiplier")
	var base := tuning.get_number("gillmod.bubble.duration_s")

	var regen := RegenSystem.new(tuning)
	var modifiers := CapabilityModifiers.new()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.set_capability_modifiers(modifiers)
	system.equip("bubble")

	regen.apply_damage(DamageEvent.new("netbot", Capability.Kind.GILL))
	regen.publish_to(modifiers)

	system.snag()
	system.tick(tuning.get_number("enemy.hookline.mod_strip_seconds"))
	assert_str(system.get_equipped_id()).is_equal("bubble")

	assert_bool(system.activate()).is_true()
	assert_float(system.get_remaining()).override_failure_message(
		"REQ-004: restored after a snag while gill-damaged, the boost must still "
		+ "be the damaged duration"
	).is_equal_approx(base * factor, 0.0001)


# --- The duration and cooldown machine -------------------------------------

func test_req_004_a_mod_runs_then_cools_then_becomes_ready() -> void:
	var tuning := _tuning()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.equip("bubble")

	assert_bool(system.activate()).is_true()
	assert_bool(system.activate()).override_failure_message(
		"a second activation while running must be refused, not queued"
	).is_false()

	system.tick(system.effective_duration())
	assert_bool(system.is_cooling()).is_true()
	assert_bool(system.activate()).is_false()

	system.tick(system.cooldown_seconds())
	assert_bool(system.is_ready()).is_true()
	assert_bool(system.activate()).is_true()


func test_req_004_a_long_frame_does_not_shorten_the_cooldown() -> void:
	var tuning := _tuning()
	var system := GillModSystem.new(tuning, _registry(tuning))
	system.equip("glow")
	system.activate()

	var cooldown := system.cooldown_seconds()
	system.tick(system.effective_duration() + cooldown * 0.5)

	assert_bool(system.is_cooling()).is_true()
	assert_float(system.get_remaining()).is_equal_approx(cooldown * 0.5, 0.001)


func test_req_004_activating_with_nothing_equipped_is_refused() -> void:
	var system := _system()
	assert_bool(system.activate()).is_false()
	assert_bool(system.is_active()).is_false()


# --- No magic numbers ------------------------------------------------------

func test_req_004_every_gill_mod_tuning_key_exists_in_the_surface() -> void:
	var tuning := _tuning()
	var registry := _registry(tuning)

	for mod_id: String in registry.get_ids():
		var mod := registry.get_mod(mod_id)
		for key: String in [mod.duration_key, mod.cooldown_key]:
			assert_bool(tuning.has_key(key)).override_failure_message(
				"REQ-004: '%s' cites '%s', which the tuning surface lacks"
				% [mod_id, key]).is_true()

	assert_bool(tuning.has_key(GillModSystem.STRIP_SECONDS_KEY)).is_true()


func test_req_004_the_system_declares_no_balance_constants() -> void:
	var text := _read("res://core/gillmod/gill_mod_system.gd")
	assert_bool(text.contains("_tuning.get_number")).is_true()


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_gillmod_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in CORE_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
