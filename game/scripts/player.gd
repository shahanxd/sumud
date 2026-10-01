extends CharacterBody2D
class_name Player
## The playable character. Movement is deliberately simple (run, jump, crawl, grab) so that
## what is carried and what is flown can change it. Origin is at the feet. Several players
## can share a scene; only the active one reads input, the others stand where they are.
##
## Feel (docs/design/feel-and-readability.md): control answers the same frame, a short skid
## when turning at full run, coyote time off a ledge, a jump buffer before landing, a jump
## whose height follows how long the button is held, and a landing whose squash follows the
## impact and the load. Every number is an export so the founder can tune in play; F3 shows
## them on screen (never in bots or shots: it only answers a real key press).

## A landing. `impact_speed` is the downward speed in px/s the frame before the feet touched.
signal landed(impact_speed: float)

@export_group("Run")
@export var run_speed := 320.0
## Ground acceleration, px/s²: 320 px/s in about 0.08 s.
@export var ground_accel := 4000.0
## Ground braking (no input, or input against the run), px/s²: a stop in about 0.06 s.
@export var ground_decel := 5400.0
@export var air_accel := 1400.0
## Turning against a run faster than this fraction of full speed starts a skid.
@export var skid_threshold := 0.8
## How long the skid lasts, s; the braking rate is multiplied by skid_factor while it does.
@export var skid_time := 0.12
@export var skid_factor := 0.5

@export_group("Jump")
@export var jump_velocity := -640.0
## Seconds after walking off a ledge during which a jump still fires.
@export var coyote_time := 0.1
## Seconds before landing during which a jump press is kept and fires on landing.
@export var jump_buffer := 0.1
## Releasing jump while still rising multiplies the upward speed by this, once.
@export var jump_cut_factor := 0.45

@export_group("Carry")
@export var heavy_speed_factor := 0.6
@export var two_handed_speed_factor := 0.45
@export var crawl_speed_factor := 0.5

@export_group("Landing")
## Squash at land_ref_speed; smaller landings squash in proportion.
@export var land_squash_max := 0.30
## Impact speed (px/s) that gives the full squash. A full jump lands at about 640.
@export var land_ref_speed := 900.0
## Landing squash multipliers for a heavy one-hand load and a two-handed load.
@export var land_squash_heavy := 1.3
@export var land_squash_two_handed := 1.5
## How fast the squash or stretch eases back to rest, per second.
@export var squash_recover := 1.6
## Stretch at take-off (negative squash).
@export var jump_stretch := -0.18

@export_group("")
@export var kite_path: NodePath
## Whether this body reads input right now. The beat switches it.
@export var is_active := true
## 0 child (Layla), 1 adult (Baba). Adults can lift what children cannot.
@export_enum("child", "adult") var build := 0
@export var character_name := "Layla"
## What the feet land on, for Sound.step: "concrete" or "sand" (the beach).
@export var surface := "concrete"

var facing := 1
var crawling := false
var sitting := false
## True while braking out of a full-speed turn.
var skidding := false
## Set by a beat: +1 forbids moving right, -1 forbids moving left (darkness without a flame).
var movement_block := 0
var carried: Carryable = null
var kite: Kite = null
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
## The current squash of the body: positive pressed down (a landing), negative stretched
## (take-off), easing back to 0. The rig reads it; heavier landings and loads push it higher.
var land_squash := 0.0
## The last landing's impact speed, px/s.
var last_impact := 0.0

var _run_phase := 0.0
var _was_on_floor := true
var _coyote_left := 0.0
var _buffer_left := 0.0
var _skid_left := 0.0
## True from take-off until the jump is cut or the feet land again.
var _jump_cut_armed := false
var _debug_layer: CanvasLayer = null
var _debug_label: Label = null

@onready var stand_shape: CollisionShape2D = $StandShape
@onready var crawl_shape: CollisionShape2D = $CrawlShape
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var hand: Node2D = $Visual/Hand
@onready var visual: Node2D = $Visual
@onready var figure: Figure = $Visual
@onready var pickup_area: Area2D = $PickupArea


func _ready() -> void:
	add_to_group("player")
	if kite_path != NodePath():
		kite = get_node(kite_path) as Kite
		if kite:
			kite.carrier = self
	_apply_build()


func _apply_build() -> void:
	figure.build = build
	if build == 1:
		figure.headscarf = false
		figure.dress = 0
		figure.shoulder = 0.14
		var stand := stand_shape.shape as CapsuleShape2D
		if stand:
			# Own copy: the shape resource is shared by every player in the scene.
			stand = stand.duplicate()
			stand.height = 130.0
			stand_shape.shape = stand
			stand_shape.position.y = -65.0


## What the hands are doing, as a movement rule.
func load_kind() -> int:
	if carried == null:
		return -1
	return carried.weight


func speed_factor() -> float:
	var f := 1.0
	match load_kind():
		Carryable.Weight.HEAVY: f = heavy_speed_factor
		Carryable.Weight.TWO_HANDED: f = two_handed_speed_factor
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
	var on_floor := is_on_floor()
	var axis := 0.0
	if reads_input and not kite_mode():
		axis = Input.get_axis("move_left", "move_right")
		if movement_block != 0 and signf(axis) == float(movement_block):
			axis = 0.0

	# Crawling: hold down on the floor. Stay down while something is overhead.
	var want_crawl := reads_input and Input.is_action_pressed("move_down") and on_floor and can_crawl() and not kite_mode()
	_set_crawling(want_crawl or (crawling and _ceiling_blocked()))

	# Coyote time counts down from the last frame on the floor; the buffer from the last press.
	if on_floor:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)
		velocity.y += gravity * delta
	_buffer_left = maxf(_buffer_left - delta, 0.0)

	# Horizontal: accelerate toward the stick, brake harder, and skid out of a full-speed turn.
	var target := axis * run_speed * speed_factor()
	var rate := air_accel
	if on_floor:
		var reversing := axis != 0.0 and velocity.x != 0.0 and signf(axis) != signf(velocity.x)
		if reversing and absf(velocity.x) >= skid_threshold * run_speed * speed_factor() and _skid_left <= 0.0:
			_skid_left = skid_time
		if axis == 0.0 or reversing:
			rate = ground_decel
		else:
			rate = ground_accel
		if _skid_left > 0.0:
			_skid_left -= delta
			rate *= skid_factor
	else:
		_skid_left = 0.0
	skidding = on_floor and _skid_left > 0.0
	velocity.x = move_toward(velocity.x, target, rate * delta)

	if reads_input:
		if Input.is_action_just_pressed("jump"):
			_buffer_left = jump_buffer
		if _buffer_left > 0.0 and (on_floor or _coyote_left > 0.0) and can_jump() and not kite_mode():
			_jump()
		elif Input.is_action_just_released("jump") and _jump_cut_armed and velocity.y < 0.0:
			velocity.y *= jump_cut_factor
			_jump_cut_armed = false
		if Input.is_action_just_pressed("grab") and not kite_mode():
			_toggle_grab()
		if Input.is_action_just_pressed("kite") and kite != null:
			if kite.flying:
				kite.reel_in()
			elif on_floor and load_kind() != Carryable.Weight.TWO_HANDED:
				kite.launch(facing)

	if axis != 0.0:
		facing = 1 if axis > 0.0 else -1

	var fall_speed := velocity.y
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_land(maxf(fall_speed, 0.0))
	_was_on_floor = is_on_floor()
	_animate(delta)
	if _debug_label != null and _debug_layer.visible:
		_debug_label.text = _debug_text()


func _jump() -> void:
	velocity.y = jump_velocity
	land_squash = jump_stretch
	_buffer_left = 0.0
	_coyote_left = 0.0
	_jump_cut_armed = true


## The feet touch: squash by the impact and the load, tell the beat, sound the step.
func _land(impact_speed: float) -> void:
	last_impact = impact_speed
	_jump_cut_armed = false
	var weight := 1.0
	match load_kind():
		Carryable.Weight.HEAVY: weight = land_squash_heavy
		Carryable.Weight.TWO_HANDED: weight = land_squash_two_handed
	var frac := clampf(impact_speed / maxf(land_ref_speed, 1.0), 0.0, 1.0)
	land_squash = maxf(land_squash, land_squash_max * frac * weight)
	Sound.step(surface, lerpf(-8.0, 0.0, frac))
	landed.emit(impact_speed)


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


## Drives the figure: which pose, how far into the stride, what the hands hold.
func _animate(delta: float) -> void:
	var moving := is_on_floor() and absf(velocity.x) > 20.0
	if moving:
		figure.stride = clampf(absf(velocity.x) / maxf(run_speed, 1.0), 0.15, 1.0)
		var cadence := 5.0 if crawling else 7.0 + 5.0 * figure.stride
		# A foot plants each time the phase crosses a multiple of PI (one leg, then the other).
		var plants := floori(_run_phase / PI)
		_run_phase += delta * cadence
		if floori(_run_phase / PI) != plants:
			Sound.step(surface, -12.0 if crawling else -2.0)
	else:
		figure.stride = move_toward(figure.stride, 0.0, delta * 4.0)
		# Ease the legs back together instead of freezing mid-step.
		var rest := roundf(_run_phase / PI) * PI
		_run_phase = move_toward(_run_phase, rest, delta * 10.0)
	land_squash = move_toward(land_squash, 0.0, delta * squash_recover)

	figure.phase = _run_phase
	figure.load = load_kind()
	figure.arm_up = kite_mode()
	figure.airborne = not is_on_floor()
	figure.squash = land_squash
	if sitting:
		figure.pose = Figure.Pose.SIT
	elif crawling:
		figure.pose = Figure.Pose.CRAWL
	elif moving or figure.stride > 0.02:
		figure.pose = Figure.Pose.WALK
	else:
		figure.pose = Figure.Pose.STAND
	# Squash keeps the volume: pressed down, the body widens a little.
	visual.scale = Vector2(float(facing) * (1.0 - land_squash * 0.5), 1.0 + land_squash)


# -- Debug overlay (F3) -----------------------------------------------------------------

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_active:
		return
	if key.keycode != KEY_F3 and key.physical_keycode != KEY_F3:
		return
	if Day.bot_mode or OS.get_cmdline_user_args().has("--smoke"):
		return
	_toggle_debug()
	get_viewport().set_input_as_handled()


func _toggle_debug() -> void:
	if _debug_layer == null:
		_debug_layer = CanvasLayer.new()
		_debug_layer.name = "FeelDebug"
		_debug_layer.layer = 100
		var panel := PanelContainer.new()
		panel.position = Vector2(16.0, 16.0)
		panel.self_modulate = Color(1.0, 1.0, 1.0, 0.85)
		_debug_label = Label.new()
		_debug_label.add_theme_font_size_override("font_size", 18)
		panel.add_child(_debug_label)
		_debug_layer.add_child(panel)
		add_child(_debug_layer)
		_debug_layer.visible = false
	_debug_layer.visible = not _debug_layer.visible
	if _debug_layer.visible:
		_debug_label.text = _debug_text()


func _debug_text() -> String:
	var lines := PackedStringArray()
	lines.append("%s  feel (F3)" % character_name)
	lines.append("gravity %.0f   jump %.0f   cut x%.2f" % [gravity, jump_velocity, jump_cut_factor])
	lines.append("run %.0f   accel %.0f   decel %.0f   air %.0f" % [run_speed, ground_accel, ground_decel, air_accel])
	lines.append("skid %.2fs x%.2f at %.0f%%" % [skid_time, skid_factor, skid_threshold * 100.0])
	lines.append("coyote %.2fs   buffer %.2fs" % [coyote_time, jump_buffer])
	lines.append("carry heavy %.2f   two-handed %.2f   crawl %.2f" % [heavy_speed_factor, two_handed_speed_factor, crawl_speed_factor])
	lines.append("land squash %.2f @ %.0f   heavy x%.2f   two-handed x%.2f" % [land_squash_max, land_ref_speed, land_squash_heavy, land_squash_two_handed])
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var la: float = float(cam.get("look_ahead")) if cam.get("look_ahead") != null else 0.0
		var gz: float = float(cam.get("ground_zoom")) if cam.get("ground_zoom") != null else cam.zoom.x
		lines.append("camera look-ahead %.0f   ground zoom %.2f   zoom now %.2f" % [la, gz, cam.zoom.x])
	lines.append("vel %.0f, %.0f   floor %s   load %d   impact %.0f" % [velocity.x, velocity.y, str(is_on_floor()), load_kind(), last_impact])
	return "\n".join(lines)
