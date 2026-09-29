extends Node2D
## Plays the whole prototype day through the real runner: Day.start(1) in bot mode, and for
## each beat the runner starts, the matching bot plays it. At the end it checks that every
## beat ran, that each handed its result forward, and that the notebook kept the acts.
## Exit code 0 when every check of every bot passes.

const BOTS := {
	"res://scenes/beach.tscn": "res://tests/bot_beach_beat.gd",
	"res://scenes/street.tscn": "res://tests/bot_street.gd",
	"res://scenes/home.tscn": "res://tests/bot_home.gd",
	"res://scenes/night_street.tscn": "res://tests/bot_night.gd",
	"res://scenes/notebook_page.tscn": "res://tests/bot_notebook.gd",
}

var total_passed := 0
var all_fails := PackedStringArray()
var played: Array = []
var _pending := 0


func _ready() -> void:
	Notebook.clear()
	Day.beat_started.connect(_on_beat_started)
	Day.day_finished.connect(_on_day_finished)
	await get_tree().physics_frame
	Day.start(1, self)


func _on_beat_started(beat: Beat, index: int) -> void:
	var path := beat.scene_file_path
	played.append(path)
	print("flow: beat %d %s" % [index, path])
	if not BOTS.has(path):
		print("flow: no bot for ", path)
		return
	var bot: Bot = (load(BOTS[path]) as GDScript).new()
	bot.flow = true
	_pending += 1
	bot.run_finished.connect(func(p: int, f: PackedStringArray):
		total_passed += p
		all_fails.append_array(f)
		_pending -= 1
		bot.queue_free())
	add_child(bot)


func _on_day_finished(day: int, ctx: Dictionary) -> void:
	# Give the last bot a moment to report.
	for _i in 30:
		if _pending == 0:
			break
		await get_tree().physics_frame
	var fails := PackedStringArray()
	var checks := 0
	var expect := {
		"five beats ran in order": played == BOTS.keys(),
		"the beach handed kite_fetched forward": bool(ctx.get("kite_fetched", false)),
		"the street handed water forward": bool(ctx.get("water", false)),
		"the house handed the candle forward": bool(ctx.get("candle", false)),
		"the night handed bread forward": bool(ctx.get("bread", false)),
		"the notebook page ran": bool(ctx.get("notebook_shown", false)),
		"the notebook kept at least seven entries": Notebook.day_entries(day).size() >= 7,
		"the notebook kept at least four acts for the final sky": Notebook.remembered_acts().size() >= 4,
	}
	for k in expect:
		checks += 1
		if expect[k]:
			print("  ok   ", k)
		else:
			print("  FAIL ", k)
			fails.append("flow: " + String(k))
	all_fails.append_array(fails)
	total_passed += checks - fails.size()
	print("flow: %d passed, %d failed (day %d, %d entries)" % [total_passed, all_fails.size(), day, Notebook.day_entries(day).size()])
	for f in all_fails:
		print("  failed: ", f)
	get_tree().quit(0 if all_fails.is_empty() else 1)
