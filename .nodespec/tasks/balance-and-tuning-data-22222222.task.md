# Task: Balance and Tuning Data

> **Scope:** implement ONLY this node ("Balance and Tuning Data"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Shared Library
**Technology:** Godot
**Description:** Reusable code package consumed as a dependency by other services

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Constraints That Apply Here

None recorded for this node. Standing conditions the build must honour (security, compliance, cost, technology and the like) can be filed with a `create_constraint` patch.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This node is the reason no other system holds a magic number. It is mostly data
plus a strict loader, and its strictness is the whole value — a tuning file that
silently defaults is worse than one that refuses to load.

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

**Data files, not constants.** All balance values live in data (`core/tuning/*.tres`
or JSON — pick one and keep it uniform) and are read through the Tuning Data
Interface. Changing a value alters observable behavior with no code change and no
recompile, which means consumers read through the interface at use time rather
than caching into a `const` at load. The tuning surface is enumerated in the
criteria and spans capability-loss modifiers, default lives per attempt, dash
charge and recharge, Gill Mod durations and cooldowns, enemy debuff magnitudes and
windows, restoration resource costs, grapple range, camera smoothing thresholds,
mutation loadout duration, momentum retention across grammar transitions, and
maximum retry duration.

**Every key carries name, unit and permitted range.** Store those alongside the
value, not in a separate document — the loader validates against the declared
range, and a missing or out-of-range value fails with a *named* error identifying
the key. Never substitute a default for a bad value; a silent default turns a
balance bug into a mystery.

**Keys cited by other requirements must exist.** REQ-025's last criterion makes
this node responsible for the whole project's tuning-key integrity: every key
cited in another requirement's acceptance criteria exists here with a documented
unit and range, and a test fails when a cited key is absent. Implement that as a
real test with an explicit list of cited keys —
`controller.transition.momentum_retention_ratio`, `controller.grapple.max_range_m`,
`capability.gill_loss.boost_duration_multiplier`, `regen.mutation.duration_s`,
`enemy.hookline.mod_strip_seconds`, `enemy.runoff.vision_debuff_factor`,
`enemy.runoff.gill_recharge_multiplier`, `enemy.runoff.duration_s`,
`camera.smoothing.max_position_delta_m_per_frame`,
`camera.smoothing.max_rotation_delta_deg_per_frame`,
`progression.max_retry_seconds` — kept in one place and asserted key by key. When
a requirement gains a new tuning key, that list is the thing to update.

**World overrides are a closed set.** The values a world may override through the
Level Contract are explicitly enumerated, and an override outside that set is
rejected. Declare the overridable set in the tuning data itself and have the Level
Contract schema reference it, so there is one list rather than two that drift.
Rejection is an error at world load, surfaced the same way a contract violation is
— the world becomes unavailable rather than silently running with an ignored
override.

**Verification.** GdUnit4 tests live under `test/` mirroring this directory, and
each test name carries the requirement id it proves (`test_req_0NN_...`) — the
harness parses that id back out and reports it as the failing rule, which is how
a contributor or agent locates what broke. Unit-tier tests exercise this system's
logic as plain objects; integration-tier tests drive it against the real
controller and the real save interface via GdUnit4's `scene_runner`, because the
criteria explicitly reject isolation-only coverage.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Expose the interface Axolotl Controller consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:fa1448ec -->
  Record the endpoint/identifiers Axolotl Controller needs in this node's config artifacts — coordinate with Axolotl Controller.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface Regeneration and Capability System consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:6122b508 -->
  Record the endpoint/identifiers Regeneration and Capability System needs in this node's config artifacts — coordinate with Regeneration and Capability System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface Lives and Checkpoint System consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:a6c293b2 -->
  Record the endpoint/identifiers Lives and Checkpoint System needs in this node's config artifacts — coordinate with Lives and Checkpoint System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Gill Mod Ability Framework consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:d3771261 -->
  Record the endpoint/identifiers Gill Mod Ability Framework needs in this node's config artifacts — coordinate with Gill Mod Ability Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface Drift Fleet Enemy Framework consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:6d3c67ec -->
  Record the endpoint/identifiers Drift Fleet Enemy Framework needs in this node's config artifacts — coordinate with Drift Fleet Enemy Framework.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Expose the interface Restoration State System consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:ec31be4d -->
  Record the endpoint/identifiers Restoration State System needs in this node's config artifacts — coordinate with Restoration State System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T8 — Expose the interface Camera System consumes, per Contract "Tuning Data Interface" (dependency).** <!-- t:3bf082ad -->
  Record the endpoint/identifiers Camera System needs in this node's config artifacts — coordinate with Camera System.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T9 — Expose the interface World Static Analysis Gate consumes, per Contract "Engine Feature Policy" (dependency).** <!-- t:5c920cb0 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T10 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-025: Balance and Tuning Configuration
Category: technical | Status: in-progress
Many acceptance criteria across the player systems assert a "configured modifier", "bounded window", or "configured magnitude" without anywhere defining the values. Without a single named home for those numbers, tests have nothing to assert against and every system invents its own constants. This requirement establishes one authoritative, data-driven tuning surface covering capability-loss modifiers (swim speed, boost duration, climb height), default lives per attempt, dash charge and recharge rates, Gill Mod durations and cooldowns, enemy debuff magnitudes and windows, and restoration resource costs. Values live in data rather than code so they can be tuned without recompiling and so an AI agent or contributor can adjust balance without touching system logic. Worlds may override a documented subset; everything else stays global to keep the game coherent across forks.

**Acceptance criteria — your task boxes:**
- [x] All balance values are defined in data files rather than as constants in system code
  → THIS NODE: internal logic
- [x] The tuning surface covers capability-loss modifiers, default lives per attempt, dash charge and recharge, Gill Mod durations and cooldowns, enemy debuff magnitudes and windows, restoration resource costs, grapple range, camera smoothing thresholds, mutation loadout duration, momentum retention across grammar transitions, and maximum retry duration
  → THIS NODE: internal logic — possible coordination point: Contract "Tuning Data Interface" (dependency) from Gill Mod Ability Framework (keyword signal only)
- [x] Every value carries a documented name, unit, and permitted range
  → THIS NODE: internal logic
- [x] Changing a tuning value alters observable behavior with no code change and no recompile
  → THIS NODE: internal logic
- [x] The set of values a world may override through the Level Contract is explicitly enumerated, and an override outside that set is rejected
  → THIS NODE: internal logic — possible coordination point: Contract "Engine Feature Policy" (dependency) from World Static Analysis Gate (keyword signal only)
- [x] Loading a tuning file with a missing or out-of-range value fails with a named error rather than silently defaulting
  → THIS NODE: internal logic
- [x] Every tuning key cited by another requirement's acceptance criteria exists in the tuning data with a documented unit and permitted range, and a test fails when a cited key is absent
  → THIS NODE: internal logic

### REQ-037: Platformer jump feel and climb robustness
Category: functional | Status: pending
_Shared with: Axolotl Controller, Input System — their slices live in their own task docs._
The jump must feel fair and the climb must survive contact noise, because a platforming level is only as good as the forgiveness under it. None of these rules change where the axolotl CAN go on a perfectly-timed input; they change how much timing precision the player is asked for.

THREE FORGIVENESS RULES live in a JumpFeel class apart from the controller, pure arithmetic over time provable frame by frame with no scene: COYOTE TIME (a press just after the ledge still hops, the window expires, and firing spends it so it cannot chain into a double jump), JUMP BUFFERING (a press while falling is remembered on the rising edge only and fires on landing), and VARIABLE HEIGHT (releasing the button mid-rise cuts the climb, so one button expresses a range of arcs).

VARIABLE HEIGHT NEEDED A NEW INPUT FACT. Verbs are edge-triggered, so the hop verb is gone by the frame after launch, and a cut reading it would cut EVERY jump — measured in the greybox as a 2.02 m arc landing at 0.23 m. PlayerIntent therefore carries a second set, `sustained`, holding the verbs whose physical input is still down. It is re-resolved against the live grammar every frame, dropped on a device switch, and cleared on respawn, the same rules the held direction set follows.

THE CLIMB had two scene-tree bugs no unit test could see. Moving purely ALONG a wall generates no contact, so the climb detached on its second frame; the climber now presses into the wall at a tuned adhesion that move_and_slide absorbs. And losing the wall for a single frame — a seam, or the moment of cresting a lip — dropped the climber the whole way down; the controller now keeps the wall for a tuned contact grace after the body reports losing it.

THE ARC is retuned for platforming (impulse 9 m/s against 20 m/s² gravity, waddle 4.2 m/s) and measured in the live greybox: 1.81 m standing jump, 3.15 m running gap, the envelope every official level's geometry is derived from. Every window, the cut ratio, the adhesion and the grace are tuning keys with documented units and ranges (REQ-025); at zero each rule disables itself and the strict behaviour returns.

**Acceptance criteria — your task boxes:**
- [x] Coyote time forgives a hop pressed just after leaving a ledge, expires after the tuned window, and is spent by firing so a hop can never chain into a mid-air ascent
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping
- [x] A hop pressed in mid-air is buffered on the rising edge only and fires on touchdown; the buffer expires rather than firing late, and holding the button does not refill it
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping
- [x] Releasing the hop mid-rise cuts the vertical speed by the tuned ratio; the cut never touches a descent, a rise the hop did not start, or a rise whose button is still held — proven through the real controller, where a tapped jump measurably rises less than a held one
  → THIS NODE via Contract "Tuning Data Interface" (dependency) from Axolotl Controller — coordinate with Axolotl Controller
- [x] PlayerIntent carries a sustained verb set alongside the edge-triggered one: a held key sustains its verb until release, re-resolves under the live grammar (SPACE held through the water/land seam sustains what it means now), and is dropped on a device switch and on clear()
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping
- [x] A climber presses into the wall at the tuned adhesion on every frame — steering up, sideways, and clinging still — so motion along the surface cannot end the climb by starving it of contact, and the greybox smoke proves the climb rises in a real scene
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping
- [x] Losing wall contact for less than the tuned grace does not end a climb and regaining the wall resets the window; contact lost past the grace releases exactly once
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping
- [x] Every window, ratio and speed above is a tuning key with documented unit and range, and the greybox smoke and coral walk complete against the retuned arc
  → owner unresolved — this node or a sharing node (Axolotl Controller, Input System): no contract evidence; assign via the requirement mapping

## Interface Contracts

### RECEIVES FROM: Axolotl Controller (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Regeneration and Capability System (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Lives and Checkpoint System (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Gill Mod Ability Framework (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Drift Fleet Enemy Framework (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Restoration State System (shared-library)
- **Contract:** Tuning Data Interface
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Camera System (shared-library)
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

**Depends on THIS node being available:**
- Axolotl Controller (initiates Tuning Data Interface against this node (dependency))
- Regeneration and Capability System (initiates Tuning Data Interface against this node (dependency))
- Lives and Checkpoint System (initiates Tuning Data Interface against this node (dependency))
- Gill Mod Ability Framework (initiates Tuning Data Interface against this node (dependency))
- Drift Fleet Enemy Framework (initiates Tuning Data Interface against this node (dependency))
- Restoration State System (initiates Tuning Data Interface against this node (dependency))
- Camera System (initiates Tuning Data Interface against this node (dependency))
- World Static Analysis Gate (initiates Engine Feature Policy against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `core/tuning/tuning.json` | config | --- | draft |
| `test/core/tuning/test_tuning_data.gd` | source | --- | draft |
| `core/tuning/tuning_error.gd` | source | --- | draft |
| `core/tuning/tuning_data.gd` | source | --- | draft |
| `.nodespec/tests/req-025.tests.md` - Test plan for requirement: Balance and Tuning Configuration | test-plan | markdown | draft |
