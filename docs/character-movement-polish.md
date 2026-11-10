# Character movement and animation pass

Implemented in the shared controller and hero scene, affecting the starting lagoon and Living Cascade.

## Movement

Ground acceleration is 36 m/s²; underwater and air steering use 24 m/s². Opposing input multiplies braking acceleration by 1.5. These live in the tuning file. Base land/swim speed, hop impulse, coyote time, jump buffer, combat timings and capsule dimensions are retained. Land stopping and underwater coasting retain their existing drag.

Gamepad movement axes preserve magnitude after a steering deadzone of 0.18. Digital diagonals remain capped at unit length. Action axes retain their existing threshold. The jump-release cut is applied once per jump instead of repeatedly multiplying upward velocity every frame. Ground floor snap is 0.18 m.

## Animation

Locomotion animation uses measured body displacement after collision; carried current is removed for swimming effort. Walking clip speed follows travel immediately, including slow analog movement. Water/land clip transitions blend over 0.20 s. The existing body posture, tail wave, idle underwater paddle and combat clips are retained.

Foot contacts anchor in world space during stance with bounded rotational correction. Anchors release on loss of support, swing, water entry, actions, fast turns, excessive reach, or pose reset. One bone per limb limits the existing rig: this is a bounded planting improvement, not a new multi-joint IK rig. Acceleration/braking add restrained body pitch. Visual animation does not move the physics capsule.

## Suit preparation

`AxolotlBody.get_suit_mount()` exposes `Model/SuitMount`. This is an empty visual integration point, not an enabled suit mechanic. Keep collision and the controller on the body. Once the asset and intended power arrive, decide whether it shares the existing skeleton or needs an adapter. Use the existing capability modifiers and ability hooks for powers; remove only the suit's own modifiers on unequip, leaving regeneration and other systems intact. Do not infer abilities from the visual reference alone.

## Verification

171 unit/regression tests including acceleration at 30/60/120 Hz, analog speed, reversals, jump release, existing jump forgiveness, animations, attacks and input remapping. Four older speed assertions now wait for acceleration to settle, while dedicated tests verify first-frame response.

Runtime checks include 66 passage/platform crossings, the translated full production route, 3,581 containment checks, seven real combat input checks, 19 lagoon checks and 17 collectible/dance/save checks. Navigation fixtures suppress enemy attacks only in the test fixture; combat tests exercise the production AI separately. Visual review captures real keyboard input in the lagoon and Cascade.

Original project files are backed up in the task workspace under `work/movement-polish/backup`. No source GLB was regenerated.

## Natural swimming turn refinement

Free swimming visual yaw now ramps angular speed, with a 240-degree/s cap and 850-degree/s² acceleration. The head leads within a bounded neck angle, the torso banks, and the turn propagates down the tail. Actions retain their existing response. Pose reset clears turn momentum. This modifies visual orientation only; controller steering, collision geometry and passage paths are unchanged. Added tests cover angular acceleration, rate limits, settling, neck bounds and reset.

## Riverheart milestone — first hero pass, 10 November 2026

This bounded pass begins REQ-002 before encounter-section construction. The [current storyboard](design/first-adventure-storyboard.md) puts Skippy's motion first, route clearance second, then one polished encounter, lighting/vegetation and the Riverheart sequence. Historical counts above are not fresh verification of this revision.

Walking starts above 0.25 m/s and continues until measured speed falls to 0.15 m/s. This small hysteresis removes idle/walk chatter around the threshold without delaying the controller. The gait clock is retained through stops and moving tail whacks. On the last whack frame, only the time remaining after the action advances locomotion; the legs no longer consume the same time twice. Animation speed still follows actual collision-resolved displacement.

Landing squash now scales smoothly with incoming velocity into the contacted floor normal, from no deformation at or below 0.6 m/s to the existing full deformation at 6 m/s. Higher impacts stay bounded and volume-preserving. Tiny floor reacquisitions do not emit a full landing sound. Checkpoint visual reset clears squash, gait/action phase, swim effort, swim offset and swim-turn momentum. Wetness still dries gradually.

### Transition policy v1 — implemented subset

| Transition | Current policy | Remaining quality work |
| --- | --- | --- |
| Idle → start/travel | Start above 0.25 m/s; restore gait phase; 0.12 s blend | Authored start pose and multi-joint foot contact |
| Travel → stop/idle | Stop at or below 0.15 m/s; retain phase; 0.12 s blend | Authored braking and turn-in-place poses |
| Walking → whack → walking | Preserve walking feet; action priority unchanged; consume action-boundary time once | Production-camera review of all directional strikes |
| Rise → fall → land | Existing hop/fall selection; floor-normal impact scales visual landing | Dedicated landing clip and varied slope/contact reel |
| Land ↔ swim | Existing 0.20 s clip blend and procedural body posture | Surface/dive silhouettes and full seam traversal review |
| Swim turn/idle | Existing bounded turn, traveling tail wave and idle paddling | Improved rig and normal/slow-motion approval |
| Capture/dance/damage | Existing action priority and cancellation rules retained | Full token/interruption matrix remains open |
| Checkpoint reset | Clear action/gait, squash and procedural swimming pose | Full adventure reset/re-entry acceptance remains open |

Fresh evidence: 62 focused unit tests passed, plus the live AnimationPlayer gait-continuity probe (six assertions). The live probe verifies stop/resume, a tail-whack ending between sample boundaries, and action/phase reset. Run it with Godot `--headless --path . --script res://test/core/rendering/run_hero_gait.gd`. A scripted Lagoon input sample captured idle, travel, whack, hop, fall and landing with the production hero/camera; Compatibility before/after images are motion inspection only, not a rendering-quality comparison or deterministic traversal proof. A separate Forward+ capture uses the project's normal renderer.

The twelve-bone model still has only one joint per leg. This pass does not provide full leg IK, a new rig, complete transition coverage, an approved animation reel, or a cleared collision route. The Riverheart gameplay and new encounter section are not implemented here. The mobile prototype remains parked.

