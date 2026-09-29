extends Node
class_name Bot
## Base class for scripted playthroughs. A bot presses the real input actions and checks
## the design's rules, as a coroutine: `await hold("move_right", 60)`. Subclasses override
## run(). Prints one line per check; exit code 0 when every check passes.

var passed := 0
var fails := PackedStringArray()
var name_tag := "bot"


func _ready() -> void:
	await get_tree().physics_frame
	await run()


## Override. Awaitable.
func run() -> void:
	pass


func frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func hold(action: String, n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)


func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)


func release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "grab", "kite", "interact", "switch_character", "notebook"]:
		Input.action_release(a)


func check(ok: bool, what: String) -> void:
	if ok:
		passed += 1
		print("  ok   ", what)
	else:
		fails.append(what)
		print("  FAIL ", what)


## Waits until `pred` is true or `max_frames` pass. Returns whether it became true.
func until(pred: Callable, max_frames: int) -> bool:
	for _i in max_frames:
		if pred.call():
			return true
		await get_tree().physics_frame
	return pred.call()


func teleport(p: Player, to: Vector2) -> void:
	p.global_position = to
	p.velocity = Vector2.ZERO


## Prints the summary and quits with the exit code. Call at the end of run().
func done() -> void:
	release_all()
	print("%s: %d passed, %d failed" % [name_tag, passed, fails.size()])
	for f in fails:
		print("  failed: ", f)
	get_tree().quit(0 if fails.is_empty() else 1)
