class_name LifeSystem
extends RefCounted

## The Lives and Checkpoint System (REQ-003) — Pillar 1, hard layer.
##
## This node supplies the stakes the capability system deliberately does not. Its
## criteria are mostly NEGATIVE — what must never cost a life, what must never
## happen at zero — and negative properties are defended by structure here rather
## than by care:
##
##   * A life can only be spent by naming a source from CatastrophicSource's
##     closed set. Everything else in the game is outside that set by
##     construction, so AC-2 is not a rule anyone has to remember.
##   * Zero lives is a SETBACK: replenish, return to the last checkpoint, restore
##     capabilities. There is no method here that restarts a world, and a test
##     walks the method and signal lists to keep it that way.
##   * The respawn path holds no reference to the checkpoint store. AC-4 says a
##     respawn never modifies the save file; the way to make that true is for the
##     code that could write to be unreachable from the code that respawns.
##
## The lives-per-attempt override is resolved ONCE at world load into an
## effective value, rather than consulting the contract on every decrement — a
## world's declaration cannot change mid-attempt, and re-reading it every time
## would be a place for it to appear to.

const DEFAULT_LIVES_KEY := "progression.default_lives_per_attempt"
const MAX_RETRY_KEY := "progression.max_retry_seconds"

## The Level Contract field a world declares its override in.
const CONTRACT_LIVES_FIELD := "livesPerAttempt"

signal life_lost(remaining: int, source: CatastrophicSource.Kind)

## Emitted when the last life goes, BEFORE the respawn that immediately follows.
## Listeners use it for the setback beat; it is not a failure state.
signal lives_exhausted()

signal checkpoint_activated(checkpoint_id: String)
signal respawned(position: Vector3, checkpoint_id: String, replenished: int)

var _tuning: TuningData
var _restorer: CapabilityRestorer = null
var _store: CheckpointStore = null

var _world_id: String = ""
var _graph: CheckpointGraph = null
var _spawn_point: Vector3 = Vector3.ZERO

## Resolved once at world load. See the class docstring.
var _lives_per_attempt: int = 0
var _lives: int = 0

var _active_checkpoint: String = ""


func _init(tuning: TuningData) -> void:
	_tuning = tuning
	_lives_per_attempt = _tuning.get_count(DEFAULT_LIVES_KEY)
	_lives = _lives_per_attempt


# --- Wiring -----------------------------------------------------------------

## Installed by the Game Client. Absent, a checkpoint still records its anchor
## and still replenishes lives — it simply restores no capabilities, and reports
## zero rather than pretending.
func set_capability_restorer(restorer: CapabilityRestorer) -> void:
	_restorer = restorer


func set_checkpoint_store(store: CheckpointStore) -> void:
	_store = store


# --- World load -------------------------------------------------------------

## Loads a world and resolves its effective lives-per-attempt (AC-6).
##
## [param contract] is the world's Level Contract declaration. An override is
## honoured only when the tuning surface says that key is world-overridable AND
## the value sits inside the key's permitted range — a world asking for 9999
## lives is refused and gets the global default, because the range in the tuning
## data is the balance decision and a world does not get to leave it.
func open_world(world_id: String, graph: CheckpointGraph = null,
		contract: Dictionary = {}) -> void:
	_world_id = world_id
	_graph = graph
	_lives_per_attempt = _resolve_lives_per_attempt(contract)
	_lives = _lives_per_attempt
	_active_checkpoint = ""

	# A previous session's anchor, if this world has been played before.
	if _store != null:
		var remembered := _store.load_checkpoint(world_id)
		if not remembered.is_empty() and _graph != null and _graph.has(remembered):
			_active_checkpoint = remembered


func _resolve_lives_per_attempt(contract: Dictionary) -> int:
	var default_lives := _tuning.get_count(DEFAULT_LIVES_KEY)
	if not contract.has(CONTRACT_LIVES_FIELD):
		return default_lives

	# The closed override set lives in the tuning data (REQ-025 AC-5). Asking it
	# rather than keeping a second list here is what stops the two drifting.
	if not _tuning.is_world_overridable(DEFAULT_LIVES_KEY):
		return default_lives

	var requested := int(contract[CONTRACT_LIVES_FIELD])
	var bounds := _tuning.get_permitted_range(DEFAULT_LIVES_KEY)
	if bounds.size() != 2:
		return default_lives
	if float(requested) < bounds[0] or float(requested) > bounds[1]:
		return default_lives

	return requested


func set_spawn_point(position: Vector3) -> void:
	_spawn_point = position


# --- AC-1 and AC-2: spending a life ----------------------------------------

## Spends a life for a catastrophe named by id — the lane enemies and hazards
## use across the Checkpoint and Life Interface.
##
## Returns false, changing nothing, for ANY id outside CatastrophicSource's
## closed set. That is AC-2 in one line: ordinary enemy and hazard contact
## reaches this method and bounces off it, because "netbot" is not in the set and
## no amount of contact makes it so.
func report_catastrophe(source_id: String) -> bool:
	var resolved := CatastrophicSource.from_id(source_id)
	if resolved == CatastrophicSource.UNKNOWN:
		return false
	return lose_life(resolved as CatastrophicSource.Kind)


## The typed lane, for callers inside core where the compiler can check the
## argument. Returns false when a life was not spent.
func lose_life(source: CatastrophicSource.Kind) -> bool:
	if _lives <= 0:
		return false

	_lives -= 1
	life_lost.emit(_lives, source)

	if _lives <= 0:
		lives_exhausted.emit()
		_respawn_at_checkpoint()

	return true


# --- AC-3 and AC-4: zero lives is a setback --------------------------------

## Replenish, return to the last activated checkpoint, restore capabilities.
##
## Note what is absent: no world reload, no save write, no penalty. This method
## does not reference _store at all, and that is deliberate — AC-4 is a property
## of what this code can reach, not of what it happens to do today.
func _respawn_at_checkpoint() -> void:
	_lives = _lives_per_attempt

	if _restorer != null:
		_restorer.restore_all()

	respawned.emit(get_respawn_position(), _active_checkpoint, _lives)


## Where a respawn puts the axolotl: the last activated checkpoint, or the world
## spawn when none has been reached yet.
##
## Falling back to spawn is NOT a world restart — it is the only anchor that
## exists before the first checkpoint, and the world's state is untouched either
## way.
func get_respawn_position() -> Vector3:
	if _graph != null and not _active_checkpoint.is_empty():
		var checkpoint := _graph.find(_active_checkpoint)
		if checkpoint != null:
			return checkpoint.position
	return _spawn_point


# --- AC-5: checkpoints ------------------------------------------------------

## Activates a checkpoint: records the respawn anchor, replenishes lives, and
## restores capability state through the published interface.
##
## This is the one path that persists, because checkpoint progress must survive a
## session. Returns false for an id the loaded world does not declare.
func activate_checkpoint(checkpoint_id: String) -> bool:
	if _graph == null or not _graph.has(checkpoint_id):
		return false

	_active_checkpoint = checkpoint_id
	_lives = _lives_per_attempt

	if _restorer != null:
		_restorer.restore_all()

	if _store != null:
		_store.persist_checkpoint(_world_id, checkpoint_id)

	checkpoint_activated.emit(checkpoint_id)
	return true


func get_active_checkpoint() -> String:
	return _active_checkpoint


func has_active_checkpoint() -> bool:
	return not _active_checkpoint.is_empty()


# --- AC-7: checkpoint spacing ----------------------------------------------

func max_retry_seconds() -> float:
	return _tuning.get_number(MAX_RETRY_KEY)


## Checkpoint ids in the loaded world whose incoming replay segment exceeds the
## tuned bound. Empty means the world conforms; a world with no graph loaded
## reports nothing checkable rather than a false pass — see
## CheckpointGraph.conforms_to.
func failing_checkpoint_segments() -> PackedStringArray:
	if _graph == null:
		return PackedStringArray()
	return _graph.segments_over(max_retry_seconds())


func world_spacing_conforms() -> bool:
	if _graph == null:
		return false
	return _graph.conforms_to(max_retry_seconds())


# --- The HUD State Interface ------------------------------------------------

func get_lives() -> int:
	return _lives


func get_lives_per_attempt() -> int:
	return _lives_per_attempt


func get_world_id() -> String:
	return _world_id


func get_checkpoint_graph() -> CheckpointGraph:
	return _graph
