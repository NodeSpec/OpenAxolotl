# Task: World Static Analysis Gate

> **Scope:** implement ONLY this node ("World Static Analysis Gate"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CLI Tool
**Technology:** Python
**Description:** Command-line interface application for developer or operator interaction

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This is the project's security and policy gate. It answers: does this GDScript
call anything it is not sanctioned to call? Two requirements ride on it — the
community submission pipeline (REQ-020) and the project-wide multiplayer ban
(REQ-030) — and both are load-bearing. This is a family game whose contribution
pipeline explicitly welcomes AI agents; this gate plus mandatory human review is
what stands between that pipeline and arbitrary code execution on a player's
machine.

**Catalog guidance that does not apply here.** The Python technology guidance in
this packet describes a FastAPI web service — `fastapi`/`uvicorn`, SQLAlchemy
async sessions, Celery workers, `src/main.py` + `src/routes/__init__.py`, CORS
and JWT. None of it applies. This node is a short-lived, synchronous,
filesystem-only command-line program with no HTTP surface, no database, no
broker and no async runtime. Ignore the suggested file structure in T1 and the
SDK/API pattern snippets entirely. What carries over from that guidance is only
the tooling advice: `uv` for the environment with a committed lockfile, `ruff`
for lint and format, `pytest` with fixtures, strict `mypy`, and pinned
dependencies.

**Packaging.** All four Python validators share one distribution at `tools/`
(`tools/pyproject.toml`, package `openaxolotl_tools`), because they share the
fixture corpus, the result-emitting code and the CI invocation convention;
splitting them into four distributions would duplicate all three. Each tool is
its own subpackage with its own console entry point declared in
`[project.scripts]`. `openaxolotl_tools/common/` holds the pieces every tool
needs: `result.py` (builds and serialises the `Validator CLI Invocation`
result object), `cli.py` (the shared `argparse` parent parser giving every tool
the identical `--target/--format/--fail-fast` surface), and `schemas.py`
(loads and caches the JSON Schema files from `contracts/`).

**Scope is wider than community worlds.** The multiplayer check scans core
systems, official worlds, the reference template *and* submissions. The
sanctioned-API check scans world modules only, since core systems legitimately
call engine APIs a world may not. Encode that split as two rule sets over one
walker, driven by which directory a file sits in, rather than as two tools.

**Parsing GDScript.** There is no GDScript AST library to lean on, and regex over
source text is not defensible for a security gate — it misses continuation lines
and flags matches inside strings and comments. Implement a small tokenizer in
`openaxolotl_tools/staticgate/gdscript.py` that strips comments and string
literals first, then extracts identifiers, annotations and call targets with line
numbers. Everything downstream works on that token stream. Getting the tokenizer
right is the majority of this node's real work; budget accordingly, and test it
against source containing forbidden identifiers inside comments and strings,
which must NOT be flagged.

**Forbidden classes.** The sanctioned-API rule set rejects filesystem
(`FileAccess`, `DirAccess`), network (`HTTPRequest`, `HTTPClient`, `TCPServer`,
`StreamPeer*`, `PacketPeer*`), OS execution (`OS.execute`, `OS.shell_open`) and
dynamic evaluation (`Expression`, `GDScript.new()` + `reload`, `load` on a
runtime-built path) — anything outside the `sanctionedApi` block of
`contracts/level_contract.v1.json`. The multiplayer rule set rejects `@rpc`
annotations, `rpc`/`rpc_id`/`rpc_config` calls, `is_multiplayer_authority` and
`set_multiplayer_authority`, the `multiplayer` property and `MultiplayerAPI`,
every `MultiplayerPeer` implementation (ENet, WebRTC, WebSocket), and the
`MultiplayerSynchronizer` and `MultiplayerSpawner` node types in both `.gd` and
`.tscn` files. Scene files matter: a `MultiplayerSpawner` can be added in the
editor without any script mentioning it.

**Both rule sets are data.** They load from `contracts/sanctioned_api.v1.json`
and `contracts/engine_feature_policy.v1.json`. The multiplayer ban therefore
exists in three enforced places — the policy file this gate reads, the Level
Contract's forbidden list covering world modules, and `project.godot` settings —
which is what makes "no multiplayer" a machine-checked property rather than a
line in the README. Violation output names the specific API and the file, per the
criterion.

**project.godot check.** A dedicated rule parses `project.godot` and fails on any
networking or multiplayer autoload, peer configuration or network-related
setting. This is a text-format INI file; parse it with `configparser` rather than
pattern-matching.

**Emitting results.** Every run ends by constructing exactly one result object
matching the `Validator CLI Invocation` `resultSchema` — `tool`,
`schemaVersion`, `target`, `passed`, `violations[]` — and printing it as JSON
when `--format json`, or as a human-readable rendering of the same object when
`--format text` (the default). Text output is a *rendering* of the object, never
a separate code path, so a message can never appear in one format and not the
other. `schemaVersion` is read from the schema file actually loaded, not
hardcoded, so a contract bump is visible in every result. Exit codes follow the
contract exactly: `0` clean, `1` one or more `severity: "error"` violations, `2`
invocation error — bad arguments, unreadable target, missing or unparseable
schema file. A `warning`-severity violation is reported but never changes the
exit code, per the contract's merge-gate rule. `violations[].rule` is a stable
dotted id, never a message string, because that id is what an AI agent maps back
to the contract element it broke.

**Fixtures.** The malicious fixture world exercises each forbidden call class,
and a separate multiplayer fixture file exercises each banned multiplayer API.
Both come from the Test Harness via Shared Test Fixtures. Assert per-class
rejection — one test per forbidden class asserting the specific rule id — so a
gate that stopped detecting one class cannot hide behind the others still firing.

**Human review is not optional and not this tool's job.** The gate is
pre-screening. Branch protection requiring maintainer approval is configured by
the CI Pipeline node; never add a path that lets a green gate merge on its own.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with World: Coral Cove (godot) per Contract "Sanctioned World API Surface" (dependency).** <!-- t:77966695 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with World: Bubble Bay (godot) per Contract "Sanctioned World API Surface" (dependency).** <!-- t:e89d6a3b -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Test Harness and Fixtures (python-backend) per Contract "Shared Test Fixtures" (dependency).** <!-- t:7d12e948 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement the integration with World: Reference Template (godot) per Contract "Sanctioned World API Surface" (dependency).** <!-- t:399a52b4 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Implement the integration with OpenAxolotl Game Client (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:a43ca1c2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement the integration with Axolotl Controller (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:546745c9 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Implement the integration with Input System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:bd31611d -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Implement the integration with Save System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:a9445cde -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement the integration with Camera System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:ef1a4794 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T11 — Implement the integration with Regeneration and Capability System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:e9c4ec1d -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T12 — Implement the integration with Lives and Checkpoint System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:981e0017 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T13 — Implement the integration with Gill Mod Ability Framework (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:62d73ed0 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T14 — Implement the integration with Restoration State System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:fe53cd74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T15 — Implement the integration with Collectibles System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:52cba5a0 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T16 — Implement the integration with Drift Fleet Enemy Framework (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:974ec999 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T17 — Implement the integration with Player HUD (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:73051846 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T18 — Implement the integration with Audio System (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:6ce65853 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T19 — Implement the integration with Balance and Tuning Data (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:1662a95a -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T20 — Implement the integration with Flagship Boss Encounter (godot) per Contract "Engine Feature Policy" (dependency).** <!-- t:ea212880 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T21 — Expose the interface CI Pipeline consumes, per Contract "Validator CLI Invocation" (ipc).** <!-- t:a39cc42a -->
  Record the endpoint/identifiers CI Pipeline needs in this node's config artifacts — coordinate with CI Pipeline.
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T22 — Implement: "Every submission passes automated contract-compliance and content-policy pre-screening before human review" (REQ-020).** <!-- t:e8911875 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Every submission passes automated contract-compliance and content-policy pre-screening before human review" — possible coordination point: Contract "Engine Feature Policy" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T23 — Implement: "Static analysis rejects any community world script calling filesystem, network, OS-execution, or dynamic-evaluation APIs, or otherwise reaching outside the sanctioned world API surface defined by the Level Contract" (REQ-020).** <!-- t:3e43b10a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Static analysis rejects any community world script calling filesystem, network, OS-execution, or dynamic-evaluation APIs, or otherwise reaching outside the sanctioned world API surface defined by the Level Contract" — possible coordination point: Contract "Sanctioned World API Surface" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T24 — Implement: "A deliberately malicious fixture world attempting each forbidden call class is rejected by the static-analysis gate" (REQ-020).** <!-- t:73df8c93 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "A deliberately malicious fixture world attempting each forbidden call class is rejected by the static-analysis gate"
- [ ] **T25 — Implement: "Every submission requires explicit human maintainer approval before merge, enforced by branch protection with no automated-only merge path" (REQ-020).** <!-- t:acff5839 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Every submission requires explicit human maintainer approval before merge, enforced by branch protection with no automated-only merge path"
- [ ] **T26 — Implement: "Accepted community worlds are packaged and surfaced in the hub as Community Lagoon portals credited to their author" (REQ-020).** <!-- t:98bb8640 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Accepted community worlds are packaged and surfaced in the hub as Community Lagoon portals credited to their author" — possible coordination point: Contract "Sanctioned World API Surface" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T27 — Implement: "Portal tiering distinguishes Official, Community, and Experimental Lagoons" (REQ-020).** <!-- t:ace3d125 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Portal tiering distinguishes Official, Community, and Experimental Lagoons" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T28 — Implement: "Pipeline opens only after Level Contract v1 is declared frozen" (REQ-020).** <!-- t:82d1202c -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Pipeline opens only after Level Contract v1 is declared frozen" — possible coordination point: Contract "Validator CLI Invocation" (ipc) from CI Pipeline (keyword signal only)
- [ ] **T29 — Implement: "Content guidelines and the maintainer review checklist are documented for a family-audience bar" (REQ-020).** <!-- t:1ef7c7b6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Content guidelines and the maintainer review checklist are documented for a family-audience bar" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T30 — Implement: "A static check rejects any use of Godot multiplayer APIs, including @rpc annotations, rpc/rpc_id/rpc_config calls, is_multiplayer_authority and set_multiplayer_authority, the multiplayer property and MultiplayerAPI, any MultiplayerPeer implementation (ENet, WebRTC, WebSocket), and MultiplayerSynchronizer or MultiplayerSpawner nodes" (REQ-030).** <!-- t:7da78021 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "A static check rejects any use of Godot multiplayer APIs, including @rpc annotations, rpc/rpc_id/rpc_config calls, is_multiplayer_authority and set_multiplayer_authority, the multiplayer property and MultiplayerAPI, any MultiplayerPeer implementation (ENet, WebRTC, WebSocket), and MultiplayerSynchronizer or MultiplayerSpawner nodes" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T31 — Implement: "The check scans core systems, official worlds, the reference template, and community submissions — not world modules alone" (REQ-030).** <!-- t:aef4417f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "The check scans core systems, official worlds, the reference template, and community submissions — not world modules alone" — possible coordination point: Contract "Sanctioned World API Surface" (dependency) to World: Reference Template (keyword signal only)
- [ ] **T32 — Implement: "A fixture file exercising each forbidden multiplayer API class is rejected by the check, with output naming the specific API and file" (REQ-030).** <!-- t:29a6bb9d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "A fixture file exercising each forbidden multiplayer API class is rejected by the check, with output naming the specific API and file" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T33 — Implement: "The check runs as a required CI check and a pull request introducing any forbidden multiplayer API cannot merge" (REQ-030).** <!-- t:9275cc64 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "The check runs as a required CI check and a pull request introducing any forbidden multiplayer API cannot merge" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T34 — Implement: "project.godot declares no networking or multiplayer autoloads, peer configuration, or network-related project settings" (REQ-030).** <!-- t:528ceeb3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "project.godot declares no networking or multiplayer autoloads, peer configuration, or network-related project settings" — possible coordination point: Contract "Engine Feature Policy" (dependency) to Player HUD (keyword signal only)
- [ ] **T35 — Implement: "No architecture node is a game server, and no networking or multiplayer service appears anywhere in the project's technology set" (REQ-030).** <!-- t:207ac8e5 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "No architecture node is a game server, and no networking or multiplayer service appears anywhere in the project's technology set" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T36 — Implement: "The Level Contract's sanctioned world API surface lists every multiplayer API as forbidden, so world modules are covered by the same ban as core" (REQ-030).** <!-- t:481025f1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "The Level Contract's sanctioned world API surface lists every multiplayer API as forbidden, so world modules are covered by the same ban as core" — possible coordination point: Contract "Sanctioned World API Surface" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T37 — Implement: "Contributor documentation states the project is single-player only and warns that general Godot multiplayer guidance and engine sample code do not apply here" (REQ-030).** <!-- t:97ad73fc -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-030 "Contributor documentation states the project is single-player only and warns that general Godot multiplayer guidance and engine sample code do not apply here" — possible coordination point: Contract "Engine Feature Policy" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T38 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-020: Community Lagoon Submission Pipeline (Post-MVP)
Category: business | Status: in-progress
POST-MVP, and strictly sequenced: this opens only after Level Contract v1 is frozen. Opening earlier means every core update breaks early contributor worlds and burns exactly the goodwill the project depends on. Contributors submit worlds by pull request; accepted worlds become packaged community worlds surfaced in the hub as Community Lagoon portals, visibly credited to their author. SECURITY MODEL: community worlds are GDScript modules exactly like official worlds — the code-authoring premise applies to everyone, and there is no separate data-only contributor path. Safety therefore comes from two controls rather than from forbidding code: automated static analysis that rejects any world script reaching outside the sanctioned world API surface defined by the Level Contract (no filesystem, network, OS-execution, or dynamic-evaluation calls), and mandatory human maintainer review before merge. Both stages are required; there is no automated-only merge path. This gating is load-bearing rather than a nicety — this is a game marketed to families with an AI-agent-authored contribution pipeline, and an ungated path would be the project's largest risk. Tiering is Official, Community, and Experimental Lagoons.

**Acceptance criteria — your task boxes:**
- [ ] Every submission passes automated contract-compliance and content-policy pre-screening before human review
  → covered by Task T22
- [ ] Static analysis rejects any community world script calling filesystem, network, OS-execution, or dynamic-evaluation APIs, or otherwise reaching outside the sanctioned world API surface defined by the Level Contract
  → covered by Task T23
- [ ] A deliberately malicious fixture world attempting each forbidden call class is rejected by the static-analysis gate
  → covered by Task T24
- [ ] Every submission requires explicit human maintainer approval before merge, enforced by branch protection with no automated-only merge path
  → covered by Task T25
- [ ] Accepted community worlds are packaged and surfaced in the hub as Community Lagoon portals credited to their author
  → covered by Task T26
- [ ] Portal tiering distinguishes Official, Community, and Experimental Lagoons
  → covered by Task T27
- [ ] Pipeline opens only after Level Contract v1 is declared frozen (manual)
  → covered by Task T28
- [ ] Content guidelines and the maintainer review checklist are documented for a family-audience bar (manual)
  → covered by Task T29

### REQ-030: No Multiplayer — Enforced Single-Player Constraint
Category: technical | Status: in-progress
"No multiplayer" is a firm non-goal in every phase, and this requirement makes it machine-enforced rather than merely stated. The enforcement exists because the constraint is actively working against its environment: general Godot guidance, sample code, and the engine's own documentation are heavily multiplayer-oriented, and the technology guidance embedded in this project's own node context carries an RPC/server-authority movement sample that directly contradicts this non-goal. A human or AI contributor following ordinary Godot idiom would reach for @rpc and MultiplayerAPI without ever intending to add multiplayer. A documented non-goal cannot stop that; a merge-blocking static check can. Scope is deliberately repo-wide — core systems, official worlds, the reference template, and community submissions alike — because the risk is highest in exactly the core movement and input code where the contradicting sample appears. Single-player also means no network layer at all: no peers, no synchronizers, no authority checks, no server-side validation scaffolding.

**Acceptance criteria — your task boxes:**
- [ ] A static check rejects any use of Godot multiplayer APIs, including @rpc annotations, rpc/rpc_id/rpc_config calls, is_multiplayer_authority and set_multiplayer_authority, the multiplayer property and MultiplayerAPI, any MultiplayerPeer implementation (ENet, WebRTC, WebSocket), and MultiplayerSynchronizer or MultiplayerSpawner nodes
  → covered by Task T30
- [ ] The check scans core systems, official worlds, the reference template, and community submissions — not world modules alone
  → covered by Task T31
- [ ] A fixture file exercising each forbidden multiplayer API class is rejected by the check, with output naming the specific API and file
  → covered by Task T32
- [ ] The check runs as a required CI check and a pull request introducing any forbidden multiplayer API cannot merge
  → covered by Task T33
- [ ] project.godot declares no networking or multiplayer autoloads, peer configuration, or network-related project settings
  → covered by Task T34
- [ ] No architecture node is a game server, and no networking or multiplayer service appears anywhere in the project's technology set
  → covered by Task T35
- [ ] The Level Contract's sanctioned world API surface lists every multiplayer API as forbidden, so world modules are covered by the same ban as core
  → covered by Task T36
- [ ] Contributor documentation states the project is single-player only and warns that general Godot multiplayer guidance and engine sample code do not apply here (manual)
  → covered by Task T37

## Interface Contracts

### SENDS TO: World: Coral Cove (shared-library)
- **Contract:** Sanctioned World API Surface
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "description": "The complete set of engine and project APIs a world module may call, and the classes of call it may never make. Enforced by the World Static Analysis Gate as a merge-blocking CI check against every world — official worlds, the reference template, and community submissions alike. This surface is the security boundary for community-contributed code: worlds ship GDScript like any other module, so safety comes from this allowlist plus mandatory human review, never from an automated-only merge path.",
  "enforcement": {
    "tool": "world-static-analysis",
    "severity": "error",
    "appliesTo": [
      "worlds/<world_id>/**/*.gd",
      "worlds/<world_id>/**/*.tscn",
      "worlds/<world_id>/world.json"
    ],
    "mergeGate": "blocking",
    "defaultPosture": "deny — a symbol absent from sanctionedInterfaces is a violation, not an omission"
  },
  "sourceOfTruth": "The allowlist below is derived from the interfaces the Level Contract declares. This schema is the authority the static-analysis gate loads; no rule is hardcoded in the gate. Adding a rule here changes gate behavior with no code change.",
  "contractVersion": "1.0",
  "violationOutput": {
    "exitCode": "non-zero on any violation",
    "requirement": "Failure output names the offending file, line, the specific forbidden symbol, and the call class it violates, as structured machine-readable output an AI coding agent can parse and self-correct against."
  },
  "guidanceOverride": "Where general Godot documentation, engine samples, or catalog technology guidance demonstrate RPC-based movement, server-authority patterns, direct file access for saves, or raw Input reads, that guidance DOES NOT APPLY to world modules in this project. Implement world logic as local single-player code against the sanctioned interfaces above.",
  "forbiddenCallClasses": {
    "network": {
      "symbols": [
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "StreamPeerTLS",
        "PacketPeerUDP",
        "TCPServer",
        "UDPServer",
        "WebSocketPeer",
        "IP"
      ],
      "rationale": "Single-player, offline game. There is no network layer of any kind."
    },
    "filesystem": {
      "symbols": [
        "FileAccess",
        "DirAccess",
        "ResourceSaver",
        "ProjectSettings.globalize_path",
        "ConfigFile"
      ],
      "rationale": "A world module has no legitimate reason to touch the filesystem; persistence goes through the Save Integration Interface."
    },
    "multiplayer": {
      "symbols": {
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
          "network/*"
        ]
      },
      "rationale": "No multiplayer, in any phase — a firm non-goal, not a deferral. This mirrors the Engine Feature Policy applied to core systems, so world modules are covered by exactly the same ban as core (REQ-030)."
    },
    "osExecution": {
      "symbols": [
        "OS.execute",
        "OS.create_process",
        "OS.shell_open",
        "OS.set_environment",
        "OS.get_environment"
      ],
      "rationale": "Executing processes or shelling out from world code is arbitrary code execution on a contributor's machine."
    },
    "coreInternals": {
      "symbols": [
        "any member prefixed _ on a core system",
        "get_node paths into core/ scene trees",
        "direct instantiation of core system classes not exposed via a sanctioned interface"
      ],
      "rationale": "Reaching past a published interface into a core system's private members is the hole that makes a world unforkable. If a world can only achieve something this way, the interface is wrong — fix the interface, not the world."
    },
    "dynamicEvaluation": {
      "symbols": [
        "Expression",
        "GDScript.new",
        "Object.call",
        "Object.callv",
        "Object.set_script",
        "ResourceLoader.load with a non-literal path",
        "load with a non-literal path",
        "str2var",
        "bytes_to_var"
      ],
      "rationale": "Dynamic evaluation defeats static analysis entirely — it is how an allowlist gets bypassed."
    }
  },
  "sanctionedInterfaces": {
    "save": {
      "contract": "Save Integration Interface",
      "description": "The only permitted persistence path. Worlds never open, read, or write a save file directly."
    },
    "audio": {
      "contract": "Audio Event Interface"
    },
    "input": {
      "contract": "Player Input Interface",
      "description": "Player intent only. Worlds MUST NOT read the Godot Input singleton or raw InputEvent directly."
    },
    "camera": {
      "contract": "Camera Hint Interface",
      "description": "Declarative hint volumes only; no custom camera code."
    },
    "tuning": {
      "contract": "Tuning Data Interface",
      "description": "Read-only, and overrides limited to the Level Contract's sanctionedTuningOverrides set."
    },
    "enemies": {
      "contract": "Enemy Registration Interface"
    },
    "abilities": {
      "contract": "Gill Mod Registration Interface"
    },
    "controller": {
      "contract": "Axolotl Controller Interface",
      "description": "Movement state (read-only), capability modifiers, and ability hooks. Worlds never touch controller internals."
    },
    "checkpoints": {
      "contract": "Checkpoint and Life Interface"
    },
    "restoration": {
      "contract": "Restoration Region Interface",
      "description": "Declare restorable regions and query or advance their state."
    },
    "collectibles": {
      "contract": "Collectible Registration Interface"
    }
  }
}
```

### SENDS TO: World: Bubble Bay (shared-library)
- **Contract:** Sanctioned World API Surface
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "description": "The complete set of engine and project APIs a world module may call, and the classes of call it may never make. Enforced by the World Static Analysis Gate as a merge-blocking CI check against every world — official worlds, the reference template, and community submissions alike. This surface is the security boundary for community-contributed code: worlds ship GDScript like any other module, so safety comes from this allowlist plus mandatory human review, never from an automated-only merge path.",
  "enforcement": {
    "tool": "world-static-analysis",
    "severity": "error",
    "appliesTo": [
      "worlds/<world_id>/**/*.gd",
      "worlds/<world_id>/**/*.tscn",
      "worlds/<world_id>/world.json"
    ],
    "mergeGate": "blocking",
    "defaultPosture": "deny — a symbol absent from sanctionedInterfaces is a violation, not an omission"
  },
  "sourceOfTruth": "The allowlist below is derived from the interfaces the Level Contract declares. This schema is the authority the static-analysis gate loads; no rule is hardcoded in the gate. Adding a rule here changes gate behavior with no code change.",
  "contractVersion": "1.0",
  "violationOutput": {
    "exitCode": "non-zero on any violation",
    "requirement": "Failure output names the offending file, line, the specific forbidden symbol, and the call class it violates, as structured machine-readable output an AI coding agent can parse and self-correct against."
  },
  "guidanceOverride": "Where general Godot documentation, engine samples, or catalog technology guidance demonstrate RPC-based movement, server-authority patterns, direct file access for saves, or raw Input reads, that guidance DOES NOT APPLY to world modules in this project. Implement world logic as local single-player code against the sanctioned interfaces above.",
  "forbiddenCallClasses": {
    "network": {
      "symbols": [
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "StreamPeerTLS",
        "PacketPeerUDP",
        "TCPServer",
        "UDPServer",
        "WebSocketPeer",
        "IP"
      ],
      "rationale": "Single-player, offline game. There is no network layer of any kind."
    },
    "filesystem": {
      "symbols": [
        "FileAccess",
        "DirAccess",
        "ResourceSaver",
        "ProjectSettings.globalize_path",
        "ConfigFile"
      ],
      "rationale": "A world module has no legitimate reason to touch the filesystem; persistence goes through the Save Integration Interface."
    },
    "multiplayer": {
      "symbols": {
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
          "network/*"
        ]
      },
      "rationale": "No multiplayer, in any phase — a firm non-goal, not a deferral. This mirrors the Engine Feature Policy applied to core systems, so world modules are covered by exactly the same ban as core (REQ-030)."
    },
    "osExecution": {
      "symbols": [
        "OS.execute",
        "OS.create_process",
        "OS.shell_open",
        "OS.set_environment",
        "OS.get_environment"
      ],
      "rationale": "Executing processes or shelling out from world code is arbitrary code execution on a contributor's machine."
    },
    "coreInternals": {
      "symbols": [
        "any member prefixed _ on a core system",
        "get_node paths into core/ scene trees",
        "direct instantiation of core system classes not exposed via a sanctioned interface"
      ],
      "rationale": "Reaching past a published interface into a core system's private members is the hole that makes a world unforkable. If a world can only achieve something this way, the interface is wrong — fix the interface, not the world."
    },
    "dynamicEvaluation": {
      "symbols": [
        "Expression",
        "GDScript.new",
        "Object.call",
        "Object.callv",
        "Object.set_script",
        "ResourceLoader.load with a non-literal path",
        "load with a non-literal path",
        "str2var",
        "bytes_to_var"
      ],
      "rationale": "Dynamic evaluation defeats static analysis entirely — it is how an allowlist gets bypassed."
    }
  },
  "sanctionedInterfaces": {
    "save": {
      "contract": "Save Integration Interface",
      "description": "The only permitted persistence path. Worlds never open, read, or write a save file directly."
    },
    "audio": {
      "contract": "Audio Event Interface"
    },
    "input": {
      "contract": "Player Input Interface",
      "description": "Player intent only. Worlds MUST NOT read the Godot Input singleton or raw InputEvent directly."
    },
    "camera": {
      "contract": "Camera Hint Interface",
      "description": "Declarative hint volumes only; no custom camera code."
    },
    "tuning": {
      "contract": "Tuning Data Interface",
      "description": "Read-only, and overrides limited to the Level Contract's sanctionedTuningOverrides set."
    },
    "enemies": {
      "contract": "Enemy Registration Interface"
    },
    "abilities": {
      "contract": "Gill Mod Registration Interface"
    },
    "controller": {
      "contract": "Axolotl Controller Interface",
      "description": "Movement state (read-only), capability modifiers, and ability hooks. Worlds never touch controller internals."
    },
    "checkpoints": {
      "contract": "Checkpoint and Life Interface"
    },
    "restoration": {
      "contract": "Restoration Region Interface",
      "description": "Declare restorable regions and query or advance their state."
    },
    "collectibles": {
      "contract": "Collectible Registration Interface"
    }
  }
}
```

### RECEIVES FROM: CI Pipeline (ci-cd-pipeline)
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** github-actions

**Schema:**
```
{
  "exitCodes": {
    "0": "all checks passed",
    "1": "one or more conformance violations found",
    "2": "invocation error (bad arguments, unreadable target, missing schema file)"
  },
  "mergeGate": "Any tool exiting non-zero blocks merge. Warnings do not block but are reported.",
  "invocation": {
    "form": "<tool-command> [--target <path>] [--format json|text] [--fail-fast]",
    "localParity": "the documented local command and the CI invocation MUST be identical, so a contributor cannot pass locally and fail in CI",
    "formatDefault": "text for humans; json required in CI and for agent self-verification",
    "targetDefault": "repository root; a world or asset module path narrows the run"
  },
  "description": "How CI invokes the four repo validators (Level Contract Checker, Asset Contract Validator, World Static Analysis Gate, Test Harness) and how results come back. Consumers are CI jobs and AI agents self-verifying before submission, so output is structured rather than prose.",
  "resultSchema": {
    "type": "object",
    "required": [
      "tool",
      "schemaVersion",
      "target",
      "passed",
      "violations"
    ],
    "properties": {
      "tool": {
        "enum": [
          "level-contract-checker",
          "asset-contract-validator",
          "world-static-analysis",
          "test-harness"
        ],
        "type": "string"
      },
      "passed": {
        "type": "boolean"
      },
      "target": {
        "type": "string"
      },
      "violations": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "rule",
            "severity",
            "file",
            "message"
          ],
          "properties": {
            "file": {
              "type": "string"
            },
            "line": {
              "type": "integer"
            },
            "rule": {
              "type": "string",
              "description": "Stable rule id, so an agent can map a failure back to the contract element that produced it"
            },
            "message": {
              "type": "string"
            },
            "severity": {
              "enum": [
                "error",
                "warning"
              ],
              "type": "string"
            },
            "remediation": {
              "type": "string",
              "description": "What to change to satisfy the rule"
            }
          }
        }
      },
      "schemaVersion": {
        "type": "string",
        "description": "Version of the contract or ruleset evaluated against"
      }
    }
  }
}
```

### SENDS TO: Test Harness and Fixtures (cli-tool)
- **Contract:** Shared Test Fixtures
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: World: Reference Template (shared-library)
- **Contract:** Sanctioned World API Surface
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "description": "The complete set of engine and project APIs a world module may call, and the classes of call it may never make. Enforced by the World Static Analysis Gate as a merge-blocking CI check against every world — official worlds, the reference template, and community submissions alike. This surface is the security boundary for community-contributed code: worlds ship GDScript like any other module, so safety comes from this allowlist plus mandatory human review, never from an automated-only merge path.",
  "enforcement": {
    "tool": "world-static-analysis",
    "severity": "error",
    "appliesTo": [
      "worlds/<world_id>/**/*.gd",
      "worlds/<world_id>/**/*.tscn",
      "worlds/<world_id>/world.json"
    ],
    "mergeGate": "blocking",
    "defaultPosture": "deny — a symbol absent from sanctionedInterfaces is a violation, not an omission"
  },
  "sourceOfTruth": "The allowlist below is derived from the interfaces the Level Contract declares. This schema is the authority the static-analysis gate loads; no rule is hardcoded in the gate. Adding a rule here changes gate behavior with no code change.",
  "contractVersion": "1.0",
  "violationOutput": {
    "exitCode": "non-zero on any violation",
    "requirement": "Failure output names the offending file, line, the specific forbidden symbol, and the call class it violates, as structured machine-readable output an AI coding agent can parse and self-correct against."
  },
  "guidanceOverride": "Where general Godot documentation, engine samples, or catalog technology guidance demonstrate RPC-based movement, server-authority patterns, direct file access for saves, or raw Input reads, that guidance DOES NOT APPLY to world modules in this project. Implement world logic as local single-player code against the sanctioned interfaces above.",
  "forbiddenCallClasses": {
    "network": {
      "symbols": [
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "StreamPeerTLS",
        "PacketPeerUDP",
        "TCPServer",
        "UDPServer",
        "WebSocketPeer",
        "IP"
      ],
      "rationale": "Single-player, offline game. There is no network layer of any kind."
    },
    "filesystem": {
      "symbols": [
        "FileAccess",
        "DirAccess",
        "ResourceSaver",
        "ProjectSettings.globalize_path",
        "ConfigFile"
      ],
      "rationale": "A world module has no legitimate reason to touch the filesystem; persistence goes through the Save Integration Interface."
    },
    "multiplayer": {
      "symbols": {
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
          "network/*"
        ]
      },
      "rationale": "No multiplayer, in any phase — a firm non-goal, not a deferral. This mirrors the Engine Feature Policy applied to core systems, so world modules are covered by exactly the same ban as core (REQ-030)."
    },
    "osExecution": {
      "symbols": [
        "OS.execute",
        "OS.create_process",
        "OS.shell_open",
        "OS.set_environment",
        "OS.get_environment"
      ],
      "rationale": "Executing processes or shelling out from world code is arbitrary code execution on a contributor's machine."
    },
    "coreInternals": {
      "symbols": [
        "any member prefixed _ on a core system",
        "get_node paths into core/ scene trees",
        "direct instantiation of core system classes not exposed via a sanctioned interface"
      ],
      "rationale": "Reaching past a published interface into a core system's private members is the hole that makes a world unforkable. If a world can only achieve something this way, the interface is wrong — fix the interface, not the world."
    },
    "dynamicEvaluation": {
      "symbols": [
        "Expression",
        "GDScript.new",
        "Object.call",
        "Object.callv",
        "Object.set_script",
        "ResourceLoader.load with a non-literal path",
        "load with a non-literal path",
        "str2var",
        "bytes_to_var"
      ],
      "rationale": "Dynamic evaluation defeats static analysis entirely — it is how an allowlist gets bypassed."
    }
  },
  "sanctionedInterfaces": {
    "save": {
      "contract": "Save Integration Interface",
      "description": "The only permitted persistence path. Worlds never open, read, or write a save file directly."
    },
    "audio": {
      "contract": "Audio Event Interface"
    },
    "input": {
      "contract": "Player Input Interface",
      "description": "Player intent only. Worlds MUST NOT read the Godot Input singleton or raw InputEvent directly."
    },
    "camera": {
      "contract": "Camera Hint Interface",
      "description": "Declarative hint volumes only; no custom camera code."
    },
    "tuning": {
      "contract": "Tuning Data Interface",
      "description": "Read-only, and overrides limited to the Level Contract's sanctionedTuningOverrides set."
    },
    "enemies": {
      "contract": "Enemy Registration Interface"
    },
    "abilities": {
      "contract": "Gill Mod Registration Interface"
    },
    "controller": {
      "contract": "Axolotl Controller Interface",
      "description": "Movement state (read-only), capability modifiers, and ability hooks. Worlds never touch controller internals."
    },
    "checkpoints": {
      "contract": "Checkpoint and Life Interface"
    },
    "restoration": {
      "contract": "Restoration Region Interface",
      "description": "Declare restorable regions and query or advance their state."
    },
    "collectibles": {
      "contract": "Collectible Registration Interface"
    }
  }
}
```

### SENDS TO: OpenAxolotl Game Client (game-client)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Axolotl Controller (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Input System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Save System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Camera System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Regeneration and Capability System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Lives and Checkpoint System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Gill Mod Ability Framework (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Restoration State System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Collectibles System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Player HUD (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Audio System (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Balance and Tuning Data (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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

### SENDS TO: Flagship Boss Encounter (shared-library)
- **Contract:** Engine Feature Policy
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

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
- World: Coral Cove (this node calls/depends on it via Sanctioned World API Surface (dependency))
- World: Bubble Bay (this node calls/depends on it via Sanctioned World API Surface (dependency))
- Test Harness and Fixtures (this node calls/depends on it via Shared Test Fixtures (dependency))
- World: Reference Template (this node calls/depends on it via Sanctioned World API Surface (dependency))
- OpenAxolotl Game Client (this node calls/depends on it via Engine Feature Policy (dependency))
- Axolotl Controller (this node calls/depends on it via Engine Feature Policy (dependency))
- Input System (this node calls/depends on it via Engine Feature Policy (dependency))
- Save System (this node calls/depends on it via Engine Feature Policy (dependency))
- Camera System (this node calls/depends on it via Engine Feature Policy (dependency))
- Regeneration and Capability System (this node calls/depends on it via Engine Feature Policy (dependency))
- Lives and Checkpoint System (this node calls/depends on it via Engine Feature Policy (dependency))
- Gill Mod Ability Framework (this node calls/depends on it via Engine Feature Policy (dependency))
- Restoration State System (this node calls/depends on it via Engine Feature Policy (dependency))
- Collectibles System (this node calls/depends on it via Engine Feature Policy (dependency))
- Drift Fleet Enemy Framework (this node calls/depends on it via Engine Feature Policy (dependency))
- Player HUD (this node calls/depends on it via Engine Feature Policy (dependency))
- Audio System (this node calls/depends on it via Engine Feature Policy (dependency))
- Balance and Tuning Data (this node calls/depends on it via Engine Feature Policy (dependency))
- Flagship Boss Encounter (this node calls/depends on it via Engine Feature Policy (dependency))

**Depends on THIS node being available:**
- CI Pipeline (initiates Validator CLI Invocation against this node (ipc))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-020.tests.md` - Test plan for requirement: Community Lagoon Submission Pipeline (Post-MVP) | test-plan | markdown | draft |
| `.nodespec/tests/req-030.tests.md` - Test plan for requirement: No Multiplayer — Enforced Single-Player Constraint | test-plan | markdown | draft |
