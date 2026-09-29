extends Node2D
class_name Beam
## A fallen roof beam from the kit. Two-handed and adult-only: Layla cannot lift it. While
## it lies across the doorway it blocks the door; carried away, the door is free.

signal lifted(beam: Beam)

@export var door_x := 640.0
@export var block_reach := 120.0

@onready var item: Carryable = $Item
@onready var block: StaticBody2D = $Block
@onready var block_shape: CollisionShape2D = $Block/Shape
@onready var lean: Polygon2D = $Block/Lean

var _lifted_once := false


func _ready() -> void:
	item.picked_up.connect(_on_picked)
	item.dropped.connect(_on_dropped)
	_set_block(true)


func blocking() -> bool:
	return not block_shape.disabled


func _on_picked(_item: Carryable) -> void:
	_set_block(false)
	if not _lifted_once:
		_lifted_once = true
		lifted.emit(self)


func _on_dropped(_item: Carryable, at: Vector2) -> void:
	_set_block(absf(at.x - door_x) < block_reach)


func _set_block(on: bool) -> void:
	block_shape.disabled = not on
	lean.visible = on
	item.visible = not on
