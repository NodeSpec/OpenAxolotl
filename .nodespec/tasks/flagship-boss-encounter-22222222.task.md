# Task: Flagship Boss Encounter

> **Scope:** implement ONLY this node ("Flagship Boss Encounter"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
The Flagship is the one encounter that gates restoration: defeating it sets its
region's `unlocked` flag, which is what permits restoration to begin at all. It
is also the game's proof that both movement grammars and the Gill Mod system are
mandatory rather than optional flavour.

**Placement and shape.** This is a `shared-library` node: it lives in its own
directory under `core/`, exposes a `class_name`-registered public surface, and is
consumed by other systems and by world modules as a dependency. It is not an
autoload unless it genuinely needs one global instance — prefer an explicit
reference passed in over a singleton, because a singleton is untestable under
GdUnit4 without process-level teardown, and this project's whole verification
story runs through GdUnit4.

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
this packet carries multiplayer sample code — `@rpc` annotations,
`is_multiplayer_authority`, `MultiplayerSynchronizer`. It is generic engine
guidance and it is forbidden in this project. REQ-030 bans the whole Godot
multiplayer surface, the Engine Feature Policy contract records the ban
machine-readably, and the World Static Analysis Gate fails CI on any occurrence
anywhere in `core/`, `worlds/` or the reference template. This is single-player
only, in every phase, with no deferral. Systems talk to each other through
signals and direct calls on the interfaces declared in this packet.

**Phase structure is a requirement, not a design preference.** At least one
mandatory phase completable only in the water grammar, at least one only in land,
and at least one gated on the Gill Mod its host world requires. Model phases as
explicit, ordered, queryable data — each declaring the grammar or mod it
requires — so a test can assert the coverage rather than a designer asserting it
in a comment. That data also drives the checkpoint behaviour below.

**Two damage channels, deliberately unequal.** Ordinary attacks strip capability
through the Capability Modifier Interface; only the designated finishing moves
decrement a life, through the Checkpoint and Life Interface with a boss-finisher
source id. Keep the finisher set small and explicit; every other attack must have
no path to the life interface.

**Checkpoints resume the phase, not the fight.** Checkpoints within the encounter
restore lives and capability state and resume at the last *completed* phase. That
requires phase progress to be checkpoint state, which means the encounter
registers its phase index with the Lives and Checkpoint System rather than
tracking it privately. Without that, a player losing all lives in phase three
restarts at phase one — the exact punishing failure the lives design exists to
avoid.

**Unlocking restoration.** On defeat, set the region's `unlocked` flag through the
Restoration Region Interface. Note the deliberate asymmetry with the Dredger: a
Dredger reverts a restored region to `barren` but leaves `unlocked` set, so the
Flagship is fought once and the restoration can be redone. Do not clear
`unlocked` from this node for any reason.

**Optional by contract.** A world declaring no boss stays contract-valid and
fully completable — Bubble Bay is the world that proves it. Restoration in a
bossless world must therefore be unlockable by some other declared means, so
`unlocked` cannot default to false-and-only-boss-can-set-it; the Level Contract
declares the default for a world with no boss.

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
criteria explicitly reject isolation-only coverage. "Reads as a climactic set piece and its restoration payoff lands" is
manual.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Drift Fleet Enemy Framework (godot) per Contract "Enemy Registration Interface" (dependency).** <!-- t:091d8bdf -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Restoration State System (godot) per Contract "Restoration Region Interface" (dependency).** <!-- t:b339696f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Lives and Checkpoint System (godot) per Contract "Checkpoint and Life Interface" (dependency).** <!-- t:25e4d91d -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface World: Coral Cove consumes, per Contract "Enemy Registration Interface" (dependency).** <!-- t:26bebacb -->
  Record the endpoint/identifiers World: Coral Cove needs in this node's config artifacts — coordinate with World: Coral Cove.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement: "The encounter reads as a climactic set piece and its restoration payoff lands" (REQ-013).** <!-- t:89189d9f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "The encounter reads as a climactic set piece and its restoration payoff lands" — possible coordination point: Contract "Restoration Region Interface" (dependency) to Restoration State System (keyword signal only)
- [ ] **T8 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-013: Flagship Boss Encounter
Category: functional | Status: in-progress
The regional set-piece encounter and the mechanic that ties boss design directly to Pillar 3. The Flagship is the source vessel anchoring a region's Drift Fleet presence — the largest piece of extraction machinery, still faceless, still unmanned. Its finishing moves are one of the few life-costing catastrophic events, while its ordinary attacks strip capability like any other Drift Fleet unit, so the fight escalates along both layers at once. Defeating it flips the whole region from barren to restorable, making the boss the gate on the restoration payoff rather than a detached spectacle. The encounter should require both movement grammars and the Gill Mod its world emphasizes. Boss is an optional Level Contract element, so a world without one remains fully valid.

**Acceptance criteria — your task boxes:**
- [x] Flagship ordinary attacks strip capability, and its designated finishing moves decrement a life
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] Defeating the Flagship sets its region's restoration unlocked flag, permitting restoration to begin
  → THIS NODE: internal logic — possible coordination point: Contract "Restoration Region Interface" (dependency) to Restoration State System (keyword signal only)
- [x] The encounter contains at least one mandatory phase completable only in the water grammar and at least one completable only in the land grammar
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] The encounter contains at least one mandatory phase gated on the Gill Mod its host world requires
  → THIS NODE: internal logic — possible coordination point: Contract "Engine Feature Policy" (dependency) from World Static Analysis Gate (keyword signal only)
- [x] Checkpoints within the encounter restore lives and capability state and resume the encounter at the last completed phase rather than from its start
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [x] A world declaring no boss remains contract-valid and fully completable
  → THIS NODE: internal logic — possible coordination point: Contract "Checkpoint and Life Interface" (dependency) to Lives and Checkpoint System (keyword signal only)
- [ ] The encounter reads as a climactic set piece and its restoration payoff lands (manual)
  → covered by Task T7

### REQ-036: Drift Fleet and Flagship reachable from a world
Category: functional | Status: pending
_Shared with: World: Coral Cove, Drift Fleet Enemy Framework, Model Refinement Pipeline, Restoration State System — their slices live in their own task docs._
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
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework
- [x] The shipped enemy roster loads into a world's fleet so a manifest can name any of its units
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework
- [x] Contact with a declared entangling unit, driven through the runtime's own scene seam, entangles the player
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Model Refinement Pipeline, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A scene node naming a unit the world never declared stays inert on every lane, not only at wiring time
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) from World: Coral Cove — coordinate with World: Coral Cove
- [x] A dredger reverts the region its node names back to barren while leaving the region's unlocked flag set
  → THIS NODE via Contract "Restoration Region Interface" (dependency) to Restoration State System — coordinate with Restoration State System
- [x] A valid boss declaration builds a Flagship encounter and its region starts locked
  → THIS NODE via Contract "Restoration Region Interface" (dependency) to Restoration State System — coordinate with Restoration State System
- [x] A refused boss declaration leaves the region locked rather than opening it
  → THIS NODE via Contract "Restoration Region Interface" (dependency) to Restoration State System — coordinate with Restoration State System
- [x] A boss phase volume clears a phase only when the player arrives in the grammar that phase demands
  → owner unresolved — this node or a sharing node (World: Coral Cove, Drift Fleet Enemy Framework, Model Refinement Pipeline, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] Both official worlds declare and place a Drift Fleet, and every walk probe, contract checker and the perf gate stay green with the units in place
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework
- [x] Every Drift Fleet unit ships as a contract-conforming asset with provenance recording the generator
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework

## Interface Contracts

### SENDS TO: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Enemy Registration Interface
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

### SENDS TO: Lives and Checkpoint System (shared-library)
- **Contract:** Checkpoint and Life Interface
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
- Drift Fleet Enemy Framework (this node calls/depends on it via Enemy Registration Interface (dependency))
- Restoration State System (this node calls/depends on it via Restoration Region Interface (dependency))
- Lives and Checkpoint System (this node calls/depends on it via Checkpoint and Life Interface (dependency))

**Depends on THIS node being available:**
- World: Coral Cove (initiates Enemy Registration Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `.nodespec/tests/req-013.tests.md` - Test plan for requirement: Flagship Boss Encounter | test-plan | markdown | draft |
| `core/boss/flagship_encounter.gd` | source | --- | draft |
| `core/boss/flagship_error.gd` | source | --- | draft |
| `test/core/boss/test_flagship_encounter.gd` | source | --- | draft |
