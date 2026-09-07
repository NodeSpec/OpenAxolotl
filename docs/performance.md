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
| hero (all five role meshes) | 5 | 29,632 |

Heaviest playable frame ≈ 129k triangles — an order of magnitude under
where a desktop GPU starts to care, which is the intent: the look comes
from silhouettes, shared procedural surfaces and two 1024² hero maps, not
from polygon counts. The perf gate now runs **twice** per chain — bubble_bay
and, via `OAX_PERF_WORLD=coral_cove`, the valley — flying the same waypoint
route the coral walk proves completability with, so the measured traversal
is the route that actually ships.
