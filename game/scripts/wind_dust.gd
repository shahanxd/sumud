extends Node2D
class_name WindDust
## Makes the wind visible: motes of sand and dust that ride the global Wind field around the
## camera, brighter when the light is warm, wrapping so the air is never empty. A few of
## them are larger and slower, like scraps of paper.

@export var count := 110
@export var color := Color(0.96, 0.9, 0.78, 0.35)
@export var area := Vector2(2400.0, 1100.0)

var _pos := PackedVector2Array()
var _weight := PackedFloat32Array()
var _size := PackedFloat32Array()
var _seeded := false


func _ready() -> void:
	z_index = 3
	_pos.resize(count)
	_weight.resize(count)
	_size.resize(count)
	for i in count:
		_weight[i] = randf_range(0.35, 1.0)
		_size[i] = 1.0 if randf() < 0.85 else randf_range(2.0, 3.5)


func _centre() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam else Vector2.ZERO


func _process(delta: float) -> void:
	var c := _centre()
	var half := area * 0.5
	if not _seeded:
		for i in count:
			_pos[i] = c + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
		_seeded = true
	for i in count:
		var p := _pos[i]
		var w := Wind.sample(p) * _weight[i]
		var jitter := Vector2(sin(p.y * 0.05 + p.x * 0.01) * 12.0, cos(p.x * 0.04) * 18.0) * _weight[i]
		p += (w + jitter) * delta
		# Wrap around the camera so the field stays full.
		if p.x > c.x + half.x: p.x -= area.x
		elif p.x < c.x - half.x: p.x += area.x
		if p.y > c.y + half.y: p.y -= area.y
		elif p.y < c.y - half.y: p.y += area.y
		_pos[i] = p
	queue_redraw()


func _draw() -> void:
	for i in count:
		var a := color.a * (0.4 + 0.6 * _weight[i])
		var col := Color(color.r, color.g, color.b, a)
		var s := _size[i]
		if s <= 1.0:
			draw_rect(Rect2(to_local(_pos[i]), Vector2(2.0, 1.4)), col)
		else:
			draw_rect(Rect2(to_local(_pos[i]), Vector2(s * 2.2, s * 0.8)), Color(col.r, col.g, col.b, a * 0.8))
