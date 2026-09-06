# Coral Cove

The first official world (REQ-011) — and, more importantly, the first
battle-test of the Level Contract. It is built with **no privileges an
outside contributor lacks**: a manifest, a scene, and nothing else. There is
no script in this module; every mechanic is a declaration the game client's
`WorldSystems` runtime binds. If you can read `world.json` and `world.tscn`,
you can build a world exactly like this one.

## The route

One line down −Z, completable with a single held forward key — because
completability is a headless regression test, not a hope:

1. **Spawn** on the shore (land grammar — waddle).
2. **The lagoon** — a `WaterVolume` spanning the route: water grammar in,
   land grammar out the far side. Both grammars are mandatory, not scenery.
3. **The hermit snail** — a *discovery* collectible on the shore: a rescued
   creature, declared in the manifest, placed once in the scene, and written
   to the profile the moment it is touched. A second one, the lantern shrimp,
   sits **off the route** by the seed bed — the optional branch the reward
   layer exists for; the straight-line walk never reaches it and asserts so.
4. **Glow Gills pickup → glow gate.** A bioluminescent false wall that opens
   only while the equipped mod grants `reveal_bioluminescent`. A camera hint
   volume tightens framing through the grotto — declaratively, as the
   contract requires.
5. **Bubble Gills pickup → bubble gate** (`bubble_platform`). Coral Cove
   gates on **Bubble and Glow**; Bubble Bay takes **Jet**, so the official
   set covers all three MVP mods (the REQ-011 cross-world split).
6. **The coral shelf** — the declared restorable region. Seven kelp seeds
   along the path restore it: one `resource`-kind collectible, `kelp_seed`,
   declared once and placed seven times, each delivered to the shelf and
   *spent* (`restoration.*.resource_cost` overridden to 3+4 through the
   sanctioned `tuningOverrides`). Only a **restored** shelf opens the wall in
   front of the finish. Restoration is on the critical path, not a side
   activity.
7. **Finish volume** → back to the Open Lagoon, completion recorded through
   the save-integration interface.

## Declarations used

| Contract element | Used here |
|---|---|
| required: spawnPoint, checkpoints (×5, roughly every 10 m — the density REQ-003 AC-7's 5 s replay bound demands at waddle pace; the coral walk measures every segment), finishCondition (`reach_volume`), saveIntegration, controllerCompatibility | yes |
| optional: restorableRegions | `coral_shelf`, gate `shelf_wall` opens at `restored` |
| optional: tuningOverrides | both restoration resource costs (sanctioned set) |
| optional: cameraHints | one hint volume over the grotto |
| optional: collectibles | `kelp_seed` (resource → `coral_shelf`), `hermit_snail` and `lantern_shrimp` (discovery) — Coral Cove is the world that exercises **both** kinds; Bubble Bay declares resources only |
| optional: boss, enemies, music, npcs, secretAreas, customAbility | **not declared** — absent defaults apply |

Scene-group conventions bound by the runtime (`gill_mod_pickup`,
`affordance_gate`, `restoration_resource`, `restoration_gate`) are recorded
in `docs/contract-friction.md` as candidates for Level Contract elements
before the v1 freeze — they are conventions today, and pretending otherwise
would hide exactly the friction REQ-011 exists to surface.

## Pending integrations

The Drift Fleet framework and the Flagship encounter exist as core nodes
but are not yet declared here. When they are, Coral Cove is where the boss
path gets proven (Bubble Bay declares none): the `boss` element gets
declared, the shelf's unlock moves behind the Flagship per REQ-008's design,
and Dredger pressure joins the shelf. None of REQ-011's criteria depend on
them today, and the world is fully completable without them — by contract,
an absent optional element is a decision, not a gap.

## Verification

- `oax-level-check --target worlds/coral_cove` — contract conformance
- `oax-static-gate --target .` — sanctioned-surface analysis, same gate as a
  community submission
- `godot --headless --audio-driver Dummy --path . --script test/worlds/run_coral_walk.gd`
  — the full playthrough: both grammars, both mod gates, seven seeds spent,
  the snail rescued and persisted, the off-route shrimp untouched,
  restoration, finish, return, checkpoint spacing
