# Task: Progress, Recovery & Rewards

> **Scope:** implement ONLY this node ("Progress, Recovery & Rewards"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

Own core/progression, core/save (except shell lifetime composition), core/regen, core/collectibles, core/restoration, existing core/gillmod and crayfish reward presentation. Document persistence and reset snapshots explicitly. Use stable world/collectible identities; five unique crayfish unlock a reusable dance without spending them. Keep pickups in authored accessible habitats and align visible creatures with triggers. Dance requires a clear flat shore and cancels on movement, water entry, damage, capture and reset, with no invulnerability. Coordinate cancellation with hero/enemies and namespaces with installation. Existing Gill Mods are optional; future suits and whirlpool are gaps, not completed features.

This document describes planned work. All completion boxes remain open until current evidence or recorded human approval is attached. Keep the existing task keys and criterion identities. Shared payload schemas are normative even where generic dependency guidance describes only wiring.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
  - [ ] Inventory the current bound implementation including `test/core/progression/test_life_system.gd`, `core/restoration/restoration_store.gd`, `core/collectibles/save_collectible_store.gd`, `core/gillmod/gill_mod_error.gd`; record each retained component, migration gap and owning dependency before changing files.
  - [ ] Use the existing repository/project and test harness; adapt the current component in place rather than creating a parallel scaffold.
  - [ ] Document checkpoint snapshot and life/capability loss rules from the current implementation.
  - [ ] Record a baseline fixture and observable behavior for this component at the pinned gameplay commit; keep historical results separate from fresh proof.
- [ ] **T2 — Expose the interface Versioned World Runtime API consumes, per Contract "Progress Snapshot v1" (dependency).** <!-- t:a2ce1280 -->
  Record the endpoint/identifiers Versioned World Runtime API needs in this node's config artifacts — coordinate with Versioned World Runtime API.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Progress Snapshot v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T3 — Expose the interface Adventure Catalog & Installation consumes, per Contract "Progress Snapshot v1" (dependency).** <!-- t:9c252060 -->
  Record the endpoint/identifiers Adventure Catalog & Installation needs in this node's config artifacts — coordinate with Adventure Catalog & Installation.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Progress Snapshot v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T4 — Implement: "Crayfish move within authored shore or underwater habitats with their pickup trigger aligned to the visible creature; they cannot escape into inaccessible terrain." (REQ-006).** <!-- t:cc643a30 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Crayfish move within authored shore or underwater habitats with their pickup trigger aligned to the visible creature; they cannot escape into inaccessible terrain."
  - [ ] Implement this criterion within the existing owned component and public contracts, using five distinct and repeated crayfish pickups, habitat movement and dance start/cancellation on shore/water/damage/reset as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T5 — Implement: "Collecting five unique glowing crayfish unlocks a reusable dance; repeated collection of the same identity cannot increase the saved total." (REQ-006).** <!-- t:d73ef1d1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Collecting five unique glowing crayfish unlocks a reusable dance; repeated collection of the same identity cannot increase the saved total."
  - [ ] Implement this criterion within the existing owned component and public contracts, using five distinct and repeated crayfish pickups, habitat movement and dance start/cancellation on shore/water/damage/reset as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T6 — Implement: "Dance starts only on a flat, clear shore while stationary; movement, water entry, damage, capture or checkpoint reset cancels it. It grants no invulnerability and consumes no collected crayfish." (REQ-006).** <!-- t:37416fc1 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "Dance starts only on a flat, clear shore while stationary; movement, water entry, damage, capture or checkpoint reset cancels it. It grants no invulnerability and consumes no collected crayfish."
  - [ ] Implement this criterion within the existing owned component and public contracts, using five distinct and repeated crayfish pickups, habitat movement and dance start/cancellation on shore/water/damage/reset as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T7 — Implement: "The hero stands on hind legs for the line-dance-inspired routine with a separate groove cue; ordinary background music remains unobtrusive and has independent volume control." (REQ-006).** <!-- t:4b735b20 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-006 "The hero stands on hind legs for the line-dance-inspired routine with a separate groove cue; ordinary background music remains unobtrusive and has independent volume control."
  - [ ] Prepare a repeatable human-review setup for five distinct and repeated crayfish pickups, habitat movement and dance start/cancellation on shore/water/damage/reset; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T8 — Implement: "Checkpoint activation and respawn restore position, velocity and the documented capability/life snapshot without leaving attack, capture or dance states active." (REQ-007).** <!-- t:85a9d1a3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "Checkpoint activation and respawn restore position, velocity and the documented capability/life snapshot without leaving attack, capture or dance states active." — possible coordination point: Contract "Progress Snapshot v1" (dependency) from Versioned World Runtime API (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using checkpoint activation, death/capture reset, reload, capability loss and independent world save identities as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T9 — Implement: "Restoration, completion, unique discoveries and dance unlock persist through save/reload under documented namespaces." (REQ-007).** <!-- t:3db1a0a0 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "Restoration, completion, unique discoveries and dance unlock persist through save/reload under documented namespaces."
  - [ ] Implement this criterion within the existing owned component and public contracts, using checkpoint activation, death/capture reset, reload, capability loss and independent world save identities as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T10 — Implement: "Unavailable abilities or reduced capability do not softlock the first adventure; mandatory recovery paths remain reachable." (REQ-007).** <!-- t:3d8cefc0 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "Unavailable abilities or reduced capability do not softlock the first adventure; mandatory recovery paths remain reachable." — possible coordination point: Contract "Progress Snapshot v1" (dependency) from Adventure Catalog & Installation (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using checkpoint activation, death/capture reset, reload, capability loss and independent world save identities as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T11 — Implement: "Document exactly which encounters can remove capability or consume a life; neither the future whirlpool nor future suit powers are treated as implemented requirements." (REQ-007).** <!-- t:a92beda3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "Document exactly which encounters can remove capability or consume a life; neither the future whirlpool nor future suit powers are treated as implemented requirements."
  - [ ] Prepare a repeatable human-review setup for checkpoint activation, death/capture reset, reload, capability loss and independent world save identities; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T12 — Implement: "Riverheart progress distinguishes captive, freed/carried and returned/restored states; checkpoint reset, reload and migration from the old seed-gate save cannot lose the artifact, duplicate it or permanently lock the finale." (REQ-007).** <!-- t:0a0fc365 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-007 "Riverheart progress distinguishes captive, freed/carried and returned/restored states; checkpoint reset, reload and migration from the old seed-gate save cannot lose the artifact, duplicate it or permanently lock the finale." — possible coordination point: Contract "Progress Snapshot v1" (dependency) from Versioned World Runtime API (keyword signal only)
- [ ] **T13 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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
- **engine:** Godot 4.7 / GDScript 2.0
- **delivery:** Desktop first; tablet feasibility and consoles deferred.
- **gameplayBaseline:** 2464a14a40e2be6dbccab9d141ba3e0e783d3e45

## Vision This Node Serves

The sentences of the project vision that the outcomes behind this node's requirements cite:

- Preserve three checkpoints, optional discoveries, glowing crayfish and the optional dance reward.
- Accessible shores, entrance seams and underwater/pool boundaries are contained; accidental fallthrough is a defect.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-006: Glowing crayfish and an optional dance reward
Category: functional | Status: pending
Blue shore and underwater pickups are recognizable animated crayfish. Their reward adds personality without blocking adventure progress.

**Acceptance criteria — your task boxes:**
- [ ] Crayfish move within authored shore or underwater habitats with their pickup trigger aligned to the visible creature; they cannot escape into inaccessible terrain.
  → covered by Task T4
- [ ] Collecting five unique glowing crayfish unlocks a reusable dance; repeated collection of the same identity cannot increase the saved total.
  → covered by Task T5
- [ ] Dance starts only on a flat, clear shore while stationary; movement, water entry, damage, capture or checkpoint reset cancels it. It grants no invulnerability and consumes no collected crayfish.
  → covered by Task T6
- [ ] The hero stands on hind legs for the line-dance-inspired routine with a separate groove cue; ordinary background music remains unobtrusive and has independent volume control. (manual)
  → covered by Task T7

### REQ-007: Consistent recovery, capabilities and saved progress
Category: functional | Status: pending
Preserve existing regeneration/capability, lives/checkpoint and Gill Mod concepts behind explicit public interfaces. Unexpected fallthrough is a defect, not an intended difficulty mechanic.

**Acceptance criteria — your task boxes:**
- [ ] Checkpoint activation and respawn restore position, velocity and the documented capability/life snapshot without leaving attack, capture or dance states active.
  → covered by Task T8
- [ ] Restoration, completion, unique discoveries and dance unlock persist through save/reload under documented namespaces.
  → covered by Task T9
- [ ] Unavailable abilities or reduced capability do not softlock the first adventure; mandatory recovery paths remain reachable.
  → covered by Task T10
- [ ] Document exactly which encounters can remove capability or consume a life; neither the future whirlpool nor future suit powers are treated as implemented requirements. (manual)
  → covered by Task T11
- [ ] Riverheart progress distinguishes captive, freed/carried and returned/restored states; checkpoint reset, reload and migration from the old seed-gate save cannot lose the artifact, duplicate it or permanently lock the finale.
  → covered by Task T12

## Interface Contracts

### RECEIVES FROM: Versioned World Runtime API (shared-library)
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

### RECEIVES FROM: Adventure Catalog & Installation (shared-library)
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

**Depends on THIS node being available:**
- Versioned World Runtime API (initiates Progress Snapshot v1 against this node (dependency))
- Adventure Catalog & Installation (initiates Progress Snapshot v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `test/core/progression/test_life_system.gd` | source | --- | draft |
| `core/restoration/restoration_store.gd` | source | --- | draft |
| `core/collectibles/collectibles_system.gd.uid` | config | --- | draft |
| `core/collectibles/save_collectible_store.gd` | source | --- | draft |
| `core/gillmod/gill_mod_error.gd` | source | --- | draft |
| `core/restoration/restorable_region.gd` | source | --- | draft |
| `core/restoration/restorable_region.gd.uid` | config | --- | draft |
| `core/gillmod/gill_mod_registry.gd.uid` | config | --- | draft |
| `core/collectibles/collectible_error.gd` | source | --- | draft |
| `core/regen/capability_state.gd.uid` | config | --- | draft |
| `core/save/save_error.gd.uid` | config | --- | draft |
| `test/core/regen/test_regen_system.gd.uid` | config | --- | draft |
| `core/progression/checkpoint_graph.gd.uid` | config | --- | draft |
| `core/rendering/crayfish_motion.gd.uid` | config | --- | draft |
| `core/gillmod/gill_mod_system.gd.uid` | config | --- | draft |
| `core/collectibles/collectible_error.gd.uid` | config | --- | draft |
| `core/restoration/restoration_system.gd` | source | --- | draft |
| `core/gillmod/gill_mod.gd` | source | --- | draft |
| `core/restoration/scene_traversal_gate.gd.uid` | config | --- | draft |
| `core/save/save_restoration_store.gd.uid` | config | --- | draft |
| `core/save/save_migrations.gd.uid` | config | --- | draft |
| `core/save/tiered_compatibility_policy.gd.uid` | config | --- | draft |
| `test/core/restoration/test_restoration_system.gd` | source | --- | draft |
| `core/gillmod/gill_mod_registry.gd` | source | --- | draft |
| `core/progression/life_system.gd.uid` | config | --- | draft |
| `test/core/collectibles/test_collectibles_system.gd` | source | --- | draft |
| `core/collectibles/collectible_def.gd` | source | --- | draft |
| `test/core/restoration/test_restoration_system.gd.uid` | config | --- | draft |
| `.nodespec/tests/req-007.tests.md` - Test plan for requirement: Consistent recovery, capabilities and saved progress | test-plan | markdown | draft |
| `core/gillmod/gill_mod_system.gd` | source | --- | draft |
| `core/regen/capability.gd` | source | --- | draft |
| `core/collectibles/collectible_kind.gd.uid` | config | --- | draft |
| `core/restoration/traversal_gate.gd.uid` | config | --- | draft |
| `core/save/save_system.gd.uid` | config | --- | draft |
| `core/progression/save_checkpoint_store.gd.uid` | config | --- | draft |
| `core/gillmod/mods/bubble.json` | config | --- | draft |
| `core/save/save_restoration_store.gd` | source | --- | draft |
| `core/regen/capability_state.gd` | source | --- | draft |
| `core/restoration/restoration_system.gd.uid` | config | --- | draft |
| `core/rendering/crayfish_shell.gdshader` | source | --- | draft |
| `core/restoration/restoration_store.gd.uid` | config | --- | draft |
| `core/regen/damage_event.gd.uid` | config | --- | draft |
| `core/rendering/crayfish_import.gd.uid` | config | --- | draft |
| `core/regen/state_discriminator.gd.uid` | config | --- | draft |
| `core/gillmod/mods/jet.json` | config | --- | draft |
| `core/save/world_contract_shape.gd.uid` | config | --- | draft |
| `core/rendering/crayfish_shell.gdshader.uid` | config | --- | draft |
| `core/collectibles/collectible_kind.gd` | source | --- | draft |
| `core/regen/damage_event.gd` | source | --- | draft |
| `test/core/save/test_save_system.gd.uid` | config | --- | draft |
| `core/gillmod/mods/glow.json` | config | --- | draft |
| `core/progression/checkpoint_store.gd.uid` | config | --- | draft |
| `test/core/gillmod/test_gill_mod_system.gd` | source | --- | draft |
| `core/progression/catastrophic_source.gd.uid` | config | --- | draft |
| `core/save/save_compatibility_policy.gd.uid` | config | --- | draft |
| `core/progression/capability_restorer.gd.uid` | config | --- | draft |
| `core/progression/checkpoint.gd.uid` | config | --- | draft |
| `core/regen/capability.gd.uid` | config | --- | draft |
| `core/regen/mutation_loadout.gd` | source | --- | draft |
| `core/collectibles/save_collectible_store.gd.uid` | config | --- | draft |
| `core/collectibles/collectible_store.gd` | source | --- | draft |
| `core/regen/feedback_cue.gd` | source | --- | draft |
| `core/regen/mutation_loadout.gd.uid` | config | --- | draft |
| `core/save/save_error.gd` | source | --- | draft |
| `core/progression/checkpoint_graph.gd` | source | --- | draft |
| `core/rendering/crayfish_import.gd` | source | --- | draft |
| `core/save/save_system.gd` | source | --- | draft |
| `core/restoration/region_state.gd.uid` | config | --- | draft |
| `core/regen/state_discriminator.gd` | source | --- | draft |
| `core/rendering/crayfish_motion.gd` | source | --- | draft |
| `test/core/progression/test_life_system.gd.uid` | config | --- | draft |
| `core/save/world_contract_shape.gd` | source | --- | draft |
| `core/progression/capability_restorer.gd` | source | --- | draft |
| `.nodespec/tests/req-006.tests.md` - Test plan for requirement: Glowing crayfish and an optional dance reward | test-plan | markdown | draft |
| `test/core/save/test_save_system.gd` | source | --- | draft |
| `core/collectibles/collectibles_system.gd` | source | --- | draft |
| `core/regen/feedback_table.gd` | source | --- | draft |
| `core/collectibles/collectible_store.gd.uid` | config | --- | draft |
| `core/save/save_compatibility_policy.gd` | source | --- | draft |
| `core/progression/checkpoint_store.gd` | source | --- | draft |
| `core/restoration/region_state.gd` | source | --- | draft |
| `core/collectibles/collectible_def.gd.uid` | config | --- | draft |
| `core/regen/regen_system.gd` | source | --- | draft |
| `core/save/tiered_compatibility_policy.gd` | source | --- | draft |
| `core/progression/save_checkpoint_store.gd` | source | --- | draft |
| `core/restoration/restoration_error.gd` | source | --- | draft |
| `docs/crayfish-groove.md` | doc | --- | draft |
| `core/regen/feedback_table.gd.uid` | config | --- | draft |
| `core/gillmod/gill_mod_error.gd.uid` | config | --- | draft |
| `test/core/collectibles/test_collectibles_system.gd.uid` | config | --- | draft |
| `test/core/regen/test_regen_system.gd` | source | --- | draft |
| `core/progression/catastrophic_source.gd` | source | --- | draft |
| `core/save/save_migrations.gd` | source | --- | draft |
| `core/progression/life_system.gd` | source | --- | draft |
| `core/restoration/traversal_gate.gd` | source | --- | draft |
| `test/core/gillmod/test_gill_mod_system.gd.uid` | config | --- | draft |
| `core/gillmod/gill_mod.gd.uid` | config | --- | draft |
| `core/progression/checkpoint.gd` | source | --- | draft |
| `core/regen/regen_system.gd.uid` | config | --- | draft |
| `core/restoration/restoration_error.gd.uid` | config | --- | draft |
| `docs/save_compatibility_policy.md` | doc | --- | draft |
| `core/restoration/scene_traversal_gate.gd` | source | --- | draft |
| `core/regen/feedback_cue.gd.uid` | config | --- | draft |
