extends CharacterBody2D
class_name Player
## The playable character. Movement is deliberately simple (run, jump, crawl, grab) so that
## what is carried and what is flown can change it. Origin is at the feet. Several players
## can share a scene; only the active one reads input, the others stand where they are.

@export var run_speed := 320.0
@export var jump_velocity := -640.0
@export var ground_accel := 2600.0
@export var air_accel := 1400.0
@export var crawl_speed_factor := 0.5
@export var kite_path: NodePath
## Whether this body reads input right now. The beat switches it.
@export var is_active := true
## 0 child (Layla), 1 adult (Baba). Adults can lift what children cannot.
@export_enum("child", "adult") var build := 0
@export var character_name := "Layla"

var facing := 1
var crawling := false
var sitting := false
var carried: Carryable = null
var kite: Kite = null
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _run_phase := 0.0
var _squash := 0.0
var _was_on_floor := true

@onready var stand_shape: CollisionShape2D = $StandShape
@onready var crawl_shape: CollisionShape2D = $CrawlShape
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var hand: Node2D = $Visual/Hand
@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Body
@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	add_to_group("player")
	if kite_path != NodePath():
		kite = get_node(kite_path) as Kite
		if kite:
			kite.carrier = self
	_apply_build()


func _apply_build() -> void:
	if build == 1:
		visual.scale = Vector2(1.12, 1.18)
		var scarf := get_node_or_null("Visual/Headscarf")
		if scarf:
			scarf.visible = false
		var stand := stand_shape.shape as CapsuleShape2D
		if stand:
			stand.height = 130.0
			stand_shape.position.y = -65.0


## What the hands are doing, as a movement rule.
func load_kind() -> int:
	if carried == null:
		return -1
	return carried.weight


func speed_factor() -> float:
	var f := 1.0
	match load_kind():
		Carryable.Weight.HEAVY: f = 0.6
		Carryable.Weight.TWO_HANDED: f = 0.45
	if crawling:
		f *= crawl_speed_factor
	return f


func can_jump() -> bool:
	return load_kind() in [-1, Carryable.Weight.LIGHT] and not crawling and not sitting


func can_crawl() -> bool:
	return load_kind() != Carryable.Weight.TWO_HANDED and not sitting


func can_lift(item: Carryable) -> bool:
	return item.min_build <= build


func has_light() -> bool:
	return carried != null and carried.is_light_source and carried.lit


func kite_mode() -> bool:
	return kite != null and kite.flying


## Sitting: no input, a lower pose. Used by sit spots.
func sit(on: bool) -> void:
	sitting = on
	if on:
		_set_crawling(false)
		velocity.x = 0.0


func _physics_process(delta: float) -> void:
	var reads_input := is_active and not sitting
	var axis := 0.0
	if reads_input and not kite_mode():
		axis = Input.get_axis("move_left", "move_right")

	# Crawling: hold down on the floor. Stay down while something is overhead.
	var want_crawl := reads_input and Input.is_action_pressed("move_down") and is_on_floor() and can_crawl() and not kite_mode()
	_set_crawling(want_crawl or (crawling and _ceiling_blocked()))

	if not is_on_floor():
		velocity.y += gravity * delta

	var target := axis * run_speed * speed_factor()
	var accel := ground_accel if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, target, accel * delta)

	if reads_input:
		if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump() and not kite_mode():
			velocity.y = jump_velocity
			_squash = -0.18
		if Input.is_action_just_pressed("grab") and not kite_mode():
			_toggle_grab()
		if Input.is_action_just_pressed("kite") and kite != null:
			if kite.flying:
				kite.reel_in()
			elif is_on_floor() and load_kind() != Carryable.Weight.TWO_HANDED:
				kite.launch(facing)

	if axis != 0.0:
		facing = 1 if axis > 0.0 else -1

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_squash = 0.22
	_was_on_floor = is_on_floor()
	_animate(delta)


func _set_crawling(value: bool) -> void:
	if value == crawling:
		return
	crawling = value
	stand_shape.disabled = crawling
	crawl_shape.disabled = not crawling


func _ceiling_blocked() -> bool:
	ceiling_check.force_raycast_update()
	return ceiling_check.is_colliding()


func _toggle_grab() -> void:
	if carried != null:
		var at := global_position + Vector2(facing * 34.0, 0.0)
		carried.drop(at)
		carried = null
		return
	var best: Carryable = null
	var best_d := INF
	for area in pickup_area.get_overlapping_areas():
		var item := area as Carryable
		if item == null or item.held or not can_lift(item):
			continue
		var d := global_position.distance_squared_to(item.global_position)
		if d < best_d:
			best_d = d
			best = item
	if best != null:
		best.pick_up(hand)
		carried = best
		if not can_crawl():
			_set_crawling(false)


func _animate(delta: float) -> void:
	visual.scale.x = absf(visual.scale.x) * float(facing)
	var running := is_on_floor() and absf(velocity.x) > 20.0
	if running:
		_run_phase += delta * 11.0 * speed_factor() * 1.6
	else:
		_run_phase = move_toward(_run_phase, 0.0, delta * 8.0)
	_squash = move_toward(_squash, 0.0, delta * 1.6)

	var bob := -absf(sin(_run_phase)) * 4.0 if running else 0.0
	var lean := 0.0
	match load_kind():
		Carryable.Weight.HEAVY: lean = 0.12
		Carryable.Weight.TWO_HANDED: lean = 0.2
	var tall := 1.18 if build == 1 else 1.0
	if sitting:
		visual.rotation = 0.0
		visual.position = Vector2(0.0, 24.0)
		visual.scale.y = tall * 0.78
	elif crawling:
		visual.rotation = -PI * 0.5 * 0.92
		visual.position = Vector2(-10.0, 0.0)
		visual.scale.y = tall
	else:
		visual.rotation = lean
		visual.position = Vector2(0.0, bob)
		visual.scale.y = tall * (1.0 + _squash)
