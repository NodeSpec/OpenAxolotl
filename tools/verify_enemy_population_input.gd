extends SceneTree
var passed:=0
var failed:=0
func check(ok: bool,message: String) -> void:
	if ok:passed+=1;print("PASS ",message)
	else:failed+=1;push_error(message)
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
	for i: int in n:await physics_frame
func key(body: AxolotlBody,pressed: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=KEY_F;event.pressed=pressed;body.get_input_system().handle_event(event)
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage);current_scene=stage
	var world:=load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D;stage.add_child(world)
	var body:=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody;body.position=Vector3(4,1.3,-11);stage.add_child(body)
	var systems:=WorldSystems.new();systems.world_id="coral_cove";systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json"));world.add_child(systems)
	await frames(4)
	for enemy: FleetEncounter in get_nodes_in_group("fleet_encounters"):enemy.set_physics_process(false)
	var net:=world.get_node("EnemyPopulation/S02_N02") as FleetEncounter
	systems._return_player_to(net.home+Vector3(0,.27,1.25),"");body.get_controller()._heading_yaw=0
	await frames(12);check(body.is_on_floor() and not body.is_in_water(),"hero stands on real garden exit bank")
	check(net.state!=&"disabled","ordinary approach does not defeat robot")
	key(body,true);await frames(2);key(body,false);await frames(35)
	check(net.state==&"disabled","physical F press drives forward animation and robot defeat")
	systems._return_player_to(net.home+Vector3(0,2.5,0),"");await frames(55)
	check(net.state==&"disabled","descending landing physically stomps robot")
	var swimmer:=world.get_node("EnemyPopulation/S03_H02") as FleetEncounter
	systems._return_player_to(swimmer.home+Vector3(0,0,2.8),"");body.get_controller()._heading_yaw=0;await frames(8)
	check(body.is_in_water(),"actual water volume selects swimming grammar")
	check(swimmer.state!=&"disabled","swimming approach is harmless")
	key(body,true);await frames(2);key(body,false);await frames(40)
	check(swimmer.state==&"disabled","physical F swimming charge reaches and breaks robot")
	stage.queue_free();await frames(3);print("POPULATION INPUT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
