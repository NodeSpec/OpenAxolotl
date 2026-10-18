# Task: World: Coral Cove

> **Scope:** implement ONLY this node ("World: Coral Cove"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T3 — Implement the integration with Drift Fleet Enemy Framework (godot) per Contract "Enemy Registration Interface" (dependency).** <!-- t:091d8bdf -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Gill Mod Ability Framework (godot) per Contract "Gill Mod Registration Interface" (dependency).** <!-- t:9ef5b42c -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
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
- [ ] **T11 — Expose the interface Level Contract Compliance Checker consumes, per Contract "Level Contract v1" (dependency).** <!-- t:87778b5e -->
  Record the endpoint/identifiers Level Contract Compliance Checker needs in this node's config artifacts — coordinate with Level Contract Compliance Checker.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T12 — Expose the interface World Static Analysis Gate consumes, per Contract "Sanctioned World API Surface" (dependency).** <!-- t:a14fa597 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T13 — Implement: "Contract friction discovered while building the official worlds is fed back into the Level Contract before v1 is frozen" (REQ-011).** <!-- t:472ee673 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Contract friction discovered while building the official worlds is fed back into the Level Contract before v1 is frozen" — possible coordination point: Contract "Level Contract v1" (dependency) from OpenAxolotl Game Client (keyword signal only)
- [ ] **T14 — Implement: "Each official world is structured as a sequence of acts, each introducing a mechanic or hazard the player has not met and then requiring it, with the flown route proving every act is traversable" (REQ-011).** <!-- t:0eb4c79b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Each official world is structured as a sequence of acts, each introducing a mechanic or hazard the player has not met and then requiring it, with the flown route proving every act is traversable"
- [ ] **T15 — Implement: "Coral Cove builds to a Flagship encounter at its end and reaches it in normal play; Bubble Bay declares no boss and the hub hosts no encounter" (REQ-011).** <!-- t:1bbaee55 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Coral Cove builds to a Flagship encounter at its end and reaches it in normal play; Bubble Bay declares no boss and the hub hosts no encounter" — possible coordination point: Contract "Enemy Registration Interface" (dependency) to Flagship Boss Encounter (keyword signal only)
- [ ] **T16 — Implement: "Each world is fun to play through and delivers a satisfying broken-to-restored payoff" (REQ-011).** <!-- t:e1d96cf2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Each world is fun to play through and delivers a satisfying broken-to-restored payoff"
- [ ] **T17 — Implement: "A first-time player finishes each official world without developer instructions or debug commands" (REQ-011).** <!-- t:1b065702 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "A first-time player finishes each official world without developer instructions or debug commands"
- [ ] **T18 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-011: Official MVP Worlds
Category: functional | Status: in-progress
Two official worlds at MVP — Coral Cove and Bubble Bay — each a discrete, bounded, checkpointed playthrough space entered from the Open Lagoon hub.

THEY ARE THE GAME FIRST. This used to say their contract battle-test purpose was "the more important one." That was true when the project was framed as a platformer SDK and it is not true now: these are the levels people play, and if they are not enjoyable the contract they validate does not matter. Shipped content is the first purpose; battle-testing the Level Contract is the second, and a real one.

They must still be built as ordinary contract-conforming world modules using only the public extension interfaces, taking no shortcuts unavailable to an outside author — if a core-team world needs a private back door, that is a contract defect to fix, not a special case to permit. Friction encountered building them feeds back into the contract, and only once that feedback is absorbed is the contract frozen at v1.

SHAPE. A world is a run of acts, each introducing something the player has not done yet and then asking for it under pressure. Length is not capped: a level runs as long as its ideas sustain, and the official worlds are deliberately substantial rather than bite-sized. Each world exercises both movement grammars, at least one restoration region, and a distinct Gill Mod emphasis.

THE TWO WORLDS ARE NOT THE SAME SHAPE, DELIBERATELY. Coral Cove is the long build: acts stacking mechanic on mechanic to a Flagship at its end, where the restoration payoff lands (REQ-013). Bubble Bay ends on traversal instead (REQ-028). Neither the Open Lagoon hub nor any future hub hosts a boss — the hub is the calm place between levels and holds no encounter at all.

**Acceptance criteria — your task boxes:**
- [x] At least two official worlds are implemented, each passing the Level Contract compliance checker
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) from Level Contract Compliance Checker (keyword signal only)
- [x] Each official world is completable from spawn to finish condition
  → THIS NODE: internal logic
- [x] Each official world calls only the sanctioned world API surface, using no private back doors unavailable to an outside contributor, verified by the same static analysis applied to community submissions
  → THIS NODE: internal logic — possible coordination point: Contract "Sanctioned World API Surface" (dependency) from World Static Analysis Gate (keyword signal only)
- [x] Each official world exercises both movement grammars and contains at least one restorable region
  → THIS NODE: internal logic — possible coordination point: Contract "Restoration Region Interface" (dependency) to Restoration State System (keyword signal only)
- [x] Each official world contains at least one mandatory traversal challenge gated on a specific Gill Mod, and across the official set all three MVP mods are each required by at least one world
  → THIS NODE: internal logic — possible coordination point: Contract "Gill Mod Registration Interface" (dependency) to Gill Mod Ability Framework (keyword signal only)
- [ ] Contract friction discovered while building the official worlds is fed back into the Level Contract before v1 is frozen (manual)
  → covered by Task T13
- [ ] Each official world is structured as a sequence of acts, each introducing a mechanic or hazard the player has not met and then requiring it, with the flown route proving every act is traversable
  → covered by Task T14
- [ ] Coral Cove builds to a Flagship encounter at its end and reaches it in normal play; Bubble Bay declares no boss and the hub hosts no encounter
  → covered by Task T15
- [ ] Each world is fun to play through and delivers a satisfying broken-to-restored payoff (manual)
  → covered by Task T16
- [ ] A first-time player finishes each official world without developer instructions or debug commands (manual)
  → covered by Task T17

### REQ-036: Drift Fleet and Flagship reachable from a world
Category: functional | Status: pending
_Shared with: Drift Fleet Enemy Framework, Flagship Boss Encounter, Model Refinement Pipeline, Restoration State System — their slices live in their own task docs._
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
  → owner unresolved — this node or a sharing node (Drift Fleet Enemy Framework, Flagship Boss Encounter, Model Refinement Pipeline, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A scene node naming a unit the world never declared stays inert on every lane, not only at wiring time
  → owner unresolved — this node or a sharing node (Drift Fleet Enemy Framework, Flagship Boss Encounter, Model Refinement Pipeline, Restoration State System): no contract evidence; assign via the requirement mapping
- [x] A dredger reverts the region its node names back to barren while leaving the region's unlocked flag set
  → THIS NODE via Contract "Restoration Region Interface" (dependency) to Restoration State System — coordinate with Restoration State System
- [x] A valid boss declaration builds a Flagship encounter and its region starts locked
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Flagship Boss Encounter — coordinate with Flagship Boss Encounter
- [x] A refused boss declaration leaves the region locked rather than opening it
  → THIS NODE via Contract "Restoration Region Interface" (dependency) to Restoration State System — coordinate with Restoration State System
- [x] A boss phase volume clears a phase only when the player arrives in the grammar that phase demands
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Flagship Boss Encounter — coordinate with Flagship Boss Encounter
- [x] Both official worlds declare and place a Drift Fleet, and every walk probe, contract checker and the perf gate stay green with the units in place
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework
- [x] Every Drift Fleet unit ships as a contract-conforming asset with provenance recording the generator
  → THIS NODE via Contract "Enemy Registration Interface" (dependency) to Drift Fleet Enemy Framework — coordinate with Drift Fleet Enemy Framework

### REQ-038: Coral Cove full platforming playthrough, proven by a flown route
Category: functional | Status: pending
_Shared with: Test Harness and Fixtures — their slices live in their own task docs._
Coral Cove must be a full platforming playthrough — run, jump, swim, dive, boost and climb, with difficulty rising across its acts — and its completability must remain a headless regression test rather than a hope.

THE OLD PROBE SHAPED THE OLD LEVEL. The walk held one forward key from spawn to finish, which was honest for a corridor and quietly became the level's design: a route a held key can finish has no gaps, no climbs and no reason to leave the ground. Probe and level therefore change together.

GEOMETRY COMES FROM MEASUREMENT. The controller is driven headlessly through the greybox against the shipped tuning and reports its envelope (run 4.20 m/s, standing jump 1.81 m, running gap 3.15 m edge to edge, climb 2.0 m/s under a 6.0 m ceiling, swim 6.0 m/s, boost ×2.2). Every mandatory gap and rise on the route sits inside documented design bounds under that envelope; exactly one jump is built to the envelope's edge and it is the OPTIONAL one, onto the lantern shrimp's ledge, so the hard reach is a choice and never a wall.

THE ROUTE IS FLOWN, NOT HELD. A RoutePilot drives a declared waypoint list by pressing the same keys a player would press, through Input.parse_input_event, so bindings, grammar context, the Input System, PlayerIntent, the controller and move_and_slide are all under test on every run. Jumps commit by LOOKING — a short ray ahead along the direction of travel asks whether the floor stops there, and the hop fires on the last stride before it does — because the takeoff edge is the gap plus half the landing platform away from a waypoint, and no fixed distance is right for a 3 m pillar and a 12 m terrace at once. A waypoint that stops being reachable fails naming itself and where the body got to, which makes a broken route a bug report rather than a mystery.

Building the pilot surfaced and fixed real bugs unit tests could not see (the climb dropping four metres at the lip, the second jump of a pair lost to a never-released edge-triggered key), which is the point of it: the probe is the one consumer that exercises the whole platforming surface every run.

Checkpoint density follows REQ-003 AC-7 measured on the flown run, and the walk still proves every prior claim of the world — both grammars, both mod gates, the restorable region, collectibles, pillar one, completion and return.

**Acceptance criteria — your task boxes:**
- [x] The coral walk completes the world end to end by flying the designed waypoint route with real key presses — every jump, the dive under the brow, the rise over the shelf, the boost, the climb and both rivers — and still proves every prior claim: both grammars, both mod gates, seven seeds spent, the region restored, discoveries persisted, no life lost, completion and return
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping
- [x] The pilot commits each jump from an edge probe (a ray ahead along travel), not from a fixed distance, and a leg that cannot be completed fails naming the waypoint and the position reached
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping
- [x] Every mandatory gap is at most 2.7 m and every mandatory rise at most 1.3 m against the measured 3.15 m / 1.81 m envelope, verified edge to edge between platform footprints at generation time and enforced at run time by the flown route
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping
- [x] The optional lantern shrimp demands an envelope-edge jump off the route, and the flown route never collects it — the optional branch stays optional
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping
- [x] Checkpoint replay segments are measured on the flown run and every segment fits progression.max_retry_seconds
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping
- [x] The route exercises the climb contact grace and the sustained-verb cut on real geometry: the coral wall is crested without a fall and a held jump clears gaps a tapped one cannot
  → owner unresolved — this node or a sharing node (Test Harness and Fixtures): no contract evidence; assign via the requirement mapping

### REQ-039: Forested river valley: procedural surfaces and water placed as difficulty
Category: functional | Status: pending
_Shared with: OpenAxolotl Game Client, Blender (headless) — their slices live in their own task docs._
The space around and below a platforming route is gameplay, not garnish: a jump over nothing gives the player no way to judge height or distance, and a surface with no variation across it has no scale. Coral Cove therefore sits inside a forested river valley, and every terrain surface in the game wears a material instead of a flat colour.

SURFACES WITHOUT TEXTURE FILES. Platforms and terrain wear one shared triplanar shader — three octaves of value noise over a warped stratum term, sampled from world position on all three axes and blended by the normal, with a third colour on upward faces only for moss. A material is a handful of uniform values in a client-owned .tres. Triplanar and world-space for this project's specific reasons: level geometry is BoxMesh primitives and props are generated with no UV layout, so a texture path would mean unwrapping everything and keeping the unwrap in step with generators that change; and the grain runs ACROSS the seam where two boxes butt, which tiling cannot do. The two mod gates deliberately keep a flat colour — a gate is a rule, not geology. The whole decision, including when a baked PNG is the right tool instead, is documented in the Asset Contract's prose.

THE VALLEY: a scenery forest floor 24 m below the route (no collider — the pit volume sits BETWEEN route and floor, so a fall still dies at the last checkpoint while the player watches the forest come up at them), canopy trees planted on it that rise past the route and close overhead, ridges for sides, and banks enclosing the water so no volume's edge is ever visible. A five-prop forest kit (canopy tree, understory fern, fallen log, river reed, river boulder) is generated headless in Blender, deterministic under one seed, vertex-coloured, with provenance, the whole set well under a thousand triangles because it is placed by the dozen.

WATER IS PLACED AS DIFFICULTY. A river runs the full length of the act-1 staircase, so a missed jump there is a swim downstream and never a life — reeds mark that waterline, making the forgiveness legible. The glow grotto's pillars have no water under them at all. And the gorge river drops a MANDATORY swim into the middle of the jumping, with a rock rib to dive under and slot walls set twice-the-jump back from the landing so no bank bypasses it. The difficulty curve is thereby stated in geometry.

The shared haze is retuned from dense teal to thin grey-green air, because every scene in this game is above water and the underwater feel belongs to the water volumes, which tint it themselves; at the old density anything past thirty metres flattened into one plane and the valley rendered as an empty sea.

**Acceptance criteria — your task boxes:**
- [x] A shared triplanar world-space terrain shader exists with a small set of client-owned material resources, and Coral Cove's platforms, walls, beds and banks wear them rather than per-node flat colours — with the two mod gates keeping flat colour as the deliberate exception
  → THIS NODE via Contract "Level Contract v1" (dependency) from OpenAxolotl Game Client — coordinate with OpenAxolotl Game Client
- [x] The forest kit's five props are generated headless in Blender, deterministic under a seed, carry provenance records, and pass the Asset Contract validator inside the environment budget
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] A missed jump anywhere over the act-1 river costs a swim and never a life, while a fall in the glow grotto still costs a life at the last checkpoint: the pit volume sits between the route and the scenery forest floor and the waterway spans exactly the forgiving stretch
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The gorge river is a mandatory swim between jump sections — entered from the landing, dived under the rib, exited onto the first terrace — and its slot walls stand at least twice the measured jump from any standable edge so the swim cannot be bypassed on a bank
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] Every water volume in the world carries bubble particles (the REQ-034 dressing rule), emitted by the same construction that makes the volume so a new river cannot ship without them
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping
- [x] The retuned haze keeps distant geometry legible: rendered captures show the forest floor, trees and valley sides reading at route distance in every act, and the full verification chain stays green
  → owner unresolved — this node or a sharing node (OpenAxolotl Game Client, Blender (headless)): no contract evidence; assign via the requirement mapping

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
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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
| `test/worlds/coral_walk_probe.gd` | source | --- | draft |
| `test/worlds/run_coral_walk.gd` | source | --- | draft |
| `.nodespec/tests/req-011.tests.md` - Test plan for requirement: Official MVP Worlds | test-plan | markdown | draft |
| `test/worlds/coral_route.gd` | source | --- | draft |
| `test/hub/test_world_drift_fleet.gd` | test-plan | --- | draft |
| `worlds/coral_cove/world.json` | config | --- | draft |
| `worlds/bubble_bay/world.json` | config | --- | draft |
| `worlds/coral_cove/README.md` | doc | --- | draft |
| `docs/contract-friction.md` | doc | --- | draft |
| `worlds/coral_cove/world.tscn` | source | --- | draft |
