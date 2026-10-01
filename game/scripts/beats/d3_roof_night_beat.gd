extends D1HomeBeat
## Day 3, Scene 8: the roof at night, above the dark city. No window lit except the ones the
## player lit tonight, and the oven's glow. The family on the roof: Teta on her cushion, Baba
## sitting, Mama and Karim near. Layla comes up through the hatch and sits where Teta can
## reach her. The thesis of the game is held as a card over the sky; then a caption: Teta
## recites over the children until they sleep. Tonight only the caption, never a voice.

@onready var mama: Npc = $Mama
@onready var karim: Npc = $Karim

var sat := false
var card_done := false
## True from the moment the caption is shown.
var caption_shown := false
var recited := false
## The city's lit windows: as many as the player lit tonight.
var windows: Array[Polygon2D] = []


func _ready() -> void:
	title = "The dark"
	phase = "siege_night"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	baba.is_active = false
	baba.sit(true)
	teta.figure.pose = Figure.Pose.SIT
	mama.figure.pose = Figure.Pose.SIT
	karim.figure.pose = Figure.Pose.SIT
	lights.visible = false
	hint.text = Say.text("d3.s8.hint.sit")


func begin(ctx: Dictionary) -> void:
	context = ctx
	Look.set_phase(3, phase, 0.0)
	# Only the wind, low. No hum tonight; far off, nothing.
	Sound.loop("wind_loop", "ambience", -18.0, 3.0)
	_make_windows(int(ctx.get("lit_windows", 0)))


## The windows the player lit tonight, small and warm, on the street's side of the city.
func _make_windows(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in count:
		var w := Polygon2D.new()
		w.name = "LitWindow%d" % i
		var x := rng.randf_range(1480.0, 2520.0)
		var y := rng.randf_range(590.0, 680.0)
		var size := Vector2(rng.randf_range(10.0, 16.0), rng.randf_range(12.0, 20.0))
		w.polygon = PackedVector2Array([Vector2(x, y), Vector2(x + size.x, y), Vector2(x + size.x, y + size.y), Vector2(x, y + size.y)])
		w.color = Color(0.98, 0.72, 0.4, rng.randf_range(0.4, 0.6))
		w.z_index = -8
		add_child(w)
		windows.append(w)


func _tick(_delta: float) -> void:
	if _done:
		return
	if not sat and sit_spot.overlaps_body(layla) and Input.is_action_just_pressed("interact") and not Say.busy:
		sat = true
		_sequence()


func _sequence() -> void:
	layla.sit(true)
	layla.facing = 1 if teta.global_position.x > layla.global_position.x else -1
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	# The friend's voice, faint (its placeholder for now), in over 4 s.
	Sound.loop("roof_breath_loop", "voices", -14.0, 4.0)
	hint.text = ""
	await _say("d3.s8.teta.01")
	await _say("d3.s8.layla.01")
	await _say("d3.s8.teta.02")
	# The thesis stands alone: the camera is on the sky before the words.
	camera.follow(card_view)
	await _wait(1.2, 0.1)
	await Cards.show_card("day3.roof.sabr")
	card_done = true
	camera.follow(layla)
	await _wait(1.0, 0.1)
	# A caption, no speaker: Teta recites over the children. Never a synthetic recitation.
	caption_shown = true
	await Say.line("", "", Say.text("d3.s8.caption.recite"), 4.0)
	recited = true
	Notebook.write("d3_recite", Say.text("d3.note.recite", "en"), Say.text("d3.note.recite", "ar"))
	Sound.stop_loop("roof_breath_loop", 3.0)
	finish({"d3_roof_night": true})
