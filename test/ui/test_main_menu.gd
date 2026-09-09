extends GdUnitTestSuite

## The first screen's DECISIONS, held without a window.
##
## Everything asserted here is a pure function on the menu, which is why the
## suite needs no scene, no frame and no rendering: what entries exist, when a
## destructive action has to ask first, and whether the profile path the menu
## acts on is the one the game actually saves to.

const PROFILE := "user://test_main_menu_profile.json"


func after_test() -> void:
	if FileAccess.file_exists(PROFILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))


func test_a_fresh_install_is_not_offered_a_game_to_continue() -> void:
	# CONTINUE is absent rather than present-and-disabled. A first-time player
	# opening the game should see only things that are true for them.
	var entries := MainMenu.entries_for(false)
	assert_bool(entries.has(MainMenu.CONTINUE)).override_failure_message(
		"a player with no save must not be offered Continue").is_false()
	assert_bool(entries.has(MainMenu.NEW_GAME)).is_true()
	assert_bool(entries.has(MainMenu.QUIT)).is_true()


func test_a_returning_player_is_offered_their_game_first() -> void:
	var entries := MainMenu.entries_for(true)
	assert_str(entries[0]).override_failure_message(
		"Continue must be the first entry: it is what a returning player "
		+ "came back for, and it must not sit under the button that erases "
		+ "their progress").is_equal(MainMenu.CONTINUE)


func test_new_game_asks_before_erasing_a_real_save() -> void:
	# The whole point of the confirm step. This is a family game and the
	# person pressing New Game may not read the button they are pressing.
	assert_bool(MainMenu.confirm_needed(true)).override_failure_message(
		"starting a new game over an existing save must ask first").is_true()


func test_new_game_does_not_nag_when_there_is_nothing_to_lose() -> void:
	# A confirm dialog with no stakes behind it teaches players to dismiss
	# confirm dialogs, which is how the one that matters gets dismissed too.
	assert_bool(MainMenu.confirm_needed(false)).is_false()


func test_the_menu_acts_on_the_file_the_game_actually_saves_to() -> void:
	# The menu cannot ask a GameSession where the profile lives, because it
	# runs before one exists -- so the path is restated, and a restated
	# constant is a constant that can drift. This is the assertion that stops
	# "New Game" quietly erasing nothing at all.
	var session := GameSession.new()
	assert_str(MainMenu.PROFILE_PATH).override_failure_message(
		"MainMenu.PROFILE_PATH has drifted from GameSession.profile_path; "
		+ "New Game would erase a file the game never writes"
	).is_equal(session.profile_path)
	session.free()


func test_discarding_a_profile_removes_it_and_reports_that_it_did() -> void:
	var handle := FileAccess.open(PROFILE, FileAccess.WRITE)
	handle.store_string("{}")
	handle.close()
	assert_bool(MainMenu.save_exists(PROFILE)).is_true()

	assert_bool(MainMenu.discard_profile(PROFILE)).override_failure_message(
		"discarding an existing profile must report that it removed one"
	).is_true()
	assert_bool(MainMenu.save_exists(PROFILE)).override_failure_message(
		"the profile survived New Game; the next session would load the old "
		+ "progress the player asked to leave behind").is_false()


func test_discarding_nothing_is_not_an_error() -> void:
	# New Game on a fresh install takes this path every time.
	assert_bool(MainMenu.discard_profile(PROFILE)).is_false()


func test_the_game_boots_into_the_menu_rather_than_into_play() -> void:
	# The reason this screen exists. Booting straight into the hub meant the
	# game could never be started -- it was already running when the window
	# opened -- and it is a one-line project setting, so it is a one-line
	# regression too.
	assert_str(str(ProjectSettings.get_setting("application/run/main_scene"))
		).override_failure_message(
		"the game no longer boots into the main menu").is_equal(
		"res://ui/main_menu.tscn")


func test_the_menu_hands_over_to_a_scene_that_exists() -> void:
	# A typo here is a game that boots to a black screen and never recovers,
	# and it is exactly the kind of typo no other test would catch.
	assert_bool(ResourceLoader.exists(MainMenu.HUB_SCENE)
		).override_failure_message(
		"the menu points at %s, which does not load" % MainMenu.HUB_SCENE
		).is_true()
