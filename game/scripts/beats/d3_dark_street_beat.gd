extends "res://scripts/beats/night_street_beat.gd"
## Day 3, Scene 7 of docs/story/day3-script.md: the dark street. Layla leaves Abu Ahmad's
## oven with the candle and a tray of bread for four doors: the twins, Um Samir's clinic,
## Hajja Amina, Abu Khalil by the steps to the sea. Any order. At a door, interact: the
## family answers from inside, their window lights, a loaf leaves the tray. The street's
## darkness, drafts and windows work as in the night street; a dead candle relights at any
## lit window, and a door she has fed lights it too. Done when every door has bread, or
## when three have and she is back at the oven.

const BREAD := 4
## The doors, with the dark window beside each (by the window's centre x in the street data)
## and the line keys spoken from inside.
const DOORS: Array[Dictionary] = [
	{"id": "twins", "node": "Doors/TwinsDoor", "window_x": 2000.0, "lines": ["d3.s7.twin.01", "d3.s7.twin.02", "d3.s7.layla.01"]},
	{"id": "clinic", "node": "Doors/ClinicDoor", "window_x": 2270.0, "lines": ["d3.s7.um_samir.01"]},
	{"id": "hajja_amina", "node": "Doors/HajjaDoor", "window_x": 2640.0, "lines": ["d3.s7.hajja.01"]},
	{"id": "abu_khalil", "node": "Doors/AbuKhalilDoor", "window_x": 3840.0, "lines": ["d3.s7.abu_khalil.01"]},
]
const LOAF := Color(0.85, 0.72, 0.45)
const TRAY := Color(0.3, 0.26, 0.2)

## The doors in the order she fed them, by id.
var order: Array[String] = []
var bread_left := BREAD
var doors_done := 0
## Every line key this beat has fired, in order.
var said: Array[String] = []
## True while a door's lines run.
var delivering := false

var _doors: Array[Dictionary] = []
var _bread_label: Label = null
var _tray: Node2D = null
var _loaves: Array[Polygon2D] = []


func _ready() -> void:
	super._ready()
	title = "The dark street"
	phase = "siege_night"
	Look.set_phase(3, phase, 0.0)
	Look.dress()
	_register_abu_khalil_window()
	for d in DOORS:
		var area := get_node(String(d["node"])) as Area2D
		_doors.append({
			"id": String(d["id"]), "area": area, "lines": d["lines"],
			"window": _window_at(float(d["window_x"])), "done": false,
		})
	_build_hud()


func begin(ctx: Dictionary) -> void:
	# The candle and the wind from the night street; after the bang, no hum.
	super.begin(ctx)
	hint.text = Say.text("d3.s7.hint.start")
	_build_tray()
	_update_bread()


func _say(k: String) -> void:
	said.append(k)
	await Say.key(k)


func _closed() -> bool:
	return _done or not is_inside_tree()


# -- The set ---------------------------------------------------------------------------------

## Abu Khalil's window, on the house by the steps, joins the street's windows: dark tonight.
func _register_abu_khalil_window() -> void:
	var pane := get_node_or_null("AbuKhalilRoof/Window") as Polygon2D
	if pane == null:
		return
	var light := PointLight2D.new()
	light.position = Vector2(3840.0, 790.0)
	light.texture = _radial()
	light.texture_scale = 3.2
	light.color = Color(1.0, 0.78, 0.5)
	light.energy = 0.9
	light.shadow_enabled = false
	windows_node.add_child(light)
	var entry := {"data": {}, "lit": false, "act": "", "pane": pane, "light": light, "centre": Vector2(3840.0, 900.0)}
	_apply_window(entry)
	windows.append(entry)


func _window_at(x: float) -> Dictionary:
	for w in windows:
		var centre: Vector2 = w["centre"]
		if absf(centre.x - x) < 1.0:
			return w
	return {}


func _build_hud() -> void:
	_bread_label = Label.new()
	_bread_label.name = "Bread"
	_bread_label.label_settings = hint.label_settings
	_bread_label.offset_left = 32.0
	_bread_label.offset_top = 56.0
	_bread_label.offset_right = 600.0
	_bread_label.offset_bottom = 92.0
	$HUD.add_child(_bread_label)


## The tray in her other hand: a flat board with the loaves on it, behind the figure.
func _build_tray() -> void:
	if _tray != null:
		return
	_tray = Node2D.new()
	_tray.name = "Tray"
	_tray.z_index = -1
	_tray.position = Vector2(-12.0, -48.0)
	var board := Polygon2D.new()
	board.color = TRAY
	board.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(20, 0), Vector2(18, 4), Vector2(-18, 4)])
	_tray.add_child(board)
	for i in BREAD:
		var loaf := Polygon2D.new()
		loaf.color = LOAF
		var pts := PackedVector2Array()
		var c := Vector2(-12.0 + 8.0 * float(i), -3.0 - 2.0 * float(i % 2))
		for k in 10:
			var a := TAU * float(k) / 10.0
			pts.append(c + Vector2(cos(a) * 7.0, sin(a) * 3.0))
		loaf.polygon = pts
		_tray.add_child(loaf)
		_loaves.append(loaf)
	layla.visual.add_child(_tray)


func _update_bread() -> void:
	if _bread_label != null:
		_bread_label.text = "bread: %d" % bread_left
	for i in _loaves.size():
		_loaves[i].visible = i < bread_left


# -- Every frame ----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# The street's own draft hint is tonight's: the dust shows it.
	if hint.text == Say.text("night.hint.cup"):
		hint.text = Say.text("d3.s7.hint.draft")


func _door_near() -> Dictionary:
	for d in _doors:
		if not bool(d["done"]) and (d["area"] as Area2D).overlaps_body(layla):
			return d
	return {}


## Interact: a door she has not fed comes first; otherwise the street's windows as before.
func _interact_windows() -> void:
	if not delivering:
		var door := _door_near()
		if not door.is_empty():
			_deliver(door)
			return
	super._interact_windows()


# -- The doors --------------------------------------------------------------------------------

func _deliver(door: Dictionary) -> void:
	delivering = true
	door["done"] = true
	doors_done += 1
	var id := String(door["id"])
	order.append(id)
	bread_left = maxi(bread_left - 1, 0)
	_update_bread()
	hint.text = ""
	var w: Dictionary = door["window"]
	if not w.is_empty() and not bool(w["lit"]):
		w["lit"] = true
		_apply_window(w)
		acts += 1
	if candle != null and not candle.lit:
		# A door with light in it lights hers again: no dead end in the dark.
		candle.set_lit(true)
		relit += 1
	var lines: Array = door["lines"]
	for k in lines:
		await _say(String(k))
		if _closed():
			return
	Notebook.write("d3_bread_" + id, Say.text("d3.note.doors", "en") + " " + id, "", {"act": true})
	Notebook.write("d3_doors", Say.text("d3.note.doors", "en") + " " + ", ".join(order), "")
	delivering = false
	if doors_done < _doors.size():
		hint.text = Say.text("d3.s7.hint.start")
	_try_deliver()


## Over when every door has bread, or when three have and she is back at the oven.
func _try_deliver() -> void:
	if delivered or delivering or doors_done < 3:
		return
	if doors_done < _doors.size() and not (oven.overlaps_body(layla) or abu_ahmad.player_near):
		return
	delivered = true
	hint.text = ""
	finish({"d3_bread_order": order, "lit_windows": lit_count(), "blown_out": blown_out})
