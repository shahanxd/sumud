extends Area2D
class_name Carryable
## Something the player can pick up. Weight is the whole design: it changes how the
## carrier moves. LIGHT leaves the body free, HEAVY removes the jump and slows the run,
## TWO_HANDED also removes crawling, so the route itself has to change.

enum Weight { LIGHT, HEAVY, TWO_HANDED }

@export var weight := Weight.LIGHT
@export var label := "bread"
@export var color := Color(0.85, 0.72, 0.45)

var held := false
var home_parent: Node = null

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("carryable")
	home_parent = get_parent()
	var size := _size_for_weight()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y), Vector2(size.x * 0.5, -size.y),
		Vector2(size.x * 0.5, 0.0), Vector2(-size.x * 0.5, 0.0),
	])
	visual.color = color
	var shape := $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape.size = size
		$CollisionShape2D.position = Vector2(0.0, -size.y * 0.5)


func _size_for_weight() -> Vector2:
	match weight:
		Weight.LIGHT: return Vector2(28.0, 22.0)
		Weight.HEAVY: return Vector2(34.0, 44.0)
		_: return Vector2(60.0, 70.0)


## Called by the player. Moves the item into the hand.
func pick_up(hand: Node2D) -> void:
	held = true
	reparent(hand)
	position = Vector2.ZERO
	rotation = 0.0


## Called by the player. Returns the item to the level at a world position.
func drop(at: Vector2) -> void:
	held = false
	reparent(home_parent)
	global_position = at
	rotation = 0.0
