extends D1HomeBeat
## Day 3, Scene 0: eight days. Fajr on the two roofs, as on Day 1, but the hum is there, the
## zanana, louder than yesterday, and it rises through the scene. Layla on the family roof
## with her kite up; Sami on his roof across the gap with his own kite up; the pigeons on the
## tank will not settle. The talk across the gap after she has flown a while, then Teta from
## the stairs: the dress. The beat ends when she goes down through the hatch.

## Seconds of kite flight before the talk across the gap.
const TALK_AFTER := 3.0
## Where the hum goes by the end of the scene, and how long it takes to get there.
const HUM_START_DB := -22.0
const HUM_END_DB := -16.0
const HUM_RISE_SECONDS := 45.0

@onready var kite: Kite = $Kite
@onready var sami: Npc = $Sami
@onready var sami_kite: Kite = $SamiKite

## The kite is up and hers to fly; false once she has reeled it in and it has come down.
var kite_in_play := false
## True once the lines across the gap have run.
var talked := false
## True once Teta has called from the stairs; the way down ends the beat after that.
var teta_called := false
## How many times a pigeon has hopped since the scene opened.
var pigeon_hops := 0
## Seconds the kite has been in the air.
var fly_t := 0.0

var _reel_requested := false
var _sami_down := 0.0
var _hum: AudioStreamPlayer = null


func _ready() -> void:
	title = "The dark"
	phase = "morning"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	baba.is_active = false
	make_pigeons(7)
	hint.text = ""


func begin(ctx: Dictionary) -> void:
	context = ctx
	Look.set_phase(3, phase, 0.0)
	# The wind and the sea as on Day 1's fajr, and under them the hum, rising all morning.
	Sound.loop("wind_loop", "ambience", -14.0, 2.0)
	Sound.loop("sea_loop", "ambience", -24.0, 3.0)
	_hum = Sound.loop("drone_hum_loop", "ambience", HUM_START_DB, 0.1 if Day.bot_mode else 4.0)
	_hum_rises()
	layla.facing = -1
	kite.launch(-1)
	kite_in_play = true
	sami_kite.launch(1)
	hint.text = Say.text("d3.s0.hint.kite")
	_restless_pigeons()
	_talk()


## The hum climbs from faint to plain over the scene, after its fade-in.
func _hum_rises() -> void:
	await _wait(4.0, 0.2)
	if _closed() or _hum == null or not is_instance_valid(_hum):
		return
	var tw := _hum.create_tween()
	tw.tween_property(_hum, "volume_db", HUM_END_DB, 1.0 if Day.bot_mode else HUM_RISE_SECONDS)


## The pigeons will not settle: one of them hops every second or two, on top of the slow
## shifting they do every day.
func _restless_pigeons() -> void:
	while not _closed():
		await _wait(randf_range(1.0, 2.0), randf_range(0.1, 0.2))
		if _closed() or pigeons.is_empty():
			return
		var bird := pigeons[randi() % pigeons.size()]
		var to := clampf(bird.position.x + randf_range(-18.0, 18.0), TANK_X.x, TANK_X.y)
		bird.scale.x = 1.0 if to > bird.position.x else -1.0
		pigeon_hops += 1
		var tw := create_tween()
		tw.tween_property(bird, "position:y", TANK_TOP - 9.0, 0.1)
		tw.parallel().tween_property(bird, "position:x", to, 0.28)
		tw.tween_property(bird, "position:y", TANK_TOP, 0.14)


## The talk across the gap once she has flown a while; then Teta from the stairs.
func _talk() -> void:
	var need := 0.3 if Day.bot_mode else TALK_AFTER
	while fly_t < need and not _closed():
		await get_tree().physics_frame
	if _closed():
		return
	await _say("d3.s0.sami.01")
	await _say("d3.s0.layla.01")
	await _say("d3.s0.sami.02")
	await _say("d3.s0.layla.02")
	await _say("d3.s0.sami.03")
	talked = true
	await _wait(2.0, 0.2)
	if _closed():
		return
	await _say("d3.s0.teta.01")
	teta_called = true


func _tick(delta: float) -> void:
	if _done:
		return
	_kite_step()
	_sami_kite_step(delta)
	if kite.flying:
		fly_t += delta
	if teta_called and layla.global_position.y > 560.0:
		_leave()


## As on Day 1: the kite cannot fall here, and reeling it in is the way off the roof.
func _kite_step() -> void:
	if not kite_in_play:
		return
	if kite.flying:
		if layla.is_active and Input.is_action_just_pressed("kite"):
			_reel_requested = true
		return
	if _reel_requested:
		kite_in_play = false
		layla.kite = null
		kite.visible = false
		return
	if layla.is_on_floor() and layla.global_position.y < 530.0:
		kite.launch(layla.facing)


## Sami's kite goes up again a second after it comes down.
func _sami_kite_step(delta: float) -> void:
	if sami_kite.flying:
		_sami_down = 0.0
		return
	_sami_down += delta
	if _sami_down > 1.0:
		_sami_down = 0.0
		sami_kite.launch(1)


func _leave() -> void:
	hint.text = ""
	# Sami's kite comes down with the scene; a kite left flying would crackle on after the beat.
	if sami_kite.flying:
		sami_kite.reel_in()
	Notebook.write("d3_hum", Say.text("d3.note.hum", "en"), Say.text("d3.note.hum", "ar"))
	finish({"d3_hum": true})
