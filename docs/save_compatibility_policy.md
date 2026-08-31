# Save-Compatibility Policy for Forked and Divergent Worlds

**Status:** Decided. Resolves the open item named in REQ-014 and satisfies AC-6.
**Implemented by:** `core/save/tiered_compatibility_policy.gd`
**Decision point:** `core/save/save_compatibility_policy.gd`

## The problem

Worlds in OpenAxolotl are forkable modules. A player's save refers to things a
world declares — regions, collectibles, checkpoints — by id. When that world is
edited, forked, or replaced, those ids may no longer mean what they did when the
save was written. The save must not silently attach old progress to new content,
and it must not throw away progress for a trivial edit.

## The policy: tiered by change type

Each world stores the **contract-visible shape** it had when its progress was
written: the sets of region, collectible and checkpoint ids it declared. On load,
that stored shape is compared to the world's current declarations.

| Change | Outcome | Effect on progress |
|---|---|---|
| Nothing changed | `LOAD` | Used as-is. |
| World only **gained** elements | `RECONCILE` | Kept in full. New ids take their defaults. |
| An id was **removed or renamed** | `QUARANTINE` | World starts fresh. Old blob retained intact. |

### Why this split

Adding content is the common case in a project whose premise is that worlds get
forked and edited. A contributor adding one collectible must not reset every
player's progress in that world — a strict fingerprint policy would do exactly
that, and would be hostile to the forking premise the project is built on.

A removal or rename is different in kind. The save now points at something that
does not exist. Reconciling would either drop that state silently or, worse,
attach it to an id that has been reused for a different purpose — a region
marked `restored` that is no longer the same region. Quarantine is the honest
answer.

### Renames are treated as removals, deliberately

At the id level a rename is indistinguishable from a removal plus an addition.
The policy does not attempt to guess that `reef_a` became `reef_alpha`. Guessing
is precisely the silent wrongness this policy exists to prevent.

A world author who wants to rename an id without costing players their progress
should ship a **save migration** for their world rather than relying on the
compatibility policy to infer intent.

## Quarantine is not deletion

A quarantined blob is stored intact under the world's `quarantined` key. It is
never pruned. Consequences:

- Reverting a fork, or reinstalling the original world, restores the progress.
- A player who tries a fork and returns loses nothing.
- The profile grows slowly. Accepted: save data is small, and losing progress is
  worse than storing a few stale kilobytes.

## Missing and renamed modules

A save referencing a module that is not installed is **retained, not pruned**
(REQ-014 AC-3). The profile loads, every other world stays playable, and the
absent world's data waits for it to come back. Deserialization is per-module, so
one unreadable blob cannot fail the whole profile load; it is recorded as
unavailable and the load continues — mirroring how the hub surfaces an
unloadable module as an unavailable portal rather than failing the hub.

## What this policy does NOT cover

- **Semantic change under a stable id.** If a world keeps `reef_a` but rebuilds
  it into a different place, the shape is unchanged and progress is loaded as-is.
  Detecting this would require hashing world geometry, which would make every
  cosmetic edit destructive. World authors who change what an id *means* should
  change the id.
- **Cross-world dependencies.** Worlds are namespaced and may not read each
  other's data, so there is nothing to reconcile between them.
