extends Bot
## Plays Day 1's kite run: runs left from the steps with the kite ahead, jumps the pit by the
## bakery leftward, climbs the outside stairs on foot and jumps onto Hajja Amina's roof, frees
## the kite from the line by holding interact, hangs the sheet back, and answers Sami with the
## second choice. Nothing is teleported.

const EXPECTED_BARKS: Array[String] = [
	"d1.s6.sami.01", "d1.s6.layla.01", "d1.s6.abu_ahmad.01", "d1.s6.abu_fadi.01", "d1.s6.um_samir.01"]


func run() -> void:
	name_tag = "d1_kite_run"
	var beat: Node = target("KiteRun")
	var player: Player = beat.get_node("Player")
	var dressing: D1StreetDressing = beat.get_node("Dressing")
	var hint: Label = beat.get_node("HUD/Hint")
	var kite: Node2D = beat.kite
	var result := {}
	beat.finished.connect(func(r: Dictionary): result.merge(r, true))
	if not flow:
		beat.begin({})
	await frames(3)
	check(hint.text == Say.text("d1.s6.hint.run"), "the hint says to follow the kite")
	await frames(27)

	var loops: Array = Sound.running_loops()
	check(loops.has("wind_loop") and loops.has("sea_loop"), "the sea and the wind run at noon (%s)" % [loops])
	check(kite.position.x < player.global_position.x - 300.0 and kite.position.y >= 300.0 and kite.position.y <= 650.0, "the kite is ahead of her, left and up (dx=%.0f y=%.0f)" % [kite.position.x - player.global_position.x, kite.position.y])
	check(await until(func(): return beat.barks_fired.size() >= 1, 60) and beat.barks_fired[0] == "d1.s6.sami.01", "Sami cries out as it goes")

	# Run left. The kite keeps ahead and never races away.
	Input.action_press("move_left")
	check(await until(func(): return player.global_position.x < 3600.0, 400), "runs down the street leftward")
	var ahead := player.global_position.x - kite.position.x
	check(ahead > 350.0 and ahead < 900.0, "the kite keeps about a screen ahead (%.0f px)" % ahead)
	check(await until(func(): return player.global_position.x < 2380.0, 400), "reaches the pit from the right")
	Input.action_press("jump")
	await frames(42)
	Input.action_release("jump")
	var left_ground := false
	for _i in 120:
		if not player.is_on_floor() and player.global_position.x < 2320.0:
			left_ground = true
		if player.global_position.x < 1900.0:
			break
		await get_tree().physics_frame
	check(left_ground, "jumps the pit leftward")
	check(await until(func(): return player.global_position.x < 1900.0 and player.global_position.y < 905.0, 300), "is past the pit, on the road (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])

	# The far left: the kite catches on the line while she is at the stairs.
	check(await until(func(): return beat.kite_snagged, 600), "the kite snags on Hajja Amina's laundry line (x=%.0f)" % player.global_position.x)
	check(beat.barks_fired == EXPECTED_BARKS, "the doors bark in the script's order (%s)" % [beat.barks_fired])
	check(await until(func(): return player.global_position.y < 670.0 and player.global_position.x < -90.0, 300), "climbs the outside stairs on foot (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])
	Input.action_press("jump")
	await frames(30)
	Input.action_release("jump")
	check(await until(func(): return player.global_position.y < 600.0 and player.global_position.x < -150.0 and player.is_on_floor(), 150), "jumps from the landing onto the roof (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])
	check(await until(func(): return player.global_position.x < -300.0, 120), "stands under the kite")
	Input.action_release("move_left")
	check(await until(func(): return hint.text == Say.text("d1.s6.hint.free"), 30), "the hint says to free the kite")

	# Hold interact to free it; the sheet comes down.
	await hold("interact", 30)
	check(await until(func(): return beat.kite_freed, 30), "holding interact frees the kite")
	check(beat.sheet_item != null and not beat.sheet_item.held, "the sheet comes down onto the roof as a carryable")
	check(await until(func(): return dressing.hajja.visible and dressing.hajja.position.y < 600.0, 60), "Hajja Amina comes up through her hatch")

	# The optional act: hang the sheet back on the line.
	check(await until(func(): return hint.text == Say.text("d1.s6.hint.sheet"), 300), "after her lines the hint offers the sheet")
	# Walk to the sheet, pick it up, carry it under the line and press interact.
	var sheet: Carryable = beat.sheet_item
	var toward := "move_right" if sheet.global_position.x > player.global_position.x else "move_left"
	Input.action_press(toward)
	await until(func(): return absf(sheet.global_position.x - player.global_position.x) < 30.0, 90)
	Input.action_release(toward)
	await frames(6)
	await tap("grab")
	await frames(3)
	check(player.carried != null and player.carried.label == "sheet", "picks up the sheet")
	var line_x: float = D1StreetDressing.SNAG.x
	toward = "move_right" if line_x > player.global_position.x else "move_left"
	Input.action_press(toward)
	await until(func(): return absf(line_x - player.global_position.x) < 40.0, 90)
	Input.action_release(toward)
	await frames(6)
	for _i in 3:
		await tap("interact")
		await frames(4)
		if beat.laundry_done:
			break
	check(beat.laundry_done and dressing.sheet_mid.visible, "hangs the sheet back on the line")
	check(Notebook.has("d1_amina_sheet"), "the notebook keeps the act")

	# Sami arrives by the stairs; the first answer choice, taken the second way.
	Say.bot_choice = 1
	check(await until(func(): return beat.sami_on_roof, 400), "Sami arrives on the roof by the stairs (%.0f, %.0f)" % [dressing.sami.position.x, dressing.sami.position.y])
	check(await until(func(): return not result.is_empty(), 900), "the beat finishes after the adhan")
	check(Say.last_choice == "d1.s6.layla.05", "the second answer was said")
	check(String(result.get("d1_fix_answer", "")) == "better" and bool(result.get("d1_amina_laundry", false)), "the result carries the answer and the laundry (%s)" % [result])
	check(Notebook.has("d1_fix_answer") and Notebook.has("d1_kite_run"), "the notebook keeps the answer and the run")
	if not flow:
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()
