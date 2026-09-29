extends Node
## Renders the beach for a few seconds, launches the kite, saves a screenshot and quits.
## Run windowed (not headless):
##   Godot.exe --path game res://tests/shot_beach.tscn -- --out=C:/path/shot.png
## Used for visual review and for nightly image diffs.

var _frames := 0
var _out := "user://shot.png"

@onready var player: Player = $Beach/Player


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		player.global_position = Vector2(700.0, 900.0)
	if _frames == 20:
		Input.action_press("kite")
	if _frames == 22:
		Input.action_release("kite")
	if _frames == 60:
		Input.action_press("move_right")
	if _frames == 130:
		Input.action_release("move_right")
	if _frames == 200:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(_out)
		print("shot: saved ", _out, " err=", err, " size=", img.get_size())
		get_tree().quit(0 if err == OK else 1)
