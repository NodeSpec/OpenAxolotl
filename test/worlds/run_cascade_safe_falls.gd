extends SceneTree
var failures: PackedStringArray = []
var world: Node3D
var body: AxolotlBody
var systems: WorldSystems
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var stage := Node3D.new(); root.add_child(stage); current_scene=stage
	world=load("res://worlds/coral_cove/world.tscn").instantiate(); stage.add_child(world)
	world.position=Vector3(70,-6.8,30)
	body=load("res://core/controller/axolotl_body.tscn").instantiate(); stage.add_child(body)
	systems=WorldSystems.new(); systems.world_id="coral_cove"
	systems.manifest=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/coral_cove/world.json"))
	world.add_child(systems)
	await physics_frame
	var before := systems.get_lives().get_lives()
	for row: Array in [["S01 shore",Vector3(-8,2,-13)],["S02 missed landing",Vector3(-24,4,-32)],["S03 grotto",Vector3(-12,1,-65)],["S04 terrace edge",Vector3(24,7,-79)],["S05 courtyard edge",Vector3(23,9,-91)],["S06 finish shore",Vector3(-37,4,-103)],["west floor seam",Vector3(-41.8,1,-36)],["east floor seam",Vector3(39.8,1,-73)],["south floor seam",Vector3(-20,1,-126.8)]]:
		body.clear_water_contacts(); body.position=world.position+(row[1] as Vector3)
		body.velocity=Vector3(0,-2,0); body.get_controller().set_velocity(body.velocity)
		for i in range(140): await physics_frame
		var local := body.position-world.position
		if local.y< -3.8: failures.append(String(row[0])+" fell below closed floor: "+str(local))
		if systems.get_lives().get_lives()!=before: failures.append(String(row[0])+" cost a life")
		print("SAFE DROP ",row[0]," ",local)
	# A deliberately forced escape below the floor must recover without a life cost.
	var checkpoint := world.get_node("Sections/S01/CP_01")
	systems.activate_checkpoint_node(checkpoint)
	body.clear_water_contacts(); body.position=world.position+Vector3(55,-7.2,-40)
	body.velocity=Vector3(3,-12,0); body.get_controller().set_velocity(body.velocity)
	for i in range(60): await physics_frame
	if systems.get_lives().get_lives()!=before: failures.append("emergency return cost a life")
	if body.position.distance_to(systems.get_lives().get_respawn_position())>1.5: failures.append("emergency return missed checkpoint "+str(body.position))
	print("POLISH SAFE FALLS: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
