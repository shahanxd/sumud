extends Node2D
## Plays the whole prototype day through the real runner: Day.start(1) in bot mode, and for
## each beat the runner starts, the matching bot plays it. At the end it checks that every
## beat ran, that each handed its result forward, and that the notebook kept the acts.
## Exit code 0 when every check of every bot passes.

const BOTS := {
	"res://scenes/d1_home_fajr.tscn": "res://tests/bot_d1_home_fajr.gd",
	"res://scenes/d1_street_morning.tscn": "res://tests/bot_d1_street_morning.gd",
	"res://scenes/d1_beach.tscn": "res://tests/bot_d1_beach.gd",
	"res://scenes/d1_kite_run.tscn": "res://tests/bot_d1_kite_run.gd",
	"res://scenes/d1_home_asr.tscn": "res://tests/bot_d1_home_asr.gd",
	"res://scenes/d1_roof_maghrib.tscn": "res://tests/bot_d1_roof_maghrib.gd",
	"res://scenes/d1_roof_isha.tscn": "res://tests/bot_d1_roof_isha.gd",
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
	var winner := String(ctx.get("d1_contest_winner", ""))
	var expect := {
		"the eight beats of Day 1 ran in the script's order": played == BOTS.keys(),
		"the beach handed the contest winner forward": winner == "layla" or winner == "sami",
		"the beach handed the tied tail and the promise forward": bool(ctx.get("d1_tail_tied", false)) and bool(ctx.get("d1_promise", false)),
		"the kite run handed the answer choice forward": String(ctx.get("d1_fix_answer", "")) in ["practice", "better"],
		"the asr house handed the thread and the patched kite forward": bool(ctx.get("d1_thread_taken", false)) and bool(ctx.get("d1_kite_patched", false)),
		"the maghrib roof handed the held kite forward": bool(ctx.get("d1_held_still", false)),
		"the notebook page ran": bool(ctx.get("notebook_shown", false)),
		"the notebook kept at least seven entries": Notebook.day_entries(day).size() >= 7,
		"the notebook kept at least two acts for the final sky": Notebook.remembered_acts().size() >= 2,
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
	# Quit clean: a player still playing at exit is reported as leaked.
	Sound.stop_all_loops(0.0)
	for _i in 600:
		if Sound.get_child_count() == 0:
			break
		await get_tree().physics_frame
	for _i in 30:
		await get_tree().physics_frame
	get_tree().quit(0 if all_fails.is_empty() else 1)
