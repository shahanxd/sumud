extends D1HomeBeat
## Day 1, Scene 9: a light nobody mentions. Night on the roof. The city's windows are lit,
## then the grid cuts out section by section, as it does every night. On the black sea, far
## out, one light that does not move. Baba stops mending, stands, and sets the net down;
## Mishmish stops too. Then Baba sits and picks the net up again. Nobody says anything.
## The player can look: at the parapet, standing still, the camera drifts toward the light.
## Then Teta: inside. The beat ends when Layla goes down through the hatch.

## How many of the city's windows are lit before the cut.
const WINDOW_COUNT := 12
## She must stand this close to the parapet, this long, before the camera drifts.
const GAZE_REACH := 80.0
const GAZE_SECONDS := 2.0

@onready var sea_gaze: Node2D = $SeaGaze
@onready var sea_light: Polygon2D = $SeaLight

var windows: Array[Polygon2D] = []
## 0..3: how many sections of the city have gone dark.
var lights_out_stage := 0
var baba_stood := false
var sequence_done := false
## True while the camera is drifting toward the light on the sea.
var gazing := false

var _still_t := 0.0


func _ready() -> void:
	title = "The kites"
	phase = "night"
	Look.dress()
	baba.is_active = false
	baba.sit(true)
	make_pigeons(6)
	make_net(baba.global_position + Vector2(44.0, 0.0))
	make_cat(baba.global_position + Vector2(-40.0, 0.0))
	_make_windows()
	hint.text = ""


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# Night wind, the sea under it; the city's hum is only its windows.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)
	Sound.loop("sea_loop", "ambience", -24.0, 3.0)
	_sequence()


## The lit windows of the city on the skyline side, in three sections: the near houses to
## the left, the street's side of the city, and the far blocks.
func _make_windows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in WINDOW_COUNT:
		var w := Polygon2D.new()
		w.name = "CityWindow%d" % i
		var x := 0.0
		match i / 4:
			0: x = rng.randf_range(-320.0, 520.0)
			1: x = rng.randf_range(1480.0, 1960.0)
			_: x = rng.randf_range(1980.0, 2520.0)
		var y := rng.randf_range(575.0, 685.0)
		var size := Vector2(rng.randf_range(10.0, 16.0), rng.randf_range(12.0, 20.0))
		w.polygon = PackedVector2Array([Vector2(x, y), Vector2(x + size.x, y), Vector2(x + size.x, y + size.y), Vector2(x, y + size.y)])
		w.color = Color(0.98, 0.76, 0.42, rng.randf_range(0.35, 0.55))
		w.z_index = -8
		add_child(w)
		windows.append(w)


func _sequence() -> void:
	await _wait(1.5, 0.2)
	for section in 3:
		if _closed():
			return
		_cut_section(section)
		await _wait(1.0, 0.2)
	await _wait(2.5, 0.3)
	if _closed():
		return
	# Baba stops mending and stands. Mishmish stops too. Nobody says anything.
	baba.sit(false)
	baba_stood = true
	cat_moving = false
	await _wait(3.0, 0.3)
	if _closed():
		return
	baba.sit(true)
	await _wait(1.5, 0.2)
	if _closed():
		return
	await _say("d1.s9.teta.01")
	hint.text = Say.text("d1.s9.hint.inside")
	sequence_done = true


func _cut_section(section: int) -> void:
	for i in windows.size():
		if i / 4 == section:
			windows[i].visible = false
	if section == 1:
		# The street's section is ours too.
		lights.visible = false
	lights_out_stage = section + 1


func _tick(delta: float) -> void:
	if _done:
		return
	_gaze_step(delta)
	# Through the hatch: nothing lies between the roof (y 500) and the flight below it.
	if sequence_done and layla.global_position.y > 560.0:
		hint.text = ""
		finish({})


## Standing still at the parapet, the camera drifts toward the light; moving brings it back.
func _gaze_step(delta: float) -> void:
	var at_parapet := layla.global_position.distance_to(parapet.global_position) < GAZE_REACH
	var still := at_parapet and layla.is_on_floor() and absf(layla.velocity.x) < 5.0 and not layla.sitting
	if still:
		_still_t += delta
	else:
		_still_t = 0.0
	var need := 0.3 if Day.bot_mode else GAZE_SECONDS
	if still and _still_t >= need and not gazing:
		gazing = true
		camera.follow(sea_gaze)
	elif not still and gazing:
		gazing = false
		camera.follow(layla)
