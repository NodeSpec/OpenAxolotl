# Task: Asset Contract Validator

> **Scope:** implement ONLY this node ("Asset Contract Validator"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CLI Tool
**Technology:** Python
**Description:** Command-line interface application for developer or operator interaction

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW-NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with OpenAxolotl Game Client (godot) per Contract "Asset Contract v1" (custom).** <!-- t:33a614a7 -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T3 — Implement the integration with Audio System (godot) per Contract "Asset Contract v1" (custom).** <!-- t:1ee9a25e -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T4 — Implement the integration with Test Harness and Fixtures (python-backend) per Contract "Shared Test Fixtures" (dependency).** <!-- t:7d12e948 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface CI Pipeline consumes, per Contract "Validator CLI Invocation" (ipc).** <!-- t:a39cc42a -->
  Record the endpoint/identifiers CI Pipeline needs in this node's config artifacts — coordinate with CI Pipeline.
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T6 — Implement: "Asset Contract specifies required file types, resolution/format constraints, and alpha-channel handling per asset category" (REQ-015).** <!-- t:387fc410 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Asset Contract specifies required file types, resolution/format constraints, and alpha-channel handling per asset category" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T7 — Implement: "Asset Contract specifies the asset directory layout and naming convention" (REQ-015).** <!-- t:ad43b317 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Asset Contract specifies the asset directory layout and naming convention" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T8 — Implement: "Every asset requires a provenance.json recording author, generation method, and applicable license terms" (REQ-015).** <!-- t:82d20684 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Every asset requires a provenance.json recording author, generation method, and applicable license terms" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T9 — Implement: "AI-generated assets additionally record the generation tool and the prompt used; these fields are not required for hand-authored assets" (REQ-015).** <!-- t:cf9bda0b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "AI-generated assets additionally record the generation tool and the prompt used; these fields are not required for hand-authored assets" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T10 — Implement: "provenance.json has a defined schema whose generation-method field distinguishes ai-generated from hand-authored, and which conditionally requires the tool and prompt fields accordingly" (REQ-015).** <!-- t:a4f99d10 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "provenance.json has a defined schema whose generation-method field distinguishes ai-generated from hand-authored, and which conditionally requires the tool and prompt fields accordingly" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T11 — Implement: "Contract documents the style and art-direction expectations a human maintainer reviews against" (REQ-015).** <!-- t:39924a69 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Contract documents the style and art-direction expectations a human maintainer reviews against" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T12 — Implement: "A contributor can produce a conforming asset from the Asset Contract document alone" (REQ-015).** <!-- t:6566e4f2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "A contributor can produce a conforming asset from the Asset Contract document alone"
- [ ] **T13 — Implement: "Validator checks file type, resolution, format, and alpha-channel conformance per asset category" (REQ-016).** <!-- t:719700d2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Validator checks file type, resolution, format, and alpha-channel conformance per asset category" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T14 — Implement: "Validator checks directory placement and naming convention conformance" (REQ-016).** <!-- t:562d02b1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Validator checks directory placement and naming convention conformance" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T15 — Implement: "Validator requires a provenance.json per asset and validates it against the defined schema, failing on a missing or malformed one" (REQ-016).** <!-- t:428f15c1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Validator requires a provenance.json per asset and validates it against the defined schema, failing on a missing or malformed one" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T16 — Implement: "Failure output names the specific asset and the specific violated rule" (REQ-016).** <!-- t:dfa9099b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Failure output names the specific asset and the specific violated rule" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T17 — Implement: "Validator exits non-zero on failure and runs as a required CI check on every pull request touching assets" (REQ-016).** <!-- t:cf7730dc -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Validator exits non-zero on failure and runs as a required CI check on every pull request touching assets" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T18 — Implement: "Validator is runnable locally with a single documented command" (REQ-016).** <!-- t:1aad56aa -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Validator is runnable locally with a single documented command" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T19 — Implement: "A deliberately non-conforming fixture asset fails validation and conforming official assets pass" (REQ-016).** <!-- t:58c57927 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "A deliberately non-conforming fixture asset fails validation and conforming official assets pass" — possible coordination point: Contract "Shared Test Fixtures" (dependency) to Test Harness and Fixtures (keyword signal only)
- [ ] **T20 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-015: Asset Contract and AI-Art Provenance
Category: technical | Status: in-progress
The art-side sibling of the Level Contract: a specification any character, creature, or prop asset must conform to in order to enter the repo. Contributors generate art with whatever external AI tool they choose (offline authoring — no in-editor generation plugin at MVP), then drop conforming output into the repo. The contract defines required file types, directory layout and naming convention, resolution and format specs, alpha-channel handling, and a required provenance.json per asset. Provenance records author, generation method, and applicable license terms for EVERY asset; AI-generated assets additionally record the generation tool and prompt, which do not apply to hand-authored work. Provenance capture is not bookkeeping: AI-generated art may carry different rights and attribution obligations depending on generator terms of service, which is why it intersects directly with the project licensing decision.

**Acceptance criteria — your task boxes:**
- [ ] Asset Contract specifies required file types, resolution/format constraints, and alpha-channel handling per asset category
  → covered by Task T6
- [ ] Asset Contract specifies the asset directory layout and naming convention
  → covered by Task T7
- [ ] Every asset requires a provenance.json recording author, generation method, and applicable license terms
  → covered by Task T8
- [ ] AI-generated assets additionally record the generation tool and the prompt used; these fields are not required for hand-authored assets
  → covered by Task T9
- [ ] provenance.json has a defined schema whose generation-method field distinguishes ai-generated from hand-authored, and which conditionally requires the tool and prompt fields accordingly
  → covered by Task T10
- [ ] Contract documents the style and art-direction expectations a human maintainer reviews against (manual)
  → covered by Task T11
- [ ] A contributor can produce a conforming asset from the Asset Contract document alone (manual)
  → covered by Task T12

### REQ-016: Asset Contract Automated Validator
Category: technical | Status: in-progress
The art-pipeline counterpart to the Level Contract checker, and the automated half of the two-stage art gate. Validates submitted assets against the Asset Contract on every pull request BEFORE a human maintainer spends time on art-direction review: correct file types, conforming resolution and format, valid alpha handling, correct directory placement and naming, and a present, schema-valid provenance.json. Structural conformance is machine-checked; style and art-direction judgment remains explicitly human. Like the level checker, it must be locally runnable and produce failures specific enough for a contributor or an AI agent to correct without guesswork.

**Acceptance criteria — your task boxes:**
- [ ] Validator checks file type, resolution, format, and alpha-channel conformance per asset category
  → covered by Task T13
- [ ] Validator checks directory placement and naming convention conformance
  → covered by Task T14
- [ ] Validator requires a provenance.json per asset and validates it against the defined schema, failing on a missing or malformed one
  → covered by Task T15
- [ ] Failure output names the specific asset and the specific violated rule
  → covered by Task T16
- [ ] Validator exits non-zero on failure and runs as a required CI check on every pull request touching assets
  → covered by Task T17
- [ ] Validator is runnable locally with a single documented command
  → covered by Task T18
- [ ] A deliberately non-conforming fixture asset fails validation and conforming official assets pass
  → covered by Task T19

## Interface Contracts

### SENDS TO: OpenAxolotl Game Client (game-client)
- **Contract:** Asset Contract v1
- **Protocol:** custom
- **Their Technology:** godot

**Schema:**
```
{
  "categories": [
    "character",
    "creature",
    "prop",
    "environment",
    "audio"
  ],
  "assetLayout": "assets/<category>/<name>/",
  "humanReview": "style and art direction remain a human maintainer judgment; structural conformance is machine-checked",
  "contractVersion": "1.0",
  "provenanceSchema": {
    "tool": {
      "description": "Generator name and version; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "author": {
      "required": true
    },
    "prompt": {
      "description": "Prompt used; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "licenseTerms": {
      "required": true,
      "description": "Applicable license terms; for ai-generated assets these are the generator's terms of service"
    },
    "generationMethod": {
      "enum": [
        "ai-generated",
        "hand-authored"
      ],
      "required": true
    }
  },
  "requiredPerAsset": [
    "conforming source files",
    "provenance.json"
  ]
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

### SENDS TO: Audio System (shared-library)
- **Contract:** Asset Contract v1
- **Protocol:** custom
- **Their Technology:** godot

**Schema:**
```
{
  "categories": [
    "character",
    "creature",
    "prop",
    "environment",
    "audio"
  ],
  "assetLayout": "assets/<category>/<name>/",
  "humanReview": "style and art direction remain a human maintainer judgment; structural conformance is machine-checked",
  "contractVersion": "1.0",
  "provenanceSchema": {
    "tool": {
      "description": "Generator name and version; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "author": {
      "required": true
    },
    "prompt": {
      "description": "Prompt used; not required for hand-authored assets",
      "requiredWhen": "generationMethod == ai-generated"
    },
    "licenseTerms": {
      "required": true,
      "description": "Applicable license terms; for ai-generated assets these are the generator's terms of service"
    },
    "generationMethod": {
      "enum": [
        "ai-generated",
        "hand-authored"
      ],
      "required": true
    }
  },
  "requiredPerAsset": [
    "conforming source files",
    "provenance.json"
  ]
}
```

### SENDS TO: Test Harness and Fixtures (cli-tool)
- **Contract:** Shared Test Fixtures
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

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
- OpenAxolotl Game Client (this node calls/depends on it via Asset Contract v1 (custom))
- Audio System (this node calls/depends on it via Asset Contract v1 (custom))
- Test Harness and Fixtures (this node calls/depends on it via Shared Test Fixtures (dependency))

**Depends on THIS node being available:**
- CI Pipeline (initiates Validator CLI Invocation against this node (ipc))
