# Living Cascade — custom terrain revision

Custom terrain now supplies the continuous landscape; the detailed supplied models remain selected landmarks and usable rock platforms. This supersedes the blanket full-model dressing pass.

- Detailed Cascade placements: **52**, previously 428.
- Separate decoration: 2,757 grass tufts, 308 small procedural pebbles, 29 plain lagoon stones, cliff ferns and the existing four small rock ScatterFields.
- Custom continuous terrain volumes: 116, plus the channel banks and landing supports.
- Full scene counter including the hero and shadows: **2,782,949 triangles**, down from **15,959,035** (82.6% reduction).
- Scene triangle ceiling tightened from 16 million to 3 million. Frame-time targets were not changed.

## Section decisions

### S01 — Arrival pool

Continuous sandy and grassy banks replace tiled mossy-rock floors. Sculpted shore slopes, short grass patches, lagoon stones and a planted cliff accent lead out of the starting tunnel.

### S02 — Stepping garden

The ten landing stones across S02 and S04 retain their full models and collision. Their supporting columns are custom rock meshes; recovery banks have continuous soil, grass and clear walking lines.

### S03 — Root passage and grotto

The full root bridge and hollow reef arches remain the landmarks. Continuous cool-toned stone walls and a pale bed replace the repeated reef-wall rows. Pebbles and a few complete reef accents frame the swim and rescue junction.

### S04 — Rising terraces

Banks, climb surfaces, sloped connectors and retaining cliffs share a terrain material family. Grass stays away from the route. A headwater bed and rims feed the scenic waterfall above its impact pool.

### S05 — Crown courtyard

Patchy meadow and sandy paths replace the carpet of repeated stones. The crown retains its flowering arch. Its waterfall has a raised source basin, a lip, shallow runoff and a small drop into the existing basin.

### S06 — Chute and finish

Two continuous carved banks replace rows of corner-rock models. A continuous bed and single water surface follow the channel height profile, removing visible strip seams at bends. The root bridge, dive arch and reward reef remain, with grass and smaller stones around the finish bank.

## Placement, material and collision approach

Fixed seeds produce irregular patches and varied stone sizes without changing placement each run. The route clearance mask keeps taller planting away from primary movement lines. Source asset files are unchanged. Broad terrain uses section-specific sand, grass and stone colours, with restrained grain, moss distribution and wetness. These are custom terrain surfaces, not baked pictures of the supplied models.

Each new bank, ramp and cliff uses subdivided geometry and matching mesh collision. Stable body paths and climbable groups are retained. Perimeter and gate walls also retain an interior solid backstop. The old chute floor segments are disabled after one continuous, collidable bed is generated from the water profile. Simple internal shadow meshes reduce self-shadow striping; grass uses the existing ScatterField pipeline with a procedural mesh extension so transforms survive headless builds.

The S05 front remains the existing open balcony over catch pools. Intentional routes, recovery water and the lagoon inlet remain open. The tests sample route and boundary behavior; they are not an exhaustive proof for every player jump, camera angle or future enemy attack.

## Verification

- Unit suite: **PASS**. 623 tests, including persistent procedural scatter and custom-terrain collision.
- Production route: **PASS**. Translated full traversal, restoration, recovery, camera hints and saved progression.
- Leftmost tunnel: **PASS**. Starting lagoon through the actual finish, hub return and side-world use.
- Containment and rescue: **PASS**. 3,581 checks covering floor coverage, perimeter rays, landing supports, gate actions and grotto rescue.
- Shared water alignment: **PASS**. Every channel area references the visible surface; channel-center coverage, vertex height and triangle interpolation are checked against the swimming profile.
- GPU quality gate: **PASS**. Quality ordering on the RTX 5090 Laptop GPU at 1920 × 1080; baseline hardware remains unverified.
- CPU timing: **PASS**. The existing 50 ms spike, loading and sustained simulation targets are unchanged.

GPU log:
```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5090 Laptop GPU

GPU GATE (coral_cove, 1920x1080, NVIDIA GeForce RTX 5090 Laptop GPU)
  low     mean   0.66 ms  p95   0.83 ms  worst   0.84 ms  (96 frames)
  medium  mean   3.06 ms  p95   5.15 ms  worst   5.48 ms  (96 frames)
  high    mean   7.87 ms  p95  10.63 ms  worst  11.69 ms  (96 frames)
  low vs medium: 4.66x apart (needs 1.12x) OK
  medium vs high: 2.58x apart (needs 1.12x) OK
  ADVISORY: medium p95 is 5.15 ms here. On a 60 fps budget of 16.67 ms this is only meaningful when run on the target machine.
GPU GATE: PASS
```

CPU log:
```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==================================================================
PERF GATE (coral_cove): load 671.3 ms (budget 3000) | restore frame 13.7 ms
  spike (after discarding 1) 29.0 ms, worst 31.5 ms (budget 50) | rate 59.2 fps over 3922 frames
PERF GATE: all measurable targets hold
```

The unit runner retains the same pre-existing camera/RID/resource cleanup warnings at exit. Runtime render and traversal logs are evaluated separately. Level-contract and static-analysis reports are stored with the verification evidence.

The builder now checks for completed terrain and asset metadata before overwriting the production scene. A failed dressing dependency therefore keeps the existing built scene. The water checker supports an explicit shared surface, preserving its existing 0.001 m vertex and 0.12 m triangle-height tolerances; extra triangles are generated only where the profile needs them.

## Review limits and rebuild

This is a playable custom-terrain art revision, not a claim that every view has reached final lagoon-quality art direction. The large cliff faces, waterfall presentation and close wall/camera angles still warrant human review. The waterfall sources and runoff are scenic assemblies; the existing gameplay water and current volumes remain authoritative. Antagonist animation and encounter logic were not implemented in this terrain pass.

GPU timings varied substantially between runs on this machine. The quality-ordering check passed, but the final timing sample should not be extrapolated into a guaranteed gameplay frame rate. CPU timing was measured after the collision and terrain changes; the subsequent refinements changed the rock shader and merged the visual water strips.

- Builder: `dev/build_cascade_production.gd`.
- Placement: `dev/living_cascade/cascade_asset_dressing.gd`.
- Terrain: `dev/living_cascade/cascade_landscape.gd`.
- Materials: `core/rendering/cascade_ground.gdshader`, `cascade_grass.gdshader`.
- Persistent generated scatter: `core/rendering/cascade_mesh_field.gd`.
- Scene: `worlds/coral_cove/world.tscn`.
- Backup: workspace `work/cascade-before-custom-terrain/`.
- No Git commit created.
