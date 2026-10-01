extends Beat
class_name D1StreetBeat
## What Day 1's two street scenes share (the morning walk and the kite run at noon). Both
## are inherited scenes of street.tscn with the Day 1 dressing added: this retires Day 4's
## things (the water truck, the jerrycan, the plank), runs the queue of barks that fire as
## Layla passes x marks and never stop her, walks the twins behind her, sets the sea's
## volume by how near the beach end she is, and clears a hint after a moment. Subclasses
## override _step() for their own rules and _on_bark() to react to a line.

const BARK_SECONDS := 3.0
const CARRY_SCENE := "res://scenes/carryable.tscn"

@onready var layla: Player = $Player
@onready var hint: Label = $HUD/Hint
@onready var camera: Camera2D = $Camera
@onready var dressing: D1StreetDressing = $Dressing

## Keys of the barks that have started, in order, for the bots.
var barks_fired: Array[String] = []
## The twins fall in behind Layla once she has passed them.
var twins_following := false
## The sea loop, whose volume follows x; null until begin().
var sea: AudioStreamPlayer = null

## [x, key] pairs still to pass, in order along the walk.
var _marks: Array = []
var _leftward := false
var _bark_queue: Array[String] = []
var _hold_barks := false
var _hint_clear_in := -1.0


func _ready() -> void:
	Look.dress()
	_retire_day4()


## A timer length: short under a bot.
func secs(s: float) -> float:
	return 0.2 if Day.bot_mode else s


func wait(s: float) -> void:
	await get_tree().create_timer(secs(s)).timeout


## The marks along the street, as [x, key] pairs in the order they are passed; `leftward`
## when the walk goes toward the left (the kite run).
func set_marks(marks: Array, leftward: bool) -> void:
	_marks = marks.duplicate()
	_leftward = leftward


## Queues a timed bark: it plays when nothing else is on screen and never stops Layla.
func bark(key: String) -> void:
	_bark_queue.append(key)


## Barks stop queuing and playing (the roof scene has its own, awaited, lines).
func hold_barks(on: bool) -> void:
	_hold_barks = on
	if on:
		_bark_queue.clear()


func clear_hint_in(s: float) -> void:
	_hint_clear_in = secs(s)


## Loudness of the sea at this x: faint by the home end, close at the steps to the sand.
func sea_db_for(x: float) -> float:
	return lerpf(-38.0, -8.0, clampf((x - 2400.0) / 2600.0, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	if _done:
		return
	var x := layla.global_position.x
	_step_marks(x)
	_pump_barks()
	if sea != null and is_instance_valid(sea):
		sea.volume_db = sea_db_for(x)
	if _hint_clear_in > 0.0:
		_hint_clear_in -= delta
		if _hint_clear_in <= 0.0:
			hint.text = ""
	if twins_following:
		_follow_twins(delta)
	_step(delta)


## Override: the scene's own rules, each physics frame while the beat runs.
func _step(_delta: float) -> void:
	pass


## Override: a bark has just started.
func _on_bark(_key: String) -> void:
	pass


func _step_marks(x: float) -> void:
	while not _marks.is_empty():
		var mark: Array = _marks[0]
		var at := float(mark[0])
		var passed := x < at if _leftward else x > at
		if not passed:
			return
		_marks.pop_front()
		bark(String(mark[1]))


func _pump_barks() -> void:
	if _hold_barks or _bark_queue.is_empty() or Say.busy:
		return
	var key: String = _bark_queue.pop_front()
	barks_fired.append(key)
	Say.key(key, BARK_SECONDS)
	_on_bark(key)


## Each twin walks toward a point behind Layla (90 and 150 px), at most 0.9 of her speed.
func _follow_twins(delta: float) -> void:
	var twins: Array[Npc] = [dressing.hassan, dressing.hussein]
	var behind: Array[float] = [90.0, 150.0]
	for i in 2:
		var goal := layla.global_position.x - float(layla.facing) * behind[i]
		dressing.walk_npc(twins[i], goal, layla.run_speed * 0.9, delta)


## Day 4's water truck, jerrycan and plank are not in this street yet: unseen, out of the
## physics space, and off the kite's list of things to snag.
func _retire_day4() -> void:
	for n in ["Truck", "Jerrycan", "Plank"]:
		var node := get_node_or_null(n)
		if node == null:
			continue
		var items: Array[Node] = node.find_children("*", "Area2D", true, false)
		if node is Area2D:
			items.append(node)
		for item in items:
			if item is Carryable:
				(item as Carryable).hookable = false
				item.remove_from_group("carryable")
		_disable_collision(node)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED


func _disable_collision(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
		elif child is CollisionPolygon2D:
			(child as CollisionPolygon2D).set_deferred("disabled", true)
		_disable_collision(child)


## A light carryable made on the spot (the sheet that comes down with the kite).
func make_carryable(label: String, color: Color, at: Vector2) -> Carryable:
	var packed: PackedScene = load(CARRY_SCENE)
	var item := packed.instantiate() as Carryable
	item.label = label
	item.weight = Carryable.Weight.LIGHT
	item.color = color
	item.hookable = false
	add_child(item)
	item.global_position = at
	return item
