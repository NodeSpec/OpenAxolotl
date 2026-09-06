class_name CollectibleDef
extends RefCounted

## One entry of a world's `collectibles` declaration (REQ-010 AC-6).
##
## The shape a world writes in world.json:
##
##   { "collectibleId": "kelp_seed",   "kind": "resource",  "regionId": "coral_shelf" }
##   { "collectibleId": "hermit_snail", "kind": "discovery", "displayName": "Hermit snail" }
##
## The scene places a collectible by putting an Area3D in group `collectible`
## with metadata `collectible_id` naming one of these. The manifest says WHAT
## exists; the scene says WHERE — a transform in JSON would drift from the
## geometry it sits on, the same reasoning the contract gives for spawn points.

const ID_FIELD := "collectibleId"
const KIND_FIELD := "kind"
const REGION_FIELD := "regionId"
const DISPLAY_NAME_FIELD := "displayName"

var collectible_id: String = ""
var kind: CollectibleKind.Kind = CollectibleKind.Kind.DISCOVERY
var region_id: String = ""
var display_name: String = ""


func is_resource() -> bool:
	return kind == CollectibleKind.Kind.RESOURCE


func is_discovery() -> bool:
	return kind == CollectibleKind.Kind.DISCOVERY


## Parses one declaration. Returns null and appends a named error for any
## malformed row; a resource that names no region is malformed, because a
## resource with nowhere to go is not a resource.
static func from_dictionary(
	entry: Variant,
	out_errors: Array[CollectibleError]
) -> CollectibleDef:
	if not (entry is Dictionary):
		out_errors.append(CollectibleError.new(
			CollectibleError.MALFORMED_DECLARATION, CollectiblesSystem.MANIFEST_FIELD,
			"each collectible declaration must be an object"))
		return null

	var row := entry as Dictionary
	var id := String(row.get(ID_FIELD, "")).strip_edges()
	if id.is_empty():
		out_errors.append(CollectibleError.new(
			CollectibleError.MISSING_FIELD, ID_FIELD,
			"a collectible declaration must name its '%s'" % ID_FIELD))
		return null

	var kind_text := String(row.get(KIND_FIELD, "")).strip_edges()
	var resolved := CollectibleKind.from_id(kind_text)
	if resolved == CollectibleKind.UNKNOWN:
		out_errors.append(CollectibleError.new(
			CollectibleError.UNKNOWN_KIND, id,
			"'%s' is not one of %s" % [kind_text, ", ".join(CollectibleKind.all_ids())]))
		return null

	var def := CollectibleDef.new()
	def.collectible_id = id
	def.kind = resolved as CollectibleKind.Kind
	def.display_name = String(row.get(DISPLAY_NAME_FIELD, id))

	if def.is_resource():
		def.region_id = String(row.get(REGION_FIELD, "")).strip_edges()
		if def.region_id.is_empty():
			out_errors.append(CollectibleError.new(
				CollectibleError.MISSING_FIELD, id,
				"a resource collectible must name the '%s' it restores" % REGION_FIELD))
			return null

	return def
