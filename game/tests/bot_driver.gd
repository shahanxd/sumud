extends Node
## Scripted playthrough of the beach greybox, run headless. Presses the real input actions
## and checks the rules of the design: running, jumping, carrying (weight slows, heavy
## removes the jump), crawling under the low wall, and flying the kite.
## Exit code 0 when every check passes, 1 otherwise.

var _step := 0
var _frames := 0
var _passed := 0
var _fails := PackedStringArray()

var _x0 := 0.0
var _y0 := 0.0
var _y_min := INF
var _free_run := 0.0

@onready var player: Player = $Beach/Player
@onready var kite: Kite = $Beach/Kite


func _check(ok: bool, name: String) -> void:
	if ok:
		_passed += 1
		print("  ok   ", name)
	else:
		_fails.append(name)
		print("  FAIL ", name)


func _next() -> void:
	_step += 1
	_frames = 0


func _physics_process(_delta: float) -> void:
	_frames += 1
	match _step:
		0:
			if _frames == 10:
				_x0 = player.global_position.x
				Input.action_press("move_right")
				_next()
		1:
			if _frames == 60:
				_free_run = player.global_position.x - _x0
				_check(_free_run > 200.0, "runs right (%.0f px in 60 frames)" % _free_run)
				Input.action_release("move_right")
				_next()
		2:
			# Jump height follows the hold: held through the rise (about 0.65 s at -640)
			# for the full jump, a tap for a hop.
			if _frames == 1:
				_y0 = player.global_position.y
				_y_min = _y0
				Input.action_press("jump")
			if _frames == 45:
				Input.action_release("jump")
			_y_min = minf(_y_min, player.global_position.y)
			if _frames == 110:
				_check(_y_min < _y0 - 120.0, "jumps (%.0f px high)" % (_y0 - _y_min))
				_check(absf(player.global_position.y - _y0) < 2.0, "lands back on the ground")
				_y_min = _y0
				Input.action_press("jump")
			if _frames == 113:
				Input.action_release("jump")
			if _frames > 110:
				_y_min = minf(_y_min, player.global_position.y)
			if _frames == 200:
				var hop := _y0 - _y_min
				_check(hop > 25.0 and hop < 120.0, "a tap gives a lower hop (%.0f px)" % hop)
				_check(absf(player.global_position.y - _y0) < 2.0, "lands again after the hop")
				_next()
		3:
			# Teleport next to the jerrycan (heavy) and grab it.
			if _frames == 1:
				player.global_position = Vector2(1090.0, 900.0)
				player.velocity = Vector2.ZERO
			if _frames == 12:
				Input.action_press("grab")
			if _frames == 14:
				Input.action_release("grab")
			if _frames == 20:
				_check(player.carried != null and player.carried.label == "jerrycan", "grabs the jerrycan")
				_x0 = player.global_position.x
				Input.action_press("move_right")
				_next()
		4:
			if _frames == 60:
				var d := player.global_position.x - _x0
				_check(d < _free_run * 0.75 and d > 50.0, "heavy load slows the run (%.0f vs %.0f px)" % [d, _free_run])
				Input.action_release("move_right")
				_next()
		5:
			if _frames == 1:
				_y0 = player.global_position.y
				_y_min = _y0
				Input.action_press("jump")
			if _frames == 3:
				Input.action_release("jump")
			_y_min = minf(_y_min, player.global_position.y)
			if _frames == 40:
				_check(_y_min > _y0 - 10.0, "heavy load removes the jump")
				Input.action_press("grab")
				_next()
		6:
			if _frames == 2:
				Input.action_release("grab")
			if _frames == 10:
				_check(player.carried == null, "drops the jerrycan")
				_check(not $Beach/Jerrycan.held and $Beach/Jerrycan.get_parent() == $Beach, "jerrycan returns to the level")
				_next()
		7:
			# Crawl under the low wall: gap is 55 px, the crawl box is 40 px tall.
			if _frames == 1:
				player.global_position = Vector2(2880.0, 900.0)
				player.velocity = Vector2.ZERO
			if _frames == 10:
				Input.action_press("move_down")
				Input.action_press("move_right")
			if _frames == 30:
				_check(player.crawling, "crawls when holding down")
			if _frames == 200:
				_check(player.global_position.x > 3130.0, "passes under the low wall (x=%.0f)" % player.global_position.x)
				Input.action_release("move_down")
				Input.action_release("move_right")
				_next()
		8:
			if _frames == 30:
				_check(not player.crawling, "stands up again past the wall")
				player.global_position = Vector2(600.0, 900.0)
				player.velocity = Vector2.ZERO
			if _frames == 40:
				_x0 = player.global_position.x
				Input.action_press("kite")
			if _frames == 42:
				Input.action_release("kite")
			if _frames == 200:
				_check(kite.flying, "kite launches")
				_check(kite.global_position.y < player.global_position.y - 250.0, "kite climbs (%.0f px above)" % (player.global_position.y - kite.global_position.y))
				Input.action_press("move_right")
				_next()
		9:
			if _frames == 1:
				_y0 = kite.global_position.x
			if _frames == 60:
				_check(absf(player.global_position.x - _x0) < 1.0, "player stands still while flying")
				_check(kite.global_position.x > _y0 + 30.0, "kite steers right")
				Input.action_release("move_right")
				Input.action_press("kite")
				_next()
		10:
			if _frames == 2:
				Input.action_release("kite")
			if _frames == 10:
				_check(not kite.flying, "kite reels in")
				_next()
		11:
			# Quit clean: a sound still playing at exit is reported as leaked.
			if _frames == 1:
				Sound.stop_all_loops(0.0)
			if _frames > 30 and (Sound.get_child_count() == 0 or _frames > 600):
				print("bot: %d passed, %d failed" % [_passed, _fails.size()])
				for f in _fails:
					print("  failed: ", f)
				get_tree().quit(0 if _fails.is_empty() else 1)
				_step = 99
