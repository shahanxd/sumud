extends Beat
## Day 3 at isha, Scene 6 of docs/story/day3-script.md: bread. The bakery's power is dead
## and its back room half collapsed; flour under the rubble, a beam across the oven door,
## the hand-cranked machine. Three characters, switching: Layla crawls into the back room
## for two flour sacks, Baba lifts the beam off the oven door, Teta walks to Abu Ahmad and
## persuades him. Sami holds the candle, the room's only light besides Layla's. Any order;
## nothing fails. Then Abu Ahmad cranks by candlelight, Sami counts the turns, and the
## hadith of the one sheet is held on the oven mouth.

const CANDLE_SCENE := preload("res://scenes/carryable.tscn")
const SACKS_NEEDED := 2
const GLOW_ENERGY := 2.0
const MOUTH_WARM := Color(1.0, 0.55, 0.2, 0.85)
## Radians per second of the crank while the machine runs.
const CRANK_SPEED := 5.0
## Left of this x Layla is inside the back room (the crawl gap is at 880..960).
const BACK_ROOM_X := 880.0

@onready var layla: Player = $Player
@onready var baba: Player = $Baba
@onready var teta: Player = $Teta
@onready var abu_ahmad: Npc = $AbuAhmad
@onready var sami: Npc = $Sami
@onready var beam: Beam = $Beam
@onready var hopper: Area2D = $Hopper
@onready var handle: Node2D = $Machine/Handle
@onready var glow: PointLight2D = $Oven/Glow
@onready var mouth: Polygon2D = $Oven/Mouth
@onready var oven_view: Node2D = $OvenView
@onready var tray: Node2D = $Tray
@onready var camera: Camera2D = $Camera
@onready var hint: Label = $HUD/Hint

var candle: Carryable = null
var sacks: Array[Carryable] = []
var active: Player = null
var switch_enabled := false
var sacks_in := 0
var oven_clear := false
var persuaded := false
var baking := false
var card_shown := false
var cat_seen := false
var baba_spoke := false
var cranking := false
var turns := 0

var _talking := false
var _switched_once := false
var _crank_angle := 0.0


func _ready() -> void:
	title = "Bread"
	phase = "siege_night"
	Look.dress()
	baba.is_active = false
	teta.is_active = false
	active = layla
	# The oven is cold under the beam; the mouth is a dark hole until the baking starts.
	glow.energy = 0.0
	mouth.color = Color(0.08, 0.06, 0.06, 1.0)
	tray.visible = false
	# The beam leans over the oven mouth in the back wall, not across the walkway: it blocks
	# the oven, never the room, so the three tasks can be done in any order.
	beam.block.collision_layer = 0
	beam.lifted.connect(_on_beam_lifted)
	for node in [$Sack1, $Sack2]:
		var sack := node as Carryable
		if sack != null:
			sacks.append(sack)
	abu_ahmad.talked.connect(_on_abu_ahmad_talked)


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	_give_candle()
	# After the bang only the wind. No hum, no grid, no oven yet.
	Sound.loop("wind_loop", "ambience", -16.0, 2.0)
	Sound.play("door_wood", "effects", -8.0)
	_opening()


func _bot_time(seconds: float, bot_seconds: float = 0.2) -> float:
	return bot_seconds if Day.bot_mode else seconds


## The candle from under the stairs, lit, in Layla's hand (as the night street gives it).
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


# -- The opening -----------------------------------------------------------------------------

func _opening() -> void:
	await get_tree().create_timer(_bot_time(0.8, 0.1)).timeout
	if _done:
		return
	await Say.key("d3.s6.abu_ahmad.01")
	Say.key("d3.s6.sami.01", 3.0)
	switch_enabled = true
	_refresh_hint()


# -- Switching -------------------------------------------------------------------------------

## Tab cycles Layla, Baba, Teta. Only one reads input; the camera follows that one.
func _switch() -> void:
	var order: Array[Player] = [layla, baba, teta]
	var i := order.find(active)
	_switched_once = true
	_activate(order[(i + 1) % order.size()])
	Sound.play("cloth_rustle", "effects", -8.0, 0.08)


func _activate(who: Player) -> void:
	active = who
	layla.is_active = who == layla
	baba.is_active = who == baba
	teta.is_active = who == teta
	camera.follow(who)
	_refresh_hint()


## One line at the top: the switch hint when switching unlocks, then the active character's
## own task while it is open and the switch hint again once it is done; nothing once the
## baking starts.
func _refresh_hint() -> void:
	if baking:
		hint.text = ""
		return
	if not switch_enabled:
		return
	var key := "d3.s6.hint.switch"
	if not _switched_once:
		pass
	elif active == layla and sacks_in < SACKS_NEEDED:
		key = "d3.s6.hint.flour"
	elif active == baba and not oven_clear:
		key = "d3.s6.hint.beam"
	elif active == teta and not persuaded:
		key = "d3.s6.hint.teta"
	hint.text = Say.text(key)


# -- Layla: the flour ------------------------------------------------------------------------

func _in_back_room(p: Player) -> bool:
	return p.global_position.x < BACK_ROOM_X


func _cat_lines() -> void:
	await Say.key("d3.s6.layla.01", 2.5)
	Say.key("d3.s6.abu_ahmad.05", 3.5)


## A sack set down in the hopper is poured in and counted; one set down anywhere else
## stays where it is and can be picked up again.
func _take_sack(sack: Carryable) -> void:
	sacks.erase(sack)
	sacks_in += 1
	_flour_puff(hopper.global_position + Vector2(0.0, -200.0))
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)
	sack.queue_free()
	_refresh_hint()


func _flour_puff(at: Vector2) -> void:
	for i in 12:
		var mote := Polygon2D.new()
		mote.color = Color(0.85, 0.82, 0.74, 0.6)
		mote.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		mote.position = at + Vector2(randf_range(-30.0, 30.0), randf_range(-10.0, 10.0))
		add_child(mote)
		var tw := create_tween()
		tw.tween_property(mote, "position", mote.position + Vector2(randf_range(-50.0, 50.0), randf_range(-70.0, -20.0)), randf_range(0.6, 1.2))
		tw.parallel().tween_property(mote, "modulate:a", 0.0, randf_range(0.6, 1.2))
		tw.tween_callback(mote.queue_free)


# -- Baba: the beam --------------------------------------------------------------------------

func _on_beam_lifted(_beam: Beam) -> void:
	oven_clear = true
	if not baba_spoke:
		baba_spoke = true
		Say.key("d3.s6.baba.01", 3.0)
	_refresh_hint()


# -- Teta: the talk --------------------------------------------------------------------------

func _on_abu_ahmad_talked(_npc: Npc) -> void:
	if persuaded or _talking or baking or not teta.is_active:
		return
	if teta.global_position.distance_to(abu_ahmad.global_position) > abu_ahmad.talk_radius:
		return
	_persuade()


func _persuade() -> void:
	_talking = true
	hint.text = ""
	teta.facing = -1 if abu_ahmad.global_position.x < teta.global_position.x else 1
	await Say.key("d3.s6.teta.01")
	await Say.key("d3.s6.abu_ahmad.02")
	await Say.key("d3.s6.teta.02")
	await Say.key("d3.s6.abu_ahmad.03")
	await Say.key("d3.s6.teta.03")
	# "After a while."
	await get_tree().create_timer(_bot_time(1.4)).timeout
	await Say.key("d3.s6.abu_ahmad.04")
	persuaded = true
	_talking = false
	_refresh_hint()


# -- The baking ------------------------------------------------------------------------------

func _bake() -> void:
	baking = true
	switch_enabled = false
	hint.text = ""
	_activate(layla)
	# The oven warms; the crank turns; Sami counts.
	var tw := create_tween()
	tw.tween_property(glow, "energy", GLOW_ENERGY, _bot_time(2.0, 0.3))
	tw.parallel().tween_property(mouth, "color", MOUTH_WARM, _bot_time(2.0, 0.3))
	cranking = true
	await Say.key("d3.s6.abu_ahmad.06")
	await Say.key("d3.s6.sami.02")
	await Say.key("d3.s6.abu_ahmad.07")
	# The hadith stands alone: the camera is on the oven mouth before the words appear.
	camera.follow(oven_view)
	await get_tree().create_timer(_bot_time(1.2, 0.1)).timeout
	tray.visible = true
	await Cards.show_card("day3.oven.sheet")
	card_shown = true
	camera.follow(layla)
	await Say.key("d3.s6.abu_ahmad.08")
	_return_candle()
	Notebook.write("d3_bread", Say.text("d3.note.bread", "en"), Say.text("d3.note.bread", "ar"), {"act": true})
	finish({"d3_bread_for_street": true, "bread": true, "candle": true})


## Layla leaves with the candle for the dark street: if she set it down for the sacks and
## nobody else picked it up, it is back in her hand as the tray goes out.
func _return_candle() -> void:
	if candle == null or not is_instance_valid(candle) or candle.held or layla.carried != null:
		return
	candle.set_lit(true)
	candle.pick_up(layla.hand)
	layla.carried = candle


# -- Every frame -----------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _done:
		return
	if switch_enabled and not baking and not _talking and not Say.busy and Input.is_action_just_pressed("switch_character"):
		_switch()
	for sack in sacks.duplicate():
		if is_instance_valid(sack) and not sack.held and hopper.overlaps_area(sack):
			_take_sack(sack)
	if not cat_seen and _in_back_room(layla):
		cat_seen = true
		_cat_lines()
	if not baba_spoke and baba.is_active and baba.global_position.distance_to(beam.item.global_position) < 170.0:
		baba_spoke = true
		Say.key("d3.s6.baba.01", 3.0)
	if not baking and sacks_in >= SACKS_NEEDED and oven_clear and persuaded:
		_bake()


func _process(delta: float) -> void:
	if not cranking:
		return
	var before := floori(_crank_angle / TAU)
	_crank_angle += CRANK_SPEED * delta
	handle.rotation = _crank_angle
	if floori(_crank_angle / TAU) != before:
		# A soft tick each turn, for Sami to count; the handle keeps turning under the fade
		# after the beat has ended, silently.
		turns += 1
		if not _done:
			Sound.play("stitch_%d" % (turns % 3 + 1), "effects", -16.0, 0.1)
