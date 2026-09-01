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

## Assertions actually evaluated during the current test.
##
## This exists because of a real bug this shim caused: a suite called
## `is_less_equal`, which the shim did not implement. `override_failure_message`
## returns Variant, so the call was resolved at RUNTIME rather than parse time —
## it raised a script error, GDScript aborted the test function on the spot, and
## the runner saw an empty failure list and printed PASS. A test that never ran
## reported success, which is worse than no test at all.
##
## The runner fails any test that recorded zero assertions, so an abort before
## the first assertion cannot masquerade as a pass. That is a BACKSTOP, not the
## cure, and it has a known hole: a suite whose helper asserts first has already
## scored one by the time a bad call lands, which is exactly how a second
## occurrence slipped through. The cure is test/core/harness/, which reads the
## suites and fails when they call something this file does not implement.
var _assertions: int = 0


func get_failures() -> PackedStringArray:
	return _failures.duplicate()


func get_assertion_count() -> int:
	return _assertions


func reset_failures() -> void:
	_failures.clear()
	_assertions = 0


func _fail(message: String) -> void:
	_failures.append(message)


func _record_assertion() -> void:
	_assertions += 1


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
		_suite._record_assertion()
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
	func is_not_equal(other: int) -> void:
		_check(_v != other, "expected something other than %d" % other)
	func is_greater(bound: int) -> void:
		_check(_v > bound, "expected greater than %d but got %d" % [bound, _v])
	func is_greater_equal(bound: int) -> void:
		_check(_v >= bound, "expected at least %d but got %d" % [bound, _v])
	func is_less(bound: int) -> void:
		_check(_v < bound, "expected less than %d but got %d" % [bound, _v])
	func is_less_equal(bound: int) -> void:
		_check(_v <= bound, "expected at most %d but got %d" % [bound, _v])
	func is_zero() -> void:
		_check(_v == 0, "expected 0 but got %d" % _v)


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
	func is_less(bound: float) -> void:
		_check(_v < bound, "expected less than %s but got %s" % [bound, _v])
	func is_less_equal(bound: float) -> void:
		_check(_v <= bound, "expected at most %s but got %s" % [bound, _v])
	func is_greater(bound: float) -> void:
		_check(_v > bound, "expected greater than %s but got %s" % [bound, _v])
	func is_greater_equal(bound: float) -> void:
		_check(_v >= bound, "expected at least %s but got %s" % [bound, _v])
	func is_between(low: float, high: float) -> void:
		_check(_v >= low and _v <= high,
			"expected between %s and %s but got %s" % [low, high, _v])


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
	func _at(index: int) -> Variant:
		if _v is Array:
			return (_v as Array)[index]
		if _v is PackedStringArray:
			return (_v as PackedStringArray)[index]
		return null
	func is_empty() -> void:
		_check(_size() == 0, "expected an empty array but it held %d" % _size())
	func is_not_empty() -> void:
		_check(_size() > 0, "expected a non-empty array")
	func has_size(expected: int) -> void:
		_check(_size() == expected,
			"expected %d elements but got %d" % [expected, _size()])
	func contains(expected: Array) -> void:
		for item: Variant in expected:
			_check(_has(item), "expected array to contain '%s'" % str(item))
	func not_contains(unexpected: Array) -> void:
		for item: Variant in unexpected:
			_check(not _has(item), "expected array NOT to contain '%s'" % str(item))
	## Order-sensitive equality. contains() is the subset check; this is the
	## whole-value one, and the two are not interchangeable — a test asserting a
	## SEQUENCE (signal order, say) needs this.
	func is_equal(expected: Variant) -> void:
		var other := _ArrayAssert.new(_suite, expected)
		if _size() != other._size():
			_check(false, "expected %d elements but got %d" % [other._size(), _size()])
			return
		for index: int in range(_size()):
			if str(_at(index)) != str(other._at(index)):
				_check(false, "element %d: expected '%s' but got '%s'"
					% [index, str(other._at(index)), str(_at(index))])
				return
		_check(true, "")


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
