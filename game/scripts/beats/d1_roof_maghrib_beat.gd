extends D1HomeBeat
## Day 1, Scene 8: the question. The sun goes down into the sea behind the roof. Pigeons on
## the tank, Baba mending his net, Teta on her cushion by the parapet with the key in her
## hands. Layla sits with her; Teta flicks Layla's own kite up into the maghrib wind and hands
## her the string: "Don't fly it. Hold it. Still." The player keeps it still against the gusts
## while they talk; it cannot fail, it only drifts. Teta answers neither question; she smiles
## at the sea, and the hadith card lands on that. Then Baba, from his net.

## How long the kite is held, in seconds; the talk happens inside it.
const HOLD_SECONDS := 20.0

@onready var kite: Kite = $Kite

var sat := false
## True from Teta's launch until the hold is over: the kite is up and the player holds it.
var holding := false
var hold_done := false
var card_done := false
## The kite's horizontal distance from where it started, smoothed, and its average over the hold.
var drift := 0.0
var drift_avg := 0.0

var _kite_up := false
var _start_x := 0.0
var _drift_sum := 0.0
var _drift_n := 0
var _hold_t := 0.0


func _ready() -> void:
	title = "The kites"
	phase = "dusk"
	Look.dress()
	baba.is_active = false
	baba.sit(true)
	kite.carrier = layla
	make_pigeons(7)
	make_net(baba.global_position + Vector2(44.0, 0.0))
	make_cat(baba.global_position + Vector2(-40.0, 0.0))
	hint.text = Say.text("d1.s8.hint.sit")


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The wind over the roof and the sea under it, both faint; nothing else until she sits.
	Sound.loop("wind_loop", "ambience", -14.0, 2.0)
	Sound.loop("sea_loop", "ambience", -24.0, 3.0)


func _tick(delta: float) -> void:
	if _done:
		return
	if not sat and sit_spot.overlaps_body(layla) and Input.is_action_just_pressed("interact") and not Say.busy:
		sat = true
		_roof_sequence()
	if _kite_up and not kite.flying:
		# It cannot fall: back up without a word.
		kite.launch(1)
	if holding and kite.flying:
		var d := absf(kite.global_position.x - _start_x)
		drift = lerpf(drift, d, 1.0 - exp(-3.0 * delta))
		_drift_sum += drift
		_drift_n += 1
		drift_avg = _drift_sum / float(_drift_n)
		_hold_t += delta


func _roof_sequence() -> void:
	layla.sit(true)
	layla.facing = -1 if teta.global_position.x < layla.global_position.x else 1
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	# The friend's voice rises softly (its placeholder for now) over 4 s; everything else quiet.
	Sound.loop("roof_breath_loop", "voices", -6.0, 4.0)
	hint.text = ""
	await _say("d1.s8.teta.01")
	Look.set_phase(1, "night", 1.0 if Day.bot_mode else 14.0)
	if String(context.get("d1_contest_winner", "")) == "layla":
		await _say("d1.s8.layla.win")
	else:
		await _say("d1.s8.layla.lose")
		await _say("d1.s8.teta.02")
	await _say("d1.s8.teta.08")
	# An old woman's flick of the wrist: the kite goes up from Layla's hand into the wind.
	_kite_up = true
	kite.launch(1)
	hint.text = Say.text("d1.s8.hint.still")
	await _wait(1.5, 0.15)
	_start_x = kite.global_position.x
	holding = true
	await _say("d1.s8.layla.05")
	await _say("d1.s8.teta.09")
	await _say("d1.s8.teta.03")
	await _say("d1.s8.layla.01")
	await _say("d1.s8.layla.02")
	await _say("d1.s8.teta.05")
	await _say("d1.s8.layla.03")
	var need := 2.0 if Day.bot_mode else HOLD_SECONDS
	while _hold_t < need and not _closed():
		await get_tree().physics_frame
	holding = false
	hold_done = true
	hint.text = ""
	Notebook.write("d1_teta_question", Say.text("d1.note.teta", "en"), Say.text("d1.note.teta", "ar"))
	# Teta smiles at the sea. The card stands alone: the camera is on the sea before the words.
	camera.follow(card_view)
	await _wait(1.2, 0.1)
	await Cards.show_card("day1.roof.smile")
	camera.follow(layla)
	card_done = true
	await _say("d1.s8.baba.01")
	_kite_up = false
	kite.reel_in()
	layla.sit(false)
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	Sound.stop_loop("roof_breath_loop", 3.0)
	finish({"d1_held_still": true, "d1_drift": snappedf(drift_avg, 0.1)})
