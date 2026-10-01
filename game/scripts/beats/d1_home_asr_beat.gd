extends Beat
## Day 1 at asr, Scene 7 of docs/story/day1-script.md: the power comes on. Layla comes in from
## the street; Mama has her lists, Teta her knafeh, Karim his sleep, Baba his net. The grid's
## half day arrives on schedule: the bulb, the fan, the windows across the street, the cheer
## outside. Layla takes a little of Nour's dress thread from the sewing tin, climbs to the
## roof, and stitches Sami's torn kite across the gap to his family's roof while he holds the
## spars; then a test flight in the asr wind, and Um Sami calling him down for the bread.

enum Stage { HOUSE, MEETING, STITCH, TEST, FLYING, DONE }

const FAN_SPEED := 9.0
const FLY_SECONDS := 2.0

@onready var layla: Player = $Player
@onready var baba: Player = $Baba
@onready var teta: Npc = $Teta
@onready var karim: Npc = $Karim
@onready var sami: Npc = $Sami
@onready var spool: Carryable = $Spool
@onready var patched_kite: Kite = $PatchedKite
@onready var gap_spot: Area2D = $GapSpot
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var lights: Node2D = $House/Lights
@onready var bulb_light: PointLight2D = $House/Lights/BulbLight
@onready var fan_blades: Node2D = $Fan/Blades
@onready var street_windows: Node2D = $StreetWindows
@onready var tear: Polygon2D = $Sami/TornKite/Tear
@onready var stitch_line: Line2D = $Sami/TornKite/Stitch

var stage := Stage.HOUSE
var power_on := false
var fan_speed := 0.0
var karim_awake := false
var teta_warned := false
var thread_taken := false
var gap_met := false
var sami_waiting := false
var stitched := false
var flown := false

var _stitching := false
var _stitch_step := 0
var _fly_t := 0.0
var _bulb_energy := 0.0
var _stitch_points := PackedVector2Array()


func _ready() -> void:
	title = "The power"
	phase = "noon"
	Look.set_phase(1, phase, 0.0)
	Look.dress()
	baba.is_active = false
	# The grid is off when she comes in: no bulb, no fan, dark windows.
	_bulb_energy = bulb_light.energy
	lights.visible = false
	bulb_light.energy = 0.0
	for child in street_windows.get_children():
		var w := child as Polygon2D
		if w != null:
			w.color.a = 0.0
	stitch_line.visible = false
	spool.picked_up.connect(_on_spool_taken)
	hint.text = Say.text("d1.s7.hint.thread")


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The wind over the house, faint. Day 1: no hum, no rumble.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)
	Sound.play("door_wood", "effects", -6.0)
	_barks()
	_power()


func _bot_time(seconds: float, bot_seconds: float = 0.2) -> float:
	return bot_seconds if Day.bot_mode else seconds


## The house talks as she passes: timed, queued, never blocking.
func _barks() -> void:
	await get_tree().create_timer(_bot_time(1.0)).timeout
	Say.key("d1.s7.mama.01", 3.5)
	Say.key("d1.s7.layla.01", 2.5)
	Say.key("d1.s7.mama.02", 3.5)


# -- The power -------------------------------------------------------------------------------

func _power() -> void:
	await get_tree().create_timer(_bot_time(4.0, 0.5)).timeout
	if _done:
		return
	power_on = true
	lights.visible = true
	var tw := create_tween()
	tw.tween_property(bulb_light, "energy", _bulb_energy, _bot_time(1.2))
	fan_speed = 0.01
	var fan_tw := create_tween()
	fan_tw.tween_property(self, "fan_speed", FAN_SPEED, _bot_time(3.0))
	var i := 0
	for child in street_windows.get_children():
		var w := child as Polygon2D
		if w == null:
			continue
		var wt := create_tween()
		wt.tween_property(w, "color:a", 0.55, _bot_time(0.8)).set_delay(_bot_time(0.3 + 0.35 * float(i), 0.05 * float(i)))
		i += 1
	Say.key("d1.s7.kids.01", 3.0)
	_karim_wakes()


func _karim_wakes() -> void:
	await get_tree().create_timer(_bot_time(1.5)).timeout
	if _done:
		return
	karim_awake = true
	var tw := create_tween()
	tw.tween_property(karim, "rotation", 0.0, _bot_time(0.9)).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(karim, "position", Vector2(1340.0, 900.0), _bot_time(0.9))
	Say.key("d1.s7.karim.01", 3.5)
	await get_tree().create_timer(_bot_time(3.0, 0.3)).timeout
	if _done:
		return
	# Nobody answers him.
	Say.key("d1.s7.karim.02", 3.5)


# -- The thread ------------------------------------------------------------------------------

func _on_spool_taken(_item: Carryable) -> void:
	if thread_taken:
		return
	hint.text = ""
	Say.key("d1.s7.teta.02", 3.0)
	Say.key("d1.s7.layla.02", 2.0)
	Say.key("d1.s7.teta.03", 3.0)
	await Say.key("d1.s7.teta.04")
	thread_taken = true
	Notebook.write("d1_thread", Say.text("d1.note.thread", "en"), Say.text("d1.note.thread", "ar"))
	if stage == Stage.HOUSE:
		hint.text = Say.text("home.hint.roof")


func _has_spool() -> bool:
	return is_instance_valid(spool) and layla.carried == spool


# -- The roofs -------------------------------------------------------------------------------

func _meet_sami() -> void:
	gap_met = true
	stage = Stage.MEETING
	hint.text = ""
	await Say.key("d1.s7.sami.01")
	await Say.key("d1.s7.layla.03")
	await Say.key("d1.s7.sami.02")
	await Say.key("d1.s7.layla.04")
	await Say.key("d1.s7.sami.03")
	stage = Stage.STITCH
	hint.text = Say.text("d1.s7.hint.stitch")


func _at_gap_with_spool() -> bool:
	return _has_spool() and gap_spot.overlaps_body(layla) and layla.is_on_floor() and not Say.busy


func _stitch() -> void:
	_stitching = true
	await hold_action("interact", 2.0, _at_gap_with_spool, _on_stitch_progress)
	# The thread is used up; the tear closes under a row of stitches.
	layla.carried = null
	spool.queue_free()
	tear.visible = false
	stitch_line.visible = true
	stitched = true
	stage = Stage.TEST
	hint.text = Say.text("d1.s7.hint.test")


func _on_stitch_progress(p: float) -> void:
	var step := int(p * 6.0)
	if step > _stitch_step:
		_stitch_step = step
		Sound.play("stitch_%d" % randi_range(1, 3), "effects", -6.0, 0.1)
		# The stitches appear one by one along the tear.
		var n := clampi(2 + step, 2, stitch_line.get_point_count())
		stitch_line.visible = true
		stitch_line.modulate.a = 1.0
		_show_stitches(n)


func _show_stitches(n: int) -> void:
	if _stitch_points.is_empty():
		_stitch_points = stitch_line.points.duplicate()
	stitch_line.points = _stitch_points.slice(0, n)


## The test flight: once the patched kite has been up two seconds, Sami sees it fly, Um Sami
## calls from below, and he answers with Layla's own line from the morning.
func _test_flight() -> void:
	stage = Stage.FLYING
	hint.text = ""
	await Say.key("d1.s7.sami.04")
	await Say.key("d1.s7.um_sami.01")
	await Say.key("d1.s7.sami.05")
	if patched_kite.flying:
		patched_kite.reel_in()
	flown = true
	# Sami goes down with his kite.
	var tw := create_tween()
	tw.tween_property(sami, "position:x", sami.position.x + 240.0, _bot_time(2.0, 0.3))
	tw.tween_callback(sami.hide)
	await tw.finished
	await get_tree().create_timer(_bot_time(1.0)).timeout
	# The asr light yellows toward maghrib: the adhan as a phase turn.
	await adhan(1, "dusk", 6.0)
	stage = Stage.DONE
	finish({"d1_thread_taken": true, "d1_kite_patched": true})


# -- Every frame -----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if fan_speed > 0.0:
		fan_blades.rotation += fan_speed * delta


func _physics_process(delta: float) -> void:
	if power_on and not teta_warned and layla.global_position.distance_to(teta.global_position) < 150.0:
		teta_warned = true
		Say.key("d1.s7.teta.01", 3.0)
	match stage:
		Stage.HOUSE:
			if gap_spot.overlaps_body(layla):
				if _has_spool():
					_meet_sami()
				elif not sami_waiting:
					# Without the thread Sami only sees what she has not brought, and waits.
					sami_waiting = true
					Say.key("d1.s7.sami.01", 3.0)
		Stage.STITCH:
			if not _stitching and _at_gap_with_spool() and Input.is_action_pressed("interact"):
				_stitch()
		Stage.TEST:
			if patched_kite.flying:
				_fly_t += delta
				if _fly_t >= _bot_time(FLY_SECONDS, 0.3):
					_test_flight()
			else:
				_fly_t = 0.0
