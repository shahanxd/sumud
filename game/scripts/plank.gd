extends Node2D
class_name Plank
## A plank from the kit of puzzle pieces. Carried two-handed (no jump, no crawl, slow).
## Set down within reach of its gap it snaps across as a bridge; picked up again it is a
## plank once more. The gap is the span between `gap_left` and `gap_right` in world x.

signal bridged(plank: Plank)
signal lifted(plank: Plank)

@export var gap_left := 2000.0
@export var gap_right := 2300.0
@export var ground_y := 900.0
@export var snap_reach := 160.0
@export var length := 340.0
@export var thickness := 14.0

var is_bridge := false

@onready var item: Carryable = $Item
@onready var bridge: StaticBody2D = $Bridge
@onready var bridge_shape: CollisionShape2D = $Bridge/Shape
@onready var bridge_visual: Polygon2D = $Bridge/Visual


func _ready() -> void:
	item.dropped.connect(_on_dropped)
	item.picked_up.connect(_on_picked)
	# The bridge's top is flush with the road, so walking onto it needs no step up.
	var half := length * 0.5
	bridge_visual.polygon = PackedVector2Array([
		Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(half, thickness), Vector2(-half, thickness)])
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	bridge_shape.shape = rect
	bridge_shape.position = Vector2(0.0, thickness * 0.5)
	bridge.global_position = Vector2((gap_left + gap_right) * 0.5, ground_y)
	_set_bridge(false)


func _on_dropped(_item: Carryable, at: Vector2) -> void:
	var near_left := absf(at.x - gap_left) < snap_reach and absf(at.y - ground_y) < 60.0
	var near_right := absf(at.x - gap_right) < snap_reach and absf(at.y - ground_y) < 60.0
	if near_left or near_right:
		_set_bridge(true)
		bridged.emit(self)


func _on_picked(_item: Carryable) -> void:
	if is_bridge:
		_set_bridge(false)
		lifted.emit(self)


func _set_bridge(on: bool) -> void:
	is_bridge = on
	bridge_shape.disabled = not on
	bridge_visual.visible = on
	item.visible = not on
	if on:
		# Park the pickup at the bridge's near end so it can be lifted again.
		item.global_position = Vector2(gap_left - 20.0, ground_y)
