# Living Cascade — underwater ground depth

The ground throughout S01–S06 now blends from pale shallow sand into darker blue-green sediment as local water depth increases. Existing fine sand and river-pebble maps supply detail; the pebble share increases with depth while broad irregular patches break up the mixture.

## Section treatment

| Section | Ground treatment |
|---|---|
| S01 · Arrival pool | The inlet and shore ramp retain pale sand near the surface. The lower pool bed blends into darker blue-green sediment with more visible pebble patches. |
| S02 · Stepping-stone garden | Light margins lead into the deeper ground around the stepping stones. Existing sand grain, pebbles and surface relief stay visible through the colour transition. |
| S03 · Root passage | The deeper passage bed now shares the blue underwater palette of the refined arches. The shallower approach remains lighter, with a blended transition at the entrance. |
| S04 · Terrace dive pool | The ground uses this raised pool’s actual water height. Its deeper dive approach receives darker pebbled sediment while the approach above the water keeps its warm sand. |
| S05 · Crown courtyard | The courtyard basin has pale sloping edges and a darker centre. The separate scenic source pools and runoff also contribute their local water heights. |
| S06 · Downstream chute | Depth follows the curved, descending water surface. The bed keeps a consistent deep tone along the chute, while rising banks and the exit ramp become lighter. |

## Implementation

- `dev/living_cascade/cascade_ground_depth.gd` computes water depth during the normal production build, using the actual water volumes, their priorities and the shared sloping channel profile. Four scenic source/runoff water planes are included separately.
- The helper writes signed depth and coverage into unused green/blue vertex-colour channels. The existing red planting mask, vertices, normals, indices and collision shapes are preserved. A coverage mask limits the effect to water areas; vertical bounds prevent raised scenic pools from colouring unrelated ground beneath them.
- `core/rendering/cascade_pbr_ground.gdshader` blends shallow, middle and deep sediment with smooth overlapping ranges. Submersion fades in over approximately 0.025–0.22 m; mid-depth colour develops over 0.15–1.75 m, and the deepest colour develops over 1.10–3.20 m. Pebble blending increases across approximately 0.20–3.20 m. These are art-tuning ranges, not gameplay thresholds.
- `dev/build_cascade_production.gd` runs the bake after terrain and asset dressing and checks the resulting metadata before replacing the production scene. `worlds/coral_cove/world.tscn` contains the saved material bindings and depth data.

The bake covers 71 meshes and 21,734 vertices, including 4,996 submerged vertices. Section totals: S01 8, S02 7, S03 6, S04 26, S05 10, S06 13, plus the shared perimeter foundation. Only floor and bank materials receive the new depth treatment; wall and supplied prop materials remain unchanged.

Depth follows each water surface instead of a single map-height threshold. For example, the tested S04 dive-pool water surface is 3.8 m in level-local coordinates and the tested S05 basin surface is 6.2 m. The chute uses its continuous profile as it descends. All calculations remain valid when the entire level is translated for the starting-lagoon connection.

This is a build-time depth field for the current static terrain and water layout. Rebuild the production scene after moving water or reshaping the ground. The shader interpolates stored depth during rendering; it performs no per-frame CPU water queries. Existing 2K maps and their CC0 source records remain in `assets/environment/cascade_surfaces/sources.json`. No new images were generated, downloaded or upscaled.

## Validation for this change

- Nine comparisons against runtime water depths passed: one in every section and three additional equal-depth points along the descending chute. The test translates the loaded world before checking its water surfaces.
- Saved-scene inspection compared every treated mesh’s faces to the previous scene: 71 unchanged meshes. It also checked 1,565 stored vertex masks and the retained planting channel after save/reload.
- Eleven focused tests passed for fall recovery, supplied assets and rendering contracts. The full 625-test suite and full gameplay route were not rerun for this material change.
- All nine original supplied models, all nine external collision resources, the optimized tunnel GLB and all 15 terrain source maps retain their previous SHA-256 hashes.
- Scene geometry remains 2,959,022 triangles, below the unchanged 3,000,000 ceiling.
- Static analysis and level contract checks passed. Matching section views rendered without script or shader errors and were visually inspected.
- GPU quality ordering passed on this computer. These GPU-only timings are a current-machine sample, not a sustained whole-game frame-rate claim or a baseline-hardware certification.

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5090 Laptop GPU

GPU GATE (coral_cove, 1920x1080, NVIDIA GeForce RTX 5090 Laptop GPU)
  low     mean   0.75 ms  p95   0.92 ms  worst   0.93 ms  (96 frames)
  medium  mean   1.67 ms  p95   1.96 ms  worst   2.01 ms  (96 frames)
  high    mean   3.75 ms  p95   4.48 ms  worst   4.53 ms  (96 frames)
  low vs medium: 2.23x apart (needs 1.12x) OK
  medium vs high: 2.25x apart (needs 1.12x) OK
  ADVISORY: medium p95 is 1.96 ms here. On a 60 fps budget of 16.67 ms this is only meaningful when run on the target machine.
GPU GATE: PASS
```

The saved review compares the previous blue-tunnel scene and this ground update with matching cameras and lagoon lighting. Animated water may be in a different phase. Layout, collision, blue tunnel materials, ordinary fall recovery and gameplay are unchanged. No Git commit was created.
