extends Node2D
class_name Npc
## A neighbour in silhouette. Stands where placed, faces the player when they are near,
## and reports when the player talks to them. The beat decides what is said.

signal talked(npc: Npc)
signal approached(npc: Npc)

@export var npc_name := "Sami"
## 0 child, 1 adult, 2 elder: changes the height of the silhouette.
@export_enum("child", "adult", "elder") var build := 0
@export var headscarf := false
@export var talk_radius := 130.0
@export var silhouette := Color(0.09, 0.08, 0.10)

var player_near := false

var _visual: Node2D
var _prompt: Polygon2D
var _was_near := false


func _ready() -> void:
	add_to_group("npc")
	_build()


func _build() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	var h: float = [0.78, 1.0, 0.9][build]
	var body := Polygon2D.new()
	body.color = silhouette
	body.polygon = _scaled(PackedVector2Array([
		Vector2(-12, -80), Vector2(12, -80), Vector2(16, -40), Vector2(10, -40), Vector2(14, 0),
		Vector2(4, 0), Vector2(0, -30), Vector2(-4, 0), Vector2(-14, 0), Vector2(-10, -40), Vector2(-16, -40)]), h)
	_visual.add_child(body)
	var head := Polygon2D.new()
	head.color = silhouette
	head.polygon = _scaled(PackedVector2Array([
		Vector2(0, -112), Vector2(11, -109), Vector2(16, -98), Vector2(12, -85), Vector2(0, -80),
		Vector2(-12, -85), Vector2(-16, -98), Vector2(-11, -109)]), h)
	_visual.add_child(head)
	if headscarf:
		var scarf := Polygon2D.new()
		scarf.color = silhouette
		scarf.polygon = _scaled(PackedVector2Array([
			Vector2(0, -117), Vector2(13, -113), Vector2(19, -100), Vector2(19, -86), Vector2(24, -70),
			Vector2(8, -74), Vector2(0, -76), Vector2(-8, -74), Vector2(-24, -70), Vector2(-19, -86),
			Vector2(-19, -100), Vector2(-13, -113)]), h)
		_visual.add_child(scarf)
	if build == 2:
		# A cane.
		var cane := Line2D.new()
		cane.width = 3.0
		cane.default_color = silhouette
		cane.points = PackedVector2Array([Vector2(20, -60), Vector2(26, 0)])
		_visual.add_child(cane)
	for dx in [4.0, 11.0]:
		var eye := Polygon2D.new()
		eye.color = Color(1.0, 0.85, 0.6)
		var y := -100.0 * h
		eye.polygon = PackedVector2Array([Vector2(dx, y), Vector2(dx + 4, y), Vector2(dx + 4, y + 4), Vector2(dx, y + 4)])
		_visual.add_child(eye)
	# A small warm mark above the head when the player can talk.
	_prompt = Polygon2D.new()
	_prompt.color = Color(1.0, 0.85, 0.6, 0.0)
	var py := -132.0 * h
	_prompt.polygon = PackedVector2Array([Vector2(0, py - 6), Vector2(5, py), Vector2(0, py + 6), Vector2(-5, py)])
	_visual.add_child(_prompt)


func _scaled(points: PackedVector2Array, h: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(p.x * lerpf(0.85, 1.0, h), p.y * h))
	return out


func _physics_process(delta: float) -> void:
	var p := _nearest_player()
	player_near = p != null and p.global_position.distance_to(global_position) < talk_radius
	if player_near:
		_visual.scale.x = -1.0 if p.global_position.x < global_position.x else 1.0
	_prompt.color.a = move_toward(_prompt.color.a, 1.0 if player_near else 0.0, delta * 4.0)
	if player_near and not _was_near:
		approached.emit(self)
	_was_near = player_near
	if player_near and Input.is_action_just_pressed("interact") and not Say.busy:
		talked.emit(self)


func _nearest_player() -> Player:
	var best: Player = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("player"):
		var pl := node as Player
		if pl == null:
			continue
		var d := pl.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = pl
	return best
