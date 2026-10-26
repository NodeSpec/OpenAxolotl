# Living Cascade — texture and shore refinement

All six sections now use detailed surface maps, with the starting lagoon's palette and actual broadleaf/vine geometry reused for continuity. The continuous terrain and selected full-model landmarks remain the level's structure.

## Section decisions

### S01 — Arrival Pool

Warm sandstone and pale sand carry the lagoon palette into the level. Curved grass blades and broadleaf plants soften the banks. Two rock shoulders close the inlet sides while keeping the stream corridor clear.

### S02 — Stepping-stone Garden

Textured sand and planted soil surround the complete landing-stone models. Rock cracks, darker wet edges and softer shore rims make the recovery banks read as continuous terrain.

### S03 — Hollow-root Dive

The submerged bed blends sand with river pebbles. Cooler mossy stone frames the root passage and rescue grotto; the supplied hollow arch models retain their original surfaces and collision.

### S04 — Cascade Terraces

Mossy rock distinguishes the climb and dive route. Textured headwater rims and beds tie the waterfall source to the cliffs. Sandy connectors and short planting keep the movement route readable.

### S05 — Restoration Garden

Warm rock walls surround patchy meadow and sandy paths. Curved grass and lagoon vines add detail around the courtyard. The flowering crown arch, raised source basin and restoration progression remain in place.

### S06 — Waterfall Run

The continuous channel banks use mossy stone, sand and planted tops. The finish shore joins the closed foundation. A nonlethal checkpoint return backs up the physical boundaries throughout the Cascade.

## What supplies the detail

Five CC0 material families supply 15 real 2048 × 2048 maps: colour, OpenGL normal and packed ambient-occlusion/roughness/metalness (ARM). The shader uses colour, normals, occlusion and roughness; these terrain surfaces are nonmetallic. All maps use mipmaps and high-quality VRAM compression. Triplanar stone projection reduces dependence on mesh UVs. Broad noise and planting masks break up repetition, while sand/grass transitions and a restrained wet band distinguish banks from submerged beds.

Grass is curved geometry with root-to-tip shading and wind, replacing the old triangular spikes. There are 2,757 grass tufts, 308 small pebbles, 29 lagoon stones and 2,945 broadleaf/vine leaves. Lagoon foliage is generated with the existing LagoonArt implementation during the build and saved as static meshes; it does not regenerate at runtime.

Bank corners and shore lips are softened away from the main route, with collision rebuilt from the same terrain mesh. The scene contains 118 custom terrain volumes and 52 selected supplied model placements. The full scene counter, including the hero and shadows, is **2,959,022 triangles**, below the unchanged **3,000,000** ceiling. Source model triangle counts and all original GLBs are unchanged.

## Fall protection

The visible foundation is 86 × 137 m, reaches y = -3.75 at its top and overlaps the perimeter wall feet and inlet. Two solid inlet shoulders close the sides of the stream entrance. Existing high banks and dividing walls remain continuous.

The Cascade's ordinary fall volume is now `safe_return_volume`, not a life-costing pit. Its upper edge is y = -3.5, below the deepest authored bed at -3.2. It returns an escaped player to the active checkpoint without spending a life or altering collected progression. The 126 × 177 m footprint includes a 20 m margin around the foundation and stays scoped to the Cascade instead of covering the connected lagoon.

Nine physical drops cover every section plus west/east/south floor seams. A forced escape outside the floor also returns to the checkpoint without a life cost. These checks and the 3,581 containment samples are evidence for the tested routes and seams, not exhaustive proof of every possible jump or future enemy knockback.

The proposed whirlpool is **not implemented**. It remains the planned intentional suction/fall hazard for a later encounter pass. Other worlds' existing pit behavior is unchanged.

## Fair visual comparison

The review rerenders the archived previous scene and current scene using the same cameras, Medium quality and actual continuous-world lagoon lighting. The connected Cascade already retains that lighting during gameplay. Earlier standalone review captures used the generic world lighting, making their colours a poor comparison; no runtime lighting change was needed here. The lagoon reference image is an existing project capture.

## Verification

- **Unit suite:** 625 passed, 0 failed. The final recovery-volume refinement also passed 11 focused regression tests.
- **Playable journey:** Production traversal, restoration, saving and checkpoint return passed. The real leftmost lagoon tunnel passed all 35 checks.
- **Containment:** 3,581 floor, boundary, landing, gate and rescue checks passed. Nine physical drops and one forced escape returned safely without losing lives.
- **Performance:** CPU regression and GPU quality-ordering gates passed. High quality reached 20.88 ms GPU p95, so this does not establish 60 fps on High. The existing geometry and timing targets were retained.
- **Asset integrity:** All nine original GLBs are unchanged. All 15 surface maps were verified as real 2048 × 2048 files against their source hashes.

The unit runner still reports its pre-existing exit cleanup leaks: 3 camera RIDs, 478 ObjectDB instances and 25 resources. These counts match the previous run. The final route, capture, fall and focused regression runs reported no script or shader errors.

CPU log:
```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==================================================================
PERF GATE (coral_cove): load 1317.1 ms (budget 3000) | restore frame 13.8 ms
  spike (after discarding 1) 28.2 ms, worst 34.1 ms (budget 50) | rate 59.1 fps over 3922 frames
PERF GATE: all measurable targets hold
```

GPU log:
```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5090 Laptop GPU

GPU GATE (coral_cove, 1920x1080, NVIDIA GeForce RTX 5090 Laptop GPU)
  low     mean   1.46 ms  p95   3.70 ms  worst   3.71 ms  (96 frames)
  medium  mean   5.19 ms  p95  10.32 ms  worst  12.16 ms  (96 frames)
  high    mean  10.62 ms  p95  20.88 ms  worst  24.75 ms  (96 frames)
  low vs medium: 3.56x apart (needs 1.12x) OK
  medium vs high: 2.05x apart (needs 1.12x) OK
  ADVISORY: medium p95 is 10.32 ms here. On a 60 fps budget of 16.67 ms this is only meaningful when run on the target machine.
GPU GATE: PASS
```

GPU quality ordering was measured on an RTX 5090 Laptop GPU at 1920 × 1080. GTX 1650-class baseline performance remains unverified. The texture pass does not replace the level's broad wall silhouettes, finish waterfall spray/foam effects, or add enemy animation/AI. Waterfall source basins are scenic; existing gameplay water volumes remain authoritative. Final art and camera review should happen through the actual leftmost tunnel.

## Files and rebuilding

- Terrain material: `core/rendering/cascade_pbr_ground.gdshader`.
- Texture selection: `dev/living_cascade/cascade_surface_library.gd`.
- Geometry and planting: `dev/living_cascade/cascade_landscape.gd` and `core/rendering/cascade_grass.gdshader`.
- Builder and recovery: `dev/build_cascade_production.gd`, `hub/world_systems.gd`.
- Production scene: `worlds/coral_cove/world.tscn`.
- Surface assets and provenance: `assets/environment/cascade_surfaces/`.
- Regression tests: `test/worlds/test_cascade_assets.gd`, `test/worlds/run_cascade_safe_falls.gd`, `test/worlds/run_cascade_production.gd`, `test/hub/test_fall_recovery.gd`.
- Rebuild after importing assets: `godot --headless --path . --script res://dev/build_cascade_production.gd`.
- Visual comparison archive: `dev/archive/cascade_before_pbr/`. This is not the active level.
- Logs and counters: `review/cascade-polish-verification/`.

No Git commit was created.

## Texture sources

All five families are published under [CC0 by Poly Haven](https://polyhaven.com/license). `sources.json` records exact download URLs, authors and SHA-256 hashes. Its catalog `dimensions` field is source metadata, not raster pixel size; `cascade-polish-integrity.json` records verified pixel sizes.

- [rock_face_03](https://polyhaven.com/a/rock_face_03) — Dario Barresi, Rico Cilliers.
- [mossy_rock](https://polyhaven.com/a/mossy_rock) — Rob Tuytel.
- [sand_01](https://polyhaven.com/a/sand_01) — Rob Tuytel.
- [leafy_grass](https://polyhaven.com/a/leafy_grass) — Charlotte Baglioni.
- [dry_river_pebbles](https://polyhaven.com/a/dry_river_pebbles) — Amal Kumar.
