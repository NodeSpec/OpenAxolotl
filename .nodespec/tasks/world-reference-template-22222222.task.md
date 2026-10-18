# Task: World: Reference Template

> **Scope:** implement ONLY this node ("World: Reference Template"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
The template is the canonical starting point for a new world, and it is also the
project's minimality test. Its value comes from what it does *not* contain: it
declares no optional Level Contract elements at all, so every optional element's
absent-default path is exercised by something that ships and runs in CI.

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

**Required five, optional zero.** Implement exactly the five required elements —
spawn point, checkpoints, finish condition, controller compatibility, save
integration — and declare no optional element. That means no enemies, no
collectibles, no boss, no camera hints, no world-supplied audio. Each of those
absences is a default path asserted by a criterion somewhere else in the project
(a world declaring no collectibles stays completable; audio falls back to defaults
rather than silence; the bossless world stays contract-valid), and this template
is what keeps all of them exercised.

**No special case in the loader.** The hub discovers and loads the template like
any other world, with no branch in loader code. That is the criterion, and it is
also the cheapest ongoing proof that world discovery is genuinely generic — if
someone adds a special case for the template, this criterion fails.

**Contract changes must break it loudly.** A contract change that would make the
template non-conforming has to fail CI rather than pass silently. So the template
runs through `oax-level-check` as a required check, and it must stay minimal: a
template that declares extra elements "for illustration" would satisfy new
required elements accidentally and stop functioning as a tripwire.

**Written to be copied.** The documentation criterion is manual: instructions
covering what to copy and what to change. Write the module so those instructions
are short — clear file names, one manifest, comments marking the three or four
places a new world author actually edits. This is the file an AI coding agent
starts from when given a one-sentence world brief, so its legibility is
load-bearing for REQ-017's agent-authored-world criterion.

**Completable.** The template runs from spawn to finish condition. Keep the
traversal trivial; its job is to prove the contract, not to entertain.

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
- [ ] **T2 — Implement the integration with Save System (godot) per Contract "Save Integration Interface" (dependency).** <!-- t:bcbdac74 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface OpenAxolotl Game Client consumes, per Contract "Level Contract v1" (dependency).** <!-- t:99890668 -->
  Record the endpoint/identifiers OpenAxolotl Game Client needs in this node's config artifacts — coordinate with OpenAxolotl Game Client.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface Level Contract Compliance Checker consumes, per Contract "Level Contract v1" (dependency).** <!-- t:87778b5e -->
  Record the endpoint/identifiers Level Contract Compliance Checker needs in this node's config artifacts — coordinate with Level Contract Compliance Checker.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface World Static Analysis Gate consumes, per Contract "Sanctioned World API Surface" (dependency).** <!-- t:a14fa597 -->
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Implement: "The template is documented as the canonical starting point for a new world, with instructions on what to copy and what to change" (REQ-029).** <!-- t:ceeee88b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-029 "The template is documented as the canonical starting point for a new world, with instructions on what to copy and what to change"
- [ ] **T7 — Implement: "The template demonstrates each mechanic a new level is likely to use at least once as a worked example: both movement grammars, a checkpoint, a collectible, a Drift Fleet machine, water using the shared surface, the shared lighting rig, and one gated path" (REQ-029).** <!-- t:e9b8be87 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-029 "The template demonstrates each mechanic a new level is likely to use at least once as a worked example: both movement grammars, a checkpoint, a collectible, a Drift Fleet machine, water using the shared surface, the shared lighting rig, and one gated path" — possible coordination point: Contract "Sanctioned World API Surface" (dependency) from World Static Analysis Gate (keyword signal only)
- [ ] **T8 — Implement: "The template is short enough to play in a few minutes and its scene tree is organised and commented so a newcomer can find and change a platform, a machine and a collectible without reading any core code" (REQ-029).** <!-- t:8ef8e4e7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-029 "The template is short enough to play in a few minutes and its scene tree is organised and commented so a newcomer can find and change a platform, a machine and a collectible without reading any core code"
- [ ] **T9 — Implement: "A minimal world declaring no optional contract elements still loads and completes, proving every optional element's absent-default path, exercised by the conforming-world fixture rather than by the shipped template" (REQ-029).** <!-- t:391d993e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-029 "A minimal world declaring no optional contract elements still loads and completes, proving every optional element's absent-default path, exercised by the conforming-world fixture rather than by the shipped template"
- [ ] **T10 — Implement: "Someone who has not worked on this project opens the template in the Godot editor, makes a change of their own, and sees it in play without being told how by a maintainer" (REQ-029).** <!-- t:493d9aca -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-029 "Someone who has not worked on this project opens the template in the Godot editor, makes a change of their own, and sees it in play without being told how by a maintainer"
- [ ] **T11 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-029: Template Level — the on-ramp a new author opens
Category: technical | Status: in-progress
THE PROJECT'S TEACHING ARTIFACT, and the concrete answer to "families learn AI-development here." Not a curriculum and not a document: a level you can take apart. A newcomer opens it in Godot's own editor, plays it, changes something, and watches the change happen. That is the on-ramp, and everything else in the contribution story hangs off whether this level is actually openable by someone who has never seen the repo.

WHAT CHANGED, AND WHY. This started as a deliberately minimal fixture: five required contract elements, nothing optional, existing to prove the contract was satisfiable and that every optional element's absent-default really worked. That is a real job but it is a CI job, and it is the wrong shape for teaching — you cannot learn a game from an empty room, and a template that demonstrates nothing gives a newcomer nothing to change. That proof moves to `fixtures/worlds/conforming_world`, which already exists and is already exercised by the compliance checker, and the shipped template becomes the thing it is actually for.

WHAT IT HAS TO BE. Playable start to finish and small enough to hold in your head — minutes, not the acts an official world runs to. Built from a representative slice of the REAL game: the shipped axolotl, at least one Drift Fleet machine, water with the real shader, the shared lighting rig, a checkpoint, a collectible, and at least one mod-gated or restoration-gated path — so that every mechanic a newcomer might want to use is present once, as a worked example they can copy in place. Laid out and commented so the obvious first edits are obvious: move a platform, add a machine, drop in a collectible, retune a jump.

WHAT IT STILL HAS TO BE. It remains what a new level is COPIED from, so it must never drift out of conformance: validated by the compliance checker and the static-analysis gate on every pull request exactly like any other world, so a contract change that would break it fails CI rather than silently teaching the wrong pattern. Coral Cove and Bubble Bay are full official worlds and far too large to serve either purpose.

**Acceptance criteria — your task boxes:**
- [x] The template implements all five required Level Contract elements: spawn point, checkpoints, finish condition, controller compatibility, save integration
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) from OpenAxolotl Game Client (keyword signal only)
- [x] The template passes the Level Contract compliance checker as a required CI check
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) from Level Contract Compliance Checker (keyword signal only)
- [x] The template passes the World Static Analysis Gate, calling only the sanctioned world API surface
  → THIS NODE: internal logic — possible coordination point: Contract "Sanctioned World API Surface" (dependency) from World Static Analysis Gate (keyword signal only)
- [x] The hub discovers and loads the template like any other world, with no special case in loader code
  → THIS NODE: internal logic
- [x] The template is completable from spawn to finish condition
  → THIS NODE: internal logic
- [x] A contract change that would make the template non-conforming fails CI rather than passing silently
  → THIS NODE: internal logic
- [ ] The template is documented as the canonical starting point for a new world, with instructions on what to copy and what to change (manual)
  → covered by Task T6
- [ ] The template demonstrates each mechanic a new level is likely to use at least once as a worked example: both movement grammars, a checkpoint, a collectible, a Drift Fleet machine, water using the shared surface, the shared lighting rig, and one gated path
  → covered by Task T7
- [ ] The template is short enough to play in a few minutes and its scene tree is organised and commented so a newcomer can find and change a platform, a machine and a collectible without reading any core code
  → covered by Task T8
- [ ] A minimal world declaring no optional contract elements still loads and completes, proving every optional element's absent-default path, exercised by the conforming-world fixture rather than by the shipped template
  → covered by Task T9
- [ ] Someone who has not worked on this project opens the template in the Godot editor, makes a change of their own, and sees it in play without being told how by a maintainer (manual)
  → covered by Task T10

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

### SENDS TO: Save System (shared-library)
- **Contract:** Save Integration Interface
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
- Save System (this node calls/depends on it via Save Integration Interface (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Client (initiates Level Contract v1 against this node (dependency))
- Level Contract Compliance Checker (initiates Level Contract v1 against this node (dependency))
- World Static Analysis Gate (initiates Sanctioned World API Surface against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `worlds/reference_template/world.json` | config | --- | draft |
| `worlds/reference_template/world.tscn` | source | --- | draft |
| `worlds/reference_template/README.md` | doc | --- | draft |
| `test/worlds/run_template_walk.gd` | source | --- | draft |
| `test/worlds/template_walk_probe.gd` | source | --- | draft |
| `tools/test_reference_template.py` | source | --- | draft |
| `.nodespec/tests/req-029.tests.md` - Test plan for requirement: Reference Template World | test-plan | markdown | draft |
