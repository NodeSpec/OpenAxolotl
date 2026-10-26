# Task: Drift Fleet Encounters

> **Scope:** implement ONLY this node ("Drift Fleet Encounters"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Implement the integration with Hero Motion & Animation (godot) per Contract "Hero Motion and Action Snapshot v1" (dependency).** <!-- t:7e5f80fa -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface Versioned World Runtime API consumes, per Contract "Declarative World Definition v1" (dependency).** <!-- t:ab1d2af8 -->
  Record the endpoint/identifiers Versioned World Runtime API needs in this node's config artifacts — coordinate with Versioned World Runtime API.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement: "An enemy acquires the player only inside its authored awareness range and valid line of sight, respects its home leash and habitat, and returns smoothly when pursuit ends." (REQ-004).** <!-- t:b4e8b24b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-004 "An enemy acquires the player only inside its authored awareness range and valid line of sight, respects its home leash and habitat, and returns smoothly when pursuit ends." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T5 — Implement: "Attack wind-up, active contact and recovery are distinct; committed attacks do not rotate or home after release and cancelled attacks cannot retain active hit windows." (REQ-004).** <!-- t:e0f38213 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-004 "Attack wind-up, active contact and recovery are distinct; committed attacks do not rotate or home after release and cancelled attacks cannot retain active hit windows." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T6 — Implement: "A valid strike defeats an ordinary robot once per action, produces bounded mechanical debris, disables its attack/collision as appropriate, and cleans up debris." (REQ-004).** <!-- t:59502ef8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-004 "A valid strike defeats an ordinary robot once per action, produces bounded mechanical debris, disables its attack/collision as appropriate, and cleans up debris." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T7 — Implement: "Production encounters are reviewed for smooth acceleration, turning and pose transitions, readable timing and space to evade." (REQ-004).** <!-- t:193b4927 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-004 "Production encounters are reviewed for smooth acceleration, turning and pose transitions, readable timing and space to evade." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T8 — Implement: "Enemy acceleration, heading and pose transitions use versioned habitat-specific tuning and pass the same timed pursuit/return replay at 30, 60 and 120 render FPS without different attack counts or out-of-habitat motion." (REQ-004).** <!-- t:40c83f14 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-004 "Enemy acceleration, heading and pose transitions use versioned habitat-specific tuning and pass the same timed pursuit/return replay at 30, 60 and 120 render FPS without different attack counts or out-of-habitat motion." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T9 — Implement: "Netbot uses the animated net contact socket; three distinct tail-whack presses strictly before two seconds escape capture, while timeout resets to the active checkpoint without an additional life penalty." (REQ-005).** <!-- t:d2bab822 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-005 "Netbot uses the animated net contact socket; three distinct tail-whack presses strictly before two seconds escape capture, while timeout resets to the active checkpoint without an additional life penalty."
- [ ] **T10 — Implement: "Escaping a net clears the capture state but does not automatically defeat Netbot; a later valid attack can defeat it." (REQ-005).** <!-- t:97d546be -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-005 "Escaping a net clears the capture state but does not automatically defeat Netbot; a later valid attack can defeat it."
- [ ] **T11 — Implement: "Hookline throws toward the committed player position and retracts over three seconds without homing or new recovery hits; any equipped-Gill-Mod snag uses the bounded existing timer." (REQ-005).** <!-- t:a0bb6ee8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-005 "Hookline throws toward the committed player position and retracts over three seconds without homing or new recovery hits; any equipped-Gill-Mod snag uses the bounded existing timer." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T12 — Implement: "A player without a Gill Mod can evade or defeat Hookline and can complete the first adventure." (REQ-005).** <!-- t:2d9f4a59 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-005 "A player without a Gill Mod can evade or defeat Hookline and can complete the first adventure." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
- [ ] **T13 — Implement: "Net capture, escape, death and checkpoint reset cancel all outstanding attack tokens and contact windows; a held button counts as one press, and an escape input at or after the two-second deadline fails." (REQ-005).** <!-- t:de4c7082 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-005 "Net capture, escape, death and checkpoint reset cancel all outstanding attack tokens and contact windows; a held button counts as one press, and an escape input at or after the two-second deadline fails." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) to Hero Motion & Animation (keyword signal only)
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

- Our axolotl's expressive movement, land-and-water traversal, readable robot encounters, discoveries and restoration rewards create the sense of adventure.
- Three Netbots occupy land; five Hooklines are distributed across land and underwater positions.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-004: Nearby enemies with readable, smooth behavior
Category: functional | Status: pending
Netbots occupy land; Hooklines support land and underwater habitats. Encounters use perception, bounded patrols, telegraphs, committed attacks and readable recovery.

**Acceptance criteria — your task boxes:**
- [ ] An enemy acquires the player only inside its authored awareness range and valid line of sight, respects its home leash and habitat, and returns smoothly when pursuit ends.
  → covered by Task T4
- [ ] Attack wind-up, active contact and recovery are distinct; committed attacks do not rotate or home after release and cancelled attacks cannot retain active hit windows.
  → covered by Task T5
- [ ] A valid strike defeats an ordinary robot once per action, produces bounded mechanical debris, disables its attack/collision as appropriate, and cleans up debris.
  → covered by Task T6
- [ ] Production encounters are reviewed for smooth acceleration, turning and pose transitions, readable timing and space to evade. (manual)
  → covered by Task T7
- [ ] Enemy acceleration, heading and pose transitions use versioned habitat-specific tuning and pass the same timed pursuit/return replay at 30, 60 and 120 render FPS without different attack counts or out-of-habitat motion.
  → covered by Task T8

### REQ-005: Netbot capture and Hookline attack rules
Category: functional | Status: pending
Keep the currently requested opponent identities and escape rules, with optional encounters that do not silently become progression gates.

**Acceptance criteria — your task boxes:**
- [ ] Netbot uses the animated net contact socket; three distinct tail-whack presses strictly before two seconds escape capture, while timeout resets to the active checkpoint without an additional life penalty.
  → covered by Task T9
- [ ] Escaping a net clears the capture state but does not automatically defeat Netbot; a later valid attack can defeat it.
  → covered by Task T10
- [ ] Hookline throws toward the committed player position and retracts over three seconds without homing or new recovery hits; any equipped-Gill-Mod snag uses the bounded existing timer.
  → covered by Task T11
- [ ] A player without a Gill Mod can evade or defeat Hookline and can complete the first adventure.
  → covered by Task T12
- [ ] Net capture, escape, death and checkpoint reset cancel all outstanding attack tokens and contact windows; a held button counts as one press, and an escape input at or after the two-second deadline fails.
  → covered by Task T13

## Interface Contracts

### SENDS TO: Hero Motion & Animation (shared-library)
- **Contract:** Hero Motion and Action Snapshot v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Hero Motion and Action Snapshot v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "tick",
    "worldId",
    "position",
    "velocity",
    "headingRadians",
    "medium",
    "action",
    "actionToken",
    "phase",
    "grounded",
    "checkpointId"
  ],
  "properties": {
    "tick": {
      "type": "integer",
      "minimum": 0
    },
    "phase": {
      "enum": [
        "none",
        "windup",
        "active",
        "recovery"
      ],
      "type": "string"
    },
    "action": {
      "enum": [
        "idle",
        "travel",
        "jump",
        "fall",
        "land",
        "swim",
        "surface",
        "dive",
        "tail_whack",
        "spin",
        "captured",
        "dance",
        "reset"
      ],
      "type": "string"
    },
    "medium": {
      "enum": [
        "land",
        "water",
        "transition"
      ],
      "type": "string"
    },
    "worldId": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.:-]+$"
    },
    "grounded": {
      "type": "boolean"
    },
    "position": {
      "type": "array",
      "items": {
        "type": "number"
      },
      "maxItems": 3,
      "minItems": 3
    },
    "velocity": {
      "type": "array",
      "items": {
        "type": "number"
      },
      "maxItems": 3,
      "minItems": 3
    },
    "actionToken": {
      "type": "string",
      "minLength": 1
    },
    "checkpointId": {
      "type": [
        "string",
        "null"
      ]
    },
    "schemaVersion": {
      "const": 1
    },
    "headingRadians": {
      "type": "number"
    }
  },
  "description": "Read-only snapshot from the sole physics-root owner. Presentation cannot write gameplay state; hit windows use the authoritative action token. Reset invalidates prior tokens. Animation transition table and profile are separately versioned assets.",
  "additionalProperties": false
}
```

### RECEIVES FROM: Versioned World Runtime API (shared-library)
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
- Hero Motion & Animation (this node calls/depends on it via Hero Motion and Action Snapshot v1 (dependency))

**Depends on THIS node being available:**
- Versioned World Runtime API (initiates Declarative World Definition v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `core/enemies/visuals/fleet_animation_preview.tscn` | source | --- | draft |
| `core/boss/flagship_error.gd.uid` | config | --- | draft |
| `core/enemies/roster/runoff_drone.json` | config | --- | draft |
| `core/enemies/fleet_encounter.gd.uid` | config | --- | draft |
| `core/enemies/roster/netbot.json` | config | --- | draft |
| `core/enemies/net_capture.gd.uid` | config | --- | draft |
| `core/enemies/enemy_error.gd` | source | --- | draft |
| `core/enemies/visuals/fleet_animation_preview.gd` | source | --- | draft |
| `core/boss/flagship_encounter.gd` | source | --- | draft |
| `core/boss/flagship_error.gd` | source | --- | draft |
| `test/core/boss/test_flagship_encounter.gd.uid` | config | --- | draft |
| `core/enemies/fleet_encounter.gd` | source | --- | draft |
| `core/enemies/visuals/fleet_breakup.gd.uid` | config | --- | draft |
| `test/core/boss/test_flagship_encounter.gd` | source | --- | draft |
| `core/enemies/enemy_def.gd` | source | --- | draft |
| `core/enemies/visuals/fleet_enemy_visual.gd` | source | --- | draft |
| `core/enemies/visuals/README.md` | doc | --- | draft |
| `core/enemies/enemy_registry.gd` | source | --- | draft |
| `test/hub/test_world_drift_fleet.gd.uid` | config | --- | draft |
| `core/enemies/visuals/fleet_breakup.gd` | source | --- | draft |
| `core/enemies/cascade_population.tscn` | source | --- | draft |
| `test/core/enemies/test_striking_back.gd.uid` | config | --- | draft |
| `docs/enemies.md` | doc | --- | draft |
| `core/enemies/net_capture.gd` | source | --- | draft |
| `test/core/enemies/test_drift_fleet.gd` | source | --- | draft |
| `core/enemies/visuals/net_capture_preview.tscn` | source | --- | draft |
| `core/enemies/visuals/hookline_rig_visual.tscn` | source | --- | draft |
| `docs/enemy-population.md` | doc | --- | draft |
| `core/enemies/drift_fleet_system.gd` | source | --- | draft |
| `core/enemies/enemy_registry.gd.uid` | config | --- | draft |
| `core/enemies/drift_fleet_system.gd.uid` | config | --- | draft |
| `test/hub/test_world_drift_fleet.gd` | test-plan | --- | draft |
| `core/enemies/roster/hookline_rig.json` | config | --- | draft |
| `core/enemies/visuals/netbot_visual.tscn` | source | --- | draft |
| `core/enemies/enemy_def.gd.uid` | config | --- | draft |
| `core/enemies/visuals/net_capture_preview.gd` | source | --- | draft |
| `core/enemies/visuals/fleet_enemy_visual.gd.uid` | config | --- | draft |
| `core/boss/flagship_encounter.gd.uid` | config | --- | draft |
| `core/enemies/visuals/fleet_animation_preview.gd.uid` | config | --- | draft |
| `test/core/enemies/test_drift_fleet.gd.uid` | config | --- | draft |
| `test/core/enemies/test_striking_back.gd` | source | --- | draft |
| `core/enemies/visuals/net_capture_preview.gd.uid` | config | --- | draft |
| `core/enemies/enemy_error.gd.uid` | config | --- | draft |
| `core/enemies/roster/dredger.json` | config | --- | draft |
