extends SceneTree
var passed:=0
var failed:=0
func check(ok: bool,message: String) -> void:
	if ok:passed+=1
	else:failed+=1;push_error(message)
func frames(n: int) -> void:
	for i: int in n:await physics_frame
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var world:=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D;stage.add_child(world)
	var body:=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody;body.position=Vector3(4,1.3,-11);stage.add_child(body)
	var save:=SaveSystem.new();var systems:=WorldSystems.new();systems.save_system=save;systems.world_id="coral_cove";systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json"));save.open_world("coral_cove",systems.manifest);world.add_child(systems)
	await frames(20)
	check(get_nodes_in_group("dance_crayfish").size()==13,"all thirteen pickups loaded")
	var count:=0
	for path: String in ["ShoreCrayfish/glow_crayfish_arrival_a","ShoreCrayfish/glow_crayfish_arrival_b","ShoreCrayfish/glow_crayfish_garden_bank","ShoreCrayfish/glow_crayfish_terrace_bank","Sections/S03/RootDive/glow_crayfish_root_0"]:
		var pickup:=world.get_node(path) as Node3D
		body.clear_water_contacts();body.global_position=pickup.global_position+Vector3.UP*.3;body.velocity=Vector3.ZERO;body.get_controller().set_velocity(Vector3.ZERO)
		await frames(35);count+=1
		check(body.crayfish_count==count,"physical pickup counts "+path)
		check(world.get_node_or_null(path)==null,"physical pickup removed "+path)
	body.clear_water_contacts();body.global_position=Vector3(4,1.3,-11);body.velocity=Vector3.ZERO;body.get_controller().set_velocity(Vector3.ZERO);await frames(40)
	check(body.request_dance(),"actual level bank permits unlocked dance")
	systems._return_player_to(Vector3(4,1.3,-11),"");check(not body.is_dancing(),"checkpoint return cancels dance")
	var copy:=SaveSystem.new();var path:="user://crayfish_dance_verification_only.json"
	check(save.save_to_file(path),"test profile saves");check(copy.load_from_file(path),"test profile reloads");check(int(copy.load_section("crayfish_dance").get("count",0))==5,"dance unlock survives disk round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	world.queue_free();await frames(2)
	world=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D;stage.add_child(world)
	systems=WorldSystems.new();systems.save_system=copy;systems.world_id="coral_cove";systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json"));world.add_child(systems);await frames(3)
	await process_frame;await process_frame
	print("RELOAD COUNT ",get_nodes_in_group("dance_crayfish").size())
	check(get_nodes_in_group("dance_crayfish").size()==8,"five collected crayfish remain absent on reload")
	stage.queue_free();await frames(2);print("CRAYFISH WORLD: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
