# Task: Family Workshop & Starter

> **Scope:** implement ONLY this node ("Family Workshop & Starter"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Implement the integration with Content Export & Conformance (python-backend) per Contract "Data-only Level Package Manifest v1" (dependency).** <!-- t:ff704c25 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Approved Kit Entry v1" (dependency).** <!-- t:8692c42f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement: "The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels." (REQ-010).** <!-- t:3e257213 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T5 — Implement: "A documented first remix changes one bounded part of the starter and passes conformance without editing core systems." (REQ-010).** <!-- t:433ed3f9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A documented first remix changes one bounded part of the starter and passes conformance without editing core systems." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T6 — Implement: "A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly." (REQ-010).** <!-- t:d5cf0d46 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T7 — Implement: "Parent-facing instructions clearly distinguish local experimentation, supported downloadable content and executable core contributions." (REQ-010).** <!-- t:e070de01 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "Parent-facing instructions clearly distinguish local experimentation, supported downloadable content and executable core contributions." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T8 — Implement: "A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes." (REQ-010).** <!-- t:74cbe57f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes." — possible coordination point: Contract "Data-only Level Package Manifest v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T9 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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
- Direct Godot editing remains supported.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-010: A small, approachable family level-creation workflow
Category: functional | Status: pending
Parents and children can remix a small complete example through Codex and NodeSpec or direct Godot editing. AI is optional for playing and the direct editor path remains supported.

**Acceptance criteria — your task boxes:**
- [ ] The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels.
  → covered by Task T4
- [ ] A documented first remix changes one bounded part of the starter and passes conformance without editing core systems.
  → covered by Task T5
- [ ] A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly. (manual)
  → covered by Task T6
- [ ] Parent-facing instructions clearly distinguish local experimentation, supported downloadable content and executable core contributions. (manual)
  → covered by Task T7
- [ ] A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes. (manual)
  → covered by Task T8

## Interface Contracts

### SENDS TO: Content Export & Conformance (cli-tool)
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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Content Export & Conformance (this node calls/depends on it via Data-only Level Package Manifest v1 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Approved Kit Entry v1 (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `test/worlds/run_bubble_walk.gd.uid` | config | --- | draft |
| `test/worlds/bubble_walk_probe.gd.uid` | config | --- | draft |
| `worlds/reference_template/world.json` | config | --- | draft |
| `test/worlds/run_template_walk.gd.uid` | config | --- | draft |
| `worlds/reference_template/world.tscn` | source | --- | draft |
| `worlds/reference_template/README.md` | doc | --- | draft |
| `test/worlds/template_walk_probe.gd.uid` | config | --- | draft |
| `test/worlds/run_template_walk.gd` | source | --- | draft |
| `test/worlds/template_walk_probe.gd` | source | --- | draft |
| `worlds/bubble_bay/world.json` | config | --- | draft |
| `tools/test_reference_template.py` | source | --- | draft |
| `test/worlds/run_bubble_walk.gd` | source | --- | draft |
| `test/worlds/bubble_walk_probe.gd` | source | --- | draft |
| `README.md` | doc | --- | draft |
| `worlds/bubble_bay/world.tscn` | source | --- | draft |
| `worlds/bubble_bay/README.md` | doc | --- | draft |
| `docs/world-authoring.md` | doc | --- | draft |
