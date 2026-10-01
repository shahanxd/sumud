extends Bot
## Plays Day 1's asr home beat to its end: comes in from the street, sees the power come on,
## takes Teta's thread, really walks the stairs to the roof, meets Sami across the gap,
## stitches the torn kite, flies the test flight and hears Um Sami call him down.


func run() -> void:
	name_tag = "d1_home_asr"
	var home = target("HomeAsr")
	var layla: Player = home.get_node("Player")
	var baba: Player = home.get_node("Baba")
	var spool: Carryable = home.get_node("Spool")
	var kite: Kite = home.get_node("PatchedKite")
	var sami: Npc = home.get_node("Sami")
	var lights: Node2D = home.get_node("House/Lights")
	var bulb: PointLight2D = home.get_node("House/Lights/BulbLight")
	var windows: Node2D = home.get_node("StreetWindows")
	var hint: Label = home.get_node("HUD/Hint")
	var result := {}
	# In the day flow the runner frees the beat the moment it finishes, so what the end
	# looks like is read here, while it is still alive, never after.
	var snap := {}
	home.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["sami_gone"] = not sami.visible
		snap["kite_down"] = not kite.flying)
	if not flow:
		home.begin({})
	await frames(5)
	check(layla.is_active and not baba.is_active, "Layla is active, Baba stays by the door with his net")
	var loops: Array = Sound.running_loops()
	check("wind_loop" in loops, "the wind runs faint over the house (%s)" % [loops])
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "Day 1: no hum and no rumble")
	check(not home.power_on and not lights.visible and bulb.energy == 0.0, "the house is dark when she comes in")
	check(String(Look.current.get("phase", "")) == "noon", "the asr light (%s)" % Look.current.get("phase"))
	check(hint.text == Say.text("d1.s7.hint.thread"), "the thread hint shows")

	# The power comes on.
	check(await until(func(): return home.power_on, 120), "the power comes on a moment after she enters")
	await frames(20)
	check(lights.visible and bulb.energy > 0.3, "the bulb comes up (energy %.2f)" % bulb.energy)
	check(home.fan_speed > 0.0, "the ceiling fan starts to turn")
	var lit := 0
	for w in windows.get_children():
		if (w as Polygon2D).color.a > 0.3:
			lit += 1
	check(lit >= 4, "windows light up across the street (%d of %d)" % [lit, windows.get_child_count()])
	check(await until(func(): return home.karim_awake, 120), "Karim wakes with the power")

	# The thread from the sewing tin.
	teleport(layla, Vector2(790.0, 900.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(layla.carried == spool and spool.label == "spool", "Layla takes the thread from the tin")
	check(await until(func(): return home.thread_taken, 900), "Teta's lines run and the thread is marked taken")
	check(Notebook.has("d1_thread"), "the notebook keeps the thread")
	teleport(layla, Vector2(1000.0, 900.0))
	check(await until(func(): return home.teta_warned, 60), "Teta's spoon line near the tray")

	# The stairs, on foot: under the flight to the wall, up, back along the first floor, up again.
	teleport(layla, Vector2(900.0, 900.0))
	await hold("move_right", 120)
	check(layla.global_position.y < 730.0 and layla.global_position.x > 1300.0, "Layla walks up the ground-floor flight with the spool (%s)" % layla.global_position)
	await hold("move_left", 160)
	check(layla.global_position.y < 530.0, "Layla walks up the second flight to the roof (%s)" % layla.global_position)
	Input.action_press("move_right")
	var at_gap := await until(func(): return home.gap_met, 300)
	Input.action_release("move_right")
	check(at_gap, "at the roof's edge Sami sees the thread across the gap (%s)" % layla.global_position)
	check(sami.global_position.x - layla.global_position.x > 100.0, "the gap keeps them apart (%.0f px)" % (sami.global_position.x - layla.global_position.x))
	check(await until(func(): return home.stage == home.Stage.STITCH, 900), "the talk across the gap ends with the stitch hint")
	check(hint.text == Say.text("d1.s7.hint.stitch"), "the stitch hint shows")

	# Stitch: hold E at the gap with the spool.
	var stitches := int(Sound.play_count.get("stitch_1", 0)) + int(Sound.play_count.get("stitch_2", 0)) + int(Sound.play_count.get("stitch_3", 0))
	await hold("interact", 40)
	check(await until(func(): return home.stitched, 60), "holding E stitches the tear")
	var stitches_after := int(Sound.play_count.get("stitch_1", 0)) + int(Sound.play_count.get("stitch_2", 0)) + int(Sound.play_count.get("stitch_3", 0))
	check(stitches_after > stitches, "the stitches are heard (%d)" % (stitches_after - stitches))
	check(layla.carried == null and not is_instance_valid(spool), "the thread is used up")
	check(not home.get_node("Sami/TornKite/Tear").visible, "the tear is closed")
	check(hint.text == Say.text("d1.s7.hint.test"), "the test flight hint shows")

	# The test flight from the roof.
	await frames(5)
	await tap("kite")
	check(await until(func(): return kite.flying, 30), "Q launches the patched kite from the roof")
	check(await until(func(): return home.stage == home.Stage.FLYING, 300), "after two seconds up, Sami calls it flying")
	check(await until(func(): return home.flown, 900), "Um Sami calls from below and Sami answers; the kite comes in")
	check(await until(func(): return result.get("d1_kite_patched", false), 900), "the beat finishes with the patched kite")
	check(bool(snap.get("kite_down", false)), "the kite is reeled in")
	check(bool(result.get("d1_thread_taken", false)), "the result carries the thread")
	check(bool(snap.get("sami_gone", false)), "Sami has gone down with his kite")
	check(String(Look.current.get("phase", "")) == "dusk", "the asr light has turned toward maghrib (%s)" % Look.current.get("phase"))
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
