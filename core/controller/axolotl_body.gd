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

## The visual the body carries — the character model — turned to face the
## controller's heading each step. The BODY never rotates: its capsule is the
## physics footprint every probe and tuning value was proven against, and a
## capsule is round, so facing is a visual fact and nothing more. A scene
## without a model (the template walk builds a bare body) simply has nothing
## to turn.
@export var model_path: NodePath = ^"Model"

## Re-emitted from the controller so the camera and HUD can follow the grammar
## without holding a reference to the controller itself.
signal grammar_changed(grammar: MovementGrammar.Grammar)
signal water_state_changed(in_water: bool)

## A strike window opened, re-emitted from the controller with the body's own
## position folded in. The controller has no scene and no enemies; whatever
## binds the world answers this by finding the machines within reach of that
## point. Same division as anchor discovery for the grapple.
signal strike_opened(kind: CombatStrike.Kind, origin: Vector3, reach: float)

var _tuning: TuningData
var _controller: AxolotlController
var _input: InputSystem
var _model: Node3D

## Squash and stretch on the model (hop and landing), multiplied onto the
## scale the scene authored for it. Visual only, like facing.
var _squash: HeroSquash
var _model_base_scale: Vector3 = Vector3.ONE
var _was_grounded: bool = true

## The rig's clips, chosen from the same state this wrapper already computes.
## Visual only: a body whose model carries no AnimationPlayer simply never
## binds, which is what the bare bodies the walk probes build do.
var _animator: HeroAnimator

## Overlapping water volumes, counted rather than flagged: two volumes meeting at
## a seam must not read as "left the water" when the player crosses the join.
var _water_volumes: int = 0


func _ready() -> void:
	initialise()


## Builds the controller, the input system and the visual layer. Idempotent,
## and callable directly: a node added while the SceneTree is still
## initialising — which the test runner does — never receives _ready, so the
## setup has to be reachable without it. WorldSystems.wire() exists for the
## same reason and says the same thing; before this, the body simply could
## not be built inside a test at all.
func initialise() -> void:
	if _controller != null:
		return
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

	if not model_path.is_empty():
		_model = get_node_or_null(model_path) as Node3D
	_animator = HeroAnimator.new()
	if _model != null:
		# The look is the client's: dress the imported model in the shared
		# hero materials, whatever the exporter wrote into the file.
		HeroSkin.apply(_model)
		_model_base_scale = _model.scale
		_animator.bind(_model)
	_squash = HeroSquash.new(_tuning)
	_controller.hopped.connect(_squash.on_hop)

	# The action clips are triggered by the VERB, never guessed from motion: a
	# roll and a fast waddle look identical to a velocity sample, and the whole
	# point of the dodge is that the player can see they committed to it.
	#
	# REQ-035 gameplay-feel pass: the visible one-shot is time-scaled to the
	# exact committed movement window. Imported clip length is an art property;
	# roll/spin duration is gameplay tuning. They must end together.
	_controller.rolled.connect(
		func() -> void: _animator.play_action(
			HeroAnimator.ROLL, _controller.get_roll().duration_seconds()))
	_controller.spin_sprint_started.connect(
		func() -> void: _animator.play_action(
			HeroAnimator.SPIN, _controller.get_spin_sprint().duration_seconds()))
	_controller.strike_opened.connect(_on_strike_opened)


func get_controller() -> AxolotlController:
	return _controller


## The camera whose yaw defines "forward". Optional: with none bound the
## directions stay world-space, which is what every headless probe and unit
## test wants and what this always used to do.
var _camera: CameraFollow = null


## Bind the camera that defines forward. Called by whatever assembles the
## player scene; a body with no camera keeps world-relative movement.
func set_camera(camera: CameraFollow) -> void:
	_camera = camera


## The camera that defines forward, or null. The route probes read it so they
## can aim before pressing forward, which is the same order a player does it in.
func get_camera() -> CameraFollow:
	return _camera


## Rotate a movement direction out of screen space into world space.
##
## THIS IS THE OTHER HALF OF A LOOK AXIS, and shipping one without the other
## would be worse than shipping neither: a camera the player can swing while W
## still means world -Z means that after any turn, forward is some direction
## they have to work out. Camera-relative movement is what makes "push the
## stick where you want to go" true.
##
## The VERTICAL component is left alone. In the water grammar it comes from
## SPACE and SHIFT, which mean up and down in the world and not relative to
## wherever the camera is pitched — a swimmer pressing "up" while looking at
## the floor wants to rise, not to swim into it.
func _camera_relative(direction: Vector3) -> Vector3:
	if _camera == null or direction.is_zero_approx():
		return direction
	var horizontal := Vector3(direction.x, 0.0, direction.z)
	if horizontal.is_zero_approx():
		return direction
	var rotated := horizontal.rotated(
		Vector3.UP, deg_to_rad(_camera.get_yaw_deg()))
	return Vector3(rotated.x, direction.y, rotated.z)


func get_input_system() -> InputSystem:
	return _input


func get_animator() -> HeroAnimator:
	return _animator


## The visual half of losing a capability (REQ-019's comedic register): the
## world's runtime calls this when the regeneration system announces a loss,
## so the flinch is tied to the event rather than guessed from motion.
func play_hurt() -> void:
	if _animator != null:
		_animator.play_hurt()


func is_in_water() -> bool:
	return _water_volumes > 0


## The swing plays here rather than in the controller for the same reason the
## roll and the spin do: the controller owns no AnimationPlayer. The strike is
## re-emitted with the body's position, which is the one fact the controller
## cannot supply and the scene cannot do without.
func _on_strike_opened(kind: CombatStrike.Kind, reach: float) -> void:
	if kind == CombatStrike.Kind.TAIL_WHACK:
		_animator.play_action(HeroAnimator.WHACK)
	strike_opened.emit(kind, global_position, reach)


## A machine was landed on. Called by whatever owns the scene, which is the
## only thing that knows: the bounce is the controller's, the flourish is the
## animator's.
func stomped() -> void:
	_controller.apply_stomp_bounce()
	velocity = _controller.get_velocity()
	_squash.on_hop()


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

	var intent := _input.poll_intent()
	intent.direction = _camera_relative(intent.direction)
	_controller.physics_step(delta, is_in_water(), intent)

	velocity = _controller.get_velocity()
	_apply_gravity(delta)

	move_and_slide()

	_update_climb(intent, delta)

	# A landing is the floor flag going false to true on land. Water has no
	# floor to slap; brushing the seabed while swimming is not a landing.
	var grounded := is_on_floor()
	if grounded and not _was_grounded and not is_in_water():
		_squash.on_land()
	_was_grounded = grounded

	_animator.step(delta, is_in_water(), grounded, velocity)

	if _model != null:
		# Yaw then pitch, in that order: the pitch is about the model's OWN
		# lateral axis, so it has to be applied after the turn or a diving
		# axolotl swimming east would tip sideways instead of nose-down.
		_model.rotation = Vector3(_controller.get_pitch(),
			_controller.get_heading_yaw(), 0.0)
		_model.scale = _model_base_scale * _squash.step(delta)

	# Collision may have cancelled the motion the controller asked for — walking
	# into a wall, or landing. Handing the resolved velocity back keeps the
	# controller's momentum honest instead of letting it accumulate speed against
	# geometry it never actually moved through.
	_controller.set_velocity(velocity)
	_controller.sync_body_position(global_position)


## Climbing needs the physics world, which is why the controller cannot start it
## alone: `try_climb` takes a collision layer and a group list, and only a body
## that has actually moved knows what it is touching. Without this the climb verb
## was inert in every real scene while its unit tests stayed green — the logic
## was right and nothing ever fed it.
##
## Attachment is REQUESTED, not automatic: brushing a climbable wall while
## waddling past must not stick the axolotl to it. The player asks by pressing
## the climb verb, and this looks at what they are against when they do.
func _update_climb(intent: PlayerIntent, delta: float) -> void:
	if _controller.is_climbing():
		# Let go when the wall does — but not on the FIRST frame without it.
		# The contact fact is the body's to report; how long a climber may
		# keep it after losing the wall is the controller's to decide, and it
		# gives a brief grace so a seam in the surface, or the moment of
		# cresting a lip, does not drop a climber four metres.
		_controller.report_wall_contact(is_on_wall(), delta)
		if not _controller.is_climbing():
			return
		if not is_on_wall():
			return
		# Kept current every frame: a curved or jointed surface changes the climb
		# basis as the axolotl traverses it, and a stale normal would send
		# lateral steering off along the wall it started on.
		_controller.set_climb_surface_normal(get_wall_normal())
		return

	if not intent.wants(MovementGrammar.Verb.CLIMB):
		return

	for index: int in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider() as CollisionObject3D
		if collider == null:
			continue
		var groups := PackedStringArray()
		for group: Variant in collider.get_groups():
			groups.append(String(group))
		if _controller.try_climb(collider.collision_layer, groups):
			_controller.set_climb_surface_normal(
				get_slide_collision(index).get_normal())
			return


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
