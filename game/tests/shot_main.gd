extends Node
## Runs the real main scene (main.tscn, which starts Day 1 itself), holds "move right" for
## a while, and saves the viewport at given frames, so what the player sees can be reviewed
## on a box with no screen. Arguments after "--":  --out=/dir  --shots=60,240,600
## --walk=120,600 (frames between which move_right is held)

var _frames := 0
var _out := "user://"
var _shots: Array[int] = [60, 240, 600]
var _walk := Vector2i(120, 600)


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--shots="):
			_shots.clear()
			for s in arg.substr(8).split(","):
				_shots.append(int(s))
		elif arg.begins_with("--walk="):
			var w := arg.substr(7).split(",")
			_walk = Vector2i(int(w[0]), int(w[1]))
	var packed: PackedScene = load("res://scenes/main.tscn")
	add_child(packed.instantiate())


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == _walk.x:
		Input.action_press("move_right")
	if _frames == _walk.y:
		Input.action_release("move_right")
	if _frames in _shots:
		_save("%s/main_%04d.png" % [_out, _frames])
	if _frames > _shots.max() + 2:
		get_tree().quit(0)


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	var cam := get_viewport().get_camera_2d()
	print("shot: ", path, " err=", err, " size=", img.get_size(), " camera=", cam.get_path() if cam else "NONE",
		" cam_pos=", cam.global_position if cam else Vector2.ZERO, " zoom=", cam.zoom if cam else Vector2.ZERO)
