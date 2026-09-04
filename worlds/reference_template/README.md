# Reference Template

**Copy this directory to start a new world.** That is the whole purpose of it.

```
cp -r worlds/reference_template worlds/my_world
```

Then change three things, and nothing else:

1. **The directory name.** It *is* your world id, and your save-key namespace,
   and your portal id. Lowercase letters, digits and underscores, 3–32
   characters, starting with a letter.
2. **`world.json`** — set `worldId` to match the directory exactly, set
   `displayName` to whatever you want players to read, and re-namespace every
   entry in `saveIntegration.keys` so each begins with your world id and a dot.
3. **`world.tscn`** — build your geometry, then move `Spawn`, `Checkpoint` and
   `Finish` into it.

Check your work before you open a pull request:

```
python tools/level_contract_checker.py --target worlds/my_world --format json
python tools/static_gate.py --target . --format json
```

Both exit non-zero on any violation and name the offending file, line and rule.

---

## What is here, and why so little

This template implements the **five required** Level Contract elements and
**nothing optional**:

| Element | Where it lives |
|---|---|
| Spawn point | `world.tscn`, one node in group `spawn_point` |
| Checkpoints | `world.tscn`, at least one node in group `checkpoint` |
| Finish condition | `world.json`, `finishCondition.kind` |
| Controller compatibility | `world.json`, `controllerCompatibility` |
| Save integration | `world.json`, `saveIntegration.keys` |

The minimality is deliberate and load-bearing. Every optional element has a
defined default when absent — no enemies spawn, no collectibles are engaged, the
engine's default music bed plays rather than silence — and because this template
declares none of them, those defaults are exercised by something that ships and
runs in CI on every pull request. It is the smallest possible proof that the
contract is satisfiable.

So **do not add an element here "for illustration."** A template carrying extras
would accidentally satisfy a newly required element and stop being the tripwire
it exists to be: a contract change that would break a minimal world has to fail
CI loudly rather than pass quietly.

## The three group names are the contract

The hub finds your nodes by **group**, never by node name. `spawn_point`,
`checkpoint` and `finish_volume` must keep those exact names; rename the nodes
themselves freely. Exactly one `spawn_point` — two is not a richer world, it is
an ambiguous one.

## There is no script here

A world is data and a scene. The game supplies the behaviour, which is why this
template passes the World Static Analysis Gate by calling nothing at all.

If your world does need script, it may call only the sanctioned world API
surface in `contracts/sanctioned_api.v1.json` — seven interfaces, and notably
**not** raw input, the controller, the filesystem, or anything multiplayer. See
`docs/level-contract.md` for what each one is for and why the excluded ones are
excluded.

## What must not be here

A world must never contain `project.godot` or `export_presets.cfg`. A module
carrying those is trying to be a game rather than a part of one, and it would
override project-wide policy the rest of the codebase depends on.

---

Passing the automated checks means a person will look at your world. It never
means it merges on its own — that human gate is deliberate and permanent.
