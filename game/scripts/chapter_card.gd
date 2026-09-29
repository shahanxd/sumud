extends Control
class_name ChapterCard
## A chapter card that stitches itself in: a tatreez band embroiders across the top and
## bottom of a black cloth while the day title appears. Data comes from the generator's
## JSON (game/assets/tatreez/band_N.json), which lists every stitch in stitching order.

signal finished

@export var band_path := "res://assets/tatreez/band_1.json"
@export var stitch_seconds := 2.4
@export var hold_seconds := 1.6
@export var cell := 10.0

var _stitches: Array = []
var _cloth := Color(0.08, 0.07, 0.06)
var _band_w := 0
var _band_h := 0
var _progress := 0.0   # 0..1 share of stitches placed
var _title_alpha := 0.0

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle


func _ready() -> void:
	_load_band()
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0


func _load_band() -> void:
	var file := FileAccess.open(band_path, FileAccess.READ)
	if file == null:
		push_warning("chapter card: band not found " + band_path)
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	_stitches = data.get("stitches", [])
	_band_w = int(data.get("width", 0))
	_band_h = int(data.get("height", 0))
	_cloth = Color(data.get("cloth", "#15110F"))


## Plays the card. Awaitable: `await card.play("Day 1", "The Kite Festival")`.
func play(day_text: String, title_text: String) -> void:
	title_label.text = title_text
	subtitle_label.text = day_text
	_progress = 0.0
	_title_alpha = 0.0
	var tw := create_tween()
	tw.tween_property(self, "_progress", 1.0, stitch_seconds).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "_title_alpha", 1.0, stitch_seconds * 0.8).set_delay(stitch_seconds * 0.4)
	tw.tween_interval(hold_seconds)
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	await tw.finished
	finished.emit()


func _process(_delta: float) -> void:
	title_label.modulate.a = _title_alpha
	subtitle_label.modulate.a = _title_alpha
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _cloth)
	if _stitches.is_empty():
		return
	var band_px_w := _band_w * cell
	var x_off := (size.x - band_px_w) * 0.5
	var count := int(_progress * _stitches.size())
	var thread_w := maxf(1.0, cell * 0.22)
	var inset := cell * 0.12
	for row_offset in [cell * 6.0, size.y - cell * (6.0 + _band_h)]:
		for i in count:
			var s: Array = _stitches[i]
			var x: float = x_off + float(s[0]) * cell
			var y: float = row_offset + float(s[1]) * cell
			var c := Color(String(s[2]))
			draw_line(Vector2(x + inset, y + inset), Vector2(x + cell - inset, y + cell - inset), c, thread_w, true)
			draw_line(Vector2(x + cell - inset, y + inset), Vector2(x + inset, y + cell - inset), c, thread_w, true)
