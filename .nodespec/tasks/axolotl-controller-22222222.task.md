# Task: Axolotl Controller

> **Scope:** implement ONLY this node ("Axolotl Controller"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node is pillar two of the game: two mechanically distinct movement grammars
joined by one signature transition skill. Everything else in the project binds to
its public interface, so its surface is effectively frozen the moment the first
world module ships against it — design the interface before the physics.

**Placement and shape.** This is a `shared-library` node: it lives in its own
directory under `core/`, exposes a `class_name`-registered public surface, and is
consumed by other systems and by world modules as a dependency. It is not an
autoload unless it genuinely needs one global instance — prefer an explicit
reference passed in over a singleton, because a singleton is untestable under
GdUnit4 without process-level teardown, and this project's whole verification
story runs through GdUnit4.

**Catalog guidance that does not apply here.** The Godot technology guidance in
this packet carries multiplayer sample code — `@rpc` annotations,
`is_multiplayer_authority`, `MultiplayerSynchronizer`. It is generic engine
guidance and it is forbidden in this project. REQ-030 bans the whole Godot
multiplayer surface, the Engine Feature Policy contract records the ban
machine-readably, and the World Static Analysis Gate fails CI on any occurrence
anywhere in `core/`, `worlds/` or the reference template. This is single-player
only, in every phase, with no deferral. Systems talk to each other through
signals and direct calls on the interfaces declared in this packet.

**Grammar switching is the hard part.** The criterion is exact: crossing a water
volume boundary switches grammar *in the same physics frame* as the crossing,
with no frame rendered in the previous grammar. That rules out reacting to an
`Area3D` `body_entered` signal in `_process` — signal delivery lands a frame
late. Do the volume test inside `_physics_process` before movement integration,
so detection and grammar switch happen in one tick. Momentum carries across the
switch at `controller.transition.momentum_retention_ratio`, applied to magnitude
rather than the vector, so a swimmer surfacing keeps speed without keeping an
underwater heading.

**Two state machines, one body.** Implement water and land as separate movement
strategies behind a common interface rather than as branches inside one
`_physics_process`, and keep the `CharacterBody3D` motion call shared. Water
grammar owns full 3D directional swimming, dive and a cooldown-governed bubble
boost; land grammar owns waddle, hop and climbing on surfaces tagged climbable
(use a physics layer or a group for the tag — never a name check). The
water-powered dash sits above both grammars because it works in either, and its
charge recharges only while in water, which is what makes it read as a transition
skill rather than a generic ability.

**Tongue grapple.** Range is `controller.grapple.max_range_m`, tested inclusively
— an anchor exactly at max range attaches, one beyond it is rejected. Anchor
discovery is a group query plus a raycast, not a proximity scan of the whole
scene.

**The public interface is the deliverable.** Worlds bind to movement state,
capability modifiers and ability hooks without touching controller internals.
That means: movement state exposed as a read-only enum plus signals on change;
capability modifiers applied through the Capability Modifier Interface as
multiplicative factors this node consumes but never authors; ability hooks
registered by the Gill Mod framework rather than known to the controller.
Anything a world can only achieve by reaching into a private member is a hole in
this interface — fix the interface, not the world. The World Static Analysis Gate
enforces the resulting allowlist, so an omission here becomes a rejected world
module later.

**No magic numbers.** Every balance value this system uses is read from the
Balance and Tuning Data node through the Tuning Data Interface, never declared as
a GDScript constant. REQ-025 makes that a checked property: a cited tuning key
that does not exist in the tuning data fails a test, and changing a value must
alter behavior with no recompile.

**Input.** Read player intent from the Input System's Player Input Interface.
Worlds must never read raw input, and neither should this node reach into
`Input` directly for gameplay verbs — that indirection is what makes rebinding
and context-sensitive bindings possible.

**Verification.** GdUnit4 tests live under `test/` mirroring this directory, and
each test name carries the requirement id it proves (`test_req_0NN_...`) — the
harness parses that id back out and reports it as the failing rule, which is how
a contributor or agent locates what broke. Unit-tier tests exercise this system's
logic as plain objects; integration-tier tests drive it against the real
controller and the real save interface via GdUnit4's `scene_runner`, because the
criteria explicitly reject isolation-only coverage. The one manual criterion here — that both grammars feel distinct and
pleasurable — is proven by hands-on play and a task-doc tick, not by a test.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Audio System (godot) per Contract "Audio Event Interface" (dependency).** <!-- t:218035d2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Balance and Tuning Data (godot) per Contract "Tuning Data Interface" (dependency).** <!-- t:03c75344 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface OpenAxolotl Game Client consumes, per Contract "Axolotl Controller Interface" (dependency).** <!-- t:68abdd87 -->
  Record the endpoint/identifiers OpenAxolotl Game Client needs in this node's config artifacts — coordinate with OpenAxolotl Game Client.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Regeneration and Capability System consumes, per Contract "Capability Modifier Interface" (dependency).** <!-- t:a57b3f8c -->
  Record the endpoint/identifiers Regeneration and Capability System needs in this node's config artifacts — coordinate with Regeneration and Capability System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface Gill Mod Ability Framework consumes, per Contract "Axolotl Controller Interface" (dependency).** <!-- t:2ab653c5 -->
  Record the endpoint/identifiers Gill Mod Ability Framework needs in this node's config artifacts — coordinate with Gill Mod Ability Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface Player HUD consumes, per Contract "HUD State Interface" (dependency).** <!-- t:3e14fc4a -->
  Record the endpoint/identifiers Player HUD needs in this node's config artifacts — coordinate with Player HUD.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface Input System consumes, per Contract "Player Input Interface" (dependency).** <!-- t:39cc30a2 -->
  Record the endpoint/identifiers Input System needs in this node's config artifacts — coordinate with Input System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement: "Water grammar supports full 3D directional swimming, dive, and a bubble boost governed by a cooldown" (REQ-001).** <!-- t:e2760bfa -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "Water grammar supports full 3D directional swimming, dive, and a bubble boost governed by a cooldown" — possible coordination point: Contract "Capability Modifier Interface" (dependency) from Regeneration and Capability System (keyword signal only)
- [ ] **T11 — Implement: "Land grammar supports waddle locomotion, hop, and climbing on surfaces tagged as climbable" (REQ-001).** <!-- t:25ece100 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "Land grammar supports waddle locomotion, hop, and climbing on surfaces tagged as climbable" — possible coordination point: Contract "Capability Modifier Interface" (dependency) from Regeneration and Capability System (keyword signal only)
- [ ] **T12 — Implement: "Tongue grapple attaches to anchor points at or within tuning key controller.grapple.max_range_m, rejects anchors beyond it, and pulls the axolotl to the attached anchor" (REQ-001).** <!-- t:70f44dc6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "Tongue grapple attaches to anchor points at or within tuning key controller.grapple.max_range_m, rejects anchors beyond it, and pulls the axolotl to the attached anchor" — possible coordination point: Contract "Tuning Data Interface" (dependency) to Balance and Tuning Data (keyword signal only)
- [ ] **T13 — Implement: "Both movement grammars feel distinct, responsive, and pleasurable in hands-on play" (REQ-001).** <!-- t:f6d9a45b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "Both movement grammars feel distinct, responsive, and pleasurable in hands-on play" — possible coordination point: Contract "Capability Modifier Interface" (dependency) from Regeneration and Capability System (keyword signal only)
- [ ] **T14 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-001: Axolotl Character Controller — Dual Movement Grammars
Category: functional | Status: in-progress
The player character controller implementing two mechanically distinct movement grammars joined by a signature transition skill. WATER: fast directional swimming, current interaction, diving, bubble boost, underwater tunnel traversal. LAND: waddle locomotion, hop, climbing on wet/climbable surfaces, tongue grapple to anchor points. TRANSITION: a water-powered dash usable in both grammars, charged in water and spent anywhere, which is the signature move binding the two grammars together. The controller exposes a stable, documented public interface that any Level Contract-conforming world binds against, so no world ever re-implements or forks movement. This is Pillar 2 and the core answer to "why is this not a cute skin on generic platformer mechanics."

**Acceptance criteria — your task boxes:**
- [x] Crossing a water volume boundary switches movement grammar in the same physics frame as the crossing, with no frame rendered in the previous grammar, and retains momentum magnitude per tuning key controller.transition.momentum_retention_ratio
  → THIS NODE: internal logic — possible coordination point: Contract "Tuning Data Interface" (dependency) to Balance and Tuning Data (keyword signal only)
- [ ] Water grammar supports full 3D directional swimming, dive, and a bubble boost governed by a cooldown
  → covered by Task T10
- [ ] Land grammar supports waddle locomotion, hop, and climbing on surfaces tagged as climbable
  → covered by Task T11
- [ ] Tongue grapple attaches to anchor points at or within tuning key controller.grapple.max_range_m, rejects anchors beyond it, and pulls the axolotl to the attached anchor
  → covered by Task T12
- [x] Water-powered dash is usable in both grammars, consumes a charge, and recharges only while in water
  → THIS NODE: internal logic — possible coordination point: Contract "Capability Modifier Interface" (dependency) from Regeneration and Capability System (keyword signal only)
- [x] Controller exposes a documented public interface (movement state, capability modifiers, ability hooks) that worlds bind to without modifying controller internals
  → THIS NODE: internal logic — possible coordination point: Contract "Capability Modifier Interface" (dependency) from Regeneration and Capability System (keyword signal only)
- [ ] Both movement grammars feel distinct, responsive, and pleasurable in hands-on play (manual)
  → covered by Task T13

## Interface Contracts

### RECEIVES FROM: OpenAxolotl Game Client (game-client)
- **Contract:** Axolotl Controller Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Regeneration and Capability System (shared-library)
- **Contract:** Capability Modifier Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Gill Mod Ability Framework (shared-library)
- **Contract:** Axolotl Controller Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Player HUD (shared-library)
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

### RECEIVES FROM: Input System (shared-library)
- **Contract:** Player Input Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Balance and Tuning Data (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

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
- Audio System (this node calls/depends on it via Audio Event Interface (dependency))
- Balance and Tuning Data (this node calls/depends on it via Tuning Data Interface (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Client (initiates Axolotl Controller Interface against this node (dependency))
- Regeneration and Capability System (initiates Capability Modifier Interface against this node (dependency))
- Gill Mod Ability Framework (initiates Axolotl Controller Interface against this node (dependency))
- Player HUD (initiates HUD State Interface against this node (dependency))
- Input System (initiates Player Input Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-001.tests.md` - Test plan for requirement: Axolotl Character Controller — Dual Movement Grammars | test-plan | markdown | draft |
| `core/controller/capability_modifiers.gd` | source | --- | draft |
| `core/controller/water_dash.gd` | source | --- | draft |
| `core/controller/tongue_grapple.gd` | source | --- | draft |
| `core/controller/axolotl_controller.gd` | source | --- | draft |
| `core/controller/movement_grammar.gd` | source | --- | draft |
| `test/core/controller/test_axolotl_controller.gd` | source | --- | draft |
| `core/controller/player_intent.gd` | source | --- | draft |
