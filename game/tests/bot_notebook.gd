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
	check(page.entry_count == Notebook.day_entries(1).size() and page.entry_count >= 2, "every entry of the day is on the page (%d)" % page.entry_count)
	await frames(5)
	await tap("interact")
	check(await until(func(): return page.closed, 60), "interact closes the notebook")
	check(await until(func(): return result.get("notebook_shown", false), 400), "the end card plays and the beat finishes")
	done()
