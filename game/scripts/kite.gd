extends Node2D
class_name Kite
## A kite on a string, flying in the global Wind field. While it flies the player stands
## still and the movement keys steer it; up and down reel the string in and out.
## The string is drawn as a hanging chain so it sags when the wind drops.

@export var anchor_path: NodePath
@export var string_length := 420.0
@export var min_length := 120.0
@export var max_length := 900.0
@export var reel_speed := 220.0
@export var lift := 3.6
@export var drag := 2.0
@export var weight := 180.0
@export var steer_force := 1100.0
@export var ground_y := 890.0

const ROPE_POINTS := 16
const TAIL_POINTS := 9
## How close the kite or its tail must pass to snag a light item.
const HOOK_REACH := 46.0
const HOOK_WEIGHT := 90.0

signal hooked_item(item: Carryable)
signal dropped_item(item: Carryable)

var flying := false
var vel := Vector2.ZERO
## A light carryable the kite has snagged. It comes down when the kite is reeled in.
var hooked: Carryable = null
## Whoever holds the string; the item is dropped at their feet.
var carrier: Node2D = null

var _anchor: Node2D
var _rope := PackedVector2Array()
var _rope_prev := PackedVector2Array()
var _tail := PackedVector2Array()
## Seconds until the bag crackles again, and the crackle now playing.
var _flap_timer := 0.0
var _flap_player: AudioStreamPlayer2D = null

@onready var string_line: Line2D = $String
@onready var sail: Polygon2D = $Sail
@onready var tail_line: Line2D = $Tail


func _ready() -> void:
	_anchor = get_node(anchor_path) as Node2D
	_rope.resize(ROPE_POINTS)
	_rope_prev.resize(ROPE_POINTS)
	_tail.resize(TAIL_POINTS)
	top_level = true
	visible = false


func launch(facing: int) -> void:
	flying = true
	visible = true
	global_position = _anchor.global_position + Vector2(facing * 50.0, -70.0)
	vel = Vector2(facing * 80.0, -220.0)
	_flap_timer = 0.15
	for i in ROPE_POINTS:
		var p := _anchor.global_position.lerp(global_position, float(i) / float(ROPE_POINTS - 1))
		_rope[i] = p
		_rope_prev[i] = p
	for i in TAIL_POINTS:
		_tail[i] = global_position


func reel_in() -> void:
	flying = false
	visible = false
	_stop_flap()
	if hooked != null:
		var at := global_position
		if carrier != null:
			at = carrier.global_position + Vector2(signf(global_position.x - carrier.global_position.x) * 44.0, 0.0)
		else:
			at.y = ground_y + 10.0
		_release(at)


func _release(at: Vector2) -> void:
	var item := hooked
	hooked = null
	weight -= HOOK_WEIGHT
	item.drop(at)
	dropped_item.emit(item)


## The plastic bag crackling in the wind: a 1.5 s one-shot retriggered every 1.1 to 1.7 s,
## sooner in stronger wind, from where the kite is.
func _flap(delta: float) -> void:
	_flap_timer -= delta
	if _flap_timer > 0.0:
		return
	var speed := Wind.sample(global_position).length()
	var strong := clampf((speed - 60.0) / 300.0, 0.0, 1.0)
	_flap_timer = clampf(lerpf(1.7, 1.1, strong) + randf_range(-0.08, 0.08), 1.1, 1.7)
	_flap_player = Sound.play_at("kite_flap", global_position, "effects", -4.0, 0.12)


## Lets the current crackle die away when the kite comes down.
func _stop_flap() -> void:
	if _flap_player == null or not is_instance_valid(_flap_player):
		return
	var tw := _flap_player.create_tween()
	tw.tween_property(_flap_player, "volume_db", Sound.SILENT_DB, 0.15)
	tw.tween_callback(_flap_player.queue_free)
	_flap_player = null


## Snag the nearest light, unheld carryable that the kite or its tail is touching.
func _try_hook() -> void:
	if hooked != null:
		return
	for node in get_tree().get_nodes_in_group("carryable"):
		var item := node as Carryable
		if item == null or item.held or item.weight != Carryable.Weight.LIGHT or not item.hookable:
			continue
		var centre := item.global_position + Vector2(0.0, -11.0)
		var near := global_position.distance_to(centre) < HOOK_REACH
		if not near:
			for p in _tail:
				if p.distance_to(centre) < HOOK_REACH:
					near = true
					break
		if near:
			hooked = item
			weight += HOOK_WEIGHT
			item.pick_up(self)
			item.position = Vector2(0.0, 40.0)
			hooked_item.emit(item)
			return


func _physics_process(delta: float) -> void:
	if not flying or _anchor == null:
		return
	var anchor := _anchor.global_position

	# Reeling.
	var reel := Input.get_axis("move_down", "move_up")
	string_length = clampf(string_length - reel * reel_speed * delta, min_length, max_length)

	# Aerodynamics, kept simple and stable: drag toward the wind, lift upward from airspeed,
	# weight downward, and a steering push from the player.
	var wind := Wind.sample(global_position)
	var relative := wind - vel
	var force := relative * drag
	force.y -= relative.length() * lift
	force.y += weight
	force.x += Input.get_axis("move_left", "move_right") * steer_force
	vel += force * delta
	vel *= 0.995
	global_position += vel * delta

	# The string is a rope: it can be slack but never longer than string_length.
	var offset := global_position - anchor
	var dist := offset.length()
	if dist > string_length:
		var dir := offset / dist
		global_position = anchor + dir * string_length
		var outward := vel.dot(dir)
		if outward > 0.0:
			vel -= dir * outward

	# Crash if it touches the ground.
	if global_position.y > ground_y:
		if hooked != null:
			_release(Vector2(global_position.x, ground_y + 10.0))
		reel_in()
		return

	rotation = offset.angle() + PI * 0.5
	_flap(delta)
	_update_rope(anchor, delta)
	_update_tail(delta)
	_try_hook()
	if hooked != null:
		hooked.rotation = -rotation


func _update_rope(anchor: Vector2, delta: float) -> void:
	var segment := string_length / float(ROPE_POINTS - 1)
	# Verlet step for the inner points.
	for i in range(1, ROPE_POINTS - 1):
		var p := _rope[i]
		var v := (p - _rope_prev[i]) * 0.96
		_rope_prev[i] = p
		var w := Wind.sample(p) * 0.15
		_rope[i] = p + v + (Vector2(0.0, 380.0) + w) * delta * delta
	_rope[0] = anchor
	_rope[ROPE_POINTS - 1] = global_position
	for _iter in 4:
		for i in range(ROPE_POINTS - 1):
			var a := _rope[i]
			var b := _rope[i + 1]
			var d := b - a
			var l := d.length()
			if l < 0.001:
				continue
			var diff := (l - segment) / l
			var lock_a := i == 0
			var lock_b := i + 1 == ROPE_POINTS - 1
			if lock_a and lock_b:
				continue
			if lock_a:
				_rope[i + 1] = b - d * diff
			elif lock_b:
				_rope[i] = a + d * diff
			else:
				_rope[i] = a + d * diff * 0.5
				_rope[i + 1] = b - d * diff * 0.5
	# Line2D is a child, so convert to local space.
	var pts := PackedVector2Array()
	pts.resize(ROPE_POINTS)
	for i in ROPE_POINTS:
		pts[i] = to_local(_rope[i])
	string_line.points = pts


func _update_tail(delta: float) -> void:
	var t := 1.0 - exp(-14.0 * delta)
	_tail[0] = global_position
	for i in range(1, TAIL_POINTS):
		var target := _tail[i - 1] + Vector2(0.0, 10.0) - Wind.sample(_tail[i - 1]) * 0.03
		_tail[i] = _tail[i].lerp(target, t)
	var pts := PackedVector2Array()
	pts.resize(TAIL_POINTS)
	for i in TAIL_POINTS:
		pts[i] = to_local(_tail[i])
	tail_line.points = pts
