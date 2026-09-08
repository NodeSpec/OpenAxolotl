# World authoring tools

Four command-line tools rewrite a level's ART without touching its GAME. They
are how the greybox that the route probes fly becomes a place worth being in,
and they exist as tools rather than as an editor session so that the change is
reviewable, repeatable, and available to an agent working headless.

None of them is part of `oax-test`. They are run deliberately, by a person or
an agent doing a visual pass, and their output is a scene diff you read.

| tool | command | what it writes |
|---|---|---|
| terrain sheller | `oax-shell` | organic shells over greybox collision proxies |
| prop scatterer | `oax-scatter` | hand-placed props collapsed into MultiMeshes |
| dressing filler | `oax-fill` | generated filler density, as MultiMeshes |
| gameplay snapshot | `oax-snapshot` | nothing — it is the proof the other three changed no gameplay |

```sh
python tools/shell_terrain.py     --target worlds/<world> [--dry-run]
python tools/scatter_props.py     --target worlds/<world> [--dry-run]
python tools/fill_dressing.py     --target worlds/<world> [--dry-run]
python tools/gameplay_snapshot.py --target worlds/<world> [--compare before.json]
```

Every one takes `--format json` and exits `0` on success, `1` on a refusal or
a difference, `2` on an invocation error — the same shape as the four repo
validators, so a script can read them the same way.

## The rule all four serve

**A visual pass may not change the game.** Collision geometry, spawn and
checkpoint markers, water volumes, gates, enemies and collectibles are the
level; everything else is how it looks. A stray transform on a `StaticBody3D`
moves a platform the route was measured against and nothing about the render
looks wrong — and the walk probes will not catch it, because the error a
visual pass makes is ten centimetres, not ten metres.

So the pass is bracketed:

```sh
python tools/gameplay_snapshot.py --target worlds/coral_cove > /tmp/before.json
python tools/fill_dressing.py --target worlds/coral_cove
python tools/gameplay_snapshot.py --target worlds/coral_cove --compare /tmp/before.json
```

An empty diff is a proof, not an assurance. `tools/test_gameplay_snapshot.py`
is what makes that sentence worth anything: it holds the snapshot to catching
a platform that moved 0.1 m, a collider resized behind an unchanged
sub-resource id, a deleted checkpoint, and a marker that lost its group —
because a comparison that cannot fail would make the other three tools' proofs
worthless at the same time.

## Two kinds of dressing, and why both

This is the distinction that took two failed passes to find, so it is worth
stating plainly. Two requirements pull in opposite directions and a level
needs both:

* **REQ-011 wants LANDMARKS** — named, hand-placed clusters, one per traversal
  beat, so a contributor can reason about composition by reading the scene.
  `OpeningTreeLeft` is a decision about where the player's eye goes.
* **REQ-034 and REQ-027 want DENSITY, in MultiMeshes** — a valley reads as a
  valley because there is a lot of it, and the cost of a lot of it is
  per-OBJECT. Hundreds of individual instances spend the frame budget on the
  fact that there are many plants rather than on there being much plant.

They are only in conflict if one tool is asked to do both jobs. Landmarks are
authored, stay individual instances, and are nobody's to generate. Filler is
generated, is nobody's decision individually, and belongs in a MultiMesh.
`oax-fill` writes only the second kind and never touches the first.

## Running them twice

All three writing tools are run more than once in practice — a kit is
regenerated, a platform moves, the budget changes. Each has a rule for it, and
each rule exists because the tool once did the wrong thing:

* **`oax-fill` rewrites.** It removes the fields a previous run left before
  writing new ones, so a second run produces a byte-identical scene. Without
  that it appended: Coral Cove went from six filler fields to twelve to
  eighteen, doubling and tripling the filler while every report said it had
  written 112 instances.
* **`oax-shell` skips.** A body that already carries a `Shell` child is left
  alone. Without that a second run added a second shell to every body and a
  second `visible = false` to every proxy — thirty-two shells became
  sixty-four.
* **`oax-scatter` refuses.** Once a world carries scatter fields, the
  individual instances still under `Dressing` are the landmarks somebody
  KEPT. A second run cannot tell a kept landmark from an unconverted prop,
  and it ate them: twenty-four named clusters in Coral Cove became eight
  anonymous fields, exit 0, no warning. It now stops with
  `scatter.landmarks_kept` unless `--collapse-landmarks` says that is really
  the intent.

## Where filler is allowed to be

`oax-fill` places on platform tops only, and its refusals matter more than its
placements:

| rule | constant | why |
|---|---|---|
| clear of gameplay | `GAMEPLAY_CLEARANCE` 3.2 m | dressing that hides a collectible is worse than no dressing |
| clear of landmarks | `LANDMARK_CLEARANCE` 2.6 m | the composition beats keep the silhouette they were placed for |
| inset from the edge | `EDGE_INSET` 0.9 m | vegetation over a ledge tells the player the edge is somewhere it is not, in a game about reading edges |
| big enough to dress | `MIN_PLATFORM_AREA` 12 m² | a prop on a 2×2 step is bigger than the thing it stands on |
| within the frame budget | `--triangle-budget`, default 18,000 | the densities are a SHAPE, not a count |

That last one is the one to understand before changing a density. Left to
themselves the six palette densities place 638 instances in Coral Cove — about
99,000 triangles, against a whole-scene ceiling of 150,000 that the dressed
valley and the hero already spend 126,000 of. Hand-tuning six numbers until
the total happened to fit would be six numbers nobody could re-derive, and
they would stop fitting the first time a kit was regenerated at a different
resolution. So placement is generated at the density the LOOK wants and then
thinned to what the frame can afford, measured from the props' own glb
headers, proportionally so the mix survives and deterministically so the
result is reviewable.

Placement is seeded per platform by name, so the same level always produces
the same fill and a diff means someone changed the level.

## Materials come from names

`oax-shell` picks a terrain material from the proxy body's own name —
`shore`, `ledge`, `wall`, `pillar` and the rest map to the client's terrain
materials, and anything unrecognised gets `river_stone`. The level already
names its bodies for what they are, so the name is the honest signal rather
than a table someone has to maintain in parallel.

Two entries in that table are not obvious and are deliberate:

* `ground` means **sand**, not woodland. The hub's `Ground` is the Open Lagoon
  shore; read as woodland it wore `forest_earth`, whose low tint is nearly
  black, and rendered the entire hub as a dark slab.
* Names matching `--geometric` (`Gate`, `Pedestal`, `Portal`, and the Drift
  Fleet's) are skipped entirely. A mod gate reads as a rule precisely because
  it is a clean slab among organic rock; wrapping it in a boulder would make
  it look like scenery the player can ignore.

## Fixtures

`tools/scene_fixtures.py` builds the `.tscn` all four tools' tests read. It is
one fixture rather than four because the properties most worth testing are
across tools — filler must avoid the landmarks the scatterer left standing,
and none of the passes may move anything the snapshot calls gameplay.

```sh
python tools/scene_fixtures.py /tmp/fixture   # materialise it and look at it
```
