extends "res://test/run_tests.gd"

func _initialize() -> void:
	for path: String in ["res://test/core/rendering/test_hero_motion.gd","res://test/core/rendering/test_hero_animator.gd","res://test/core/controller/test_hero_squash.gd","res://test/core/controller/test_combat_verbs.gd"]:
		_run_suite(path)
	print("HERO TESTS: %d passed, %d failed" % [_passed,_failed])
	quit(0 if _failed == 0 else 1)
