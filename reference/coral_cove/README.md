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

The two props are roughly two hundred times their budget; the environment
pieces about ten times. That is not a complaint about the models — it is what
an image-to-3D export is, and the repository has a pipeline for exactly this:

```sh
python tools/decimate_model.py \
    --input reference/coral_cove/Dredger_Rustbreaker.glb \
    --output assets/prop/dredger/dredger.glb
```

The budget and the texture ceiling come from the Asset Contract, resolved from
the OUTPUT path's category, so neither number is restated on a command line and
neither can drift from what CI enforces. See `docs/asset-contract.md`.

Until a reduced version lands in `assets/`, the shipped models remain the
procedurally generated ones from `tools/blender/make_drift_fleet.py` and
`tools/blender/make_forest_kit.py`.

**Licensing.** These carry Meshy's terms, like the hero. REQ-021 is blocking on
that decision and it is sharper now than it was: the project's promise is
"build your level out of our assets", and that is a grant we cannot make over
geometry whose terms are someone else's. Either the terms permit it, or these
are replaced by in-repo generated equivalents whose output is Apache-2.0 with
the rest of the project.

**Not delivered:** the coral branch and the netbot were named in the upload but
did not arrive; those two directories still hold only their generated versions.
