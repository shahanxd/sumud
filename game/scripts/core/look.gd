extends Node
## Autoload "Look". The per-day colour budget from game/data/palette.json. Beats put their
## sky ColorRect in group "sky", their sea Polygon2D in group "sea" and one CanvasModulate
## in group "ambient"; set_phase() tweens all of them. Everything is driven by one JSON
## file the founder can tune.

const PALETTE_PATH := "res://data/palette.json"

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
	for k in ["sky_top", "sky_horizon", "sea", "haze", "ambient"]:
		var c := Color(String(base.get(k, "#ffffff")))
		if k != "ambient":
			c = _desaturate(c, sat)
		out[k] = c
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
		else:
			mix[k] = b[k]
	current = mix
	_apply(mix)


## Applies the palette to the scene tree now. Also called by a beat after it builds.
func _apply(p: Dictionary) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("sky"):
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("top_color", p["sky_top"])
			mat.set_shader_parameter("horizon_color", p["sky_horizon"])
	for node in tree.get_nodes_in_group("sea"):
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("deep_color", p["sea"])
			mat.set_shader_parameter("glint_color", p["sky_horizon"])
	for node in tree.get_nodes_in_group("ambient"):
		if node is CanvasModulate:
			(node as CanvasModulate).color = p["ambient"]
	for node in tree.get_nodes_in_group("skyline"):
		if node.has_method("tint"):
			node.tint(p["haze"])


## Dress a freshly built beat with the current palette.
func dress() -> void:
	_apply(current)
