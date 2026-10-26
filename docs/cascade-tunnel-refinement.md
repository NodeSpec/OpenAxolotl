# Living Cascade — tunnel surface refinement

The six Coralvine Arch instances (four in S03, one in S04 and one in S06) now use the terrain's refined stone family with a restrained moss blend. Their existing leaf, flower and cyan accent colours remain visible.

The original material already had linear mipmapped filtering. The visible problem was its packed 2K colour atlas: baked coarse colour patches became prominent at close swimming distances. The new material gives stone its own world-scale triplanar colour, normal and roughness detail, using the existing `rock_face_03` maps with `mossy_rock` colour variation. No texture upscaling or new asset download was required. The source atlas supplies colour-based masks for this particular model's green plants, warm/purple flowers and bright cyan accents. Its baked plant normal strength is reduced, and sampling uses anisotropic mipmapped filtering.

The original model's angular geometry remains. This is a surface treatment; it does not smooth or replace the tunnel mesh, fill its opening, or change its collision.

## Build and persistence

- New material: `core/rendering/cascade_tunnel.gdshader`.
- Shared material setup: `dev/living_cascade/cascade_tunnel_material.gd`.
- Placement hook: `dev/living_cascade/cascade_asset_dressing.gd`, limited to `reef_arch`.
- Packing: `dev/build_cascade_production.gd` marks only the six tunnel instances editable while retaining imported child owners. The development builder instantiates those models with editor instance state, so it saves their material overrides without duplicating mesh nodes. Runtime loads the already packed scene.
- Production: `worlds/coral_cove/world.tscn`.

The packing approach was verified with an isolated save/reload probe and the complete saved scene. Godot documents the instance edit states and owned-node packing in its [PackedScene reference](https://docs.godotengine.org/en/stable/classes/class_packedscene.html).

## Verification

- Saved material overrides: all six surfaces passed; no other supplied models receive this shader.
- Focused regression suite: 11 passed, 0 failed.
- Floor, gate, landing, rescue and containment checks: 3,581 passed.
- All nine external collision resources are byte-identical to their pre-change hashes.
- All nine original source GLBs and the optimized tunnel GLB retain their hashes.
- Scene triangles: 2,959,022, unchanged and within the 3-million ceiling.
- Static analysis and level-contract checker passed.
- Saved-scene render logs contain no script or shader errors. Four matching camera pairs are in the review.

GPU quality-ordering log on the current RTX 5090 Laptop GPU:

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5090 Laptop GPU

GPU GATE (coral_cove, 1920x1080, NVIDIA GeForce RTX 5090 Laptop GPU)
  low     mean   0.76 ms  p95   0.93 ms  worst   1.38 ms  (96 frames)
  medium  mean   1.72 ms  p95   2.14 ms  worst   2.38 ms  (96 frames)
  high    mean   3.94 ms  p95   4.69 ms  worst   4.84 ms  (96 frames)
  low vs medium: 2.27x apart (needs 1.12x) OK
  medium vs high: 2.30x apart (needs 1.12x) OK
  ADVISORY: medium p95 is 2.14 ms here. On a 60 fps budget of 16.67 ms this is only meaningful when run on the target machine.
GPU GATE: PASS
```

The quality-ordering gate is not a guarantee of 60 fps on High or on the target baseline GPU. Timing targets were not altered. The broader terrain pass's performance limitation remains open.

## Art sources and scope

The existing terrain textures are CC0 [Rock Face 03](https://polyhaven.com/a/rock_face_03) and [Mossy Rock](https://polyhaven.com/a/mossy_rock); provenance remains in `assets/environment/cascade_surfaces/sources.json`. The original Coralvine Arch files are unchanged. Its texture-specific colour mask should be reviewed if that source model is replaced.

No gameplay, whirlpool, enemy, shore or terrain-layout changes were made in this refinement. No Git commit was created. The comparison baseline is archived at `dev/archive/cascade_before_tunnel/world.tscn`.
