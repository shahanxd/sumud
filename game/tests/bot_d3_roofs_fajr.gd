extends Bot
## Plays Day 3 Scene 0: the two roofs at fajr with the hum under them. Flies the kite while
## Sami flies his across the gap, hears the hum rise, watches the pigeons refuse to settle,
## hears the talk across the gap and Teta's call from the stairs, reels in and goes down
## through the hatch, which ends the beat with the hum marked.


func run() -> void:
	name_tag = "d3_roofs_fajr"
	var beat = target("RoofsFajr")
	var layla: Player = beat.get_node("Player")
	var baba: Player = beat.get_node("Baba")
	var kite: Kite = beat.get_node("Kite")
	var sami: Npc = beat.get_node("Sami")
	var sami_kite: Kite = beat.get_node("SamiKite")
	var teta: Npc = beat.get_node("Teta")
	var result := {"finished": false, "y_at_end": 0.0}
	# The runner frees the beat the moment it finishes; read her place at that moment.
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		result["finished"] = true
		result["y_at_end"] = layla.global_position.y)
	var bangs0 := int(Sound.play_count.get("strike_bang", 0))
	var birds0 := int(Sound.play_count.get("birds_leave", 0))
	if not flow:
		beat.begin({})
	await frames(10)
	check(String(Look.current.get("phase", "")) == "morning" and int(Look.current.get("day", 0)) == 3, "fajr on Day 3: the morning palette with the day's saturation (%s, day %s)" % [Look.current.get("phase"), Look.current.get("day")])
	check(float(Look.current.get("saturation", 1.0)) < 0.6, "the colour is drained toward Day 3 (saturation %.2f)" % float(Look.current.get("saturation", 1.0)))
	check(layla.is_active and not baba.is_active, "Layla is active; Baba is not on the roof")
	check(kite.flying and beat.kite_in_play, "her kite is already up when the scene opens")
	check(sami_kite.flying, "Sami's kite is up over his roof")
	check(beat.get_node_or_null("NeighbourRoof") is StaticBody2D, "the neighbour roof stands across the gap")
	check(sami.global_position.x > 1510.0 and sami.global_position.y < 530.0, "Sami stands on his roof (%s)" % sami.global_position)
	check(sami.global_position.x - layla.global_position.x > 110.0, "the gap keeps them apart (%.0f px)" % (sami.global_position.x - layla.global_position.x))
	check(teta.global_position.y > 560.0, "Teta is on the stairs, not the roof (%s)" % teta.global_position)
	var loops: Array = Sound.running_loops()
	check("drone_hum_loop" in loops, "the hum is there from the start (%s)" % [loops])
	check("wind_loop" in loops and not ("rumble_loop" in loops), "the wind runs; no rumble this morning (%s)" % [loops])
	check(beat.hint.text == Say.text("d3.s0.hint.kite"), "the hint is the kite and the zanana")
	check(beat.pigeons.size() == 7, "pigeons on the tank (%d)" % beat.pigeons.size())
	var hum: AudioStreamPlayer = Sound.get_node_or_null("loop_drone_hum_loop")
	check(hum != null, "the hum has a player on the ambience bus")

	# Steering moves the kite, not her.
	var x0 := layla.global_position.x
	var kx := kite.global_position.x
	await hold("move_right", 30)
	check(absf(layla.global_position.x - x0) < 1.0, "she stands still while the kite flies")
	check(kite.global_position.x > kx + 20.0, "the kite steers right (%.0f px)" % (kite.global_position.x - kx))

	# The talk across the gap, then Teta.
	check(await until(func(): return beat.talked, 600), "the talk across the gap runs after she has flown a while (%s)" % [beat.said])
	check("d3.s0.sami.03" in beat.said and "d3.s0.layla.02" in beat.said, "eight days: Sami's count and Layla's answers were said")
	check(beat.pigeon_hops >= 2, "the pigeons will not settle (%d hops)" % beat.pigeon_hops)
	check(kite.flying and sami_kite.flying, "both kites are still up through the talk")
	check(await until(func(): return beat.teta_called, 300), "Teta calls from the stairs: the dress")
	if hum != null and is_instance_valid(hum):
		check(hum.volume_db > -22.0, "the hum has risen since the scene opened (%.1f dB)" % hum.volume_db)
	else:
		check(false, "the hum player is gone before the scene ends")
	check(int(Sound.play_count.get("strike_bang", 0)) == bangs0 and int(Sound.play_count.get("birds_leave", 0)) == birds0, "nothing has happened yet: no bang, the birds stay")

	# Reel in, then down through the hatch.
	await tap("kite")
	check(await until(func(): return not beat.kite_in_play, 30), "reeling in ends the kite play")
	check(not kite.flying and layla.kite == null, "the kite goes with her, out of play")
	await move_until("move_left", func(): return layla.global_position.x < 962.0, 120)
	await hold("move_down", 12)
	check(await until(func(): return layla.global_position.y > 560.0, 60), "down at the hatch drops her onto the upper flight (%s)" % layla.global_position)
	check(await until(func(): return bool(result["finished"]), 60), "the beat finishes once she is below the roof")
	check(bool(result.get("d3_hum", false)), "the result carries d3_hum")
	check(float(result["y_at_end"]) > 560.0, "she is on the way down (y %.0f)" % float(result["y_at_end"]))
	check(Notebook.has("d3_hum"), "the notebook keeps the bee")
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
