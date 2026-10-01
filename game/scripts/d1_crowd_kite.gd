extends Node2D
class_name CrowdKite
## A festival kite in a bystander's hand: one of the generated kite sprites, held low until
## launch() is called, then rising on a thin string to hang in the day's wind beside the
## sky kites. Decorative only: nothing collides, nothing is hooked, nothing wins.

const KITE_DIR := "res://assets/props/kites/"

## Which of assets/props/kites/kite_N.png this one is.
@export_range(1, 8) var texture_index := 1
@export var sail_scale := 0.13
## Where it hangs once up, relative to the hand that holds it: downwind and high.
@export var fly_offset := Vector2(220.0, -340.0)
@export var rise_seconds := 3.0
@export var string_color := Color(0.25, 0.22, 0.2, 0.6)

var flying := false

var _delay := -1.0
var _up := 0.0
var _clock := 0.0
var _phase := 0.0
var _rest := Vector2(10.0, -26.0)
var _sprite: Sprite2D
var _string: Line2D


func _ready() -> void:
	z_index = 1
	_phase = randf() * TAU
	_sprite = Sprite2D.new()
	var path := KITE_DIR + "kite_%d.png" % texture_index
	if ResourceLoader.exists(path):
		_sprite.texture = load(path) as Texture2D
	_sprite.scale = Vector2(sail_scale, sail_scale)
	_sprite.position = _rest
	_sprite.rotation = 0.45
	add_child(_sprite)
	_string = Line2D.new()
	_string.width = 1.0
	_string.default_color = string_color
	_string.visible = false
	add_child(_string)


## Sends the kite up after `delay` seconds. A second call does nothing.
func launch(delay: float = 0.0) -> void:
	if flying or _delay >= 0.0:
		return
	_delay = maxf(delay, 0.0)


func _process(delta: float) -> void:
	_clock += delta
	if not flying and _delay >= 0.0:
		_delay -= delta
		if _delay <= 0.0:
			flying = true
			_string.visible = true
	if not flying:
		return
	_up = move_toward(_up, 1.0, delta / maxf(rise_seconds, 0.1))
	var e := 1.0 - pow(1.0 - _up, 2.0)
	var wind := Wind.sample(global_position + fly_offset)
	var sway := Vector2(sin(_clock * 0.9 + _phase) * 16.0, cos(_clock * 1.3 + _phase * 1.7) * 10.0) * e
	var pos := _rest.lerp(fly_offset + wind * 0.1, e) + sway
	_sprite.position = pos
	_sprite.rotation = lerpf(0.45, clampf(wind.x / 900.0, -0.35, 0.35) + sin(_clock * 1.1 + _phase) * 0.05, e)
	_draw_string(pos)


## The string from the hand to the kite's foot, bowing a little downwind.
func _draw_string(pos: Vector2) -> void:
	var foot := pos + Vector2(0.0, 36.0 * sail_scale / 0.13)
	var mid := foot * 0.5 + Vector2(18.0, 24.0)
	var pts := PackedVector2Array()
	for k in 9:
		var u := float(k) / 8.0
		pts.append(Vector2.ZERO.lerp(mid, u).lerp(mid.lerp(foot, u), u))
	_string.points = pts
