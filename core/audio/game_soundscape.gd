extends Node
## Owns audible playback for the real hero; follows the hero across world transitions.
const DIR:="res://assets/audio/cascade/"
const EXPLORATION_PATH := "res://assets/audio/exploration/quiet_currents.ogg"
const LAND_MUSIC_DB := -10.0
const WATER_MUSIC_DB := -13.0
const DANCE_DUCK_DB := -44.0
var body: AxolotlBody
var audio: AudioSystem
var background: AudioStreamPlayer
var groove: AudioStreamPlayer
var _step_clock:=0.0
var _last_water:=false
var _mix: Tween
var _bed_mix: Tween
var _dancing := false
func _ready() -> void:
	body=get_parent() as AxolotlBody
	for bus: String in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://core/audio/default_bank.json")) as Dictionary
	var defaults: Dictionary=(raw["cues"] as Dictionary).duplicate();defaults.merge(raw["beds"] as Dictionary)
	var bank:=AudioBank.resolve(defaults,{})
	if bank==null:return
	audio=AudioSystem.new(bank,GodotAudioSink.new(self))
	background=AudioStreamPlayer.new()
	background.name="ExplorationMusic"
	background.bus="Music"
	background.stream=loop_stream(EXPLORATION_PATH)
	background.volume_db=-60.0
	add_child(background)
	background.play()
	_last_water=body.is_in_water()
	_fade_background(1.4)
	groove=AudioStreamPlayer.new();groove.name="DanceMusic";groove.bus="Music";groove.stream=load(DIR+"crayfish_groove.wav") as AudioStream;groove.volume_db=-3.;add_child(groove)
	audio.set_grammar(body.is_in_water())
	body.water_state_changed.connect(_water_changed)
	body.strike_opened.connect(func(kind: CombatStrike.Kind,_origin: Vector3,_reach: float) -> void:
		play(&"tail_whack" if kind==CombatStrike.Kind.TAIL_WHACK else (&"spin_charge" if kind==CombatStrike.Kind.SPIN_SPRINT else &"landing")))
	body.get_controller().hopped.connect(func() -> void:audio.play_movement(AudioEvent.Movement.LEAP))
	body.get_controller().rolled.connect(func() -> void:play(&"slide"))

static func loop_stream(path: String) -> AudioStream:
	var original := load(path) as AudioStream
	if original == null:
		push_error("[audio.stream_missing] "+path)
		return null
	var stream := original.duplicate() as AudioStream
	if stream is AudioStreamWAV:
		var wav:=stream as AudioStreamWAV;wav.loop_mode=AudioStreamWAV.LOOP_FORWARD;wav.loop_begin=0;wav.loop_end=roundi(wav.get_length()*wav.mix_rate)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop=true
		(stream as AudioStreamOggVorbis).loop_offset=0.0
	return stream

func play(id: StringName) -> void:
	if audio==null:return
	for cue: AudioEvent.Cue in AudioEvent.all_cues():
		if AudioEvent.cue_id(cue)==String(id):audio.play_cue(cue);return

func _water_changed(water: bool) -> void:
	if audio==null:return
	audio.set_grammar(water)
	if water and not _last_water:audio.play_cue(AudioEvent.Cue.MOVEMENT_DIVE)
	_last_water=water
	# Water changes adjust the ongoing music without restarting its phrase.
	if not _dancing:_fade_background(0.65)

func _background_target_db() -> float:
	return DANCE_DUCK_DB if _dancing else (WATER_MUSIC_DB if _last_water else LAND_MUSIC_DB)

func _fade_background(seconds: float) -> void:
	if _bed_mix!=null:_bed_mix.kill()
	_bed_mix=create_tween()
	_bed_mix.tween_property(background,"volume_db",_background_target_db(),seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_dancing(active: bool) -> void:
	if _mix!=null:
		_mix.kill()
		_mix=null
	_dancing=active
	_fade_background(0.18 if active else 0.6)
	if active:
		groove.volume_db=-3.0
		groove.play()
	else:
		_mix=create_tween()
		_mix.tween_property(groove,"volume_db",-60.0,0.15)
		_mix.tween_callback(groove.stop)

func _physics_process(delta: float) -> void:
	if body==null or audio==null or body.is_dancing():return
	_step_clock-=delta
	if body.velocity.length()>.6 and (body.is_in_water() or body.is_on_floor()) and _step_clock<=0:
		audio.play_movement(AudioEvent.Movement.STRIDE)
		_step_clock=.72 if body.is_in_water() else .36
