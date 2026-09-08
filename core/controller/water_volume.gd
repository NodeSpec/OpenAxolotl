@tool
class_name WaterVolume
extends Area3D

## A region of water, placed by a world (REQ-001 AC-1, REQ-034, REQ-039).
##
## Which grammar the axolotl is in is a property of WHERE IT IS, so a world
## declares water by placing a volume rather than by scripting a state change.
## That is the same shape CameraHintVolume uses for framing, and it is what lets
## a contributor build a lagoon without touching controller code.
##
## The volume tells the body it entered; the body counts overlaps and the
## controller decides what a grammar change means. Nothing here knows about
## swimming — a volume that tried to set the grammar directly would be a second
## authority on the transition, and the momentum carry would depend on which one
## ran first.
##
## THE SURFACE NEEDS NOTHING FROM HERE. The shared water shader damps its waves
## to nothing at the volume's rim and puts a band of surf there, and it works
## that out from the mesh's own face-local coordinates rather than from
## anything this node publishes. That was not the first design: the extents
## went out as an instance uniform, which is correct in the game and silently
## dropped by the headless renderer — right in play, untestable in CI. A volume
## is still just a box somebody placed.
##
## WHAT IT ANNOUNCES. Crossing the surface is the most physical thing that
## happens in this game and for a long time it happened in silence: the grammar
## changed, the animation changed, and the water itself did not react at all.
## Entering and leaving now raise a splash at the crossing point through
## WaterSplash, and ask for an audio cue by NAME — never a file path, because
## the Audio System alone decides what water sounds like (REQ-023).
##
## `@tool` so the shape is visible while editing. It does nothing in the editor
## beyond existing.

signal body_entered_water(body: AxolotlBody)
signal body_exited_water(body: AxolotlBody)

## Semantic audio ids, resolved by the Audio System. A dive and a surfacing are
## different sounds — one is a body arriving, the other is water closing behind
## it — so they are different ids rather than one "splash".
const CUE_ENTER := "water_enter"
const CUE_EXIT := "water_exit"

signal audio_cue_requested(cue_id: String)

## Below this vertical speed a crossing is a wade rather than a plunge, and it
## gets the smaller splash. A number rather than a boolean because the two ends
## of it are genuinely different events: stepping off a shore into shallows
## should not throw the same sheet of water as falling in from a ledge.
const PLUNGE_SPEED := 6.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	axolotl.enter_water()
	_splash(axolotl, true)
	body_entered_water.emit(axolotl)


func _on_body_exited(body: Node3D) -> void:
	var axolotl := body as AxolotlBody
	if axolotl == null:
		return
	axolotl.exit_water()
	_splash(axolotl, false)
	body_exited_water.emit(axolotl)


## Raises a splash where the body met the surface.
##
## AT THE SURFACE, NOT AT THE BODY. A player who dives in fast is already half
## a metre under by the frame the area reports it, and a splash centred on them
## appears underwater where nobody sees it. The crossing point is the body's
## own x and z at the height of this volume's top face, which is where the
## water was actually disturbed.
func _splash(body: AxolotlBody, entering: bool) -> void:
	var top := _surface_height()
	if is_inf(top):
		return
	var at := Vector3(body.global_position.x, top, body.global_position.z)
	var speed := absf(body.velocity.y)

	# DEFERRED, because this is inside the physics flush. body_entered fires
	# while the physics server is iterating its own state, and adding a node
	# to the tree during that is refused outright — "parent node is busy
	# setting up children" — so the splash simply never appeared. Every other
	# reaction to a volume in this game is deferred for the same reason; the
	# splash is the newest one to learn it.
	#
	# The crossing is measured NOW and the effect raised next frame: a
	# deferred call that read the body's velocity when it finally ran would
	# read it a frame late, by which point a dive has already changed speed.
	#
	# Through a method on this node rather than a bound Callable on
	# WaterSplash's static: binding one failed at runtime, and because it
	# failed INSIDE the crossing handler it took the rest of the handler with
	# it — the water grammar still switched, and every signal after this line
	# silently stopped being emitted.
	_raise_splash.call_deferred(at, speed, speed >= PLUNGE_SPEED)
	audio_cue_requested.emit(CUE_ENTER if entering else CUE_EXIT)


func _raise_splash(at: Vector3, speed: float, plunging: bool) -> void:
	WaterSplash.erupt(self, at, speed, plunging)


## The world height of this volume's top face, or INF when it has no box to
## take one from.
func _surface_height() -> float:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var box := (node as MeshInstance3D).mesh as BoxMesh
		if box != null:
			return (node as Node3D).global_position.y + box.size.y * 0.5
	return INF
