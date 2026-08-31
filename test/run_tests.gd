extends SceneTree

## The headless test runner (REQ-026 AC-1).
##
##   godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
##
## Discovers every test/**/test_*.gd, runs each test_* method, and exits
## non-zero if any assertion failed. Test names carry the requirement id they
## prove, so the summary reports the failing rule the way REQ-026 AC-6 requires.

const TEST_ROOT := "res://test"

var _passed: int = 0
var _failed: int = 0
var _results: Array[Dictionary] = []


func _initialize() -> void:
	var suites := _discover(TEST_ROOT)
	suites.sort()

	for suite_path: String in suites:
		_run_suite(suite_path)

	print("\n%s" % "=".repeat(66))
	print("%d passed, %d failed, %d total" % [_passed, _failed, _passed + _failed])

	if _failed > 0:
		print("\nFAILURES")
		for row: Dictionary in _results:
			if not bool(row["ok"]):
				print("  %s :: %s" % [row["suite"], row["test"]])
				for message: String in (row["failures"] as PackedStringArray):
					print("      %s" % message)

	quit(1 if _failed > 0 else 0)


func _discover(root: String) -> PackedStringArray:
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
				found.append_array(_discover(path))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func _run_suite(suite_path: String) -> void:
	var script: GDScript = load(suite_path)
	if script == null:
		_failed += 1
		_results.append({
			"suite": suite_path, "test": "<load>", "ok": false,
			"failures": PackedStringArray(["could not load suite"]),
		})
		return

	var suite_name := suite_path.get_file().get_basename()
	print("\n%s" % suite_name)

	for method: Dictionary in script.get_script_method_list():
		var test_name := String(method["name"])
		if not test_name.begins_with("test_"):
			continue

		# A fresh instance per test: state must never leak between cases.
		var suite: GdUnitTestSuite = script.new()
		if suite.has_method("before_test"):
			suite.call("before_test")

		suite.reset_failures()
		suite.call(test_name)
		var failures := suite.get_failures()

		if suite.has_method("after_test"):
			suite.call("after_test")
		suite.cleanup_temp_dirs()

		var ok := failures.is_empty()
		if ok:
			_passed += 1
			print("  PASS  %s" % test_name)
		else:
			_failed += 1
			print("  FAIL  %s" % test_name)
			for message: String in failures:
				print("          %s" % message)

		_results.append({
			"suite": suite_name, "test": test_name,
			"ok": ok, "failures": failures,
		})
