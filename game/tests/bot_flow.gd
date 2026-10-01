extends Node2D
## Plays the whole prototype day through the real runner: Day.start(1) in bot mode, and for
## each beat the runner starts, the matching bot plays it. At the end it checks that every
## beat ran, that each handed its result forward, and that the notebook kept the acts.
## Exit code 0 when every check of every bot passes.

const DAY_BOTS := {
	1: {
	"res://scenes/d1_home_fajr.tscn": "res://tests/bot_d1_home_fajr.gd",
	"res://scenes/d1_street_morning.tscn": "res://tests/bot_d1_street_morning.gd",
	"res://scenes/d1_beach.tscn": "res://tests/bot_d1_beach.gd",
	"res://scenes/d1_kite_run.tscn": "res://tests/bot_d1_kite_run.gd",
	"res://scenes/d1_home_asr.tscn": "res://tests/bot_d1_home_asr.gd",
	"res://scenes/d1_roof_maghrib.tscn": "res://tests/bot_d1_roof_maghrib.gd",
	"res://scenes/d1_roof_isha.tscn": "res://tests/bot_d1_roof_isha.gd",
	"res://scenes/notebook_page.tscn": "res://tests/bot_notebook.gd",
	},
	3: {
	"res://scenes/d3_roofs_fajr.tscn": "res://tests/bot_d3_roofs_fajr.gd",
	"res://scenes/d3_dress.tscn": "res://tests/bot_d3_dress.gd",
	"res://scenes/d3_strike.tscn": "res://tests/bot_d3_strike.gd",
	"res://scenes/d3_minaret.tscn": "res://tests/bot_d3_minaret.gd",
	"res://scenes/d3_bakery.tscn": "res://tests/bot_d3_bakery.gd",
	"res://scenes/d3_dark_street.tscn": "res://tests/bot_d3_dark_street.gd",
	"res://scenes/d3_roof_night.tscn": "res://tests/bot_d3_roof_night.gd",
	"res://scenes/notebook_page.tscn": "res://tests/bot_notebook.gd",
	},
}
var BOTS: Dictionary = {}
var which_day := 1

var total_passed := 0
var reported := 0
var all_fails := PackedStringArray()
var played: Array = []
var _pending := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--day="):
			which_day = int(String(arg).substr(6))
	BOTS = DAY_BOTS.get(which_day, {})
	Notebook.clear()
	Day.beat_started.connect(_on_beat_started)
	Day.day_finished.connect(_on_day_finished)
	await get_tree().physics_frame
	Day.start(which_day, self)


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
		reported += 1
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
	var expect := {}
	if which_day == 3:
		expect = {
			"the eight beats of Day 3 ran in order": played == BOTS.keys(),
			"every Day 3 bot reported (a bot that touches a freed beat dies silently)": reported == BOTS.size(),
			"the strike handed the candle forward": bool(ctx.get("candle", false)) or bool(ctx.get("d3_struck", false)),
			"the bakery handed bread for the street forward": bool(ctx.get("d3_bread_for_street", false)),
			"the dark street handed the order of doors forward": (ctx.get("d3_bread_order", []) as Array).size() >= 1,
			"the notebook page ran": bool(ctx.get("notebook_shown", false)),
			"the notebook kept at least five entries": Notebook.day_entries(day).size() >= 5,
			"the notebook kept at least two acts for the final sky": Notebook.remembered_acts().size() >= 2,
		}
	else:
		expect = {
		"the eight beats of Day 1 ran in the script's order": played == BOTS.keys(),
		"every Day 1 bot reported (a bot that touches a freed beat dies silently)": reported == BOTS.size(),
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
