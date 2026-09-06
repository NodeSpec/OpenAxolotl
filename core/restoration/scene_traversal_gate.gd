class_name SceneTraversalGate
extends TraversalGate

## The production [TraversalGate]: restoration toggling real geometry (REQ-008 AC-3).
##
## This is where "opens paths that were not previously available" stops being a
## boolean and becomes collision and navigation. The base class tracks the
## open/closed value so the system stays testable with no scene tree; this
## subclass is what a world's scene actually installs.
##
## Collision and navigation are toggled TOGETHER and deliberately so. Disabling
## a collision shape without re-enabling navigation leaves a path the player can
## swim through but that no Drift Fleet unit will ever path along, which reads
## as a bug rather than as a restored route. Either may be null — a purely
## navigational region has no barrier to remove, and a barrier with no navmesh
## has nothing to re-bake — but whichever is present is driven.
##
## Nothing here touches materials or particles. The visual half of a
## transformation rides on the region's transition signal, so that art can be
## as dramatic as it likes without ever becoming the mechanism.

var _barrier: CollisionShape3D
var _navigation: NavigationRegion3D


func _init(
	p_gate_id: String = "",
	p_opens_at: RegionState.State = RegionState.State.RESTORED,
	p_barrier: CollisionShape3D = null,
	p_navigation: NavigationRegion3D = null
) -> void:
	super(p_gate_id, p_opens_at)
	_barrier = p_barrier
	_navigation = p_navigation


func get_barrier() -> CollisionShape3D:
	return _barrier


func get_navigation() -> NavigationRegion3D:
	return _navigation


## Opening REMOVES the barrier and enables navigation; closing restores both.
## The barrier's `disabled` flag is the inverse of the gate being open, which is
## the one place that inversion is written down.
func _apply_open(open_now: bool) -> void:
	if _barrier != null:
		_barrier.disabled = open_now
	if _navigation != null:
		_navigation.enabled = open_now
