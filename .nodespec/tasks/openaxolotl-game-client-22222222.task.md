# Task: OpenAxolotl Game Client

> **Scope:** implement ONLY this node ("OpenAxolotl Game Client"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Game Client
**Technology:** Godot
**Description:** Game client application handling rendering, input, and local simulation

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

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
holds GdUnit4 itself. The Python tooling lives under `tools/` and the shared
test fixtures under `fixtures/`; both carry a `.gdignore` file so Godot's
importer never scans them — this matters because the fixture set deliberately
contains malformed and malicious world modules that would otherwise break
editor import for everyone.

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
- [ ] **T16 — Implement: "Contract is published as a machine-readable schema file that the compliance checker loads as its single source of truth, with no conformance rules hardcoded in the checker" (REQ-006).** <!-- t:8a448cc0 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Contract is published as a machine-readable schema file that the compliance checker loads as its single source of truth, with no conformance rules hardcoded in the checker"
- [ ] **T17 — Implement: "A prose contract document explains every schema element and its rationale for human contributors" (REQ-006).** <!-- t:f54e24ad -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A prose contract document explains every schema element and its rationale for human contributors" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T18 — Implement: "A documented migration path describes how a v1 world is brought forward when the contract version increments" (REQ-006).** <!-- t:05b606b3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A documented migration path describes how a v1 world is brought forward when the contract version increments" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T19 — Implement: "A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone" (REQ-006).** <!-- t:92ae5f33 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T20 — Implement: "Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it" (REQ-006).** <!-- t:a8f5e226 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T21 — Implement: "Hub discovers installed world modules at runtime from the worlds directory with no hardcoded world list" (REQ-009).** <!-- t:fb1796f6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Hub discovers installed world modules at runtime from the worlds directory with no hardcoded world list" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T22 — Implement: "Entering a portal loads the corresponding world at its spawn point, and completing the finish condition returns the player to the hub" (REQ-009).** <!-- t:232d1763 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Entering a portal loads the corresponding world at its spawn point, and completing the finish condition returns the player to the hub" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T23 — Implement: "Adding, removing, or replacing a world module changes the available portals without any edit to hub code" (REQ-009).** <!-- t:3abf07a5 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Adding, removing, or replacing a world module changes the available portals without any edit to hub code" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T24 — Implement: "A world module that fails to load or fails contract validation is surfaced as unavailable without crashing or blocking the hub" (REQ-009).** <!-- t:5801f026 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "A world module that fails to load or fails contract validation is surfaced as unavailable without crashing or blocking the hub" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T25 — Implement: "Portals carry a tier designation (Official, Community, Experimental) and are visually distinguished by tier" (REQ-009).** <!-- t:46fe597b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Portals carry a tier designation (Official, Community, Experimental) and are visually distinguished by tier" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T26 — Implement: "Hub reflects per-world completion and restoration progress read through the save-integration interface" (REQ-009).** <!-- t:00981ae1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Hub reflects per-world completion and restoration progress read through the save-integration interface" — possible coordination point: Contract "Save Integration Interface" (dependency) to Save System (keyword signal only)
- [ ] **T27 — Implement: "A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world" (REQ-017).** <!-- t:88c0ed62 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Reference Template (keyword signal only)
- [ ] **T28 — Implement: "Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written" (REQ-017).** <!-- t:687cbf04 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written" — possible coordination point: Contract "Asset Contract v1" (custom) from Asset Contract Validator (keyword signal only)
- [ ] **T29 — Implement: "Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo" (REQ-017).** <!-- t:ce3124be -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T30 — Implement: "Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples" (REQ-017).** <!-- t:f50808d7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T31 — Implement: "README states the agent-authored contribution workflow with a concrete example prompt" (REQ-017).** <!-- t:9d36c5b8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "README states the agent-authored contribution workflow with a concrete example prompt" — possible coordination point: Contract "HUD State Interface" (dependency) to Player HUD (keyword signal only)
- [ ] **T32 — Implement: "An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker" (REQ-017).** <!-- t:0426c75f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T33 — Implement: "A baseline target PC specification is documented, and the frame-rate target, the maximum permitted frame-time spike, and the world load-time budget on that baseline are each stated as numbers" (REQ-027).** <!-- t:6e50e9a1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "A baseline target PC specification is documented, and the frame-rate target, the maximum permitted frame-time spike, and the world load-time budget on that baseline are each stated as numbers" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T34 — Implement: "Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal" (REQ-027).** <!-- t:6305f4b4 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T35 — Implement: "A restoration state transition completes without exceeding the documented maximum frame-time spike" (REQ-027).** <!-- t:4c8aa8d6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "A restoration state transition completes without exceeding the documented maximum frame-time spike" — possible coordination point: Contract "HUD State Interface" (dependency) to Player HUD (keyword signal only)
- [ ] **T36 — Implement: "World load time from selecting a hub portal to player control stays within the documented load-time budget" (REQ-027).** <!-- t:8609e8b4 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "World load time from selecting a hub portal to player control stays within the documented load-time budget" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T37 — Implement: "A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached" (REQ-027).** <!-- t:ba2d3e65 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached" — possible coordination point: Contract "Core Module Dependency" (dependency) from Test Harness and Fixtures (keyword signal only)
- [ ] **T38 — Implement: "The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case" (REQ-027).** <!-- t:447b635f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-027 "The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case"
- [ ] **T39 — Implement: "Code license is chosen and applied to the repository" (REQ-021).** <!-- t:281343c1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Code license is chosen and applied to the repository" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T40 — Implement: "Official art and audio asset license is chosen, documented, and distinguished from the code license" (REQ-021).** <!-- t:f8fd989b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Official art and audio asset license is chosen, documented, and distinguished from the code license" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T41 — Implement: "Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing" (REQ-021).** <!-- t:207df9ff -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T42 — Implement: "Contributor licensing terms for submitted worlds and assets are documented in the contribution guide" (REQ-021).** <!-- t:6f240208 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Contributor licensing terms for submitted worlds and assets are documented in the contribution guide" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T43 — Implement: "Licensing decision is resolved before the public README and contribution guide ship" (REQ-021).** <!-- t:ac788e6d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Licensing decision is resolved before the public README and contribution guide ship" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T44 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.

**Your first action — expand these work orders.** Each task above guarantees WHAT must be covered, not HOW. Before writing any code or configuration, expand every task with the concrete implementation steps for THIS technology in THIS project — the specific resources, settings, files, schemas, and tests — using the Configuration, Interface Contracts, Technology Guidance, and node context as your references. Record the expanded list in this section via update_artifact (propose_patches) after this doc is accepted, keeping task IDs, criterion citations, and open `[PLACEHOLDER: …]` tags intact. Resolve placeholders with the user through the proposal flow; this node is never complete while one remains open. When the work orders are implemented, verify through the test lane: run get_test_plan for each requirement this node serves, implement and run the plan's tests, and report outcomes via report_test_results — passing results are the evidence that flips criteria met.

## Configuration

User-selected configuration for this component (honor these choices):
- **csharp:** not used - no .cs files, no Mono/.NET assemblies, no C# build step. The catalog line 'use GDScript for gameplay logic and C# for complex systems' does NOT apply here.
- **engine:** Godot 4.x, GDScript 2.0
- **typing:** statically typed GDScript throughout (typed params, returns, members)
- **language:** GDScript
- **rationale:** One language keeps the contribution surface narrow for humans and AI agents alike; a second toolchain doubles build, review and static-gate parser burden for no gameplay gain.

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

### REQ-006: Level Contract v1 Specification
Category: technical | Status: in-progress
THE ANCHOR REQUIREMENT of the entire project. A versioned specification defining what any world module must provide to be a valid OpenAxolotl world, published in TWO forms: a MACHINE-READABLE SCHEMA FILE that the compliance checker consumes as its single source of truth, and a PROSE DOCUMENT explaining each element and its rationale to human contributors. Publishing the schema as the authority is what makes conformance genuinely testable rather than a matter of reading a document carefully. REQUIRED elements: spawn point, checkpoints, finish condition, axolotl controller compatibility, save integration. OPTIONAL elements: collectibles, enemies, boss, custom ability, secret areas, NPCs, per-world lives-per-attempt override. Checkpoints are REQUIRED (not optional) because they anchor two separate systems: life refill and capability-state restore. The contract also defines the SANCTIONED WORLD API SURFACE — the public interfaces a world module may call — which is what the community static-analysis gate enforces against. The contract must be explicitly versioned with a defined v1-to-v2 migration story, and frozen at v1 only after the official MVP worlds have battle-tested it. Worlds are authored as code and Godot scenes only; there is no editor GUI authoring path, which keeps the contract surface narrow and checkable.

**Acceptance criteria — your task boxes:**
- [ ] Contract is published as a machine-readable schema file that the compliance checker loads as its single source of truth, with no conformance rules hardcoded in the checker
  → covered by Task T16
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
  → covered by Task T17
- [ ] A documented migration path describes how a v1 world is brought forward when the contract version increments (manual)
  → covered by Task T18
- [ ] A contributor unfamiliar with the codebase can produce a conforming world from the contract document alone (manual)
  → covered by Task T19
- [ ] Contract is frozen at v1 only after the official MVP worlds have been built against it and their friction fed back into it (manual)
  → covered by Task T20

### REQ-009: Open Lagoon Hub and World Loading
Category: functional | Status: in-progress
The hub that makes the modular architecture visible as a place. The Open Lagoon is a central space containing portals to worlds; the player enters a discrete, bounded, checkpointed world through a portal and returns on completion. Level selection is deliberately discrete rather than an interconnected open world. The hub discovers available world modules at runtime from the worlds directory rather than referencing a hardcoded list, which is what allows a world to be added, forked, or replaced without editing the hub. Portals are tiered and visually distinguished — Official Lagoons at MVP, with Community and Experimental tiers reserved for the post-MVP community layer. A world that fails to load must not break the hub.

**Acceptance criteria — your task boxes:**
- [ ] Hub discovers installed world modules at runtime from the worlds directory with no hardcoded world list
  → covered by Task T21
- [ ] Entering a portal loads the corresponding world at its spawn point, and completing the finish condition returns the player to the hub
  → covered by Task T22
- [ ] Adding, removing, or replacing a world module changes the available portals without any edit to hub code
  → covered by Task T23
- [ ] A world module that fails to load or fails contract validation is surfaced as unavailable without crashing or blocking the hub
  → covered by Task T24
- [ ] Portals carry a tier designation (Official, Community, Experimental) and are visually distinguished by tier
  → covered by Task T25
- [ ] Hub reflects per-world completion and restoration progress read through the save-integration interface
  → covered by Task T26

### REQ-017: AI-Agent Contributor Workflow and Documentation
Category: technical | Status: in-progress
The requirement that produces the project's distinctive public identity: an open-source game designed for humans AND AI coding agents to extend together. A contributor must be able to open any AI coding agent, point it at this repository, say "create a new OpenAxolotl level set inside a giant aquarium where the player uses Bubble Gills to climb to the top," and get a compliant world. That only works if the repository carries machine-readable, agent-consumable documentation of everything an agent needs: the architecture, the Level Contract, the Asset Contract, Godot and GDScript conventions, existing mechanics and their extension interfaces, acceptance criteria, and how to run the checkers and tests to self-verify before submitting. This documentation is a first-class deliverable, not README garnish, and it must be validated by actually driving an agent through it end to end.

**Acceptance criteria — your task boxes:**
- [ ] A reference example world exists, passes the compliance checker, and is documented as the canonical starting point for a new world
  → covered by Task T27
- [ ] Documentation states the exact commands to run the Level Contract checker, the Asset Contract validator, and the test suite locally, and a test proves those documented commands succeed as written
  → covered by Task T28
- [ ] Repository documents the architecture, Level Contract, Asset Contract, and Godot/GDScript conventions in a form an AI coding agent can consume directly from the repo (manual)
  → covered by Task T29
- [ ] Documentation enumerates the extension interfaces for abilities, enemies, and worlds with worked examples (manual)
  → covered by Task T30
- [ ] README states the agent-authored contribution workflow with a concrete example prompt (manual)
  → covered by Task T31
- [ ] An AI coding agent, given only the repository and a one-sentence world brief, produces a world that passes the compliance checker (manual)
  → covered by Task T32

### REQ-027: Performance Targets
Category: non-functional | Status: in-progress
A colorful 3D platformer for families on unspecified PC hardware needs stated performance targets, and this project has a specific risk most platformers do not: restoration state changes swap traversable geometry at runtime, potentially across a large region, while Dredgers can revert it mid-encounter. That is a hitch waiting to happen at exactly the moment the game is trying to deliver its most satisfying visual payoff. Targets also matter for the contribution pipeline — a community world that tanks frame rate is a defect the automated pre-screen should be able to catch, which requires a number to check against. Includes frame rate on a defined baseline machine, world load time from hub portal, and a bound on the hitch introduced by a restoration transition.

**Acceptance criteria — your task boxes:**
- [ ] A baseline target PC specification is documented, and the frame-rate target, the maximum permitted frame-time spike, and the world load-time budget on that baseline are each stated as numbers
  → covered by Task T33
- [ ] Official worlds sustain the documented frame-rate target on the baseline specification during normal traversal
  → covered by Task T34
- [ ] A restoration state transition completes without exceeding the documented maximum frame-time spike
  → covered by Task T35
- [ ] World load time from selecting a hub portal to player control stays within the documented load-time budget
  → covered by Task T36
- [ ] A performance regression test runs in CI against an official world and fails when any of the three documented targets is breached
  → covered by Task T37
- [ ] The game remains smooth during a Flagship encounter combined with a restoration reversion, the heaviest expected load case (manual)
  → covered by Task T38

### REQ-021: Licensing Policy — Code, Assets, and AI Provenance
Category: business | Status: pending
A NAMED OPEN ITEM that blocks the public-facing README and contribution guide. The project's headline claim is "fork it," which requires an explicit and defensible split between the code license and the official art/audio license — these likely cannot both be maximally permissive if the axolotl character IP is to stay controlled. This decision is entangled with AI-art provenance: assets generated through external AI tools carry the generator's terms of service, captured per-asset in provenance.json, which may constrain how official and community art can be relicensed or redistributed. Both must be resolved together, not separately, and must be resolved before any public contribution workflow copy is written. Contributor licensing terms for submitted worlds and assets are part of this decision.

**Acceptance criteria — your task boxes:**
- [ ] Code license is chosen and applied to the repository (manual)
  → covered by Task T39
- [ ] Official art and audio asset license is chosen, documented, and distinguished from the code license (manual)
  → covered by Task T40
- [ ] Policy documents how AI-generated asset provenance and generator terms of service affect redistribution and relicensing (manual)
  → covered by Task T41
- [ ] Contributor licensing terms for submitted worlds and assets are documented in the contribution guide (manual)
  → covered by Task T42
- [ ] Licensing decision is resolved before the public README and contribution guide ship (manual)
  → covered by Task T43

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
| `project.godot` | config | --- | draft |
| `.nodespec/tests/req-017.tests.md` - Test plan for requirement: AI-Agent Contributor Workflow and Documentation | test-plan | markdown | draft |
| `dev/fall_guard.gd` | source | --- | draft |
| `.nodespec/tests/req-006.tests.md` - Test plan for requirement: Level Contract v1 Specification | test-plan | markdown | draft |
| `.nodespec/tests/req-021.tests.md` - Test plan for requirement: Licensing Policy — Code, Assets, and AI Provenance | test-plan | markdown | draft |
| `contracts/level_contract.v1.json` | schema | --- | draft |
| `.nodespec/tests/req-027.tests.md` - Test plan for requirement: Performance Targets | test-plan | markdown | draft |
| `contracts/sanctioned_api.v1.json` | schema | --- | draft |
| `test/contracts/test_level_contract.gd` | source | --- | draft |
| `dev/greybox.tscn` | design | --- | draft |
| `docs/level-contract.md` | doc | --- | draft |
| `dev/run_smoke.gd` | source | --- | draft |
| `.nodespec/tests/req-009.tests.md` - Test plan for requirement: Open Lagoon Hub and World Loading | test-plan | markdown | draft |
| `dev/smoke_probe.gd` | source | --- | draft |
