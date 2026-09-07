@tool
class_name ScatterField
extends Node3D

## One prop type, drawn many times, in ONE draw call (REQ-027, REQ-034).
##
## THE PROBLEM THIS SOLVES. Coral Cove dressed itself with 183 separate
## MeshInstance3D nodes — 48 canopy trees, 50 ferns, 20 reeds and so on, each
## its own scene instance and its own draw call. That is expensive in exactly
## the wrong way: the cost is per-OBJECT, so the budget was being spent on the
## fact that there are many plants rather than on there being much plant. A
## MultiMesh draws all 48 trees in one call, which both costs less than the
## 48 did AND leaves room to go to hundreds.
##
## DENSITY IS THE POINT. A forest reads as a forest because there is a lot of
## it, not because each tree is detailed — and the thing that gives away a
## sparse one is repetition, not polygon count. So this stores a transform per
## instance and hands the shader a per-instance phase and tint, which is what
## turns forty-eight copies of one mesh into forty-eight plants.
##
## THE MESH COMES FROM A PACKED SCENE, not from a Mesh resource, because the
## environment kit ships .glb files and Godot imports those as PackedScene.
## Rather than change every asset's import type — which would break the asset
## contract's expectations and every existing instance — this instantiates the
## scene once at startup, lifts the mesh out of it, and throws the instance
## away. That happens once per field, not once per instance.

## The prop to scatter, as the kit ships it.
@export var prop_scene: PackedScene:
	set(value):
		prop_scene = value
		_rebuild()

## The material every instance wears. Left null, the mesh keeps whatever
## material came out of the .glb — which is what a non-vegetation field
## (boulders, logs) wants, since those must not sway.
@export var surface_material: Material:
	set(value):
		surface_material = value
		_rebuild()

## Instance transforms, twelve floats each: basis rows 0..8 then origin.
##
## A flat float array rather than an Array[Transform3D] because that is what
## Godot serialises compactly into a .tscn — an array of Transform3D writes a
## line per instance and would put two thousand lines of noise in a diff.
@export var transforms: PackedFloat32Array = PackedFloat32Array():
	set(value):
		transforms = value
		_rebuild()

## Per-instance (phase, tint) pairs feeding INSTANCE_CUSTOM in the vegetation
## shader. Regenerated from the transforms when absent, so a hand-authored
## field does not have to supply them.
@export var variation: PackedFloat32Array = PackedFloat32Array():
	set(value):
		variation = value
		_rebuild()

const FLOATS_PER_TRANSFORM := 12

var _multi: MultiMeshInstance3D


func _ready() -> void:
	_rebuild()


## How many instances this field carries. Used by the scene triangle counter,
## which has to multiply the mesh by this rather than counting one mesh.
func instance_count() -> int:
	return transforms.size() / FLOATS_PER_TRANSFORM


func get_multimesh_instance() -> MultiMeshInstance3D:
	return _multi


## The mesh this field WILL draw, readable without the field ever being built.
##
## Deliberately independent of _ready. A field instantiated but not added to a
## tree — which is how the scene triangle counter and every headless probe in
## this repo inspect a world — has no MultiMesh yet, and a caller that reached
## through get_multimesh_instance() would measure zero and conclude the
## dressing was free. What the field DECLARES is knowable at any time, so that
## is what this reports.
func get_source_mesh() -> Mesh:
	return _extract_mesh()


## Build the MultiMesh from whatever this field currently declares.
##
## DELIBERATELY INDEPENDENT OF THE TREE. This used to return early unless
## is_inside_tree(), which looked like sensible cheapness and was a bug: a node
## added to the root from inside SceneTree._initialize — how the test harness
## and every headless probe in this repo build their scenes — is NOT in the
## tree until the first frame, so the field silently built nothing and every
## caller measured an empty forest. Nothing here needs a tree; add_child works
## on an unparented node just as well.
##
## Repeated calls are fine and expected: the setters fire once each as a .tscn
## loads, so a field rebuilds two or three times during load. That is a handful
## of allocations per field, against the alternative of a guard that makes the
## thing behave differently under test than in the game.
func _rebuild() -> void:
	if _multi != null:
		# free() rather than queue_free(): a field that is not in the tree has
		# no frame end to be collected at, and the stale node would linger as a
		# second copy of the whole scatter.
		remove_child(_multi)
		_multi.free()
		_multi = null

	var mesh := _extract_mesh()
	var count := instance_count()
	if mesh == null or count == 0:
		return

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Custom data rather than instance colour: the meshes are already vertex
	# painted, and Godot folds MultiMesh colour into the same COLOR the vertex
	# paint arrives on. Keeping variation in INSTANCE_CUSTOM leaves the kit's
	# own painting untouched and makes the shader's inputs unambiguous.
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = count

	for index: int in count:
		multimesh.set_instance_transform(index, _transform_at(index))
		multimesh.set_instance_custom_data(index, _variation_at(index))

	_multi = MultiMeshInstance3D.new()
	_multi.name = "Instances"
	_multi.multimesh = multimesh
	if surface_material != null:
		_multi.material_override = _fitted_material(mesh)
	# Scattered dressing is not worth a shadow pass each: the plants shade
	# themselves through the shader's own lighting, and a field of hundreds
	# casting individual shadows is the kind of cost that made the valley slow.
	_multi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_multi)


## The field's material, sized to the mesh it will actually draw.
##
## THE MATERIAL IS DUPLICATED PER FIELD, and it has to be. The wind shader
## needs the plant's own height to know where the lever ends, and the kit's
## plants differ by a factor of thirty — a canopy tree is 21.9 model units and
## a fern is 0.74. One shared material means one height, and one height is
## wrong for everything else: too small and the lever saturates a tenth of the
## way up a trunk so the whole crown translates as a rigid block with a visible
## kink under it; too large and short plants never move at all. Fifty ferns sat
## at eighteen percent of their sway for exactly this reason.
##
## A duplicate per FIELD, not per instance — there are nine of them.
func _fitted_material(mesh: Mesh) -> Material:
	var shaded := surface_material as ShaderMaterial
	if shaded == null:
		return surface_material
	var fitted := shaded.duplicate() as ShaderMaterial
	fitted.set_shader_parameter("model_height",
		maxf(mesh.get_aabb().size.y, 0.05))
	return fitted


func _transform_at(index: int) -> Transform3D:
	var base := index * FLOATS_PER_TRANSFORM
	return Transform3D(
		Basis(
			Vector3(transforms[base], transforms[base + 1], transforms[base + 2]),
			Vector3(transforms[base + 3], transforms[base + 4], transforms[base + 5]),
			Vector3(transforms[base + 6], transforms[base + 7], transforms[base + 8])),
		Vector3(transforms[base + 9], transforms[base + 10], transforms[base + 11]))


func _variation_at(index: int) -> Color:
	if variation.size() >= (index + 1) * 2:
		return Color(variation[index * 2], variation[index * 2 + 1], 0.0, 0.0)
	# Derived from the instance's own position when none was authored, so it is
	# deterministic — the same field scatters identically every run — while no
	# two instances share a phase.
	var origin := _transform_at(index).origin
	return Color(
		fposmod(origin.x * 0.317 + origin.z * 0.523, 1.0),
		fposmod(origin.x * 0.711 + origin.z * 0.219, 1.0),
		0.0, 0.0)


## The first mesh inside `prop_scene`, or null.
func _extract_mesh() -> Mesh:
	if prop_scene == null:
		return null
	var probe := prop_scene.instantiate()
	var found: Mesh = null
	for node: Node in probe.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			found = mesh
			break
	probe.free()
	return found
