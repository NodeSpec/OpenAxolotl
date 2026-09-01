class_name CameraOccluderProbe
extends RefCounted

## The port the camera asks "is anything between the axolotl and here?"
## (REQ-005 AC-2).
##
## A fraction rather than a hit point, because the rig needs to shorten a
## distance and a scalar is the thing it can shorten. 1.0 is clear; 0.4 means
## geometry starts 40% of the way out.
##
## The base returns CLEAR, unlike the grapple's AnchorSource which grants
## nothing. The asymmetry is deliberate and worth stating: a grapple with no
## source should miss, but a camera with no probe must not slam itself into the
## axolotl's face — the safe degenerate for a camera is "no avoidance", and a rig
## without a probe is documented as performing none rather than pretending to.

## Fraction of the segment from [param _from] to [param _to] that is clear, in
## 0..1. Callers clamp, so an implementation returning something out of range
## degrades rather than corrupting the camera position.
func clear_fraction(_from: Vector3, _to: Vector3) -> float:
	return 1.0
