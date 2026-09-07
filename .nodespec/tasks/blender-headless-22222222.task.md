# Task: Blender (headless)

> **Scope:** implement ONLY this node ("Blender (headless)"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** External Service
**Technology:** blender
**Description:** Third-party API or SaaS integration

## Your Deliverable

This component is an engine that owns its own internals. Never decompose its internals into architecture nodes, and never reimplement its functionality as application code.
- **Connection contracts** for every interface below (triggers, payloads, endpoints)
- **Configuration artifacts** that bind this engine into the system (config kind)

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Author the binding configuration for External Service.** <!-- t:c714c44f -->
  Configuration artifacts that bind this engine into the system — the engine owns its internals; never reimplement them.
- [ ] **T2 — Expose the interface Model Refinement Pipeline consumes, per Contract "Blender Headless CLI" (dependency).** <!-- t:0fef59fc -->
  Record the endpoint/identifiers Model Refinement Pipeline needs in this node's config artifacts — coordinate with Model Refinement Pipeline.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Resolve ownership, then implement: "The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer" (REQ-032).** <!-- t:147c1192 -->
  [PLACEHOLDER: owner — this node or a sharing node (Model Refinement Pipeline); assign via the requirement mapping, then keep this task here or move it to the owning node's doc]
  ↳ serves: REQ-032 "The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer"
- [ ] **T4 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.

**Your first action — expand these work orders.** Each task above guarantees WHAT must be covered, not HOW. Before writing any code or configuration, expand every task with the concrete implementation steps for THIS technology in THIS project — the specific resources, settings, files, schemas, and tests — using the Configuration, Interface Contracts, Technology Guidance, and node context as your references. Record the expanded list in this section via update_artifact (propose_patches) after this doc is accepted, keeping task IDs, criterion citations, and open `[PLACEHOLDER: …]` tags intact. Resolve placeholders with the user through the proposal flow; this node is never complete while one remains open. When the work orders are implemented, verify through the test lane: run get_test_plan for each requirement this node serves, implement and run the plan's tests, and report outcomes via report_test_results — passing results are the evidence that flips criteria met.

## Project Context

OpenAxolotl — Play it. Fork it. Build a world.

A colorful 3D action-platformer in Godot where a tiny axolotl explores strange aquatic worlds, restoring damaged habitats and rescuing creatures. Every world is a self-contained module anyone — human or AI coding agent — can fork, replace, or extend. Open source is a gameplay feature, not a line in the README.

FOUR PILLARS

1. Regeneration is the constant loop; lives are the hard failure state. Damage strips a capability — tail, gill, leg — with comedic pop-and-sparkle framing rather than draining a health bar, and never ends a run on its own. A separate limited life count is spent only on catastrophic events and returns the player to the last checkpoint. Regeneration stays expressive and ever-present; lives supply the stakes.

2. Two movement grammars, one axolotl. Water and land are mechanically distinct, joined by a water-powered dash as the signature transition skill. This is the answer to "why is this not a cute skin on generic platformer mechanics."

3. The world regenerates with you. Regions progress barren, resourced, restored — opening real traversal paths rather than swapping visuals — and Drift Fleet dredgers can undo that progress. This carries the open-source metaphor mechanically, without a child ever needing to notice it.

4. The repo is the game. Every world conforms to a versioned Level Contract published as a machine-readable schema. A contributor never needs to understand the whole game, only the contract. The project is effectively an open-source platformer SDK.

ANTAGONISTS
The Drift Fleet: faceless industrial extraction machinery, deliberately never human characters. Nets, hooks, dredges and pollution, with no gore and no humanized violence — the same machinery that broke the habitat is what the player disables to heal it.

MVP SCOPE
PC only. Two official worlds plus a minimal reference template. Three Gill Mods — Bubble, Jet, Glow — built to depth rather than breadth; Electric, Frost and Giant are post-MVP and double as the reference example for community-built mods. Contract compliance, asset conformance, and world static analysis are automated and merge-blocking, so an AI agent can verify its own work before submitting.

COMMUNITY (post-MVP)
Opens only once Level Contract v1 is frozen; opening earlier means every core update breaks early contributor worlds. Community worlds ship code like any other world — safety comes from static analysis against the sanctioned world API surface plus mandatory human review, never an automated-only merge path. This is a family game with an agent-authored contribution pipeline, so that gate is load-bearing.

NON-GOALS (firm, not deferrals)
No multiplayer, in any phase. No console certification. No level-editor GUI, ever — worlds are authored as code and Godot scenes only, so humans and AI agents build the same way and the contract surface stays narrow enough to check.

OPEN ITEMS
Licensing split between code and official art/audio, entangled with AI-generation provenance. Save-compatibility policy for forked and divergent worlds.

## Requirements — Your Scope

### REQ-032: Blender Headless Refinement Pipeline
Category: technical | Status: pending
_Shared with: Model Refinement Pipeline — their slices live in their own task docs._
Blender is the one external tool the asset pipeline leans on, for geometry work a game engine cannot do for itself: merging a generator's loose parts into role meshes, writing smooth normals, and later rigging and animation clips. It must never be needed interactively: a documented command (tools/refine_model.py) finds Blender ($OAX_BLENDER, then PATH), runs tools/blender/refine_model.py in the background, and validates what comes back against the Asset Contract, so a human or an AI agent can hand a model to Blender and prove the result without opening a window. Refinement classifies parts by the same hero palette thresholds the game client uses (core/rendering/hero_skin.gd), joins them into one mesh per role, names each material axolotl_<role> as the contract with the client, keeps vertex colours, and preserves geometry exactly, so a model that met its triangle budget still meets it and the provenance sidecar stays true. No Blender is an invocation error, never a silent pass. Blender itself is an external service on the architecture, invoked only through this command line.

**Acceptance criteria — your task boxes:**
- [x] The refinement command builds the documented headless Blender command line and reports a missing Blender as an invocation error, never a silent pass
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] Refining the hero model produces one mesh per role with named materials, smooth normals and vertex colours, and preserves the triangle count exactly
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The Blender script and the game client classify parts by the same palette thresholds
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The shipped hero asset is the refined form and its provenance sidecar records the refinement as a tool in the chain
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [ ] The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer (manual)
  → covered by Task T3

### REQ-035: Hero rig and animation set
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, Axolotl Controller, Model Refinement Pipeline, Asset Contract Validator — their slices live in their own task docs._
The hero model must deform as it moves rather than slide as a rigid prop. The shipped axolotl carries a skeleton and an animation clip for every movement state the controller already computes, and the game client plays the matching clip from that state.

THE RIG is produced headless, through the same Blender lane as the refinement pass (REQ-032), so it is reproducible from the unrigged source and never depends on a rigging artist or a GUI session. Twelve bones: root, spine, head, two gill stalks, four legs, three tail segments. Weights are computed by inverse-square distance to the two nearest bone segments rather than heat-diffused, because Blender's automatic weights need manifold geometry and the hero is a merged pile of primitives — bone heat can fail outright and would fail differently per Blender build.

The eye and its highlight are bound WHOLE to the head bone. Under the nearest-two rule they landed 77% and 70% respectively on the gill bones — measurably different ratios — so the highlight slid off the pupil whenever the fronds swung.

THE CLIPS are the contract with the client, by name: idle, waddle, swim, hop, fall, hurt. The rigging CLI fails the build if a clip is missing, if the geometry changed, or if nothing came back skinned.

THE CLIENT chooses the clip from four facts the body already has each physics step: in water, on the floor, vertical speed, planar speed. Water wins over everything; airborne splits on direction of travel; grounded splits on whether it is moving. HURT is a one-shot that overrides the locomotion choice for its own length and is driven by the world's capability-loss signal, not guessed from motion — a flinch the player cannot see is not feedback.

Geometry is never altered by rigging, so the triangle budget the Asset Contract sets (REQ-030) continues to hold.

**Acceptance criteria — your task boxes:**
- [x] The rigging pipeline runs headless in Blender and produces a skinned model carrying all six named clips (idle, waddle, swim, hop, fall, hurt), failing the build if any is missing or nothing is skinned
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] Rigging preserves geometry exactly: the triangle count out equals the triangle count in and the model stays inside its Asset Contract budget
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The shipped hero imports into Godot with a Skeleton3D carrying the documented bones, every mesh skinned, and the ongoing clips set to loop despite glTF importing them one-shot
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The eye and its highlight are each driven by exactly one bone, and that bone is the head, so the highlight cannot separate from the pupil
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Axolotl Controller, Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The animator maps every movement state to its clip: water to swim regardless of other state, rising to hop, descending to fall, grounded and moving to waddle, grounded and still to idle
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The hurt flinch overrides locomotion for the full length of its clip and resumes locomotion afterwards
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] An animator bound to a model with no AnimationPlayer is inert rather than broken, so bodies built without a model still run
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] The hero's provenance records the rigging step, its tool, and the bones and clips it added
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline

### REQ-039: Forested river valley: procedural surfaces and water placed as difficulty
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, World: Coral Cove — their slices live in their own task docs._
The space around and below a platforming route is gameplay, not garnish: a jump over nothing gives the player no way to judge height or distance, and a surface with no variation across it has no scale. Coral Cove therefore sits inside a forested river valley, and every terrain surface in the game wears a material instead of a flat colour.

SURFACES WITHOUT TEXTURE FILES. Platforms and terrain wear one shared triplanar shader — three octaves of value noise over a warped stratum term, sampled from world position on all three axes and blended by the normal, with a third colour on upward faces only for moss. A material is a handful of uniform values in a client-owned .tres. Triplanar and world-space for this project's specific reasons: level geometry is BoxMesh primitives and props are generated with no UV layout, so a texture path would mean unwrapping everything and keeping the unwrap in step with generators that change; and the grain runs ACROSS the seam where two boxes butt, which tiling cannot do. The two mod gates deliberately keep a flat colour — a gate is a rule, not geology. The whole decision, including when a baked PNG is the right tool instead, is documented in the Asset Contract's prose.

THE VALLEY: a scenery forest floor 24 m below the route (no collider — the pit volume sits BETWEEN route and floor, so a fall still dies at the last checkpoint while the player watches the forest come up at them), canopy trees planted on it that rise past the route and close overhead, ridges for sides, and banks enclosing the water so no volume's edge is ever visible. A five-prop forest kit (canopy tree, understory fern, fallen log, river reed, river boulder) is generated headless in Blender, deterministic under one seed, vertex-coloured, with provenance, the whole set well under a thousand triangles because it is placed by the dozen.

WATER IS PLACED AS DIFFICULTY. A river runs the full length of the act-1 staircase, so a missed jump there is a swim downstream and never a life — reeds mark that waterline, making the forgiveness legible. The glow grotto's pillars have no water under them at all. And the gorge river drops a MANDATORY swim into the middle of the jumping, with a rock rib to dive under and slot walls set twice-the-jump back from the landing so no bank bypasses it. The difficulty curve is thereby stated in geometry.

The shared haze is retuned from dense teal to thin grey-green air, because every scene in this game is above water and the underwater feel belongs to the water volumes, which tint it themselves; at the old density anything past thirty metres flattened into one plane and the valley rendered as an empty sea.

**Acceptance criteria — your task boxes:**
- [x] A shared triplanar world-space terrain shader exists with a small set of client-owned material resources, and Coral Cove's platforms, walls, beds and banks wear them rather than per-node flat colours — with the two mod gates keeping flat colour as the deliberate exception
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping
- [x] The forest kit's five props are generated headless in Blender, deterministic under a seed, carry provenance records, and pass the Asset Contract validator inside the environment budget
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping
- [x] A missed jump anywhere over the act-1 river costs a swim and never a life, while a fall in the glow grotto still costs a life at the last checkpoint: the pit volume sits between the route and the scenery forest floor and the waterway spans exactly the forgiving stretch
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping
- [x] The gorge river is a mandatory swim between jump sections — entered from the landing, dived under the rib, exited onto the first terrace — and its slot walls stand at least twice the measured jump from any standable edge so the swim cannot be bypassed on a bank
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping
- [x] Every water volume in the world carries bubble particles (the REQ-034 dressing rule), emitted by the same construction that makes the volume so a new river cannot ship without them
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping
- [x] The retuned haze keeps distant geometry legible: rendered captures show the forest floor, trees and valley sides reading at route distance in every act, and the full verification chain stays green
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, World: Coral Cove): no contract evidence; assign via the requirement mapping

### REQ-040: Hero surface quality: baked character maps at toy-grade finish
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, Model Refinement Pipeline — their slices live in their own task docs._
The hero must read as a finished toy at gameplay distance AND in a close-up: the reference is a well-made vinyl figure under studio light — pristine gloss, soft translucent skin, deep wet eyes — not a vertex-tinted mesh. This extends REQ-035 (Hero Character Look), whose final criterion (the maintainer sign-off render) has stayed unmet precisely because flat vertex colour under real lighting still reads as unfinished.

THE CHARACTER IS THE ONE ASSET THAT EARNS TEXTURES. The Asset Contract's surface doctrine says baked maps are the last resort, paid for only where a pattern must be AUTHORED rather than DESCRIBED — and the hero's skin is that case: mottling that follows anatomy, a belly-to-back gradient, pore-scale relief. So the Blender lane gains a bake stage: UV-unwrap the generated hero headless, bake fine-detail maps (albedo detail and normal) from procedural node trees in Cycles, and ship them beside the glb under the character category's documented size bounds, with the bake recorded in provenance like every other generation step.

THE ROLE MATERIALS finish the job in Godot, because most of the Astro Bot read is MATERIAL rather than map: subsurface scattering and a clearcoat sheen on skin so light enters rather than bounces; a high-gloss dark eye whose highlight is geometry (the gleam) and therefore never lost to environment reflections; gill fronds lit from behind through backlight so they glow when the sun crosses them; the baked normal map giving the skin its fine relief only at close range.

PERFORMANCE IS A CONSTRAINT, NOT A HOPE: the hero stays inside its existing Asset Contract triangle budget (the bake adds maps, never geometry), texture memory stays within the category's size bounds, and the whole dressed Coral Cove scene is measured — total triangles counted headlessly and the perf gate extended to run the valley — so desktop testing meets a scene in the tens of thousands of triangles, not hundreds.

**Acceptance criteria — your task boxes:**
- [x] The Blender lane bakes hero maps headless and reproducibly: the generated axolotl is UV-unwrapped and fine-detail albedo and normal maps are baked from procedural sources in one CLI invocation, recorded in the asset's provenance
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline
- [x] Baked maps conform to the Asset Contract character category: PNG, within the documented size bounds, living in the asset's own directory, and the validator passes
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The bake adds no geometry: the shipped hero's triangle count is unchanged and remains inside its Asset Contract budget
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The skin role material carries the baked normal and detail maps with subsurface scattering and a clearcoat sheen; the eye is high-gloss with its highlight guaranteed by the gleam geometry; gills glow when backlit — all applied by the existing role classification at runtime
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] Rendered close-up and gameplay-distance captures on the shared rig show the finish: visible skin relief in close-up that vanishes into a clean silhouette at distance, no shading seam at any UV boundary
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The dressed Coral Cove scene's total triangle count is measured headlessly and stays under 150,000, and the performance gate runs the valley world within the documented budgets
  → THIS NODE via Contract "Blender Headless CLI" (dependency) from Model Refinement Pipeline — coordinate with Model Refinement Pipeline

## Interface Contracts

### RECEIVES FROM: Model Refinement Pipeline (cli-tool)
- **Contract:** Blender Headless CLI
- **Protocol:** dependency
- **Transport:** ipc
- **Spec Format:** custom
- **Their Technology:** python-backend

**Schema:**
```
{
  "argv": [
    "<blender>",
    "--background",
    "--python-exit-code",
    "1",
    "--python",
    "tools/blender/refine_model.py",
    "--",
    "--input",
    "<in.glb>",
    "--output",
    "<out.glb>",
    "--smooth-angle",
    "<degrees>"
  ],
  "roles": [
    "skin",
    "eye",
    "gleam",
    "gill",
    "detail"
  ],
  "stdout": {
    "summaryLine": "REFINE {\"partsIn\": int, \"meshesOut\": int, \"mergedByRole\": {role: int}, \"polygons\": int, \"smoothAngleDeg\": float, \"blender\": version}"
  },
  "exitCode": "non-zero on any Python exception inside the script (--python-exit-code)",
  "invariants": [
    "triangle count preserved exactly",
    "one mesh per role present",
    "materials named axolotl_<role>",
    "NORMAL and COLOR_0 on every primitive"
  ],
  "description": "How the pipeline drives Blender: one background process, one script, arguments after `--`, a JSON summary line on stdout the pipeline parses.",
  "paletteThresholds": {
    "GILL_MAX_GREEN": 0.5,
    "EYE_MAX_LUMINANCE": 0.15,
    "GLEAM_MIN_CHANNEL": 0.97,
    "DETAIL_MAX_LUMINANCE": 0.4
  }
}
```

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Depends on THIS node being available:**
- Model Refinement Pipeline (initiates Blender Headless CLI against this node (dependency))
