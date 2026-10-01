extends Node2D
class_name D1StreetDressing
## Day 1's dressing of the street, shared by the morning walk (Scene 2) and the kite run
## (Scene 6): the neighbours at their doors, each with a performed idle; Abu Fadi's solar
## panels on a cart; the clinic's sign; Hajja Amina's two-storey house at the far left with
## its roof, its laundry line and the outside staircase up to it; the steps down to the
## sand at the right end. Collision lives in the scene file; the visuals that repeat are
## built here in the street's dark palette. Beats move the people through walk_npc().

const TRIM := Color(0.30, 0.26, 0.22)
const SHADE := Color(0.10, 0.09, 0.09)
const PLASTER := Color(0.56, 0.50, 0.43)
const PANEL := Color(0.16, 0.20, 0.28)
const PAVEMENT := Color(0.38, 0.35, 0.32)
const SAND := Color(0.72, 0.64, 0.48)

## Hajja Amina's roof: its floor, its ends, the landing of the stairs and the stair foot.
## The base street's ground is y 900; the facade under the roof is the two-storey block
## between x -548 and -129 that facades.gd builds from its seed.
const ROOF_Y := 586.0
const ROOF_LEFT := -548.0
const ROOF_RIGHT := -129.0
const LANDING_Y := 660.0
const STAIR_FOOT_X := 300.0
const LINE_Y := 446.0
## Where the runaway kite catches: under the middle sheet.
const SNAG := Vector2(-340.0, 470.0)
## Where the twins wait, mid-street.
const TWINS_X := 3150.0
## The top of the steps down to the sand, past the last facade.
const SAND_STEPS_X := 5020.0
## Where Hajja Amina stands at her roof hatch when she comes up.
const HATCH_STAND := Vector2(-460.0, 586.0)
const WINDOW_STAND := Vector2(-200.0, 740.0)

@onready var hajja: Npc = $HajjaAmina
@onready var abu_ahmad: Npc = $AbuAhmad
@onready var abu_fadi: Npc = $AbuFadi
@onready var um_samir: Npc = $UmSamir
@onready var samir: Npc = $Samir
@onready var hassan: Npc = $Hassan
@onready var hussein: Npc = $Hussein
@onready var sami: Npc = $Sami
@onready var sheet_mid: Polygon2D = $Laundry/Sheet2
@onready var hook: Area2D = $Laundry/Hook
@onready var line: Line2D = $Laundry/Line

var _sheets: Array[Polygon2D] = []
var _sheet_base: Array[PackedVector2Array] = []
var _loose_panel: Polygon2D = null
var _broom: Node2D = null
var _twin_kites: Array[Sprite2D] = []
var _wave_left := 0.0
var _t := 0.0


func _ready() -> void:
	_sheets = [$Laundry/Sheet1, $Laundry/Sheet2, $Laundry/Sheet3]
	for s in _sheets:
		_sheet_base.append(s.polygon)
	line.points = PackedVector2Array([
		Vector2(-500.0, LINE_Y), Vector2(-420.0, LINE_Y + 7.0), Vector2(-340.0, LINE_Y + 10.0),
		Vector2(-260.0, LINE_Y + 7.0), Vector2(-180.0, LINE_Y)])
	_build_roof()
	_build_stairs()
	_build_window()
	_build_cart()
	_build_clinic_sign()
	_build_sand_steps()
	_build_broom()
	_build_twin_kites()
	# Standing poses: Um Samir's hands low on the broom, Abu Fadi's arms out on the panel,
	# the twins' kites held up.
	um_samir.figure.load = 1
	abu_fadi.figure.load = 2
	hassan.figure.arm_up = true
	hussein.figure.arm_up = true
	# Abu Ahmad looks into his bakery, toward the oven; the rest face the street's right.
	face_npc(abu_ahmad, 1)


# -- Building the set ---------------------------------------------------------------------

func _rect(pos: Vector2, size: Vector2, col: Color, z := 0, parent: Node = null) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = col
	p.z_index = z
	p.polygon = PackedVector2Array([pos, pos + Vector2(size.x, 0.0), pos + size, pos + Vector2(0.0, size.y)])
	(parent if parent != null else self).add_child(p)
	return p


func _poly(points: PackedVector2Array, col: Color, z := 0, parent: Node = null) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = col
	p.z_index = z
	p.polygon = points
	(parent if parent != null else self).add_child(p)
	return p


func _ring(centre: Vector2, r: float, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(centre + Vector2(cos(a), sin(a)) * r)
	return pts


## The roof: a hatch at the left, two poles with the line between them, pegs on the sheets.
func _build_roof() -> void:
	_rect(Vector2(-540.0, 536.0), Vector2(60.0, 50.0), SHADE)
	_rect(Vector2(-544.0, 532.0), Vector2(68.0, 6.0), TRIM)
	for px in [-502.0, -182.0]:
		_rect(Vector2(px, LINE_Y - 8.0), Vector2(4.0, ROOF_Y - LINE_Y + 8.0), SHADE)
		_rect(Vector2(px - 10.0, LINE_Y - 8.0), Vector2(24.0, 3.0), SHADE)
	for base in _sheet_base:
		_rect(base[0] + Vector2(2.0, -6.0), Vector2(3.0, 9.0), TRIM)
		_rect(base[1] + Vector2(-5.0, -6.0), Vector2(3.0, 9.0), TRIM)
	# The parapet's line along the front edge of the roof.
	_rect(Vector2(ROOF_LEFT, ROOF_Y - 4.0), Vector2(ROOF_RIGHT - ROOF_LEFT, 4.0), TRIM)


## The outside staircase up the neighbour's wall to the landing, and the party wall the
## jump from the landing clears onto Hajja Amina's roof.
func _build_stairs() -> void:
	var pts := PackedVector2Array()
	var x := STAIR_FOOT_X
	var y := 900.0
	pts.append(Vector2(x, y))
	for i in 12:
		y -= 20.0
		pts.append(Vector2(x, y))
		x -= 30.0
		pts.append(Vector2(x, y))
	pts.append(Vector2(ROOF_RIGHT, LANDING_Y))
	pts.append(Vector2(ROOF_RIGHT, LANDING_Y + 20.0))
	pts.append(Vector2(-60.0, 680.0))
	pts.append(Vector2(STAIR_FOOT_X, 920.0))
	_poly(pts, TRIM)
	# The wedge under the flight, in shade, so the stairs read as a solid thing.
	_poly(PackedVector2Array([
		Vector2(-60.0, 680.0), Vector2(STAIR_FOOT_X, 920.0), Vector2(STAIR_FOOT_X, 900.0 + 40.0),
		Vector2(-60.0, 700.0)]), SHADE)
	var rail := Line2D.new()
	rail.width = 3.0
	rail.default_color = SHADE
	rail.points = PackedVector2Array([Vector2(STAIR_FOOT_X + 6.0, 856.0), Vector2(-66.0, 616.0), Vector2(-136.0, 616.0)])
	add_child(rail)
	for i in 5:
		var px := STAIR_FOOT_X - 6.0 - float(i) * 84.0
		var py := 900.0 - float(i) * 56.0
		_rect(Vector2(px, py - 44.0), Vector2(3.0, 44.0), SHADE)
	_rect(Vector2(-141.0, ROOF_Y), Vector2(12.0, LANDING_Y + 20.0 - ROOF_Y), PLASTER.darkened(0.25))
	_rect(Vector2(-141.0, LANDING_Y), Vector2(81.0, 4.0), TRIM.lightened(0.2))


## Hajja Amina's first-floor window: a pale curtain behind her so her silhouette reads, a
## sill and the wall under it in front.
func _build_window() -> void:
	_rect(Vector2(-236.0, 560.0), Vector2(72.0, 134.0), SHADE, -1)
	_rect(Vector2(-232.0, 565.0), Vector2(64.0, 129.0), Color(0.50, 0.46, 0.42), -1)
	_rect(Vector2(-236.0, 704.0), Vector2(72.0, 60.0), PLASTER)
	_rect(Vector2(-242.0, 694.0), Vector2(84.0, 10.0), TRIM)
	_rect(Vector2(-236.0, 560.0), Vector2(72.0, 5.0), TRIM)


## Abu Fadi's panels: four stacked leaning on a hand cart, one in his hands being angled.
func _build_cart() -> void:
	_rect(Vector2(1700.0, 862.0), Vector2(100.0, 12.0), TRIM)
	_rect(Vector2(1800.0, 846.0), Vector2(34.0, 4.0), TRIM)
	_rect(Vector2(1830.0, 846.0), Vector2(4.0, 20.0), TRIM)
	_poly(_ring(Vector2(1720.0, 886.0), 14.0), SHADE)
	_poly(_ring(Vector2(1780.0, 886.0), 14.0), SHADE)
	for i in 4:
		var panel := Polygon2D.new()
		panel.color = PANEL
		panel.polygon = PackedVector2Array([Vector2(-36.0, -22.0), Vector2(36.0, -22.0), Vector2(36.0, 22.0), Vector2(-36.0, 22.0)])
		panel.position = Vector2(1716.0 + float(i) * 16.0, 838.0 - float(i) * 4.0)
		panel.rotation = -0.42
		add_child(panel)
		_rect(Vector2(-36.0, -1.0), Vector2(72.0, 2.0), PANEL.lightened(0.25), 0, panel)
		_rect(Vector2(-1.0, -22.0), Vector2(2.0, 44.0), PANEL.lightened(0.25), 0, panel)
	_loose_panel = Polygon2D.new()
	_loose_panel.color = PANEL
	_loose_panel.polygon = PackedVector2Array([Vector2(-40.0, -46.0), Vector2(40.0, -46.0), Vector2(40.0, 0.0), Vector2(-40.0, 0.0)])
	_loose_panel.position = Vector2(1676.0, 900.0)
	_loose_panel.rotation = -0.48
	add_child(_loose_panel)
	_rect(Vector2(-40.0, -24.0), Vector2(80.0, 2.0), PANEL.lightened(0.25), 0, _loose_panel)
	_rect(Vector2(-1.0, -46.0), Vector2(2.0, 46.0), PANEL.lightened(0.25), 0, _loose_panel)


## The clinic's board over its door, with a crescent, on the block after the pit.
func _build_clinic_sign() -> void:
	var x := 2619.0
	var w := 239.0
	var y := 696.0
	_rect(Vector2(x, y), Vector2(w, 40.0), Color(0.20, 0.17, 0.15))
	_poly(_ring(Vector2(x + 24.0, y + 20.0), 11.0, 14), Color(0.62, 0.16, 0.16))
	_poly(_ring(Vector2(x + 28.0, y + 18.0), 9.0, 14), Color(0.20, 0.17, 0.15))
	var label := Label.new()
	label.text = "عيادة الحي"
	label.position = Vector2(x + 40.0, y - 4.0)
	label.size = Vector2(w - 50.0, 48.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_direction = Control.TEXT_DIRECTION_RTL
	var font: Font = load("res://assets/fonts/amiri/Amiri-Bold.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.88, 0.80, 0.62))
	add_child(label)


## The steps down to the sand at the right end, past the last facade.
func _build_sand_steps() -> void:
	for i in 5:
		var top := 900.0 + float(i) * 20.0
		_rect(Vector2(SAND_STEPS_X + float(i) * 50.0, top), Vector2(50.0, 1000.0 - top), PAVEMENT)
		_rect(Vector2(SAND_STEPS_X + float(i) * 50.0, top), Vector2(50.0, 3.0), PAVEMENT.lightened(0.25))
	_rect(Vector2(SAND_STEPS_X + 250.0, 1000.0), Vector2(2200.0, 500.0), SAND)
	_rect(Vector2(SAND_STEPS_X - 6.0, 850.0), Vector2(4.0, 50.0), SHADE)
	_rect(Vector2(SAND_STEPS_X - 6.0, 850.0), Vector2(60.0, 3.0), SHADE)


## Um Samir's broom, held low in both hands, rocking as she sweeps the clinic step.
func _build_broom() -> void:
	_broom = Node2D.new()
	_broom.position = Vector2(14.0, -60.0)
	um_samir.add_child(_broom)
	_poly(PackedVector2Array([Vector2(0.0, -12.0), Vector2(4.0, -12.0), Vector2(30.0, 54.0), Vector2(26.0, 56.0)]), TRIM, 0, _broom)
	_poly(PackedVector2Array([Vector2(16.0, 50.0), Vector2(46.0, 50.0), Vector2(52.0, 60.0), Vector2(12.0, 60.0)]), SHADE, 0, _broom)


## The twins' small kites, held up in the leading hand; children of the figure so they flip with it.
func _build_twin_kites() -> void:
	var paths: Array[String] = ["res://assets/props/kites/kite_1.png", "res://assets/props/kites/kite_5.png"]
	var twins: Array[Npc] = [hassan, hussein]
	for i in 2:
		var tex: Texture2D = load(paths[i]) as Texture2D
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(0.075, 0.075)
		s.position = Vector2(36.0, -130.0)
		twins[i].figure.add_child(s)
		_twin_kites.append(s)
		var string := Line2D.new()
		string.width = 1.0
		string.default_color = Color(0.25, 0.22, 0.2, 0.7)
		string.points = PackedVector2Array([Vector2(24.0, -100.0), Vector2(34.0, -112.0)])
		twins[i].figure.add_child(string)


# -- Performed idles ----------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	for i in _sheets.size():
		var base := _sheet_base[i]
		var centre := Vector2((base[0].x + base[1].x) * 0.5, base[2].y)
		var w := Wind.sample(centre)
		var k := w.x * 0.05 + sin(_t * 1.9 + float(i) * 1.3) * 5.0
		_sheets[i].polygon = PackedVector2Array([base[0], base[1], base[2] + Vector2(k, 0.0), base[3] + Vector2(k * 1.15, 2.0)])
	if _loose_panel != null:
		_loose_panel.rotation = -0.48 + sin(_t * 0.9) * 0.12
	if _broom != null:
		_broom.rotation = sin(_t * 2.6) * 0.28
		um_samir.figure.position.x = sin(_t * 2.6) * 3.0
	for i in _twin_kites.size():
		var s := _twin_kites[i]
		var w := Wind.sample(s.global_position)
		s.rotation = sin(_t * 1.7 + float(i) * 2.1) * 0.12 + clampf(w.x / 1200.0, -0.3, 0.3)
	if _wave_left > 0.0:
		_wave_left -= delta
		hajja.figure.arm_up = _wave_left > 0.0
	# Samir at the hem: looks at his mother, then at the street, then back.
	face_npc(samir, 1 if fmod(_t, 5.0) < 2.5 else -1)


## Hajja Amina raises a hand from her window for a moment.
func hajja_wave() -> void:
	_wave_left = 2.5


## Hajja Amina comes up through the roof hatch (Scene 6).
func hajja_to_hatch() -> void:
	hajja.position = HATCH_STAND
	hajja.visible = true
	face_npc(hajja, 1)


# -- Moving people ------------------------------------------------------------------------

## Faces a person left (-1) or right (1), whatever the Npc's own near-player flip is doing.
func face_npc(npc: Npc, dir: int) -> void:
	if dir == 0:
		return
	var holder := npc.figure.get_parent() as Node2D
	var flip := signf(holder.scale.x) if holder != null and holder.scale.x != 0.0 else 1.0
	npc.figure.scale.x = float(dir) * flip


## Walks a person along the ground toward `target_x` at `speed`, driving the figure's walk
## from the distance covered so the feet stay planted. Returns true when there.
func walk_npc(npc: Npc, target_x: float, speed: float, delta: float) -> bool:
	var fig := npc.figure
	var dx := target_x - npc.position.x
	if absf(dx) < 4.0:
		idle_npc(npc, delta)
		return true
	var step := minf(absf(dx), speed * delta)
	npc.position.x += signf(dx) * step
	face_npc(npc, int(signf(dx)))
	fig.stride = clampf(speed / 320.0, 0.25, 1.0)
	fig.phase += delta * (7.0 + 5.0 * fig.stride)
	fig.pose = Figure.Pose.WALK
	fig.airborne = false
	return false


## Eases a walking figure back to standing.
func idle_npc(npc: Npc, delta: float) -> void:
	var fig := npc.figure
	fig.stride = move_toward(fig.stride, 0.0, delta * 4.0)
	fig.pose = Figure.Pose.WALK if fig.stride > 0.02 else Figure.Pose.STAND
	fig.airborne = false


## Moves a person along a list of points (stairs, a hop onto a roof), consuming the list.
## A steep rising leg is played as a jump. Returns true when the list is empty.
func move_npc_along(npc: Npc, path: Array[Vector2], speed: float, delta: float) -> bool:
	if path.is_empty():
		idle_npc(npc, delta)
		return true
	var goal: Vector2 = path[0]
	var to := goal - npc.position
	if to.length() <= speed * delta:
		npc.position = goal
		path.pop_front()
		return move_npc_along(npc, path, speed, delta) if not path.is_empty() else false
	npc.position += to.normalized() * speed * delta
	var fig := npc.figure
	face_npc(npc, int(signf(to.x)) if absf(to.x) > 1.0 else 0)
	fig.stride = clampf(speed / 320.0, 0.4, 1.0)
	fig.phase += delta * (7.0 + 5.0 * fig.stride)
	fig.pose = Figure.Pose.WALK
	fig.airborne = to.y < -40.0 and absf(to.x) < 140.0
	return false
