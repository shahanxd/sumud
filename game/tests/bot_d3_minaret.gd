extends Bot
## Plays Day 3 Scene 5: Layla comes out of the home door with the candle into a street with
## only the wind, hears the silence and then the adhan as a caption (no sound), walks to the
## ladder by Abu Khalil's room, really climbs it with jumps, and reaches him on his roof.


func run() -> void:
	name_tag = "d3_minaret"
	var beat = target("Minaret")
	var layla: Player = beat.get_node("Player")
	var abu_khalil: Npc = beat.get_node("AbuKhalil")
	var abu_ahmad: Npc = beat.get_node("AbuAhmad")
	var hint: Label = beat.get_node("HUD/Hint")
	var result := {}
	var snap := {}
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["delivered"] = beat.delivered
		snap["said"] = beat.said.duplicate()
		snap["abu_ahmad_far"] = abu_ahmad.global_position.distance_to(layla.global_position) > 2000.0
		snap["y"] = layla.global_position.y)
	if not flow:
		beat.begin({"candle": true})
	await frames(10)
	var candle: Carryable = beat.candle
	check(String(Look.current.get("phase", "")) == "siege_night", "the street is the siege night (%s)" % Look.current.get("phase"))
	check(Sound.running_loops() == ["wind_loop"], "after the bang only the wind: no hum, no rumble (%s)" % [Sound.running_loops()])
	check(candle != null and layla.carried == candle and layla.has_light(), "Layla comes out with the lit candle")
	check(layla.global_position.x > 3300.0 and layla.global_position.x < 3700.0, "she starts at the home door side (%.0f)" % layla.global_position.x)
	check(hint.text == "" and not beat.caption_shown and not Say.busy, "silence first: no hint, no caption")
	var plays_before := _plays()
	check(await until(func(): return beat.caption_shown, 60), "after the silence the adhan is a caption")
	await frames(2)
	check(Say.busy, "the caption is on screen")
	check(_plays() == plays_before, "no sound plays for the adhan: no synthetic voice")
	check(await until(func(): return hint.text == Say.text("d3.s5.hint.climb"), 300), "the climb hint follows the caption")
	check(absf(abu_khalil.global_position.y - 700.0) < 1.0 and abu_khalil.build == 2, "Abu Khalil stands on a low roof by the steps to the sea")
	check(abu_khalil.figure.get_node_or_null("Kuffiyeh") != null, "a kuffiyeh round his neck")

	# Along the street to the ladder's foot.
	var there := await move_until("move_right", func(): return layla.global_position.x > 3666.0, 240)
	await frames(6)
	check(there and layla.global_position.x < 3680.0, "she walks under his roof to the ladder (%s)" % layla.global_position)
	check(not beat.met, "from the street she has not reached him")

	# Up the ladder with real jumps: each rung is a one-way step.
	var y0 := layla.global_position.y
	var climbs := 0
	for _i in 6:
		if layla.global_position.y <= 702.0:
			break
		await hold("jump", 30)
		await until(func(): return layla.is_on_floor(), 90)
		climbs += 1
	check(layla.global_position.y < y0 - 60.0, "a jump takes her onto a rung (%s)" % layla.global_position)
	check(layla.global_position.y <= 702.0 and layla.is_on_floor(), "she climbs to the roof's edge in %d jumps (%s)" % [climbs, layla.global_position])
	check(layla.has_light(), "the candle came up with her")

	# Across the roof to him.
	var reached := await move_until("move_right", func(): return beat.met, 200)
	check(reached and layla.global_position.y <= 702.0, "on the roof she reaches Abu Khalil (%s)" % layla.global_position)
	check(await until(func(): return result.has("d3_minaret"), 600), "the talk runs and the beat finishes")
	var said_lines: Array = snap.get("said", [])
	check(said_lines == ["d3.s5.layla.01", "d3.s5.abu_khalil.01", "d3.s5.layla.02", "d3.s5.abu_khalil.02"], "the four lines in order (%s)" % [said_lines])
	check(bool(result.get("d3_minaret", false)) and bool(result.get("candle", false)), "the result carries d3_minaret and the candle")
	check(Notebook.has("d3_minaret"), "the notebook keeps the voice from the roof")
	check(not bool(snap.get("delivered", true)), "the oven was never the goal")
	check(bool(snap.get("abu_ahmad_far", false)), "Abu Ahmad stayed at his oven, far behind")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


func _plays() -> int:
	var n := 0
	for k in Sound.play_count:
		n += int(Sound.play_count[k])
	return n


func move_until(action: String, pred: Callable, max_frames: int) -> bool:
	Input.action_press(action)
	var ok := await until(pred, max_frames)
	Input.action_release(action)
	return ok
