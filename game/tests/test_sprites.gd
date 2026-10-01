extends Node2D
## Checks SpriteFigure against whatever frames exist for Layla: the walk frame follows the
## owner's phase, the hand follows hands.json, and the fallback to bones works for a
## character with no frames. Prints "sprites: N passed, M failed"; exit code 1 on failure.

var _pass := 0
var _fail := 0


func _check(name: String, ok: bool, detail := "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("FAIL sprites: " + name + (" (" + detail + ")" if detail != "" else ""))


func _ready() -> void:
	var bones := SpriteFigure.new()
	bones.character = "nobody"
	bones.build = 0
	add_child(bones)
	_check("no frames falls back to bones", not bones.has_frames())

	var fig := SpriteFigure.new()
	fig.character = "layla"
	fig.build = 0
	var hand := Node2D.new()
	hand.name = "Hand"
	fig.add_child(hand)
	fig.position = Vector2(300, 400)
	add_child(fig)
	await get_tree().process_frame
	if not fig.has_frames():
		print("sprites: no frames for layla, bones only (%d passed, %d failed)" % [_pass, _fail])
		_finish()
		return
	fig.pose = Figure.Pose.WALK
	fig.stride = 0.4
	var count: int = fig.get_node("Sprite").sprite_frames.get_frame_count("walk")
	_check("walk has frames", count > 1, str(count))
	fig.phase = 0.0
	await get_tree().process_frame
	var f0: int = fig.get_node("Sprite").frame
	fig.phase = PI
	await get_tree().process_frame
	var f1: int = fig.get_node("Sprite").frame
	_check("frame follows phase", f0 == 0 and f1 == count / 2, "%d -> %d of %d" % [f0, f1, count])
	var hp: Vector2 = hand.position
	_check("hand placed above the feet", hp.y < 0.0 and absf(hp.x) < fig.height(), str(hp))
	var spr: AnimatedSprite2D = fig.get_node("Sprite")
	var drawn_h: float = spr.sprite_frames.get_frame_texture("walk", 0).get_size().y * spr.scale.y
	_check("scaled to the figure's height", absf(drawn_h - fig.height()) < 1.0, "%.1f vs %.1f" % [drawn_h, fig.height()])
	fig.pose = Figure.Pose.STAND
	fig.stride = 0.0
	await get_tree().process_frame
	_check("stand falls back to an existing animation", spr.visible)
	print("sprites: %d passed, %d failed" % [_pass, _fail])
	_finish()


func _finish() -> void:
	await get_tree().process_frame
	get_tree().quit(1 if _fail > 0 else 0)
