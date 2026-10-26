extends Node3D
# Development-only pickup wiring. Uses the real collectible rules with an
# in-memory store, so prototype testing never changes a saved Coral Cove profile.
@export var collectible_id: String = "hermit_snail"
@export var display_name: String = "Hermit snail"
signal rescue_collected
var collectibles: CollectiblesSystem
var rescued := false

func _ready() -> void:
	var tuning := TuningData.load_from_file("res://core/tuning/tuning.json")
	collectibles = CollectiblesSystem.new(tuning)
	var errors: Array[CollectibleError] = []
	if not collectibles.declare_from_manifest({
		"collectibles": [{"collectibleId": collectible_id, "kind": "discovery",
			"displayName": display_name}]}, errors):
		push_error(str(errors))
		return
	collectibles.open_world("living_cascade_preview")
	var area := get_node("Rescue") as Area3D
	area.body_entered.connect(_on_rescue_touched)

func _on_rescue_touched(body: Node3D) -> void:
	if not body is AxolotlBody or rescued:
		return
	if not collectibles.collect(collectible_id):
		return
	rescued = true
	var area := get_node("Rescue") as Area3D
	area.hide()
	area.set_deferred("monitoring", false)
	(get_node("RescueLabel") as Label3D).text = display_name.to_upper() + " RESCUED"
	rescue_collected.emit()

