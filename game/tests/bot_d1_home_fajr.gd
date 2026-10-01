extends Bot
## Plays Day 1 Scenes 0 and 1: flies the kite over the roof at fajr, hears Mama call up the
## stairwell, reels in, drops through the hatch and walks the stairs down, hears the house
## wake in barks, looks at Karim and the wedding list, brushes the scarf off its hook and
## leaves through the street door.


func run() -> void:
	name_tag = "d1_home_fajr"
	var beat = target("HomeFajr")
	var layla: Player = beat.get_node("Player")
	var kite: Kite = beat.get_node("Kite")
	var result := {}
	beat.finished.connect(func(r: Dictionary): result.merge(r, true))
	if not flow:
		beat.begin({})
	await frames(10)
	check(kite.flying and beat.kite_in_play, "the kite is already up when the scene opens")
	var loops: Array = Sound.running_loops()
	check("wind_loop" in loops and "sea_loop" in loops, "the wind and the sea run faint under the roof (%s)" % [loops])
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "Day 1: no hum and no rumble")
	check(String(Look.current.get("phase", "")) == "dusk", "the dawn is the pink dusk palette (%s)" % Look.current.get("phase"))
	check(beat.hint.text == Say.text("d1.s0.hint.kite"), "the only prompt is the kite control")
	check(layla.global_position.y < 530.0, "Layla stands on the roof (%s)" % layla.global_position)
	check(beat.get_node("Mama") is Npc and beat.get_node("Karim") is Npc and beat.get_node("BabaHome") is Npc, "Mama, Karim and Baba are in the house")

	# Steering moves the kite, not her.
	var x0 := layla.global_position.x
	var kx := kite.global_position.x
	await hold("move_right", 30)
	check(absf(layla.global_position.x - x0) < 1.0, "she stands still while the kite flies")
	check(kite.global_position.x > kx + 20.0, "the kite steers right (%.0f px)" % (kite.global_position.x - kx))
	check(await until(func(): return "d1.s0.mama.02" in beat.said, 400), "Mama calls up the stairwell and Layla answers (%s)" % [beat.said])
	check(kite.flying, "the kite has not fallen in the meantime")

	# Reel in: the kite comes down into her arms and leaves play.
	await tap("kite")
	check(await until(func(): return not beat.kite_in_play, 30), "reeling in ends the kite play")
	check(not kite.flying and not kite.visible and layla.kite == null, "the kite goes with her, out of play")
	check(beat.hint.text == Say.text("d1.s1.hint.scarf"), "the hint turns to the scarf by the door")

	# Down through the hatch and the two flights, on foot.
	await move_until("move_left", func(): return layla.global_position.x < 962.0, 120)
	await hold("move_down", 12)
	check(await until(func(): return layla.global_position.y > 560.0, 60), "down at the hatch drops her onto the upper flight (%s)" % layla.global_position)
	check(await until(func(): return beat.inside and String(Look.current.get("phase", "")) == "morning", 60), "the dawn turns to morning as she comes inside")
	var on_first := await move_until("move_right", func(): return layla.global_position.y > 695.0 and layla.global_position.x > 1090.0, 240)
	check(on_first, "she walks down the upper flight to the first floor (%s)" % layla.global_position)
	check(await until(func(): return "d1.s1.mama.01" in beat.said, 60), "Mama greets her from below as she reaches the first floor")
	await move_until("move_right", func(): return layla.global_position.x > 1240.0, 120)
	await hold("move_down", 12)
	check(await until(func(): return layla.global_position.y > 740.0, 60), "down over the stairwell drops her onto the lower flight (%s)" % layla.global_position)
	var on_ground := await move_until("move_left", func(): return layla.global_position.y > 895.0 and layla.global_position.x < 1092.0, 240)
	check(on_ground, "she walks down the lower flight to the ground floor (%s)" % layla.global_position)
	check(beat.drops == 2, "two drops, one per hatch (%d)" % beat.drops)
	check(await until(func(): return "d1.s1.teta.01" in beat.said, 60), "Teta speaks up for her at the foot of the stairs")

	# Look-ats: Karim asleep, the list on the fridge.
	await move_until("move_right", func(): return layla.global_position.x > 1205.0, 120)
	# A press while a bark shows advances the bark; wait for the box to clear.
	await until(func(): return not Say.busy, 240)
	await frames(3)
	await tap("interact")
	check(await until(func(): return beat.last_look == "d1.s1.look.karim", 30), "interact by Karim shows his half-English thought")
	await move_until("move_left", func(): return layla.global_position.x < 845.0, 200)
	await until(func(): return not Say.busy, 120)
	await tap("interact")
	check(await until(func(): return beat.last_look == "d1.s1.look.list", 30), "interact by the fridge shows the wedding list thought")

	# Past Baba and the cat to the scarf and the door.
	var rustles := int(Sound.play_count.get("cloth_rustle", 0))
	await move_until("move_left", func(): return layla.global_position.x < 700.0, 120)
	check(await until(func(): return "d1.s1.baba.01" in beat.said, 60), "Baba asks if it flew")
	await move_until("move_left", func(): return beat.scarf_taken, 60)
	check(beat.scarf_taken and int(Sound.play_count.get("cloth_rustle", 0)) == rustles + 1, "the scarf comes off its hook with a rustle as she passes")
	await move_until("move_left", func(): return result.has("d1_scarf"), 90)
	check(bool(result.get("d1_scarf", false)), "out of the door: the beat finishes with the scarf")
	check(int(Sound.play_count.get("door_wood", 0)) == 1, "the street door sounds once on the way out")
	check(int(Sound.play_count.get("strike_bang", 0)) == 0, "nothing threatening happened on Day 1")
	if not flow:
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


## Holds `action` until `pred` is true or `max_frames` pass; returns whether it became true.
func move_until(action: String, pred: Callable, max_frames: int) -> bool:
	Input.action_press(action)
	var ok := await until(pred, max_frames)
	Input.action_release(action)
	return ok
