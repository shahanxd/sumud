extends Camera2D
## Follows the player and leads in the direction of travel: the look-ahead eases out to
## ±look_ahead over look_ahead_time while she runs and eases back to centre when she stops,
## so a turn swings the view rather than snapping it. While the kite flies, frames both the
## player and the kite so the sky opens up. Whatever the target, the character is never
## allowed off the screen. A beat can point it at anything else (a card's view of the sea)
## and shake it once for the strike.

@export var player_path: NodePath
@export var kite_path: NodePath
## How far ahead of the character the view leads at full run, px.
@export var look_ahead := 140.0
## Seconds for the lead to ease from centre to ±look_ahead (and back).
@export var look_ahead_time := 0.4
## Below this horizontal speed (px/s) the lead returns to centre.
@export var look_ahead_min_speed := 30.0
@export var follow_speed := 5.0
@export var ground_bias := -250.0
## The character is kept at least this far inside the screen's edges, px.
@export var edge_margin := 120.0
## The world y of the horizon (the sea line or the far ground); the sky shader is told
## where it falls on screen every frame so the sun and the haze sit on it.
@export var world_horizon_y := 700.0
## Zoom while walking; the figure should be about a sixth of the frame, not a tenth.
@export var ground_zoom := 1.3

var _player: Player
var _kite: Kite
var _target: Node2D = null
var _shake := 0.0
var _shake_time := 0.0
## The current lead, px, signed by the direction of travel.
var _lead := 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as Player
	_kite = get_node_or_null(kite_path) as Kite
	zoom = Vector2.ONE * ground_zoom
	# The beat's camera owns the view, whatever else is in the tree.
	make_current()
	if _player:
		global_position = _player.global_position + Vector2(0.0, ground_bias)
		reset_smoothing()


## Follow a player again (after a switch) or any node (a view for a card).
func follow(node: Node2D) -> void:
	if node is Player:
		_player = node
		_target = null
	else:
		_target = node


func shake(amount: float, seconds: float) -> void:
	_shake = amount
	_shake_time = seconds


func _process(delta: float) -> void:
	var target := global_position
	var target_zoom := Vector2.ONE * ground_zoom
	if _target != null:
		target = _target.global_position
		target_zoom = Vector2.ONE * 0.9
	elif _player != null:
		_step_lead(delta)
		target = _player.global_position + Vector2(_lead, ground_bias)
		if _kite != null and _kite.flying:
			target = _player.global_position.lerp(_kite.global_position, 0.5)
			var spread := _player.global_position.distance_to(_kite.global_position)
			target_zoom = Vector2.ONE * clampf(ground_zoom - spread / 2000.0, 0.7, ground_zoom)
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target, t)
	zoom = zoom.lerp(target_zoom, t)
	if _target == null and _player != null:
		_keep_on_screen()
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := _shake * clampf(_shake_time, 0.0, 1.0)
		offset = Vector2(randf_range(-k, k), randf_range(-k, k))
	else:
		offset = offset.lerp(Vector2.ZERO, t)
	_place_horizon()


## Eases the lead toward the direction of travel while moving, back to centre when still.
func _step_lead(delta: float) -> void:
	var goal := 0.0
	if absf(_player.velocity.x) > look_ahead_min_speed:
		goal = float(_player.facing) * look_ahead
	var rate := look_ahead / maxf(look_ahead_time, 0.001)
	_lead = move_toward(_lead, goal, rate * delta)


## Whatever the smoothing is doing, the character's body stays inside the frame.
func _keep_on_screen() -> void:
	var view := get_viewport_rect().size
	if view.x <= 0.0 or view.y <= 0.0 or zoom.x <= 0.0 or zoom.y <= 0.0:
		return
	var half := Vector2(view.x / zoom.x, view.y / zoom.y) * 0.5 - Vector2(edge_margin, edge_margin)
	half.x = maxf(half.x, 0.0)
	half.y = maxf(half.y, 0.0)
	# Her middle, not her feet, so a jump near the top edge counts too.
	var body := _player.global_position + Vector2(0.0, -_player.figure.height() * 0.5)
	global_position.x = clampf(global_position.x, body.x - half.x, body.x + half.x)
	global_position.y = clampf(global_position.y, body.y - half.y, body.y + half.y)


func _place_horizon() -> void:
	var view := get_viewport_rect().size
	if view.y <= 0.0:
		return
	var centre := get_screen_center_position()
	var frac := 0.5 + (world_horizon_y - centre.y) * zoom.y / view.y
	frac = clampf(frac, 0.2, 0.95)
	for node in get_tree().get_nodes_in_group("sky"):
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("horizon", frac)
