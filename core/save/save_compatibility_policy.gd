class_name SaveCompatibilityPolicy
extends RefCounted

## The single injectable decision point for what happens to a world's stored
## progress when that world's contract-visible shape has changed (REQ-014 AC-4).
##
## Isolated behind one class deliberately: the policy is a product decision, not
## an implementation detail, and the load path must never encode one implicitly.
## Swapping this object swaps the policy, and the documented policy lives in
## docs/save_compatibility_policy.md.

enum Outcome {
	LOAD,        ## use the stored progress as-is
	RECONCILE,   ## keep stored progress; new elements start at their default
	QUARANTINE,  ## set the blob aside intact and start the world fresh
}


func decide(_change: WorldContractShape.Change) -> Outcome:
	return Outcome.LOAD
