extends Node
## Development scene adapter; normal world/session integration is Chunk 7.
## Uses the existing save format and restoration system in an isolated profile.
const WORLD := "living_cascade_development_v1"
const REGION := "coral_shelf"
@export var save_path := "user://living_cascade_development_v1.json"
var save := SaveSystem.new()
var restoration: RestorationSystem
var collectibles: CollectiblesSystem
var taken: Dictionary = {}
var checkpoint := ""
var recoveries := 0
var completed := false
var finish_events := 0
var _areas: Dictionary = {}
var _body: AxolotlBody
var _scene: Node3D
var _garden: Node3D
var _terraces: Node3D
var _save_healthy := true

func _ready() -> void:
	_scene = get_parent() as Node3D
	_body = _scene.get_node("Axolotl") as AxolotlBody
	_garden = _scene.get_node("Sections/S05/RestorationGarden") as Node3D
	_terraces = _scene.get_node("Sections/S04/Terraces") as Node3D
	if not save_path.is_empty() and FileAccess.file_exists(save_path):
		var errors: Array[SaveError] = []
		_save_healthy = save.load_from_file(save_path, errors)
		if not _save_healthy:
			push_warning("Development save could not load; preserving its file: " + str(errors))
	save.open_world(WORLD, {"regions":[REGION], "checkpoints":["CP_01","CP_02","CP_03"], "collectibles":["tide_pearl"]})
	var data := save.get_world_data(WORLD)
	taken = data.get("cascadeSeedInstances", {}) as Dictionary
	checkpoint = String(data.get("lastCheckpoint", ""))
	completed = bool(data.get("completed", false))
	var tuning := TuningData.load_from_file(TuningData.DEFAULT_TUNING_PATH)
	var tuning_errors: Array[TuningError] = []
	if not tuning.apply_world_overrides({"restoration.resourced.resource_cost":3,"restoration.restored.resource_cost":4},tuning_errors):
		push_error(str(tuning_errors))
		return
	restoration = RestorationSystem.new(tuning, SaveRestorationStore.new(save,WORLD))
	var restoration_errors: Array[RestorationError] = []
	if not restoration.declare_from_manifest({"restorableRegions":[{"regionId":REGION,"unlockedBy":"entry","traversalGates":[{"gateId":"cascade_finale","opensAt":"restored"}]}]},restoration_errors):
		push_error(str(restoration_errors))
		return
	restoration.load_saved()
	restoration.unlock_region(REGION)
	collectibles = CollectiblesSystem.new(tuning, SaveCollectibleStore.new(save))
	collectibles.set_restoration(restoration)
	var collectible_errors: Array[CollectibleError] = []
	if not collectibles.declare_from_manifest({"collectibles":[{"collectibleId":"kelp_seed","kind":"resource","regionId":REGION},{"collectibleId":"tide_pearl","kind":"discovery","displayName":"Tide pearl"}]},collectible_errors):
		push_error(str(collectible_errors))
		return
	collectibles.open_world(WORLD)
	for name: String in ["SeedA","SeedB"]:
		register_seed("terrace_"+name, _terraces.get_node(name) as Area3D)
	for i in range(1,8):
		register_seed("garden_%d" % i, _garden.get_node("Seed%d" % i) as Area3D)
	update_presentation()
	setup_finish()
	if not checkpoint.is_empty():
		call_deferred("recover_player")

func register_seed(id: String, area: Area3D) -> void:
	_areas[id] = area
	area.body_entered.connect(_on_seed.bind(id))
	if taken.has(id):
		area.hide()
		area.set_deferred("monitoring",false)

func _on_seed(body: Node3D, id: String) -> void:
	if body != _body or taken.has(id):
		return
	if not collectibles.collect("kelp_seed"):
		return
	# Resource definitions are types, so persist the placed instance separately.
	# Record the instance and resulting balance/state in the same atomic save.
	taken[id] = true
	var area := _areas[id] as Area3D
	area.hide()
	area.set_deferred("monitoring",false)
	commit()
	update_presentation()

func commit() -> bool:
	restoration.save()
	save.put_world_data(WORLD,{"cascadeSeedInstances":taken.duplicate(),"lastCheckpoint":checkpoint,"completed":completed})
	if save_path.is_empty():
		return true
	if not _save_healthy:
		return false
	var ok := save.save_to_file(save_path)
	if not ok:
		push_warning("Development progress could not be saved.")
	return ok

func update_presentation() -> void:
	var state := restoration.get_state(REGION)
	var open := state == RegionState.State.RESTORED
	(_garden.get_node("Gate/Collision") as CollisionShape3D).set_deferred("disabled",open)
	(_garden.get_node("Gate/Mesh") as MeshInstance3D).visible = not open
	var color := Color(0.38,0.40,0.30)
	if state == RegionState.State.RESOURCED:
		color = Color(0.35,0.69,0.38)
	elif open:
		color = Color(1.0,0.66,0.55)
	for i in range(6):
		var crown := _garden.get_node("Crown%d" % i) as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		crown.material_override = mat
		crown.scale = Vector3.ONE * (0.55 + float(state)*0.25)
	var banked := restoration.get_region(REGION).get_resources()
	(_garden.get_node("Status") as Label3D).text = "GARDEN / %s\nSeeds found: %d / 9   Banked: %d\n%s" % [RegionState.id(state).to_upper(),taken.size(),banked,"The waterfall gate is open." if open else "Gather seeds: restore automatically at 3, then 7 total."]
	var terrace_count := int(taken.has("terrace_SeedA"))+int(taken.has("terrace_SeedB"))
	_terraces.set("seeds_collected",terrace_count)
	(_terraces.get_node("Status") as Label3D).text = "TERRACE SEEDS: %d / 2\nJOIN 45 / Enter the restoration garden." % terrace_count

func _physics_process(_delta: float) -> void:
	if _body == null or restoration == null:
		return
	var p := _body.global_position
	# Solid foundation is the final physical backstop; recover before landing there.
	if p.y < -3.1 or p.x < -42 or p.x > 40 or p.z < -127 or p.z > 6:
		recover_player()
		return
	if not _body.is_on_floor() or _body.is_in_water():
		return
	for id: String in ["CP_01","CP_02","CP_03"]:
		if id <= checkpoint:
			continue
		var marker := _scene.find_child(id,true,false) as Marker3D
		var support := marker.global_position
		if absf(p.x-support.x) <= 2.0 and absf(p.z-support.z) <= 2.0 and absf(p.y-support.y-0.8) < 0.3:
			checkpoint = id
			commit()

func recover_player() -> void:
	var target := Vector3(0,-0.4,1)
	if not checkpoint.is_empty():
		var marker := _scene.find_child(checkpoint,true,false) as Marker3D
		if marker != null:
			target = marker.global_position + Vector3.UP*0.85
	_body.get_input_system().clear()
	_body.clear_water_contacts()
	_body.global_position = target
	_body.velocity = Vector3.ZERO
	_body.get_controller().set_velocity(Vector3.ZERO)
	_body.resample_water_contacts()
	recoveries += 1

func _exit_tree() -> void:
	# Release the declaration graph before dropping the owning session.
	# Region signal closures retain their RestorationSystem until cleared.
	if collectibles != null:
		collectibles.set_restoration(null)
	if restoration != null:
		restoration.declare_from_manifest({})
	_areas.clear()

func setup_finish() -> void:
	var errors: Array[HubError] = []
	if not WorldLoader.new().wire_finish_condition(_scene,WorldLoader.REACH_VOLUME,_on_finished,errors):
		push_error(str(errors))
	var pearl := _scene.get_node("Sections/S06/Chute/TidePearl") as Area3D
	pearl.body_entered.connect(_on_pearl)
	if collectibles.is_collected("tide_pearl"):
		pearl.hide()
		pearl.set_deferred("monitoring",false)
	if completed:
		(_scene.get_node("Sections/S06/Chute/FinishLabel") as Label3D).text = "LIVING CASCADE / COMPLETE\nProgress saved in the development profile."

func _on_finished() -> void:
	if completed:
		return
	completed = true
	finish_events += 1
	commit()
	(_scene.get_node("Sections/S06/Chute/FinishLabel") as Label3D).text = "LIVING CASCADE / COMPLETE\nYou restored the garden and reached the calm bank."

func _on_pearl(body: Node3D) -> void:
	if body != _body or not collectibles.collect("tide_pearl"):
		return
	var pearl := _scene.get_node("Sections/S06/Chute/TidePearl") as Area3D
	pearl.hide()
	pearl.set_deferred("monitoring",false)
	(_scene.get_node("Sections/S06/Chute/PearlLabel") as Label3D).text = "TIDE PEARL / FOUND"
	commit()