extends GdUnitTestSuite

## Open Lagoon hub — world discovery, validation and portals (REQ-009).
##
## Test names carry the requirement id they prove (test_req_009_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).
##
## AC-3 ("adding, removing, or replacing a world module changes the available
## portals without any edit to hub code") is proven by DOING it: these tests
## create, delete and rewrite modules in a scratch directory and rescan with
## the identical registry code every time. A test that merely read the hub's
## source for the absence of a list would miss a list hidden in data.

const SCRATCH := "user://hub_test_worlds"

const HUB_SOURCES: PackedStringArray = [
	"res://hub/hub_error.gd",
	"res://hub/portal_tier.gd",
	"res://hub/contract_validator.gd",
	"res://hub/world_portal.gd",
	"res://hub/world_registry.gd",
	"res://hub/world_loader.gd",
	"res://hub/open_lagoon.gd",
]

const CONFORMING_SCENE := """
[gd_scene format=3]

[node name=\"World\" type=\"Node3D\"]

[node name=\"Spawn\" type=\"Marker3D\" parent=\".\" groups=[\"spawn_point\"]]

[node name=\"Checkpoint\" type=\"Area3D\" parent=\".\" groups=[\"checkpoint\"]]

[node name=\"Finish\" type=\"Area3D\" parent=\".\" groups=[\"finish_volume\"]]
"""


func before_test() -> void:
	_remove_scratch()
	DirAccess.make_dir_recursive_absolute(SCRATCH)


func after_test() -> void:
	_remove_scratch()


func _remove_scratch() -> void:
	var dir := DirAccess.open(SCRATCH)
	if dir == null:
		return
	for name: String in dir.get_directories():
		var module := DirAccess.open(SCRATCH.path_join(name))
		for file: String in module.get_files():
			module.remove(file)
		dir.remove(name)
	DirAccess.remove_absolute(SCRATCH)


func _manifest_for(world_id: String, extra: Dictionary = {}) -> Dictionary:
	var manifest := {
		"contractVersion": "1.0",
		"worldId": world_id,
		"displayName": world_id.capitalize(),
		"controllerCompatibility": "1.0",
		"finishCondition": {"kind": "reach_volume"},
		"saveIntegration": {"keys": ["%s.completed" % world_id]},
	}
	for key: Variant in extra:
		manifest[key] = extra[key]
	return manifest


func _install(world_id: String, extra: Dictionary = {},
		manifest_text: String = "") -> void:
	var module := SCRATCH.path_join(world_id)
	DirAccess.make_dir_recursive_absolute(module)
	var manifest := FileAccess.open(module.path_join("world.json"), FileAccess.WRITE)
	manifest.store_string(manifest_text if not manifest_text.is_empty()
		else JSON.stringify(_manifest_for(world_id, extra), "  "))
	manifest.close()
	var scene := FileAccess.open(module.path_join("world.tscn"), FileAccess.WRITE)
	scene.store_string(CONFORMING_SCENE)
	scene.close()


func _uninstall(world_id: String) -> void:
	var module := DirAccess.open(SCRATCH.path_join(world_id))
	for file: String in module.get_files():
		module.remove(file)
	DirAccess.open(SCRATCH).remove(world_id)


func _registry() -> WorldRegistry:
	return WorldRegistry.new(SCRATCH)


func _read(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()
	return text


# --- AC-1: discovery, and no world list anywhere in hub code ---------------

func test_req_009_the_installed_worlds_are_discovered_from_the_directory() -> void:
	var registry := WorldRegistry.new()  # the real res://worlds
	var portals := registry.discover()
	assert_int(portals.size()).is_greater(0)

	var available := registry.get_available()
	assert_int(available.size()).override_failure_message(
		"the shipped reference template must come up as an available portal"
	).is_greater(0)


func test_req_009_no_world_id_is_hardcoded_anywhere_in_hub_code() -> void:
	# Including no special case for the reference template: the template rides
	# the identical path, which is what proves the path is generic.
	var known_ids: PackedStringArray = [
		"reference_template", "coral_cove", "bubble_bay",
	]
	for path: String in HUB_SOURCES + PackedStringArray(["res://hub/open_lagoon.tscn"]):
		var text := _read(path)
		for world_id: String in known_ids:
			assert_bool(text.contains(world_id)).override_failure_message(
				"REQ-009 AC-1: '%s' names world '%s'; the hub must know no world"
				% [path, world_id]
			).is_false()

	# Anti-vacuity: the id list is real — one of them is actually installed.
	assert_bool(DirAccess.dir_exists_absolute(
		"res://worlds/reference_template")).is_true()


# --- AC-3: add, remove, replace — no hub edit ------------------------------

func test_req_009_adding_a_module_adds_a_portal_on_rescan() -> void:
	var registry := _registry()
	assert_int(registry.discover().size()).is_equal(0)

	_install("kelp_hollow")
	var portals := registry.discover()

	assert_int(portals.size()).is_equal(1)
	assert_str(portals[0].world_id).is_equal("kelp_hollow")
	assert_bool(portals[0].available).is_true()


func test_req_009_removing_a_module_removes_its_portal_on_rescan() -> void:
	_install("kelp_hollow")
	_install("brine_garden")
	var registry := _registry()
	assert_int(registry.discover().size()).is_equal(2)

	_uninstall("kelp_hollow")

	var remaining := registry.discover()
	assert_int(remaining.size()).is_equal(1)
	assert_str(remaining[0].world_id).is_equal("brine_garden")


func test_req_009_replacing_a_module_changes_its_portal_on_rescan() -> void:
	_install("kelp_hollow")
	var registry := _registry()
	registry.discover()
	assert_str(registry.get_portal("kelp_hollow").display_name).is_equal(
		"Kelp Hollow")

	# A fork replacing the module wholesale — same id, new declaration.
	_install("kelp_hollow", {"displayName": "Kelp Hollow: Reforged"})
	registry.discover()

	assert_str(registry.get_portal("kelp_hollow").display_name).is_equal(
		"Kelp Hollow: Reforged")


# --- AC-4: a broken module is surfaced, never fatal ------------------------

func test_req_009_a_malformed_manifest_becomes_an_unavailable_portal() -> void:
	_install("good_world")
	_install("broken_world", {}, "{this is not json")

	var registry := _registry()
	var portals := registry.discover()

	assert_int(portals.size()).override_failure_message(
		"a broken module must still be SHOWN, never silently dropped"
	).is_equal(2)

	var broken := portals[0] if portals[0].world_id != "good_world" else portals[1]
	assert_bool(broken.available).is_false()
	var codes := PackedStringArray()
	for failure: HubError in broken.failures:
		codes.append(failure.code)
	assert_bool(codes.has(HubError.MALFORMED_MANIFEST)).is_true()

	# And the neighbour is untouched: one bad module never blocks the hub.
	assert_bool(registry.get_portal("good_world").available).is_true()


func test_req_009_a_contract_violation_is_named_on_the_portal() -> void:
	_install("no_checkpoints")
	# Strip the checkpoint from the scene after install.
	var module := SCRATCH.path_join("no_checkpoints")
	var scene := FileAccess.open(module.path_join("world.tscn"), FileAccess.WRITE)
	scene.store_string(CONFORMING_SCENE.replace(
		'groups=[\"checkpoint\"]', 'groups=[\"decor\"]'))
	scene.close()

	var registry := _registry()
	registry.discover()
	var portal := registry.get_portals()[0]

	assert_bool(portal.available).is_false()
	assert_str(portal.failure_summary()).override_failure_message(
		"the failure must name the violated element so an author can fix it"
	).contains("checkpoints.scene_group_count")


func test_req_009_an_unsupported_contract_version_is_refused_by_the_hub() -> void:
	_install("from_the_future", {"contractVersion": "9.9"})

	var registry := _registry()
	registry.discover()
	var portal := registry.get_portals()[0]

	assert_bool(portal.available).override_failure_message(
		"a world targeting an unsupported contract version is refused and "
		+ "surfaced as unavailable, never loaded partially"
	).is_false()
	assert_str(portal.failure_summary()).contains("contractVersion")


func test_req_009_an_unknown_rule_kind_refuses_the_module_by_name() -> void:
	# A contract newer than the hub must fail CLOSED: refusing the module with
	# the gap named beats loading a world a rule was supposed to screen.
	var schema_path := SCRATCH.path_join("tightened_contract.json")
	var parsed: Variant = JSON.parse_string(
		_read("res://contracts/level_contract.v1.json"))
	var schema := parsed as Dictionary
	(schema["required"] as Dictionary)["futureElement"] = {
		"rules": [{"kind": "holographic_seal_check"}],
	}
	var handle := FileAccess.open(schema_path, FileAccess.WRITE)
	handle.store_string(JSON.stringify(schema))
	handle.close()

	_install("kelp_hollow")
	var registry := WorldRegistry.new(SCRATCH, ContractValidator.new(schema_path))
	registry.discover()
	var portal := registry.get_portals()[0]

	assert_bool(portal.available).is_false()
	var codes := PackedStringArray()
	for failure: HubError in portal.failures:
		codes.append(failure.code)
	assert_bool(codes.has(HubError.UNKNOWN_RULE_KIND)).is_true()


# --- AC-5: portal tiers, distinguished by more than colour ------------------

func test_req_009_tier_comes_from_the_manifest_with_official_as_default() -> void:
	_install("plain_world")
	_install("shared_world", {"tier": "community"})
	_install("wild_world", {"tier": "experimental"})

	var registry := _registry()
	registry.discover()

	assert_int(int(registry.get_portal("plain_world").tier)).is_equal(
		PortalTier.Tier.OFFICIAL)
	assert_int(int(registry.get_portal("shared_world").tier)).is_equal(
		PortalTier.Tier.COMMUNITY)
	assert_int(int(registry.get_portal("wild_world").tier)).is_equal(
		PortalTier.Tier.EXPERIMENTAL)


func test_req_009_an_unknown_tier_is_an_error_not_a_silent_default() -> void:
	# "expermental" quietly becoming an official portal is exactly the drift a
	# closed set exists to stop.
	_install("typo_world", {"tier": "expermental"})

	var registry := _registry()
	registry.discover()
	var portal := registry.get_portals()[0]

	assert_bool(portal.available).is_false()
	var codes := PackedStringArray()
	for failure: HubError in portal.failures:
		codes.append(failure.code)
	assert_bool(codes.has(HubError.UNKNOWN_TIER)).is_true()


func test_req_009_the_three_tiers_are_distinct_on_every_channel() -> void:
	# Shape, label AND colour — REQ-019 forbids colour-only encoding, so the
	# non-colour channels must discriminate on their own.
	var shapes := PackedStringArray()
	var labels := PackedStringArray()
	var colors: Array[Color] = []
	for tier: PortalTier.Tier in PortalTier.ALL:
		assert_bool(shapes.has(PortalTier.shape_id(tier))).is_false()
		assert_bool(labels.has(PortalTier.label(tier))).is_false()
		assert_bool(colors.has(PortalTier.color(tier))).is_false()
		shapes.append(PortalTier.shape_id(tier))
		labels.append(PortalTier.label(tier))
		colors.append(PortalTier.color(tier))
	assert_int(shapes.size()).is_equal(3)


func test_req_009_the_portal_label_carries_tier_and_availability_in_text() -> void:
	_install("shared_world", {"tier": "community"})
	_install("broken_world", {}, "{not json")
	var registry := _registry()
	registry.discover()

	assert_str(registry.get_portal("shared_world").portal_label()).contains(
		"Community Lagoon")
	# The unavailable portal's state is in TEXT, not only in its dimmed colour.
	for portal: WorldPortal in registry.get_unavailable():
		assert_str(portal.portal_label()).contains("(unavailable)")


# --- AC-6: progress through the save-integration interface ------------------

func test_req_009_completion_and_restoration_progress_come_from_the_save() -> void:
	_install("kelp_hollow")
	var registry := _registry()
	registry.discover()

	var save := SaveSystem.new()
	save.open_world("kelp_hollow", _manifest_for("kelp_hollow"))
	save.put_world_data("kelp_hollow", {
		"completed": true,
		"regions": {
			"shallows": {"state": "restored", "unlocked": true},
			"depths": {"state": "barren", "unlocked": true},
		},
	})

	registry.apply_progress(save)
	var portal := registry.get_portal("kelp_hollow")

	assert_bool(portal.completed).is_true()
	assert_int(portal.regions_restored).is_equal(1)
	assert_int(portal.regions_total).is_equal(2)


func test_req_009_a_world_never_visited_reads_as_unvisited_not_as_an_error() -> void:
	_install("kelp_hollow")
	var registry := _registry()
	registry.discover()

	registry.apply_progress(SaveSystem.new())

	var portal := registry.get_portal("kelp_hollow")
	assert_bool(portal.completed).is_false()
	assert_int(portal.regions_total).is_equal(0)


func test_req_009_the_hub_never_opens_the_save_file_itself() -> void:
	# The hub reads through the Save Integration Interface; the save FORMAT is
	# the Save System's private business. A hub that parsed the file would
	# quietly become a second implementation of the save format.
	for path: String in HUB_SOURCES:
		var text := _read(path)
		for symbol: String in ["load_from_file", "save_to_file", "user://"]:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-009 AC-6: '%s' touches the save file via '%s'"
				% [path, symbol]
			).is_false()


# --- The validator agrees with the merge gate --------------------------------

func test_req_009_the_runtime_validator_accepts_the_shipped_template() -> void:
	# Two engines, one data file: what the Python checker merged, the hub must
	# load. Divergence here means a world passes CI and then fails at runtime,
	# which is the worst place to find out.
	var validator := ContractValidator.new()
	var errors: Array[HubError] = []
	assert_bool(validator.validate_module(
		"res://worlds/reference_template", errors)
	).override_failure_message(
		"the shipped template must validate at runtime: "
		+ str(errors.map(func(e: HubError) -> String: return e.to_string_id()))
	).is_true()


func test_req_009_the_runtime_validator_rejects_what_the_checker_rejects() -> void:
	# Spot parity on the fixture corpus the Python checker's own tests use.
	var validator := ContractValidator.new()
	for fixture: String in ["missing_checkpoint", "two_spawn_points",
			"bad_world_id", "stray_project_file"]:
		var errors: Array[HubError] = []
		assert_bool(validator.validate_module(
			"res://fixtures/worlds/%s" % fixture, errors)
		).override_failure_message(
			"'%s' must fail runtime validation as it fails the merge gate"
			% fixture
		).is_false()


func test_req_030_hub_uses_no_multiplayer_api() -> void:
	var forbidden: PackedStringArray = [
		"@rpc", "rpc_id", "rpc_config", "MultiplayerAPI",
		"MultiplayerSynchronizer", "MultiplayerSpawner", "is_multiplayer_authority",
	]
	for path: String in HUB_SOURCES:
		var text := _read(path)
		for symbol: String in forbidden:
			assert_bool(text.contains(symbol)).override_failure_message(
				"REQ-030: '%s' contains forbidden multiplayer symbol '%s'"
				% [path, symbol]
			).is_false()
