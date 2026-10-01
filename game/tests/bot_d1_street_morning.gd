extends Bot
## Plays Day 1's morning street: walks from the home door to the steps down to the sand,
## jumps the pit by the bakery on the way, hears the barks in the street's order without
## being stopped, and is followed by the twins once past them.

const EXPECTED_BARKS: Array[String] = [
	"d1.s2.hajja.01", "d1.s2.layla.02", "d1.s2.abu_ahmad.01", "d1.s2.abu_fadi.01",
	"d1.s2.um_samir.01", "d1.s2.twin.01", "d1.s2.twin.02", "d1.s2.layla.01"]


func run() -> void:
	name_tag = "d1_street_morning"
	var beat: Node = target("StreetMorning")
	var player: Player = beat.get_node("Player")
	var dressing: D1StreetDressing = beat.get_node("Dressing")
	var hint: Label = beat.get_node("HUD/Hint")
	var result := {}
	beat.finished.connect(func(r: Dictionary): result.merge(r, true))
	if not flow:
		beat.begin({})
	await frames(3)
	check(not hint.text.is_empty(), "the controls show for the first moment")
	await frames(17)

	var loops: Array = Sound.running_loops()
	check(loops.has("wind_loop") and loops.has("sea_loop") and loops.size() == 2, "a faint wind and the sea run in the morning street (%s)" % [loops])
	var truck: Node2D = beat.get_node("Truck")
	var jerrycan: Node2D = beat.get_node("Jerrycan")
	check(not truck.visible and not jerrycan.visible and not (beat.get_node("Plank") as Node2D).visible, "Day 4's truck, jerrycan and plank are not in the street yet")
	check(await until(func(): return hint.text.is_empty(), 90), "then the hint is empty")
	check(dressing.hajja.visible and dressing.hajja.position.y < 800.0, "Hajja Amina is up at her window")
	var sea_start: float = beat.sea.volume_db

	# Walk right through the morning: nothing stops her, not even where the truck stood.
	Input.action_press("move_right")
	check(await until(func(): return player.global_position.x > 700.0, 200), "walks past where the water truck will stand (x=%.0f)" % player.global_position.x)
	await tap("grab")
	await frames(3)
	check(player.carried == null, "there is no jerrycan to pick up")
	check(await until(func(): return beat.barks_fired.size() >= 2, 120), "Hajja hails her from the window and she answers (%s)" % [beat.barks_fired])
	check(player.velocity.x > 200.0, "the barks never stop her (vx=%.0f)" % player.velocity.x)

	# The pit by the bakery is a jump, empty-handed.
	check(await until(func(): return player.global_position.x > 1950.0, 400), "reaches the pit by the bakery")
	Input.action_press("jump")
	await frames(42)
	Input.action_release("jump")
	check(await until(func(): return player.global_position.x > 2320.0, 120) and player.global_position.y < 905.0, "jumps the pit (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])

	# Past the twins, the children follow her.
	check(await until(func(): return player.global_position.x > 3400.0, 400), "passes the twins")
	check(beat.twins_following, "the twins fall in behind her")
	await frames(60)
	var hassan: Npc = dressing.hassan
	var hussein: Npc = dressing.hussein
	var d1 := player.global_position.x - hassan.position.x
	var d2 := player.global_position.x - hussein.position.x
	check(d1 > 40.0 and d1 < 500.0 and d2 > 40.0 and d2 < 600.0 and d2 > d1, "both twins run behind her, Hussein behind Hassan (%.0f, %.0f)" % [d1, d2])
	check(hassan.figure.pose == Figure.Pose.WALK and hassan.figure.scale.x > 0.0, "the twins' figures walk, facing her way")

	# The steps down to the sand end the beat; the sea has grown the whole way. In the day
	# flow the runner frees the beat the moment it finishes, so what is checked afterwards
	# is read while it still stands.
	var barks: Array[String] = []
	var sea_db := sea_start
	var last_x := 0.0
	for _i in 700:
		if not result.is_empty():
			break
		if is_instance_valid(beat):
			barks = beat.barks_fired.duplicate()
			sea_db = beat.sea.volume_db
			last_x = player.global_position.x
		await get_tree().physics_frame
	Input.action_release("move_right")
	check(not result.is_empty(), "reaches the steps to the sand and the beat finishes (x=%.0f)" % last_x)
	check(bool(result.get("d1_twins", false)), "the result records the twins")
	check(barks == EXPECTED_BARKS, "the barks came in the street's order (%s)" % [barks])
	check(sea_db > sea_start + 15.0, "the sea rose as she neared the beach (%.0f -> %.0f dB)" % [sea_start, sea_db])
	if not flow:
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
