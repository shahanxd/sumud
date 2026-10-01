extends Kite
## Sami's kite in the festival contest: the same kite as Layla's, flown by code instead of
## by the keys. It pays its string out and takes it in on a slow random walk, never past
## max_length, and holds a drifting place downwind of Sami. It never hooks anything.

@export var seed := 11
## How far downwind of the hand it tries to hang, px.
@export var drift := 260.0

var _rng := RandomNumberGenerator.new()
var _target_length := 0.0
var _clock := 0.0


func _ready() -> void:
	super()
	_rng.seed = seed
	_target_length = string_length


func _physics_process(delta: float) -> void:
	if not flying or _anchor == null:
		return
	_clock += delta
	var anchor := _anchor.global_position

	# The random walk in height: a new length now and then, approached at half reel speed.
	if _rng.randf() < delta * 0.5:
		_target_length = clampf(_target_length + _rng.randf_range(-180.0, 220.0), min_length + 80.0, max_length - 40.0)
	string_length = move_toward(string_length, _target_length, reel_speed * 0.6 * delta)

	# The same aerodynamics as the player's kite, with a steering push toward a drifting mark.
	var wind := Wind.sample(global_position)
	var relative := wind - vel
	var force := relative * drag
	force.y -= relative.length() * lift
	force.y += weight
	var want_x := anchor.x + drift + sin(_clock * 0.35) * 140.0
	force.x += clampf((want_x - global_position.x) * 5.0, -steer_force, steer_force)
	vel += force * delta
	vel *= 0.995
	global_position += vel * delta

	var offset := global_position - anchor
	var dist := offset.length()
	if dist > string_length:
		var dir := offset / dist
		global_position = anchor + dir * string_length
		var outward := vel.dot(dir)
		if outward > 0.0:
			vel -= dir * outward

	if global_position.y > ground_y:
		reel_in()
		return

	rotation = offset.angle() + PI * 0.5
	_flap(delta)
	_update_rope(anchor, delta)
	_update_tail(delta)
