# Supplied Lagoon Models

Game-ready derivatives of the three Meshy GLBs supplied by the project owner. The original files in Downloads were read, not changed. Their filenames and SHA-256 hashes are recorded in `asset-build.json`.

| Asset | Source triangles | Game triangles | Texture limit |
| --- | ---: | ---: | ---: |
| Coral rock decor | 1,943,356 | 63,999 | 2048 px |
| Boulder rock cluster | 1,916,772 | 28,000 | 2048 px |
| Flower cluster | 1,941,428 | 63,999 | 2048 px |

Blender collapse decimation preserves the existing UV/material setup; the color and normal maps were reduced from 4096 to 2048 pixels. The supplied metallic/roughness maps remain. Each exported scene has a ground-centered root pivot, with the mesh's translation retained inside the scene. Godot import generates additional mesh LODs and shadow meshes. All repeated placements share the imported mesh and material resources.

These are visual dressing, not new platforms or collision meshes. Source material appearance is retained; no automatic wind deformation or material recoloring is applied. The assets remain subject to the owner's applicable source licenses; this integration does not assign them the repository's code license.

## Placement

`hub/lagoon_imported_dressing.tscn` contains 25 named, editable instances: nine boulders, eight coral arrangements, and eight flower beds. It is instanced under `OpenLagoon/LagoonArt/ImportedModels`, so it hides and returns with the lagoon. Open that dressing scene to adjust individual transforms. The procedural background remains, with less foreground foliage where the new flowers sit.

## Rebuild

From the project directory, using Blender 5.2 and the original input directory:

```powershell
blender --background --factory-startup --python-exit-code 1 --python tools/blender/prepare_lagoon_models.py -- --source-dir "C:\Users\ltben\Downloads" --output-dir assets/environment/lagoon_meshy
godot --headless --path . --editor --import --quit
```

The script only creates derivatives in its output directory. Preserve the downloaded sources for future higher-detail builds.

## Review

`tools/lagoon_asset_catalog.gd` renders the three derivatives in isolation. `tools/lagoon_imported_review.gd` captures the hero view, both shore gardens, the tunnel approaches, and the gameplay camera. Actual screenshots, logs, and a GPU-only visibility comparison are saved in `review/lagoon_imported_*`.

`test/hub/run_imported_dressing.gd` checks material maps, shared resources, normalized roots, grounded placement, spawn/route clearance, and world-transition visibility. Existing water and art-transition checks are unchanged. These props intentionally have no gameplay collisions or contract groups.

Verified integration: 502 placement/resource/transition checks passed; water traversal passed 21 checks and existing lagoon art transitions passed 33. The shared regression suite remains at 610 passed and one pre-existing original kit vertex-color failure. Existing harness shutdown resource diagnostics and the rendered reflection-probe texture RID warnings remain.

The MX250 GPU-only visibility comparison at 1440x900 measured approximately 34 ms with the imported dressing and 29 ms with it hidden in the initial hero/gameplay views. This is a short rendering-cost sample, not an end-to-end frame-rate guarantee or a comparison against the original ZIP. The lagoon is not certified at 60 FPS on this GPU.
