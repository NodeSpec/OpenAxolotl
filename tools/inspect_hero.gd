extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	root.add_child(body)
	body.set_physics_process(false)
	var model := body.get_node("Model") as Node3D
	var skeleton := model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	print("SKELETON ",skeleton.get_path()," transform=",skeleton.transform)
	for bone: int in skeleton.get_bone_count():
		print(skeleton.get_bone_name(bone)," rest=",skeleton.get_bone_global_rest(bone)," pose=",skeleton.get_bone_pose_rotation(bone))
	var player := model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	for clip: String in player.get_animation_list():
		var animation := player.get_animation(clip)
		print("CLIP ",clip," length=",animation.length," tracks=",animation.get_track_count())
		if clip in ["waddle","spin","whack"]:
			for track: int in animation.get_track_count():
				if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
					print("  ",animation.track_get_path(track)," first=",animation.track_get_key_value(track,0)," keys=",animation.track_get_key_count(track))
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		print("MESH ",mesh.name," bounds=",mesh.get_aabb()," transform=",mesh.transform," skin binds=",mesh.skin.get_bind_count() if mesh.skin else 0)
		if mesh.skin:
			for i: int in mesh.skin.get_bind_count():
				print("  BIND ",i," ",mesh.skin.get_bind_name(i)," bone=",mesh.skin.get_bind_bone(i))
	body.queue_free()
	await process_frame
	quit()
