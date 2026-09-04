class_name CameraHintStack
extends RefCounted

## The active camera hints and how they compose (REQ-005 AC-3).
##
## Resolution is by DECLARED PRIORITY, never by enter order. That is the whole
## reason this is a stack object rather than a "last one in wins" variable: a
## player can enter two overlapping volumes in either order, and a world whose
## framing depended on which way they walked in would be unreproducible to author
## and impossible to test.
##
## Equal priorities tie-break on hint id, so even a world that forgets to give
## its volumes distinct priorities gets one deterministic answer rather than a
## coin flip.

var _hints: Array[CameraHint] = []


## Adds or REPLACES the hint with this id. Replacing rather than stacking means a
## volume re-entered after a reload cannot accumulate duplicates of itself.
## Refuses an empty id, since an unnameable hint could never be removed again.
func add(hint: CameraHint) -> bool:
	if hint == null or hint.id.is_empty():
		return false
	remove(hint.id)
	_hints.append(hint)
	return true


func remove(hint_id: String) -> bool:
	for index: int in range(_hints.size()):
		if _hints[index].id == hint_id:
			_hints.remove_at(index)
			return true
	return false


func clear() -> void:
	_hints.clear()


func size() -> int:
	return _hints.size()


func has(hint_id: String) -> bool:
	for hint: CameraHint in _hints:
		if hint.id == hint_id:
			return true
	return false


func get_hint_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for hint: CameraHint in _hints:
		out.append(hint.id)
	out.sort()
	return out


## The framing after every active hint has been applied. [param base] is left
## untouched; the caller gets a fresh object.
##
## Applied lowest priority first so the HIGHEST priority writes last and wins.
func resolve(base: CameraFraming) -> CameraFraming:
	var out := base.copy()

	var ordered := _hints.duplicate()
	ordered.sort_custom(func(a: CameraHint, b: CameraHint) -> bool:
		if a.priority != b.priority:
			return a.priority < b.priority
		return a.id < b.id)

	for hint: CameraHint in ordered:
		hint.apply_to(out)

	return out
