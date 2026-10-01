extends Bot
## Plays the notebook page: the paper shows the day's entries, interact closes it, the end
## card stitches itself in, and the beat finishes.


func run() -> void:
	name_tag = "notebook"
	var page = target("NotebookPage")
	if not flow:
		Notebook.clear()
		Notebook.begin_day(1)
		Notebook.write("test_a", "The kite brought the string down.", "الطائرة نزّلت الخيط.", {"act": true})
		Notebook.write("test_b", "Teta asked what it means to stay.", "تيتا سألتني شو معناها نبقى.")
		page.begin({})
	var result := {}
	page.finished.connect(func(r: Dictionary): result.merge(r, true))
	check(await until(func(): return page.shown, 120), "the notebook page opens")
	var pages := int(Sound.play_count.get("paper_page", 0))
	check(pages >= 1 and Sound.last_played == "paper_page", "the page is heard opening")
	check(page.entry_count == Notebook.day_entries(Notebook.current_day).size() and page.entry_count >= 2, "every entry of the day is on the page (%d)" % page.entry_count)
	await frames(5)
	var stitches := stitch_count()
	await tap("interact")
	check(await until(func(): return page.closed, 60), "interact closes the notebook")
	check(int(Sound.play_count.get("paper_page", 0)) == pages + 1, "the page is heard closing")
	check(await until(func(): return result.get("notebook_shown", false), 400), "the end card plays and the beat finishes")
	check(stitch_count() > stitches, "the end card stitches audibly (%d stitches)" % (stitch_count() - stitches))
	if not flow:
		# Quit clean: a player still playing at exit is reported as leaked.
		Sound.stop_all_loops(0.0)
		await until(func(): return Sound.get_child_count() == 0, 600)
		await frames(30)
	done()


## How many stitch sounds have played so far, over the three variants.
func stitch_count() -> int:
	var n := 0
	for i in 3:
		n += int(Sound.play_count.get("stitch_%d" % (i + 1), 0))
	return n
