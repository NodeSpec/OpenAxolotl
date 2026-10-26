# Living Cascade enemy population

Implemented 20 September 2026. The earlier enemy/gameplay plan remains the route reference; the latest request adds proximity behavior and mechanical breakup. Eight ordinary robots use the two completed animation assets (population revised 29 September 2026). Runoff Drone, Dredger, and Flagship remain outside this pass.

| Unit | Placement | Awareness | Movement |
|---|---|---|---|
| S02_N01 | Garden approach bank | 6 m | Short patrol; 1.7 m home leash |
| S02_N02 | Garden exit bank | 5 m | Short patrol; 1 m leash |
| S03_N01 | Open root-dive entrance water | 6 m | Swim patrol; 1.8 m leash, Â±0.45 m depth |
| S03_H01 | Optional root grotto | 5 m | Anchored Hookline |
| S04_N01 | Broad terrace B base | 5 m | Short patrol; 1.2 m leash |
| S04_H01 | Optional Pool A | 5 m | Anchored Hookline |
| S02_H01 | Garden exit land flank | 5 m | Anchored Hookline |
| S04_H02 | Terrace approach land | 5 m | Anchored Hookline |

Coordinates live in `core/enemies/cascade_population.tscn`; the world references that scene and declares its roster types in its manifest. Each globally unique unit name has independent state. Existing source meshes, collectibles, restoration costs, progression gates, floors and walls are preserved.

## Awareness and attacks

Idle â†’ notice â†’ pursue â†’ warning â†’ committed attack â†’ recovery. Notice scans run approximately eight times per second. Acquisition requires distance, matching land/water habitat, height compatibility, and a clear ray to the player. Lost sight cancels warning; leaving the local encounter returns the robot home. Ground movement checks five support points plus a swept body volume; swimmers check water bounds and walls. Distant machines do not run movement queries.

Only one nearby robot may own notice/warning/attack/recovery at a time. Three-and-a-half-meter checkpoint safety zones and the arrival/crown/finale route limits suppress attacks. Enemies have no blocking body collision and do not occupy stepping-stone landings, return ramps, or the mandatory dive bar.

Netbot uses its actual animated basket socket during the active cast interval. Capture allows three separate tail whacks strictly before two seconds, otherwise the player returns to the checkpoint without an extra life penalty. Escape swings tear the net; attack again to break the robot.

Hookline throws the visible hooks at a locked player position. Contact during the active throw temporarily snags an equipped Gill Mod through the existing timer. A player without a mod can still avoid or destroy these optional traps. Hooks retract over three seconds and do not home or apply new hits during recovery.

## Player hits and breakup

Both ordinary Netbots and Hooklines now break on one clean hit. Hookline roster durability changed from two to one to implement the requested ordinary-robot hit response. Tougher unused roster entries retain their tuning.

Forward whacks resolve during the 0.12â€“0.40 second contact interval with a forward strike volume and wall rejection. Swimming charges sweep between body positions throughout the active burst, catching enemies reached after activation. Each unit is hit at most once per action. Descending body contact supports the existing stomp counter.

Defeat cancels the attack and hides its vulnerable actor. The actual textured chassis is split into four mesh pieces, with arm/net or hook pieces separated. Shared fragment meshes retain the source surface materials. Up to six rigid pieces per defeated robot tumble and bounce, with reduced gravity underwater, metallic impact audio, no player collision, and removal after three seconds. No required currency is dropped. Checkpoint returns reset the attempt, cancel queued attacks and remove debris.

## Verification and limits

`tools/verify_enemy_population.gd` exercises all eight production placements, safe arrival, habitat/ground support, visible acquisition, wall rejection, net capture/escape/timeout, forward-only hits, real mesh breakup and cleanup, independent defeats, a charge that reaches a robot later, committed Hookline targeting, slow retraction, and checkpoint reset. This supplements the existing combat/enemy regression and animation suites. Review images are actual Godot frames with scripted positioning and input timing; they are not a full human balance playthrough or mobile performance certification.


Final verification: 83 production checks, seven additional real-keyboard/physics checks, and 39 existing combat/enemy regression tests passed. The level contract and static gate passed. The grotto Hookline was relocated to (-10, -1.6, -63) after full body-clearance checks detected an arch overlap missed by a floor-only ray. The live keyboard test covers F on land, F underwater, and descending contact; underwater movement and shallow downward walking do not count as stomps.

The test harness still reports pre-existing ObjectDB/resource cleanup warnings at shutdown (including the older fleet regression suite). The corrected production encounter test completes without script errors. The visual-review teardown audio playback error found in this pass was fixed by refusing playback when the audio owner has left the scene tree.


## Motion polish — 29 September 2026

All three Netbots now occupy dry banks and terraces. Five Hooklines cover three underwater positions and two dry sentry positions. S03_N01 was replaced by S03_H02; gameplay tests use the new unique ID. Existing scene instancing automatically picks up the population changes, including world rebuilds.

Movement uses acceleration and braking with distance-based arrival speeds, a separate continuous patrol clock, bounded angular acceleration (2.2 rad/s maximum turn speed) and a smooth return to the home heading. Small terrain-height differences settle gradually. Existing five-point support, water-bound and body-sweep collision checks remain in place. Robots finish aiming within roughly ten degrees before entering warning, so a gradual turn cannot cause a sideways wind-up. Attacks still commit and do not rotate to follow dodges after release.

Ordinary pose changes blend for 180 ms; stagger blends for 60 ms. Authored attack/recover endpoints match directly, preserving contact times. Repeated idle requests retain animation phase. Bounded cubic pose curves carry motion through intermediate poses without overshoot or unnecessary stops. Speed-driven chassis suspension and restrained banking settle smoothly when stationary. Hookline tucks the hooks during warning so the committed target cannot produce a position jump at release; shallow throw/retract arcs differ on land and underwater. Its three-second retraction remains harmless. Immediate attack-window cancellation also guards against an outgoing blended clip reopening a hit window.

Validation: 101 production placement/encounter checks, 180 animation checks, 29 new motion checks, 7 actual-input checks and 39 combat regressions passed. `tools/verify_enemy_motion.gd` checks acceleration at 30/60/120 Hz, travel consistency, braking, 180-degree turn limits, placement policy, transition continuity, release continuity, contact windows, cancelled-hit safety and monotone Hookline retraction. Existing teardown leak warnings remain in older harnesses. These checks do not certify full-game frame rate or Astro Bot art/animation parity.
