extends Node2D
## Builds a silhouetted Gaza City skyline from code: several parallax depth layers of
## flat-roofed buildings, rooftop water tanks, a minaret or two and the odd tower.
## Far layers are hazier (tinted toward the sky), near layers are dark and sharp.
## Every building is its own polygon, so no shape can break a whole layer, and the layers
## only scroll sideways: their y stays in world space so they sit on the horizon.

@export var seed := 3
@export var layer_count := 4
@export var width := 6000.0
@export var horizon_y := 760.0
@export var sky_color := Color(0.95, 0.78, 0.48)
@export var near_color := Color(0.09, 0.08, 0.10)
## Scales building heights: under 1.0 for a coast seen from far away.
@export var height_scale := 1.0
## How far the layers' bases spread around the horizon (1.0 = the street; 0.2 = a far coast).
@export var base_spread := 1.0
## How far the silhouette fills downward below its base (0 for a coast standing on water).
@export var fill_below := 600.0
## Fraction of the width that holds buildings; the rest is open horizon (a coast that
## runs out into sea and haze). 1.0 is a solid city.
@export var coverage := 1.0

var _layers: Array = []   # [{depth, polys: [Polygon2D]}]


func _ready() -> void:
	add_to_group("skyline")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in layer_count:
		var depth := float(i) / float(maxi(layer_count - 1, 1))  # 0 far, 1 near
		var layer := Parallax2D.new()
		layer.scroll_scale = Vector2(lerpf(0.25, 0.85, depth), 1.0)
		layer.repeat_size = Vector2(width, 0.0)
		layer.z_index = -20 + i
		add_child(layer)
		var polys: Array = []
		for shape in _buildings(rng, depth):
			var poly := Polygon2D.new()
			poly.polygon = shape
			layer.add_child(poly)
			polys.append(poly)
		_layers.append({"depth": depth, "polys": polys})
	tint(sky_color)


## Far layers take the haze colour of the day; near layers stay near-black.
func tint(haze: Color) -> void:
	sky_color = haze
	for layer in _layers:
		var depth: float = layer["depth"]
		var col := near_color.lerp(haze, (1.0 - depth) * 0.72)
		for poly in layer["polys"]:
			(poly as Polygon2D).color = col


func _buildings(rng: RandomNumberGenerator, depth: float) -> Array:
	var shapes: Array = []
	var base_y := horizon_y + lerpf(-40.0, 80.0, depth) * base_spread
	# The ground the buildings stand on, filled downward.
	if fill_below > 0.0:
		shapes.append(PackedVector2Array([
			Vector2(0.0, base_y), Vector2(width, base_y),
			Vector2(width, base_y + fill_below), Vector2(0.0, base_y + fill_below)]))
	var x := 0.0
	var built_to := width * clampf(coverage, 0.0, 1.0)
	while x < built_to:
		var w := rng.randf_range(70.0, 220.0) * lerpf(0.7, 1.3, depth)
		var h := rng.randf_range(60.0, 260.0) * lerpf(1.25, 0.9, depth) * height_scale
		if rng.randf() < 0.12:
			h *= 1.8
		# A coast thins out toward its end: the last stretch drops to low, spaced buildings.
		if coverage < 1.0:
			var tail := clampf((x - built_to * 0.7) / (built_to * 0.3), 0.0, 1.0)
			h *= lerpf(1.0, 0.45, tail)
			if tail > 0.0 and rng.randf() < tail * 0.6:
				x += w
				continue
		var top := base_y - h
		var pts := PackedVector2Array()
		pts.append(Vector2(x, base_y + 2.0))
		pts.append(Vector2(x, top))
		# Rooftop clutter: a water tank kept inside the roof, and now and then a minaret.
		var tank_w := minf(22.0 * lerpf(0.8, 1.2, depth), w * 0.35)
		var has_tank := rng.randf() < 0.65
		var tx := x + rng.randf_range(6.0, maxf(w - tank_w - 6.0, 6.0))
		var has_minaret := rng.randf() < 0.07 and w > 60.0
		var mh := rng.randf_range(160.0, 260.0) * height_scale
		var cx := x + w * 0.5
		if has_tank and (not has_minaret or tx + tank_w < cx - 14.0):
			pts.append(Vector2(tx, top))
			pts.append(Vector2(tx, top - 18.0))
			pts.append(Vector2(tx + tank_w, top - 18.0))
			pts.append(Vector2(tx + tank_w, top))
		if has_minaret:
			pts.append(Vector2(cx - 7.0, top))
			pts.append(Vector2(cx - 7.0, top - mh * 0.65))
			pts.append(Vector2(cx - 12.0, top - mh * 0.65))
			pts.append(Vector2(cx - 12.0, top - mh * 0.7))
			pts.append(Vector2(cx - 6.0, top - mh * 0.7))
			pts.append(Vector2(cx - 6.0, top - mh * 0.9))
			pts.append(Vector2(cx, top - mh))
			pts.append(Vector2(cx + 6.0, top - mh * 0.9))
			pts.append(Vector2(cx + 6.0, top - mh * 0.7))
			pts.append(Vector2(cx + 12.0, top - mh * 0.7))
			pts.append(Vector2(cx + 12.0, top - mh * 0.65))
			pts.append(Vector2(cx + 7.0, top - mh * 0.65))
			pts.append(Vector2(cx + 7.0, top))
		pts.append(Vector2(x + w, top))
		pts.append(Vector2(x + w, base_y + 2.0))
		shapes.append(pts)
		x += w + rng.randf_range(0.0, 30.0)
	return shapes
