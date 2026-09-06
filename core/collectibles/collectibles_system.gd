class_name CollectiblesSystem
extends RefCounted

## The Collectibles System (REQ-010): the reward layer for optional branches,
## and the resource economy feeding restoration.
##
## TWO KINDS WITH TWO LIFETIMES, kept distinct in the data model because only
## one of them is spent (see CollectibleKind):
##
##   * a RESOURCE collectible is delivered to its declared region through the
##     Restoration Region Interface and consumed there. This node never
##     writes region state itself — it reports "n resources for region r" and
##     lets restoration decide whether that advances anything (it refuses
##     while the region is locked, and banks the delivery).
##   * a DISCOVERY collectible is counted per world and persisted to the
##     profile BY ID, THE MOMENT IT IS COLLECTED, through the CollectibleStore
##     port. Not flushed at a checkpoint, not held in a run buffer: the Lives
##     system is forbidden from touching the save on zero lives, and this node
##     writes at pickup, so the two compose into "collection survives losing
##     every life" without either knowing the other exists (AC-4).
##
## COLLECTIBLES ARE DECLARED, NEVER SCRIPTED (AC-6). The only way one enters
## this system is [method declare_from_manifest], reading the Level Contract's
## optional `collectibles` element. There is no register call and no
## Callable hook, for the same reason restoration has none: a world author
## writes DATA, and the logic stays in core where it is tested and where the
## static gate can see the world never needed code.
##
## THE ABSENT DEFAULT IS REAL (AC-5). A manifest with no `collectibles` leaves
## this system empty and inert; nothing a finish condition can depend on
## exists, so the world stays completable by construction. The one finish
## kind that does depend on this node — `collect_all` — can never complete
## vacuously: [method all_collected] is false for a world declaring no
## discovery collectibles, so a world asking for `collect_all` with nothing to
## collect is reported uncompletable rather than instantly won.
##
## Every balance value is read from the tuning surface at use time (REQ-025):
## how many resources one pickup delivers is `collectibles.resource_pickup_value`,
## never a constant here.

signal collected(collectible_id: String, kind: CollectibleKind.Kind)
signal resources_delivered(region_id: String, count: int, states_advanced: int)

## Every declared discovery collectible is now collected. Backs the Level
## Contract's `collect_all` finish condition. Emitted once, on the pickup
## that completed the set.
signal collection_completed()

const MANIFEST_FIELD := "collectibles"
const RESOURCE_VALUE_KEY := "collectibles.resource_pickup_value"

var _tuning: TuningData
var _store: CollectibleStore
var _restoration: RestorationSystem = null

var _world_id: String = ""
var _defs: Dictionary = {}  # collectible_id -> CollectibleDef
var _order: PackedStringArray = PackedStringArray()

## Every id the profile records as collected for the open world, declared or
## not. Ids a world no longer declares are carried, never dropped: pruning a
## save is the compatibility policy's decision, not a side effect of a pickup.
var _collected: PackedStringArray = PackedStringArray()


func _init(tuning: TuningData, store: CollectibleStore = null) -> void:
	_tuning = tuning
	_store = store if store != null else CollectibleStore.new()


## The Restoration Region Interface this node delivers resources through.
## Attach BEFORE declaring, so a resource naming an undeclared region is
## refused at declaration rather than delivered to nowhere at pickup.
func set_restoration(restoration: RestorationSystem) -> void:
	_restoration = restoration


# --- Declarative construction (AC-6) ----------------------------------------

## Builds the collectible set from a world manifest. Returns false and
## populates [param out_errors] on any malformed declaration, leaving the
## system EMPTY rather than half-declared — a world with some of its
## collectibles silently missing is worse than one refused.
func declare_from_manifest(
	manifest: Dictionary,
	out_errors: Array[CollectibleError] = []
) -> bool:
	var before := out_errors.size()
	_defs = {}
	_order = PackedStringArray()

	if not manifest.has(MANIFEST_FIELD):
		# Absent is legal and means no collectibles — the contract's defined
		# default for an omitted optional element (AC-5).
		return true

	var raw: Variant = manifest[MANIFEST_FIELD]
	if not (raw is Array):
		out_errors.append(CollectibleError.new(
			CollectibleError.MALFORMED_DECLARATION, MANIFEST_FIELD,
			"'%s' must be an array of collectible declarations" % MANIFEST_FIELD))
		return false

	var declared: Dictionary = {}
	var order := PackedStringArray()
	for entry: Variant in (raw as Array):
		var def := CollectibleDef.from_dictionary(entry, out_errors)
		if def == null:
			continue
		if declared.has(def.collectible_id):
			out_errors.append(CollectibleError.new(
				CollectibleError.DUPLICATE_ID, def.collectible_id,
				"collectible '%s' is declared more than once" % def.collectible_id))
			continue
		if def.is_resource() and _restoration != null \
				and not _restoration.has_region(def.region_id):
			out_errors.append(CollectibleError.new(
				CollectibleError.UNKNOWN_REGION, def.collectible_id,
				"resource '%s' restores region '%s', which the world does not declare"
				% [def.collectible_id, def.region_id]))
			continue
		declared[def.collectible_id] = def
		order.append(def.collectible_id)

	if out_errors.size() != before:
		return false

	_defs = declared
	_order = order
	return true


## Opens a world's collection record: what the profile already holds for it.
## Called after declaring, once per world entry.
func open_world(world_id: String) -> void:
	_world_id = world_id
	_collected = _store.load_collected(world_id)
	_collected.sort()


# --- Queries ----------------------------------------------------------------

func is_engaged() -> bool:
	return not _order.is_empty()


func get_collectible_ids() -> PackedStringArray:
	return _order.duplicate()


func has_collectible(collectible_id: String) -> bool:
	return _defs.has(collectible_id)


func get_definition(collectible_id: String) -> CollectibleDef:
	return _defs.get(collectible_id, null) as CollectibleDef


func get_world_id() -> String:
	return _world_id


## Declared discovery ids, in declaration order.
func get_discovery_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in _order:
		if (_defs[id] as CollectibleDef).is_discovery():
			out.append(id)
	return out


func get_discovery_total() -> int:
	return get_discovery_ids().size()


func is_collected(collectible_id: String) -> bool:
	return _collected.has(collectible_id)


## Declared discovery ids the profile records as collected, sorted.
func get_collected_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in get_discovery_ids():
		if _collected.has(id):
			out.append(id)
	out.sort()
	return out


func get_collected_count() -> int:
	return get_collected_ids().size()


## Every declared discovery collectible collected — and NEVER vacuously true.
## A world declaring no discovery collectibles cannot be "all collected",
## because a `collect_all` world that completed at spawn would be a broken
## world reported as a finished one.
func all_collected() -> bool:
	var total := get_discovery_total()
	return total > 0 and get_collected_count() == total


## Whether a `collect_all` finish condition could ever be met here.
func is_completable_by_collection() -> bool:
	return get_discovery_total() > 0


## Resources one resource-kind pickup delivers. Read at use time, never cached
## (REQ-025).
func resource_pickup_value() -> int:
	return _tuning.get_count(RESOURCE_VALUE_KEY)


# --- Collection -------------------------------------------------------------

## Collects a declared collectible. Returns false, changing nothing, for an
## id the world does not declare or a discovery already collected.
func collect(collectible_id: String) -> bool:
	var def := get_definition(collectible_id)
	if def == null:
		return false

	if def.is_resource():
		var count := resource_pickup_value()
		var advanced := 0
		if _restoration != null:
			advanced = _restoration.deliver_resources(def.region_id, count)
		resources_delivered.emit(def.region_id, count, advanced)
		collected.emit(collectible_id, def.kind)
		return true

	if _collected.has(collectible_id):
		return false
	_collected.append(collectible_id)
	_collected.sort()
	# Committed to the profile NOW — see the class docstring on why the
	# timing is the whole of AC-4.
	_store.persist_collected(_world_id, _collected.duplicate())
	collected.emit(collectible_id, def.kind)
	if all_collected():
		collection_completed.emit()
	return true
