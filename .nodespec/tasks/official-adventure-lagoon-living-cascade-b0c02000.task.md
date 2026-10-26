# Task: Official Adventure: Lagoon & Living Cascade

> **Scope:** implement ONLY this node ("Official Adventure: Lagoon & Living Cascade"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Implement the integration with Versioned World Runtime API (godot) per Contract "Declarative World Definition v1" (dependency).** <!-- t:277a8bd7 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Approved Kit Entry v1" (dependency).** <!-- t:8692c42f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface OpenAxolotl Game Shell consumes, per Contract "Declarative World Definition v1" (dependency).** <!-- t:2dc49412 -->
  Record the endpoint/identifiers OpenAxolotl Game Shell needs in this node's config artifacts — coordinate with OpenAxolotl Game Shell.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Implement: "The leftmost tunnel enters the Living Cascade arrival area using the correct production transform and supports the intended return path." (REQ-019).** <!-- t:cfdb8a6e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-019 "The leftmost tunnel enters the Living Cascade arrival area using the correct production transform and supports the intended return path."
- [ ] **T6 — Implement: "Hub and inlet collision contain the shipped player capsule with no unsupported entrance strips; accidental escape resets safely." (REQ-019).** <!-- t:6c5484e7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-019 "Hub and inlet collision contain the shipped player capsule with no unsupported entrance strips; accidental escape resets safely."
- [ ] **T7 — Implement: "A new player can identify the entrance and practice the required controls before hostile encounters." (REQ-019).** <!-- t:d0a8b496 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-019 "A new player can identify the entrance and practice the required controls before hostile encounters."
- [ ] **T8 — Implement: "The main landings and continuous banks connect S01 to S03 with capsule-sized clearance; the swimming alternative rejoins before the root dive." (REQ-021).** <!-- t:8b25f26a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "The main landings and continuous banks connect S01 to S03 with capsule-sized clearance; the swimming alternative rejoins before the root dive."
- [ ] **T9 — Implement: "Missed jumps reach recovery water and usable ramps; the optional hermit-snail spur cannot gate completion or bypass the root dive." (REQ-021).** <!-- t:03744571 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Missed jumps reach recovery water and usable ramps; the optional hermit-snail spur cannot gate completion or bypass the root dive."
- [ ] **T10 — Implement: "Two land Netbots and one land Hookline use readable proximity encounters without becoming a required enemy-clear gate." (REQ-021).** <!-- t:dbe02945 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-021 "Two land Netbots and one land Hookline use readable proximity encounters without becoming a required enemy-clear gate."
- [ ] **T11 — Implement: "Crossing the designated finish volume after restoration records coral_cove.completed once and triggers the supported hub return flow." (REQ-026).** <!-- t:d6473845 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-026 "Crossing the designated finish volume after restoration records coral_cove.completed once and triggers the supported hub return flow."
- [ ] **T12 — Implement: "Completion works without optional discoveries, dance unlock or defeating every enemy." (REQ-026).** <!-- t:bcd49602 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-026 "Completion works without optional discoveries, dance unlock or defeating every enemy."
- [ ] **T13 — Implement: "Save/reload and re-entry preserve the documented restoration/completion/discovery state and do not leave the player captured, dancing or carrying stale velocity." (REQ-026).** <!-- t:a4a2baf2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-026 "Save/reload and re-entry preserve the documented restoration/completion/discovery state and do not leave the player captured, dancing or carrying stale velocity." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) to Reusable Level & Asset Kit (keyword signal only)
- [ ] **T14 — Implement: "CP_03 activates on the required approach; all seven garden seeds are accessible before the finale gate opens." (REQ-024).** <!-- t:607a4101 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-024 "CP_03 activates on the required approach; all seven garden seeds are accessible before the finale gate opens."
- [ ] **T15 — Implement: "Restoration spends three seeds for the first phase and four more for the second; seven total opens the gate, with nine seeds available across S04/S05." (REQ-024).** <!-- t:f177ced3 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-024 "Restoration spends three seeds for the first phase and four more for the second; seven total opens the gate, with nine seeds available across S04/S05."
- [ ] **T16 — Implement: "Fresh entry with zero, one or two terrace seeds completes after seven, six or five garden seeds respectively; save/reload cannot softlock the gate." (REQ-024).** <!-- t:084dbd51 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-024 "Fresh entry with zero, one or two terrace seeds completes after seven, six or five garden seeds respectively; save/reload cannot softlock the gate." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) to Reusable Level & Asset Kit (keyword signal only)
- [ ] **T17 — Implement: "The visible restoration and gate opening are readable from the garden pickups; no deposit station, boss or enemy-clear objective is introduced." (REQ-024).** <!-- t:cb68b910 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-024 "The visible restoration and gate opening are readable from the garden pickups; no deposit station, boss or enemy-clear objective is introduced."
- [ ] **T18 — Implement: "The inlet current tapers to a stop before the pool and CP_01 activates on its reachable dry pad." (REQ-020).** <!-- t:9a1f2693 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "The inlet current tapers to a stop before the pool and CP_01 activates on its reachable dry pad."
- [ ] **T19 — Implement: "Two broad water exits and the bank route to S02 remain reachable without a tail; optional crayfish are not required." (REQ-020).** <!-- t:484fc9d7 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "Two broad water exits and the bank route to S02 remain reachable without a tail; optional crayfish are not required."
- [ ] **T20 — Implement: "The normal camera shows the next bank exit and crown destination without foliage obscuring them." (REQ-020).** <!-- t:817c0c06 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-020 "The normal camera shows the next bank exit and crown destination without foliage obscuring them."
- [ ] **T21 — Implement: "CP_02 activates on the approach, and all three clusters are traversable within the measured current controller envelope, including the continuous climb bypass." (REQ-023).** <!-- t:66eaadfa -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-023 "CP_02 activates on the approach, and all three clusters are traversable within the measured current controller envelope, including the continuous climb bypass."
- [ ] **T22 — Implement: "Catch pools and ramps return the player to the relevant cluster, preserve capsule clearance and do not bypass the S05 restoration gate." (REQ-023).** <!-- t:d8894c40 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-023 "Catch pools and ramps return the player to the relevant cluster, preserve capsule clearance and do not bypass the S05 restoration gate."
- [ ] **T23 — Implement: "The two terrace seeds are reachable; one land Netbot, one underwater Hookline and one land Hookline have valid support/habitats." (REQ-023).** <!-- t:a0c78ba6 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-023 "The two terrace seeds are reachable; one land Netbot, one underwater Hookline and one land Hookline have valid support/habitats."
- [ ] **T24 — Implement: "The chute is continuously contained and descending; ordinary and boosted runs can negotiate the dive bar and reach the reward pool without unbounded falls." (REQ-025).** <!-- t:b430bd41 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-025 "The chute is continuously contained and descending; ordinary and boosted runs can negotiate the dive bar and reach the reward pool without unbounded falls."
- [ ] **T25 — Implement: "The dive obstacle supports stopping/reversal and active vertical control; the player is never required to swim up the waterfall." (REQ-025).** <!-- t:bafad331 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-025 "The dive obstacle supports stopping/reversal and active vertical control; the player is never required to swim up the waterfall."
- [ ] **T26 — Implement: "The tide pearl and crayfish remain optional, and accidental escape uses nonlethal checkpoint recovery; no whirlpool or boss is required." (REQ-025).** <!-- t:9abb274b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-025 "The tide pearl and crayfish remain optional, and accidental escape uses nonlethal checkpoint recovery; no whirlpool or boss is required."
- [ ] **T27 — Implement: "The actual upright player capsule can dive beneath the root, negotiate the turn, reverse and resurface at the terrace ramp without sticking or leaving the water bounds." (REQ-022).** <!-- t:edcc02bb -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-022 "The actual upright player capsule can dive beneath the root, negotiate the turn, reverse and resurface at the terrace ramp without sticking or leaving the water bounds."
- [ ] **T28 — Implement: "The root and banks prevent a dry shortcut while preserving both open-water mouths and the optional grotto return." (REQ-022).** <!-- t:ee0ab42d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-022 "The root and banks prevent a dry shortcut while preserving both open-water mouths and the optional grotto return."
- [ ] **T29 — Implement: "Two underwater Hooklines respect their habitats and swim clearances; crayfish and the lantern shrimp remain optional." (REQ-022).** <!-- t:7197271a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-022 "Two underwater Hooklines respect their habitats and swim clearances; crayfish and the lantern shrimp remain optional."
- [ ] **T30 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- Open Lagoon is the safe starting cove.
- Its leftmost downstream tunnel connects to Coral Cove, currently presented as The Living Cascade: Arrival Pool; Stepping-stone Garden; Hollow-root Dive; Cascade Terraces; Restoration Garden; Waterfall Run; completion and return to the hub.
- The current finish uses a reach_volume trigger, not a mandatory boss.
- Preserve three checkpoints, optional discoveries, glowing crayfish and the optional dance reward.
- The restoration gate requires seven total seeds, with nine available and seven accessible within the garden alone.
- Accessible shores, entrance seams and underwater/pool boundaries are contained; accidental fallthrough is a defect.
- A whirlpool, additional suit powers and a new boss remain future work until separately specified.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-019: Open Lagoon and the leftmost tunnel
Category: functional | Status: pending
Safe onboarding hub with walking, hopping, swimming and diving. The leftmost downstream tunnel is the continuous entrance to Coral Cove / Living Cascade.

**Acceptance criteria — your task boxes:**
- [ ] The leftmost tunnel enters the Living Cascade arrival area using the correct production transform and supports the intended return path.
  → covered by Task T5
- [ ] Hub and inlet collision contain the shipped player capsule with no unsupported entrance strips; accidental escape resets safely.
  → covered by Task T6
- [ ] A new player can identify the entrance and practice the required controls before hostile encounters. (manual)
  → covered by Task T7

### REQ-021: S02 — Stepping-stone Garden
Category: functional | Status: pending
Teach aimed hopping over forgiving water. Preserve the optional hermit-snail pocket and an easier swimming route.

**Acceptance criteria — your task boxes:**
- [ ] The main landings and continuous banks connect S01 to S03 with capsule-sized clearance; the swimming alternative rejoins before the root dive.
  → covered by Task T8
- [ ] Missed jumps reach recovery water and usable ramps; the optional hermit-snail spur cannot gate completion or bypass the root dive.
  → covered by Task T9
- [ ] Two land Netbots and one land Hookline use readable proximity encounters without becoming a required enemy-clear gate.
  → covered by Task T10

### REQ-026: Finish, persist and return to Open Lagoon
Category: functional | Status: pending
Complete the current first adventure at its reach_volume exit and return to the hub without a mandatory boss or undefined next-world portal.

**Acceptance criteria — your task boxes:**
- [ ] Crossing the designated finish volume after restoration records coral_cove.completed once and triggers the supported hub return flow.
  → covered by Task T11
- [ ] Completion works without optional discoveries, dance unlock or defeating every enemy.
  → covered by Task T12
- [ ] Save/reload and re-entry preserve the documented restoration/completion/discovery state and do not leave the player captured, dancing or carrying stale velocity.
  → covered by Task T13

### REQ-024: S05 — Restoration Garden and crown arch
Category: functional | Status: pending
A calm restoration payoff at the top of the level, with CP_03, the main arch and a readable gate opening into the finale.

**Acceptance criteria — your task boxes:**
- [ ] CP_03 activates on the required approach; all seven garden seeds are accessible before the finale gate opens.
  → covered by Task T14
- [ ] Restoration spends three seeds for the first phase and four more for the second; seven total opens the gate, with nine seeds available across S04/S05.
  → covered by Task T15
- [ ] Fresh entry with zero, one or two terrace seeds completes after seven, six or five garden seeds respectively; save/reload cannot softlock the gate.
  → covered by Task T16
- [ ] The visible restoration and gate opening are readable from the garden pickups; no deposit station, boss or enemy-clear objective is introduced. (manual)
  → covered by Task T17

### REQ-020: S01 — Arrival Pool
Category: functional | Status: pending
Release the player from the inlet, frame the distant crown and establish safe-water recovery. No enemy or mandatory jump gates this section.

**Acceptance criteria — your task boxes:**
- [ ] The inlet current tapers to a stop before the pool and CP_01 activates on its reachable dry pad.
  → covered by Task T18
- [ ] Two broad water exits and the bank route to S02 remain reachable without a tail; optional crayfish are not required.
  → covered by Task T19
- [ ] The normal camera shows the next bank exit and crown destination without foliage obscuring them. (manual)
  → covered by Task T20

### REQ-023: S04 — Cascade Terraces
Category: functional | Status: pending
Combine hops, short swims and a modest climb in clusters A/B/C, with CP_02 and local recovery. Two terrace seeds help but are not required before entering the garden.

**Acceptance criteria — your task boxes:**
- [ ] CP_02 activates on the approach, and all three clusters are traversable within the measured current controller envelope, including the continuous climb bypass.
  → covered by Task T21
- [ ] Catch pools and ramps return the player to the relevant cluster, preserve capsule clearance and do not bypass the S05 restoration gate.
  → covered by Task T22
- [ ] The two terrace seeds are reachable; one land Netbot, one underwater Hookline and one land Hookline have valid support/habitats.
  → covered by Task T23

### REQ-025: S06 — Waterfall Run and reward pool
Category: functional | Status: pending
Deliver a controllable descent through a banked chute beside the scenic waterfall, with a dive bar and a calm reward pool.

**Acceptance criteria — your task boxes:**
- [ ] The chute is continuously contained and descending; ordinary and boosted runs can negotiate the dive bar and reach the reward pool without unbounded falls.
  → covered by Task T24
- [ ] The dive obstacle supports stopping/reversal and active vertical control; the player is never required to swim up the waterfall.
  → covered by Task T25
- [ ] The tide pearl and crayfish remain optional, and accidental escape uses nonlethal checkpoint recovery; no whirlpool or boss is required.
  → covered by Task T26

### REQ-022: S03 — Hollow-root Dive
Category: functional | Status: pending
The mandatory underwater root passage connects the garden to the terrace ascent; the lit lantern-shrimp grotto is optional.

**Acceptance criteria — your task boxes:**
- [ ] The actual upright player capsule can dive beneath the root, negotiate the turn, reverse and resurface at the terrace ramp without sticking or leaving the water bounds.
  → covered by Task T27
- [ ] The root and banks prevent a dry shortcut while preserving both open-water mouths and the optional grotto return.
  → covered by Task T28
- [ ] Two underwater Hooklines respect their habitats and swim clearances; crayfish and the lantern shrimp remain optional.
  → covered by Task T29

## Interface Contracts

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

### RECEIVES FROM: OpenAxolotl Game Shell (game-client)
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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Versioned World Runtime API (this node calls/depends on it via Declarative World Definition v1 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Approved Kit Entry v1 (dependency))

**Depends on THIS node being available:**
- OpenAxolotl Game Shell (initiates Declarative World Definition v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `hub/lagoon_waterfall.gdshader.uid` | config | --- | draft |
| `LAGOON-UPGRADE.md` | doc | --- | draft |
| `dev/living_cascade/cascade_surface_library.gd` | source | --- | draft |
| `dev/living_cascade/containment.tscn` | source | --- | draft |
| `test/worlds/run_living_cascade_chute.gd` | source | --- | draft |
| `test/worlds/run_living_cascade_arrival.gd.uid` | config | --- | draft |
| `hub/lagoon_foliage.gdshader.uid` | config | --- | draft |
| `hub/open_lagoon.gd` | source | --- | draft |
| `hub/lagoon_rock_kit.gd.uid` | config | --- | draft |
| `dev/living_cascade/cascade_tunnel_material.gd` | source | --- | draft |
| `dev/living_cascade/cascade_basin_seals.gd` | source | --- | draft |
| `test/worlds/run_cascade_asset_containment.gd` | source | --- | draft |
| `test/hub/hub_walk_probe.gd.uid` | config | --- | draft |
| `dev/living_cascade/cascade_collision_polish.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_root.gd` | source | --- | draft |
| `test/hub/run_hub_walk.gd.uid` | config | --- | draft |
| `worlds/coral_cove/channel_profile.json` | config | --- | draft |
| `dev/fall_guard.gd` | source | --- | draft |
| `hub/lagoon_stone.gdshader` | source | --- | draft |
| `test/worlds/coral_walk_probe.gd` | source | --- | draft |
| `dev/living_cascade/chute_profile.gd.uid` | config | --- | draft |
| `dev/living_cascade/preview_session.gd.uid` | config | --- | draft |
| `hub/open_lagoon.tscn` | source | --- | draft |
| `test/worlds/run_coral_walk.gd` | source | --- | draft |
| `dev/living_cascade/chute_profile.gd` | source | --- | draft |
| `dev/living_cascade/garden.tscn` | source | --- | draft |
| `dev/living_cascade/asset_reports/root_bridge.json` | config | --- | draft |
| `test/hub/run_tightened_lagoon.gd.uid` | config | --- | draft |
| `test/worlds/coral_route.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_chute.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_terraces.gd.uid` | config | --- | draft |
| `test/hub/fall_recovery_probe.gd.uid` | config | --- | draft |
| `dev/smoke_probe.gd.uid` | config | --- | draft |
| `docs/cascade-blue-tunnel-refinement.md` | doc | --- | draft |
| `dev/living_cascade/cascade_asset_dressing.gd` | source | --- | draft |
| `test/worlds/run_cascade_production.gd.uid` | config | --- | draft |
| `dev/living_cascade/root_dive.tscn` | source | --- | draft |
| `STREAM-PASSAGE.md` | doc | --- | draft |
| `test/hub/run_lagoon_art.gd` | source | --- | draft |
| `dev/living_cascade/ASSET_PASS.md` | doc | --- | draft |
| `test/worlds/test_cascade_assets.gd.uid` | config | --- | draft |
| `test/hub/hub_walk_probe.gd` | source | --- | draft |
| `dev/living_cascade/arrival_refinements.tscn` | source | --- | draft |
| `dev/living_cascade/preview_session.gd` | source | --- | draft |
| `test/worlds/test_coral_cove_composition.gd.uid` | config | --- | draft |
| `test/hub/test_fall_recovery.gd` | source | --- | draft |
| `dev/living_cascade/asset_reports/cliff_garden.json` | config | --- | draft |
| `test/worlds/run_living_cascade_garden.gd` | source | --- | draft |
| `dev/living_cascade/chute_profile.json` | config | --- | draft |
| `test/hub/run_hub_walk.gd` | source | --- | draft |
| `docs/cascade-texture-polish.md` | doc | --- | draft |
| `dev/archive/coral_cove_before_cascade/README.md` | doc | --- | draft |
| `dev/living_cascade/cascade_ground_depth.gd.uid` | config | --- | draft |
| `docs/cascade-basin-seals.md` | doc | --- | draft |
| `dev/fall_guard.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_restoration.gd.uid` | config | --- | draft |
| `hub/lagoon_stream_rock.gdshader.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_terraces.gd` | source | --- | draft |
| `hub/lagoon_stone.gdshader.uid` | config | --- | draft |
| `docs/cascade-solid-asset-pass.md` | doc | --- | draft |
| `dev/living_cascade/garden_preview.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_arrival.gd` | source | --- | draft |
| `test/hub/run_continuous_stream.gd.uid` | config | --- | draft |
| `test/worlds/run_cascade_asset_containment.gd.uid` | config | --- | draft |
| `test/hub/run_water_walk.gd.uid` | config | --- | draft |
| `dev/living_cascade/design_reference.json` | config | --- | draft |
| `dev/living_cascade/chute_water.gd.uid` | config | --- | draft |
| `hub/lagoon_hydrology.gd.uid` | config | --- | draft |
| `test/worlds/run_coral_walk.gd.uid` | config | --- | draft |
| `dev/living_cascade/asset_reports/crown_arch.json` | config | --- | draft |
| `hub/lagoon_imported_dressing.tscn` | source | --- | draft |
| `test/worlds/run_living_cascade_containment.gd` | source | --- | draft |
| `dev/living_cascade/cascade_collision_polish.gd` | source | --- | draft |
| `test/worlds/run_cascade_safe_falls.gd` | source | --- | draft |
| `dev/living_cascade/BUILD_PLAN.md` | doc | --- | draft |
| `dev/build_cascade_production.gd` | source | --- | draft |
| `test/hub/run_fall_recovery.gd` | source | --- | draft |
| `test/worlds/coral_walk_probe.gd.uid` | config | --- | draft |
| `dev/build_cascade_production.gd.uid` | config | --- | draft |
| `test/worlds/coral_route.gd` | source | --- | draft |
| `hub/lagoon_sky.gdshader` | source | --- | draft |
| `docs/cascade-custom-terrain-pass.md` | doc | --- | draft |
| `dev/living_cascade/cascade_landscape.gd` | source | --- | draft |
| `dev/capture_cascade.gd.uid` | config | --- | draft |
| `dev/living_cascade/terrace_preview.gd.uid` | config | --- | draft |
| `test/worlds/run_cascade_safe_falls.gd.uid` | config | --- | draft |
| `dev/living_cascade/asset_reports/stone_ruins.json` | config | --- | draft |
| `hub/lagoon_stream_path.gd` | source | --- | draft |
| `hub/lagoon_waterfall.gdshader` | source | --- | draft |
| `dev/archive/cascade_before_pbr/cascade_grass.gdshader` | source | --- | draft |
| `hub/lagoon_stream.gd` | source | --- | draft |
| `test/hub/run_imported_dressing.gd` | source | --- | draft |
| `dev/living_cascade/cascade_basin_seals.gd.uid` | config | --- | draft |
| `dev/living_cascade/chute_water.gd` | source | --- | draft |
| `dev/measure_channel.gd.uid` | config | --- | draft |
| `hub/lagoon_art.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_restoration.gd` | source | --- | draft |
| `worlds/coral_cove/world.json` | config | --- | draft |
| `hub/lagoon_stream.gd.uid` | config | --- | draft |
| `test/hub/run_lagoon_art.gd.uid` | config | --- | draft |
| `dev/living_cascade/asset_reports/mossy_stone.json` | config | --- | draft |
| `dev/archive/cascade_before_ground_depth/world.tscn` | source | --- | draft |
| `hub/lagoon_water.gdshader` | source | --- | draft |
| `dev/living_cascade/chute.tscn` | source | --- | draft |
| `test/hub/run_fall_recovery.gd.uid` | config | --- | draft |
| `dev/living_cascade/cascade-shadow-hulls.json` | config | --- | draft |
| `docs/cascade-ground-depth.md` | doc | --- | draft |
| `hub/lagoon_sky.gdshader.uid` | config | --- | draft |
| `dev/living_cascade/cascade_landscape.gd.uid` | config | --- | draft |
| `test/hub/run_water_walk.gd` | source | --- | draft |
| `dev/living_cascade/restoration_garden.tscn` | source | --- | draft |
| `dev/archive/cascade_before_pbr/world.tscn` | source | --- | draft |
| `dev/living_cascade/asset_reports/reef_wall.json` | config | --- | draft |
| `dev/living_cascade/cascade_asset_dressing.gd.uid` | config | --- | draft |
| `dev/living_cascade/asset_reports/bank_terrace.json` | config | --- | draft |
| `dev/archive/cascade_before_tunnel/world.tscn` | source | --- | draft |
| `test/worlds/route_pilot.gd.uid` | config | --- | draft |
| `test/hub/test_stream_path.gd` | source | --- | draft |
| `dev/archive/coral_cove_before_cascade/world.json` | config | --- | draft |
| `test/worlds/route_pilot.gd` | source | --- | draft |
| `test/hub/run_continuous_stream.gd` | source | --- | draft |
| `hub/lagoon_stream_path.gd.uid` | config | --- | draft |
| `test/worlds/test_coral_cove_composition.gd` | source | --- | draft |
| `test/hub/test_stream_path.gd.uid` | config | --- | draft |
| `dev/living_cascade/garden_preview.gd` | source | --- | draft |
| `dev/living_cascade/asset_reports/reef_ledge.json` | config | --- | draft |
| `docs/cascade-collision-polish.md` | doc | --- | draft |
| `hub/lagoon_art.gd` | source | --- | draft |
| `test/worlds/run_living_cascade_root.gd.uid` | config | --- | draft |
| `test/worlds/run_living_cascade_garden.gd.uid` | config | --- | draft |
| `test/hub/fall_recovery_probe.gd` | source | --- | draft |
| `dev/archive/coral_cove_before_cascade/world.tscn` | source | --- | draft |
| `test/worlds/run_cascade_production.gd` | source | --- | draft |
| `dev/greybox.tscn` | design | --- | draft |
| `test/worlds/run_living_cascade_containment.gd.uid` | config | --- | draft |
| `hub/lagoon_hydrology.gd` | source | --- | draft |
| `worlds/coral_cove/README.md` | doc | --- | draft |
| `hub/lagoon_water.gdshader.uid` | config | --- | draft |
| `hub/lagoon_stream_rock.gdshader` | source | --- | draft |
| `docs/cascade-tunnel-refinement.md` | doc | --- | draft |
| `dev/living_cascade/cascade_ground_depth.gd` | source | --- | draft |
| `dev/living_cascade/asset_reports/reef_arch.json` | config | --- | draft |
| `hub/open_lagoon.gd.uid` | config | --- | draft |
| `dev/archive/cascade_before_pbr/cascade_grass.gdshader.uid` | config | --- | draft |
| `dev/run_smoke.gd` | source | --- | draft |
| `test/hub/run_imported_dressing.gd.uid` | config | --- | draft |
| `test/hub/test_fall_recovery.gd.uid` | config | --- | draft |
| `dev/living_cascade/terraces.tscn` | source | --- | draft |
| `dev/living_cascade/cascade_surface_library.gd.uid` | config | --- | draft |
| `worlds/coral_cove/world.tscn` | source | --- | draft |
| `dev/run_smoke.gd.uid` | config | --- | draft |
| `test/worlds/test_cascade_assets.gd` | source | --- | draft |
| `dev/living_cascade/blockout.tscn` | source | --- | draft |
| `dev/measure_channel.gd` | source | --- | draft |
| `dev/smoke_probe.gd` | source | --- | draft |
| `hub/lagoon_rock_kit.gd` | source | --- | draft |
| `dev/capture_cascade.gd` | source | --- | draft |
| `hub/lagoon_foliage.gdshader` | source | --- | draft |
| `dev/living_cascade/cascade_tunnel_material.gd.uid` | config | --- | draft |
| `test/hub/run_tightened_lagoon.gd` | source | --- | draft |
| `dev/living_cascade/terrace_preview.gd` | source | --- | draft |
