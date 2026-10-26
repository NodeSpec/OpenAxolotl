@tool
class_name LagoonRockKit
extends RefCounted

static var _models: Dictionary = {}

static func model(kind: String) -> Dictionary:
	if _models.has(kind):
		return _models[kind]
	var scene := load("res://assets/environment/lagoon_meshy/%s.glb" % kind) as PackedScene
	var instance := scene.instantiate() as Node3D
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material: Material
	for node: Node in instance.find_children("*","MeshInstance3D",true,false):
		var visual := node as MeshInstance3D
		var placed: Transform3D = visual.transform
		var parent: Node = visual.get_parent()
		while parent != null:
			if parent is Node3D:
				placed = (parent as Node3D).transform*placed
			parent = parent.get_parent()
		for surface: int in visual.mesh.get_surface_count():
			builder.append_from(visual.mesh,surface,placed)
			material = visual.get_active_material(surface)
	var mesh: ArrayMesh = builder.commit()
	instance.free()
	_models[kind] = {"mesh":mesh,"material":material}
	return _models[kind]

static func solid(parent: Node3D, mesh: Mesh, transform: Transform3D, label: String) -> StaticBody3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface: int in mesh.get_surface_count():
		builder.append_from(mesh,surface,transform)
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("footstep_surface","stone")
	var collision := CollisionShape3D.new()
	collision.shape = builder.commit().create_trimesh_shape()
	body.add_child(collision)
	parent.add_child(body)
	return body
