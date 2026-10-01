extends Node
## Autoload "Day". Plays the beats of a day in order, with a fade between them and the
## chapter card at the start. Holds the context dictionary that beats pass forward.
## Also the single place a bot hooks into: beat_started fires with the live beat.

signal beat_started(beat: Beat, index: int)
signal day_finished(day: int, context: Dictionary)

## Day 1 follows docs/story/day1-script.md scene by scene (the scenes share three spaces:
## the home with its roof, the street, the beach). The sampler's Day 3 and Day 4 content
## (the strike at home, the water run, the night street) waits under those days. A listed
## scene that does not exist yet is skipped with a warning, so the day runs while it grows.
const DAYS := {
	1: [
		"res://scenes/d1_home_fajr.tscn",
		"res://scenes/d1_street_morning.tscn",
		"res://scenes/d1_beach.tscn",
		"res://scenes/d1_kite_run.tscn",
		"res://scenes/d1_home_asr.tscn",
		"res://scenes/d1_roof_maghrib.tscn",
		"res://scenes/d1_roof_isha.tscn",
		"res://scenes/notebook_page.tscn",
	],
	3: [
		"res://scenes/home.tscn",
		"res://scenes/night_street.tscn",
		"res://scenes/notebook_page.tscn",
	],
	4: [
		"res://scenes/street.tscn",
		"res://scenes/notebook_page.tscn",
	],
}

const CARD_SCENE := "res://scenes/chapter_card.tscn"
## The stitches of a card are heard at most this often while it embroiders itself in.
const STITCH_INTERVAL_MS := 70

## True when a bot drives the game: no holds on cards or fades.
var bot_mode := false
var day := 0
var index := -1
var beat: Beat = null
var context: Dictionary = {}

var _root: Node = null


func _ready() -> void:
	bot_mode = OS.get_cmdline_user_args().has("--bot")


## Starts a day inside `root` (usually the main scene). Beats become children of root.
func start(which: int, root: Node, ctx: Dictionary = {}) -> void:
	_root = root
	day = which
	index = -1
	context = ctx.duplicate()
	context["day"] = day
	Notebook.begin_day(day)
	Fx.blackout()
	await _play_card()
	_next()


## Plays only the beats listed, for tests. Scene paths that do not exist are skipped
## with a warning so a half-built day still runs end to end.
func start_beats(paths: Array, root: Node, ctx: Dictionary = {}) -> void:
	_root = root
	day = int(ctx.get("day", 0))
	index = -1
	context = ctx.duplicate()
	_custom = paths
	_next()


var _custom: Array = []


func _beats() -> Array:
	if not _custom.is_empty():
		return _custom
	return DAYS.get(day, [])


func _play_card() -> void:
	var packed: PackedScene = load(CARD_SCENE)
	if packed == null:
		return
	var card: ChapterCard = packed.instantiate()
	_root.add_child(card)
	if bot_mode:
		card.stitch_seconds = 0.2
		card.hold_seconds = 0.05
	stitch_sounds(card)
	await card.play("Day %d" % day, _day_title())
	card.queue_free()


## A needle for a chapter card: while its band stitches itself in, one of the three stitch
## sounds each time the placed count grows, at most one every STITCH_INTERVAL_MS. Runs
## beside card.play() (call it, do not await it) and ends with the band or with the card.
func stitch_sounds(card: ChapterCard) -> void:
	var total: int = card._stitches.size()
	var placed := 0
	var last_ms := -1000
	while is_instance_valid(card) and card.is_inside_tree() and card._progress < 1.0:
		var now_placed := int(card._progress * float(total))
		var now := Time.get_ticks_msec()
		if now_placed > placed and now - last_ms >= STITCH_INTERVAL_MS:
			last_ms = now
			Sound.play("stitch_%d" % randi_range(1, 3), "effects", -4.0, 0.1)
		placed = now_placed
		await get_tree().process_frame


func _day_title() -> String:
	match day:
		1: return "The kites"
		3: return "The dark"
		4: return "Water"
		_: return ""


func _next() -> void:
	if beat != null:
		beat.queue_free()
		beat = null
		# A beat's ambience leaves with it; the next one starts its own in begin().
		Sound.stop_all_loops(1.2)
	index += 1
	var beats := _beats()
	while index < beats.size() and not ResourceLoader.exists(beats[index]):
		push_warning("day: beat scene missing, skipped: " + beats[index])
		index += 1
	if index >= beats.size():
		_custom = []
		day_finished.emit(day, context)
		return
	var packed: PackedScene = load(beats[index])
	var node := packed.instantiate()
	beat = node as Beat
	if beat == null:
		push_error("day: %s is not a Beat" % beats[index])
		node.queue_free()
		_next()
		return
	_root.add_child(beat)
	beat.finished.connect(_on_beat_finished, CONNECT_ONE_SHOT)
	Look.set_phase(day, beat.phase, 0.0)
	beat.begin(context)
	beat_started.emit(beat, index)
	Fx.fade_in(0.0 if bot_mode else 0.8)


func _on_beat_finished(result: Dictionary) -> void:
	for k in result:
		context[k] = result[k]
	await Fx.fade_out(0.0 if bot_mode else 0.6)
	_next()
