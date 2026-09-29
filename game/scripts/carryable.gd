extends Area2D
class_name Carryable
## Something the player can pick up. Weight is the whole design: it changes how the
## carrier moves. LIGHT leaves the body free, HEAVY removes the jump and slows the run,
## TWO_HANDED also removes crawling, so the route itself has to change.

signal picked_up(item: Carryable)
signal dropped(item: Carryable, at: Vector2)

enum Weight { LIGHT, HEAVY, TWO_HANDED }

@export var weight := Weight.LIGHT
@export var label := "bread"
@export var color := Color(0.85, 0.72, 0.45)
## A light item the kite may snag and carry. Off for things that should stay put.
@export var hookable := true
## The smallest build that can lift it: 0 a child, 1 an adult.
@export var min_build := 0
## A candle or lamp: carries a flame that lights the way and can be blown out.
@export var is_light_source := false
@export var light_color := Color(1.0, 0.78, 0.5)
@export var light_radius := 260.0

var held := false
var lit := true
var home_parent: Node = null

var _light: PointLight2D = null
var _flicker := 0.0

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
	if is_light_source:
		_make_light()


func _size_for_weight() -> Vector2:
	if is_light_source:
		return Vector2(10.0, 26.0)
	match weight:
		Weight.LIGHT: return Vector2(28.0, 22.0)
		Weight.HEAVY: return Vector2(34.0, 44.0)
		_: return Vector2(60.0, 70.0)


func _make_light() -> void:
	_light = PointLight2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_light.texture = tex
	_light.texture_scale = light_radius / 128.0
	_light.color = light_color
	_light.energy = 1.1
	_light.shadow_enabled = false
	_light.position = Vector2(0.0, -30.0)
	add_child(_light)
	var flame := Polygon2D.new()
	flame.name = "Flame"
	flame.color = Color(1.0, 0.86, 0.55)
	flame.polygon = PackedVector2Array([Vector2(0, -40), Vector2(4, -32), Vector2(0, -26), Vector2(-4, -32)])
	add_child(flame)


func _process(delta: float) -> void:
	if _light == null:
		return
	_flicker += delta * 9.0
	_light.energy = (1.05 + 0.12 * sin(_flicker) * sin(_flicker * 1.7)) if lit else 0.0
	var flame := get_node_or_null("Flame")
	if flame:
		flame.visible = lit


## Blows the flame out, or lights it again at a flame source.
func set_lit(on: bool) -> void:
	lit = on


## Called by the player. Moves the item into the hand.
func pick_up(hand: Node2D) -> void:
	held = true
	reparent(hand)
	position = Vector2.ZERO
	rotation = 0.0
	picked_up.emit(self)


## Called by the player. Returns the item to the level at a world position.
func drop(at: Vector2) -> void:
	held = false
	reparent(home_parent)
	global_position = at
	rotation = 0.0
	dropped.emit(self, at)
