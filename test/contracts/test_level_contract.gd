extends GdUnitTestSuite

## Level Contract v1 — REQ-006.
##
## Test names carry the requirement id they prove (test_req_006_...) so the
## runner reports it as the failing rule (REQ-026 AC-6).
##
## What this suite can and cannot prove is worth stating plainly. The contract's
## claim is that conformance rules live in DATA and no checker hardcodes them.
## The checker itself is REQ-007 and does not exist yet, so these tests verify
## the schema is complete, self-consistent, and expressed in terms a checker
## could execute — not that a checker executes them. AC-1's second half stays
## unproven until REQ-007 lands, and is reported skipped rather than claimed.

const CONTRACT_PATH := "res://contracts/level_contract.v1.json"
const SANCTIONED_PATH := "res://contracts/sanctioned_api.v1.json"
const MODEL_PATH := "res://.nodespec/model.json"
const TUNING_PATH := "res://core/tuning/tuning.json"

## The five required elements REQ-006 names in its own text. Listed here so the
## schema is checked against the REQUIREMENT rather than against itself — a
## schema that dropped an element would otherwise still agree with itself.
const REQUIRED_BY_REQUIREMENT: PackedStringArray = [
	"spawnPoint", "checkpoints", "finishCondition",
	"controllerCompatibility", "saveIntegration",
]

## The optional elements REQ-006 names.
const OPTIONAL_BY_REQUIREMENT: PackedStringArray = [
	"collectibles", "enemies", "boss", "customAbility", "secretAreas", "npcs",
	"livesPerAttemptOverride",
]


func _load(path: String) -> Dictionary:
	var handle := FileAccess.open(path, FileAccess.READ)
	assert_object(handle).override_failure_message(
		"cannot open '%s'" % path).is_not_null()
	var text := handle.get_as_text()
	handle.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_bool(parsed is Dictionary).override_failure_message(
		"'%s' is not a JSON object" % path).is_true()
	return parsed as Dictionary


func _contract() -> Dictionary:
	return _load(CONTRACT_PATH)


func _sanctioned() -> Dictionary:
	return _load(SANCTIONED_PATH)


## Every rule anywhere in the contract, flattened.
func _all_rules(contract: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for section: String in ["required", "optional"]:
		for element: String in (contract[section] as Dictionary):
			var body: Dictionary = (contract[section] as Dictionary)[element]
			for rule: Variant in (body.get("rules", []) as Array):
				out.append(rule as Dictionary)
	for rule: Variant in ((contract["moduleLayout"] as Dictionary).get(
			"rules", []) as Array):
		out.append(rule as Dictionary)
	return out


# --- AC-1: published as a machine-readable schema file ----------------------

func test_req_006_the_contract_is_a_machine_readable_file() -> void:
	# The half of AC-1 that is provable today: the contract parses as data and
	# declares itself the authority. The other half — that the checker loads it
	# and hardcodes nothing — needs REQ-007 and is reported skipped.
	var contract := _contract()
	assert_str(String(contract["contractVersion"])).is_not_empty()
	assert_str(String(contract["sourceOfTruth"])).contains("hardcodes no")
	assert_dict(contract["ruleKinds"] as Dictionary).is_not_empty()


# --- AC-2: every required element carries a machine-checkable rule ----------

func test_req_006_every_required_element_has_a_checkable_rule() -> void:
	var contract := _contract()
	var required: Dictionary = contract["required"]
	var kinds: Dictionary = contract["ruleKinds"]

	for element: String in REQUIRED_BY_REQUIREMENT:
		assert_bool(required.has(element)).override_failure_message(
			"REQ-006 AC-2: required element '%s' is missing from the schema"
			% element).is_true()

		var rules: Array = (required[element] as Dictionary).get("rules", [])
		assert_int(rules.size()).override_failure_message(
			"REQ-006 AC-2: '%s' is declared but carries no conformance rule, "
			% element + "so a checker could not test it").is_greater_equal(1)

		for rule: Variant in rules:
			var kind := String((rule as Dictionary)["kind"])
			assert_bool(kinds.has(kind)).override_failure_message(
				"'%s' cites rule kind '%s', which no checker implements"
				% [element, kind]).is_true()


func test_req_006_a_rule_citing_an_unknown_kind_would_be_caught() -> void:
	# Anti-vacuity for the check above: prove the kind lookup bites rather than
	# always finding the kind present.
	var kinds: Dictionary = _contract()["ruleKinds"]
	assert_bool(kinds.has("manifest_field_present")).is_true()
	assert_bool(kinds.has("vibes_based_inspection")).override_failure_message(
		"the rule-kind check must reject a kind the schema does not define"
	).is_false()


func test_req_006_every_rule_kind_declares_its_arguments() -> void:
	# A kind without declared arguments is not implementable from the file
	# alone, which would push the detail back into the checker.
	var kinds: Dictionary = _contract()["ruleKinds"]
	for kind: String in kinds:
		var body: Dictionary = kinds[kind]
		assert_int((body["arguments"] as Array).size()).override_failure_message(
			"rule kind '%s' declares no arguments" % kind).is_greater_equal(1)
		assert_str(String(body["description"])).is_not_empty()


func test_req_006_every_rule_supplies_the_arguments_its_kind_declares() -> void:
	# The schema must be internally executable: a rule missing an argument its
	# kind requires would fail at check time rather than at authoring time.
	var contract := _contract()
	var kinds: Dictionary = contract["ruleKinds"]

	var checked := 0
	for rule: Dictionary in _all_rules(contract):
		var kind := String(rule["kind"])
		for argument: Variant in (kinds[kind] as Dictionary)["arguments"]:
			var name := String(argument)
			# `max` is documented as omittable for an unbounded count.
			if kind == "scene_group_count" and name == "max":
				continue
			assert_bool(rule.has(name)).override_failure_message(
				"a '%s' rule is missing its '%s' argument" % [kind, name]
			).is_true()
		checked += 1

	assert_int(checked).override_failure_message(
		"no rules were examined, so this would pass vacuously"
	).is_greater_equal(10)


# --- AC-3: every optional element declares its absent default ---------------

func test_req_006_every_optional_element_declares_a_default() -> void:
	var optional: Dictionary = _contract()["optional"]

	for element: String in OPTIONAL_BY_REQUIREMENT:
		assert_bool(optional.has(element)).override_failure_message(
			"REQ-006 AC-3: optional element '%s' is missing from the schema"
			% element).is_true()

	for element: String in optional:
		var declared := String((optional[element] as Dictionary).get(
			"absentDefault", ""))
		assert_str(declared).override_failure_message(
			"REQ-006 AC-3: optional element '%s' declares no absentDefault, "
			% element + "so its behaviour when omitted is undefined"
		).is_not_empty()


func test_req_006_no_element_is_both_required_and_optional() -> void:
	var contract := _contract()
	var required: Dictionary = contract["required"]
	for element: String in (contract["optional"] as Dictionary):
		assert_bool(required.has(element)).override_failure_message(
			"'%s' is declared both required and optional" % element).is_false()


# --- AC-4: explicit version identifier, declared by every world -------------

func test_req_006_the_contract_and_every_world_carry_a_version() -> void:
	var contract := _contract()
	assert_str(String(contract["contractVersion"])).is_equal("1.0")

	# The world-facing half: a world must DECLARE the version it targets, and
	# that declaration is itself a required element with a rule.
	var required: Dictionary = contract["required"]
	assert_bool(required.has("contractVersion")).override_failure_message(
		"REQ-006 AC-4: worlds must declare the contract version they target"
	).is_true()

	var accepted: Array = []
	for rule: Variant in (required["contractVersion"] as Dictionary)["rules"]:
		var body: Dictionary = rule
		if String(body["kind"]) == "manifest_field_in_set":
			accepted = body["values"] as Array
	assert_array(accepted).override_failure_message(
		"the accepted version set must be closed, so an unsupported world is "
		+ "refused rather than loaded hopefully").is_equal(["1.0"] as Array)

	# And the version must be a closed set at the contract level too, with a
	# stated policy for what happens when a world targets something else.
	assert_str(String((contract["versioning"] as Dictionary)["compatibility"])
		).contains("refused")


# --- AC-5: module layout and naming convention ------------------------------

func test_req_006_the_module_layout_is_defined() -> void:
	var layout: Dictionary = _contract()["moduleLayout"]

	assert_str(String(layout["root"])).is_equal("worlds/<world_id>/")
	assert_str(String((layout["files"] as Dictionary)["manifest"]["name"])
		).is_equal("world.json")
	assert_str(String((layout["files"] as Dictionary)["scene"]["name"])
		).is_equal("world.tscn")
	assert_int((layout["rules"] as Array).size()).is_greater_equal(2)


func test_req_006_the_world_id_convention_accepts_and_rejects() -> void:
	# A naming convention nothing is tested against is a suggestion. Prove the
	# published pattern actually admits legal ids and refuses illegal ones.
	var pattern := String((_contract()["moduleLayout"] as Dictionary)["worldIdPattern"])
	var regex := RegEx.new()
	assert_int(regex.compile(pattern)).override_failure_message(
		"the published worldIdPattern must be a valid regular expression"
	).is_equal(OK)

	for legal: String in ["coral_cove", "bubble_bay", "ref", "a_world_2"]:
		assert_object(regex.search(legal)).override_failure_message(
			"'%s' should be a legal world id" % legal).is_not_null()

	for illegal: String in ["Coral Cove", "coral-cove", "1cove", "_cove", "ab",
			"CoralCove", "coral.cove", ""]:
		assert_object(regex.search(illegal)).override_failure_message(
			"'%s' must be rejected as a world id" % illegal).is_null()


# --- AC-6: the sanctioned world API surface ---------------------------------

## The set of contract names on edges leaving a world node — the architecture's
## own answer to "what may a world call".
func _derive_world_interfaces() -> Array[String]:
	var model := _load(MODEL_PATH)

	var world_nodes := {}
	for entry: Variant in (model["nodes"] as Array):
		var node: Dictionary = entry
		if String(node["label"]).begins_with("World:"):
			world_nodes[String(node["id"])] = true

	var contract_names := {}
	for entry: Variant in (model["contracts"] as Array):
		var contract: Dictionary = entry
		contract_names[String(contract["id"])] = String(contract["name"])

	var derived := {}
	for entry: Variant in (model["edges"] as Array):
		var edge: Dictionary = entry
		if world_nodes.has(String(edge["source"])):
			derived[contract_names[String(edge["contractId"])]] = true

	var out: Array[String] = []
	for name: String in derived:
		out.append(name)
	out.sort()
	return out


func test_req_006_the_sanctioned_surface_matches_the_architecture() -> void:
	# THE anti-drift test. The allowlist is derived from the graph, never
	# authored, so widening it by hand fails here rather than silently granting
	# a world reach the architecture never gave it.
	var derived := _derive_world_interfaces()
	assert_int(derived.size()).override_failure_message(
		"no world-outbound edges were found, so this would pass vacuously"
	).is_greater_equal(5)

	var declared: Array[String] = []
	for entry: Variant in (_sanctioned()["allowedInterfaces"] as Array):
		declared.append(String((entry as Dictionary)["contract"]))
	declared.sort()

	assert_array(declared).override_failure_message(
		"REQ-006 AC-6: the allowlist and the architecture disagree.\n"
		+ "  graph says: %s\n  file says:  %s" % [
			", ".join(derived), ", ".join(declared)]
	).is_equal(derived)


func test_req_006_excluded_interfaces_are_named_with_a_reason() -> void:
	# An allowlist that merely omits something teaches nothing. Every interface
	# a contributor might reasonably expect must be listed as excluded, with the
	# reason and the thing to do instead.
	var sanctioned := _sanctioned()
	var allowed := {}
	for entry: Variant in (sanctioned["allowedInterfaces"] as Array):
		allowed[String((entry as Dictionary)["contract"])] = true

	var excluded := {}
	for entry: Variant in (sanctioned["deliberatelyExcluded"] as Array):
		var body: Dictionary = entry
		var name := String(body["contract"])
		excluded[name] = true
		assert_str(String(body["why"])).is_not_empty()
		assert_str(String(body["instead"])).is_not_empty()
		assert_bool(allowed.has(name)).override_failure_message(
			"'%s' is listed as both allowed and excluded" % name).is_false()

	for expected: String in ["Player Input Interface",
			"Axolotl Controller Interface", "Tuning Data Interface"]:
		assert_bool(excluded.has(expected)).override_failure_message(
			"'%s' is a surface a contributor would reach for; it must be "
			% expected + "explicitly excluded rather than merely absent"
		).is_true()


func test_req_006_the_surface_forbids_raw_input_and_multiplayer() -> void:
	# Two bans this file must carry because other requirements rest on it:
	# REQ-024 AC-6 (worlds never read raw input) and REQ-030 AC-7 (the world
	# API surface lists every multiplayer API as forbidden).
	var classes: Dictionary = _sanctioned()["forbiddenCallClasses"]

	assert_bool(classes.has("rawInput")).override_failure_message(
		"REQ-024 AC-6 rests on worlds being unable to read input"
	).is_true()
	assert_array(classes["rawInput"]["symbols"] as Array).contains(["Input"])

	assert_bool(classes.has("multiplayer")).override_failure_message(
		"REQ-030 AC-7 requires the world API surface to list every "
		+ "multiplayer API as forbidden").is_true()
	var apis: Dictionary = classes["multiplayer"]["symbols"]
	assert_array(apis["annotations"] as Array).contains(["@rpc"])
	assert_array(apis["nodes"] as Array).contains(
		["MultiplayerSynchronizer", "MultiplayerSpawner"])


# --- Cross-file consistency --------------------------------------------------

func test_req_006_tuning_overrides_reference_the_tuning_surface() -> void:
	# The contract must not keep a second copy of the overridable set. It cites
	# the tuning file, and the citation must resolve.
	var optional: Dictionary = _contract()["optional"]
	var rules: Array = (optional["tuningOverrides"] as Dictionary)["rules"]

	var reference := ""
	for rule: Variant in rules:
		var body: Dictionary = rule
		if String(body["kind"]) == "manifest_keys_subset_of":
			reference = String(body["allowedFrom"])
	assert_str(reference).is_equal("core/tuning/tuning.json#worldOverridable")

	# And the cited location actually holds a non-empty list.
	var tuning := _load(TUNING_PATH)
	assert_array(tuning["worldOverridable"] as Array).override_failure_message(
		"the contract cites worldOverridable, which must exist and be non-empty"
	).is_not_empty()


func test_req_006_the_finish_condition_kinds_are_a_closed_set() -> void:
	# An open-ended completion kind would put completion logic back into world
	# script, which is the one thing the hub must be able to trust.
	var finish: Dictionary = (_contract()["required"] as Dictionary)["finishCondition"]

	var values: Array = []
	for rule: Variant in (finish["rules"] as Array):
		var body: Dictionary = rule
		if String(body["kind"]) == "manifest_field_in_set" \
				and String(body["field"]) == "finishCondition.kind":
			values = body["values"] as Array

	assert_array(values).is_not_empty()
	assert_array(values).not_contains(["custom"])

	# Every accepted kind must be documented, or a contributor cannot pick one.
	var documented: Dictionary = finish["kinds"]
	for kind: Variant in values:
		assert_bool(documented.has(String(kind))).override_failure_message(
			"finish condition kind '%s' is accepted but undocumented" % kind
		).is_true()


func test_req_006_the_contract_forbids_an_editor_authoring_path() -> void:
	# A firm non-goal, and one the contract surface depends on: no editor GUI
	# means the checkable surface is code and scenes only.
	assert_str(String(_contract()["authoringPath"])).contains(
		"no editor GUI authoring path")
