extends Node3D
## F6 animation stage. This scene deliberately has no encounter AI or damage.
var actors: Array[Node3D]=[]
func _ready() -> void:
	var env:=WorldEnvironment.new();var settings:=Environment.new();env.environment=settings
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(.04,.065,.085)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_energy=.65;add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-150,0);sun.light_energy=1.6;sun.shadow_enabled=true;add_child(sun)
	var floor_node:=MeshInstance3D.new();var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(30,30);floor_node.mesh=floor_mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.09,.14,.18);material.roughness=.9;floor_node.material_override=material;add_child(floor_node)
	var camera:=Camera3D.new();camera.position=Vector3(0,2.6,-5.5);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.8;add_child(camera);camera.look_at(Vector3(0,.6,0));camera.make_current()
	for index: int in 2:
		var kind: String=["netbot","hookline_rig"][index]
		var actor:=load("res://core/enemies/visuals/%s_visual.tscn"%kind).instantiate() as Node3D
		actor.position=Vector3(1.25 if index==0 else -1.25,.53 if index==0 else 1.25,0.)
		actor.rotation.y=.25 if index==0 else -.2;add_child(actor);actors.append(actor)
	var layer:=CanvasLayer.new();add_child(layer)
	var box:=VBoxContainer.new();box.position=Vector2(24,24);layer.add_child(box)
	var heading:=Label.new();heading.text="DRIFT FLEET / Animation workshop";heading.add_theme_font_size_override("font_size",26);box.add_child(heading)
	var note:=Label.new();note.text="Netbot (left)  /  Hookline Rig (right)\nChoose a clip. Disabled holds until Reset. Attack automatically recovers.";box.add_child(note)
	var buttons:=HBoxContainer.new();box.add_child(buttons)
	for clip: String in ["idle","notice","warn","attack","recover","stagger","disabled","reset"]:
		var button:=Button.new();button.text=clip.capitalize();buttons.add_child(button)
		button.pressed.connect(func() -> void:
			for actor: Node3D in actors: actor.call("play_state",StringName(clip)))

