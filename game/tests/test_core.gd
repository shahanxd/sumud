extends Bot
## Checks the prototype spine headless: the notebook round-trips JSON, the colour budget
## resolves per day, the day runner chains beats and merges their results, and the
## screen effects run without error. Run:
##   godot --headless --path game res://tests/test_core.tscn -- --bot --notebook=user://test_notebook.json


func run() -> void:
	name_tag = "core"

	# Notebook.
	Notebook.clear()
	Notebook.begin_day(1)
	Notebook.write("kite_fetched_bread", "The kite brought the bread down from the roof.", "أنزلت الطائرة الخبز عن السطح", {"act": true})
	Notebook.write("kite_fetched_bread", "The kite brought the bread down from the roof.", "", {"act": true})
	Notebook.write("teta_line", "Teta asked what it means to stay.")
	check(Notebook.entries.size() == 2, "notebook replaces a repeated key instead of doubling it")
	check(Notebook.remembered_acts().size() == 1, "notebook counts acts for the final sky")
	var before := JSON.stringify(Notebook.entries)
	Notebook.entries = []
	Notebook.load_file()
	check(JSON.stringify(Notebook.entries) == before, "notebook round-trips through JSON (%s)" % Notebook.path)
	check(Notebook.has("teta_line", 1), "notebook finds an entry by key and day")

	# Look.
	var d1 := Look.palette(1, "dusk")
	var d7 := Look.palette(7, "dusk")
	check(d1["saturation"] > d7["saturation"], "day 7 spends less colour than day 1")
	check((d7["sky_horizon"] as Color).s < (d1["sky_horizon"] as Color).s, "desaturation lowers the horizon's saturation")
	var night := Look.palette(1, "night")
	check((night["ambient"] as Color).get_luminance() < 0.6, "night ambient is dark")
	Look.set_phase(1, "night", 0.0)
	check(Look.current["phase"] == "night", "set_phase with no duration applies at once")

	# Day runner.
	var finished := {}
	var starts := []
	Day.beat_started.connect(func(b: Beat, i: int): starts.append(i))
	# Lambdas capture locals by value, so mutate the dictionary rather than reassigning it.
	Day.day_finished.connect(func(_d: int, ctx: Dictionary): finished.merge(ctx, true))
	# A loop left running by one beat must not reach the next.
	Sound.loop("wind_loop", "ambience", -10.0, 0.0)
	Day.start_beats([
		"res://tests/beats/fake_beat.tscn",
		"res://tests/beats/missing_beat.tscn",
		"res://tests/beats/fake_beat.tscn",
	], get_parent(), {"day": 1, "carried": "bread"})
	var ok := await until(func(): return not finished.is_empty(), 300)
	check(ok, "day runner reaches the end of its beat list")
	check(starts == [0, 2], "day runner skips a missing beat and keeps the order (%s)" % [starts])
	check(int(finished.get("fake", 0)) == 2, "beat results merge into the day's context (fake=%s)" % finished.get("fake"))
	check(finished.get("carried") == "bread", "context passed at start survives to the end")
	check(Day.beat == null or not is_instance_valid(Day.beat) or Day.beat.is_queued_for_deletion(), "the last beat is freed")
	check(Sound.running_loops().is_empty(), "the day runner stops every loop between beats (%s)" % [Sound.running_loops()])

	# Fx.
	await Fx.strike_flash(0.1)
	await Fx.whiteout(0.1)
	await Fx.letterbox(true, 0.05)
	await Fx.letterbox(false, 0.05)
	await Fx.fade_out(0.05)
	await Fx.fade_in(0.05)
	check(true, "screen effects run to completion")

	# Quit clean: the loop the runner faded out must be gone before the tree goes down, and
	# the mixer needs a moment more to drop its playback.
	await until(func(): return Sound.get_child_count() == 0, 300)
	await frames(30)
	done()
