extends D1StreetBeat
## Day 1, Scene 6: the kite run. Sami's string has snapped on the beach and the wind takes
## his kite inland, back up the street screen-left, past the doors Layla learned in the
## morning. The kite is the signpost: it keeps ahead of her, dipping and rising on the wind,
## and waits when she falls behind. The route asks for the jump over the pit by the bakery
## and the climb up the outside stairs at the far left onto Hajja Amina's roof, where the
## kite snags on the laundry line and brings a sheet down. She frees the kite (hold E), may
## hang the sheet back (an act the notebook keeps), Sami arrives, and the day's first answer
## choice is made. The dhuhr adhan turns the phase and the beat ends.

const START := Vector2(4880.0, 900.0)
const KITE_TEXTURE := "res://assets/props/kites/kite_3.png"
## How far ahead of Layla the kite keeps, px.
const LEAD := 600.0
const KITE_Y_MIN := 300.0
const KITE_Y_MAX := 650.0
const TAIL_POINTS := 8
## Where the twins and Sami stop chasing: the foot of the stairs.
const CHASE_STOP_X := 470.0
## Barks as she passes the doors again, in the script's order.
const MARKS: Array = [
	[2950.0, "d1.s6.abu_ahmad.01"],
	[2200.0, "d1.s6.abu_fadi.01"],
	[1500.0, "d1.s6.um_samir.01"],
]

enum KiteState { FLYING, SNAGGED, FREED }

var kite: Node2D = null
var kite_state := KiteState.FLYING
var kite_snagged := false
var kite_freed := false
## The sheet that came down with the kite, once it exists; freed when it is hung back.
var sheet_item: Carryable = null
var laundry_done := false
var fix_answer := ""
var roof_started := false
var sami_on_roof := false

var _cam_target: Node2D = null
var _cam_on_kite := false
var _kite_sprite: Sprite2D = null
var _tail_line: Line2D = null
var _tail := PackedVector2Array()
var _flap_timer := 0.4
var _free_progress := 0.0
var _t := 0.0
var _sami_path: Array[Vector2] = []
var _sami_climbing := false
var _sami_follows := true


func _ready() -> void:
	title = "The kite run"
	phase = "noon"
	super()
	_build_kite()
	_cam_target = Node2D.new()
	_cam_target.name = "CamTarget"
	add_child(_cam_target)


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	layla.global_position = START
	layla.velocity = Vector2.ZERO
	layla.facing = -1
	# Noon: the sea loud at the steps and fading up the street, the wind between the houses.
	Sound.loop("wind_loop", "ambience", -14.0, 2.0)
	sea = Sound.loop("sea_loop", "ambience", sea_db_for(START.x), 0.0)
	dressing.hajja.visible = false
	dressing.sami.visible = true
	dressing.sami.position = Vector2(START.x + 110.0, 900.0)
	dressing.face_npc(dressing.sami, -1)
	kite.position = Vector2(START.x - LEAD, 480.0)
	for i in TAIL_POINTS:
		_tail[i] = kite.position
	_cam_target.global_position = layla.global_position.lerp(kite.position, 0.4)
	camera.call("follow", _cam_target)
	_cam_on_kite = true
	hint.text = Say.text("d1.s6.hint.run")
	clear_hint_in(4.0)
	bark("d1.s6.sami.01")
	bark("d1.s6.layla.01")
	set_marks(MARKS, true)


func _build_kite() -> void:
	kite = Node2D.new()
	kite.name = "RunawayKite"
	kite.z_index = 5
	add_child(kite)
	_kite_sprite = Sprite2D.new()
	var tex: Texture2D = load(KITE_TEXTURE) as Texture2D
	if tex != null:
		_kite_sprite.texture = tex
	_kite_sprite.scale = Vector2(0.2, 0.2)
	kite.add_child(_kite_sprite)
	_tail_line = Line2D.new()
	_tail_line.width = 3.0
	_tail_line.default_color = Color(0.95, 0.92, 0.85, 0.9)
	kite.add_child(_tail_line)
	# The snapped string, a short dark thread hanging from the bridle.
	var thread := Line2D.new()
	thread.width = 1.5
	thread.default_color = Color(0.2, 0.17, 0.15, 0.9)
	thread.points = PackedVector2Array([Vector2(0.0, 10.0), Vector2(-8.0, 40.0), Vector2(-4.0, 66.0)])
	kite.add_child(thread)
	_tail.resize(TAIL_POINTS)


func _step(delta: float) -> void:
	_t += delta
	var x := layla.global_position.x
	_step_kite(delta)
	_step_camera()
	# The twins chase once she has passed them; everyone stops at the foot of the stairs.
	if not twins_following and _sami_follows and x < D1StreetDressing.TWINS_X - 40.0:
		twins_following = true
	if x < CHASE_STOP_X and (twins_following or _sami_follows):
		twins_following = false
		_sami_follows = false
		for npc in [dressing.hassan, dressing.hussein, dressing.sami]:
			dressing.idle_npc(npc as Npc, delta)
			dressing.face_npc(npc as Npc, -1)
	if _sami_follows:
		dressing.walk_npc(dressing.sami, x - float(layla.facing) * 420.0, layla.run_speed * 0.95, delta)
	if _sami_climbing:
		var speed := 2600.0 if Day.bot_mode else 520.0
		if dressing.move_npc_along(dressing.sami, _sami_path, speed, delta):
			_sami_climbing = false
			sami_on_roof = true
			dressing.face_npc(dressing.sami, int(signf(x - dressing.sami.position.x)))
	# At the roof, under the line: the kite is freed by holding interact.
	if kite_snagged and not roof_started and _near_kite():
		roof_started = true
		_roof_sequence()
	# The optional act: the sheet carried under the line and hung back with interact.
	if sheet_item != null and not laundry_done and layla.carried == sheet_item:
		if dressing.hook.overlaps_body(layla) and Input.is_action_just_pressed("interact"):
			_hang_sheet()


## The kite ahead of her: moving left toward a point LEAD ahead of her x, quicker the
## further it has fallen behind that point, drifting back slowly when she has fallen
## behind, bobbing on the wind between KITE_Y_MIN and KITE_Y_MAX; near the far left it
## sinks to the line and catches.
func _step_kite(delta: float) -> void:
	match kite_state:
		KiteState.FLYING:
			var snag := D1StreetDressing.SNAG
			var desired := layla.global_position.x - LEAD
			var dx := desired - kite.position.x
			var speed := 0.0
			if dx < 0.0:
				speed = minf(absf(dx) * 1.6 + 60.0, 560.0)
			else:
				speed = minf(dx * 0.4, 50.0)
			kite.position.x = maxf(move_toward(kite.position.x, desired, speed * delta), snag.x)
			var wind := Wind.sample(kite.position)
			var want_y := 470.0 + sin(_t * 0.6) * 110.0 + wind.y * 0.8 + sin(_t * 1.7) * 30.0
			if kite.position.x < snag.x + 420.0:
				want_y = snag.y
			want_y = clampf(want_y, KITE_Y_MIN, KITE_Y_MAX)
			kite.position.y = move_toward(kite.position.y, want_y, 170.0 * delta)
			kite.rotation = -0.38 + sin(_t * 1.3) * 0.08 + clampf(wind.x / 1500.0, -0.2, 0.2)
			_flap(delta)
			if kite.position.x <= snag.x + 0.5 and absf(kite.position.y - snag.y) < 6.0:
				kite_state = KiteState.SNAGGED
				kite_snagged = true
				Sound.play("cloth_rustle", "effects", -4.0, 0.1)
		KiteState.SNAGGED:
			var snag := D1StreetDressing.SNAG
			kite.position = snag + Vector2(sin(_t * 2.1) * 4.0, 0.0)
			kite.rotation = PI * 0.82 + sin(_t * 2.3) * 0.12 + sin(_t * 31.0) * 0.25 * _free_progress
		KiteState.FREED:
			kite.global_position = layla.hand.global_position + Vector2(0.0, 12.0)
			kite.rotation = 0.5 * float(layla.facing)
	_update_tail(delta)


func _flap(delta: float) -> void:
	_flap_timer -= delta
	if _flap_timer > 0.0:
		return
	var speed := Wind.sample(kite.global_position).length()
	var strong := clampf((speed - 60.0) / 300.0, 0.0, 1.0)
	_flap_timer = clampf(lerpf(1.7, 1.1, strong) + randf_range(-0.08, 0.08), 1.1, 1.7)
	Sound.play_at("kite_flap", kite.global_position, "effects", -8.0, 0.12)


func _update_tail(delta: float) -> void:
	var t := 1.0 - exp(-14.0 * delta)
	var root := kite.to_global(Vector2(0.0, 56.0 * kite.scale.y))
	_tail[0] = root
	for i in range(1, TAIL_POINTS):
		var target := _tail[i - 1] + Vector2(0.0, 9.0) - Wind.sample(_tail[i - 1]) * 0.03
		_tail[i] = _tail[i].lerp(target, t)
	var pts := PackedVector2Array()
	pts.resize(TAIL_POINTS)
	for i in TAIL_POINTS:
		pts[i] = kite.to_local(_tail[i])
	_tail_line.points = pts


## The camera leads toward the kite through the run, and comes back to her at the stairs.
func _step_camera() -> void:
	if _cam_on_kite:
		_cam_target.global_position = layla.global_position.lerp(kite.global_position, 0.4) + Vector2(0.0, -40.0)
		if kite_snagged and layla.global_position.x < CHASE_STOP_X + 200.0:
			_cam_on_kite = false
			camera.call("follow", layla)


## True when she stands on the roof under the hanging kite.
func _near_kite() -> bool:
	return layla.global_position.y < 620.0 and layla.global_position.distance_to(kite.global_position) < 170.0


func _on_free_progress(t: float) -> void:
	_free_progress = t


func _roof_sequence() -> void:
	hold_barks(true)
	hint.text = Say.text("d1.s6.hint.free")
	await hold_action("interact", 1.2, _near_kite, _on_free_progress)
	_free_kite()
	hint.text = ""
	await wait(0.5)
	# Hajja Amina comes up through her hatch to see who is dancing on her roof.
	dressing.hajja_to_hatch()
	Sound.play("door_wood", "effects", -8.0, 0.05)
	await Say.key("d1.s6.hajja.01")
	await Say.key("d1.s6.layla.02")
	await Say.key("d1.s6.hajja.02")
	if not laundry_done:
		hint.text = Say.text("d1.s6.hint.sheet")
	_sami_climb()
	while _sami_climbing:
		await get_tree().physics_frame
	await Say.key("d1.s6.sami.02")
	await Say.key("d1.s6.layla.03")
	await Say.key("d1.s6.sami.03")
	# The first answer choice: never timed; she stands still to answer.
	layla.is_active = false
	var pick: int = await Say.choose(["d1.s6.layla.04", "d1.s6.layla.05"])
	layla.is_active = true
	await Say.key("d1.s6.sami.04" if pick == 0 else "d1.s6.sami.05")
	fix_answer = "practice" if pick == 0 else "better"
	var note := "d1.note.fix_practice" if pick == 0 else "d1.note.fix_better"
	Notebook.write("d1_fix_answer", Say.text(note, "en"), Say.text(note, "ar"))
	Notebook.write("d1_kite_run", Say.text("d1.note.run", "en"), Say.text("d1.note.run", "ar"))
	await _grace()
	hint.text = ""
	# The dhuhr adhan from the minaret: the hook for the recording, the phase turning.
	await adhan(1, "noon", 6.0)
	finish({"d1_fix_answer": fix_answer, "d1_amina_laundry": laundry_done})


## The kite comes off the line into her hands; the sheet it tore loose drops to the roof.
func _free_kite() -> void:
	kite_state = KiteState.FREED
	kite_freed = true
	_free_progress = 0.0
	kite.scale = Vector2(0.6, 0.6)
	Sound.play("grab", "effects", 0.0, 0.05)
	dressing.sheet_mid.visible = false
	# It falls at her feet, a step to the side, wherever on the roof she stood to reach.
	var at_x := clampf(layla.global_position.x + 44.0 * float(layla.facing), D1StreetDressing.ROOF_LEFT + 40.0, D1StreetDressing.ROOF_RIGHT - 40.0)
	sheet_item = make_carryable("sheet", Color(0.78, 0.76, 0.72), Vector2(at_x, D1StreetDressing.ROOF_Y))
	sheet_item.dropped.connect(_on_sheet_dropped)
	Sound.play("cloth_rustle", "effects", -2.0, 0.1)


func _on_sheet_dropped(_item: Carryable, at: Vector2) -> void:
	if laundry_done:
		return
	var snag := D1StreetDressing.SNAG
	if absf(at.x - snag.x) < 95.0 and at.y < 640.0:
		_hang_sheet()


## The sheet goes back on the line: the act Hajja Amina remembers.
func _hang_sheet() -> void:
	if laundry_done or sheet_item == null:
		return
	laundry_done = true
	if layla.carried == sheet_item:
		layla.carried = null
	sheet_item.queue_free()
	sheet_item = null
	dressing.sheet_mid.visible = true
	Sound.play("cloth_rustle", "effects", -2.0, 0.1)
	hint.text = ""
	Say.key("d1.s6.hajja.03", 4.0)
	Notebook.write("d1_amina_sheet", Say.text("d1.note.amina", "en"), Say.text("d1.note.amina", "ar"), {"act": true})


## Sami comes up the stairs the way she did: along the ground, up the flight, over onto the roof.
func _sami_climb() -> void:
	var roof_y := D1StreetDressing.ROOF_Y
	var landing_y := D1StreetDressing.LANDING_Y
	_sami_path = [
		Vector2(D1StreetDressing.STAIR_FOOT_X, 900.0),
		Vector2(-60.0, landing_y),
		Vector2(-109.0, landing_y),
		Vector2(-178.0, roof_y),
		Vector2(-250.0, roof_y),
	]
	_sami_climbing = true


## A moment for the sheet if it is still down: the hint stays, the kite waits in her hand.
func _grace() -> void:
	if laundry_done:
		return
	var left := secs(6.0)
	while left > 0.0 and not laundry_done:
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
