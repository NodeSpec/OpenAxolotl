extends "res://test/run_tests.gd"
func _initialize() -> void:
	for path: String in ["res://test/core/audio/test_audio_system.gd","res://test/core/input/test_input_system.gd","res://test/core/collectibles/test_collectibles_system.gd","res://test/core/rendering/test_hero_animator.gd","res://test/core/rendering/test_hero_motion.gd","res://test/core/controller/test_combat_verbs.gd","res://test/hub/test_world_systems.gd"]:_run_suite(path)
	print("DANCE REGRESSION: %d passed, %d failed"%[_passed,_failed]);quit(1 if _failed else 0)
