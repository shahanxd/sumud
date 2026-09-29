extends CanvasLayer
## Autoload "Say". Dialogue on screen: the Arabic line above, the English below, the
## speaker's name small. Lines come from data/lines.csv by key so the readers can review
## every word in one file. A line waits for the interact key, or for its seconds.

const LINES_PATH := "res://data/lines.csv"
const ARABIC_FONT := "res://assets/fonts/amiri/Amiri-Regular.ttf"

var busy := false
var lines: Dictionary = {}

var _box: PanelContainer
var _speaker: Label
var _ar: Label
var _en: Label
var _advance := false


func _ready() -> void:
	layer = 60
	_load_lines()
	_build()


func _load_lines() -> void:
	var file := FileAccess.open(LINES_PATH, FileAccess.READ)
	if file == null:
		return
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3 or row[0].is_empty():
			continue
		var entry := {}
		for i in mini(header.size(), row.size()):
			entry[header[i]] = row[i]
		lines[row[0]] = entry


func _build() -> void:
	_box = PanelContainer.new()
	# Anchored to a line near the bottom; the box grows upward to fit however many lines wrap.
	_box.anchor_left = 0.0
	_box.anchor_right = 1.0
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = 240.0
	_box.offset_right = -240.0
	_box.offset_top = -60.0
	_box.offset_bottom = -60.0
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.04, 0.78)
	style.set_corner_radius_all(4)
	style.content_margin_left = 40.0
	style.content_margin_right = 40.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	_box.add_theme_stylebox_override("panel", style)
	add_child(_box)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(col)

	_speaker = Label.new()
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", Color(0.82, 0.55, 0.42))
	col.add_child(_speaker)

	_ar = Label.new()
	_ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ar.text_direction = Control.TEXT_DIRECTION_RTL
	_ar.language = "ar"
	_ar.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ar.add_theme_font_size_override("font_size", 44)
	_ar.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
	var font := load(ARABIC_FONT)
	if font:
		_ar.add_theme_font_override("font", font)
	col.add_child(_ar)

	_en = Label.new()
	_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_en.autowrap_mode = TextServer.AUTOWRAP_WORD
	_en.add_theme_font_size_override("font_size", 28)
	_en.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78))
	col.add_child(_en)

	_box.modulate.a = 0.0
	_box.visible = false


## Shows one line. Waits for interact, or `seconds` if given. Awaitable.
func line(speaker: String, ar: String, en: String, seconds: float = 0.0) -> void:
	while busy:
		await get_tree().process_frame
	busy = true
	_speaker.text = speaker
	_ar.text = ar
	_ar.visible = not ar.is_empty()
	_en.text = en
	_box.visible = true
	var tw := create_tween()
	tw.tween_property(_box, "modulate:a", 1.0, 0.25)
	await tw.finished
	_advance = false
	var bot := OS.get_cmdline_user_args().has("--bot")
	var min_frames := 3 if bot else 30
	var max_frames := 12 if bot else (int(seconds * 60.0) if seconds > 0.0 else 60 * 60)
	for i in max_frames:
		await get_tree().physics_frame
		if i >= min_frames and Input.is_action_just_pressed("interact"):
			break
	var out := create_tween()
	out.tween_property(_box, "modulate:a", 0.0, 0.2)
	await out.finished
	_box.visible = false
	busy = false


## Shows the line with this key from data/lines.csv.
func key(k: String, seconds: float = 0.0) -> void:
	var entry: Dictionary = lines.get(k, {})
	if entry.is_empty():
		push_warning("say: no line with key " + k)
		await line("", "", k, seconds)
		return
	await line(String(entry.get("speaker", "")), String(entry.get("ar", "")), String(entry.get("en", "")), seconds)


func text(k: String, lang: String = "en") -> String:
	var entry: Dictionary = lines.get(k, {})
	return String(entry.get(lang, k))
