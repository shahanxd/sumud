extends Bot
## Plays Day 1 Scene 9: watches the city's lights cut out in sections, the light on the sea
## that never moves, Baba standing and sitting again with the cat gone still, stands at the
## parapet until the camera drifts toward the light, hears Teta send her in, and goes down
## through the hatch, which ends the beat.


func run() -> void:
	name_tag = "d1_roof_isha"
	var beat = target("RoofIsha")
	var layla: Player = beat.get_node("Player")
	var baba: Player = beat.get_node("Baba")
	var lights: Node2D = beat.get_node("House/Lights")
	var sea_light: Polygon2D = beat.get_node("SeaLight")
	var result := {"finished": false, "y_at_end": 0.0}
	# The runner frees the beat right after it finishes; read her place at that moment.
	beat.finished.connect(func(_r: Dictionary):
		result["finished"] = true
		result["y_at_end"] = layla.global_position.y)
	if not flow:
		beat.begin({})
	await frames(5)
	check(String(Look.current.get("phase", "")) == "night", "isha: the roof is in the night palette (%s)" % Look.current.get("phase"))
	check(lights.visible, "the house's lights are on at first")
	var windows: Array = beat.windows
	check(windows.size() >= 10 and windows.size() <= 14, "the city's windows are lit (%d)" % windows.size())
	var lit := 0
	for w in windows:
		if (w as Polygon2D).visible:
			lit += 1
	check(lit == windows.size(), "every window is lit before the cut")
	check(baba.sitting and beat.cat_moving, "Baba mends his net; Mishmish is awake beside him")
	var light_at: Vector2 = sea_light.global_position

	# The grid goes, section by section.
	check(await until(func(): return beat.lights_out_stage >= 1, 120), "the first section of the city goes dark")
	check(lights.visible, "our street still has power when the first section goes")
	check(await until(func(): return beat.lights_out_stage == 3, 120), "the rest cuts out, a section at a time")
	var dark := 0
	for w in windows:
		if not (w as Polygon2D).visible:
			dark += 1
	check(dark == windows.size() and not lights.visible, "every window is dark, ours too")
	check(sea_light.visible and sea_light.global_position == light_at, "the light on the sea is still there, where it was")
	var loops: Array = Sound.running_loops()
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops) and int(Sound.play_count.get("strike_bang", 0)) == 0, "no hum, no rumble, no strike: nothing threatening")

	# Baba stands, the cat stops, Baba sits again. Nobody says anything.
	check(await until(func(): return beat.baba_stood, 200), "Baba stops mending and stands")
	check(not baba.sitting and not beat.cat_moving, "while he stands the cat is still too")
	check(not Say.busy and beat.said.is_empty(), "nobody says anything about it")
	check(await until(func(): return baba.sitting, 200), "Baba sits and picks up the net again")
	check(await until(func(): return "d1.s9.teta.01" in beat.said and beat.sequence_done, 400), "Teta sends her inside")
	check(beat.hint.text == Say.text("d1.s9.hint.inside"), "the hint is the way down")
	check(sea_light.global_position == light_at, "the light has not moved all this while")

	# Standing still at the parapet, the camera drifts toward the light; moving brings it back.
	await move_until("move_right", func(): return absf(layla.global_position.x - 1200.0) < 30.0, 120)
	check(await until(func(): return beat.gazing, 90), "still at the parapet, the camera drifts toward the light")
	await hold("move_left", 8)
	check(await until(func(): return not beat.gazing, 30), "moving brings the camera back to her")

	# Down through the hatch: the beat ends on the first floor.
	await move_until("move_left", func(): return layla.global_position.x < 962.0, 120)
	await hold("move_down", 12)
	check(await until(func(): return layla.global_position.y > 560.0, 60), "down at the hatch drops her through (%s)" % layla.global_position)
	check(await until(func(): return bool(result["finished"]), 120), "the beat finishes once she is below the roof")
	check(float(result["y_at_end"]) > 560.0, "she is on the way down the stairs (y %.0f)" % float(result["y_at_end"]))
	if not flow:
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


func move_until(action: String, pred: Callable, max_frames: int) -> bool:
	Input.action_press(action)
	var ok := await until(pred, max_frames)
	Input.action_release(action)
	return ok
