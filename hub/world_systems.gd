class_name WorldSystems
extends Node

## The runtime a world's DECLARATIONS bind to (REQ-011, serving REQ-004/008).
##
## "Declare, don't script" only works if something on the game-client side
## turns declarations into behaviour. This node is that something: the hub
## attaches one to every world it loads, and it wires the world's manifest and
## scene-group conventions to the real core systems — Gill Mods, restoration,
## tuning — so a world module ships NO code at all. The reference template
## proved a world can be pure scene+manifest; this is what lets an official
## world stay that way while having mechanics.
##
## SCENE CONVENTIONS (the world side of the sanctioned interfaces; each is a
## Godot group plus node metadata, because group membership is the contract's
## own tagging rule — never a name, never a type):
##
##   gill_mod_pickup      Area3D, meta `mod_id`     — walking through equips
##                        the named Gill Mod via the registration interface.
##   affordance_gate      StaticBody3D, meta `affordance` — a barrier that
##                        opens while the equipped mod GRANTS the named
##                        affordance. This is how a traversal challenge is
##                        gated on a specific mod, declaratively.
##   restoration_resource Area3D, meta `region_id`  — walking through delivers
##                        one resource to the named region.
##   restoration_gate     StaticBody3D, meta `region_id` + `gate_id` — scene
##                        geometry mirroring the manifest-declared traversal
##                        gate: opens and closes with the region's state, both
##                        directions, so a Dredger reversion closes real paths.
##
## These conventions are contract FRICTION, deliberately surfaced: they belong
## in the Level Contract as optional elements before v1 freezes, and they are
## recorded in docs/contract-friction.md rather than silently invented here.
##
## UNLOCK POLICY. A region cannot advance while locked — that is the
## Flagship's gate (REQ-008 AC-2). A world that declares NO boss has nothing
## to gate on, so its regions unlock on entry; when a world declares a boss,
## its regions stay locked until the encounter (wired when the Flagship node
## exists). The friction log proposes an explicit `unlockedBy` field.

signal mod_equipped(mod_id: String)
signal gate_changed(gate_kind: String, gate_ref: String, open: bool)
signal resource_delivered(region_id: String, resources_held: int)

const GROUP_MOD_PICKUP := "gill_mod_pickup"
const GROUP_AFFORDANCE_GATE := "affordance_gate"
const GROUP_RESOURCE_PICKUP := "restoration_resource"
const GROUP_RESTORATION_GATE := "restoration_gate"
const PLAYER_GROUP := "player"

const TUNING_PATH := "res://core/tuning/tuning.json"
const MODS_DIR := "res://core/gillmod/mods"

## Set by the hub before this node enters the tree.
var manifest: Dictionary = {}

var _tuning: TuningData
var _mods: GillModSystem
var _restoration: RestorationSystem
var _affordance_gates: Array[Node3D] = []
var _restoration_gates: Dictionary = {}  # gate_id -> Node3D


var _wired := false


func _ready() -> void:
	wire()


## Idempotent, and callable directly: a node added while the SceneTree is
## still initialising (the test runner does this) never receives _ready — and
## is not even inside the tree yet — so the wiring must be reachable without
## either, which is also why the scene scan below walks the world's own
## subtree rather than querying tree-wide groups.
func wire() -> void:
	if _wired or get_parent() == null:
		return
	_wired = true
	add_to_group("world_systems")

	_tuning = TuningData.load_from_file(TUNING_PATH)
	if _tuning == null:
		push_warning("WorldSystems: tuning data failed to load; not wiring")
		return
	var overrides: Variant = manifest.get("tuningOverrides", {})
	if overrides is Dictionary and not (overrides as Dictionary).is_empty():
		var tuning_errors: Array[TuningError] = []
		if not _tuning.apply_world_overrides(
				overrides as Dictionary, tuning_errors):
			push_warning("WorldSystems: tuning overrides refused: %s"
				% str(tuning_errors))

	var registry := GillModRegistry.new(_tuning)
	registry.load_directory(MODS_DIR)
	_mods = GillModSystem.new(_tuning, registry)
	_mods.equipped.connect(_on_mod_equipped)
	# Affordances are ACTIVE windows, not permanent upgrades — the framework's
	# own gate doctrine — so gates must follow activation and expiry too.
	_mods.activated.connect(
		func(_mod_id: String, _duration: float) -> void:
			_apply_affordance_gates())
	_mods.expired.connect(
		func(_mod_id: String) -> void: _apply_affordance_gates())

	_restoration = RestorationSystem.new(_tuning)
	var errors: Array[RestorationError] = []
	if not _restoration.declare_from_manifest(manifest, errors):
		# Contract validation runs before load, so this is a defect worth
		# hearing about — but a broken declaration must not crash the world.
		push_warning("WorldSystems: region declaration failed: %s"
			% str(errors.map(func(e: RestorationError) -> String: return str(e))))
	if not manifest.has("boss"):
		for region_id in _restoration.get_region_ids():
			_restoration.unlock_region(region_id)
	_restoration.region_traversal_changed.connect(_on_traversal_changed)

	_wire_scene()
	_apply_affordance_gates()


func get_mods() -> GillModSystem:
	return _mods


func get_restoration() -> RestorationSystem:
	return _restoration


func get_tuning() -> TuningData:
	return _tuning


func _physics_process(delta: float) -> void:
	if _mods != null:
		_mods.tick(delta)


# --- Scene wiring -----------------------------------------------------------

func _world_root() -> Node:
	return get_parent()


## Walks the WORLD'S OWN subtree rather than tree-wide groups: inherently
## scoped to the world this runtime serves (a neighbouring world's gates are
## untouchable by construction), and independent of whether the tree has
## started iterating yet.
func _wire_scene() -> void:
	for node: Node in _world_root().find_children("*", "", true, false):
		if node == self:
			continue
		if node.is_in_group(GROUP_MOD_PICKUP) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _collect_mod))
		elif node.is_in_group(GROUP_RESOURCE_PICKUP) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _collect_resource))
		elif node.is_in_group(GROUP_AFFORDANCE_GATE) and node is Node3D:
			_affordance_gates.append(node as Node3D)
		elif node.is_in_group(GROUP_RESTORATION_GATE) and node is Node3D:
			var gate_id := String(node.get_meta("gate_id", ""))
			if not gate_id.is_empty():
				_restoration_gates[gate_id] = node


func _on_pickup_touched(body: Node3D, pickup: Node, handler: Callable) -> void:
	# body_entered fires during the physics flush; everything a pickup does —
	# freeing itself, toggling a barrier's collision — mutates state the flush
	# is iterating, so the whole collection is deferred out of it.
	if body.is_in_group(PLAYER_GROUP):
		handler.call_deferred(pickup)


func _collect_mod(pickup: Node) -> void:
	var mod_id := String(pickup.get_meta("mod_id", ""))
	if _mods != null and _mods.equip(mod_id):
		# Touching the pickup is the player OPENING the affordance window:
		# equip and activate together, because an affordance is a timed
		# window the framework grants while a mod is ACTIVE, never a
		# permanent upgrade (its own gate doctrine).
		_mods.activate()
		pickup.queue_free()
	else:
		push_warning("WorldSystems: pickup names unknown mod '%s'" % mod_id)


func _collect_resource(pickup: Node) -> void:
	var region_id := String(pickup.get_meta("region_id", ""))
	if _restoration == null or not _restoration.has_region(region_id):
		push_warning("WorldSystems: pickup names unknown region '%s'" % region_id)
		return
	_restoration.deliver_resources(region_id, 1)
	resource_delivered.emit(
		region_id, _restoration.get_region(region_id).get_resources())
	pickup.queue_free()


# --- Gates ------------------------------------------------------------------

func _on_mod_equipped(mod_id: String) -> void:
	_apply_affordance_gates()
	mod_equipped.emit(mod_id)


## An affordance gate is open exactly while the equipped mod grants its named
## affordance — the mechanism behind "a mandatory traversal challenge gated on
## a specific Gill Mod". Recomputed on every equip change, in both directions:
## swapping away from the granting mod closes the passage again.
func _apply_affordance_gates() -> void:
	for gate in _affordance_gates:
		var affordance := String(gate.get_meta("affordance", ""))
		var open := _mods != null and _mods.has_affordance(affordance)
		if _set_barrier_open(gate, open):
			gate_changed.emit("affordance", affordance, open)


func _on_traversal_changed(
		_region_id: String, gate_id: String, open: bool) -> void:
	var gate: Variant = _restoration_gates.get(gate_id)
	if gate is Node3D and _set_barrier_open(gate as Node3D, open):
		gate_changed.emit("restoration", gate_id, open)


## Returns true when the barrier's state actually changed. A visible barrier
## is a CLOSED one, so `visible == open` detects the flip. Collision is
## toggled with set_deferred because restoration advances from inside a
## pickup's physics callback, mid-flush; visibility follows immediately so an
## open gate reads as open.
func _set_barrier_open(barrier: Node3D, open: bool) -> bool:
	var changed := barrier.visible == open
	for child in barrier.find_children("*", "CollisionShape3D", true, false):
		(child as CollisionShape3D).set_deferred("disabled", open)
	barrier.visible = not open
	return changed
