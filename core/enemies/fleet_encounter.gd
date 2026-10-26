class_name FleetEncounter
extends Area3D
## One placed machine: local awareness, visible attack timing, and bounded movement.
const Breakup = preload("res://core/enemies/visuals/fleet_breakup.gd")
@export var underwater := false
@export var notice_range := 6.0
@export var leash_radius := 2.0
@export var patrol_radius := .55
var state: StringName = &"idle"
var home := Vector3.ZERO
var visual: FleetEnemyVisual
var systems: Node
var fleet: DriftFleetSystem
var _clock := 0.0
var _scan := 0.0
var _lost := 0.0
var _cooldown := 0.0
var _player: AxolotlBody
var _hit := false
var _previous_tips: Array[Vector3] = []
var _debris: Node3D
var _home_yaw := 0.0
# Movement is accelerated in metres/second, independent of animation and scan clocks.
var _move_velocity := Vector3.ZERO
var _yaw_velocity := 0.0
var _patrol_clock := 0.0
var _alert: Label3D

func _ready() -> void:
	home=global_position; _home_yaw=rotation.y
	visual=get_node("Visual") as FleetEnemyVisual
	visual.state_finished.connect(_finished)
	add_to_group("fleet_encounters")
	_alert=Label3D.new(); _alert.text="!"; _alert.font_size=72; _alert.pixel_size=.008; _alert.position.y=1.0; _alert.billboard=BaseMaterial3D.BILLBOARD_ENABLED; _alert.modulate=Color(1,.72,.16); _alert.visible=false; add_child(_alert)
	_patrol_clock=float(abs(String(name).hash())%100)/13.0
	visual.set_locomotion(Vector3.ZERO,0.0,underwater,0.0)

func bind_encounter(owner_systems: Node, model: DriftFleetSystem) -> void:
	systems=owner_systems; fleet=model
	fleet.enemy_staggered.connect(_on_staggered)
	fleet.enemy_recovered.connect(_on_recovered)

func _on_staggered(id: String,_kind: String,_seconds: float) -> void:
	if id==String(name): _set_state(&"stagger")

func _on_recovered(id: String) -> void:
	if id==String(name) and state==&"stagger": _set_state(&"idle")

func _exit_tree() -> void:
	if fleet!=null:
		if fleet.enemy_staggered.is_connected(_on_staggered): fleet.enemy_staggered.disconnect(_on_staggered)
		if fleet.enemy_recovered.is_connected(_on_recovered): fleet.enemy_recovered.disconnect(_on_recovered)
	fleet=null; systems=null

func _set_state(next: StringName) -> void:
	state=next; _clock=0.0
	_alert.visible=next in [&"notice",&"warn"]
	if next==&"attack": _hit=false; _move_velocity=Vector3.ZERO; _yaw_velocity=0.0; _previous_tips=_tips()
	visual.play_state(next if next not in [&"pursue",&"return"] else &"idle")

func _finished(clip: StringName) -> void:
	if state==&"disabled": return
	if clip==&"notice" and state==clip: _set_state(&"pursue")
	elif clip==&"warn" and state==clip:
		if _eligible() and _visible_player() and global_position.distance_to(_player.global_position)<=attack_range()+.25:
			visual.lock_attack_target(_player.global_position); _set_state(&"attack")
		else: _set_state(&"return")
	elif clip==&"attack" and state==clip: _set_state(&"recover")
	elif clip==&"recover" and state==clip: _cooldown=1.3; _set_state(&"idle")

func attack_range() -> float: return 2.8 if visual.enemy_kind==&"hookline_rig" else 1.5

func _eligible() -> bool:
	if not is_instance_valid(_player) or systems==null: return false
	if _player.is_in_water()!=underwater or systems._net_capture.active(): return false
	if _player.global_position.distance_to(home)>notice_range+leash_radius: return false
	# Protected checkpoint pads, arrival, crown and downhill finale.
	var local_player: Vector3=systems.get_parent().to_local(_player.global_position)
	if local_player.z>-19.5 or local_player.z < -91.0: return false
	for checkpoint: Node3D in systems._checkpoint_nodes:
		if checkpoint.global_position.distance_to(_player.global_position)<3.5: return false
	return absf(_player.global_position.y-global_position.y)<(2.5 if underwater else 1.5)

func _visible_player() -> bool:
	if not is_instance_valid(_player): return false
	return clear_line(global_position,_player.global_position)

func clear_line(from: Vector3,to: Vector3) -> bool:
	var q:=PhysicsRayQueryParameters3D.create(from,to,1)
	if is_instance_valid(_player): q.exclude=[_player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _owns_attack() -> bool:
	for other: Node in get_tree().get_nodes_in_group("fleet_encounters"):
		if other!=self and other.systems==systems and other.state in [&"notice",&"warn",&"attack",&"recover"]:
			if other.global_position.distance_to(global_position)<10.0: return false
	return true

func _physics_process(delta: float) -> void:
	if fleet==null or state==&"disabled": return
	if not is_instance_valid(_player): _player=get_tree().get_first_node_in_group("player") as AxolotlBody
	_clock+=delta; _patrol_clock+=delta; _cooldown=maxf(0,_cooldown-delta)
	visual.set_locomotion(global_basis.inverse()*_move_velocity,_yaw_velocity,underwater,delta)
	if state==&"stagger": _move_velocity=Vector3.ZERO; _yaw_velocity=0.0; return
	if state==&"attack":
		if not _eligible(): _set_state(&"recover"); return
		_contact_tips(); return
	if state==&"recover": _move_velocity=Vector3.ZERO; _yaw_velocity=0.0; return
	if state==&"return":
		_move_toward(home,delta)
		if global_position.distance_to(home)<.12:
			_turn_toward(_home_yaw,delta)
			if absf(angle_difference(rotation.y,_home_yaw))<.04 and _move_velocity.length()<.05: _set_state(&"idle")
		return
	_scan-=delta
	if _scan<=0:
		_scan=.12
		var sees:=_eligible() and global_position.distance_to(_player.global_position)<notice_range and _visible_player()
		_lost=0.0 if sees else _lost+.12
		if state==&"idle" and sees and _cooldown<=0 and _owns_attack(): _set_state(&"notice")
		elif state in [&"notice",&"pursue",&"warn"] and (not _eligible() or _lost>.24): _set_state(&"return")
	if state in [&"notice",&"pursue",&"warn"] and is_instance_valid(_player):
		var direction:=_player.global_position-global_position
		_turn_toward(atan2(-direction.x,-direction.z),delta)
		if state==&"pursue":
			if direction.length()<=attack_range():
				_move_toward(global_position,delta)
				# Finish aiming before winding up, rather than throwing sideways mid-turn.
				if absf(angle_difference(rotation.y,atan2(-direction.x,-direction.z)))<.18 and _owns_attack(): _set_state(&"warn")
			else: _move_toward(_player.global_position,delta)
		else: _move_toward(global_position,delta)
	elif state==&"idle":
		# A short maintenance patrol; remote machines avoid per-frame physics queries.
		if is_instance_valid(_player) and global_position.distance_squared_to(_player.global_position)<225:
			_move_toward(home+Vector3(sin(_patrol_clock*.4),0,cos(_patrol_clock*.4)) * patrol_radius,delta,.35)
		else: _move_velocity=Vector3.ZERO; _yaw_velocity=0.0

func _turn_toward(yaw: float,delta: float) -> void:
	var error:=angle_difference(rotation.y,yaw)
	# A bounded angular acceleration removes the snap when acquisition reverses a patrol.
	var desired:=clampf(error*4.0,-2.2,2.2)
	_yaw_velocity=move_toward(_yaw_velocity,desired,7.5*delta)
	var turn:=_yaw_velocity*delta
	if absf(turn)>absf(error) and signf(turn)==signf(error): turn=error; _yaw_velocity=0.0
	rotation.y+=turn

func _move_toward(target: Vector3,delta: float,speed_scale: float=1.0) -> void:
	if leash_radius<=0.0: _move_velocity=Vector3.ZERO; return
	var offset:=target-home
	offset.y=clampf(offset.y,-.45,.45) if underwater else 0.0
	var flat:=Vector3(offset.x,0,offset.z).limit_length(leash_radius)
	var destination:=home+Vector3(flat.x,offset.y,flat.z)
	var direction:=destination-global_position
	if not underwater: direction.y=0.0
	var top_speed: float=(.8 if underwater else .95)*speed_scale
	var desired_velocity:=direction.normalized()*minf(top_speed,direction.length()*2.8)
	var acceleration: float=1.8 if underwater else 2.8
	_move_velocity=_move_velocity.move_toward(desired_velocity,acceleration*delta)
	if state in [&"idle",&"return"] and _move_velocity.length()>.04 and direction.length()>.12:
		_turn_toward(atan2(-_move_velocity.x,-_move_velocity.z),delta)
	if _move_velocity.length()<.002: _move_velocity=Vector3.ZERO; return
	var desired:=global_position+_move_velocity*delta
	var leash_offset:=desired-home; leash_offset.y=0.0
	if leash_offset.length()>leash_radius+.01: _move_velocity=Vector3.ZERO; return
	if underwater:
		desired.y=clampf(desired.y,home.y-.45,home.y+.45)
		var inside:=false
		for water: Node in get_tree().get_nodes_in_group("water_volumes"):
			if water.contains_point(desired,-.7): inside=true; break
		if not inside: _move_velocity=Vector3.ZERO; return
	else:
		var floor_y:=global_position.y
		for foot: Vector3 in [Vector3.ZERO,Vector3(.38,0,0),Vector3(-.38,0,0),Vector3(0,0,.38),Vector3(0,0,-.38)]:
			var q:=PhysicsRayQueryParameters3D.create(desired+foot+Vector3.UP*.2,desired+foot-Vector3.UP*1.0,1)
			if is_instance_valid(_player): q.exclude=[_player.get_rid()]
			var hit:=get_world_3d().direct_space_state.intersect_ray(q)
			if hit.is_empty() or hit.normal.y<.8 or absf((hit.position.y+.54)-global_position.y)>.2: _move_velocity=Vector3.ZERO; return
			if foot==Vector3.ZERO: floor_y=hit.position.y+.54
		# Follow small dressed-terrain undulations without a one-frame vertical jump.
		desired.y=move_toward(global_position.y,floor_y,.8*delta)
		for water: Node in get_tree().get_nodes_in_group("water_volumes"):
			if water.contains_point(desired-Vector3.UP*.4,-.2): _move_velocity=Vector3.ZERO; return
	var query:=PhysicsShapeQueryParameters3D.new(); var sphere:=SphereShape3D.new(); sphere.radius=.38; query.shape=sphere; query.collision_mask=1; query.transform=Transform3D(Basis.IDENTITY,global_position); query.motion=desired-global_position
	if is_instance_valid(_player): query.exclude=[_player.get_rid()]
	var sweep:=get_world_3d().direct_space_state.cast_motion(query)
	if sweep[0]<1.0: _move_velocity=Vector3.ZERO; return
	global_position=desired

func _tips() -> Array[Vector3]:
	var result: Array[Vector3]=[]
	if visual.enemy_kind==&"netbot":
		result.append((visual.get_node("Facing/Body/CaptureArm/NetBasket/AttackSocket") as Node3D).global_position)
	else:
		for side: String in ["Left","Right"]: result.append((visual.get_node("Facing/Body/Hook"+side) as Node3D).global_position)
	return result

func _contact_tips() -> void:
	var tips:=_tips()
	if visual.attack_active and not _hit and _visible_player():
		for i: int in tips.size():
			var near:=Geometry3D.get_closest_point_to_segment(_player.global_position,_previous_tips[i],tips[i])
			if near.distance_to(_player.global_position)<(.72 if visual.enemy_kind==&"netbot" else .55):
				_hit=true; systems._on_enemy_contact(self); break
	_previous_tips=tips

func defeat(direction: Vector3) -> void:
	if state==&"disabled": return
	_move_velocity=Vector3.ZERO; _yaw_velocity=0.0
	visual.attack_active=false; visual.get_node("AnimationPlayer").stop(); state=&"disabled"; _alert.visible=false
	_debris=Breakup.new(); get_parent().add_child(_debris); _debris.burst(visual,underwater,direction)
	visual.hide(); set_deferred("monitoring",false); set_deferred("monitorable",false)

func reset_encounter() -> void:
	if is_instance_valid(_debris): _debris.queue_free()
	_move_velocity=Vector3.ZERO; _yaw_velocity=0.0
	visual.reset_locomotion()
	global_position=home; rotation.y=_home_yaw; _hit=false; _lost=0; _cooldown=1.5
	visual.show(); visual.play_state(&"reset"); _set_state(&"idle")
	set_deferred("monitoring",true); set_deferred("monitorable",true)
