extends CharacterBody3D

## FIXTURE — deliberately forbidden. REQ-030 AC-3.
##
## Exercises every banned multiplayer class in one file, so a gate that stopped
## detecting one class cannot hide behind the others still firing. This is a
## near-verbatim copy of the RPC/server-authority sample the NodeSpec catalog
## injects into this project's own Godot node packets, which is precisely the
## code an agent following ordinary Godot idiom would write.
##
## Never imported by Godot: fixtures/ carries a .gdignore.

var peer := ENetMultiplayerPeer.new()
var fallback := WebSocketMultiplayerPeer.new()
var offline := OfflineMultiplayerPeer.new()
var api: MultiplayerAPI = null


func _ready() -> void:
	peer.create_client("127.0.0.1", 7777)
	multiplayer.multiplayer_peer = peer
	set_multiplayer_authority(1)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var input := Vector2.ZERO
	move_intent.rpc_id(1, input)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func move_intent(input: Vector2) -> void:
	if get_multiplayer_authority() != 1:
		return
	velocity = Vector3(input.x, 0.0, input.y)


func _configure() -> void:
	rpc_config("move_intent", {})
	rpc("move_intent", Vector2.ZERO)
