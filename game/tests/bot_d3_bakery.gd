extends Bot
## Plays Day 3's bakery beat (Scene 6) to its end with real inputs: Tab cycles the three,
## Layla cannot lift the beam and Baba cannot get through the crawl gap, Baba lifts the beam,
## Teta walks slowly to Abu Ahmad and persuades him, Layla really crawls into the back room
## for both sacks and drops them in the hopper, and the baking ends on the hadith card.


func run() -> void:
	name_tag = "d3_bakery"
	var bakery = target("Bakery")
	var layla: Player = bakery.get_node("Player")
	var baba: Player = bakery.get_node("Baba")
	var teta: Player = bakery.get_node("Teta")
	var abu_ahmad: Npc = bakery.get_node("AbuAhmad")
	var beam: Beam = bakery.get_node("Beam")
	var beam_item: Carryable = beam.get_node("Item")
	var sack1: Carryable = bakery.get_node("Sack1")
	var sack2: Carryable = bakery.get_node("Sack2")
	var glow: PointLight2D = bakery.get_node("Oven/Glow")
	var camera: Camera2D = bakery.get_node("Camera")
	var hint: Label = bakery.get_node("HUD/Hint")
	var result := {}
	# The runner frees the beat the moment it finishes: read the end while it is alive.
	var snap := {}
	bakery.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["glow"] = glow.energy
		snap["turns"] = bakery.turns
		snap["candle"] = layla.has_light()
		snap["card"] = bakery.card_shown)
	if not flow:
		bakery.begin({"candle": true})
	await frames(10)
	check(layla.is_active and not baba.is_active and not teta.is_active, "Layla is active at the door; Baba and Teta stand by")
	check(layla.has_light(), "Layla holds the lit candle from under the stairs")
	check(Sound.running_loops() == ["wind_loop"], "only the wind runs after the bang (%s)" % [Sound.running_loops()])
	check(glow.energy < 0.05 and beam.blocking(), "the oven is cold under the beam")

	# Switching waits for Abu Ahmad.
	await tap("switch_character")
	await frames(3)
	check(layla.is_active and not bakery.switch_enabled, "Tab does nothing before Abu Ahmad has spoken")
	check(await until(func(): return bakery.switch_enabled, 600), "switching unlocks after the opening line")
	check(hint.text == Say.text("d3.s6.hint.switch"), "the switch hint shows once switching is open")

	# Layla cannot lift the beam. She sets the candle down by the door first.
	await tap("grab")
	await frames(3)
	check(layla.carried == null, "Layla sets the candle down")
	teleport(layla, beam_item.global_position + Vector2(30.0, 0.0))
	await frames(4)
	await tap("grab")
	await frames(3)
	check(layla.carried == null and beam.blocking(), "Layla cannot lift the beam")
	# Standing, the collapsed lintel stops her at the back room.
	teleport(layla, Vector2(1010.0, 900.0))
	await frames(4)
	await hold("move_left", 60)
	check(layla.global_position.x > 950.0 and not layla.crawling, "standing, the rubble stops her at the back room (x=%.0f)" % layla.global_position.x)

	# Baba: the beam. He cannot get through the crawl gap.
	await tap("switch_character")
	await frames(3)
	check(baba.is_active and not layla.is_active and not teta.is_active, "Tab switches to Baba")
	check(hint.text == Say.text("d3.s6.hint.beam"), "Baba's hint shows the beam")
	teleport(baba, Vector2(1010.0, 900.0))
	await frames(4)
	Input.action_press("move_down")
	Input.action_press("move_left")
	await frames(90)
	release_all()
	check(baba.global_position.x > 950.0, "Baba cannot get through the crawl gap (x=%.0f)" % baba.global_position.x)
	teleport(baba, beam_item.global_position + Vector2(40.0, 0.0))
	await frames(4)
	await tap("grab")
	await frames(3)
	check(baba.carried == beam_item, "Baba lifts the beam")
	check(not beam.blocking() and bakery.oven_clear, "the oven door is clear once the beam is up")
	await hold("move_right", 50)
	await tap("grab")
	await frames(3)
	check(baba.carried == null and not beam.blocking(), "the beam set down away from the oven stays out of the way")

	# Teta: the walk and the talk.
	await tap("switch_character")
	await frames(3)
	check(teta.is_active and not baba.is_active and not layla.is_active, "Tab switches to Teta")
	check(hint.text == Say.text("d3.s6.hint.teta"), "Teta's hint shows the talk")
	var y0 := teta.global_position.y
	await tap("jump")
	await frames(20)
	check(absf(teta.global_position.y - y0) < 2.0, "Teta does not jump")
	var x0 := teta.global_position.x
	await hold("move_left", 60)
	var walked := x0 - teta.global_position.x
	check(walked > 50.0 and walked < 160.0, "Teta walks slowly (%.0f px in 60 frames)" % walked)
	Input.action_press("move_left")
	var near := await until(func(): return teta.global_position.distance_to(abu_ahmad.global_position) < 120.0, 400)
	Input.action_release("move_left")
	check(near, "Teta walks to Abu Ahmad (x=%.0f)" % teta.global_position.x)
	await frames(6)
	await tap("interact")
	check(await until(func(): return bakery._talking, 60), "E starts the persuasion")
	check(await until(func(): return bakery.persuaded, 1500), "Teta persuades Abu Ahmad")
	check(not bakery.baking, "nothing bakes before the flour is in")

	# Layla: the flour, twice, on hands and knees.
	await tap("switch_character")
	await frames(3)
	check(layla.is_active and not teta.is_active, "Tab cycles back to Layla")
	check(hint.text == Say.text("d3.s6.hint.flour"), "Layla's hint shows the flour")
	teleport(layla, Vector2(1000.0, 900.0))
	await frames(4)
	Input.action_press("move_down")
	Input.action_press("move_left")
	var inside := await until(func(): return layla.global_position.x < 712.0, 300)
	release_all()
	check(inside and layla.crawling, "she crawls through the gap into the back room (x=%.0f)" % layla.global_position.x)
	check(bakery.cat_seen, "Layla sees the cat in the rubble")
	await tap("grab")
	await frames(3)
	check(layla.carried == sack1, "she takes the first sack")
	Input.action_press("move_down")
	Input.action_press("move_right")
	var out := await until(func(): return layla.global_position.x > 1010.0, 300)
	release_all()
	check(out, "she crawls out with the sack (x=%.0f)" % layla.global_position.x)
	await frames(20)
	check(not layla.crawling, "she stands up again in the front room")
	# A sack set down short of the hopper is not counted and can be taken again.
	await tap("grab")
	await frames(6)
	check(bakery.sacks_in == 0 and is_instance_valid(sack1) and not sack1.held, "a sack dropped short of the machine is not counted")
	await tap("grab")
	await frames(3)
	check(layla.carried == sack1, "the dropped sack can be picked up again")
	Input.action_press("move_right")
	var at_machine := await until(func(): return layla.global_position.x > 1250.0, 300)
	Input.action_release("move_right")
	check(at_machine, "she carries it to the machine (x=%.0f)" % layla.global_position.x)
	await frames(4)
	await tap("grab")
	check(await until(func(): return bakery.sacks_in == 1, 30), "the first sack goes into the hopper")

	Input.action_press("move_left")
	await until(func(): return layla.global_position.x < 1000.0, 300)
	Input.action_release("move_left")
	await frames(4)
	Input.action_press("move_down")
	Input.action_press("move_left")
	var inside2 := await until(func(): return layla.global_position.x < 802.0, 300)
	release_all()
	check(inside2 and layla.crawling, "she crawls in again (x=%.0f)" % layla.global_position.x)
	await tap("grab")
	await frames(3)
	check(layla.carried == sack2, "she takes the second sack")
	Input.action_press("move_down")
	Input.action_press("move_right")
	await until(func(): return layla.global_position.x > 1010.0, 300)
	release_all()
	await frames(10)
	Input.action_press("move_right")
	await until(func(): return layla.global_position.x > 1250.0, 300)
	Input.action_release("move_right")
	await frames(4)
	await tap("grab")
	check(await until(func(): return bakery.sacks_in == 2, 30), "the second sack goes in: two counted")

	# The baking.
	check(await until(func(): return bakery.baking, 60), "with flour, oven and Abu Ahmad, the baking starts")
	check(await until(func(): return glow.energy > 1.0, 300), "the oven glow warms up")
	check(await until(func(): return Cards.showing, 1500), "the hadith card appears on the oven mouth")
	await frames(15)
	check(Cards.showing, "the card holds")
	check(camera.zoom.x < 1.2, "the camera is on the oven mouth under the card (zoom %.2f)" % camera.zoom.x)
	check(await until(func(): return not Cards.showing, 600), "the card lets go")
	check(await until(func(): return result.get("d3_bread_for_street", false), 900), "the beat finishes with bread for the street")
	check(bool(result.get("bread", false)) and bool(result.get("candle", false)), "the result carries the bread and the candle")
	check(int(snap.get("turns", 0)) >= 1, "the crank turned (%d turns)" % int(snap.get("turns", 0)))
	check(bool(snap.get("candle", false)), "Layla leaves with the lit candle")
	check(Notebook.has("d3_bread"), "the notebook remembers the bread")
	var act := false
	for e in Notebook.remembered_acts():
		if (e as Dictionary).get("key") == "d3_bread":
			act = true
	check(act, "the bread is an act for the final sky")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
