extends Bot
## Plays Day 3 Scene 1: Layla comes up through the family hatch, really jumps the gap onto
## Sami's roof, sits with the women, hears the talk, freezes with them when the hum rises,
## hands the thread three times as the red band grows, hears Um Sami shout for the bread
## and Sami answer from below, and the asr light turns toward maghrib.


func run() -> void:
	name_tag = "d3_dress"
	var beat = target("Dress")
	var layla: Player = beat.get_node("Player")
	var teta: Npc = beat.get_node("Teta")
	var um_sami: Npc = beat.get_node("UmSami")
	var nour: Npc = beat.get_node("Nour")
	var mama: Npc = beat.get_node("Mama")
	var hint: Label = beat.get_node("HUD/Hint")
	var sit_spot: Area2D = beat.get_node("SitSpot")
	var result := {}
	# The runner frees the beat the moment it finishes; the end state is read while alive.
	var snap := {}
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["hum_level"] = beat.hum_level
		snap["band"] = beat.band_shown
		snap["said"] = beat.said.duplicate()
		snap["threads"] = beat.threads_handed)
	if not flow:
		beat.begin({})
	await frames(10)
	check(String(Look.current.get("phase", "")) == "noon", "the dress is sewn at noon (%s)" % Look.current.get("phase"))
	check(absf(float(Look.current.get("saturation", 1.0)) - 0.35) < 0.02, "Day 3 spends little colour (saturation %.2f)" % float(Look.current.get("saturation", 1.0)))
	var loops: Array = Sound.running_loops()
	check("drone_hum_loop" in loops and "wind_loop" in loops, "the hum is under everything with the wind (%s)" % [loops])
	check(beat.hum_level == -18.0, "the hum sits at -18 dB")
	check(hint.text == Say.text("d3.s1.hint.sit"), "the hint is the sit")
	var seated := 0
	for w in [teta, um_sami, nour, mama]:
		if (w as Npc).figure.pose == Figure.Pose.SIT:
			seated += 1
	check(seated == 4, "Teta, Um Sami, Nour and Mama sit round the dress (%d)" % seated)
	check(layla.global_position.x < 1000.0 and absf(layla.global_position.y - 500.0) < 3.0, "Layla starts at the family roof hatch (%s)" % layla.global_position)
	check(beat.band_shown == 6, "the red band starts with six squares")

	# Along the family roof and over the gap, a real jump.
	Input.action_press("move_right")
	var at_edge := await until(func(): return layla.global_position.x > 1300.0, 180)
	Input.action_press("jump")
	await frames(20)
	Input.action_release("jump")
	var crossed := await until(func(): return layla.global_position.x > 1540.0 and layla.is_on_floor(), 120)
	Input.action_release("move_right")
	await frames(6)
	check(at_edge and crossed and absf(layla.global_position.y - 500.0) < 3.0, "she jumps the gap onto Sami's roof (%s)" % layla.global_position)

	# To the cushion among them and sit.
	if layla.global_position.x < 1650.0:
		await move_until("move_right", func(): return layla.global_position.x > 1670.0, 120)
	elif layla.global_position.x > 1730.0:
		await move_until("move_left", func(): return layla.global_position.x < 1710.0, 120)
	await frames(8)
	check(sit_spot.overlaps_body(layla), "she stands at the sit spot (%s)" % layla.global_position)
	await tap("interact")
	check(await until(func(): return beat.sat, 30), "interact sits her with the women")
	check(layla.sitting, "Layla sits")
	check(int(Sound.play_count.get("cloth_rustle", 0)) >= 1, "cloth rustles as she sits down")

	# The talk, then the pause.
	check(await until(func(): return not is_instance_valid(beat) or "d3.s1.um_sami.02" in beat.said, 1200), "the talk runs to Um Sami's patience (%s)" % [_said(beat, snap)])
	check("d3.s1.teta.01" in _said(beat, snap) and "d3.s1.teta.02" in _said(beat, snap), "Teta's proverb placeholder and the spool line are said as they stand")
	check(await until(func(): return beat.paused_hands, 120), "the hum rises and every hand stops")
	await frames(12)
	check(teta.figure.process_mode == Node.PROCESS_MODE_DISABLED and layla.figure.process_mode == Node.PROCESS_MODE_DISABLED, "the idles are frozen through the pause")
	check(beat.hum_level == -12.0, "the hum is up 6 dB")
	check(await until(func(): return not beat.paused_hands, 400), "Teta says Allah yustur and the hands go on")
	check("d3.s1.teta.03" in _said(beat, snap), "Allah yustur was said")
	check(teta.figure.process_mode == Node.PROCESS_MODE_INHERIT and beat.hum_level == -18.0, "the idles resume and the hum settles")

	# The thread, three times.
	check(await until(func(): return hint.text == Say.text("d3.s1.hint.thread"), 500), "after the hem talk the thread hint shows")
	var stitches_before := _stitches()
	for i in 3:
		var reached := await until(func(): return beat.reaching != null, 200)
		var who: Npc = beat.reaching
		check(reached and who != null and who != teta, "a hand reaches for the thread (%s)" % (who.npc_name if who != null else "nobody"))
		await hold("interact", 30)
		check(await until(func(): return beat.threads_handed == i + 1, 60), "holding E hands the thread (%d)" % (i + 1))
		check(beat.band_shown == 6 + 4 * (i + 1), "the red band grows by a third (%d squares)" % beat.band_shown)
	check(_stitches() > stitches_before, "the stitches are heard as the band grows")

	# Um Sami shouts down, Sami answers, the adhan turns the light.
	check(await until(func(): return result.has("d3_dress"), 600), "the beat finishes with the dress")
	check("d3.s1.um_sami.04" in _said(beat, snap) and "d3.s1.sami.01" in _said(beat, snap), "Um Sami shouts for the bread and Sami answers from below")
	check(Notebook.has("d3_dress"), "the notebook keeps the dress")
	check(bool(result.get("d3_dress", false)), "the result carries d3_dress")
	check(int(snap.get("band", 0)) == 18 and int(snap.get("threads", 0)) == 3, "the band is full at the end")
	check(float(snap.get("hum_level", 0.0)) == -24.0, "the hum fades under the adhan")
	check(String(Look.current.get("phase", "")) == "dusk", "the asr light has turned toward maghrib (%s)" % Look.current.get("phase"))
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


func _stitches() -> int:
	return int(Sound.play_count.get("stitch_1", 0)) + int(Sound.play_count.get("stitch_2", 0)) + int(Sound.play_count.get("stitch_3", 0))


func move_until(action: String, pred: Callable, max_frames: int) -> bool:
	Input.action_press(action)
	var ok := await until(pred, max_frames)
	Input.action_release(action)
	return ok


## The beat's spoken keys while it is alive, the snapshot once the runner has freed it.
func _said(beat: Variant, snap: Dictionary) -> Array:
	if is_instance_valid(beat):
		return beat.said
	return snap.get("said", [])
