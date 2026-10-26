# Living Cascade — blue underwater tunnel correction

The previous tunnel refinement shifted the stone toward the lagoon's warm land palette. This correction restores its blue underwater identity while retaining the independent high-detail textures.

## Surface layers

- **Blue mineral rock:** the real 2K `rock_face_03` colour, normal and ARM maps supply cracks, grain and surface response. Luminance detail is mapped into the blue mineral palette, rather than magnifying the source model's crowded atlas.
- **Teal weathering:** the existing `mossy_rock` colour map supplies a separate algae-like texture. Broad spatial variation and upward-facing surfaces control its blend. This is a styled moss texture, not a new underwater scan.
- **Fine pitted detail:** the existing `dry_river_pebbles` colour and OpenGL normal maps contribute smaller deposits and relief. They are projected at 2.2 times the main texture frequency, preventing all detail from sharing one repeated scale.
- **Original accents:** the model-specific colour mask retains green plants, purple/warm coral and cyan accents from the original atlas. The original angular mesh silhouette is unchanged.

The main texture repeats approximately every 1.67 m; finer detail repeats approximately every 0.76 m. Triplanar projection and anisotropic mipmapped filtering decouple stone detail from the model's enlargement. No new raster images were generated, downloaded or upscaled. Source maps remain byte-identical.

## Implementation

The correction changes `core/rendering/cascade_tunnel.gdshader` and `dev/living_cascade/cascade_tunnel_material.gd`; the normal development build saves the material bindings into `worlds/coral_cove/world.tscn`. The previous imported-scene ownership fix remains in place. All six `reef_arch` placements use the same corrected material. Other asset materials, terrain, lighting, gameplay and fall protection are unchanged.

## Validation for this correction

- Saved-scene inspection: six tunnel surfaces, each with all required 2K maps; no other supplied assets use the tunnel shader.
- Four actual Godot camera views inspected: root passage, grotto, terrace dive arch and chute. Capture logs contain no script or shader errors.
- All nine external collision resources, the optimized tunnel GLB and all 15 terrain source maps match their previous SHA-256 hashes.
- Scene triangle count remains 2,959,022, within the existing 3-million ceiling.
- GPU quality-ordering gate passed. This is a current-machine sample, not proof of a sustained target frame rate on baseline hardware.

This material-only correction did not rerun the full gameplay/unit suite. The earlier containment and regression records remain in the previous tunnel review; collision and geometry were verified unchanged here.

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5090 Laptop GPU

GPU GATE (coral_cove, 1920x1080, NVIDIA GeForce RTX 5090 Laptop GPU)
  low     mean   0.74 ms  p95   0.91 ms  worst   0.91 ms  (96 frames)
  medium  mean   1.67 ms  p95   1.97 ms  worst   1.99 ms  (96 frames)
  high    mean   3.82 ms  p95   4.51 ms  worst   4.64 ms  (96 frames)
  low vs medium: 2.26x apart (needs 1.12x) OK
  medium vs high: 2.29x apart (needs 1.12x) OK
  ADVISORY: medium p95 is 1.97 ms here. On a 60 fps budget of 16.67 ms this is only meaningful when run on the target machine.
GPU GATE: PASS
```

The image review compares the original blue model to this corrected blue version under the same cameras and lagoon lighting. The superseded warm version is also available for comparison. Texture sources and their CC0 provenance remain in `assets/environment/cascade_surfaces/sources.json`.

No Git commit was created.
