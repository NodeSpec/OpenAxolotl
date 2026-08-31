class_name GdUnitTestSuite
extends RefCounted

## STOPGAP: a minimal stand-in for GdUnit4's test-suite base and fluent
## assertions (REQ-026).
##
## Why this exists: the test plans suggest GdUnit4, but the addon cannot be
## fetched in every environment (GitHub archive endpoints are blocked behind
## some proxies). A test suite that cannot run is decoration — it produces no
## evidence and flips no acceptance criterion. This shim implements exactly the
## GdUnit4 API surface the suites use, so they run headless under plain Godot
## today and need no edits when the real addon lands.
##
## TO REMOVE: drop this file and add addons/gdUnit4. The suites are written
## against GdUnit4's API, not this shim's, so nothing else changes.

var _failures: PackedStringArray = []
var _temp_dirs: PackedStringArray = []


func get_failures() -> PackedStringArray:
	return _failures.duplicate()


func reset_failures() -> void:
	_failures.clear()


func _fail(message: String) -> void:
	_failures.append(message)


## GdUnit4's per-test temp directory. Cleaned by the runner after each suite.
func create_temp_dir(tag: String) -> String:
	var path := "user://tmp_%s_%d" % [tag, Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(path)
	_temp_dirs.append(path)
	return path


func cleanup_temp_dirs() -> void:
	for path: String in _temp_dirs:
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		for file: String in dir.get_files():
			dir.remove(file)
		DirAccess.remove_absolute(path)
	_temp_dirs.clear()


# --- Fluent assertion entry points -----------------------------------------

func assert_str(value: String) -> _StrAssert:
	return _StrAssert.new(self, value)


func assert_int(value: int) -> _IntAssert:
	return _IntAssert.new(self, value)


func assert_bool(value: bool) -> _BoolAssert:
	return _BoolAssert.new(self, value)


func assert_float(value: float) -> _FloatAssert:
	return _FloatAssert.new(self, value)


func assert_array(value: Variant) -> _ArrayAssert:
	return _ArrayAssert.new(self, value)


func assert_dict(value: Dictionary) -> _DictAssert:
	return _DictAssert.new(self, value)


func assert_object(value: Variant) -> _ObjectAssert:
	return _ObjectAssert.new(self, value)


# --- Assertion objects ------------------------------------------------------

class _Base extends RefCounted:
	var _suite: GdUnitTestSuite
	var _message: String = ""

	func _init(suite: GdUnitTestSuite) -> void:
		_suite = suite

	## GdUnit4's custom-failure-message hook. Returns self so it chains.
	func override_failure_message(message: String) -> Variant:
		_message = message
		return self

	func _check(ok: bool, fallback: String) -> void:
		if ok:
			return
		_suite._fail(_message if not _message.is_empty() else fallback)


class _StrAssert extends _Base:
	var _v: String
	func _init(suite: GdUnitTestSuite, v: String) -> void:
		super(suite)
		_v = v
	func is_equal(expected: String) -> void:
		_check(_v == expected, "expected '%s' but got '%s'" % [expected, _v])
	func is_not_equal(other: String) -> void:
		_check(_v != other, "expected something other than '%s'" % other)
	func is_empty() -> void:
		_check(_v.is_empty(), "expected an empty string but got '%s'" % _v)
	func is_not_empty() -> void:
		_check(not _v.is_empty(), "expected a non-empty string")
	func contains(needle: String) -> void:
		_check(_v.contains(needle), "expected string to contain '%s'" % needle)
	func not_contains(needle: String) -> void:
		_check(not _v.contains(needle), "expected string NOT to contain '%s'" % needle)


class _IntAssert extends _Base:
	var _v: int
	func _init(suite: GdUnitTestSuite, v: int) -> void:
		super(suite)
		_v = v
	func is_equal(expected: int) -> void:
		_check(_v == expected, "expected %d but got %d" % [expected, _v])
	func is_greater(bound: int) -> void:
		_check(_v > bound, "expected greater than %d but got %d" % [bound, _v])
	func is_less(bound: int) -> void:
		_check(_v < bound, "expected less than %d but got %d" % [bound, _v])


class _BoolAssert extends _Base:
	var _v: bool
	func _init(suite: GdUnitTestSuite, v: bool) -> void:
		super(suite)
		_v = v
	func is_true() -> void:
		_check(_v, "expected true but got false")
	func is_false() -> void:
		_check(not _v, "expected false but got true")


class _FloatAssert extends _Base:
	var _v: float
	func _init(suite: GdUnitTestSuite, v: float) -> void:
		super(suite)
		_v = v
	func is_equal_approx(expected: float, tolerance: float) -> void:
		_check(absf(_v - expected) <= tolerance,
			"expected %s (+/- %s) but got %s" % [expected, tolerance, _v])


class _ArrayAssert extends _Base:
	var _v: Variant
	func _init(suite: GdUnitTestSuite, v: Variant) -> void:
		super(suite)
		_v = v
	func _size() -> int:
		if _v is Array:
			return (_v as Array).size()
		if _v is PackedStringArray:
			return (_v as PackedStringArray).size()
		return 0
	func _has(item: Variant) -> bool:
		if _v is Array:
			return (_v as Array).has(item)
		if _v is PackedStringArray:
			return (_v as PackedStringArray).has(String(item))
		return false
	func is_empty() -> void:
		_check(_size() == 0, "expected an empty array but it held %d" % _size())
	func is_not_empty() -> void:
		_check(_size() > 0, "expected a non-empty array")
	func contains(expected: Array) -> void:
		for item: Variant in expected:
			_check(_has(item), "expected array to contain '%s'" % str(item))


class _DictAssert extends _Base:
	var _v: Dictionary
	func _init(suite: GdUnitTestSuite, v: Dictionary) -> void:
		super(suite)
		_v = v
	func is_empty() -> void:
		_check(_v.is_empty(), "expected an empty dictionary")
	func is_not_empty() -> void:
		_check(not _v.is_empty(), "expected a non-empty dictionary")


class _ObjectAssert extends _Base:
	var _v: Variant
	func _init(suite: GdUnitTestSuite, v: Variant) -> void:
		super(suite)
		_v = v
	func is_null() -> void:
		_check(_v == null, "expected null but got an object")
	func is_not_null() -> void:
		_check(_v != null, "expected an object but got null")
