# First Adventure design consistency audit

28 October 2026. Scope: publish the agreed design brief and local visual references, and replace their NodeSpec links. This is a documentation/design audit, not a new gameplay test run.

## Preserved design invariants

| Area | Agreed intent retained |
|---|---|
| Entry and order | Safe Open Lagoon; leftmost tunnel; Arrival Pool, Stepping-stone Garden, Hollow-root Dive, Cascade Terraces, Restoration Garden, Waterfall Run; finish and hub return |
| Orientation | Root opening frames the distant crown; terrace rests progressively reveal the destination; normal follow-camera readability governs dressing |
| Recovery | Three checkpoints; forgiving water, local ramps and contained shores; nonlethal fallback for accidental escapes |
| Encounters | S02: two land Netbots and one land Hookline. S03: two underwater Hooklines. S04: one land Netbot, one underwater Hookline and one land Hookline. Combat is optional |
| Progression | Two terrace seeds plus seven garden seeds; automatic 3 + 4 restoration; no forced backtracking for seeds |
| Optional content | Hermit snail, lantern shrimp, tide pearl, glowing crayfish and dance do not gate completion |
| Finale | Banked water descent, telegraphed dive bar, calm reward pool, reach-volume completion and saved hub return; no new boss, suit or whirlpool |
| Surface style | Lagoon continuity, authored landforms and selected complete asset landmarks; grass/soil/sand/rock transitions, coherent texture scale and restrained repeat patterns |
| Underwater style | Blue textured arches, pale shallow sediment blending into darker pebbled depths relative to each water surface; readable hero and exits |
| Water sources | Visible source basins, lips, spillways and receiving water; scenic waterfall sheets separate from gameplay volumes |

## Publication checks

- Four visual references were compared byte-for-byte with their source, with SHA-256 values in references/source-manifest.json. The hero concept was extracted from the original HTML without re-encoding. PNG files use the repository's existing Git LFS policy; SVG bytes are preserved by scoped attributes.
- The brief and reference guide use portable repository-relative links. NodeSpec workflow, step and outcome links are updated after push to immutable GitHub commit URLs; the source map records repository paths without requiring a self-referential commit hash.
- The workflow reference map preserves the eight step IDs/order, eight outcome IDs and REQ-019–026 relationships. Existing criterion IDs, text, verification lanes and derivations are unchanged. It is a focused design snapshot, not a native NodeSpec export.
- Old concept dimensions remain labelled as authored targets. Stale implementation notes are explicitly superseded, including swimming Netbots, life-costing falls, facade-only dressing and warm underwater arches.
- The original task/test plan remains the implementation authority; this publication does not tick tasks, mark criteria passed or certify visual/performance parity with another game.

## Remaining boundaries

The older root architecture export and native .nodespec model/spec files are not refreshed by this documentation publication. Do not reimport them over the live NodeSpec project. The prior Godot setup/version discrepancy and fresh movement, camera, collision and hardware validation remain implementation work. The artwork expresses a target; this audit establishes reference consistency, not that the present level achieves the target.
