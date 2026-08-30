# Task: CI Pipeline

> **Scope:** implement ONLY this node ("CI Pipeline"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CI/CD Pipeline
**Technology:** GitHub Actions
**Description:** Automated build, test and deployment pipeline triggered by commits, tags or schedules.

## Your Deliverable

This component is an engine that owns its own internals (GitHub Actions). Never decompose its internals into architecture nodes, and never reimplement its functionality as application code.
- **Connection contracts** for every interface below (triggers, payloads, endpoints)
- **The engine's definition IS a deliverable code file** — whatever form this engine's definitions take (workflow/DAG, pipeline, gateway config, manifest set, scrape/rule config). Author it as an artifact bound to this node; it versions through git like any code.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW-NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Author the GitHub Actions definition artifact.** <!-- t:a115e8f0 -->
  The engine's definition IS the deliverable — in whatever form this engine's definitions take (workflow/DAG, gateway config, manifest set, scrape/rule config). Author it as a code artifact bound to this node. Never reimplement the engine's internals as application code.
- [ ] **T2 — Declare the wiring to Level Contract Compliance Checker (python-backend) per Contract "Validator CLI Invocation" (ipc).** <!-- t:7b52f757 -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T3 — Declare the wiring to Asset Contract Validator (python-backend) per Contract "Validator CLI Invocation" (ipc).** <!-- t:3d896c0d -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T4 — Declare the wiring to OpenAxolotl Game Client (godot) per Contract "Core Module Dependency" (dependency).** <!-- t:bdaacefa -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Declare the wiring to World Static Analysis Gate (python-backend) per Contract "Validator CLI Invocation" (ipc).** <!-- t:da0d4306 -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T6 — Declare the wiring to Test Harness and Fixtures (python-backend) per Contract "Validator CLI Invocation" (ipc).** <!-- t:4e18f696 -->
  Build to the contract schema EXACTLY (see Interface Contracts).
- [ ] **T7 — Configure the service to satisfy: "A PC build is produced from a clean checkout via a single documented command" (REQ-018).** <!-- t:eaefdcbe -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "A PC build is produced from a clean checkout via a single documented command" — possible coordination point: Contract "Validator CLI Invocation" (ipc) to Test Harness and Fixtures (keyword signal only)
- [ ] **T8 — Configure the service to satisfy: "The build packages the core game and all official worlds into a runnable artifact" (REQ-018).** <!-- t:2f331924 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "The build packages the core game and all official worlds into a runnable artifact" — possible coordination point: Contract "Core Module Dependency" (dependency) to OpenAxolotl Game Client (keyword signal only)
- [ ] **T9 — Configure the service to satisfy: "CI runs the Level Contract checker, the Asset Contract validator, and the automated test suite on every pull request" (REQ-018).** <!-- t:d334780b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "CI runs the Level Contract checker, the Asset Contract validator, and the automated test suite on every pull request" — possible coordination point: Contract "Validator CLI Invocation" (ipc) to Level Contract Compliance Checker (keyword signal only)
- [ ] **T10 — Configure the service to satisfy: "A pull request failing any contract check or test cannot merge" (REQ-018).** <!-- t:f79102ab -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "A pull request failing any contract check or test cannot merge" — possible coordination point: Contract "Validator CLI Invocation" (ipc) to Test Harness and Fixtures (keyword signal only)
- [ ] **T11 — Configure the service to satisfy: "Building and running the game from a clean clone is documented as a reproducible sequence of at most five commands, and following that sequence verbatim produces a running game" (REQ-018).** <!-- t:eea3a388 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Building and running the game from a clean clone is documented as a reproducible sequence of at most five commands, and following that sequence verbatim produces a running game" — possible coordination point: Contract "Core Module Dependency" (dependency) to OpenAxolotl Game Client (keyword signal only)
- [ ] **T12 — Configure the service to satisfy: "The packaged build launches and is playable end to end on a clean PC without a development environment installed" (REQ-018).** <!-- t:e6ea8c59 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "The packaged build launches and is playable end to end on a clean PC without a development environment installed" — possible coordination point: Contract "Validator CLI Invocation" (ipc) to Test Harness and Fixtures (keyword signal only)
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

### REQ-018: PC Build and Distribution
Category: technical | Status: in-progress
A reproducible PC build of the game produced from the repository, plus the CI that proves the project stays buildable and playable as contributions land. PC-only is a firm non-goal boundary, not a staging step: no console certification is planned in any phase. The build must package the core game together with its official worlds, and the pipeline must run the Level Contract checker, the Asset Contract validator, and the automated test suite so that a contribution which breaks the game or violates either contract cannot merge. Because contributors and AI agents need a fast local loop, building and running from a clean clone must be a short, documented sequence.

**Acceptance criteria — your task boxes:**
- [ ] A PC build is produced from a clean checkout via a single documented command
  → covered by Task T7
- [ ] The build packages the core game and all official worlds into a runnable artifact
  → covered by Task T8
- [ ] CI runs the Level Contract checker, the Asset Contract validator, and the automated test suite on every pull request
  → covered by Task T9
- [ ] A pull request failing any contract check or test cannot merge
  → covered by Task T10
- [ ] Building and running the game from a clean clone is documented as a reproducible sequence of at most five commands, and following that sequence verbatim produces a running game
  → covered by Task T11
- [ ] The packaged build launches and is playable end to end on a clean PC without a development environment installed (manual)
  → covered by Task T12

## Interface Contracts

### SENDS TO: Level Contract Compliance Checker (cli-tool)
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

### SENDS TO: Asset Contract Validator (cli-tool)
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

### SENDS TO: World Static Analysis Gate (cli-tool)
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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
- **Contract:** Validator CLI Invocation
- **Protocol:** ipc
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

## Technology Guidance

_Reference for executing the Implementation Tasks above — apply where relevant. The task list stands even where this guidance is thin._

**Purpose:** CI/CD automation platform built into GitHub. Define workflows as YAML files that trigger on events (push, PR, schedule, manual). Supports matrix builds, reusable workflows, and marketplace actions.

**Configuration Template:**
```
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
permissions:
  contents: read   # default-deny; widen per job only as needed
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test
```

**Best Practices:**
- Pin action versions to full SHA for security
- Use repository secrets for sensitive values
- Cache dependencies between runs
- Use environment protection rules for production deployments
- Minimize workflow permissions with permissions key

**Anti-Patterns to Avoid:**
- Hardcoding secrets in workflow files
- Using latest tag for actions
- Running workflows with excessive permissions
- Not caching between workflow runs

**Security:** Pin third-party actions to a full commit SHA — tags are mutable and have been hijacked. Set explicit least-privilege permissions at the workflow/job level (contents: read as the floor). Never expose secrets to workflows triggerable from forks; treat pull_request_target as a loaded weapon. Prefer OIDC federation to cloud providers over long-lived cloud credentials stored as repository secrets.

**Suggested File Structure:**
- `.github/workflows/ci.yml` (config)

## Manual Steps

> The following steps require manual action by a human. AI cannot complete these steps automatically.

**Quick checklist:**
- [ ] Create Workflow Directory *(required)*
- [ ] Configure Repository Secrets *(required)*
- [ ] Set Up Environment Protection Rules *(optional)*
- [ ] Configure Workflow Permissions *(optional)*

### Required Steps

#### [manual_workflow] Create Workflow Directory

Create .github/workflows/ directory in your repository root. Workflow YAML files in this directory are automatically detected by GitHub.

```bash
mkdir -p .github/workflows
```

#### [environment_variable] Configure Repository Secrets

In your repo Settings > Secrets and Variables > Actions, add secrets for API keys, deployment credentials, and tokens. These are available as secrets.MY_SECRET in workflows.

**Reference:** https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions

### Optional Steps

#### [permissions] Set Up Environment Protection Rules

In Settings > Environments, create environments (staging, production). Add protection rules: required reviewers, wait timer, and branch restrictions. Reference environments in deploy jobs.

#### [permissions] Configure Workflow Permissions

In Settings > Actions > General > Workflow permissions, set the default token permission to read-only. Explicitly grant write permissions per workflow using the permissions key.

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Level Contract Compliance Checker (this node calls/depends on it via Validator CLI Invocation (ipc))
- Asset Contract Validator (this node calls/depends on it via Validator CLI Invocation (ipc))
- OpenAxolotl Game Client (this node calls/depends on it via Core Module Dependency (dependency))
- World Static Analysis Gate (this node calls/depends on it via Validator CLI Invocation (ipc))
- Test Harness and Fixtures (this node calls/depends on it via Validator CLI Invocation (ipc))
