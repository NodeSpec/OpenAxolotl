# Hero rig audit (REQ-002 AC-9)

Audited and rebuilt 10 November 2026 on `claude/hero-rig-rebuild`, against the
hero as it stood at `codex-branch` b243aa5, on Godot 4.7.2.

**Status: audited, replaced, awaiting the owner's approval.** AC-9 is a manual
criterion. This document is the evidence for it; the approval is not the
author's to give.

## What the criterion asks

> Audit and approve the production rig, skin weights, clip coverage and
> contact chains; document whether each limb supports planted-foot solving and
> replace the current one-joint limb limitation before promising full foot
> locking.

In order: what the rig was, what was wrong with it, what replaced it, what each
limb can now do, what the clips cover, and what is still not true.

## 1. The rig as found

Twelve bones — `root`, `spine`, `head`, two gills, four legs, three tail
segments — with **one bone per leg**, written by `tools/blender/rig_model.py`
and fitted to the Meshy sculpt by `tools/blender/fit_hero_rig.py`.

A one-bone leg holds its foot at a fixed distance from its pivot, so the foot
can only move on a sphere. It cannot stay on a point of ground while the body
travels over it, which is what a planted foot is. `HeroMotion._place_foot`
said so in its own comments and capped its correction at 0.38 rad.

That limitation was known. Two defects underneath it were not.

**The skin did not follow the skeleton.** The fitter mirrors left and right
limbs; the sculpt is not mirrored. It is frozen mid-stride, the front-left foot
reaching forward under the head while the front-right stands out to the side.
Bone-heat weighting against that mirrored skeleton handed the real front-left
foot to whatever bone was nearest. Measured on the shipped file, share of each
sole's skin weight by bone:

| sole | own leg | head | gill | spine / root |
|---|---|---|---|---|
| front-left  | **28%** | **57%** | 10% | 6% |
| front-right | 75% | 13% | 6% | 6% |
| hind-left   | 100% | – | – | – |
| hind-right  | 98% | – | – | 2% |

The front-left foot swung when the head turned and barely moved when its leg
stepped. Vertices led by each leg bone ran from 176 (front-left) to 1,799
(front-right), a tenfold asymmetry on limbs that are the same size, and 7,977
vertices of head, gills and trunk carried stray leg weight.

**The cadence asked for four times what a leg can reach.** The walk ran at
`speed / 1.2` cycles per second with each foot down for 62% of the cycle, so
each foot was asked to hold still across 0.74 m of body travel. The legs are
0.11–0.14 m long. No correction closes that gap.

### Measured, before

`tools/hero_gait_probe.gd` drives the real game with real input and samples the
skeleton after every modifier has run. *Slide* is how far the feet travel over
the ground while within 3 cm of it, divided by how far the body travels in that
same contact time: 1.0 is a foot glued to the body, 0.0 a foot glued to the
ground.

| speed | slide | notes |
|---|---|---|
| 0.86 m/s | 0.715 | front-left foot never within 3 cm of the ground; lowest 7.1 cm |
| 2.14 m/s | 0.574 | same |
| 4.17 m/s | 0.583 | same |

## 2. What replaced it

`tools/extend_hero_rig.py` (`oax-extend-rig`), pure standard-library Python on
the GLB. For each leg it:

- measures distance from the sole **along the mesh surface**, so a gill a few
  centimetres from a foot in a straight line is a long walk away over the skin;
- finds where the limb ends by its own thickness — rings of equal distance stay
  narrow along the shaft and widen where the leg meets the body;
- adds four bones under the existing one: `upper_xx` at the shoulder or hip,
  `shin_xx` at mid-shaft, `foot_xx` at the ankle, `toe_xx` (unweighted) on the
  ground contact;
- rebinds the limb to that chain, blends into the body's existing weights
  across the shoulder, and strips leg weight from everything else.

The rig is now **28 bones**. The twelve originals keep their names, parents,
rest transforms and bind matrices exactly; positions, normals, UVs, materials
and all nine clips are byte-identical. No clip gained a channel.

| leg | sole on own foot bone | upper | lower | limb (world) | buried pivot → real shoulder |
|---|---|---|---|---|---|
| front-left  | 28% → **100%** | 0.127 | 0.143 | 0.135 m | 0.300 |
| front-right | 75% → **100%** | 0.122 | 0.138 | 0.130 m | 0.197 |
| hind-left   | 100% → **100%** | 0.108 | 0.125 | 0.117 m | 0.207 |
| hind-right  | 98% → **100%** | 0.101 | 0.122 | 0.111 m | 0.089 |

Lengths are in the model's units except where marked; the body scene shows the
model at 0.5.

The last column is why `upper_xx` exists. The first version of this tool hung
the shin straight off `leg_xx` and solved from there. On the front-left leg
that made one bone of 0.43 and one of 0.13, which cannot fold closer than 0.30:
a foot placed under the body went 2 cm through the floor instead. The gait
probe caught it. Solved from the real shoulder the two bones are near equal and
the limb folds like a limb.

## 3. What each limb supports

All four limbs now support planted-foot solving. `HeroMotion` solves each as a
two-bone chain from `upper_xx` to `foot_xx` with an analytic solver
(`HeroMotion.solve_leg`), places the foot flat, and keeps it on a fixed point
of the world for as long as the leg reaches.

*Planted span* is the length of ground, centred on where the foot stands, that
the leg can reach from walking height (`HeroMotion.planted_span`):

| leg | planted span |
|---|---|
| front-left  | 0.136 m |
| front-right | 0.140 m |
| hind-left   | 0.178 m |
| hind-right  | 0.139 m |

The walk is timed from that (`HeroAnimator.STANCE_TRAVEL = 0.16`,
`gait_cadence`, `gait_duty`): slow, the animal steps exactly as often as it
takes to keep each stance inside the reach; from about 1.4 m/s the cycle caps
at 5 per second and becomes a scurry, with feet touching briefly and spending
most of the cycle in the air. A foot that runs out of reach is lifted, never
dragged.

A rig without the new bones takes the old path unchanged: the one-bone
correction, at the old cadence.

### Measured, after

Same probe, same route, same threshold.

| speed | slide before | slide after | notes |
|---|---|---|---|
| 0.86 m/s | 0.715 | **0.105** | all four feet reach the ground, at every speed |
| 2.14 m/s | 0.574 | **0.125** | |
| 4.17 m/s | 0.583 | **0.222** | |

A frame-by-frame trace of the same walk shows no foot moving at all between
consecutive frames while it is in stance: 0.0000 m at its largest, over 139,
99 and 59 stance samples at the three speeds. What the remaining slide figure counts is the first and last frame of
each swing, when the foot is under 3 cm but already or still moving. It is
reported as measured rather than re-thresholded away.

**What may be promised:** a foot on the ground does not move over it.
**What may not:** that a foot stays down for the whole nominal stance at speed.
Above the cap it cannot; that is leg length, and the gait says so by lifting.

## 4. Clip coverage against REQ-002's transition table

| state | what plays | verdict |
|---|---|---|
| idle | `idle` clip; feet hold a fitted, mirrored stance | covered |
| start | no clip. Acceleration lean; feet step off by gait phase | procedural only |
| travel | `waddle` clip for the body, placed feet for the legs | covered |
| turn | no clip. Heading easing, bank, head lead, tail follow-through; standing feet re-step in diagonal pairs | procedural only |
| stop | no clip. A foot caught mid-step finishes to its stance in 0.14 s | procedural only |
| jump | `hop`, with squash and stretch | covered |
| fall | `fall` | covered |
| land | no clip. Landing squash, two footfall puffs, feet re-take the ground over 0.10 s | procedural only |
| swim | `swim` plus the travelling body wave; limbs paddle about their shoulders with a folding shin | covered |
| surface | nothing dedicated: the 0.20 s cross-fade into and out of `swim` | **gap** |
| dive | nothing dedicated: same cross-fade | **gap** |
| attack | `whack` on land, `spin` in water, `roll` dodge, all rewritten at load; feet follow the clip | covered |
| capture | no clip in the animator's table; the body tracks the state and shows UI | **gap** |
| dance | `dance`, generated at load; the modifier stands down for it | covered |
| reset | `HeroAnimator.reset` and `HeroMotion.reset_pose` clear actions and foot state | covered |

Also present and not in the table: `hurt`.

Whether procedural-only is acceptable for start, turn, stop and land is a
judgement for the AC-10 reel. Surface, dive and capture have no authored
motion at all.

## 5. What is still not true

- **The bind pose is asymmetric and the chains inherit it.** The front-left
  shoulder sits 0.16 further forward than the front-right; the hind-left limb
  leaves the body 0.34 from the centreline and the hind-right 0.17. Stances are
  mirrored at runtime, but the limbs differ in length by a fifth and the
  hind-right has the least reach. A hero exported in a neutral, symmetric pose
  would remove this at the source and is the recommended next step for the
  asset.
- **Clips still key `leg_xx`,** the pivot buried in the body. `HeroMotion`
  hands that rotation to `upper_xx` every frame so the limb turns where it is
  attached. The dance is the exception: the modifier stands down for it, so
  dancing legs still swing about the buried pivots.
- **The shoulder blend is narrow** — 0.12 units between limb and body. It was
  inspected in the close-up frames from one low side camera, standing, walking,
  scurrying and treading water, and no tearing was seen. It was not inspected
  from below or head-on.
- **Flat ground only.** The probe route is level sand. Ground height under a
  foot is read one physics tick late; behaviour on steps, ledges and steep
  slopes was not measured.
- **Moving ground was not tested.** Foot placement uses velocity relative to
  water flow; platforms that carry the animal were not exercised.
- **`tools/hero_review.gd` cannot reach its swim section.** It fails on a
  missing `Waterway` node in the Living Cascade, on the untouched branch as
  well as on this one, so its swim and spin checks do not run. Not changed
  here; the swim frames for this work come from `tools/hero_feet_review.gd`.
- **Fast swimming was checked by measurement, not by eye.** Treading water
  was inspected in close-up. At full swim speed each limb's shoulder-to-toe
  direction was printed against the direction it is aimed in and agrees to
  within a few hundredths. The close-up of it is half hidden: the animal swims
  into a bank that cuts across the camera, so only the hind limbs are seen.
- **Actions are not placed.** During a tail whack, roll, spin, flinch or dance
  the feet follow the clip, as they did before, and re-take the ground when it
  ends. Planting them through the whack's hip swing was tried and stretched
  the legs.
- **Promised and not done in this pass:** longer spine and tail chains, and
  authored clips for start, stop, turn, land, surface and dive.

## 6. If your checkout still has the twelve-bone model

The rebuilt model is one commit, the code and tests another, because the
session that made them could not reach the Git LFS endpoint to upload the
model. If `oax-extend-rig --check` fails on your checkout, regenerate it:

```
oax-extend-rig --input assets/character/axolotl/axolotl.glb \
               --output assets/character/axolotl/axolotl.glb
```

The result is byte-for-byte the audited file (sha256 `da916c87…cc2b4f`,
3,505,800 bytes). Until then the game runs exactly as it did before this work
— the new code on the old model reproduces the "before" slide figures above to
the last digit — and the tests that describe the rebuilt rig fail: six in the
hero suites and one in `tools/test_extend_hero_rig.py`.

## 7. Evidence, and how to reproduce it

```
python3 -m unittest tools.test_extend_hero_rig          # 13 tests, the rig tool
oax-extend-rig --input assets/character/axolotl/axolotl.glb --check
godot --headless --audio-driver Dummy --path . --script test/run_hero_tests.gd
godot --headless --path . --audio-driver Dummy --fixed-fps 60 --script tools/hero_gait_probe.gd
godot --path . --audio-driver Dummy --fixed-fps 60 --script tools/hero_feet_review.gd
```

- `tools/test_extend_hero_rig.py` — the tool on a synthetic animal with the
  same defect (a sole bound to the wrong bone): chain added, soles owned, body
  freed of leg weight, originals and clips untouched, idempotent, refuses an
  animal with no feet. One test pins the shipped hero to the tool's output.
- `test/core/rendering/test_hero_legs.gd` — the imported rig carries the
  chains; every sole follows its own foot on the mesh the renderer gets; the
  solver keeps bone lengths and reaches or clamps honestly; the cadence never
  asks for more than `STANCE_TRAVEL`; every leg's planted span covers at least
  80% of it; a rig without leg joints keeps its old walk.
- Hero suites (`test/run_hero_tests.gd`): 40 passed, 0 failed before this
  work; 49 passed, 0 failed after.
- Full Godot suite (`test/run_tests.gd`): 636 passed, 6 failed before; 645
  passed, 6 failed after. The six are the same six, none in this work's
  files: three in `test_striking_back`, and one each in `test_regen_system`,
  `test_hero_surface` (scene triangle budget) and
  `test_coral_cove_composition`.
- Python tools (`python3 -m unittest discover -s tools -p 'test_*.py'`): 194
  run, 6 failures and 3 errors, 7 skipped. All nine come from files this work
  did not touch — `project.godot`, which the static gate cannot parse, the
  asset validator's 71 findings in other asset folders (none in the hero's),
  and six oversized textures. That suite was not run on the untouched branch,
  so "already failing" is read from the causes, not from a before-run.
