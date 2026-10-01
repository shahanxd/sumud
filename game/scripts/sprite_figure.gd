extends Figure
class_name SpriteFigure
## A Figure whose body is drawn from generated or filmed frames instead of bones.
##
## Owners (Player, Npc) keep setting pose, phase, stride, load, arm_up, airborne and squash as
## they do for Figure; this class picks an animation from `assets/characters/<character>/frames.tres`
## (built by tools/build_frames.gd) and moves the hand node to the per-frame hand point in
## hands.json. When no frames exist for the character it behaves exactly like Figure, so a scene
## can switch to this script before any frames are made.
##
## Walk and run are driven by `phase` (the owner's foot cycle), not by the clock, so the feet stay
## planted at any speed; every other animation plays at its own fps.

## Folder name under res://assets/characters/. Empty means "bones only".
@export var character := ""
## The figure's height in frame pixels, as a fraction of the frame height (frames are cropped to
## the animation's box, so a jump's box is taller than the standing figure).
@export var frame_height_ratio := 1.0

var _sprite: AnimatedSprite2D
var _hands: Dictionary = {}
var _meta: Dictionary = {}
var _frame_size: Dictionary = {}
var _current := ""
var _base := "idle"


func _ready() -> void:
	super._ready()
	_load_frames()


## Switch to another character's frames (or to none). Owners call it when their own export is
## applied after this node is ready.
func set_character(name: String) -> void:
	character = name
	if _sprite != null:
		_sprite.queue_free()
		_sprite = null
	_hands = {}
	_meta = {}
	_frame_size = {}
	_current = ""
	_load_frames()


func _load_frames() -> void:
	if character == "":
		return
	var path := "res://assets/characters/%s/frames.tres" % character
	if not ResourceLoader.exists(path):
		return
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null:
		return
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.centered = false
	_sprite.name = "Sprite"
	add_child(_sprite)
	_hands = _read_json("res://assets/characters/%s/hands.json" % character)
	_meta = _read_json("res://assets/characters/%s/meta.json" % character)
	for anim in frames.get_animation_names():
		if frames.get_frame_count(anim) > 0:
			var tex: Texture2D = frames.get_frame_texture(anim, 0)
			if tex != null:
				_frame_size[anim] = tex.get_size()


func has_frames() -> bool:
	return _sprite != null


func _process(delta: float) -> void:
	if _sprite == null:
		super._process(delta)
		return
	var anim := _pick_animation()
	if anim == "":
		_sprite.visible = false
		super._process(delta)
		return
	_sprite.visible = true
	var count: int = _sprite.sprite_frames.get_frame_count(anim)
	var cyclic := _base == "walk" or _base == "run" or _base == "crawl"
	if anim != _current:
		_current = anim
		_fit(anim)
		if cyclic:
			_sprite.stop()
			_sprite.animation = anim
		else:
			_sprite.play(anim)
	if cyclic and count > 0:
		var cycle := fposmod(phase, TAU) / TAU
		_sprite.frame = int(floor(cycle * float(count))) % count
	elif _base == "jump" and anim.begins_with("jump") and count >= 6:
		# Frames: crouch, take-off, rise, apex, fall, land. Pick by vertical speed.
		_sprite.stop()
		var idx := 4
		if vertical < -0.7:
			idx = 1
		elif vertical < -0.25:
			idx = 2
		elif vertical < 0.25:
			idx = 3
		_sprite.frame = idx
	elif _base == "land" and anim.begins_with("jump"):
		_sprite.stop()
		_sprite.frame = count - 1
	elif _base == "idle" and not anim.begins_with("idle"):
		# Standing with only a cycle to show: hold its first frame.
		_sprite.stop()
		_sprite.frame = 0
	_place_hand(anim)
	# No bones to draw; keep the redraw off.


func _draw() -> void:
	if _sprite == null:
		super._draw()


## Scale the frame so the figure stands height() tall with its feet at the origin.
func _fit(anim: String) -> void:
	var size: Vector2 = _frame_size.get(anim, Vector2(1.0, 1.0))
	var ratio := 1.0
	var m: Variant = _meta.get(anim)
	if m is Dictionary:
		ratio = float((m as Dictionary).get("stand_ratio", 1.0))
	var s := height() * ratio / maxf(size.y * frame_height_ratio, 1.0)
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(-size.x * 0.5 * s, -size.y * s)


func _place_hand(anim: String) -> void:
	if _hand == null:
		return
	var list: Variant = _hands.get(anim)
	if list is Array:
		var arr: Array = list as Array
		if arr.size() > 0:
			var idx: int = clampi(_sprite.frame, 0, arr.size() - 1)
			var pt: Variant = arr[idx]
			if pt is Array and (pt as Array).size() >= 2:
				var px := float((pt as Array)[0])
				var py := float((pt as Array)[1])
				_hand.position = _sprite.position + Vector2(px, py) * _sprite.scale
				return
	# No hand data: a sensible default at hip height, leading side.
	_hand.position = Vector2(height() * 0.18, -height() * 0.45)


## The first animation that exists from the most specific name down.
func _pick_animation() -> String:
	var base := "idle"
	match pose:
		Pose.SIT:
			base = "sit"
		Pose.CRAWL:
			base = "crawl"
		Pose.WALK:
			base = "run" if stride > 0.6 else "walk"
		_:
			base = "idle"
	if airborne and pose != Pose.SIT and pose != Pose.CRAWL:
		base = "jump"
	elif squash > 0.08 and base == "idle":
		base = "land"
	_base = base
	var candidates: Array[String] = []
	if arm_up:
		candidates.append(base + "_kite")
	if load >= 2:
		candidates.append(base + "_twohand")
	if load >= 1:
		candidates.append(base + "_heavy")
	if load >= 0:
		candidates.append(base + "_carry")
	candidates.append(base)
	if base == "jump" or base == "land":
		candidates.append("jump")
		candidates.append("run")
		candidates.append("walk")
	if base == "run":
		candidates.append("walk")
	if base == "walk":
		candidates.append("run")
	for g in ["idle", "walk", "run"]:
		candidates.append(g)
	for c in candidates:
		if _sprite.sprite_frames.has_animation(c) and _sprite.sprite_frames.get_frame_count(c) > 0:
			return c
	return ""


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}
