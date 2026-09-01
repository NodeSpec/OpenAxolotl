class_name AxolotlBody
extends CharacterBody3D

## The scene-tree body the controller drives (REQ-001, REQ-024).
##
## AxolotlController is a RefCounted that computes VELOCITY and nothing else —
## its own comment says "the CharacterBody3D wrapper owns position and the motion
## call". This is that wrapper, and it is deliberately thin: read intent, hand
## the controller the frame, take the velocity back, move. Every gameplay
## decision stays in the controller, where it is testable without a scene.
##
## What genuinely belongs HERE, because it needs the physics world:
##
##   * GRAVITY. The controller preserves velocity.y on land precisely so the
##     wrapper can own the fall; integrating it inside the controller would make
##     a headless test responsible for simulating a floor.
##   * GROUNDEDNESS, from is_on_floor(). The controller gates the hop on it.
##   * WATER STATE, counted from the volumes currently overlapping.
##   * The RAW EVENT FEED, forwarded to the Input System and nowhere else.
##
## The event forward is one line on purpose. `Input` is never touched here: this
## node receives events the engine already delivered and hands them straight
## over, which is what keeps REQ-024 AC-6 provable by a scan rather than by
## convention.

const GRAVITY_LAND_KEY := "controller.gravity.land_m_per_s2"
const GRAVITY_WATER_KEY := "controller.gravity.water_m_per_s2"
const TERMINAL_SPEED_KEY := "controller.gravity.terminal_speed_m_per_s"

@export_file("*.json") var tuning_path: String = "res://core/tuning/tuning.json"
@export_file("*.json") var bindings_path: String = BindingTable.DEFAULTS_PATH

## Re-emitted from the controller so the camera and HUD can follow the grammar
## without holding a reference to the controller itself.
signal grammar_changed(grammar: MovementGrammar.Grammar)
signal water_state_changed(in_water: bool)

var _tuning: TuningData
var _controller: AxolotlController
var _input: InputSystem

## Overlapping water volumes, counted rather than flagged: two volumes meeting at
## a seam must not read as "left the water" when the player crosses the join.
var _water_volumes: int = 0


func _ready() -> void:
	var tuning_errors: Array[TuningError] = []
	_tuning = TuningData.load_from_file(tuning_path, tuning_errors)
	for error: TuningError in tuning_errors:
		push_error(str(error))
	if _tuning == null:
		set_physics_process(false)
		return

	_controller = AxolotlController.new(_tuning)
	_controller.grammar_changed.connect(_on_grammar_changed)

	var binding_errors: Array[InputError] = []
	var table := BindingTable.load_from_file(bindings_path, binding_errors)
	for error: InputError in binding_errors:
		push_error(str(error))
	if table == null:
		set_physics_process(false)
		return

	_input = InputSystem.new(table)

	# The two default differently — the controller starts on land, the Input
	# System starts in water — and the controller only announces a grammar on its
	# first physics step. That leaves a window, however brief, where a key would
	# resolve against the wrong context. Syncing here closes it explicitly rather
	# than leaving it resting on which node happens to initialise first.
	_input.set_grammar(_controller.get_grammar())

	_controller.set_anchor_source(SceneAnchorSource.new(self))
	_controller.sync_body_position(global_position)


func get_controller() -> AxolotlController:
	return _controller


func get_input_system() -> InputSystem:
	return _input


func is_in_water() -> bool:
	return _water_volumes > 0


# --- The event feed ----------------------------------------------------------

## The entire engine-facing input surface. Marking the event handled stops it
## reaching a UI layer underneath once one exists.
func _unhandled_input(event: InputEvent) -> void:
	if _input != null and _input.handle_event(event):
		get_viewport().set_input_as_handled()


# --- The frame ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _controller == null or _input == null:
		return

	# The controller reasons about the body's position for the grapple and the
	# climb ceiling, so it is told where the body actually ended up last frame
	# rather than integrating a position of its own that could drift from the
	# one collision resolved.
	_controller.sync_body_position(global_position)
	_controller.set_grounded(is_on_floor())

	_controller.physics_step(delta, is_in_water(), _input.poll_intent())

	velocity = _controller.get_velocity()
	_apply_gravity(delta)

	move_and_slide()

	# Collision may have cancelled the motion the controller asked for — walking
	# into a wall, or landing. Handing the resolved velocity back keeps the
	# controller's momentum honest instead of letting it accumulate speed against
	# geometry it never actually moved through.
	_controller.set_velocity(velocity)
	_controller.sync_body_position(global_position)


## Gravity lives here rather than in the controller because it is a property of
## the physics world, and because the controller preserves velocity.y on land
## expressly so this can own it.
##
## Suspended while climbing or grappling: both are deliberate vertical routes the
## controller is already driving, and adding a fall underneath them would fight
## the movement the player asked for.
func _apply_gravity(delta: float) -> void:
	if _controller.is_climbing() or _controller.get_grapple().is_attached():
		return

	var pull := _tuning.get_number(
		GRAVITY_WATER_KEY if is_in_water() else GRAVITY_LAND_KEY)
	if pull <= 0.0:
		return

	velocity.y = maxf(velocity.y - pull * delta,
		-_tuning.get_number(TERMINAL_SPEED_KEY))


# --- Water volumes -----------------------------------------------------------

## Called by WaterVolume as the body crosses its boundary. Counted, so nested or
## abutting volumes cannot make the player surface mid-swim.
func enter_water() -> void:
	_water_volumes += 1
	if _water_volumes == 1:
		water_state_changed.emit(true)


func exit_water() -> void:
	_water_volumes = maxi(_water_volumes - 1, 0)
	if _water_volumes == 0:
		water_state_changed.emit(false)


func _on_grammar_changed(grammar: MovementGrammar.Grammar) -> void:
	# The Input System resolves bindings against the active grammar, which is how
	# W means swim in water and waddle on land. Without this the whole
	# context-sensitive scheme would resolve against a grammar frozen at startup.
	_input.set_grammar(grammar)
	grammar_changed.emit(grammar)
