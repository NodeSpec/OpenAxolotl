class_name CapabilityRestorer
extends RefCounted

## The one thing the Lives system needs from Regeneration (REQ-003 AC-5).
##
## Checkpoint activation restores capability state, and so does the respawn at
## zero lives. Both go through THIS — a method call on a published interface —
## never by reaching into the Regeneration system's flags. If Lives could set
## those flags directly there would be two writers to the same state, and the
## capability system's careful never-fatal arithmetic would be one careless line
## away from a system that does not own it.
##
## Declared here, in the consumer, and implemented by the provider: the same
## shape the Audio system uses for its settings store. That is what lets the
## Lives system be tested against a fake without the Regeneration system present,
## and it keeps the dependency pointing the way the architecture declares it.

## Regrows every lost capability, returning how many were actually restored.
## The base restores nothing, so a rig wired without a restorer reports zero
## rather than silently claiming a restoration that did not happen.
func restore_all() -> int:
	return 0
