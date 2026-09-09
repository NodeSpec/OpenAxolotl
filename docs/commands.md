# Commands

The canonical command reference (REQ-018). CI runs the commands on this page
**character-identically** — that is the Validator CLI Invocation contract's
parity rule, and `tools/test_ci_pipeline.py` fails the moment this page and
`.github/workflows/pr.yml` disagree. Change a command here and in the workflow
together, or the suite tells on you.

## Build and run from a clean clone

Four commands, engine download included. Nothing else to install — the game
has no dependency a fresh Linux machine with `git`, `curl`, `unzip` and
`bash` lacks.

<!-- clean-clone-sequence -->
```sh
git clone https://github.com/NodeSpec/OpenAxolotl.git
cd OpenAxolotl
./scripts/build.sh
./build/linux/OpenAxolotl.x86_64
```

`scripts/build.sh` is the single build command: it fetches the pinned Godot
engine and export templates into `.toolchain/` (cached; subsequent builds
skip the download), imports the project, and exports
`build/linux/OpenAxolotl.x86_64` + `OpenAxolotl.pck` — the core game and
every world module under `worlds/`, manifests included. The harness executes
this exact sequence from a fresh clone (substituting only the clone URL for
the local repository) and boots the result headless; the sequence is
verified by running it, never by reading it.

## The repo validators

One-time setup (also part of `./scripts/setup.sh`):

```sh
python3 -m pip install -e .
```

The four validator commands. Each exits 0 on pass, 1 on violations, 2 on an
invocation error, and emits the shared Validator CLI result JSON with
`--format json`; CI runs these exact strings and publishes each JSON as a job
artifact.

<!-- ci-commands -->
```sh
oax-level-check --target . --format json
oax-asset-check --target . --format json
oax-static-gate --target . --format json
oax-test --target . --format json
./scripts/build.sh
```

Zero-install alternative (the checkers are standard-library Python on
purpose, so a contributor — or an AI agent verifying its own world — can run
them without installing anything):

```sh
python tools/level_contract_checker.py --target worlds/<your_world>
python tools/asset_contract_validator.py --target .
python tools/static_gate.py --target .
```

## Test suites individually

`oax-test` is an aggregator, not an owner: it runs exactly these documented
commands and merges their exit codes. Run any of them alone while iterating
(`godot` here is `.toolchain/godot` or your own pinned binary):

<!-- local-suites -->
```sh
python3 -m unittest discover -s tools -p 'test_*.py'
godot --headless --audio-driver Dummy --path . --script test/run_tests.gd
godot --headless --audio-driver Dummy --path . --script dev/run_smoke.gd
godot --headless --audio-driver Dummy --path . --script test/worlds/run_template_walk.gd
godot --headless --audio-driver Dummy --path . --script test/hub/run_hub_walk.gd
godot --headless --audio-driver Dummy --path . --script test/hub/run_fall_recovery.gd
godot --headless --audio-driver Dummy --path . --script test/worlds/run_coral_walk.gd
godot --headless --audio-driver Dummy --path . --script test/worlds/run_bubble_walk.gd
godot --headless --audio-driver Dummy --path . --script test/perf/run_perf_gate.gd
```

## World authoring

Four more commands rewrite a level's art without touching its game — the
terrain sheller, the prop scatterer, the dressing filler, and the gameplay
snapshot that proves the other three changed nothing. They are deliberate
passes, not part of `oax-test`, and they have their own page:
[docs/world-authoring.md](world-authoring.md).

```sh
oax-snapshot --target worlds/coral_cove > /tmp/before.json
oax-fill --target worlds/coral_cove
oax-snapshot --target worlds/coral_cove --compare /tmp/before.json
```

## Toolchain pin

The Godot version is pinned once, in `scripts/setup.sh` (currently
`4.3-stable`, the version the entire test evidence base was produced with).
The project targets Godot 4.7 (`project.godot` `config/features`); advancing
the pin is a deliberate act — rerun the full suite on the new engine, then
change that one line. CI caches the engine and export templates keyed on the
pin, so a version bump automatically invalidates the cache.


## Controls

Movement is CAMERA-RELATIVE: forward is wherever the camera is looking, not
world -Z. That is the other half of the look axis — a camera you can turn
while W still meant a fixed world direction would be worse than no camera
control at all.

| input | does |
|---|---|
| W A S D | move, relative to the camera |
| mouse / right stick | look — turn and pitch the camera |
| click | capture the mouse (Escape releases it) |
| Space | hop on land, swim up in water (hold for height) |
| Shift | dodge roll on land, swim down in water |
| E | climb on land, bubble boost in water |
| F | tail whack on land, spin sprint in water |
| C | dive (hold to keep descending) |
| Q | tongue grapple |
| right mouse | dash |
| left mouse / Tab / R | gill mod activate / next / previous |

Three of those are contextual pairs — `Shift`, `E` and `F` each mean one thing
on land and another in water — and none of them is a conflict, because a
binding is scoped to a movement grammar and the two never overlap. That is the
same rule that lets `W` be swim-forward and waddle-forward.

**Diving and surfacing are held, not tapped.** A dive eases into its speed
rather than snapping to it, and the model noses down into the descent and up
into a rise, so holding `C` is a dive and releasing it levels off.

**The two strikes are grammar-exclusive on purpose.** A tail whack plants four
feet and swings; a spin sprint is a body with nothing to push against turning
itself into the attack. See [docs/enemies.md](enemies.md) for what a strike
does to a machine.

The camera holds where you put it while you are moving. It eases back behind
your direction of travel only after `camera.look.assist_delay_seconds` of no
look input — if it followed travel continuously it would close a loop with
camera-relative movement and the two would spiral.

Sensitivity, pitch limits, invert and the assist are all `camera.look.*` keys
in `core/tuning/tuning.json`.
