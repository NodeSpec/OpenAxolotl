# Task: Model Refinement Pipeline

> **Scope:** implement ONLY this node ("Model Refinement Pipeline"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CLI Tool
**Technology:** Python
**Description:** Command-line interface application for developer or operator interaction

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with Blender (headless) (blender) per Contract "Blender Headless CLI" (dependency).** <!-- t:65b6ef7e -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Asset Contract Validator (python-backend) per Contract "GLB Header Reader" (dependency).** <!-- t:1cf0e1e9 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Resolve ownership, then implement: "The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer" (REQ-032).** <!-- t:147c1192 -->
  [PLACEHOLDER: owner — this node or a sharing node (Blender (headless)); assign via the requirement mapping, then keep this task here or move it to the owning node's doc]
  ↳ serves: REQ-032 "The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer"
- [ ] **T5 — Resolve ownership, then implement: "The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures" (REQ-034).** <!-- t:869fddb7 -->
  [PLACEHOLDER: owner — this node or a sharing node (OpenAxolotl Game Client); assign via the requirement mapping, then keep this task here or move it to the owning node's doc]
  ↳ serves: REQ-034 "The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures"
- [ ] **T6 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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
_Shared with: Blender (headless) — their slices live in their own task docs._
Blender is the one external tool the asset pipeline leans on, for geometry work a game engine cannot do for itself: merging a generator's loose parts into role meshes, writing smooth normals, and later rigging and animation clips. It must never be needed interactively: a documented command (tools/refine_model.py) finds Blender ($OAX_BLENDER, then PATH), runs tools/blender/refine_model.py in the background, and validates what comes back against the Asset Contract, so a human or an AI agent can hand a model to Blender and prove the result without opening a window. Refinement classifies parts by the same hero palette thresholds the game client uses (core/rendering/hero_skin.gd), joins them into one mesh per role, names each material axolotl_<role> as the contract with the client, keeps vertex colours, and preserves geometry exactly, so a model that met its triangle budget still meets it and the provenance sidecar stays true. No Blender is an invocation error, never a silent pass. Blender itself is an external service on the architecture, invoked only through this command line.

**Acceptance criteria — your task boxes:**
- [x] The refinement command builds the documented headless Blender command line and reports a missing Blender as an invocation error, never a silent pass
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] Refining the hero model produces one mesh per role with named materials, smooth normals and vertex colours, and preserves the triangle count exactly
  → owner unresolved — this node or a sharing node (Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The Blender script and the game client classify parts by the same palette thresholds
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] The shipped hero asset is the refined form and its provenance sidecar records the refinement as a tool in the chain
  → owner unresolved — this node or a sharing node (Blender (headless)): no contract evidence; assign via the requirement mapping
- [ ] The refined axolotl reads smoother and more toy-like than the raw export in a rendered capture reviewed by the maintainer (manual)
  → covered by Task T4

### REQ-034: World Dressing and Living Water
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client — their slices live in their own task docs._
The step from greybox to a place: a shared, regenerable environment kit and water that moves. The kit is four vertex-coloured props in the aquatic palette (rock cluster, coral branch, kelp strand, seagrass tuft), BUILT procedurally by a deterministic headless Blender script (tools/blender/make_environment_kit.py, fixed seed) so the whole kit can be regenerated or re-paletted from source rather than depending on binaries nobody can rebuild; each prop ships as a contract-conforming asset with provenance. Scenes are dressed with kit instances under one Dressing container per scene, and dressing is VISUAL ONLY as a hard rule: no physics object and no scene group anywhere beneath the container, so decoration can never invalidate a tuned probe, collide with the player, or accidentally become a Level Contract element. The shared water surface graduates from a flat tint to an animated unshaded shader (world-space crossed-sine shimmer with caustic glints and fresnel-weighted transparency), still one client-owned material every WaterVolume references, and official worlds' water carries rising bubble particles. Walks, the perf gate and the contract checkers must stay green through all of it.

**Acceptance criteria — your task boxes:**
- [x] Every kit prop loads with meshes whose palette comes from vertex colours
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client): no contract evidence; assign via the requirement mapping
- [x] The kit is generated by a deterministic headless Blender script and every kit asset passes the Asset Contract with provenance recording the generator
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client): no contract evidence; assign via the requirement mapping
- [x] The hub and both official worlds carry at least a dozen kit props under a Dressing container whose subtree has no physics objects and no scene groups
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client): no contract evidence; assign via the requirement mapping
- [x] The shared water material carries an animated shader that stays unshaded and translucent, and official worlds' water volumes carry bubble particles
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client): no contract evidence; assign via the requirement mapping
- [x] Every walk probe, the perf gate and both contract checkers pass unchanged with the dressing in place
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client): no contract evidence; assign via the requirement mapping
- [ ] The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures (manual)
  → covered by Task T5

### REQ-035: Hero rig and animation set
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, Axolotl Controller, Blender (headless), Asset Contract Validator — their slices live in their own task docs._
The hero model must deform as it moves rather than slide as a rigid prop. The shipped axolotl carries a skeleton and an animation clip for every movement state the controller already computes, and the game client plays the matching clip from that state.

THE RIG is produced headless, through the same Blender lane as the refinement pass (REQ-032), so it is reproducible from the unrigged source and never depends on a rigging artist or a GUI session. Twelve bones: root, spine, head, two gill stalks, four legs, three tail segments. Weights are computed by inverse-square distance to the two nearest bone segments rather than heat-diffused, because Blender's automatic weights need manifold geometry and the hero is a merged pile of primitives — bone heat can fail outright and would fail differently per Blender build.

The eye and its highlight are bound WHOLE to the head bone. Under the nearest-two rule they landed 77% and 70% respectively on the gill bones — measurably different ratios — so the highlight slid off the pupil whenever the fronds swung.

THE CLIPS are the contract with the client, by name: idle, waddle, swim, hop, fall, hurt. The rigging CLI fails the build if a clip is missing, if the geometry changed, or if nothing came back skinned.

THE CLIENT chooses the clip from four facts the body already has each physics step: in water, on the floor, vertical speed, planar speed. Water wins over everything; airborne splits on direction of travel; grounded splits on whether it is moving. HURT is a one-shot that overrides the locomotion choice for its own length and is driven by the world's capability-loss signal, not guessed from motion — a flinch the player cannot see is not feedback.

Geometry is never altered by rigging, so the triangle budget the Asset Contract sets (REQ-030) continues to hold.

**Acceptance criteria — your task boxes:**
- [x] The rigging pipeline runs headless in Blender and produces a skinned model carrying all six named clips (idle, waddle, swim, hop, fall, hurt), failing the build if any is missing or nothing is skinned
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] Rigging preserves geometry exactly: the triangle count out equals the triangle count in and the model stays inside its Asset Contract budget
  → THIS NODE via Contract "GLB Header Reader" (dependency) to Asset Contract Validator — coordinate with Asset Contract Validator
- [x] The shipped hero imports into Godot with a Skeleton3D carrying the documented bones, every mesh skinned, and the ongoing clips set to loop despite glTF importing them one-shot
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] The eye and its highlight are each driven by exactly one bone, and that bone is the head, so the highlight cannot separate from the pupil
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Axolotl Controller, Blender (headless), Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The animator maps every movement state to its clip: water to swim regardless of other state, rising to hop, descending to fall, grounded and moving to waddle, grounded and still to idle
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] The hurt flinch overrides locomotion for the full length of its clip and resumes locomotion afterwards
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] An animator bound to a model with no AnimationPlayer is inert rather than broken, so bodies built without a model still run
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Axolotl Controller, Blender (headless), Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The hero's provenance records the rigging step, its tool, and the bones and clips it added
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)

### REQ-036: Drift Fleet and Flagship reachable from a world
Category: functional | Status: pending
_Shared with: World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System — their slices live in their own task docs._
The Drift Fleet runtime (REQ-012) and the Flagship encounter (REQ-013) must be reachable from a world. Both were built and tested headless, and every one of those tests passed while no world could reach either: the WorldSystems runtime had no enemy scene convention, never constructed a DriftFleetSystem, and never read the manifest's optional `boss` element. The framework's own comment says it "owns no enemy placement and no geometry: a world places enemies, and whatever binds the scene calls the lanes below" — nothing was that binder.

THE JOIN follows the shape every other element uses: the manifest declares, the scene places, the runtime connects the two.

  * `enemies` lists the roster ids a world uses. Nodes in the `enemy` group carry an enemy_id; a dredger also carries the region_id it sits over, because which stretch of reef a dredger threatens is placement rather than roster data.
  * Contact routes by the unit's DECLARED behaviour, never by anything the scene picks — entangle and snag through the one contact lane, dredge through strike_region, a toxin aura on both the enter and exit edges because an aura is a volume rather than a hit. A world therefore cannot invent an effect by placing a node, which is the point of the sanctioned surface.
  * Placing a node is not a declaration: a node naming an undeclared unit stays inert, the same rule a collectible pickup naming an undeclared id follows. The check runs on every lane rather than only at wiring time, because the probes and tests drive those seams directly.
  * `boss` builds a FlagshipEncounter wired to Regeneration, Lives, Restoration and the Gill Mods. A refused declaration leaves the region LOCKED: a boss that failed to build has not been beaten, and opening the region because the declaration was malformed would hand the player the payoff for free.
  * The `boss_phase` scene convention makes the encounter drivable from a scene at all. A phase volume reads the player's grammar at the moment of contact rather than declaring it, because that is the point of REQ-013 AC-3 — a water-only phase must be cleared while actually swimming.

THE FLEET IS BUILT even when a world declares nothing, so the accessor never returns null and the tick loop needs no special case. That tick is load-bearing: the entanglement and aura-linger timers live in the fleet precisely so a despawned enemy cannot strand the player debuffed forever.

THE UNITS have bodies, generated through the same headless Blender lane as the environment kit. The design rule is the vision's: faceless industrial extraction machinery, never human characters, so every unit is assembled from machine primitives and none has a face, an eye or a limb. A cold oxidised-iron palette with a single amber warning accent separates them from the warm reef, and they are flat-shaded where the reef kit is smooth, because manufactured things have hard edges.

Units sit OFF the walked route in both official worlds: the walk probes measure every checkpoint segment against progression.max_retry_seconds, and an entangling unit on that line would fail a completability probe for a reason unrelated to completability.

**Acceptance criteria — your task boxes:**
- [x] A world declaring no enemies still has a working DriftFleetSystem, so the absent default is a no-op rather than a null, and the reference template keeps exercising that path
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] The shipped enemy roster loads into a world's fleet so a manifest can name any of its units
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] Contact with a declared entangling unit, driven through the runtime's own scene seam, entangles the player
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A scene node naming a unit the world never declared stays inert on every lane, not only at wiring time
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A dredger reverts the region its node names back to barren while leaving the region's unlocked flag set
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A valid boss declaration builds a Flagship encounter and its region starts locked
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A refused boss declaration leaves the region locked rather than opening it
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A boss phase volume clears a phase only when the player arrives in the grammar that phase demands
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] Both official worlds declare and place a Drift Fleet, and every walk probe, contract checker and the perf gate stay green with the units in place
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] Every Drift Fleet unit ships as a contract-conforming asset with provenance recording the generator
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Flagship Boss Encounter, Restoration State System): no contract evidence; assign via the requirement mapping

### REQ-040: Hero surface quality: baked character maps at toy-grade finish
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, Blender (headless) — their slices live in their own task docs._
The hero must read as a finished toy at gameplay distance AND in a close-up: the reference is a well-made vinyl figure under studio light — pristine gloss, soft translucent skin, deep wet eyes — not a vertex-tinted mesh. This extends REQ-035 (Hero Character Look), whose final criterion (the maintainer sign-off render) has stayed unmet precisely because flat vertex colour under real lighting still reads as unfinished.

THE CHARACTER IS THE ONE ASSET THAT EARNS TEXTURES. The Asset Contract's surface doctrine says baked maps are the last resort, paid for only where a pattern must be AUTHORED rather than DESCRIBED — and the hero's skin is that case: mottling that follows anatomy, a belly-to-back gradient, pore-scale relief. So the Blender lane gains a bake stage: UV-unwrap the generated hero headless, bake fine-detail maps (albedo detail and normal) from procedural node trees in Cycles, and ship them beside the glb under the character category's documented size bounds, with the bake recorded in provenance like every other generation step.

THE ROLE MATERIALS finish the job in Godot, because most of the Astro Bot read is MATERIAL rather than map: subsurface scattering and a clearcoat sheen on skin so light enters rather than bounces; a high-gloss dark eye whose highlight is geometry (the gleam) and therefore never lost to environment reflections; gill fronds lit from behind through backlight so they glow when the sun crosses them; the baked normal map giving the skin its fine relief only at close range.

PERFORMANCE IS A CONSTRAINT, NOT A HOPE: the hero stays inside its existing Asset Contract triangle budget (the bake adds maps, never geometry), texture memory stays within the category's size bounds, and the whole dressed Coral Cove scene is measured — total triangles counted headlessly and the perf gate extended to run the valley — so desktop testing meets a scene in the tens of thousands of triangles, not hundreds.

**Acceptance criteria — your task boxes:**
- [x] The Blender lane bakes hero maps headless and reproducibly: the generated axolotl is UV-unwrapped and fine-detail albedo and normal maps are baked from procedural sources in one CLI invocation, recorded in the asset's provenance
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)
- [x] Baked maps conform to the Asset Contract character category: PNG, within the documented size bounds, living in the asset's own directory, and the validator passes
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The bake adds no geometry: the shipped hero's triangle count is unchanged and remains inside its Asset Contract budget
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The skin role material carries the baked normal and detail maps with subsurface scattering and a clearcoat sheen; the eye is high-gloss with its highlight guaranteed by the gleam geometry; gills glow when backlit — all applied by the existing role classification at runtime
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] Rendered close-up and gameplay-distance captures on the shared rig show the finish: visible skin relief in close-up that vanishes into a clean silhouette at distance, no shading seam at any UV boundary
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The dressed Coral Cove scene's total triangle count is measured headlessly and stays under 150,000, and the performance gate runs the valley world within the documented budgets
  → THIS NODE via Contract "Blender Headless CLI" (dependency) to Blender (headless) — coordinate with Blender (headless)

## Interface Contracts

### SENDS TO: Blender (headless) (external-service)
- **Contract:** Blender Headless CLI
- **Protocol:** dependency
- **Transport:** ipc
- **Spec Format:** custom
- **Their Technology:** blender

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

### SENDS TO: Asset Contract Validator (cli-tool)
- **Contract:** GLB Header Reader
- **Protocol:** dependency
- **Transport:** none
- **Spec Format:** custom
- **Their Technology:** python-backend

**Schema:**
```
{
  "raises": "HeaderError on a malformed file",
  "function": "glb_header(path: str) -> tuple[int, int, list[str]]",
  "description": "The pipeline imports the Asset Contract Validator's glb_header(path) -> (triangles, mesh_count, animation_names) and DEFAULT_SCHEMA to hold the refined output to the same triangle budget the validator enforces, reading only the JSON chunk and never decoding geometry.",
  "budgetSource": "contracts/asset_contract.v1.json categories.<category>.maxTriangles"
}
```

## Technology Guidance

_Reference for executing the Implementation Tasks above — apply where relevant. The task list stands even where this guidance is thin._

**Purpose:** The default language for data/ML-adjacent backends and a first-class choice for typed API services (FastAPI + Pydantic). Spans API services, workers, ML pipelines, inference services, webhook handlers and CLIs — when the component touches the data/ML ecosystem, Python is usually the honest pick.

**SDK Initialization:**
```
pip install fastapi uvicorn sqlalchemy pydantic-settings
# main.py
from fastapi import FastAPI
app = FastAPI()

@app.get("/health")
def health(): return {"status": "ok"}

# uvicorn main:app --reload
```

**Common API Patterns:**

#### REST Endpoint
FastAPI endpoint with dependency injection and response model
```
@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

#### Dependency Injection
Composable dependency chain for DB sessions and auth
```
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    payload = verify_token(token)
    return await db.get(User, payload["sub"])
```

#### Background Task
Celery task for async background processing
```
from celery import Celery
celery_app = Celery("tasks", broker="redis://localhost:6379")

@celery_app.task
def send_email(to: str, subject: str, body: str):
    smtp_client.send(to=to, subject=subject, body=body)
```

**Configuration Template:**
```
# pyproject.toml
[project]
name = "myapp"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[tool.ruff]
target-version = "py311"
select = ["E", "F", "I", "UP"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]
```

**Best Practices:**
- Type hints everywhere + Pydantic models at every boundary — FastAPI turns them into validation and OpenAPI for free
- uv for env + deps (committed lockfile, pinned python version); one venv per service
- Async where the framework is async — mixing blocking calls (requests, raw psycopg) into async handlers is the classic FastAPI foot-gun; use httpx/asyncpg
- Workers: Celery or arq with explicit idempotency — Python queue consumers WILL be redelivered
- ruff for lint+format (one tool), pytest with fixtures over unittest classes

**Anti-Patterns to Avoid:**
- Blocking I/O inside async routes (sync DB drivers, requests) — kills the event loop invisibly
- requirements.txt without pins in a production service
- Django for a pure JSON API where FastAPI is lighter — Django earns its weight only when the admin/ORM/auth batteries are used
- Global mutable module state as a cache — breaks under multiple workers

**Security:** Use Pydantic models for automatic input validation on all endpoints. Use parameterized queries via SQLAlchemy ORM, never raw string interpolation. Set CORS middleware with explicit allowed origins. Use python-jose or PyJWT for JWT validation. Pin dependencies and use pip-audit for vulnerability scanning. Never run uvicorn with --reload in production.

**Integration Patterns:**
- FastAPI or Flask for HTTP framework with automatic OpenAPI docs
- SQLAlchemy 2.0 with asyncio for async database access
- Celery or ARQ for distributed task queues
- Pydantic for data validation and settings management
- pytest with httpx.AsyncClient for async API testing

**Suggested File Structure:**
- `src/main.py` (source)
- `src/routes/__init__.py` (source)
- `pyproject.toml` (config)

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Blender (headless) (this node calls/depends on it via Blender Headless CLI (dependency))
- Asset Contract Validator (this node calls/depends on it via GLB Header Reader (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `tools/blender/make_drift_fleet.py` | source | --- | draft |
| `tools/refine_model.py` | source | --- | draft |
| `tools/blender/refine_model.py` | source | --- | draft |
| `tools/test_refine_model.py` | source | --- | draft |
| `tools/blender/make_environment_kit.py` | source | --- | draft |
| `tools/blender/rig_model.py` | source | --- | draft |
| `tools/rig_model.py` | source | --- | draft |
