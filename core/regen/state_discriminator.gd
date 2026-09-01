class_name StateDiscriminator
extends RefCounted

## How one hazard, interactable or restoration state is told apart WITHOUT
## COLOUR (REQ-019 AC-1).
##
## There is deliberately no colour field on this class. Art will of course colour
## these things, and should — but if a colour lived here it would eventually
## become the discriminator, and a player with colour-blindness or a washed-out
## screen would lose the distinction the criterion protects. Leaving it out makes
## "not relying on colour alone" a property of the type rather than a rule
## someone has to remember.
##
## Three independent non-colour channels, because they serve different distances:
## the SHAPE reads across a room, the GLYPH reads on the HUD, the LABEL reads for
## a player using a screen reader or still learning to read the silhouettes.

## Stable state id, e.g. "hazard.netbot".
var state_id: String = ""

## World-space silhouette family. What the thing looks like at range, before any
## detail resolves.
var shape: String = ""

## HUD/marker icon id. Unique across every state, so no two markers collide.
var glyph: String = ""

## Human-readable name. Unique, and the fallback channel when neither silhouette
## nor icon is available.
var label: String = ""


func _init(p_state_id: String = "", p_shape: String = "",
		p_glyph: String = "", p_label: String = "") -> void:
	state_id = p_state_id
	shape = p_shape
	glyph = p_glyph
	label = p_label


## Every non-colour channel populated. A state missing one has fewer ways to be
## told apart than the criterion promises.
func is_complete() -> bool:
	return not state_id.is_empty() and not shape.is_empty() \
		and not glyph.is_empty() and not label.is_empty()
