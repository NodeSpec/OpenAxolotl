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

| Category | File types | Image resolution | Alpha | Mesh budget |
|---|---|---|---|---|
| character | `.png`, `.glb` | 64×64 – 2048×2048 | **required** | ≤ 60 000 triangles |
| creature | `.png`, `.glb` | 64×64 – 2048×2048 | **required** | ≤ 30 000 triangles |
| prop | `.png`, `.glb` | 32×32 – 2048×2048 | **required** | ≤ 10 000 triangles |
| environment | `.png`, `.glb` | 128×128 – 4096×4096 | allowed | ≤ 200 000 triangles |
| audio | `.wav`, `.ogg` | ≤ 2 channels, 44100 or 48000 Hz | — | — |

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
