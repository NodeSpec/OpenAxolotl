# Performance targets

REQ-027. This page documents the baseline machine and the three numeric
targets. The numbers live twice on purpose: here as the prose authority,
and machine-readably in `contracts/performance_targets.v1.json`, which the
perf gate (`test/perf/run_perf_gate.gd`) loads as its source of truth —
`tools/test_performance_targets.py` fails the moment the two disagree, so
neither can drift.

## Why this game needs stated numbers

Restoration state changes swap **traversable geometry at runtime** —
potentially across a whole region — and Dredgers revert it mid-encounter.
That is a frame-time hitch waiting to happen at exactly the moment the game
delivers its most satisfying payoff. And the community pipeline needs a
number to check against: a world that tanks frame rate is a defect the
automated pre-screen should catch, which is impossible without a target.

## The baseline specification

A 2020-class mid-range family PC:

| Component | Baseline |
|---|---|
| CPU | 4 cores / 8 threads, x86-64 (Ryzen 3 3300X / Core i3-10100 class) |
| RAM | 8 GB |
| GPU | GTX 1650 / Radeon RX 570 class, 4 GB VRAM |
| Storage | SATA SSD |
| Display | 1920×1080 |
| OS | 64-bit Windows or Linux |
| Renderer | Forward+ (Vulkan) with the shared lighting rig; Mobile as the automatic fallback |

The look foundation — SDFGI, screen-space ambient occlusion, volumetric fog,
soft cascaded shadows, TAA with 2× MSAA — is what this baseline has to carry
at 60 FPS, and it is the first thing to scale back if a rendering run on
baseline-class hardware shows it cannot. Those knobs live in one place,
`core/rendering/base_environment.tres` and the `[rendering]` section of
`project.godot`; scaling back never touches a world.

## The three targets

| Target | Number | Meaning |
|---|---|---|
| Frame-rate target | **60 FPS** | Sustained during normal traversal of any official world on the baseline machine |
| Maximum frame-time spike | **50 ms** | No single frame may exceed this, including the frame in which a restoration state transition swaps region geometry |
| World load-time budget | **3000 ms** | From selecting a hub portal to the player standing at the world spawn with control |

## How the automated gate measures (and what it cannot claim)

`test/perf/run_perf_gate.gd` runs headless in CI as the `perf-gate` suite of
`oax-test`: it enters an official world through the hub, traverses it to
completion, and fails (exit 1) when any of the three targets is breached by
what it can measure:

- **Load time** — wall-clock from the `enter_world` call to the first
  physics frame with the player in the world. Checked against the 3000 ms
  budget directly.
- **Frame-time spike** — wall-clock delta between consecutive physics
  frames over the whole traversal, after a 60-frame settle. The single
  largest delta is discarded (one scheduler hiccup on a shared CI runner is
  noise, two are a hitch); the next-largest is checked against the 50 ms
  budget. The delta of the frame in which the restoration transition fired
  is additionally checked on its own — that specific frame is the REQ-027
  risk case and never gets the outlier discard.
- **Sustained rate** — physics frames divided by elapsed wall time across
  the traversal, checked against 60 FPS with a 5% pacing tolerance. This is
  recorded and enforced as a REGRESSION TRIPWIRE only: a headless CI
  container is not the baseline machine and renders nothing, so this
  measurement can catch a simulation-side collapse but can NOT prove the
  baseline frame-rate criterion. Proving "60 FPS on the baseline
  specification" requires a rendering run on baseline-class hardware, which
  no automated check in this repository has access to — that verification
  stays open, deliberately, rather than being claimed by proxy.

Run it alone:

```sh
godot --headless --audio-driver Dummy --path . --script test/perf/run_perf_gate.gd
```

## Changing a target

Change the number in `contracts/performance_targets.v1.json` **and** in the
table above (the parity test insists), in one commit, with the reasoning in
the commit message. The gate picks the new number up with no code change.


## Measured scene weight (2026-09-07)

Counted headlessly over the instanced scenes (indexed triangles), asserted
in `test/core/rendering/test_hero_surface.gd` against a 150,000 budget for
the heaviest world plus the hero:

| scene | mesh instances | triangles |
|---|---|---|
| Coral Cove (forested river valley, fully dressed) | 239 | 99,416 |
| Bubble Bay | 47 | 68,800 |
| Open Lagoon hub | 28 | 36,912 |
| hero (all five role meshes) | 5 | 34,392 |

Heaviest playable frame ≈ 134k triangles. **Triangle count is not what makes
this game slow, and an earlier version of this paragraph claimed otherwise.**
It said the scene was "an order of magnitude under where a desktop GPU starts
to care" — true about geometry, and irrelevant, because the cost is in the
per-pixel effect stack, not the vertex count. The honest statement is that
geometry is cheap here and the frame budget is spent almost entirely on
SDFGI, volumetric fog, SSAO, TAA and soft shadows. See **Graphics quality**
below. The look still comes
from silhouettes, shared procedural surfaces and two 1024² hero maps, not
from polygon counts. The hero grew by 4,760 triangles when it was
rebuilt against the maintainer's reference sheet — nearly all of it the
feathered gill blades, which is where a character's silhouette actually
lives and so the right place to spend them. The 150,000 assertion in
`test/core/rendering/test_hero_surface.gd` is what proves the spend
still fits, at every regeneration rather than at review time. The perf
gate now runs **twice** per chain — bubble_bay
and, via `OAX_PERF_WORLD=coral_cove`, the valley — flying the same waypoint
route the coral walk proves completability with, so the measured traversal
is the route that actually ships.


## Graphics quality (REQ-027)

### Why this section exists

The shared environment was tuned for a screenshot and shipped as the only
option: SDFGI at four cascades, volumetric fog with GI injection, SSAO, TAA
layered over 2× MSAA, and a 4096 directional shadow at the highest soft-filter
quality with a 1.5° sun. That is a stack a mid-range desktop cannot hold at
60 fps — and **no gate in the repo could see it**, because both perf gates run
`--headless`, which selects Godot's dummy rendering server. They measure
script and physics time and never rasterise a pixel. Their own docstrings say
so; the mistake was reading their "60 fps" as a statement about the frame rate
a player would get.

### The levels

`core/rendering/render_quality.gd`, applied by the shared rig
(`WorldLighting.set_quality`). **MEDIUM is the default** — a default a
mid-range machine cannot hold means the first thing a new player meets is
stutter, and most will never find the setting that fixes it.

| | LOW | MEDIUM (default) | HIGH (authored look) |
|---|---|---|---|
| SDFGI | off | off | 4 cascades |
| Volumetric fog | off | off | on |
| SSAO | off | radius 0.5, no detail | radius 1.0, detail 0.5 |
| Glow | off | on | on |
| Sun | point, 1 cascade, 45 m | point, 2 cascades, 80 m | 1.5° area, 2 cascades, 80 m |
| Shadow filter / atlas | hard / 2048 | soft-low / 2048 | soft-high / 4096 |
| AA | FXAA | 2× MSAA | 2× MSAA + TAA |
| 3D scale | 75% | 100% | 100% |

**Every level removes effects; none of them re-grades the picture.** Sky,
tonemap, exposure, fog colour and the sun's direction and energy are identical
at all three, because those carry "one world, one voice" — a quality level
that shifted them would make the game a *different game* on a slower machine
rather than the same game rendered more cheaply. `test_render_quality.gd`
asserts this.

SDFGI is off below HIGH rather than half-resolution because the expensive part
is **re-voxelisation**, not resolution: the cascades rebuild as the camera
travels, so a 128 m level pays continuously rather than once. That is also the
most likely source of stutter as opposed to a low but steady frame rate.

### Measuring it

`test/perf/run_gpu_gate.gd` — note the absent `--headless` — flies the camera
along the coral route and samples the viewport's own measured GPU time at each
waypoint, at all three levels. It is **opt-in** (`OAX_GPU_GATE=1`) because it
needs a display and takes minutes, not because it is optional to care about.

    OAX_GPU_GATE=1 OAX_GODOT=<godot> python3 tools/oax_test.py --target .

    # or directly, which is what you want on the machine you actually play on:
    <godot> --audio-driver Dummy --rendering-driver vulkan \
        --resolution 1920x1080 --path . --script test/perf/run_gpu_gate.gd

**What it asserts is the ORDERING**, not a millisecond figure: each level must
be at least 1.12× cheaper than the one above it. That is a property of the
levels themselves and holds on any rasteriser, so a change that makes MEDIUM
cost what HIGH costs fails on any machine. Absolute milliseconds are reported
and explicitly *not* gated — CI here rasterises through llvmpipe, a software
renderer, and treating its numbers as an fps figure would repeat exactly the
error this whole section corrects.

Measured on llvmpipe at 1280×720 (ratios meaningful, absolutes not):

| level | mean | p95 | worst |
|---|---|---|---|
| LOW | 94.5 ms | 134.1 ms | 146.9 ms |
| MEDIUM | 204.2 ms | 245.6 ms | 300.4 ms |
| HIGH | 471.5 ms | 533.6 ms | 560.0 ms |

**HIGH costs 2.3× MEDIUM and 5.0× LOW.** Since HIGH was previously the only
option, moving the default to MEDIUM should roughly halve GPU frame time.

### Changing it

There is no options screen yet — that is follow-up work, and it is where this
belongs. Until then `OAX_QUALITY=low|medium|high` overrides the default at
launch.
