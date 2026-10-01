extends D1HomeBeat
## Day 1, Scenes 0 and 1: before anyone is awake, and the house wakes. Layla is on the
## roof at fajr with her kite already up over the sea; the first input of the game is the
## kite. Mama calls up the stairwell. When Layla reels in, the kite comes down into her arms
## and she goes down through the house: Teta on her mat, Mama at the gas ring, Baba just in
## from the sea with Mishmish round his legs, Karim asleep. Barks as she passes, look-ats on
## interact, the white scarf from its hook by the door, and out into the street.

const LOOKS := {
	"LookKey": "d1.s1.look.key",
	"LookList": "d1.s1.look.list",
	"LookKarim": "d1.s1.look.karim",
	"LookCat": "d1.s1.look.cat",
}

@onready var kite: Kite = $Kite
@onready var mama: Npc = $Mama
@onready var baba_home: Npc = $BabaHome
@onready var karim: Npc = $Karim
@onready var scarf_hook: Node2D = $ScarfHook
@onready var scarf_cloth: Polygon2D = $ScarfHook/Cloth

## The kite is up and hers to fly; false once she has reeled it in and it has come down.
var kite_in_play := false
var scarf_taken := false
## The key of the last look-at thought shown.
var last_look := ""
var inside := false

var _reel_requested := false
var _mama_greeted := false
var _teta_spoke := false
var _baba_spoke := false
var _zones: Array[Area2D] = []


func _ready() -> void:
	title = "The kites"
	phase = "dusk"
	Look.dress()
	baba.is_active = false
	teta.figure.pose = Figure.Pose.SIT
	for zone_name in LOOKS:
		var zone := get_node(String(zone_name)) as Area2D
		if zone != null:
			_zones.append(zone)
	make_cat(baba_home.global_position + Vector2(-20.0, 0.0))
	hint.text = ""


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	# The sea and the wind first, the way the scene opens: the sea is in view from the roof.
	Sound.loop("wind_loop", "ambience", -14.0, 2.0)
	Sound.loop("sea_loop", "ambience", -22.0, 3.0)
	layla.facing = -1
	kite.launch(-1)
	kite_in_play = true
	hint.text = Say.text("d1.s0.hint.kite")
	_mama_calls()


## Mama from the stairwell, after the player has had the kite a while.
func _mama_calls() -> void:
	await _wait(7.0, 0.4)
	if _closed():
		return
	await _bark("d1.s0.mama.01", 3.0)
	await _bark("d1.s0.layla.01", 2.0)
	await _bark("d1.s0.mama.02", 2.5)


func _tick(_delta: float) -> void:
	if _done:
		return
	_kite_step()
	var p := layla.global_position
	if not inside and p.y > 560.0:
		inside = true
		# Dawn goes on without her: the pink gives way to morning as she comes down.
		Look.set_phase(1, "morning", 0.3 if Day.bot_mode else 25.0)
	if not _mama_greeted and p.y > 690.0:
		_mama_greeted = true
		_group_mama()
	if not _teta_spoke and p.distance_to(teta.global_position) < 170.0:
		_teta_spoke = true
		_group_teta()
	if not _baba_spoke and p.distance_to(baba_home.global_position) < 170.0:
		_baba_spoke = true
		_group_baba()
	if not scarf_taken and p.distance_to(scarf_hook.global_position) < 60.0:
		_take_scarf()
	if layla.is_active and not layla.kite_mode() and Input.is_action_just_pressed("interact") and not Say.busy:
		_look()
	if street_door.overlaps_body(layla):
		_leave()


## The kite cannot fall here: if it touches down it is quietly up again. Reeling in (the
## kite key) is the exit: it comes down into her arms and leaves play with her.
func _kite_step() -> void:
	if not kite_in_play:
		return
	if kite.flying:
		if layla.is_active and Input.is_action_just_pressed("kite"):
			_reel_requested = true
		return
	if _reel_requested:
		kite_in_play = false
		layla.kite = null
		kite.visible = false
		hint.text = Say.text("d1.s1.hint.scarf")
		return
	if layla.is_on_floor() and layla.global_position.y < 530.0:
		kite.launch(layla.facing)


func _group_mama() -> void:
	await _bark("d1.s1.mama.01", 3.0)
	await _bark("d1.s1.layla.01", 2.0)


func _group_teta() -> void:
	await _bark("d1.s1.teta.01", 3.0)
	await _bark("d1.s1.teta.02", 3.0)
	await _bark("d1.s1.layla.03", 2.0)


func _group_baba() -> void:
	await _bark("d1.s1.baba.01", 2.0)
	await _bark("d1.s1.layla.02", 2.0)
	await _bark("d1.s1.baba.02", 3.0)


func _take_scarf() -> void:
	scarf_taken = true
	scarf_cloth.visible = false
	Sound.play("cloth_rustle", "effects", -6.0, 0.08)


## A look-at: the nearest zone she stands in gives one of her thoughts, timed, never blocking.
func _look() -> void:
	var best: Area2D = null
	var best_d := INF
	for zone in _zones:
		if not zone.overlaps_body(layla):
			continue
		var d := zone.global_position.distance_squared_to(layla.global_position)
		if d < best_d:
			best_d = d
			best = zone
	if best == null:
		return
	last_look = String(LOOKS[best.name])
	_bark(last_look, 2.5)


func _leave() -> void:
	hint.text = ""
	Sound.play("door_wood", "effects")
	finish({"d1_scarf": scarf_taken})
