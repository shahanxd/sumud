extends Bot
## Plays Day 3 Scenes 2 to 4: the telegraph on the roof (the birds, the hum, the rumble,
## Baba from inside), is caught on the roof once on purpose (white-out, back to the hatch),
## then really runs down through the hatch into the stairwell inside the shorter clock,
## holds the card on the candle, survives the one bang, holds the card over the dark street,
## sits through the title card and the names, switches to Baba to lift the beam, switches
## back, and takes the lit candle out of the door.


func run() -> void:
	name_tag = "d3_strike"
	var beat = target("Strike")
	var layla: Player = beat.get_node("Player")
	var baba: Player = beat.get_node("Baba")
	var teta: Npc = beat.get_node("Teta")
	var mama: Npc = beat.get_node("Mama")
	var karim: Npc = beat.get_node("Karim")
	var candle: Carryable = beat.get_node("Candle")
	var lights: Node2D = beat.get_node("House/Lights")
	var window_bar: Polygon2D = beat.get_node("House/WindowBarG")
	var window_void: Polygon2D = beat.get_node("House/WindowVoid")
	var glass_floor: Node2D = beat.get_node("GlassFloor")
	var result := {}
	beat.finished.connect(func(r: Dictionary): result.merge(r, true))
	# Counts are shared across the day's beats: everything is measured from here.
	var bangs0 := int(Sound.play_count.get("strike_bang", 0))
	var birds0 := int(Sound.play_count.get("birds_leave", 0))
	var ring0 := int(Sound.play_count.get("ringing", 0))
	var door0 := int(Sound.play_count.get("door_wood", 0))
	if not flow:
		beat.begin({})
	await frames(10)
	check(layla.is_active and not baba.is_active, "Layla is active; Baba stands by downstairs")
	check(layla.global_position.y < 530.0, "Layla is on the roof at maghrib (%s)" % layla.global_position)
	check(teta.global_position.y > 890.0 and mama.global_position.y > 890.0 and karim.global_position.y > 890.0 and baba.global_position.y > 890.0, "Teta, Mama, Karim and Baba are downstairs, under the stairs")
	check(String(Look.current.get("phase", "")) == "dusk" and int(Look.current.get("day", 0)) == 3, "maghrib: the dusk palette of Day 3 (%s)" % Look.current.get("phase"))
	var loops: Array = Sound.running_loops()
	check("wind_loop" in loops and "drone_hum_loop" in loops, "the wind and the hum run over the roof (%s)" % [loops])
	check(not ("rumble_loop" in loops) and not beat.strike_armed, "no rumble yet: the telegraph has not begun")
	check(beat.pigeons.size() == 7, "pigeons on the tank (%d)" % beat.pigeons.size())

	# The telegraph: the birds, the hum up, the rumble under it, Baba from inside, the clock.
	check(await until(func(): return beat.strike_armed, 120), "the telegraph begins a moment after the scene opens")
	check(int(Sound.play_count.get("birds_leave", 0)) == birds0 + 1 and beat.pigeons.is_empty(), "the pigeons lift all at once")
	check(beat.hint.text == Say.text("d3.s2.hint.cover"), "the hint is the way down to the family")
	check(await until(func(): return "rumble_loop" in Sound.running_loops(), 90), "the rumble comes in under the hum (%s)" % [Sound.running_loops()])
	check(await until(func(): return "d3.s2.baba.01" in beat.said, 120), "Baba shouts from inside")

	# Caught outside once: stay on the roof through the clock.
	check(await until(func(): return beat.fails >= 1, 300), "caught on the roof: white-out, not death")
	check(layla.global_position.distance_to(Vector2(960.0, 500.0)) < 60.0 and not beat.struck, "sent back to the hatch, and the bang has not come (%.0f, %.0f)" % [layla.global_position.x, layla.global_position.y])

	# The real run, inside the shorter clock: down through the hatch and along the flight
	# into the stairwell. Down opens the well; right carries her through the air and on.
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(4)
	Input.action_release("move_down")
	var dropped := await until(func(): return layla.global_position.y > 560.0, 60)
	check(dropped, "down at the hatch drops her onto the upper flight (%s)" % layla.global_position)
	var covered := await until(func(): return beat.in_cover, 150)
	Input.action_release("move_right")
	check(covered and beat.fails == 1, "in the stairwell in time on the second clock (%s, fails %d)" % [layla.global_position, beat.fails])
	check(layla.global_position.x > 1060.0 and layla.global_position.y > 560.0, "she ran there on foot, below the roof (%s)" % layla.global_position)
	check(not layla.is_active, "no control under the stairs")
	check(await until(func(): return "d3.s3.baba.01" in beat.said, 120), "Baba: heads down")

	# The ayah on the candle: the camera leaves the faces, every bus goes silent, the card holds.
	check(await until(func(): return Cards.showing, 300), "Teta's whisper is the card on the candle, not a spoken line")
	# The duck takes 0.4 s to reach silence; the card holds longer than that in bot mode.
	await frames(30)
	var amb := AudioServer.get_bus_index("ambience")
	check(amb >= 0 and AudioServer.get_bus_volume_db(amb) < -60.0, "every bus is silent under the ayah (%.0f dB)" % (AudioServer.get_bus_volume_db(amb) if amb >= 0 else 0.0))
	check("drone_hum_loop" in Sound.running_loops() and "rumble_loop" in Sound.running_loops() and not beat.struck, "the hum and the rumble are only held, the bang has not come")
	for _i in 12:
		if beat.card_done:
			break
		await frames(20)
		await tap("interact")
	check(await until(func(): return beat.card_done, 200), "the card holds, then continues on interact")

	# The bang.
	check(await until(func(): return beat.struck, 200), "the bang")
	check(int(Sound.play_count.get("strike_bang", 0)) == bangs0 + 1, "one bang, on the strike bus (%d)" % (int(Sound.play_count.get("strike_bang", 0)) - bangs0))
	check(Sound.running_loops().is_empty(), "every loop is cut with the bang (%s)" % [Sound.running_loops()])
	check(String(Look.current.get("phase", "")) == "siege_night", "the world goes dark and grey (%s)" % Look.current.get("phase"))
	check(not lights.visible, "the lights are gone")
	check(not window_bar.visible and window_void.visible and glass_floor.visible, "the ground-floor window is blown in, glass on the floor")
	check(await until(func(): return beat.beam != null, 120), "the beam comes down across the door")
	check(beat.beam.blocking(), "the beam blocks the door")
	check(int(Sound.play_count.get("ringing", 0)) == ring0 + 1, "the ringing, once, after the bang")

	# The second card over the dark street, then the title.
	check(await until(func(): return Cards.showing, 300), "the second card lands over the street through the empty frame")
	var stitches_before := _stitches()
	for _i in 12:
		if beat.test_card_done:
			break
		await frames(20)
		await tap("interact")
	check(await until(func(): return beat.test_card_done, 200), "the second card holds, then continues")
	check(await until(func(): return beat.titled, 300), "the title card: SUMUD")
	check(_stitches() > stitches_before, "the title stitched itself in with the needle (%d stitches)" % (_stitches() - stitches_before))
	check(not layla.is_active and not beat.switch_enabled, "no control through the title and the names")

	# The names, in the script's order; then Baba and the beam.
	check(await until(func(): return beat.named, 900), "everyone says their name (%s)" % [beat.said])
	var order: Array[String] = ["d3.s4.karim.01", "d3.s4.baba.01", "d3.s4.mama.01", "d3.s4.baba.02", "d3.s4.layla.01", "d3.s4.karim.02", "d3.s4.teta.01", "d3.s4.mama.02"]
	var in_order := true
	var last := -1
	for k in order:
		var i: int = beat.said.find(k)
		if i < 0 or i < last:
			in_order = false
		last = i
	check(in_order, "the names came in the script's order")
	check(await until(func(): return beat.switch_enabled, 300), "switching unlocks after Baba asks for the light")
	check(layla.is_active and beat.hint.text == Say.text("d3.s4.hint.switch"), "control returns with the switch hint")
	check(Notebook.has("d3_strike"), "the notebook remembers the strike")

	# Only Baba lifts the beam.
	var beam_item: Carryable = beat.beam.get_node("Item")
	teleport(layla, beam_item.global_position + Vector2(40.0, 0.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(layla.carried == null, "Layla cannot lift the beam")
	await tap("switch_character")
	await frames(3)
	check(baba.is_active and not layla.is_active, "Tab switches to Baba")
	teleport(baba, beam_item.global_position + Vector2(40.0, 0.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(baba.carried == beam_item, "Baba lifts the beam")
	check(not beat.beam.blocking() and beat.hint.text == Say.text("d3.s4.hint.candle"), "the door is free while the beam is up, and the hint turns to the candle")
	teleport(baba, Vector2(1000.0, 900.0))
	await frames(3)
	await tap("grab")
	await frames(3)
	check(baba.carried == null and not beat.beam.blocking(), "the beam set down away from the door stays out of the way")

	# Layla takes the candle from the step and out.
	await tap("switch_character")
	await frames(3)
	check(layla.is_active, "Tab switches back to Layla")
	teleport(layla, Vector2(1090.0, 900.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(layla.carried == candle and layla.has_light(), "Layla carries the lit candle from the step")
	# Seven seconds on from the bang the wind is back, low; nothing else.
	var wind_back := await until(func(): return "wind_loop" in Sound.running_loops(), 600)
	check(wind_back and not ("drone_hum_loop" in Sound.running_loops()) and not ("rumble_loop" in Sound.running_loops()), "the wind returns after the bang; no hum tonight (%s)" % [Sound.running_loops()])
	teleport(layla, Vector2(630.0, 900.0))
	check(await until(func(): return result.get("candle", false), 300), "out of the door: the beat finishes with the candle")
	check(bool(result.get("d3_struck", false)) and bool(result.get("strike", false)) and bool(result.get("beam_lifted", false)), "the result carries d3_struck, strike and beam_lifted (%s)" % [result])
	check(int(result.get("d3_fails", -1)) == 1, "the result counts the one time she was caught (%s)" % [result.get("d3_fails")])
	check(int(Sound.play_count.get("door_wood", 0)) == door0 + 1 and int(Sound.play_count.get("strike_bang", 0)) == bangs0 + 1, "the door to the street sounds on the way out, and the bang was only ever one")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


func _stitches() -> int:
	return int(Sound.play_count.get("stitch_1", 0)) + int(Sound.play_count.get("stitch_2", 0)) + int(Sound.play_count.get("stitch_3", 0))
