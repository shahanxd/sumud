extends Node2D
## Builds a silhouetted Gaza City skyline from code: several parallax depth layers of
## flat-roofed buildings, rooftop water tanks, washing poles and a minaret or two.
## Far layers are hazier (tinted toward the sky), near layers are dark and sharp.

@export var seed := 3
@export var layer_count := 4
@export var width := 6000.0
@export var horizon_y := 760.0
@export var sky_color := Color(0.95, 0.78, 0.48)
@export var near_color := Color(0.09, 0.08, 0.10)


var _layers: Array[Polygon2D] = []


func _ready() -> void:
	add_to_group("skyline")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in layer_count:
		var depth := float(i) / float(maxi(layer_count - 1, 1))  # 0 far, 1 near
		var layer := Parallax2D.new()
		var scale := lerpf(0.25, 0.85, depth)
		layer.scroll_scale = Vector2(scale, lerpf(0.6, 0.95, depth))
		layer.repeat_size = Vector2(width, 0.0)
		layer.z_index = -20 + i
		add_child(layer)
		var poly := Polygon2D.new()
		poly.polygon = _skyline(rng, depth)
		poly.set_meta("depth", depth)
		layer.add_child(poly)
		_layers.append(poly)
	tint(sky_color)


## Far layers take the haze colour of the day; near layers stay near-black.
func tint(haze: Color) -> void:
	sky_color = haze
	for poly in _layers:
		var depth: float = poly.get_meta("depth", 1.0)
		poly.color = near_color.lerp(haze, (1.0 - depth) * 0.72)


func _skyline(rng: RandomNumberGenerator, depth: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var base_y := horizon_y + lerpf(-40.0, 80.0, depth)
	var x := 0.0
	pts.append(Vector2(0.0, base_y + 600.0))
	pts.append(Vector2(0.0, base_y))
	while x < width:
		var w := rng.randf_range(70.0, 220.0) * lerpf(0.7, 1.3, depth)
		var h := rng.randf_range(60.0, 260.0) * lerpf(1.25, 0.9, depth)
		var top := base_y - h
		pts.append(Vector2(x, base_y))
		pts.append(Vector2(x, top))
		# Rooftop clutter: water tanks and a parapet step.
		var cx := x + w * 0.5
		if rng.randf() < 0.65:
			var tank_w := 22.0 * lerpf(0.8, 1.2, depth)
			var tx := x + rng.randf_range(10.0, maxf(w - tank_w - 10.0, 12.0))
			pts.append(Vector2(tx, top))
			pts.append(Vector2(tx, top - 18.0))
			pts.append(Vector2(tx + tank_w, top - 18.0))
			pts.append(Vector2(tx + tank_w, top))
		if rng.randf() < 0.07:
			# A minaret: thin shaft with a small balcony and a pointed cap.
			var mx := cx
			var mh := rng.randf_range(160.0, 260.0)
			pts.append(Vector2(mx - 7.0, top))
			pts.append(Vector2(mx - 7.0, top - mh * 0.65))
			pts.append(Vector2(mx - 12.0, top - mh * 0.65))
			pts.append(Vector2(mx - 12.0, top - mh * 0.7))
			pts.append(Vector2(mx - 6.0, top - mh * 0.7))
			pts.append(Vector2(mx - 6.0, top - mh * 0.9))
			pts.append(Vector2(mx, top - mh))
			pts.append(Vector2(mx + 6.0, top - mh * 0.9))
			pts.append(Vector2(mx + 6.0, top - mh * 0.7))
			pts.append(Vector2(mx + 12.0, top - mh * 0.7))
			pts.append(Vector2(mx + 12.0, top - mh * 0.65))
			pts.append(Vector2(mx + 7.0, top - mh * 0.65))
			pts.append(Vector2(mx + 7.0, top))
		pts.append(Vector2(x + w, top))
		pts.append(Vector2(x + w, base_y))
		x += w + rng.randf_range(0.0, 30.0)
	pts.append(Vector2(width, base_y))
	pts.append(Vector2(width, base_y + 600.0))
	return pts
