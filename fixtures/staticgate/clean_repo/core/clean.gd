extends Node

## FIXTURE — deliberately CLEAN, and the anti-vacuity control for the gate.
##
## Every banned identifier appears in this file, and not one of them is code.
## They sit in comments, in single- and double-quoted strings, in a
## triple-quoted block, and behind escaped quotes. A gate that greps raw source
## flags all of them and is unusable, because this project's own contracts,
## docs and test files discuss the ban constantly — the explanation of a rule
## must never be reported as a violation of it.
##
## Mentioned here on purpose: @rpc, rpc_id, rpc_config, MultiplayerAPI,
## SceneMultiplayer, MultiplayerSynchronizer, MultiplayerSpawner,
## ENetMultiplayerPeer, WebRTCMultiplayerPeer, is_multiplayer_authority,
## set_multiplayer_authority, FileAccess, OS.execute, Expression.

const BANNED_DOC := "This project forbids @rpc and rpc_id entirely."
const SINGLE_QUOTED := 'MultiplayerSpawner and MultiplayerSynchronizer are banned.'
const ESCAPED := "the annotation is written \"@rpc\" and never used"

const LONG_NOTE := """
Godot's own documentation demonstrates is_multiplayer_authority() and
ENetMultiplayerPeer.create_server(). That guidance does not apply here.
A MultiplayerAPI reference in prose is not a MultiplayerAPI call.
"""


func explain() -> String:
	# Even here: rpc_config, OS.execute, FileAccess, Expression, str2var.
	var note := "see contracts/engine_feature_policy.v1.json for the full list"
	return note + BANNED_DOC + SINGLE_QUOTED + ESCAPED + LONG_NOTE


func do_ordinary_work(delta: float) -> float:
	var velocity := 1.0
	velocity += delta
	return velocity
