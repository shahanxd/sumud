extends Beat
## The day closes in Layla's notebook: cream paper, the basmala written at the top the way
## every schoolchild writes it, the day's entries in Arabic over English, the acts of care
## marked in tatreez red. Then the end card stitches itself in.

const CARD_SCENE := preload("res://scenes/chapter_card.tscn")
const ARABIC_FONT := "res://assets/fonts/amiri/Amiri-Regular.ttf"
const INK := Color(0.17, 0.14, 0.12)
const PAPER := Color(0.945, 0.9, 0.815)
const RED := Color(0.71, 0.07, 0.11)

var shown := false
var closed := false
var entry_count := 0

var _layer: CanvasLayer
var _paper: Panel
var _hint: Label


func _ready() -> void:
	title = "The notebook"
	phase = "night"


func begin(ctx: Dictionary) -> void:
	super.begin(ctx)
	_build()
	var snd := get_node_or_null("/root/Sound")
	if snd != null and snd.has_method("play"):
		snd.play("paper_page", "effects")
	var tw := create_tween()
	tw.tween_property(_paper, "modulate:a", 1.0, 0.2 if Day.bot_mode else 1.0)
	await tw.finished
	shown = true


func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.03, 0.04, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(backdrop)

	_paper = Panel.new()
	_paper.set_anchors_preset(Control.PRESET_CENTER)
	_paper.custom_minimum_size = Vector2(1180, 940)
	_paper.offset_left = -590
	_paper.offset_right = 590
	_paper.offset_top = -470
	_paper.offset_bottom = 470
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 24
	_paper.add_theme_stylebox_override("panel", style)
	_paper.modulate.a = 0.0
	_layer.add_child(_paper)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	_paper.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var font = load(ARABIC_FONT)
	var basmala := _label("بسم الله الرحمن الرحيم", 40, INK, true, font)
	basmala.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(basmala)
	var day_line := _label("اليوم الأول", 30, INK, true, font)
	day_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(day_line)
	var day_en := _label("Day 1", 22, INK.lightened(0.25), false, null)
	day_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(day_en)
	col.add_child(_rule())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)

	var entries := Notebook.day_entries(Notebook.current_day)
	entry_count = entries.size()
	for e in entries:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var ar := String(e.get("ar", ""))
		if not ar.is_empty():
			var ar_label := _label(ar, 30, INK, true, font)
			ar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(ar_label)
		var en_text := String(e.get("en", ""))
		var en_label := _label(en_text, 22, INK.lightened(0.15), false, null)
		en_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(en_label)
		if bool(e.get("act", false)):
			var mark := _label("✕  remembered", 16, RED, false, null)
			row.add_child(mark)
		list.add_child(row)

	_hint = _label(Say.text("notebook.hint.close"), 18, INK.lightened(0.35), false, null)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_hint)


func _label(text: String, size: int, color: Color, rtl: bool, font) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if rtl:
		l.text_direction = Control.TEXT_DIRECTION_RTL
		l.language = "ar"
	if font:
		l.add_theme_font_override("font", font)
	return l


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = RED
	r.custom_minimum_size = Vector2(0, 2)
	return r


func _physics_process(_delta: float) -> void:
	if shown and not closed and Input.is_action_just_pressed("interact"):
		closed = true
		_close()


func _close() -> void:
	var snd := get_node_or_null("/root/Sound")
	if snd != null and snd.has_method("play"):
		snd.play("paper_page", "effects")
	var tw := create_tween()
	tw.tween_property(_paper, "modulate:a", 0.0, 0.1 if Day.bot_mode else 0.6)
	await tw.finished
	var card := CARD_SCENE.instantiate()
	card.band_path = "res://assets/tatreez/band_2.json"
	if Day.bot_mode:
		card.stitch_seconds = 0.2
		card.hold_seconds = 0.05
	_layer.add_child(card)
	await card.play(Say.text("notebook.end.day"), Say.text("notebook.end.title"))
	card.queue_free()
	finish({"notebook_shown": true, "entries": entry_count})
