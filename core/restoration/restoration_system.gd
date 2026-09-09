class_name RestorationSystem
extends RefCounted

## The World Restoration State System (REQ-008) — pillar three.
##
## The world regenerates with you: regions move barren -> resourced -> restored,
## opening real traversal routes rather than swapping visuals, and Dredgers can
## flatten that progress back. It carries the open-source metaphor mechanically,
## without a child ever needing to notice the metaphor.
##
## REGIONS ARE DECLARED, NEVER SCRIPTED. The only way a region enters this
## system is [method declare_from_manifest], reading the `restorableRegions`
## element a world publishes through the Level Contract (AC-7). There is
## deliberately no register-a-region call, no callback hook and no way to hand in
## a Callable: a world author writes DATA, and every state machine in the game
## lives in core where it can be tested. That is also what keeps the sanctioned
## world API surface narrow enough for the static gate to check — a world that
## could install its own progression logic would be unverifiable by construction.
##
## The declaration is validated rather than trusted. A region that declares no
## traversal gate is REFUSED, because "advancing state opens paths that were not
## previously available, not only visuals" cannot be satisfied by a region whose
## restoration changes nothing traversable. That check is the difference between
## the criterion being enforced and being hoped for.
##
## This node never calls the Audio System, the HUD or the Save System directly.
## It emits semantic signals and reads/writes through the RestorationStore port,
## so consumers subscribe and the dependencies point the way the architecture
## declares them.

signal region_state_changed(region_id: String, from: RegionState.State, to: RegionState.State)
signal region_unlocked_changed(region_id: String, unlocked: bool)
signal region_traversal_changed(region_id: String, gate_id: String, open: bool)

## Semantic ambience request. A bed id from the Audio Event Interface's closed
## set — this node says "restored", the Audio System decides what that sounds
## like (REQ-023).
signal ambience_requested(region_id: String, bed: AudioEvent.Bed)

const MANIFEST_FIELD := "restorableRegions"
const REGION_ID_FIELD := "regionId"
const GATES_FIELD := "traversalGates"
const GATE_ID_FIELD := "gateId"
const OPENS_AT_FIELD := "opensAt"

## What lifts a region's unlock, declared per region (contract friction F-2).
##
## WHY THIS EXISTS. The policy used to be INFERRED from an unrelated element:
## a world declaring no boss had every region unlocked at entry, and a world
## declaring one had every region locked until the encounter. That reads fine
## until a level wants both — restoration on its critical path AND a Flagship
## at its end — at which point the inference deadlocks it: the regions the
## route needs stay locked behind a boss the route cannot reach without them.
## Coral Cove is exactly that level.
##
## ABSENT KEEPS THE OLD INFERENCE, so every world and fixture written before
## this field existed means what it always meant. Declaring it is how a world
## says what it actually wants.
const UNLOCKED_BY_FIELD := "unlockedBy"
const UNLOCK_AT_ENTRY := "entry"
const UNLOCK_BY_BOSS := "boss"
const UNLOCK_POLICIES: Array[String] = [UNLOCK_AT_ENTRY, UNLOCK_BY_BOSS]

var _tuning: TuningData
var _store: RestorationStore
var _regions: Dictionary = {}
var _order: PackedStringArray = PackedStringArray()

## region_id -> declared unlock policy, or absent when the world did not say.
var _unlock_policy: Dictionary = {}


func _init(tuning: TuningData, store: RestorationStore = null) -> void:
	_tuning = tuning
	_store = store if store != null else RestorationStore.new()


# --- Declarative construction (AC-7) ----------------------------------------

## Builds regions from a world manifest. Returns false and populates
## [param out_errors] on any malformed declaration, leaving the system empty
## rather than half-built — a partially declared world is worse than a refused
## one, because the missing regions surface later as silently absent progression.
func declare_from_manifest(
	manifest: Dictionary,
	out_errors: Array[RestorationError] = []
) -> bool:
	var before := out_errors.size()
	var declared: Dictionary = {}
	var order := PackedStringArray()
	var policies: Dictionary = {}

	if not manifest.has(MANIFEST_FIELD):
		# Absent is legal and means no restoration progression — the contract's
		# defined default for an omitted optional element.
		_regions = {}
		_order = PackedStringArray()
		_unlock_policy = {}
		return true

	var raw: Variant = manifest[MANIFEST_FIELD]
	if not (raw is Array):
		out_errors.append(RestorationError.new(
			RestorationError.MALFORMED_DECLARATION, MANIFEST_FIELD,
			"'%s' must be an array of region declarations" % MANIFEST_FIELD))
		return false

	for entry: Variant in (raw as Array):
		_declare_one(entry, declared, order, policies, out_errors)

	if out_errors.size() != before:
		return false

	_regions = declared
	_order = order
	_unlock_policy = policies
	return true


func _declare_one(
	entry: Variant,
	declared: Dictionary,
	order: PackedStringArray,
	policies: Dictionary,
	out_errors: Array[RestorationError]
) -> void:
	if not (entry is Dictionary):
		out_errors.append(RestorationError.new(
			RestorationError.MALFORMED_DECLARATION, MANIFEST_FIELD,
			"each region declaration must be an object"))
		return

	var row := entry as Dictionary
	var region_id := String(row.get(REGION_ID_FIELD, "")).strip_edges()
	if region_id.is_empty():
		out_errors.append(RestorationError.new(
			RestorationError.MISSING_FIELD, REGION_ID_FIELD,
			"a region declaration must name its '%s'" % REGION_ID_FIELD))
		return

	if declared.has(region_id):
		out_errors.append(RestorationError.new(
			RestorationError.DUPLICATE_REGION, region_id,
			"region '%s' is declared more than once" % region_id))
		return

	# REFUSED, not defaulted. A misspelled policy is a level that unlocks at
	# the wrong moment, which surfaces as an unreachable route rather than as
	# an error — the most expensive kind of typo this contract can carry.
	if row.has(UNLOCKED_BY_FIELD):
		var policy := String(row[UNLOCKED_BY_FIELD]).strip_edges()
		if not UNLOCK_POLICIES.has(policy):
			out_errors.append(RestorationError.new(
				RestorationError.UNKNOWN_UNLOCK_POLICY, region_id,
				"region '%s' declares '%s': '%s'; expected one of %s"
				% [region_id, UNLOCKED_BY_FIELD, policy, str(UNLOCK_POLICIES)]))
			return
		policies[region_id] = policy

	var gates := _declare_gates(region_id, row, out_errors)
	if gates.is_empty():
		return

	var region := RestorableRegion.new(region_id, gates)
	region.state_changed.connect(_on_state_changed)
	region.unlocked_changed.connect(
		func(rid: String, unlocked: bool) -> void:
			region_unlocked_changed.emit(rid, unlocked))
	region.traversal_changed.connect(
		func(rid: String, gate_id: String, open: bool) -> void:
			region_traversal_changed.emit(rid, gate_id, open))

	declared[region_id] = region
	order.append(region_id)


func _declare_gates(
	region_id: String,
	row: Dictionary,
	out_errors: Array[RestorationError]
) -> Array[TraversalGate]:
	var gates: Array[TraversalGate] = []
	var raw: Variant = row.get(GATES_FIELD, null)

	if not (raw is Array) or (raw as Array).is_empty():
		out_errors.append(RestorationError.new(
			RestorationError.NO_TRAVERSAL_EFFECT, region_id,
			("region '%s' declares no '%s'; restoration must open a path that " +
			"was not previously available, not only change visuals")
			% [region_id, GATES_FIELD]))
		return gates

	for gate_entry: Variant in (raw as Array):
		if not (gate_entry is Dictionary):
			out_errors.append(RestorationError.new(
				RestorationError.MALFORMED_DECLARATION, region_id,
				"each traversal gate must be an object"))
			return [] as Array[TraversalGate]

		var gate_row := gate_entry as Dictionary
		var gate_id := String(gate_row.get(GATE_ID_FIELD, "")).strip_edges()
		if gate_id.is_empty():
			out_errors.append(RestorationError.new(
				RestorationError.MISSING_FIELD, region_id,
				"a traversal gate must name its '%s'" % GATE_ID_FIELD))
			return [] as Array[TraversalGate]

		var opens_text := String(gate_row.get(OPENS_AT_FIELD, "")).strip_edges()
		if not RegionState.is_known_id(opens_text):
			out_errors.append(RestorationError.new(
				RestorationError.UNKNOWN_GATE_STATE, "%s/%s" % [region_id, gate_id],
				"'%s' is not one of barren, resourced, restored" % opens_text))
			return [] as Array[TraversalGate]

		var opens_at := RegionState.from_id(opens_text)
		if opens_at == RegionState.State.BARREN:
			# A gate open at barren is open always, so it is not a gate at all —
			# declaring one would let a region satisfy the traversal requirement
			# while opening nothing.
			out_errors.append(RestorationError.new(
				RestorationError.NO_TRAVERSAL_EFFECT, "%s/%s" % [region_id, gate_id],
				"a gate opening at 'barren' is never closed and opens no path"))
			return [] as Array[TraversalGate]

		gates.append(TraversalGate.new(gate_id, opens_at))

	return gates


# --- Queries ----------------------------------------------------------------

func get_region_ids() -> PackedStringArray:
	return _order.duplicate()


func has_region(region_id: String) -> bool:
	return _regions.has(region_id)


func get_region(region_id: String) -> RestorableRegion:
	return _regions.get(region_id, null) as RestorableRegion


func get_state(region_id: String) -> RegionState.State:
	var region := get_region(region_id)
	return RegionState.State.BARREN if region == null else region.get_state()


func is_unlocked(region_id: String) -> bool:
	var region := get_region(region_id)
	return false if region == null else region.is_unlocked()


## Whether [param region_id] should be unlocked the moment the player enters,
## given whether the world declares a boss at all.
##
## The declared policy wins. When a region declares none, this falls back to
## the inference the runtime used before the field existed — no boss in the
## world means nothing to gate on, so unlock; a boss means wait for it — which
## is what keeps every world written before F-2 meaning what it meant.
func unlocks_at_entry(region_id: String, world_declares_boss: bool) -> bool:
	var policy := String(_unlock_policy.get(region_id, ""))
	if policy == UNLOCK_AT_ENTRY:
		return true
	if policy == UNLOCK_BY_BOSS:
		return false
	return not world_declares_boss


## What a region declared, or "" when it left the policy to the inference.
func unlock_policy_of(region_id: String) -> String:
	return String(_unlock_policy.get(region_id, ""))


## Every declared region restored. Backs the Level Contract's
## `restore_all_regions` finish condition; a world with no regions is vacuously
## complete, which is why the hub requires the element for that finish kind.
func all_restored() -> bool:
	for region_id: String in _order:
		if not (_regions[region_id] as RestorableRegion).is_restored():
			return false
	return true


# --- Drivers ----------------------------------------------------------------

## Collectibles deliver restoration resources here.
func deliver_resources(region_id: String, count: int) -> int:
	var region := get_region(region_id)
	if region == null:
		return 0
	return region.deliver_resources(count, _tuning)


## The Flagship encounter unlocks a region. Idempotent: re-defeating cannot
## re-emit the cue.
##
## THE UNLOCK SPENDS WHAT THE PLAYER ALREADY BANKED. Resources delivered while
## a region was locked are held rather than wasted (that is the point of the
## flag being separate from the state), but nothing used to spend them: the
## lock lifted and the banked pile just sat there until some unrelated later
## pickup happened to call deliver_resources again. On a boss-gated region that
## made the encounter's whole payoff a no-op — you beat the Flagship, the
## region unlocked, and visibly nothing happened. A zero delivery banks nothing
## and advances as far as the existing pile pays for, which is exactly the
## "restoration may now begin, and it does" moment the fight is for.
func unlock_region(region_id: String) -> bool:
	var region := get_region(region_id)
	if region == null:
		return false
	var changed := region.set_unlocked(true)
	if changed:
		region.deliver_resources(0, _tuning)
	return changed


## A Dredger flattens a region back to barren, keeping its unlock (AC-5, AC-6).
func dredger_attack(region_id: String) -> bool:
	var region := get_region(region_id)
	return false if region == null else region.revert_to_barren()


func _on_state_changed(
	region_id: String,
	from: RegionState.State,
	to: RegionState.State
) -> void:
	region_state_changed.emit(region_id, from, to)
	ambience_requested.emit(region_id, RegionState.audio_bed(to))


# --- Persistence (AC-4) -----------------------------------------------------

## Writes every region's state and unlocked flag through the save port.
func save() -> void:
	var payload: Dictionary = {}
	for region_id: String in _order:
		payload[region_id] = (_regions[region_id] as RestorableRegion).to_dictionary()
	_store.save_regions(payload)


## Restores from the save port. Regions absent from the payload keep their
## declared defaults rather than erroring: a world that gained a region since
## the save was written must load, with the new region simply barren and locked.
func load_saved() -> void:
	var payload := _store.load_regions()
	for region_id: String in _order:
		if not payload.has(region_id):
			continue
		var stored: Variant = payload[region_id]
		if stored is Dictionary:
			(_regions[region_id] as RestorableRegion).from_dictionary(
				stored as Dictionary)
