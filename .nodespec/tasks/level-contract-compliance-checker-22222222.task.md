# Task: Level Contract Compliance Checker

> **Scope:** implement ONLY this node ("Level Contract Compliance Checker"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CLI Tool
**Technology:** Python
**Description:** Command-line interface application for developer or operator interaction

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
This tool answers one question for one world module: does it conform to
`contracts/level_contract.v1.json`? It is the gate every world module — the two
official worlds, the reference template, and every future community submission —
passes through, and it is the first thing an AI agent authoring a world runs
against its own output.

**Catalog guidance that does not apply here.** The Python technology guidance in
this packet describes a FastAPI web service — `fastapi`/`uvicorn`, SQLAlchemy
async sessions, Celery workers, `src/main.py` + `src/routes/__init__.py`, CORS
and JWT. None of it applies. This node is a short-lived, synchronous,
filesystem-only command-line program with no HTTP surface, no database, no
broker and no async runtime. Ignore the suggested file structure in T1 and the
SDK/API pattern snippets entirely. What carries over from that guidance is only
the tooling advice: `uv` for the environment with a committed lockfile, `ruff`
for lint and format, `pytest` with fixtures, strict `mypy`, and pinned
dependencies.

**Packaging.** All four Python validators share one distribution at `tools/`
(`tools/pyproject.toml`, package `openaxolotl_tools`), because they share the
fixture corpus, the result-emitting code and the CI invocation convention;
splitting them into four distributions would duplicate all three. Each tool is
its own subpackage with its own console entry point declared in
`[project.scripts]`. `openaxolotl_tools/common/` holds the pieces every tool
needs: `result.py` (builds and serialises the `Validator CLI Invocation`
result object), `cli.py` (the shared `argparse` parent parser giving every tool
the identical `--target/--format/--fail-fast` surface), and `schemas.py`
(loads and caches the JSON Schema files from `contracts/`).

**The checker holds no rules of its own.** Package `openaxolotl_tools/levelcheck/`,
entry point `oax-level-check`. It loads `contracts/level_contract.v1.json` at
startup and validates the target module's manifest against it with `jsonschema`;
every required element, optional-element default, and naming rule comes from that
file. The criterion "adding a new rule to the contract schema changes checker
behavior without any code change" is the design constraint that decides this
node's whole shape: any time you find yourself writing an `if element ==` branch,
that rule belongs in the schema instead. The only logic that legitimately lives
in Python is what JSON Schema cannot express — directory-layout and file-naming
checks against the filesystem, and the contract-version comparison that rejects a
world targeting a version this checker does not support.

**Version handling.** Read `contractVersion` from the module manifest and compare
it against the versions the loaded schema declares support for. An unsupported
version is a single clear violation with rule id `contract.version.unsupported`,
not a cascade of downstream "missing element" errors — an agent reading a
hundred violations caused by one version mismatch will fix the wrong thing.
Detect and short-circuit.

**Emitting results.** Every run ends by constructing exactly one result object
matching the `Validator CLI Invocation` `resultSchema` — `tool`,
`schemaVersion`, `target`, `passed`, `violations[]` — and printing it as JSON
when `--format json`, or as a human-readable rendering of the same object when
`--format text` (the default). Text output is a *rendering* of the object, never
a separate code path, so a message can never appear in one format and not the
other. `schemaVersion` is read from the schema file actually loaded, not
hardcoded, so a contract bump is visible in every result. Exit codes follow the
contract exactly: `0` clean, `1` one or more `severity: "error"` violations, `2`
invocation error — bad arguments, unreadable target, missing or unparseable
schema file. A `warning`-severity violation is reported but never changes the
exit code, per the contract's merge-gate rule. `violations[].rule` is a stable
dotted id, never a message string, because that id is what an AI agent maps back
to the contract element it broke.

**Fixtures.** The conforming world, the non-conforming world and the malicious
world fixtures come from the Test Harness node via the Shared Test Fixtures
contract — import them from `openaxolotl_tools.harness.fixtures` rather than
keeping a private copy, because the criterion requires the checker, validator and
static gate to share one corpus. This checker's own test asserts that the
non-conforming fixture fails with the *specific expected* rule id, not merely
that it fails; a checker that rejects everything would otherwise pass.

**Reporting up.** Violation messages carry a `remediation` string saying what to
change. This is the field an AI agent acts on, so write it as an instruction
("declare `spawn_point` in `world.json`"), not as a restatement of the problem.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with World: Coral Cove (godot) per Contract "Level Contract v1" (dependency).** <!-- t:bd68a2e3 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with World: Bubble Bay (godot) per Contract "Level Contract v1" (dependency).** <!-- t:04060a69 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement the integration with Test Harness and Fixtures (python-backend) per Contract "Shared Test Fixtures" (dependency).** <!-- t:7d12e948 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement the integration with World: Reference Template (godot) per Contract "Level Contract v1" (dependency).** <!-- t:d6a167a4 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface CI Pipeline consumes, per Contract "Validator CLI Invocation" (ipc).** <!-- t:a39cc42a -->
  Record the endpoint/identifiers CI Pipeline needs in this node's config artifacts — coordinate with CI Pipeline.
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T7 — Implement: "A deliberately non-conforming fixture world fails the checker with the expected specific violation, and each official MVP world passes it" (REQ-007).** <!-- t:d30c83d8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "A deliberately non-conforming fixture world fails the checker with the expected specific violation, and each official MVP world passes it" — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [ ] **T8 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-007: Level Contract Automated Compliance Checker
Category: technical | Status: in-progress
The tool that makes "AI agents can build compliant levels" a fact rather than a hope. A runnable checker that validates any world module against the Level Contract and reports precise, actionable conformance failures. It must be runnable locally by a contributor, invokable by an AI coding agent as a self-check before submitting, and runnable in CI on every pull request as the automated pre-screen that runs BEFORE any human review. Because there is no editor GUI authoring path, the checker only ever needs to validate code and Godot scene files — a deliberately narrow and checkable surface. Failure output must name the specific missing or malformed contract element, not merely report pass/fail, because its primary consumer is an agent trying to self-correct.

**Acceptance criteria — your task boxes:**
- [x] Checker loads the Level Contract schema file as its source of truth and validates presence and well-formedness of every required element it declares
  → THIS NODE: internal logic — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [x] Checker validates a world's declared contract version and rejects a world targeting an unsupported version
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] Checker validates world module directory layout and naming convention
  → THIS NODE: internal logic — possible coordination point: Contract "Level Contract v1" (dependency) to World: Coral Cove (keyword signal only)
- [x] Failure output names the specific failing element, its file location, and the violated rule, emitted as structured machine-readable output an AI coding agent can parse
  → THIS NODE: internal logic — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [x] Checker exits with a non-zero status on failure and zero on success
  → THIS NODE: internal logic — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [x] Checker is runnable locally with a single documented command
  → THIS NODE: internal logic — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] A deliberately non-conforming fixture world fails the checker with the expected specific violation, and each official MVP world passes it
  → covered by Task T7
- [x] Adding a new rule to the contract schema changes checker behavior without any code change to the checker
  → THIS NODE: internal logic

## Interface Contracts

### SENDS TO: World: Coral Cove (shared-library)
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

### SENDS TO: World: Bubble Bay (shared-library)
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

### RECEIVES FROM: CI Pipeline (ci-cd-pipeline)
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** github-actions

**Schema:**
```
{
  "exitCodes": {
    "0": "all checks passed",
    "1": "one or more conformance violations found",
    "2": "invocation error (bad arguments, unreadable target, missing schema file)"
  },
  "mergeGate": "Any tool exiting non-zero blocks merge. Warnings do not block but are reported.",
  "invocation": {
    "form": "<tool-command> [--target <path>] [--format json|text] [--fail-fast]",
    "localParity": "the documented local command and the CI invocation MUST be identical, so a contributor cannot pass locally and fail in CI",
    "formatDefault": "text for humans; json required in CI and for agent self-verification",
    "targetDefault": "repository root; a world or asset module path narrows the run"
  },
  "description": "How CI invokes the four repo validators (Level Contract Checker, Asset Contract Validator, World Static Analysis Gate, Test Harness) and how results come back. Consumers are CI jobs and AI agents self-verifying before submission, so output is structured rather than prose.",
  "resultSchema": {
    "type": "object",
    "required": [
      "tool",
      "schemaVersion",
      "target",
      "passed",
      "violations"
    ],
    "properties": {
      "tool": {
        "enum": [
          "level-contract-checker",
          "asset-contract-validator",
          "world-static-analysis",
          "test-harness"
        ],
        "type": "string"
      },
      "passed": {
        "type": "boolean"
      },
      "target": {
        "type": "string"
      },
      "violations": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "rule",
            "severity",
            "file",
            "message"
          ],
          "properties": {
            "file": {
              "type": "string"
            },
            "line": {
              "type": "integer"
            },
            "rule": {
              "type": "string",
              "description": "Stable rule id, so an agent can map a failure back to the contract element that produced it"
            },
            "message": {
              "type": "string"
            },
            "severity": {
              "enum": [
                "error",
                "warning"
              ],
              "type": "string"
            },
            "remediation": {
              "type": "string",
              "description": "What to change to satisfy the rule"
            }
          }
        }
      },
      "schemaVersion": {
        "type": "string",
        "description": "Version of the contract or ruleset evaluated against"
      }
    }
  }
}
```

### SENDS TO: Test Harness and Fixtures (cli-tool)
- **Contract:** Shared Test Fixtures
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### SENDS TO: World: Reference Template (shared-library)
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

## Technology Guidance

_Reference for executing the Implementation Tasks above — apply where relevant. The task list stands even where this guidance is thin._

**Purpose:** The default language for data/ML-adjacent backends and a first-class choice for typed API services (FastAPI + Pydantic). Spans API services, workers, ML pipelines, inference services, webhook handlers and CLIs — when the component touches the data/ML ecosystem, Python is usually the honest pick.

**SDK Initialization:**
```
pip install fastapi uvicorn sqlalchemy pydantic-settings
# main.py
from fastapi import FastAPI
app = FastAPI()

@app.get("/health")
def health(): return {"status": "ok"}

# uvicorn main:app --reload
```

**Common API Patterns:**

#### REST Endpoint
FastAPI endpoint with dependency injection and response model
```
@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

#### Dependency Injection
Composable dependency chain for DB sessions and auth
```
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    payload = verify_token(token)
    return await db.get(User, payload["sub"])
```

#### Background Task
Celery task for async background processing
```
from celery import Celery
celery_app = Celery("tasks", broker="redis://localhost:6379")

@celery_app.task
def send_email(to: str, subject: str, body: str):
    smtp_client.send(to=to, subject=subject, body=body)
```

**Configuration Template:**
```
# pyproject.toml
[project]
name = "myapp"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[tool.ruff]
target-version = "py311"
select = ["E", "F", "I", "UP"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]
```

**Best Practices:**
- Type hints everywhere + Pydantic models at every boundary — FastAPI turns them into validation and OpenAPI for free
- uv for env + deps (committed lockfile, pinned python version); one venv per service
- Async where the framework is async — mixing blocking calls (requests, raw psycopg) into async handlers is the classic FastAPI foot-gun; use httpx/asyncpg
- Workers: Celery or arq with explicit idempotency — Python queue consumers WILL be redelivered
- ruff for lint+format (one tool), pytest with fixtures over unittest classes

**Anti-Patterns to Avoid:**
- Blocking I/O inside async routes (sync DB drivers, requests) — kills the event loop invisibly
- requirements.txt without pins in a production service
- Django for a pure JSON API where FastAPI is lighter — Django earns its weight only when the admin/ORM/auth batteries are used
- Global mutable module state as a cache — breaks under multiple workers

**Security:** Use Pydantic models for automatic input validation on all endpoints. Use parameterized queries via SQLAlchemy ORM, never raw string interpolation. Set CORS middleware with explicit allowed origins. Use python-jose or PyJWT for JWT validation. Pin dependencies and use pip-audit for vulnerability scanning. Never run uvicorn with --reload in production.

**Integration Patterns:**
- FastAPI or Flask for HTTP framework with automatic OpenAPI docs
- SQLAlchemy 2.0 with asyncio for async database access
- Celery or ARQ for distributed task queues
- Pydantic for data validation and settings management
- pytest with httpx.AsyncClient for async API testing

**Suggested File Structure:**
- `src/main.py` (source)
- `src/routes/__init__.py` (source)
- `pyproject.toml` (config)

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- World: Coral Cove (this node calls/depends on it via Level Contract v1 (dependency))
- World: Bubble Bay (this node calls/depends on it via Level Contract v1 (dependency))
- Test Harness and Fixtures (this node calls/depends on it via Shared Test Fixtures (dependency))
- World: Reference Template (this node calls/depends on it via Level Contract v1 (dependency))

**Depends on THIS node being available:**
- CI Pipeline (initiates Validator CLI Invocation against this node (ipc))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `tools/level_contract_checker.py` | source | --- | draft |
| `tools/.gdignore` | config | --- | draft |
| `.nodespec/tests/req-007.tests.md` - Test plan for requirement: Level Contract Automated Compliance Checker | test-plan | markdown | draft |
| `tools/test_level_contract_checker.py` | source | --- | draft |
