extends Bot
## Plays Day 3 Scene 8: the roof at night over the dark city, the oven glow and the windows
## she lit, the family sitting. Walks from the hatch to Teta, sits, hears the talk, holds the
## card over the sky, reads the caption of Teta reciting, and checks the beat ends marked.


func run() -> void:
	name_tag = "d3_roof_night"
	var beat = target("RoofNight")
	var layla: Player = beat.get_node("Player")
	var baba: Player = beat.get_node("Baba")
	var teta: Npc = beat.get_node("Teta")
	var mama: Npc = beat.get_node("Mama")
	var karim: Npc = beat.get_node("Karim")
	var lights: Node2D = beat.get_node("House/Lights")
	var oven: Node2D = beat.get_node("OvenGlow")
	var result := {"finished": false, "sitting_at_end": false, "recited": false}
	# The runner frees the beat right after it finishes; read her state at that moment.
	beat.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		result["finished"] = true
		result["recited"] = beat.recited
		result["sitting_at_end"] = layla.sitting)
	var bangs0 := int(Sound.play_count.get("strike_bang", 0))
	if not flow:
		beat.begin({"lit_windows": 3})
	await frames(10)
	var lit_expected := int(beat.context.get("lit_windows", 0))
	check(String(Look.current.get("phase", "")) == "siege_night" and int(Look.current.get("day", 0)) == 3, "night after the strike: the siege_night palette (%s)" % Look.current.get("phase"))
	check(not lights.visible, "the house is dark")
	check(beat.windows.size() == lit_expected, "as many windows lit as she lit tonight (%d of %d)" % [beat.windows.size(), lit_expected])
	check(oven.visible and oven.get_child_count() >= 1, "the oven glows low on the skyline")
	var loops: Array = Sound.running_loops()
	check("wind_loop" in loops and loops.size() == 1, "only the wind, low (%s)" % [loops])
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "no hum tonight, no rumble")
	check(layla.is_active and not baba.is_active and baba.sitting, "Layla is active; Baba sits")
	check(teta.global_position.y < 530.0 and mama.global_position.y < 530.0 and karim.global_position.y < 530.0, "Teta, Mama and Karim are on the roof")
	check(absf(layla.global_position.x - 960.0) < 30.0 and layla.global_position.y < 530.0, "Layla comes in at the hatch (%s)" % layla.global_position)
	check(beat.hint.text == Say.text("d3.s8.hint.sit"), "the hint is the sit")

	# Along the roof to Teta, past the family, and sit.
	var reached := await move_until("move_right", func(): return layla.global_position.x > 1240.0, 150)
	check(reached and layla.global_position.y < 530.0, "she walks the roof to Teta (%s)" % layla.global_position)
	await frames(6)
	await tap("interact")
	check(await until(func(): return beat.sat, 30), "interact at the sit spot starts the scene")
	check(layla.sitting, "Layla sits where Teta can reach her")
	check("roof_breath_loop" in Sound.running_loops(), "the roof breath comes in faint on the voices bus")
	check(int(Sound.play_count.get("cloth_rustle", 0)) >= 1, "cloth rustles as she sits down")
	check(await until(func(): return "d3.s8.teta.02" in beat.said, 600), "the talk: the minaret, and Abu Khalil's roof (%s)" % [beat.said])

	# The card over the sky: no line cues it; it holds, then continues on interact.
	check(await until(func(): return Cards.showing, 300), "the card lands over the sky")
	await frames(30)
	var amb := AudioServer.get_bus_index("ambience")
	check(amb >= 0 and AudioServer.get_bus_volume_db(amb) < -60.0, "every bus is silent under the ayah (%.0f dB)" % (AudioServer.get_bus_volume_db(amb) if amb >= 0 else 0.0))
	for _i in 12:
		if beat.card_done:
			break
		await frames(20)
		await tap("interact")
	check(await until(func(): return beat.card_done, 200), "the card holds, then continues on interact")

	# The caption: no speaker, no voice.
	check(await until(func(): return beat.caption_shown, 300), "then the caption: Teta recites over the children")
	await frames(3)
	check(Say.busy and String(Say._speaker.text).is_empty(), "the recitation is a caption with no speaker, never a voice")
	check(await until(func(): return bool(result["finished"]), 600), "the caption runs its time and the beat finishes")
	check(bool(result["recited"]), "the caption was shown to its end before the beat ended")
	check(bool(result.get("d3_roof_night", false)), "the result carries d3_roof_night")
	check(bool(result["sitting_at_end"]), "she is still sitting with them at the end")
	check(Notebook.has("d3_recite"), "the notebook keeps Teta reading over them")
	check(int(Sound.play_count.get("strike_bang", 0)) == bangs0, "nothing else happened tonight")
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
