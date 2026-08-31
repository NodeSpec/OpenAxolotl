class_name TieredCompatibilityPolicy
extends SaveCompatibilityPolicy

## The project's chosen save-compatibility policy for forked and divergent
## worlds (REQ-014 AC-4, AC-6). Documented in docs/save_compatibility_policy.md.
##
## Tiered by change type:
##   - nothing changed        -> load as-is
##   - the world only GAINED  -> reconcile; progress kept, new elements default
##   - anything was REMOVED   -> quarantine; blob retained, world starts fresh
##     or RENAMED
##
## The reasoning: this project's premise is that worlds get forked and edited, so
## adding a region or a collectible is the common case and must not cost players
## their progress. A removal or rename is different in kind — the save now points
## at something that does not exist, and reconciling would either drop state
## silently or, worse, attach it to an id that has been reused for a different
## purpose. Quarantine is the honest answer there, and because the blob is
## retained rather than deleted, reverting the fork restores the progress.


func decide(change: WorldContractShape.Change) -> Outcome:
	match change:
		WorldContractShape.Change.NONE:
			return Outcome.LOAD
		WorldContractShape.Change.ADDITIVE:
			return Outcome.RECONCILE
		WorldContractShape.Change.DESTRUCTIVE:
			return Outcome.QUARANTINE
		_:
			return Outcome.QUARANTINE  # unknown change class: fail safe
