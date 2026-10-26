# Living Cascade — execution plan

Revision 2 design source: C:/Users/ltben/Documents/Codex/2026-09-11/ana/outputs/living-cascade-specification.json

Build small, playable increments in dev/living_cascade before switching the shipped world.

| Chunk | Deliverable | Pass condition | Status |
|---|---|---|---|
| 1 | Six section roots and exact join markers; playable arrival pool, bank ramp, existing axolotl and camera | Real input-driven swim → ramp → grounded bank → JOIN_12; clean import | PASS — import and real-input traversal |
| 2 | S02 stones with measured gaps, optional spur and recovery water | Complete jumps and swim alternative; recover each miss to the local route | PASS — jumps, rescue, recovery and swim route |
| 3 | S03 root dive and east-bank exit | Capsule clears ceiling/floor, camera remains usable, no dry bypass | PASS — forward/reverse, rescue, clearance and camera sightlines |
| 4 | S04 three terrace clusters and local recovery | Each rise/gap tested; pools do not overlap dry approaches; reduced-capability bypass | PASS — five rising jumps, climb, dive, bypass, seeds and recoveries |
| 5 | S05 garden, nine seeds total, automatic 3+4 restoration, closed gate | Zero-seed garden entry still finishes; gate cannot be bypassed; persistence/retry behavior verified | PASS — 0/1/2 terrace-seed cases, gate, basin exits, save/reload and retry |
| 6 | S06 chute with straight dive approach, contained bends and finish | Water seams stable, boost/tail-loss tested, reachable calm finish | PASS — normal/boost/reduced-speed, reversal, deliberate dive, stopping and saved finish |
| 7 | World integration and presentation | Reconcile old boss/save dependencies, connect lagoon, update route tests, capture hero views and profile | PASS integration and technical checks; prototype presentation reviewed |

The production Living Cascade is now reached through the normal lagoon passage (F5). Its former Coral Cove scene is archived. The development scene remains isolated for tests. Dated records below describe earlier milestones; the latest Chunk 7 record gives current status and visual limitations.

Open dev/living_cascade/blockout.tscn in Godot and run the current scene (F6). Default controls: WASD movement, Space swim up/jump, Shift swim down, mouse look. The prototype now reaches JOIN_OUT at the final calm bank. The reach_volume callback records completion in the separate development profile.

Verification:
godot --headless --audio-driver Dummy --path . --script test/worlds/run_living_cascade_arrival.gd

Implementation decisions for S01:
- Pool footprint X=-10…2, Z=-12…-2, surface Y=0, bed Y=-2.
- East-bank pad at CP_01=(3,0.4,-8) stays dry.
- Ramp top runs from (-4,-2,-8) to (2,0.4,-8), 4 m wide and about 21.8 degrees.
- Dry join Y values are support heights; the capsule centre stands 0.8 m above them.
- Inlet current is deferred until lagoon integration. Prototype water is still to isolate bank-transition behavior.
- Dev perimeter walls prevent walking into unfinished sections.

## Chunk 1 validation result

Godot import completed without errors. The real-input arrival probe reported PASS at approximately (-7.352, 1.201, -17.837), within the JOIN_12 arrival tolerance. It verified swimming at spawn, camera binding, six section roots, correct join position, swim-to-grounded-land transition and final dry support. The route used the real input/controller/physics chain and no waypoint teleports.

Logs: C:/Users/ltben/Documents/OpenAxolotl-main/review/living-cascade-arrival.log and C:/Users/ltben/Documents/OpenAxolotl-main/review/editor-import-codex-check.log.

Chunk 1 results cover arrival traversal; chunk 2 results are recorded below. Final visual quality, S03–S06, persistent checkpoints, current-assisted inlet and full world integration remain pending.


## Chunk 2 — completed

S02 is now instanced from dev/living_cascade/garden.tscn. The arrival scene connects to its approach bank; S03–S06 are still planning markers. The playable prototype now ends at JOIN_23=(-22,0.8,-44).

| Landing | Centre X/Z | Top Y | Gap from previous landing |
|---|---|---|---|
| P21 | -22 / -25 | 0.4 | Continuous approach |
| P22 | -22 / -29.2 | 0.5 | 1.2 m |
| P23 | -22 / -33.8 | 0.65 | 1.6 m |
| P24 | -22 / -38.8 | 0.8 | 2.0 m |
| Optional O1 | -27.4 / -29.2 | 0.9 | 2.4 m west from P22; return to P22 |

Each landing has a 3 × 3 m usable top. Recovery water is at Y=0 with bed Y=-2. The two 4 m horizontal-run ramps rise from (-18,-2) to (-14,0.4) at Z=-27.5 and Z=-36.5. Their approximately 31-degree slopes were traversed by the actual controller. A clear swimming lane near X=-19.25 passes east of the stones and west of the ramps. The east recovery bank leads through a separate gentle rise to the exit bank.

The optional rescue uses the existing CollectiblesSystem with an in-memory store. Touching its gold placeholder collects the hermit snail and updates the label once; this development adapter does not write saved discovery progress. Final art and full WorldSystems integration remain later work.

### Verification

- Godot import: clean.
- Arrival regression: PASS.
- Continuous input-driven arrival → garden approach: PASS.
- All three main jumps, optional rescue jump and return: PASS, with grounded arrivals and no water contact during jumps.
- Four deliberate missed-jump recoveries: PASS (159–168 physics frames, roughly 2.7–2.8 seconds at 60 Hz).
- Swimming alternative to JOIN_23: PASS.
- Test resets teleport only between independent recovery scenarios. The main route and each recovery itself use real input/controller/physics movement.
- Two geometry problems were found and fixed: ramp intrusion into the swimming lane, and a collision lip where the lower ramp met the exit-bank rise.
- Visual camera comfort and final art are not certified by these headless checks.

Commands:
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script test/worlds/run_living_cascade_garden.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script test/worlds/run_living_cascade_arrival.gd

Next: chunk 3, the required root dive with audited capsule clearance and the east-bank exit.

## Chunks 1–2 refinement and Chunk 3 — completed

Reference: revision 2 of the illustrated design, section sheets, coordinate ledger and capsule audit. These remain the design basis; the details below record the tested blockout.

### Refinements to earlier chunks

- Restored the development scene root to an identity basis. A slight saved rotation conflicted with the specification's world-aligned water surfaces and join coordinates.
- Expanded the CP_01 marked pad to 4 × 4 m, aligned its top to Y=0.4, extended the supporting east bank, and adjusted its ramp to meet the pad without a lip.
- Added the specified 4 × 6 m shallow shelf (X=-10…-6, Z=-8…-2, top Y=-0.3), an access ramp and a second exit into the arrival bank.
- Both arrival exits were traversed with the existing tail-loss swim-speed factor (0.6).
- Re-ran all garden jumps, rescue, swimming alternative and four missed-jump recoveries after connecting the root.
- Added short-press jump tests: the 1.2 m and 1.6 m gaps were reached; the 2.0 m gap produced a safe water landing with successful recovery. Hold jump longer for the widest gap.
- The old garden endpoint wall is removed and its sign now introduces the root dive.

### Root blockout and specification mapping

- Entry remains JOIN_23=(-22,0.8,-44); exit remains JOIN_34=(12,0.8,-56). A staging pad immediately east supports the player until S04 is built.
- Main swim targets follow (-22,-1.6,-50), (-18,-1.6,-55), (-10,-1.6,-58), (-2,-1.6,-58), (4,-1.6,-58).
- Still water surface Y=0; bed Y=-3.2; root underside Y=-0.5. The 1.6 m upright capsule fits the audited Y=-1.6 targets with 0.3 m overhead clearance.
- The main chamber is widened around the bend; its roof and side walls prevent a dry shortcut. The entrance reserves a 6 m swimming opening beside a separate 4 m return ramp.
- A 4 m wide ramp rises eastward from (4,-3.2,-56) to (12,0.8,-56). A matching exit water volume covers its submerged portion.
- O2 houses a lantern-shrimp placeholder at (-12,-1.6,-65). Its optional loop returns through (-2,-1.6,-65) and (0,-1.6,-59) to the main exit. The old optional-branch Y=-1.2 text was inconsistent with the capsule audit and is corrected to -1.6 in the specification.
- Cyan guide markers identify the main dive path. Final organic root meshes, lighting composition and waterfall vista remain presentation work.
- The existing collectible adapter now accepts a discovery ID/name and serves both prototypes, still using an in-memory store only.

### Validation

Godot headless checks report PASS:
1. Arrival regression.
2. Garden traversal, optional rescue, four miss recoveries, swimming route and short-release cases.
3. Continuous input-driven traversal from S01 through S02 into S03.
4. Forward and reverse root passage using the actual tail-loss speed modifier.
5. Optional lantern-shrimp rescue and rejoin; normal completion without that discovery.
6. Surface-height travel cannot pass through the roof without diving.
7. Capsule shape queries clear at the main bend, main chamber and optional pocket.
8. Stationary camera-to-player sightline queries clear at four underwater viewpoints.
9. Both arrival shore exits at reduced swim speed.

Commands:
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script test/worlds/run_living_cascade_root.gd

Main and reverse traversals use real input without waypoint teleports. Independent branch, camera, clearance and recovery cases reset their initial positions. Tests verify traversal and geometric sightlines, not final rendered beauty or all possible user camera angles.

The prototype now ends at JOIN_34. S04–S06, persistent checkpoints, lagoon current integration, restoration, completion/save migration and final art remain pending. Next: Chunk 4, the cascade terraces.


## Reference comparison and Chunk 4 — completed, 12 September 2026

Compared against the revision 2 section specification, join/elevation ledger and overhead map. The broad route remains arrival → west garden → submerged root crossing → east-bank terraces. Chunk 4's test reads dev/living_cascade/design_reference.json and checks the first five join markers against that reference, the identity scene basis and the three S02 gap widths. The illustrated map is a placement guide, not a collision outline.

Chunks 1–3 regressions passed again after replacing the root's temporary endpoint pad/wall with S04's entry bank. Their gameplay geometry otherwise remains as recorded above. The root sign now points to the terraces.

### Terrace geometry and deliberate refinements

All coordinates below are support heights, except explicit underwater capsule targets.

| Feature | Tested blockout | Reference comparison |
|---|---|---|
| Entry / CP_02 | JOIN_34=(12,0.8,-56); entry bank spans X=12…24, Z=-59…-54; 4 × 4 m CP pad at (16,0.8,-57) | Join and checkpoint target retained |
| A landings | (22,1.6,-61.9), (22,2.4,-66), each 3 × 3 m | Two +0.8 m rises; gaps 1.4 and 1.1 m, below 1.6 m limit |
| B climb | Broad approach at Y=2.4; climb top Y=4.4 near (30,-78) | Exactly 2 m; continuous ramp bypass from X=22…28.5 at Z=-77 |
| B dive | Surface 3.8; bed 1.0; brow underside 3.2; capsule target Y=2.1 | Specified 0.3 m vertical capsule clearance on each side |
| C landings | (21,5.2,-88), (16.5,6,-88), (16.5,6.8,-92), each 3 × 3 m | Three +0.8 m rises; gaps 1.5, 1.5 and 1.0 m |
| Exit | JOIN_45=(24,6.8,-92) | Exact specified join; S05 remains unbuilt |
| Seeds | Broad ledges at (22,2.4,-66) and (30,4.4,-78) | Both specified resources collected on the mandatory route |

Pool surfaces/beds remain A=1.8/-0.2, B=3.8/1.0, C=5.8/3.8, plus the lower 0/-2 gutter. Elevated water is offset from lower dry approaches. Decorative spillways and current are not implemented.

The B exit ramp now sits in a side basin at X≈34.5, beyond the dive brow, and rises from bed Y=1 to bank Y=4.4. The route crosses a southern bank and returns to the C approach. This avoids a ramp obstructing the underwater passage. Pool B extends beneath upper misses; its return ramp starts at bed height near (17,1,-91.5) and rises to (24,4.4,-91.5). Pool C is a compact lateral recovery pocket at X=12…15, with a ramp back to C2. The upper exit deck is thin enough to preserve passage above the lower return bank.

These are as-built refinements to the map's schematic pool/shore shapes. Some boundaries extend slightly beyond S04's planning rectangle to contain the shared endpoint. C's local recovery can rejoin C2 rather than always restarting C1; this intentionally avoids unnecessary repetition. Before S05/S06 integration, resolve the shared boundary and verify the final dividing ridge and gate containment. Those later protections are not certified by the current development perimeter.

### Validation and limits

Godot 4.7.2 headless import completed without errors. Arrival, garden, root and terraces scripts all report PASS after the final geometry changes.

The terrace script traverses S01–S04 continuously using actual controller input, without waypoint teleportation. It verifies five dry rising jumps, the 2 m climb, passage beneath the B brow, grounded JOIN_45 arrival and both resource pickups. Independent cases verify the ramp bypass with the existing 0.5 reduced-climb factor, five deliberate misses returning through local pools or ramp catches, and dry approaches staying outside higher water volumes. Independent scenarios reset their starting position; this is not teleport-assisted route traversal.

Command:

godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script test/worlds/run_living_cascade_terraces.gd

The terrace adapter uses the existing CollectiblesSystem with an in-memory store. Restoration spending, saved resource identity, retry behavior and persistent checkpoints are still pending. Tests cover the stated routes and scenarios, not every possible miss, camera angle or rendered composition. Organic meshes, landmark framing, open-valley views, final effects and pacing remain presentation/integration work.

Next: Chunk 5 — restoration garden, seven additional garden seeds, automatic 3+4 spending, gate containment and persistence/retry checks. Do not switch the shipped Coral Cove world until the integration chunk resolves its existing completion and save dependencies.

## Containment refinement and Chunk 5 — completed, 12 September 2026

Reference: revision 2 S05 section sheet, seed positions, CP_03 and JOIN_56 ledger, pool elevations and 3+4 restoration audit. The continuous real-input route now reaches JOIN_56=(8,7,-104) from the original arrival spawn.

### Floors, walls and unexpected falls

- Added a solid foundation covering X=-38…40 and Z=-113…6, top Y=-4.2 and bottom Y=-6.2. It lies below every existing pool bed and closes otherwise open voids beneath the scaffold.
- Added connected, non-climbable outer walls extending from Y=-6.2 to 16, with overlapping corners. These are development containment geometry; future valley-facing art can replace them with tested terrain boundaries.
- Closed the unfinished inlet at Z=3.5…4.5. Chunk 7 will replace that cap when joining the lagoon.
- Preserved the local pool/ramp catches around the intended jumps. A wide miss that escapes those catches returns to the latest activated checkpoint at capsule-centre Y<-3.1, before landing on the foundation. An explicit X/Z bounds check also catches an unexpected collision escape.
- The new development session replaces the old spawn-only fall guard. Recovery clears velocity and water contacts, then resamples immersion at the checkpoint. CP_01, CP_02 and CP_03 are monotonic within a visit: backtracking cannot overwrite a later checkpoint with an earlier one.
- This is development recovery, without life loss. Production pit/lives/session semantics remain part of Chunk 7. When S06 is built, extend the foundation and perimeter to its full chute footprint before opening this boundary.

### Restoration garden mapping

| Element | As built |
|---|---|
| Entrance | The terrace's temporary end wall is removed. Garden entry crosses the 4 m opening at X=22…26, through CP_03=(24,6.8,-94). |
| Banks | East/north/south banks at Y=6.8; west bank at Y=7.0. A gentle X=16…18 transition connects the two heights. Clear bank routes lead to every seed. |
| Basin | X=18…26, Z=-104…-98; surface Y=6.2, bed Y=4.2. Two 4 m wide opposing ramps rise to the west/east shores. |
| Garden seeds | (27,6.8,-95), (31,6.8,-99), (29,6.8,-105), (21,6.8,-107), (13,7,-103), (16,7,-97), (12,7,-101); pickup centres add 0.75 m above support. |
| Restoration | Existing RestorationSystem and CollectiblesSystem, with the reference 3 and 4 resource-cost overrides. No deposit interaction. Terrace seeds and garden seeds share one region. |
| Gate | X=8.5…9.5, Z=-106…-102, extending from Y=-4.2 to 12; adjoining ridges close the sides. Floor at Y=7 closes the underpass. Collision and visible barrier clear only when restored. |
| End | JOIN_56=(8,7,-104) has a supported bank. Temporary wall X=5…6 holds the player until the chute is built. |
| State feedback | Visible muted → green → peach crown placeholders and a world-space state/seed label. Only the explicit gate changes collision. Final organic crown and lighting are later presentation work. |

The rectangular bank/retaining geometry is a tested scaffold interpretation of the map. The specified endpoints, seed/support coordinates, pool bounds and elevation targets are retained. The broad outside wall and foundation are containment scaffolding, not the final landscape silhouette or hero composition.

### Save, pickup and retry behavior

The development adapter uses the existing SaveSystem and SaveRestorationStore. Its dedicated profile is user://living_cascade_development_v1.json, under the separate living_cascade_development_v1 world namespace. It does not load or write the normal gameplay profile.

Resource definitions identify a type, not a unique placed seed. The adapter therefore records nine stable placed-instance IDs alongside the restoration region state, banked resources and last checkpoint, committing them together through SaveSystem's atomic file replacement. A collected seed stays absent on reload; revisiting it cannot pay the gate twice. An unreadable development save is preserved instead of overwritten.

Normal F6 runs resume at the last activated development checkpoint. For a fresh non-persistent test, set PreviewSession.save_path to an empty string in the scene inspector. Automated route tests override this field in memory; the persistence test uses a unique review/living-cascade-save-test-*.json fixture. Neither test mode touches the normal gameplay save.

### Verification

All six headless checks pass, with no script errors, resource leaks or shutdown errors in their final logs:

1. Arrival regression.
2. Garden stepping stones, rescue, misses and swimming alternative.
3. Root dive, reverse/reduced-speed routes, capsule and stationary sightline checks.
4. Terrace jumps/recoveries plus continuous S01–S05 traversal: two terrace seeds and five garden seeds open the gate; no fallback reset is used on that extension.
5. Restoration garden with 0, 1 and 2 terrace seeds: automatic spending at totals 3 and 7, exact balances, both basin exits, reload at six collected seeds, no duplicate pickup on revisit, restored gate after reload, and fall recovery retaining progress.
6. Containment: 2,301 floor-coverage rays, perimeter probes at several heights, the closed dividing ridge/gate, walk/jump/climb attempts against the gate, and independent wide-miss cases.

The persistence tests initialize terrace extras as test fixtures; the continuous terrace test separately proves both physical terrace pickups feed the same restoration system. Main routes use actual keyboard/controller/physics movement. Independent recovery and restart cases set their starting positions explicitly.

Final Godot 4.7.2 editor import: clean. Final art, every possible movement/camera combination, rendered readability and full game/save migration are not certified by these headless checks.

Next: Chunk 6 — the contained waterfall chute, current seams and dive bar, reduced-speed/boost handling, calm finish and optional pearl. Keep the current exit cap until the entire chute floor, water and boundaries are ready.

## Chunk 6 — completed, 12 September 2026

Reference: revision 2 S06 route, elevation ledger, straight dive-bar approach, 2.8 m depth requirement, contained bends, optional pearl and reach_volume completion. All six sections now connect through actual controller-driven traversal, from arrival to JOIN_OUT=(-38,1,-110).

### Chute geometry and reference mapping

- Surface anchors remain (6,6.2,-104), (0,5.8,-110), (-18,2.5,-119), (-27,0.4,-110) and (-28,0.4,-104). The three bends are rounded with short quadratic transitions, so the built centreline trims the sharp map corners rather than turning instantly at each anchor.
- The channel has an 8 m clear width and 56 overlapping floor/water strips. Its bed follows 2.8 m below the centreline surface. Retaining banks extend approximately 3.8 m above the adjacent water and join the final pool banks. The intake includes a reversible 4 m wide ramp back to the +7 garden lip.
- The dive bar stays at X=-12, Z=-116 on the long straight, with surface Y=3.6, underside Y=3.0, and bed Y=0.8. The tested capsule-centre target Y=1.9 clears both bed and bar. It spans the channel and meets the side banks.
- The current is up to 1 m/s, ramps in at the intake and fades at the finish. Still side margins provide stopping places. A still approach pocket within 2.8 m along the channel of the bar, for players above Y=2.15, prevents the controller's surface-following velocity from pressing a blocked player down the obstacle. The dive remains player-controlled. This pocket is a tested refinement to the proposed current layout.
- Water Areas remain unrotated. Their box shapes follow the channel direction, while a shared section-relative profile supplies surface height, slope and flow. Overlapping Areas use distinct ordered priorities and the same field, avoiding disagreement between adjoining strip surfaces. Named junction strips cover the bends. Translation of the water profile is checked; rotation is still outside the design contract.
- The 12 × 10 m reward pool is centred at (-28,0.4,-104), with still water and bed Y=-2.4. A short bed extension supports the inlet. A 4 m wide ramp rises westward from (-28,-2.4,-106) to (-34,1,-106), joining the broad final bank.
- The optional tide pearl is on that bank at support (-36,1,-102). The only final exit lane runs between retaining walls at X=-40…-36. Its completion volume crosses Z=-108.5 immediately before JOIN_OUT. No boss, pearl requirement or onward portal is added.
- The former garden exit cap is removed. The solid foundation now covers X=-42…40 and Z=-127…6, with enclosing walls outside that footprint. The depth guard remains Y=-3.1 and returns to the latest development checkpoint. Bounds include a small containment margin beyond the schematic map envelope.

### Completion and persistence

The existing WorldLoader.wire_finish_condition(..., REACH_VOLUME, ...) wires the final Area's player-entry signal to the development completion callback. Completion is idempotent and persisted through the existing SaveSystem. The tide pearl is a discovery in the existing CollectiblesSystem, backed by SaveCollectibleStore; its ID is an additive extension to the separate development world's saved shape. The seven-seed economy remains unchanged.

The existing user://living_cascade_development_v1.json profile now includes completion and the optional pearl. Normal gameplay saves and the shipped Coral Cove world remain untouched. Chunk 7 must still reconcile the shipped boss/open_sea/fleet_core contract and adapt the development checkpoint/bounds handling to the production world session.

### Verification

All seven headless suites pass: arrival, stepping-stone garden, root, terraces/full route, restoration, containment and chute. Final Godot 4.7.2 editor import is clean, with no errors or warnings in the final logs.

The full route uses actual keyboard/controller/physics input continuously from arrival to the finish, including terrace pickups and garden restoration. The chute suite separately proves:

- Normal, 0.6 swim-speed and boosted downstream runs to the supported final bank; the boost's active state is observed.
- Continuous immersion after the intake shore transition.
- Full upstream return through both bends and the dive bar to the garden lip at reduced swim speed.
- A surface-height approach stops at the bar, then reversing and deliberately diving succeeds.
- Shared strip surface values, deterministic priorities, world-aligned water Areas and translated profile sampling.
- Capsule clearance at the dive bar, still side-margin/pool stopping, optional pearl collection, saved completion and pearl persistence on reload.
- Expanded floor coverage at 2,706 sample points and the existing closed-gate/perimeter checks.

Independent chute scenarios set their starting positions and initialize restoration as a fixture. They do not teleport along the tested routes. The continuous full-level test separately exercises real seed collection and gate opening. Frame logs report peak speed for diagnostics, not a measured player completion-time claim.

Implementation files: dev/living_cascade/chute.tscn, chute_profile.json, chute_profile.gd and chute_water.gd. The existing preview_session.gd owns the isolated completion adapter. Tests: test/worlds/run_living_cascade_chute.gd and the extended run_living_cascade_terraces.gd.

Next: Chunk 7 — production world/save/lives integration, lagoon connection, final landscape and waterfall presentation, hero-camera review and profiling. The scenic waterfall and polished crown/foliage are still presentation work; headless traversal does not certify final rendered readability or every possible camera/movement combination.

## Chunk 7 — integration complete; presentation reviewed, 12 September 2026

The Living Cascade now replaces the shipped Coral Cove scene. It is reached by running the game (F5) and swimming through the lagoon's leftmost downstream passage. The previous scene and manifest are preserved in `dev/archive/coral_cove_before_cascade/`. The development scene remains available for isolated tests.

### Design and integration

Revision 2's six-section order, join coordinates, measured jumps, terrace climb/bypass, nine-seed distribution, automatic 3+4 restoration, dive bar and calm finish remain the gameplay authority. Production is an unrotated scene translated to the lagoon outlet. It contains one spawn and one stream-entry marker; the duplicated development marker and both inlet backstops are removed. The tunnel's existing floor and walls cover the opening. The 2,706-point foundation check still passes; outer walls, dividing ridges, local recovery pools and gate collision remain.

The normal WorldSystems runtime now owns all three checkpoint Areas, pickups, restoration, life loss and pit recovery. A recovery costs one life, clears old water contacts and returns to dry CP_03 when that checkpoint is active. The existing reach_volume finish returns to the hub and persists completion. There is no boss, open_sea region, fleet_core requirement or mandatory pearl in the replacement manifest.

Each resource pickup now has a stable scene-path instance ID. Collecting one records its identity and restoration progress together in the normal profile, so collected seeds remain absent after reload. The existing five-second/focus-loss/completion save policy remains in effect. Entry into a world still begins at its entrance; checkpoints govern retries within that visit. Full application restart does not resume the character at CP_03. This preserves the current game's entry policy rather than silently introducing a new resume mode.

An explicit manifest migration option retains matching region state, discoveries, completion and unlock state while archiving the entire old world blob under `quarantined`. Retired IDs and obsolete checkpoint positions do not become active in the new layout. The migration was tested with a legacy-shaped fixture and separate test profiles; the user's live profile was not opened or overwritten during implementation.

### Water and camera corrections found during review

Production uses core `channel_profile.gd` and `channel_water_volume.gd`, with world-local channel data. It has no dependency on development scripts. The same numerical height/flow implementation is used by the development chute.

The original nearest-segment height selection exposed a discontinuity inside the tight bend. Nearby segment planes now blend into a continuous height field, with an analytic slope; straight segments retain their linear grade. Flow direction blends along the same neighborhood. Deterministic overlap priorities, still margins, the deliberate-dive pocket and the 1 m/s current setting remain. All normal, reduced-speed, boost and full upstream-return scenarios pass after this correction.

Each curved water mesh is sampled from that field, with 0.2 m target cells. The largest tested triangle-centre difference is approximately 0.100 m, below the 0.12 m regression tolerance; mesh vertices match to 0.001 m. This is a sampled approximation, not a claim of identical height at every rendered pixel. Flat pools use subdivided planes with the shared shader's `mesh_is_surface` setting. Water Areas include small bubble systems.

WorldSystems now connects CameraHintVolume signals to the real camera rig and removes hints on unload. Production solids carry the camera-collision layer. Tests observe the crown hint activating, its authored pitch taking effect, and all hints leaving the stack when the world unloads. Review-camera teleports explicitly resettle the camera; ordinary player movement keeps the existing smooth following behavior.

### Presentation and honest limits

Added the root bridge and rising roots, crown arch, restoration-responsive peach blooms, separate scenic waterfall, shared terrain skins, and seven batched foliage/rock fields. Walkable skin caps remain on their collision tops, with small lowered rims. Decorative foliage and landmarks add no player collision. Development coordinate labels and temporary crown blobs are removed from the shipped scene. Existing kit vertex colors are restored through a post-import script for four assets that otherwise imported with white materials.

Rendered arrival, stones, root exit, barren/restored crown, finish and overview views were inspected. Initial roots that obscured the exit were relocated, crown framing was widened, and oversized guidance text was reduced. The overview capture disables fog on its own review camera; hero captures use normal Medium lighting.

**This is an integrated, dressed prototype, not finished concept-art fidelity.** The main remaining visual work is replacing the broad rectangular wall facades, improving the crown/waterfall reveal along the terrace approach, softening the procedural root/flower shapes, and replacing rescue placeholders. The current tall containment walls restrict some long views shown in the concept image. These are recorded differences, not a claim that every hero sightline matches the illustration. No arbitrary camera orbit, every possible miss, player completion time or baseline-hardware frame rate is certified here.

### Verification

| Check | Result |
|---|---|
| Godot unit suite | 619 passed, 0 failed |
| Real-input normal-game playthrough | PASS; 3,956 physics frames, seven seeds, restoration, finish, hub return and restored revisit |
| Production integration at a translated origin | PASS; legacy migration, pickup persistence, one-life pit recovery, dry checkpoint, camera activation/cleanup and reload |
| Continuous lagoon passage | 31 checks, 0 failures; no player/camera replacement or activation teleport |
| Containment | PASS; 2,706 foundation rays and gate walk/jump/climb attempts |
| Chute / full development route | PASS after smoothing; normal, boost, tail loss, reversal, deliberate dive, stopping, pearl and S01–S06 route |
| Level contract / static API analysis | PASS; static analysis scanned 220 files |
| Headless performance | PASS; load 227 ms, restoration frame 2.2 ms, post-discard spike 2.8 ms against 50 ms budget |
| Actual GPU gate, 1920×1080 | PASS on NVIDIA GeForce RTX 5090 Laptop GPU |

GPU means: Low 1.06 ms, Medium 4.30 ms, High 5.87 ms, with 96 samples per quality. Medium p95 was 11.36 ms and its worst sample 18.22 ms. These are GPU-only measurements on this computer, not whole-game frame times or a promise for a lower-end GPU. The headless rate (928 physics frames/s) is a CPU regression measurement and renders nothing.

Final gameplay, capture and import logs contain no script errors or resource-leak reports. The unit suite deliberately feeds malformed JSON to error-handling fixtures, so its expected parser diagnostics must not be confused with runtime game errors. A pre-tree player initialization fallback removes four unrelated out-of-tree errors discovered by those tests. Two closing-brace indentation changes in `project.godot` let the existing INI-based static checker read the unchanged shader-global values.

Primary logs: `review/cascade-units-final.log`, `cascade-walk-final.log`, `cascade-production-final.log`, `cascade-stream-final.log`, `cascade-containment-final.log`, `chute-final.log`, `terraces-final.log`, `cascade-performance.log`, `cascade-gpu-performance.log`, and `cascade-editor-final.log`.

Next refinement: review the integrated game by hand, then improve landscape and landmark readability within the tested collision layout. Do not remove containment walls simply to imitate the concept silhouette.



## Follow-up — leftmost starting-cove connection

The Living Cascade is now the leftmost tunnel when facing the exits. Its manifest supplies hub presentation order and requests the continuous passage. The stream, receiving world, excavated floor, visible water seam and northern boundary opening all move together by -6 m in X. Bubble Bay moves to the middle tunnel and remains usable. Directory names no longer determine the main route. See `review/left-tunnel-stream.log` for the real-input connection and complete route test, and `living-cascade-asset-brief.md` in the design outputs for the next art deliverables.

## Supplied asset integration - 13 September 2026

Nine source models now contribute the root/crown arches, cliff and reef wall relief, stone surfaces, ledges and underwater dressing. All 372 collision shapes remain; the linked-asset scene totals 395,289 triangles including the hero. Gameplay, unit, level-contract and static checks pass. The GPU quality-order benchmark remains flagged because Low measured slower than Medium; no threshold was relaxed. See ASSET_PASS.md for preparation reports, exact placements, validation, limitations and rollback details.
