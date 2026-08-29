# Task: Regeneration and Capability System

> **Scope:** implement ONLY this node ("Regeneration and Capability System"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node is pillar one: damage strips a capability with comedic framing, and it
never ends a run. The separation between this system and the Lives system is the
single most important boundary in the game's design, and it is stated as a
criterion that must hold *under any combination of losses*.

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

**Capabilities, not health.** There is no health value anywhere in this node —
not a hidden one, not a hit counter that maps to capability loss. Model
capability state as a set of independent flags (tail, gill, leg) with a defined
movement modifier each: tail reduces swim speed, gill reduces boost duration, leg
reduces climb height. Modifiers publish through the Capability Modifier Interface
as multiplicative factors the Axolotl Controller and Gill Mod framework consume;
this node never mutates their internals. Because they are multiplicative and
independent, "all capabilities lost" degrades movement without ever reaching
zero — which is exactly what makes the never-fatal criterion structurally true
rather than defended by a clamp.

**Prove the boundary, don't assert it.** The criterion "capability loss alone
never triggers a life loss, a death, or a run reset under any combination of
losses" is best verified combinatorially: enumerate all subsets of the capability
set, apply each, step frames, and assert no life-loss signal and no reset. Three
capabilities is eight cases; write the loop rather than three hand-picked tests,
because the criterion says *any* combination.

**Regen stations.** A station restores all lost capabilities on use, and may
additionally apply a temporary mutation loadout for
`regen.mutation.duration_s`, after which the axolotl reverts to its base
configuration. Implement the revert as a timer owned by this node, not by the
station, so a world removing a station mid-loadout cannot strand the player in a
mutated configuration. Checkpoint respawn fully restores capability state — that
restoration is triggered by the Lives and Checkpoint System through its
interface, so this node exposes a `restore_all()` entry rather than watching for
respawns itself.

**Tone is a requirement, not polish.** REQ-019 rides on this node: every
capability-loss type triggers both a visual and an audio cue (never one alone),
hazards and interactables are distinguishable without relying on color alone, and
no failure state depicts blood, gore or humanized violence. The color-independence
criterion is machine-checkable — give every hazard and capability state an
explicit non-color discriminator (shape, icon or text) in its state table, and let
a test assert the table is complete. Audio cues go out through the Audio Event
Interface; this node emits semantic events ("tail lost", "gill regrown"), never
sound file paths.

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
criteria explicitly reject isolation-only coverage. The tone and comedy criteria on this node are manual by nature — they
prove out by ticking their boxes and having the user approve the change card;
`report_test_results` refuses to bind them.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Axolotl Controller (godot) per Contract "Capability Modifier Interface" (dependency).** <!-- t:8756db97 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-002 "Damage from enemies and non-catastrophic hazards strips a specific capability rather than reducing a health value" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-002 "Each capability loss applies a defined, measurable movement modifier: tail reduces swim speed, gill reduces boost duration, leg reduces climb height" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-002 "Capability loss alone never triggers a life loss, a death, or a run reset under any combination of losses" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-002 "Capability state is fully restored when the player respawns at a checkpoint" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-019 "Every capability-loss type triggers both a visual and an audio feedback cue" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-019 "The game is completable using a single input device with no required simultaneous inputs beyond that device's capability" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-019 "Capability loss and regrowth are presented with comedic, non-gruesome feedback across every loss type" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-019 "Tone reads as playful and family-appropriate to a reviewer playing the capability-loss loop repeatedly" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T3 — Implement the integration with Gill Mod Ability Framework (godot) per Contract "Capability Modifier Interface" (dependency).** <!-- t:cb981af6 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Audio System (godot) per Contract "Audio Event Interface" (dependency).** <!-- t:218035d2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement the integration with Balance and Tuning Data (godot) per Contract "Tuning Data Interface" (dependency).** <!-- t:03c75344 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-002 "Regen stations can apply a temporary mutation loadout that alters the axolotl configuration for the duration given by tuning key regen.mutation.duration_s, after which the axolotl reverts to its base configuration" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T6 — Expose the interface Lives and Checkpoint System consumes, per Contract "Capability Modifier Interface" (dependency).** <!-- t:c3844026 -->
  Record the endpoint/identifiers Lives and Checkpoint System needs in this node's config artifacts — coordinate with Lives and Checkpoint System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface Drift Fleet Enemy Framework consumes, per Contract "Capability Modifier Interface" (dependency).** <!-- t:a5387420 -->
  Record the endpoint/identifiers Drift Fleet Enemy Framework needs in this node's config artifacts — coordinate with Drift Fleet Enemy Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface Player HUD consumes, per Contract "HUD State Interface" (dependency).** <!-- t:3e14fc4a -->
  Record the endpoint/identifiers Player HUD needs in this node's config artifacts — coordinate with Player HUD.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-019 "Hazards, interactables, and restoration state are distinguishable without relying on color alone" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-019 "No enemy, hazard, or failure state depicts blood, gore, or humanized violence" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T9 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement: "Regen stations restore all lost capabilities on use" (REQ-002).** <!-- t:b6ffc0b7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Regen stations restore all lost capabilities on use"
- [ ] **T11 — Implement: "Each loss and regrowth plays comedic, non-gruesome feedback consistent with the family-appropriate tone" (REQ-002).** <!-- t:2c4f8fa3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Each loss and regrowth plays comedic, non-gruesome feedback consistent with the family-appropriate tone"
- [ ] **T12 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-002: Regeneration and Capability Loss System
Category: functional | Status: in-progress
Pillar 1, soft layer — the signature mechanic and the game's constant feedback loop. Damage does not deplete a health bar; it strips a CAPABILITY. Losing the tail reduces swim speed, losing a gill reduces boost duration, losing a leg reduces climb height. Each loss is presented with comedic pop-and-sparkle framing, never gruesome. Capability loss modulates difficulty by making the world harder to traverse, and NEVER by itself ends a run — that is exclusively the life layer's job. Regen stations restore lost capabilities and can additionally reconfigure the axolotl into temporary mutation loadouts, turning healing from a chore into a build-crafting moment. Capability state is restored at checkpoints alongside lives.

**Acceptance criteria — your task boxes:**
- [ ] Damage from enemies and non-catastrophic hazards strips a specific capability rather than reducing a health value
  → covered by Task T2
- [ ] Each capability loss applies a defined, measurable movement modifier: tail reduces swim speed, gill reduces boost duration, leg reduces climb height
  → covered by Task T2
- [ ] Capability loss alone never triggers a life loss, a death, or a run reset under any combination of losses
  → covered by Task T2
- [ ] Regen stations restore all lost capabilities on use
  → covered by Task T10
- [ ] Regen stations can apply a temporary mutation loadout that alters the axolotl configuration for the duration given by tuning key regen.mutation.duration_s, after which the axolotl reverts to its base configuration
  → covered by Task T5
- [ ] Capability state is fully restored when the player respawns at a checkpoint
  → covered by Task T2
- [ ] Each loss and regrowth plays comedic, non-gruesome feedback consistent with the family-appropriate tone (manual)
  → covered by Task T11

### REQ-019: Kid-Appropriate Tone and Accessibility
Category: non-functional | Status: in-progress
A cross-cutting constraint on every system in the game. Capability loss must read as comedic and magical — a cartoon POP, a puff, sparkly regrowth — never gruesome, bloody, or distressing, because the signature mechanic is literally limb loss in a game for families. Antagonists are faceless machinery with no gore and no humanized violence. Beyond tone, the game must be playable by younger players and mixed-skill families: readable visual language for hazards and interactables, no reliance on color alone, remappable controls, and a difficulty floor where the capability layer softens failure rather than punishing it. This requirement constrains art, animation, enemy design, and failure feedback throughout.

**Acceptance criteria — your task boxes:**
- [ ] Hazards, interactables, and restoration state are distinguishable without relying on color alone
  → covered by Task T8
- [ ] Every capability-loss type triggers both a visual and an audio feedback cue
  → covered by Task T2
- [ ] The game is completable using a single input device with no required simultaneous inputs beyond that device's capability
  → covered by Task T2
- [ ] Capability loss and regrowth are presented with comedic, non-gruesome feedback across every loss type (manual)
  → covered by Task T2
- [ ] No enemy, hazard, or failure state depicts blood, gore, or humanized violence (manual)
  → covered by Task T8
- [ ] Tone reads as playful and family-appropriate to a reviewer playing the capability-loss loop repeatedly (manual)
  → covered by Task T2

## Interface Contracts

### SENDS TO: Axolotl Controller (shared-library)
- **Contract:** Capability Modifier Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Gill Mod Ability Framework (shared-library)
- **Contract:** Capability Modifier Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Lives and Checkpoint System (shared-library)
- **Contract:** Capability Modifier Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Capability Modifier Interface
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
- Axolotl Controller (this node calls/depends on it via Capability Modifier Interface (dependency))
- Gill Mod Ability Framework (this node calls/depends on it via Capability Modifier Interface (dependency))
- Audio System (this node calls/depends on it via Audio Event Interface (dependency))
- Balance and Tuning Data (this node calls/depends on it via Tuning Data Interface (dependency))

**Depends on THIS node being available:**
- Lives and Checkpoint System (initiates Capability Modifier Interface against this node (dependency))
- Drift Fleet Enemy Framework (initiates Capability Modifier Interface against this node (dependency))
- Player HUD (initiates HUD State Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-019.tests.md` - Test plan for requirement: Kid-Appropriate Tone and Accessibility | test-plan | markdown | draft |
| `.nodespec/tests/req-002.tests.md` - Test plan for requirement: Regeneration and Capability Loss System | test-plan | markdown | draft |
