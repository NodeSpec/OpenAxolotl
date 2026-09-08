# Coral Cove source models

Raw Meshy exports, uploaded by the maintainer for Coral Cove: two canopy trees,
a river bank, a Dredger and a Hookline Rig.

**They are here rather than in `assets/` because they are source material, not
runtime assets.** Each arrived at roughly two million triangles with 2–5 MB
JPEG maps — the same shape the hero arrived in. Measured on arrival:

| Model | Triangles | Size | Category budget |
|---|---|---|---|
| `Coral_Cove_Canopy_Tree_1.glb` | 1,995,258 | 17.5 MB | environment, 200,000 |
| `Coral_Cove_Canopy_Tree_2.glb` | 1,991,318 | 17.3 MB | environment, 200,000 |
| `Coral_Cove_River_Bank.glb` | 2,002,284 | 16.1 MB | environment, 200,000 |
| `Dredger_Rustbreaker.glb` | 1,985,600 | 16.0 MB | **prop, 10,000** |
| `Hookline.glb` | 1,984,122 | 18.3 MB | **prop, 10,000** |
| `Netgrin_Salvage_Bot.glb` | 1,972,184 | 15.0 MB | **prop, 10,000** |

The three props are roughly two hundred times their budget; the environment
pieces about ten times. That is not a complaint about the models — it is what
an image-to-3D export is, and the repository has a pipeline for exactly this:

```sh
python tools/decimate_model.py \
    --input reference/coral_cove/Dredger_Rustbreaker.glb \
    --output assets/prop/dredger/dredger.glb \
    --max-triangles 3000 --max-texture 1024
```

The budget, the texture ceiling and the deviation ceiling all come from the
Asset Contract, resolved from the OUTPUT path's category, so no number is
restated on a command line and none can drift from what CI enforces. See
`docs/asset-contract.md`.

**They are decimated well past their category ceilings, on purpose.** The
contract's 10 000 triangles is what a prop file may contain; what actually has
to fit is the scene, and Coral Cove places fifteen machines against a 150 000
triangle whole-scene budget. Three thousand each is what the level can afford,
and at that count each machine still reads as itself — the Dredger keeps its
red cab, amber stripe and cutting drum. The environment pieces ship at 6 000.

**Draco.** These arrive with `KHR_draco_mesh_compression`, and the Blender here
has no `libextern_draco.so`, so it imports them as empty. Decode first:

```sh
npx @gltf-transform/cli copy in.glb out.glb   # strips the Draco extension
```

**They are kits, not single objects.** `Coral_Cove_Canopy_Tree_1.glb` is a
grove of six trees at assorted sizes; `Coral_Cove_River_Bank.glb` is four
separate shelf pieces. Both are one mesh in the file, so they can only be
placed as a whole until someone splits the loose parts into their own assets.
That is why they land under names that say what they are rather than replacing
the single-tree `canopy_tree` a ScatterField scatters — scattering a grove
would plant six trees at every scatter point.

The three machines ARE like-for-like replacements, so they took over the
`dredger`, `hookline_rig` and `netbot` asset paths Coral Cove already
references. The Flagship and the Runoff Drone remain the procedurally
generated ones from `tools/blender/make_drift_fleet.py`, and the forest kit
from `tools/blender/make_forest_kit.py` still supplies the scattered dressing.

**Licensing.** These carry Meshy's terms, like the hero. REQ-021 is blocking on
that decision and it is sharper now than it was: the project's promise is
"build your level out of our assets", and that is a grant we cannot make over
geometry whose terms are someone else's. Either the terms permit it, or these
are replaced by in-repo generated equivalents whose output is Apache-2.0 with
the rest of the project.

The netbot arrived separately, already texture-optimised by Meshy — which
reduces the maps, not the mesh: it is still 1.97 million triangles, so it lands
here with the rest.

**Not delivered:** the coral branch was named in the upload but did not arrive;
that directory still holds only its generated version.
