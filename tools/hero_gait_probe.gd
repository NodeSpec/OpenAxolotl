extends SceneTree

## Measures how far the hero's feet slide over the ground while they are on it
## (REQ-002: "feet that plant").
##
##     godot --headless --path . --audio-driver Dummy --fixed-fps 60 \
##           --script tools/hero_gait_probe.gd
##
## WHY THIS EXISTS. "The feet skate" is the complaint every platformer hero
## gets and the one nobody can argue with a screenshot, because skating is a
## property of MOTION. So this drives the real game — real input events, the
## real controller, the real skeleton after every modifier has run — and
## reports one number per speed:
##
##     slide = distance the feet travelled over the ground while touching it
##             ------------------------------------------------------------
##             distance the body travelled in that same contact time
##
## 1.00 is a foot glued to the body: it crosses the ground exactly as fast as
## the animal does, which is skating. 0.00 is a foot glued to the ground: the
## body passes over it, which is walking.
##
## The foot is sampled on the skeleton's own `modification_processed` signal —
## after animation AND procedural correction — so the number describes the
## pose that reaches the screen, not the clip that went in. Contact is decided
## by height above the ground under the foot and nothing else, so the same
## probe measures any rig and any animation layer; it knows nothing about
## gait phases or planted flags and cannot be flattered by them.
##
## It prints one `GAIT PROBE` line of JSON per speed and exits 0. It asserts
## nothing: it is an instrument. The thresholds live in the test suite.

## A foot this close to the ground under it is touching it.
const CONTACT_HEIGHT := 0.03

## Stick deflections to measure, slowest first. The input layer turns these
## into walking speeds through its own deadzone, so the speeds are whatever
## the game makes of them; each line reports the speed it actually measured.
const DEFLECTIONS: Array[float] = [0.35, 0.60, 1.00]

const WARMUP_FRAMES := 45
const MEASURED_FRAMES := 150

var stage: Node3D
var hub: OpenLagoon
var body: AxolotlBody
var motion: HeroMotion
var recording := false
var rows: Array[Dictionary] = []


func _initialize() -> void:
	run.call_deferred()


func frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func stick(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)


func _sample() -> void:
	if not recording:
		return
	var feet: Array[Vector3] = []
	var heights: Array[float] = []
	var space := body.get_world_3d().direct_space_state
	for foot: int in 4:
		var at: Vector3 = motion.foot_position(foot)
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
			at + Vector3.UP * 0.5, at + Vector3.DOWN * 1.0,
			body.collision_mask, [body.get_rid()]))
		feet.append(at)
		heights.append(at.y - (hit["position"] as Vector3).y if not hit.is_empty() else INF)
	rows.append({"body": body.global_position, "feet": feet, "heights": heights})


func _report(deflection: float, seconds: float) -> void:
	var travelled := 0.0
	for i: int in range(1, rows.size()):
		var step: Vector3 = (rows[i]["body"] as Vector3) - (rows[i - 1]["body"] as Vector3)
		travelled += Vector2(step.x, step.z).length()
	var speed: float = travelled / seconds
	var per_frame: float = travelled / maxf(1.0, rows.size() - 1.0)

	var slides: Array[float] = []
	var contact: Array[float] = []
	var lowest: Array[float] = []
	var slid_total := 0.0
	var contact_frames_total := 0
	for foot: int in 4:
		var slid := 0.0
		var touching := 0
		var low := INF
		for i: int in range(1, rows.size()):
			var height: float = (rows[i]["heights"] as Array[float])[foot]
			var before: float = (rows[i - 1]["heights"] as Array[float])[foot]
			low = minf(low, height)
			if height < CONTACT_HEIGHT and before < CONTACT_HEIGHT:
				var step: Vector3 = (rows[i]["feet"] as Array[Vector3])[foot] \
					- (rows[i - 1]["feet"] as Array[Vector3])[foot]
				slid += Vector2(step.x, step.z).length()
				touching += 1
		slides.append(snappedf(slid / maxf(0.0001, touching * per_frame), 0.001) if touching > 0 else -1.0)
		contact.append(snappedf(float(touching) / maxf(1.0, rows.size() - 1.0), 0.001))
		lowest.append(snappedf(low, 0.001))
		slid_total += slid
		contact_frames_total += touching

	print("GAIT PROBE ", JSON.stringify({
		"stick": deflection,
		"speed_m_per_s": snappedf(speed, 0.01),
		"slide": snappedf(slid_total / maxf(0.0001, contact_frames_total * per_frame), 0.001) if contact_frames_total > 0 else -1.0,
		"slide_per_foot": slides,
		"contact_fraction_per_foot": contact,
		"lowest_height_per_foot": lowest,
		"clip": body.get_animator().get_current_clip(),
		"frames": rows.size(),
	}))


func run() -> void:
	stage = load("res://hub/open_lagoon.tscn").instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	hub = stage.get_node("OpenLagoon") as OpenLagoon
	body = stage.get_node("Axolotl") as AxolotlBody
	motion = body.get_visual_motion()
	motion.modification_processed.connect(_sample)

	for deflection: float in DEFLECTIONS:
		body.get_input_system().clear()
		stick(0.0)
		hub._move_player_to(Vector3(-3, 1.1, 9))
		body.get_camera().set_yaw_deg(0.0)
		await frames(40)
		stick(deflection)
		await frames(WARMUP_FRAMES)
		rows.clear()
		recording = true
		await frames(MEASURED_FRAMES)
		recording = false
		_report(deflection, MEASURED_FRAMES / float(Engine.physics_ticks_per_second))
		stick(0.0)
		await frames(20)

	stage.queue_free()
	await process_frame
	quit(0)
