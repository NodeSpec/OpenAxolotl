extends GdUnitTestSuite

## The test harness checking itself — REQ-026.
##
## This exists because the same bug bit twice. The assertion shim implements a
## subset of GdUnit4's API; when a suite calls a method the shim lacks, GDScript
## resolves it at RUNTIME (override_failure_message returns Variant), raises a
## script error, ABORTS the test function on the spot, and the runner sees an
## empty failure list and prints PASS. A test that never ran reports success,
## which is worse than having no test.
##
## Two guards already exist and neither is sufficient alone:
##
##   * The runner fails any test that evaluated ZERO assertions. That catches an
##     abort before the first assertion, but not one after — and a suite whose
##     helper asserts first (a tuning loader that checks for load errors, say)
##     has already scored one by the time the bad call lands. That is exactly how
##     the second occurrence slipped through.
##   * Running the suite and grepping the log for SCRIPT ERROR catches everything,
##     but only if someone looks.
##
## So this test closes the hole at the source: it reads every suite's code,
## extracts the assertion methods actually called on each assert_* entry point,
## and asserts the shim implements them. A missing method now fails as a normal
## red test naming the gap, before it can silently swallow a suite.
##
## TO REMOVE with the shim: once addons/gdUnit4 is vendored, the real library
## defines these and this file goes with gdunit_compat.gd.

const TEST_ROOT := "res://test"

## The chain shapes the suites actually use. A terminal assertion returns void,
## so a chain is at most `entry(...).method(...)` or
## `entry(...).override_failure_message(...).method(...)`.
const CHAIN_LIMIT := 2
const MESSAGE_HOOK := "override_failure_message"


func _entry_probes() -> Dictionary:
	# One live instance per entry point, so membership is checked by reflection
	# against the real class rather than against a list that could drift.
	# Constructing an assert object records nothing; only _check does.
	return {
		"assert_str": assert_str(""),
		"assert_int": assert_int(0),
		"assert_bool": assert_bool(true),
		"assert_float": assert_float(0.0),
		"assert_array": assert_array([]),
		"assert_dict": assert_dict({}),
		"assert_object": assert_object(null),
	}


func _suite_paths(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return found

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := root.path_join(entry)
		if dir.current_is_dir():
			if entry != "support":
				found.append_array(_suite_paths(path))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


## Source with line breaks collapsed, so a chain wrapped across lines reads as
## one statement.
func _flattened(path: String) -> String:
	var handle := FileAccess.open(path, FileAccess.READ)
	var text := handle.get_as_text()
	handle.close()

	var out := ""
	for line: String in text.split("\n"):
		out += line.strip_edges() + " "
	return out


## Index just past the ')' matching the '(' at [param open_at]; -1 when the
## parens do not balance, in which case the caller skips this occurrence rather
## than inventing a method name from the wreckage.
func _match_paren(text: String, open_at: int) -> int:
	var depth := 0
	var index := open_at
	while index < text.length():
		var character := text[index]
		if character == "(":
			depth += 1
		elif character == ")":
			depth -= 1
			if depth == 0:
				return index + 1
		index += 1
	return -1


## The method name of a chained call starting at [param from], and where it ends.
## Returns an empty name when the next thing is not a chained call.
func _next_call(text: String, from: int) -> Dictionary:
	var index := from
	while index < text.length() and text[index] == " ":
		index += 1
	if index >= text.length() or text[index] != ".":
		return {"name": "", "end": from}

	var name_start := index + 1
	var cursor := name_start
	while cursor < text.length() and (text[cursor].is_valid_identifier()
			or text[cursor] == "_" or text[cursor].is_valid_int()):
		cursor += 1
	if cursor >= text.length() or text[cursor] != "(":
		return {"name": "", "end": from}

	var closed := _match_paren(text, cursor)
	if closed < 0:
		return {"name": "", "end": -1}
	return {"name": text.substr(name_start, cursor - name_start), "end": closed}


## Every (entry point, method) pair the suites actually call.
func _collect_calls() -> Dictionary:
	var calls: Dictionary = {}
	for entry_name: String in _entry_probes():
		calls[entry_name] = PackedStringArray()

	for path: String in _suite_paths(TEST_ROOT):
		var text := _flattened(path)
		for entry_name: String in calls:
			var search := 0
			while true:
				var at := text.find(entry_name + "(", search)
				if at < 0:
					break
				search = at + 1

				var cursor := _match_paren(text, at + entry_name.length())
				if cursor < 0:
					break

				for _step: int in range(CHAIN_LIMIT):
					var call := _next_call(text, cursor)
					var method := String(call["name"])
					if method.is_empty():
						break
					var found: PackedStringArray = calls[entry_name]
					if found.find(method) == -1:
						found.append(method)
						calls[entry_name] = found
					cursor = int(call["end"])
					if cursor < 0 or method != MESSAGE_HOOK:
						break
	return calls


# --- The guard --------------------------------------------------------------

func test_req_026_the_shim_implements_every_assertion_the_suites_call() -> void:
	var probes := _entry_probes()
	var calls := _collect_calls()

	for entry_name: String in calls:
		var probe: Object = probes[entry_name]
		for method: String in (calls[entry_name] as PackedStringArray):
			assert_bool(probe.has_method(method)).override_failure_message(
				"REQ-026: suites call %s(...).%s(...) but the assertion shim does "
				% [entry_name, method]
				+ "not implement it. GDScript resolves that at runtime, aborts the "
				+ "test mid-way and the runner scores it PASS — add the method to "
				+ "test/support/gdunit_compat.gd."
			).is_true()


func test_req_026_the_shim_guard_actually_found_the_suites() -> void:
	# Without this the guard above passes for a parser that matched nothing,
	# which is the same vacuous-green failure it exists to prevent.
	assert_int(_suite_paths(TEST_ROOT).size()).override_failure_message(
		"the harness guard found no suites to scan"
	).is_greater(3)

	var calls := _collect_calls()
	var total := 0
	for entry_name: String in calls:
		total += (calls[entry_name] as PackedStringArray).size()

	assert_int(total).override_failure_message(
		"the harness guard extracted no assertion calls — the chain parser "
		+ "is broken and this test is proving nothing"
	).is_greater(15)

	# And it must be finding the real, distinctive ones.
	assert_array(calls["assert_bool"]).contains(["is_true", "is_false"])
	assert_array(calls["assert_float"]).contains(["is_equal_approx"])


func test_req_026_the_shim_guard_reports_a_method_that_does_not_exist() -> void:
	# Proves the membership check bites rather than passing for anything.
	assert_bool(assert_array([]).has_method("is_equal")).is_true()
	assert_bool(assert_array([]).has_method("no_such_assertion")).override_failure_message(
		"has_method must distinguish a real assertion from an absent one"
	).is_false()


## AC-2's roster: the five system areas the criterion names, each of which
## must be covered by a real suite with real tests. Existence is checked
## HERE, as a test, so deleting a suite fails red instead of quietly
## shrinking coverage.
const UNIT_COVERAGE := {
	"capability": "res://test/core/regen/test_regen_system.gd",
	"lives": "res://test/core/progression/test_life_system.gd",
	"restoration": "res://test/core/restoration/test_restoration_system.gd",
	"ability-registration": "res://test/core/gillmod/test_gill_mod_system.gd",
	"save-interface": "res://test/core/save/test_save_system.gd",
}

## AC-5's roster: the five NAMED fixtures, and for each the tool-test source
## that must reference it — pinning not just existence but SHARING. The
## conforming and non-conforming assets are a generated corpus
## (tools/asset_fixtures.py, by design: no binaries in git), so their name
## is the generator and the sharing reference is the validator suite
## invoking it.
const FIXTURE_ROSTER := [
	["conforming world", "res://fixtures/worlds/conforming_world/world.json",
		"res://tools/test_level_contract_checker.py",
		"fixtures/worlds/conforming_world"],
	["non-conforming world",
		"res://fixtures/worlds/missing_checkpoint/world.json",
		"res://tools/test_level_contract_checker.py",
		"fixtures/worlds/missing_checkpoint"],
	["malicious world",
		"res://fixtures/staticgate/malicious_world/worlds/rogue_world/rogue.gd",
		"res://tools/test_static_gate.py", "malicious_world"],
	["conforming + non-conforming assets (generated corpus)",
		"res://tools/asset_fixtures.py",
		"res://tools/test_asset_contract_validator.py", "asset_fixtures"],
]


func test_req_026_every_named_system_area_has_a_unit_suite() -> void:
	for area: String in UNIT_COVERAGE:
		var path: String = UNIT_COVERAGE[area]
		assert_bool(FileAccess.file_exists(path)).override_failure_message(
			"REQ-026 AC-2: the '%s' area has no unit suite at %s"
			% [area, path]).is_true()
		assert_str(_flattened(path)).override_failure_message(
			"REQ-026 AC-2: %s contains no test functions" % path
		).contains("func test_")


func test_req_026_the_named_fixtures_exist_and_are_shared() -> void:
	for entry: Array in FIXTURE_ROSTER:
		var label := String(entry[0])
		var fixture := String(entry[1])
		var consumer := String(entry[2])
		var reference := String(entry[3])
		assert_bool(FileAccess.file_exists(fixture)).override_failure_message(
			"REQ-026 AC-5: the %s fixture is missing (%s)" % [label, fixture]
		).is_true()
		assert_str(_flattened(consumer)).override_failure_message(
			"REQ-026 AC-5: %s no longer references the %s fixture — it "
			% [consumer, label]
			+ "exists but is not SHARED").contains(reference)


func test_req_026_a_test_that_asserts_nothing_is_a_failure() -> void:
	# The runner's other guard, asserted from inside: a suite instance that has
	# evaluated no assertions reports zero, which is what the runner turns into a
	# failure rather than a silent pass.
	var fresh := GdUnitTestSuite.new()
	assert_int(fresh.get_assertion_count()).is_equal(0)

	fresh.assert_bool(true).is_true()
	assert_int(fresh.get_assertion_count()).override_failure_message(
		"every evaluated assertion must be counted, or the runner's "
		+ "zero-assertion guard cannot fire"
	).is_equal(1)
