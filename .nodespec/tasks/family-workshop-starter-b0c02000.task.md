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

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

Use worlds/reference_template, the retained Bubble Bay example, docs/world-authoring.md and starter probes as inputs to a parent-led creation workflow. A complete standalone game precedes creation. Provide a playable bounded starter using the same public API and approved kit as official levels. Measure setup separately from the 15–30 minute first-remix goal; compare AI-assisted and direct Godot edits honestly. Parent-facing instructions distinguish local experiments, supported data-only downloads and separately reviewed executable core changes. A clean Git clone must fetch LFS assets and the pinned toolchain. Do not treat archived examples or public reference uploads as approved redistributable starter assets.

This document describes planned work. All completion boxes remain open until current evidence or recorded human approval is attached. Keep the existing task keys and criterion identities. Shared payload schemas are normative even where generic dependency guidance describes only wiring.

Curation integration: parent-operated private creation for ages 5–9 remains optional. Document separate local-preview, asset/character review, complete-level review and executable-core-contribution routes. The supported guided Codex/NodeSpec path shares documented formats/validators with other capable AI tools and direct Godot; playing requires no AI account or child profile.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
  - [ ] Inventory the current bound implementation including `worlds/reference_template/world.tscn`, `test/worlds/run_template_walk.gd`, `test/worlds/template_walk_probe.gd`, `tools/test_reference_template.py`; record each retained component, migration gap and owning dependency before changing files.
  - [ ] Use the existing repository/project and test harness; adapt the current component in place rather than creating a parallel scaffold.
  - [ ] Pin supported Godot/Python toolchain versions and document setup/recovery.
  - [ ] Record a baseline fixture and observable behavior for this component at the pinned gameplay commit; keep historical results separate from fresh proof.
- [ ] **T2 — Implement the integration with Content Export & Conformance (python-backend) per Contract "Data-only Level Package Manifest v2" (dependency).** <!-- t:8114da52 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Compile the starter's supported content into Data-only Level Package Manifest v2 with the complete pinned dependency closure; define canonical dependency hashing identically in Python and Godot.
  - [ ] Reject missing, conflicting, cyclic, floating and changed dependency pins; require a separate playable-level review for official publication while retaining private preview.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Approved Kit Entry v2" (dependency).** <!-- t:4c52ade0 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Resolve immutable Approved Kit Entry v2 identities, versions, content hashes and dependency manifests; add an explicit migration/rejection path for v1 rather than silently accepting it as approved.
  - [ ] Use fixtures for approved, missing, wrong-scope, changed and withdrawn entries; retain existing collision/rig/material behavior and make incompatibility actionable at the consumer boundary.
- [ ] **T4 — Implement: "The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels." (REQ-010).** <!-- t:3e257213 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels." — possible coordination point: Contract "Data-only Level Package Manifest v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using a fresh parent/newcomer setup and bounded starter remix through preview, validation, export and actual play as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T5 — Implement: "A documented first remix changes one bounded part of the starter and passes conformance without editing core systems." (REQ-010).** <!-- t:433ed3f9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A documented first remix changes one bounded part of the starter and passes conformance without editing core systems." — possible coordination point: Contract "Data-only Level Package Manifest v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using a fresh parent/newcomer setup and bounded starter remix through preview, validation, export and actual play as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T6 — Implement: "A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly." (REQ-010).** <!-- t:d5cf0d46 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly." — possible coordination point: Contract "Data-only Level Package Manifest v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Prepare a repeatable human-review setup for a fresh parent/newcomer setup and bounded starter remix through preview, validation, export and actual play; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T7 — Implement: "Parent-facing instructions distinguish private local experimentation, reusable asset/character submissions, playable-level submissions and executable core contributions. They explain the parent's operator role, that submission does not guarantee publication, and that no child account or public profile is required; an observed family walkthrough confirms this is understandable." (REQ-010).** <!-- t:2bf8c193 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "Parent-facing instructions distinguish private local experimentation, reusable asset/character submissions, playable-level submissions and executable core contributions. They explain the parent's operator role, that submission does not guarantee publication, and that no child account or public profile is required; an observed family walkthrough confirms this is understandable." — possible coordination point: Contract "Approved Kit Entry v2" (dependency) to Reusable Level & Asset Kit (keyword signal only)
  - [ ] Update the parent-facing starter guide with the four contribution routes, parent/operator responsibilities, private preview and optional alias-based submission; retain the direct-Godot path.
  - [ ] Prepare the following binding scenario: Given the parent-facing starter instructions and a parent/child pair aged 5–9, when the parent walks through a private remix and explains the optional asset, character, level and core-code submission routes, then record whether they correctly distinguish preview from publication, can proceed without a child account/public profile, and understand that official inclusion requires owner review.
  - [ ] Prepare the review fixture and capture the human decision; do not mark the criterion met until the user confirms it.
- [ ] **T8 — Implement: "A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes." (REQ-010).** <!-- t:74cbe57f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-010 "A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes." — possible coordination point: Contract "Data-only Level Package Manifest v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Prepare a repeatable human-review setup for a fresh parent/newcomer setup and bounded starter remix through preview, validation, export and actual play; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T9 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.
  - [ ] Run the component's current automated binding scenarios at the pushed implementation commit and report each result against its exact criterion; leave skipped/stale checks open.
  - [ ] Collect the required human review and its evidence separately; do not auto-tick manual criteria or equate a headless pass with visual quality.
  - [ ] Check every work-order step, dependency contract and remaining migration gap before declaring completion; hand off unresolved items with owner and reproduction.

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
- Families with children aged 5–9 create privately with a parent as the tool/account operator, and submit voluntarily through the parent-facing workflow.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-010: A small, approachable family level-creation workflow
Category: functional | Status: pending
Parents and children aged 5–9 privately remix a small complete example, with the parent operating accounts and AI tools. Codex/NodeSpec is a guided path; documented formats and validators also support other capable AI tools and direct Godot editing. Creation and submission are optional and separate from ordinary play.

**Acceptance criteria — your task boxes:**
- [ ] The starter plays from spawn to finish and demonstrates land, water, one enemy, checkpoint, collectible and one restoration or supported ability gate through the same public interfaces as official levels.
  → covered by Task T4
- [ ] A documented first remix changes one bounded part of the starter and passes conformance without editing core systems.
  → covered by Task T5
- [ ] A newcomer test covers setup, describing an idea, editing, previewing, checking and exporting; the 15–30 minute first-remix goal is measured after setup and reported honestly. (manual)
  → covered by Task T6
- [ ] Parent-facing instructions distinguish private local experimentation, reusable asset/character submissions, playable-level submissions and executable core contributions. They explain the parent's operator role, that submission does not guarantee publication, and that no child account or public profile is required; an observed family walkthrough confirms this is understandable. (manual)
  → covered by Task T7
- [ ] A family trial starts from a clean pinned-toolchain setup and records time, errors and assistance for a bounded AI-assisted remix and an equivalent direct-Godot edit; export and playtest must succeed without core changes. (manual)
  → covered by Task T8

## Interface Contracts

### SENDS TO: Content Export & Conformance (cli-tool)
- **Contract:** Data-only Level Package Manifest v2
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "type": "object",
  "title": "Data-only Level Package Manifest v2",
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
    "validationProfileId",
    "dependencies",
    "dependencyManifestSha256"
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
    "dependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "entryId",
          "version",
          "contentSha256"
        ],
        "properties": {
          "entryId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "version": {
            "type": "string",
            "minLength": 1
          },
          "contentSha256": {
            "type": "string",
            "pattern": "^[a-f0-9]{64}$"
          }
        },
        "additionalProperties": false
      },
      "uniqueItems": true
    },
    "schemaVersion": {
      "const": 2
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
    },
    "dependencyManifestSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  },
  "description": "Published package permits only validated data and explicitly approved resource encodings; executable scripts and scene-attached code are forbidden. Paths must be relative normalized non-symlink paths without traversal; declared and extracted sizes obey a versioned limit profile. Authoring scripts may be used only locally to produce validated data. Raw Godot PCK import is not the published-content security boundary. dependencies pins every transitive kit resource used by the definition to an exact entry/version/digest; reject conflicting versions, duplicate entryIds, missing pins or cycles. dependencyManifestSha256 hashes the documented canonical sorted dependency array. Resolve definition kitEntryIds only through this manifest and the declared kitVersion; no floating latest references. Official release requires separate playable_level approval even when every dependency is approved. Private preview is not a publication approval. v1 packages require an explicit conversion and fresh review.",
  "additionalProperties": false
}
```

### SENDS TO: Reusable Level & Asset Kit (shared-library)
- **Contract:** Approved Kit Entry v2
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Approved Kit Entry v2",
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
    "forwardAxis",
    "contentSha256",
    "reviewId",
    "dependencyManifestSha256"
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
    "reviewId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
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
        "type": "object",
        "required": [
          "entryId",
          "version",
          "contentSha256"
        ],
        "properties": {
          "entryId": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_.:-]+$"
          },
          "version": {
            "type": "string",
            "minLength": 1
          },
          "contentSha256": {
            "type": "string",
            "pattern": "^[a-f0-9]{64}$"
          }
        },
        "additionalProperties": false
      },
      "uniqueItems": true
    },
    "contentSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    },
    "metersPerUnit": {
      "type": "number",
      "exclusiveMinimum": 0
    },
    "schemaVersion": {
      "const": 2
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
    },
    "dependencyManifestSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  },
  "description": "Every entry resolves to pinned approved resources and a typed configuration schema. Numeric parameters must be bounded in that schema. Collision geometry is authored for traversal, separate from decorative detail; rig joint/socket requirements are explicit in asset metadata. Unknown entries fail export. Official kit publication requires a matching approved Contribution Review Decision v1 with reusable_asset scope, subjectKind asset or character, matching identity/version/content digest and dependency-manifest digest, and current owner authorization. dependencies pins exact versions/digests; stable IDs alone are insufficient. The content digest covers the complete resource manifest and reviewed public metadata, excluding the approval receipt itself to avoid a circular hash. Kit approval never approves an assembled level. This is a v2 target contract; v1 input is not silently treated as approved.",
  "additionalProperties": false
}
```

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Content Export & Conformance (this node calls/depends on it via Data-only Level Package Manifest v2 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Approved Kit Entry v2 (dependency))

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
| `.nodespec/tests/req-010.tests.md` - Test plan for requirement: A small, approachable family level-creation workflow | test-plan | markdown | draft |
| `README.md` | doc | --- | draft |
| `worlds/bubble_bay/world.tscn` | source | --- | draft |
| `worlds/bubble_bay/README.md` | doc | --- | draft |
| `docs/world-authoring.md` | doc | --- | draft |
