# Task: Quality Evidence & Migration Gates

> **Scope:** implement ONLY this node ("Quality Evidence & Migration Gates"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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

Treat the refined NodeSpec vision/requirements as target authority and Git gameplay snapshot 2464a14 (storage correction da401e2) as existing implementation authority. Export current NodeSpec anchors before any repository model import can restore the old 25-node/36-requirement model. Record source ownership, defects, production input tapes and rendered captures before implementation. Resolve the known toolchain mismatch: project.godot declares 4.7 while scripts/setup.sh pins 4.3-stable; choose the actual supported version and align CI/editor/export templates before accepting evidence. Require fresh clean-clone LFS/import evidence. Gate hero/camera reel, representative section, official route and family-remix trial separately. Desktop performance needs named hardware/preset and recorded memory/load/frame-time budgets; tablet remains a separate measured feasibility decision. No historical test ticks or asset bindings count as proof.

This document describes planned work. All completion boxes remain open until current evidence or recorded human approval is attached. Keep the existing task keys and criterion identities. Shared payload schemas are normative even where generic dependency guidance describes only wiring.

### Current tooling diagnostics

As of 2026-10-26, NodeSpec get_project_status and get_build_readiness return internal errors for this project. Do not interpret that as passing readiness. Cross-check the actual architecture, mapped requirements, stored tasks and work graph; the expected plan has 187 work orders and 117 criterion checks. The native REQ-005 generator also failed, so its five approved scenarios were restored explicitly without marking evidence complete. Repository export and actual Godot toolchain alignment remain distinct follow-up work; no NodeSpec metadata edit proves those repository changes occurred.

Curation integration: verify the v2 package/evidence/release boundaries with the same one-binding-scenario-per-criterion budget. Keep human age-suitability, design and performance review distinct from automated conformance. Record approved scope and exact dependency bytes in fixtures; historical captures are not new evidence.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Python component.** <!-- t:8265a1f5 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `src/main.py`, `src/routes/__init__.py`, `pyproject.toml`.
  - [ ] Inventory the current bound implementation including `tools/verify_cascade_basin_seals.gd`, `tools/water_review.gd`, `tools/tightened_lagoon_review.gd`, `tools/verify_enemy_motion.gd`; record each retained component, migration gap and owning dependency before changing files.
  - [ ] Use the existing repository/project and test harness; adapt the current component in place rather than creating a parallel scaffold.
  - [ ] Connect and reconcile the repository against this new specification before enabling anchor synchronization.
  - [ ] Pin the actual supported Godot editor/runtime/export-template version after resolving the documented 4.7 versus 4.3-stable mismatch; record clean-clone LFS and import verification before subsequent evidence.
- [ ] **T2 — Implement the integration with OpenAxolotl Game Shell (godot) per Contract "Quality Run Record v1" (dependency).** <!-- t:5af229f9 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Quality Run Record v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T3 — Implement the integration with Content Export & Conformance (python-backend) per Contract "Conformance Evidence v2" (dependency).** <!-- t:1e26203c -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Dispatch validation by subjectKind asset, character or level and emit Conformance Evidence v2 tied to exact identity/version/snapshot/dependency digests.
  - [ ] Keep technical pass separate from human approval; exercise passing, failed and unrun checks plus evidence for a different subject/version.
- [ ] **T4 — Implement: "Name the desktop baseline hardware and approve numerical frame-time, memory, load-time and restoration-hitch budgets before release performance sign-off." (REQ-017).** <!-- t:301b2c0e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Name the desktop baseline hardware and approve numerical frame-time, memory, load-time and restoration-hitch budgets before release performance sign-off."
  - [ ] Prepare a repeatable human-review setup for a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T5 — Implement: "A reproducible benchmark exercises the decorated first adventure with water, active enemies, debris and restoration and reports its measurements against the approved budgets." (REQ-017).** <!-- t:c3c83c42 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "A reproducible benchmark exercises the decorated first adventure with water, active enemies, debris and restoration and reports its measurements against the approved budgets."
  - [ ] Implement this criterion within the existing owned component and public contracts, using a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T6 — Implement: "A tablet release is not committed until touch controls, UI readability, memory, sustained thermal/frame-time behavior and distribution constraints are demonstrated on named devices." (REQ-017).** <!-- t:c99f94fc -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "A tablet release is not committed until touch controls, UI readability, memory, sustained thermal/frame-time behavior and distribution constraints are demonstrated on named devices."
  - [ ] Prepare a repeatable human-review setup for a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T7 — Implement: "Release notes distinguish tested platforms from experimental targets and do not equate a triangle ceiling with verified performance." (REQ-017).** <!-- t:02b05128 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Release notes distinguish tested platforms from experimental targets and do not equate a triangle ceiling with verified performance."
  - [ ] Prepare a repeatable human-review setup for a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T8 — Implement: "The initial desktop quality target is 60 FPS with p95 frame time at most 16.7 ms, p99 at most 33.3 ms and no steady-play frame above 50 ms over a five-minute rendered benchmark after a declared warm-up; world entry is measured separately against 3000 ms. Hardware, resolution, renderer, quality preset, memory budget and capture overhead must be recorded before this can pass." (REQ-017).** <!-- t:d4e22b9c -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "The initial desktop quality target is 60 FPS with p95 frame time at most 16.7 ms, p99 at most 33.3 ms and no steady-play frame above 50 ms over a five-minute rendered benchmark after a declared warm-up; world entry is measured separately against 3000 ms. Hardware, resolution, renderer, quality preset, memory budget and capture overhead must be recorded before this can pass." — possible coordination point: Contract "Quality Run Record v1" (dependency) to OpenAxolotl Game Shell (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T9 — Implement: "Approve the character reel, representative decorated section and family-remix trial as separate quality gates; failure creates named corrective work and cannot be waived by merely passing functional tests." (REQ-017).** <!-- t:844896f0 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-017 "Approve the character reel, representative decorated section and family-remix trial as separate quality gates; failure creates named corrective work and cannot be waived by merely passing functional tests."
  - [ ] Prepare a repeatable human-review setup for a warmed five-minute rendered desktop benchmark with water/enemies/debris/restoration and separately timed world entry on recorded hardware/settings; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T10 — Implement: "Before enabling sync or importing anchors, compare the repository's model/spec with this project and explicitly choose the authoritative documents; retain the old project as history." (REQ-018).** <!-- t:45b0b389 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Before enabling sync or importing anchors, compare the repository's model/spec with this project and explicitly choose the authoritative documents; retain the old project as history."
  - [ ] Prepare a repeatable human-review setup for current NodeSpec anchors against the pinned Git snapshot, a clean LFS checkout and separate records of implemented behavior, gaps and historical evidence; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T11 — Implement: "Repository files are mapped to their responsible nodes with traceable paths and commit references; generated anchors are not misbound as component source." (REQ-018).** <!-- t:3343c570 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Repository files are mapped to their responsible nodes with traceable paths and commit references; generated anchors are not misbound as component source."
  - [ ] Implement this criterion within the existing owned component and public contracts, using current NodeSpec anchors against the pinned Git snapshot, a clean LFS checkout and separate records of implemented behavior, gaps and historical evidence as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T12 — Implement: "Requirements remain unverified until fresh automated evidence or recorded manual approval is attached; old test ticks are not imported as current proof." (REQ-018).** <!-- t:a0ed4287 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Requirements remain unverified until fresh automated evidence or recorded manual approval is attached; old test ticks are not imported as current proof." — possible coordination point: Contract "Quality Run Record v1" (dependency) to OpenAxolotl Game Shell (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using current NodeSpec anchors against the pinned Git snapshot, a clean LFS checkout and separate records of implemented behavior, gaps and historical evidence as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T13 — Implement: "Track implementation gaps separately from desired behavior, including content export/loader, curated distribution, future suit powers, whirlpool and boss placement." (REQ-018).** <!-- t:4f3440ba -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Track implementation gaps separately from desired behavior, including content export/loader, curated distribution, future suit powers, whirlpool and boss placement." — possible coordination point: Contract "Conformance Evidence v2" (dependency) to Content Export & Conformance (keyword signal only)
  - [ ] Prepare a repeatable human-review setup for current NodeSpec anchors against the pinned Git snapshot, a clean LFS checkout and separate records of implemented behavior, gaps and historical evidence; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T14 — Implement: "Before code changes, record a source inventory, baseline input replays and rendered captures, open defects and migration ownership; existing historical test reports are reference material only." (REQ-018).** <!-- t:ade9dc50 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-018 "Before code changes, record a source inventory, baseline input replays and rendered captures, open defects and migration ownership; existing historical test reports are reference material only." — possible coordination point: Contract "Quality Run Record v1" (dependency) to OpenAxolotl Game Shell (keyword signal only)
  - [ ] Prepare a repeatable human-review setup for current NodeSpec anchors against the pinned Git snapshot, a clean LFS checkout and separate records of implemented behavior, gaps and historical evidence; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T15 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- Desktop is the first release target.
- Tablet play is a later feasibility milestone requiring measured performance, touch controls and readable UI on named devices; it is not promised by the current art quality.
- This new project records the agreed end state and the first-level reference.
- Existing implementation is context only: no requirement is considered verified until fresh evidence is attached after the repository is connected.
- Do not overwrite this specification with older repository anchors during connection.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-017: Desktop-first quality with a separate tablet decision
Category: non-functional | Status: pending
Ship a polished desktop experience first. Tablet play is a later feasibility decision; console certification and multiplayer are outside the current delivery scope.

**Acceptance criteria — your task boxes:**
- [ ] Name the desktop baseline hardware and approve numerical frame-time, memory, load-time and restoration-hitch budgets before release performance sign-off. (manual)
  → covered by Task T4
- [ ] A reproducible benchmark exercises the decorated first adventure with water, active enemies, debris and restoration and reports its measurements against the approved budgets.
  → covered by Task T5
- [ ] A tablet release is not committed until touch controls, UI readability, memory, sustained thermal/frame-time behavior and distribution constraints are demonstrated on named devices. (manual)
  → covered by Task T6
- [ ] Release notes distinguish tested platforms from experimental targets and do not equate a triangle ceiling with verified performance. (manual)
  → covered by Task T7
- [ ] The initial desktop quality target is 60 FPS with p95 frame time at most 16.7 ms, p99 at most 33.3 ms and no steady-play frame above 50 ms over a five-minute rendered benchmark after a declared warm-up; world entry is measured separately against 3000 ms. Hardware, resolution, renderer, quality preset, memory budget and capture overhead must be recorded before this can pass.
  → covered by Task T8
- [ ] Approve the character reel, representative decorated section and family-remix trial as separate quality gates; failure creates named corrective work and cannot be waived by merely passing functional tests. (manual)
  → covered by Task T9

### REQ-018: Repository onboarding preserves this end-state specification
Category: technical | Status: pending
The owner will connect the existing NodeSpec/OpenAxolotl repository after project creation. Inventory and reconcile actual implementation against this new specification without replacing it with old anchors.

**Acceptance criteria — your task boxes:**
- [ ] Before enabling sync or importing anchors, compare the repository's model/spec with this project and explicitly choose the authoritative documents; retain the old project as history. (manual)
  → covered by Task T10
- [ ] Repository files are mapped to their responsible nodes with traceable paths and commit references; generated anchors are not misbound as component source.
  → covered by Task T11
- [ ] Requirements remain unverified until fresh automated evidence or recorded manual approval is attached; old test ticks are not imported as current proof.
  → covered by Task T12
- [ ] Track implementation gaps separately from desired behavior, including content export/loader, curated distribution, future suit powers, whirlpool and boss placement. (manual)
  → covered by Task T13
- [ ] Before code changes, record a source inventory, baseline input replays and rendered captures, open defects and migration ownership; existing historical test reports are reference material only. (manual)
  → covered by Task T14

## Interface Contracts

### SENDS TO: OpenAxolotl Game Shell (game-client)
- **Contract:** Quality Run Record v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Quality Run Record v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "runId",
    "sourceRevision",
    "requirementId",
    "criterionId",
    "scenarioId",
    "mode",
    "status",
    "profileId",
    "inputReplayId",
    "hardwareRecord",
    "artifactPaths"
  ],
  "properties": {
    "mode": {
      "enum": [
        "automated",
        "manual"
      ],
      "type": "string"
    },
    "runId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "status": {
      "enum": [
        "unrun",
        "pass",
        "fail",
        "review_pending"
      ],
      "type": "string"
    },
    "profileId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "scenarioId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "criterionId": {
      "type": "string",
      "minLength": 1
    },
    "artifactPaths": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      }
    },
    "inputReplayId": {
      "type": [
        "string",
        "null"
      ]
    },
    "requirementId": {
      "type": "string",
      "minLength": 1
    },
    "schemaVersion": {
      "const": 1
    },
    "hardwareRecord": {
      "type": [
        "string",
        "null"
      ]
    },
    "sourceRevision": {
      "type": "string",
      "minLength": 1
    }
  },
  "description": "One binding scenario per criterion; exact source, settings and evidence required. Rendered target-hardware performance evidence is distinct from headless functional tests. Manual quality gates need human approval. Historical renders or old reports are not current verification.",
  "additionalProperties": false
}
```

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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- OpenAxolotl Game Shell (this node calls/depends on it via Quality Run Record v1 (dependency))
- Content Export & Conformance (this node calls/depends on it via Conformance Evidence v2 (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `docs/performance.md` | doc | --- | draft |
| `.gitignore` | config | --- | draft |
| `test/run_tests.gd.uid` | config | --- | draft |
| `test/core/harness/test_harness_integrity.gd.uid` | config | --- | draft |
| `pyproject.toml` | config | --- | draft |
| `tools/verify_cascade_basin_seals.gd` | source | --- | draft |
| `tools/water_review.gd` | source | --- | draft |
| `tools/tightened_lagoon_review.gd` | source | --- | draft |
| `tools/verify_enemy_motion.gd` | source | --- | draft |
| `tools/hero_review.gd` | source | --- | draft |
| `tools/.gdignore` | config | --- | draft |
| `tools/__init__.py` | source | --- | draft |
| `test/run_hero_tests.gd.uid` | config | --- | draft |
| `tools/verify_crayfish_world.gd` | source | --- | draft |
| `test/support/gdunit_compat.gd.uid` | config | --- | draft |
| `tools/lagoon_preview.gd` | source | --- | draft |
| `Capture Lagoon.cmd` | source | --- | draft |
| `Capture Hero.cmd` | source | --- | draft |
| `docs/local-source-manifest.json` | config | --- | draft |
| `tools/verify_sealed_inlet.gd` | source | --- | draft |
| `tools/test_ci_pipeline.py` | source | --- | draft |
| `test/run_hero_tests.gd` | source | --- | draft |
| `tools/inspect_hero.gd` | source | --- | draft |
| `test/perf/perf_gate_probe.gd` | source | --- | draft |
| `tools/verify_net_capture.gd` | source | --- | draft |
| `tools/run_dance_regression.gd` | source | --- | draft |
| `.nodespec/tests/req-017.tests.md` - Test plan for requirement: Desktop-first quality with a separate tablet decision | test-plan | markdown | draft |
| `tools/verify_crayfish_dance.gd` | source | --- | draft |
| `tools/test_import_weight.py` | source | --- | draft |
| `test/perf/perf_gate_probe.gd.uid` | config | --- | draft |
| `docs/commands.md` | doc | --- | draft |
| `tools/lagoon_asset_catalog.gd` | source | --- | draft |
| `ARCHITECTURE.md` | doc | --- | draft |
| `.github/workflows/pr.yml` | config | --- | draft |
| `scripts/build.sh` | build | --- | draft |
| `tools/verify_enemy_population.gd` | source | --- | draft |
| `tools/verify_cascade_collision_polish.gd` | source | --- | draft |
| `tools/verify_enemy_population_input.gd` | source | --- | draft |
| `test/perf/run_gpu_gate.gd` | source | --- | draft |
| `tools/test_performance_targets.py` | source | --- | draft |
| `test/perf/run_perf_gate.gd` | source | --- | draft |
| `scripts/setup.sh` | build | --- | draft |
| `tools/test_gameplay_snapshot.py` | source | --- | draft |
| `tools/verify_exploration_music.gd` | source | --- | draft |
| `test/run_tests.gd` | source | --- | draft |
| `.nodespec/tests/req-018.tests.md` - Test plan for requirement: Repository onboarding preserves this end-state specification | test-plan | markdown | draft |
| `test/perf/run_perf_gate.gd.uid` | config | --- | draft |
| `test/support/gdunit_compat.gd` | source | --- | draft |
| `docs/mvp-readiness.md` | doc | --- | draft |
| `testdemo.txt` | doc | --- | draft |
| `test/perf/run_gpu_gate.gd.uid` | config | --- | draft |
| `contracts/performance_targets.v1.json` | config | --- | draft |
| `tools/gameplay_snapshot.py` | source | --- | draft |
| `tools/lagoon_imported_review.gd` | source | --- | draft |
| `tools/verify_crayfish_habitat.gd` | source | --- | draft |
| `test/core/harness/test_harness_integrity.gd` | source | --- | draft |
| `tools/verify_fleet_animations.gd` | source | --- | draft |
| `.gitattributes` | config | --- | draft |
