extends Node2D
## Placeholder main scene. Proves the project opens, renders and quits cleanly.
## Replaced by the Day 1 beach scene in the first prototype milestone.

const VERSION := "0.0.1-skeleton"


func _ready() -> void:
	print("SUMUD %s ready" % VERSION)
	if OS.get_cmdline_user_args().has("--smoke"):
		# Used by the headless smoke test: one frame, then exit 0.
		await get_tree().process_frame
		get_tree().quit(0)
