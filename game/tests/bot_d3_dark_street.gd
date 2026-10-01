extends Bot
## Plays Day 3 Scene 7: Layla leaves the oven with the candle and four loaves, cups the flame
## through the first draft, feeds the twins and the clinic (their windows light), loses the
## candle to the clinic's alley, is blocked by the dark, relights at the window she lit,
## feeds Hajja Amina and walks the long way to Abu Khalil's door by the steps to the sea.


func run() -> void:
	name_tag = "d3_dark_street"
	var beat = target("DarkStreet")
	var layla: Player = beat.get_node("Player")
	var oven: Area2D = beat.get_node("Oven")
	var hint: Label = beat.get_node("HUD/Hint")
	var result := {}
	var snap := {}
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["bread_left"] = beat.bread_left
		snap["lit"] = beat.lit_count())
	if not flow:
		beat.begin({"candle": true})
	await frames(10)
	var candle: Carryable = beat.candle
	var bread_label: Label = beat.get_node("HUD/Bread")
	check(String(Look.current.get("phase", "")) == "siege_night", "the street is the siege night (%s)" % Look.current.get("phase"))
	check(Sound.running_loops() == ["wind_loop"], "only the wind: no hum after the bang (%s)" % [Sound.running_loops()])
	check(candle != null and layla.carried == candle and layla.has_light(), "Layla starts with the lit candle")
	check(oven.overlaps_body(layla), "she starts at Abu Ahmad's oven (%s)" % layla.global_position)
	check(beat.bread_left == 4 and bread_label.text == "bread: 4", "four loaves on the tray, counted on the HUD")
	var tray: Node2D = layla.visual.get_node_or_null("Tray")
	check(tray != null and tray.get_child_count() == 5, "the tray is drawn in her other hand")
	check(hint.text == Say.text("d3.s7.hint.start"), "the hint names the four doors")
	check(beat.lit_count() == 5, "five windows are lit from the data table; Abu Khalil's is dark (%d)" % beat.lit_count())
	await frames(20)
	check(not beat.delivered, "the oven is not the goal with no bread delivered")

	# The first draft, by the stall: cupped.
	Input.action_press("move_right")
	Input.action_press("interact")
	# The gust decides on its own clock, not on where she is: hold until it has passed.
	var past := await until(func(): return _draft_done(beat, "the alley by the stall") and layla.global_position.x > 1830.0, 240)
	Input.action_release("interact")
	check(past and candle.lit and beat.blown_out == 0, "cupping the flame carries it through the first alley")
	check(hint.text == Say.text("d3.s7.hint.draft"), "the dust showed the draft and tonight's hint replaced the street's (%s)" % hint.text)

	# The twins' door.
	await until(func(): return layla.global_position.x > 1900.0, 60)
	Input.action_release("move_right")
	await frames(6)
	await tap("interact")
	check(await until(func(): return beat.order.size() == 1, 30) and beat.order[0] == "twins", "bread for the twins (%s)" % [beat.order])
	check(beat.bread_left == 3 and bread_label.text == "bread: 3", "three loaves left")
	check(beat.lit_count() == 6, "the twins' window lights")
	check(await until(func(): return not beat.delivering, 400), "Hassan, Hussein and Layla's answer run")
	check("d3.s7.twin.01" in beat.said and "d3.s7.twin.02" in beat.said and "d3.s7.layla.01" in beat.said, "the twins' lines were said (%s)" % [beat.said])
	check(Notebook.has("d3_bread_twins") and Notebook.has("d3_doors"), "the notebook keeps the twins' bread and the list of doors")

	# The clinic.
	await move_until("move_right", func(): return layla.global_position.x > 2330.0, 200)
	await frames(6)
	await tap("interact")
	check(await until(func(): return beat.order.size() == 2, 30) and beat.order[1] == "clinic", "bread for the clinic (%s)" % [beat.order])
	check(beat.lit_count() == 7, "the clinic's window lights")
	check(await until(func(): return not beat.delivering, 300), "Um Samir's line runs")

	# The clinic's alley takes the flame when she stands in the draft without cupping.
	await move_until("move_right", func(): return layla.global_position.x > 2462.0, 120)
	check(await until(func(): return not candle.lit, 120), "the alley draft blows the candle out when it is not cupped")
	check(beat.blown_out == 1, "one candle lost")
	var x_dark := layla.global_position.x
	await hold("move_right", 60)
	check(layla.global_position.x < x_dark + 60.0, "without a flame the dark stops her short of Hajja Amina's door (x=%.0f)" % layla.global_position.x)
	# Back to the clinic window she lit, and relight.
	await move_until("move_left", func(): return layla.global_position.x < 2290.0, 200)
	await until(func(): return not Say.busy, 120)
	await frames(6)
	await tap("interact")
	check(await until(func(): return candle.lit, 30) and beat.relit == 1, "the window she lit relights her candle")

	# Hajja Amina.
	await until(func(): return not Say.busy, 240)
	await move_until("move_right", func(): return layla.global_position.x > 2540.0, 240)
	await frames(6)
	check(candle.lit, "the alley's draft waits once: the flame is kept the second time")
	await tap("interact")
	check(await until(func(): return beat.order.size() == 3, 30) and beat.order[2] == "hajja_amina", "bread for Hajja Amina (%s)" % [beat.order])
	check(beat.lit_count() == 8 and beat.bread_left == 1, "her window lights; one loaf left")
	check(await until(func(): return not beat.delivering, 300), "Hajja Amina's line runs")
	check(not beat.delivered, "with three doors fed and the oven far behind, the walk goes on")

	# The long walk past home to Abu Khalil's door by the steps.
	var far := await move_until("move_right", func(): return layla.global_position.x > 3740.0, 420)
	await frames(6)
	check(far and candle.lit, "she walks the dark stretches past home with the flame (%s)" % layla.global_position)
	await tap("interact")
	check(await until(func(): return beat.order.size() == 4, 30) and beat.order[3] == "abu_khalil", "bread for Abu Khalil (%s)" % [beat.order])
	check(await until(func(): return result.has("d3_bread_order"), 400), "the fourth door ends the walk")
	var got: Array = result.get("d3_bread_order", [])
	check(got == ["twins", "clinic", "hajja_amina", "abu_khalil"], "the result carries the order of doors (%s)" % [got])
	check(int(result.get("lit_windows", 0)) == 9 and int(snap.get("lit", 0)) == 9, "nine windows are lit at the end (%s)" % result.get("lit_windows"))
	check(int(result.get("blown_out", -1)) == 1, "the result counts the candle lost")
	check(int(snap.get("bread_left", -1)) == 0, "the tray is empty")
	check(Notebook.has("d3_bread_abu_khalil") and Notebook.remembered_acts().size() >= 4, "every door is an act the notebook keeps")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


func _draft_done(beat: Node, draft_name: String) -> bool:
	for d in beat.drafts:
		if String(d["name"]) == draft_name:
			return bool(d["done"])
	return false


func move_until(action: String, pred: Callable, max_frames: int) -> bool:
	Input.action_press(action)
	var ok := await until(pred, max_frames)
	Input.action_release(action)
	return ok
