extends Node
## Plays the chapter card, screenshots it mid-stitch, and checks the finished signal fires.
## Windowed:  Godot.exe --path game res://tests/shot_card.tscn -- --out=<png>
## Headless:  works too (no screenshot content, but the signal check still runs).

var _out := ""
var _done := false

@onready var card: ChapterCard = $Layer/ChapterCard


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	card.finished.connect(func() -> void: _done = true)
	card.play("DAY 1", "The Kite Festival")
	await get_tree().create_timer(1.6).timeout
	if _out != "":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		print("shot: saved ", _out, " err=", img.save_png(_out))
	await get_tree().create_timer(4.0).timeout
	print("card finished signal: ", _done)
	get_tree().quit(0 if _done else 1)
