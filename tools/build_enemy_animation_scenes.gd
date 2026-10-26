extends SceneTree
const Visual = preload("res://core/enemies/visuals/fleet_enemy_visual.gd")
const OUT := "res://core/enemies/visuals/"

func _initialize() -> void: build.call_deferred()
func own(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child: Node in node.get_children(): own(child, owner_node)
func track(anim: Animation, path: String, keys: Array) -> void:
	var index := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(index, NodePath(path))
	for key: Array in keys: anim.track_insert_key(index, key[0], key[1])
func event(anim: Animation, time: float, label: StringName) -> void:
	var index := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(index, NodePath("."))
	anim.track_insert_key(index,time,{"method": &"emit_cue", "args": [label]})

# Pose fields: body pitch, body yaw, body roll, body height, capture lift,
# basket counter-pitch, cable extension, hook twist, lamp energy, forward lunge.
func poses(kind: String, clip: String) -> Array:
	var rest := [0.,0.,0.,0.,0.,0.,0.,0.,0.25,0.]
	if clip == "reset": return [[0.,rest],[0.18,rest]]
	if kind == "netbot":
		match clip:
			"idle": return [[0.,rest],[1.,[0.,0.,0.,.002,-.025,.015,0.,0.,.3,0.]],[2.,rest]]
			"notice": return [[0.,rest],[.22,[0.,0.,0.,0.,-.20,.12,0.,0.,1.2,0.]],[.45,[0.,0.,0.,0.,-.15,.1,0.,0.,.8,0.]]]
			"warn": return [[0.,[0.,0.,0.,0.,-.15,.1,0.,0.,.8,0.]],[.45,[0.,0.,.025,0.,-.65,.4,0.,0.,1.8,0.]],[.65,[0.,0.,.025,0.,-.60,.4,0.,0.,.7,0.]],[.9,[0.,0.,.025,0.,-.65,.4,0.,0.,1.8,0.]]]
			"attack": return [[0.,[0.,0.,.025,0.,-.65,.4,0.,0.,1.8,0.]],[.16,[0.,0.,-.055,.015,.14,-.12,0.,0.,2.,-.16]],[.32,[0.,0.,-.04,.015,.10,-.10,0.,0.,1.,-.16]],[.55,[0.,0.,0.,0.,.08,-.08,0.,0.,.4,0.]]]
			"recover": return [[0.,[0.,0.,0.,0.,.08,-.08,0.,0.,.4,0.]],[.6,[0.,0.,0.,0.,.05,-.04,0.,0.,.15,0.]],[1.35,rest]]
			"stagger": return [[0.,rest],[.1,[0.,0.,.09,.025,-.3,.15,0.,0.,0.,.06]],[.24,[0.,0.,-.05,0.,-.12,.06,0.,0.,.4,0.]],[.7,rest]]
			"disabled": return [[0.,rest],[.14,[0.,0.,.10,.02,-.24,.12,0.,0.,2.,0.]],[.42,[0.,0.,-.035,-.005,.12,-.08,0.,0.,.2,0.]],[.85,[0.,0.,-.035,-.005,.12,-.08,0.,0.,0.,0.]]]
	else:
		match clip:
			"idle": return [[0.,rest],[.75,[0.,.018,0.,.012,0.,0.,.015,.045,.3,0.]],[1.5,[0.,0.,0.,0.,0.,0.,0.,0.,.25,0.]],[2.25,[0.,-.018,0.,-.012,0.,0.,.015,-.045,.3,0.]],[3.,rest]]
			"notice": return [[0.,rest],[.2,[0.,0.,0.,.035,0.,0.,.06,.12,1.2,0.]],[.45,[0.,0.,0.,.02,0.,0.,.035,.06,.8,0.]]]
			"warn": return [[0.,[0.,0.,0.,.02,0.,0.,.035,.06,.8,0.]],[.45,[0.,0.,0.,.025,0.,0.,0.,-.28,1.8,0.]],[.7,[0.,0.,0.,.025,0.,0.,0.,-.28,.7,0.]],[1.,[0.,0.,0.,.025,0.,0.,0.,-.28,1.8,0.]]]
			"attack": return [[0.,[0.,0.,0.,.025,0.,0.,0.,-.28,1.8,0.]],[.22,[0.,0.,0.,.015,0.,0.,.68,-.28,2.,0.]],[.62,[0.,0.,0.,.015,0.,0.,.68,.32,1.3,0.]],[.85,[0.,0.,0.,.015,0.,0.,.68,.32,.4,0.]]]
			"recover": return [[0.,[0.,0.,0.,.015,0.,0.,.68,.32,.4,0.]],[1.5,[0.,0.,0.,0.,0.,0.,.34,.10,.15,0.]],[3.,rest]]
			"stagger": return [[0.,rest],[.1,[.10,0.,.12,.025,0.,0.,.10,.3,0.,0.]],[.28,[-.05,0.,-.06,0.,0.,0.,.04,-.15,.4,0.]],[.7,rest]]
			"disabled": return [[0.,rest],[.15,[0.,0.,-.12,0.,0.,0.,.15,.3,2.,0.]],[.5,[0.,0.,.14,-.055,0.,0.,.22,.12,.15,0.]],[1.,[0.,0.,.14,-.055,0.,0.,.22,.12,0.,0.]]]
	return []

func pose_value(samples: Array,segment: int,component: int,time: float) -> float:
	var a: Array=samples[segment]; var b: Array=samples[segment+1]
	var span: float=float(b[0])-float(a[0])
	var left: float=float(a[1][component]); var right: float=float(b[1][component])
	var slope: float=(right-left)/span
	var m0:=0.0; var m1:=0.0
	if segment>0:
		var prev: Array=samples[segment-1]
		var d: float=(left-float(prev[1][component]))/(float(a[0])-float(prev[0]))
		if d*slope>0.0: m0=2.0*d*slope/(d+slope)
	if segment+2<samples.size():
		var following: Array=samples[segment+2]
		var d: float=(float(following[1][component])-right)/(float(following[0])-float(b[0]))
		if d*slope>0.0: m1=2.0*d*slope/(d+slope)
	var t:=clampf((time-float(a[0]))/span,0.0,1.0)
	return (2*t*t*t-3*t*t+1)*left+(t*t*t-2*t*t+t)*span*m0+(-2*t*t*t+3*t*t)*right+(t*t*t-t*t)*span*m1

func build() -> void:
	for kind: String in ["netbot", "hookline_rig"]:
		var actor := Node3D.new()
		actor.name = "Netbot" if kind == "netbot" else "HooklineRig"
		actor.set_script(Visual)
		actor.set("enemy_kind",StringName(kind))
		var facing := Node3D.new(); facing.name="Facing";actor.add_child(facing)
		facing.rotation.y = -PI/2 if kind == "netbot" else PI
		var body := Node3D.new();body.name="Body";facing.add_child(body)
		var source := load("res://assets/prop/%s_animated/%s_animated.glb" % [kind,kind]).instantiate() as Node3D
		for part_name: String in (["Chassis","CaptureArm","NetBasket"] if kind == "netbot" else ["Chassis","HookLeft","HookRight"]):
			var part := source.find_child(part_name,true,false) as Node3D
			assert(part != null,part_name)
			part.owner=null;part.get_parent().remove_child(part);body.add_child(part)
		if kind == "netbot":
			var basket := body.get_node("NetBasket") as Node3D
			var arm := body.get_node("CaptureArm") as Node3D
			body.remove_child(basket);arm.add_child(basket);basket.position -= arm.position;basket.scale.x=1.85
		else:
			var cable_material := StandardMaterial3D.new()
			cable_material.albedo_color=Color(.10,.18,.22);cable_material.metallic=.65;cable_material.roughness=.4
			for side: String in ["Left","Right"]:
				var cable := MeshInstance3D.new();cable.name="Cable"+side
				var cylinder := CylinderMesh.new();cylinder.top_radius=.013;cylinder.bottom_radius=.013;cylinder.height=1.;cylinder.radial_segments=8;cylinder.rings=0;cylinder.cap_top=false;cylinder.cap_bottom=false
				cable.mesh=cylinder;cable.material_override=cable_material
				cable.position=Vector3(-.69 if side=="Left" else .69,.065,0.)
				cable.scale.y=.05;body.add_child(cable)
		var lamp := OmniLight3D.new();lamp.name="WarningLamp";lamp.position=Vector3(.33,.48,0.) if kind=="netbot" else Vector3(0.,.53,0.)
		lamp.light_color=Color(1.,.55,.12);lamp.omni_range=.75;lamp.light_energy=.25;lamp.shadow_enabled=false;body.add_child(lamp)
		var socket := Marker3D.new();socket.name="AttackSocket"
		if kind=="netbot":body.get_node("CaptureArm/NetBasket").add_child(socket);socket.position=Vector3(-.20,-.10,0.)
		else:body.get_node("HookRight").add_child(socket);socket.position=Vector3(0.,-.14,0.)
		var player := AnimationPlayer.new();player.name="AnimationPlayer";actor.add_child(player)
		var library := AnimationLibrary.new()
		for clip: String in ["idle","notice","warn","attack","recover","stagger","disabled","reset"]:
			var samples := poses(kind,clip)
			var animation := Animation.new();animation.length=float(samples[-1][0])
			if clip=="idle":animation.loop_mode=Animation.LOOP_LINEAR
			var paths: Array[String] = ["Facing/Body:rotation","Facing/Body:position","Facing/Body/WarningLamp:light_energy", ".:cable_extension"]
			if kind=="netbot":paths.append_array(["Facing/Body/CaptureArm:rotation","Facing/Body/CaptureArm/NetBasket:rotation"])
			else:paths.append_array(["Facing/Body/HookLeft:rotation","Facing/Body/HookRight:rotation"])
			for channel: int in paths.size():
				var keys: Array=[]
				# Bake continuous, bounded pose curves; preserve authored attack times.
				var frames := ceili(animation.length*60.)
				for frame: int in range(frames+1):
					var t := minf(frame/60.,animation.length)
					var segment := 0
					while segment < samples.size()-2 and t > float(samples[segment+1][0]):segment+=1
					var p: Array=[]
					for component: int in 10:p.append(pose_value(samples,segment,component,t))
					var value: Variant
					match channel:
						0:value=Vector3(p[0],p[1],p[2])
						1:value=Vector3(p[9],p[3],0.)
						2:value=p[8]
						3:value=p[6]
						4:value=Vector3(0.,0.,p[4]) if kind=="netbot" else Vector3(0.,p[7],0.)
						5:value=Vector3(0.,0.,p[5]) if kind=="netbot" else Vector3(0.,-p[7],0.)
					keys.append([t,value])
				track(animation,paths[channel],keys)
			track(animation,".:attack_active",[[0.,false]])
			animation.value_track_set_update_mode(animation.get_track_count()-1,Animation.UPDATE_DISCRETE)
			if clip=="attack":
				var index := animation.get_track_count()-1
				animation.track_insert_key(index,.12 if kind=="netbot" else .22,true)
				animation.track_insert_key(index,.34 if kind=="netbot" else .66,false)
				event(animation,.12 if kind=="netbot" else .22,&"release")
			if clip in ["notice","warn","stagger","disabled"]:event(animation,.02,StringName(clip))
			library.add_animation(StringName(clip),animation)
		player.add_animation_library(&"",library)
		own(facing,actor);own(player,actor)
		var packed := PackedScene.new();assert(packed.pack(actor)==OK)
		assert(ResourceSaver.save(packed,OUT+kind+"_visual.tscn")==OK)
		print("BUILT ",kind," clips=",player.get_animation_list())
		source.free();actor.free()
	quit()
