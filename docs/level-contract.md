# The Level Contract v1

**A world is a folder.** Drop it in `worlds/`, and the hub finds it, validates it, and gives it a portal. Nothing else in the game needs to know your world exists.

This document explains the contract. The authority is `contracts/level_contract.v1.json` — if this page and that file ever disagree, **the file is right and this page is stale.** The file is what the compliance checker loads; this page is what explains why.

---

## Why a contract at all

You should be able to build a world without understanding the game. That is the whole premise, and it is what makes the project extensible by a human on a weekend and by an AI coding agent from a one-sentence brief.

A contract makes that possible in both directions:

- **For you**, it is a short list of what to provide. You never read the controller's source to find out what a checkpoint is.
- **For the project**, it is a thing a machine can check. Your world is validated before any human looks at it, so review is about whether your world is *good*, not whether it is *wired up*.

The corollary is that the contract is deliberately small. Every element below earns its place by being something the game genuinely cannot supply on your behalf.

---

## The shape of a world

```
worlds/coral_cove/
  world.json      required — the declaration
  world.tscn      required — the scene the hub instances
  *.gd            optional — statically typed GDScript, checked against the sanctioned API surface
  assets/         optional — art and audio, each with a provenance record
```

Your **world id** is the directory name: lowercase, digits and underscores, 3–32 characters, starting with a letter. `coral_cove` is fine; `Coral Cove`, `coral-cove` and `1cove` are not.

It is the directory name, the save-key namespace and the portal id all at once, which is why it is constrained. Renaming it later renames where your players' progress lives.

A world must **not** contain a `project.godot` or an `export_presets.cfg`. A module carrying those is trying to be a game rather than a part of one, and it would override project-wide policy the rest of the codebase depends on.

---

## The five required elements

### Spawn point

One node, in the Godot group `spawn_point`. Exactly one — two spawn points is not a richer world, it is an ambiguous one, and the hub would have to pick arbitrarily.

It lives in the **scene**, not the manifest, because it is a transform. A transform written into JSON drifts from the geometry it is supposed to sit on the first time you move a platform.

### Checkpoints

At least one node in the group `checkpoint`.

Checkpoints are **required, not optional**, and this is the one place the contract is stricter than it looks like it needs to be. They anchor two separate systems: a checkpoint refills the life count *and* restores capability state. A world without one has no defined answer to "the player ran out of lives, now what?"

Spacing is your judgement, not a conformance rule — but the intent is that replay time from any checkpoint to the next stays within `progression.max_retry_seconds`. Losing a life should sting, not punish.

### Finish condition

How your world ends and returns the player to the hub. Declared in `world.json`:

```json
"finishCondition": { "kind": "reach_volume" }
```

Four kinds, and only four:

| Kind | Completes when |
|---|---|
| `reach_volume` | The player enters a node in group `finish_volume` |
| `defeat_boss` | Your declared boss is defeated |
| `restore_all_regions` | Every declared restorable region reaches `restored` |
| `collect_all` | Every declared collectible is collected |

There is deliberately no `custom`. An open-ended kind would put completion logic back into world script, and completion is the one thing the hub must be able to trust without reading your code.

### Controller compatibility

```json
"controllerCompatibility": "1.0"
```

Which version of the Axolotl Controller Interface you built against. This is a **declaration, not a call** — your world never invokes the controller. The Game Client owns that wiring; you are telling it what you assumed.

### Save integration

```json
"saveIntegration": { "keys": ["coral_cove.shards_found", "coral_cove.gate_open"] }
```

Every save key you read or write, declared up front. Keys must begin with your world id and a dot, so two worlds cannot collide and a removed world's data stays identifiable.

An empty array is valid and means your world persists nothing. That is different from omitting the field: the first is a decision, the second is an oversight, and the checker treats them differently.

---

## The optional elements

Everything else. Each has a **defined default when absent**, which is what lets the reference template declare none of them and still be a complete, playable world — and what makes the template a live test that every default actually works.

| Element | When you omit it |
|---|---|
| `collectibles` | None; the collectibles system is not engaged |
| `enemies` | No Drift Fleet units spawn |
| `boss` | No Flagship encounter; the world stays fully completable |
| `customAbility` | Only the installed Gill Mods are available |
| `secretAreas` | None |
| `npcs` | None |
| `music` | The engine's default bed plays — never silence |
| `cameraHints` | Default framing for the active movement grammar |
| `restorableRegions` | No restoration progression |
| `tuningOverrides` | Every tuning value stays global |
| `livesPerAttemptOverride` | The global `progression.default_lives_per_attempt` applies |

Two notes worth reading before you reach for them:

**Camera hints are volumes, never code.** You place a hint volume and declare the framing it wants. There is no circumstance in which a world ships custom camera code.

**Tuning overrides are a closed set.** You may override only the keys enumerated in `core/tuning/tuning.json` under `worldOverridable` — currently the lives count and the two restoration resource costs. The contract *references* that list rather than copying it, so the two cannot drift apart. Movement, capability, camera and enemy tuning stay global, because a fork where the axolotl swims at a different speed is a different game, not a different world.

---

## What your world may call

The allowlist lives in `contracts/sanctioned_api.v1.json` and is enforced by the static-analysis gate as a merge-blocking check. Seven interfaces:

`Save Integration` · `Audio Event` · `Camera Hint` · `Gill Mod Registration` · `Enemy Registration` · `Collectible Registration` · `Restoration Region`

That list is **derived from the architecture graph**, not written by hand — it is exactly the set of interfaces the design gives world modules an edge to, and a test recomputes it from the model on every run. An earlier hand-written draft listed eleven, four of which the architecture never granted.

So some things you might reach for are **not** available, on purpose:

- **Raw input.** Worlds read player *intent*, never input. A path gated on a physical key could never be rebound, which would break remapping for every player of your world.
- **The controller.** You declare compatibility; you don't call it.
- **The tuning surface.** You declare overrides in your manifest.
- **The filesystem.** Persistence goes through save integration. Always.
- **Anything multiplayer.** No `@rpc`, no `MultiplayerSynchronizer`, no peers. This is single-player in every phase — a firm non-goal, not a deferral. Much of the Godot documentation you will find online assumes multiplayer; that guidance does not apply here.

If you genuinely need something excluded, the fix is to propose the architecture edge — not to widen the allowlist. A world that can only work by reaching outside this surface is evidence that an interface is wrong, not that your world is special.

---

## Versioning

Every world declares `"contractVersion": "1.0"`. A world targeting a version the running game does not support is refused by the hub and shown as an unavailable portal — never loaded partially.

**What can change within a version:** new *optional* elements. An absent optional element already has a defined default, so existing worlds stay conforming by definition.

**What increments the version:** adding a required element, removing an element, or narrowing a closed set.

When the version does increment, it ships with a migration note naming every changed element and the mechanical edit a v1 world needs. The previous version stays loadable for at least one release, so a fork has a window rather than a breakage.

**v1 is not frozen yet.** It freezes only after both official MVP worlds are built against it and their friction has been fed back in. Freezing now would encode what we imagined instead of what we needed.

---

## Checking your work

```
# validate a world against this contract
python tools/level_contract_checker.py --target worlds/<your_world> --format json

# check the sanctioned API surface
python tools/world_static_analysis.py --target worlds/<your_world> --format json

# the full test suite
godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
```

Both checkers exit non-zero on any violation and emit structured JSON naming the offending file, line, and the specific rule broken — so an AI coding agent can parse the output and self-correct before submitting.

> **Status:** the two Python checkers are REQ-007 and REQ-020 and are not built yet. The contract and the sanctioned surface they consume are complete, and the test suite command above works today. Until the checkers land, conformance is verified by reading `contracts/level_contract.v1.json` — which is exactly the situation this contract exists to end, so they are the next tools to build.

---

## Getting a human to merge it

Automated checks are a **pre-screen, not a merge path**. Passing them means a person will look at your world; it never means it merges on its own. That is deliberate and permanent: this is a family game accepting code from strangers and from agents, and the human gate is load-bearing.
