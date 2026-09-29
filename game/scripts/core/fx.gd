extends CanvasLayer
## Autoload "Fx". Full-screen effects that every beat shares: fade to and from black,
## the strike flash and white-out of dust, and the letterbox for cinematic beats.
## The photosensitivity option turns the flash into a soft fade.

var photosensitive_safe := false

var _fade: ColorRect
var _flash: ColorRect
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _letterbox := 0.0


func _ready() -> void:
	layer = 100
	_fade = _rect(Color(0, 0, 0, 1))
	_flash = _rect(Color(1, 1, 1, 0))
	_bar_top = _rect(Color(0, 0, 0, 1))
	_bar_bottom = _rect(Color(0, 0, 0, 1))
	_bar_top.anchor_bottom = 0.0
	_bar_bottom.anchor_top = 1.0
	_set_letterbox(0.0)


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(r)
	return r


func fade_in(seconds: float) -> void:
	await _fade_to(0.0, seconds)


func fade_out(seconds: float) -> void:
	await _fade_to(1.0, seconds)


func _fade_to(alpha: float, seconds: float) -> void:
	if seconds <= 0.0:
		_fade.color.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, seconds)
	await tw.finished


## The strike: a hard white flash that decays into dust and clears slowly.
func strike_flash(dust_seconds: float = 3.0) -> void:
	var tw := create_tween()
	if photosensitive_safe:
		tw.tween_property(_flash, "color:a", 0.85, 0.5)
	else:
		_flash.color.a = 1.0
	tw.tween_property(_flash, "color:a", 0.75, 0.25)
	tw.tween_property(_flash, "color:a", 0.0, dust_seconds).set_ease(Tween.EASE_IN)
	await tw.finished


## Failure is a white screen of dust and a return to the last doorway.
func whiteout(seconds: float = 1.2) -> void:
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 1.0, seconds * 0.4)
	tw.tween_interval(seconds * 0.2)
	tw.tween_property(_flash, "color:a", 0.0, seconds * 0.4)
	await tw.finished


func letterbox(on: bool, seconds: float = 0.6) -> void:
	var tw := create_tween()
	tw.tween_method(_set_letterbox, _letterbox, 1.0 if on else 0.0, seconds)
	await tw.finished


func _set_letterbox(t: float) -> void:
	_letterbox = t
	var h := 0.11 * t
	_bar_top.anchor_bottom = h
	_bar_bottom.anchor_top = 1.0 - h
	_bar_top.offset_bottom = 0.0
	_bar_bottom.offset_top = 0.0
