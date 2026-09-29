extends Bot
## Plays the night street: darkness blocks her without a flame, the draft takes the candle
## when it is not cupped, a lit window relights it, cupping keeps it through the next
## draft, the clinic's lamp is lit from her flame, and Abu Ahmad's oven ends the beat.


func run() -> void:
	name_tag = "night"
	var night = target("NightStreet")
	var layla: Player = night.get_node("Player")
	if not flow:
		night.begin({"candle": true})
	var result := {}
	night.finished.connect(func(r: Dictionary): result.merge(r, true))
	await frames(10)
	var candle: Carryable = night.candle
	check(candle != null and layla.carried == candle and layla.has_light(), "Layla starts with the lit candle from home")
	check(night.lit_count() == 5, "five windows are lit from the data table (%d)" % night.lit_count())
	check(Sound.running_loops() == ["wind_loop"], "only the wind runs at night: no hum, no rumble on Day 1 (%s)" % [Sound.running_loops()])

	# Without a flame, darkness is a wall.
	await tap("grab")
	await frames(3)
	check(layla.carried == null, "sets the candle down")
	teleport(layla, Vector2(3360.0, 900.0))
	await frames(3)
	await hold("move_left", 90)
	check(layla.global_position.x > 3270.0, "without a flame she cannot go deeper into the dark (x=%.0f)" % layla.global_position.x)
	await hold("move_right", 30)
	teleport(layla, candle.global_position + Vector2(20.0, 0.0))
	await frames(4)
	await tap("grab")
	await frames(3)
	check(layla.carried == candle, "picks the candle up again")

	# The draft by the clinic takes the flame when it is not cupped.
	teleport(layla, Vector2(2640.0, 900.0))
	await frames(3)
	Input.action_press("move_left")
	var out := await until(func(): return not candle.lit, 240)
	Input.action_release("move_left")
	check(out, "the alley draft blows the candle out when it is not cupped")
	check(night.blown_out == 1, "one candle lost")
	check(int(Sound.play_count.get("candle_out", 0)) == 1, "the puff is heard once, from the candle itself")
	# Dead candle: darkness blocks again; a lit window relights it.
	teleport(layla, Vector2(2690.0, 900.0))
	await frames(4)
	await tap("interact")
	await frames(3)
	check(candle.lit and night.relit == 1, "a lit window relights the candle")

	# Through the same alley again is free (a draft waits once); cup the flame at the next one.
	teleport(layla, Vector2(2380.0, 900.0))
	await frames(3)
	# The clinic's dark window: light it from the flame (after the neighbour's line has cleared).
	teleport(layla, Vector2(2270.0, 900.0))
	await until(func(): return not Say.busy, 180)
	await frames(4)
	await tap("interact")
	await frames(3)
	check(night.acts == 1 and night.lit_count() == 6, "the clinic's lamp is lit from her flame")
	check(Notebook.has("night_clinic_lamp"), "the notebook remembers the act")

	teleport(layla, Vector2(1800.0, 900.0))
	await frames(3)
	Input.action_press("move_left")
	Input.action_press("interact")
	var passed := await until(func(): return layla.global_position.x < 1690.0, 240)
	Input.action_release("interact")
	Input.action_release("move_left")
	check(passed and candle.lit, "cupping the flame carries it through the draft by the stall")

	# The oven.
	teleport(layla, Vector2(1200.0, 900.0))
	check(await until(func(): return night.delivered, 120), "reaching the oven with a flame ends the walk")
	check(await until(func(): return result.get("bread", false), 300), "the beat finishes with bread")
	check(int(result.get("lit_windows", 0)) == 6, "the result counts six lit windows")
	check(Notebook.has("night_bread"), "the notebook remembers the bread")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
