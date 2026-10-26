extends SceneTree
var passed := 0
var failed := 0
func check(ok: bool,message: String) -> void:
	if ok:passed+=1;print("PASS ",message)
	else:failed+=1;push_error(message)
func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var body := load("res://core/controller/axolotl_body.tscn").instantiate() as AxolotlBody
	root.add_child(body)
	body.set_physics_process(false)
	var sound := body.get_node("Soundscape")
	var background := sound.get("background") as AudioStreamPlayer
	var groove := sound.get("groove") as AudioStreamPlayer
	var music_bus := AudioServer.get_bus_index("Music")
	var effects_bus := AudioServer.get_bus_index("Effects")
	var music_gain := AudioServer.get_bus_volume_db(music_bus)
	var effects_gain := AudioServer.get_bus_volume_db(effects_bus)
	check(background.stream is AudioStreamOggVorbis,"recorded score loads as compressed Ogg")
	check((background.stream as AudioStreamOggVorbis).loop,"exploration loop enabled")
	check(absf(background.stream.get_length()-(48.0*4.0*60.0/104.0))<0.05,"complete 48-bar track imported at 104 BPM")
	check(background.bus=="Music","music respects the Music bus")
	check(groove.stream.resource_path.ends_with("crayfish_groove.wav"),"separate shuffle stream retained")
	await wait_seconds(1.55)
	check(background.playing and absf(background.volume_db+10.0)<0.05,"quiet land playback fades in")
	sound.call("_water_changed",true)
	await wait_seconds(0.8)
	check(absf(background.volume_db+13.0)<0.05,"water mix smoothly settles 3 dB lower")
	sound.call("set_dancing",true)
	await wait_seconds(0.3)
	check(groove.playing and absf(background.volume_db+44.0)<0.05,"dance ducks exploration without replacing shuffle")
	sound.call("_water_changed",false)
	await wait_seconds(0.15)
	check(absf(background.volume_db+44.0)<0.05,"shore transition cannot un-duck an active dance")
	sound.call("set_dancing",false)
	await wait_seconds(0.75)
	check(not groove.playing and absf(background.volume_db+10.0)<0.05,"ending dance restores the current land mix")
	background.seek(background.stream.get_length()-0.2)
	await wait_seconds(0.55)
	check(background.playing and background.get_playback_position()<1.0,"actual playback wraps across the end of the score")
	check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus),music_gain) and is_equal_approx(AudioServer.get_bus_volume_db(effects_bus),effects_gain),"music changes preserve user bus volumes")
	body.queue_free();await process_frame
	print("EXPLORATION MUSIC: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
