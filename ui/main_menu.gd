class_name MainMenu
extends Control

## The first screen the game shows (REQ-022's sibling: the shell around the
## playthrough rather than the readout inside it).
##
## Until now `run/main_scene` booted straight into the hub, which meant the
## game had no way to be STARTED — it was simply already running the moment
## the window opened, and no way to be left either. This is the screen that
## makes "play the game" a thing a player does rather than a thing that has
## already happened to them.
##
## WHAT IT OWNS, AND WHAT IT DELIBERATELY DOES NOT. It owns three decisions:
## whether a save exists, what to do about it, and which scene to hand over
## to. It owns no game state at all — it never touches SaveSystem, never
## reads a profile's contents, and never decides what "progress" means.
## GameSession already loads `user://profile.json` on its own `_ready` if the
## file is there, so CONTINUE is simply "change scene and let the session do
## what it already does". NEW GAME is the only case that needs an action, and
## the action is on the FILE, not on the save format: remove it, and the
## session finds nothing and starts fresh. That keeps the menu ignorant of
## every save-compatibility rule in core/save/, which is where those rules
## belong and where they are already tested.
##
## ERASING A CHILD'S PROGRESS IS NOT A ONE-BUTTON ACTION. This is a family
## game; the person pressing New Game may be five. So New Game only asks for
## confirmation when there is actually something to lose, and the confirm
## step defaults its focus to CANCEL rather than to the destructive answer.
##
## BUILT IN CODE, like PlayerHud and WaterSplash and for the same reason: the
## whole screen is a title, three buttons and a confirm row, and that reads
## better as thirty lines that explain themselves than as a .tscn nobody can
## diff. The scene file is a Control with this script and nothing else.
##
## `entries_for` and `confirm_needed` are static and pure, so the whole of
## what this screen DECIDES is testable without a window, a scene tree, or a
## frame of rendering — the same rule HeroAnimator.choose_clip follows.

## Where GameSession keeps the profile. Restated here rather than reached for
## through an instance, because the menu runs BEFORE any session exists and
## has nothing to ask. Kept in step with GameSession.profile_path's default,
## and test_main_menu.gd fails if the two ever drift apart.
const PROFILE_PATH := "user://profile.json"

const HUB_SCENE := "res://hub/open_lagoon.tscn"

const CONTINUE := "Continue"
const NEW_GAME := "New Game"
const QUIT := "Quit"

## The aquatic palette, same family the worlds are lit in. Menu colours are
## stated here rather than pulled from a theme because there is one screen and
## a theme resource would be indirection with nothing on the other end of it.
const BACKDROP := Color(0.09, 0.20, 0.26)
const TITLE_TINT := Color(0.86, 0.96, 0.96)
const WARN_TINT := Color(1.0, 0.83, 0.55)

signal started(fresh: bool)

var _buttons: Dictionary = {}
var _confirm_row: HBoxContainer = null
var _menu_column: VBoxContainer = null


## Which entries the menu offers. CONTINUE is absent rather than disabled when
## there is no save: a greyed-out row a new player can never use is a worse
## first screen than one that only shows what is true.
static func entries_for(has_save: bool) -> Array[String]:
	var entries: Array[String] = []
	if has_save:
		entries.append(CONTINUE)
	entries.append(NEW_GAME)
	entries.append(QUIT)
	return entries


## Whether New Game has to ask first. Only when there is progress to destroy —
## on a fresh install the question would be noise with no stakes behind it.
static func confirm_needed(has_save: bool) -> bool:
	return has_save


static func save_exists(path: String = PROFILE_PATH) -> bool:
	return FileAccess.file_exists(path)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	_menu_column = VBoxContainer.new()
	_menu_column.add_theme_constant_override("separation", 14)
	centre.add_child(_menu_column)

	var title := Label.new()
	title.text = "OpenAxolotl"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", TITLE_TINT)
	_menu_column.add_child(title)

	var tagline := Label.new()
	tagline.text = "A platformer you can add levels to"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.add_theme_color_override("font_color", TITLE_TINT)
	_menu_column.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	_menu_column.add_child(spacer)

	var first: Button = null
	for entry: String in entries_for(save_exists()):
		var button := Button.new()
		button.text = entry
		button.custom_minimum_size = Vector2(300, 52)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_on_pressed.bind(entry))
		_menu_column.add_child(button)
		_buttons[entry] = button
		if first == null:
			first = button

	# Focus so the screen is usable on a gamepad from the first frame without
	# touching a mouse. REQ-019 asks for the game to be completable on a
	# single input device, and a menu that needs a pointer to leave breaks
	# that on the very first screen. Held as the first button BUILT rather
	# than by child index: the header rows above it are decoration and adding
	# one more would silently move focus onto a Label.
	if first != null:
		first.grab_focus()


func _on_pressed(entry: String) -> void:
	match entry:
		CONTINUE:
			_enter(false)
		NEW_GAME:
			if confirm_needed(save_exists()):
				_ask_to_overwrite()
			else:
				_enter(true)
		QUIT:
			get_tree().quit()


## The confirm step. Built on demand and torn down on cancel, so the menu has
## exactly one shape at rest.
func _ask_to_overwrite() -> void:
	if _confirm_row != null:
		return
	for button: Button in _buttons.values():
		button.disabled = true

	var warning := Label.new()
	warning.text = "Starting a new game erases your saved progress."
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", WARN_TINT)
	warning.name = "OverwriteWarning"
	_menu_column.add_child(warning)

	_confirm_row = HBoxContainer.new()
	_confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_row.add_theme_constant_override("separation", 12)
	_menu_column.add_child(_confirm_row)

	var erase := Button.new()
	erase.text = "Erase and start"
	erase.custom_minimum_size = Vector2(190, 46)
	erase.pressed.connect(func() -> void: _enter(true))
	_confirm_row.add_child(erase)

	var cancel := Button.new()
	cancel.text = "Keep my game"
	cancel.custom_minimum_size = Vector2(190, 46)
	cancel.pressed.connect(_dismiss_confirm)
	_confirm_row.add_child(cancel)

	# Focus lands on KEEP, never on ERASE: the default answer to a destructive
	# question is the one that destroys nothing.
	cancel.grab_focus()


func _dismiss_confirm() -> void:
	if _confirm_row == null:
		return
	var warning := _menu_column.get_node_or_null(^"OverwriteWarning")
	if warning != null:
		warning.queue_free()
	_confirm_row.queue_free()
	_confirm_row = null
	for button: Button in _buttons.values():
		button.disabled = false
	var fallback: Button = _buttons.get(NEW_GAME)
	if fallback != null:
		fallback.grab_focus()


## Hands over to the hub. A fresh run removes the profile FIRST, so the
## GameSession that comes up finds nothing and builds a new one — the menu
## never writes a save format it does not own.
func _enter(fresh: bool) -> void:
	if fresh:
		discard_profile()
	started.emit(fresh)
	get_tree().change_scene_to_file(HUB_SCENE)


## Removes the profile if it is there. Returns whether anything was removed,
## so a caller (and the test) can tell "erased" from "there was nothing".
static func discard_profile(path: String = PROFILE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(
		ProjectSettings.globalize_path(path)) == OK
