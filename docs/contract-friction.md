# Level Contract friction log

REQ-011 makes this list a deliverable: every place the Level Contract made an
official world fight it gets recorded HERE while building, and fed back into
the contract **before v1 freezes**. Freezing without absorbing this list is
what would break every early community world on the first core update — the
exact failure the official worlds exist to prevent.

Each entry: what was needed, the interim answer shipped, and the proposed
contract change. Interim answers are conventions, deliberately visible as
such — a convention promoted to a contract element becomes checkable; one
left implicit becomes folklore.

## F-1 · Runtime binding conventions are not contract elements

**Needed while building Coral Cove:** a way for a scene to declare mod
pickups, mod-gated barriers, restoration resources, and restoration-gate
geometry — with no world script.

**Interim:** four scene-group conventions bound by the game client's
`WorldSystems` runtime (`hub/world_systems.gd`):
`gill_mod_pickup` (+meta `mod_id`), `affordance_gate` (+meta `affordance`),
`restoration_resource` (+meta `region_id`), `restoration_gate`
(+meta `region_id`, `gate_id`).

**Proposed contract change:** promote these to optional contract elements
with `scene_group_count` rules and documented metadata, so the checker can
verify them (e.g. a `restoration_gate` naming a `gateId` the manifest never
declared should fail conformance, not silently never open). Additive, so it
lands within v1.

## F-2 · Regions have no declared unlock condition

**Needed:** `coral_shelf` must be restorable on entry — there is no Flagship
yet — but REQ-008 AC-2 says a locked region cannot advance and the Flagship
is what unlocks it. The manifest has no way to say which applies.

**Interim:** `WorldSystems` unlocks every region at entry when the manifest
declares **no** `boss`, and keeps regions locked when one is declared
(tested both ways in `test/hub/test_world_systems.gd`).

**Proposed contract change:** an explicit `unlockedBy` field per region
(`"entry"` | `"boss"`), so the policy is a declaration rather than an
inference from an unrelated element's absence.

## F-3 · Gate geometry binds by convention, not by declaration

**Needed:** the manifest declares `traversalGates` with ids; the scene
carries the geometry; nothing in the contract ties the two together.

**Interim:** the `restoration_gate` group's `gate_id` metadata must match a
manifest `gateId` — unchecked by the compliance checker, so a typo produces
a gate that never opens, discovered only by the playthrough test.

**Proposed contract change:** part of F-1 — a rule kind that cross-checks
scene metadata against manifest declarations (a new rule KIND, so it needs
checker work; worth it, this is exactly the drift class the contract exists
to catch).

## F-4 · The `music` element has no schema

**Noticed:** `music` is an optional element with a defined absent-default,
but no declared shape for the present case (track id? event id? loop
points?). Coral Cove declared nothing rather than invent one.

**Proposed contract change:** define the present-shape (an Audio Event
Interface id) before any world declares music, or the first declaration
becomes the de-facto schema.

## F-5 · Affordance windows vs. gate dwell time

**Noticed:** affordances are ACTIVE windows (the Gill Mod framework's
doctrine), so a mod-gated barrier is open for `gillmod.<id>.duration_s`
after activation. A gate placed too far from where a player would activate
the mod is uncompletable in ways no structural check sees.

**Interim:** Coral Cove places each gate a few metres after its pickup, and
the playthrough test would catch a regression.

**Proposed contract note (documentation, not a rule):** world authoring
guidance in `docs/level-contract.md` — keep an affordance gate within its
mod's activation window at walking speed; the completability test is the
enforcement.
