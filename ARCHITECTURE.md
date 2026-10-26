# OpenAxolotl — Architecture Reference

Generated from the supplied [NodeSpec architecture export](architecture.json).

Exported: `2026-10-26T19:02:23.836Z` · schema version `8` · graph hash `2b85ed1a`.

## Authority and scope

This reference replaces the retired 25-component architecture overview. It describes the agreed target architecture and maps existing implementation to its owners; it does not claim the target behavior is implemented or tested.

The JSON is preserved byte-for-byte as the supplied export. Its embedded artifacts are a point-in-time snapshot and may include historical source documents. This root JSON is not the native `.nodespec/model.json` or `.nodespec/spec.json` format. Those repository anchors still require a separate authoritative NodeSpec export; do not import the older anchors back over the current project.

Workflow definitions and the accepted work-plan ordering are not included as top-level fields in this export. The live NodeSpec project remains authoritative for those relationships. Task and test document contents are embedded under `artifacts`; the paths shown there are not a claim that the corresponding updated native files have already been exported to this repository.

## Product intent

OpenAxolotl is a joyful single-player adventure game where families explore and restore imaginative worlds, then create adventures of their own together. A shared library of polished characters, environments and mechanics helps turn their ideas into playable levels. Reviewed community adventures become new destinations for everyone to explore.

THE GAME COMES FIRST. Children should enjoy the shipped game without creating anything or needing an AI account. Our axolotl's expressive movement, land-and-water traversal, readable robot encounters, discoveries and restoration rewards create the sense of adventure. Astro Bot inspires pacing, clarity and responsiveness; matching another game's production quality is an aspiration, not an unmeasured acceptance claim.

PLAY, CREATE, SHARE. Play official adventures. With a parent, remix a small playable starter using the shared asset/gameplay kit, Codex and NodeSpec, previewing and iterating in Godot. Direct Godot editing remains supported. Submit a level for automated checks and human review; approved, versioned adventures can be downloaded and played through the hub. Creation is optional, parent-led for young children, and separate from the child-facing game.

FOUR RESPONSIBILITIES. Core game systems own the hero, movement, camera, combat, regeneration/capabilities, checkpoints, saves, restoration, collectibles, audio and common enemy behaviors. A reusable Level Kit packages approved assets with materials, collision and supported gameplay behavior. Individual levels own layout, placements, objectives and presentation configuration. Authoring and distribution own the starter workflow, export/validation, review, curated catalog and package lifecycle. Levels use a small versioned public World API; shared code contains no hardcoded coordinates for a particular world.

CONTENT EXTENSIONS. Local authoring may use code and Godot scenes. Published downloadable level packages contain only supported declarative content and approved component/asset references. Arbitrary scripts, native extensions and executable scene resources are excluded from that package format. New powers or enemy logic that require executable changes are separately reviewed core contributions. The package schema and loader must be designed and tested; this is a target architecture, not a claim that the current repository already implements it.

FIRST ADVENTURE REFERENCE. Open Lagoon is the safe starting cove. Its leftmost downstream tunnel connects to Coral Cove, currently presented as The Living Cascade: Arrival Pool; Stepping-stone Garden; Hollow-root Dive; Cascade Terraces; Restoration Garden; Waterfall Run; completion and return to the hub. The current finish uses a reach_volume trigger, not a mandatory boss. Preserve three checkpoints, optional discoveries, glowing crayfish and the optional dance reward. Three Netbots occupy land; five Hooklines are distributed across land and underwater positions. The restoration gate requires seven total seeds, with nine available and seven accessible within the garden alone. Accessible shores, entrance seams and underwater/pool boundaries are contained; accidental fallthrough is a defect. A whirlpool, additional suit powers and a new boss remain future work until separately specified.

DELIVERY. Desktop is the first release target. Tablet play is a later feasibility milestone requiring measured performance, touch controls and readable UI on named devices; it is not promised by the current art quality. Consoles are deferred. This remains a single-player game, not a general-purpose engine or a multiplayer platform.

OPEN CONTRIBUTION. Establish code licensing, asset remix/redistribution rights, provenance, credits and contributor permissions before inviting public reuse. The repository's code license does not automatically cover externally generated models, textures or music. Publish only packages that pass conformance checks, human play/content review and measured device budgets. Approval identifies immutable package bytes; updates are reviewed again and withdrawn releases are removed from future distribution.

This new project records the agreed end state and the first-level reference. Existing implementation is context only: no requirement is considered verified until fresh evidence is attached after the repository is connected. Do not overwrite this specification with older repository anchors during connection.

## Planning inventory

| Item | Count |
|---|---:|
| Architecture components | 13 |
| Dependency relationships | 22 |
| Versioned contracts | 10 |
| Requirements | 26 |
| Acceptance criteria | 117 |
| Work orders | 187 |
| Implementation steps | 438 |
| Task documents | 13 |
| Test-plan documents | 26 |
| Planned automated / manual checks | 87 / 30 |
| Bound artifacts, including planning documents | 1207 |
| Acceptance criteria marked met | 0 |

Planned checks are not test results. The export contains no reported test-suite results.

## Component ownership

| Component | Role | Technology | Requirements | Bound artifacts |
|---|---|---|---|---:|
| OpenAxolotl Game Shell | game-client | godot | REQ-001 | 9 |
| Hero Motion & Animation | shared-library | godot | REQ-002 | 91 |
| Input, Camera & Accessibility | shared-library | godot | REQ-003 | 45 |
| Drift Fleet Encounters | shared-library | godot | REQ-004, REQ-005 | 47 |
| Progress, Recovery & Rewards | shared-library | godot | REQ-006, REQ-007 | 104 |
| Versioned World Runtime API | shared-library | godot | REQ-008 | 25 |
| Reusable Level & Asset Kit | shared-library | godot | REQ-009 | 581 |
| Official Adventure: Lagoon & Living Cascade | shared-library | godot | REQ-019, REQ-020, REQ-021, REQ-022, REQ-023, REQ-024, REQ-025, REQ-026 | 170 |
| Family Workshop & Starter | cli-tool | python-backend | REQ-010 | 19 |
| Content Export & Conformance | cli-tool | python-backend | REQ-011, REQ-012 | 41 |
| Curated Review & Release | cli-tool | python-backend | REQ-013, REQ-016 | 5 |
| Adventure Catalog & Installation | shared-library | godot | REQ-014, REQ-015 | 11 |
| Quality Evidence & Migration Gates | cli-tool | python-backend | REQ-017, REQ-018 | 59 |

## Dependency topology

Each edge runs from the consumer to the provider. Attached schemas define the exchanged data even where the relationship kind is `dependency`.

| Consumer | Provider | Contract |
|---|---|---|
| Hero Motion & Animation | Input, Camera & Accessibility | Semantic Input Frame v1 |
| Drift Fleet Encounters | Hero Motion & Animation | Hero Motion and Action Snapshot v1 |
| Versioned World Runtime API | Hero Motion & Animation | Hero Motion and Action Snapshot v1 |
| Versioned World Runtime API | Drift Fleet Encounters | Declarative World Definition v1 |
| Versioned World Runtime API | Progress, Recovery & Rewards | Progress Snapshot v1 |
| Versioned World Runtime API | Reusable Level & Asset Kit | Approved Kit Entry v1 |
| Hero Motion & Animation | Reusable Level & Asset Kit | Approved Kit Entry v1 |
| Official Adventure: Lagoon & Living Cascade | Versioned World Runtime API | Declarative World Definition v1 |
| Official Adventure: Lagoon & Living Cascade | Reusable Level & Asset Kit | Approved Kit Entry v1 |
| OpenAxolotl Game Shell | Versioned World Runtime API | Declarative World Definition v1 |
| OpenAxolotl Game Shell | Input, Camera & Accessibility | Semantic Input Frame v1 |
| OpenAxolotl Game Shell | Official Adventure: Lagoon & Living Cascade | Declarative World Definition v1 |
| OpenAxolotl Game Shell | Adventure Catalog & Installation | Installed Adventure State v1 |
| Family Workshop & Starter | Content Export & Conformance | Data-only Level Package Manifest v1 |
| Family Workshop & Starter | Reusable Level & Asset Kit | Approved Kit Entry v1 |
| Content Export & Conformance | Versioned World Runtime API | Declarative World Definition v1 |
| Content Export & Conformance | Reusable Level & Asset Kit | Approved Kit Entry v1 |
| Curated Review & Release | Content Export & Conformance | Conformance Evidence v1 |
| Adventure Catalog & Installation | Curated Review & Release | Signed Catalog Release v1 |
| Adventure Catalog & Installation | Progress, Recovery & Rewards | Progress Snapshot v1 |
| Quality Evidence & Migration Gates | OpenAxolotl Game Shell | Quality Run Record v1 |
| Quality Evidence & Migration Gates | Content Export & Conformance | Conformance Evidence v1 |

## Contract inventory

| Contract | Kind | Format |
|---|---|---|
| Semantic Input Frame v1 | dependency | json_schema |
| Hero Motion and Action Snapshot v1 | dependency | json_schema |
| Progress Snapshot v1 | dependency | json_schema |
| Declarative World Definition v1 | dependency | json_schema |
| Approved Kit Entry v1 | dependency | json_schema |
| Data-only Level Package Manifest v1 | dependency | json_schema |
| Conformance Evidence v1 | dependency | json_schema |
| Signed Catalog Release v1 | dependency | json_schema |
| Installed Adventure State v1 | dependency | json_schema |
| Quality Run Record v1 | dependency | json_schema |

Full contract schemas are in `architecture.json`; existing repository contract files are migration inputs and may not yet implement these target interfaces.

## Requirement index

| Requirement | Intent | Owner |
|---|---|---|
| REQ-001 | A complete single-player adventure before creation | OpenAxolotl Game Shell |
| REQ-002 | Expressive, smooth axolotl movement and animation | Hero Motion & Animation |
| REQ-003 | Readable camera, controls and accessible feedback | Input, Camera & Accessibility |
| REQ-004 | Nearby enemies with readable, smooth behavior | Drift Fleet Encounters |
| REQ-005 | Netbot capture and Hookline attack rules | Drift Fleet Encounters |
| REQ-006 | Glowing crayfish and an optional dance reward | Progress, Recovery & Rewards |
| REQ-007 | Consistent recovery, capabilities and saved progress | Progress, Recovery & Rewards |
| REQ-008 | Four architectural responsibilities and a versioned World API | Versioned World Runtime API |
| REQ-009 | A reusable gameplay kit with coherent presentation | Reusable Level & Asset Kit |
| REQ-010 | A small, approachable family level-creation workflow | Family Workshop & Starter |
| REQ-011 | A bounded, versioned downloadable content format | Content Export & Conformance |
| REQ-012 | Automated content checks and reproducible builds | Content Export & Conformance |
| REQ-013 | Human review before community publication | Curated Review & Release |
| REQ-014 | Curated discovery and reliable package installation | Adventure Catalog & Installation |
| REQ-015 | Compatible updates, save migrations and withdrawal | Adventure Catalog & Installation |
| REQ-016 | Explicit code, asset and contributor rights | Curated Review & Release |
| REQ-017 | Desktop-first quality with a separate tablet decision | Quality Evidence & Migration Gates |
| REQ-018 | Repository onboarding preserves this end-state specification | Quality Evidence & Migration Gates |
| REQ-019 | Open Lagoon and the leftmost tunnel | Official Adventure: Lagoon & Living Cascade |
| REQ-020 | S01 — Arrival Pool | Official Adventure: Lagoon & Living Cascade |
| REQ-021 | S02 — Stepping-stone Garden | Official Adventure: Lagoon & Living Cascade |
| REQ-022 | S03 — Hollow-root Dive | Official Adventure: Lagoon & Living Cascade |
| REQ-023 | S04 — Cascade Terraces | Official Adventure: Lagoon & Living Cascade |
| REQ-024 | S05 — Restoration Garden and crown arch | Official Adventure: Lagoon & Living Cascade |
| REQ-025 | S06 — Waterfall Run and reward pool | Official Adventure: Lagoon & Living Cascade |
| REQ-026 | Finish, persist and return to Open Lagoon | Official Adventure: Lagoon & Living Cascade |

## Remaining implementation and synchronization work

- Export the current native NodeSpec model, specification, task/test documents and board without restoring the retired architecture.
- Align the actual Godot editor, CI runtime and export templates: `project.godot` declares 4.7 while `scripts/setup.sh` currently pins 4.3-stable.
- Preserve the accepted quality-first sequence: source/baseline evidence, hero rig and movement with camera, encounters and one finished section, complete official route, family starter/export, then reviewed release and installation.
- Validate a clean checkout with Git LFS assets and fresh import, input-driven route, animation, encounter and rendered performance evidence. Historical checks and linked files are not proof of acceptance.
- Treat data-only export/loading, curated distribution, future suits, whirlpool and boss placement according to their recorded implementation gaps; none become mandatory first-adventure behavior merely because source assets exist.
