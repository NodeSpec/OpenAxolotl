extends SceneTree
var passed := 0
var failed := 0
func check(value: bool, label: String) -> void:
	if value: passed+=1;print("PASS ",label)
	else: failed+=1;push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for kind: String in ["netbot","hookline_rig"]:
		var packed:=load("res://core/enemies/visuals/%s_visual.tscn"%kind) as PackedScene
		var actor:=packed.instantiate() as Node3D;actor.set("autoplay_idle",false);root.add_child(actor)
		var other:=packed.instantiate() as Node3D;other.set("autoplay_idle",false);root.add_child(other)
		var player:=actor.get_node("AnimationPlayer") as AnimationPlayer
		player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		check(player.get_animation_list().size()==8,kind+" eight authored clips")
		var triangles:=0
		for item: Node in actor.find_children("*","MeshInstance3D",true,false):
			var mesh: Mesh=(item as MeshInstance3D).mesh
			for surface: int in mesh.get_surface_count():
				var arrays:=mesh.surface_get_arrays(surface)
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				triangles+=indices.size()/3 if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()/3
		check(triangles<=10000,kind+" triangle budget: "+str(triangles))
		for clip: StringName in player.get_animation_list():
			var animation:=player.get_animation(clip)
			check((animation.loop_mode==Animation.LOOP_LINEAR)==(clip==&"idle"),kind+" loop policy "+clip)
			for track: int in animation.get_track_count():
				var path:=animation.track_get_path(track)
				check(actor.has_node(NodePath(path.get_concatenated_names())),kind+" bound track "+String(path))
		check(bool(actor.call("play_state",&"warn")),kind+" starts warning")
		player.advance(player.get_animation(&"warn").length+.01)
		check(not bool(actor.get("attack_active")),kind+" warning never activates hit window")
		check(actor.get("state")==&"warn",kind+" warning holds for controller")
		actor.call("play_state",&"attack");player.advance(.25)
		check(bool(actor.get("attack_active")),kind+" release activates window")
		check(not bool(other.get("attack_active")),kind+" instances are independent")
		if kind=="netbot":
			check(absf((actor.get_node("Facing/Body/CaptureArm") as Node3D).rotation.z)>.05,"netbot capture arm moves separately")
		else:
			var hook:=actor.get_node("Facing/Body/HookRight") as Node3D
			var cable:=actor.get_node("Facing/Body/CableRight") as MeshInstance3D
			check(not bool(actor.call("lock_attack_target",Vector3.ONE)),"hookline cannot retarget after throw")
			check(hook.position.z>2.5,"hookline hooks throw forward toward target")
			check((cable.position+cable.basis.y*.5).distance_to(hook.position)<.0001,"hookline cable ends at hook pivot")
		actor.call("play_state",&"stagger")
		check(not bool(actor.get("attack_active")),kind+" interruption closes window immediately")
		player.advance(.8)
		check(actor.get("state")==&"idle",kind+" stagger returns to idle")
		actor.call("play_state",&"attack");player.advance(.7 if kind=="netbot" else 1.)
		check(actor.get("state")==&"recover",kind+" attack enters recovery")
		check(not bool(actor.get("attack_active")),kind+" recovery is harmless")
		player.advance(3.1)
		check(actor.get("state")==&"idle",kind+" recovery returns to idle")
		actor.call("play_state",&"disabled");player.advance(1.2)
		check(actor.get("state")==&"disabled",kind+" disabled stays inert")
		check(not bool(actor.call("play_state",&"attack")),kind+" disabled rejects attacks")
		check(bool(actor.call("play_state",&"reset")),kind+" explicit reset accepted")
		player.advance(.2)
		check(actor.get("state")==&"idle",kind+" reset returns to idle")
		check(is_zero_approx(float(actor.get("cable_extension"))),kind+" reset retracts cables")
		check(actor.transform==Transform3D.IDENTITY,kind+" no gameplay root motion")
		check(not bool(actor.call("play_state",&"missing")),kind+" unknown clip rejected")
		actor.queue_free();other.queue_free();await process_frame
	print("ANIMATION CHECKS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
