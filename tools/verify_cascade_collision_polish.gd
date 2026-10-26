extends SceneTree
## Real input through the shipped player capsule, in both directions and off-center.
var world: Node3D
var body: AxolotlBody
var held: Dictionary = {}
var failures: PackedStringArray = []
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func key(code: Key, down: bool) -> void:
	if bool(held.get(code, false)) == down: return
	held[code] = down
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func release() -> void:
	for code: Key in [KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE, KEY_SHIFT]: key(code, false)
func reset(p: Vector3) -> void:
	release()
	body.get_input_system().clear()
	body.clear_water_contacts()
	body.position = p
	body.velocity = Vector3.ZERO
	body.get_controller().set_velocity(Vector3.ZERO)
	body.get_controller().sync_body_position(p)
	body.resample_water_contacts()
	for i in range(3): await physics_frame
func travel(target: Vector3, swim: bool) -> bool:
	for i in range(420):
		var delta := target - body.position
		if Vector2(delta.x, delta.z).length() < 0.42 and (not swim or absf(delta.y) < 0.4):
			release()
			return true
		key(KEY_A, delta.x < -0.14); key(KEY_D, delta.x > 0.14)
		key(KEY_W, delta.z < -0.14); key(KEY_S, delta.z > 0.14)
		key(KEY_SPACE, swim and delta.y > 0.14); key(KEY_SHIFT, swim and delta.y < -0.14)
		await physics_frame
	release()
	for j in body.get_slide_collision_count():
		print("BLOCKED ", body.get_slide_collision(j).get_collider().get_path(), " target ", target)
	return false
func run() -> void:
	var stage := Node3D.new(); root.add_child(stage)
	world = load("res://worlds/coral_cove/world.tscn").instantiate() as Node3D
	stage.add_child(world)
	body = load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	stage.add_child(body)
	await physics_frame
	# Enemy AI isn't wired in this fixture; the separate combat regression covers it.
	for row: Array in [["S03_EntryTunnel", -1.6, 3.5, 0.65], ["S03_MiddleTunnel", -1.6, 3.5, 0.65], ["S03_ExitTunnel", -1.6, 3.5, 0.65], ["S03_GrottoArch", -1.6, 3.5, 0.65], ["S04_DiveArch", 2.1, 2.3, 0.3], ["S06_DiveTunnel", 1.7, 3.0, 0.65]]:
		var arch := world.get_node("SuppliedAssets/" + String(row[0])) as Node3D
		for offset: float in [-float(row[3]), 0.0, float(row[3])]:
			var a := arch.to_global(Vector3(offset, 0, float(row[2])))
			var b := arch.to_global(Vector3(offset, 0, -float(row[2])))
			# This is a pocket grotto, not a through tunnel: stop before its solid
			# back wall, which must continue containing the player.
			if row[0] == "S03_GrottoArch": b = arch.to_global(Vector3(offset, 0, -2.7))
			a.y = float(row[1]); b.y = float(row[1])
			for reverse: bool in [false, true]:
				await reset(b if reverse else a)
				var ok := await travel(a if reverse else b, true)
				check(ok, "%s lane %.2f reverse=%s stopped=%s" % [row[0], offset, reverse, body.position])
	for rock: Node3D in world.get_node("SuppliedAssets").get_children():
		if not rock.has_meta("landing_support_y"): continue
		var center := Vector3(rock.position.x, float(rock.get_meta("landing_support_y")) + 0.85, rock.position.z)
		for direction: Vector3 in [Vector3.RIGHT, Vector3.FORWARD, Vector3(1, 0, 1).normalized()]:
			await reset(center - direction * 0.85)
			var ok := await travel(center + direction * 0.85, false)
			check(ok and body.is_on_floor(), "rock crossing " + String(rock.name) + " " + str(direction))
	print("CASCADE COLLISION MOVEMENT: ", checks - failures.size(), "/", checks, " passed")
	for failure: String in failures: print("FAIL ", failure)
	release()
	stage.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
