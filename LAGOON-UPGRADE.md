# Open Lagoon Water And Art Pass

## Play

Double-click **Play Lagoon.cmd**, or import **project.godot** in Godot 4.7.2 and press F5. The launcher uses this computer's Godot installation and opens a 1280x720 game window. Set `GODOT_BIN` to use another installation.

This is a separate extracted copy. The supplied ZIP is untouched; no Git commit was made. Existing player controls, save system, and level content remain.

The subsequent shared character animation and surface-interaction pass is documented in [HERO-ANIMATION.md](HERO-ANIMATION.md), with a playable recording in `review/hero-motion.avi`. Verification counts below describe the earlier water/art pass.

## Water And Traversal

- Shared water now has lit wave normals, sun/sky specular response, screen-space refraction, depth absorption, shoreline foam, and restrained animated light patterns on submerged geometry.
- Moving through shallow water creates repeated foot splashes and expanding ripples. Swimming near the surface creates a wake and ripples. Entry/exit droplets retain their impact-speed scaling.
- The lagoon is calm: no directional current in its main volume. Surface ripples do not push the player.
- Most of the lagoon floor is shallow enough to run. Three sloped depressions allow swimming, with immersion hysteresis to avoid rapidly switching movement at the boundary.
- Each tunnel entrance is lower, with a descending water surface and bed. A localized current ramps up over its approach, flows into the tunnel, and leads to its existing level trigger.
- The generated visible basin floor and physical collision use the same mesh. Decorative shoreline rocks remain visual-only.
- Subtle camera-local depth grading applies in other levels. It fades with depth, restores on surfacing, and is explicitly disabled throughout the lagoon.
- Existing deep-water levels keep their original overlap-based swimming and surface-launch behavior. New shallow areas opt into `WaterVolume.shallow_wading_enabled`; the lagoon enables it. This avoids changing already-authored platforming routes.

## Art

The three supplied Meshy models are now integrated as 25 saved scene instances along the shore and beside the tunnel approaches. Optimized derivatives retain their PBR maps; the downloaded originals are untouched. See [asset notes](assets/environment/lagoon_meshy/README.md), and edit placements in `hub/lagoon_imported_dressing.tscn`. Actual updated renders are named `review/lagoon_imported_*.png`.

The previous seeded tropical dressing remains: sandstone banks, shoreline rocks, palms, vines, flowers, coral, and three registry-built masonry entrances. Hub lighting restores to the shared world lighting on entry and reapplies on return.

A one-shot, box-projected lagoon reflection probe captures the surroundings. The full entrance composition is built at runtime from the world registry; use F5 to inspect it.

## Limits

This is a playable procedural environment pass, not an Astro Bot-quality final environment or a pixel match to the reference. Bespoke sculpted meshes, authored botanical assets and texture/normal maps, and richer tunnel interiors remain substantial visual work.

Water uses analytic waves, bounded gameplay currents, and particle/ripple effects, not a fluid simulation. Refraction is screen-space and cannot correctly include every overlapping transparent object. The reflection probe is approximate and does not update moving scenery each frame. Performance has not been certified at 60 FPS or on every renderer/quality tier.

## Verification

Actual Forward+ captures were checked on the NVIDIA GeForce MX250, in addition to headless tests.

- Lagoon water traversal: **21 checks passed**, including all three downstream entrances, no idle drift, shallow running, pocket swimming, return to land, and within-volume teleport contact recovery.
- Rendered water/depth review: **20 checks passed**, including wading spray, swimming ripples, changing fixed-camera pixels, depth grading, surfacing restoration, and lagoon exemption.
- Existing hub walk: **13 checks passed**.
- Existing fall recovery: **5 checks passed**.
- Lagoon art/lighting transitions: **33 checks passed**.
- Bubble Bay traversal: **22 checks passed**.
- Coral Cove traversal: **29 checks passed**, also checked against the untouched ZIP baseline. Existing deep-water exit timing is preserved; no route waypoints or level geometry were changed to pass the test.
- Shared regression suite: **601 passed, 1 failed, 602 total**.
- The shared suite has a pre-existing `test_every_kit_prop_loads_with_meshes_and_vertex_colour_albedo` failure naming four original kit GLBs. SHA-256 comparison confirmed those assets match the input ZIP; they were not changed to silence it.
- Existing harness runs also emit out-of-tree node and shutdown resource-leak diagnostics. The rendered review additionally reports texture RIDs at shutdown; this is not a completely clean whole-project test run.

Logs and actual game renders are in `review/`. `lagoon_0.png` through `lagoon_2.png` use art-review cameras; `lagoon_3.png` uses the player camera. `water_wading.png`, `water_swimming.png`, and `water_level_*.png` show the interaction/depth checks. No reference image is composited into these renders.

**Capture Lagoon.cmd** regenerates the four lagoon views without writing player progress.

## Main Files

- `core/rendering/water_surface.gdshader` and `water_surface.tres`: shared water appearance.
- `core/rendering/water_trail.gd`, `water_splash.gd`, `water_ripple.gdshader`: movement-driven effects.
- `core/rendering/water_depth_lighting.gd`: camera-local underwater grading.
- `core/controller/water_volume.gd`: surface sampling, immersion settings, bounded currents.
- `core/controller/axolotl_body.gd`: water contacts, movement integration, teleport recovery.
- `hub/lagoon_hydrology.gd`: physical basin, swimming pockets, channel surfaces and volumes.
- `hub/lagoon_art.gd`: seeded art and hub lighting.
- `hub/open_lagoon.gd`: lowered registry entrances and existing world transitions.

The previous `hub/lagoon_water.gdshader` and `hub/lagoon_sky.gdshader` files are no longer used.

## Retest

From this project directory, with Godot on PATH:

```powershell
godot --headless --audio-driver Dummy --path . --script test/hub/run_water_walk.gd
godot --headless --audio-driver Dummy --path . --script test/hub/run_lagoon_art.gd
godot --headless --audio-driver Dummy --path . --script test/hub/run_hub_walk.gd
godot --headless --audio-driver Dummy --path . --script test/hub/run_fall_recovery.gd
godot --headless --audio-driver Dummy --path . --script test/worlds/run_coral_walk.gd
godot --headless --audio-driver Dummy --path . --script test/worlds/run_bubble_walk.gd
godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
godot --path . --script tools/water_review.gd
```
