extends Node2D
class_name Facades
## A row of Gaza City street facades built from code: two- to four-storey plastered blocks
## with shop fronts under awnings or half-rolled shutters, windows in recessed shade,
## balconies with railings and laundry, water tanks, solar panels and rebar stubs on the
## roofs, and a pavement along the road. Colour sits in the sunlit plaster; the openings
## stay dark, so a silhouette in front of them still reads. One building can be the bakery.

@export var seed := 5
@export var start_x := -800.0
@export var end_x := 4400.0
@export var ground_y := 900.0
@export var storey := 140.0
## The building under this x gets the bakery's wide mouth and sign (negative for none).
@export var bakery_x := -100000.0
## Stretches of pavement to leave out (a pit), as x ranges.
@export var pavement_gaps: Array[Vector2] = []
@export var plasters: Array[Color] = [
	Color(0.56, 0.50, 0.43), Color(0.50, 0.46, 0.42), Color(0.60, 0.53, 0.44), Color(0.46, 0.43, 0.41)]
@export var shade := Color(0.10, 0.09, 0.09)
@export var trim := Color(0.30, 0.26, 0.22)
@export var pavement := Color(0.38, 0.35, 0.32)
@export var awnings: Array[Color] = [Color(0.46, 0.22, 0.18), Color(0.24, 0.32, 0.30), Color(0.50, 0.42, 0.25)]
@export var laundry: Array[Color] = [Color(0.62, 0.62, 0.64), Color(0.46, 0.30, 0.30), Color(0.34, 0.40, 0.50), Color(0.60, 0.55, 0.40)]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rng.seed = seed
	var x := start_x
	while x < end_x:
		var w := _rng.randf_range(260.0, 480.0)
		var floors := _rng.randi_range(2, 4)
		var is_bakery := bakery_x >= x and bakery_x < x + w
		_building(x, w, floors, is_bakery)
		x += w + (_rng.randf_range(0.0, 14.0) if _rng.randf() < 0.3 else 0.0)
	_pavement()


func _rect(pos: Vector2, size: Vector2, col: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = col
	p.z_index = z
	p.polygon = PackedVector2Array([pos, pos + Vector2(size.x, 0.0), pos + size, pos + Vector2(0.0, size.y)])
	add_child(p)
	return p


func _poly(points: PackedVector2Array, col: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = col
	p.z_index = z
	p.polygon = points
	add_child(p)
	return p


func _building(x: float, w: float, floors: int, is_bakery: bool) -> void:
	var h := floors * storey + 34.0
	var top := ground_y - h
	var plaster: Color = plasters[_rng.randi() % plasters.size()]
	_rect(Vector2(x, top), Vector2(w, h), plaster)
	# A slightly darker party-wall edge so neighbours separate.
	_rect(Vector2(x, top), Vector2(3.0, h), plaster.darkened(0.18))
	# Parapet with rebar stubs waiting for the next floor.
	_rect(Vector2(x, top), Vector2(w, 16.0), trim)
	var stubs := _rng.randi_range(0, 3)
	for i in stubs:
		var sx := x + _rng.randf_range(20.0, w - 20.0)
		_rect(Vector2(sx, top - 22.0), Vector2(2.0, 22.0), shade)
	# Rooftop clutter: tanks, a solar panel, a dish.
	var tanks := _rng.randi_range(1, 3)
	for i in tanks:
		var tx := x + _rng.randf_range(16.0, w - 46.0)
		_rect(Vector2(tx, top - 24.0), Vector2(30.0, 24.0), shade)
		_rect(Vector2(tx + 3.0, top - 27.0), Vector2(24.0, 3.0), shade)
	if _rng.randf() < 0.45:
		var px := x + _rng.randf_range(20.0, w - 80.0)
		_poly(PackedVector2Array([
			Vector2(px, top - 4.0), Vector2(px + 60.0, top - 4.0), Vector2(px + 56.0, top - 26.0), Vector2(px + 4.0, top - 26.0)]),
			Color(0.16, 0.20, 0.28))
	# Upper floors.
	for k in range(1, floors):
		var floor_y := ground_y - k * storey - 34.0
		_windows_row(x, w, floor_y, plaster)
	# Ground floor: the shop.
	_shopfront(x, w, plaster, is_bakery)


func _windows_row(x: float, w: float, floor_y: float, plaster: Color) -> void:
	var n := maxi(int(w / 130.0), 1)
	var gap := w / float(n)
	for i in n:
		var wx := x + gap * (i + 0.5) - 24.0
		var wy := floor_y - 108.0
		_rect(Vector2(wx, wy), Vector2(48.0, 72.0), shade)
		_rect(Vector2(wx - 4.0, wy + 72.0), Vector2(56.0, 4.0), trim)
		# A shutter half down, or a curtain's lighter edge.
		var r := _rng.randf()
		if r < 0.35:
			_rect(Vector2(wx, wy), Vector2(48.0, _rng.randf_range(18.0, 44.0)), plaster.darkened(0.30))
		elif r < 0.55:
			_rect(Vector2(wx + 30.0, wy + 4.0), Vector2(14.0, 64.0), Color(0.42, 0.38, 0.34))
		if _rng.randf() < 0.42:
			_balcony(wx - 26.0, floor_y - 30.0, 100.0, plaster)
		elif _rng.randf() < 0.25:
			_rect(Vector2(wx + 52.0, wy + 36.0), Vector2(26.0, 20.0), shade)
			_rect(Vector2(wx + 54.0, wy + 38.0), Vector2(22.0, 16.0), Color(0.40, 0.38, 0.36))


func _balcony(bx: float, by: float, bw: float, plaster: Color) -> void:
	# Slab, its shadow on the wall, railing, and sometimes laundry.
	_rect(Vector2(bx, by), Vector2(bw, 8.0), trim)
	_rect(Vector2(bx, by + 8.0), Vector2(bw, 26.0), Color(0.0, 0.0, 0.0, 0.28))
	_rect(Vector2(bx, by - 46.0), Vector2(bw, 3.0), shade)
	var bars := int(bw / 14.0)
	for i in bars + 1:
		_rect(Vector2(bx + i * (bw / bars), by - 46.0), Vector2(2.0, 46.0), shade)
	if _rng.randf() < 0.45:
		var n := _rng.randi_range(2, 4)
		for i in n:
			var cx := bx + 10.0 + i * (bw - 20.0) / float(n)
			var col: Color = laundry[_rng.randi() % laundry.size()]
			_rect(Vector2(cx, by - 44.0), Vector2(_rng.randf_range(12.0, 20.0), _rng.randf_range(22.0, 38.0)), col)
	# A darker wall band under the slab reads as the recess.
	_rect(Vector2(bx + 4.0, by - 46.0), Vector2(bw - 8.0, 46.0), plaster.darkened(0.12), -1)


func _shopfront(x: float, w: float, plaster: Color, is_bakery: bool) -> void:
	var g := ground_y
	var ox := x + 28.0
	var ow := w - 56.0
	var oh := 118.0
	if is_bakery:
		ox = x + 20.0
		ow = w - 40.0
		oh = 132.0
	_rect(Vector2(ox, g - oh), Vector2(ow, oh), shade)
	var kind := _rng.randf()
	if is_bakery:
		# The oven's mouth glows at the back, bread trays under the counter light.
		_rect(Vector2(ox + ow * 0.55, g - 58.0), Vector2(46.0, 34.0), Color(0.86, 0.46, 0.16))
		_rect(Vector2(ox + ow * 0.55 + 6.0, g - 52.0), Vector2(34.0, 22.0), Color(0.98, 0.72, 0.30))
		_rect(Vector2(ox + 12.0, g - 40.0), Vector2(ow * 0.4, 40.0), Color(0.24, 0.20, 0.17))
		_rect(Vector2(ox + 16.0, g - 46.0), Vector2(ow * 0.4 - 8.0, 6.0), Color(0.62, 0.48, 0.30))
		_sign(ox, g - oh - 84.0, ow, "مخبز أبو أحمد")
	elif kind < 0.4:
		# Rolling shutter, part way down.
		var down := _rng.randf_range(0.35, 0.7)
		var sh := oh * down
		_rect(Vector2(ox, g - oh), Vector2(ow, sh), plaster.darkened(0.25))
		var lines := int(sh / 10.0)
		for i in lines:
			_rect(Vector2(ox, g - oh + i * 10.0), Vector2(ow, 2.0), plaster.darkened(0.45))
	elif kind < 0.75:
		# A door and a shop window with goods shelved behind.
		_rect(Vector2(ox + 8.0, g - oh + 10.0), Vector2(ow - 16.0, 8.0), trim)
		var shelf := ox + 20.0
		while shelf < ox + ow - 40.0:
			var col: Color = laundry[_rng.randi() % laundry.size()].darkened(0.35)
			_rect(Vector2(shelf, g - _rng.randf_range(50.0, 90.0)), Vector2(_rng.randf_range(10.0, 22.0), 18.0), col)
			shelf += _rng.randf_range(26.0, 44.0)
	else:
		# Shut for the day: a full shutter.
		_rect(Vector2(ox, g - oh), Vector2(ow, oh - 6.0), plaster.darkened(0.25))
		var lines := int((oh - 6.0) / 10.0)
		for i in lines:
			_rect(Vector2(ox, g - oh + i * 10.0), Vector2(ow, 2.0), plaster.darkened(0.45))
	# Awning over most shops: a striped band sloping out, and its shadow on the wall.
	if is_bakery or _rng.randf() < 0.6:
		var base: Color = awnings[_rng.randi() % awnings.size()]
		var ay := g - oh - 14.0
		var stripes := int(ow / 26.0)
		for i in stripes:
			var sx := ox - 6.0 + i * (ow + 12.0) / float(stripes)
			var sw := (ow + 12.0) / float(stripes)
			var col := base if i % 2 == 0 else base.lightened(0.35)
			_poly(PackedVector2Array([
				Vector2(sx, ay - 22.0), Vector2(sx + sw, ay - 22.0), Vector2(sx + sw + 4.0, ay + 6.0), Vector2(sx + 4.0, ay + 6.0)]), col)
		_rect(Vector2(ox - 2.0, ay + 6.0), Vector2(ow + 16.0, 24.0), Color(0.0, 0.0, 0.0, 0.30))
	# A step and a doorstep of shade.
	_rect(Vector2(ox - 6.0, g - 6.0), Vector2(ow + 12.0, 6.0), trim)


func _sign(x: float, y: float, w: float, text: String) -> void:
	_rect(Vector2(x, y), Vector2(w, 40.0), Color(0.20, 0.17, 0.15))
	var label := Label.new()
	label.text = text
	label.position = Vector2(x, y - 4.0)
	label.size = Vector2(w, 48.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_direction = Control.TEXT_DIRECTION_RTL
	var font: Font = load("res://assets/fonts/amiri/Amiri-Bold.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.88, 0.80, 0.62))
	add_child(label)


func _pavement() -> void:
	var edges: Array[float] = [start_x]
	for gap in pavement_gaps:
		edges.append(gap.x)
		edges.append(gap.y)
	edges.append(end_x)
	var i := 0
	while i + 1 < edges.size():
		var a: float = edges[i]
		var b: float = edges[i + 1]
		if b > a:
			_rect(Vector2(a, ground_y - 12.0), Vector2(b - a, 12.0), pavement, 1)
			_rect(Vector2(a, ground_y - 12.0), Vector2(b - a, 3.0), pavement.lightened(0.25), 1)
		i += 2
