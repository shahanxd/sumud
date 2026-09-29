extends Camera2D
## Follows the player with a little look-ahead. While the kite flies, frames both the
## player and the kite so the sky opens up.

@export var player_path: NodePath
@export var kite_path: NodePath
@export var look_ahead := 140.0
@export var follow_speed := 5.0
@export var ground_bias := -250.0

var _player: Player
var _kite: Kite


func _ready() -> void:
	_player = get_node(player_path) as Player
	_kite = get_node(kite_path) as Kite
	if _player:
		global_position = _player.global_position + Vector2(0.0, ground_bias)


func _process(delta: float) -> void:
	if _player == null:
		return
	var target := _player.global_position + Vector2(_player.facing * look_ahead, ground_bias)
	var target_zoom := Vector2.ONE
	if _kite != null and _kite.flying:
		target = _player.global_position.lerp(_kite.global_position, 0.5)
		var spread := _player.global_position.distance_to(_kite.global_position)
		target_zoom = Vector2.ONE * clampf(1.0 - spread / 2400.0, 0.7, 1.0)
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target, t)
	zoom = zoom.lerp(target_zoom, t)
