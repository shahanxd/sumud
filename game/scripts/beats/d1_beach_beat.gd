extends Beat
## Day 1 on the beach, Scenes 3, 4 and 5 of docs/story/day1-script.md in one beat: the
## festival, the count to thirty, the promise. Layla finds Sami, crawls under the beached
## boat for the plastic bag the twins point at and ties it on as a tail; the whistle sends
## every kite on the beach up and the crowd counts to thirty while she flies against Sami's
## kite; then the two of them sit on the sand and tie a piece of his string to hers.
## Nothing can fail here: a kite that comes down goes up again and the count does not wait.

const COUNT_TO := 30
const COUNT_SECONDS := 30.0
const COUNT_SECONDS_BOT := 3.0
## Points of the tail the bag adds, behind the kite's own.
const EXTRA_TAIL_POINTS := 14

enum Stage { FIND, TALK, BAG, TIE, CONTEST, RESULT, SIT, PROMISE, DONE }

@onready var player_node: Player = $Player
@onready var kite: Kite = $Kite
@onready var sami_kite: Kite = $SamiKite
@onready var sami: Npc = $Sami
@onready var bag: Carryable = $Bag
@onready var sit_spot: Area2D = $SitSpot
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint
@onready var count_label: Label = $HUD/Count
@onready var long_tail: Line2D = $Kite/LongTail
@onready var sami_second_kite: Sprite2D = $Sami/RestingKiteB

var stage := Stage.FIND
var met := false
var crawl_said := false
var tail_tied := false
var counting := false
var count_value := 0
var winner := ""
var sat := false
var knot_ready := false
var promised := false

var _tying := false
var _bag_gone := false
var _last_tie_step := 0
var _last_knot_step := 0
var _count_words := PackedStringArray()
var _extra_tail := PackedVector2Array()
var _sami_down := 0.0


func _ready() -> void:
	title = "The kites"
	phase = "morning"
	Look.dress()
	sami.approached.connect(_on_sami_approached)
	bag.picked_up.connect(_on_bag_picked)
	long_tail.visible = false
	count_label.visible = false
	_extra_tail.resize(EXTRA_TAIL_POINTS)
	_count_words = _words_of_count()


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The Mediterranean and the onshore wind; Day 1 has no hum and no rumble.
	Sound.loop("sea_loop", "ambience", -4.0, 2.0)
	Sound.loop("wind_loop", "ambience", -8.0, 2.0)
	hint.text = Say.text("beach.hint.find")


func _bot_time(seconds: float, bot_seconds: float = 0.2) -> float:
	return bot_seconds if Day.bot_mode else seconds


# -- Scene 3: the festival ------------------------------------------------------------------

func _on_sami_approached(_npc: Npc) -> void:
	if not met:
		_meet()


func _meet() -> void:
	met = true
	stage = Stage.TALK
	hint.text = ""
	await Say.key("d1.s3.sami.01")
	await Say.key("d1.s3.layla.01")
	await Say.key("d1.s3.sami.02")
	await Say.key("d1.s3.layla.02")
	await Say.key("d1.s3.sami.03")
	# The twins shout from the boat; their lines are timed and never block.
	Say.key("d1.s3.twin.01", 3.0)
	Say.key("d1.s3.twin.02", 3.0)
	stage = Stage.BAG
	if player_node.carried == bag:
		hint.text = Say.text("d1.s3.hint.tie")
	else:
		hint.text = Say.text("d1.s3.hint.crawl")


func _on_bag_picked(_item: Carryable) -> void:
	if stage == Stage.BAG:
		hint.text = Say.text("d1.s3.hint.tie")


## Standing with the bag in hand and the kite in the other: anywhere on the sand will do.
func _can_tie() -> bool:
	return not _bag_gone and player_node.carried == bag and not player_node.crawling \
		and player_node.is_on_floor() and not kite.flying and not Say.busy


func _tie() -> void:
	_tying = true
	stage = Stage.TIE
	await hold_action("interact", 1.5, _can_tie, _on_tie_progress)
	# The bag becomes the tail: it leaves her hand and the kite's tail grows.
	player_node.carried = null
	_bag_gone = true
	bag.queue_free()
	tail_tied = true
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	hint.text = ""
	await Say.key("d1.s3.layla.04")
	await Say.key("d1.s3.sami.04")
	Notebook.write("d1_tail", Say.text("d1.note.tail", "en"), Say.text("d1.note.tail", "ar"))
	_contest()


func _on_tie_progress(p: float) -> void:
	# A rustle at each third of the knot.
	var step := int(p * 3.0)
	if step > 0 and step != _last_tie_step:
		_last_tie_step = step
		Sound.play("cloth_rustle", "effects", -10.0, 0.1)


# -- Scene 4: thirty -------------------------------------------------------------------------

func _contest() -> void:
	stage = Stage.CONTEST
	await Say.key("d1.s3.volunteer.01")
	await get_tree().create_timer(_bot_time(1.0)).timeout
	Say.key("d1.s4.volunteer.01", 2.0)
	_whistle()
	hint.text = Say.text("d1.s4.hint.fly")
	# Every kite on the beach goes up: the bystanders', Sami's, and the player's when she launches.
	var i := 0
	for node in get_tree().get_nodes_in_group("d1_flyer"):
		var ck := node as CrowdKite
		if ck != null:
			ck.launch(_bot_time(0.3 + 0.35 * float(i), 0.05 + 0.06 * float(i)))
			i += 1
	await get_tree().create_timer(_bot_time(0.8)).timeout
	_launch_sami_kite()
	await _count()
	_result()


## No whistle exists yet: a short crackle pitched far up stands in for it.
func _whistle() -> void:
	var p := Sound.play("kite_flap", "effects", -10.0)
	if p != null:
		p.pitch_scale = 6.0


func _launch_sami_kite() -> void:
	sami_second_kite.visible = false
	sami_kite.launch(1)


func _count() -> void:
	counting = true
	count_value = 0
	count_label.visible = true
	count_label.modulate.a = 1.0
	var total := COUNT_SECONDS_BOT if Day.bot_mode else COUNT_SECONDS
	Look.set_phase(1, "noon", total)
	Say.key("d1.s4.crowd.count", 3.0)
	camera.set("ground_zoom", 1.0)
	var t := 0.0
	while t < total:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		var n := clampi(int(floor(t / total * float(COUNT_TO))) + 1, 1, COUNT_TO)
		if n != count_value:
			count_value = n
			count_label.text = _count_text(n)
			_pulse_count()
		# The camera pulls back slowly while she flies; it never takes control.
		camera.set("ground_zoom", lerpf(1.0, 0.72, t / total))
		_keep_sami_kite_up(dt)
	counting = false
	count_value = COUNT_TO
	# Thirty: the roar (the birds stand in until a crowd exists), the frame comes back in.
	Sound.play("birds_leave", "effects", -4.0)
	var tw := create_tween()
	tw.tween_property(camera, "ground_zoom", 1.3, _bot_time(3.0, 0.3))
	var fade := create_tween()
	fade.tween_property(count_label, "modulate:a", 0.0, _bot_time(1.5, 0.2)).set_delay(_bot_time(1.0, 0.1))
	fade.tween_callback(count_label.hide)


## Sami's kite goes up again a second after it comes down; the count does not wait for him either.
func _keep_sami_kite_up(dt: float) -> void:
	if sami_kite.flying:
		_sami_down = 0.0
		return
	_sami_down += dt
	if _sami_down > 1.0:
		_sami_down = 0.0
		sami_kite.launch(1)


func _pulse_count() -> void:
	count_label.pivot_offset = count_label.size * 0.5
	count_label.scale = Vector2(1.18, 1.18)
	var tw := create_tween()
	tw.tween_property(count_label, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)


## The words the crowd shouts, from the count line (Arabic once the writer fills it, the
## transliteration until then); after those, the digits alone.
func _words_of_count() -> PackedStringArray:
	var out := PackedStringArray()
	var src := Say.text("d1.s4.crowd.count", "ar")
	if src.is_empty() or src == "d1.s4.crowd.count":
		src = Say.text("d1.s4.crowd.count", "en")
	for part in src.split("..."):
		var w := String(part).strip_edges()
		if not w.is_empty():
			out.append(w)
	return out


func _count_text(n: int) -> String:
	if n <= _count_words.size():
		return "%s\n%d" % [_count_words[n - 1], n]
	return str(n)


## Whichever kite is higher at thirty wins; a kite on the sand counts as the sand.
func _winner() -> String:
	var layla_y := kite.global_position.y if kite.flying else kite.ground_y
	var sami_y := sami_kite.global_position.y if sami_kite.flying else sami_kite.ground_y
	return "layla" if layla_y < sami_y else "sami"


func _result() -> void:
	stage = Stage.RESULT
	winner = _winner()
	hint.text = ""
	Say.key("d1.s4.twin.win_%s" % winner, 3.0)
	if winner == "layla":
		await Say.key("d1.s4.sami.lose")
		await Say.key("d1.s4.layla.win")
	else:
		await Say.key("d1.s4.layla.lose")
		await Say.key("d1.s4.sami.win")
		await Say.key("d1.s4.layla.tailful")
	Notebook.write("d1_count", Say.text("d1.note.count", "en"), Say.text("d1.note.count", "ar"))
	var note := "d1.note.won" if winner == "layla" else "d1.note.lost"
	Notebook.write("d1_contest", Say.text(note, "en"), Say.text(note, "ar"))
	# Both kites rest on the sand for the sit.
	if kite.flying:
		kite.reel_in()
	if sami_kite.flying:
		sami_kite.reel_in()
	stage = Stage.SIT
	hint.text = Say.text("d1.s5.hint.sit")


# -- Scene 5: the promise --------------------------------------------------------------------

func _is_sitting() -> bool:
	return player_node.sitting and not Say.busy


func _promise() -> void:
	sat = true
	stage = Stage.PROMISE
	if kite.flying:
		kite.reel_in()
	player_node.sit(true)
	player_node.facing = -1 if sami.global_position.x < player_node.global_position.x else 1
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	# The friend's voice under the sit: its placeholder pad, faint, on the voices bus.
	Sound.loop("roof_breath_loop", "voices", -14.0, 4.0)
	hint.text = ""
	await Say.key("d1.s5.sami.01")
	await Say.key("d1.s5.layla.01")
	await Say.key("d1.s5.sami.02")
	await Say.key("d1.s5.sami.03")
	await Say.key("d1.s5.layla.02")
	await Say.key("d1.s5.sami.04")
	await Say.key("d1.s5.layla.03")
	await Say.key("d1.s5.sami.07")
	await Say.key("d1.s5.sami.05")
	knot_ready = true
	hint.text = Say.text("d1.s5.hint.knot")
	# No close-up exists yet: the camera leans in on the two of them for the knot.
	var tw_in := create_tween()
	tw_in.tween_property(camera, "ground_zoom", 1.6, _bot_time(1.0))
	await hold_action("interact", 1.5, _is_sitting, _on_knot_progress)
	hint.text = ""
	var tw_out := create_tween()
	tw_out.tween_property(camera, "ground_zoom", 1.3, _bot_time(1.5))
	await Say.key("d1.s5.sami.06")
	await Say.key("d1.s5.layla.04")
	Sound.play("paper_page", "effects", -8.0)
	await Say.key("d1.s5.sami.08")
	Notebook.write("d1_promise", Say.text("d1.note.promise", "en"), Say.text("d1.note.promise", "ar"), {"act": true})
	promised = true
	player_node.sit(false)
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	Sound.stop_loop("roof_breath_loop", 2.0)
	stage = Stage.DONE
	finish({"d1_contest_winner": winner, "d1_tail_tied": true, "d1_promise": true})


func _on_knot_progress(p: float) -> void:
	var step := int(p * 4.0)
	if step > 0 and step != _last_knot_step:
		_last_knot_step = step
		Sound.play("stitch_%d" % randi_range(1, 3), "effects", -8.0, 0.1)


# -- Every frame -----------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	match stage:
		Stage.BAG:
			if player_node.crawling and not crawl_said:
				crawl_said = true
				Say.key("d1.s3.layla.03", 2.5)
			if not _tying and _can_tie() and Input.is_action_pressed("interact"):
				_tie()
		Stage.SIT:
			if not sat and sit_spot.overlaps_body(player_node) and Input.is_action_just_pressed("interact") and not Say.busy:
				_promise()


func _process(delta: float) -> void:
	_update_long_tail(delta)


## The bag's tail: a chain that trails from the end of the kite's own tail, blown by the
## wind like the rest of it. Drawn in the kite's space, since the line is its child.
func _update_long_tail(delta: float) -> void:
	var show := tail_tied and kite.flying
	long_tail.visible = show
	if not show:
		return
	var own: PackedVector2Array = kite._tail
	if own.is_empty():
		return
	var start := own[own.size() - 1]
	if _extra_tail[0].distance_to(start) > 400.0:
		for i in EXTRA_TAIL_POINTS:
			_extra_tail[i] = start
	var t := 1.0 - exp(-12.0 * delta)
	_extra_tail[0] = start
	for i in range(1, EXTRA_TAIL_POINTS):
		var target := _extra_tail[i - 1] + Vector2(0.0, 11.0) - Wind.sample(_extra_tail[i - 1]) * 0.035
		_extra_tail[i] = _extra_tail[i].lerp(target, t)
	var pts := PackedVector2Array()
	pts.resize(EXTRA_TAIL_POINTS)
	for i in EXTRA_TAIL_POINTS:
		pts[i] = kite.to_local(_extra_tail[i])
	long_tail.points = pts
