extends Bot
## Plays the home beat: sits with Teta, holds the hadith card, is caught on the roof once
## (white-out, back to the hatch), takes cover, survives the bang, switches to Baba to lift
## the beam, switches back, takes the candle out of the door.


func run() -> void:
	name_tag = "home"
	var home = target("Home")
	var layla: Player = home.get_node("Player")
	var baba: Player = home.get_node("Baba")
	var candle: Carryable = home.get_node("Candle")
	var result := {}
	home.finished.connect(func(r: Dictionary): result.merge(r, true))
	await frames(10)
	check(not baba.is_active and layla.is_active, "Layla is active, Baba stands by")

	# Up to the roof and sit with Teta.
	teleport(layla, Vector2(1250.0, 500.0))
	await frames(8)
	await tap("interact")
	check(await until(func(): return home.sat, 60), "sitting with Teta starts the roof scene")
	check(layla.sitting, "Layla sits")
	# Lines auto-advance in bot mode; the card needs the interact key after its minimum hold.
	var card_open := await until(func(): return Cards.showing, 900)
	check(card_open, "the hadith card appears after Teta's question")
	for _i in 12:
		if home.card_done:
			break
		await frames(20)
		await tap("interact")
	check(await until(func(): return home.card_done, 200), "the card holds, then continues on interact")
	check(String(Look.current.get("phase", "")) == "night", "the roof sit turned the sky to night (%s)" % Look.current.get("phase"))
	check(Notebook.has("home_teta_question"), "the notebook keeps Teta's question")

	# Stay on the roof: caught outside once.
	check(await until(func(): return home.strike_armed, 300), "the strike is telegraphed after the card")
	check(await until(func(): return home.fails >= 1, 400), "caught on the roof: white-out, not death")
	check(layla.global_position.distance_to(Vector2(960.0, 500.0)) < 60.0, "sent back to the hatch (%.0f, %.0f)" % [layla.global_position.x, layla.global_position.y])

	# Take cover inside.
	teleport(layla, Vector2(800.0, 900.0))
	check(await until(func(): return home.struck, 400), "inside in time: the strike lands")
	check(String(Look.current.get("phase", "")) == "siege_night", "the world goes dark and grey (%s)" % Look.current.get("phase"))
	check(await until(func(): return home.beam != null, 120), "the beam comes down across the door")
	check(home.beam.blocking(), "the beam blocks the door")
	check(await until(func(): return home.switch_enabled, 900), "switching unlocks after Baba speaks")

	# Only Baba lifts the beam.
	var beam_item: Carryable = home.beam.get_node("Item")
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
	check(not home.beam.blocking(), "the door is free while the beam is up")
	teleport(baba, Vector2(1100.0, 900.0))
	await frames(3)
	await tap("grab")
	await frames(3)
	check(baba.carried == null and not home.beam.blocking(), "the beam set down away from the door stays out of the way")

	# Layla takes the candle out.
	await tap("switch_character")
	await frames(3)
	check(layla.is_active, "Tab switches back to Layla")
	teleport(layla, candle.global_position + Vector2(-20.0, 0.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(layla.carried == candle and layla.has_light(), "Layla carries the lit candle")
	teleport(layla, Vector2(630.0, 900.0))
	check(await until(func(): return result.get("candle", false), 300), "out of the door: the beat finishes with the candle")
	check(Notebook.has("home_first_strike"), "the notebook remembers the first strike")
	done()
