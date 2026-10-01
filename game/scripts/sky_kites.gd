extends Node2D
class_name SkyKites
## The festival sky: many small homemade kites hanging in the wind over the beach, each a
## generated sprite from assets/props/kites, swaying on the day's wind field with a thin string
## falling away below it. Decorative only: nothing collides, nothing is hooked.

const KITE_DIR := "res://assets/props/kites/"
const KITE_COUNT := 8

@export var count := 110
## World box the kites hang in: the visible sky sits between the frame top (about y 460 at the
## ground camera) and the horizon (y 702); near kites may dip below it.
@export var span := Rect2(-1200.0, 300.0, 8600.0, 420.0)
## Sprite scale range: small far kites, a few nearer ones.
@export var scale_min := 0.07
@export var scale_max := 0.26
@export var string_color := Color(0.25, 0.22, 0.2, 0.35)
@export var seed := 7

var _sprites: Array[Sprite2D] = []
var _homes: PackedVector2Array = PackedVector2Array()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _t := 0.0
var _wind: Node


func _ready() -> void:
	_wind = get_node_or_null("/root/Wind")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var textures: Array[Texture2D] = []
	for i in range(1, KITE_COUNT + 1):
		var path := KITE_DIR + "kite_%d.png" % i
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				textures.append(tex)
	if textures.is_empty():
		return
	for n in count:
		var s := Sprite2D.new()
		s.texture = textures[rng.randi_range(0, textures.size() - 1)]
		var sc := rng.randf_range(scale_min, scale_max)
		s.scale = Vector2(sc, sc)
		# Far kites sit higher and fade a little into the haze.
		var depth := inverse_lerp(scale_min, scale_max, sc)
		s.modulate = Color(1.0, 1.0, 1.0, lerpf(0.7, 1.0, depth))
		s.position = Vector2(
			span.position.x + rng.randf() * span.size.x,
			span.position.y + rng.randf() * span.size.y * (1.0 - depth * 0.5))
		add_child(s)
		_sprites.append(s)
		_homes.append(s.position)
		_phases.append(rng.randf() * TAU)


func _process(delta: float) -> void:
	_t += delta
	for i in _sprites.size():
		var s := _sprites[i]
		var home := _homes[i]
		var wind := Vector2(140.0, 0.0)
		if _wind:
			wind = _wind.call("sample", home)
		var ph := _phases[i]
		var sway := Vector2(sin(_t * 0.9 + ph) * 14.0, cos(_t * 1.3 + ph * 1.7) * 9.0)
		s.position = home + sway + wind * 0.08
		s.rotation = clampf(wind.x / 900.0, -0.35, 0.35) + sin(_t * 1.1 + ph) * 0.05
	queue_redraw()


func _draw() -> void:
	# A short run of string under each kite, fading out: the flyers are off screen or in the
	# crowd, so the line only needs to say "held", not reach a hand.
	for i in _sprites.size():
		var s := _sprites[i]
		var top := s.position + Vector2(0.0, s.texture.get_size().y * 0.5 * s.scale.y)
		var length := 110.0 + 900.0 * s.scale.x
		var foot := top + Vector2(-length * 0.35, length)
		var mid := top.lerp(foot, 0.5) + Vector2(-length * 0.08, 0.0)
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		for k in 9:
			var u := float(k) / 8.0
			pts.append(top.lerp(mid, u).lerp(mid.lerp(foot, u), u))
			colors.append(Color(string_color.r, string_color.g, string_color.b, string_color.a * (1.0 - u)))
		draw_polyline_colors(pts, colors, 1.0, true)
