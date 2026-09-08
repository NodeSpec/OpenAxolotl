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
##
## FIGHT LEGS NAME A MACHINE AND END WHEN IT IS DOWN. They are here for the
## same reason the jumps are: the level's machines were placed six to ten
## metres off this line while the longest strike reached 2.3 m, so every one
## of them was decoration. A route that walks past a machine proves nothing
## about whether it can be fought; a leg that has to put one down proves both
## that it is in reach and that its declared durability is beatable with the
## verb the grammar there actually offers.


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
	RoutePilot.fight("NetbotLagoonGap", Vector3(0, -5, -37.6), "the first machine in the level: a one-hit Netbot in open water, where a single spin sprint is both the escape from its net and the end of it"),
	RoutePilot.at("boost", Vector3(0, -5, -39.5), "boost for the climb over the shelf"),
	RoutePilot.at("swim", Vector3(0, 0.6, -40), "up the near face of RiseWall"),
	RoutePilot.at("swim", Vector3(0, 0.6, -42.5), "over the top"),
	RoutePilot.fight("NetbotRiseWall", Vector3(0, 0.6, -43.6), "the same lesson again, mid-climb over RiseWall"),
	RoutePilot.at("swim", Vector3(0, 0.8, -46), "onto the first shore step, still submerged"),
	RoutePilot.at("swim", Vector3(0, 4.2, -49), "up to the surface, clear over the shore lip"),
	RoutePilot.at("swim", Vector3(0, 4.2, -51.5), "out of the water and down onto CoveShore"),
	RoutePilot.at("walk", Vector3(0, 3.8, -52), "CoveShore -- out of the water, land grammar back"),
	RoutePilot.at("climb", Vector3(0, 3.8, -63.5), "INTO the coral wall -- a climb leg aims at the far side of the face, so the pilot keeps pressing into it until the contact it is waiting for actually happens"),
	RoutePilot.at("walk", Vector3(0, 8.2, -65), "over the lip onto the wall top"),
	RoutePilot.at("walk", Vector3(0, 8.2, -66.4), "the Glow gill mod"),
	RoutePilot.fight("HooklineGlowGate", Vector3(3.2, 8.2, -67.4), "a Hookline Rig on the wall top: two tail whacks, fought with the Glow mod already in hand so its line is visible"),
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
	RoutePilot.fight("RunoffDroneGorge", Vector3(0, 3.6, -105.8), "a Runoff Drone past the arch: three strikes, fought from inside its own murk"),
	RoutePilot.at("boost", Vector3(0, 3.6, -106.6), "boost down the last of the channel"),
	RoutePilot.at("swim", Vector3(0, 7.2, -107.4), "up to the surface at the far end"),
	RoutePilot.at("swim", Vector3(0, 7.2, -109.6), "out of the water onto the first terrace"),
	RoutePilot.at("walk", Vector3(0, 7, -110), "terrace 1"),
	RoutePilot.fight("DredgerSeedBed", Vector3(-3.5, 7, -110), "the level's boss beat, guarding the way into the seed bed: four strikes on the only machine that can spend a life, and it must fall before a single seed is planted"),
	RoutePilot.at("walk", Vector3(0, 7, -110.6), "seed 1"),
	RoutePilot.at("walk", Vector3(-3, 7, -111.4), "seed 2"),
	RoutePilot.at("jump", Vector3(-8.5, 7.4, -111.7), "seed 3, out on the left pillar (2.0 m across)"),
	RoutePilot.at("jump", Vector3(-3, 7, -112.4), "back onto terrace 1"),
	RoutePilot.at("jump", Vector3(0, 6, -117), "terrace 2 (gap 2.2, a step down)"),
	RoutePilot.fight("RunoffDroneSeedBed", Vector3(3.5, 6, -117.8), "a Drone venting over terrace two: three strikes on foot, and the seeds here are gathered half blind until it is down"),
	RoutePilot.at("walk", Vector3(2.5, 6, -117.6), "seed 4"),
	RoutePilot.at("jump", Vector3(8.5, 6.4, -118.2), "seed 6, out on the right pillar (2.0 m across)"),
	RoutePilot.at("jump", Vector3(2.5, 6, -118.8), "back onto terrace 2"),
	RoutePilot.at("walk", Vector3(-2.5, 6, -119.4), "seed 5"),
	RoutePilot.at("jump", Vector3(0, 5, -124.5), "terrace 3 (gap 2.2)"),
	RoutePilot.at("walk", Vector3(0, 5, -125.6), "seed 7 -- the shelf reaches `restored` here"),
	RoutePilot.at("walk", Vector3(0, 5, -128.6), "through the opened shelf wall"),

	# --- ACT 7: THE TIDE RACE ---------------------------------------------
	# The shelf wall used to open onto the finish two metres later. It now
	# opens onto sixty-eight more metres of level: down the tide steps to the
	# waterline, along the race channel with a dive under the surge bar, and
	# out onto the sea terrace.
	RoutePilot.at("walk", Vector3(0, 5, -136), "onto RaceLanding past the wall"),
	RoutePilot.at("jump", Vector3(0, 4.2, -147), "TideStep1 (gap 1.5, a step down)"),
	RoutePilot.at("jump", Vector3(2.5, 3.4, -154), "TideStep2 (gap 2.0, down and 2.5 m right)"),
	RoutePilot.at("swim", Vector3(0, 2.2, -160), "off the last step straight into the race"),
	RoutePilot.at("swim", Vector3(0, -0.4, -165), "down for the surge bar"),
	RoutePilot.at("swim", Vector3(0, -0.4, -169), "under SurgeBar"),
	RoutePilot.fight("NetbotTideRace", Vector3(0, -0.4, -170.5), "a Netbot in the race current -- one strike, but the current is moving"),
	RoutePilot.at("boost", Vector3(0, 0.4, -173), "boost along the channel"),
	RoutePilot.at("swim", Vector3(0, 1.6, -180), "back up to the waterline"),
	RoutePilot.at("swim", Vector3(0, 2.4, -187), "over the submerged sea shore"),
	RoutePilot.at("swim", Vector3(0, 2.2, -190), "out of the water and down onto SeaShore"),
	RoutePilot.at("walk", Vector3(0, 2.0, -191), "SeaShore -- land grammar back"),
	RoutePilot.fight("RunoffDroneSeaShore", Vector3(0, 2.0, -193), "the last machine in the level, between the player and the final jump"),
	RoutePilot.at("jump", Vector3(0, 3.0, -198.5), "SeaTerrace (gap 1.0, rise 1.0)"),

	# --- ACT 8: THE FLEET YARD --------------------------------------------
	# The sea terrace is now the door into the yard rather than the end of the
	# level. Everything past it is a chain of moored hulls over open water,
	# and the act's difficulty is DENSITY: five machines and a climb, with
	# nothing under the gaps but the pit.
	RoutePilot.at("jump", Vector3(0, 3.4, -208.5), "YardCauseway (gap 2.0, rise 0.2)"),
	RoutePilot.fight("NetbotYardGate", Vector3(3, 3.4, -208.5), "the gate machine: the same one-strike Netbot the level opened with, so the act starts on ground the player is sure of"),
	RoutePilot.at("jump", Vector3(0, 4.2, -218), "YardHull1 (gap 2.0, rise 0.8)"),
	RoutePilot.at("jump", Vector3(2.5, 5.0, -226), "YardHull2 (gap 2.0, and 2.5 m right)"),
	RoutePilot.fight("HooklineYardHull", Vector3(5, 5.0, -226), "a Rig out on the hull, fought with a two-metre drop on three sides"),
	RoutePilot.at("jump", Vector3(0, 5.8, -234), "YardHull3 (gap 2.0, back to the centre line)"),
	RoutePilot.at("jump", Vector3(-2.5, 6.6, -242), "YardHull4 (gap 2.0, and 2.5 m left)"),
	RoutePilot.at("jump", Vector3(0, 7.4, -252), "YardDeck (gap 2.0, rise 0.8)"),
	RoutePilot.fight("RunoffDroneYardDeck", Vector3(-4, 7.4, -252), "the deck, and the first of the two machines on it"),
	RoutePilot.fight("HooklineYardDeck", Vector3(0, 7.4, -255.5), "and the second, in front of the mast: five strikes between them, and the deck is the only ground in forty metres wide enough to back up on"),
	RoutePilot.at("climb", Vector3(0, 7.4, -259.5), "INTO YardMast -- the climb verb the coral wall taught and the level has not asked for since"),
	RoutePilot.at("walk", Vector3(0, 11.6, -261), "over the lip onto the crown"),
	RoutePilot.fight("NetbotYardCrown", Vector3(3, 11.6, -264), "the last machine in the level, standing over the reward"),
	RoutePilot.at("walk", Vector3(0, 11.6, -265), "the fleet beacon"),
	RoutePilot.at("finish", Vector3(0, 11.6, -267), "the finish volume, on the crown of the yard"),
	] as Array[RoutePilot.Waypoint]
