extends Beat
class_name D1HomeBeat
## Shared ground for the Day 1 beats that play in the home and on its roof (fajr, maghrib,
## isha). Their scenes inherit home.tscn; this script holds what they share: the hatch
## (press down over the roof hatch, or over the stairwell on the first floor, to drop through
## the one-way well, so the stairs can be walked down as well as up), the pigeons on the
## tank, Mishmish the cat, Baba's net, and a record of every line key the beat has fired
## so the bots can read what was said.

## Where on the roof the hatch is (x range over the one-way RoofWell), and where on the first
## floor the stairwell is (x range over FloorFirstWell).
const HATCH_X := Vector2(900.0, 985.0)
const STAIRWELL_X := Vector2(1150.0, 1340.0)
## The top of the water tank, where the pigeons stand.
const TANK_TOP := 440.0
const TANK_X := Vector2(1006.0, 1054.0)

@onready var layla: Player = $Player
@onready var baba: Player = $Baba
@onready var teta: Npc = $Teta
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var lights: Node2D = $House/Lights
@onready var parapet: Node2D = $House/Parapet
@onready var card_view: Node2D = $CardView
@onready var hatch: Node2D = $Hatch
@onready var sit_spot: Area2D = $SitSpot
@onready var street_door: Area2D = $StreetDoor
@onready var roof_well: CollisionPolygon2D = $House/Structure/RoofWell
@onready var floor_well: CollisionPolygon2D = $House/Structure/FloorFirstWell

## Every line key this beat has fired, in order.
var said: Array[String] = []
var pigeons: Array[Polygon2D] = []
var cat: Node2D = null
## While true the cat flicks its tail and shifts about; a beat sets it false to make it stop.
var cat_moving := false
## How many times she has dropped through a hatch.
var drops := 0

var _open_well: CollisionPolygon2D = null
var _open_since := 0.0
var _cat_home := Vector2.ZERO
var _cat_tail: Polygon2D = null


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The runner sets the phase before begin(); a bot running the scene alone has not.
	Look.set_phase(1, phase, 0.0)


func _physics_process(delta: float) -> void:
	_hatch_step(delta)
	_tick(delta)


## Per-frame logic of the beat itself. Override.
func _tick(_delta: float) -> void:
	pass


## A dialogue line, waited for (interact advances it).
func _say(k: String) -> void:
	said.append(k)
	await Say.key(k)


## A bark: shown for `seconds`, never blocking play. Awaitable only to keep a group in order.
func _bark(k: String, seconds: float) -> void:
	said.append(k)
	await Say.key(k, seconds)


func _wait(seconds: float, bot_seconds: float = 0.2) -> void:
	await get_tree().create_timer(bot_seconds if Day.bot_mode else seconds).timeout


## True once the beat is over or gone; coroutines that loop check it after every await.
func _closed() -> bool:
	return _done or not is_inside_tree()


# -- The hatch ---------------------------------------------------------------------------

## The wells in the roof and the first floor are one-way so the stairs can be climbed; held
## down over the hatch (or the stairwell) opens the well under her for a moment so she drops
## onto the flight below. Nothing else changes: walking up is as it was.
func _hatch_step(delta: float) -> void:
	if _open_well != null:
		_open_since += delta
		if layla.global_position.y > _well_top(_open_well) + 30.0 or _open_since > 0.7:
			_open_well.disabled = false
			_open_well = null
		return
	if not layla.is_active or layla.sitting or layla.kite_mode() or not layla.is_on_floor():
		return
	if not Input.is_action_pressed("move_down"):
		return
	var p := layla.global_position
	if absf(p.y - _well_top(roof_well)) < 6.0 and p.x > HATCH_X.x and p.x < HATCH_X.y:
		_open(roof_well)
	elif absf(p.y - _well_top(floor_well)) < 6.0 and p.x > STAIRWELL_X.x and p.x < STAIRWELL_X.y:
		_open(floor_well)


func _open(well: CollisionPolygon2D) -> void:
	_open_well = well
	_open_since = 0.0
	well.disabled = true
	drops += 1
	Sound.step("concrete", -6.0)


func _well_top(well: CollisionPolygon2D) -> float:
	var top := INF
	for p in well.polygon:
		top = minf(top, p.y)
	return top + well.global_position.y


# -- Dressing: pigeons, the cat, the net ---------------------------------------------------

## Pigeons on the water tank: small dark shapes that shift now and then.
func make_pigeons(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in count:
		var bird := Polygon2D.new()
		bird.color = Color(0.07, 0.06, 0.08)
		bird.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(-7, -4), Vector2(-3, -7), Vector2(3, -7), Vector2(6, -5),
			Vector2(8, -9), Vector2(10, -8), Vector2(9, -4), Vector2(7, -2), Vector2(6, 0),
		])
		bird.position = Vector2(lerpf(TANK_X.x, TANK_X.y, (float(i) + 0.5) / float(count)) + rng.randf_range(-3.0, 3.0), TANK_TOP)
		bird.scale.x = 1.0 if rng.randf() < 0.5 else -1.0
		bird.z_index = 1
		add_child(bird)
		pigeons.append(bird)
	_pigeon_life()


func _pigeon_life() -> void:
	while not _closed():
		await _wait(randf_range(2.0, 5.0), randf_range(0.2, 0.5))
		if _closed() or pigeons.is_empty():
			return
		var bird := pigeons[randi() % pigeons.size()]
		var to := clampf(bird.position.x + randf_range(-14.0, 14.0), TANK_X.x, TANK_X.y)
		bird.scale.x = 1.0 if to > bird.position.x else -1.0
		var tw := create_tween()
		tw.tween_property(bird, "position:y", TANK_TOP - 3.0, 0.08)
		tw.parallel().tween_property(bird, "position:x", to, 0.3)
		tw.tween_property(bird, "position:y", TANK_TOP, 0.1)


## Mishmish: a small dark shape at someone's feet, tail flicking, winding from side to side.
func make_cat(at: Vector2) -> void:
	cat = Node2D.new()
	cat.name = "Cat"
	cat.position = at
	_cat_home = at
	var body := Polygon2D.new()
	body.color = Color(0.08, 0.07, 0.09)
	body.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(-18, -6), Vector2(-12, -12), Vector2(0, -13), Vector2(10, -11),
		Vector2(14, -17), Vector2(16, -21), Vector2(19, -17), Vector2(21, -12), Vector2(19, -7),
		Vector2(14, -3), Vector2(12, 0),
	])
	cat.add_child(body)
	_cat_tail = Polygon2D.new()
	_cat_tail.name = "Tail"
	_cat_tail.color = body.color
	_cat_tail.position = Vector2(-16, -7)
	_cat_tail.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(-4, -6), Vector2(-7, -14), Vector2(-5, -16), Vector2(-1, -9), Vector2(3, -2),
	])
	cat.add_child(_cat_tail)
	add_child(cat)
	cat_moving = true
	_cat_life()


func _cat_life() -> void:
	while not _closed():
		await _wait(randf_range(0.7, 1.8), randf_range(0.1, 0.3))
		if _closed() or cat == null or not cat_moving:
			continue
		var tw := create_tween()
		tw.tween_property(_cat_tail, "rotation", randf_range(-0.5, 0.5), 0.25)
		if randf() < 0.4:
			var to := _cat_home + Vector2(randf_range(-36.0, 36.0), 0.0)
			cat.scale.x = 1.0 if to.x > cat.position.x else -1.0
			tw.parallel().tween_property(cat, "position", to, 0.5)


## Baba's net: a dark heap beside where he sits, with a few pale knots.
func make_net(at: Vector2) -> void:
	var heap := Polygon2D.new()
	heap.name = "Net"
	heap.color = Color(0.17, 0.19, 0.21)
	heap.position = at
	heap.polygon = PackedVector2Array([
		Vector2(-34, 0), Vector2(-28, -10), Vector2(-14, -18), Vector2(2, -22), Vector2(18, -16),
		Vector2(30, -8), Vector2(36, 0),
	])
	add_child(heap)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for _i in 7:
		var knot := Polygon2D.new()
		knot.color = Color(0.5, 0.5, 0.46, 0.8)
		var c := Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(-14.0, -4.0))
		knot.polygon = PackedVector2Array([c + Vector2(-1.5, 0), c + Vector2(0, -1.5), c + Vector2(1.5, 0), c + Vector2(0, 1.5)])
		heap.add_child(knot)
