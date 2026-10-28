# First Adventure — Lagoon & Living Cascade design storyboard

This is a design and review brief dated 27 October 2026, not a declaration that the game meets its quality targets. Owner: Official Adventure: Lagoon & Living Cascade (b0c02000-2026-4020-8000-000000000008). Workflow: First Adventure — Open Lagoon & Living Cascade. Preserve REQ-019–026 and their existing criterion IDs, outcome links and order.

The experience is a welcoming land-and-water adventure for children: learn safely, see a distant destination, alternate short challenges with recovery and discovery, restore the garden, enjoy a controlled descent and return home. Reference quality means readable composition, responsive expressive movement, coherent materials and fair recovery; “Astro Bot quality” is an aspiration, not a pass result.

Source precedence: current agreed NodeSpec intent and latest user decisions govern gameplay; revision-2 numerical ledgers govern proposed joins/heights, subject to remeasurement; overhead/elevation drawings govern broad layout; concept art governs composition and mood. Later custom-terrain, blue-tunnel, depth-material, smooth-collision and basin-seal revisions supersede older facade-only, warm-tunnel and life-costing-fall notes. Old no-enemy and swimming-Netbot sketches do not replace the current three land Netbots and five land/water Hooklines. No boss, new suit, whirlpool or additional mandatory collectible is introduced.

The storyboard beats below are textual design panels derived from inspected art and drawings, not new rendered storyboards. All referenced art and documents are available in this repository. Original visual bytes are preserved in references/source-manifest.json; the concept reference page distinguishes illustration from gameplay authority. NodeSpec links pin the published repository revision. This document and workflow-reference-map.json are design records, not native NodeSpec model/spec exports; do not substitute old .nodespec anchors for live intent.

## Inspected reference register

- **R1 — [Original hero/top-down concept and drawing guide](references/concept-and-drawings.md)**: Concept composition and mood; the drawing guide records scope and superseded details, not a shipped or measured level.
- **R2 — [Dimensioned overhead drawing](references/living-cascade-overhead.svg)**: S01–S06 envelopes, joins, three checkpoints and optional branches; lines are not collision edges.
- **R3 — [Unfolded elevation drawing](references/living-cascade-elevation.svg)**: Height progression; exaggerated vertical scale, not literal terrain or swim-body positions.
- **R4 — [Revision 2 section and water ledger](../../dev/living_cascade/design_reference.json)**: Dimensions and joins are design targets; remeasure against the current controller before construction.
- **R5 — [Supplied surface and underwater asset art board](../../asset_inbox/Reference%20Image_2_Level_1.png)**: Root/crown/cliff/ledge/stone families; blue underwater palette and soft natural forms. Approximate illustrated scale is not traversal geometry.
- **R6 — [Starting lagoon appearance and behavior](../../LAGOON-UPGRADE.md)**: Calm wading basin, swimming pockets, tropical sandstone/foliage and downstream passages. Historical verification is not fresh evidence.
- **R7 — [Lagoon gameplay-camera visual reference](references/lagoon-gameplay-reference.png)**: Observed in-game palette and water/shore continuity benchmark, not final fidelity certification.
- **R8 — [Custom terrain and structural asset direction](../../docs/cascade-custom-terrain-pass.md)**: Authored terrain connects selected complete models; avoid repetitive oversized copies and facade-only landmarks.
- **R9 — [Surface detail and planting revision](../../docs/cascade-texture-polish.md)**: Layered sand/stone/soil, grass geometry, wet bands and lagoon material continuity.
- **R10 — [Blue tunnel material revision](../../docs/cascade-blue-tunnel-refinement.md)**: Blue mineral stone, teal weathering, fine pitted detail and retained coral accents; supersedes warm tunnel treatment.
- **R11 — [Underwater depth material revision](../../docs/cascade-ground-depth.md)**: Light shallow sand to darker blue-green pebble sediment, relative to each local water surface.
- **R12 — [Collision and basin containment revisions](../../docs/cascade-basin-seals.md)**: Connected inlet, underwater exits and raised pool shores; physical containment before nonlethal fallback. See also docs/cascade-collision-polish.md.

## 00 — Explore Open Lagoon

**Traceability:** REQ-019; existing workflow step and outcome retained. **Storyboard:** Welcome → experiment → choose the leftmost passage.

Intent: make Open Lagoon a safe, inviting place to learn walking, hopping, wading, swimming and diving before the first adventure.

**Player-view panels:** Frame the small pink hero against pale sand and clear turquoise shallows; present the three tunnel mouths as recognizable destinations. Let the child experiment in calm water and deeper pockets with nearby sloping exits. Then guide attention toward the leftmost downstream tunnel using bank shape, current direction and restrained accents; preserve the same hero and camera through the connection.

**Art and terrain:** Use the lagoon's sandstone, tropical foliage and wet/dry shoreline as the continuity benchmark. Group vegetation at the margins, keep the learning space open, and make the leftmost passage readable without implying the other mouths enter Living Cascade.

**Gameplay and safety:** The basin has no directional drift or attack encounter. Tunnel current belongs to its approach, not the whole lagoon. Both tunnel directions need supported floors and closed sides.

**Review evidence:** Record a normal-camera spawn-to-tunnel walkthrough showing wade/swim/land transitions, clear route cues, and entry/return without a camera snap, collision snag or unsupported seam. Compare shore detail to R7 under matched lighting, not an overhead beauty camera.

**References:** R6, R7, R9, R12.

## S01 — Arrival Pool

**Traceability:** REQ-020; existing workflow step and outcome retained. **Storyboard:** Release → reveal → settle.

Intent: slow the incoming journey, show the crown destination and establish safe-water recovery.

**Player-view panels:** Enter the pool and let the current ease away. Frame the distant flowering crown and waterfall through the central root opening while the nearer stones lead left. Reach CP_01 on a dry pad, then follow a continuous bank to the garden.

**Art and terrain:** Warm wet sandstone, pale sand, sparse peach flowers and low planting carry the lagoon into the Cascade. Submerged sand becomes blue-green with depth. Use authored rock shoulders to hide the inlet seam without narrowing the usable channel.

**Gameplay and safety:** No enemy or mandatory jump. Keep both broad water exits accessible, including reduced-capability movement. CP_01 remains dry and unobstructed.

**Review evidence:** From the normal arrival camera, show both the next bank exit and crown without requiring a camera rotation. Inspect inlet floor overlap, underwater side closures and both exit ramps. Preserve the view corridor by lowering foliage or reshaping scenic walls, never by opening a collision gap.

**References:** R1, R2, R4, R5, R9, R11, R12.

## S02 — Stepping-stone Garden

**Traceability:** REQ-021; existing workflow step and outcome retained. **Storyboard:** Teach → repeat → offer a detour.

Intent: make aimed hopping enjoyable with swimming as an equally valid, forgiving recovery route.

**Player-view panels:** Reveal the four principal landings before the first hop. Repeat a short readable jump rhythm, give the player a choice to swim beneath, and offer the hermit-snail spur as an out-and-back discovery. Rejoin both routes before the root dive.

**Art and terrain:** Complete mossy landing-stone models sit within custom continuous banks; usable tops contrast with pale sides and darker wet margins. Vary surrounding rock groupings, grass density and silhouette without disguising landing edges or repeating one scaled model across every shape.

**Gameplay and safety:** Retain authored clear landing tops and tested gaps; the drawing's illustrative stones do not determine jumps. Two land Netbots and one land Hookline occupy broad side pockets, clear of takeoffs, landing tops, ramps and the optional ledge. Proximity warnings precede attacks; bypassing combat remains valid.

**Review evidence:** Capture each takeoff with the full destination visible and test misses into water, return ramps and the optional spur. Review warning → attack → recovery from normal approach speed; no enemy, hook or robot debris may obstruct the easier swim route. Target quick local recovery; measure rather than assert the older ten-second goal.

**References:** R1, R2, R4, R5, R8, R9, R12.

## S03 — Hollow-root Dive

**Traceability:** REQ-022; existing workflow step and outcome retained. **Storyboard:** Invite a dive → blue discovery → warm exit reveal.

Intent: provide a legible underwater passage with a distinct atmosphere, an optional grotto and an obvious way back to daylight.

**Player-view panels:** Show the submerged opening from the approach. Swim beneath the root through a broad blue corridor; a secondary glow invites the optional lantern-shrimp grotto. Warm light at the exit reveals the resurfacing basin and terrace ramp.

**Art and terrain:** Use real arch and reef silhouettes, blue mineral textures, teal weathering and restrained coral accents. Blend pale approach sediment into darker pebbled depths. Separate primary-route light from optional-pocket glow; keep the hero, hook lines and exit readable through water effects.

**Gameplay and safety:** Two underwater Hooklines remain in widened chambers rather than overhead pinch points. Optional glowing crayfish and the grotto never gate progress. The passage remains reversible with adequate capsule, tail-motion and camera clearance; side walls prevent an accidental dry bypass.

**Review evidence:** Show entry, underwater bend, optional pocket and exit from the swimming camera. Test diagonal approaches through both arch mouths and retreat under attack. Reject enlarged-atlas pixelation, abrupt depth-colour seams, camera occlusion, snagging decorative coral and reachable floor/side holes.

**References:** R1, R2, R3, R4, R5, R10, R11, R12.

## S04 — Cascade Terraces

**Traceability:** REQ-023; existing workflow step and outcome retained. **Storyboard:** Reorient → rise in three phrases → anticipate the crown.

Intent: combine hops, short swims and a modest climb while preserving reliable local recovery.

**Player-view panels:** Activate CP_02 at the entry. Traverse A/B/C as short action-and-rest clusters, each rest ledge revealing more of the crown. Offer the continuous climb bypass and the two terrace seeds as helpful extras before the garden.

**Art and terrain:** Make the three terrace groups distinct through ledge silhouette, restrained planting and wet/dry material transitions. Waterfalls visibly begin at retained headwater basins and spill over believable lips. Integrate cliff and ledge assets with sculpted terrain; avoid stacked copies and broad flat wall facades dominating the view.

**Gameplay and safety:** One land Netbot, one land Hookline and one underwater Hookline occupy roomy connectors/pools. Keep each pool's water and collision separate from lower dry ledges. Misses recover at the failed cluster via nearby ramps, without dropping routinely to the level bottom or bypassing the restoration gate.

**Review evidence:** Capture every combined rise-and-gap pair, rest-ledge crown view and pool exit. Test the bypass with reduced capability, side approaches to retained pools and player knockback near shores. Underwater depth tint must use each raised pool's surface, not one global altitude. Show source → spillway → receiving basin continuity.

**References:** R1, R2, R3, R4, R5, R8, R9, R11, R12.

## S05 — Restoration Garden

**Traceability:** REQ-024; existing workflow step and outcome retained. **Storyboard:** Arrive at the landmark → restore → reveal the finale.

Intent: deliver a peaceful restoration payoff at the crown arch without a collection or save-state softlock.

**Player-view panels:** Activate dry CP_03 on the required approach. Explore a continuous garden bank around the basin with the crown as the focal point. Show barren → resourced → restored changes from pickup viewpoints, then reveal the open gate toward the chute.

**Art and terrain:** Use the main crown arch as a singular hero landmark, not a repeated ornament. Patchy meadow, peach blooms, sandy paths, layered warm rock and vines surround it. The raised waterfall source has a visible basin and lip. Keep pickup silhouettes and the gate distinct from decorative flowers.

**Gameplay and safety:** Seven accessible garden seeds plus two terrace extras; automatic spending is three then four, seven total. No deposit station or enemy-clear gate. Keep the arch's usable openings, dry checkpoint, basin exits and pickup path clear; restoration decoration must not introduce new blocking collision.

**Review evidence:** Capture matched barren/resourced/restored frames and a pickup-to-gate view. Verify zero/one/two terrace-seed arrivals, reloads, missed optional discoveries and a reduced-capability circuit. Check the gate's complete boundary against swim/jump bypasses and inspect all raised-basin shores. Calm reward presentation must survive close gameplay-camera inspection.

**References:** R1, R2, R3, R4, R5, R8, R9, R11, R12.

## S06 — Waterfall Run

**Traceability:** REQ-025; existing workflow step and outcome retained. **Storyboard:** Release into flow → telegraphed dive → calm landing.

Intent: give the player a joyful, steerable finale beside the scenic waterfall, ending in a safe reward pool.

**Player-view panels:** From the restored gate, reveal the banked water run and its first direction. Telegraph the dive bar before the straight approach; keep the next bend and landing readable. Ease into still turquoise water and a broad exit bank after the final turn.

**Art and terrain:** White water and gold flower accents build energy, then subside at the reward pool. Keep scenic vertical waterfalls visually connected to their source but spatially separate from the playable chute. Depth-dependent sediment follows the descending surface continuously; spray must not hide the hero or dive cue.

**Gameplay and safety:** Continuous high banks and a supported bed contain the run. Preserve braking, reversing and deliberate diving at current movement speeds, including boosted and reduced-capability traversal. No unbounded freefall, required waterfall ascent, enemy ambush, mandatory pearl, boss or whirlpool.

**Review evidence:** Record normal and boosted descent, stopping before the bar, reversal and pool exit. Sweep bends, bar clearances, water-volume joins and both banks. Verify no positive water step or current discontinuity ejects the player. Accidental escape is a defect with nonlethal fallback, not an intended finale hazard.

**References:** R1, R2, R3, R4, R5, R9, R11, R12.

## 07 — Finish and return

**Traceability:** REQ-026; existing workflow step and outcome retained. **Storyboard:** Celebrate → acknowledge progress → return home.

Intent: make completing the adventure and returning to Open Lagoon feel clear, calm and continuous.

**Player-view panels:** Let the player settle on the reward bank, optionally find the tide pearl, then cross the only exit lane's reach_volume. Acknowledge restoration/completion and return through the existing hub flow. Revisit with the saved world state consistently presented.

**Art and terrain:** Carry turquoise water, warm sand and the lagoon's plant language through the finish. Keep the exit silhouette distinct from optional rewards; reduce spray and visual noise so the moment reads as completion.

**Gameplay and safety:** Persist coral_cove.completed through the existing finish policy. Optional discoveries, crayfish and dancing are not completion conditions. Checkpoint retry and full application restart remain distinct policies; do not imply restart resumes at CP_03.

**Review evidence:** Capture finish trigger → completion acknowledgment → lagoon return, then re-entry and save reload. Confirm no duplicate reward, missed completion volume, stuck camera hint, stale water contact or restored-state regression. Supply a continuous gameplay recording rather than treating selected screenshots as proof of a complete route.

**References:** R1, R4, R6, R9, R12.

## Quality review applied to every section

- **Composition:** inspect the actual follow camera at entry, action and payoff; the next action, usable surface and recovery exit must be readable. Use root/crown/waterfall reveals as recurring orientation, and keep decorative frames outside camera and movement clearance.
- **Terrain and assets:** use authored banks and cliffs for continuous landforms, complete selected models for landmarks, and intentional clusters for small dressing. Inspect repeated silhouettes, identical rotations, stretched proportions, exposed box shapes, floating props and visibly mismatched collision. Random detail must be seeded and kept off traversal and camera corridors.
- **Materials:** compare lagoon and Cascade under matched lighting/resolution. Keep sand, soil, moss, rock and grass at coherent physical scale with variation at several sizes; no enlarged atlas pixels, obvious repeating stamps, hard blend seams or sparkly undersampled normals. Blue underwater stone blends with fine sediment/pebbles; shallow-to-deep colour is based on the relevant water surface and preserves visibility.
- **Water and motion:** visibly connect every scenic waterfall to a source basin/lip and receiving water; separate scenic sheets from gameplay volumes. Review smooth heading changes, swim-body motion, shoreline transitions and enemy anticipation/attack/recovery from real input. Screen effects must not obscure platform edges, hook lines or the hero.
- **Containment and fairness:** visible shore edges and supporting collision agree at the actual terrain surface. Sweep connected entrance seams, underwater arches, raised-pool sides and recovery ramps with the shipped capsule, including diagonal, boosted and knockback approaches. Physical containment is primary; safe checkpoint return is a backup and ordinary escape costs no life. No hidden wall should conceal a reachable visual opening without appropriate visible boundary design.
- **Evidence:** for each step retain entry/action/payoff captures, a normal-camera continuous traversal, tested miss/retreat/recovery cases and recorded issues. Attach commit, scene, camera, lighting, quality preset, resolution, device and test conditions. Compare to the named references rather than certifying a beauty shot. Re-run affected checks after geometry, collision, water or controller changes; historical pass counts and triangle totals are not current certification. Measure whole-game frame times on the declared desktop tier, without changing thresholds just to pass.

These are review instructions refining existing intent. Existing automated/manual acceptance criteria remain unmodified and unmet until appropriate fresh evidence and human review. Hero/camera/enemy systems retain their current architecture owners; the adventure owns their placement, composition and encounter pacing.


## Publication and design audit

See [design consistency audit](design-consistency-audit.md), [workflow reference map](workflow-reference-map.json), and [visual source hashes](references/source-manifest.json). Gameplay criteria and requirement links remain authoritative in NodeSpec.
