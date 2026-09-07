class_name CoralRoute
extends RefCounted

## The designed route through Coral Cove, waypoint by waypoint — the ONE copy.
##
## Two probes fly it: the coral walk (completability and every world claim,
## REQ-038) and the performance gate (frame cost while traversing, REQ-027).
## They used to be able to differ, because the perf gate held one key down a
## corridor; a platforming route killed that, and the moment the gate learned
## to fly, the route data had to live where both probes read the SAME one.
## A perf gate measuring a route the walk no longer walks would be measuring
## a level that does not exist.
##
## Coordinates are in the LEVEL's own space, readable against world.tscn.
## Each waypoint names the platform it stands on; the gaps between them are
## the gaps the world's header measures against the controller's envelope.


static func waypoints() -> Array[RoutePilot.Waypoint]:
	return [
	RoutePilot.at("walk", Vector3(0, 7.3, -4.6), "StartLedge, at the lip"),
	RoutePilot.at("jump", Vector3(0, 8.2, -9.7), "ShelfStep1  (gap 2.2, rise 0.9)"),
	RoutePilot.at("jump", Vector3(0, 9.1, -15.1), "ShelfStep2  (gap 2.4, rise 0.9)"),
	RoutePilot.at("jump", Vector3(0, 9.9, -21.8), "ShelfStep3 + the hermit snail (gap 2.4, rise 0.8)"),
	RoutePilot.at("jump", Vector3(0, 9.9, -27.8), "ShelfLip -- the last dry ground before the cove"),
	RoutePilot.at("swim", Vector3(0, 1.5, -32.5), "off the lip and into the cove"),
	RoutePilot.at("swim", Vector3(0, -5, -34), "line up below the brow"),
	RoutePilot.at("swim", Vector3(0, -5, -36.5), "through the gap under DiveBar"),
	RoutePilot.at("boost", Vector3(0, -5, -39.5), "boost for the climb over the shelf"),
	RoutePilot.at("swim", Vector3(0, 0.6, -40), "up the near face of RiseWall"),
	RoutePilot.at("swim", Vector3(0, 0.6, -42.5), "over the top"),
	RoutePilot.at("swim", Vector3(0, 0.8, -46), "onto the first shore step, still submerged"),
	RoutePilot.at("swim", Vector3(0, 4.2, -49), "up to the surface, clear over the shore lip"),
	RoutePilot.at("swim", Vector3(0, 4.2, -51.5), "out of the water and down onto CoveShore"),
	RoutePilot.at("walk", Vector3(0, 3.8, -52), "CoveShore -- out of the water, land grammar back"),
	RoutePilot.at("climb", Vector3(0, 3.8, -63.5), "INTO the coral wall -- a climb leg aims at the far side of the face, so the pilot keeps pressing into it until the contact it is waiting for actually happens"),
	RoutePilot.at("walk", Vector3(0, 8.2, -65), "over the lip onto the wall top"),
	RoutePilot.at("walk", Vector3(0, 8.2, -66.4), "the Glow gill mod"),
	RoutePilot.at("jump", Vector3(0, 8.2, -69.5), "past the opened glow gate"),
	RoutePilot.at("jump", Vector3(0, 8.2, -74.1), "pillar 1 (gap 2.6 -- the widest on the route)"),
	RoutePilot.at("jump", Vector3(1.5, 8.2, -79), "pillar 2 (gap 2.2, and 1.5 m to the right)"),
	RoutePilot.at("jump", Vector3(0, 9.4, -83.7), "pillar 3 + the stray hook (gap 2.2, rise 1.2)"),
	RoutePilot.at("jump", Vector3(-1.5, 9.4, -88.4), "pillar 4 (gap 2.2, and 1.5 m back to the left)"),
	RoutePilot.at("jump", Vector3(0, 8.8, -94), "the grotto landing (gap 2.2)"),
	RoutePilot.at("walk", Vector3(0, 8.8, -95.6), "the Bubble gill mod"),
	RoutePilot.at("swim", Vector3(0, 7, -99.5), "into the gorge river"),
	RoutePilot.at("swim", Vector3(0, 3.6, -102), "down for the arch"),
	RoutePilot.at("swim", Vector3(0, 3.6, -104.2), "under GorgeArch"),
	RoutePilot.at("boost", Vector3(0, 3.6, -105.2), "boost down the last of the channel"),
	RoutePilot.at("swim", Vector3(0, 7.2, -107.4), "up to the surface at the far end"),
	RoutePilot.at("swim", Vector3(0, 7.2, -109.6), "out of the water onto the first terrace"),
	RoutePilot.at("walk", Vector3(0, 7, -110), "terrace 1"),
	RoutePilot.at("walk", Vector3(0, 7, -110.6), "seed 1"),
	RoutePilot.at("walk", Vector3(-3, 7, -111.4), "seed 2"),
	RoutePilot.at("jump", Vector3(-8.5, 7.4, -111.7), "seed 3, out on the left pillar (2.0 m across)"),
	RoutePilot.at("jump", Vector3(-3, 7, -112.4), "back onto terrace 1"),
	RoutePilot.at("jump", Vector3(0, 6, -117), "terrace 2 (gap 2.2, a step down)"),
	RoutePilot.at("walk", Vector3(2.5, 6, -117.6), "seed 4"),
	RoutePilot.at("jump", Vector3(8.5, 6.4, -118.2), "seed 6, out on the right pillar (2.0 m across)"),
	RoutePilot.at("jump", Vector3(2.5, 6, -118.8), "back onto terrace 2"),
	RoutePilot.at("walk", Vector3(-2.5, 6, -119.4), "seed 5"),
	RoutePilot.at("jump", Vector3(0, 5, -124.5), "terrace 3 (gap 2.2)"),
	RoutePilot.at("walk", Vector3(0, 5, -125.6), "seed 7 -- the shelf reaches `restored` here"),
	RoutePilot.at("walk", Vector3(0, 5, -128.6), "through the opened shelf wall"),
	RoutePilot.at("finish", Vector3(0, 5, -133), "the finish volume"),
	] as Array[RoutePilot.Waypoint]
