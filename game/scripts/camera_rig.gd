extends Camera2D
## Follows the player with a little look-ahead. While the kite flies, frames both the
## player and the kite so the sky opens up. A beat can point it at anything else (a card's
## view of the sea) and shake it once for the strike.

@export var player_path: NodePath
@export var kite_path: NodePath
@export var look_ahead := 140.0
@export var follow_speed := 5.0
@export var ground_bias := -250.0
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
		target = _player.global_position + Vector2(_player.facing * look_ahead, ground_bias)
		if _kite != null and _kite.flying:
			target = _player.global_position.lerp(_kite.global_position, 0.5)
			var spread := _player.global_position.distance_to(_kite.global_position)
			target_zoom = Vector2.ONE * clampf(ground_zoom - spread / 2000.0, 0.7, ground_zoom)
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target, t)
	zoom = zoom.lerp(target_zoom, t)
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := _shake * clampf(_shake_time, 0.0, 1.0)
		offset = Vector2(randf_range(-k, k), randf_range(-k, k))
	else:
		offset = offset.lerp(Vector2.ZERO, t)
	_place_horizon()


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
