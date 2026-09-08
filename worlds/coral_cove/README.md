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

## Where it is

A forested river valley, seen from a route suspended in it. That is a
deliberate change from "platforms over open water", and the reason is
gameplay rather than scenery: a jump over nothing gives the player no way to
judge how high they are or how far they are going. The valley floor sits 24 m
below with ferns and fallen logs on it, canopy trees rise past the route and
close overhead, and the sides of the valley are visible in the haze. The
player can now see the drop they are jumping over.

**Water is the forgiving half of the level, and it is placed on purpose.**

* A **river runs under the whole tide shelf**, so a missed jump in act 1
  drops the player into water rather than onto the respawn. It flows
  downstream onto the route, so a miss costs the collectible above it and a
  stretch of swimming — never a life. Reeds mark that waterline; where there
  are reeds, the gap is survivable.
* The **grotto river** in act 4b is the opposite kind of water: a swim the
  route *requires*, dropped into the middle of a run of pillar jumps so the
  grammar switch lands while the player is still in a jumping rhythm.
* The **glow grotto's four pillars have no water under them at all**. That
  contrast is the difficulty curve stated in geometry rather than in a
  comment: the section that teaches is over a river, the section that tests
  is over a fall.

## Surfaces

Nothing here carries a colour of its own any more. Platforms wear one of the
client's shared procedural terrain materials
(`core/rendering/terrain_surface.gdshader`): triplanar world-space noise plus
a stratum term, sampled from world position on all three axes so no surface
needs UVs and the grain runs *across* the seam where two boxes meet. Moss is
a third colour applied to upward faces only, which is what makes the top you
land on read differently from the side you see across a gap.

The two mod gates are the deliberate exception — they keep a flat colour,
because a gate is a rule and not geology, and flat colour is the oldest
signal in the language for "this object obeys different rules".

## The route, in eight acts

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
4. **The glow grotto** *(the hard section, over open valley)*. The **Glow Gills pickup** and
   its bioluminescent false wall, which opens only while the equipped mod
   grants `reveal_bioluminescent`. Then four narrow pillars over open valley,
   two of them offset sideways so the jump has to be *aimed* and not merely
   timed. A **stray hook** waits on the third: an ordinary `hazard` that
   pops the axolotl's leg off with a sparkle and **never costs a life**.
   Then the **Bubble Gills pickup** and its gate (`bubble_platform`). Coral
   Cove gates on **Glow and Bubble**; Bubble Bay takes **Jet**, so the
   official pair covers all three MVP mods.
   The **lantern shrimp** hangs off this section on a side ledge the route
   never touches — the optional branch the reward layer exists for, and the
   walk asserts it stayed uncollected.
4b. **The gorge river** *(a swim between the jumps)*. The route drops off the
   grotto landing into a river running in a slot, ducks under a rock rib —
   the same dive act 2 taught, asked for again in a channel a quarter the
   width — and climbs out onto the first terrace. The slot walls are set six
   metres back from the landing's edge, which is twice the jump: there is no
   bank to hop along instead.
5. **The seed beds** *(restoration)*. Three descending terraces carrying the
   seven kelp seeds, with a Dredger over the entrance and a Runoff Drone on
   terrace two, — one `resource`-kind collectible, `kelp_seed`, declared
   once and placed seven times, each delivered to the shelf and *spent*
   (`restoration.*.resource_cost` overridden to 3+4 through the sanctioned
   `tuningOverrides`). Two of the seeds are out on side pillars that cost a
   jump each way. The **regen station** on the way in regrows the leg.
6. **The shelf**. Only a **restored** `coral_shelf` opens the wall, so
   restoration is on the critical path, not a side activity. Past it the
   valley drains toward open sea.
7. **The tide race** *(the water act)*. Two tide steps down to a waterline,
   then thirty metres of channel between two banks with a **surge bar**
   across it that has to be dived under, and a submerged sea shore to swim
   up onto at the far end. The **tide pearl** sits out on a perch in the
   middle of the channel, off the route like the lantern shrimp: the flown
   walk never collects it.

   It is also where the water is meant to be **looked at**. Acts 2 and 4b
   cross water at depth, under a brow and under an arch, where the surface
   is overhead and mostly out of frame. Here the route runs along the
   waterline with a bank either side, which is the one place in the level
   where the wave displacement, the surf against the shore and the splash
   going in are all in shot at once.

   Then the finish volume returns the player to the Open Lagoon, with
   completion recorded through the save-integration interface.

Under everything: one **pit volume**, sitting *between* the route and the
forest floor. Every gap the waterway does not run under is a real one —
falling costs a life and returns the player to the last checkpoint — and the
player watches the valley come up at them on the way, because the floor is
scenery and the pit is invisible.

## The Drift Fleet, and the fight ladder

Nine machines, and the route stops for eight of them. They used to stand six
to ten metres off the line the level is designed around while the longest
strike reached 2.3 m, so a player walking the route swam past all four and
never met one: the whole combat lane was decoration. The coral walk now
**fights** its way through, and a machine that drifts out of reach fails the
run rather than going quiet.

They climb in durability, and the level teaches each step before it asks for
the next:

| Act | Machine | Strikes | Why here |
|---|---|---|---|
| 2, the lagoon | `NetbotLagoonGap` | 1 | The first machine in the game. In water, where one spin sprint is both the escape from its net and the end of it — the cheapest possible place to learn that machines can be hit at all |
| 2, over RiseWall | `NetbotRiseWall` | 1 | The same lesson mid-climb, with somewhere to be |
| 4, the wall top | `HooklineGlowGate` | 2 | On land with Glow already in hand, so its line is visible: the counter and the fight in one beat |
| 4, ShrimpLedge | `HooklineShrimpLedge` | 2 | **Optional**, guarding the lantern shrimp. A reward worth a fight, never a toll |
| 4b, past the arch | `RunoffDroneGorge` | 3 | The first three-strike machine, fought from inside its own murk |
| 5, the seed-bed gate | `DredgerSeedBed` | 4 | The boss beat: the only machine that can spend a life, standing over the shelf it flattened |
| 5, terrace two | `RunoffDroneSeedBed` | 3 | Seeds here are gathered half blind until it is down |
| 7, the race channel | `NetbotTideRace` | 1 | One strike, in a current |
| 7, the sea shore | `RunoffDroneSeaShore` | 3 | The last machine, between the player and the final jump |

**The Dredger stands at the entrance to the seed bed, not inside it**, and
that is forced rather than chosen. Seven seeds at one resource each against
costs of 3 and 4 is exactly seven with no slack, and a Dredger reversion
zeroes a region's banked resources as well as its state — so a player who
touched this machine after collecting even one seed could never reach
`restored` again, and the shelf wall would stay shut with no way back. The
flown route found that in one pass. A world wanting a Dredger that threatens
work already done needs enough spare seeds to re-restore from barren after a
reversion: fourteen here, not eight.

## Checkpoints

Twenty-seven of them, which is far denser than the old corridor's five. A
platforming route is slower per metre than a walk, and REQ-003 AC-7 bounds
the replay from any anchor to the next by `progression.max_retry_seconds`
(5 s) — so climbs, dives and pillar detours each need an anchor of their
own. The coral walk **measures every segment** on the run rather than
trusting this paragraph; the two segments that first broke the bound are
why there is a checkpoint at the foot of the coral wall and another past
the second seed terrace. The tide race added two more the same way: laid
out with one anchor at each end it measured a **nine-second** replay
against the five-second bound, so there is now one on the last dry step
and one mid-channel. The fight ladder added four more for the same measured
reason: a fight is a place a player dies, and the lagoon swim, the gorge
exit and terrace two each held one more of them than a five-second replay
could carry.

## Declarations used

| Contract element | Used here |
|---|---|
| required: spawnPoint, checkpoints, finishCondition (`reach_volume`), saveIntegration, controllerCompatibility | yes |
| optional: restorableRegions | `coral_shelf`, gate `shelf_wall` opens at `restored` |
| optional: tuningOverrides | both restoration resource costs (sanctioned set) |
| optional: cameraHints | one hint volume over the grotto |
| optional: collectibles | `kelp_seed` (resource → `coral_shelf`), `hermit_snail` and `lantern_shrimp` (discovery) — Coral Cove is the world that exercises **both** kinds; Bubble Bay declares resources only |
| optional: enemies | all four Drift Fleet kinds, **nine machines** placed on the walked route; the coral walk fights eight of them |
| scene conventions: two `WaterVolume` bodies | the valley waterway (river into cove) and the gorge river |
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
