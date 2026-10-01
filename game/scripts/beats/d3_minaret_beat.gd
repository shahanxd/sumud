extends "res://scripts/beats/night_street_beat.gd"
## Day 3, Scene 5 of docs/story/day3-script.md: the silent minaret. The street black after
## the bang, the mosque's speakers gone with the power, only the wind. Layla comes out of the
## home door with the candle. Silence, then from a low roof by the steps to the sea one unaided
## voice calls the isha adhan: Abu Khalil. Until a human recording exists the adhan is a
## caption and silence, never a synthetic voice. She climbs the ladder by his room to see him.
## Abu Ahmad's oven is not the goal tonight; the street's darkness, drafts and windows keep
## working as in the night street.

const LINES: Array[String] = ["d3.s5.layla.01", "d3.s5.abu_khalil.01", "d3.s5.layla.02", "d3.s5.abu_khalil.02"]
const KUFFIYEH := Color(0.86, 0.84, 0.78)
const KUFFIYEH_DARK := Color(0.14, 0.13, 0.14)

@onready var abu_khalil: Npc = $AbuKhalil

## Every line key this beat has fired, in order.
var said: Array[String] = []
## True once the adhan caption has been shown.
var caption_shown := false
var climb_hinted := false
## True once she has reached Abu Khalil on his roof.
var met := false


func _ready() -> void:
	super._ready()
	title = "The minaret"
	phase = "siege_night"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	_dress_abu_khalil()
	abu_khalil.approached.connect(_on_abu_khalil_approached)


func begin(ctx: Dictionary) -> void:
	# The candle and the wind come from the night street. After the bang: no hum.
	super.begin(ctx)
	hint.text = ""
	_opening()


func _wait(seconds: float, bot_seconds: float = 0.2) -> void:
	await get_tree().create_timer(bot_seconds if Day.bot_mode else seconds).timeout


func _closed() -> bool:
	return _done or not is_inside_tree()


func _say(k: String) -> void:
	said.append(k)
	await Say.key(k)


## Silence first; then the adhan as a caption; then the way up.
func _opening() -> void:
	await _wait(3.0, 0.3)
	if _closed():
		return
	caption_shown = true
	await Say.line("", "", Say.text("d3.s5.caption.adhan"), 5.0)
	if _closed() or met:
		return
	climb_hinted = true
	hint.text = Say.text("d3.s5.hint.climb")


## A kuffiyeh round his neck: the one pale thing on an elder in silhouette.
func _dress_abu_khalil() -> void:
	var h := abu_khalil.figure.height()
	var band := Polygon2D.new()
	band.name = "Kuffiyeh"
	band.color = KUFFIYEH
	band.polygon = PackedVector2Array([
		Vector2(-0.12 * h, -0.86 * h), Vector2(0.13 * h, -0.86 * h), Vector2(0.11 * h, -0.78 * h),
		Vector2(0.07 * h, -0.58 * h), Vector2(0.02 * h, -0.58 * h), Vector2(0.04 * h, -0.78 * h),
		Vector2(-0.05 * h, -0.78 * h), Vector2(-0.07 * h, -0.62 * h), Vector2(-0.12 * h, -0.62 * h),
		Vector2(-0.11 * h, -0.78 * h),
	])
	abu_khalil.figure.add_child(band)
	for i in 4:
		var mark := Polygon2D.new()
		mark.color = KUFFIYEH_DARK
		var x := -0.09 * h + 0.055 * h * float(i)
		var y := -0.84 * h
		mark.polygon = PackedVector2Array([Vector2(x, y), Vector2(x + 0.02 * h, y), Vector2(x + 0.02 * h, y + 0.02 * h), Vector2(x, y + 0.02 * h)])
		band.add_child(mark)


func _on_abu_khalil_approached(_npc: Npc) -> void:
	if met or _done:
		return
	met = true
	_meet()


func _meet() -> void:
	hint.text = ""
	for k in LINES:
		await _say(k)
		if _closed():
			return
	Notebook.write("d3_minaret", Say.text("d3.note.minaret", "en"), Say.text("d3.note.minaret", "ar"))
	finish({"d3_minaret": true, "candle": true})


## The oven is not the goal tonight: Abu Ahmad's talk and the oven do nothing.
func _try_deliver() -> void:
	pass
