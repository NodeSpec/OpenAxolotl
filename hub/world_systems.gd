class_name WorldSystems
extends Node

## The runtime a world's DECLARATIONS bind to (REQ-011, serving REQ-002/003/
## 004/008/010).
##
## "Declare, don't script" only works if something on the game-client side
## turns declarations into behaviour. This node is that something: the hub
## attaches one to every world it loads, and it wires the world's manifest and
## scene-group conventions to the real core systems — Gill Mods, restoration,
## collectibles, regeneration, lives, tuning — so a world module ships NO code
## at all. The reference template proved a world can be pure scene+manifest;
## this is what lets an official world stay that way while having mechanics.
##
## SCENE CONVENTIONS (the world side of the sanctioned interfaces; each is a
## Godot group plus node metadata, because group membership is the contract's
## own tagging rule — never a name, never a type):
##
##   spawn_point          Node3D — where the player begins and the anchor a
##                        respawn falls back to before any checkpoint.
##   checkpoint           Node3D — a life-and-capability anchor. Its id is the
##                        node name. An Area3D checkpoint is its own trigger;
##                        a Marker3D gets a trigger slab generated across it.
##                        Touching it records the respawn anchor, refills
##                        lives and regrows every capability (REQ-003 AC-5).
##   pit_volume           Area3D — a bottomless pit: CATASTROPHIC. Costs a
##                        life and returns the player to the last checkpoint
##                        (REQ-003 AC-1). Place one under the world so walking
##                        off the edge means something.
##   crush_hazard         Area3D — the other placeable catastrophe.
##   hazard               Area3D, meta `capability` (tail|gill|leg), optional
##                        meta `hazard_id` — ORDINARY damage: strips the named
##                        capability and NEVER costs a life (REQ-002 AC-1,
##                        REQ-003 AC-2). The hazard stays; a second touch of
##                        an already-lost capability does nothing.
##   regen_station        Area3D — regrows every lost capability (REQ-002 AC-4).
##   gill_mod_pickup      Area3D, meta `mod_id`     — walking through equips
##                        the named Gill Mod via the registration interface.
##   affordance_gate      StaticBody3D, meta `affordance` — a barrier that
##                        opens while the equipped mod GRANTS the named
##                        affordance. This is how a traversal challenge is
##                        gated on a specific mod, declaratively.
##   collectible          Area3D, meta `collectible_id` — a placed collectible
##                        the manifest's `collectibles` element DECLARES. A
##                        resource kind delivers to its region; a discovery
##                        kind is rescued once and persisted. A node naming
##                        an undeclared id is refused (REQ-010).
##   restoration_gate     StaticBody3D, meta `region_id` + `gate_id` — scene
##                        geometry mirroring the manifest-declared traversal
##                        gate: opens and closes with the region's state, both
##                        directions, so a Dredger reversion closes real paths.
##
## These conventions are contract FRICTION, deliberately surfaced: they belong
## in the Level Contract as optional elements before v1 freezes, and they are
## recorded in docs/contract-friction.md rather than silently invented here.
##
## PILLAR ONE, WIRED. The Regeneration system publishes its capability factors
## onto the player's controller through the Capability Modifier Interface —
## a lost tail really does slow the swim. The Lives system takes the
## Regeneration system as its CapabilityRestorer and the profile as its
## CheckpointStore, and every catastrophe returns the player to the last
## anchor: a life is spent, and at zero the count refills (a setback, never a
## restart). Entry into a world ALWAYS starts at the spawn point even when the
## profile remembers a later checkpoint, because restoration and pickups are
## not yet persisted — resuming past the seeds you would need to re-collect
## would strand you behind a wall. The anchor is still recorded (friction
## F-10). Every loss and regrowth asks for feedback through
## [signal feedback_requested] and gets a small sparkle burst at the player
## — the comedic pop the tone requirement asks for, in greybox form.
##
## UNLOCK POLICY. A region cannot advance while locked — that is the
## Flagship's gate (REQ-008 AC-2). A world that declares NO boss has nothing
## to gate on, so its regions unlock on entry; when a world declares a boss,
## its regions stay locked until the encounter (wired when the Flagship node
## exists). The friction log proposes an explicit `unlockedBy` field.
##
## FINISH CONDITIONS owned by systems. `reach_volume` is the loader's; the
## `collect_all` kind is completed HERE, by the collectibles system announcing
## that every declared discovery is collected, through the callback the hub
## installs in [member on_finish_condition]. A `collect_all` world declaring
## no discovery collectibles is uncompletable and is reported as such at
## wire time rather than instantly won.

signal mod_equipped(mod_id: String)
signal gate_changed(gate_kind: String, gate_ref: String, open: bool)
signal resource_delivered(region_id: String, resources_held: int)
signal collectible_collected(collectible_id: String, kind: CollectibleKind.Kind)
signal checkpoint_activated(checkpoint_id: String)
signal life_lost(remaining: int, source: CatastrophicSource.Kind)
signal returned_to_anchor(position: Vector3, checkpoint_id: String)
signal feedback_requested(cue: FeedbackCue)

## The Drift Fleet's world-facing events. The semantic audio id is re-emitted
## rather than resolved here: this node names what happened, the Audio System
## alone decides what it sounds like (REQ-023).
signal audio_cue_requested(cue_id: String)
signal region_dredged(region_id: String)
signal boss_phase_completed(phase_id: String, index: int)
signal boss_phase_reached(volume_name: String)
signal boss_defeated(region_id: String)

const GROUP_SPAWN := "spawn_point"
const GROUP_CHECKPOINT := "checkpoint"
const GROUP_PIT := "pit_volume"
const GROUP_CRUSH := "crush_hazard"
const GROUP_HAZARD := "hazard"
const GROUP_REGEN_STATION := "regen_station"
const GROUP_MOD_PICKUP := "gill_mod_pickup"
const GROUP_AFFORDANCE_GATE := "affordance_gate"
const GROUP_COLLECTIBLE := "collectible"
const GROUP_RESTORATION_GATE := "restoration_gate"
const GROUP_ENEMY := "enemy"
const GROUP_BOSS_PHASE := "boss_phase"
const META_COLLECTIBLE_ID := "collectible_id"
const META_HAZARD_CAPABILITY := "capability"
const META_HAZARD_ID := "hazard_id"
const META_ENEMY_ID := "enemy_id"
const META_REGION_ID := "region_id"
const PLAYER_GROUP := "player"

## The optional Level Contract elements this runtime binds. `enemies` is a
## list of {"enemyId": "<roster id>"} — the world DECLARING which Drift Fleet
## units it uses; a scene node naming an undeclared unit is refused, the same
## way a collectible pickup naming an undeclared id is.
const MANIFEST_ENEMIES := "enemies"
const MANIFEST_BOSS := "boss"
const FIELD_ENEMY_ID := "enemyId"

const FINISH_COLLECT_ALL := "collect_all"

## The trigger slab generated across a checkpoint declared as a bare marker:
## the width of the greybox routes, tall enough to catch a hop, thin along
## the route so it fires where the marker stands. Geometry, not balance.
const CHECKPOINT_TRIGGER_SIZE := Vector3(24.0, 4.0, 2.0)

const TUNING_PATH := "res://core/tuning/tuning.json"
const MODS_DIR := "res://core/gillmod/mods"

## Set by the hub before this node enters the tree.
var manifest: Dictionary = {}

## The world's id — the save namespace collection and checkpoints persist
## into. Empty means an anonymous world (a test scene): state counts for the
## session and is kept nowhere.
var world_id: String = ""

## The Save Integration Interface, when a profile is attached. Null means the
## stores remember nothing beyond this session, honestly.
var save_system: SaveSystem = null

## Installed by the hub: what to call when a system-owned finish condition is
## met. Invalid means nothing listens (a test scene).
var on_finish_condition: Callable = Callable()

var _tuning: TuningData
var _mods: GillModSystem
var _restoration: RestorationSystem
var _collectibles: CollectiblesSystem
var _regen: RegenSystem
var _lives: LifeSystem
var _fleet: DriftFleetSystem
var _flagship: FlagshipEncounter

## Roster ids this world declared. Empty means the world declares no Drift
## Fleet at all, which is the contract's absent default and what the
## reference template ships.
var _declared_enemies: PackedStringArray = PackedStringArray()
var _affordance_gates: Array[Node3D] = []
var _restoration_gates: Dictionary = {}  # gate_id -> Node3D
var _checkpoint_nodes: Array[Node3D] = []
var _spawn_position: Vector3 = Vector3.ZERO


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

	_wire_collectibles()
	_wire_pillar_one()
	# After pillar one: the fleet and the Flagship both reach through Lives
	# and Regeneration, which _wire_pillar_one builds. Before _wire_scene:
	# the scene scan binds enemy nodes to the fleet those two create.
	_wire_drift_fleet()
	_wire_flagship()
	_wire_scene()
	_open_lives()
	_apply_affordance_gates()
	_publish_modifiers()


## The collectibles system over the attached profile (or over nothing), the
## restoration interface it delivers through, and the world's declaration.
func _wire_collectibles() -> void:
	var store := SaveCollectibleStore.new(save_system) if save_system != null \
		else CollectibleStore.new()
	_collectibles = CollectiblesSystem.new(_tuning, store)
	_collectibles.set_restoration(_restoration)
	var errors: Array[CollectibleError] = []
	if not _collectibles.declare_from_manifest(manifest, errors):
		push_warning("WorldSystems: collectible declaration failed: %s"
			% str(errors.map(
				func(e: CollectibleError) -> String: return e.to_string_id())))
	_collectibles.open_world(world_id)
	_collectibles.collected.connect(
		func(collectible_id: String, kind: CollectibleKind.Kind) -> void:
			collectible_collected.emit(collectible_id, kind))
	_collectibles.resources_delivered.connect(
		func(region_id: String, _count: int, _advanced: int) -> void:
			var region := _restoration.get_region(region_id)
			resource_delivered.emit(
				region_id, 0 if region == null else region.get_resources()))

	if _finish_kind() == FINISH_COLLECT_ALL:
		if not _collectibles.is_completable_by_collection():
			push_warning("WorldSystems: finishCondition is collect_all but the "
				+ "world declares no discovery collectibles; it cannot complete")
		_collectibles.collection_completed.connect(_on_collection_completed)


## The Drift Fleet (REQ-012), which had no way into a world at all until now.
##
## DriftFleetSystem's own comment says it "owns no enemy placement and no
## geometry: a world places enemies, and whatever binds the scene calls the
## lanes below". This node IS that binder, and it was the missing half: the
## framework, its roster and its tests were complete while no world could
## reach any of it. Same shape as every other element here — the manifest
## declares, the scene places, this joins the two.
##
## The system is built even when the world declares no enemies, so the
## accessor never hands back null and the tick loop needs no special case;
## with nothing declared it simply has nothing to do.
func _wire_drift_fleet() -> void:
	var registry := EnemyRegistry.new(_tuning)
	var roster_errors: Array[EnemyError] = []
	registry.load_directory(EnemyRegistry.ROSTER_DIRECTORY, roster_errors)
	for error: EnemyError in roster_errors:
		push_warning("WorldSystems: enemy roster: %s" % str(error))

	_fleet = DriftFleetSystem.new(_tuning, registry)
	_fleet.set_gill_mods(_mods)
	_fleet.set_restoration(_restoration)
	_fleet.set_life_system(_lives)
	_fleet.audio_cue_requested.connect(
		func(cue_id: String) -> void: audio_cue_requested.emit(cue_id))
	# A dredger reverting a region is a world event the hub and HUD follow,
	# not something they should have to poll the restoration system for.
	_fleet.region_dredged.connect(
		func(_enemy_id: String, region_id: String) -> void:
			region_dredged.emit(region_id))

	var declared: Variant = manifest.get(MANIFEST_ENEMIES, [])
	if not (declared is Array):
		push_warning("WorldSystems: 'enemies' must be a list; ignoring it")
		return
	for entry: Variant in declared as Array:
		if not (entry is Dictionary):
			push_warning("WorldSystems: each 'enemies' entry must be an object")
			continue
		var enemy_id := String((entry as Dictionary).get(FIELD_ENEMY_ID, ""))
		if not registry.has(enemy_id):
			push_warning("WorldSystems: world declares unknown enemy '%s'"
				% enemy_id)
			continue
		if not (enemy_id in _declared_enemies):
			_declared_enemies.append(enemy_id)


## The Flagship (REQ-013), read from the world's optional `boss` element.
##
## Defeat is the ONLY thing this joins that the encounter cannot do alone:
## the encounter calls RestorationSystem.unlock_region itself, so what is
## added here is the world-facing signal and the phase anchor. A world with
## no boss keeps the auto-unlock above, which is why the reference template
## completes with no encounter at all.
func _wire_flagship() -> void:
	if not manifest.has(MANIFEST_BOSS):
		return
	var declaration: Variant = manifest.get(MANIFEST_BOSS)
	if not (declaration is Dictionary):
		push_warning("WorldSystems: 'boss' must be an object; ignoring it")
		return

	var errors: Array[FlagshipError] = []
	_flagship = FlagshipEncounter.from_declaration(
		declaration as Dictionary, errors)
	if _flagship == null:
		# Contract validation runs before load, so a refusal here is a defect
		# worth hearing about — but it must not take the world down, and the
		# region stays LOCKED rather than silently opening: a boss that failed
		# to build has not been beaten.
		push_warning("WorldSystems: boss declaration refused: %s"
			% str(errors.map(func(e: FlagshipError) -> String: return str(e))))
		return

	_flagship.set_regen(_regen)
	_flagship.set_life_system(_lives)
	_flagship.set_restoration(_restoration)
	_flagship.set_gill_mods(_mods)
	_flagship.phase_completed.connect(
		func(phase_id: String, index: int) -> void:
			boss_phase_completed.emit(phase_id, index))
	_flagship.encounter_defeated.connect(
		func(region_id: String) -> void:
			boss_defeated.emit(region_id))


func get_drift_fleet() -> DriftFleetSystem:
	return _fleet


func get_flagship() -> FlagshipEncounter:
	return _flagship


## Regeneration and Lives, joined the way the architecture declares them:
## Lives takes Regeneration as its CapabilityRestorer, and Regeneration
## publishes onto the controller through the modifier interface. Neither
## reaches into the other.
func _wire_pillar_one() -> void:
	_regen = RegenSystem.new(_tuning)
	_regen.capability_lost.connect(
		func(_kind: Capability.Kind) -> void:
			_publish_modifiers()
			_flinch_player())
	_regen.capability_restored.connect(
		func(_kind: Capability.Kind) -> void: _publish_modifiers())
	_regen.mutation_applied.connect(
		func(_id: String) -> void: _publish_modifiers())
	_regen.mutation_expired.connect(
		func(_id: String) -> void: _publish_modifiers())
	_regen.feedback_requested.connect(_on_feedback_requested)

	_lives = LifeSystem.new(_tuning)
	_lives.set_capability_restorer(_regen)
	_lives.life_lost.connect(_on_life_lost)
	_lives.checkpoint_activated.connect(
		func(checkpoint_id: String) -> void:
			checkpoint_activated.emit(checkpoint_id))
	_lives.respawned.connect(
		func(position: Vector3, checkpoint_id: String, _replenished: int) -> void:
			_return_player_to(position, checkpoint_id))


## Opens the Lives system on the checkpoints the scene declared, IN SCENE
## ORDER — a world author's declaration order is the play order, and the
## replay-time field stays zero because spacing is MEASURED by the walk
## probes, never estimated from geometry (REQ-003 AC-7).
##
## The checkpoint store is attached AFTER open_world on purpose: entry always
## starts from the spawn point (see the class docstring), while activations
## made during play still persist through the Save Integration Interface.
func _open_lives() -> void:
	var graph := CheckpointGraph.new(world_id)
	for node: Node3D in _checkpoint_nodes:
		if not graph.add(Checkpoint.new(node.name, _world_position_of(node), 0.0)):
			push_warning("WorldSystems: checkpoint '%s' refused (duplicate name?)"
				% node.name)
	_lives.open_world(world_id, graph, {})
	if save_system != null:
		_lives.set_checkpoint_store(SaveCheckpointStore.new(save_system))
	_lives.set_spawn_point(_spawn_position)


func _finish_kind() -> String:
	var condition: Variant = manifest.get("finishCondition", {})
	if not (condition is Dictionary):
		return ""
	return String((condition as Dictionary).get("kind", ""))


func get_mods() -> GillModSystem:
	return _mods


func get_restoration() -> RestorationSystem:
	return _restoration


func get_collectibles() -> CollectiblesSystem:
	return _collectibles


func get_regen() -> RegenSystem:
	return _regen


func get_lives() -> LifeSystem:
	return _lives


func get_tuning() -> TuningData:
	return _tuning


func _physics_process(delta: float) -> void:
	if _mods != null:
		_mods.tick(delta)
	if _regen != null:
		_regen.tick(delta)
	if _fleet != null:
		# The entanglement and aura-linger timers live in the fleet precisely
		# so a despawned enemy cannot strand the player debuffed forever —
		# which only holds if something ticks it.
		_fleet.tick(delta)


## The world is going away: the factors this world's regeneration published
## onto the player's controller must not follow the player into the hub.
## Called on tree exit, and explicitly by the hub before it frees a finished
## world so the release never depends on teardown order.
func release_player_factors() -> void:
	var controller := _player_controller()
	if controller == null:
		return
	var modifiers := controller.get_capability_modifiers()
	for factor_id: String in modifiers.get_factor_ids():
		if factor_id.begins_with(RegenSystem.FACTOR_PREFIX):
			modifiers.clear_factor(factor_id)


func _exit_tree() -> void:
	release_player_factors()


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
		if node.is_in_group(GROUP_SPAWN) and node is Node3D:
			_spawn_position = _world_position_of(node as Node3D)
		elif node.is_in_group(GROUP_CHECKPOINT) and node is Node3D:
			_wire_checkpoint_node(node as Node3D)
		elif node.is_in_group(GROUP_PIT) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _on_catastrophe_touched))
		elif node.is_in_group(GROUP_CRUSH) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _on_catastrophe_touched))
		elif node.is_in_group(GROUP_HAZARD) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _on_hazard_touched))
		elif node.is_in_group(GROUP_REGEN_STATION) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _on_station_touched))
		elif node.is_in_group(GROUP_MOD_PICKUP) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _collect_mod))
		elif node.is_in_group(GROUP_COLLECTIBLE) and node is Area3D:
			_wire_collectible_node(node as Area3D)
		elif node.is_in_group(GROUP_AFFORDANCE_GATE) and node is Node3D:
			_affordance_gates.append(node as Node3D)
		elif node.is_in_group(GROUP_RESTORATION_GATE) and node is Node3D:
			var gate_id := String(node.get_meta("gate_id", ""))
			if not gate_id.is_empty():
				_restoration_gates[gate_id] = node
		elif node.is_in_group(GROUP_ENEMY) and node is Area3D:
			_wire_enemy_node(node as Area3D)
		elif node.is_in_group(GROUP_BOSS_PHASE) and node is Area3D:
			(node as Area3D).body_entered.connect(
				_on_pickup_touched.bind(node, _on_boss_phase_touched))


## A checkpoint declared as an Area3D is its own trigger. One declared as a
## bare marker gets a trigger slab generated across it, so the contract's
## "any Node3D in the checkpoint group" stays true for the player too.
func _wire_checkpoint_node(node: Node3D) -> void:
	_checkpoint_nodes.append(node)
	var trigger := node as Area3D
	if trigger == null:
		trigger = Area3D.new()
		trigger.name = "Trigger"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = CHECKPOINT_TRIGGER_SIZE
		shape.shape = box
		trigger.add_child(shape)
		node.add_child(trigger)
	trigger.body_entered.connect(
		_on_pickup_touched.bind(node, activate_checkpoint_node))


## A discovery the profile already records as rescued is not in the world any
## more — the persisted state is what the player SEES on re-entry, not just
## a number. Everything else waits for the player.
func _wire_collectible_node(node: Area3D) -> void:
	var id := String(node.get_meta(META_COLLECTIBLE_ID, ""))
	if _collectibles != null and _collectibles.is_collected(id):
		node.queue_free()
		return
	node.body_entered.connect(_on_pickup_touched.bind(node, collect_node))


## An enemy volume, bound to the lane its ROSTER ENTRY names rather than to
## anything the scene chooses. A scene node carries an id and a position; the
## behaviour is the registry's, so a world cannot invent an effect by placing
## a node — which is the whole point of the sanctioned surface.
##
## An enemy the world never declared is left inert with a warning, exactly
## like a collectible pickup naming an undeclared id. Placing a node is not a
## declaration.
func _wire_enemy_node(node: Area3D) -> void:
	var enemy_id := String(node.get_meta(META_ENEMY_ID, ""))
	if _fleet == null or not (enemy_id in _declared_enemies):
		push_warning("WorldSystems: enemy node '%s' names undeclared unit '%s'"
			% [node.name, enemy_id])
		return
	var enemy := _fleet.get_registry().get_enemy(enemy_id)
	if enemy == null:
		return

	match enemy.behavior:
		EnemyDef.Behavior.TOXIN_AURA:
			# An aura is a VOLUME, not a hit: it applies while the player is
			# inside and lingers after. Both edges matter, so both are bound.
			node.body_entered.connect(
				_on_pickup_touched.bind(node, _on_aura_entered))
			node.body_exited.connect(
				_on_pickup_touched.bind(node, _on_aura_exited))
		EnemyDef.Behavior.DREDGE:
			node.body_entered.connect(
				_on_pickup_touched.bind(node, _on_dredger_touched))
		_:
			# Entangle and snag both land through the one contact lane; the
			# registry decides which, and the affordance counters live there.
			node.body_entered.connect(
				_on_pickup_touched.bind(node, _on_enemy_contact))


## The declared unit a scene node stands for, or "" if the node names one the
## world never declared.
##
## Checked on every lane rather than only at wiring time. The wiring check
## alone left the rule resting on "nothing else ever calls these" — and the
## probes and tests DO drive these seams directly, which is exactly how an
## undeclared unit would have slipped through with full effect.
func _declared_unit_of(enemy_node: Node) -> String:
	var enemy_id := String(enemy_node.get_meta(META_ENEMY_ID, ""))
	if _fleet == null or not (enemy_id in _declared_enemies):
		return ""
	return enemy_id


## Contact with an entangling or snagging unit. Driven through the same
## deferred seam every other volume uses, so a probe can drive it without
## physics.
func _on_enemy_contact(enemy_node: Node) -> void:
	var enemy_id := _declared_unit_of(enemy_node)
	if not enemy_id.is_empty():
		_fleet.contact(enemy_id)


## A Dredger strikes the region its node names, reverting restored terrain
## (REQ-008 AC-5). The region is the SCENE's to name because which stretch of
## reef a dredger sits over is placement, not roster data.
func _on_dredger_touched(enemy_node: Node) -> void:
	var enemy_id := _declared_unit_of(enemy_node)
	if enemy_id.is_empty():
		return
	var region_id := String(enemy_node.get_meta(META_REGION_ID, ""))
	if region_id.is_empty():
		push_warning("WorldSystems: dredger '%s' names no region"
			% enemy_node.name)
		return
	_fleet.strike_region(enemy_id, region_id)


func _on_aura_entered(enemy_node: Node) -> void:
	var enemy_id := _declared_unit_of(enemy_node)
	if not enemy_id.is_empty():
		_fleet.enter_aura(enemy_id)


func _on_aura_exited(enemy_node: Node) -> void:
	var enemy_id := _declared_unit_of(enemy_node)
	if not enemy_id.is_empty():
		_fleet.exit_aura(enemy_id)


## A boss phase volume: reaching it clears the current phase, IF the player
## arrives in the grammar that phase demands.
##
## The grammar is read from the player at the moment of contact rather than
## declared on the volume, because that is the whole point of AC-3 — a
## water-only phase must be cleared while actually swimming. The encounter
## itself refuses a phase whose affordance is not active, so this hands over
## the fact and lets the declaration decide.
##
## This is the seam that makes the Flagship DRIVABLE from a scene at all: the
## encounter's phase logic was complete and reachable only from a test.
func _on_boss_phase_touched(volume: Node) -> void:
	if _flagship == null:
		return
	var controller := _player_controller()
	if controller == null:
		return
	if not _flagship.complete_phase(controller.get_grammar()):
		# Not a defect: arriving on land at a water phase is the gate doing
		# its job, and the player simply has to come back the right way.
		return
	boss_phase_reached.emit(String(volume.name))


func _on_pickup_touched(body: Node3D, pickup: Node, handler: Callable) -> void:
	# body_entered fires during the physics flush; everything a pickup does —
	# freeing itself, toggling a barrier's collision, moving the player —
	# mutates state the flush is iterating, so the whole reaction is deferred
	# out of it.
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


## Collects the collectible a scene node stands for. Public so the seam can
## be driven without physics; the pickup volume calls it deferred. Returns
## false, leaving the node in place, for an undeclared id.
func collect_node(pickup: Node) -> bool:
	var id := String(pickup.get_meta(META_COLLECTIBLE_ID, ""))
	if _collectibles == null or not _collectibles.collect(id):
		push_warning("WorldSystems: pickup names unknown collectible '%s'" % id)
		return false
	pickup.queue_free()
	return true


func _on_collection_completed() -> void:
	if on_finish_condition.is_valid():
		on_finish_condition.call()


# --- Pillar one: the seams a scene node drives --------------------------------

## Activates the checkpoint a scene node stands for (its id is its name).
## Public so the seam can be driven without physics.
##
## The ACTIVE checkpoint does not re-activate: a respawn lands the player
## inside its own trigger, and re-activating there would refill the life the
## pit just cost — the stakes layer would be free. Reaching a DIFFERENT
## checkpoint (forward, or back to an earlier one) activates as normal.
func activate_checkpoint_node(node: Node) -> bool:
	if _lives == null or _lives.get_active_checkpoint() == node.name:
		return false
	return _lives.activate_checkpoint(node.name)


## A pit or crush volume: the closed catastrophic set decides whether a life
## is spent, and any spent life returns the player to the last anchor.
func _on_catastrophe_touched(volume: Node) -> void:
	var source_id := CatastrophicSource.id(CatastrophicSource.Kind.CRUSH_HAZARD) \
		if volume.is_in_group(GROUP_CRUSH) \
		else CatastrophicSource.id(CatastrophicSource.Kind.PIT_VOLUME)
	report_catastrophe(source_id)


## Reports a catastrophe by source id. Returns false, changing nothing, for
## any id outside CatastrophicSource's closed set — an ordinary hazard cannot
## reach this by any spelling (REQ-003 AC-2).
func report_catastrophe(source_id: String) -> bool:
	return _lives != null and _lives.report_catastrophe(source_id)


func _on_life_lost(remaining: int, source: CatastrophicSource.Kind) -> void:
	life_lost.emit(remaining, source)
	# At zero the Lives system respawns (and refills) on its own; any other
	# spent life still returns the player to the anchor — a catastrophe is a
	# setback every time, not only the last time.
	if remaining > 0:
		_return_player_to(_lives.get_respawn_position(),
			_lives.get_active_checkpoint())


## An ordinary hazard strips the capability it names. Public so the seam can
## be driven without physics. Returns false for an unknown capability id, for
## a capability already lost, or for a hazard trying to smuggle a catastrophe
## through this lane.
func apply_hazard_node(hazard: Node) -> bool:
	var kind := _capability_from_id(
		String(hazard.get_meta(META_HAZARD_CAPABILITY, "")))
	if kind < 0:
		push_warning("WorldSystems: hazard '%s' names no capability" % hazard.name)
		return false
	var source := String(hazard.get_meta(META_HAZARD_ID, hazard.name))
	return _regen != null and _regen.apply_damage(
		DamageEvent.new(source, kind as Capability.Kind, false))


func _on_hazard_touched(hazard: Node) -> void:
	apply_hazard_node(hazard)


func _on_station_touched(_station: Node) -> void:
	if _regen != null:
		_regen.restore_all()


static func _capability_from_id(text: String) -> int:
	for kind: Capability.Kind in Capability.ALL:
		if Capability.id(kind) == text:
			return int(kind)
	return -1


## Moves the player to an anchor and drops the motion that carried them into
## the catastrophe: arriving back already moving is how a respawn becomes a
## second fall (the greybox fall guard learned this first).
func _return_player_to(position: Vector3, checkpoint_id: String) -> void:
	var player := _player()
	if player != null:
		_place_at(player, position)
		var body := player as AxolotlBody
		if body != null:
			body.velocity = Vector3.ZERO
			if body.get_input_system() != null:
				body.get_input_system().clear()
			if body.get_controller() != null:
				body.get_controller().set_velocity(Vector3.ZERO)
				body.get_controller().sync_body_position(position)
	returned_to_anchor.emit(position, checkpoint_id)


## The visual half of a capability loss. The runtime already knows the moment
## it happens; the body owns how the axolotl reacts to it, so this only asks.
## A world running without a rigged player (the walk probes build bare
## bodies) simply has nothing to flinch.
func _flinch_player() -> void:
	var body := _player() as AxolotlBody
	if body != null:
		body.play_hurt()


func _player() -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node3D
	if player != null:
		return player
	# Group registration happens on tree entry; before the tree iterates (the
	# test runner) a node's own group list is still authoritative.
	for node: Node in tree.root.find_children("*", "", true, false):
		if node.is_in_group(PLAYER_GROUP) and node is Node3D:
			return node as Node3D
	return null


## A node's position in tree space, composed up the parent chain. Equivalent
## to global_position once the tree is running, and still correct BEFORE it
## is (the test runner builds worlds ahead of the first iteration, when
## global_position is not yet available).
static func _world_position_of(node: Node3D) -> Vector3:
	var transform := node.transform
	var parent := node.get_parent()
	while parent is Node3D:
		transform = (parent as Node3D).transform * transform
		parent = parent.get_parent()
	return transform.origin


## Places a node at a tree-space position through the same parent chain.
static func _place_at(node: Node3D, world_position: Vector3) -> void:
	var parent_transform := Transform3D.IDENTITY
	var parent := node.get_parent()
	while parent is Node3D:
		parent_transform = (parent as Node3D).transform * parent_transform
		parent = parent.get_parent()
	node.position = parent_transform.affine_inverse() * world_position


func _player_controller() -> AxolotlController:
	var body := _player() as AxolotlBody
	return null if body == null else body.get_controller()


## The Capability Modifier Interface: this world's regeneration state, as
## factors on the player's controller. Republished on every change.
func _publish_modifiers() -> void:
	var controller := _player_controller()
	if controller == null:
		return
	var modifiers := controller.get_capability_modifiers()
	if _regen != null:
		_regen.publish_to(modifiers)
	if _fleet != null:
		# Handed over HERE rather than at wire time because the player may not
		# exist yet when a world is built (the walk probes construct the world
		# first). This runs at the end of wiring and again on every change, so
		# the fleet gets the modifier interface as soon as there is one.
		_fleet.set_capability_modifiers(modifiers)


## Every loss and regrowth asks for both channels (REQ-019 AC-2). The audio
## half is the Audio System's once assets exist; the visual half gets a
## sparkle burst at the player — comedic pop, greybox edition.
func _on_feedback_requested(cue: FeedbackCue) -> void:
	feedback_requested.emit(cue)
	var player := _player()
	if player == null:
		return
	var burst := CPUParticles3D.new()
	burst.name = "FeedbackBurst"
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 0.6
	burst.spread = 180.0
	burst.initial_velocity_min = 2.5
	burst.initial_velocity_max = 4.5
	burst.gravity = Vector3(0.0, -3.0, 0.0)
	burst.scale_amount_min = 0.08
	burst.scale_amount_max = 0.16
	burst.color = Color(1.0, 0.85, 0.3) if cue.visual_id.begins_with("vfx.pop") \
		else Color(0.6, 1.0, 0.8)
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	burst.mesh = mesh
	_world_root().add_child(burst)
	_place_at(burst, _world_position_of(player) + Vector3(0.0, 0.8, 0.0))
	burst.emitting = true
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(burst.lifetime + 0.2).timeout.connect(burst.queue_free)


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
