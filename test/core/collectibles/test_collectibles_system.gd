extends GdUnitTestSuite

## Collectibles System — REQ-010.
##
## Test names carry the requirement id they prove (test_req_010_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).
##
## Unit-tier tests drive the system as a plain object against a store double;
## the integration-tier tests below use the REAL SaveSystem on a real file and
## the REAL LifeSystem, because the criteria explicitly reject isolation-only
## coverage for persistence and for surviving the life layer.

const TUNING_PATH := "res://core/tuning/tuning.json"
const CONTRACT_PATH := "res://contracts/level_contract.v1.json"
const OFFICIAL_WORLDS: PackedStringArray = [
	"res://worlds/coral_cove", "res://worlds/bubble_bay",
]

const COLLECTIBLE_SOURCES: PackedStringArray = [
	"res://core/collectibles/collectible_error.gd",
	"res://core/collectibles/collectible_kind.gd",
	"res://core/collectibles/collectible_def.gd",
	"res://core/collectibles/collectible_store.gd",
	"res://core/collectibles/save_collectible_store.gd",
	"res://core/collectibles/collectibles_system.gd",
]

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("collectibles")


## In-memory double for the Save Integration Interface's collectibles field,
## keyed per world so the per-world criterion can be told apart from a global
## count. Counts writes so a test can assert WHEN persistence happened.
class FakeStore extends CollectibleStore:
	var by_world: Dictionary = {}
	var writes: int = 0

	func load_collected(world_id: String) -> PackedStringArray:
		return (by_world.get(world_id, PackedStringArray()) as PackedStringArray).duplicate()

	func persist_collected(world_id: String, ids: PackedStringArray) -> void:
		by_world[world_id] = ids.duplicate()
		writes += 1


func _tuning() -> TuningData:
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(TUNING_PATH, errors)
	assert_array(errors).is_empty()
	return data


## A tuning file identical to the real one except for the value under
## [param key] — how "changing a value alters behaviour with no recompile" is
## proven rather than asserted (REQ-025).
func _tuning_with(key: String, value: float) -> TuningData:
	var handle := FileAccess.open(TUNING_PATH, FileAccess.READ)
	var root: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	((root as Dictionary)["values"] as Dictionary)[key]["value"] = value
	var path := _temp_dir.path_join("tuning.json")
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(root, "  "))
	out.close()
	var errors: Array[TuningError] = []
	var data := TuningData.load_from_file(path, errors)
	assert_array(errors).is_empty()
	return data


func _region_manifest() -> Dictionary:
	return {
		"restorableRegions": [
			{
				"regionId": "coral_shelf",
				"traversalGates": [{"gateId": "shelf_wall", "opensAt": "restored"}],
			},
		],
	}


## One resource type and two discovery collectibles — the two lifetimes side
## by side.
func _manifest() -> Dictionary:
	var manifest := _region_manifest()
	manifest["collectibles"] = [
		{"collectibleId": "kelp_seed", "kind": "resource", "regionId": "coral_shelf"},
		{"collectibleId": "hermit_snail", "kind": "discovery",
			"displayName": "Hermit snail"},
		{"collectibleId": "lantern_shrimp", "kind": "discovery"},
	]
	return manifest


func _restoration(tuning: TuningData, unlocked: bool = true) -> RestorationSystem:
	var restoration := RestorationSystem.new(tuning)
	var errors: Array[RestorationError] = []
	assert_bool(restoration.declare_from_manifest(_region_manifest(), errors)).is_true()
	if unlocked:
		restoration.unlock_region("coral_shelf")
	return restoration


## A declared system over [param store] with restoration attached and the
## world opened — the state a world has right after the hub wires it.
func _system(store: CollectibleStore, tuning: TuningData = null,
		manifest: Dictionary = {}, unlocked: bool = true) -> CollectiblesSystem:
	if tuning == null:
		tuning = _tuning()
	if manifest.is_empty():
		manifest = _manifest()
	var system := CollectiblesSystem.new(tuning, store)
	system.set_restoration(_restoration(tuning, unlocked))
	var errors: Array[CollectibleError] = []
	assert_bool(system.declare_from_manifest(manifest, errors)).override_failure_message(
		"the reference declaration must be accepted: %s"
		% str(errors.map(func(e: CollectibleError) -> String: return e.to_string_id()))
	).is_true()
	system.open_world("coral_cove")
	return system


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


func _region(system: CollectiblesSystem) -> RestorableRegion:
	return system._restoration.get_region("coral_shelf")


# --- AC-1: resources are collectible and consumed to advance restoration ----

func test_req_010_collecting_resources_advances_the_regions_restoration_state() -> void:
	var tuning := _tuning()
	var system := _system(FakeStore.new(), tuning)
	var region := _region(system)
	var cost_resourced := tuning.get_count("restoration.resourced.resource_cost")
	var cost_restored := tuning.get_count("restoration.restored.resource_cost")
	var deliveries: Array[Array] = []
	system.resources_delivered.connect(
		func(region_id: String, count: int, advanced: int) -> void:
			deliveries.append([region_id, count, advanced]))

	for _pickup: int in range(cost_resourced):
		assert_bool(system.collect("kelp_seed")).is_true()
	assert_int(int(region.get_state())).override_failure_message(
		"REQ-010 AC-1: %d seeds must pay for 'resourced'" % cost_resourced
	).is_equal(int(RegionState.State.RESOURCED))
	# CONSUMED, not merely counted: the region spent them.
	assert_int(region.get_resources()).is_equal(0)

	for _pickup: int in range(cost_restored):
		system.collect("kelp_seed")
	assert_int(int(region.get_state())).is_equal(int(RegionState.State.RESTORED))
	assert_int(region.get_resources()).is_equal(0)

	assert_int(deliveries.size()).is_equal(cost_resourced + cost_restored)
	assert_str(String(deliveries[0][0])).is_equal("coral_shelf")
	# The delivery that tipped the state reports it advanced exactly one step.
	assert_int(int(deliveries[cost_resourced - 1][2])).is_equal(1)
	assert_int(int(deliveries[0][2])).is_equal(0)


func test_req_010_resources_delivered_to_a_locked_region_are_banked_not_spent() -> void:
	# The Restoration Region Interface decides; this node only delivers. A
	# locked region refuses to advance and the resources wait for the unlock.
	var system := _system(FakeStore.new(), null, {}, false)
	for _pickup: int in range(20):
		system.collect("kelp_seed")
	var region := _region(system)
	assert_int(int(region.get_state())).is_equal(int(RegionState.State.BARREN))
	assert_int(region.get_resources()).override_failure_message(
		"REQ-010 AC-1: a locked region banks deliveries rather than losing them"
	).is_equal(20 * system.resource_pickup_value())


func test_req_010_a_resource_pickup_is_repeatable_and_never_persisted_by_id() -> void:
	# Resources are a TYPE placed many times; collecting one does not make the
	# type "collected", and the profile never records a consumable.
	var store := FakeStore.new()
	var system := _system(store)
	assert_bool(system.collect("kelp_seed")).is_true()
	assert_bool(system.collect("kelp_seed")).is_true()
	assert_bool(system.is_collected("kelp_seed")).is_false()
	assert_int(store.writes).is_equal(0)
	assert_int(system.get_collected_count()).is_equal(0)


# --- REQ-025: the pickup value is tuning data, not a constant ---------------

func test_req_025_the_resource_pickup_value_is_read_from_tuning() -> void:
	var real := _tuning()
	assert_bool(real.has_key(CollectiblesSystem.RESOURCE_VALUE_KEY)).override_failure_message(
		"REQ-025: '%s' must exist in tuning.json" % CollectiblesSystem.RESOURCE_VALUE_KEY
	).is_true()

	# Same code, different data: every pickup now delivers three.
	var retuned := _tuning_with(CollectiblesSystem.RESOURCE_VALUE_KEY, 3.0)
	var system := _system(FakeStore.new(), retuned, {}, false)
	system.collect("kelp_seed")
	assert_int(_region(system).get_resources()).override_failure_message(
		"REQ-025: changing the tuned value must change what a pickup delivers"
	).is_equal(3)
	assert_int(system.resource_pickup_value()).is_equal(3)


func test_req_025_the_collectibles_node_declares_no_balance_constants() -> void:
	for path: String in COLLECTIBLE_SOURCES:
		var text := _read(path)
		for banned: String in ["_VALUE :=", "_COUNT :=", "_COST :=", "PICKUP_VALUE :="]:
			assert_bool(text.contains("const " + banned)).override_failure_message(
				"REQ-025: '%s' declares a balance constant '%s'; balance lives in tuning.json"
				% [path, banned]).is_false()


# --- AC-2: discovery collectibles counted per world, persisted to profile ---

func test_req_010_discovery_collectibles_are_counted_per_world() -> void:
	var store := FakeStore.new()
	var system := _system(store)

	assert_int(system.get_discovery_total()).is_equal(2)
	assert_int(system.get_collected_count()).is_equal(0)
	assert_bool(system.collect("hermit_snail")).is_true()
	assert_int(system.get_collected_count()).is_equal(1)
	assert_array(Array(system.get_collected_ids())).is_equal(["hermit_snail"])

	# Another world, same ids declared: its count is its own.
	system.open_world("bubble_bay")
	assert_int(system.get_collected_count()).override_failure_message(
		"REQ-010 AC-2: a count is PER WORLD; bubble_bay has collected nothing"
	).is_equal(0)
	system.collect("lantern_shrimp")
	assert_int(system.get_collected_count()).is_equal(1)

	# And back: coral_cove still has exactly its own snail.
	system.open_world("coral_cove")
	assert_int(system.get_collected_count()).is_equal(1)
	assert_bool(system.is_collected("hermit_snail")).is_true()
	assert_bool(system.is_collected("lantern_shrimp")).is_false()


func test_req_010_a_discovery_is_persisted_the_moment_it_is_collected() -> void:
	var store := FakeStore.new()
	var system := _system(store)
	assert_int(store.writes).is_equal(0)

	system.collect("hermit_snail")

	assert_int(store.writes).override_failure_message(
		"REQ-010 AC-2: the pickup itself must write through the save interface, "
		+ "not a later checkpoint or flush").is_equal(1)
	assert_array(Array(store.load_collected("coral_cove"))).contains(["hermit_snail"])


func test_req_010_a_discovery_collectible_is_collected_exactly_once() -> void:
	var store := FakeStore.new()
	var system := _system(store)
	var announced: Array[String] = []
	system.collected.connect(
		func(id: String, _kind: CollectibleKind.Kind) -> void: announced.append(id))

	assert_bool(system.collect("hermit_snail")).is_true()
	assert_bool(system.collect("hermit_snail")).override_failure_message(
		"a second pickup of the same discovery must be refused").is_false()
	assert_int(system.get_collected_count()).is_equal(1)
	assert_int(store.writes).is_equal(1)
	assert_array(announced).is_equal(["hermit_snail"] as Array[String])


func test_req_010_an_undeclared_id_is_refused_and_changes_nothing() -> void:
	var store := FakeStore.new()
	var system := _system(store)
	assert_bool(system.collect("golden_axolotl")).is_false()
	assert_int(store.writes).is_equal(0)
	assert_int(system.get_collected_count()).is_equal(0)


# --- AC-3: persists through the save-integration interface across sessions -

func test_req_010_collected_state_survives_a_new_session_through_the_real_save_system() -> void:
	var path := _temp_dir.path_join("profile.json")
	var tuning := _tuning()

	# Session one: a real profile, opened for the world, one creature rescued.
	var first_save := SaveSystem.new()
	first_save.open_world("coral_cove", _manifest())
	var first := _system(SaveCollectibleStore.new(first_save), tuning)
	assert_bool(first.collect("hermit_snail")).is_true()
	assert_bool(first_save.save_to_file(path)).is_true()

	# Session two: nothing survives but the file.
	var second_save := SaveSystem.new()
	var errors: Array[SaveError] = []
	assert_bool(second_save.load_from_file(path, errors)).is_true()
	assert_array(errors).is_empty()
	second_save.open_world("coral_cove", _manifest())
	var second := _system(SaveCollectibleStore.new(second_save), tuning)

	assert_bool(second.is_collected("hermit_snail")).override_failure_message(
		"REQ-010 AC-3: a rescued creature must still be rescued next session"
	).is_true()
	assert_bool(second.is_collected("lantern_shrimp")).is_false()
	assert_int(second.get_collected_count()).is_equal(1)


func test_req_010_the_store_writes_only_inside_the_worlds_own_namespace() -> void:
	# The Save System refuses reserved keys; the store must ride that
	# protection rather than reach around it.
	var save := SaveSystem.new()
	save.open_world("coral_cove", _manifest())
	var store := SaveCollectibleStore.new(save)
	store.persist_collected("coral_cove", PackedStringArray(["hermit_snail"]))

	var data := save.get_world_data("coral_cove")
	assert_array(data["collectibles"] as Array).is_equal(["hermit_snail"])
	# The other world's namespace and the profile-level keys are untouched.
	assert_bool(save.get_world_data("bubble_bay").is_empty()).is_true()
	assert_array(Array(save.get_unlocked_gill_mods())).is_empty()


# --- AC-4: survives losing all lives and respawning at a checkpoint ---------

func test_req_010_collection_survives_losing_every_life_and_respawning() -> void:
	# End to end, with the REAL life system over the REAL save system: rescue
	# a creature, run out of lives, respawn at the checkpoint — the creature is
	# still rescued, and the save file did not even change across the respawn
	# (collection was already in it).
	var path := _temp_dir.path_join("profile.json")
	var tuning := _tuning()
	var save := SaveSystem.new()
	save.open_world("coral_cove", _manifest())

	var graph := CheckpointGraph.new("coral_cove")
	graph.add(Checkpoint.new("cp_reef", Vector3(10.0, 0.0, 0.0), 2.0))
	var lives := LifeSystem.new(tuning)
	lives.set_checkpoint_store(SaveCheckpointStore.new(save))
	lives.open_world("coral_cove", graph)
	lives.activate_checkpoint("cp_reef")

	var collectibles := _system(SaveCollectibleStore.new(save), tuning)
	assert_bool(collectibles.collect("hermit_snail")).is_true()
	assert_bool(save.save_to_file(path)).is_true()
	var before := _read(path)
	assert_str(before).contains("hermit_snail")

	# An Array, not an int: a lambda captures a local primitive by value.
	var respawns: Array[String] = []
	lives.respawned.connect(
		func(_p: Vector3, checkpoint_id: String, _n: int) -> void:
			respawns.append(checkpoint_id))
	for _spend: int in range(lives.get_lives_per_attempt()):
		lives.report_catastrophe("pit_volume")
	assert_array(respawns).is_equal(["cp_reef"] as Array[String])

	assert_bool(collectibles.is_collected("hermit_snail")).override_failure_message(
		"REQ-010 AC-4: losing every life must not un-rescue a creature"
	).is_true()
	assert_int(collectibles.get_collected_count()).is_equal(1)
	# And the profile on disk already held it, so the respawn had nothing to
	# discard: the file is byte-identical across the whole setback.
	save.save_to_file(path)
	assert_str(_read(path)).override_failure_message(
		"REQ-010 AC-4: the save must be unchanged by the respawn, holding the collection"
	).is_equal(before)

	# A fresh session over that file still counts it.
	var reopened := SaveSystem.new()
	reopened.load_from_file(path, [] as Array[SaveError])
	reopened.open_world("coral_cove", _manifest())
	var later := _system(SaveCollectibleStore.new(reopened), tuning)
	assert_bool(later.is_collected("hermit_snail")).is_true()


# --- AC-5: a world declaring no collectibles stays valid and completable ----

func test_req_010_a_world_declaring_no_collectibles_is_inert_and_valid() -> void:
	var system := CollectiblesSystem.new(_tuning(), FakeStore.new())
	var errors: Array[CollectibleError] = []
	assert_bool(system.declare_from_manifest({}, errors)).is_true()
	assert_array(errors).is_empty()
	system.open_world("reference_template")

	assert_bool(system.is_engaged()).is_false()
	assert_int(system.get_discovery_total()).is_equal(0)
	# Nothing a finish condition could depend on exists...
	assert_bool(system.collect("anything")).is_false()
	# ...and the one finish kind that depends on this node can never fire
	# vacuously for it.
	assert_bool(system.all_collected()).override_failure_message(
		"REQ-010 AC-5: 'all collected' must never be true of nothing"
	).is_false()
	assert_bool(system.is_completable_by_collection()).is_false()


func test_req_010_the_reference_template_declares_none_and_conforms() -> void:
	# The contract's absent-default path is exercised by a REAL world: the
	# reference template declares no collectibles and passes the hub's own
	# contract validation. Its completability is the template walk's job.
	var manifest_text := _read("res://worlds/reference_template/world.json")
	var manifest: Variant = JSON.parse_string(manifest_text)
	assert_bool((manifest as Dictionary).has("collectibles")).is_false()

	var validator := ContractValidator.new()
	assert_bool(validator.is_ready()).is_true()
	var errors: Array[HubError] = []
	assert_bool(validator.validate_module(
		"res://worlds/reference_template", errors)).override_failure_message(
		"REQ-010 AC-5: a world with no collectibles must remain contract-valid: %s"
		% str(errors)).is_true()


func test_req_010_collect_all_completes_only_when_every_discovery_is_collected() -> void:
	var system := _system(FakeStore.new())
	var completed: Array[bool] = []
	system.collection_completed.connect(func() -> void: completed.append(true))

	system.collect("kelp_seed")  # a resource is not part of the set
	system.collect("hermit_snail")
	assert_bool(system.all_collected()).is_false()
	assert_array(completed).is_empty()

	system.collect("lantern_shrimp")
	assert_bool(system.all_collected()).is_true()
	assert_int(completed.size()).override_failure_message(
		"the completing pickup must announce completion exactly once").is_equal(1)

	system.collect("kelp_seed")
	assert_int(completed.size()).is_equal(1)


# --- AC-6: declared through the contract element, never scripted -----------

func test_req_010_a_malformed_declaration_is_refused_with_a_named_error() -> void:
	var tuning := _tuning()
	var cases: Array[Array] = [
		[{"collectibles": "pearls"}, CollectibleError.MALFORMED_DECLARATION],
		[{"collectibles": ["pearl"]}, CollectibleError.MALFORMED_DECLARATION],
		[{"collectibles": [{"kind": "discovery"}]}, CollectibleError.MISSING_FIELD],
		[{"collectibles": [{"collectibleId": "x", "kind": "trophy"}]},
			CollectibleError.UNKNOWN_KIND],
		[{"collectibles": [{"collectibleId": "x", "kind": "resource"}]},
			CollectibleError.MISSING_FIELD],
		[{"collectibles": [
			{"collectibleId": "x", "kind": "discovery"},
			{"collectibleId": "x", "kind": "discovery"}]},
			CollectibleError.DUPLICATE_ID],
		[{"collectibles": [
			{"collectibleId": "x", "kind": "resource", "regionId": "nowhere"}]},
			CollectibleError.UNKNOWN_REGION],
	]
	for row: Array in cases:
		var system := CollectiblesSystem.new(tuning, FakeStore.new())
		system.set_restoration(_restoration(tuning))
		var errors: Array[CollectibleError] = []
		assert_bool(system.declare_from_manifest(row[0] as Dictionary, errors)
			).override_failure_message(
				"expected %s to be refused" % String(row[1])).is_false()
		assert_int(errors.size()).is_greater(0)
		assert_str(errors[0].code).is_equal(String(row[1]))
		# Refused means EMPTY, never half-declared.
		assert_bool(system.is_engaged()).is_false()


func test_req_010_the_kind_set_is_closed_and_exact() -> void:
	assert_array(Array(CollectibleKind.all_ids())).is_equal(["resource", "discovery"])
	assert_bool(CollectibleKind.is_known_id("resources")).is_false()
	assert_bool(CollectibleKind.is_known_id("Discovery")).is_false()
	assert_int(CollectibleKind.from_id("discovery")).is_equal(
		int(CollectibleKind.Kind.DISCOVERY))


func test_req_010_the_contract_declares_collectibles_as_an_optional_element_with_shape() -> void:
	var contract: Variant = JSON.parse_string(_read(CONTRACT_PATH))
	var element := ((contract as Dictionary)["optional"] as Dictionary)["collectibles"] as Dictionary
	assert_str(String(element.get("manifestField", ""))).is_equal("collectibles")
	assert_str(String(element.get("absentDefault", ""))).is_not_empty()
	# The present-shape is written down, so the first world to declare one
	# does not freeze this node's internals as the contract by accident.
	assert_bool(element.has("entryShape")).is_true()
	var kinds := (element["entryShape"] as Dictionary)["kinds"] as Dictionary
	for kind_id: String in CollectibleKind.all_ids():
		assert_bool(kinds.has(kind_id)).override_failure_message(
			"the contract must document collectible kind '%s'" % kind_id).is_true()
	var rules := element.get("rules", []) as Array
	assert_int(rules.size()).is_greater(0)
	assert_str(String((rules[0] as Dictionary)["kind"])).is_equal("manifest_field_type")


func test_req_010_official_worlds_declare_collectibles_and_place_them_without_scripts() -> void:
	# The world side of AC-6, checked against the shipped worlds: every scene
	# node in the `collectible` group names a collectible the manifest
	# declares, each discovery is placed exactly once, and the module ships
	# no script at all — declaration and placement are the whole of it.
	var declared_any := false
	for module: String in OFFICIAL_WORLDS:
		var manifest := JSON.parse_string(_read(module.path_join("world.json"))) as Dictionary
		if not manifest.has("collectibles"):
			continue
		declared_any = true
		var system := CollectiblesSystem.new(_tuning(), FakeStore.new())
		var errors: Array[CollectibleError] = []
		assert_bool(system.declare_from_manifest(manifest, errors)).override_failure_message(
			"%s declares malformed collectibles: %s" % [module, str(errors)]).is_true()

		var placed := _placed_collectible_ids(module.path_join("world.tscn"))
		assert_int(placed.size()).is_greater(0)
		for id: String in placed:
			assert_bool(system.has_collectible(id)).override_failure_message(
				"%s places collectible '%s' that its manifest never declares"
				% [module, id]).is_true()
		for id: String in system.get_discovery_ids():
			assert_int(placed.count(id)).override_failure_message(
				"%s must place discovery '%s' exactly once (found %d)"
				% [module, id, placed.count(id)]).is_equal(1)

		var dir := DirAccess.open(module)
		for entry: String in dir.get_files():
			assert_bool(entry.ends_with(".gd")).override_failure_message(
				"%s ships a script (%s); collectibles must need none" % [module, entry]
			).is_false()
	assert_bool(declared_any).override_failure_message(
		"at least one official world must exercise the collectibles element").is_true()


## Reads `collectible_id` metadata of every `collectible`-group node from the
## scene FILE, the way the checker counts groups — never by instancing.
func _placed_collectible_ids(scene_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var in_collectible := false
	var meta := RegEx.create_from_string("^metadata/collectible_id\\s*=\\s*\"([^\"]*)\"")
	for line: String in _read(scene_path).split("\n"):
		if line.begins_with("[node "):
			in_collectible = line.contains("\"collectible\"")
			continue
		if in_collectible:
			var found := meta.search(line)
			if found != null:
				out.append(found.get_string(1))
	return out


func test_req_010_removing_a_declared_discovery_is_a_destructive_save_change() -> void:
	# The save-compatibility shape reads discovery ids straight from the
	# manifest declaration, so a fork that drops a creature the profile
	# recorded as rescued is classified destructive (and quarantined by the
	# policy) rather than silently losing the record. Dropping a RESOURCE
	# type is not destructive: nothing in the profile ever referred to it.
	var stored := WorldContractShape.from_dictionary(_manifest())
	assert_array(Array(stored.collectibles)).is_equal(["hermit_snail", "lantern_shrimp"])

	var without_shrimp := _manifest()
	(without_shrimp["collectibles"] as Array).remove_at(2)
	assert_int(stored.classify(WorldContractShape.from_dictionary(without_shrimp))
		).is_equal(WorldContractShape.Change.DESTRUCTIVE)

	var without_seeds := _manifest()
	(without_seeds["collectibles"] as Array).remove_at(0)
	assert_int(stored.classify(WorldContractShape.from_dictionary(without_seeds))
		).is_equal(WorldContractShape.Change.NONE)


# --- REQ-030: no multiplayer surface in this node --------------------------

func test_req_030_collectibles_node_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in COLLECTIBLE_SOURCES:
		var text := _read(path)
		assert_str(text).is_not_empty()
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'" % [path, symbol]
			).is_false()
