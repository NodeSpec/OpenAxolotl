# Task: World: Coral Cove

> **Scope:** implement ONLY this node ("World: Coral Cove"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
Coral Cove is the first official world and the one that carries the cross-world
criteria for the official set — including the requirement that both official
worlds are built with no privileges an outside contributor lacks.

**Placement and shape.** A world is a self-contained module under `worlds/`,
discovered by the hub at runtime with no entry in any code-side list. It declares
itself through a manifest validated against `contracts/level_contract.v1.json`,
and it may call only the symbols in the sanctioned world API surface — the World
Static Analysis Gate rejects anything else. Build it exactly the way an outside
contributor would: no private back doors, no reaching into a core system's
internals, no engine API a community world could not also use. That constraint is
the point of the official worlds, and one of them states it as a criterion.

**Catalog guidance that does not apply here.** The Godot technology guidance in
this packet carries multiplayer sample code — `@rpc` annotations,
`is_multiplayer_authority`, `MultiplayerSynchronizer`. It is generic engine
guidance and it is forbidden in this project. REQ-030 bans the whole Godot
multiplayer surface, the Engine Feature Policy contract records the ban
machine-readably, and the World Static Analysis Gate fails CI on any occurrence
anywhere in `core/`, `worlds/` or the reference template. This is single-player
only, in every phase, with no deferral. Systems talk to each other through
signals and direct calls on the interfaces declared in this packet.

**No back doors, verified by the same gate.** The criterion says each official
world calls only the sanctioned world API surface, using no private back doors,
*verified by the same static analysis applied to community submissions*. So
Coral Cove runs through `oax-static-gate` in CI exactly as a submission would. If
building this world requires an API that is not sanctioned, the correct fix is to
add it to the sanctioned surface deliberately — updating
`contracts/sanctioned_api.v1.json` and the interfaces it reflects — never to work
around the gate. Every such addition is a decision about what community
contributors may do, so treat it as a contract change, not a build fix.

**Coverage this world owns.** Both movement grammars exercised, at least one
restorable region, at least one mandatory traversal challenge gated on a specific
Gill Mod, and a Flagship encounter (Bubble Bay declares none, so Coral Cove is
where the boss path is proven). Across the official set all three MVP mods must
each be required by at least one world — coordinate the split with Bubble Bay so
the union genuinely covers Bubble, Jet and Glow rather than both worlds gating on
the same one.

**Completability is a headless test.** The playthrough smoke test drives this
world from spawn to finish condition and asserts completion. Design the critical
path so it is drivable by simulated input — deterministic enemy placement on the
mandatory route, no timing window that depends on frame rate — otherwise the smoke
test becomes flaky and the project loses its regression net.

**Declare, don't script.** Regions, collectibles, enemies, camera hints, checkpoints
and audio are all declared through the Level Contract's elements. Reach for a
script only where the contract has no element for what you need, and when that
happens, treat it as contract feedback rather than as a local workaround.

**Contract feedback is a deliverable.** One manual criterion says friction
discovered while building the official worlds is fed back into the Level Contract
before v1 is frozen. Keep a running list as you build — every place the contract
made you fight it — and land those changes before the freeze. Freezing v1 without
that feedback is what would break every early community world on the first core
update.

**Verification.** GdUnit4 tests live under `test/` mirroring this directory, and
each test name carries the requirement id it proves (`test_req_0NN_...`) — the
harness parses that id back out and reports it as the failing rule, which is how
a contributor or agent locates what broke. Unit-tier tests exercise this system's
logic as plain objects; integration-tier tests drive it against the real
controller and the real save interface via GdUnit4's `scene_runner`, because the
criteria explicitly reject isolation-only coverage. Frame-rate on the baseline spec is asserted via `Performance.get_monitor()`
in the CI performance test. Fun and the restoration payoff are manual.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Restoration State System (godot) per Contract "Restoration Region Interface" (dependency).** <!-- t:b339696f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-011 "Each official world exercises both movement grammars and contains at least one restorable region" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T3 — Implement the integration with Drift Fleet Enemy Framework (godot) per Contract "Enemy Registration Interface" (dependency).** <!-- t:091d8bdf -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Gill Mod Ability Framework (godot) per Contract "Gill Mod Registration Interface" (dependency).** <!-- t:9ef5b42c -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-011 "Each official world contains at least one mandatory traversal challenge gated on a specific Gill Mod, and across the official set all three MVP mods are each required by at least one world" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T5 — Implement the integration with Collectibles System (godot) per Contract "Collectible Registration Interface" (dependency).** <!-- t:9bc134aa -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Implement the integration with Flagship Boss Encounter (godot) per Contract "Enemy Registration Interface" (dependency).** <!-- t:1f8b6190 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement the integration with Camera System (godot) per Contract "Camera Hint Interface" (dependency).** <!-- t:e3e65073 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Implement the integration with Save System (godot) per Contract "Save Integration Interface" (dependency).** <!-- t:bcbdac74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Implement the integration with Audio System (godot) per Contract "Audio Event Interface" (dependency).** <!-- t:218035d2 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Expose the interface OpenAxolotl Game Client consumes, per Contract "Level Contract v1" (dependency).** <!-- t:99890668 -->
  Record the endpoint/identifiers OpenAxolotl Game Client needs in this node's config artifacts — coordinate with OpenAxolotl Game Client.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-011 "At least two official worlds are implemented, each passing the Level Contract compliance checker" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-011 "Contract friction discovered while building the official worlds is fed back into the Level Contract before v1 is frozen" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T11 — Expose the interface Level Contract Compliance Checker consumes, per Contract "Level Contract v1" (dependency).** <!-- t:87778b5e -->
  Record the endpoint/identifiers Level Contract Compliance Checker needs in this node's config artifacts — coordinate with Level Contract Compliance Checker.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T12 — Expose the interface World Static Analysis Gate consumes, per Contract "Sanctioned World API Surface" (dependency).** <!-- t:a14fa597 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-011 "Each official world is completable from spawn to finish condition" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-011 "Each official world calls only the sanctioned world API surface, using no private back doors unavailable to an outside contributor, verified by the same static analysis applied to community submissions" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-011 "Each world is fun to play through and delivers a satisfying broken-to-restored payoff" — requirement not mapped to that node; verify or reassign before relying on it
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

### REQ-011: Official MVP Worlds
Category: functional | Status: in-progress
Two to three official worlds at MVP — Coral Cove, Bubble Bay, and one more — each a discrete, bounded, checkpointed playthrough space entered from the Open Lagoon. Their purpose is dual and the second purpose is the more important one: they are shipped content AND they are the battle-test of the Level Contract. They must be built as ordinary contract-conforming world modules using only the public extension interfaces, taking no shortcuts unavailable to an outside contributor — if a core team world needs a private back door, that is a contract defect to fix, not a special case to permit. Friction encountered building them feeds back into the contract, and only once that feedback is absorbed is the contract frozen at v1. Each world should exercise both movement grammars, at least one restoration region, and a distinct Gill Mod emphasis.

**Acceptance criteria — your task boxes:**
- [ ] At least two official worlds are implemented, each passing the Level Contract compliance checker
  → covered by Task T10
- [ ] Each official world is completable from spawn to finish condition
  → covered by Task T12
- [ ] Each official world calls only the sanctioned world API surface, using no private back doors unavailable to an outside contributor, verified by the same static analysis applied to community submissions
  → covered by Task T12
- [ ] Each official world exercises both movement grammars and contains at least one restorable region
  → covered by Task T2
- [ ] Each official world contains at least one mandatory traversal challenge gated on a specific Gill Mod, and across the official set all three MVP mods are each required by at least one world
  → covered by Task T4
- [ ] Contract friction discovered while building the official worlds is fed back into the Level Contract before v1 is frozen (manual)
  → covered by Task T10
- [ ] Each world is fun to play through and delivers a satisfying broken-to-restored payoff (manual)
  → covered by Task T12

## Interface Contracts

### RECEIVES FROM: OpenAxolotl Game Client (game-client)
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

### SENDS TO: Restoration State System (shared-library)
- **Contract:** Restoration Region Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Enemy Registration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Gill Mod Ability Framework (shared-library)
- **Contract:** Gill Mod Registration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Collectibles System (shared-library)
- **Contract:** Collectible Registration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Level Contract Compliance Checker (cli-tool)
- **Contract:** Level Contract v1
- **Protocol:** dependency
- **Their Technology:** python-backend

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

### SENDS TO: Flagship Boss Encounter (shared-library)
- **Contract:** Enemy Registration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World Static Analysis Gate (cli-tool)
- **Contract:** Sanctioned World API Surface
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: Camera System (shared-library)
- **Contract:** Camera Hint Interface
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

### SENDS TO: Audio System (shared-library)
- **Contract:** Audio Event Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

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
- Restoration State System (this node calls/depends on it via Restoration Region Interface (dependency))
- Drift Fleet Enemy Framework (this node calls/depends on it via Enemy Registration Interface (dependency))
- Gill Mod Ability Framework (this node calls/depends on it via Gill Mod Registration Interface (dependency))
- Collectibles System (this node calls/depends on it via Collectible Registration Interface (dependency))
- Flagship Boss Encounter (this node calls/depends on it via Enemy Registration Interface (dependency))
- Camera System (this node calls/depends on it via Camera Hint Interface (dependency))
- Save System (this node calls/depends on it via Save Integration Interface (dependency))
- Audio System (this node calls/depends on it via Audio Event Interface (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Client (initiates Level Contract v1 against this node (dependency))
- Level Contract Compliance Checker (initiates Level Contract v1 against this node (dependency))
- World Static Analysis Gate (initiates Sanctioned World API Surface against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-011.tests.md` - Test plan for requirement: Official MVP Worlds | test-plan | markdown | draft |
