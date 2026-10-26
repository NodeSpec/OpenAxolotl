extends RefCounted
## One capture at a time. Simulation time pauses with the world.
signal escaped(unit_id: String)
signal captured(unit_id: String)
const LIMIT := 2.0
const REQUIRED_WHACKS := 3
const GRACE := 1.0
var unit_id := ""
var remaining := 0.0
var whacks := 0
var grace_remaining := 0.0

func active() -> bool: return not unit_id.is_empty()
func begin(id: String) -> bool:
	if id.is_empty() or active() or grace_remaining > 0.0: return false
	unit_id=id;remaining=LIMIT;whacks=0
	return true
func tick(delta: float) -> void:
	if delta <= 0.0: return
	grace_remaining=maxf(0.0,grace_remaining-delta)
	if not active(): return
	remaining=maxf(0.0,remaining-delta)
	if remaining <= 0.000001:
		var id:=unit_id
		clear();captured.emit(id)
func tail_whack() -> bool:
	if not active() or remaining <= 0.000001: return false
	whacks+=1
	if whacks>=REQUIRED_WHACKS:
		var id:=unit_id
		clear();escaped.emit(id)
	return true
func clear() -> void:
	unit_id="";remaining=0.0;whacks=0;grace_remaining=GRACE
