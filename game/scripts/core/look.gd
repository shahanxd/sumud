extends Node
## Autoload "Look". The per-day colour budget from game/data/palette.json. Beats put their
## sky ColorRect in group "sky", their sea Polygon2D in group "sea" and one CanvasModulate
## in group "ambient"; set_phase() tweens all of them, plus the sun, the haze, the stars and
## the print pass. Everything is driven by one JSON file the founder can tune.

const PALETTE_PATH := "res://data/palette.json"
const COLOR_KEYS := ["sky_top", "sky_horizon", "sea", "haze", "ambient", "sun_color", "tint", "ground"]
const FLOAT_KEYS := ["saturation", "sun_x", "sun_y", "sun_size", "sun_glow", "stars", "haze_alpha", "grain", "vignette"]

var current: Dictionary = {}
var _data: Dictionary = {}
var _tween: Tween


func _ready() -> void:
	var file := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
	current = palette(1, "morning")


## The resolved palette for a day and phase: the phase defaults, then the day's
## saturation applied to sky, sea and haze.
func palette(day: int, phase: String) -> Dictionary:
	var defaults: Dictionary = _data.get("default", {})
	var base: Dictionary = defaults.get(phase, defaults.get("morning", {})).duplicate()
	var days: Dictionary = _data.get("days", {})
	var day_over: Dictionary = days.get(str(day), {})
	var sat := float(day_over.get("saturation", 1.0)) * float(base.get("saturation", 1.0))
	var out := {}
	for k in COLOR_KEYS:
		var fallback := "#ffffff"
		var c := Color(String(base.get(k, fallback)))
		if k in ["sky_top", "sky_horizon", "sea", "haze", "ground"]:
			c = _desaturate(c, sat)
		out[k] = c
	for k in FLOAT_KEYS:
		var d := 1.0
		match k:
			"sun_x": d = 0.76
			"sun_y": d = 0.42
			"sun_size": d = 0.03
			"sun_glow": d = 0.3
			"stars": d = 0.0
			"haze_alpha": d = 0.5
			"grain": d = 0.05
			"vignette": d = 0.3
		out[k] = float(base.get(k, d))
	out["saturation"] = sat
	out["phase"] = phase
	out["day"] = day
	return out


func _desaturate(c: Color, sat: float) -> Color:
	var grey := c.get_luminance()
	return Color(lerpf(grey, c.r, sat), lerpf(grey, c.g, sat), lerpf(grey, c.b, sat), c.a)


## Moves every dressed node toward the palette over `seconds`.
func set_phase(day: int, phase: String, seconds: float = 2.0) -> void:
	var target := palette(day, phase)
	if _tween:
		_tween.kill()
	if seconds <= 0.0:
		current = target
		_apply(current)
		return
	var from := current.duplicate()
	_tween = create_tween()
	_tween.tween_method(func(t: float): _blend(from, target, t), 0.0, 1.0, seconds)


func _blend(a: Dictionary, b: Dictionary, t: float) -> void:
	var mix := {}
	for k in b:
		if b[k] is Color and a.get(k) is Color:
			mix[k] = (a[k] as Color).lerp(b[k], t)
		elif (b[k] is float or b[k] is int) and (a.get(k) is float or a.get(k) is int) and k != "day":
			mix[k] = lerpf(float(a[k]), float(b[k]), t)
		else:
			mix[k] = b[k]
	current = mix
	_apply(mix)


## Applies the palette to the scene tree now. Also called by a beat after it builds.
func _apply(p: Dictionary) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var haze: Color = p["haze"]
	var haze_a := Color(haze.r, haze.g, haze.b, float(p.get("haze_alpha", 0.5)))
	for node in tree.get_nodes_in_group("sky"):
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("top_color", p["sky_top"])
			mat.set_shader_parameter("horizon_color", p["sky_horizon"])
			mat.set_shader_parameter("sun_pos", Vector2(float(p.get("sun_x", 0.76)), float(p.get("sun_y", 0.42))))
			mat.set_shader_parameter("sun_color", p["sun_color"])
			mat.set_shader_parameter("sun_size", float(p.get("sun_size", 0.03)))
			mat.set_shader_parameter("sun_glow", float(p.get("sun_glow", 0.3)))
			mat.set_shader_parameter("haze_color", haze_a)
			mat.set_shader_parameter("stars", float(p.get("stars", 0.0)))
			mat.set_shader_parameter("saturation", 1.0)
	for node in tree.get_nodes_in_group("sea"):
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("deep_color", p["sea"])
			mat.set_shader_parameter("glint_color", p["sun_color"])
			mat.set_shader_parameter("haze_color", haze)
			mat.set_shader_parameter("sun_x", float(p.get("sun_x", 0.76)))
			mat.set_shader_parameter("glint_strength", 0.25 + 0.4 * float(p.get("sun_glow", 0.3)))
	for node in tree.get_nodes_in_group("ambient"):
		if node is CanvasModulate:
			(node as CanvasModulate).color = p["ambient"]
	# The ground is the brightest thing below the horizon by day and near-black by night;
	# figures and props stay dark, so the silhouette rule holds.
	for node in tree.get_nodes_in_group("ground"):
		if node is Polygon2D:
			(node as Polygon2D).color = p["ground"]
	for node in tree.get_nodes_in_group("skyline"):
		if node.has_method("tint"):
			node.tint(haze)
	var grade := get_node_or_null("/root/Grade")
	if grade != null and grade.has_method("apply"):
		grade.apply(p)


## Dress a freshly built beat with the current palette.
func dress() -> void:
	_apply(current)
