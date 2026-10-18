# Task: OpenAxolotl Game Client

> **Scope:** implement ONLY this node ("OpenAxolotl Game Client"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Game Client
**Technology:** Godot
**Description:** Game client application handling rendering, input, and local simulation

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Constraints That Apply Here

None recorded for this node. Standing conditions the build must honour (security, compliance, cost, technology and the like) can be filed with a `create_constraint` patch.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node is the Godot project itself plus three things that only make sense at
project scope: the Level Contract v1 schema every other module is judged
against, the Open Lagoon hub that discovers and loads world modules at runtime,
and the contributor-facing documentation and performance budgets.

**Repository layout (project-wide, settled here once).** The Godot project root
IS the repository root — `project.godot` sits at the top level so every core
system, world module and contract schema is reachable as a plain `res://` path
with no import gymnastics. `core/` holds one directory per core system node,
`hub/` holds the Open Lagoon hub and world loader, `worlds/` holds world
modules discovered at runtime, `contracts/` holds the machine-readable schema
files, `test/` holds GdUnit4 GDScript tests mirroring `core/`, and `addons/`
holds GdUnit4 itself. `dev/` holds the developers' proving ground — the greybox
scene and its headless smoke driver. It is deliberately NOT under `worlds/`: it
declares no manifest and satisfies no contract element, so the hub must never
discover it, and putting it there would mean either a special case in the loader
or a permanently invalid module. It is superseded by the reference template
(REQ-029) as the thing a contributor copies, but it outlives it as the scene
core systems are exercised in without dragging a contract along. The Python tooling lives under `tools/` and the shared
test fixtures under `fixtures/`; both carry a `.gdignore` file so Godot's
importer never scans them — this matters because the fixture set deliberately
contains malformed and malicious world modules that would otherwise break
editor import for everyone.

**Language: GDScript only.** This project is written in GDScript and nothing
else. There is no C#: no `.cs` files, no Mono/.NET assemblies, no C# build step,
no mixed-language interop layer. Where the Godot catalog guidance in this packet
says "use GDScript for gameplay logic and C# for complex systems", the C# half
DOES NOT APPLY here — a "complex system" is not a reason to reach for a second
language. One language keeps the contribution surface narrow, which is the whole
premise: humans and AI coding agents extend the same repo from the Level Contract
alone, and a second toolchain doubles the build, the review surface and the
static-analysis gate's parser burden for no gameplay gain. Use *statically typed*
GDScript throughout — typed parameters, return types and members — since the
catalog itself lists untyped GDScript as an anti-pattern and the gate's tokenizer
is simpler and safer against typed source. Target Godot 4.7 / GDScript 2.0. (The
four Python validator nodes and the GitHub Actions CI node are deliberately
outside this policy; it governs game code.)

**Catalog guidance that does not apply here.** The Godot technology guidance in
this packet includes multiplayer sample code — `@rpc` annotations,
`is_multiplayer_authority`, `MultiplayerSynchronizer`. It is generic engine
guidance and it is forbidden in this project. REQ-030 bans the entire Godot
multiplayer surface, the Engine Feature Policy contract records the ban
machine-readably, and the World Static Analysis Gate fails CI on any occurrence
in core, worlds, the template or submissions. Cross-node communication in this
project is signals and direct calls through the declared interfaces, never RPC.
`project.godot` must additionally declare no networking autoloads, no peer
configuration and no network-related project settings — that is a checked
criterion, not a style preference.

**The Level Contract is a data file, not code.** `contracts/level_contract.v1.json`
is a JSON Schema document and it is the single source of truth: the compliance
checker loads it and hardcodes nothing, and the hub loads the same file to
validate a module before loading it. Adding a conformance rule means editing
that file only. The schema declares the five required elements (spawn point,
checkpoints, finish condition, controller compatibility, save integration), each
optional element together with the default applied when absent, the
`contractVersion` identifier every world module must declare, the module
directory layout and naming convention, and a `sanctionedApi` block naming the
symbols a world may call. Keep `contracts/sanctioned_api.v1.json` derived from
the actual architecture edges rather than authored from intent — an allowlist
written from memory drifts from the interfaces that really exist, and the static
gate then rejects legitimate world code. The prose companion at
`docs/level-contract.md` explains each element and its rationale; it is
documentation of the schema, never a second source of truth.

**Hub and loader.** `hub/world_registry.gd` scans `res://worlds/` at runtime,
reads each module's manifest, validates it against the loaded schema, and builds
the portal list from what survives. There is no hardcoded world list anywhere,
including no special case for the reference template — the template must go
through the identical path, which is what proves the path is genuinely generic.
A module that fails to load or fails validation is recorded with its failure
reason and surfaced as an unavailable portal; it never propagates an exception
into the hub. Portals carry a `tier` field (`official`, `community`,
`experimental`) coming from the manifest, and tier is distinguished by shape and
label as well as color, because REQ-019 and REQ-022 forbid color-only encoding
project-wide. Per-world completion and restoration progress are read through the
Save Integration Interface — the hub never opens the save file.

**Performance budgets.** State the baseline PC specification and the three
numbers (frame-rate target, maximum permitted frame-time spike, world load-time
budget) in `docs/performance.md` and mirror them as data in the tuning set so
the CI regression test reads the same numbers the documentation states. Measure
in-engine with `Performance.get_monitor()` rather than wall-clock timing around
the frame loop. The load-time budget is measured from portal selection to the
frame the player first has control, not to scene instantiation.

**Documentation.** REQ-017's testable criterion is that the exact documented
commands succeed as written. Keep the command strings in one place —
`docs/commands.md` — and have the harness parse that file and execute what it
finds, so documentation drift fails CI instead of quietly misleading a
contributor. The remaining REQ-017 criteria are manual and prove out through
task-doc ticks plus user approval, not through `report_test_results`.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Axolotl Controller (godot) per Contract "Axolotl Controller Interface" (dependency).** <!-- t:a33cf1c7 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves: REQ-033 "The axolotl reads as a glossy toy with wet eyes and glowing gills to the maintainer in a rendered capture on baseline-class hardware" — coordinate with Axolotl Controller
- [ ] **T3 — Implement the integration with Camera System (godot) per Contract "Core Module Dependency" (dependency).** <!-- t:3d3effd0 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Save System (godot) per Contract "Save Integration Interface" (dependency).** <!-- t:bcbdac74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement the integration with Lives and Checkpoint System (godot) per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:25e4d91d -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Implement the integration with World: Coral Cove (godot) per Contract "Level Contract v1" (dependency).** <!-- t:bd68a2e3 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement the integration with World: Bubble Bay (godot) per Contract "Level Contract v1" (dependency).** <!-- t:04060a69 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Implement the integration with Player HUD (godot) per Contract "HUD State Interface" (dependency).** <!-- t:c8a2f551 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Implement the integration with Audio System (godot) per Contract "Audio Event Interface" (dependency).** <!-- t:218035d2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement the integration with Input System (godot) per Contract "Player Input Interface" (dependency).** <!-- t:da38b8ef -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T11 — Implement the integration with World: Reference Template (godot) per Contract "Level Contract v1" (dependency).** <!-- t:d6a167a4 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T12 — Expose the interface Asset Contract Validator consumes, per Contract "Asset Contract v1" (custom).** <!-- t:8c09fb30 -->
  Record the endpoint/identifiers Asset Contract Validator needs in this node's config artifacts — coordinate with Asset Contract Validator.
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T13 — Expose the interface CI Pipeline consumes, per Contract "Core Module Dependency" (dependency).** <!-- t:8c23999f -->
  Record the endpoint/identifiers CI Pipeline needs in this node's config artifacts — coordinate with CI Pipeline.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T14 — Expose the interface Test Harness and Fixtures consumes, per Contract "Core Module Dependency" (dependency).** <!-- t:61c95f0c -->
  Record the endpoint/identifiers Test Harness and Fixtures needs in this node's config artifacts — coordinate with Test Harness and Fixtures.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T15 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T16 — Implement: "A prose contract document explains every schema element and its rationale for human contributors" (REQ-006).** <!-- t:f54e24ad -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A prose contract document explains every schema element and its rationale for human contributors" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T17 — Implement: "A documented migration path describes how a v1 world is brought forward when the contract version increments" (REQ-006).** <!-- t:05b606b3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A documented migration path describes how a v1 world is brought forward when the contract version increments" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T18 — Implement: "A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone" (REQ-006).** <!-- t:92ae5f33 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T19 — Implement: "Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it" (REQ-006).** <!-- t:a8f5e226 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T20 — Implement: "A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world" (REQ-017).** <!-- t:88c0ed62 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Reference Template (keyword signal only)
- [ ] **T21 — Implement: "Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written" (REQ-017).** <!-- t:687cbf04 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written" — possible coordination point: Contract "Asset Contract v1" (custom) from Asset Contract Validator (keyword signal only)
- [ ] **T22 — Implement: "Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo" (REQ-017).** <!-- t:ce3124be -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T23 — Implement: "Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples" (REQ-017).** <!-- t:f50808d7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T24 — Implement: "README states the agent-authored contribution workflow with a concrete example prompt" (REQ-017).** <!-- t:9d36c5b8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "README states the agent-authored contribution workflow with a concrete example prompt" — possible coordination point: Contract "HUD State Interface" (dependency) to Player HUD (keyword signal only)
- [ ] **T25 — Implement: "An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker" (REQ-017).** <!-- t:0426c75f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T26 — Implement: "The README is the front door and reaches the rest: it states what the game is, that levels can be added to it, and links every contributor document in the repository, so no contributor-facing page is discoverable only by browsing the file tree" (REQ-017).** <!-- t:a2b55a3c -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "The README is the front door and reaches the rest: it states what the game is, that levels can be added to it, and links every contributor document in the repository, so no contributor-facing page is discoverable only by browsing the file tree" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T27 — Implement: "Documentation walks the editor-first path end to end — open the template in Godot, play it, change a platform, add a machine, run the checkers, see it in the hub — written for someone who has not used Godot before and assuming no terminal-first or agent workflow" (REQ-017).** <!-- t:c8131e1e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Documentation walks the editor-first path end to end — open the template in Godot, play it, change a platform, add a machine, run the checkers, see it in the hub — written for someone who has not used Godot before and assuming no terminal-first or agent workflow" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T28 — Implement: "A person outside this project follows the editor-first path from the README alone and gets a change of their own running, without a maintainer answering questions" (REQ-017).** <!-- t:d599d559 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "A person outside this project follows the editor-first path from the README alone and gets a change of their own running, without a maintainer answering questions" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T29 — Implement: "Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal" (REQ-027).** <!-- t:6305f4b4 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T30 — Implement: "A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached" (REQ-027).** <!-- t:ba2d3e65 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached" — possible coordination point: Contract "Core Module Dependency" (dependency) from Test Harness and Fixtures (keyword signal only)
- [ ] **T31 — Implement: "The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case" (REQ-027).** <!-- t:447b635f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case"
- [ ] **T32 — Implement: "The hub and both official worlds read as the documented toy look (saturated albedo, real lighting) to the maintainer on baseline-class hardware at the documented frame rate" (REQ-031).** <!-- t:08ad7205 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-031 "The hub and both official worlds read as the documented toy look (saturated albedo, real lighting) to the maintainer on baseline-class hardware at the documented frame rate" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T33 — Implement: "Code license is chosen and applied to the repository" (REQ-021).** <!-- t:281343c1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Code license is chosen and applied to the repository" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T34 — Implement: "Official art and audio asset license is chosen, documented, and distinguished from the code license" (REQ-021).** <!-- t:f8fd989b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Official art and audio asset license is chosen, documented, and distinguished from the code license" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T35 — Implement: "Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing" (REQ-021).** <!-- t:207df9ff -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T36 — Implement: "Contributor licensing terms for submitted worlds and assets are documented in the contribution guide" (REQ-021).** <!-- t:6f240208 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Contributor licensing terms for submitted worlds and assets are documented in the contribution guide" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T37 — Implement: "Licensing decision is resolved before the public README and contribution guide ship" (REQ-021).** <!-- t:ac788e6d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Licensing decision is resolved before the public README and contribution guide ship" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T38 — Implement: "The policy states explicitly whether a level author may build with the shipped assets, and on what terms, both inside this repository and outside it" (REQ-021).** <!-- t:9211484f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "The policy states explicitly whether a level author may build with the shipped assets, and on what terms, both inside this repository and outside it" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T39 — Implement: "Every shipped asset whose provenance records terms originating outside this repository is either covered by the chosen policy or replaced with an asset the project can license, with none left unresolved at the point the contribution guide ships" (REQ-021).** <!-- t:6599fbcd -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Every shipped asset whose provenance records terms originating outside this repository is either covered by the chosen policy or replaced with an asset the project can license, with none left unresolved at the point the contribution guide ships" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T40 — Resolve ownership, then implement: "The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures" (REQ-034).** <!-- t:869fddb7 -->
  [PLACEHOLDER: owner — this node or a sharing node (Model Refinement Pipeline); assign via the requirement mapping, then keep this task here or move it to the owning node's doc]
  ↳ serves: REQ-034 "The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T41 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.

**Your first action — expand these work orders.** Each task above guarantees WHAT must be covered, not HOW. Before writing any code or configuration, expand every task with the concrete implementation steps for THIS technology in THIS project — the specific resources, settings, files, schemas, and tests — using the Configuration, Interface Contracts, Existing Implementation, Technology Guidance, and node context as your references. Write each work order's steps under its task line as indented checkbox lines (`  - [ ] <step>`), one action each, naming the file, setting or interface it changes, and send them with update_artifact (propose_patches, passing base_sequence) after this doc is accepted, keeping task IDs, criterion citations, and open `[PLACEHOLDER: …]` tags intact; the steps stay with their work order when this doc regenerates. Resolve placeholders with the user through the proposal flow; this node is never complete while one remains open. When the work orders are implemented, verify through the test lane: run get_test_plan for each requirement this node serves, implement and run the plan's tests, and report outcomes via report_test_results — passing results are the evidence that flips criteria met.

## Configuration

User-selected configuration for this component (honor these choices):
- **csharp:** not used - no .cs files, no Mono/.NET assemblies, no C# build step. The catalog line 'use GDScript for gameplay logic and C# for complex systems' does NOT apply here.
- **engine:** Godot 4.x, GDScript 2.0
- **typing:** statically typed GDScript throughout (typed params, returns, members)
- **language:** GDScript
- **rationale:** One language keeps the contribution surface narrow for humans and AI agents alike; a second toolchain doubles build, review and static-gate parser burden for no gameplay gain.

## Vision This Node Serves

No outcome behind this node's requirements cites the vision, so no sentence is carried here. The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-006: Level Contract v1 Specification
Category: technical | Status: in-progress
THE ANCHOR REQUIREMENT of the entire project. A versioned specification defining what any world module must provide to be a valid OpenAxolotl world, published in TWO forms: a MACHINE-READABLE SCHEMA FILE that the compliance checker consumes as its single source of truth, and a PROSE DOCUMENT explaining each element and its rationale to human contributors. Publishing the schema as the authority is what makes conformance genuinely testable rather than a matter of reading a document carefully. REQUIRED elements: spawn point, checkpoints, finish condition, axolotl controller compatibility, save integration. OPTIONAL elements: collectibles, enemies, boss, custom ability, secret areas, NPCs, per-world lives-per-attempt override. Checkpoints are REQUIRED (not optional) because they anchor two separate systems: life refill and capability-state restore. The contract also defines the SANCTIONED WORLD API SURFACE — the public interfaces a world module may call — which is what the community static-analysis gate enforces against. The contract must be explicitly versioned with a defined v1-to-v2 migration story, and frozen at v1 only after the official MVP worlds have battle-tested it. Worlds are authored as code and Godot scenes only; there is no editor GUI authoring path, which keeps the contract surface narrow and checkable.

**Acceptance criteria — your task boxes:**
- [x] Contract is published as a machine-readable schema file that the compliance checker loads as its single source of truth, with no conformance rules hardcoded in the checker
  → THIS NODE: internal logic
- [x] Schema enumerates every required element (spawn point, checkpoints, finish condition, controller compatibility, save integration) with a machine-checkable conformance rule for each
  → THIS NODE: internal logic — possible coordination point: Contract "Axolotl Controller Interface" (dependency) to Axolotl Controller (keyword signal only)
- [x] Schema enumerates every optional element together with the defined default behavior applied when it is absent
  → THIS NODE: internal logic
- [x] Schema carries an explicit contract version identifier, and every world module declares the contract version it targets
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] Schema defines the world module directory layout and file naming convention
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] Schema enumerates the sanctioned world API surface that a world module may call
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] A prose contract document explains every schema element and its rationale for human contributors (manual)
  → covered by Task T16
- [ ] A documented migration path describes how a v1 world is brought forward when the contract version increments (manual)
  → covered by Task T17
- [ ] A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone (manual)
  → covered by Task T18
- [ ] Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it (manual)
  → covered by Task T19

### REQ-009: Open Lagoon Hub and World Loading
Category: functional | Status: in-progress
The hub that makes the modular architecture visible as a place. The Open Lagoon is a central space containing portals to worlds; the player enters a discrete, bounded, checkpointed world through a portal and returns on completion. Level selection is deliberately discrete rather than an interconnected open world. The hub discovers available world modules at runtime from the worlds directory rather than referencing a hardcoded list, which is what allows a world to be added, forked, or replaced without editing the hub. Portals are tiered and visually distinguished — Official Lagoons at MVP, with Community and Experimental tiers reserved for the post-MVP community layer. A world that fails to load must not break the hub.

**Acceptance criteria — your task boxes:**
- [x] Hub discovers installed world modules at runtime from the worlds directory with no hardcoded world list
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] Entering a portal loads the corresponding world at its spawn point, and completing the finish condition returns the player to the hub
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] Adding, removing, or replacing a world module changes the available portals without any edit to hub code
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] A world module that fails to load or fails contract validation is surfaced as unavailable without crashing or blocking the hub
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] Portals carry a tier designation (Official, Community, Experimental) and are visually distinguished by tier
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] Hub reflects per-world completion and restoration progress read through the save-integration interface
  → THIS NODE: internal logic — possible coordination point: Contract "Save Integration Interface" (dependency) to Save System (keyword signal only)

### REQ-017: Level Author Workflow and Documentation
Category: technical | Status: in-progress
Everything a person needs to add a level to this game, and the documentation that makes it possible without asking a maintainer.

THE PRIMARY PATH IS THE GODOT EDITOR. A newcomer opens the template level (REQ-029) in Godot, plays it, changes something, and sees the change. They are not writing a game — they are editing a level of a game that already works, using the editor the engine already ships. Nothing in this requirement may assume an AI agent, a terminal-first workflow, or prior Godot experience as a precondition for that path.

AN AI CODING AGENT IS A SECOND WAY IN, not the only one and not a prerequisite. Someone who would rather describe a level than place it should be able to point an agent at this repository, say "a level set inside a giant aquarium where the player uses Bubble Gills to climb to the top," and get something that passes the checkers. That works only because the repository already carries machine-readable, agent-consumable documentation — the architecture, the Level Contract, the Asset Contract, the asset catalogue, Godot and GDScript conventions, the extension interfaces, and how to run the checkers and tests to self-verify.

THE DOCUMENTATION IS A FIRST-CLASS DELIVERABLE AND IT HAS TO BE REACHABLE. A repository can carry a thousand lines of excellent contributor documentation and still have no on-ramp if nothing links to it; the front door is the README, and the README is part of this requirement rather than garnish on it. Both paths are proven by someone outside this project actually walking them, not by the machinery existing.

**Acceptance criteria — your task boxes:**
- [ ] A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world
  → covered by Task T20
- [ ] Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written
  → covered by Task T21
- [ ] Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo (manual)
  → covered by Task T22
- [ ] Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples (manual)
  → covered by Task T23
- [ ] README states the agent-authored contribution workflow with a concrete example prompt (manual)
  → covered by Task T24
- [ ] An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker (manual)
  → covered by Task T25
- [ ] The README is the front door and reaches the rest: it states what the game is, that levels can be added to it, and links every contributor document in the repository, so no contributor-facing page is discoverable only by browsing the file tree
  → covered by Task T26
- [ ] Documentation walks the editor-first path end to end — open the template in Godot, play it, change a platform, add a machine, run the checkers, see it in the hub — written for someone who has not used Godot before and assuming no terminal-first or agent workflow
  → covered by Task T27
- [ ] A person outside this project follows the editor-first path from the README alone and gets a change of their own running, without a maintainer answering questions (manual)
  → covered by Task T28

### REQ-027: Performance Targets
Category: non-functional | Status: in-progress
A colorful 3D platformer for families on unspecified PC hardware needs stated performance targets, and this project has a specific risk most platformers do not: restoration state changes swap traversable geometry at runtime, potentially across a large region, while Dredgers can revert it mid-encounter. That is a hitch waiting to happen at exactly the moment the game is trying to deliver its most satisfying visual payoff. Targets also matter for the contribution pipeline — a community world that tanks frame rate is a defect the automated pre-screen should be able to catch, which requires a number to check against. Includes frame rate on a defined baseline machine, world load time from hub portal, and a bound on the hitch introduced by a restoration transition.

**Acceptance criteria — your task boxes:**
- [x] A baseline target PC specification is documented, and the frame-rate target, the maximum permitted frame-time spike, and the world load-time budget on that baseline are each stated as numbers
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal
  → covered by Task T29
- [x] A restoration state transition completes without exceeding the documented maximum frame-time spike
  → THIS NODE: internal logic — possible coordination point: Contract "HUD State Interface" (dependency) to Player HUD (keyword signal only)
- [x] World load time from selecting a hub portal to player control stays within the documented load-time budget
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached
  → covered by Task T30
- [ ] The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case (manual)
  → covered by Task T31

### REQ-031: Shared Look Foundation
Category: technical | Status: pending
One rendering look for the whole game, owned by the game client and shared by every world. Worlds ship geometry; the client ships the look: a single lighting rig (core/rendering/world_lighting.tscn) carrying the shared environment (sky-lit ambient and reflections, AgX-class tonemapping so saturated albedo never clips, screen-space ambient occlusion, SDFGI bounce, restrained glow, teal depth fog and thin volumetric fog) and one sun with soft two-cascade shadows. The rig lives at the main scene level beside the hub, never inside it, because the hub disables its own subtree while a world is active and a light parented under it would go dark on entering a world (which is how official worlds were previously lit by ambient colour alone). The renderer is Forward+, with the Mobile renderer as the automatic fallback on hardware that cannot drive it. This is the foundation the art direction in docs/asset-contract.md (toy materials: saturated albedo, real lighting) and every later asset pass build on; the performance baseline in docs/performance.md is what it must fit inside.

**Acceptance criteria — your task boxes:**
- [x] The project renders with Forward+ and declares the Mobile renderer as its automatic fallback
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] The shared environment is sky-lit, with ambient and reflections read from the sky, and has tonemapping, ambient occlusion, global illumination, glow and fog enabled
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] The shared lighting rig ships one WorldEnvironment carrying the shared environment and one sun with soft cascaded shadows
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] The main scene instances the lighting rig beside the hub, never inside the subtree the hub disables while a world is active
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] The reference template ships no sun of its own and is lit by the client's rig, proving a world needs no lighting to be complete
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Reference Template (keyword signal only)
- [ ] The hub and both official worlds read as the documented toy look (saturated albedo, real lighting) to the maintainer on baseline-class hardware at the documented frame rate (manual)
  → covered by Task T32

### REQ-033: Hero Character Look
Category: functional | Status: pending
_Shared with: Axolotl Controller — their slices live in their own task docs._
The axolotl reads as a well-made toy: the material and eye pass on top of the Shared Look Foundation (REQ-031). The game client dresses the imported hero model in its own materials by part role, skin, eye, eye gleam, gill and fin, mouth detail, decided by the pipeline's material name first and by the model's vertex colours as a fallback, so the look survives a repainted or regenerated model. Skin is vertex-coloured, slightly wet (clearcoat) and lets light through at the edges (subsurface scattering); eyes are deep blue-black with near-zero roughness and a full clearcoat so the sky lands as a sharp reflection; the baked catchlights are unshaded so they never go grey in shadow; gills and fins carry strong subsurface scattering and backlight so they glow when lit from behind; mouth details are matte. Motion joins the look: a hop stretches the model taller and thinner and a landing squashes it shorter and wider, volume-preserving, recovering within a fraction of a second, driven by tuning keys and applied only to the Model child so physics never changes. This is the family-friendly comedic register of REQ-019 applied to the character itself.

**Acceptance criteria — your task boxes:**
- [x] The hero palette classifies skin, eye, gleam, gill and detail parts, and a refined model's material names take precedence over its colours
  → owner unresolved — this node or a sharing node (Axolotl Controller): no contract evidence; assign via the requirement mapping
- [x] Each role wears a client material with the properties the art direction asks for: vertex-coloured translucent skin, a wet dark eye, an unshaded gleam, backlit gills, matte details
  → owner unresolved — this node or a sharing node (Axolotl Controller): no contract evidence; assign via the requirement mapping
- [x] The shipped hero model is dressed by role at runtime with every surface wearing a client material
  → owner unresolved — this node or a sharing node (Axolotl Controller): no contract evidence; assign via the requirement mapping
- [x] A hop stretches the model taller and thinner and a landing squashes it shorter and wider, both volume-preserving and recovering to rest within a second
  → owner unresolved — this node or a sharing node (Axolotl Controller): no contract evidence; assign via the requirement mapping
- [x] Squash and stretch amounts and the recovery rate are tuning keys with documented units and ranges
  → owner unresolved — this node or a sharing node (Axolotl Controller): no contract evidence; assign via the requirement mapping
- [ ] The axolotl reads as a glossy toy with wet eyes and glowing gills to the maintainer in a rendered capture on baseline-class hardware (manual)
  → covered by Task T2

### REQ-034: World Dressing and Living Water
Category: functional | Status: pending
_Shared with: Model Refinement Pipeline — their slices live in their own task docs._
The step from greybox to a place: a shared, regenerable environment kit and water that moves. The kit is four vertex-coloured props in the aquatic palette (rock cluster, coral branch, kelp strand, seagrass tuft), BUILT procedurally by a deterministic headless Blender script (tools/blender/make_environment_kit.py, fixed seed) so the whole kit can be regenerated or re-paletted from source rather than depending on binaries nobody can rebuild; each prop ships as a contract-conforming asset with provenance. Scenes are dressed with kit instances under one Dressing container per scene, and dressing is VISUAL ONLY as a hard rule: no physics object and no scene group anywhere beneath the container, so decoration can never invalidate a tuned probe, collide with the player, or accidentally become a Level Contract element. The shared water surface graduates from a flat tint to an animated unshaded shader (world-space crossed-sine shimmer with caustic glints and fresnel-weighted transparency), still one client-owned material every WaterVolume references, and official worlds' water carries rising bubble particles. Walks, the perf gate and the contract checkers must stay green through all of it.

**Acceptance criteria — your task boxes:**
- [x] Every kit prop loads with meshes whose palette comes from vertex colours
  → owner unresolved — this node or a sharing node (Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The kit is generated by a deterministic headless Blender script and every kit asset passes the Asset Contract with provenance recording the generator
  → owner unresolved — this node or a sharing node (Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The hub and both official worlds carry at least a dozen kit props under a Dressing container whose subtree has no physics objects and no scene groups
  → owner unresolved — this node or a sharing node (Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The shared water material carries an animated shader that stays unshaded and translucent, and official worlds' water volumes carry bubble particles
  → owner unresolved — this node or a sharing node (Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] Every walk probe, the perf gate and both contract checkers pass unchanged with the dressing in place
  → owner unresolved — this node or a sharing node (Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [ ] The dressed hub and worlds read as an underwater place rather than a greybox to the maintainer in rendered captures (manual)
  → covered by Task T40

### REQ-021: Licensing Policy — Code, Assets, and AI Provenance
Category: business | Status: blocked
A BLOCKER, no longer an open item beside the work. The project's promise is now "add a level to this game, built out of our assets" — and the second half of that sentence is a GRANT. You cannot invite people to build with assets you have not established you can license to them, and every day the invitation is unwritten is a day the project's headline is unsupported.

The decision has three parts and they resolve together or not at all:

CODE AND ART ARE PROBABLY NOT THE SAME LICENSE. Code wants to be maximally permissive. Official art likely does not, if the axolotl's identity is to stay coherent — a character anyone may relicense into anything is a character with no character. The split has to be explicit and defensible rather than inherited from whichever LICENSE file happened to land at the repo root.

AI PROVENANCE CONSTRAINS WHAT CAN BE GRANTED. Assets generated through external tools carry that generator's terms of service, captured per-asset in provenance.json. The shipped hero is exactly this case: its own provenance record states that the generator's terms govern the geometry and flags review before any redistribution assuming a uniform repository-wide grant. Either those terms permit what we intend to promise, or the asset is replaced with one generated by the in-repo pipeline, whose output the project can license freely. That is a decision plus possibly a rebuild, and it is the concrete blocking item.

REUSE HAS TO BE POSITIVELY PERMITTED, not merely unprohibited. A level author needs to know they may ship a level built from our assets, and under what terms — inside this repository and, if it is allowed at all, outside it. Contributor terms for submitted levels and any art they bring are the same decision from the other side.

Resolved before the README and the contribution guide ship, because those documents are where the grant is actually made.

**Acceptance criteria — your task boxes:**
- [ ] Code license is chosen and applied to the repository (manual)
  → covered by Task T33
- [ ] Official art and audio asset license is chosen, documented, and distinguished from the code license (manual)
  → covered by Task T34
- [ ] Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing (manual)
  → covered by Task T35
- [ ] Contributor licensing terms for submitted worlds and assets are documented in the contribution guide (manual)
  → covered by Task T36
- [ ] Licensing decision is resolved before the public README and contribution guide ship (manual)
  → covered by Task T37
- [ ] The policy states explicitly whether a level author may build with the shipped assets, and on what terms, both inside this repository and outside it (manual)
  → covered by Task T38
- [ ] Every shipped asset whose provenance records terms originating outside this repository is either covered by the chosen policy or replaced with an asset the project can license, with none left unresolved at the point the contribution guide ships (manual)
  → covered by Task T39

### REQ-035: Hero rig and animation set
Category: functional | Status: pending
_Shared with: Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator — their slices live in their own task docs._
The hero model must deform as it moves rather than slide as a rigid prop. The shipped axolotl carries a skeleton and an animation clip for every movement state the controller already computes, and the game client plays the matching clip from that state.

THE RIG is produced headless, through the same Blender lane as the refinement pass (REQ-032), so it is reproducible from the unrigged source and never depends on a rigging artist or a GUI session. Twelve bones: root, spine, head, two gill stalks, four legs, three tail segments. Weights are computed by inverse-square distance to the two nearest bone segments rather than heat-diffused, because Blender's automatic weights need manifold geometry and the hero is a merged pile of primitives — bone heat can fail outright and would fail differently per Blender build.

The eye and its highlight are bound WHOLE to the head bone. Under the nearest-two rule they landed 77% and 70% respectively on the gill bones — measurably different ratios — so the highlight slid off the pupil whenever the fronds swung.

THE CLIPS are the contract with the client, by name: idle, waddle, swim, hop, fall, hurt. The rigging CLI fails the build if a clip is missing, if the geometry changed, or if nothing came back skinned.

THE CLIENT chooses the clip from four facts the body already has each physics step: in water, on the floor, vertical speed, planar speed. Water wins over everything; airborne splits on direction of travel; grounded splits on whether it is moving. HURT is a one-shot that overrides the locomotion choice for its own length and is driven by the world's capability-loss signal, not guessed from motion — a flinch the player cannot see is not feedback.

Geometry is never altered by rigging, so the triangle budget the Asset Contract sets (REQ-030) continues to hold.

**Acceptance criteria — your task boxes:**
- [x] The rigging pipeline runs headless in Blender and produces a skinned model carrying all six named clips (idle, waddle, swim, hop, fall, hurt), failing the build if any is missing or nothing is skinned
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] Rigging preserves geometry exactly: the triangle count out equals the triangle count in and the model stays inside its Asset Contract budget
  → THIS NODE via Contract "Asset Contract v1" (custom) from Asset Contract Validator — coordinate with Asset Contract Validator
- [x] The shipped hero imports into Godot with a Skeleton3D carrying the documented bones, every mesh skinned, and the ongoing clips set to loop despite glTF importing them one-shot
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The eye and its highlight are each driven by exactly one bone, and that bone is the head, so the highlight cannot separate from the pupil
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The animator maps every movement state to its clip: water to swim regardless of other state, rising to hop, descending to fall, grounded and moving to waddle, grounded and still to idle
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The hurt flinch overrides locomotion for the full length of its clip and resumes locomotion afterwards
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] An animator bound to a model with no AnimationPlayer is inert rather than broken, so bodies built without a model still run
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping
- [x] The hero's provenance records the rigging step, its tool, and the bones and clips it added
  → owner unresolved — this node or a sharing node (Axolotl Controller, Blender (headless), Model Refinement Pipeline, Asset Contract Validator): no contract evidence; assign via the requirement mapping

### REQ-039: Forested river valley: procedural surfaces and water placed as difficulty
Category: functional | Status: pending
_Shared with: World: Coral Cove, Blender (headless) — their slices live in their own task docs._
The space around and below a platforming route is gameplay, not garnish: a jump over nothing gives the player no way to judge height or distance, and a surface with no variation across it has no scale. Coral Cove therefore sits inside a forested river valley, and every terrain surface in the game wears a material instead of a flat colour.

SURFACES WITHOUT TEXTURE FILES. Platforms and terrain wear one shared triplanar shader — three octaves of value noise over a warped stratum term, sampled from world position on all three axes and blended by the normal, with a third colour on upward faces only for moss. A material is a handful of uniform values in a client-owned .tres. Triplanar and world-space for this project's specific reasons: level geometry is BoxMesh primitives and props are generated with no UV layout, so a texture path would mean unwrapping everything and keeping the unwrap in step with generators that change; and the grain runs ACROSS the seam where two boxes butt, which tiling cannot do. The two mod gates deliberately keep a flat colour — a gate is a rule, not geology. The whole decision, including when a baked PNG is the right tool instead, is documented in the Asset Contract's prose.

THE VALLEY: a scenery forest floor 24 m below the route (no collider — the pit volume sits BETWEEN route and floor, so a fall still dies at the last checkpoint while the player watches the forest come up at them), canopy trees planted on it that rise past the route and close overhead, ridges for sides, and banks enclosing the water so no volume's edge is ever visible. A five-prop forest kit (canopy tree, understory fern, fallen log, river reed, river boulder) is generated headless in Blender, deterministic under one seed, vertex-coloured, with provenance, the whole set well under a thousand triangles because it is placed by the dozen.

WATER IS PLACED AS DIFFICULTY. A river runs the full length of the act-1 staircase, so a missed jump there is a swim downstream and never a life — reeds mark that waterline, making the forgiveness legible. The glow grotto's pillars have no water under them at all. And the gorge river drops a MANDATORY swim into the middle of the jumping, with a rock rib to dive under and slot walls set twice-the-jump back from the landing so no bank bypasses it. The difficulty curve is thereby stated in geometry.

The shared haze is retuned from dense teal to thin grey-green air, because every scene in this game is above water and the underwater feel belongs to the water volumes, which tint it themselves; at the old density anything past thirty metres flattened into one plane and the valley rendered as an empty sea.

**Acceptance criteria — your task boxes:**
- [x] A shared triplanar world-space terrain shader exists with a small set of client-owned material resources, and Coral Cove's platforms, walls, beds and banks wear them rather than per-node flat colours — with the two mod gates keeping flat colour as the deliberate exception
  → THIS NODE via Contract "Level Contract v1" (dependency) to World: Coral Cove — coordinate with World: Coral Cove
- [x] The forest kit's five props are generated headless in Blender, deterministic under a seed, carry provenance records, and pass the Asset Contract validator inside the environment budget
  → owner unresolved — this node or a sharing node (World: Coral Cove, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] A missed jump anywhere over the act-1 river costs a swim and never a life, while a fall in the glow grotto still costs a life at the last checkpoint: the pit volume sits between the route and the scenery forest floor and the waterway spans exactly the forgiving stretch
  → owner unresolved — this node or a sharing node (World: Coral Cove, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The gorge river is a mandatory swim between jump sections — entered from the landing, dived under the rib, exited onto the first terrace — and its slot walls stand at least twice the measured jump from any standable edge so the swim cannot be bypassed on a bank
  → owner unresolved — this node or a sharing node (World: Coral Cove, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] Every water volume in the world carries bubble particles (the REQ-034 dressing rule), emitted by the same construction that makes the volume so a new river cannot ship without them
  → THIS NODE via Contract "Level Contract v1" (dependency) to World: Coral Cove — coordinate with World: Coral Cove
- [x] The retuned haze keeps distant geometry legible: rendered captures show the forest floor, trees and valley sides reading at route distance in every act, and the full verification chain stays green
  → owner unresolved — this node or a sharing node (World: Coral Cove, Blender (headless)): no contract evidence; assign via the requirement mapping

### REQ-040: Hero surface quality: baked character maps at toy-grade finish
Category: functional | Status: pending
_Shared with: Blender (headless), Model Refinement Pipeline — their slices live in their own task docs._
The hero must read as a finished toy at gameplay distance AND in a close-up: the reference is a well-made vinyl figure under studio light — pristine gloss, soft translucent skin, deep wet eyes — not a vertex-tinted mesh. This extends REQ-035 (Hero Character Look), whose final criterion (the maintainer sign-off render) has stayed unmet precisely because flat vertex colour under real lighting still reads as unfinished.

THE CHARACTER IS THE ONE ASSET THAT EARNS TEXTURES. The Asset Contract's surface doctrine says baked maps are the last resort, paid for only where a pattern must be AUTHORED rather than DESCRIBED — and the hero's skin is that case: mottling that follows anatomy, a belly-to-back gradient, pore-scale relief. So the Blender lane gains a bake stage: UV-unwrap the generated hero headless, bake fine-detail maps (albedo detail and normal) from procedural node trees in Cycles, and ship them beside the glb under the character category's documented size bounds, with the bake recorded in provenance like every other generation step.

THE ROLE MATERIALS finish the job in Godot, because most of the Astro Bot read is MATERIAL rather than map: subsurface scattering and a clearcoat sheen on skin so light enters rather than bounces; a high-gloss dark eye whose highlight is geometry (the gleam) and therefore never lost to environment reflections; gill fronds lit from behind through backlight so they glow when the sun crosses them; the baked normal map giving the skin its fine relief only at close range.

PERFORMANCE IS A CONSTRAINT, NOT A HOPE: the hero stays inside its existing Asset Contract triangle budget (the bake adds maps, never geometry), texture memory stays within the category's size bounds, and the whole dressed Coral Cove scene is measured — total triangles counted headlessly and the perf gate extended to run the valley — so desktop testing meets a scene in the tens of thousands of triangles, not hundreds.

**Acceptance criteria — your task boxes:**
- [x] The Blender lane bakes hero maps headless and reproducibly: the generated axolotl is UV-unwrapped and fine-detail albedo and normal maps are baked from procedural sources in one CLI invocation, recorded in the asset's provenance
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] Baked maps conform to the Asset Contract character category: PNG, within the documented size bounds, living in the asset's own directory, and the validator passes
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The bake adds no geometry: the shipped hero's triangle count is unchanged and remains inside its Asset Contract budget
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The skin role material carries the baked normal and detail maps with subsurface scattering and a clearcoat sheen; the eye is high-gloss with its highlight guaranteed by the gleam geometry; gills glow when backlit — all applied by the existing role classification at runtime
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] Rendered close-up and gameplay-distance captures on the shared rig show the finish: visible skin relief in close-up that vanishes into a clean silhouette at distance, no shading seam at any UV boundary
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping
- [x] The dressed Coral Cove scene's total triangle count is measured headlessly and stays under 150,000, and the performance gate runs the valley world within the documented budgets
  → owner unresolved — this node or a sharing node (Blender (headless), Model Refinement Pipeline): no contract evidence; assign via the requirement mapping

## Interface Contracts

### SENDS TO: Axolotl Controller (shared-library)
- **Contract:** Axolotl Controller Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Camera System (shared-library)
- **Contract:** Core Module Dependency
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Save System (shared-library)
- **Contract:** Save Integration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Lives and Checkpoint System (shared-library)
- **Contract:** Checkpoint and Life Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: World: Coral Cove (shared-library)
- **Contract:** Level Contract v1
- **Protocol:** dependency
- **Their Technology:** godot

**Schema:**
```
{
  "optional": {
    "boss": {
      "default": "none"
    },
    "npcs": {
      "default": "none"
    },
    "music": {
      "default": "engine defaults apply, never silence"
    },
    "enemies": {
      "default": "none"
    },
    "cameraHints": {
      "default": "none",
      "description": "Camera hint volumes overriding framing declaratively; no custom camera code permitted"
    },
    "secretAreas": {
      "default": "none"
    },
    "collectibles": {
      "default": "none"
    },
    "customAbility": {
      "default": "none"
    },
    "tuningOverrides": {
      "default": "none",
      "description": "Only values in sanctionedTuningOverrides may be overridden; anything else is rejected"
    },
    "restorableRegions": {
      "default": "none",
      "description": "Each region declares states barren/resourced/restored plus a separate boolean unlocked flag"
    },
    "livesPerAttemptOverride": {
      "default": "global default applies"
    }
  },
  "required": {
    "spawnPoint": {
      "description": "Player spawn transform where the world begins"
    },
    "checkpoints": {
      "minCount": 1,
      "description": "One or more checkpoint volumes; anchor BOTH life refill and capability-state restore"
    },
    "finishCondition": {
      "description": "Declarative completion condition returning the player to the Open Lagoon hub"
    },
    "saveIntegration": {
      "description": "Declares the save keys this world reads and writes through the save-integration interface"
    },
    "controllerCompatibility": {
      "description": "Declares the Axolotl Controller interface version the world binds against"
    }
  },
  "moduleLayout": {
    "root": "worlds/<world_id>/",
    "scene": "world.tscn",
    "manifest": "world.json"
  },
  "authoringPath": "code and Godot scenes only — there is no editor GUI authoring path",
  "sourceOfTruth": "This schema file is the authority the compliance checker loads; no conformance rule is hardcoded in the checker. Adding a rule here changes checker behavior with no code change.",
  "contractVersion": "1.0",
  "sanctionedTuningOverrides": {
    "description": "Enumerated subset of balance values a world may override; everything else stays global"
  },
  "sanctionedWorldApiSurface": {
    "allowed": [
      "Axolotl Controller Interface",
      "Save Integration Interface",
      "Gill Mod Registration Interface",
      "Enemy Registration Interface",
      "Restoration Region Interface",
      "Collectible Registration Interface",
      "Camera Hint Interface",
      "Audio Event Interface",
      "HUD State Interface"
    ],
    "forbidden": [
      "filesystem access",
      "network access",
      "OS execution",
      "dynamic evaluation",
      "Core Module Dependency (internal engine wiring, not a world-facing interface)",
      "ALL Godot multiplayer and networking APIs per the Engine Feature Policy contract: @rpc, rpc, rpc_id, rpc_config, is_multiplayer_authority, set_multiplayer_authority, multiplayer, MultiplayerAPI, SceneMultiplayer, any MultiplayerPeer implementation, MultiplayerSynchronizer, MultiplayerSpawner"
    ],
    "description": "The exhaustive list of public interfaces a world module may call. The static-analysis gate rejects any world script reaching outside it. This list is verified against the actual graph edges, not authored from intent."
  }
}
```

### SENDS TO: World: Bubble Bay (shared-library)
- **Contract:** Level Contract v1
- **Protocol:** dependency
- **Their Technology:** godot

**Schema:**
```
{
  "optional": {
    "boss": {
      "default": "none"
    },
    "npcs": {
      "default": "none"
    },
    "music": {
      "default": "engine defaults apply, never silence"
    },
    "enemies": {
      "default": "none"
    },
    "cameraHints": {
      "default": "none",
      "description": "Camera hint volumes overriding framing declaratively; no custom camera code permitted"
    },
    "secretAreas": {
      "default": "none"
    },
    "collectibles": {
      "default": "none"
    },
    "customAbility": {
      "default": "none"
    },
    "tuningOverrides": {
      "default": "none",
      "description": "Only values in sanctionedTuningOverrides may be overridden; anything else is rejected"
    },
    "restorableRegions": {
      "default": "none",
      "description": "Each region declares states barren/resourced/restored plus a separate boolean unlocked flag"
    },
    "livesPerAttemptOverride": {
      "default": "global default applies"
    }
  },
  "required": {
    "spawnPoint": {
      "description": "Player spawn transform where the world begins"
    },
    "checkpoints": {
      "minCount": 1,
      "description": "One or more checkpoint volumes; anchor BOTH life refill and capability-state restore"
    },
    "finishCondition": {
      "description": "Declarative completion condition returning the player to the Open Lagoon hub"
    },
    "saveIntegration": {
      "description": "Declares the save keys this world reads and writes through the save-integration interface"
    },
    "controllerCompatibility": {
      "description": "Declares the Axolotl Controller interface version the world binds against"
    }
  },
  "moduleLayout": {
    "root": "worlds/<world_id>/",
    "scene": "world.tscn",
    "manifest": "world.json"
  },
  "authoringPath": "code and Godot scenes only — there is no editor GUI authoring path",
  "sourceOfTruth": "This schema file is the authority the compliance checker loads; no conformance rule is hardcoded in the checker. Adding a rule here changes checker behavior with no code change.",
  "contractVersion": "1.0",
  "sanctionedTuningOverrides": {
    "description": "Enumerated subset of balance values a world may override; everything else stays global"
  },
  "sanctionedWorldApiSurface": {
    "allowed": [
      "Axolotl Controller Interface",
      "Save Integration Interface",
      "Gill Mod Registration Interface",
      "Enemy Registration Interface",
      "Restoration Region Interface",
      "Collectible Registration Interface",
      "Camera Hint Interface",
      "Audio Event Interface",
      "HUD State Interface"
    ],
    "forbidden": [
      "filesystem access",
      "network access",
      "OS execution",
      "dynamic evaluation",
      "Core Module Dependency (internal engine wiring, not a world-facing interface)",
      "ALL Godot multiplayer and networking APIs per the Engine Feature Policy contract: @rpc, rpc, rpc_id, rpc_config, is_multiplayer_authority, set_multiplayer_authority, multiplayer, MultiplayerAPI, SceneMultiplayer, any MultiplayerPeer implementation, MultiplayerSynchronizer, MultiplayerSpawner"
    ],
    "description": "The exhaustive list of public interfaces a world module may call. The static-analysis gate rejects any world script reaching outside it. This list is verified against the actual graph edges, not authored from intent."
  }
}
```

### RECEIVES FROM: Asset Contract Validator (cli-tool)
- **Contract:** Asset Contract v1
- **Protocol:** custom
- **Their Technology:** python-backend

**Schema:**
```
{
  "categories": [
    "character",
    "creature",
    "prop",
    "environment",
    "audio"
  ],
  "assetLayout": "assets/<category>/<name>/",
  "humanReview": "style and art direction remain a human maintainer judgment; structural conformance is machine-checked",
  "contractVersion": "1.0",
  "provenanceSchema": {
    "tool": {
      "description": "Generator name and version; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "author": {
      "required": true
    },
    "prompt": {
      "description": "Prompt used; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "licenseTerms": {
      "required": true,
      "description": "Applicable license terms; for ai-generated assets these are the generator's terms of service"
    },
    "generationMethod": {
      "enum": [
        "ai-generated",
        "hand-authored"
      ],
      "required": true
    }
  },
  "requiredPerAsset": [
    "conforming source files",
    "provenance.json"
  ]
}
```

### RECEIVES FROM: CI Pipeline (ci-cd-pipeline)
- **Contract:** Core Module Dependency
- **Protocol:** dependency
- **Their Technology:** github-actions

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Player HUD (shared-library)
- **Contract:** HUD State Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Audio System (shared-library)
- **Contract:** Audio Event Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Input System (shared-library)
- **Contract:** Player Input Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Test Harness and Fixtures (cli-tool)
- **Contract:** Core Module Dependency
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: World: Reference Template (shared-library)
- **Contract:** Level Contract v1
- **Protocol:** dependency
- **Their Technology:** godot

**Schema:**
```
{
  "optional": {
    "boss": {
      "default": "none"
    },
    "npcs": {
      "default": "none"
    },
    "music": {
      "default": "engine defaults apply, never silence"
    },
    "enemies": {
      "default": "none"
    },
    "cameraHints": {
      "default": "none",
      "description": "Camera hint volumes overriding framing declaratively; no custom camera code permitted"
    },
    "secretAreas": {
      "default": "none"
    },
    "collectibles": {
      "default": "none"
    },
    "customAbility": {
      "default": "none"
    },
    "tuningOverrides": {
      "default": "none",
      "description": "Only values in sanctionedTuningOverrides may be overridden; anything else is rejected"
    },
    "restorableRegions": {
      "default": "none",
      "description": "Each region declares states barren/resourced/restored plus a separate boolean unlocked flag"
    },
    "livesPerAttemptOverride": {
      "default": "global default applies"
    }
  },
  "required": {
    "spawnPoint": {
      "description": "Player spawn transform where the world begins"
    },
    "checkpoints": {
      "minCount": 1,
      "description": "One or more checkpoint volumes; anchor BOTH life refill and capability-state restore"
    },
    "finishCondition": {
      "description": "Declarative completion condition returning the player to the Open Lagoon hub"
    },
    "saveIntegration": {
      "description": "Declares the save keys this world reads and writes through the save-integration interface"
    },
    "controllerCompatibility": {
      "description": "Declares the Axolotl Controller interface version the world binds against"
    }
  },
  "moduleLayout": {
    "root": "worlds/<world_id>/",
    "scene": "world.tscn",
    "manifest": "world.json"
  },
  "authoringPath": "code and Godot scenes only — there is no editor GUI authoring path",
  "sourceOfTruth": "This schema file is the authority the compliance checker loads; no conformance rule is hardcoded in the checker. Adding a rule here changes checker behavior with no code change.",
  "contractVersion": "1.0",
  "sanctionedTuningOverrides": {
    "description": "Enumerated subset of balance values a world may override; everything else stays global"
  },
  "sanctionedWorldApiSurface": {
    "allowed": [
      "Axolotl Controller Interface",
      "Save Integration Interface",
      "Gill Mod Registration Interface",
      "Enemy Registration Interface",
      "Restoration Region Interface",
      "Collectible Registration Interface",
      "Camera Hint Interface",
      "Audio Event Interface",
      "HUD State Interface"
    ],
    "forbidden": [
      "filesystem access",
      "network access",
      "OS execution",
      "dynamic evaluation",
      "Core Module Dependency (internal engine wiring, not a world-facing interface)",
      "ALL Godot multiplayer and networking APIs per the Engine Feature Policy contract: @rpc, rpc, rpc_id, rpc_config, is_multiplayer_authority, set_multiplayer_authority, multiplayer, MultiplayerAPI, SceneMultiplayer, any MultiplayerPeer implementation, MultiplayerSynchronizer, MultiplayerSpawner"
    ],
    "description": "The exhaustive list of public interfaces a world module may call. The static-analysis gate rejects any world script reaching outside it. This list is verified against the actual graph edges, not authored from intent."
  }
}
```

### RECEIVES FROM: World Static Analysis Gate (cli-tool)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "scope": [
    "core systems",
    "official worlds",
    "reference template",
    "community submissions"
  ],
  "rationale": "Single-player is a firm non-goal boundary in every phase. There is no network layer: no peers, no synchronizers, no authority checks, and no server-side validation scaffolding.",
  "description": "Engine features this project bans outright, enforced repo-wide by the World Static Analysis Gate as a merge-blocking CI check. This policy exists because ordinary Godot idiom and the technology guidance carried in this project's own node context are multiplayer-oriented; a contributor following normal engine practice would add networking without intending to. The ban is mechanical, not advisory.",
  "enforcement": {
    "tool": "world-static-analysis",
    "severity": "error",
    "mergeGate": "blocking"
  },
  "bannedFeature": "multiplayer and networking",
  "forbiddenSymbols": {
    "apis": [
      "multiplayer",
      "MultiplayerAPI",
      "SceneMultiplayer"
    ],
    "calls": [
      "rpc",
      "rpc_id",
      "rpc_config"
    ],
    "nodes": [
      "MultiplayerSynchronizer",
      "MultiplayerSpawner"
    ],
    "peers": [
      "MultiplayerPeer",
      "ENetMultiplayerPeer",
      "WebRTCMultiplayerPeer",
      "WebSocketMultiplayerPeer",
      "OfflineMultiplayerPeer"
    ],
    "authority": [
      "is_multiplayer_authority",
      "set_multiplayer_authority",
      "get_multiplayer_authority"
    ],
    "annotations": [
      "@rpc"
    ],
    "projectSettings": [
      "network/*",
      "any multiplayer autoload or peer configuration in project.godot"
    ]
  },
  "guidanceOverride": "Where general Godot documentation, engine samples, or catalog technology guidance demonstrate RPC-based movement or server-authority patterns, that guidance DOES NOT APPLY to this project. Implement movement, input, and state as local single-player logic."
}
```

## Technology Guidance

_Reference for executing the Implementation Tasks above — apply where relevant. The task list stands even where this guidance is thin._

**Purpose:** Open-source game engine for 2D and 3D games with its own GDScript language, C# support, and a scene-tree architecture

**SDK Initialization:**
```
# player.gd — client input, server authority via MultiplayerAPI
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    var input := Input.get_vector("left", "right", "forward", "back")
    move_intent.rpc_id(1, input)  # send intent to server (peer 1), never position

@rpc("any_peer", "call_remote", "unreliable_ordered")
func move_intent(input: Vector2) -> void:
    if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
        return  # reject spoofed intents
    velocity = _simulate(input)  # server simulates; clients receive replicated state
```

**Best Practices:**
- Use the scene tree and node composition for game architecture
- Leverage signals for decoupled communication between nodes
- Use resources (tres/res) for shared data and configuration
- Implement autoloads (singletons) sparingly for global state
- Use GDScript for gameplay logic and C# for complex systems
- Leverage AnimationPlayer and AnimationTree for state machines
- Use TileMaps and TileSets for 2D level design
- Export custom properties with @export for editor-configurable values

**Anti-Patterns to Avoid:**
- Overusing get_node() with hardcoded paths instead of exported NodePaths
- Not using signals, creating tight coupling between nodes
- Putting all logic in _process without delta time consideration
- Creating deep node hierarchies instead of flat compositions
- Not using typed GDScript (static typing) for better performance and safety
- Ignoring the scene instancing system and duplicating node trees

**Security:** The shipped game is fully inspectable — GDScript decompiles trivially and PCK files unpack, so no API keys, no server credentials, and no authoritative logic in the client: purchases, scores, and inventory mutations happen on a backend the player cannot edit. In multiplayer, clients send INTENT (input) and the server simulates — validate every RPC server-side (sender identity, argument bounds, rate) because @rpc("any_peer") means exactly that. Savegames are user-editable files: sign or checksum what matters competitively, and never load untrusted .tscn/.gd content — instancing a scene executes its scripts.

**Suggested File Structure:**
- `scripts/main.gd` (source)
- `scenes/main.tscn` (source)
- `project.godot` (config)
- `export_presets.cfg` (config)

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Axolotl Controller (this node calls/depends on it via Axolotl Controller Interface (dependency))
- Camera System (this node calls/depends on it via Core Module Dependency (dependency))
- Save System (this node calls/depends on it via Save Integration Interface (dependency))
- Lives and Checkpoint System (this node calls/depends on it via Checkpoint and Life Interface (dependency))
- World: Coral Cove (this node calls/depends on it via Level Contract v1 (dependency))
- World: Bubble Bay (this node calls/depends on it via Level Contract v1 (dependency))
- Player HUD (this node calls/depends on it via HUD State Interface (dependency))
- Audio System (this node calls/depends on it via Audio Event Interface (dependency))
- Input System (this node calls/depends on it via Player Input Interface (dependency))
- World: Reference Template (this node calls/depends on it via Level Contract v1 (dependency))

**Depends on THIS node being available:**
- Asset Contract Validator (initiates Asset Contract v1 against this node (custom))
- CI Pipeline (initiates Core Module Dependency against this node (dependency))
- Test Harness and Fixtures (initiates Core Module Dependency against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `docs/mvp-readiness.md` | doc | --- | draft |
| `docs/performance.md` | doc | --- | draft |
| `hub/open_lagoon.gd` | source | --- | draft |
| `project.godot` | config | --- | draft |
| `.nodespec/tests/req-017.tests.md` - Test plan for requirement: AI-Agent Contributor Workflow and Documentation | test-plan | markdown | draft |
| `hub/world_systems.gd` | source | --- | draft |
| `dev/fall_guard.gd` | source | --- | draft |
| `.nodespec/tests/req-006.tests.md` - Test plan for requirement: Level Contract v1 Specification | test-plan | markdown | draft |
| `hub/open_lagoon.tscn` | source | --- | draft |
| `assets/character/axolotl/axolotl_skin_normal.png` | design | --- | draft |
| `assets/environment/understory_fern/understory_fern.glb` | design | --- | draft |
| `assets/environment/river_reed/provenance.json` | config | --- | draft |
| `test/core/rendering/test_hero_anatomy.gd` | source | --- | draft |
| `test/hub/test_world_registry.gd` | source | --- | draft |
| `assets/character/axolotl/axolotl.glb` | design | --- | draft |
| `core/rendering/terrain/mossy_stone.tres` | source | --- | draft |
| `test/hub/hub_walk_probe.gd` | source | --- | draft |
| `assets/environment/river_boulder/provenance.json` | config | --- | draft |
| `assets/environment/fallen_log/provenance.json` | config | --- | draft |
| `core/rendering/materials/forest_canopy.tres` | source | --- | draft |
| `core/rendering/terrain/coral_shelf_stone.tres` | source | --- | draft |
| `core/rendering/terrain/river_stone.tres` | source | --- | draft |
| `test/hub/test_world_systems.gd` | source | --- | draft |
| `test/hub/run_hub_walk.gd` | source | --- | draft |
| `test/core/rendering/test_terrain_shell.gd` | source | --- | draft |
| `assets/environment/canopy_tree/canopy_tree.glb` | design | --- | draft |
| `test/perf/run_gpu_gate.gd` | source | --- | draft |
| `.nodespec/tests/req-021.tests.md` - Test plan for requirement: Licensing Policy — Code, Assets, and AI Provenance | test-plan | markdown | draft |
| `core/rendering/scatter_field.gd` | source | --- | draft |
| `core/rendering/terrain_surface.gdshader` | source | --- | draft |
| `core/rendering/base_environment.tres` | source | --- | draft |
| `assets/environment/river_boulder/river_boulder.glb` | design | --- | draft |
| `test/perf/perf_gate_probe.gd` | source | --- | draft |
| `assets/environment/river_reed/river_reed.glb` | design | --- | draft |
| `core/rendering/world_lighting.tscn` | source | --- | draft |
| `assets/environment/fallen_log/fallen_log.glb` | design | --- | draft |
| `core/rendering/world_lighting.gd` | source | --- | draft |
| `core/rendering/terrain/river_sand.tres` | source | --- | draft |
| `assets/environment/understory_fern/provenance.json` | config | --- | draft |
| `hub/hub_error.gd` | source | --- | draft |
| `core/rendering/vegetation_wind.gdshader` | source | --- | draft |
| `core/rendering/water_surface.tres` | source | --- | draft |
| `assets/character/axolotl/provenance.json` | config | --- | draft |
| `contracts/level_contract.v1.json` | schema | --- | draft |
| `hub/portal_tier.gd` | source | --- | draft |
| `.nodespec/tests/req-027.tests.md` - Test plan for requirement: Performance Targets | test-plan | markdown | draft |
| `core/rendering/render_quality.gd` | source | --- | draft |
| `tools/test_performance_targets.py` | source | --- | draft |
| `test/perf/run_perf_gate.gd` | source | --- | draft |
| `test/core/rendering/test_world_lighting.gd` | source | --- | draft |
| `test/core/rendering/test_hero_surface.gd` | source | --- | draft |
| `core/rendering/hero_skin.gd` | source | --- | draft |
| `core/rendering/materials/axolotl_skin.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_eye.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_eye_gleam.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_gill.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_detail.tres` | source | --- | draft |
| `test/core/rendering/test_hero_skin.gd` | source | --- | draft |
| `contracts/sanctioned_api.v1.json` | schema | --- | draft |
| `hub/contract_validator.gd` | source | --- | draft |
| `test/core/rendering/test_scatter_field.gd` | source | --- | draft |
| `test/contracts/test_level_contract.gd` | source | --- | draft |
| `hub/world_portal.gd` | source | --- | draft |
| `dev/greybox.tscn` | design | --- | draft |
| `assets/character/axolotl/axolotl_skin_detail.png` | design | --- | draft |
| `core/rendering/water_surface.gdshader` | source | --- | draft |
| `test/core/rendering/test_world_dressing.gd` | source | --- | draft |
| `assets/environment/rock_cluster/rock_cluster.glb` | design | --- | draft |
| `assets/environment/rock_cluster/provenance.json` | config | --- | draft |
| `assets/environment/coral_branch/coral_branch.glb` | design | --- | draft |
| `assets/environment/coral_branch/provenance.json` | config | --- | draft |
| `assets/environment/kelp_strand/kelp_strand.glb` | design | --- | draft |
| `assets/environment/kelp_strand/provenance.json` | config | --- | draft |
| `assets/environment/seagrass_tuft/seagrass_tuft.glb` | design | --- | draft |
| `assets/environment/seagrass_tuft/provenance.json` | config | --- | draft |
| `docs/level-contract.md` | doc | --- | draft |
| `contracts/performance_targets.v1.json` | config | --- | draft |
| `assets/environment/canopy_tree/provenance.json` | config | --- | draft |
| `hub/world_registry.gd` | source | --- | draft |
| `test/core/rendering/test_render_quality.gd` | source | --- | draft |
| `core/rendering/terrain_shell.gd` | source | --- | draft |
| `dev/run_smoke.gd` | source | --- | draft |
| `.nodespec/tests/req-009.tests.md` - Test plan for requirement: Open Lagoon Hub and World Loading | test-plan | markdown | draft |
| `core/rendering/hero_animator.gd` | source | --- | draft |
| `test/core/rendering/test_hero_animator.gd` | test-plan | --- | draft |
| `hub/world_loader.gd` | source | --- | draft |
| `dev/smoke_probe.gd` | source | --- | draft |
| `core/rendering/terrain/forest_earth.tres` | source | --- | draft |
