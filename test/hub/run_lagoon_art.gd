extends SceneTree

var checks: int = 0
var failures: PackedStringArray = []

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func run() -> void:
	var stage := (load("res://hub/open_lagoon.tscn") as PackedScene).instantiate() as Node3D
	stage.set("profile_path", "")
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var hub := stage.get_node("OpenLagoon") as OpenLagoon
	var art := hub.get_node("LagoonArt") as LagoonArt
	check(art.get_child_count() < 32,"Landscape should be batched by material")
	check(art.find_children("*","StaticBody3D",true,false).size() >= 18,"Solid lagoon rocks carry physical collision")
	var holder := stage.get_node("WorldLighting/WorldEnvironment") as WorldEnvironment
	var sunny: Environment = holder.environment
	var sun := stage.get_node("WorldLighting/Sun") as DirectionalLight3D
	var hub_rotation: Vector3 = sun.rotation
	var hub_bias: float = sun.shadow_normal_bias
	var hub_depth_bias: float = sun.shadow_bias
	var portals: Array[WorldPortal] = hub.get_registry().get_available()
	check(portals.size() == 3,"The supplied game should expose three available tunnels")
	for portal: WorldPortal in portals:
		var entrance := hub.find_child("Portal_%s" % portal.world_id,true,false) as Node3D
		check(entrance != null and entrance.has_node("WaterTunnel"),"Registry portal should have tunnel art")
		var triggers: Array[Node] = entrance.find_children("*","Area3D",true,false)
		check(triggers.size() == 1,"Available tunnel should retain exactly one entry trigger")
		check(hub.enter_world(portal.world_id),"Every existing level should still load")
		await process_frame
		check(holder.environment != sunny,"World entry must restore shared lighting")
		check(not art.is_visible_in_tree(),"Lagoon art must disappear inside a level")
		hub.notify_finish_condition_met()
		await process_frame
		await process_frame
		check(holder.environment == sunny,"Return must restore lagoon lighting")
		check(sun.rotation.is_equal_approx(hub_rotation),"Return must restore lagoon sun direction")
		check(is_equal_approx(sun.shadow_normal_bias,hub_bias),"Return must restore lagoon shadow bias")
		check(is_equal_approx(sun.shadow_bias,hub_depth_bias),"Return must restore lagoon depth bias")
		check(art.is_visible_in_tree(),"Return must reveal lagoon art")
	stage.queue_free()
	await process_frame
	print("LAGOON ART: %d checks, %d failures" % [checks,failures.size()])
	for failure: String in failures:
		print("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)
