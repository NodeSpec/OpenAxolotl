# Coral Cove

The first official world (REQ-011) — and, more importantly, the first
battle-test of the Level Contract. It is built with **no privileges an
outside contributor lacks**: a manifest, a scene, and nothing else. There is
no script in this module; every mechanic is a declaration the game client's
`WorldSystems` runtime binds. If you can read `world.json` and `world.tscn`,
you can build a world exactly like this one.

## Geometry comes from measurement

Coral Cove was a corridor: one straight line down −Z, completable with a
single held forward key. That was a real property worth having — it made
completability a headless regression test rather than a hope — but it had
quietly become the level's *design*. A route a held key can finish is a
route with no gaps, no climbs, and no reason to leave the ground.

So the route is a platforming route now, and the numbers it is built from
were **measured, not chosen**. The controller was driven headlessly through
the greybox against the shipped tuning:

| | measured |
|---|---|
| run speed | 4.20 m/s |
| standing jump | 1.81 m |
| running jump, edge to edge | 3.15 m |
| climb | 2.0 m/s, 6.0 m ceiling per wall |
| swim / bubble boost | 6.0 m/s, ×2.2 |

Every **mandatory** gap on the route is 2.6 m or less against that 3.15 m,
and every mandatory rise 1.2 m or less against that 1.81 m — comfortable,
but not free. Exactly one jump is built to the edge of the envelope, 1.6 m
of rise across 2.5 m, and it is the **optional** one, onto the lantern
shrimp's ledge.

None of that is enforced by this table. The coral walk flies the route
waypoint by waypoint, pressing the keys a player would press, and fails
naming the waypoint it could not reach. Retune the arc smaller and it says
so.

## The route, in six acts

1. **The tide shelf** *(land — run, jump)*. A rising staircase of four gaps
   on wide, forgiving platforms. The **hermit snail** — a *discovery*
   collectible, a rescued creature written to the profile the moment it is
   touched — sits on the third.
2. **The lagoon** *(water — swim, dive, boost)*. A `WaterVolume` the route
   drops into: water grammar in, land grammar out the far side. Two
   obstacles that cannot be swum straight through — a rock brow passable
   only *underneath*, then a shelf passable only *over*. Down, then up, in
   one crossing. The **bubble boost** is what makes it quick.
3. **The coral wall** *(land — climb)*. Four metres of climbable face,
   inside the 6 m ceiling. The block is both the wall and the platform above
   it, so cresting the lip ends the climb by simply running out of wall.
4. **The glow grotto** *(the hard section)*. The **Glow Gills pickup** and
   its bioluminescent false wall, which opens only while the equipped mod
   grants `reveal_bioluminescent`. Then four narrow pillars over open water,
   two of them offset sideways so the jump has to be *aimed* and not merely
   timed. A **stray hook** waits on the third: an ordinary `hazard` that
   pops the axolotl's leg off with a sparkle and **never costs a life**.
   Then the **Bubble Gills pickup** and its gate (`bubble_platform`). Coral
   Cove gates on **Glow and Bubble**; Bubble Bay takes **Jet**, so the
   official pair covers all three MVP mods.
   The **lantern shrimp** hangs off this section on a side ledge the route
   never touches — the optional branch the reward layer exists for, and the
   walk asserts it stayed uncollected.
5. **The seed beds** *(restoration)*. Three descending terraces carrying the
   seven kelp seeds — one `resource`-kind collectible, `kelp_seed`, declared
   once and placed seven times, each delivered to the shelf and *spent*
   (`restoration.*.resource_cost` overridden to 3+4 through the sanctioned
   `tuningOverrides`). Two of the seeds are out on side pillars that cost a
   jump each way. The **regen station** on the way in regrows the leg.
6. **The shelf**. Only a **restored** `coral_shelf` opens the wall in front
   of the finish, so restoration is on the critical path, not a side
   activity. Then the finish volume returns the player to the Open Lagoon,
   with completion recorded through the save-integration interface.

Under everything: one **pit volume**. Every gap on the route is real —
falling costs a life and returns the player to the last checkpoint.

## Checkpoints

Seventeen of them, which is far denser than the old corridor's five. A
platforming route is slower per metre than a walk, and REQ-003 AC-7 bounds
the replay from any anchor to the next by `progression.max_retry_seconds`
(5 s) — so climbs, dives and pillar detours each need an anchor of their
own. The coral walk **measures every segment** on the run rather than
trusting this paragraph; the two segments that first broke the bound are
why there is a checkpoint at the foot of the coral wall and another past
the second seed terrace.

## Declarations used

| Contract element | Used here |
|---|---|
| required: spawnPoint, checkpoints, finishCondition (`reach_volume`), saveIntegration, controllerCompatibility | yes |
| optional: restorableRegions | `coral_shelf`, gate `shelf_wall` opens at `restored` |
| optional: tuningOverrides | both restoration resource costs (sanctioned set) |
| optional: cameraHints | one hint volume over the grotto |
| optional: collectibles | `kelp_seed` (resource → `coral_shelf`), `hermit_snail` and `lantern_shrimp` (discovery) — Coral Cove is the world that exercises **both** kinds; Bubble Bay declares resources only |
| optional: enemies | four Drift Fleet units, all placed **off** the walked route |
| optional: boss, music, npcs, secretAreas, customAbility | **not declared** — absent defaults apply |
| scene conventions: `pit_volume`, `hazard`, `regen_station`, `climbable` | one pit under the whole world; one leg-stripping hook; one station; one climbable wall |

Scene-group conventions bound by the runtime (`gill_mod_pickup`,
`affordance_gate`, `collectible`, `restoration_gate`, `checkpoint`,
`pit_volume`, `hazard`, `regen_station`, `enemy`, `climbable`) are recorded
in `docs/contract-friction.md` as candidates for Level Contract elements
before the v1 freeze — they are conventions today, and pretending otherwise
would hide exactly the friction REQ-011 exists to surface.

## Pending integrations

The Drift Fleet units are placed (REQ-036); the **Flagship** is not. When it
is, Coral Cove is where the boss path gets proven (Bubble Bay declares
none): the `boss` element gets declared and the shelf's unlock moves behind
the Flagship per REQ-008's design. None of REQ-011's criteria depend on it
today, and the world is fully completable without it — by contract, an
absent optional element is a decision, not a gap.

## Verification

- `oax-level-check --target worlds/coral_cove` — contract conformance
- `oax-static-gate --target .` — sanctioned-surface analysis, same gate as a
  community submission
- `godot --headless --audio-driver Dummy --path . --script test/worlds/run_coral_walk.gd`
  — the full playthrough, flown by `RoutePilot` through the real key path:
  every jump, the dive, the boost and the climb; both grammars; both mod
  gates; seven seeds spent; the snail rescued and persisted; the off-route
  shrimp untouched; the leg lost to the hook and regrown at the station with
  no life spent; every checkpoint activated by touch; restoration, finish,
  return, and checkpoint spacing measured against the bound
