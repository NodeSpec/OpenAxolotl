extends RefCounted
const ROOT := "res://assets/environment/cascade_surfaces/"
const POLISHED: Array[String] = ["S01","S02","S03","S04","S05","S06","Perimeter"]

static func apply(result: ShaderMaterial,section: String) -> void:
	if section not in POLISHED: return
	result.shader=load("res://core/rendering/cascade_pbr_ground.gdshader")
	var rock := "mossy_rock" if section in ["S03","S04","S06"] else "rock_face_03"
	for pair: Array in [["rock",rock],["sand","sand_01"],["turf","leafy_grass"],["gravel","dry_river_pebbles"]]:
		result.set_shader_parameter(String(pair[0])+"_color",load(ROOT+String(pair[1])+"_diff_2k.jpg"))
		result.set_shader_parameter(String(pair[0])+"_normal",load(ROOT+String(pair[1])+"_nor_gl_2k.png"))
		result.set_shader_parameter(String(pair[0])+"_arm",load(ROOT+String(pair[1])+"_arm_2k.png"))
	result.set_shader_parameter("rock_tint",Color("f5e6c9") if section!="S03" else Color("c7e0d9"))
	result.set_shader_parameter("sand_tint",Color("fff0c7"))
	result.set_shader_parameter("grass_tint",Color("a2d786") if section!="S05" else Color("b5df8d"))
	result.set_shader_parameter("rock_scale",0.20 if section!="S03" else 0.32)
	result.set_shader_parameter("gravel_share",0.72 if section=="S03" else 0.28)
