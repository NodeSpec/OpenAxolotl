# Task: Drift Fleet Enemy Framework

> **Scope:** implement ONLY this node ("Drift Fleet Enemy Framework"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
The antagonists are industrial machinery, never people — no gore, no humanized
violence. Mechanically, the roster's job is to strip capabilities and undo
restoration; only the Dredger's area-wipe touches lives at all.

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

**Four enemies, four distinct pressures.** Netbots entangle and strip swim speed,
countered by Jet Gills. Hookline Rigs snag and strip the equipped Gill Mod for
`enemy.hookline.mod_strip_seconds`, revealed in advance by Glow Gills — the
reveal is what makes the counter skill rather than luck, so the line must be
detectable before the trigger volume, not simultaneously with it. Dredgers revert
restored regions to barren and their area-wipe decrements a life. Runoff Drones
apply a vision and gill-recharge debuff while the player is inside the toxin
volume, at `enemy.runoff.vision_debuff_factor`,
`enemy.runoff.gill_recharge_multiplier` and `enemy.runoff.duration_s`.

**Route the effects, do not implement them.** Capability stripping goes through
the Capability Modifier Interface to the Regeneration system; the life decrement
goes through the Checkpoint and Life Interface with the Dredger area-wipe named as
its catastrophic source (that system rejects unlisted sources, so the source id
must match); region reversion goes through the Restoration Region Interface. This
node owns behaviour and targeting, never the state its effects land in. That is
what keeps "ordinary enemy contact never decrements lives" true by construction —
only the Dredger has a code path to the life interface at all.

**The registration interface is a deliverable.** A fixture enemy must be addable
without modifying any file in the enemy system core. Same discipline as the Gill
Mod framework: enemies are declared as resources discovered from a directory,
with behaviour composed from a small set of published hooks. Write the fixture
enemy first.

**Optional by contract.** A world declaring no enemies stays contract-valid and
fully completable — the reference template proves that path, so nothing in world
loading or finish-condition evaluation may assume an enemy exists.

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
criteria explicitly reject isolation-only coverage. "Runoff Drone encounters make land routes read as the favorable path" is
a manual, hands-on criterion.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Regeneration and Capability System (godot) per Contract "Capability Modifier Interface" (dependency).** <!-- t:e1629c6b -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Lives and Checkpoint System (godot) per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:25e4d91d -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Restoration State System (godot) per Contract "Restoration Region Interface" (dependency).** <!-- t:b339696f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement the integration with Balance and Tuning Data (godot) per Contract "Tuning Data Interface" (dependency).** <!-- t:03c75344 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface World: Coral Cove consumes, per Contract "Enemy Registration Interface" (dependency).** <!-- t:26bebacb -->
  Record the endpoint/identifiers World: Coral Cove needs in this node's config artifacts — coordinate with World: Coral Cove.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface World: Bubble Bay consumes, per Contract "Enemy Registration Interface" (dependency).** <!-- t:44f2567d -->
  Record the endpoint/identifiers World: Bubble Bay needs in this node's config artifacts — coordinate with World: Bubble Bay.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface Flagship Boss Encounter consumes, per Contract "Enemy Registration Interface" (dependency).** <!-- t:119f06e1 -->
  Record the endpoint/identifiers Flagship Boss Encounter needs in this node's config artifacts — coordinate with Flagship Boss Encounter.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Implement: "Netbots entangle the player and strip swim-speed capability, and Jet Gills provide a functioning counter" (REQ-012).** <!-- t:244321a6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Netbots entangle the player and strip swim-speed capability, and Jet Gills provide a functioning counter" — possible coordination point: Contract "Capability Modifier Interface" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T11 — Implement: "Hookline Rigs snag the player and strip the equipped Gill Mod for the window given by tuning key enemy.hookline.mod_strip_seconds, and Glow Gills reveal the line before it triggers" (REQ-012).** <!-- t:d3b6e7af -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Hookline Rigs snag the player and strip the equipped Gill Mod for the window given by tuning key enemy.hookline.mod_strip_seconds, and Glow Gills reveal the line before it triggers" — possible coordination point: Contract "Tuning Data Interface" (dependency) to Balance and Tuning Data (keyword signal only)
- [ ] **T12 — Implement: "Dredgers revert restored regions to barren, and their area-wipe attack decrements a life" (REQ-012).** <!-- t:0f1bda8e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Dredgers revert restored regions to barren, and their area-wipe attack decrements a life" — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] **T13 — Implement: "Runoff Drones apply a vision and gill-recharge debuff while the player is inside the toxin volume, with magnitudes and duration given by tuning keys enemy.runoff.vision_debuff_factor, enemy.runoff.gill_recharge_multiplier, and enemy.runoff.duration_s" (REQ-012).** <!-- t:f877676b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Runoff Drones apply a vision and gill-recharge debuff while the player is inside the toxin volume, with magnitudes and duration given by tuning keys enemy.runoff.vision_debuff_factor, enemy.runoff.gill_recharge_multiplier, and enemy.runoff.duration_s" — possible coordination point: Contract "Tuning Data Interface" (dependency) to Balance and Tuning Data (keyword signal only)
- [ ] **T14 — Implement: "Enemies are registered through a documented extension interface, and a fixture enemy can be added without modifying any file in the enemy system core" (REQ-012).** <!-- t:18eba66d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Enemies are registered through a documented extension interface, and a fixture enemy can be added without modifying any file in the enemy system core" — possible coordination point: Contract "Capability Modifier Interface" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T15 — Implement: "A world declaring no enemies remains contract-valid and fully completable" (REQ-012).** <!-- t:a2dfe7b9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "A world declaring no enemies remains contract-valid and fully completable" — possible coordination point: Contract "Capability Modifier Interface" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T16 — Implement: "Runoff Drone encounters make land routes read as the favorable path in hands-on play" (REQ-012).** <!-- t:a13cf8f3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Runoff Drone encounters make land routes read as the favorable path in hands-on play" — possible coordination point: Contract "Capability Modifier Interface" (dependency) to Regeneration and Capability System (keyword signal only)
- [ ] **T17 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-012: Drift Fleet Enemy Roster
Category: functional | Status: in-progress
The antagonist faction: faceless industrial extraction machinery, deliberately NOT human characters. This preserves every intended gameplay hook — nets, hooks, dredging, pollution — without making a real profession the villain, and it fits the restoration theme better, since the machinery that broke the habitat is exactly what the player disables to heal it. Each enemy is designed against a specific capability or system rather than being a generic damage-dealer. NETBOTS: drifting drone trawlers dragging ghost nets that entangle and strip swim-speed capability; countered with Jet Gills. HOOKLINE RIGS: patrolling barbed-lure rigs that snag and briefly strip the equipped Gill Mod; countered by spotting the line in murk with Glow Gills. DREDGERS: heavy bottom-scrapers that revert restored terrain to barren, with area-wipe attacks that cost a life. RUNOFF DRONES: toxin sprayers that cloud water, debuffing vision and gill recharge to push the player onto land routes and exercise the second movement grammar. Enemies are an optional Level Contract element and are registered extensibly so a world can supply its own.

**Acceptance criteria — your task boxes:**
- [ ] Netbots entangle the player and strip swim-speed capability, and Jet Gills provide a functioning counter
  → covered by Task T10
- [ ] Hookline Rigs snag the player and strip the equipped Gill Mod for the window given by tuning key enemy.hookline.mod_strip_seconds, and Glow Gills reveal the line before it triggers
  → covered by Task T11
- [ ] Dredgers revert restored regions to barren, and their area-wipe attack decrements a life
  → covered by Task T12
- [ ] Runoff Drones apply a vision and gill-recharge debuff while the player is inside the toxin volume, with magnitudes and duration given by tuning keys enemy.runoff.vision_debuff_factor, enemy.runoff.gill_recharge_multiplier, and enemy.runoff.duration_s
  → covered by Task T13
- [ ] Enemies are registered through a documented extension interface, and a fixture enemy can be added without modifying any file in the enemy system core
  → covered by Task T14
- [ ] A world declaring no enemies remains contract-valid and fully completable
  → covered by Task T15
- [ ] Runoff Drone encounters make land routes read as the favorable path in hands-on play (manual)
  → covered by Task T16

## Interface Contracts

### SENDS TO: Regeneration and Capability System (shared-library)
- **Contract:** Capability Modifier Interface
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

### SENDS TO: Restoration State System (shared-library)
- **Contract:** Restoration Region Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World: Coral Cove (shared-library)
- **Contract:** Enemy Registration Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World: Bubble Bay (shared-library)
- **Contract:** Enemy Registration Interface
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
- **Contract:** Enemy Registration Interface
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
- Lives and Checkpoint System (this node calls/depends on it via Checkpoint and Life Interface (dependency))
- Restoration State System (this node calls/depends on it via Restoration Region Interface (dependency))
- Balance and Tuning Data (this node calls/depends on it via Tuning Data Interface (dependency))

**Depends on THIS node being available:**
- World: Coral Cove (initiates Enemy Registration Interface against this node (dependency))
- World: Bubble Bay (initiates Enemy Registration Interface against this node (dependency))
- Flagship Boss Encounter (initiates Enemy Registration Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))
