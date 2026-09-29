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
## Auto gives an elder a long dress and everyone else none.
@export_enum("auto:-1", "none:0", "short:1", "long:2") var dress := -1
@export var talk_radius := 130.0
@export var silhouette := Color(0.09, 0.08, 0.10)

var player_near := false
var figure: Figure

var _visual: Node2D
var _prompt: Polygon2D
var _was_near := false


func _ready() -> void:
	add_to_group("npc")
	_build()


func _build() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	figure = Figure.new()
	figure.build = build
	figure.headscarf = headscarf
	figure.dress = dress if dress >= 0 else (2 if build == 2 else 0)
	figure.cane = build == 2
	figure.color = silhouette
	figure.hand_path = NodePath()
	_visual.add_child(figure)
	# A small warm mark above the head when the player can talk.
	_prompt = Polygon2D.new()
	_prompt.color = Color(1.0, 0.85, 0.6, 0.0)
	var py := -figure.height() * 1.16
	_prompt.polygon = PackedVector2Array([Vector2(0, py - 6), Vector2(5, py), Vector2(0, py + 6), Vector2(-5, py)])
	_visual.add_child(_prompt)


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
