# Task: Adventure Catalog & Installation

> **Scope:** implement ONLY this node ("Adventure Catalog & Installation"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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

<!-- AI-AUTHORED SECTION: NodeSpec never writes prose here. Your text survives regeneration verbatim while the derived sections around it keep refreshing. -->
_Not yet authored._ **Consuming AI — author this section BEFORE building.** Working from this full packet plus the repository, record the project-specific context no catalog can know: how this node's technology composes with its neighbors in THIS project, the integration specifics behind each interface contract, configuration rationale, and your intended implementation approach. Replace this placeholder (keep the heading) either by editing this file in the repo and pushing — NodeSpec surfaces the edit as a change card for the user to accept — or via an update_artifact patch through propose_patches. If a REVIEW NEEDED line appears here later, the derived context changed after you wrote this: re-verify the section, then delete that line.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
- [ ] **T2 — Implement the integration with Curated Review & Release (python-backend) per Contract "Signed Catalog Release v1" (dependency).** <!-- t:d731ec28 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Progress, Recovery & Rewards (godot) per Contract "Progress Snapshot v1" (dependency).** <!-- t:dc8702b0 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface OpenAxolotl Game Shell consumes, per Contract "Installed Adventure State v1" (dependency).** <!-- t:78a30660 -->
  Record the endpoint/identifiers OpenAxolotl Game Shell needs in this node's config artifacts — coordinate with OpenAxolotl Game Shell.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement: "Only approved compatible non-withdrawn package versions appear as installable releases, with author credits and compatibility information." (REQ-014).** <!-- t:a237c0e5 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-014 "Only approved compatible non-withdrawn package versions appear as installable releases, with author credits and compatibility information." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) to Curated Review & Release (keyword signal only)
- [ ] **T6 — Implement: "Downloads are staged, verified against the approved release record and activated atomically; interruption, invalid content or failed verification preserves the previous working install." (REQ-014).** <!-- t:2d9aa792 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-014 "Downloads are staged, verified against the approved release record and activated atomically; interruption, invalid content or failed verification preserves the previous working install." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) to Curated Review & Release (keyword signal only)
- [ ] **T7 — Implement: "A missing or incompatible world shows an actionable unavailable state while the hub and other installed worlds remain playable." (REQ-014).** <!-- t:1941b28f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-014 "A missing or incompatible world shows an actionable unavailable state while the hub and other installed worlds remain playable." — possible coordination point: Contract "Installed Adventure State v1" (dependency) from OpenAxolotl Game Shell (keyword signal only)
- [ ] **T8 — Implement: "Official and previously installed supported content remains playable without a network connection or AI account." (REQ-014).** <!-- t:776cf03a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-014 "Official and previously installed supported content remains playable without a network connection or AI account." — possible coordination point: Contract "Installed Adventure State v1" (dependency) from OpenAxolotl Game Shell (keyword signal only)
- [ ] **T9 — Implement: "Install verification checks a release signature against the bundled trusted publisher key and the package digest before activation; unsupported keys, tampering or downgrade outside the compatibility policy preserve the prior installation." (REQ-014).** <!-- t:bb111113 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-014 "Install verification checks a release signature against the bundled trusted publisher key and the package digest before activation; unsupported keys, tampering or downgrade outside the compatibility policy preserve the prior installation." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) to Curated Review & Release (keyword signal only)
- [ ] **T10 — Implement: "Progress is isolated by stable world identity and save-schema version; one level cannot read or overwrite another level's save namespace." (REQ-015).** <!-- t:773fb9d1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Progress is isolated by stable world identity and save-schema version; one level cannot read or overwrite another level's save namespace." — possible coordination point: Contract "Progress Snapshot v1" (dependency) to Progress, Recovery & Rewards (keyword signal only)
- [ ] **T11 — Implement: "Updates declare compatibility/migration behavior; failed migrations retain the prior installation and recoverable save data." (REQ-015).** <!-- t:d4372c64 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Updates declare compatibility/migration behavior; failed migrations retain the prior installation and recoverable save data."
- [ ] **T12 — Implement: "Removing a level preserves progress by default; irreversible progress deletion requires an explicit separate player action." (REQ-015).** <!-- t:85dbabc9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Removing a level preserves progress by default; irreversible progress deletion requires an explicit separate player action." — possible coordination point: Contract "Progress Snapshot v1" (dependency) to Progress, Recovery & Rewards (keyword signal only)
- [ ] **T13 — Implement: "Withdrawn releases stop being offered for installation; rollback is offered only when both runtime and save-schema compatibility permit it." (REQ-015).** <!-- t:5b629178 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-015 "Withdrawn releases stop being offered for installation; rollback is offered only when both runtime and save-schema compatibility permit it." — possible coordination point: Contract "Signed Catalog Release v1" (dependency) to Curated Review & Release (keyword signal only)
- [ ] **T14 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
  Ordering doctrine — plans follow schemas (contract-first TDD): schemas → test plans → implement → verify. Resolve any open [PLACEHOLDER: schema] gap FIRST (get_build_readiness supplies draftInputs; submit the schema via propose_patches update_contract) — test-plan scenarios touching a schemaless contract stay one-line [blocked by schema: …] markers until the schema lands, then the plan refreshes itself.
  AUTOMATED criteria: call get_test_plan for EACH requirement this node serves, implement the plan's test cases, run them, and report every outcome via report_test_results — a passing result flips the criterion's met flag automatically and the response receipt shows which criteria flipped.
  MANUAL criteria (rows marked (manual) above): report_test_results REFUSES to bind them — prove each by ticking its criterion box in this task doc and having the user approve the resulting change card; that approval is the only thing that flips a manual criterion met.
  This node is complete only when every criterion box is ticked and no `[PLACEHOLDER: …]` tag remains open.

**Your first action — expand these work orders.** Each task above guarantees WHAT must be covered, not HOW. Before writing any code or configuration, expand every task with the concrete implementation steps for THIS technology in THIS project — the specific resources, settings, files, schemas, and tests — using the Configuration, Interface Contracts, Existing Implementation, Technology Guidance, and node context as your references. Write each work order's steps under its task line as indented checkbox lines (`  - [ ] <step>`), one action each, naming the file, setting or interface it changes, and send them with update_artifact (propose_patches, passing base_sequence) after this doc is accepted, keeping task IDs, criterion citations, and open `[PLACEHOLDER: …]` tags intact; the steps stay with their work order when this doc regenerates. Resolve placeholders with the user through the proposal flow; this node is never complete while one remains open. When the work orders are implemented, verify through the test lane: run get_test_plan for each requirement this node serves, implement and run the plan's tests, and report outcomes via report_test_results — passing results are the evidence that flips criteria met.

## Configuration

User-selected configuration for this component (honor these choices):
- **engine:** Godot 4.7 / GDScript 2.0
- **delivery:** Desktop first; tablet feasibility and consoles deferred.
- **gameplayBaseline:** 2464a14a40e2be6dbccab9d141ba3e0e783d3e45

## Vision This Node Serves

The sentences of the project vision that the outcomes behind this node's requirements cite:

- Reviewed community adventures become new destinations for everyone to explore.
- Submit a level for automated checks and human review; approved, versioned adventures can be downloaded and played through the hub.
- Approval identifies immutable package bytes; updates are reviewed again and withdrawn releases are removed from future distribution.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-014: Curated discovery and reliable package installation
Category: functional | Status: pending
The hub exposes official and approved community adventures. Failed or incompatible downloads must not damage the game or existing installs.

**Acceptance criteria — your task boxes:**
- [ ] Only approved compatible non-withdrawn package versions appear as installable releases, with author credits and compatibility information.
  → covered by Task T5
- [ ] Downloads are staged, verified against the approved release record and activated atomically; interruption, invalid content or failed verification preserves the previous working install.
  → covered by Task T6
- [ ] A missing or incompatible world shows an actionable unavailable state while the hub and other installed worlds remain playable.
  → covered by Task T7
- [ ] Official and previously installed supported content remains playable without a network connection or AI account.
  → covered by Task T8
- [ ] Install verification checks a release signature against the bundled trusted publisher key and the package digest before activation; unsupported keys, tampering or downgrade outside the compatibility policy preserve the prior installation.
  → covered by Task T9

### REQ-015: Compatible updates, save migrations and withdrawal
Category: technical | Status: pending
Treat package versioning and saves as a lifecycle. Stable world identity survives releases; incompatible migrations are not attempted silently.

**Acceptance criteria — your task boxes:**
- [ ] Progress is isolated by stable world identity and save-schema version; one level cannot read or overwrite another level's save namespace.
  → covered by Task T10
- [ ] Updates declare compatibility/migration behavior; failed migrations retain the prior installation and recoverable save data.
  → covered by Task T11
- [ ] Removing a level preserves progress by default; irreversible progress deletion requires an explicit separate player action.
  → covered by Task T12
- [ ] Withdrawn releases stop being offered for installation; rollback is offered only when both runtime and save-schema compatibility permit it.
  → covered by Task T13

## Interface Contracts

### RECEIVES FROM: OpenAxolotl Game Shell (game-client)
- **Contract:** Installed Adventure State v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Installed Adventure State v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "activeVersion",
    "previousVersion",
    "state",
    "manifestDigest",
    "errorCode",
    "saveNamespace"
  ],
  "properties": {
    "state": {
      "enum": [
        "absent",
        "staging",
        "ready",
        "failed",
        "withdrawn"
      ],
      "type": "string"
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "errorCode": {
      "type": [
        "string",
        "null"
      ]
    },
    "activeVersion": {
      "type": [
        "string",
        "null"
      ]
    },
    "saveNamespace": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "schemaVersion": {
      "const": 1
    },
    "manifestDigest": {
      "type": [
        "string",
        "null"
      ]
    },
    "previousVersion": {
      "type": [
        "string",
        "null"
      ]
    }
  },
  "description": "Staging is isolated from active version. Only validated compatible packages become ready; activation is atomic and rollback preserves previous content and save backup. Offline or catalog failure does not prevent official/installed play. World content has no network capability.",
  "additionalProperties": false
}
```

### SENDS TO: Curated Review & Release (cli-tool)
- **Contract:** Signed Catalog Release v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

### SENDS TO: Progress, Recovery & Rewards (shared-library)
- **Contract:** Progress Snapshot v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Progress Snapshot v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "worldId",
    "worldVersion",
    "checkpointId",
    "collectedIds",
    "restoredIds",
    "completed",
    "danceUnlocked",
    "capabilities",
    "revision"
  ],
  "properties": {
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "revision": {
      "type": "integer",
      "minimum": 0
    },
    "completed": {
      "type": "boolean"
    },
    "restoredIds": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      }
    },
    "capabilities": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      }
    },
    "checkpointId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "collectedIds": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_.:-]+$"
      }
    },
    "worldVersion": {
      "type": "string",
      "minLength": 1
    },
    "danceUnlocked": {
      "type": "boolean"
    },
    "schemaVersion": {
      "const": 1
    }
  },
  "description": "Snapshot is namespaced by worldId, applied atomically after validation, and duplicate stable IDs are rejected. Migration copies original data before activation; capture/reset cancels transient actions. Precise existing life/capability rules must be inventoried before migration.",
  "additionalProperties": false
}
```

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Curated Review & Release (this node calls/depends on it via Signed Catalog Release v1 (dependency))
- Progress, Recovery & Rewards (this node calls/depends on it via Progress Snapshot v1 (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Shell (initiates Installed Adventure State v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `hub/portal_tier.gd.uid` | config | --- | draft |
| `test/hub/test_world_registry.gd.uid` | config | --- | draft |
| `test/hub/test_world_registry.gd` | source | --- | draft |
| `hub/world_registry.gd.uid` | config | --- | draft |
| `hub/portal_tier.gd` | source | --- | draft |
| `hub/world_portal.gd.uid` | config | --- | draft |
| `hub/world_portal.gd` | source | --- | draft |
| `hub/world_registry.gd` | source | --- | draft |
