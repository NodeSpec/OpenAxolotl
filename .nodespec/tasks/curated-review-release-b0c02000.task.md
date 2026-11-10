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

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

This is a target capability, not an implemented publication service merely because LICENSE and branch-policy files are bound here. Establish code/asset licensing and per-asset redistribution approval before public remix invitations. Bind every human approval and automated conformance result to the exact package digest/version; changing bytes invalidates approval. Curate suitability, credits, accessibility, recovery and declared-device performance. Sign an approved release record for the installation consumer; signing credentials remain outside game content. Keep executable mechanics on the separate core-contribution route and publish understandable parent-led submission rules.

This document describes planned work. All completion boxes remain open until current evidence or recorded human approval is attached. Keep the existing task keys and criterion identities. Shared payload schemas are normative even where generic dependency guidance describes only wiring.

Curation integration: own the private typed submission queue, reviewer/publisher authorization, auditable decisions and withdrawal impact. Produce Contribution Review Decision v1 for approved reusable assets/characters; produce Signed Catalog Release v2 only for a separately approved complete level. Review exact public metadata as well as content and dependencies. Owner delegation is explicit and revocable; passing checks, source-code availability and asset-only approval cannot bypass human approval. Review state and child personal details never enter the player catalog. New executable behavior follows core-code review.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
  - [ ] Inventory the current bound implementation; record each retained component, migration gap and owning dependency before changing files.
  - [ ] Use the existing repository/project and test harness; adapt the current component in place rather than creating a parallel scaffold.
  - [ ] Define submission and review records with immutable package digest/version and artifact evidence.
  - [ ] Record a baseline fixture and observable behavior for this component at the pinned gameplay commit; keep historical results separate from fresh proof.
- [ ] **T2 — Implement the integration with Content Export & Conformance (python-backend) per Contract "Conformance Evidence v2" (dependency).** <!-- t:1e26203c -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Dispatch validation by subjectKind asset, character or level and emit Conformance Evidence v2 tied to exact identity/version/snapshot/dependency digests.
  - [ ] Keep technical pass separate from human approval; exercise passing, failed and unrun checks plus evidence for a different subject/version.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Contribution Review Decision v1" (custom).** <!-- t:e26989ea -->
  Build to the contract schema EXACTLY (see Interface Contracts).
  - [ ] Produce the owner-authorized Contribution Review Decision v1 and submit it to the reusable kit ingestion boundary; verify declared scope, reviewer delegation, exact content/dependency digests, evidence and rights before approval.
  - [ ] Reject wrong-scope, changed-content and revoked-authority publication attempts; retain a private audit record and publish only reviewed metadata through the appropriate kit or adventure channel.
- [ ] **T4 — Expose the interface Adventure Catalog & Installation consumes, per Contract "Signed Catalog Release v2" (dependency).** <!-- t:5b76a738 -->
  Record the endpoint/identifiers Adventure Catalog & Installation needs in this node's config artifacts — coordinate with Adventure Catalog & Installation.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Require a current owner-authorized playable-level review and exact dependency digest before producing or accepting Signed Catalog Release v2; keep publisher credentials outside game content.
  - [ ] Test signature/digest verification and rejection of asset-only approvals, revoked authorization, withdrawn dependencies and changed metadata while preserving the previous install.
- [ ] **T5 — Implement: "The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution." (REQ-016).** <!-- t:99caf038 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution." — possible coordination point: Contract "Conformance Evidence v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using asset manifests with approved, missing and denied redistribution rights and required attribution as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T6 — Implement: "Review and publish the code license, asset reuse terms, generator/third-party obligations, contributor permissions and separate official branding/publication policy before inviting public reuse or submissions. Parent-facing terms explain that open-source reuse or a fork does not confer official approval, and public credit can use a parent-approved alias without publishing a child's personal details." (REQ-016).** <!-- t:215da80e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Review and publish the code license, asset reuse terms, generator/third-party obligations, contributor permissions and separate official branding/publication policy before inviting public reuse or submissions. Parent-facing terms explain that open-source reuse or a fork does not confer official approval, and public credit can use a parent-approved alias without publishing a child's personal details." — possible coordination point: Contract "Contribution Review Decision v1" (custom) to Reusable Level & Asset Kit (keyword signal only)
  - [ ] Update the rights/publication policy to distinguish code licensing, asset permissions, contributor consent and official branding; document parent-approved public aliases.
  - [ ] Prepare the following binding scenario: Given the published code, asset, contributor and branding policies and parent-facing submission instructions, when a human rights review and parent walkthrough compare reuse, independent forks and official inclusion, then record that applicable third-party obligations and permissions are explicit, official approval is not implied by open-source reuse, and public credit can use an alias without child personal details.
  - [ ] Prepare the review fixture and capture the human decision; do not mark the criterion met until the user confirms it.
- [ ] **T7 — Implement: "Each published package retains its credited asset manifest and required attribution through installation and updates." (REQ-016).** <!-- t:8a7c604e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-016 "Each published package retains its credited asset manifest and required attribution through installation and updates." — possible coordination point: Contract "Signed Catalog Release v2" (dependency) from Adventure Catalog & Installation (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using asset manifests with approved, missing and denied redistribution rights and required attribution as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T8 — Implement: "Official publication requires passing automated checks and recorded owner-authorized human approval for the exact submission type, identity, version, content digest and pinned dependencies. Contributors and automated agents cannot approve or publish their own submissions without explicit owner delegation; an asset/character reuse approval cannot authorize a playable level." (REQ-013).** <!-- t:e1f86860 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Official publication requires passing automated checks and recorded owner-authorized human approval for the exact submission type, identity, version, content digest and pinned dependencies. Contributors and automated agents cannot approve or publish their own submissions without explicit owner delegation; an asset/character reuse approval cannot authorize a playable level." — possible coordination point: Contract "Contribution Review Decision v1" (custom) to Reusable Level & Asset Kit (keyword signal only)
  - [ ] Implement the typed review state and authorization gate, with separate reusable_asset/playable_level scope, immutable approval snapshots and audited change/withdrawal decisions.
  - [ ] Prepare the following binding scenario: Given passing and failing evidence, asset-only and level approvals, matching and changed snapshots, and owner/delegate/contributor/automation identities, when Curated Review & Release attempts official publication, then it permits only a matching-scope exact-version approval recorded by an authorized human and a currently authorized publisher; missing evidence, wrong scope, revoked delegation and unauthorized self-publication are rejected.
  - [ ] Implement the publication/validation state transition and run the scenario through the public interface; report fresh evidence only after execution.
- [ ] **T9 — Implement: "Human review checks age appropriateness for children aged 5–9, cohesive art and gameplay, playability, recovery, clarity, accessibility, rights and measured performance on the declared hardware tier. Asset/character reviews include animation, materials, collision and supported behavior; level reviews play the complete route and its assembled content. Names, descriptions, thumbnails and audio are included." (REQ-013).** <!-- t:dceb5b30 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Human review checks age appropriateness for children aged 5–9, cohesive art and gameplay, playability, recovery, clarity, accessibility, rights and measured performance on the declared hardware tier. Asset/character reviews include animation, materials, collision and supported behavior; level reviews play the complete route and its assembled content. Names, descriptions, thumbnails and audio are included." — possible coordination point: Contract "Contribution Review Decision v1" (custom) to Reusable Level & Asset Kit (keyword signal only)
  - [ ] Create separate asset/character and complete-level human review checklists, including all public metadata, age-5–9 suitability, art, behavior, rights, accessibility and measured performance.
  - [ ] Prepare the following binding scenario: Given one asset, one character and one complete adventure with their names, descriptions, thumbnails and audio, when an authorized human applies the age-5–9 suitability and quality checklist to each declared review scope, then record separate evidence for reusable-content checks versus the complete level playthrough, rights, accessibility and measured hardware performance; leave approval open on any unresolved failure.
  - [ ] Prepare the review fixture and capture the human decision; do not mark the criterion met until the user confirms it.
- [ ] **T10 — Implement: "Changing submitted content, public-facing metadata or pinned dependencies invalidates the applicable approval and requires a new version/review. Draft, changes-requested and rejected submissions are excluded from public catalogs; review decisions record reviewer identity, scope, reason and time, and only authorized owners/delegates may change release status." (REQ-013).** <!-- t:2a43bb0d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Changing submitted content, public-facing metadata or pinned dependencies invalidates the applicable approval and requires a new version/review. Draft, changes-requested and rejected submissions are excluded from public catalogs; review decisions record reviewer identity, scope, reason and time, and only authorized owners/delegates may change release status." — possible coordination point: Contract "Conformance Evidence v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Implement the typed review state and authorization gate, with separate reusable_asset/playable_level scope, immutable approval snapshots and audited change/withdrawal decisions.
  - [ ] Prepare the following binding scenario: Given an approved immutable submission snapshot and review audit record, when content, public metadata or a pinned dependency changes or an unauthorized identity attempts a decision, then Curated Review & Release rejects approval reuse, requires a new version/review, keeps drafts and rejected candidates out of the official catalog and records authorized decisions with reviewer, scope, reason and time.
  - [ ] Implement the publication/validation state transition and run the scenario through the public interface; report fresh evidence only after execution.
- [ ] **T11 — Implement: "Credits, contributor permissions and parent-led submission instructions are understandable before submission." (REQ-013).** <!-- t:6f2bfd24 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-013 "Credits, contributor permissions and parent-led submission instructions are understandable before submission."
  - [ ] Prepare a repeatable human-review setup for a candidate package digest with complete approvals, missing approvals, rejection and modified bytes; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T12 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- Reviewed community adventures become new destinations for everyone to explore.
- With a parent, remix a small playable starter using the shared asset/gameplay kit, Codex and NodeSpec, previewing and iterating in Godot.
- Establish code licensing, asset remix/redistribution rights, provenance, credits and contributor permissions before inviting public reuse.
- Publish only packages that pass conformance checks, human play/content review and measured device budgets.
- Approval identifies immutable package bytes; updates are reviewed again and withdrawn releases are removed from future distribution.
- The project owner controls the official game, submission interface, approved asset and character library, adventure catalog and release decisions; review authority may be explicitly delegated and revoked, but contributors and automated tools cannot publish themselves.
- Open-source code may be forked under its license; that grants neither official publication nor use of official branding beyond separately documented permissions.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-016: Explicit code, asset and contributor rights
Category: business | Status: pending
Distinguish open-source code licensing, asset/model/texture/music/level redistribution and remix permissions, contributor consent and official branding. Independent forks remain possible under the code license; official inclusion and branding permission are separate owner-controlled decisions. Externally generated assets need reviewed provenance.

**Acceptance criteria — your task boxes:**
- [ ] The exportable asset catalog excludes assets lacking a recorded approved redistribution/remix status and required attribution.
  → covered by Task T5
- [ ] Review and publish the code license, asset reuse terms, generator/third-party obligations, contributor permissions and separate official branding/publication policy before inviting public reuse or submissions. Parent-facing terms explain that open-source reuse or a fork does not confer official approval, and public credit can use a parent-approved alias without publishing a child's personal details. (manual)
  → covered by Task T6
- [ ] Each published package retains its credited asset manifest and required attribution through installation and updates.
  → covered by Task T7

### REQ-013: Human review before community publication
Category: functional | Status: pending
The project owner controls official acceptance and release, with explicitly delegated and revocable reviewer/publisher roles. Private parent-led submissions enter a review queue by type (asset, character or playable level); automated checks and human review are both required. Reusable-content approval and complete-level approval are separate decisions, and contributors receive actionable feedback.

**Acceptance criteria — your task boxes:**
- [ ] Official publication requires passing automated checks and recorded owner-authorized human approval for the exact submission type, identity, version, content digest and pinned dependencies. Contributors and automated agents cannot approve or publish their own submissions without explicit owner delegation; an asset/character reuse approval cannot authorize a playable level.
  → covered by Task T8
- [ ] Human review checks age appropriateness for children aged 5–9, cohesive art and gameplay, playability, recovery, clarity, accessibility, rights and measured performance on the declared hardware tier. Asset/character reviews include animation, materials, collision and supported behavior; level reviews play the complete route and its assembled content. Names, descriptions, thumbnails and audio are included. (manual)
  → covered by Task T9
- [ ] Changing submitted content, public-facing metadata or pinned dependencies invalidates the applicable approval and requires a new version/review. Draft, changes-requested and rejected submissions are excluded from public catalogs; review decisions record reviewer identity, scope, reason and time, and only authorized owners/delegates may change release status.
  → covered by Task T10
- [ ] Credits, contributor permissions and parent-led submission instructions are understandable before submission. (manual)
  → covered by Task T11

## Interface Contracts

### SENDS TO: Content Export & Conformance (cli-tool)
- **Contract:** Conformance Evidence v2
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

**Schema:**
```
{
  "type": "object",
  "title": "Conformance Evidence v2",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "packageSha256",
    "validatorVersion",
    "profileId",
    "result",
    "checks",
    "evidencePaths",
    "subjectKind",
    "subjectId",
    "subjectVersion",
    "dependencyManifestSha256"
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
    "profileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "subjectId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "subjectKind": {
      "enum": [
        "asset",
        "character",
        "level"
      ]
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
      "const": 2
    },
    "subjectVersion": {
      "type": "string",
      "minLength": 1
    },
    "validatorVersion": {
      "type": "string",
      "minLength": 1
    },
    "dependencyManifestSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  },
  "description": "Evidence binds exact immutable package bytes and validator/profile versions. Unrun never counts as pass. Diagnostics identify offending paths/fields; static checks do not prove real-player traversal or art quality. Human sign-offs are separate. v2 identifies asset, character or level subjects explicitly (subjectId is worldId for a level). packageSha256 hashes the reviewed submission snapshot including public metadata. Select the validation profile by subjectKind; a level additionally needs complete-route checks, while an asset/character needs material, rig, collision and resource-budget checks. This report cannot grant approval or publication.",
  "additionalProperties": false
}
```

### RECEIVES FROM: Adventure Catalog & Installation (shared-library)
- **Contract:** Signed Catalog Release v2
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Signed Catalog Release v2",
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
    "signature",
    "approvalScope",
    "dependencyManifestSha256"
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
    "approvalScope": {
      "const": "playable_level"
    },
    "packageSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    },
    "schemaVersion": {
      "const": 2
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
    },
    "dependencyManifestSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  },
  "description": "Maintainer approves immutable bytes after play, content, rights and performance review. Sign a canonical versioned payload with a trusted publisher key; algorithm/key rotation/encoding specification must be settled in implementation design before networking. Runtime verifies signature and digest before activation; package changes invalidate approval. No arbitrary remote code execution. Only the owner or an explicitly delegated publisher may sign the official release after validating current reviewer authorization and a playable_level decision matching worldId/version/packageSha256/dependencyManifestSha256. A reusable_asset approval never authorizes this record. Reviewed public metadata must match the approved submission snapshot. Reject withdrawn approval/dependencies at publication and distribution; offline installed content follows the documented preservation policy. v2 signs all declared fields except signature using the separately specified canonical encoding.",
  "additionalProperties": false
}
```

### SENDS TO: Reusable Level & Asset Kit (shared-library)
- **Contract:** Contribution Review Decision v1
- **Protocol:** custom
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "allOf": [
    {
      "if": {
        "properties": {
          "subjectKind": {
            "const": "level"
          }
        }
      },
      "else": {
        "properties": {
          "scope": {
            "const": "reusable_asset"
          }
        }
      },
      "then": {
        "properties": {
          "scope": {
            "const": "playable_level"
          }
        }
      }
    }
  ],
  "title": "Contribution Review Decision v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "reviewId",
    "subjectKind",
    "subjectId",
    "subjectVersion",
    "contentSha256",
    "dependencyManifestSha256",
    "scope",
    "status",
    "reviewerId",
    "authorityRecordId",
    "decidedAt",
    "reason",
    "evidenceIds",
    "rightsRecordId"
  ],
  "properties": {
    "scope": {
      "enum": [
        "reusable_asset",
        "playable_level"
      ]
    },
    "reason": {
      "type": "string",
      "minLength": 1
    },
    "status": {
      "enum": [
        "approved",
        "changes_requested",
        "rejected",
        "withdrawn"
      ]
    },
    "reviewId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "decidedAt": {
      "type": "string",
      "format": "date-time"
    },
    "subjectId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "reviewerId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "evidenceIds": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "subjectKind": {
      "enum": [
        "asset",
        "character",
        "level"
      ]
    },
    "contentSha256": {
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
    "subjectVersion": {
      "type": "string",
      "minLength": 1
    },
    "authorityRecordId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "dependencyManifestSha256": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  },
  "description": "Owner-controlled audit receipt. Validate reviewerId against the owner/delegation authority record and its permitted scope at decision/publication time; strings asserting authority are not trusted proof. Approval requires passing conformance for the same immutable snapshot plus recorded human content/play/rights/performance review. Content includes reviewed public metadata and an immutable resource manifest; dependencyManifestSha256 uses the same canonical sorted pins as the package. Receipts are private review records; public releases expose only approved metadata and references, not child personal details or review discussion. Changed content/dependencies need a new review. Withdrawal records a new audited decision and enumerates dependent releases. This contract specifies planned behavior, not an implemented moderation service.",
  "additionalProperties": false
}
```

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Content Export & Conformance (this node calls/depends on it via Conformance Evidence v2 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Contribution Review Decision v1 (custom))

**Depends on THIS node being available:**
- Adventure Catalog & Installation (initiates Signed Catalog Release v2 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `LICENSE` | doc | --- | draft |
| `.nodespec/tests/req-013.tests.md` - Test plan for requirement: Human review before community publication | test-plan | markdown | draft |
| `docs/branch-protection.md` | doc | --- | draft |
| `.nodespec/tests/req-016.tests.md` - Test plan for requirement: Explicit code, asset and contributor rights | test-plan | markdown | draft |
