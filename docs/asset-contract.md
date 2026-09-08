# The Asset Contract

How art and audio enter OpenAxolotl (REQ-015). The machine-readable contract
is [`contracts/asset_contract.v1.json`](../contracts/asset_contract.v1.json)
and the provenance sidecar schema is
[`contracts/provenance.schema.json`](../contracts/provenance.schema.json) —
those files are the source of truth and the validator reads them directly.
This page is the contributor's walkthrough of the same rules, plus the one
part that is deliberately human: style review.

Assets are authored **offline with whatever tool you choose** — hand-painted,
AI-generated, recorded — and dropped into the repository as conforming files.
There is no in-editor generation plugin at MVP, and none is needed: if your
output satisfies this contract, it is submittable.

## Layout and naming

```
assets/<category>/<name>/
    <name>.png          # one or more source files
    provenance.json     # always
```

- Categories: `character`, `creature`, `prop`, `environment`, `audio`.
- `<name>` and every file stem: `lower_snake_case`, starting with a letter
  (`^[a-z][a-z0-9_]*$`). The same convention as tuning keys and save
  namespaces, so one grep finds an asset everywhere it is referenced.
- Nothing sits loose in `assets/` or in a category directory; every asset
  owns a folder.

## Per-category constraints

| Category | File types | Image resolution | Alpha | Mesh budget | Deviation |
|---|---|---|---|---|---|
| character | `.png`, `.glb` | 64×64 – 2048×2048 | **required** | ≤ 60 000 triangles | ≤ 0.5 % |
| creature | `.png`, `.glb` | 64×64 – 2048×2048 | **required** | ≤ 30 000 triangles | ≤ 0.5 % |
| prop | `.png`, `.glb` | 32×32 – 2048×2048 | **required** | ≤ 10 000 triangles | ≤ 2 % |
| environment | `.png`, `.glb` | 128×128 – 4096×4096 | allowed | ≤ 200 000 triangles | ≤ 3 % |
| audio | `.wav`, `.ogg` | ≤ 2 channels, 44100 or 48000 Hz | — | — | — |

The last column is how far a *decimated* surface may stray from the dense
source it came from, and it only applies to a model that went through
`oax-decimate`; the section on that tool derives the numbers.

**The mesh budget bounds one file; the scene has a budget of its own.**
`test/core/rendering/test_hero_surface.gd` asserts 400 000 triangles for the
whole dressed valley plus the hero, and the two numbers have to be read
together. Coral Cove instances ten externally authored machines: at the prop
ceiling those alone are 100 000 triangles, so an asset is only allowed to fill
its category budget while the scene it lives in has room for what that costs.

That reading cuts both ways, and it is worth recording which way it went here.
Squeezing the machines to 5 000 to fit a 150 000-triangle scene made the
Netbot's net stray 3.07 % of its diagonal — refused by its own deviation gate
— and cost the Dredger its hose runs and railings. Paying real quality to a
number is the moment to check the number, and 150 000 turned out to be a
holdover from when every mesh in the valley was a `BoxMesh` or a 176-triangle
generated prop. It was never what the baseline GTX 1650 struggles with; SDFGI
and the shadow cascades are. So the scene ceiling moved and the machines ship
at their category budget, textures included.

Characters, creatures and props composite over arbitrary backgrounds — an
image without an alpha channel ships a rectangle, so alpha is required.
Environment textures may legitimately be opaque, so alpha is merely allowed.

## 3D models

A 3D asset is a **binary glTF 2.0** file (`.glb`), one per asset directory,
beside any textures it uses:

```
assets/character/axolotl/
  axolotl.glb        the mesh (and its rig, materials and clips, if any)
  axolotl.png        optional textures, checked like any other image
  provenance.json    required, exactly as for every other asset
```

Godot imports glTF natively — meshes, skeletons, materials, animation clips
— so there is no conversion step to drift, and a `.glb` from Blender, a
CC0 pack or an AI mesh generator drops straight in. Reference it from a scene
as a `PackedScene` and instance it; the hero is
`core/controller/axolotl_body.tscn`, which does exactly that.

The validator reads the file's JSON chunk (its header) and sums the primitive
index counts against the category's triangle budget; it never decodes
geometry. Godot's `<file>.import` sidecars are engine bookkeeping — ignored
wherever they appear, and gitignored.

Vertex-coloured, textured and untextured meshes are all legitimate. Whether
the model *looks* right is the human half below, exactly as for images.

### Refining a model in Blender (headless)

Blender is the one external tool the pipeline leans on, for geometry work
an engine cannot do for itself: merging a generator's loose parts, smooth
normals, and later rigging and animation clips. It never runs interactively
here. The documented command (REQ-032):

```sh
python tools/refine_model.py --input assets/character/axolotl/axolotl.glb \
                             --output assets/character/axolotl/axolotl.glb
```

It finds Blender (`$OAX_BLENDER`, then `blender` on PATH; Blender 4.0 or
newer with `numpy` available to its Python), runs
`tools/blender/refine_model.py` in the background, and validates what comes
back. No Blender is an invocation error (exit 2), never a silent pass.

What refinement does, and what it deliberately does not:

- **Merges parts by role.** Each part is classified by its mean vertex
  colour against the hero palette — the same thresholds
  `core/rendering/hero_skin.gd` uses in the game — and joined into one mesh
  per role: skin, eye, gleam, gill, detail.
- **Names the materials** `axolotl_<role>`. That name is the contract with
  the client: `HeroSkin` dresses a surface by material name first and falls
  back to vertex colours only for a raw file that names nothing.
- **Writes smooth normals** (auto-smooth at 60°, `--smooth-angle` to change).
- **Keeps vertex colours** and **preserves geometry exactly**: the triangle
  count must not change, so a model that met its budget still meets it and
  the provenance sidecar's description of the geometry stays true. A step
  that changes geometry (decimation, sculpting) is a separate, reviewed
  change with its own provenance note.

Record the refinement in `provenance.json`'s `tool` field, as the hero's
sidecar does.

### Bringing an outside model inside its budget (headless)

The pipeline now begins outside this repository: a concept image goes to
Meshy, and what comes back is a dense uniform remesh with its detail baked
into 4K maps. The hero arrived at **1,933,518 triangles** across 1.75 m² of
surface — a triangle every 1.4 mm, thirty-two times the character budget, and
geometry the game will never see, because at gameplay camera distance those
triangles are far below one pixel each. Every environment kit that follows it
will arrive the same way, so reduction is a pipeline stage, not a chore:

```sh
python tools/decimate_model.py --input reference/hero/pink_axolotl_2.glb \
                               --output reference/hero/pink_axolotl_2_reduced.glb \
                               --max-triangles 55000
```

The budget, the texture ceiling **and the deviation ceiling** all come from the
**contract**, resolved from the output path's category, so no number is
restated in a command line and none can drift from what CI enforces.
`--max-triangles`, `--max-texture` and `--max-deviation` override them for a
destination outside `assets/`, as above — and `--max-triangles` is how a
shipped asset reaches its *scene* budget rather than its category ceiling:

```sh
python tools/decimate_model.py --input reference/coral_cove/Dredger_Rustbreaker.glb \
                               --output assets/prop/dredger/dredger.glb \
                               --max-triangles 3000 --max-texture 1024
```

Writing over the input is refused: decimation cannot be undone, and the dense
source is the only thing a second attempt at a different ratio can start from.

**Why this is safe here, and when it would not be.** Reducing polygons ruins
a model whose detail *is* its geometry — a sculpt with no maps, where the
wrinkles are vertices. These are the opposite: base colour, normal and
metallic-roughness over a UV layout, so the wrinkles are pixels, and collapse
decimation interpolates UVs along the edges it collapses. What is genuinely
at risk is the **silhouette** — the outline of a gill filament, which no
normal map can restore — so the tool measures that instead of assuming it.

Two gates, and both exist because they catch different failures:

- **Deviation.** The surface is sampled in both directions. *Decimated →
  original* catches invention; *original → decimated* catches loss, and that
  is the one that matters for a creature with thin parts: when a filament
  dissolves entirely, every point that was on it is suddenly far from any
  remaining surface, while everything left behind still sits on the original.
  A one-way measurement would report the model as near-perfect with the gills
  gone. The ceiling is **0.5 % of the bounding-box diagonal for a character or
  creature** — about two screen pixels of silhouette error on a hero at
  gameplay distance, since a two-metre hero fills roughly a third of a 1080p
  frame a couple of metres away, so one pixel is about a fifth of a percent of
  its diagonal. Props get 2 % and environment 3 %, and the reason is not only
  distance: **it is what the strayed geometry is made of.** A Dredger's worst
  point is its hardware — a railing, a hose, an intake lip — where the hero's
  is the outline the player reads all game. Losing pipework off a machine at
  gameplay distance costs nothing; losing a gill filament changes the
  character. Half a percent stays the fallback wherever the contract has no
  category to consult, because the strictest number in the family is the safe
  one to guess.

  **The looser ceilings are not licence to stop looking.** Every asset here
  was rendered at its shipped count before it was committed, and the numbers
  were chosen so the gate still catches what it is for: a model collapsing to
  a coarse hull, which a triangle count alone reports as a success.
  `tools/test_decimate_model.py` holds both halves — the same coarse sphere is
  refused at `assets/character/` and accepted at `assets/environment/`, so a
  tool that quietly stopped reading the contract fails the pair.
- **Open seams.** Deviation is not enough on its own, and the hero proved it.
  It passed both directions at a *thousandth* of its diagonal and still
  rendered with black hairline cracks down its flanks, because the export is
  not one watertight surface: 1,009,622 vertices for 966,739 distinct
  positions, and **84,666 edges with a single face on them**. In the source
  the two lips of each seam sit on top of each other and nothing shows.
  Decimate them and each lip collapses on its own, the pair drifts a fraction
  of a millimetre apart, and the surface opens — every sample still green,
  the model visibly broken. So coincident vertices are welded before anything
  is collapsed (the hero's 84,666 open edges become 0, and stay 0 through the
  reduction), and an output with more open edges than its welded source is an
  error. Welding is safe for the maps: Blender keeps UVs per face corner, so
  the seam's two different UVs stay exactly where they were.

**What comes out is named for what it is.** Godot extracts an
embedded-texture `.glb`'s images when it imports one, and names each file
`<glb stem>_<image name>` — so whatever the exporter called a map becomes a
real filename in `assets/`. Meshy's current exports call them `Image_0`,
`Image_1` and `Image_2`, which land as `dredger_Image_0.jpg`: a name the
contract's lower_snake_case rule rejects, and one the repository's ignore
rules (written for `_base_color`, `_normal`, `_metallic_roughness`) do not
cover, so an otherwise perfect asset fails validation over a derived file
nobody authored. The decimator therefore renames each map by the Principled
BSDF input it reaches — base colour, normal, metallic-roughness — before it
exports, and reports the renames in `imagesRenamed`. Extracted textures stay
gitignored: they are regenerated from the model on any fresh checkout.

Recording the result: decimation changes geometry, so it needs its own
provenance note, as the section above requires.

## Provenance — every asset, no exceptions

Each asset directory carries a `provenance.json`:

```json
{
  "author": "you, or your agent identity",
  "generationMethod": "ai-generated",
  "licenseTerms": "generator ToS reference, or CC0-1.0, ...",
  "tool": "imagegen 3.1",
  "prompt": "a small pink axolotl scout, side view, transparent background"
}
```

- `author`, `generationMethod`, `licenseTerms` — always required.
- `generationMethod` is `ai-generated` or `hand-authored`.
- `tool` and `prompt` are **required for `ai-generated`** assets and not
  required for hand-authored ones. The conditional is written into the JSON
  Schema itself (`if/then`), so this rule is visible in the contract file,
  not buried in validator code.
- No other fields are accepted.

This is a licensing instrument, not bookkeeping: AI-generated art can carry
rights and attribution obligations from the generator's terms of service,
and the project's licensing decision depends on being able to tell which
assets those are.

## Validating your asset

The documented command — the same one CI runs:

```sh
oax-asset-check --target . --format json
```

Zero-install alternative (the validator is standard-library Python):

```sh
python tools/asset_contract_validator.py --target .
```

Point `--target` at a repository root, an `assets/` tree, or one asset
directory to narrow the run. Exit 0 means conforming; exit 1 lists
violations, each with a stable dotted rule id (`character.alpha_channel`,
`provenance.missing`, …), the specific file, and where possible a
remediation. Exit 2 means the invocation itself was wrong.

## Style and art direction — the human half

Structural conformance is machine-checked; **style is reviewed by a human
maintainer, and only a human**. There is deliberately no automated style
check: a false rejection of legitimate work is worse here than a style miss
review would catch. What the maintainer reviews against:

- **Soft, rounded silhouettes.** This is a family game about a small
  axolotl; nothing ships with aggressive spikes, gore, or humanized menace.
  The Drift Fleet is machinery — nets, hooks, dredges — never people.
- **Toy materials: saturated albedo, real lighting.** The reference is a
  well-made toy under a soft studio light, not a cel-shaded cartoon. Colour
  lives in the albedo — clean, saturated, from the aquatic palettes (teals,
  sea-greens, warm coral accents) with readable value contrast — and the
  shared lighting rig does the shading: sky ambient, bounced light, contact
  occlusion, soft shadows. Materials are smooth and slightly glossy (a wet
  sheen on skin and coral, a matte finish on sand and rock), never noisy,
  never photoreal. Skin, gills and fins may let light through. Characters
  read at gameplay distance; detail that only reads in a close-up is lost.
- **Comedic, not gruesome.** Damage framing is pop-and-sparkle; assets that
  depict injury realistically do not fit the regeneration pillar.
- **One world, one voice.** Audio sits in a soft, watery register — no
  harsh distortion, no jump-scare stingers.

A submission that passes the validator and misses these expectations gets
art-direction feedback in review, exactly like code review — the validator
narrows what a human must look at; it never replaces the look.

### Surfaces — why there are no texture files

There is not a single image texture in this repository, and that is a
decision rather than an omission. Ask "how do we get from greybox shapes to
something that reads as a game?" and the honest answer has three parts, in
descending order of how much each one buys:

**1. Silhouette, first and by a distance.** A box with a beautiful bark
texture is still a box. Almost everything that reads as "greybox" is shape,
not surface — which is why the environment and forest kits are generated
geometry with jittered vertices and layered lobes, and why a level's dressing
budget goes on trees and boulders before it goes on anything else.

**2. Procedural surfaces, second.** Platforms and terrain wear
[`core/rendering/terrain_surface.gdshader`](../core/rendering/terrain_surface.gdshader),
a triplanar world-space shader: three octaves of value noise over a stratum
term, sampled on all three axes and blended by the normal, plus a third
colour applied to upward faces only for moss and dirt. A material is a
handful of uniform values in a `.tres` under `core/rendering/terrain/`.

Three things fall out of that choice, and they are why it beats a texture
path for this project specifically:

- **No UVs.** Level geometry is `BoxMesh` primitives and the props are
  generated in Blender with no UV layout at all. A texture path means
  unwrapping every one of them and keeping the unwrap in step with a
  generator that changes.
- **Continuous across seams.** Two boxes butted together sample the same
  world-space field, so the grain runs *across* the join instead of
  restarting at it. A tiled texture cannot do that without an atlas.
- **Reviewable.** The whole material family is one shader plus a few numbers,
  so it can be read in a diff, retuned without a re-bake, and regenerated by
  anyone. A PNG is a binary that arrives with a claim about how it was made.

Vertex colour does the same job for meshes: the kits paint a gradient into
`COLOR_0` and the shared material reads it as albedo.

**3. Baked maps, last — and exactly one asset has earned them.** `.png` is a
conforming file type in every model category, so baked maps are permitted
whenever an asset genuinely needs them — anything where the pattern has to be
*authored* rather than *described*. The **hero is that asset** (REQ-040): its
skin carries a computed normal map (pore relief over mottle bumps) and a
neutral detail map multiplied over the vertex colour, both produced by
`tools/blender/bake_hero_maps.py` from a deterministic procedural height
field, rasterised against the shipped mesh's own tangents. The price was paid
in full: the mesh ships its UV layout and tangents, the provenance records
the bake, and the script fails its own run if the geometry changes. Everything
else still describes its pattern instead of authoring one.

**Flat colour is still a tool, not a failure.** The two mod gates in Coral
Cove keep a single flat albedo on purpose: a gate is a rule, not geology, and
giving it the same bedded rock as the cliff beside it tells the player it is
scenery they cannot pass. Flat colour is the oldest signal in the language
for "this object obeys different rules".

### Rendering — the shared look

Worlds ship geometry; the game client ships the look. One lighting rig,
[`core/rendering/world_lighting.tscn`](../core/rendering/world_lighting.tscn),
carries the shared environment
([`core/rendering/base_environment.tres`](../core/rendering/base_environment.tres))
and the sun, and the main scene instances it **beside** the hub so it keeps
lighting whichever world the player enters. Every world — official, template,
community — is lit by it, which is how the look above stays one look without
each contributor re-tuning a sun.

What the rig provides, and what an asset may therefore assume:

| Rig feature | What it means for an asset |
|---|---|
| Procedural sky, ambient and reflections read from it | No baked ambient in textures; a mid-grey albedo reads mid-grey |
| AgX tonemapping | Saturated albedo does not clip to white; author colours at full chroma |
| Screen-space ambient occlusion + SDFGI | Contact shading and bounce come free; do not paint them in |
| Soft two-cascade sun shadows | Geometry casts and receives; keep silhouettes clean, they are seen twice |
| Restrained glow (highlights above white only) | Emissive materials glow; albedo never does |
| Teal depth fog + thin volumetric fog | Distant geometry recedes into water; far detail is wasted effort |
| Shared water surface material (`core/rendering/water_surface.tres`) | A `WaterVolume` mesh wears this, never its own tint; water is one look everywhere |

The renderer is **Forward+** (`project.godot`), with the Mobile renderer as
the automatic fallback on hardware that cannot drive it — the same scenes
render there with the expensive effects (GI, occlusion, volumetric fog)
silently dropped. Compatibility (OpenGL) is not a target: the toy look is
unreachable on it. The baseline machine and the frame budget the rig has to
respect are in [`performance.md`](performance.md).

A world that needs a mood of its own — a dusk, a deep trench — adds a
`WorldEnvironment` in its scene and it takes precedence while the world is
active. It never needs a sun.
