extends Node

## Drives the greybox headlessly and asserts the axolotl actually moved.
##
## The unit suites prove the controller computes the right velocity. They cannot
## prove the WIRING: that events reach the Input System, that intent reaches the
## controller, that the velocity reaches move_and_slide, that gravity lands the
## body on a floor, that a water volume flips the grammar, and that the camera
## follows what moved. Every one of those is a scene-tree fact, and every one of
## them is a place this could be silently dead while the unit suite stays green.
##
## Events go in through `Input.parse_input_event`, which pushes them along the
## engine's real delivery path into AxolotlBody._unhandled_input, rather than
## calling the Input System directly. Calling directly would skip exactly the
## seam most likely to be miswired. This file lives in `dev/` and is deliberately
## outside the REQ-024 AC-6 sweep, which covers `core/` and `worlds/` — the rule
## is that no GAME system reads raw input, and a headless harness driving the
## game from outside is not a game system. If that sweep is ever widened, this
## file needs an explicit exemption rather than a rewrite.
##
## Not a GdUnit4 suite: the runner executes suites inside _initialize() and never
## iterates a frame, so nothing there can step physics. This is the seed of
## REQ-026 AC-4's playthrough test, which needs the same frame-stepping shape.

const SETTLE_FRAMES := 30
const WALK_FRAMES := 90
## A 6 m/s hop against 18 m/s^2 gravity is airborne for ~0.67 s, which is 40
## frames at 60 Hz — so 40 would sample the landing on the exact frame it
## happens. The margin is for the tuning moving, not for flakiness.
const HOP_FRAMES := 75
const STOP_FRAMES := 45
const CLIMB_APPROACH := 70
const CLIMB_FRAMES := 80
const SWIM_FRAMES := 120

var _body: AxolotlBody
var _camera: CameraFollow

var _frame: int = 0
var _phase: int = 0
var _phase_start: int = 0

var _failures: PackedStringArray = []
var _checks: int = 0

var _rest_position: Vector3 = Vector3.ZERO
var _walk_start: Vector3 = Vector3.ZERO
var _hop_peak: float = -INF
var _swim_start: Vector3 = Vector3.ZERO
var _saw_water_grammar := false
var _camera_start: Vector3 = Vector3.ZERO
var _stop_start: Vector3 = Vector3.ZERO
var _climb_base: float = 0.0
var _climb_started := false


func _ready() -> void:
	_body = get_tree().current_scene.get_node_or_null("Axolotl") as AxolotlBody
	_camera = get_tree().current_scene.get_node_or_null("Camera") as CameraFollow

	if _body == null or _camera == null:
		_fail("scene is missing Axolotl or Camera")
		_finish()
		return

	_body.grammar_changed.connect(func(g: MovementGrammar.Grammar) -> void:
		if g == MovementGrammar.Grammar.WATER:
			_saw_water_grammar = true)
	_camera_start = _camera.global_position
	_body.get_controller().climb_started.connect(
		func() -> void: _climb_started = true)


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)


func _fail(message: String) -> void:
	_checks += 1
	_failures.append(message)


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _elapsed() -> int:
	return _frame - _phase_start


func _advance() -> void:
	_phase += 1
	_phase_start = _frame


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _body == null:
		return

	match _phase:
		0:
			_settle()
		1:
			_walk()
		2:
			_stop()
		3:
			_hop()
		4:
			_climb()
		5:
			_swim()
		6:
			_report()


## Gravity must find the floor, and the land grammar must be the one in force.
func _settle() -> void:
	if _elapsed() < SETTLE_FRAMES:
		return

	_rest_position = _body.global_position
	_check(_body.is_on_floor(),
		"the axolotl never landed: gravity or the floor collision is not wired")
	_check(absf(_rest_position.y - 0.8) < 0.15,
		"resting height was %.3f, expected ~0.8 (capsule half-height on y=0)"
			% _rest_position.y)
	_check(_body.get_controller().get_grammar() == MovementGrammar.Grammar.LAND,
		"expected the land grammar on the ground")
	_check(not _body.is_in_water(), "the axolotl started in water")
	_advance()


## A held key must travel event -> Input System -> intent -> controller ->
## move_and_slide as actual displacement.
func _walk() -> void:
	if _elapsed() == 1:
		_walk_start = _body.global_position
		_key(KEY_W, true)
		return
	if _elapsed() < WALK_FRAMES:
		return

	_key(KEY_W, false)
	var travelled := _body.global_position - _walk_start
	_check(travelled.z < -1.0,
		"holding W moved the axolotl %.3f m along Z; expected it to walk forward"
			% travelled.z)
	_check(_body.is_on_floor(), "the axolotl left the ground while waddling")
	_advance()


## RELEASING the key must stop the axolotl.
##
## This phase exists because its absence let a real bug ship: both grammars
## documented "absence of steering preserves momentum" and nothing ever took
## that momentum away, so the axolotl coasted at full waddle speed until it
## walked off the level. The old walk phase released W and immediately moved on
## without ever checking it had stopped.
func _stop() -> void:
	if _elapsed() == 1:
		_stop_start = _body.global_position
		return
	if _elapsed() < STOP_FRAMES:
		return

	var drifted := _body.global_position.distance_to(_stop_start)
	_check(drifted < 0.5,
		"the axolotl drifted %.2f m in %d frames after the key was released; "
			% [drifted, STOP_FRAMES] + "it should have stopped")
	_check(Vector2(_body.velocity.x, _body.velocity.z).length() < 0.1,
		"horizontal speed was still %.3f after release"
			% Vector2(_body.velocity.x, _body.velocity.z).length())
	_advance()


## The hop is grounded-gated in the controller and the fall is the wrapper's, so
## a rise followed by a return to rest proves both halves are connected.
func _hop() -> void:
	if _elapsed() == 1:
		_key(KEY_SPACE, true)
		return
	if _elapsed() == 3:
		_key(KEY_SPACE, false)
	_hop_peak = maxf(_hop_peak, _body.global_position.y)

	if _elapsed() < HOP_FRAMES:
		return

	_check(_hop_peak > _rest_position.y + 0.5,
		"the hop peaked at %.3f, only %.3f above rest"
			% [_hop_peak, _hop_peak - _rest_position.y])
	_check(_body.is_on_floor(),
		"the axolotl never came back down: gravity is not being applied")
	_advance()


## Climbing needs BOTH halves wired: the body must notice a climbable wall and
## call try_climb, and forward steering must then run UP the wall rather than
## into it. Both were broken while the unit tests stayed green.
func _climb() -> void:
	if _elapsed() == 1:
		# In front of the climbable wall (x 9..19, face at z=-11.5), facing it.
		_body.global_position = Vector3(14.0, 0.8, -9.0)
		_body.velocity = Vector3.ZERO
		_body.get_input_system().clear()
		_key(KEY_W, true)
		return

	# Walked into the wall by now; ask to climb, still pushing forward.
	if _elapsed() == CLIMB_APPROACH:
		_climb_base = _body.global_position.y
		_key(KEY_E, true)
		return
	if _elapsed() == CLIMB_APPROACH + 2:
		_key(KEY_E, false)
		return

	if _elapsed() < CLIMB_APPROACH + CLIMB_FRAMES:
		return

	_key(KEY_W, false)
	_check(_climb_started,
		"the climb never attached: the body is not reporting the climbable "
			+ "wall to the controller")
	_check(_body.global_position.y > _climb_base + 0.5,
		"attached but rose only %.2f m; forward steering is driving into the "
			% (_body.global_position.y - _climb_base) + "wall rather than up it")
	_advance()


## Dropped into the pool: the volume must flip the grammar, and the SAME key
## that was walking must now steer in three dimensions.
func _swim() -> void:
	if _elapsed() == 1:
		_body.global_position = Vector3(0.0, -4.0, 18.0)
		_body.velocity = Vector3.ZERO
		return

	# Two frames for the Area3D overlap to register before asserting on it.
	if _elapsed() == 4:
		_check(_body.is_in_water(),
			"the water volume did not report the axolotl inside it")
		_check(_body.get_controller().get_grammar()
				== MovementGrammar.Grammar.WATER,
			"the grammar did not change to water")
		_swim_start = _body.global_position
		_key(KEY_SPACE, true)
		return

	if _elapsed() < SWIM_FRAMES:
		return

	_key(KEY_SPACE, false)
	var risen := _body.global_position.y - _swim_start.y
	_check(risen > 0.5,
		"SPACE rose %.3f m in water; in water it must steer upward, not hop"
			% risen)
	_check(_saw_water_grammar,
		"grammar_changed never announced the water grammar")
	_advance()


func _report() -> void:
	var moved := _camera.global_position.distance_to(_camera_start)
	_check(moved > 1.0,
		"the camera never moved: it is not following the axolotl")
	_check(_camera.global_position.distance_to(_body.global_position) < 12.0,
		"the camera ended %.2f m from the axolotl; the rig lost its target"
			% _camera.global_position.distance_to(_body.global_position))

	# Proximity is not framing. A camera can sit the correct distance away and
	# still be aimed at the sky — which is exactly the bug a rendered frame
	# caught and this check now pins: the axolotl must be near the view axis,
	# not merely nearby.
	var forward := -_camera.global_transform.basis.z
	var to_target := (_body.global_position - _camera.global_position).normalized()
	_check(forward.dot(to_target) > 0.9,
		"the axolotl is %.2f off the camera's view axis (1.0 is centred); "
			% forward.dot(to_target)
			+ "the camera is near it but not looking at it")
	_finish()


func _finish() -> void:
	print("\n%s" % "=".repeat(66))
	if _failures.is_empty():
		print("GREYBOX SMOKE: %d checks passed" % _checks)
	else:
		print("GREYBOX SMOKE: %d of %d checks FAILED"
			% [_failures.size(), _checks])
		for message: String in _failures:
			print("  - %s" % message)
	get_tree().quit(1 if not _failures.is_empty() else 0)
