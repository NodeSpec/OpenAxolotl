# Task: Curated Review & Release

> **Scope:** implement ONLY this node ("Curated Review & Release"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Implement the integration with Content Export & Conformance (python-backend) per Contract "Conformance Evidence v1" (dependency).** <!-- t:20a5bfbb -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface Adventure Catalog & Installation consumes, per Contract "Signed Catalog Release v1" (dependency).** <!-- t:f2e86f67 -->
  Record the endpoint/identifiers Adventure Catalog & Installation needs in this node's config artifacts — coordinate with Adventure Catalog & Installation.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement: "The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution." (REQ-016).** <!-- t:99caf038 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution." — possible coordination point: Contract "Conformance Evidence v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T5 — Implement: "Review and publish the code license, asset reuse terms, generator/third-party obligations and contributor permissions before inviting public reuse or submissions." (REQ-016).** <!-- t:24e63f0e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Review and publish the code license, asset reuse terms, generator/third-party obligations and contributor permissions before inviting public reuse or submissions."
- [ ] **T6 — Implement: "Each published package retains its credited asset manifest and required attribution through installation and updates." (REQ-016).** <!-- t:8a7c604e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Each published package retains its credited asset manifest and required attribution through installation and updates." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) from Adventure Catalog & Installation (keyword signal only)
- [ ] **T7 — Implement: "Publication is blocked until required automated checks and recorded human approvals are present for the exact package digest and version." (REQ-013).** <!-- t:8205f641 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Publication is blocked until required automated checks and recorded human approvals are present for the exact package digest and version."
- [ ] **T8 — Implement: "The review checklist covers playability, recovery, clarity, content suitability, accessibility, asset rights and measured performance on the declared hardware tier." (REQ-013).** <!-- t:cd703194 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "The review checklist covers playability, recovery, clarity, content suitability, accessibility, asset rights and measured performance on the declared hardware tier." — possible coordination point: Contract "Conformance Evidence v1" (dependency) to Content Export & Conformance (keyword signal only)
- [ ] **T9 — Implement: "Changing submitted bytes invalidates approval and requires a new version/review; a rejected candidate remains unavailable to the public catalog." (REQ-013).** <!-- t:5fe34be9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Changing submitted bytes invalidates approval and requires a new version/review; a rejected candidate remains unavailable to the public catalog." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) from Adventure Catalog & Installation (keyword signal only)
- [ ] **T10 — Implement: "Credits, contributor permissions and parent-led submission instructions are understandable before submission." (REQ-013).** <!-- t:6f2bfd24 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Credits, contributor permissions and parent-led submission instructions are understandable before submission."
- [ ] **T11 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- Reviewed community adventures become new destinations for everyone to explore.
- With a parent, remix a small playable starter using the shared asset/gameplay kit, Codex and NodeSpec, previewing and iterating in Godot.
- Establish code licensing, asset remix/redistribution rights, provenance, credits and contributor permissions before inviting public reuse.
- Publish only packages that pass conformance checks, human play/content review and measured device budgets.
- Approval identifies immutable package bytes; updates are reviewed again and withdrawn releases are removed from future distribution.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-016: Explicit code, asset and contributor rights
Category: business | Status: pending
The open-source promise distinguishes source-code licensing from permissions for models, textures, music and submitted levels. Externally generated assets need reviewed provenance and redistribution/remix rights.

**Acceptance criteria — your task boxes:**
- [ ] The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution.
  → covered by Task T4
- [ ] Review and publish the code license, asset reuse terms, generator/third-party obligations and contributor permissions before inviting public reuse or submissions. (manual)
  → covered by Task T5
- [ ] Each published package retains its credited asset manifest and required attribution through installation and updates.
  → covered by Task T6

### REQ-013: Human review before community publication
Category: functional | Status: pending
A curated family-facing library requires both automated validation and human review of the exact submitted version. Contributors receive actionable feedback.

**Acceptance criteria — your task boxes:**
- [ ] Publication is blocked until required automated checks and recorded human approvals are present for the exact package digest and version.
  → covered by Task T7
- [ ] The review checklist covers playability, recovery, clarity, content suitability, accessibility, asset rights and measured performance on the declared hardware tier. (manual)
  → covered by Task T8
- [ ] Changing submitted bytes invalidates approval and requires a new version/review; a rejected candidate remains unavailable to the public catalog.
  → covered by Task T9
- [ ] Credits, contributor permissions and parent-led submission instructions are understandable before submission. (manual)
  → covered by Task T10

## Interface Contracts

### SENDS TO: Content Export & Conformance (cli-tool)
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

### RECEIVES FROM: Adventure Catalog & Installation (shared-library)
- **Contract:** Signed Catalog Release v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Signed Catalog Release v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "version",
    "packageUrl",
    "packageSha256",
    "bytes",
    "worldApiVersion",
    "minimumGameVersion",
    "reviewId",
    "rightsRecordId",
    "status",
    "keyId",
    "signature"
  ],
  "properties": {
    "bytes": {
      "type": "integer",
      "minimum": 0
    },
    "keyId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "status": {
      "enum": [
        "published",
        "withdrawn"
      ],
      "type": "string"
    },
    "version": {
      "type": "string",
      "minLength": 1
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "reviewId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "signature": {
      "type": "string",
      "minLength": 1
    },
    "packageUrl": {
      "type": "string",
      "minLength": 1
    },
    "packageSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    },
    "schemaVersion": {
      "const": 1
    },
    "rightsRecordId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "worldApiVersion": {
      "const": "1"
    },
    "minimumGameVersion": {
      "type": "string",
      "minLength": 1
    }
  },
  "description": "Maintainer approves immutable bytes after play, content, rights and performance review. Sign a canonical versioned payload with a trusted publisher key; algorithm/key rotation/encoding specification must be settled in implementation design before networking. Runtime verifies signature and digest before activation; package changes invalidate approval. No arbitrary remote code execution.",
  "additionalProperties": false
}
```

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Content Export & Conformance (this node calls/depends on it via Conformance Evidence v1 (dependency))

**Depends on THIS node being available:**
- Adventure Catalog & Installation (initiates Signed Catalog Release v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `LICENSE` | doc | --- | draft |
| `docs/branch-protection.md` | doc | --- | draft |
