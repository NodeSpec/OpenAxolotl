extends SceneTree
var passed:=0
var failed:=0
func check(condition: bool, label: String) -> void:
	if condition:passed+=1
	else:failed+=1;push_error("FAIL: "+label)
func frames(n: int) -> void:
	for i: int in n:await physics_frame
func key(body: AxolotlBody, code: Key, pressed: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;body.get_input_system().handle_event(event)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var floor_body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(20,1,20);shape.shape=box;floor_body.add_child(shape);floor_body.position.y=-.5;stage.add_child(floor_body)
	var body:=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody;body.position=Vector3(0,.85,0);stage.add_child(body)
	var world:=Node3D.new();stage.add_child(world)
	var store:=SaveSystem.new();var systems:=WorldSystems.new();systems.save_system=store;systems.world_id="dance_test"
	var defs: Array=[]
	for i: int in 5:defs.append({"collectibleId":"glow_crayfish_test_%d"%i,"kind":"discovery","displayName":"Crayfish"})
	systems.manifest={"collectibles":defs};world.add_child(systems)
	await frames(20)
	check(body.is_on_floor(),"hero grounded on real collision floor")
	check(not body.request_dance(),"locked before collecting")
	for i: int in 5:
		var pickup:=Area3D.new();pickup.add_to_group("dance_crayfish");pickup.set_meta("collectible_id","glow_crayfish_test_%d"%i);world.add_child(pickup)
		check(systems.collect_node(pickup),"collect unique crayfish %d"%i)
		check(body.crayfish_count==i+1,"progress follows actual pickup")
		if i==3:check(not body.request_dance(),"four crayfish stay locked")
	check(not systems.get_collectibles().collect("glow_crayfish_test_0"),"duplicate discovery cannot be farmed")
	check(int(store.load_section("crayfish_dance").get("count",0))==5,"unlock saved through profile interface")
	check(body.can_dance(),"five unlock safe shore dance")
	key(body,KEY_G,true);key(body,KEY_G,false)
	check(body.is_dancing(),"G starts dance")
	var sound:=body.get_node("Soundscape")
	check((sound.get("groove") as AudioStreamPlayer).playing,"groove plays with dance")
	var original:=body.global_position;await frames(35)
	check(body.global_position.distance_to(original)<.001,"dance does not move collision body")
	check((sound.get("background") as AudioStreamPlayer).volume_db< -30.,"exploration ducks under groove")
	key(body,KEY_W,true);await frames(2);key(body,KEY_W,false)
	check(not body.is_dancing(),"movement cancels dance")
	await frames(35)
	check(not (sound.get("groove") as AudioStreamPlayer).playing,"cancel fades and stops groove")
	check((sound.get("background") as AudioStreamPlayer).volume_db> -6.,"background restored")
	body.enter_water();check(not body.request_dance(),"underwater dance rejected");body.exit_water();await frames(20)
	check(body.request_dance(),"unlock reusable")
	body.set_net_captured(true);check(not body.is_dancing(),"net cancels dance");check(not body.request_dance(),"captured cannot dance");body.set_net_captured(false)
	await frames(2);check(body.request_dance(),"dance after escape");body.play_hurt();check(not body.is_dancing(),"hurt cancels dance")
	await frames(60)
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_DPAD_DOWN;pad.pressed=true;body.get_input_system().handle_event(pad);pad.pressed=false;body.get_input_system().handle_event(pad)
	check(body.is_dancing(),"D-pad Down starts dance")
	body.stop_dance();await frames(15)
	var skeleton:=body.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	check(skeleton.get_bone_pose_position(0).distance_to(skeleton.get_bone_rest(0).origin)<.001,"no residual root translation")
	var player:=body.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	for sample: int in 64:
		var pose:=load("res://core/rendering/hero_dance_clips.gd").sample_pose(skeleton,body._motion._feet,.10+float(sample)/64.*.80) as Array[Transform3D]
		var globals: Array[Transform3D]=[];var support_height:=INF
		for bone: int in skeleton.get_bone_count():
			var parent:=skeleton.get_bone_parent(bone);globals.append((globals[parent] if parent>=0 else Transform3D.IDENTITY)*pose[bone])
			var bone_name:=skeleton.get_bone_name(bone)
			if bone_name.begins_with("leg_b"):support_height=minf(support_height,(globals[bone]*(body._motion._feet[bone_name] as Vector3)).y)
		check(support_height>=-.04 and support_height<.13,"grounded support foot at dance sample %d"%sample)
	check(absf(player.get_animation("dance").length-(sound.get("groove") as AudioStreamPlayer).stream.get_length())<.0001,"music and dance duration agree")
	check(body.request_dance(),"start final complete routine")
	body.get_animator()._action_remaining=.001;await frames(2);check(not body.is_dancing(),"routine ends automatically")
	await frames(25);check(not (sound.get("groove") as AudioStreamPlayer).playing,"natural ending stops groove")
	var bank: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://core/audio/default_bank.json"))
	for kind: String in ["cues","beds"]:
		for id: String in bank[kind]:check(load(bank[kind][id]) is AudioStream,"audio exists: "+id)
	stage.queue_free();await frames(2)
	print("CRAYFISH DANCE: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
