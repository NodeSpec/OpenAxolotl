# Bubble Bay

The second official world (REQ-028), and the deliberate opposite of Coral
Cove wherever the Level Contract offers a choice. Together the two official
worlds are the contract's battle test: what one exercises, the other omits.

## What this world proves on purpose

| Contract choice | Coral Cove | Bubble Bay |
|---|---|---|
| Boss | absent (framework unbuilt) | **absent by design** — REQ-028 AC-6 makes the optional-boss path an acceptance criterion, not a scope cut |
| `tuningOverrides` | overrides restoration costs to 3+4 | **absent** — the restoration economy runs on the contract's default costs (5+8 = thirteen pearls) |
| Gill Mods gated | Bubble + Glow | **Jet** — the one mod Coral Cove does not emphasize, so the official set requires all three MVP mods |
| Collectibles | both kinds: `kelp_seed` resources plus two discovery creatures | **resources only** — the `pearl` type placed thirteen times; no discovery collectibles, so nothing here is persisted by id and `collect_all` could never be its finish |
| Camera hints | one grotto hint volume | none — the default framing carries the whole route |

Like every world, Bubble Bay is manifest + scene with **no scripts**: every
mechanic is a scene-group + metadata declaration bound at runtime by the
game client's WorldSystems (see `docs/contract-friction.md` — these
conventions are logged as candidate contract elements for v1).

## The route

One straight line down −Z, drivable with a single held forward key, because
completability is a headless regression test (`test/worlds/run_bubble_walk.gd`):

1. **Spawn** on land (waddle grammar).
2. **The bay** — a water volume spanning the route; the water grammar is
   mandatory, and the far shore returns the land grammar. *(Checkpoint 1.)*
3. **Jet pickup → jet gate** — a wrecked trawl net that opens only while the
   equipped mod grants `jet_dash`. The gate spans the route: the Jet mod is
   mandatory. *(Checkpoint 2.)*
4. **Thirteen pearls** — one `resource`-kind collectible, `pearl`, declared
   once in the manifest and placed thirteen times; each is delivered to
   region `kelp_nursery` and spent at the default costs (5 to reach
   `resourced`, 8 more to reach `restored`).
5. **The nursery boom** — the region's declared traversal gate; opens only
   when `kelp_nursery` reaches `restored`. Restoration is mandatory.
6. **Finish volume** — `reach_volume` returns the player to the Open Lagoon
   with `bubble_bay.completed` written through the save interface.

## Contract declarations

| Element | Declaration |
|---|---|
| contractVersion | 1.0 |
| finishCondition | `reach_volume` |
| saveIntegration | `bubble_bay.completed` |
| restorableRegions | `kelp_nursery`, traversal gate `nursery_boom` opens at `restored` |
| checkpoints | 6, roughly every 10 m — the density REQ-003 AC-7's 5 s replay bound demands at waddle pace; the bubble walk measures every segment |
| collectibles | `pearl` (resource → `kelp_nursery`); no discovery kind |
| boss / enemies / customAbility / music | absent — defined defaults apply |

## Pending integrations

The Drift Fleet framework exists as a core node but is not yet declared
here. When it is, Bubble Bay is the natural home for Netbot encounters (the
Jet mod is their documented counter) — but it stays boss-free forever;
that is its half of the battle test.

## Verify locally

```sh
python tools/level_contract_checker.py --target worlds/bubble_bay
python tools/static_gate.py --target .
godot --headless --audio-driver Dummy --path . --script test/worlds/run_bubble_walk.gd
```
