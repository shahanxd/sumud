extends Beat
## Day 3, Scene 1 of docs/story/day3-script.md: the dress. The women's space on Sami's roof
## at noon: Teta, Um Sami, Nour and Mama on cushions round Nour's white dress, stitching its
## red tatreez; tea; the hum under everything. Layla comes up through the family hatch,
## jumps the gap and sits with them. Hand thread: hold interact when a hand reaches for it;
## nothing to solve. Once, the hum rises and every hand stops. Then Um Sami shouts down for
## the bread and the asr light yellows toward maghrib.

## The hum at rest, raised for the pause, and faded under the adhan (dB).
const HUM_DB := -18.0
const HUM_RAISED_DB := -12.0
const HUM_FADED_DB := -24.0
## The red band across the dress: squares shown at the start, and in all.
const BAND_START := 6
const BAND_TOTAL := 18
const BAND_X0 := 1560.0
const BAND_STEP := 15.0
const BAND_Y := 470.0
const SQUARE := 6.0
const RED := Color(0.71, 0.07, 0.11)
## How many times a hand reaches for the thread.
const HANDS := 3

const TALK: Array[String] = [
	"d3.s1.um_sami.01", "d3.s1.layla.01", "d3.s1.nour.01", "d3.s1.layla.02", "d3.s1.nour.02",
	"d3.s1.mama.01", "d3.s1.teta.01", "d3.s1.teta.02", "d3.s1.layla.03", "d3.s1.nour.03",
	"d3.s1.um_sami.02",
]

@onready var layla: Player = $Player
@onready var baba: Player = $Baba
@onready var teta: Npc = $Teta
@onready var um_sami: Npc = $UmSami
@onready var nour: Npc = $Nour
@onready var mama: Npc = $Mama
@onready var sit_spot: Area2D = $SitSpot
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var dress: Polygon2D = $Dress

## Every line key this beat has fired, in order.
var said: Array[String] = []
var sat := false
## True while the hum is up and every hand has stopped.
var paused_hands := false
var threads_handed := 0
## Red squares shown on the band.
var band_shown := 0
## The woman whose hand is out for the thread, while one is.
var reaching: Npc = null
## The hum's target level right now, dB.
var hum_level := HUM_DB
var hum_player: AudioStreamPlayer = null

var _women: Array[Npc] = []
var _squares: Array[Polygon2D] = []
var _prompt: Polygon2D = null
var _prompt_base := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	title = "The dress"
	phase = "noon"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	baba.is_active = false
	_women = [teta, um_sami, nour, mama]
	for w in _women:
		w.figure.pose = Figure.Pose.SIT
	_build_band()
	_build_prompt()
	hint.text = Say.text("d3.s1.hint.sit")


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The wind over the roofs, faint, and the zanana under everything.
	Sound.loop("wind_loop", "ambience", -18.0, 2.0)
	hum_player = Sound.loop("drone_hum_loop", "ambience", HUM_DB, 0.1 if Day.bot_mode else 2.0)


# -- Helpers -------------------------------------------------------------------------------

func _say(k: String) -> void:
	said.append(k)
	await Say.key(k)


func _wait(seconds: float, bot_seconds: float = 0.2) -> void:
	await get_tree().create_timer(bot_seconds if Day.bot_mode else seconds).timeout


func _closed() -> bool:
	return _done or not is_inside_tree()


func _is_sitting() -> bool:
	return layla.sitting and not Say.busy


func _set_hum(db: float, seconds: float) -> void:
	hum_level = db
	if hum_player == null or not is_instance_valid(hum_player):
		return
	var tw := hum_player.create_tween()
	tw.tween_property(hum_player, "volume_db", db, seconds)


# -- The band and the prompt ----------------------------------------------------------------

func _build_band() -> void:
	for i in BAND_TOTAL:
		var sq := Polygon2D.new()
		sq.color = RED
		var x := BAND_X0 + BAND_STEP * float(i)
		sq.polygon = PackedVector2Array([
			Vector2(x, BAND_Y), Vector2(x + SQUARE, BAND_Y), Vector2(x + SQUARE, BAND_Y + SQUARE), Vector2(x, BAND_Y + SQUARE)])
		sq.visible = i < BAND_START
		dress.add_child(sq)
		_squares.append(sq)
	band_shown = BAND_START


func _show_band(n: int) -> void:
	n = clampi(n, 0, BAND_TOTAL)
	for i in _squares.size():
		_squares[i].visible = i < n
	if n > band_shown:
		Sound.play("stitch_%d" % randi_range(1, 3), "effects", -6.0, 0.1)
	band_shown = n


## A small warm mark over the woman whose hand is out.
func _build_prompt() -> void:
	_prompt = Polygon2D.new()
	_prompt.name = "ThreadPrompt"
	_prompt.color = Color(1.0, 0.85, 0.6, 0.95)
	_prompt.polygon = PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
	_prompt.z_index = 3
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	_t += delta
	if _prompt != null and _prompt.visible:
		_prompt.position = _prompt_base + Vector2(0.0, sin(_t * 4.0) * 3.0)


# -- Every frame ----------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _done:
		return
	if not sat and sit_spot.overlaps_body(layla) and layla.is_on_floor() and Input.is_action_just_pressed("interact") and not Say.busy:
		sat = true
		_sequence()


# -- The scene -------------------------------------------------------------------------------

func _sequence() -> void:
	layla.sit(true)
	layla.facing = -1
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	hint.text = ""
	for k in TALK:
		await _say(k)
		if _closed():
			return
	await _pause()
	if _closed():
		return
	await _say("d3.s1.mama.02")
	await _say("d3.s1.nour.04")
	await _say("d3.s1.um_sami.03")
	await _threads()
	if _closed():
		return
	await _say("d3.s1.um_sami.04")
	# Sami from the street below: his name, no figure.
	await _say("d3.s1.sami.01")
	Notebook.write("d3_dress", Say.text("d3.note.dress", "en"), Say.text("d3.note.dress", "ar"))
	# The asr light yellows toward maghrib; the hum sinks under the adhan's turn.
	_set_hum(HUM_FADED_DB, 0.5 if Day.bot_mode else 6.0)
	await adhan(3, "dusk", 6.0)
	finish({"d3_dress": true})


## The hum rises; every hand stops for a moment; Teta says the thing she says.
func _pause() -> void:
	paused_hands = true
	_freeze(true)
	_set_hum(HUM_RAISED_DB, 0.4)
	await Say.line("", "", Say.text("d3.s1.pause"), 0.3 if Day.bot_mode else 2.0)
	_set_hum(HUM_DB, 1.5)
	await _say("d3.s1.teta.03")
	_freeze(false)
	paused_hands = false


## Stops (or restarts) every figure's idle: breathing, the scarf tails, the frames.
func _freeze(on: bool) -> void:
	var mode := Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	for w in _women:
		w.figure.process_mode = mode
	layla.figure.process_mode = mode


## Three times a hand reaches; hold interact to hand the thread; the band grows by a third.
func _threads() -> void:
	hint.text = Say.text("d3.s1.hint.thread")
	var askers: Array[Npc] = [um_sami, nour, mama]
	var step := (BAND_TOTAL - BAND_START) / HANDS
	for i in HANDS:
		await _wait(1.0, 0.2)
		# Each hand asks afresh: a key held through from the last one does not count.
		while Input.is_action_pressed("interact") and not _closed():
			await get_tree().physics_frame
		if _closed():
			return
		reaching = askers[i]
		_prompt_base = reaching.global_position + Vector2(0.0, -reaching.figure.height() * 0.8)
		_prompt.position = _prompt_base
		_prompt.visible = true
		_lean(reaching, true)
		await hold_action("interact", 1.0, _is_sitting, _on_thread_progress)
		if _closed():
			return
		_lean(reaching, false)
		_prompt.visible = false
		reaching = null
		threads_handed += 1
		_show_band(BAND_START + step * threads_handed)
	hint.text = ""


## As she holds, the stitches appear one by one along the band.
func _on_thread_progress(p: float) -> void:
	var step := (BAND_TOTAL - BAND_START) / HANDS
	var target := BAND_START + step * threads_handed + int(p * float(step))
	if target > band_shown:
		_show_band(target)


## The asker leans a hand's width toward Layla, and back.
func _lean(npc: Npc, out: bool) -> void:
	var dir := signf(layla.global_position.x - npc.global_position.x)
	var to := npc.position.x + dir * 8.0 if out else npc.position.x - dir * 8.0
	var tw := create_tween()
	tw.tween_property(npc, "position:x", to, 0.3).set_ease(Tween.EASE_OUT)
