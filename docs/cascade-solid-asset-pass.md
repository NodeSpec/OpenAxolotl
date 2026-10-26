# Living Cascade â€” full-model asset pass

This supersedes the September 13 relief-panel pass. The supplied GLBs are now the visible 3D level forms, with uniform scaling and linked scene instances. Original files in `asset_inbox` are unchanged.

## Asset analysis

| Prepared asset | Native bounds: X Ã— Y Ã— Z | Geometry and intended role |
|---|---|---|
| Woodland root bridge (`root_bridge`) | 1.888 Ã— 1.168 Ã— 1.384 | Four feet and two connected arch faces. Used as the main root landmark and the surface bridge over the chute; preserve its deep opening. |
| Flowering crown arch (`crown_arch`) | 1.897 Ã— 1.161 Ã— 1.429 | A flowering wooden arch, not a waterfall mesh. Its full depth sits on separate cliff pedestals; animated water is authored separately. |
| Verdant cliff (`cliff_garden`) | 1.899 Ã— 1.643 Ã— 1.365 | Tall, deep cliff with fused foliage. Used for tall boundaries, inlet flanks, garden dividers and waterfall pedestals. Fit endpoints around openings. |
| Corner rock formation (`stone_ruins`) | 1.898 Ã— 0.989 Ã— 1.529 | A broad, low corner mass. Used for layered banks, column feet and turning river edges; it cannot replace a tall thin wall at the same scale. |
| Jungle bank terrace (`bank_terrace`) | 1.903 Ã— 0.656 Ã— 1.347 | A stepped shelf with a higher planted rear. Used at pool edges and balcony corners, with the raised part facing away from the route. |
| Mossy stone island (`mossy_stone`) | 1.903 Ã— 0.767 Ã— 1.879 | A rounded stone with a usable upper plateau. Replaces all ten jump/optional stones and forms bank surfaces. Landing height comes from a mesh ray, not the foliage bounding box. |
| Reef wall (`reef_wall`) | 1.901 Ã— 1.599 Ã— 0.596 | The naturally thin wall in this kit. Small complete modules form the submerged wall band, keeping their coral and vegetation near the waterline. |
| Reef ledge (`reef_ledge`) | 1.790 Ã— 1.470 Ã— 1.904 | A deep shelf with an undercut and coral. Used beside swim lanes and the reward pool; kept away from the shrimp rescue and ramp exits. |
| Coralvine tunnel arch (`reef_arch`) | 1.891 Ã— 1.430 Ã— 1.781 | A tunnel with substantial depth and four feet. Rotated along each swim direction; separate modules leave a side junction into the optional grotto. |

Bounds describe the prepared models before placement; they are not real-world scale claims. The model filenames and fused geometry were inspected independently of the illustration labels. The crown model is an arch, so no waterfall geometry was assumed to exist inside it.

## Section decisions

### S01 â€” Arrival pool

The inlet cliffs now leave the complete incoming tunnel corridor open. Whole bank terraces and stones define the shore, with smaller stones on the submerged bed. The bank edge sits behind the ramp top, so approaching from the tunnel does not catch a rock lip.

50 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

### S02 â€” Stepping garden

P21â€“P24 and O1 are complete mossy-stone models with their own mesh collision. Their centre anchors and target heights are retained. Full rock feet reach the bed; the wall is built from overlapping volumetric cliff modules. Recovery-ramp mouths stay clear.

65 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

### S03 â€” Root dive and grotto

The solid RootRoof and SecretRoof are retired. A full-depth wooden bridge sits above three hollow cave modules. A side junction leads through a diagonally placed grotto arch to the existing lantern shrimp at (âˆ’12, âˆ’1.6, âˆ’65). The nearby shelf was moved away from the rescue.

93 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

### S04 â€” Rising terraces

The five landing stones have real rock columns below them. Replacement climb surfaces retain the climbable group and layer. A complete underwater arch replaces the rectangular dive brow; the swim continues to z = âˆ’86.9 before rising toward the exit ramp at y = 3.1.

95 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

### S05 â€” Restoration crown

The full flowering arch rests on two cliff pedestals, with a separate animated waterfall. The front is an open rock balcony above S04 catch pools: the old thin partition could not contain deep cliff models without blocking the paths. Fitted west dividers and the restoration gate remain. Visible soil joins courtyard rocks where a continuous walking surface is needed.

65 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

### S06 â€” Chute and reward pool

Overlapping whole corner-rock formations form both sides of the descending channel. A wooden bridge spans the banks above a separate underwater dive arch. The reward bank and reef use full models. Its walking rocks sit 15 cm below the former support height so the exit ramp leads onto them cleanly.

42 full-model placements. See `review/cascade-asset-placements.json` for every transform, source asset and collision type.

## Collision and remaining authored terrain

Jump stones and hollow arches use mesh collision. Solid cliff/shelf pieces use convex collision to avoid snagging on individual leaves. The climbable tag and collision layer transfer to the replacement climbing rocks. Closed boundaries retain backstops inside the rock formations; the outer foundation and safety recovery remain.

The garden has visible soil 2 cm below the target walking height between stones. Its collision matches that visible soil. Ramps, sand beds, water/current volumes, the restoration barrier and safety foundation remain authored geometry. No bank infill is placed above the jump stones, and no baked facade panels or asset-texture shader covers the old blockout.

The crown keeps its original atlas and responds to restoration through material tint. The supplied arch is fused, so its flowers do not independently grow or animate.

## Geometry and performance

The nine imported source meshes total **359,527 triangles**. The full scene counter, which multiplies every placement and includes shadow proxies and the hero, reports **15,959,035 triangles**. The Living Cascade geometry ceiling is now **16,000,000**, replacing the 400,000 ceiling used for the relief scaffold. This is an explicit scope change to allow complete models; it is not a frame-rate target or a baseline-hardware certification.

Godot generated no mesh LODs for these supplied derivatives despite the import flag. Further collapse reductions were rejected after measured shape damage. The retained models use linked shared resources. Solid rocks use small convex shadow meshes; arches retain their open silhouettes in shadows. Interior wall occluders reject some hidden geometry. Shared compressed collision resources keep the scene text compact.

The 60 FPS / 50 ms spike / 3000 ms loading targets are unchanged. Actual GPU and CPU gate logs accompany this pass. Target-class GPU profiling and human playtesting remain necessary before calling the art production-final.

## Verification

- Unit suite: PASS. 622 checks, including full-model, proportions, collision and retired-relief regressions.
- Production journey: PASS. Full route, restoration, checkpoints, recovery, camera and save/reload.
- Starting-cove connection: PASS. Leftmost tunnel â†’ complete level â†’ hub, with side-world checks.
- Containment and rescue: PASS. 3,581 checks: foundation, perimeter, landing heights, closed-gate actions and actual shrimp pickup/return.
- GPU quality gate: PASS. RTX 5090 Laptop at 1920 Ã— 1080: mean Low 1.66 ms / Medium 3.60 ms / High 6.89 ms; p95 2.81 / 6.87 / 10.80 ms. Quality ordering passes. Baseline GTX 1650 performance remains unverified.
- Coral Cove CPU gate: OVER BUDGET. OVER BUDGET: isolated repeat measured a 55.6 ms spike against the 50 ms limit. Loading (179.5 ms) and sustained simulation (58.5 fps) passed. The first run also exceeded the spike limit at 54.6 ms.
- Level contract and static analysis: PASS, zero violations. Import-weight unit tests: 3 passed.
- All nine Cascade asset directories pass the scoped asset-contract validator.

The CPU spike failure is an open performance issue. This revision is functionally verified but is not a complete performance sign-off. The geometry ceiling increase above must not be read as meeting the unchanged timing budgets.

Placement totals count 428 linked level models, plus 16 small decorative instances in four full-model ScatterFields.

The unit runner still reports its pre-existing camera/resource cleanup warnings at process exit; the previous 619-test console log contains the same warnings. Runtime build, playthrough and render logs are checked separately. The project-wide asset-contract validator also has pre-existing `lagoon_meshy` naming/provenance findings; the nine Cascade assets remain unchanged by this pass.

## Sources and rebuild

- Design: `outputs/living-cascade-specification.json`, original top-down/hero image, and `asset_inbox/Reference Image_2_Level_1.png`.
- Builder: `dev/build_cascade_production.gd` â†’ `dev/living_cascade/cascade_asset_dressing.gd`.
- Runtime: `core/rendering/cascade_asset_visibility.gd`, `cascade_crown_state.gd`, and `cascade_collision/*.res`.
- Scene: `worlds/coral_cove/world.tscn`.
- Tests: `test/worlds/test_cascade_assets.gd`, `run_cascade_asset_containment.gd`, existing production/stream and performance probes.
- Backup of the prior pass: workspace `work/cascade-before-solid-assets/`.
- No Git commit was created.
