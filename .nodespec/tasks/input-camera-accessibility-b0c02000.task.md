# Task: Input, Camera & Accessibility

> **Scope:** implement ONLY this node ("Input, Camera & Accessibility"). Work belonging to other nodes appears here solely as interfaces and coordination points — do not implement or re-derive it.
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
- [ ] **T2 — Expose the interface Hero Motion & Animation consumes, per Contract "Semantic Input Frame v1" (dependency).** <!-- t:76c0e689 -->
  Record the endpoint/identifiers Hero Motion & Animation needs in this node's config artifacts — coordinate with Hero Motion & Animation.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T3 — Expose the interface OpenAxolotl Game Shell consumes, per Contract "Semantic Input Frame v1" (dependency).** <!-- t:9867c53a -->
  Record the endpoint/identifiers OpenAxolotl Game Shell needs in this node's config artifacts — coordinate with OpenAxolotl Game Shell.
  Dependency contract — capture the reference/identifier wiring in this node's config artifacts; no payload schema expected.
- [ ] **T4 — Implement: "Every mandatory action is available on keyboard/mouse and gamepad; remapped inputs update the prompts." (REQ-003).** <!-- t:04ad802f -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Every mandatory action is available on keyboard/mouse and gamepad; remapped inputs update the prompts." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) from OpenAxolotl Game Shell (keyword signal only)
- [ ] **T5 — Implement: "The follow camera handles terrain obstruction and underwater passages without clipping through blocking geometry or losing the player." (REQ-003).** <!-- t:58f84152 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "The follow camera handles terrain obstruction and underwater passages without clipping through blocking geometry or losing the player."
- [ ] **T6 — Implement: "Mandatory routes, enemy warnings and restoration changes remain understandable without relying only on color or audio; music/effects volume and reduced-motion options are reviewed." (REQ-003).** <!-- t:12d992f4 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Mandatory routes, enemy warnings and restoration changes remain understandable without relying only on color or audio; music/effects volume and reduced-motion options are reviewed." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T7 — Implement: "Input is sampled independently of presentation, normalized to semantic actions and consumed once per physics tick; dead zones, remapping and focus loss cannot create repeated presses or stuck movement." (REQ-003).** <!-- t:c4c21b6a -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Input is sampled independently of presentation, normalized to semantic actions and consumed once per physics tick; dead zones, remapping and focus loss cannot create repeated presses or stuck movement." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T8 — Implement: "Camera collision and framing use the same reference traversal through the inlet, root tunnel and terrace edges; changing render FPS cannot create a one-frame camera teleport except an explicit respawn cut." (REQ-003).** <!-- t:29fb80a8 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Camera collision and framing use the same reference traversal through the inlet, root tunnel and terrace edges; changing render FPS cannot create a one-frame camera teleport except an explicit respawn cut." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T9 — Implement: "Approve controller feel and camera framing in the same character reel, including a reduced-motion profile, before expanding world dressing." (REQ-003).** <!-- t:8779fa87 -->
  No interface contract maps to this criterion — it is this node's internal responsibility.
  ↳ serves: REQ-003 "Approve controller feel and camera framing in the same character reel, including a reduced-motion profile, before expanding world dressing." — possible coordination point: Contract "Semantic Input Frame v1" (dependency) from Hero Motion & Animation (keyword signal only)
- [ ] **T10 — Verify every acceptance criterion above and tick its box.** <!-- t:7cb6cb39 -->
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

### REQ-003: Readable camera, controls and accessible feedback
Category: functional | Status: pending
Support keyboard/mouse and gamepad on desktop with clear camera framing, input prompts and multiple feedback channels.

**Acceptance criteria — your task boxes:**
- [ ] Every mandatory action is available on keyboard/mouse and gamepad; remapped inputs update the prompts.
  → covered by Task T4
- [ ] The follow camera handles terrain obstruction and underwater passages without clipping through blocking geometry or losing the player.
  → covered by Task T5
- [ ] Mandatory routes, enemy warnings and restoration changes remain understandable without relying only on color or audio; music/effects volume and reduced-motion options are reviewed. (manual)
  → covered by Task T6
- [ ] Input is sampled independently of presentation, normalized to semantic actions and consumed once per physics tick; dead zones, remapping and focus loss cannot create repeated presses or stuck movement.
  → covered by Task T7
- [ ] Camera collision and framing use the same reference traversal through the inlet, root tunnel and terrace edges; changing render FPS cannot create a one-frame camera teleport except an explicit respawn cut.
  → covered by Task T8
- [ ] Approve controller feel and camera framing in the same character reel, including a reduced-motion profile, before expanding world dressing. (manual)
  → covered by Task T9

## Interface Contracts

### RECEIVES FROM: Hero Motion & Animation (shared-library)
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

### RECEIVES FROM: OpenAxolotl Game Shell (game-client)
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

## Technology Guidance

_Catalog guidance suppressed for this node (metadata.suppressCatalogGuidance) — the project's own rulings in ## Implementation Context and the requirements govern. Re-enable by removing the flag._

## Dependency Chain

Startup/initialization order based on edge directions and interaction patterns.

**Depends on THIS node being available:**
- Hero Motion & Animation (initiates Semantic Input Frame v1 against this node (dependency))
- OpenAxolotl Game Shell (initiates Semantic Input Frame v1 against this node (dependency))

## Existing Implementation

| File | Kind | Language | Status |
|------|------|----------|--------|
| `hub/hud/player_hud.gd.uid` | config | --- | draft |
| `core/camera/camera_occluder_probe.gd` | source | --- | draft |
| `core/input/input_error.gd` | source | --- | draft |
| `core/camera/scene_occluder_probe.gd` | source | --- | draft |
| `test/core/camera/test_look_input.gd` | source | --- | draft |
| `test/core/camera/test_look_input.gd.uid` | config | --- | draft |
| `core/input/input_verb.gd` | source | --- | draft |
| `core/camera/camera_hint_volume.gd` | source | --- | draft |
| `core/camera/camera_rig.gd` | source | --- | draft |
| `core/input/binding_context.gd.uid` | config | --- | draft |
| `core/input/binding_context.gd` | source | --- | draft |
| `test/core/camera/test_camera_rig.gd` | source | --- | draft |
| `core/camera/camera_hint.gd.uid` | config | --- | draft |
| `hub/hud/player_hud.gd` | source | --- | draft |
| `core/camera/look_input.gd` | source | --- | draft |
| `core/input/input_device.gd` | source | --- | draft |
| `core/input/input_binding.gd` | source | --- | draft |
| `core/camera/camera_rig.gd.uid` | config | --- | draft |
| `core/camera/scene_occluder_probe.gd.uid` | config | --- | draft |
| `core/input/binding_table.gd` | source | --- | draft |
| `core/input/default_bindings.json` | config | --- | draft |
| `core/camera/camera_framing.gd` | source | --- | draft |
| `core/camera/look_input.gd.uid` | config | --- | draft |
| `core/input/input_device.gd.uid` | config | --- | draft |
| `core/input/input_system.gd` | source | --- | draft |
| `core/input/input_error.gd.uid` | config | --- | draft |
| `core/camera/camera_occluder_probe.gd.uid` | config | --- | draft |
| `core/camera/camera_hint.gd` | source | --- | draft |
| `test/core/input/test_input_system.gd` | source | --- | draft |
| `test/core/input/test_input_system.gd.uid` | config | --- | draft |
| `core/camera/camera_hint_stack.gd.uid` | config | --- | draft |
| `core/camera/camera_hint_stack.gd` | source | --- | draft |
| `test/hub/test_player_hud.gd` | source | --- | draft |
| `core/camera/camera_follow.gd.uid` | config | --- | draft |
| `test/hub/test_player_hud.gd.uid` | config | --- | draft |
| `core/camera/camera_framing.gd.uid` | config | --- | draft |
| `core/input/binding_table.gd.uid` | config | --- | draft |
| `core/input/input_binding.gd.uid` | config | --- | draft |
| `core/camera/camera_follow.gd` | source | --- | draft |
| `test/core/camera/test_camera_rig.gd.uid` | config | --- | draft |
| `core/input/input_verb.gd.uid` | config | --- | draft |
| `core/input/input_system.gd.uid` | config | --- | draft |
| `core/camera/camera_hint_volume.gd.uid` | config | --- | draft |
