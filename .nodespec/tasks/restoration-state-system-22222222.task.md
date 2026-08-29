# Task: Restoration State System

> **Scope:** implement ONLY this node ("Restoration State System"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node carries pillar three — the world regenerates with you — and it is the
mechanical form of the open-source metaphor. Its state model is deliberately
small and exactly specified, because both the save system and every world module
depend on it being predictable.

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

**Exactly three states plus one flag.** A region exposes `barren`, `resourced`,
`restored` — no more, no intermediate, no "restoring" transient — and a separate
boolean `unlocked` flag. The two axes are independent and that independence is
load-bearing: a region with `unlocked == false` cannot advance out of `barren`
no matter how many resources are delivered (the Flagship gates it), and reverting
a restored region to `barren` leaves `unlocked` set, so the player redoes the
restoration without refighting the boss. Model them as two separate fields; the
moment they are collapsed into one enum, the revert criterion becomes impossible
to satisfy.

**Restoration must change traversal.** The criterion says advancing state opens
paths that were not previously available, not only visuals. Implement state
change as enabling or disabling collision geometry and navigation, with the
visual change riding along — if a designer can satisfy a state change by swapping
a material, the pillar is lost. A test asserts a path is untraversable at
`barren` and traversable at `restored` by driving the controller through it.

**Reversion.** Dredger attacks revert a restored region to `barren`, and the
revert must be reflected in traversal and in persistence, not just in the
displayed state. Route reversion through the same state-transition path as
advancement so the two can never diverge — one `set_state()` with the geometry,
audio and save side effects hanging off it.

**Declarative regions.** A world declares its restorable regions through the
Level Contract, not through bespoke scripting. This node reads that declaration
and instantiates regions from it; a world author writes data, never a state
machine. That is what keeps the sanctioned world API surface narrow enough for
the static gate to check.

**Persistence and neighbours.** State and the unlocked flag persist per region
through the Save Integration Interface. Collectibles feed resources in; the Drift
Fleet framework and the Flagship encounter drive reversion and unlocking; the
HUD reads current state and progress toward the next; the Audio System shifts
ambience on transition. All of those are interface calls in this packet — emit
semantic transition signals and let consumers subscribe, rather than calling into
each consumer.

**No magic numbers.** Every balance value this system uses is read from the
Balance and Tuning Data node through the Tuning Data Interface, never declared as
a GDScript constant. REQ-025 makes that a checked property: a cited tuning key
that does not exist in the tuning data fails a test, and changing a value must
alter behavior with no recompile.

**Verification.** GdUnit4 tests live under `test/` mirroring this directory, and
each test name carries the requirement id it proves (`test_req_0NN_...`) — the
harness parses that id back out and reports it as the failing rule, which is how
a contributor or agent locates what broke. Unit-tier tests exercise this system's
logic as plain objects; integration-tier tests drive it against the real
controller and the real save interface via GdUnit4's `scene_runner`, because the
criteria explicitly reject isolation-only coverage. The "visually dramatic and satisfying" criterion is manual.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Save System (godot) per Contract "Save Integration Interface" (dependency).** <!-- t:bcbdac74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-008 "Restoration state and unlocked flag per region persist through the save-integration interface across sessions" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T3 — Implement the integration with Audio System (godot) per Contract "Audio Event Interface" (dependency).** <!-- t:218035d2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Balance and Tuning Data (godot) per Contract "Tuning Data Interface" (dependency).** <!-- t:03c75344 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Collectibles System consumes, per Contract "Restoration Region Interface" (dependency).** <!-- t:e38c9912 -->
  Record the endpoint/identifiers Collectibles System needs in this node's config artifacts — coordinate with Collectibles System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-008 "A region exposes a queryable restoration state with exactly the progression barren, resourced, restored, and a separate boolean unlocked flag" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-008 "A region whose unlocked flag is false cannot advance out of barren regardless of resources delivered" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-008 "Advancing restoration state changes traversable geometry or opens paths that were not previously available, not only visuals" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-008 "Dredger attacks revert a restored region to barren, and the reverted state is reflected in traversal and persistence" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-008 "Reverting a region to barren leaves its unlocked flag set, so restoration can be redone without refighting the Flagship" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-008 "A world declares its restorable regions declaratively through the Level Contract rather than through bespoke scripting" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T6 — Expose the interface Drift Fleet Enemy Framework consumes, per Contract "Restoration Region Interface" (dependency).** <!-- t:cd966a9d -->
  Record the endpoint/identifiers Drift Fleet Enemy Framework needs in this node's config artifacts — coordinate with Drift Fleet Enemy Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface World: Coral Cove consumes, per Contract "Restoration Region Interface" (dependency).** <!-- t:7a4f7070 -->
  Record the endpoint/identifiers World: Coral Cove needs in this node's config artifacts — coordinate with World: Coral Cove.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface World: Bubble Bay consumes, per Contract "Restoration Region Interface" (dependency).** <!-- t:4245b3fe -->
  Record the endpoint/identifiers World: Bubble Bay needs in this node's config artifacts — coordinate with World: Bubble Bay.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Expose the interface Player HUD consumes, per Contract "HUD State Interface" (dependency).** <!-- t:3e14fc4a -->
  Record the endpoint/identifiers Player HUD needs in this node's config artifacts — coordinate with Player HUD.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Expose the interface Flagship Boss Encounter consumes, per Contract "Restoration Region Interface" (dependency).** <!-- t:db3d4e32 -->
  Record the endpoint/identifiers Flagship Boss Encounter needs in this node's config artifacts — coordinate with Flagship Boss Encounter.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T11 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T12 — Implement: "The broken-to-restored transformation is visually dramatic and satisfying in hands-on play" (REQ-008).** <!-- t:65920f8b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-008 "The broken-to-restored transformation is visually dramatic and satisfying in hands-on play"
- [ ] **T13 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-008: World Restoration State System
Category: functional | Status: in-progress
Pillar 3 — the mechanic that carries the open-source metaphor without a child ever needing to get the metaphor. Regions within a world hold a first-class, inspectable restoration state with EXACTLY three states — barren, resourced, restored — plus a SEPARATE BOOLEAN UNLOCKED FLAG that gates whether progression may begin at all. The flag is deliberately not a fourth state: defeating a region's Flagship sets the flag, permitting a barren region to start progressing, while the state enum itself stays a simple three-step progression. The player collects a resource, restores water, plants bloom, wildlife appears, and new traversal paths open — so restoration is genuinely mechanical, gating progression and opening routes, not merely a cosmetic swap. Restoration state persists through the save system. It is also reversible under pressure: Dredger enemies flatten restored terrain back to barren, which gives the loop stakes and makes those encounters urgent.

**Acceptance criteria — your task boxes:**
- [ ] A region exposes a queryable restoration state with exactly the progression barren, resourced, restored, and a separate boolean unlocked flag
  → covered by Task T5
- [ ] A region whose unlocked flag is false cannot advance out of barren regardless of resources delivered
  → covered by Task T5
- [ ] Advancing restoration state changes traversable geometry or opens paths that were not previously available, not only visuals
  → covered by Task T5
- [ ] Restoration state and unlocked flag per region persist through the save-integration interface across sessions
  → covered by Task T2
- [ ] Dredger attacks revert a restored region to barren, and the reverted state is reflected in traversal and persistence
  → covered by Task T5
- [ ] Reverting a region to barren leaves its unlocked flag set, so restoration can be redone without refighting the Flagship
  → covered by Task T5
- [ ] A world declares its restorable regions declaratively through the Level Contract rather than through bespoke scripting
  → covered by Task T5
- [ ] The broken-to-restored transformation is visually dramatic and satisfying in hands-on play (manual)
  → covered by Task T12

## Interface Contracts

### SENDS TO: Save System (shared-library)
- **Contract:** Save Integration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Collectibles System (shared-library)
- **Contract:** Restoration Region Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Restoration Region Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World: Coral Cove (shared-library)
- **Contract:** Restoration Region Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World: Bubble Bay (shared-library)
- **Contract:** Restoration Region Interface
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

### SENDS TO: Balance and Tuning Data (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Flagship Boss Encounter (shared-library)
- **Contract:** Restoration Region Interface
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
- Save System (this node calls/depends on it via Save Integration Interface (dependency))
- Audio System (this node calls/depends on it via Audio Event Interface (dependency))
- Balance and Tuning Data (this node calls/depends on it via Tuning Data Interface (dependency))

**Depends on THIS node being available:**
- Collectibles System (initiates Restoration Region Interface against this node (dependency))
- Drift Fleet Enemy Framework (initiates Restoration Region Interface against this node (dependency))
- World: Coral Cove (initiates Restoration Region Interface against this node (dependency))
- World: Bubble Bay (initiates Restoration Region Interface against this node (dependency))
- Player HUD (initiates HUD State Interface against this node (dependency))
- Flagship Boss Encounter (initiates Restoration Region Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-008.tests.md` - Test plan for requirement: World Restoration State System | test-plan | markdown | draft |
