class_name PlayerHud
extends CanvasLayer

## The Player HUD (REQ-022) — the game-state readout.
##
## The HUD is a CONSUMER at the end of every interface the systems already
## publish: it holds no game state of its own, computes nothing, and can
## never disagree with the systems because every line is (re)written from a
## live query at the moment a system says something changed.
##
## SAME-FRAME is structural, not scheduled: signal emission in Godot is a
## synchronous call, so the label text is rewritten inside the very call
## stack that raised the change (AC-1, AC-2) — there is no deferred update,
## no dirty flag, no next-frame flush to miss. The only per-frame work is
## the countdowns and the dash recharge fraction, values that change every
## frame by nature.
##
## NEVER COLOR ALONE (AC-5): every state below is carried by TEXT — a count,
## a name, a bracketed state word, an OK/LOST marker, a fraction. Color and
## iconography may be layered on later; removing them must never remove
## information, so the text IS the source of truth and the tests assert on
## it.
##
## Wiring is push-in (set_*), like every consumer in this project: the HUD
## displays the systems it is GIVEN and shows an honest placeholder for the
## ones it is not — a world with no restorable regions shows "Region: none",
## never a fabricated row.

const INTACT_MARK := "[OK]"
const LOST_MARK := "[LOST]"

var _lives: LifeSystem = null
var _regen: RegenSystem = null
var _mods: GillModSystem = null
var _restoration: RestorationSystem = null
var _dash: WaterDash = null
var _tuning: TuningData = null
var _active_region: String = ""

var _root: VBoxContainer
var _lives_label: Label
var _capability_labels: Dictionary = {}
var _mod_label: Label
var _region_label: Label
var _dash_label: Label


func _init() -> void:
	layer = 10
	_root = VBoxContainer.new()
	_root.name = "Readout"
	_root.offset_left = 12.0
	_root.offset_top = 12.0
	add_child(_root)

	_lives_label = _add_line("Lives")
	for kind: Capability.Kind in Capability.ALL:
		_capability_labels[kind] = _add_line("Capability_%s" % Capability.id(kind))
	_mod_label = _add_line("Mod")
	_region_label = _add_line("Region")
	_dash_label = _add_line("Dash")

	# Honest placeholders until systems are wired.
	refresh_all()


func _add_line(line_name: String) -> Label:
	var label := Label.new()
	label.name = line_name
	_root.add_child(label)
	return label


# --- Wiring (installed by the Game Client) -----------------------------------

func set_life_system(lives: LifeSystem) -> void:
	_lives = lives
	if _lives != null:
		# Synchronous connections: the text below is rewritten inside the
		# emitting call stack — the same frame the change is raised (AC-1).
		_lives.life_lost.connect(
			func(_remaining: int, _source: CatastrophicSource.Kind) -> void:
				_refresh_lives())
		_lives.respawned.connect(
			func(_position: Vector3, _checkpoint: String,
					_replenished: int) -> void:
				_refresh_lives())
		# A checkpoint REPLENISHES too (REQ-003 AC-5); the count it refills
		# must show the same frame, not on the next loss.
		_lives.checkpoint_activated.connect(
			func(_checkpoint: String) -> void: _refresh_lives())
	_refresh_lives()


func set_regen(regen: RegenSystem) -> void:
	_regen = regen
	if _regen != null:
		_regen.capability_lost.connect(
			func(kind: Capability.Kind) -> void: _refresh_capability(kind))
		_regen.capability_restored.connect(
			func(kind: Capability.Kind) -> void: _refresh_capability(kind))
	_refresh_capabilities()


func set_gill_mods(mods: GillModSystem) -> void:
	_mods = mods
	if _mods != null:
		# Every one of these changes the mod line. Explicit arities, because
		# a connect with the wrong signature fails at emit time — the worst
		# time — and clever reflection here would hide exactly that.
		_mods.equipped.connect(func(_mod_id: String) -> void: _refresh_mod())
		_mods.unequipped.connect(func(_mod_id: String) -> void: _refresh_mod())
		_mods.activated.connect(
			func(_mod_id: String, _duration: float) -> void: _refresh_mod())
		_mods.expired.connect(func(_mod_id: String) -> void: _refresh_mod())
		_mods.ready_again.connect(
			func(_mod_id: String) -> void: _refresh_mod())
		_mods.stripped.connect(
			func(_mod_id: String, _seconds: float) -> void: _refresh_mod())
		_mods.restored.connect(func(_mod_id: String) -> void: _refresh_mod())
	_refresh_mod()


func set_restoration(restoration: RestorationSystem,
		active_region: String = "") -> void:
	_restoration = restoration
	_active_region = active_region
	if _restoration != null:
		_restoration.region_state_changed.connect(
			func(region_id: String, _from: RegionState.State,
					_to: RegionState.State) -> void:
				if region_id == _active_region:
					_refresh_region())
	_refresh_region()


func set_active_region(region_id: String) -> void:
	_active_region = region_id
	_refresh_region()


func set_dash(dash: WaterDash) -> void:
	_dash = dash
	_refresh_dash()


# --- The frame: only values that change every frame by nature ----------------

func _process(_delta: float) -> void:
	if _mods != null and (_mods.is_active() or _mods.is_cooling()
			or _mods.is_stripped()):
		_refresh_mod()
	if _dash != null:
		_refresh_dash()
	if _restoration != null and not _active_region.is_empty():
		_refresh_region()


func refresh_all() -> void:
	_refresh_lives()
	_refresh_capabilities()
	_refresh_mod()
	_refresh_region()
	_refresh_dash()


# --- The lines ---------------------------------------------------------------

func _refresh_lives() -> void:
	if _lives == null:
		_lives_label.text = "Lives: --"
		return
	_lives_label.text = "Lives: %d of %d" \
		% [_lives.get_lives(), _lives.get_lives_per_attempt()]


func _refresh_capabilities() -> void:
	for kind: Capability.Kind in Capability.ALL:
		_refresh_capability(kind)


func _refresh_capability(kind: Capability.Kind) -> void:
	var label: Label = _capability_labels[kind]
	if _regen == null:
		label.text = "%s: --" % Capability.id(kind).capitalize()
		return
	label.text = "%s: %s" % [Capability.id(kind).capitalize(),
		LOST_MARK if _regen.is_lost(kind) else INTACT_MARK]


func _refresh_mod() -> void:
	if _mods == null:
		_mod_label.text = "Mod: --"
		return
	if _mods.is_stripped():
		_mod_label.text = "Mod: %s [SNAGGED %.1fs]" \
			% [_mods.get_stripped_mod_id(), _mods.get_strip_remaining()]
		return
	if not _mods.has_equipped():
		_mod_label.text = "Mod: none"
		return
	var mod_id := _mods.get_equipped_id()
	if _mods.is_active():
		_mod_label.text = "Mod: %s [ACTIVE %.1fs]" \
			% [mod_id, _mods.get_remaining()]
	elif _mods.is_cooling():
		_mod_label.text = "Mod: %s [COOLING %.1fs]" \
			% [mod_id, _mods.get_remaining()]
	else:
		_mod_label.text = "Mod: %s [READY]" % mod_id


func _refresh_region() -> void:
	if _restoration == null or _active_region.is_empty() \
			or not _restoration.has_region(_active_region):
		_region_label.text = "Region: none"
		return
	var region := _restoration.get_region(_active_region)
	var state_id := RegionState.id(region.get_state())
	if region.is_restored():
		_region_label.text = "Region %s: %s [COMPLETE]" \
			% [_active_region, state_id]
		return
	var locked_mark := "" if region.is_unlocked() else " [LOCKED]"
	if _tuning == null:
		# Without a tuning surface the cost of the next state is unknowable;
		# show what IS known rather than inventing a denominator.
		_region_label.text = "Region %s: %s (%d held)%s" \
			% [_active_region, state_id, region.get_resources(), locked_mark]
		return
	_region_label.text = "Region %s: %s (%d/%d to next)%s" \
		% [_active_region, state_id, region.get_resources(),
			region.cost_to_next(_tuning), locked_mark]


func set_tuning(tuning: TuningData) -> void:
	_tuning = tuning
	_refresh_region()


func _refresh_dash() -> void:
	if _dash == null:
		_dash_label.text = "Dash: --"
		return
	var charges := _dash.get_charges()
	var maximum := _dash.max_charges()
	if charges >= maximum:
		_dash_label.text = "Dash: %d of %d [FULL]" % [charges, maximum]
		return
	# get_recharge_progress() is accrued SECONDS toward the next charge; the
	# tuned seconds-per-charge turns it into the fraction the bar shows.
	var percent := 0
	if _tuning != null:
		var needed := _tuning.get_number(WaterDash.RECHARGE_SECONDS_KEY)
		if needed > 0.0:
			percent = int(round(clampf(
				_dash.get_recharge_progress() / needed, 0.0, 1.0) * 100.0))
	_dash_label.text = "Dash: %d of %d [RECHARGING %d%%]" \
		% [charges, maximum, percent]


# --- Read-back for tests and tooling -----------------------------------------

func get_lives_text() -> String:
	return _lives_label.text


func get_capability_text(kind: Capability.Kind) -> String:
	return (_capability_labels[kind] as Label).text


func get_mod_text() -> String:
	return _mod_label.text


func get_region_text() -> String:
	return _region_label.text


func get_dash_text() -> String:
	return _dash_label.text
