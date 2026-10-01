extends Bot
## Plays Day 1 Scene 8: walks to Teta at the parapet, sits, hears the talk, holds the kite
## still against the wind while they speak, holds the hadith card, hears Baba from his net,
## and checks the beat hands forward that she held still and how far the kite drifted.


func run() -> void:
	name_tag = "d1_roof_maghrib"
	var beat = target("RoofMaghrib")
	var layla: Player = beat.get_node("Player")
	var baba: Player = beat.get_node("Baba")
	var kite: Kite = beat.get_node("Kite")
	var result := {}
	# The runner frees the beat right after it finishes; what the last checks need is read
	# at the moment of finishing, while the nodes are alive.
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		result["kite_flying_at_end"] = kite.flying
		result["sitting_at_end"] = layla.sitting)
	if not flow:
		beat.begin({"d1_contest_winner": "layla"})
	await frames(10)
	var won := String(beat.context.get("d1_contest_winner", "")) == "layla"
	check(String(Look.current.get("phase", "")) == "dusk", "the roof starts at maghrib, dusk palette (%s)" % Look.current.get("phase"))
	var loops: Array = Sound.running_loops()
	check("wind_loop" in loops and not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "the wind runs faint; no hum, no rumble (%s)" % [loops])
	check(not baba.is_active and baba.sitting, "Baba sits on the roof over his net")
	check(beat.get_node_or_null("Net") != null, "the net lies beside him")
	check(beat.pigeons.size() >= 6 and beat.pigeons.size() <= 9, "pigeons on the tank (%d)" % beat.pigeons.size())
	check(not kite.flying, "the kite is not up yet: Teta launches it")
	check(beat.hint.text == Say.text("d1.s8.hint.sit"), "the hint is the sit")
	var pigeon_x: Array[float] = []
	for p in beat.pigeons:
		pigeon_x.append(p.position.x)

	# Along the roof to the sit spot and sit.
	var reached := await move_until("move_right", func(): return layla.global_position.x > 1240.0, 120)
	check(reached and layla.global_position.y < 530.0, "she walks the roof to Teta (%s)" % layla.global_position)
	await frames(6)
	await tap("interact")
	check(await until(func(): return beat.sat, 30), "interact at the sit spot starts the scene")
	check(layla.sitting, "Layla sits")
	check("roof_breath_loop" in Sound.running_loops(), "the roof breath comes in on the voices bus")
	check(int(Sound.play_count.get("cloth_rustle", 0)) >= 1, "cloth rustles as she sits down")

	# Teta's launch and the hold.
	check(await until(func(): return beat.holding, 600), "Teta launches the kite and the hold begins")
	check(kite.flying, "the kite is up")
	if won:
		check("d1.s8.layla.win" in beat.said and not ("d1.s8.layla.lose" in beat.said) and not ("d1.s8.teta.02" in beat.said), "with the contest won, Layla says so and Teta has no correction (%s)" % [beat.said])
	else:
		check("d1.s8.layla.lose" in beat.said and "d1.s8.teta.02" in beat.said and not ("d1.s8.layla.win" in beat.said), "with the contest lost, Sami's tail cheated and Teta corrects her (%s)" % [beat.said])
	check("d1.s8.teta.08" in beat.said, "Teta hands over the string: hold it, still")
	check(beat.hint.text == Say.text("d1.s8.hint.still"), "the hint is the hold")
	check(layla.sitting and absf(layla.velocity.x) < 1.0, "she holds from where she sits")
	# A push against the wind: the drift measure answers the kite, nothing fails.
	await hold("move_left", 30)
	check(kite.flying and beat.holding, "steering during the hold cannot end it")
	check(await until(func(): return beat.hold_done, 1200), "the hold runs its time with the talk inside it")
	check("d1.s8.layla.03" in beat.said and "d1.s8.teta.05" in beat.said, "the talk reached the key (%s)" % [beat.said])
	check(beat.drift_avg >= 0.0 and beat.drift_avg < 900.0, "the drift was measured (avg %.1f px)" % beat.drift_avg)
	check(Notebook.has("d1_teta_question"), "the notebook keeps Teta's question")
	var moved := false
	for i in beat.pigeons.size():
		if absf(beat.pigeons[i].position.x - pigeon_x[i]) > 0.5:
			moved = true
	check(moved, "the pigeons shifted now and then")

	# The card: camera on the sea first, then the words; interact after the minimum hold.
	check(await until(func(): return Cards.showing, 300), "the hadith card appears with no line to cue it")
	for _i in 12:
		if beat.card_done:
			break
		await frames(20)
		await tap("interact")
	check(await until(func(): return beat.card_done, 200), "the card holds, then continues on interact")
	check(String(Look.current.get("phase", "")) == "night", "the sit turned the sky to night (%s)" % Look.current.get("phase"))
	check(await until(func(): return "d1.s8.baba.01" in beat.said, 300), "Baba speaks from his net after the card")
	check(await until(func(): return result.has("d1_held_still"), 300), "the beat finishes")
	check(bool(result.get("d1_held_still", false)) and result.get("d1_drift") is float, "the result carries d1_held_still and d1_drift (%s)" % [result])
	check(not bool(result["kite_flying_at_end"]) and not bool(result["sitting_at_end"]), "the kite is down and she is on her feet")
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
