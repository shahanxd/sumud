extends D1HomeBeat
## Day 3, Scenes 2, 3 and 4: the birds, under the stairs, the bang. Maghrib on the family
## roof with the hum under the wind. The pigeons lift all at once, the hum rises, a rumble
## under it, Baba's voice from inside: about twelve seconds to get down the stairs to the
## family under the stairwell. Caught outside is white dust and the roof door, never death.
## Under the stairs the camera is on the candle on the step while Teta's lips move (the
## ayah is a card, never a spoken line). Then one real, close bang: every loop cut, the
## flash, the dark, the ringing, the ground-floor window blown in. Over the dark street
## through the empty frame, a second card; then the title card, SUMUD. Then the names, and
## the beam across the door that only Baba can lift while Layla holds the light.

const BEAM_SCENE := preload("res://scenes/beam.tscn")
const CARD_SCENE := "res://scenes/chapter_card.tscn"

@onready var mama: Npc = $Mama
@onready var karim: Npc = $Karim
@onready var cover: Area2D = $Cover
@onready var candle: Carryable = $Candle
@onready var beam_spawn: Node2D = $BeamSpawn
@onready var stair_candle: Node2D = $StairCandle
@onready var window_view: Node2D = $WindowView
@onready var window_bar: Polygon2D = $House/WindowBarG
@onready var window_void: Polygon2D = $House/WindowVoid
@onready var window_shards: Node2D = $House/WindowShards
@onready var glass_floor: Node2D = $GlassFloor
@onready var title_layer: CanvasLayer = $TitleLayer

## The telegraph has begun: the birds are up and the clock runs.
var strike_armed := false
## She reached the family under the stairs in time.
var in_cover := false
## The first card (under the stairs) has been held and released.
var card_done := false
var struck := false
## The second card (over the dark street) has been held and released.
var test_card_done := false
## The title card has played.
var titled := false
## Everyone has said their name.
var named := false
## How many times she was caught outside.
var fails := 0
var switch_enabled := false
var beam: Beam = null
var delivered := false

var _active: Player
var _hum: AudioStreamPlayer = null


func _ready() -> void:
	title = "The dark"
	phase = "dusk"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	baba.is_active = false
	_active = layla
	# The family pressed together under the stairs, already down.
	teta.figure.pose = Figure.Pose.SIT
	mama.figure.pose = Figure.Pose.SIT
	karim.figure.pose = Figure.Pose.SIT
	make_pigeons(7)
	hint.text = ""


func begin(ctx: Dictionary) -> void:
	context = ctx
	Look.set_phase(3, phase, 0.0)
	# The wind faint over the roof and the hum under it, plainer than this morning.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)
	_hum = Sound.loop("drone_hum_loop", "ambience", -14.0, 0.1 if Day.bot_mode else 2.0)
	_opening()


func _opening() -> void:
	await _wait(2.0, 0.3)
	if _closed():
		return
	_telegraph()


func _tick(_delta: float) -> void:
	if _done:
		return
	if switch_enabled and Input.is_action_just_pressed("switch_character"):
		_switch()
	if struck and not delivered and layla.is_active and layla.carried == candle and street_door.overlaps_body(layla):
		delivered = true
		_leave()


# -- Scene 2: the birds ----------------------------------------------------------------------

## The birds leave first, the hum climbs, the rumble comes in under it, Baba from inside.
## Then the clock.
func _telegraph() -> void:
	strike_armed = true
	_birds_leave()
	Sound.play("birds_leave", "effects")
	if _hum != null and is_instance_valid(_hum):
		var tw := _hum.create_tween()
		tw.tween_property(_hum, "volume_db", _hum.volume_db + 6.0, 0.3 if Day.bot_mode else 3.0)
	_rumble()
	_bark("d3.s2.baba.01", 2.5)
	_family_barks()
	hint.text = Say.text("d3.s2.hint.cover")
	_countdown(2.0 if Day.bot_mode else 12.0)


func _rumble() -> void:
	await _wait(1.0, 0.1)
	if _closed() or struck:
		return
	Sound.loop("rumble_loop", "rumble", -12.0, 0.3 if Day.bot_mode else 3.0)


## Mama and Karim under the stairs while she runs: barks, never blocking.
func _family_barks() -> void:
	await _wait(2.0, 0.2)
	if _closed() or struck:
		return
	await _bark("d3.s2.mama.01", 2.5)
	if _closed() or struck:
		return
	await _bark("d3.s2.karim.01", 2.0)


## The clock, as the sampler had it: own pace waits for her; otherwise the seconds run and
## caught outside is a white screen of dust, the roof door, and a shorter clock.
func _countdown(seconds: float) -> void:
	if Settings.own_pace:
		while not cover.overlaps_body(layla):
			await get_tree().physics_frame
		_under_the_stairs()
		return
	var t := 0.0
	while t < seconds:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	if cover.overlaps_body(layla):
		_under_the_stairs()
		return
	await Fx.whiteout(0.3 if Day.bot_mode else 1.2)
	layla.global_position = hatch.global_position
	layla.velocity = Vector2.ZERO
	fails += 1
	_countdown(minf(seconds, 1.5 if Day.bot_mode else 6.0))


## The pigeons lift all at once off the tank and go.
func _birds_leave() -> void:
	for bird in pigeons:
		if is_instance_valid(bird):
			bird.queue_free()
	pigeons.clear()
	for i in 9:
		var bird := Polygon2D.new()
		bird.color = Color(0.06, 0.05, 0.07)
		bird.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(0, -3), Vector2(9, 0), Vector2(0, 3)])
		bird.position = Vector2(randf_range(TANK_X.x - 20.0, TANK_X.y + 20.0), TANK_TOP + randf_range(-8.0, 0.0))
		add_child(bird)
		var tw := create_tween()
		var dest := bird.position + Vector2(randf_range(-900.0, -500.0), randf_range(-700.0, -400.0))
		tw.tween_property(bird, "position", dest, randf_range(2.2, 3.4)).set_delay(randf_range(0.0, 0.5)).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bird, "scale:y", 0.3, 0.12).set_delay(randf_range(0.0, 0.5))
		tw.tween_callback(bird.queue_free)


# -- Scene 3: under the stairs ---------------------------------------------------------------

## In time. No control from here to the names: heads down, the candle on the step, the card.
func _under_the_stairs() -> void:
	in_cover = true
	hint.text = ""
	layla.is_active = false
	layla.facing = 1 if teta.global_position.x > layla.global_position.x else -1
	await _say("d3.s3.baba.01")
	# Teta's lips move. The camera is on the candle on the step, not on faces, before the words.
	camera.follow(stair_candle)
	await _wait(1.2, 0.1)
	await Cards.show_card("day3.teta.hasbuna")
	card_done = true
	await _wait(0.8, 0.1)
	_strike()


# -- Scene 4: the bang -----------------------------------------------------------------------

func _strike() -> void:
	struck = true
	hint.text = ""
	# The bang is alone: every loop cut at once, the one close bang, then the ringing under
	# the white-out. Only the wind comes back, seven seconds on; no hum tonight.
	Sound.stop_all_loops(0.05)
	Sound.play("strike_bang", "strike")
	_wind_returns()
	camera.shake(22.0, 0.9)
	Fx.strike_flash(3.0)
	Look.set_phase(3, "siege_night", 0.4)
	lights.visible = false
	_window_blows()
	await _wait(1.6, 0.2)
	Sound.play("ringing", "strike")
	beam = BEAM_SCENE.instantiate()
	beam.position = beam_spawn.position
	beam.door_x = street_door.global_position.x
	add_child(beam)
	beam.lifted.connect(_on_beam_lifted)
	Sound.play("drop_heavy", "effects")
	# The street gone dark, seen through the empty frame; the card lands on that.
	camera.follow(window_view)
	await _wait(1.2, 0.1)
	await Cards.show_card("day3.stairs.test")
	test_card_done = true
	await _title_card()
	camera.follow(layla)
	await _wait(1.0, 0.1)
	await _say("d3.s4.karim.01")
	await _say("d3.s4.baba.01")
	await _say("d3.s4.mama.01")
	await _say("d3.s4.baba.02")
	await _say("d3.s4.layla.01")
	await _say("d3.s4.karim.02")
	await _say("d3.s4.teta.01")
	await _say("d3.s4.mama.02")
	named = true
	await _say("d3.s4.baba.03")
	layla.is_active = true
	switch_enabled = true
	hint.text = Say.text("d3.s4.hint.switch")
	Notebook.write("d3_strike", Say.text("d3.note.strike", "en"), Say.text("d3.note.strike", "ar"))


## The ground-floor window blown in: the bar gone, the dark beyond where the glass was, a
## few shards left in the frame, glass on the floor.
func _window_blows() -> void:
	window_bar.visible = false
	window_void.visible = true
	window_shards.visible = true
	glass_floor.visible = true


## The title card: SUMUD, stitched in over black, three seconds, no control.
func _title_card() -> void:
	var packed: PackedScene = load(CARD_SCENE)
	if packed == null:
		titled = true
		return
	var card: ChapterCard = packed.instantiate()
	title_layer.add_child(card)
	if Day.bot_mode:
		card.stitch_seconds = 0.2
		card.hold_seconds = 0.05
	else:
		card.stitch_seconds = 2.4
		card.hold_seconds = 3.0
	Day.stitch_sounds(card)
	await card.play("", "SUMUD")
	card.queue_free()
	titled = true


## After the bang only the ringing; the wind returns low, seven seconds on. Runs beside
## the rest of the strike; if the beat has ended by then, nothing starts.
func _wind_returns() -> void:
	await get_tree().create_timer(7.0).timeout
	if _closed():
		return
	Sound.loop("wind_loop", "ambience", -20.0, 4.0)


func _switch() -> void:
	_active = baba if _active == layla else layla
	layla.is_active = _active == layla
	baba.is_active = _active == baba
	camera.follow(_active)
	Sound.play("cloth_rustle", "effects", -8.0, 0.08)


func _on_beam_lifted(_beam: Beam) -> void:
	hint.text = Say.text("d3.s4.hint.candle")


func _leave() -> void:
	hint.text = ""
	Sound.play("door_wood", "effects")
	finish({
		"candle": true,
		"d3_struck": true,
		"strike": true,
		"beam_lifted": beam != null and not beam.blocking(),
		"d3_fails": fails,
	})
