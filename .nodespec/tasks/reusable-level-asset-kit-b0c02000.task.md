# Task: Reusable Level & Asset Kit

> **Scope:** implement ONLY this node ("Reusable Level & Asset Kit"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Expose the interface Versioned World Runtime API consumes, per Contract "Approved Kit Entry v1" (dependency).** <!-- t:a316d3e6 -->
  Record the endpoint/identifiers Versioned World Runtime API needs in this node's config artifacts — coordinate with Versioned World Runtime API.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface Hero Motion & Animation consumes, per Contract "Approved Kit Entry v1" (dependency).** <!-- t:6e56a29f -->
  Record the endpoint/identifiers Hero Motion & Animation needs in this node's config artifacts — coordinate with Hero Motion & Animation.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface Official Adventure: Lagoon & Living Cascade consumes, per Contract "Approved Kit Entry v1" (dependency).** <!-- t:dd472da1 -->
  Record the endpoint/identifiers Official Adventure: Lagoon & Living Cascade needs in this node's config artifacts — coordinate with Official Adventure: Lagoon & Living Cascade.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Family Workshop & Starter consumes, per Contract "Approved Kit Entry v1" (dependency).** <!-- t:91979131 -->
  Record the endpoint/identifiers Family Workshop & Starter needs in this node's config artifacts — coordinate with Family Workshop & Starter.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Expose the interface Content Export & Conformance consumes, per Contract "Approved Kit Entry v1" (dependency).** <!-- t:3772a3ad -->
  Record the endpoint/identifiers Content Export & Conformance needs in this node's config artifacts — coordinate with Content Export & Conformance.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T7 — Implement: "Each catalog entry has a stable ID/version, supported parameters, required dependencies, habitat/collision rules and rights/provenance metadata." (REQ-009).** <!-- t:d32fc35b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Each catalog entry has a stable ID/version, supported parameters, required dependencies, habitat/collision rules and rights/provenance metadata." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) from Versioned World Runtime API (keyword signal only)
- [ ] **T8 — Implement: "Gameplay prefabs ship with appropriate collision, interaction volumes and bounded behavior; decorative motion cannot move gameplay collision." (REQ-009).** <!-- t:efe3ed71 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Gameplay prefabs ship with appropriate collision, interaction volumes and bounded behavior; decorative motion cannot move gameplay collision." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T9 — Implement: "Land surfaces, shores, grass, rock, underwater depth gradients, waterfall origins, hero and enemies meet the starting-lagoon visual reference at gameplay distance without stretched pixelated textures or distracting repetition." (REQ-009).** <!-- t:a64aeb36 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Land surfaces, shores, grass, rock, underwater depth gradients, waterfall origins, hero and enemies meet the starting-lagoon visual reference at gameplay distance without stretched pixelated textures or distracting repetition." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T10 — Implement: "Art and sound review checks action readability, sensible material scale, adjustable low-level background music and a distinct dance cue; asset and device budgets are recorded separately." (REQ-009).** <!-- t:0adcb690 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Art and sound review checks action readability, sensible material scale, adjustable low-level background music and a distinct dance cue; asset and device budgets are recorded separately."
- [ ] **T11 — Implement: "The kit records mesh units, pivot/forward conventions, visual bounds, gameplay hulls, material scale and animation sockets; importing a revised model fails visibly when its required rig/socket contract is incompatible." (REQ-009).** <!-- t:a5a67e34 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "The kit records mesh units, pivot/forward conventions, visual bounds, gameplay hulls, material scale and animation sockets; importing a revised model fails visibly when its required rig/socket contract is incompatible." — possible coordination point: Contract "Approved Kit Entry v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T12 — Implement: "Approve one representative shore-to-underwater section with final lighting, material blends, silhouette variety and collision before extending the same treatment across all sections." (REQ-009).** <!-- t:e5a6a803 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-009 "Approve one representative shore-to-underwater section with final lighting, material blends, silhouette variety and collision before extending the same treatment across all sections."
- [ ] **T13 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

- With a parent, remix a small playable starter using the shared asset/gameplay kit, Codex and NodeSpec, previewing and iterating in Godot.
- A reusable Level Kit packages approved assets with materials, collision and supported gameplay behavior.

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-009: A reusable gameplay kit with coherent presentation
Category: functional | Status: pending
Give creators usable gameplay components rather than isolated meshes: terrain, water, enemies, checkpoints, pickups, gates, materials, lighting and audio with documented parameters.

**Acceptance criteria — your task boxes:**
- [ ] Each catalog entry has a stable ID/version, supported parameters, required dependencies, habitat/collision rules and rights/provenance metadata.
  → covered by Task T7
- [ ] Gameplay prefabs ship with appropriate collision, interaction volumes and bounded behavior; decorative motion cannot move gameplay collision.
  → covered by Task T8
- [ ] Land surfaces, shores, grass, rock, underwater depth gradients, waterfall origins, hero and enemies meet the starting-lagoon visual reference at gameplay distance without stretched pixelated textures or distracting repetition. (manual)
  → covered by Task T9
- [ ] Art and sound review checks action readability, sensible material scale, adjustable low-level background music and a distinct dance cue; asset and device budgets are recorded separately. (manual)
  → covered by Task T10
- [ ] The kit records mesh units, pivot/forward conventions, visual bounds, gameplay hulls, material scale and animation sockets; importing a revised model fails visibly when its required rig/socket contract is incompatible.
  → covered by Task T11
- [ ] Approve one representative shore-to-underwater section with final lighting, material blends, silhouette variety and collision before extending the same treatment across all sections. (manual)
  → covered by Task T12

## Interface Contracts

### RECEIVES FROM: Versioned World Runtime API (shared-library)
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

### RECEIVES FROM: Hero Motion & Animation (shared-library)
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

### RECEIVES FROM: Official Adventure: Lagoon & Living Cascade (shared-library)
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

### RECEIVES FROM: Family Workshop & Starter (cli-tool)
- **Contract:** Approved Kit Entry v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

### RECEIVES FROM: Content Export & Conformance (cli-tool)
- **Contract:** Approved Kit Entry v1
- **Protocol:** dependency
- **Spec Format:** json_schema
- **Their Technology:** python-backend

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

**Depends on THIS node being available:**
- Versioned World Runtime API (initiates Approved Kit Entry v1 against this node (dependency))
- Hero Motion & Animation (initiates Approved Kit Entry v1 against this node (dependency))
- Official Adventure: Lagoon & Living Cascade (initiates Approved Kit Entry v1 against this node (dependency))
- Family Workshop & Starter (initiates Approved Kit Entry v1 against this node (dependency))
- Content Export & Conformance (initiates Approved Kit Entry v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `assets/audio/exploration/provenance.json` | config | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_2.jpg.import` | config | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_normal.jpg` | design | --- | draft |
| `reference/coral_cove/README.md` | doc | --- | draft |
| `asset_inbox/.gdignore` | config | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_base_color.jpg` | design | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_base_color.jpg.import` | config | --- | draft |
| `core/rendering/terrain_surface.gdshader` | source | --- | draft |
| `core/audio/settings_store.gd.uid` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/facade_color.png.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/provenance.json` | config | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/prop/netbot/netbot.glb` | design | --- | draft |
| `assets/environment/cascade_cliff_garden/facade_depth.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_2.jpg` | design | --- | draft |
| `test/core/rendering/test_water_behaviour.gd.uid` | config | --- | draft |
| `tools/source_art/quiet_currents/drum-tree.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_0.jpg` | design | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_diff_2k.jpg.import` | config | --- | draft |
| `core/rendering/terrain_surface.gdshader.uid` | config | --- | draft |
| `assets/audio/cascade/gill_mod_bubble_activated.wav` | design | --- | draft |
| `core/rendering/terrain/forest_earth.tres` | source | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_base_color.jpg.import` | config | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_normal.jpg.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_arm_2k.png` | design | --- | draft |
| `assets/audio/cascade/capability_regrown_leg.wav.import` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/facade_color.png.import` | config | --- | draft |
| `core/rendering/water_surface.gdshader.uid` | config | --- | draft |
| `assets/audio/cascade/movement_hop.wav` | design | --- | draft |
| `assets/audio/cascade/crayfish_pickup.wav` | design | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_normal.jpg` | design | --- | draft |
| `core/rendering/world_lighting.gd.uid` | config | --- | draft |
| `core/rendering/cascade_collision/cliff_garden.res` | design | --- | draft |
| `assets/character/axolotl/axolotl_normal.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_0.jpg.import` | config | --- | draft |
| `assets/audio/cascade/landing.wav.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_normal.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_0.jpg` | design | --- | draft |
| `assets/character/axolotl/axolotl_base_color.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_wall/facade_depth.png` | design | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack.glb.import` | config | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_base_color.jpg` | design | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_base_color.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_1.jpg` | design | --- | draft |
| `assets/audio/cascade/capability_lost_gill.wav.import` | config | --- | draft |
| `assets/environment/canopy_tree/canopy_tree.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_2.jpg` | design | --- | draft |
| `assets/environment/cascade_bank_terrace/facade_depth.png.import` | config | --- | draft |
| `assets/environment/fallen_log/provenance.json` | config | --- | draft |
| `tools/source_art/crayfish_build_details.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch.glb.import` | config | --- | draft |
| `assets/audio/exploration/quiet_currents.ogg` | design | --- | draft |
| `tools/blender/build_explorer_backpack.py` | source | --- | draft |
| `assets/environment/river_reed/river_reed.glb` | design | --- | draft |
| `assets/prop/flagship/provenance.json` | config | --- | draft |
| `assets/prop/flagship/flagship.glb.import` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated.glb.import` | config | --- | draft |
| `asset_inbox/Meshy_AI_Verdant_Cliff_Garden_0913173327_texture-optimized.glb` | design | --- | draft |
| `asset_inbox/Meshy_AI_Coral_Reef_Ruins_0913200130_texture-optimized.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch.glb` | design | --- | draft |
| `core/rendering/terrain/coral_shelf_stone.tres` | source | --- | draft |
| `assets/environment/cascade_reef_wall/facade_color.png` | design | --- | draft |
| `assets/audio/cascade/region_resourced.wav` | design | --- | draft |
| `tools/test_scatter_props.py` | source | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch.glb.import` | config | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/provenance.json` | config | --- | draft |
| `core/rendering/water_trail.gd` | source | --- | draft |
| `tools/blender/lagoon_rock_variants.py` | source | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_arm_2k.png` | design | --- | draft |
| `test/core/rendering/test_world_dressing.gd.uid` | config | --- | draft |
| `assets/audio/cascade/tail_whack.wav.import` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_base_color.jpg.import` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/sources.json` | config | --- | draft |
| `assets/audio/cascade/net_escape.wav` | design | --- | draft |
| `assets/environment/river_boulder/provenance.json` | config | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_metallic_roughness.jpg.import` | config | --- | draft |
| `core/rendering/water_plane.tres` | source | --- | draft |
| `asset_inbox/Meshy_AI_Blooming_Woodland_Arc_0913173247_texture-optimized.glb` | design | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_base_color.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/cascade_surfaces/README.md` | doc | --- | draft |
| `core/rendering/cascade_collision/reef_wall.res` | design | --- | draft |
| `asset_inbox/Meshy_AI_Mossy_Stone_Island_0913173318_texture-optimized.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_2.jpg.import` | config | --- | draft |
| `assets/audio/cascade/movement_dive.wav` | design | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_base_color.jpg.import` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge.glb.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace.glb` | design | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_normal.jpg` | design | --- | draft |
| `core/rendering/terrain_shell.gd` | source | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_arm_2k.png` | design | --- | draft |
| `core/rendering/restoration_bloom.gd.uid` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_1.jpg.import` | config | --- | draft |
| `core/rendering/cascade_ground.gdshader` | source | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_nor_gl_2k.png.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_arm_2k.png.import` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_metallic_roughness.jpg` | design | --- | draft |
| `assets/prop/netbot/netbot_base_color.jpg` | design | --- | draft |
| `assets/audio/cascade/net_caught.wav.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden.glb` | design | --- | draft |
| `assets/environment/kelp_strand/kelp_strand.glb.import` | config | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_metallic_roughness.jpg.import` | config | --- | draft |
| `core/rendering/cascade_asset_visibility.gd` | source | --- | draft |
| `assets/character/axolotl/axolotl.glb` | design | --- | draft |
| `test/core/rendering/test_scatter_field.gd` | source | --- | draft |
| `reference/hero/pink_axolotl_2.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_diff_2k.jpg` | design | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_normal.jpg` | design | --- | draft |
| `core/rendering/cascade_collision/stone_ruins.res` | design | --- | draft |
| `core/rendering/cascade_collision/bank_terrace.res` | design | --- | draft |
| `assets/audio/cascade/grammar_land.wav` | design | --- | draft |
| `assets/prop/dredger/dredger_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_base_color.jpg` | design | --- | draft |
| `assets/character/axolotl/axolotl_skin_detail.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_1.jpg.import` | config | --- | draft |
| `assets/environment/seagrass_tuft/seagrass_tuft.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_1.jpg.import` | config | --- | draft |
| `assets/audio/cascade/capability_regrown_tail.wav` | design | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_base_color.jpg` | design | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_color.png.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/audio/cascade/gill_mod_jet_activated.wav` | design | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_diff_2k.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_ledge/facade_depth.png` | design | --- | draft |
| `tools/source_art/quiet_currents/download_drums.py` | source | --- | draft |
| `assets/audio/cascade/net_caught.wav` | design | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_diff_2k.jpg.import` | config | --- | draft |
| `asset_inbox/Meshy_AI_Coralvine_Arch_0913195214_texture-optimized.glb` | design | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_base_color.jpg.import` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/facade_color.png.import` | config | --- | draft |
| `assets/prop/flagship/flagship.glb` | design | --- | draft |
| `core/rendering/cascade_grass.gdshader.uid` | config | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_nor_gl_2k.png.import` | config | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_1.jpg.import` | config | --- | draft |
| `core/rendering/cascade_tunnel.gdshader.uid` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_color.png` | design | --- | draft |
| `tools/blender/lagoon_arch_passage.py` | source | --- | draft |
| `test/core/audio/test_audio_system.gd.uid` | config | --- | draft |
| `core/rendering/scatter_field.gd.uid` | config | --- | draft |
| `assets/environment/vertex_color_import.gd.uid` | config | --- | draft |
| `assets/prop/runoff_drone/runoff_drone.glb` | design | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_normal.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_0.jpg.import` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_roughness.png.import` | config | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated.glb` | design | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch.glb` | design | --- | draft |
| `assets/environment/cascade_reef_arch/provenance.json` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_normal.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_1.jpg` | design | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/cascade_bank_terrace/facade_depth.png` | design | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_normal.jpg.import` | config | --- | draft |
| `core/rendering/cascade_crown_state.gd.uid` | config | --- | draft |
| `assets/audio/cascade/dance_unlocked.wav.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/facade_depth.png.import` | config | --- | draft |
| `assets/prop/dredger/dredger.glb.import` | config | --- | draft |
| `assets/character/axolotl/axolotl.glb.import` | config | --- | draft |
| `assets/audio/cascade/tail_whack.wav` | design | --- | draft |
| `assets/environment/understory_fern/provenance.json` | config | --- | draft |
| `assets/audio/cascade/spin_charge.wav` | design | --- | draft |
| `tools/source_art/quiet_currents/download_samples.py` | source | --- | draft |
| `assets/environment/river_reed/river_reed.glb.import` | config | --- | draft |
| `core/rendering/cascade_mesh_field.gd.uid` | config | --- | draft |
| `assets/prop/hookline_rig/provenance.json` | config | --- | draft |
| `assets/character/axolotl/axolotl_skin_normal.png.import` | config | --- | draft |
| `assets/environment/canopy_tree/provenance.json` | config | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_1.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_0.jpg.import` | config | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_base_color.jpg` | design | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_roughness.png` | design | --- | draft |
| `assets/environment/cascade_crown_arch/provenance.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_2.jpg.import` | config | --- | draft |
| `assets/environment/fallen_log/fallen_log.glb.import` | config | --- | draft |
| `reference/coral_cove/Coral_Cove_River_Bank.glb` | design | --- | draft |
| `assets/environment/cascade_cliff_garden/facade_color.png.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster.glb.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_nor_gl_2k.png.import` | config | --- | draft |
| `assets/character/axolotl/axolotl_skin_detail.png.import` | config | --- | draft |
| `test/core/rendering/test_water_surface.gd` | source | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge.glb` | design | --- | draft |
| `assets/prop/hookline_rig_animated/provenance.json` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_base_color.jpg.import` | config | --- | draft |
| `core/audio/godot_audio_sink.gd.uid` | config | --- | draft |
| `assets/audio/cascade/capability_lost_tail.wav.import` | config | --- | draft |
| `core/rendering/water_splash.gd` | source | --- | draft |
| `assets/environment/canopy_tree/canopy_tree.glb` | design | --- | draft |
| `core/rendering/cascade_tunnel.gdshader` | source | --- | draft |
| `assets/prop/dredger/dredger_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_arm_2k.png.import` | config | --- | draft |
| `core/rendering/vegetation_wind.gdshader.uid` | config | --- | draft |
| `core/rendering/terrain/mossy_stone.tres` | source | --- | draft |
| `assets/audio/cascade/capability_lost_gill.wav` | design | --- | draft |
| `tools/source_art/.gdignore` | config | --- | draft |
| `test/core/rendering/test_render_quality.gd.uid` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/facade_color.png` | design | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall.glb` | design | --- | draft |
| `core/rendering/terrain_shell.gd.uid` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/audio/cascade/region_restored.wav.import` | config | --- | draft |
| `reference/hero/01_hero_perspective.png` | design | --- | draft |
| `core/rendering/cascade_ground.gdshader.uid` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_normal.jpg.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_base_color.jpg` | design | --- | draft |
| `core/rendering/cascade_terrain.gdshader.uid` | config | --- | draft |
| `assets/prop/hookline_rig/hookline_rig.glb` | design | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_base_color.jpg` | design | --- | draft |
| `assets/environment/canopy_grove/provenance.json` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_base_color.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_ledge/provenance.json` | config | --- | draft |
| `assets/prop/dredger/dredger.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_2.jpg` | design | --- | draft |
| `assets/environment/cascade_stone_ruins/facade_color.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_2.jpg` | design | --- | draft |
| `test/core/rendering/test_render_quality.gd` | source | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_base_color.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_1.jpg.import` | config | --- | draft |
| `assets/audio/cascade/movement_dive.wav.import` | config | --- | draft |
| `tools/source_art/quiet_currents/compose_exploration.py` | source | --- | draft |
| `tools/blender/prepare_lagoon_models.py` | source | --- | draft |
| `test/core/rendering/test_water_behaviour.gd` | source | --- | draft |
| `core/rendering/cascade_crown_state.gd` | source | --- | draft |
| `assets/audio/cascade/movement_swim_stroke.wav` | design | --- | draft |
| `assets/character/axolotl/axolotl_skin_normal.png` | design | --- | draft |
| `assets/prop/netbot/netbot_metallic_roughness.jpg` | design | --- | draft |
| `assets/prop/dredger/provenance.json` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_base_color.jpg.import` | config | --- | draft |
| `tools/blender/make_forest_kit.py` | source | --- | draft |
| `assets/environment/cascade_stone_ruins/facade_depth.png` | design | --- | draft |
| `core/audio/game_soundscape.gd` | source | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_normal.png.import` | config | --- | draft |
| `tools/test_shell_terrain.py` | source | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_2.jpg.import` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_metallic_roughness.jpg` | design | --- | draft |
| `assets/prop/netbot/netbot_base_color.jpg.import` | config | --- | draft |
| `tools/source_art/cascade_audio_analysis.json` | config | --- | draft |
| `core/rendering/water_depth_lighting.gd.uid` | config | --- | draft |
| `core/rendering/cascade_mesh_field.gd` | source | --- | draft |
| `core/rendering/terrain/river_sand.tres` | source | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_normal.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock.glb` | design | --- | draft |
| `tools/blender/decimate_model.py` | source | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_diff_2k.jpg` | design | --- | draft |
| `core/rendering/render_quality.gd` | source | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_base_color.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_1.jpg.import` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_color.png` | design | --- | draft |
| `assets/prop/netbot_animated/provenance.json` | config | --- | draft |
| `core/rendering/vegetation_wind.gdshader` | source | --- | draft |
| `core/rendering/cascade_terrain.gdshader` | source | --- | draft |
| `assets/prop/netbot/netbot.glb.import` | config | --- | draft |
| `core/rendering/base_environment.tres` | source | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall.glb.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden.glb.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_metallic_roughness.jpg` | design | --- | draft |
| `assets/audio/cascade/gill_mod_jet_activated.wav.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/asset-build.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_1.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_2.jpg` | design | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_top.png.import` | config | --- | draft |
| `assets/prop/dredger/dredger_normal.jpg` | design | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_base_color.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock.glb` | design | --- | draft |
| `assets/audio/cascade/crayfish_groove.wav` | design | --- | draft |
| `assets/audio/cascade/spin_charge.wav.import` | config | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_normal.jpg.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_normal.jpg` | design | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_base_color.jpg.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/provenance.json` | config | --- | draft |
| `reference/coral_cove/Coral_Cove_Canopy_Tree_2.glb` | design | --- | draft |
| `assets/audio/cascade/capability_regrown_gill.wav` | design | --- | draft |
| `assets/creature/glowing_crayfish/glowing_crayfish.glb.import` | config | --- | draft |
| `tools/test_fill_dressing.py` | source | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_normal.jpg` | design | --- | draft |
| `tools/blender/bake_hero_maps.py` | source | --- | draft |
| `reference/coral_cove/Coral_Cove_Canopy_Tree_1.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock.glb.import` | config | --- | draft |
| `assets/prop/netbot/netbot_normal.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_0.jpg` | design | --- | draft |
| `assets/audio/cascade/checkpoint.wav.import` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/audio/cascade/grammar_water.wav.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_normal.jpg.import` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_diff_2k.jpg.import` | config | --- | draft |
| `assets/audio/cascade/grammar_land.wav.import` | config | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch.glb` | design | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_normal.jpg` | design | --- | draft |
| `assets/environment/cascade_bank_terrace/facade_color.png.import` | config | --- | draft |
| `core/rendering/world_lighting.tscn` | source | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_base_color.jpg` | design | --- | draft |
| `core/rendering/scatter_field.gd` | source | --- | draft |
| `assets/audio/cascade/capability_regrown_tail.wav.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_0.jpg` | design | --- | draft |
| `tools/source_art/glowing_crayfish.blend` | design | --- | draft |
| `core/rendering/materials/forest_canopy.tres` | source | --- | draft |
| `assets/audio/cascade/movement_waddle_step.wav` | design | --- | draft |
| `core/rendering/terrain/river_stone.tres` | source | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_0.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_2.jpg` | design | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_base_color.jpg` | design | --- | draft |
| `reference/hero/pink_axolotl_2_reduced.glb` | design | --- | draft |
| `assets/environment/cascade_reef_wall/provenance.json` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/facade_color.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_0.jpg` | design | --- | draft |
| `assets/audio/cascade/provenance.json` | config | --- | draft |
| `assets/creature/glowing_crayfish/glowing_crayfish.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_2.jpg` | design | --- | draft |
| `tools/source_art/quiet_currents/drum_sample_license.txt` | doc | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_0.jpg` | design | --- | draft |
| `test/core/rendering/test_terrain_shell.gd.uid` | config | --- | draft |
| `assets/prop/netbot/netbot_normal.jpg.import` | config | --- | draft |
| `assets/audio/cascade/checkpoint.wav` | design | --- | draft |
| `core/rendering/water_trail.gd.uid` | config | --- | draft |
| `assets/audio/cascade/movement_hop.wav.import` | config | --- | draft |
| `assets/environment/sand_shelf_set/provenance.json` | config | --- | draft |
| `assets/audio/cascade/gill_mod_bubble_activated.wav.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_2.jpg` | design | --- | draft |
| `assets/audio/exploration/quiet_currents.ogg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_0.jpg.import` | config | --- | draft |
| `core/rendering/cascade_collision/crown_arch.res` | design | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_0.jpg` | design | --- | draft |
| `tools/decimate_model.py` | source | --- | draft |
| `assets/environment/cascade_root_bridge/provenance.json` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_roughness.png` | design | --- | draft |
| `assets/audio/cascade/crayfish_groove.wav.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/facade_depth.png.import` | config | --- | draft |
| `assets/audio/cascade/landing.wav` | design | --- | draft |
| `assets/environment/understory_fern/understory_fern.glb.import` | config | --- | draft |
| `assets/audio/cascade/dance_unlocked.wav` | design | --- | draft |
| `assets/environment/cascade_reef_wall/facade_color.png.import` | config | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_normal.jpg.import` | config | --- | draft |
| `core/rendering/world_lighting.gd` | source | --- | draft |
| `tools/test_decimate_model.py` | source | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_1.jpg.import` | config | --- | draft |
| `assets/audio/cascade/crayfish_pickup.wav.import` | config | --- | draft |
| `tools/build_enemy_animation_scenes.gd` | source | --- | draft |
| `assets/audio/cascade/cascade_exploration.wav` | design | --- | draft |
| `assets/audio/cascade/cascade_exploration.wav.import` | config | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_base_color.jpg.import` | config | --- | draft |
| `assets/character/axolotl/axolotl_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_normal.jpg.import` | config | --- | draft |
| `tools/source_art/quiet_currents/build_details.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/open_arch.glb.import` | config | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set.glb.import` | config | --- | draft |
| `assets/environment/coral_branch/coral_branch.glb.import` | config | --- | draft |
| `tools/source_art/quiet_currents/drum-manifest.json` | config | --- | draft |
| `assets/environment/rock_cluster/rock_cluster.glb.import` | config | --- | draft |
| `assets/creature/glowing_crayfish/provenance.json` | config | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_metallic_roughness.jpg` | design | --- | draft |
| `asset_inbox/Meshy_AI_Jungle_Stone_Terrace_0913173344_texture-optimized.glb` | design | --- | draft |
| `tools/blender/make_drift_fleet.py` | source | --- | draft |
| `assets/audio/cascade/slide.wav.import` | config | --- | draft |
| `assets/audio/cascade/region_restored.wav` | design | --- | draft |
| `reference/coral_cove/Hookline.glb` | design | --- | draft |
| `assets/environment/canopy_grove/canopy_grove.glb.import` | config | --- | draft |
| `core/audio/godot_audio_sink.gd` | source | --- | draft |
| `assets/environment/cascade_cliff_garden/facade_color.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/shore_rock_Image_0.jpg.import` | config | --- | draft |
| `assets/audio/cascade/net_escape.wav.import` | config | --- | draft |
| `assets/audio/cascade/movement_waddle_step.wav.import` | config | --- | draft |
| `assets/character/axolotl/axolotl_normal.jpg.import` | config | --- | draft |
| `core/rendering/water_surface.tres` | source | --- | draft |
| `assets/environment/river_boulder/river_boulder.glb.import` | config | --- | draft |
| `assets/character/axolotl/axolotl_metallic_roughness.jpg` | design | --- | draft |
| `assets/character/axolotl/provenance.json` | config | --- | draft |
| `core/audio/audio_settings.gd.uid` | config | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_metallic_roughness.jpg` | design | --- | draft |
| `assets/prop/hookline_rig_animated/hookline_rig_animated_normal.jpg.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace.glb.import` | config | --- | draft |
| `assets/environment/river_reed/provenance.json` | config | --- | draft |
| `assets/audio/cascade/movement_swim_stroke.wav.import` | config | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_base_color.jpg.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_diff_2k.jpg` | design | --- | draft |
| `core/audio/audio_event.gd` | source | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins_normal.jpg` | design | --- | draft |
| `test/core/rendering/test_water_surface.gd.uid` | config | --- | draft |
| `tools/source_art/quiet_currents/score-events.json` | config | --- | draft |
| `asset_inbox/Meshy_AI_Enchanted_Bloom_Arch_0913173256_texture-optimized.glb` | design | --- | draft |
| `tools/make_cascade_audio.py` | source | --- | draft |
| `assets/environment/cascade_mossy_stone/provenance.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock_Image_2.jpg.import` | config | --- | draft |
| `core/rendering/cascade_pbr_ground.gdshader` | source | --- | draft |
| `assets/environment/cascade_mossy_stone/facade_depth.png` | design | --- | draft |
| `assets/audio/cascade/capability_lost_leg.wav` | design | --- | draft |
| `assets/environment/understory_fern/understory_fern.glb` | design | --- | draft |
| `core/audio/default_bank.json` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/facade_depth.png.import` | config | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_base_color.jpg` | design | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_nor_gl_2k.png` | design | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_normal.jpg.import` | config | --- | draft |
| `assets/audio/cascade/region_barren.wav` | design | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_nor_gl_2k.png` | design | --- | draft |
| `core/audio/game_soundscape.gd.uid` | config | --- | draft |
| `tools/blender/make_axolotl.py` | source | --- | draft |
| `assets/environment/lagoon_meshy/flower_cluster_Image_1.jpg` | design | --- | draft |
| `test/core/rendering/test_world_lighting.gd.uid` | config | --- | draft |
| `core/rendering/render_quality.gd.uid` | config | --- | draft |
| `assets/audio/cascade/region_resourced.wav.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_1.jpg` | design | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall.glb` | design | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_normal.jpg` | design | --- | draft |
| `test/core/rendering/test_world_lighting.gd` | source | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch.glb.import` | config | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_normal.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/open_arch_Image_1.jpg` | design | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_normal.jpg` | design | --- | draft |
| `core/audio/audio_bank.gd.uid` | config | --- | draft |
| `test/core/rendering/test_terrain_shell_readability.gd` | source | --- | draft |
| `core/rendering/materials/axolotl_skin.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_eye.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_eye_gleam.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_gill.tres` | source | --- | draft |
| `core/rendering/materials/axolotl_detail.tres` | source | --- | draft |
| `tools/refine_model.py` | source | --- | draft |
| `tools/blender/refine_model.py` | source | --- | draft |
| `tools/test_refine_model.py` | source | --- | draft |
| `assets/environment/fallen_log/fallen_log.glb` | design | --- | draft |
| `tools/blender/make_glow_crayfish.py` | source | --- | draft |
| `core/audio/audio_sink.gd` | source | --- | draft |
| `reference/coral_cove/Netgrin_Salvage_Bot.glb` | design | --- | draft |
| `assets/environment/lagoon_meshy/coral_rock.glb.import` | config | --- | draft |
| `assets/environment/cascade_reef_wall/facade_depth.png.import` | config | --- | draft |
| `core/audio/audio_system.gd` | source | --- | draft |
| `assets/environment/cascade_surfaces/sand_01_arm_2k.png.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_nor_gl_2k.png` | design | --- | draft |
| `assets/environment/cascade_mossy_stone/facade_depth.png.import` | config | --- | draft |
| `assets/prop/dredger/dredger_base_color.jpg` | design | --- | draft |
| `assets/environment/cascade_reef_wall/reef_wall_normal.jpg` | design | --- | draft |
| `reference/README.md` | doc | --- | draft |
| `tools/source_art/quiet_currents/instrument_sample_license.txt` | doc | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_color.png.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_arm_2k.png.import` | config | --- | draft |
| `assets/prop/runoff_drone/provenance.json` | config | --- | draft |
| `core/rendering/cascade_collision/reef_arch.res` | design | --- | draft |
| `assets/environment/canopy_grove/canopy_grove.glb` | design | --- | draft |
| `assets/environment/cascade_cliff_garden/cliff_garden_base_color.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster.glb.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_arm_2k.png` | design | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_normal.png.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins.glb.import` | config | --- | draft |
| `assets/prop/netbot/netbot_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_0.jpg.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_arm_2k.png.import` | config | --- | draft |
| `assets/environment/vertex_color_import.gd` | source | --- | draft |
| `assets/environment/canopy_grove_tall/provenance.json` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone.glb` | design | --- | draft |
| `tools/source_art/quiet_currents/README.md` | doc | --- | draft |
| `tools/scatter_props.py` | source | --- | draft |
| `assets/environment/cascade_mossy_stone/facade_color.png` | design | --- | draft |
| `assets/prop/dredger/dredger_base_color.jpg.import` | config | --- | draft |
| `tools/shell_terrain.py` | source | --- | draft |
| `core/rendering/cascade_sheet.gdshader` | source | --- | draft |
| `assets/character/axolotl/axolotl_base_color.jpg.import` | config | --- | draft |
| `core/rendering/cascade_collision/reef_ledge.res` | design | --- | draft |
| `tools/blender/fit_hero_rig.py` | source | --- | draft |
| `asset_inbox/Reference Image_2_Level_1.png` | design | --- | draft |
| `assets/audio/cascade/slide.wav` | design | --- | draft |
| `assets/audio/cascade/gill_mod_glow_activated.wav` | design | --- | draft |
| `core/audio/audio_system.gd.uid` | config | --- | draft |
| `tools/source_art/quiet_currents/sample-tree.json` | config | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_nor_gl_2k.png` | design | --- | draft |
| `core/audio/settings_store.gd` | source | --- | draft |
| `test/core/audio/test_audio_system.gd` | source | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_normal.jpg.import` | config | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall.glb.import` | config | --- | draft |
| `core/rendering/presentation_motion.gd` | source | --- | draft |
| `tools/source_art/cascade_audio_build_details.json` | config | --- | draft |
| `assets/prop/dredger/dredger_normal.jpg.import` | config | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_base_color.jpg` | design | --- | draft |
| `reference/.gdignore` | config | --- | draft |
| `assets/prop/hookline_rig/hookline_rig_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/open_arch.glb` | design | --- | draft |
| `assets/prop/netbot/provenance.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/waterfall_arch_Image_1.jpg` | design | --- | draft |
| `test/core/rendering/test_terrain_shell_readability.gd.uid` | config | --- | draft |
| `assets/prop/runoff_drone/runoff_drone.glb.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_2.jpg.import` | config | --- | draft |
| `core/rendering/presentation_motion.gd.uid` | config | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Leather_saddle_roughness.png.import` | config | --- | draft |
| `core/rendering/restoration_bloom.gd` | source | --- | draft |
| `core/rendering/cascade_sheet.gdshader.uid` | config | --- | draft |
| `core/audio/audio_sink.gd.uid` | config | --- | draft |
| `assets/audio/cascade/region_barren.wav.import` | config | --- | draft |
| `asset_inbox/Meshy_AI_Blooming_Stone_Ruins_0913173308_texture-optimized.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_diff_2k.jpg.import` | config | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone.glb.import` | config | --- | draft |
| `core/rendering/cascade_collision/root_bridge.res` | design | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_stone_normal.jpg.import` | config | --- | draft |
| `assets/audio/cascade/gill_mod_glow_activated.wav.import` | config | --- | draft |
| `core/rendering/water_surface.gdshader` | source | --- | draft |
| `tools/blender/make_environment_kit.py` | source | --- | draft |
| `test/core/rendering/test_world_dressing.gd` | source | --- | draft |
| `assets/environment/rock_cluster/rock_cluster.glb` | design | --- | draft |
| `assets/environment/rock_cluster/provenance.json` | config | --- | draft |
| `assets/environment/coral_branch/coral_branch.glb` | design | --- | draft |
| `assets/environment/coral_branch/provenance.json` | config | --- | draft |
| `assets/environment/kelp_strand/kelp_strand.glb` | design | --- | draft |
| `assets/environment/kelp_strand/provenance.json` | config | --- | draft |
| `assets/environment/seagrass_tuft/seagrass_tuft.glb` | design | --- | draft |
| `assets/environment/seagrass_tuft/provenance.json` | config | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_nor_gl_2k.png` | design | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_bank_terrace/bank_terrace_metallic_roughness.jpg` | design | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_normal.jpg` | design | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge.glb.import` | config | --- | draft |
| `reference/coral_cove/Dredger_Rustbreaker.glb` | design | --- | draft |
| `tools/source_art/quiet_currents/samples-manifest.json` | config | --- | draft |
| `core/audio/audio_settings.gd` | source | --- | draft |
| `assets/environment/cascade_mossy_stone/mossy_top.png` | design | --- | draft |
| `core/rendering/water_ripple.gdshader.uid` | config | --- | draft |
| `assets/environment/river_boulder/river_boulder.glb` | design | --- | draft |
| `core/rendering/cascade_collision/mossy_stone.res` | design | --- | draft |
| `assets/audio/cascade/capability_lost_leg.wav.import` | config | --- | draft |
| `assets/environment/cascade_stone_ruins/stone_ruins.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/rock_face_03_nor_gl_2k.png.import` | config | --- | draft |
| `core/audio/audio_event.gd.uid` | config | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock.glb` | design | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_diff_2k.jpg.import` | config | --- | draft |
| `test/core/rendering/test_terrain_shell.gd` | source | --- | draft |
| `assets/audio/cascade/capability_lost_tail.wav` | design | --- | draft |
| `assets/audio/cascade/grammar_water.wav` | design | --- | draft |
| `assets/environment/cascade_surfaces/leafy_grass_nor_gl_2k.png.import` | config | --- | draft |
| `assets/environment/cascade_surfaces/dry_river_pebbles_arm_2k.png` | design | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_2.jpg.import` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_base_color.jpg` | design | --- | draft |
| `asset_inbox/Meshy_AI_Coral_Reef_Ledge_0913195229_texture-optimized.glb` | design | --- | draft |
| `test/core/rendering/test_water_boundary_alignment.gd.uid` | config | --- | draft |
| `core/rendering/cascade_asset_visibility.gd.uid` | config | --- | draft |
| `assets/prop/hookline_rig/hookline_rig.glb.import` | config | --- | draft |
| `assets/environment/cascade_reef_arch/reef_arch_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_normal.jpg.import` | config | --- | draft |
| `assets/audio/cascade/capability_regrown_leg.wav` | design | --- | draft |
| `core/audio/audio_bank.gd` | source | --- | draft |
| `assets/environment/cascade_reef_ledge/reef_ledge_metallic_roughness.jpg.import` | config | --- | draft |
| `core/rendering/cascade_pbr_ground.gdshader.uid` | config | --- | draft |
| `tools/blender/rig_model.py` | source | --- | draft |
| `tools/rig_model.py` | source | --- | draft |
| `assets/environment/cascade_root_bridge/root_bridge_metallic_roughness.jpg` | design | --- | draft |
| `tools/source_art/quiet_currents/analysis.json` | config | --- | draft |
| `tools/blender/prepare_enemy_animation_parts.py` | source | --- | draft |
| `assets/environment/sand_shelf_set/sand_shelf_set_metallic_roughness.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/cliff_rock_Image_0.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/README.md` | doc | --- | draft |
| `core/rendering/water_ripple.gdshader` | source | --- | draft |
| `assets/environment/cascade_surfaces/mossy_rock_diff_2k.jpg` | design | --- | draft |
| `assets/environment/canopy_grove/canopy_grove_metallic_roughness.jpg` | design | --- | draft |
| `core/rendering/water_depth_lighting.gd` | source | --- | draft |
| `assets/character/explorer_backpack/explorer_backpack_Canvas_olive_normal.png` | design | --- | draft |
| `tools/fill_dressing.py` | source | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_0.jpg` | design | --- | draft |
| `assets/character/explorer_backpack/provenance.json` | config | --- | draft |
| `assets/environment/lagoon_meshy/bank_rock_Image_2.jpg.import` | config | --- | draft |
| `assets/environment/lagoon_meshy/boulder_cluster_Image_1.jpg` | design | --- | draft |
| `core/rendering/cascade_grass.gdshader` | source | --- | draft |
| `core/rendering/water_splash.gd.uid` | config | --- | draft |
| `assets/audio/cascade/capability_regrown_gill.wav.import` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated_normal.jpg.import` | config | --- | draft |
| `assets/prop/netbot_animated/netbot_animated.glb` | design | --- | draft |
| `test/core/rendering/test_scatter_field.gd.uid` | config | --- | draft |
| `assets/environment/canopy_grove_tall/canopy_grove_tall_normal.jpg.import` | config | --- | draft |
| `test/core/rendering/test_water_boundary_alignment.gd` | source | --- | draft |
| `assets/environment/cascade_crown_arch/crown_arch_base_color.jpg.import` | config | --- | draft |
