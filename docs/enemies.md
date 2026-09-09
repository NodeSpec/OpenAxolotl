# The Drift Fleet — enemy roster and extension interface

REQ-012. The antagonist faction is **faceless industrial extraction
machinery**, deliberately not human characters: nets, hooks, dredging and
pollution stay as gameplay hooks without making a real profession the
villain, and the machinery that broke the habitat is exactly what the player
disables to heal it.

Every enemy is designed **against a specific core system**, never as a
generic damage-dealer — and every counter is something the player owns:

| Enemy | Attacks | Through which seam | Counter |
|---|---|---|---|
| **Netbot** | Ghost net entangles, multiplying swim speed by `enemy.netbot.swim_speed_multiplier` for `enemy.netbot.entangle_seconds` | Capability Modifier Interface (its own `drift:` namespace) | **Jet Gills** — an active `net_escape` window refuses the entanglement, and opening it mid-net releases immediately |
| **Hookline Rig** | Snags the equipped Gill Mod for `enemy.hookline.mod_strip_seconds`, then it returns automatically | `GillModSystem.snag()` (the restore timer lives there — a despawned rig cannot strand the player) | **Glow Gills** — `reveal_hookline` reveals the line *before it triggers*, so the player routes around it; revealing does not disarm |
| **Dredger** | Reverts a restored region to barren (real geometry closes; the unlock survives). Its **area wipe** decrements a life | `RestorationSystem.dredger_attack()`; `LifeSystem.report_catastrophe("dredger_area_wipe")` | Restoration can be redone without refighting anything; the wipe is the game's telegraphed catastrophe |
| **Runoff Drone** | A toxin aura: vision × `enemy.runoff.vision_debuff_factor`, gill recharge × `enemy.runoff.gill_recharge_multiplier`, lingering `enemy.runoff.duration_s` after leaving | Published factors: `vision_factor()` for presentation, `scaled_mod_delta()` for whoever ticks the Gill Mod system (only the COOLING phase slows) | Leave the water — land routes read as the favorable path |

The **only** enemy lane that can cost a life is the Dredger's area wipe, and
only because its declaration names a source inside `CatastrophicSource`'s
closed set. Every other behavior has no field for a catastrophic source at
all — REQ-003's "ordinary contact never decrements lives" stays structural
with an open roster.

## Hitting back

Every lane above used to run one way: the machines acted, and the player's
only answer was to route around them. Three strikes now answer them, and each
one is a thing the player already knows how to do rather than a new weapon:

| Strike | Where | How | Reach |
|---|---|---|---|
| **Tail whack** | Land | The land strike verb (`F` / right shoulder) — plants the feet and swings the longest part of the animal | `combat.tail_whack.reach_m` |
| **Stomp** | Land | Land on the machine from above. No button: the oldest verb in the genre, and the first thing a player tries | `combat.stomp.reach_m` |
| **Spin sprint** | Water | The water burst verb (`F` / right shoulder) — underwater there is nothing to plant your feet against, so the body becomes the attack | `combat.spin_sprint.reach_m` |

### How many strikes a machine takes

**Durability is roster data.** Every declaration carries a `durability` — the
number of strikes that puts the machine down — and the runtime reads it rather
than knowing it, so a forked world ships a machine with its own weight without
touching a line of core code. The field is optional and defaults to `2`;
declaring anything outside 1–6 is **refused, not clamped**, because a roster
asking for zero hits wants a machine that is already beaten when the level
loads and one asking for fifty wants an invincible one, and both are far
likelier to be a typo than an intention.

The shipped ladder is a spread rather than a curve, so the four machines read
as four different problems:

| Machine | Durability | Why |
|---|---|---|
| **Netbot** | 1 | The lightest unit, and its entangle is the most frustrating thing to be caught by mid-swim. A single answer is the right answer |
| **Hookline Rig** | 2 | Static and telegraphed; two hits is enough to make approaching it a decision |
| **Runoff Drone** | 3 | Fought from inside its own debuff, so the exchange is longer by construction |
| **Dredger** | 4 | The only machine that can cost a life, and the only one that changes the level. It should be the wall |

**A strike short of durability STAGGERS; the one that reaches it DEFEATS.**
Both release whatever the machine was already doing to the player on the spot —
so the swing that lands on a Netbot is also how you get out of its net — and
both refuse every effect lane while they hold. The difference is what happens
next: a staggered machine reels for `enemy.stagger_seconds` and then works
again, and a defeated one stays down. A staggered machine can be struck again,
which is what lets a durability-4 Dredger go down in one exchange rather than
four separate approaches.

**Defeat is a knock-out that stays down, not a destruction, and it lasts for
the ATTEMPT.** Two constraints meet here and both are deliberate:

* These are **machines being knocked over**, not things being killed. REQ-019
  AC-5 forbids depicting violence done to anything that reads as alive, and
  nothing here has hit points, health, or a death. A defeated machine is tipped
  over in place and half sunk — visibly beaten, still a landmark.
* A level a player can permanently empty **stops being a route problem** the
  second time they walk it. So a checkpoint respawn calls
  `DriftFleetSystem.reset_defeats()` and the whole roster stands back up,
  partial damage included: the stretch that killed you is a stretch you fight
  through again.

A stomp pays a bounce (`combat.stomp.bounce_m_per_s`), deliberately set below
the hop impulse: it rewards landing the hit without making machines the best
way up.

The strike itself carries no scene. The controller opens a window and says how
far it reaches; `WorldSystems` decides which placed machines are inside that
reach — the same division the tongue grapple already uses for anchor
discovery, and what lets the whole combat lane be tested without a physics
world.

## The extension interface

Enemies are **declarations, not scripts** — the same shape as Gill Mods. The
four shipped enemies live in `core/enemies/roster/*.json` and are discovered
by `EnemyRegistry.load_directory()`, the identical code path a new enemy
takes: drop a JSON file in the roster directory (or `register()` a
declaration held in memory). No file in the enemy system core changes.

A declaration:

```json
{
  "id": "netbot",
  "displayName": "Netbot",
  "behavior": "entangle",
  "audioCueId": "enemy_netbot_entangle",
  "durability": 1,
  "entangle": {
    "factorKey": "enemy.netbot.swim_speed_multiplier",
    "durationKey": "enemy.netbot.entangle_seconds",
    "target": "swim_speed",
    "escapeAffordance": "net_escape"
  }
}
```

`id`, `displayName`, `behavior` and `audioCueId` are always required, plus
one block named after the behavior. `durability` is optional and defaults to
`2` — a middle-of-the-range number that is obviously a default, so a machine
that lost the field is neither a free kill nor invincible:

| `behavior` | Block | Required fields |
|---|---|---|
| `entangle` | `entangle` | `factorKey`, `durationKey`, `escapeAffordance`; optional `target` (`all` \| `swim_speed` \| `waddle_speed`, default `all`) |
| `snag` | `snag` | `revealAffordance` |
| `dredge` | `dredge` | `areaWipeSource` — must be an id from `CatastrophicSource`'s closed set |
| `toxin_aura` | `toxinAura` | `visionFactorKey`, `rechargeFactorKey`, `durationKey` |

The behavior set is **closed on purpose**. Each behavior binds a seam a core
system publishes; an open "run my script" behavior would hand content the
unverifiable power the sanctioned world API surface exists to deny. A new
*behavior* is a core change with tests; a new *enemy* on an existing
behavior is a JSON file.

Validation at registration (all failures are named `EnemyError`s with stable
dotted codes):

- every cited tuning key must exist in the live tuning surface — a
  misspelled key fails at load, not at first contact;
- `areaWipeSource` outside the catastrophic closed set is refused
  (`enemy.unsanctioned_catastrophe`);
- `durability` outside 1–`EnemyDef.MAX_DURABILITY` (6), or not a whole number,
  is refused rather than clamped (`enemy.missing_field`);
- duplicate ids, unknown behaviors and missing fields are refused.

## Worlds and enemies

A world declaring **no enemies remains contract-valid and fully
completable** (REQ-012 AC-6) — the reference template and both official
worlds prove this every run: none declares an enemy, all pass the checker,
all complete headlessly. When the Level Contract's optional `enemies`
element gains scene-binding conventions (see `docs/contract-friction.md`
F-1 for the pattern), Bubble Bay is the planned home for Netbot encounters —
the Jet mod it gates is their documented counter.

## Verify locally

```sh
godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
```

The Drift Fleet suite is `test/core/enemies/test_drift_fleet.gd`.
