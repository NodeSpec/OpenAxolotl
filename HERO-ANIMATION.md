# Axolotl Animation And Surface Interaction

## Play And Review

Run `Play Lagoon.cmd`, or import `project.godot` in Godot 4.7.2 and press F5. The improvements belong to the shared character, not just the lagoon. WASD moves, Space jumps/swims upward, F swings the tail on land or spins in water, and Shift rolls on land or swims downward.

`review/hero-motion.avi` is an actual 30 FPS Godot recording with close review cameras: walking, turning, stationary and moving tail attacks, shallow-water foot splashes, swimming, and a barrel spin. The swimming segment uses Coral Cove. `Capture Hero.cmd` regenerates it and the accompanying PNG frames without writing player progress. It is a short inspection sequence, not a performance benchmark or the normal gameplay camera.

## Changes

- Smooth visual heading, body banking, head lead, delayed tail follow-through, and restrained gill motion.
- Speed-responsive walking cadence, ground-normal body alignment, and bounded stance-foot correction on uneven ground.
- Swimming posture blends into a torso-centered position. Spin and roll curves ease into and out of the turn; swimming spins make two full revolutions with tucked limbs.
- Tail attacks have anticipation, a fast delayed-segment sweep, counterrotation, and recovery. Walking legs continue their gait during moving attacks.
- Actual gait contacts select shallow-water spray or dry sand grains and fading toe prints. Landing impacts scale with impact speed. Sand effects require a sand surface tag and do not emit underwater.
- Swimming wakes, trailing spin bubbles, and a short tail-tip ribbon reinforce movement without changing damage or reach.
- Private material instances preserve the authored textures while adding wet sheen that gradually dries.

The original character GLB, collision capsule, controller movement, combat hit windows, and level routes remain unchanged. Action animations are replaced only on private runtime animation copies. New sandy surfaces can join `surface_sand` or set `footstep_surface` metadata to `sand`; other ground does not automatically emit sand.

## Limits

This is an animation and interaction polish pass, not a finished Astro Bot-quality character. The existing 12-bone rig has one joint per limb, no knee/ankle chain, and no facial rig. Foot placement is a small angular correction, not full leg IK or guaranteed foot locking. Bespoke rigging, authored performance clips, facial animation, and further mesh/skin-weight refinement are still needed for that production target. No new high-fidelity mesh was generated.

## Verification

- Focused animation, motion, and combat tests: 33 passed, 0 failed.
- Rendered input-driven review: 138 checks, 0 failures, including capture writes, moving pixels, gait effects, attack behavior, and measured skeleton spin travel.
- Shared suite: 610 passed, 1 pre-existing failure, 611 total. The existing kit-prop vertex-color test still fails on original assets; it was not suppressed.
- Lagoon water traversal: 21 passed. Coral Cove traversal: 29 passed. Bubble Bay traversal: 22 passed.
- Forward+ render inspected on the NVIDIA GeForce MX250. These runs do not certify 60 FPS. Existing harness and rendered shutdowns still report leaked objects/resources and texture RIDs; the whole-project run is not warning-free.

From this directory, with Godot on PATH:

```powershell
godot --headless --audio-driver Dummy --path . --script test/run_hero_tests.gd
godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
godot --path . --audio-driver Dummy --fixed-fps 30 --write-movie review/hero-motion.avi --script tools/hero_review.gd
```

Main implementation: `hero_animator.gd`, `hero_action_clips.gd`, `hero_motion.gd`, and `hero_surface_effects.gd` under `core/rendering/`, integrated by `core/controller/axolotl_body.gd`.
