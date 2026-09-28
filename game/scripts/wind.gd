extends Node
## Global wind field (autoload "Wind"). Sampled by the kite, dust, washing lines and cloth.
## The wind is mostly onshore, blowing from the sea on the left toward the city on the
## right, with slow gusts and small eddies from smooth noise. It is stronger higher up.

var base_direction := Vector2(1.0, -0.15).normalized()
var base_strength := 140.0     # pixels per second, calm day
var gust_strength := 120.0     # how much a gust adds or removes
var height_reference_y := 600.0 # world y at which the height factor is 1.0

var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	_noise.seed = 7
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.8


func _process(delta: float) -> void:
	_time += delta


## Wind velocity at a world position, in pixels per second.
func sample(pos: Vector2) -> Vector2:
	var gust := _noise.get_noise_3d(pos.x * 0.0015, pos.y * 0.003, _time * 0.25)
	var eddy := _noise.get_noise_3d(pos.x * 0.004 + 100.0, pos.y * 0.004, _time * 0.6)
	var strength := base_strength + gust_strength * gust
	var direction := base_direction.rotated(eddy * 0.35)
	var height_factor := clampf(1.0 + (height_reference_y - pos.y) / 1200.0, 0.6, 1.8)
	return direction * strength * height_factor


## 0..1 turbulence measure, used to shake washing and dust.
func turbulence(pos: Vector2) -> float:
	return absf(_noise.get_noise_3d(pos.x * 0.01, pos.y * 0.01, _time * 1.5))
