extends Node
## Renders any scene for visual review and saves a screenshot. Windowed (use xvfb-run on a
## headless box). Arguments after "--":
##   --scene=res://scenes/home.tscn  --out=/path/shot.png  --frames=90
##   --phase=dusk  (a palette phase to apply)  --pos=x,y  (a camera position, optional)
##   --shots=a.png@60,b.png@200  (several shots at frame counts, optional)

var _frames := 0
var _scene_path := "res://scenes/beach.tscn"
var _out := "user://shot.png"
var _at := 90
var _phase := ""
var _pos := ""
var _shots: Array = []
var _scene: Node = null


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene_path = arg.substr(8)
		elif arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--frames="):
			_at = int(arg.substr(9))
		elif arg.begins_with("--phase="):
			_phase = arg.substr(8)
		elif arg.begins_with("--pos="):
			_pos = arg.substr(6)
		elif arg.begins_with("--shots="):
			for part in arg.substr(8).split(","):
				var bits := part.split("@")
				_shots.append([bits[0], int(bits[1]) if bits.size() > 1 else _at])
	var packed: PackedScene = load(_scene_path)
	_scene = packed.instantiate()
	add_child(_scene)
	if _scene is Beat:
		(_scene as Beat).begin({})
	if not _phase.is_empty():
		Look.set_phase(1, _phase, 0.0)
	if not _pos.is_empty():
		var cam := _scene.get_node_or_null("Camera") as Camera2D
		if cam:
			var xy := _pos.split(",")
			var marker := Node2D.new()
			marker.position = Vector2(float(xy[0]), float(xy[1]))
			_scene.add_child(marker)
			if cam.has_method("follow"):
				cam.follow(marker)
	if _shots.is_empty():
		_shots.append([_out, _at])


func _physics_process(_delta: float) -> void:
	_frames += 1
	for s in _shots:
		if _frames == int(s[1]):
			_save(String(s[0]))
	var last := 0
	for s in _shots:
		last = maxi(last, int(s[1]))
	if _frames > last + 2:
		get_tree().quit(0)


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("shot: saved ", path, " err=", err, " size=", img.get_size())
