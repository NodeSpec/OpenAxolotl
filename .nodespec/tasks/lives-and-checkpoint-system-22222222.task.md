# Task: Lives and Checkpoint System

> **Scope:** implement ONLY this node ("Lives and Checkpoint System"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node supplies the stakes the capability system deliberately does not. Its
criteria are mostly negative — what must *never* decrement a life, what must
*never* happen at zero — and negative criteria are proven by an exhaustive
allowlist, not by spot checks.

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

**Lives decrement from a closed set.** Pit volumes, crush hazards, boss finishers
and Dredger area-wipe attacks. Implement that as an explicit enumeration of
catastrophic sources, and make `lose_life()` require a source from that
enumeration as an argument — an unlisted source is a runtime error, not a silent
life loss. That shape turns "ordinary enemy and hazard contact never decrements
lives" from a thing you hope holds into a thing that cannot compile wrong, and it
gives the test a clean assertion: every non-catastrophic source rejected.

**Zero lives is a setback, never a reset.** Respawn at the last activated
checkpoint with the life count replenished and capability state restored. The
world does not restart from the beginning, and the save file is neither modified
nor penalised — the criterion names both, so assert both: a checkpoint respawn
test that reads the save file's bytes before and after and asserts no write. This
is the crucial design property that keeps failure family-friendly, and it is easy
to break later with a well-meaning "autosave on death".

**Checkpoints.** Activating a checkpoint records respawn position and restores
both life count and capability state — capability restoration goes through the
Regeneration system's interface, not by reaching into its flags. Checkpoint state
persists through the Save Integration Interface. A world may declare a
lives-per-attempt override through the Level Contract; when it does not, the
global default from the tuning data applies. Resolve the override at world load
and hold one effective value, rather than consulting the contract on every
decrement.

**Checkpoint spacing is a measurable property.** Every official world must keep
replay time from any checkpoint to the next at or below
`progression.max_retry_seconds`. That is verified by walking a world's checkpoint
graph in a headless test and comparing against the tuning key, not by a designer's
judgement — so expose the checkpoint list as queryable data on the loaded world
rather than as scene nodes only.

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
criteria explicitly reject isolation-only coverage. "Losing all lives reads as a meaningful setback without feeling
punishing" is manual and proves out through repeated play plus a task-doc tick.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Regeneration and Capability System (godot) per Contract "Capability Modifier Interface" (dependency).** <!-- t:e1629c6b -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Save System (godot) per Contract "Save Integration Interface" (dependency).** <!-- t:bcbdac74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Balance and Tuning Data (godot) per Contract "Tuning Data Interface" (dependency).** <!-- t:03c75344 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface OpenAxolotl Game Client consumes, per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:eafae80f -->
  Record the endpoint/identifiers OpenAxolotl Game Client needs in this node's config artifacts — coordinate with OpenAxolotl Game Client.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface Drift Fleet Enemy Framework consumes, per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:6e39a10c -->
  Record the endpoint/identifiers Drift Fleet Enemy Framework needs in this node's config artifacts — coordinate with Drift Fleet Enemy Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface Player HUD consumes, per Contract "HUD State Interface" (dependency).** <!-- t:3e14fc4a -->
  Record the endpoint/identifiers Player HUD needs in this node's config artifacts — coordinate with Player HUD.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface Flagship Boss Encounter consumes, per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:f4ba4c5d -->
  Record the endpoint/identifiers Flagship Boss Encounter needs in this node's config artifacts — coordinate with Flagship Boss Encounter.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement: "Lives decrement only from designated catastrophic sources: pit volumes, crush hazards, boss finishers, and Dredger area-wipe attacks" (REQ-003).** <!-- t:3ccdbe80 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Lives decrement only from designated catastrophic sources: pit volumes, crush hazards, boss finishers, and Dredger area-wipe attacks" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) from Flagship Boss Encounter (keyword signal only)
- [ ] **T11 — Implement: "Ordinary enemy and hazard contact never decrements lives" (REQ-003).** <!-- t:ab89affb -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Ordinary enemy and hazard contact never decrements lives" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) from Drift Fleet Enemy Framework (keyword signal only)
- [ ] **T12 — Implement: "Reaching zero lives respawns the player at the last activated checkpoint with the life count replenished" (REQ-003).** <!-- t:ac5805e6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Reaching zero lives respawns the player at the last activated checkpoint with the life count replenished" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) from OpenAxolotl Game Client (keyword signal only)
- [ ] **T13 — Implement: "Reaching zero lives never restarts the world from the beginning and never modifies or penalizes the save file" (REQ-003).** <!-- t:bad4a681 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Reaching zero lives never restarts the world from the beginning and never modifies or penalizes the save file" — possible coordination point: Contract "Save Integration Interface" (dependency) to Save System (keyword signal only)
- [ ] **T14 — Implement: "Activating a checkpoint records respawn position and restores both life count and capability state" (REQ-003).** <!-- t:7c444bf1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Activating a checkpoint records respawn position and restores both life count and capability state" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) from OpenAxolotl Game Client (keyword signal only)
- [ ] **T15 — Implement: "A world can declare a lives-per-attempt override through the Level Contract, and the global default applies when it does not" (REQ-003).** <!-- t:4ec52f09 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "A world can declare a lives-per-attempt override through the Level Contract, and the global default applies when it does not" — possible coordination point: Contract "Engine Feature Policy" (dependency) from World Static Analysis Gate (keyword signal only)
- [ ] **T16 — Implement: "Checkpoint spacing in every official world keeps the replay time from any checkpoint to the next at or below tuning key progression.max_retry_seconds" (REQ-003).** <!-- t:1d442410 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Checkpoint spacing in every official world keeps the replay time from any checkpoint to the next at or below tuning key progression.max_retry_seconds" — possible coordination point: Contract "Tuning Data Interface" (dependency) to Balance and Tuning Data (keyword signal only)
- [ ] **T17 — Implement: "Losing all lives reads as a meaningful setback without feeling punishing, across repeated play" (REQ-003).** <!-- t:f17eefd2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Losing all lives reads as a meaningful setback without feeling punishing, across repeated play"
- [ ] **T18 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-003: Lives, Checkpoints and Hard Failure State
Category: functional | Status: in-progress
Pillar 1, hard layer — the stakes that the capability layer deliberately does not provide. A limited life count per attempt. ONLY catastrophic events cost a life directly: bottomless pits, crush hazards, boss finishing moves, and Dredger area-wipe attacks. Ordinary enemy contact does not — it strips capability instead. Reaching zero lives returns the player to the last checkpoint with lives replenished; it is NOT a full level restart and NOT a save-file penalty. Checkpoints are the anchor for both systems: they refill lives AND restore capability state, which is precisely why the Level Contract lists checkpoints as required rather than optional. Worlds may override the lives-per-attempt count, otherwise a global default applies.

**Acceptance criteria — your task boxes:**
- [ ] Lives decrement only from designated catastrophic sources: pit volumes, crush hazards, boss finishers, and Dredger area-wipe attacks
  → covered by Task T10
- [ ] Ordinary enemy and hazard contact never decrements lives
  → covered by Task T11
- [ ] Reaching zero lives respawns the player at the last activated checkpoint with the life count replenished
  → covered by Task T12
- [ ] Reaching zero lives never restarts the world from the beginning and never modifies or penalizes the save file
  → covered by Task T13
- [ ] Activating a checkpoint records respawn position and restores both life count and capability state
  → covered by Task T14
- [ ] A world can declare a lives-per-attempt override through the Level Contract, and the global default applies when it does not
  → covered by Task T15
- [ ] Checkpoint spacing in every official world keeps the replay time from any checkpoint to the next at or below tuning key progression.max_retry_seconds
  → covered by Task T16
- [ ] Losing all lives reads as a meaningful setback without feeling punishing, across repeated play (manual)
  → covered by Task T17

## Interface Contracts

### RECEIVES FROM: OpenAxolotl Game Client (game-client)
- **Contract:** Checkpoint and Life Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Regeneration and Capability System (shared-library)
- **Contract:** Capability Modifier Interface
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

### RECEIVES FROM: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Checkpoint and Life Interface
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

### SENDS TO: Balance and Tuning Data (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Flagship Boss Encounter (shared-library)
- **Contract:** Checkpoint and Life Interface
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
- Regeneration and Capability System (this node calls/depends on it via Capability Modifier Interface (dependency))
- Save System (this node calls/depends on it via Save Integration Interface (dependency))
- Balance and Tuning Data (this node calls/depends on it via Tuning Data Interface (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Client (initiates Checkpoint and Life Interface against this node (dependency))
- Drift Fleet Enemy Framework (initiates Checkpoint and Life Interface against this node (dependency))
- Player HUD (initiates HUD State Interface against this node (dependency))
- Flagship Boss Encounter (initiates Checkpoint and Life Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))
