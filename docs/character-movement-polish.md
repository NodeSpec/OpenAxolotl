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
