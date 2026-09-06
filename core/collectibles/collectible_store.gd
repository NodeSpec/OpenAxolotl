class_name CollectibleStore
extends RefCounted

## The port this system needs from the Save Integration Interface (REQ-010
## AC-3, AC-4).
##
## Collected discovery ids persist per world across sessions. They go through
## the save system like everything else the player earns — never through a
## private file of this node's own.
##
## Declared HERE, in the consumer, and implemented by the provider: the same
## shape the restoration store and the checkpoint store take. It lets the
## system be built and fully tested against a double, and keeps the
## dependency pointing the way the architecture declares it — collectibles
## depend on an interface, never on the Save System's internals.
##
## The default implementation remembers nothing. That is a legitimate answer
## for a world running with no profile attached (a test, a scratch hub): the
## session's collection still counts, it simply is not kept.

const FIELD := "collectibles"


func load_collected(_world_id: String) -> PackedStringArray:
	return PackedStringArray()


func persist_collected(_world_id: String, _ids: PackedStringArray) -> void:
	pass
