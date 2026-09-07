# MVP readiness

Assessment: 2026-09-07, starting at `b37fb8c` on
`claude/openaxolotl-vision-kjw94z`. This is an implementation assessment,
not an acceptance report or a replacement for NodeSpec.

## Source of scope

Read `.nodespec/model.json` for architecture, contracts and artifact mappings,
and `.nodespec/spec.json` for the original vision and acceptance criteria.
`.nodespec/BOARD.md` is generated; its smoke-test checks do not establish
hands-on enjoyment, visual acceptance or target-PC performance.

The original MVP is a single-player PC platformer: Open Lagoon, Coral Cove,
Bubble Bay, a reference world, Bubble/Jet/Glow Gill Mods, regeneration and
capability loss, checkpoints/lives, habitat restoration, Drift Fleet enemies,
and a Flagship encounter. Community submissions follow contract-v1 freeze.
Multiplayer, consoles and a level-editor GUI are explicitly out of scope.
The later red rocket/torpedo and yellow friendship concepts need an explicit
spec decision before replacing the original mod lineup.

## First integration patch

- REQ-014 / REQ-008: the shipped main scene now owns a save session, attaches
  the profile to the hub, and saves every five seconds, on completion, on
  focus loss and on window close. Restoration uses its existing save port;
  region resources, unlocks and traversal state load on world entry.
  Existing collectible/checkpoint stores now receive the production profile.
  Equipping a Gill Mod records its unlock. Temporary equipment still resets
  when entering a world; saved unlocks are records, not automatic equipment.
- Writes replace the previous profile only after a successful temporary-file
  write. A failed profile load uses a temporary session and preserves the
  existing file. Storage errors are not yet presented in a player-facing UI.
- REQ-022: HUD countdown/recharge processing stays enabled when the hub
  disables its own physics and processing during world play.
- REQ-015 / REQ-016: the unreferenced Meshy source GLB is preserved under
  `reference/`, outside engine import and game export. Its original name
  failed the naming check; correcting that exposed its triangle-budget failure.
  The existing runtime hero remains the player scene's asset.

## Playable MVP release gates, in order

| Priority | Work | Acceptance evidence |
| --- | --- | --- |
| 1 | Complete a polished Coral Cove playthrough: movement, camera, recoverable falls, readable objectives, restoration and boss payoff | A first-time player finishes without developer instructions or debug commands; record blockers and retry failures |
| 2 | Integrate the approved pink axolotl and its agreed variants | Optimized GLB, rig/animations and collision tested in actual swimming, land movement, damage and mod changes; maintainer approves rendered captures |
| 3 | Finish player-facing flow | Discoverable controls, pause/resume, settings, return-to-hub and completion feedback work with keyboard/mouse and controller |
| 4 | Finish save/resume semantics | Cross-session tests for both official worlds, completion, restored paths, discoveries, mods and checkpoints; decide safe checkpoint resume versus replay from spawn |
| 5 | Bring Bubble Bay to the same standard | Both official worlds playable from a clean profile and a returning profile; reference world remains contract-conforming |
| 6 | Ship a reproducible Windows build and establish the supported Godot version | Clean Windows install launches and plays; setup pin and project version agree; original PC distribution requirements verified |
| 7 | Confirm frame rate, sound and art on the target PC | Rendered traversal and worst-case boss/restoration captures, performance measurements and hands-on audio review |
| 8 | Resolve release documentation and licensing decisions | Maintainer chooses code/art/audio terms; provenance reviewed; contributor workflow and contract-v1 friction resolved |

## Asset finding

`reference/hero/pink_axolotl_2.glb` is 73,480,152 bytes with
1,933,518 indexed triangles, no skins and no animations. It was not referenced
by the player scene. This is a source model, not a drop-in animated hero.
The repository currently allows 60,000 character triangles; the working asset
recommendation is at most 50,000 triangles, 2048-pixel hero textures and about
10 MB per runtime GLB (25 MB upper preference). Optimize and rig it before
moving a derived version into `assets/character/`. Moving the source does not
shrink existing Git history.

## Known limits

World entry still starts at the spawn rather than the recorded checkpoint.
Resource pickups reset on entry; discovery collectibles and restoration are
persistent. Replay behavior, boss state and resource farming need explicit
playtesting. Automated traversal probes do not prove that a world feels fun.
Only a Linux export preset is currently present. The setup script pins Godot
4.3 while `project.godot` declares 4.7; no engine upgrade is part of this patch.

## Verification for this patch

- Godot 4.3 unit suite: 535 passed, zero failed, including a real profile
  round trip that reloads restoration resources and opens the scene gate.
- Hub traversal: 13 checks passed, including production session wiring,
  completion on disk and an active HUD while the hub is disabled.
- Coral Cove: 27 checks passed. Bubble Bay: 22 checks passed.
- Python suite under `OAX_UNDER_TEST_HARNESS=1`: 121 tests run, three skipped,
  no failures. Nested aggregator/build checks are excluded in this mode;
  the build was run separately on the working tree.
- Level Contract and static analysis validators passed. The Python asset
  conformance tests passed after separating the Meshy source from runtime assets.
- Linux build succeeded and the exported executable booted headlessly.
  Pack index inspection confirms all three world manifests and the session
  script are present, and the large source model is absent.
- Headless Godot logs still contain rendering-dummy and resource-cleanup
  diagnostics. No graphical or audio acceptance, Windows build verification,
  or target-PC performance claim is made here.

## Integration update

Merged Claude's terrain-shell work at `4de8113` and preserved its source-model
location under `reference/hero/`. The hub scene keeps both the terrain shell
and production save session. `reference/.gdignore` and the export exclusion
keep reference inputs out of the runtime. The verification counts above
describe the original patch before this integration update.
