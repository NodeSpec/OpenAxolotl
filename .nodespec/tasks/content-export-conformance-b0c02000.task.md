# Task: Content Export & Conformance

> **Scope:** implement ONLY this node ("Content Export & Conformance"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** CLI Tool
**Technology:** Python
**Description:** Command-line interface application for developer or operator interaction

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Constraints That Apply Here

None recorded for this node. Standing conditions the build must honour (security, compliance, cost, technology and the like) can be filed with a `create_constraint` patch.

## Implementation Context

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
- [ ] **T2 — Implement the integration with Versioned World Runtime API (godot) per Contract "Declarative World Definition v1" (dependency).** <!-- t:277a8bd7 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Approved Kit Entry v1" (dependency).** <!-- t:8692c42f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface Family Workshop & Starter consumes, per Contract "Data-only Level Package Manifest v1" (dependency).** <!-- t:cbc0b876 -->
  Record the endpoint/identifiers Family Workshop & Starter needs in this node's config artifacts — coordinate with Family Workshop & Starter.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Curated Review & Release consumes, per Contract "Conformance Evidence v1" (dependency).** <!-- t:4edd0a25 -->
  Record the endpoint/identifiers Curated Review & Release needs in this node's config artifacts — coordinate with Curated Review & Release.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface Quality Evidence & Migration Gates consumes, per Contract "Conformance Evidence v1" (dependency).** <!-- t:b9dcea9e -->
  Record the endpoint/identifiers Quality Evidence & Migration Gates needs in this node's config artifacts — coordinate with Quality Evidence & Migration Gates.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement: "CI runs level/schema checks, asset checks, public-API/static rules, representative real-input route tests and the relevant core regressions from a documented clean setup." (REQ-012).** <!-- t:bb634300 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "CI runs level/schema checks, asset checks, public-API/static rules, representative real-input route tests and the relevant core regressions from a documented clean setup." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) to Reusable Level & Asset Kit (keyword signal only)
- [ ] **T8 — Implement: "Validation detects missing markers, unreachable required progression, gate bypasses, capsule-sized containment gaps and invalid habitat placement." (REQ-012).** <!-- t:1bd7db58 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Validation detects missing markers, unreachable required progression, gate bypasses, capsule-sized containment gaps and invalid habitat placement."
- [ ] **T9 — Implement: "Package validation enforces file-count, compressed/uncompressed size and allowed-resource limits, safe paths and integrity checks before activation." (REQ-012).** <!-- t:ebd42c47 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Package validation enforces file-count, compressed/uncompressed size and allowed-resource limits, safe paths and integrity checks before activation." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) from Family Workshop & Starter (keyword signal only)
- [ ] **T10 — Implement: "Each acceptance criterion records a current result or an explicit manual review; skipped, stale or historical checks are not reported as passing." (REQ-012).** <!-- t:42414c38 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Each acceptance criterion records a current result or an explicit manual review; skipped, stale or historical checks are not reported as passing." — possible coordination point: Contract "Conformance Evidence v1" (dependency) from Curated Review & Release (keyword signal only)
- [ ] **T11 — Implement: "Test plans use one initial binding scenario per automated acceptance criterion and a separate manual checklist; performance measurements use a rendered build and visual quality is never inferred from a headless pass." (REQ-012).** <!-- t:d706a0f2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Test plans use one initial binding scenario per automated acceptance criterion and a separate manual checklist; performance measurements use a rendered build and visual quality is never inferred from a headless pass." — possible coordination point: Contract "Conformance Evidence v1" (dependency) from Quality Evidence & Migration Gates (keyword signal only)
- [ ] **T12 — Implement: "Route tests drive the production controller with real input through entrance, pools, underwater turns and every section; teleporting between checkpoints cannot count as traversal proof." (REQ-012).** <!-- t:7ea1bddc -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-012 "Route tests drive the production controller with real input through entrance, pools, underwater turns and every section; teleporting between checkpoints cannot count as traversal proof."
- [ ] **T13 — Implement: "The machine-readable package schema defines identity/version, contract/runtime/kit compatibility, sections, spawn, checkpoints, objectives, finish, asset references, save schema, credits and integrity metadata." (REQ-011).** <!-- t:104bb36d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "The machine-readable package schema defines identity/version, contract/runtime/kit compatibility, sections, spawn, checkpoints, objectives, finish, asset references, save schema, credits and integrity metadata." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) to Reusable Level & Asset Kit (keyword signal only)
- [ ] **T14 — Implement: "Export and load reject scripts, native extensions, executable resource/scene references, unknown behavior IDs, invalid parameter ranges and paths outside the package namespace." (REQ-011).** <!-- t:6b45c654 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Export and load reject scripts, native extensions, executable resource/scene references, unknown behavior IDs, invalid parameter ranges and paths outside the package namespace." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) from Family Workshop & Starter (keyword signal only)
- [ ] **T15 — Implement: "A conforming starter exports and loads through the same runtime content path used for approved community levels." (REQ-011).** <!-- t:25a8aae8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "A conforming starter exports and loads through the same runtime content path used for approved community levels." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) from Family Workshop & Starter (keyword signal only)
- [ ] **T16 — Implement: "A proposed mechanic requiring new executable behavior is routed to a separate reviewed core-code change rather than smuggled into a downloadable level." (REQ-011).** <!-- t:477c6433 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "A proposed mechanic requiring new executable behavior is routed to a separate reviewed core-code change rather than smuggled into a downloadable level." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) from Family Workshop & Starter (keyword signal only)
- [ ] **T17 — Implement: "Trusted editor authoring may use scripts and scenes, but export compiles supported placements into the downloadable data schema; the runtime never loads a submitted executable scene or script as content." (REQ-011).** <!-- t:3d826860 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-011 "Trusted editor authoring may use scripts and scenes, but export compiles supported placements into the downloadable data schema; the runtime never loads a submitted executable scene or script as content." — possible coordination point: Contract "Declarative World Definition v1" (dependency) to Versioned World Runtime API (keyword signal only)
- [ ] **T18 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.

**Your first action — expand these work orders.** Each task above guarantees WHAT must be covered, not HOW. Before writing any code or configuration, expand every task with the concrete implementation steps for THIS technology in THIS project — the specific resources, settings, files, schemas, and tests — using the Configuration, Interface Contracts, Existing Implementation, Technology Guidance, and node context as your references. Write each work order's steps under its task line as indented checkbox lines (`  - [ ] <step>`), one action each, naming the file, setting or interface it changes, and send them with update_artifact (propose_patches, passing base_sequence) after this doc is accepted, keeping task IDs, criterion citations, and open `[PLACEHOLDER: …]` tags intact; the steps stay with their work order when this doc regenerates. Resolve placeholders with the user through the proposal flow; this node is never complete while one remains open. When the work orders are implemented, verify through the test lane: run get_test_plan for each requirement this node serves, implement and run the plan's tests, and report outcomes via report_test_results — passing results are the evidence that flips criteria met.

## Configuration

User-selected configuration for this component (honor these choices):
- **engine:** Python 3.11+ CLI
- **delivery:** Desktop first; tablet feasibility and consoles deferred.
- **gameplayBaseline:** 2464a14a40e2be6dbccab9d141ba3e0e783d3e45

## Vision This Node Serves

The sentences of the project vision that the outcomes behind this node's requirements cite:

- With a parent, remix a small playable starter using the shared asset/gameplay kit, Codex and NodeSpec, previewing and iterating in Godot.
- Published downloadable level packages contain only supported declarative content and approved component/asset references.
- Arbitrary scripts, native extensions and executable scene resources are excluded from that package format.
- Publish only packages that pass conformance checks, human play/content review and measured device budgets.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-012: Automated content checks and reproducible builds
Category: technical | Status: pending
Conformance validates the level actually played, including route safety and progression, and fails with actionable diagnostics. Existing historical test results are not copied as fresh proof.

**Acceptance criteria — your task boxes:**
- [ ] CI runs level/schema checks, asset checks, public-API/static rules, representative real-input route tests and the relevant core regressions from a documented clean setup.
  → covered by Task T7
- [ ] Validation detects missing markers, unreachable required progression, gate bypasses, capsule-sized containment gaps and invalid habitat placement.
  → covered by Task T8
- [ ] Package validation enforces file-count, compressed/uncompressed size and allowed-resource limits, safe paths and integrity checks before activation.
  → covered by Task T9
- [ ] Each acceptance criterion records a current result or an explicit manual review; skipped, stale or historical checks are not reported as passing.
  → covered by Task T10
- [ ] Test plans use one initial binding scenario per automated acceptance criterion and a separate manual checklist; performance measurements use a rendered build and visual quality is never inferred from a headless pass.
  → covered by Task T11
- [ ] Route tests drive the production controller with real input through entrance, pools, underwater turns and every section; teleporting between checkpoints cannot count as traversal proof.
  → covered by Task T12

### REQ-011: A bounded, versioned downloadable content format
Category: technical | Status: pending
Local Godot source may be freely iterated, but published level packages contain only supported declarative content and approved component/asset references. A Godot scene or PCK is not assumed safe merely because it is called content.

**Acceptance criteria — your task boxes:**
- [ ] The machine-readable package schema defines identity/version, contract/runtime/kit compatibility, sections, spawn, checkpoints, objectives, finish, asset references, save schema, credits and integrity metadata.
  → covered by Task T13
- [ ] Export and load reject scripts, native extensions, executable resource/scene references, unknown behavior IDs, invalid parameter ranges and paths outside the package namespace.
  → covered by Task T14
- [ ] A conforming starter exports and loads through the same runtime content path used for approved community levels.
  → covered by Task T15
- [ ] A proposed mechanic requiring new executable behavior is routed to a separate reviewed core-code change rather than smuggled into a downloadable level.
  → covered by Task T16
- [ ] Trusted editor authoring may use scripts and scenes, but export compiles supported placements into the downloadable data schema; the runtime never loads a submitted executable scene or script as content.
  → covered by Task T17

## Interface Contracts

### RECEIVES FROM: Family Workshop & Starter (cli-tool)
- **Contract:** Data-only Level Package Manifest v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "type": "object",
  "title": "Data-only Level Package Manifest v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "version",
    "worldApiVersion",
    "minimumGameVersion",
    "definitionPath",
    "files",
    "unpackedBytes",
    "creditsPath",
    "kitVersion",
    "saveSchemaVersion",
    "validationProfileId"
  ],
  "properties": {
    "files": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "path",
          "sha256",
          "bytes",
          "kind"
        ],
        "properties": {
          "kind": {
            "enum": [
              "definition",
              "mesh",
              "texture",
              "audio",
              "credits"
            ],
            "type": "string"
          },
          "path": {
            "type": "string",
            "minLength": 1
          },
          "bytes": {
            "type": "integer",
            "minimum": 0
          },
          "sha256": {
            "type": "string",
            "pattern": "^[a-f0-9]{64}$"
          }
        },
        "additionalProperties": false
      }
    },
    "version": {
      "type": "string",
      "minLength": 1
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "kitVersion": {
      "type": "string",
      "minLength": 1
    },
    "creditsPath": {
      "type": "string",
      "minLength": 1
    },
    "schemaVersion": {
      "const": 1
    },
    "unpackedBytes": {
      "type": "integer",
      "minimum": 0
    },
    "definitionPath": {
      "type": "string",
      "minLength": 1
    },
    "worldApiVersion": {
      "const": "1"
    },
    "saveSchemaVersion": {
      "type": "integer",
      "minimum": 1
    },
    "minimumGameVersion": {
      "type": "string",
      "minLength": 1
    },
    "validationProfileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    }
  },
  "description": "Published package permits only validated data and explicitly approved resource encodings; executable scripts and scene-attached code are forbidden. Paths must be relative normalized non-symlink paths without traversal; declared and extracted sizes obey a versioned limit profile. Authoring scripts may be used only locally to produce validated data. Raw Godot PCK import is not the published-content security boundary.",
  "additionalProperties": false
}
```

### SENDS TO: Versioned World Runtime API (shared-library)
- **Contract:** Declarative World Definition v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Declarative World Definition v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "worldVersion",
    "apiVersion",
    "entrySpawn",
    "spawns",
    "checkpoints",
    "components",
    "objectives",
    "finish",
    "sections",
    "saveSchemaVersion",
    "controllerProfileId",
    "kitVersion"
  ],
  "properties": {
    "finish": {
      "type": "object",
      "required": [
        "objectiveId",
        "returnDestination"
      ],
      "properties": {
        "objectiveId": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9_.:-]+$"
        },
        "returnDestination": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9_.:-]+$"
        }
      },
      "additionalProperties": false
    },
    "spawns": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "id",
          "position"
        ],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "position": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "maxItems": 3,
            "minItems": 3
          }
        },
        "additionalProperties": false
      }
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "sections": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "id",
          "componentIds",
          "checkpointIds"
        ],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "componentIds": {
            "type": "array",
            "items": {
              "type": "string",
              "pattern": "^[a-zA-Z0-9_.:-]+$"
            }
          },
          "checkpointIds": {
            "type": "array",
            "items": {
              "type": "string",
              "pattern": "^[a-zA-Z0-9_.:-]+$"
            }
          }
        },
        "additionalProperties": false
      },
      "minItems": 1
    },
    "apiVersion": {
      "const": "1"
    },
    "components": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "instanceId",
          "kitEntryId",
          "position",
          "rotation",
          "scale",
          "configurationRef"
        ],
        "properties": {
          "scale": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "maxItems": 3,
            "minItems": 3
          },
          "position": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "maxItems": 3,
            "minItems": 3
          },
          "rotation": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "maxItems": 3,
            "minItems": 3
          },
          "instanceId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "kitEntryId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "configurationRef": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false
      }
    },
    "entrySpawn": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "kitVersion": {
      "type": "string",
      "minLength": 1
    },
    "objectives": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "id",
          "kind",
          "targetIds",
          "requiredCount"
        ],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "kind": {
            "enum": [
              "collect",
              "restore",
              "reach_volume"
            ],
            "type": "string"
          },
          "targetIds": {
            "type": "array",
            "items": {
              "type": "string",
              "pattern": "^[a-zA-Z0-9_.:-]+$"
            }
          },
          "requiredCount": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false
      }
    },
    "checkpoints": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "id",
          "spawnId"
        ],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "spawnId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          }
        },
        "additionalProperties": false
      }
    },
    "worldVersion": {
      "type": "string",
      "minLength": 1
    },
    "schemaVersion": {
      "const": 1
    },
    "saveSchemaVersion": {
      "type": "integer",
      "minimum": 1
    },
    "controllerProfileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    }
  },
  "description": "Target contract, not the legacy on-disk format. All IDs and configurationRefs must resolve to approved typed kit descriptors; dangling references fail before activation. Validate → stage → register → spawn; failures roll back. Creators cannot access private service paths or inject executable scripts.",
  "additionalProperties": false
}
```

### SENDS TO: Reusable Level & Asset Kit (shared-library)
- **Contract:** Approved Kit Entry v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Approved Kit Entry v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "entryId",
    "kind",
    "resourceId",
    "configurationSchema",
    "metersPerUnit",
    "bounds",
    "collisionProfile",
    "materialProfile",
    "sockets",
    "licenseRecordId",
    "version",
    "dependencies",
    "habitats",
    "forwardAxis"
  ],
  "properties": {
    "kind": {
      "enum": [
        "terrain",
        "prop",
        "character",
        "enemy",
        "water",
        "objective",
        "audio",
        "effect"
      ],
      "type": "string"
    },
    "bounds": {
      "type": "object",
      "required": [
        "minimum",
        "maximum"
      ],
      "properties": {
        "maximum": {
          "type": "array",
          "items": {
            "type": "number"
          },
          "maxItems": 3,
          "minItems": 3
        },
        "minimum": {
          "type": "array",
          "items": {
            "type": "number"
          },
          "maxItems": 3,
          "minItems": 3
        }
      },
      "additionalProperties": false
    },
    "entryId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "sockets": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      }
    },
    "version": {
      "type": "string",
      "minLength": 1
    },
    "habitats": {
      "type": "array",
      "items": {
        "enum": [
          "land",
          "water",
          "both",
          "none"
        ]
      }
    },
    "resourceId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "forwardAxis": {
      "enum": [
        "+X",
        "-X",
        "+Y",
        "-Y",
        "+Z",
        "-Z"
      ]
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      }
    },
    "metersPerUnit": {
      "type": "number",
      "exclusiveMinimum": 0
    },
    "schemaVersion": {
      "const": 1
    },
    "licenseRecordId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "materialProfile": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "collisionProfile": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "configurationSchema": {
      "type": "object",
      "required": [
        "resourceId",
        "sha256"
      ],
      "properties": {
        "sha256": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        },
        "resourceId": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9_.:-]+$"
        }
      },
      "additionalProperties": false
    }
  },
  "description": "Every entry resolves to pinned approved resources and a typed configuration schema. Numeric parameters must be bounded in that schema. Collision geometry is authored for traversal, separate from decorative detail; rig joint/socket requirements are explicit in asset metadata. Unknown entries fail export.",
  "additionalProperties": false
}
```

### RECEIVES FROM: Curated Review & Release (cli-tool)
- **Contract:** Conformance Evidence v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "type": "object",
  "title": "Conformance Evidence v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "packageSha256",
    "validatorVersion",
    "profileId",
    "result",
    "checks",
    "evidencePaths"
  ],
  "properties": {
    "checks": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "checkId",
          "status",
          "path",
          "message"
        ],
        "properties": {
          "path": {
            "type": [
              "string",
              "null"
            ]
          },
          "status": {
            "enum": [
              "pass",
              "fail",
              "unrun"
            ],
            "type": "string"
          },
          "checkId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "message": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false
      }
    },
    "result": {
      "enum": [
        "pass",
        "fail",
        "unrun"
      ],
      "type": "string"
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "profileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "evidencePaths": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "packageSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    },
    "schemaVersion": {
      "const": 1
    },
    "validatorVersion": {
      "type": "string",
      "minLength": 1
    }
  },
  "description": "Evidence binds exact immutable package bytes and validator/profile versions. Unrun never counts as pass. Diagnostics identify offending paths/fields; static checks do not prove real-player traversal or art quality. Human sign-offs are separate.",
  "additionalProperties": false
}
```

### RECEIVES FROM: Quality Evidence & Migration Gates (cli-tool)
- **Contract:** Conformance Evidence v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "type": "object",
  "title": "Conformance Evidence v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "packageSha256",
    "validatorVersion",
    "profileId",
    "result",
    "checks",
    "evidencePaths"
  ],
  "properties": {
    "checks": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "checkId",
          "status",
          "path",
          "message"
        ],
        "properties": {
          "path": {
            "type": [
              "string",
              "null"
            ]
          },
          "status": {
            "enum": [
              "pass",
              "fail",
              "unrun"
            ],
            "type": "string"
          },
          "checkId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "message": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false
      }
    },
    "result": {
      "enum": [
        "pass",
        "fail",
        "unrun"
      ],
      "type": "string"
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "profileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "evidencePaths": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "packageSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    },
    "schemaVersion": {
      "const": 1
    },
    "validatorVersion": {
      "type": "string",
      "minLength": 1
    }
  },
  "description": "Evidence binds exact immutable package bytes and validator/profile versions. Unrun never counts as pass. Diagnostics identify offending paths/fields; static checks do not prove real-player traversal or art quality. Human sign-offs are separate.",
  "additionalProperties": false
}
```

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Versioned World Runtime API (this node calls/depends on it via Declarative World Definition v1 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Approved Kit Entry v1 (dependency))

**Depends on THIS node being available:**
- Family Workshop & Starter (initiates Data-only Level Package Manifest v1 against this node (dependency))
- Curated Review & Release (initiates Conformance Evidence v1 against this node (dependency))
- Quality Evidence & Migration Gates (initiates Conformance Evidence v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `tools/asset_fixtures.py` | source | --- | draft |
| `fixtures/worlds/unsupported_version/world.tscn` | design | --- | draft |
| `tools/level_contract_checker.py` | source | --- | draft |
| `fixtures/worlds/bad_world_id/world.tscn` | design | --- | draft |
| `fixtures/worlds/malformed_manifest/world.tscn` | design | --- | draft |
| `tools/oax_test.py` | source | --- | draft |
| `contracts/engine_feature_policy.v1.json` | schema | --- | draft |
| `tools/scene_fixtures.py` | source | --- | draft |
| `fixtures/worlds/stray_project_file/world.tscn` | design | --- | draft |
| `contracts/provenance.schema.json` | schema | --- | draft |
| `fixtures/worlds/unsanctioned_tuning/world.tscn` | design | --- | draft |
| `tools/gdscript_scan.py` | source | --- | draft |
| `fixtures/.gdignore` | config | --- | draft |
| `fixtures/worlds/two_spawn_points/world.tscn` | design | --- | draft |
| `fixtures/worlds/stray_project_file/project.godot` | config | --- | draft |
| `fixtures/worlds/conforming_world/world.json` | config | --- | draft |
| `tools/static_gate.py` | source | --- | draft |
| `fixtures/worlds/unsanctioned_tuning/world.json` | config | --- | draft |
| `fixtures/worlds/two_spawn_points/world.json` | config | --- | draft |
| `fixtures/worlds/conforming_world/world.tscn` | design | --- | draft |
| `tools/test_static_gate.py` | source | --- | draft |
| `fixtures/worlds/malformed_manifest/world.json` | config | --- | draft |
| `fixtures/worlds/stray_project_file/world.json` | config | --- | draft |
| `fixtures/worlds/missing_checkpoint/world.json` | config | --- | draft |
| `fixtures/staticgate/multiplayer_repo/core/net_player.gd` | source | --- | draft |
| `tools/test_level_contract_checker.py` | source | --- | draft |
| `fixtures/worlds/bad_world_id/world.json` | config | --- | draft |
| `fixtures/worlds/missing_checkpoint/world.tscn` | design | --- | draft |
| `fixtures/staticgate/multiplayer_repo/core/net_scene.tscn` | source | --- | draft |
| `fixtures/staticgate/multiplayer_repo/project.godot` | config | --- | draft |
| `fixtures/worlds/unsupported_version/world.json` | config | --- | draft |
| `tools/test_asset_contract_validator.py` | source | --- | draft |
| `tools/asset_contract_validator.py` | source | --- | draft |
| `fixtures/staticgate/malicious_world/worlds/rogue_world/rogue.gd` | source | --- | draft |
| `fixtures/staticgate/clean_repo/core/clean.gd` | source | --- | draft |
| `fixtures/staticgate/clean_repo/project.godot` | config | --- | draft |
| `docs/asset-contract.md` | doc | --- | draft |
| `contracts/asset_contract.v1.json` | schema | --- | draft |
