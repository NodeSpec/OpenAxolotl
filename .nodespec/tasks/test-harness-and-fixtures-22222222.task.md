# Task: Test Harness and Fixtures

> **Scope:** implement ONLY this node ("Test Harness and Fixtures"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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

- [ ] **T1 — Scaffold the Python component.**
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with OpenAxolotl Game Client (godot) per Contract "Core Module Dependency" (dependency).**
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface CI Pipeline consumes, per Contract "Validator CLI Invocation" (ipc).**
  Record the endpoint/identifiers CI Pipeline needs in this node's config artifacts — coordinate with CI Pipeline.
  Build to the contract schema EXACTLY (see Interface Contracts).
  ↳ serves (unverified match): REQ-026 "Named fixtures exist for a conforming world, a non-conforming world, a malicious world, a conforming asset, and a non-conforming asset, and are shared by the checker, validator, and static-analysis tests" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T4 — Expose the interface Level Contract Compliance Checker consumes, per Contract "Shared Test Fixtures" (dependency).**
  Record the endpoint/identifiers Level Contract Compliance Checker needs in this node's config artifacts — coordinate with Level Contract Compliance Checker.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  ↳ serves (unverified match): REQ-026 "Unit tests cover the capability, lives, restoration, ability-registration, and save-interface logic" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-026 "Integration tests exercise each system against the controller and save-integration interfaces rather than in isolation only" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-026 "A headless playthrough smoke test drives an official world from spawn to finish condition and asserts completion" — requirement not mapped to that node; verify or reassign before relying on it
  ↳ serves (unverified match): REQ-026 "Test output identifies the failing requirement or criterion it maps to, so a contributor or agent can locate what broke" — requirement not mapped to that node; verify or reassign before relying on it
- [ ] **T5 — Expose the interface Asset Contract Validator consumes, per Contract "Shared Test Fixtures" (dependency).**
  Record the endpoint/identifiers Asset Contract Validator needs in this node's config artifacts — coordinate with Asset Contract Validator.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface World Static Analysis Gate consumes, per Contract "Shared Test Fixtures" (dependency).**
  Record the endpoint/identifiers World Static Analysis Gate needs in this node's config artifacts — coordinate with World Static Analysis Gate.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement: "The suite runs headless with a single documented command and exits non-zero on any failure" (REQ-026).**
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-026 "The suite runs headless with a single documented command and exits non-zero on any failure"
- [ ] **T8 — Implement: "The suite runs in CI on every pull request" (REQ-026).**
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-026 "The suite runs in CI on every pull request"
- [ ] **T9 — Verify every acceptance criterion above and tick its box.**
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

### REQ-026: Automated Test Suite and Test Harness
Category: technical | Status: in-progress
REQ-018 requires CI to run "the automated test suite" but nothing required that suite to exist or defined its scope. For a project whose central claim is that AI agents can contribute compliant worlds, the test harness is load-bearing infrastructure: it is how an agent proves its own work before submitting, and it is what stops a contributed world from silently breaking core systems. Scope covers three tiers — unit tests for system logic, integration tests exercising a system against the controller and save interfaces, and headless playthrough smoke tests that drive an official world from spawn to finish condition to catch regressions no unit test would. Godot supports headless execution, so playthrough tests are runnable in CI without a display. Test fixtures (a conforming world, a non-conforming world, a malicious world, a conforming and non-conforming asset) are themselves deliverables, since several requirements assert against them.

**Acceptance criteria — your task boxes:**
- [ ] The suite runs headless with a single documented command and exits non-zero on any failure
  → covered by Task T7
- [ ] Unit tests cover the capability, lives, restoration, ability-registration, and save-interface logic
  → covered by Task T4
- [ ] Integration tests exercise each system against the controller and save-integration interfaces rather than in isolation only
  → covered by Task T4
- [ ] A headless playthrough smoke test drives an official world from spawn to finish condition and asserts completion
  → covered by Task T4
- [ ] Named fixtures exist for a conforming world, a non-conforming world, a malicious world, a conforming asset, and a non-conforming asset, and are shared by the checker, validator, and static-analysis tests
  → covered by Task T3
- [ ] Test output identifies the failing requirement or criterion it maps to, so a contributor or agent can locate what broke
  → covered by Task T4
- [ ] The suite runs in CI on every pull request
  → covered by Task T8

## Interface Contracts

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

### SENDS TO: OpenAxolotl Game Client (game-client)
- **Contract:** Core Module Dependency
- **Protocol:** dependency
- **Their Technology:** godot

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Level Contract Compliance Checker (cli-tool)
- **Contract:** Shared Test Fixtures
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: Asset Contract Validator (cli-tool)
- **Contract:** Shared Test Fixtures
- **Protocol:** dependency
- **Their Technology:** python-backend

_Dependency contract — no payload schema expected. Capture the connection/config
expectations (endpoints, identifiers, references) in this node's config artifacts;
propose a schema only if a real payload shape exists for this interface._

### RECEIVES FROM: World Static Analysis Gate (cli-tool)
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
- OpenAxolotl Game Client (this node calls/depends on it via Core Module Dependency (dependency))

**Depends on THIS node being available:**
- CI Pipeline (initiates Validator CLI Invocation against this node (ipc))
- Level Contract Compliance Checker (initiates Shared Test Fixtures against this node (dependency))
- Asset Contract Validator (initiates Shared Test Fixtures against this node (dependency))
- World Static Analysis Gate (initiates Shared Test Fixtures against this node (dependency))
