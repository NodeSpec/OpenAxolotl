# Hero animation refinement

Implemented September 19, 2026 in the existing OpenAxolotl Godot project.

- Tail whack: deeper anticipation, stronger proximal tail sweep, torso counter-turn and a slightly wider short-lived sweep ribbon. Existing clip duration, combat reach and controller strike behavior are preserved.
- Active swimming: speed blends the feet into a close trailing posture. A phase-delayed lateral wave moves from spine to tail with increasing amplitude. It replaces the moving imported wave rather than adding two competing cycles. The head counteracts part of the torso bend.
- Underwater idle: the original four foot-direction curves are preserved exactly at zero swim effort. Existing gentle idle tail movement remains.
- Land dodge: the existing roll action now uses a grounded slide presentation, feet swept back and a shallow 5.5 cm torso drop that only applies on the floor. Collision, speed, duration and bindings are unchanged.
- Underwater charge: three tapered current ribbons wrap around the torso; short bubble bursts move tangentially outward and drift upward. No physical current force is added. Geometry is bounded to 144 ribbon triangles; effects stop at water exit and fade at charge completion.
- Surface contact: ground raycasts gate slide grit. Sand gets temporary scuffs; other dry ground gets smaller neutral grit; submerged contact gets spray. Airborne and swimming states produce no slide disturbance. Existing 32-mark cap and three-second fade are shared with footprints.
- Equipment follows the same rig. Foot-contact fitting now excludes the backpack mesh, whose leg-weighted harness is not part of the feet.
- Splash cleanup uses a weak reference so a pending lifetime timer is safe after scene unload.

Validation: 46 focused character/backpack/motion/combat/rendering tests passed; 22 real-input gameplay checks passed in the starting lagoon and Living Cascade. Captures cover whack, active swim, idle swim, charge and land slide, including recovery. They also test airborne suppression, effect cleanup, unchanged capsule displacement during whack, and equipment attachment. Four new regression tests cover unchanged idle curves, close swimming limbs, wave timing, slide posture, stronger strike amplitude, and stable flow frames during vertical or zero-speed motion. Static gate and level-contract checker passed. Original hero GLB SHA-256 remains ed167e1f2a1fd1c54bcb91524211f9af57cfe985a7b92cd4083757c58060dd5d.

No script errors in the final tests or captures. Full-level shutdown retains the existing seven-texture RID cleanup warning; it is not resolved by this work. No Git commit created.

Files changed: core/rendering/hero_action_clips.gd, hero_motion.gd, hero_surface_effects.gd, hero_slide_scuff.gdshader, water_splash.gd, and test/core/rendering/test_hero_motion.gd. Existing source backups are in the task workspace work/animation-polish. Gameplay and studio capture harnesses remain in the task workspace work folder. Review: hero-animation-review.html.


## Forward strike follow-up

The whack now pivots the hips approximately 103 degrees at full extension, with the root orbiting around the visual character centre on the ground plane. Shoulders and head counter-turn toward the target. Most tail bend is at the base, with a straighter outer tail so it sweeps outward into a forward strike instead of coiling beside the torso. The pose is applied by the existing SkeletonModifier and restores after the action; no controller/capsule motion is added.

The live rig reached 0.978 m forward of the character centre and 0.437 m ahead of the head. Nine in-game checks passed, including keyboard activation, fixed capsule position and exact root-position recovery. The expanded 47-test focused suite passed; its new spatial regression samples the generated clip across the whole swing and checks forward reach, head clearance, and an above-ground tail. Actual gameplay and overhead captures are in the updated replay. The prior static/level gates were not rerun for this two-file pose adjustment. The existing seven-texture shutdown warning remains. No Git commit.
