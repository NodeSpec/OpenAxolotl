class_name RestorationStore
extends RefCounted

## The port this system needs from the Save Integration Interface (REQ-008 AC-4).
##
## Restoration state and the unlocked flag persist per region across sessions.
## They go through the save system like everything else the player earns — never
## through a private file of this node's own, which would be a second save
## format to version, migrate and keep consistent with the first.
##
## Declared HERE, in the consumer, and implemented by the provider: the same
## shape the Audio system uses for its settings store and the Lives system uses
## for its capability restorer. That is what lets restoration be built and fully
## tested against a double before the wiring exists, and it keeps the dependency
## pointing the way the architecture declares it — restoration depends on an
## interface, never on the Save System's internals.

const SECTION := "restoration"


## Returns the stored payload, or an empty Dictionary when nothing is saved yet.
## An empty result is a legitimate first-run answer, not an error: a world whose
## regions have never been touched is simply all-barren and all-locked.
func load_regions() -> Dictionary:
	return {}


func save_regions(_payload: Dictionary) -> void:
	pass
