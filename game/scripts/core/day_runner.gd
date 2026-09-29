extends Node
## Autoload "Day". Plays the beats of a day in order, with a fade between them and the
## chapter card at the start. Holds the context dictionary that beats pass forward.
## Also the single place a bot hooks into: beat_started fires with the live beat.

signal beat_started(beat: Beat, index: int)
signal day_finished(day: int, context: Dictionary)

## The prototype day: one continuous playable from the beach to the end card.
const DAYS := {
	1: [
		"res://scenes/beach.tscn",
		"res://scenes/street.tscn",
		"res://scenes/home.tscn",
		"res://scenes/roof.tscn",
		"res://scenes/strike.tscn",
		"res://scenes/night_street.tscn",
		"res://scenes/notebook_page.tscn",
	],
}

const CARD_SCENE := "res://scenes/chapter_card.tscn"

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
	var card := packed.instantiate()
	_root.add_child(card)
	if bot_mode:
		card.stitch_seconds = 0.2
		card.hold_seconds = 0.05
	await card.play("Day %d" % day, _day_title())
	card.queue_free()


func _day_title() -> String:
	match day:
		1: return "The kites"
		_: return ""


func _next() -> void:
	if beat != null:
		beat.queue_free()
		beat = null
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
