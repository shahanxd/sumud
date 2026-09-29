extends Node2D
## A pose sheet for visual review: every build and pose of the Figure rig on plain paper.
## Windowed (xvfb-run on a headless box). Argument after "--":  --out=/path/sheet.png

var _frames := 0
var _out := "user://figures.png"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	var paper := ColorRect.new()
	paper.color = Color(0.93, 0.89, 0.82)
	paper.size = Vector2(1920, 1080)
	paper.z_index = -10
	add_child(paper)
	var row1: Array = [
		["stand", {}],
		["walk", {"pose": Figure.Pose.WALK, "stride": 0.45, "phase": 0.9}],
		["run", {"pose": Figure.Pose.WALK, "stride": 1.0, "phase": 2.2}],
		["run 2", {"pose": Figure.Pose.WALK, "stride": 1.0, "phase": 4.0}],
		["crawl", {"pose": Figure.Pose.CRAWL, "stride": 0.5, "phase": 1.0}],
		["sit", {"pose": Figure.Pose.SIT}],
		["light", {"load": 0, "pose": Figure.Pose.WALK, "stride": 0.4, "phase": 1.2}],
		["heavy", {"load": 1}],
		["two hands", {"load": 2}],
		["kite", {"arm_up": true}],
		["jump", {"airborne": true}],
	]
	var row2: Array = [
		["Baba", {"build": 1, "headscarf": false, "dress": 0}],
		["Baba walk", {"build": 1, "headscarf": false, "dress": 0, "pose": Figure.Pose.WALK, "stride": 0.5, "phase": 1.0}],
		["Baba beam", {"build": 1, "headscarf": false, "dress": 0, "load": 2, "pose": Figure.Pose.WALK, "stride": 0.3, "phase": 2.0}],
		["Teta", {"build": 2, "headscarf": true, "dress": 2, "cane": true}],
		["Teta sit", {"build": 2, "headscarf": true, "dress": 2, "pose": Figure.Pose.SIT}],
		["Sami", {"build": 0, "headscarf": false, "dress": 0}],
		["Sami run", {"build": 0, "headscarf": false, "dress": 0, "pose": Figure.Pose.WALK, "stride": 1.0, "phase": 1.0}],
		["Abu Ahmad", {"build": 1, "headscarf": false, "dress": 0, "pose": Figure.Pose.WALK, "stride": 0.3, "phase": 3.5}],
		["Mama", {"build": 1, "headscarf": true, "dress": 2, "pose": Figure.Pose.WALK, "stride": 0.5, "phase": 0.5}],
		["Layla faces left", {"flip": true, "pose": Figure.Pose.WALK, "stride": 0.5, "phase": 1.5}],
	]
	_row(row1, 400.0)
	_row(row2, 900.0)


func _row(specs: Array, y: float) -> void:
	var x := 120.0
	for spec in specs:
		var label: String = spec[0]
		var props: Dictionary = spec[1]
		var holder := Node2D.new()
		holder.position = Vector2(x, y)
		add_child(holder)
		var f := Figure.new()
		f.build = 0
		f.headscarf = true
		f.dress = 1
		for k in props:
			if k == "flip":
				holder.scale.x = -1.0
			else:
				f.set(k, props[k])
		holder.add_child(f)
		var ground := Line2D.new()
		ground.width = 2.0
		ground.default_color = Color(0.6, 0.55, 0.5)
		ground.points = PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)])
		holder.add_child(ground)
		var text := Label.new()
		text.text = label
		text.position = Vector2(-60, 10)
		text.size = Vector2(120, 30)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_color", Color(0.35, 0.3, 0.28))
		text.add_theme_font_size_override("font_size", 18)
		holder.add_child(text)
		x += 165.0


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 70:
		_save()
	if _frames > 74:
		get_tree().quit(0)


func _save() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_out)
	print("shot: saved ", _out, " err=", err, " size=", img.get_size())
