# Task: Hero Motion & Animation

> **Scope:** implement ONLY this node ("Hero Motion & Animation"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Implement the integration with Input, Camera & Accessibility (godot) per Contract "Semantic Input Frame v1" (dependency).** <!-- t:bb26635f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Implement the integration with Reusable Level & Asset Kit (godot) per Contract "Approved Kit Entry v1" (dependency).** <!-- t:8692c42f -->
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Expose the interface Drift Fleet Encounters consumes, per Contract "Hero Motion and Action Snapshot v1" (dependency).** <!-- t:d9b523c8 -->
  Record the endpoint/identifiers Drift Fleet Encounters needs in this node's config artifacts — coordinate with Drift Fleet Encounters.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T5 — Expose the interface Versioned World Runtime API consumes, per Contract "Hero Motion and Action Snapshot v1" (dependency).** <!-- t:b6a706a0 -->
  Record the endpoint/identifiers Versioned World Runtime API needs in this node's config artifacts — coordinate with Versioned World Runtime API.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T6 — Implement: "Land/water transitions retain the configured momentum, keep collision and visual pose aligned, and do not leave the player in the wrong movement grammar." (REQ-002).** <!-- t:691ce13d -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Land/water transitions retain the configured momentum, keep collision and visual pose aligned, and do not leave the player in the wrong movement grammar." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T7 — Implement: "Movement and facing accelerate and decelerate continuously at 30, 60 and 120 Hz; a swimming reversal turns through a bounded arc instead of snapping." (REQ-002).** <!-- t:5d9323f9 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Movement and facing accelerate and decelerate continuously at 30, 60 and 120 Hz; a swimming reversal turns through a bounded arc instead of snapping." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T8 — Implement: "Swimming folds the feet toward the body with a traveling body/tail wave; underwater idle preserves gentle foot motion; tail whack visibly reaches forward and has a bounded hit window." (REQ-002).** <!-- t:d4b5447a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Swimming folds the feet toward the body with a traveling body/tail wave; underwater idle preserves gentle foot motion; tail whack visibly reaches forward and has a bounded hit window." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T9 — Implement: "Review walking, hopping, climbing, swimming, turning, tail whack and spin charge in the production camera; underwater spin bubbles/current and land-slide surface disturbance communicate the action without obscuring threats." (REQ-002).** <!-- t:a159cffd -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Review walking, hopping, climbing, swimming, turning, tail whack and spin charge in the production camera; underwater spin bubbles/current and land-slide surface disturbance communicate the action without obscuring threats." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T10 — Implement: "The character has exactly one authoritative physics-root writer; animation, backpack and surface effects cannot change the collision root, damage reach or movement velocity." (REQ-002).** <!-- t:cfaeac8e -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "The character has exactly one authoritative physics-root writer; animation, backpack and surface effects cannot change the collision root, damage reach or movement velocity." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T11 — Implement: "At a fixed 60 Hz physics step, the same timed input replay rendered at 30, 60 and 120 FPS finishes within 5 percent of reference travel distance and 5 degrees of reference heading, with identical action and checkpoint events." (REQ-002).** <!-- t:34fb634b -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "At a fixed 60 Hz physics step, the same timed input replay rendered at 30, 60 and 120 FPS finishes within 5 percent of reference travel distance and 5 degrees of reference heading, with identical action and checkpoint events." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T12 — Implement: "Allowed locomotion inputs affect simulation within two physics ticks; buffered jump and interruption windows are configurable and tests cover their boundary ticks." (REQ-002).** <!-- t:fdf4d565 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Allowed locomotion inputs affect simulation within two physics ticks; buffered jump and interruption windows are configurable and tests cover their boundary ticks." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) to Input, Camera & Accessibility (keyword signal only)
- [ ] **T13 — Implement: "A versioned animation transition table covers idle, start, travel, turn, stop, jump, fall, land, swim, surface, dive, attack, capture, dance and reset; every allowed edge exits without a stuck pose, duplicate action event or stale blend." (REQ-002).** <!-- t:bd9aa3b2 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "A versioned animation transition table covers idle, start, travel, turn, stop, jump, fall, land, swim, surface, dive, attack, capture, dance and reset; every allowed edge exits without a stuck pose, duplicate action event or stale blend." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Versioned World Runtime API (keyword signal only)
- [ ] **T14 — Implement: "Audit and approve the production rig, skin weights, clip coverage and contact chains; document whether each limb supports planted-foot solving and replace the current one-joint limb limitation before promising full foot locking." (REQ-002).** <!-- t:2f75d092 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Audit and approve the production rig, skin weights, clip coverage and contact chains; document whether each limb supports planted-foot solving and replace the current one-joint limb limitation before promising full foot locking." — possible coordination point: Contract "Hero Motion and Action Snapshot v1" (dependency) from Drift Fleet Encounters (keyword signal only)
- [ ] **T15 — Implement: "Approve a fixed production-camera reel at normal speed and slow motion covering starts, stops, reversals, slopes, landing, swimming transitions and moving attacks; resolve visible foot sliding, snapping, broken deformation and mechanical body/tail motion before declaring the character-polish milestone complete." (REQ-002).** <!-- t:a767140a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-002 "Approve a fixed production-camera reel at normal speed and slow motion covering starts, stops, reversals, slopes, landing, swimming transitions and moving attacks; resolve visible foot sliding, snapping, broken deformation and mechanical body/tail motion before declaring the character-polish milestone complete." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) to Input, Camera & Accessibility (keyword signal only)
- [ ] **T16 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

The whole vision is one read away: get_outcome_board lists every sentence with its id.

## Requirements — Your Scope

### REQ-002: Expressive, smooth axolotl movement and animation
Category: functional | Status: pending
Retain the character's distinct land and water movement, responsive transitions and readable actions. Polish is measured through motion continuity and play review rather than a claim of parity with Astro Bot.

**Acceptance criteria — your task boxes:**
- [ ] Land/water transitions retain the configured momentum, keep collision and visual pose aligned, and do not leave the player in the wrong movement grammar.
  → covered by Task T6
- [ ] Movement and facing accelerate and decelerate continuously at 30, 60 and 120 Hz; a swimming reversal turns through a bounded arc instead of snapping.
  → covered by Task T7
- [ ] Swimming folds the feet toward the body with a traveling body/tail wave; underwater idle preserves gentle foot motion; tail whack visibly reaches forward and has a bounded hit window.
  → covered by Task T8
- [ ] Review walking, hopping, climbing, swimming, turning, tail whack and spin charge in the production camera; underwater spin bubbles/current and land-slide surface disturbance communicate the action without obscuring threats. (manual)
  → covered by Task T9
- [ ] The character has exactly one authoritative physics-root writer; animation, backpack and surface effects cannot change the collision root, damage reach or movement velocity.
  → covered by Task T10
- [ ] At a fixed 60 Hz physics step, the same timed input replay rendered at 30, 60 and 120 FPS finishes within 5 percent of reference travel distance and 5 degrees of reference heading, with identical action and checkpoint events.
  → covered by Task T11
- [ ] Allowed locomotion inputs affect simulation within two physics ticks; buffered jump and interruption windows are configurable and tests cover their boundary ticks.
  → covered by Task T12
- [ ] A versioned animation transition table covers idle, start, travel, turn, stop, jump, fall, land, swim, surface, dive, attack, capture, dance and reset; every allowed edge exits without a stuck pose, duplicate action event or stale blend.
  → covered by Task T13
- [ ] Audit and approve the production rig, skin weights, clip coverage and contact chains; document whether each limb supports planted-foot solving and replace the current one-joint limb limitation before promising full foot locking. (manual)
  → covered by Task T14
- [ ] Approve a fixed production-camera reel at normal speed and slow motion covering starts, stops, reversals, slopes, landing, swimming transitions and moving attacks; resolve visible foot sliding, snapping, broken deformation and mechanical body/tail motion before declaring the character-polish milestone complete. (manual)
  → covered by Task T15

## Interface Contracts

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

### RECEIVES FROM: Drift Fleet Encounters (shared-library)
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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Must be available BEFORE this node starts:**
- Input, Camera & Accessibility (this node calls/depends on it via Semantic Input Frame v1 (dependency))
- Reusable Level & Asset Kit (this node calls/depends on it via Approved Kit Entry v1 (dependency))

**Depends on THIS node being available:**
- Drift Fleet Encounters (initiates Hero Motion and Action Snapshot v1 against this node (dependency))
- Versioned World Runtime API (initiates Hero Motion and Action Snapshot v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `test/core/controller/test_axolotl_body_scene.gd.uid` | config | --- | draft |
| `core/rendering/hero_animator.gd.uid` | config | --- | draft |
| `core/controller/jump_feel.gd.uid` | config | --- | draft |
| `core/controller/water_dash.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_surface.gd` | source | --- | draft |
| `core/controller/axolotl_body.gd.uid` | config | --- | draft |
| `core/controller/bubble_boost.gd` | source | --- | draft |
| `core/controller/tongue_grapple.gd.uid` | config | --- | draft |
| `test/core/controller/test_movement_polish.gd` | source | --- | draft |
| `core/controller/player_intent.gd.uid` | config | --- | draft |
| `core/controller/climb_surface.gd.uid` | config | --- | draft |
| `docs/character-movement-polish.md` | doc | --- | draft |
| `core/controller/climb_surface.gd` | source | --- | draft |
| `test/core/controller/test_hero_squash.gd.uid` | config | --- | draft |
| `test/core/controller/test_camera_relative_movement.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_backpack.gd` | source | --- | draft |
| `core/controller/water_volume.gd.uid` | config | --- | draft |
| `core/controller/grapple_anchor.gd` | source | --- | draft |
| `core/controller/burst_move.gd` | source | --- | draft |
| `test/core/controller/test_jump_feel.gd` | source | --- | draft |
| `core/rendering/hero_slide_scuff.gdshader.uid` | config | --- | draft |
| `docs/hero-backpack-flat-notes.md` | doc | --- | draft |
| `core/rendering/hero_slide_scuff.gdshader` | source | --- | draft |
| `core/controller/anchor_source.gd` | source | --- | draft |
| `core/controller/combat_strike.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_skin.gd.uid` | config | --- | draft |
| `core/rendering/hero_footprint.gdshader` | source | --- | draft |
| `core/controller/scene_anchor_source.gd.uid` | config | --- | draft |
| `core/controller/movement_grammar.gd.uid` | config | --- | draft |
| `test/core/controller/test_movement_polish.gd.uid` | config | --- | draft |
| `core/controller/scene_anchor_source.gd` | source | --- | draft |
| `core/controller/channel_profile.gd` | source | --- | draft |
| `core/controller/bubble_boost.gd.uid` | config | --- | draft |
| `core/rendering/hero_surface_effects.gd` | source | --- | draft |
| `test/core/controller/test_axolotl_body_scene.gd` | source | --- | draft |
| `core/controller/burst_move.gd.uid` | config | --- | draft |
| `test/core/controller/test_jump_feel.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_surface.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_animator.gd.uid` | config | --- | draft |
| `core/rendering/hero_skin.gd.uid` | config | --- | draft |
| `core/controller/combat_strike.gd` | source | --- | draft |
| `core/controller/channel_water_volume.gd` | source | --- | draft |
| `HERO-ANIMATION.md` | doc | --- | draft |
| `core/controller/axolotl_controller.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_motion.gd` | source | --- | draft |
| `core/controller/jump_feel.gd` | source | --- | draft |
| `core/rendering/hero_action_clips.gd` | source | --- | draft |
| `core/rendering/hero_dance_clips.gd` | source | --- | draft |
| `core/controller/capability_modifiers.gd` | source | --- | draft |
| `core/controller/axolotl_body.gd` | source | --- | draft |
| `core/rendering/hero_motion.gd.uid` | config | --- | draft |
| `docs/hero-mobile-feasibility.md` | doc | --- | draft |
| `core/rendering/hero_dance_clips.gd.uid` | config | --- | draft |
| `core/controller/channel_water_volume.gd.uid` | config | --- | draft |
| `core/controller/channel_profile.gd.uid` | config | --- | draft |
| `core/controller/water_dash.gd` | source | --- | draft |
| `core/controller/water_volume.gd` | source | --- | draft |
| `test/core/rendering/test_hero_backpack.gd.uid` | config | --- | draft |
| `core/controller/capability_modifiers.gd.uid` | config | --- | draft |
| `core/rendering/hero_motion.gd` | source | --- | draft |
| `test/core/controller/test_combat_verbs.gd` | source | --- | draft |
| `core/controller/grapple_anchor.gd.uid` | config | --- | draft |
| `core/rendering/hero_skin.gd` | source | --- | draft |
| `test/core/rendering/test_hero_skin.gd` | source | --- | draft |
| `core/controller/hero_squash.gd` | source | --- | draft |
| `test/core/controller/test_hero_squash.gd` | source | --- | draft |
| `test/core/rendering/test_hero_anatomy.gd` | source | --- | draft |
| `core/controller/tongue_grapple.gd` | source | --- | draft |
| `docs/hero-backpack-implementation.md` | doc | --- | draft |
| `core/controller/hero_squash.gd.uid` | config | --- | draft |
| `core/controller/axolotl_body.tscn` | source | --- | draft |
| `test/core/controller/test_camera_relative_movement.gd` | source | --- | draft |
| `test/core/controller/test_axolotl_controller.gd.uid` | config | --- | draft |
| `core/controller/axolotl_controller.gd` | source | --- | draft |
| `test/core/controller/test_combat_verbs.gd.uid` | config | --- | draft |
| `test/core/rendering/test_hero_motion.gd.uid` | config | --- | draft |
| `core/controller/anchor_source.gd.uid` | config | --- | draft |
| `core/rendering/hero_surface_effects.gd.uid` | config | --- | draft |
| `core/controller/movement_grammar.gd` | source | --- | draft |
| `docs/hero-animation-notes.md` | doc | --- | draft |
| `test/core/rendering/test_hero_anatomy.gd.uid` | config | --- | draft |
| `test/core/controller/test_axolotl_controller.gd` | source | --- | draft |
| `core/rendering/hero_action_clips.gd.uid` | config | --- | draft |
| `core/rendering/hero_backpack.gd.uid` | config | --- | draft |
| `core/controller/player_intent.gd` | source | --- | draft |
| `core/rendering/hero_animator.gd` | source | --- | draft |
| `test/core/rendering/test_hero_animator.gd` | test-plan | --- | draft |
| `core/rendering/hero_footprint.gdshader.uid` | config | --- | draft |
| `core/rendering/hero_backpack.gd` | source | --- | draft |
