class_name ClimbSurface
extends RefCounted

## The "is this surface climbable" test (REQ-001 AC-3).
##
## The tag is a PHYSICS LAYER or a GROUP — never a node name, and never a name
## substring. A name check looks like it works in the first world and then quietly
## fails the moment a contributor calls their wall "Rock_Wall_02b" instead of
## "climbable_wall"; worse, it makes the Level Contract depend on a naming
## convention that no schema can express or validate. A layer bit and a group are
## both first-class, inspectable, and checkable by static analysis of a community
## world (REQ-020), which a name is not.
##
## Two accepted tags rather than one because they serve different authors: the
## layer suits whole-mesh terrain painted in the physics editor, the group suits
## individual props tagged in a scene. Either alone is sufficient.

## Godot physics layer NUMBER (1-based, as shown in the inspector).
const CLIMBABLE_PHYSICS_LAYER := 4

## The corresponding collision_layer BIT MASK (0-based shift). Derived rather
## than written out, so the layer number above is the single place to change it.
const CLIMBABLE_LAYER_MASK := 1 << (CLIMBABLE_PHYSICS_LAYER - 1)

## SceneTree group a world adds to any node whose surface may be climbed.
const CLIMBABLE_GROUP := "climbable"


## True when the surface carries either tag. Pure and static: it takes the data a
## collision result already provides, so nothing here needs a scene tree, which
## is what lets the criterion be asserted headlessly.
static func is_climbable(collision_layer: int, groups: PackedStringArray) -> bool:
	if (collision_layer & CLIMBABLE_LAYER_MASK) != 0:
		return true
	return groups.find(CLIMBABLE_GROUP) != -1


## Convenience for the layer half alone, for callers that only have a body.
static func layer_is_climbable(collision_layer: int) -> bool:
	return (collision_layer & CLIMBABLE_LAYER_MASK) != 0


## What a world author must do to make a surface climbable. Surfaced as data so
## the Level Contract documentation and an authoring error message can quote the
## same sentence rather than each keeping their own copy.
static func tag_requirement() -> String:
	return "Set physics layer %d on the collider, or add it to the \"%s\" group." \
		% [CLIMBABLE_PHYSICS_LAYER, CLIMBABLE_GROUP]
