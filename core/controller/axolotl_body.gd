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
var _motion: HeroMotion
var _model_base_position := Vector3.ZERO

## Overlapping water volumes, counted rather than flagged: two volumes meeting at
## a seam must not read as "left the water" when the player crosses the join.
var _water_volumes: int = 0
var _water_sources: Array[WaterVolume] = []
var _immersed: bool = false


func _ready() -> void:
	initialise()
	floor_snap_length = 0.18
	var trail := WaterTrail.new()
	trail.name = "WaterTrail"
	add_child(trail)
	var surface_effects := HeroSurfaceEffects.new()
	surface_effects.name = "HeroSurfaceEffects"
	add_child(surface_effects)


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
	_controller.sync_body_position(global_position if is_inside_tree() else position)

	if not model_path.is_empty():
		_model = get_node_or_null(model_path) as Node3D
	_animator = HeroAnimator.new()
	if _model != null:
		# The look is the client's: dress the imported model in the shared
		# hero materials, whatever the exporter wrote into the file.
		HeroSkin.apply(_model)
		preload("res://core/rendering/hero_backpack.gd").attach(_model)
		_model_base_scale = _model.scale
		_animator.bind(_model)
		_model_base_position = _model.position
		var skeletons := _model.find_children("*","Skeleton3D",true,false)
		if not skeletons.is_empty():
			_motion = HeroMotion.new()
			_motion.name = "SecondaryMotion"
			(skeletons[0] as Skeleton3D).add_child(_motion)
			_motion.bind(self,_model)
			_animator.install_dance(skeletons[0] as Skeleton3D,_motion._feet)
	_input.ability_verb_requested.connect(_on_hero_ability)
	if _model!=null:
		_soundscape=preload("res://core/audio/game_soundscape.gd").new()
		_soundscape.name="Soundscape";add_child(_soundscape)
		_make_dance_hud()
		_input.device_changed.connect(func(_device: String,_prompts: String) -> void:_refresh_dance_hud())
	_squash = HeroSquash.new(_tuning)
	_controller.hopped.connect(_squash.on_hop)

	# The action clips are triggered by the VERB, never guessed from motion: a
	# roll and a fast waddle look identical to a velocity sample, and the whole
	# point of the dodge is that the player can see they committed to it.
	_controller.rolled.connect(
		func() -> void: _animator.play_action(HeroAnimator.ROLL,_controller.get_roll().duration_seconds()))
	_controller.spin_sprint_started.connect(
		func() -> void: _animator.play_action(HeroAnimator.SPIN,_controller.get_spin_sprint().duration_seconds()))
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

func get_visual_motion() -> HeroMotion:
	return _motion

func reset_visual_motion() -> void:
	if _motion != null:
		_motion.reset_pose(_controller.get_heading_yaw())
	if _animator != null:
		_animator.reset()


## The visual half of losing a capability (REQ-019's comedic register): the
## world's runtime calls this when the regeneration system announces a loss,
## so the flinch is tied to the event rather than guessed from motion.
func play_hurt() -> void:
	stop_dance()
	if _animator != null:
		_animator.play_hurt()


func is_in_water() -> bool:
	return _water_volumes > 0 or _immersed


func register_water(volume: WaterVolume) -> void:
	if not _water_sources.has(volume):
		_water_sources.append(volume)
	refresh_water_state()


func unregister_water(volume: WaterVolume) -> void:
	_water_sources.erase(volume)
	refresh_water_state()


func get_water_volume() -> WaterVolume:
	var selected: WaterVolume = null
	for volume: WaterVolume in _water_sources:
		if is_instance_valid(volume) and (selected == null or volume.water_priority > selected.water_priority):
			selected = volume
	return selected


func refresh_water_state() -> void:
	var previous: bool = is_in_water()
	var volume: WaterVolume = get_water_volume()
	var point: Vector3 = global_position if is_inside_tree() else position
	_immersed = volume != null and volume.should_swim(point, _immersed)
	if previous != is_in_water():
		water_state_changed.emit(is_in_water())


func clear_water_contacts() -> void:
	for volume: WaterVolume in _water_sources:
		if is_instance_valid(volume):
			volume.forget_body(self)
	_water_sources.clear()
	refresh_water_state()


func resample_water_contacts() -> void:
	if not is_inside_tree():
		return
	# Teleports within the same Area3D do not produce another entry signal.
	for node: Node in get_tree().get_nodes_in_group("water_volumes"):
		var volume := node as WaterVolume
		if volume != null and volume.can_process() and volume.contains_point(global_position,0.55):
			volume.track_body(self)


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

var _net_captured := false
var _capture_ui: CanvasLayer
var _capture_label: Label

func set_net_captured(value: bool) -> void:
	if value:stop_dance()
	if _animator!=null:_animator.allow_water_whack=value
	_net_captured=value
	velocity=Vector3.ZERO
	if _controller != null: _controller.set_net_captured(value)
	if _input != null:
		_input.clear()
		_input.set_grammar(MovementGrammar.Grammar.LAND if value else _controller.get_grammar())
	if not value and is_instance_valid(_capture_ui):
		_capture_ui.queue_free();_capture_ui=null;_capture_label=null

func show_net_capture(seconds: float, count: int) -> void:
	if not is_instance_valid(_capture_label):
		_capture_ui=CanvasLayer.new();_capture_ui.layer=30;add_child(_capture_ui)
		_capture_label=Label.new();_capture_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_capture_label.position=Vector2(-280,-125);_capture_label.custom_minimum_size=Vector2(560,90)
		_capture_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_capture_label.add_theme_font_size_override("font_size",26)
		_capture_label.add_theme_color_override("font_outline_color",Color.BLACK)
		_capture_label.add_theme_constant_override("outline_size",6)
		_capture_ui.add_child(_capture_label)
	_capture_label.text="CAUGHT — TAIL WHACK TO ESCAPE!\n%d / 3 whacks   ·   %.1f seconds" % [count,seconds]

func _physics_process(delta: float) -> void:
	if _controller == null or _input == null:
		return
	# Deep-water surface launches retain the physics server's exit timing.
	for volume: WaterVolume in _water_sources.duplicate():
		if not is_instance_valid(volume):
			_water_sources.erase(volume)
		elif not volume.can_process() or (volume.shallow_wading_enabled and not volume.contains_point(global_position,0.55)):
			volume.forget_body(self)
			_water_sources.erase(volume)
	refresh_water_state()

	# The controller reasons about the body's position for the grapple and the
	# climb ceiling, so it is told where the body actually ended up last frame
	# rather than integrating a position of its own that could drift from the
	# one collision resolved.
	_controller.sync_body_position(global_position if is_inside_tree() else position)
	_controller.set_grounded(is_on_floor())

	var intent := _input.poll_intent()
	intent.direction = _camera_relative(intent.direction)
	if is_dancing() and (is_in_water() or not is_on_floor() or not intent.direction.is_zero_approx() or not intent.verbs.is_empty()):stop_dance()
	_controller.physics_step(delta, is_in_water(),PlayerIntent.none() if is_dancing() else intent)
	if is_dancing():_controller.set_velocity(Vector3.ZERO)

	velocity = _controller.get_velocity()
	_apply_gravity(delta)
	var drift := Vector3.ZERO
	var water: WaterVolume = get_water_volume()
	if water != null and is_in_water():
		drift = water.flow_at(global_position)
		velocity += drift
		if not drift.is_zero_approx() and is_zero_approx(intent.direction.y) and global_position.y > water.surface_at(global_position)-0.65:
			velocity.y = minf(velocity.y, water.surface_slope_at(global_position).dot(Vector2(velocity.x,velocity.z)))

	var motion_start := global_position
	if _net_captured or is_dancing():
		velocity=Vector3.ZERO;drift=Vector3.ZERO
	else:
		# Swimming has no floor or slope stops: glide along rock and tunnel walls.
		motion_mode = MOTION_MODE_FLOATING if is_in_water() else MOTION_MODE_GROUNDED
		wall_min_slide_angle = 0.0 if is_in_water() else deg_to_rad(15.0)
		move_and_slide()

	if not _net_captured: _update_climb(intent, delta)

	# A landing is the floor flag going false to true on land. Water has no
	# floor to slap; brushing the seabed while swimming is not a landing.
	var grounded := is_on_floor()
	if grounded and not _was_grounded and not is_in_water():
		_squash.on_land()
		play_sound(&"landing")
	_was_grounded = grounded

	# Animation follows measured travel, including slopes and collision stops.
	var travelled_velocity := (global_position - motion_start) / maxf(delta, 0.0001)
	var animation_velocity := travelled_velocity - drift if is_in_water() else travelled_velocity
	var was_dancing:=is_dancing()
	_animator.step(delta, is_in_water(), grounded, animation_velocity)
	if was_dancing and not is_dancing():
		if _soundscape!=null:_soundscape.call("set_dancing",false)
		_refresh_dance_hud()

	if _model != null:
		# Yaw then pitch, in that order: the pitch is about the model's OWN
		# lateral axis, so it has to be applied after the turn or a diving
		# axolotl swimming east would tip sideways instead of nose-down.
		if _motion != null:
			_motion.prepare(delta,is_in_water(),grounded,travelled_velocity,_controller.get_heading_yaw(),_controller.get_pitch(),get_floor_normal() if grounded else Vector3.UP)
			_model.rotation = _motion.visual_rotation
			_model.position = _model_base_position+Vector3.UP*_motion.visual_offset
		else:
			_model.rotation = Vector3(_controller.get_pitch(),_controller.get_heading_yaw(),0)
		_model.scale = _model_base_scale * _squash.step(delta)

	# Collision may have cancelled the motion the controller asked for — walking
	# into a wall, or landing. Handing the resolved velocity back keeps the
	# controller's momentum honest instead of letting it accumulate speed against
	# geometry it never actually moved through.
	var relative_velocity: Vector3 = velocity - drift
	if not drift.is_zero_approx():
		for axis: int in 3:
			if is_zero_approx(velocity[axis]):
				relative_velocity[axis] = 0.0
	_controller.set_velocity(relative_velocity)
	_controller.sync_body_position(global_position if is_inside_tree() else position)


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
	_input.set_grammar(MovementGrammar.Grammar.LAND if _net_captured else grammar)
	grammar_changed.emit(grammar)



# Cosmetic groove reward: progression is delivered by the world's collectible system.
const DANCE_UNLOCK_COUNT := 5
var crayfish_count := 0
var _soundscape: Node
var _dance_label: Label
var _dance_hud: CanvasLayer
func is_dancing() -> bool:
	return _animator!=null and _animator.get_current_action()==HeroAnimator.DANCE
func set_crayfish_count(count: int, celebrate: bool=false) -> void:
	var was_unlocked:=crayfish_count>=DANCE_UNLOCK_COUNT
	crayfish_count=maxi(crayfish_count,count)
	_refresh_dance_hud()
	if celebrate and not was_unlocked and crayfish_count>=DANCE_UNLOCK_COUNT:play_sound(&"dance_unlocked")
func play_sound(id: StringName) -> void:
	if _soundscape!=null:_soundscape.call("play",id)
func _make_dance_hud() -> void:
	_dance_hud=CanvasLayer.new();_dance_hud.layer=12;add_child(_dance_hud)
	_dance_label=Label.new();_dance_hud.add_child(_dance_label)
	_dance_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_dance_label.offset_left=-350;_dance_label.offset_right=-20;_dance_label.offset_top=18;_dance_label.offset_bottom=83
	_dance_label.custom_minimum_size=Vector2(330,65)
	_dance_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	_dance_label.add_theme_font_size_override("font_size",19)
	_dance_label.add_theme_constant_override("outline_size",5)
	_refresh_dance_hud()
func _refresh_dance_hud() -> void:
	if _dance_label==null:return
	var prompt:="G" if _input==null or _input.get_device()==InputDevice.Kind.KEYBOARD_MOUSE else "D-pad Down"
	_dance_label.text=("Glowing crayfish  %d / %d" % [mini(crayfish_count,DANCE_UNLOCK_COUNT),DANCE_UNLOCK_COUNT])+ ("\n"+prompt+": dance on shore" if crayfish_count>=DANCE_UNLOCK_COUNT else "\nCollect five to unlock the groove")
	if is_dancing():_dance_label.text="Crayfish groove!\nMove or press "+prompt+" to stop"
func _on_hero_ability(id: String) -> void:
	if id=="dance":request_dance()
func can_dance() -> bool:
	if crayfish_count<DANCE_UNLOCK_COUNT or _net_captured or is_in_water() or not is_on_floor() or velocity.length()>.45:return false
	if _controller.is_climbing() or _controller.get_grapple().is_attached() or not _animator.get_current_action().is_empty():return false
	if get_floor_normal().y<.82 or test_move(global_transform,Vector3.UP*.85):return false
	# Check the small dance footprint so a heel tap cannot hang over a ledge.
	for offset: Vector3 in [Vector3(.5,0,.45),Vector3(-.5,0,.45),Vector3(.5,0,-.45),Vector3(-.5,0,-.45)]:
		var point:=global_position+offset
		var query:=PhysicsRayQueryParameters3D.create(point,point+Vector3.DOWN*1.3,collision_mask,[get_rid()])
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or (hit["normal"] as Vector3).y<.7:return false
	return true
func request_dance() -> bool:
	if is_dancing():stop_dance();return true
	if not can_dance():
		if _dance_label!=null:_dance_label.text="Collect five crayfish to dance" if crayfish_count<DANCE_UNLOCK_COUNT else "Find a flat, clear spot on shore to dance"
		return false
	if not _animator.play_action(HeroAnimator.DANCE):return false
	velocity=Vector3.ZERO;_controller.set_velocity(Vector3.ZERO)
	if _soundscape!=null:_soundscape.call("set_dancing",true)
	_refresh_dance_hud();return true
func stop_dance() -> void:
	if not is_dancing():return
	_animator.reset()
	if _soundscape!=null:_soundscape.call("set_dancing",false)
	_refresh_dance_hud()

## Visual suit mount only. Powers will be registered through the controller's
## capability/ability interfaces when the supplied suit's design is available.
func get_suit_mount() -> Node3D:
	return get_node_or_null("Model/SuitMount") as Node3D
