extends Bot
## Plays the beach beat to its end: meets Sami, flies the kite onto the stall roof, snags
## the string, reels it down, carries it to Sami, and checks the notebook remembers it.


func run() -> void:
	name_tag = "beach beat"
	var beach = target("Beach")
	var player: Player = beach.get_node("Player")
	var kite: Kite = beach.get_node("Kite")
	var sami: Npc = beach.get_node("Sami")
	var spool: Carryable = beach.get_node("StringSpool")
	var result := {}
	beach.finished.connect(func(r: Dictionary): result.merge(r, true))
	if not flow:
		beach.begin({})
	var loops: Array = Sound.running_loops()
	check("sea_loop" in loops and "wind_loop" in loops, "the sea and the wind run under the beach (%s)" % [loops])
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "Day 1: no hum and no rumble")

	teleport(player, Vector2(3240.0, 900.0))
	check(await until(func(): return beach.asked, 90), "Sami asks for help when Layla comes near")
	await frames(40)

	teleport(player, Vector2(3450.0, 900.0))
	await frames(5)
	await tap("kite")
	check(await until(func(): return kite.flying, 30), "kite launches by the stall")

	# Steer toward the string: left and right move the kite, shortening the string lowers it.
	var target := spool.global_position + Vector2(0.0, -11.0)
	var frames_used := 0
	for i in 900:
		if kite.hooked != null:
			break
		frames_used = i
		Input.action_release("move_left")
		Input.action_release("move_right")
		if kite.global_position.x < target.x - 15.0:
			Input.action_press("move_right")
		elif kite.global_position.x > target.x + 15.0:
			Input.action_press("move_left")
		Input.action_release("move_up")
		Input.action_release("move_down")
		if kite.global_position.y < target.y - 70.0:
			Input.action_press("move_up")
		elif kite.global_position.y > target.y + 20.0:
			Input.action_press("move_down")
		await get_tree().physics_frame
	release_all()
	check(kite.hooked == spool, "kite snags the string on the roof (%d frames)" % frames_used)
	check(spool.held and spool.get_parent() == kite, "the string hangs from the kite")
	check(int(Sound.play_count.get("kite_flap", 0)) >= 1, "the bag crackles while the kite flies (%d)" % int(Sound.play_count.get("kite_flap", 0)))

	await frames(5)
	var flaps := int(Sound.play_count.get("kite_flap", 0))
	await tap("kite")
	await frames(5)
	check(not kite.flying and not spool.held, "reeling in brings the string down")
	await frames(110)
	check(int(Sound.play_count.get("kite_flap", 0)) == flaps, "the crackle stops once the kite is reeled in")
	check(spool.global_position.distance_to(player.global_position) < 120.0, "the string lands within reach (%.0f px)" % spool.global_position.distance_to(player.global_position))

	# Grab from the far side, so Layla is not yet within Sami's reach when she has it.
	teleport(player, spool.global_position + Vector2(24.0, 0.0))
	await frames(5)
	var grabs := int(Sound.play_count.get("grab", 0))
	await tap("grab")
	await frames(5)
	check(player.carried == spool, "Layla picks the string up")
	check(int(Sound.play_count.get("grab", 0)) == grabs + 1, "hands closing on the spool are heard once")

	teleport(player, sami.global_position + Vector2(-60.0, 0.0))
	check(await until(func(): return beach.delivered, 90), "Sami gets his string")
	check(await until(func(): return result.get("kite_fetched", false), 300), "the beat finishes with kite_fetched")
	check(Notebook.has("beach_fetched_string"), "the notebook remembers the act")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
