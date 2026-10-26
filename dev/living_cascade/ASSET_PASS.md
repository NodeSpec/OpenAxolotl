# Living Cascade — supplied asset integration

13 September 2026. The shipped Coral Cove scene now uses derivatives of all nine user-supplied Meshy assets, following the six-section route and the original hero/map composition. Enter through the starting cove's leftmost downstream passage.

## What changed

- S01 / arrival: rock-textured bank and floor surfaces, a bank-ledge relief and a submerged rock. The rock texture samples the interior of the supplied stone, rather than repeating its silhouette as fake raised boulders.
- S02 / stepping stones: asset-derived stone skirts beneath the existing landing caps, with the same landing heights, widths and gaps. Recovery water and return ramps are unchanged.
- S03 / root dive: sculpted woodland root arch, submerged reef wall/ceiling reliefs, a low reef shelf, an arch in the optional grotto and two subtle local fill lights. The main passage and lantern-shrimp approach remain clear.
- S04 / terraces: stone ledge skirts, natural cliff surfaces and the existing animated scenic waterfall against asset-derived cliff relief. Climbing and the bypass remain functional.
- S05 / crown: the supplied flowering arch behind the rear ridge, with an upper animated waterfall framed below it and a bank ornament on the closed east edge. Restoration changes the crown's material tint while retaining its original atlas. The supplied flowers are part of one fused textured mesh; they do not independently grow or animate.
- S06 / finish: reef relief at the finishing pool, retained water/chute geometry, exit and hub return.

The old procedural root/crown pieces and the large central canopy were removed. Existing remaining fern/reed fields still provide secondary vegetation. Walls retain their solid backing and every original collision shape. Waterfall sheets are scenic effects, not new swim volumes.

## Asset handling

Original GLBs in `asset_inbox/` are byte-for-byte unchanged. `asset_inbox/.gdignore` prevents Godot importing the dense source models. Their filenames say texture-optimized, but each original still contains roughly 2.3 million triangles.

The prepared copies live in `assets/environment/cascade_*/`. Mesh reduction welds coincident seams, preserves texture coordinates and measures surface deviation in both directions against the original (12,000 samples per direction). The initial overly aggressive reductions were rejected. Every final prepared GLB is below the existing 3% environment deviation ceiling and 200,000-triangle per-file limit. This is sampled evidence, not a mathematical maximum-error guarantee.

The arches, a bank ornament, a reef shelf and a submerged stone use full 3D models. Repeated wall, roof and ledge surfaces use baked colour/depth relief meshes from the supplied models. This keeps repeated scenery inside the unchanged whole-scene geometry budget; these reliefs are intended as surfaces on solid terrain, not freestanding models.

| Prepared asset | Triangles in GLB | Largest sampled deviation / diagonal |
|---|---:|---:|
| bank_terrace | 24,000 | 0.46% |
| cliff_garden | 146,500 | 0.39% |
| crown_arch | 32,000 | 0.74% |
| mossy_stone | 24,000 | 0.46% |
| reef_arch | 15,999 | 1.67% |
| reef_ledge | 24,000 | 0.73% |
| reef_wall | 24,000 | 0.56% |
| root_bridge | 36,000 | 2.19% |
| stone_ruins | 33,205 | 0.75% |

Every asset has a provenance sidecar. The user's original generation prompt and exact source license were not supplied; those fields explicitly record that information as unknown rather than inventing it. Structural asset validation found no violations in the nine new directories. The project-wide asset validator still reports 29 existing layout/name violations in `lagoon_meshy` and the loose `vertex_color_import.gd` files.

## Verification and limits

- Godot unit suite: 619 passed, 0 failed after replacing prototype landmark assertions with the corresponding supplied-asset landmarks. The 400,000-triangle ceiling was not increased.
- Final scene plus hero: 395,289 triangles, including the five added upper waterfall sheets.
- Collision parity: all 372 original shapes retain their transforms, enabled state and box dimensions.
- Decorative landmark clearance: player-sized capsule probes at canonical route waypoints are clear. This supplements visual review; it is not an exhaustive sweep of every possible player position.
- Leftmost cove tunnel through Living Cascade, restoration, completion and hub return: 35 checks, 0 failures.
- Translated production route, save migration, resource persistence, checkpoint recovery, restoration and reload: PASS.
- Level contract: PASS. Import-weight checks: 3 passed. Static API analysis: PASS, 222 files scanned.
- Actual gameplay, overview, upper-arch and underwater views were rendered and inspected. The level still retains its established rectangular containment/layout silhouette. This is an asset/style integration pass, not a claim of matching every curve or distant sightline of the concept illustration.

**Unresolved benchmark check:** the existing GPU gate fails its requirement that Low must be at least 12% faster than Medium. On the final build at 1920×1080, it measured Low 2.63 ms mean / 3.66 ms p95, Medium 1.11 ms mean / 1.34 ms p95, and High 4.22 ms mean / 6.59 ms p95 (96 GPU samples each). Earlier runs also showed Low slower than Medium. This is an unresolved quality-order comparison, not a passing performance gate; its cause has not been established. The graphics presets and benchmark thresholds were not changed to force a pass. These GPU-only measurements on the RTX 5090 Laptop GPU do not certify whole-game frame rate or baseline-hardware performance.

## Rebuild and rollback

Run Godot headless with `--path <project> --script res://dev/build_cascade_production.gd`. It calls `dev/living_cascade/cascade_asset_dressing.gd`; prepared GLBs and baked maps are the inputs, so Blender is not required to rebuild the game scene. The production scene has no runtime dependency on the build-time helper. GLBs remain linked PackedScene instances with their original internal ownership, rather than embedding duplicate mesh buffers into the level. This reduces the scene file from about 15 MB to 1.4 MB. Two closing-brace indentation changes in project.godot preserve compatibility with the existing INI-based static checker; shader-global values are unchanged.

The pre-pass scene, builder, manifest and composition test are backed up at `C:/Users/ltben/Documents/Codex/2026-09-11/ana/work/cascade-before-art/`. Detailed asset preparation reports are in `dev/living_cascade/asset_reports/`.

No Git commit was created. No live player profile was opened or overwritten by the test harnesses.
