extends "res://core/enemies/visuals/fleet_animation_preview.gd"
var _systems: WorldSystems
var _hero: AxolotlBody
var _netbot: Area3D
func _ready() -> void:
	super._ready()
	var solid:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(30,.2,30);collision.shape=box;solid.position.y=-.1;solid.add_child(collision);add_child(solid)
	var spawn:=Marker3D.new();spawn.name="CaptureRetry";spawn.position=Vector3(0,.85,-1.4);spawn.add_to_group("spawn_point");add_child(spawn)
	_hero=load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	_hero.position=spawn.position;add_child(_hero)
	_netbot=Area3D.new();_netbot.name="PreviewNetbot";_netbot.position=Vector3(1.25,.53,0);_netbot.set_meta("enemy_id","netbot");_netbot.add_to_group("enemy");add_child(_netbot)
	_systems=WorldSystems.new();_systems.manifest={"worldId":"net_capture_workshop","enemies":[{"enemyId":"netbot"}]};add_child(_systems)
	var layer:=CanvasLayer.new();add_child(layer)
	var button:=Button.new();button.text="Test net catch  |  Tail Whack 3 times before 2 seconds";button.position=Vector2(24,168);button.focus_mode=Control.FOCUS_NONE;layer.add_child(button)
	button.pressed.connect(test_catch)
	var help:=Label.new();help.position=Vector2(24,215);help.text="Default escape input: F / gamepad right bumper. Wait to test checkpoint reset.\nThis button simulates a net hit; enemy targeting and level placement come later.";layer.add_child(help)
	for actor: Node3D in actors:
		if actor.get("enemy_kind")==&"hookline_rig":actor.call("lock_attack_target",_hero.global_position)

func test_catch() -> void:
	if _systems._net_capture.active():return
	_hero.global_position=Vector3(0,.85,-1.4);_hero.velocity=Vector3.ZERO
	_systems._on_enemy_contact(_netbot)
