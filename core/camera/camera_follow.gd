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
## YAW, for now, TRAILS THE DIRECTION OF TRAVEL. There is no look axis: REQ-024's
## verb set is the movement and ability verbs the requirement enumerates, and a
## camera stick is not among them. A trailing camera is the honest thing to build
## against the interfaces that exist rather than inventing an unbudgeted verb —
## and it reads correctly for a proving scene. A real look axis is a REQ-005 /
## REQ-024 follow-up, and it lands as one more input verb feeding desired_yaw
## here, not as a change to the rig.

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


func _ready() -> void:
	var errors: Array[TuningError] = []
	var tuning := TuningData.load_from_file(tuning_path, errors)
	for error: TuningError in errors:
		push_error(str(error))
	if tuning == null:
		set_physics_process(false)
		return

	_rig = CameraRig.new(tuning)
	_rig.set_occluder_probe(SceneOccluderProbe.new(self))

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


func get_rig() -> CameraRig:
	return _rig


func _physics_process(delta: float) -> void:
	if _rig == null or _target == null:
		return

	_rig.update(delta, _target.global_position, _desired_yaw())
	_apply()


func _desired_yaw() -> float:
	if _body == null:
		return _yaw_deg

	var travel := _body.velocity
	travel.y = 0.0
	if travel.length() >= YAW_HOLD_SPEED:
		# Godot's -Z forward: the yaw that puts the camera BEHIND the direction
		# of travel is the heading itself.
		_yaw_deg = rad_to_deg(atan2(-travel.x, -travel.z))
	return _yaw_deg


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
	rotation = Vector3(deg_to_rad(-_rig.get_pitch_deg()),
		deg_to_rad(_rig.get_yaw_deg()), 0.0)


func _on_grammar_changed(grammar: MovementGrammar.Grammar) -> void:
	# The rig frames water and land differently — distance and pitch both change
	# — and it is told about the grammar rather than reading the controller,
	# because the architecture declares no Camera -> Controller edge.
	_rig.set_in_water(grammar == MovementGrammar.Grammar.WATER)
