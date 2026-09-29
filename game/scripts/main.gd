extends Node2D
## The main scene. Starts the prototype day; the beats are children of this node.
## `--smoke` renders one frame and exits, for the headless smoke test.

const VERSION := "0.1.0-prototype"


func _ready() -> void:
	print("SUMUD %s ready" % VERSION)
	if OS.get_cmdline_user_args().has("--smoke"):
		await get_tree().process_frame
		get_tree().quit(0)
		return
	$TitleLayer/Title.visible = false
	Day.day_finished.connect(_on_day_finished)
	Day.start(1, self)


func _on_day_finished(_day: int, _ctx: Dictionary) -> void:
	$TitleLayer/Title.visible = true
	if Day.bot_mode:
		get_tree().quit(0)
