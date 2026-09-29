extends Beat
## The street at night, prototype cut. The grid is gone; the only light is what people
## carry and what they share. Lit and dark windows come from data/street_windows.json and
## are the game's status display. Darkness is impassable without a flame. At alley mouths a
## draft is telegraphed and the flame must be cupped (hold interact) or it goes out, and a
## dead candle is relit at any lit window. A dark window can be lit from your flame: an act
## the street remembers. The goal is Abu Ahmad's oven.

const DATA_PATH := "res://data/street_windows.json"
const CANDLE_SCENE := preload("res://scenes/carryable.tscn")

@onready var layla: Player = $Player
@onready var abu_ahmad: Npc = $AbuAhmad
@onready var oven: Area2D = $Oven
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var facades: Node2D = $Facades
@onready var windows_node: Node2D = $Windows

var candle: Carryable = null
var data: Dictionary = {}
var windows: Array = []          # dicts with node refs and state
var darks: Array = []            # {x0, x1}
var drafts: Array = []           # {x0, x1, name, done}
var acts := 0
var blown_out := 0
var relit := 0
var delivered := false
var draft_active := false
var draft_hinted := false

var _draft_timer := 0.0
var _current_draft: Dictionary = {}
var _entry_side := 1


func _ready() -> void:
	title = "Night"
	phase = "siege_night"
	_load()
	_build()
	Look.dress()
	abu_ahmad.talked.connect(func(_n): _try_deliver())


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	_give_candle()
	hint.text = Say.text("night.hint.start")
	await get_tree().physics_frame
	var snd := get_node_or_null("/root/Sound")
	if snd != null and snd.has_method("loop"):
		snd.loop("wind_loop", "ambience", -8.0, 2.0)
		snd.loop("drone_hum_loop", "rumble", -14.0, 4.0)


func _give_candle() -> void:
	if candle != null:
		return
	candle = CANDLE_SCENE.instantiate()
	candle.label = "candle"
	candle.color = Color(0.95, 0.9, 0.8)
	candle.hookable = false
	candle.is_light_source = true
	add_child(candle)
	candle.global_position = layla.global_position + Vector2(20.0, 0.0)
	candle.pick_up(layla.hand)
	layla.carried = candle


func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
	for d in data.get("dark", []):
		darks.append({"x0": float(d["x0"]), "x1": float(d["x1"])})
	for d in data.get("drafts", []):
		drafts.append({"x0": float(d["x0"]), "x1": float(d["x1"]), "name": String(d.get("name", "")), "done": false})


func _build() -> void:
	var dark := Color(0.06, 0.055, 0.07)
	for h in data.get("houses", []):
		var poly := Polygon2D.new()
		var x0 := float(h["x0"])
		var x1 := float(h["x1"])
		var top := 900.0 - float(h["height"])
		poly.color = dark
		poly.polygon = PackedVector2Array([Vector2(x0, 900), Vector2(x0, top), Vector2(x0 + 18, top - 14), Vector2(x1 - 12, top - 14), Vector2(x1, top), Vector2(x1, 900)])
		facades.add_child(poly)
		# A water tank on most roofs.
		if int(x0) % 3 != 0:
			var tank := Polygon2D.new()
			tank.color = dark
			var tx := x0 + (x1 - x0) * 0.6
			tank.polygon = PackedVector2Array([Vector2(tx, top - 14), Vector2(tx, top - 44), Vector2(tx + 34, top - 44), Vector2(tx + 34, top - 14)])
			facades.add_child(tank)
	for w in data.get("windows", []):
		var entry := {"data": w, "lit": bool(w.get("lit", false)), "act": String(w.get("act", ""))}
		var x := float(w["x"])
		var y := float(w["y"])
		var wd := float(w["w"])
		var ht := float(w["h"])
		var pane := Polygon2D.new()
		pane.polygon = PackedVector2Array([Vector2(x, y), Vector2(x + wd, y), Vector2(x + wd, y + ht), Vector2(x, y + ht)])
		windows_node.add_child(pane)
		var light := PointLight2D.new()
		light.position = Vector2(x + wd * 0.5, y + ht * 0.5)
		light.texture = _radial()
		light.texture_scale = 3.2
		light.color = Color(1.0, 0.78, 0.5)
		light.energy = 0.9
		light.shadow_enabled = false
		windows_node.add_child(light)
		entry["pane"] = pane
		entry["light"] = light
		entry["centre"] = Vector2(x + wd * 0.5, 900.0)
		_apply_window(entry)
		windows.append(entry)


func _radial() -> Texture2D:
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
	return tex


func _apply_window(entry: Dictionary) -> void:
	var lit: bool = entry["lit"]
	(entry["pane"] as Polygon2D).color = Color(0.98, 0.76, 0.42, 0.7) if lit else Color(0.03, 0.03, 0.04, 1.0)
	(entry["light"] as PointLight2D).enabled = lit


func lit_count() -> int:
	var n := 0
	for w in windows:
		if w["lit"]:
			n += 1
	return n


func _physics_process(delta: float) -> void:
	if delivered:
		return
	_apply_darkness()
	_drafts(delta)
	if Input.is_action_just_pressed("interact") and not Say.busy:
		_interact_windows()
	if oven.overlaps_body(layla) and layla.has_light():
		_try_deliver()


## Darkness is impassable: without a flame Layla cannot move deeper into a dark stretch.
func _apply_darkness() -> void:
	layla.movement_block = 0
	if layla.has_light():
		return
	var x := layla.global_position.x
	for d in darks:
		if x > d["x0"] and x < d["x1"]:
			var centre: float = (d["x0"] + d["x1"]) * 0.5
			layla.movement_block = 1 if centre > x else -1
			if hint.text != Say.text("night.hint.dark"):
				hint.text = Say.text("night.hint.dark")
			return


## A draft at an alley mouth: telegraphed for a moment, then it takes the flame unless cupped.
func _drafts(delta: float) -> void:
	var x := layla.global_position.x
	if not draft_active:
		if not layla.has_light():
			return
		for d in drafts:
			if not d["done"] and x > d["x0"] and x < d["x1"]:
				draft_active = true
				_current_draft = d
				_draft_timer = 0.0
				_entry_side = 1 if x > (d["x0"] + d["x1"]) * 0.5 else -1
				if not draft_hinted:
					draft_hinted = true
					hint.text = Say.text("night.hint.cup")
				_gust_dust(d)
				return
		return
	_draft_timer += delta
	var window_seconds := 0.6 if Day.bot_mode else 1.4
	var cupping := Input.is_action_pressed("interact") and layla.is_active
	if _draft_timer > window_seconds:
		if not cupping and layla.has_light():
			candle.set_lit(false)
			blown_out += 1
			hint.text = Say.text("night.hint.relight")
			var snd := get_node_or_null("/root/Sound")
			if snd != null and snd.has_method("play"):
				snd.play("candle_out", "effects")
		_current_draft["done"] = true
		draft_active = false
	elif (_entry_side == 1 and x > _current_draft["x1"] + 40.0) or (_entry_side == -1 and x < _current_draft["x0"] - 40.0):
		# Stepped back the way she came before the gust: it waits for you.
		draft_active = false


func _gust_dust(d: Dictionary) -> void:
	for i in 14:
		var mote := Polygon2D.new()
		mote.color = Color(0.7, 0.65, 0.55, 0.55)
		mote.polygon = PackedVector2Array([Vector2(-2, -1), Vector2(2, -1), Vector2(2, 1), Vector2(-2, 1)])
		mote.position = Vector2(randf_range(d["x0"], d["x1"]), randf_range(700.0, 890.0))
		add_child(mote)
		var tw := create_tween()
		tw.tween_property(mote, "position", mote.position + Vector2(randf_range(120.0, 260.0), randf_range(-60.0, 20.0)), randf_range(0.6, 1.3))
		tw.parallel().tween_property(mote, "modulate:a", 0.0, randf_range(0.6, 1.3))
		tw.tween_callback(mote.queue_free)


## At a window: relight a dead candle from a lit one, or light a dark one from your flame.
func _interact_windows() -> void:
	if candle == null or layla.carried != candle:
		return
	var x := layla.global_position.x
	for w in windows:
		var centre: Vector2 = w["centre"]
		if absf(centre.x - x) > 90.0:
			continue
		if w["lit"] and not candle.lit:
			candle.set_lit(true)
			relit += 1
			hint.text = ""
			Say.key("night.neighbour.relight", 2.5)
			return
		if not w["lit"] and candle.lit and not String(w["act"]).is_empty():
			w["lit"] = true
			_apply_window(w)
			acts += 1
			hint.text = ""
			Say.key("night.umsamir.thanks", 3.0)
			Notebook.write(String(w["act"]), Say.text("notebook.night.clinic", "en"), Say.text("notebook.night.clinic", "ar"), {"act": true})
			return


func _try_deliver() -> void:
	if delivered or not layla.has_light():
		return
	if not (oven.overlaps_body(layla) or abu_ahmad.player_near):
		return
	delivered = true
	hint.text = ""
	layla.sit(false)
	await Say.key("night.abuahmad.bread")
	Notebook.write("night_bread", Say.text("notebook.night.bread", "en"), Say.text("notebook.night.bread", "ar"), {"act": true})
	finish({"bread": true, "lit_windows": lit_count(), "acts": acts, "blown_out": blown_out})
