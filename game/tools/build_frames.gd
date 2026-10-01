extends SceneTree
## Builds one SpriteFrames resource per character from frame strips.
##
## Layout expected under res://assets/characters/<name>/:
##   <anim>/strip.png   a horizontal strip of equal frames (tools/roto.py strip)
##   <anim>/strip.json  {"frames": n, "frame_w": w, "frame_h": h, "fps": 12, "loop": true, "hand": [[x,y], ...]}
## Output: res://assets/characters/<name>/frames.tres, hands.json (per-animation hand points) and
## meta.json (per-animation stand_ratio: the figure's height in that frame relative to standing).
##
## Run from the repo root after an import:
##   bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --import --quit
##   bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tools/build_frames.gd [-- name]

const ROOT := "res://assets/characters/"


func _init() -> void:
	var only := ""
	var argv: PackedStringArray = OS.get_cmdline_user_args()
	if argv.size() > 0:
		only = argv[0]
	var dir := DirAccess.open(ROOT)
	if dir == null:
		push_error("build_frames: no " + ROOT)
		quit(2)
		return
	var built := 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with(".") and (only == "" or entry == only):
			if _build_character(ROOT + entry + "/"):
				built += 1
		entry = dir.get_next()
	dir.list_dir_end()
	print("build_frames: built %d character(s)" % built)
	quit(0 if built > 0 else 1)


func _build_character(path: String) -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var hands := {}
	var meta_out := {}
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	var any := false
	dir.list_dir_begin()
	var anim := dir.get_next()
	while anim != "":
		if dir.current_is_dir() and not anim.begins_with("."):
			var strip_path := path + anim + "/strip.png"
			var meta_path := path + anim + "/strip.json"
			if FileAccess.file_exists(strip_path) and FileAccess.file_exists(meta_path):
				var meta: Dictionary = _read_json(meta_path)
				if _add_animation(frames, anim, strip_path, meta):
					any = true
					if meta.has("hand"):
						hands[anim] = meta["hand"]
					meta_out[anim] = {"stand_ratio": float(meta.get("stand_ratio", 1.0))}
		anim = dir.get_next()
	dir.list_dir_end()
	if not any:
		return false
	var out := path + "frames.tres"
	var err := ResourceSaver.save(frames, out)
	if err != OK:
		push_error("build_frames: could not save " + out + " (" + str(err) + ")")
		return false
	var hf := FileAccess.open(path + "hands.json", FileAccess.WRITE)
	if hf != null:
		hf.store_string(JSON.stringify(hands, "  "))
		hf.close()
	var mf := FileAccess.open(path + "meta.json", FileAccess.WRITE)
	if mf != null:
		mf.store_string(JSON.stringify(meta_out, "  "))
		mf.close()
	print("build_frames: " + out + " with " + ", ".join(frames.get_animation_names()))
	return true


func _add_animation(frames: SpriteFrames, anim: String, strip_path: String, meta: Dictionary) -> bool:
	var tex: Texture2D = load(strip_path) as Texture2D
	if tex == null:
		push_error("build_frames: cannot load " + strip_path + " (run --import first)")
		return false
	var count: int = int(meta.get("frames", 0))
	var fw: int = int(meta.get("frame_w", 0))
	var fh: int = int(meta.get("frame_h", 0))
	if count <= 0 or fw <= 0 or fh <= 0:
		push_error("build_frames: bad strip.json for " + anim)
		return false
	var fps: float = float(meta.get("fps", 12))
	var loop: bool = bool(meta.get("loop", true))
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(anim, atlas)
	return true


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}
