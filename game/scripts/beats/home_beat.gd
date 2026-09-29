extends Beat
## Home, prototype cut: three beats in one house. The roof at dusk, where Teta asks her
## question and a hadith is held as a full stop; the first strike, telegraphed by the birds
## and the hum, with cover as the only answer; and the beam that comes down across the
## door, which only Baba can lift while Layla holds the light.

const BEAM_SCENE := preload("res://scenes/beam.tscn")

@onready var layla: Player = $Player
@onready var baba: Player = $Baba
@onready var teta: Npc = $Teta
@onready var sit_spot: Area2D = $SitSpot
@onready var cover: Area2D = $Cover
@onready var door: Area2D = $StreetDoor
@onready var candle: Carryable = $Candle
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var lights: Node2D = $House/Lights
@onready var parapet: Node2D = $House/Parapet
@onready var card_view: Node2D = $CardView
@onready var hatch: Node2D = $Hatch
@onready var beam_spawn: Node2D = $BeamSpawn

var sat := false
var card_done := false
var strike_armed := false
var struck := false
var fails := 0
var switch_enabled := false
var beam: Beam = null
var delivered := false

var _sequence_started := false
var _active: Player


func _ready() -> void:
	title = "The roof"
	phase = "dusk"
	Look.dress()
	baba.is_active = false
	_active = layla
	hint.text = Say.text("home.hint.roof")


func _physics_process(_delta: float) -> void:
	if not _sequence_started and sit_spot.overlaps_body(layla) and Input.is_action_just_pressed("interact") and not Say.busy:
		_sequence_started = true
		_roof_sequence()
	if switch_enabled and Input.is_action_just_pressed("switch_character"):
		_switch()
	if struck and not delivered and layla.is_active and layla.carried == candle and door.overlaps_body(layla):
		delivered = true
		_leave()


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The wind over the roof, faint. Day 1: no hum, no rumble.
	Sound.loop("wind_loop", "ambience", -14.0, 2.0)


func _roof_sequence() -> void:
	sat = true
	layla.sit(true)
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	# The roof at dusk: the friend's vocal pad (its placeholder for now) breathes in over 4 s.
	Sound.loop("roof_breath_loop", "voices", -6.0, 4.0)
	layla.facing = -1 if teta.global_position.x < layla.global_position.x else 1
	hint.text = ""
	await Say.key("home.teta.sit")
	Look.set_phase(1, "night", 1.0 if Day.bot_mode else 14.0)
	await Say.key("home.teta.majdal")
	await Say.key("home.teta.question")
	await Say.key("home.layla.answer")
	await Say.key("home.teta.big")
	Notebook.write("home_teta_question", Say.text("notebook.home.roof", "en"), Say.text("notebook.home.roof", "ar"))
	# The hadith card stands alone: the camera moves to the sea before the words appear.
	camera.follow(card_view)
	await get_tree().create_timer(0.1 if Day.bot_mode else 1.2).timeout
	await Cards.show_card("day1.roof.smile")
	camera.follow(layla)
	card_done = true
	layla.sit(false)
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	await get_tree().create_timer(0.3 if Day.bot_mode else 2.5).timeout
	_telegraph()


## The birds leave first. Then the clock. (No hum on Day 1: the zanana comes later.)
func _telegraph() -> void:
	strike_armed = true
	_birds_leave()
	Sound.stop_loop("roof_breath_loop", 3.0)
	Sound.play("birds_leave", "effects")
	Say.key("home.baba.inside", 2.5)
	hint.text = Say.text("home.hint.cover")
	_countdown(2.0 if Day.bot_mode else 12.0)


func _countdown(seconds: float) -> void:
	if Settings.own_pace:
		while not cover.overlaps_body(layla):
			await get_tree().physics_frame
		_strike()
		return
	var t := 0.0
	while t < seconds:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	if cover.overlaps_body(layla):
		_strike()
		return
	# Caught outside: a white screen of dust, and the last doorway, seconds back.
	await Fx.whiteout(0.3 if Day.bot_mode else 1.2)
	layla.global_position = hatch.global_position
	layla.velocity = Vector2.ZERO
	fails += 1
	_countdown(minf(seconds, 1.5 if Day.bot_mode else 6.0))


func _birds_leave() -> void:
	for i in 9:
		var bird := Polygon2D.new()
		bird.color = Color(0.06, 0.05, 0.07)
		bird.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(0, -3), Vector2(9, 0), Vector2(0, 3)])
		bird.position = parapet.position + Vector2(randf_range(-160.0, 160.0), randf_range(-8.0, 0.0))
		add_child(bird)
		var tw := create_tween()
		var dest := bird.position + Vector2(randf_range(-900.0, -500.0), randf_range(-700.0, -400.0))
		tw.tween_property(bird, "position", dest, randf_range(2.2, 3.4)).set_delay(randf_range(0.0, 0.5)).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bird, "scale:y", 0.3, 0.12).set_delay(randf_range(0.0, 0.5))
		tw.tween_callback(bird.queue_free)


func _strike() -> void:
	struck = true
	hint.text = ""
	# The bang is alone: every loop cut at once, the one close bang, then the ringing under
	# the white-out. The world comes back slowly (see _wind_returns).
	Sound.stop_all_loops(0.05)
	Sound.play("strike_bang", "strike")
	_wind_returns()
	camera.shake(22.0, 0.9)
	Fx.strike_flash(3.0)
	Look.set_phase(1, "siege_night", 0.4)
	lights.visible = false
	await get_tree().create_timer(0.2 if Day.bot_mode else 1.6).timeout
	Sound.play("ringing", "strike")
	beam = BEAM_SCENE.instantiate()
	beam.position = beam_spawn.position
	beam.door_x = door.global_position.x
	add_child(beam)
	beam.lifted.connect(_on_beam_lifted)
	Sound.play("drop_heavy", "effects")
	await get_tree().create_timer(0.2 if Day.bot_mode else 2.0).timeout
	await Say.key("home.baba.everyone")
	await Say.line("Teta", Cards.arabic("day3.teta.hasbuna"), Cards.english("day3.teta.hasbuna"), 0.0)
	await Say.key("home.baba.beam")
	switch_enabled = true
	hint.text = Say.text("home.hint.switch")
	Notebook.write("home_first_strike", Say.text("notebook.home.strike", "en"), Say.text("notebook.home.strike", "ar"), {"act": true})


## After the bang only the ringing; the wind returns low, seven seconds on. Runs beside
## the rest of the strike; if the beat has ended by then, nothing starts.
func _wind_returns() -> void:
	await get_tree().create_timer(7.0).timeout
	if _done or not is_inside_tree():
		return
	Sound.loop("wind_loop", "ambience", -20.0, 4.0)


func _switch() -> void:
	_active = baba if _active == layla else layla
	layla.is_active = _active == layla
	baba.is_active = _active == baba
	camera.follow(_active)
	Sound.play("cloth_rustle", "effects", -8.0, 0.08)


func _on_beam_lifted(_beam: Beam) -> void:
	hint.text = Say.text("home.hint.candle")
	Say.key("home.baba.clear", 3.0)


func _leave() -> void:
	hint.text = ""
	Sound.play("door_wood", "effects")
	finish({"candle": true, "strike": true, "beam_lifted": beam != null and not beam.blocking()})
