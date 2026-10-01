extends Bot
## Plays the street beat: jumps the pit empty-handed, fails to with the jerrycan, walks
## back out, lays Abu Ahmad's plank as a bridge, carries the water over and home.


func run() -> void:
	name_tag = "street"
	var street = target("Street")
	var player: Player = street.get_node("Player")
	var jerrycan: Carryable = street.get_node("Jerrycan")
	var plank: Plank = street.get_node("Plank")
	var plank_item: Carryable = plank.get_node("Item")
	var result := {}
	street.finished.connect(func(r: Dictionary): result.merge(r, true))
	if not flow:
		street.begin({})
	await frames(45)
	check(Sound.running_loops() == ["wind_loop"], "only a faint wind runs in the street (%s)" % [Sound.running_loops()])

	# Empty-handed, the pit is a jump.
	teleport(player, Vector2(1850.0, 900.0))
	await frames(5)
	Input.action_press("move_right")
	await until(func(): return player.global_position.x > 1950.0, 120)
	# Held through the rise for the full jump; a tap would only hop.
	Input.action_press("jump")
	await frames(42)
	Input.action_release("jump")
	await frames(61)
	Input.action_release("move_right")
	check(player.global_position.x > 2320.0 and player.global_position.y < 905.0, "jumps the pit empty-handed (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])

	# With twenty litres, the jump is gone.
	teleport(player, Vector2(600.0, 900.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(player.carried == jerrycan, "picks up the jerrycan at the truck")
	check(not player.can_jump(), "the jerrycan removes the jump")
	Input.action_press("move_right")
	var in_pit := await until(func(): return player.global_position.y > 950.0, 900)
	Input.action_release("move_right")
	check(in_pit, "with the jerrycan she slides into the pit instead of jumping")
	check(await until(func(): return street.hinted, 30), "the beat says the rule once, in Layla's voice")

	# The pit is never a trap: walk back up the slope.
	Input.action_press("move_left")
	var out := await until(func(): return player.global_position.x < 1950.0 and player.global_position.y < 905.0, 600)
	Input.action_release("move_left")
	check(out, "she can always walk back out (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])
	await frames(3)
	var drops := int(Sound.play_count.get("drop_heavy", 0))
	await tap("grab")
	await frames(3)
	check(player.carried == null, "sets the water down")
	check(int(Sound.play_count.get("drop_heavy", 0)) == drops + 1, "twenty litres thud when set down")
	var water_x := jerrycan.global_position.x

	# Fetch the plank, two-handed.
	teleport(player, plank_item.global_position + Vector2(-30.0, 0.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(player.carried == plank_item, "picks up Abu Ahmad's plank")
	check(not player.can_jump() and not player.can_crawl(), "two-handed: no jump and no crawl")
	Input.action_press("move_right")
	var at_edge := await until(func(): return player.global_position.x >= 1925.0, 600)
	Input.action_release("move_right")
	check(at_edge, "carries the plank to the edge (x=%.0f)" % player.global_position.x)
	await frames(3)
	await tap("grab")
	await frames(3)
	check(plank.is_bridge, "the plank snaps across the pit")
	check(Notebook.has("street_plank_bridge"), "the notebook notes the plank")

	# Back for the water and over the bridge.
	teleport(player, Vector2(water_x - 30.0, 900.0))
	await frames(5)
	await tap("grab")
	await frames(3)
	check(player.carried == jerrycan, "picks the water up again")
	Input.action_press("move_right")
	var across := await until(func(): return player.global_position.x > 2400.0, 900)
	check(across and player.global_position.y < 905.0, "carries the water over the bridge (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])
	var home := await until(func(): return street.delivered, 900)
	Input.action_release("move_right")
	check(home, "reaches the home door with the water")
	check(await until(func(): return result.get("water", false), 300), "the beat finishes with water")
	check(result.get("used_plank", false), "the result records the plank")
	check(Notebook.has("street_water_home"), "the notebook remembers the water")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
