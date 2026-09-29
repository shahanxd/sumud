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
	# The item is drawn by _draw from its label; the polygon only sized the placeholder.
	visual.visible = false
	var shape := $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape = shape.duplicate()
		shape.size = size
		$CollisionShape2D.shape = shape
		$CollisionShape2D.position = Vector2(0.0, -size.y * 0.5)
	if is_light_source:
		_make_light()
	queue_redraw()


func _size_for_weight() -> Vector2:
	if is_light_source:
		return Vector2(10.0, 26.0)
	match weight:
		Weight.LIGHT: return Vector2(28.0, 22.0)
		Weight.HEAVY: return Vector2(34.0, 44.0)
		_: return Vector2(60.0, 70.0)


## Which silhouette to draw, from the label.
func _shape() -> String:
	var l := label.to_lower()
	if is_light_source:
		return "candle"
	if l.contains("bread") or l.contains("khubz"):
		return "bread"
	if l.contains("jerrycan") or l.contains("gallon"):
		return "jerrycan"
	if l.contains("drum") or l.contains("barrel"):
		return "drum"
	if l.contains("string") or l.contains("spool"):
		return "spool"
	return "box"


func _ellipse(centre: Vector2, rx: float, ry: float, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Everything a hand can hold, drawn in silhouette with one catch of light along its top,
## so it reads against both a bright sky and a dark room.
func _draw() -> void:
	var rim := color.lightened(0.45)
	if not held:
		# Contact with the ground.
		var w := _size_for_weight().x * 0.75
		draw_colored_polygon(_ellipse(Vector2(1.0, 0.0), w, 3.0), Color(0.0, 0.0, 0.0, 0.3))
	match _shape():
		"bread":
			# Three flat loaves, stacked.
			for i in 3:
				var c := Vector2(float(i - 1) * 1.5, -5.0 - float(i) * 6.0)
				draw_colored_polygon(_ellipse(c, 15.0, 4.5), color)
				draw_polyline(_ellipse(c + Vector2(0.0, -1.0), 12.0, 2.0, 12), rim, 1.2, true)
		"jerrycan":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-17, 0), Vector2(17, 0), Vector2(17, -34), Vector2(9, -42), Vector2(-17, -42)]), color)
			# Handle loop and spout cap.
			draw_polyline(PackedVector2Array([Vector2(-6, -42), Vector2(-6, -49), Vector2(6, -49), Vector2(6, -43)]), color, 3.0, true)
			draw_rect(Rect2(10, -48, 6, 7), color)
			draw_line(Vector2(-15, -40), Vector2(7, -40), rim, 1.2, true)
			draw_line(Vector2(-13, -30), Vector2(-13, -8), rim, 1.0, true)
		"drum":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-30, 0), Vector2(30, 0), Vector2(31, -66), Vector2(-31, -66)]), color)
			draw_colored_polygon(_ellipse(Vector2(0, -66), 31.0, 5.0), color)
			draw_polyline(_ellipse(Vector2(0, -66), 29.0, 4.0), rim, 1.2, true)
			for y in [-20.0, -44.0]:
				draw_line(Vector2(-30, y), Vector2(30, y), rim, 1.2, true)
		"spool":
			# A wound spool lying on its side, its stick through the middle.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-13, 0), Vector2(13, 0), Vector2(13, -16), Vector2(-13, -16)]), color)
			draw_colored_polygon(_ellipse(Vector2(-13, -8), 3.0, 8.0), color)
			draw_colored_polygon(_ellipse(Vector2(13, -8), 3.0, 8.0), color)
			draw_line(Vector2(-22, -8), Vector2(22, -8), color, 2.0, true)
			for x in [-8.0, -3.0, 2.0, 7.0]:
				draw_line(Vector2(x, -15), Vector2(x, -1), rim, 1.0, true)
		"candle":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-5, 0), Vector2(5, 0), Vector2(5, -24), Vector2(3, -27), Vector2(-4, -26)]), color)
			draw_line(Vector2(-4, -22), Vector2(-4, -6), rim, 1.0, true)
		_:
			var size := _size_for_weight()
			draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), color)
			draw_line(Vector2(-size.x * 0.5 + 2.0, -size.y + 2.0), Vector2(size.x * 0.5 - 2.0, -size.y + 2.0), rim, 1.2, true)


func _make_light() -> void:
	_light = PointLight2D.new()
	# Three stops so the light pools near the flame instead of tinting the whole room.
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.add_point(0.35, Color(1, 1, 1, 0.25))
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
	if is_light_source and lit and not on:
		Sound.play("candle_out", "effects")
	lit = on


## Called by the player. Moves the item into the hand.
func pick_up(hand: Node2D) -> void:
	held = true
	reparent(hand)
	position = Vector2.ZERO
	rotation = 0.0
	Sound.play("grab", "effects", 0.0, 0.05)
	picked_up.emit(self)


## Called by the player. Returns the item to the level at a world position.
func drop(at: Vector2) -> void:
	held = false
	reparent(home_parent)
	global_position = at
	rotation = 0.0
	# The weight is heard: a full can or a beam thuds, bread or a candle is set down.
	if weight == Weight.LIGHT:
		Sound.play("grab", "effects", -8.0, 0.05)
	else:
		Sound.play("drop_heavy", "effects", 0.0, 0.04)
	dropped.emit(self, at)
