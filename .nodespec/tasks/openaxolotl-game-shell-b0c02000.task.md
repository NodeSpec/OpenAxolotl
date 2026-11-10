# Task: OpenAxolotl Game Shell

> **Scope:** implement ONLY this node ("OpenAxolotl Game Shell"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
> This document is DERIVED from the NodeSpec model + catalog (fingerprinted, regenerable via generate_task_docs). Node context/export is the model truth; propose model changes through the proposal flow — hand-edits to model facts here do not change the model.

## Component Purpose

**Role:** Game Client
**Technology:** Godot
**Description:** Game client application handling rendering, input, and local simulation

## Your Deliverable

**Working code for this component**, honoring the contracts and criteria below, plus its configuration artifacts and tests.

## Constraints That Apply Here

None recorded for this node. Standing conditions the build must honour (security, compliance, cost, technology and the like) can be filed with a `create_constraint` patch.

## Implementation Context

> ⚠ REVIEW NEEDED: the derived sections of this document changed after this context was authored. Re-verify this section against them, update what no longer holds, then delete this line.

Own the game boot, pause/settings and service lifetime composition around project.godot and core/save/game_session.gd. Keep the local gameplay snapshot 2464a14 authoritative; da401e2 changes binary resource storage only. Adapt the existing application rather than creating another Godot project. Wire semantic input, world runtime and installed-world availability at one composition point. The catalog is optional: offline official play must boot, finish and return even if catalog initialization fails. Do not move world placement coordinates into the shell. Verify repeated load/unload and reset cancel stale services and actions.

This document describes planned work. All completion boxes remain open until current evidence or recorded human approval is attached. Keep the existing task keys and criterion identities. Shared payload schemas are normative even where generic dependency guidance describes only wiring.

## Implementation Tasks

Ordered WORK ORDERS synthesized from the model — this node's deliverable kind, contracts, criterion attribution, configuration, and dependency chain. They guarantee coverage, scope, and traceability; they deliberately do NOT contain the implementation detail — that is your job (see the expansion directive below the list).

- [ ] **T1 — Scaffold the Godot component.** <!-- t:58e89980 -->
  Create the source layout, build files, and test harness this node's working code lives in.
  Start from the catalog's suggested structure: `scripts/main.gd`, `scenes/main.tscn`, `project.godot`, `export_presets.cfg`.
  - [ ] Inventory the current bound implementation including `core/save/game_session.gd`, `Play Lagoon.cmd`, `Open Lagoon Editor.cmd`; record each retained component, migration gap and owning dependency before changing files.
  - [ ] Use the existing repository/project and test harness; adapt the current component in place rather than creating a parallel scaffold.
  - [ ] Capture a clean boot-to-return baseline and catalog all instantiated services.
  - [ ] Record a baseline fixture and observable behavior for this component at the pinned gameplay commit; keep historical results separate from fresh proof.
- [ ] **T2 — Implement the integration with Versioned World Runtime API (godot) per Contract "Declarative World Definition v1" (dependency).** <!-- t:277a8bd7 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Declarative World Definition v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T3 — Implement the integration with Input, Camera & Accessibility (godot) per Contract "Semantic Input Frame v1" (dependency).** <!-- t:bb26635f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Semantic Input Frame v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T4 — Implement the integration with Official Adventure: Lagoon & Living Cascade (godot) per Contract "Declarative World Definition v1" (dependency).** <!-- t:06fe7274 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Declarative World Definition v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T5 — Implement the integration with Adventure Catalog & Installation (godot) per Contract "Installed Adventure State v1" (dependency).** <!-- t:73eedac3 -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Installed Adventure State v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T6 — Expose the interface Quality Evidence & Migration Gates consumes, per Contract "Quality Run Record v1" (dependency).** <!-- t:915542b9 -->
  Record the endpoint/identifiers Quality Evidence & Migration Gates needs in this node's config artifacts — coordinate with Quality Evidence & Migration Gates.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
  - [ ] Map the existing producer/consumer wiring for Quality Run Record v1 to the connected component and its attached schema; document any adapter and version boundary without implementing the neighbor's internals.
  - [ ] Exercise one conforming exchange and applicable missing/incompatible/reset case through that interface; use local fixtures during development and the real provider before final acceptance.
- [ ] **T7 — Implement: "The shipped build starts and completes an official adventure without an AI account, creator tooling or a network connection." (REQ-001).** <!-- t:8f779291 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "The shipped build starts and completes an official adventure without an AI account, creator tooling or a network connection." — possible coordination point: Contract "Declarative World Definition v1" (dependency) to Official Adventure: Lagoon & Living Cascade (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using offline boot, official route completion, return and unavailable catalog as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T8 — Implement: "The game contains no multiplayer dependency; optional catalog failures do not prevent playing installed official content." (REQ-001).** <!-- t:36b91ff8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "The game contains no multiplayer dependency; optional catalog failures do not prevent playing installed official content." — possible coordination point: Contract "Installed Adventure State v1" (dependency) to Adventure Catalog & Installation (keyword signal only)
  - [ ] Implement this criterion within the existing owned component and public contracts, using offline boot, official route completion, return and unavailable catalog as the focused regression setup.
  - [ ] Exercise success, boundary and invalid/cancellation cases that apply to this criterion; assert its stated observable behavior and timing rather than internal call order, and report fresh evidence only after execution.
- [ ] **T9 — Implement: "A recorded family playtest evaluates the clarity and enjoyment of the official start-to-finish route; findings are resolved or explicitly tracked." (REQ-001).** <!-- t:43d44844 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-001 "A recorded family playtest evaluates the clarity and enjoyment of the official start-to-finish route; findings are resolved or explicitly tracked." — possible coordination point: Contract "Declarative World Definition v1" (dependency) to Official Adventure: Lagoon & Living Cascade (keyword signal only)
  - [ ] Prepare a repeatable human-review setup for offline boot, official route completion, return and unavailable catalog; record controls, camera, build and relevant device/settings.
  - [ ] Capture the evidence and record the review decision against this exact criterion; name corrective work for failures and leave approval pending until the user confirms.
- [ ] **T10 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- Children should enjoy the shipped game without creating anything or needing an AI account.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-001: A complete single-player adventure before creation
Category: functional | Status: pending
Children enjoy Skippy's complete single-player adventure without creator tooling: discover ecosystem damage, follow clues, free the Riverheart, restore the Cascade and celebrate the return. Optional creation extends the finished game.

**Acceptance criteria — your task boxes:**
- [ ] The shipped build starts and completes an official adventure without an AI account, creator tooling or a network connection.
  → covered by Task T7
- [ ] The game contains no multiplayer dependency; optional catalog failures do not prevent playing installed official content.
  → covered by Task T8
- [ ] A recorded family playtest evaluates the clarity and enjoyment of the official start-to-finish route; findings are resolved or explicitly tracked. (manual)
  → covered by Task T9

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

### SENDS TO: Input, Camera & Accessibility (shared-library)
- **Contract:** Semantic Input Frame v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** godot

**Schema:**
```
{
  "type": "object",
  "title": "Semantic Input Frame v1",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "required": [
    "schemaVersion",
    "tick",
    "move",
    "look",
    "pressed",
    "held",
    "context",
    "focus"
  ],
  "properties": {
    "held": {
      "type": "array",
      "items": {
        "enum": [
          "jump",
          "dive",
          "spin"
        ],
        "type": "string"
      }
    },
    "look": {
      "type": "array",
      "items": {
        "type": "number"
      },
      "maxItems": 3,
      "minItems": 3
    },
    "move": {
      "type": "array",
      "items": {
        "type": "number"
      },
      "maxItems": 3,
      "minItems": 3
    },
    "tick": {
      "type": "integer",
      "minimum": 0
    },
    "focus": {
      "type": "boolean"
    },
    "context": {
      "enum": [
        "land",
        "water",
        "menu",
        "captured"
      ],
      "type": "string"
    },
    "pressed": {
      "type": "array",
      "items": {
        "enum": [
          "jump",
          "dive",
          "tail_whack",
          "spin",
          "dance",
          "interact",
          "pause"
        ],
        "type": "string"
      }
    },
    "schemaVersion": {
      "const": 1
    }
  },
  "description": "One input frame per 60 Hz simulation tick; pressed is edge-triggered; focus loss clears gameplay intent; move and look are normalized camera-relative vectors. Rendering never creates duplicate presses.",
  "additionalProperties": false
}
```

### SENDS TO: Official Adventure: Lagoon & Living Cascade (shared-library)
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

### SENDS TO: Adventure Catalog & Installation (shared-library)
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

### RECEIVES FROM: Quality Evidence & Migration Gates (cli-tool)
- **Contract:** Quality Run Record v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Versioned World Runtime API (this node calls/depends on it via Declarative World Definition v1 (dependency))
- Input, Camera & Accessibility (this node calls/depends on it via Semantic Input Frame v1 (dependency))
- Official Adventure: Lagoon & Living Cascade (this node calls/depends on it via Declarative World Definition v1 (dependency))
- Adventure Catalog & Installation (this node calls/depends on it via Installed Adventure State v1 (dependency))

**Depends on THIS node being available:**
- Quality Evidence & Migration Gates (initiates Quality Run Record v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `core/save/game_session.gd.uid` | config | --- | draft |
| `project.godot` | config | --- | draft |
| `EDITOR-STARTUP.md` | doc | --- | draft |
| `core/save/game_session.gd` | source | --- | draft |
| `Play Lagoon.cmd` | source | --- | draft |
| `export_presets.cfg` | config | --- | draft |
| `.nodespec/tests/req-001.tests.md` - Test plan for requirement: A complete single-player adventure before creation | test-plan | markdown | draft |
| `Open Lagoon Editor.cmd` | source | --- | draft |
