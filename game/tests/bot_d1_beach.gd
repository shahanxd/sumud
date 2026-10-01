extends Bot
## Plays Day 1's beach beat (Scenes 3 to 5) to its end: meets Sami, really crawls under the
## boat for the bag, ties the tail, flies through the count, sits with Sami and ties the knot.
## Checks the marks and the notebook on the way.


func run() -> void:
	name_tag = "d1_beach"
	var beach = target("Beach1")
	var player: Player = beach.get_node("Player")
	var kite: Kite = beach.get_node("Kite")
	var sami_kite: Kite = beach.get_node("SamiKite")
	var bag: Carryable = beach.get_node("Bag")
	var camera: Camera2D = beach.get_node("Camera")
	var count_label: Label = beach.get_node("HUD/Count")
	var hint: Label = beach.get_node("HUD/Hint")
	var result := {}
	# In the day flow the runner frees the beat the moment it finishes, so what the end
	# looks like is read here, while it is still alive, never after.
	var snap := {}
	beach.finished.connect(func(r: Dictionary):
		result.merge(r, true)
		snap["promised"] = beach.promised
		snap["winner"] = beach.winner
		snap["standing"] = not player.sitting)
	if not flow:
		beach.begin({})
	await frames(5)
	var loops: Array = Sound.running_loops()
	check("sea_loop" in loops and "wind_loop" in loops, "the sea and the wind run under the festival (%s)" % [loops])
	check(not ("drone_hum_loop" in loops) and not ("rumble_loop" in loops), "Day 1: no hum and no rumble")
	var spool: Carryable = beach.get_node("StringSpool")
	check(not spool.visible and not spool.hookable and not beach.get_node("Jerrycan").visible, "Day 4's props are put away")
	check(get_tree().get_nodes_in_group("d1_flyer").size() >= 4, "the beach is dressed with kites in hands (%d)" % get_tree().get_nodes_in_group("d1_flyer").size())

	# Scene 3: Sami's lines when she reaches him.
	teleport(player, Vector2(3240.0, 900.0))
	check(await until(func(): return beach.met, 90), "Sami greets Layla when she comes near")
	check(await until(func(): return beach.stage == beach.Stage.BAG, 900), "the twins point under the boat after the talk")
	check(hint.text == Say.text("d1.s3.hint.crawl"), "the crawl hint shows")

	# The boat: under it on hands and knees, really. Standing, the hull stops her.
	teleport(player, Vector2(1240.0, 900.0))
	await frames(5)
	await hold("move_right", 60)
	check(player.global_position.x < 1420.0, "standing, the hull blocks her (x=%.0f)" % player.global_position.x)
	teleport(player, Vector2(1240.0, 900.0))
	await frames(5)
	Input.action_press("move_down")
	Input.action_press("move_right")
	var reached := await until(func(): return player.global_position.x > 1470.0, 240)
	check(reached and player.crawling, "she crawls under the boat (x=%.0f)" % player.global_position.x)
	check(beach.crawl_said, "Layla answers the twins about the crabs as she crawls in")
	await tap("grab")
	await frames(3)
	check(player.carried == bag, "she takes the bag from under the hull")
	var out := await until(func(): return player.global_position.x > 1700.0, 300)
	release_all()
	check(out, "she crawls out the far side with the bag (x=%.0f)" % player.global_position.x)
	await frames(20)
	check(not player.crawling, "she stands up again past the boat")
	check(hint.text == Say.text("d1.s3.hint.tie"), "the tie hint shows with the bag in hand")

	# Tie the tail: hold interact standing with the bag.
	await hold("interact", 40)
	check(await until(func(): return beach.tail_tied, 60), "holding E ties the bag on as a tail")
	check(player.carried == null and not is_instance_valid(bag), "the bag is used up by the tail")
	check(await until(func(): return Notebook.has("d1_tail"), 600), "the notebook keeps the tail")

	# Scene 4: the whistle, every kite up, the count.
	check(await until(func(): return beach.counting, 900), "the count starts after the volunteer's call")
	check(count_label.visible, "the counting label is up")
	var flyers_up := 0
	await frames(30)
	for node in get_tree().get_nodes_in_group("d1_flyer"):
		if (node as CrowdKite).flying:
			flyers_up += 1
	check(flyers_up >= 4, "the bystanders' kites go up on the whistle (%d)" % flyers_up)
	check(sami_kite.flying, "Sami's kite is up")
	await tap("kite")
	check(await until(func(): return kite.flying, 30), "Layla launches on the count")
	var tail_pts := 0
	Input.action_press("move_down")
	while beach.counting:
		if not kite.flying and player.is_on_floor():
			await tap("kite")
		var lt: Line2D = kite.get_node("LongTail")
		if lt.visible:
			tail_pts = maxi(tail_pts, lt.points.size())
		await frames(1)
	release_all()
	check(tail_pts >= 10, "the long tail trails the flying kite (%d points)" % tail_pts)
	check(beach.count_value == 30, "the count reaches thirty (%d)" % beach.count_value)
	check(camera.zoom.x < 1.0, "the camera pulled back during the count (zoom %.2f)" % camera.zoom.x)
	check(String(Look.current.get("phase", "")) == "noon", "the light moved to noon over the count (%s)" % Look.current.get("phase"))
	check(int(Sound.play_count.get("birds_leave", 0)) >= 1, "the roar stand-in sounds at thirty")
	check(await until(func(): return beach.winner != "", 60), "a winner is named")
	check(beach.winner in ["layla", "sami"], "the winner is layla or sami (%s)" % beach.winner)
	check(await until(func(): return beach.stage == beach.Stage.SIT, 900), "the lines after the count end with the sit hint")
	check(not kite.flying and not sami_kite.flying, "both kites rest on the sand")
	check(Notebook.has("d1_count") and Notebook.has("d1_contest"), "the notebook keeps the count and the contest")

	# Scene 5: sit, the promise, the knot.
	teleport(player, Vector2(3270.0, 900.0))
	await frames(8)
	await tap("interact")
	check(await until(func(): return beach.sat, 60), "E on the sit spot sits her down with Sami")
	check(player.sitting, "Layla sits")
	check("roof_breath_loop" in Sound.running_loops(), "the friend's voice comes in faint on the voices bus")
	check(await until(func(): return beach.knot_ready, 1200), "Sami holds out his string after the talk")
	check(hint.text == Say.text("d1.s5.hint.knot"), "the knot hint shows")
	await frames(10)
	var zoom_in := camera.zoom.x
	await hold("interact", 40)
	check(zoom_in > 1.35, "the camera leans in for the knot (zoom %.2f)" % zoom_in)
	check(await until(func(): return result.get("d1_promise", false), 900), "the knot is tied and the beat finishes with the promise")
	check(bool(snap.get("promised", false)), "the promise was made before the beat ended")
	check(String(result.get("d1_contest_winner", "")) == String(snap.get("winner", "?")) and bool(result.get("d1_tail_tied", false)), "the result carries the winner and the tail")
	check(Notebook.has("d1_promise"), "the notebook keeps the promise as an act")
	check(bool(snap.get("standing", false)), "Layla stands up at the end")
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
