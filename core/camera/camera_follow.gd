class_name CameraFollow
extends Camera3D

## The scene-tree camera the rig drives (REQ-005).
##
## CameraRig is a RefCounted holding all the framing logic — damping, the
## per-frame clamp, hint resolution, collision pull-in — and it computes a
## position, a pitch and a yaw. This node applies them to an actual Camera3D and
## supplies the two things the rig cannot know without a scene: where the target
## is, and what geometry is between the two.
##
## Runs in _physics_process rather than _process, and at PHYSICS priority AFTER
## the body: the target must have finished moving for this frame before the
## camera settles toward it, or the camera chases a position the body has already
## left and the clamp reports a delta that never happened.
##
## THE PLAYER OWNS THE YAW. This used to trail the direction of travel with no
## way to turn it, which in a 3D platformer means you cannot look before you
## leap or line a gap up — every jump taken on faith. LookInput now feeds yaw
## and a pitch offset from the mouse and the right stick; see that file for why
## look is not an input verb.
##
## THE ASSIST ONLY RUNS WHEN THE PLAYER IS IDLE, and that is a correctness
## requirement rather than a taste one. Movement is camera-relative (the body
## rotates its intent by this yaw), so a camera that also chased the direction
## of travel would close a feedback loop: the camera turns toward travel, which
## turns travel toward the camera, and the pair spirals. The assist therefore
## waits out `camera.look.assist_delay_seconds` of no look input AND no
## movement before easing back, so during play the camera holds exactly where
## the player put it.

@export_file("*.json") var tuning_path: String = "res://core/tuning/tuning.json"

## The axolotl. Left unset, the camera holds still rather than snapping to the
## origin, which makes a mis-wired scene obvious instead of merely wrong.
@export var target_path: NodePath

## Below this speed the camera keeps the yaw it has. Without it a stationary
## axolotl produces a zero-length velocity whose atan2 is arbitrary, and the
## camera would spin while the player stands still.
const YAW_HOLD_SPEED := 0.25

var _rig: CameraRig
var _target: Node3D
var _body: AxolotlBody
var _yaw_deg: float = 0.0

var _tuning: TuningData
var _look: LookInput
## Player-applied pitch, ADDED to the rig's own framing pitch rather than
## replacing it: the rig still decides how far above the axolotl to sit in
## water versus on land, and the player leans from there.
var _pitch_offset_deg: float = 0.0
## Seconds since the player last touched the look axis or the movement keys.
var _idle_seconds: float = 0.0


func _ready() -> void:
	var errors: Array[TuningError] = []
	var tuning := TuningData.load_from_file(tuning_path, errors)
	for error: TuningError in errors:
		push_error(str(error))
	if tuning == null:
		set_physics_process(false)
		return

	_tuning = tuning
	_rig = CameraRig.new(tuning)
	_rig.set_occluder_probe(SceneOccluderProbe.new(self))
	_look = LookInput.new(tuning)

	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
		_body = _target as AxolotlBody

	if _target == null:
		push_error("[camera.no_target] CameraFollow has no target; "
			+ "set target_path to the axolotl body")
		set_physics_process(false)
		return

	# Start settled on the target rather than easing in from the origin, which
	# would otherwise show the player a swoop across the level on every spawn.
	_rig.update(0.0, _target.global_position, _yaw_deg)
	_apply()

	if _body != null:
		_body.grammar_changed.connect(_on_grammar_changed)
		_rig.set_in_water(_body.is_in_water())
		# Self-wiring, so a new scene cannot forget it and end up with a
		# turnable camera the movement does not follow. The body needs this
		# camera's yaw to make its directions camera-relative.
		_body.set_camera(self)


func get_rig() -> CameraRig:
	return _rig


## The yaw the player is looking along. The body reads this to make movement
## camera-relative, which is the other half of a look axis: a camera you can
## turn while W still means world -Z is worse than no camera control at all.
func get_yaw_deg() -> float:
	return _yaw_deg


## Point the camera, in degrees. Exists for the route probes, which aim the
## camera at their next waypoint before pressing forward — the same order a
## player does it in, and what keeps them faithful now that forward is defined
## by where the camera looks.
func set_yaw_deg(yaw_deg: float) -> void:
	_yaw_deg = wrapf(yaw_deg, -180.0, 180.0)
	_idle_seconds = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _look == null:
		return

	# MOUSE CAPTURE lives here because this is what consumes mouse motion. It
	# is claimed on the first click rather than at startup — a game that
	# swallows the cursor the instant it opens is a game you cannot alt-tab out
	# of before you have seen anything — and released on Escape.
	#
	# Never in a headless or probe run: those have no window to capture into,
	# and a probe that grabbed the cursor would strand a developer's mouse.
	if not _display_has_mouse():
		return

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	var motion := event as InputEventMouseMotion
	# Only while captured. Reading motion with a free cursor would spin the
	# view whenever the player moved the pointer to click something.
	if motion != null and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_look.add_mouse(motion.relative)


static func _display_has_mouse() -> bool:
	return DisplayServer.get_name() != "headless"


func _physics_process(delta: float) -> void:
	if _rig == null or _target == null:
		return

	_apply_look(delta)
	_rig.update(delta, _target.global_position, _yaw_deg, _pitch_offset_deg)
	_apply()


func _apply_look(delta: float) -> void:
	_look.add_stick(Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)), delta)

	var look := _look.drain()
	if not look.is_zero_approx():
		_yaw_deg = wrapf(_yaw_deg + look.x, -180.0, 180.0)
		_pitch_offset_deg = _look.clamp_pitch(_pitch_offset_deg + look.y)
		_idle_seconds = 0.0
		return

	_idle_seconds += delta
	_assist(delta)


## Ease the camera back behind the direction of travel — but only once the
## player has been hands-off long enough that it cannot be mistaken for the
## camera fighting them, and only while they are actually moving.
func _assist(delta: float) -> void:
	if _body == null:
		return
	var travel := _body.velocity
	travel.y = 0.0
	if travel.length() < YAW_HOLD_SPEED:
		return
	if _idle_seconds < _tuning.get_number(LookInput.ASSIST_DELAY_KEY):
		return

	# Godot's -Z forward: the yaw that puts the camera BEHIND the direction of
	# travel is the heading itself.
	var behind := rad_to_deg(atan2(-travel.x, -travel.z))
	var step := _tuning.get_number(LookInput.ASSIST_SPEED_KEY) * delta
	var difference := wrapf(behind - _yaw_deg, -180.0, 180.0)
	_yaw_deg = wrapf(_yaw_deg + clampf(difference, -step, step), -180.0, 180.0)


func _apply() -> void:
	global_position = _rig.get_position()
	# Yaw then pitch, in Y-X-Z order, so pitching never rolls the horizon.
	#
	# The pitch is NEGATED. The rig's pitch is the angle the camera sits ABOVE
	# the axolotl — _orbit_position puts it at sin(pitch) up — so looking back at
	# the target means pitching DOWN by the same angle. Applying it unnegated
	# aims the camera up and away, which drops the axolotl out of the bottom of
	# the frame while every unit test still passes: the rig's numbers were right
	# the whole time, only their application here was wrong.
	# The player's lean is already inside the rig's pitch (it went in through
	# base_framing), so it must NOT be added again here — the position and the
	# rotation have to agree or the axolotl slides out of frame.
	rotation = Vector3(deg_to_rad(-_rig.get_pitch_deg()),
		deg_to_rad(_rig.get_yaw_deg()), 0.0)


func _on_grammar_changed(grammar: MovementGrammar.Grammar) -> void:
	# The rig frames water and land differently — distance and pitch both change
	# — and it is told about the grammar rather than reading the controller,
	# because the architecture declares no Camera -> Controller edge.
	_rig.set_in_water(grammar == MovementGrammar.Grammar.WATER)
