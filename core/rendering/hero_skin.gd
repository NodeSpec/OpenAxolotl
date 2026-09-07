class_name HeroSkin
extends RefCounted

## Dresses the hero model in the client's materials (docs/asset-contract.md,
## "Toy materials: saturated albedo, real lighting").
##
## The model is an imported glb; its own materials are whatever the exporter
## wrote, which for the raw upload was nothing at all. The LOOK is the game
## client's, so the client decides how each part takes light: skin, eyes, the
## eye gleams, the translucent gills and fins, and the matte mouth details.
##
## Which part is which is decided in one of two ways, in this order:
##
##   1. By MATERIAL NAME. A model refined through tools/refine_model.py comes
##      back with one mesh per role, each wearing a material named
##      `axolotl_<role>`; that name is the contract between the pipeline and
##      the client, and it survives any change of palette.
##   2. By VERTEX COLOUR, for a raw model that names nothing. Each surface's
##      mean vertex colour is classified against the hero palette: near-black
##      is an eye, pure white is a gleam, dark maroon is a mouth detail, the
##      deep pink is a gill or fin, and everything else is skin.
##
## Either way the result is a surface override on each MeshInstance3D, so the
## imported resource itself is never edited and re-importing the asset never
## loses the look.

enum Role { SKIN, EYE, GLEAM, GILL, DETAIL }

const MATERIAL_PATHS := {
	Role.SKIN: "res://core/rendering/materials/axolotl_skin.tres",
	Role.EYE: "res://core/rendering/materials/axolotl_eye.tres",
	Role.GLEAM: "res://core/rendering/materials/axolotl_eye_gleam.tres",
	Role.GILL: "res://core/rendering/materials/axolotl_gill.tres",
	Role.DETAIL: "res://core/rendering/materials/axolotl_detail.tres",
}

## The pipeline's material names (tools/blender/refine_model.py writes them).
const MATERIAL_NAME_ROLES := {
	"axolotl_skin": Role.SKIN,
	"axolotl_eye": Role.EYE,
	"axolotl_gleam": Role.GLEAM,
	"axolotl_gill": Role.GILL,
	"axolotl_detail": Role.DETAIL,
}

## Palette thresholds, shared with the Blender script so both halves agree.
const EYE_MAX_LUMINANCE := 0.15
const DETAIL_MAX_LUMINANCE := 0.4
const GLEAM_MIN_CHANNEL := 0.97
const GILL_MAX_GREEN := 0.5

## Key under which apply() reports surfaces it deliberately left alone.
const AUTHORED := "authored"

static var _cache: Dictionary = {}


static func role_name(role: Role) -> String:
	return Role.keys()[role].to_lower()


## Where a vertex colour sits in the hero palette.
static func classify_color(color: Color) -> Role:
	var luminance := color.get_luminance()
	if luminance < EYE_MAX_LUMINANCE:
		return Role.EYE
	if color.r >= GLEAM_MIN_CHANNEL and color.g >= GLEAM_MIN_CHANNEL \
			and color.b >= GLEAM_MIN_CHANNEL:
		return Role.GLEAM
	if luminance < DETAIL_MAX_LUMINANCE:
		return Role.DETAIL
	if color.g < GILL_MAX_GREEN:
		return Role.GILL
	return Role.SKIN


## The role of one surface: by the material's name first, else by the mean
## of its vertex colours, else skin.
static func role_for_surface(mesh: Mesh, surface: int) -> Role:
	var material := mesh.surface_get_material(surface)
	if material != null and MATERIAL_NAME_ROLES.has(material.resource_name):
		return MATERIAL_NAME_ROLES[material.resource_name]
	var arrays: Array = mesh.surface_get_arrays(surface)
	var colors: Variant = arrays[Mesh.ARRAY_COLOR]
	if colors == null:
		return Role.SKIN
	var packed := colors as PackedColorArray
	if packed.is_empty():
		return Role.SKIN
	var sum := Color(0, 0, 0, 0)
	for color: Color in packed:
		sum += color
	return classify_color(sum / float(packed.size()))


static func material_for(role: Role) -> Material:
	if not _cache.has(role):
		_cache[role] = load(MATERIAL_PATHS[role])
	return _cache[role]


## Dresses every mesh under `model`. Returns how many surfaces took each role,
## keyed by role name, so a caller (or a test) can see the model was read
## the way the palette intends.
static func apply(model: Node3D) -> Dictionary:
	var counts := {}
	for name: String in Role.keys():
		counts[name.to_lower()] = 0
	counts[AUTHORED] = 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in instance.mesh.get_surface_count():
			if brings_its_own_surface(instance.mesh, surface):
				counts[AUTHORED] += 1
				continue
			var role := role_for_surface(instance.mesh, surface)
			instance.set_surface_override_material(surface, material_for(role))
			counts[role_name(role)] += 1
	return counts


## Does this surface already carry authored art the client must not replace?
##
## THE ROLE MATERIALS ARE A FALLBACK, NOT A POLICY. They exist because the
## generated hero ships vertex-coloured geometry with no maps: without them
## it renders as flat untextured plastic, so the client dresses it. A model
## that arrives with a base-colour map is the opposite case — the mottling,
## the gill gradient and the pore relief ARE the asset, they are what was paid
## for, and overriding them with a flat toy material throws all of it away and
## leaves the hero looking worse than the greybox it replaced.
##
## Detected from the surface rather than declared per model, because the test
## is exactly the condition that matters: is there an albedo texture here to
## lose? A file with maps keeps them; a file without gets dressed. Nothing has
## to be configured, and a future asset behaves correctly on arrival.
static func brings_its_own_surface(mesh: Mesh, surface: int) -> bool:
	var material := mesh.surface_get_material(surface) as BaseMaterial3D
	return material != null and material.albedo_texture != null
