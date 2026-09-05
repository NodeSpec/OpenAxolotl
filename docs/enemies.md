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
  "entangle": {
    "factorKey": "enemy.netbot.swim_speed_multiplier",
    "durationKey": "enemy.netbot.entangle_seconds",
    "target": "swim_speed",
    "escapeAffordance": "net_escape"
  }
}
```

`id`, `displayName`, `behavior` and `audioCueId` are always required, plus
one block named after the behavior:

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
